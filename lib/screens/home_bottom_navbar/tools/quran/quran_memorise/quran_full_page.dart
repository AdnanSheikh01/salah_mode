import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/quran/quran_memorise/quran_memorise_shared.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:salah_mode/screens/utils/theme_data.dart';

// ─────────────────────────────────────────────────────────────────

class PageModeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ayahs;
  final String surahName;
  final int surahNumber;
  final VoidCallback onBack;

  const PageModeScreen({
    super.key,
    required this.ayahs,
    required this.surahName,
    required this.surahNumber,
    required this.onBack,
  });

  @override
  State<PageModeScreen> createState() => _PageModeScreenState();
}

class _PageModeScreenState extends State<PageModeScreen> with MemoriseHelpers {
  // How many ayahs per page
  static const int _pageSize = 5;
  int _pageIndex = 0;
  int get _totalPages => (widget.ayahs.length / _pageSize).ceil();

  List<Map<String, dynamic>> get _currentPageAyahs {
    final start = _pageIndex * _pageSize;
    final end = (start + _pageSize).clamp(0, widget.ayahs.length);
    return widget.ayahs.sublist(start, end);
  }

  // Current ayah being checked (within page)
  int _activeAyahInPage = 0;

  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;
  bool _isActive = false; // session started

  // Per-ayah word results: list of (word, isCorrect?)
  // null = not yet checked, true = correct, false = wrong
  final Map<int, List<bool?>> _wordResults = {};

  // Error sound
  final AudioPlayer _errorPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initWordResults();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    try {
      _speech.stop();
      _speech.cancel();
    } catch (_) {}
    _errorPlayer.dispose();
    super.dispose();
  }

  void _initWordResults() {
    _wordResults.clear();
    for (int i = 0; i < _currentPageAyahs.length; i++) {
      final words =
          _currentPageAyahs[i]['arabic']?.toString().trim().split(
            RegExp(r'\s+'),
          ) ??
          [];
      _wordResults[i] = List.filled(words.length, null);
    }
    _activeAyahInPage = 0;
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
          if (terminal.contains(s) && _isListening) {
            setState(() => _isListening = false);
          }
        },
      );
    } catch (_) {
      _speechReady = false;
    }
  }

  Future<void> _startSession() async {
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
    setState(() {
      _isActive = true;
    });
    _listenForCurrentAyah();
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
        if (mounted) {
          setState(() {
            _isListening = false;
          });
        }
      }
    });
  }

  Future<void> _listenForCurrentAyah() async {
    if (!mounted || _activeAyahInPage >= _currentPageAyahs.length) return;

    final arabic =
        _currentPageAyahs[_activeAyahInPage]['arabic']?.toString() ?? '';
    final wc = arabic.trim().split(RegExp(r'\s+')).length;
    // Generous durations — Quran recitation has natural pauses (tajweed)
    final secs = wc < 5
        ? 25
        : wc < 10
        ? 35
        : wc < 20
        ? 50
        : 70;

    setState(() => _isListening = true);

    try {
      await _speech.listen(
        localeId: 'ar_SA',
        listenFor: Duration(seconds: secs),
        pauseFor: const Duration(seconds: 6), // 6s gap — allows tajweed pauses
        partialResults: false,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
        onResult: (r) {
          if (!mounted) return;
          if (r.finalResult) {
            _pollTimer?.cancel();
            _checkPageAyah(r.recognizedWords);
          }
        },
      );
      _startPoll();
    } catch (e) {
      _pollTimer?.cancel();
      if (mounted) setState(() => _isListening = false);
    }
  }

  Future<void> _checkPageAyah(String spoken) async {
    try {
      _speech.stop();
    } catch (_) {}
    setState(() => _isListening = false);

    if (spoken.trim().isEmpty) {
      showSnack('No Speech', 'Could not hear you. Try again.', isWarning: true);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) _listenForCurrentAyah();
      return;
    }

    final correct =
        _currentPageAyahs[_activeAyahInPage]['arabic']?.toString() ?? '';

    // Strict per-word pronunciation matching via Levenshtein
    final match = MemoriseHelpers.strictMatch(spoken, correct);
    final ratio = match.ratio;
    final results = match.wordResults;
    final wrongCount = results.where((r) => !r).length;

    setState(
      () => _wordResults[_activeAyahInPage] = results
          .map((r) => r as bool?)
          .toList(),
    );

    if (ratio >= MemoriseHelpers.kPassThreshold) {
      // Pass — move to next ayah in page
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      if (_activeAyahInPage < _currentPageAyahs.length - 1) {
        setState(() => _activeAyahInPage++);
        _listenForCurrentAyah();
      } else {
        // Page complete
        setState(() => _isActive = false);
        showSnack(
          'Page Complete! 🎉',
          'All ayahs on this page recited correctly.',
        );
      }
    } else {
      // Fail — play error sound, highlight wrong words, wait then retry
      HapticFeedback.heavyImpact();
      await _playErrorSound();
      showSnack(
        'Wrong Words ($wrongCount)',
        MemoriseHelpers.matchDetail(spoken, correct),
        isWarning: true,
      );
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        // Reset results for this ayah and retry
        setState(() {
          _wordResults[_activeAyahInPage] = List.filled(results.length, null);
        });
        _listenForCurrentAyah();
      }
    }
  }

  Future<void> _playErrorSound() async {
    try {
      // Short buzzer tone via system sound
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  void _stopSession() {
    _pollTimer?.cancel();
    try {
      _speech.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isListening = false;
        _isActive = false;
      });
    }
  }

  void _nextPage() {
    if (_pageIndex >= _totalPages - 1) return;
    _stopSession();
    setState(() {
      _pageIndex++;
    });
    _initWordResults();
  }

  void _prevPage() {
    if (_pageIndex <= 0) return;
    _stopSession();
    setState(() {
      _pageIndex--;
    });
    _initWordResults();
  }

  @override
  Widget build(BuildContext context) {
    final pageAyahs = _currentPageAyahs;

    return Container(
      color: bg,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 8),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page ${_pageIndex + 1} of $_totalPages',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ts,
                    ),
                  ),
                  if (_isListening)
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.colorSuccess,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Listening…',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppTheme.colorSuccess,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Ayahs display
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  children: [
                    // All ayahs on page rendered as one flowing text block
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: border, width: 0.8),
                      ),
                      child: Column(
                        children: List.generate(pageAyahs.length, (i) {
                          final ayah = pageAyahs[i];
                          final arabic = ayah['arabic']?.toString() ?? '';
                          final english =
                              (ayah['translation']?.toString().isNotEmpty ==
                                          true
                                      ? ayah['translation']
                                      : ayah['english'])
                                  ?.toString() ??
                              '';
                          final ayahNum =
                              ayah['ayahNumber'] as int? ??
                              ((_pageIndex * _pageSize) + i + 1);
                          final isActive = i == _activeAyahInPage && _isActive;
                          final results = _wordResults[i];
                          final words = arabic.trim().split(RegExp(r'\s+'));

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? accent.withOpacity(0.06)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isActive
                                  ? Border.all(
                                      color: accent.withOpacity(0.25),
                                      width: 0.8,
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Ayah number badge
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      english.isNotEmpty
                                          ? (english.length > 60
                                                ? '${english.substring(0, 60)}…'
                                                : english)
                                          : '',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 10,
                                        color: ts,
                                        height: 1.4,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? accent.withOpacity(0.12)
                                            : accent.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$ayahNum',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Arabic text with per-word colouring
                                Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: List.generate(words.length, (wi) {
                                      final wordResult =
                                          (results != null &&
                                              wi < results.length)
                                          ? results[wi]
                                          : null;
                                      final color = wordResult == null
                                          ? gold
                                          : wordResult
                                          ? AppTheme.colorSuccess
                                          : AppTheme.colorError;
                                      final bg = wordResult == false
                                          ? AppTheme.colorError.withOpacity(
                                              0.10,
                                            )
                                          : Colors.transparent;

                                      return Container(
                                        padding: wordResult == false
                                            ? const EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 1,
                                              )
                                            : EdgeInsets.zero,
                                        decoration: wordResult == false
                                            ? BoxDecoration(
                                                color: bg,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: AppTheme.colorError
                                                      .withOpacity(0.30),
                                                  width: 0.6,
                                                ),
                                              )
                                            : null,
                                        child: Text(
                                          words[wi],
                                          style: TextStyle(
                                            fontFamily: 'Amiri',
                                            fontSize: 22,
                                            color: color,
                                            height: 2.0,
                                            fontWeight: wordResult == false
                                                ? FontWeight.w700
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Page nav + start button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildNavBtn(
                          enabled: _pageIndex > 0,
                          isNext: false,
                          onTap: _prevPage,
                        ),
                        Text(
                          '${_pageIndex + 1} / $_totalPages',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ts,
                          ),
                        ),
                        buildNavBtn(
                          enabled: _pageIndex < _totalPages - 1,
                          isNext: true,
                          onTap: _nextPage,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Start / Stop session button
                    GestureDetector(
                      onTap: _isActive ? _stopSession : _startSession,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: _isActive ? AppTheme.colorError : accent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isActive
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isActive
                                  ? (_isListening
                                        ? 'Stop Listening'
                                        : 'Stop Session')
                                  : 'Start Reciting Page',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(
      children: [
        GestureDetector(
          onTap: () {
            _stopSession();
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
          'Full Page Recitation',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: tp,
          ),
        ),
        const Spacer(),
        Text(
          widget.surahName,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: ts),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
//  SHARED ACTION BUTTON
