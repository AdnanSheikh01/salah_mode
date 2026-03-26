import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:salah_mode/screens/home_bottom_navbar/tools/quran/quran_memorise/quran_memorise_shared.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/quran/quran_memorise/quran_memorize.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:salah_mode/screens/utils/theme_data.dart';

// ─────────────────────────────────────────────────────────────────

class SelfModeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ayahs;
  final String surahName;
  final int surahNumber;
  final VoidCallback onBack;

  const SelfModeScreen({
    super.key,
    required this.ayahs,
    required this.surahName,
    required this.surahNumber,
    required this.onBack,
  });

  @override
  State<SelfModeScreen> createState() => _SelfModeScreenState();
}

class _SelfModeScreenState extends State<SelfModeScreen> with MemoriseHelpers {
  int _index = 0;
  final Set<int> _memorised = {};
  bool _hideAyah = false;
  String _spokenText = '';
  bool? _lastResult;

  // Per-word highlight results (null = unchecked, true = correct, false = wrong)
  List<bool?>? _wordResults;

  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;
  bool _transitioning = false;

  double get _progress =>
      widget.ayahs.isEmpty ? 0 : _memorised.length / widget.ayahs.length;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    try {
      _speech.stop();
      _speech.cancel();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _speechReady = await _speech.initialize(
        onError: (e) {
          debugPrint('Speech error: ${e.errorMsg}');
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (s) {
          if (!mounted) return;
          const terminal = {'done', 'notListening', 'doneNoResult'};
          if (terminal.contains(s) && _isListening)
            setState(() => _isListening = false);
        },
      );
    } catch (_) {
      _speechReady = false;
    }
  }

  Timer? _pollTimer;

  void _startPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) {
        _pollTimer?.cancel();
        return;
      }
      if (_isListening && !_speech.isListening) {
        _pollTimer?.cancel();
        if (mounted) setState(() => _isListening = false);
      }
    });
  }

  Future<void> _startListening() async {
    if (_isListening || !mounted) return;
    if (!_speechReady) {
      await _initSpeech();
      if (!_speechReady) {
        showSnack(
          'Not Available',
          'Speech recognition unavailable.',
          isError: true,
        );
        return;
      }
    }

    final arabic = widget.ayahs[_index]['arabic']?.toString() ?? '';
    final wc = arabic.trim().split(RegExp(r'\s+')).length;
    final secs = wc < 5
        ? 20
        : wc < 10
        ? 30
        : wc < 20
        ? 45
        : 60;

    // Clear previous results when starting fresh
    setState(() {
      _isListening = true;
      _spokenText = '';
      _lastResult = null;
      _wordResults = null;
    });

    try {
      await _speech.listen(
        localeId: 'ar_SA',
        listenFor: Duration(seconds: secs),
        pauseFor: const Duration(seconds: 6),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
        onResult: (r) {
          if (!mounted) return;
          setState(() => _spokenText = r.recognizedWords);
          if (r.finalResult) {
            _pollTimer?.cancel();
            _checkRecitation();
          }
        },
      );
      _startPoll();
    } catch (e) {
      _pollTimer?.cancel();
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _stopListening() {
    _pollTimer?.cancel();
    try {
      _speech.stop();
    } catch (_) {}
    if (mounted) setState(() => _isListening = false);
  }

  Future<void> _checkRecitation() async {
    _stopListening();
    final correct = widget.ayahs[_index]['arabic']?.toString() ?? '';
    final ratio = MemoriseHelpers.wordOverlap(_spokenText, correct);

    if (ratio >= MemoriseHelpers.kPassThreshold) {
      // ✓ Correct — clear highlights, show transitioning
      setState(() {
        _memorised.add(_index);
        _lastResult = true;
        _wordResults = null; // clear any previous wrong highlights
        _transitioning = true;
      });
      HapticFeedback.mediumImpact();
      showSnack(
        'Excellent 🤲',
        MemoriseHelpers.matchDetail(_spokenText, correct),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _nextAyah();
    } else {
      // ✗ Incorrect — highlight wrong words, wait for user to tap Recite again
      final match = MemoriseHelpers.strictMatch(_spokenText, correct);
      final wordRes = match.wordResults.map<bool?>((r) => r).toList();
      final wrongCount = match.wordResults.where((r) => !r).length;

      setState(() {
        _lastResult = false;
        _wordResults = wordRes; // triggers red word highlights
        _hideAyah = false;
      });
      HapticFeedback.heavyImpact();
      showSnack(
        'Wrong Words ($wrongCount)',
        MemoriseHelpers.matchDetail(_spokenText, correct),
        isWarning: true,
      );
      // ── Mic stays OFF — user studies the red highlighted words,
      //    then taps "Recite This Verse" when ready to try again.
    }
  }

  void _nextAyah() {
    if (_index >= widget.ayahs.length - 1) {
      showSnack('🎉 Complete!', 'You have recited all ayahs in this surah.');
      return;
    }
    setState(() {
      _index++;
      _spokenText = '';
      _lastResult = null;
      _wordResults = null;
      _hideAyah = false;
      _transitioning = false;
    });
  }

  void _prevAyah() {
    _stopListening();
    if (_index <= 0) return;
    setState(() {
      _index--;
      _spokenText = '';
      _lastResult = null;
      _wordResults = null;
      _hideAyah = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ayah = widget.ayahs[_index];
    final arabic = ayah['arabic']?.toString() ?? '';
    final english =
        (ayah['translation']?.toString().isNotEmpty == true
                ? ayah['translation']
                : ayah['english'])
            ?.toString() ??
        '';
    final ayahNum = ayah['ayahNumber'] as int? ?? (_index + 1);
    final isMem = _memorised.contains(_index);

    return Container(
      color: bg,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgress(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: border, width: 0.8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _badge('Ayah $ayahNum', accent),
                              if (isMem)
                                _badge('Memorised ✓', AppTheme.colorSuccess),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Arabic — word-highlighted when wrong, plain otherwise
                          _buildArabicText(arabic),

                          // Listening indicator
                          if (_isListening) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.colorSuccess.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.colorSuccess.withOpacity(
                                    0.28,
                                  ),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.colorSuccess,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Listening — recite this verse',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.colorSuccess,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Wrong-word review hint
                          if (_lastResult == false &&
                              _wordResults != null &&
                              !_isListening) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.colorError.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.colorError.withOpacity(0.28),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.highlight_rounded,
                                    size: 13,
                                    color: AppTheme.colorError,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Red words were wrong — study them, then tap Recite again.',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: AppTheme.colorError,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),
                          Container(height: 0.8, color: border),
                          const SizedBox(height: 12),

                          if (!_hideAyah && english.isNotEmpty)
                            Text(
                              english,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: tp,
                                height: 1.6,
                              ),
                            ),

                          if (_spokenText.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _spokenCard(_spokenText, _lastResult),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildNavBtn(
                          enabled: _index > 0 && !_isListening,
                          isNext: false,
                          onTap: _prevAyah,
                        ),
                        Text(
                          '${_index + 1} / ${widget.ayahs.length}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ts,
                          ),
                        ),
                        buildNavBtn(
                          enabled:
                              _index < widget.ayahs.length - 1 && !_isListening,
                          isNext: true,
                          onTap: _nextAyah,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (!_transitioning)
                      ActionBtn(
                        icon: _isListening
                            ? Icons.stop_rounded
                            : Icons.mic_rounded,
                        label: _isListening
                            ? 'Stop Reciting'
                            : 'Recite This Verse',
                        filled: true,
                        accent: accent,
                        btnTxt: btnTxt,
                        border: border,
                        onTap: _isListening ? _stopListening : _startListening,
                      )
                    else
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.colorSuccess.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.colorSuccess.withOpacity(0.28),
                            width: 0.8,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.colorSuccess,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Moving to next verse…',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.colorSuccess,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Arabic text — plain or per-word highlighted ────────────────
  Widget _buildArabicText(String arabic) {
    // No word results — plain gold text
    if (_wordResults == null) {
      return Text(
        arabic,
        key: ValueKey('arabic_plain_$_index'),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 26,
          color: gold,
          height: 2.0,
        ),
      );
    }

    // Word-level highlighting: wrong = red box, correct = success green, pending = gold
    final words = arabic
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return Directionality(
      key: ValueKey('arabic_highlighted_$_index'),
      textDirection: TextDirection.rtl,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: List.generate(words.length, (i) {
          final result = i < _wordResults!.length ? _wordResults![i] : null;
          final isWrong = result == false;
          final isRight = result == true;
          final color = isWrong
              ? AppTheme.colorError
              : isRight
              ? AppTheme.colorSuccess
              : gold;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            padding: isWrong
                ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
                : EdgeInsets.zero,
            decoration: isWrong
                ? BoxDecoration(
                    color: AppTheme.colorError.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: AppTheme.colorError.withOpacity(0.35),
                      width: 0.8,
                    ),
                  )
                : null,
            child: Text(
              words[i],
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 26,
                color: color,
                height: 2.0,
                fontWeight: isWrong ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(
      children: [
        GestureDetector(
          onTap: () {
            _stopListening();
            widget.onBack();
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withOpacity(0.25), width: 0.6),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Recall & Check',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: tp,
          ),
        ),
        const Spacer(),
        Text(
          '${_memorised.length}/${widget.ayahs.length}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: accent,
          ),
        ),
      ],
    ),
  );

  Widget _buildProgress() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: _progress,
        minHeight: 4,
        backgroundColor: border,
        valueColor: AlwaysStoppedAnimation<Color>(accent),
      ),
    ),
  );

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.25), width: 0.6),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );

  Widget _spokenCard(String text, bool? result) {
    final c = result == null
        ? accent
        : result
        ? AppTheme.colorSuccess
        : AppTheme.colorError;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.28), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic_rounded, size: 11, color: c),
              const SizedBox(width: 5),
              Text(
                'You recited:',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: c,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 18,
              color: c,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  MODE 3 — PAGE MODE
