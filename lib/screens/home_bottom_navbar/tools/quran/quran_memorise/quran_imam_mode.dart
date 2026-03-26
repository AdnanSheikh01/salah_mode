import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/quran/quran_memorise/quran_memorise_shared.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/quran/quran_memorise/quran_memorize.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:salah_mode/screens/utils/theme_data.dart';

enum _ImamSubMode { continuous, verseByVerse }

class ImamModeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ayahs;
  final String surahName;
  final int surahNumber;
  final VoidCallback onBack;

  const ImamModeScreen({
    super.key,
    required this.ayahs,
    required this.surahName,
    required this.surahNumber,
    required this.onBack,
  });

  @override
  State<ImamModeScreen> createState() => _ImamModeScreenState();
}

class _ImamModeScreenState extends State<ImamModeScreen> with MemoriseHelpers {
  // ── Sub-mode ───────────────────────────────────────────────────
  _ImamSubMode _subMode = _ImamSubMode.continuous;

  // ── Progress ───────────────────────────────────────────────────
  int _index = 0;
  final Set<int> _memorised = {};
  double get _progress =>
      widget.ayahs.isEmpty ? 0 : _memorised.length / widget.ayahs.length;

  // ── Audio ──────────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _completeSub;
  StreamSubscription<Duration>? _positionSub;
  Duration _audioDuration = Duration.zero;
  bool _isPlaying = false;

  // ── Speech ─────────────────────────────────────────────────────
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;
  String _spokenText = '';
  bool? _lastResult;
  List<bool?>? _wordResults;

  // ── UI state ───────────────────────────────────────────────────
  bool _hideArabic = false;
  bool _imamPlayed = false;
  String _phase = 'idle';
  bool _transitioning = false;

  // ── Word highlight ─────────────────────────────────────────────
  int _highlightedWordIndex = -1;
  Timer? _wordHighlightTimer;

  // ── Polling timer ──────────────────────────────────────────────
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
        if (mounted)
          setState(() {
            _isListening = false;
            _phase = 'idle';
            _hideArabic = false;
          });
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initSpeech();
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      _stopWordHighlight();

      // ── Follow Along: imam finishes → wait for user to tap Recite
      // ── Listen & Repeat: imam finishes → wait for user to tap Recite
      // Both modes: DO NOT auto-start mic. User taps Recite manually.
      setState(() {
        _isPlaying = false;
        _phase = 'idle';
        _hideArabic = false;
        _imamPlayed = true; // unlocks Recite button
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _wordHighlightTimer?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    _player.stop();
    _player.dispose();
    try {
      _speech.stop();
      _speech.cancel();
    } catch (_) {}
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  WORD HIGHLIGHT — position-based
  // ─────────────────────────────────────────────────────────────

  void _startWordHighlight() {
    _wordHighlightTimer?.cancel();
    _positionSub?.cancel();
    setState(() {
      _highlightedWordIndex = -1;
      _audioDuration = Duration.zero;
    });

    final arabic = widget.ayahs[_index]['arabic']?.toString() ?? '';
    final words = arabic
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return;

    _player.getDuration().then((dur) {
      if (dur != null && dur > Duration.zero) _audioDuration = dur;
    });

    _positionSub = _player.onPositionChanged.listen((position) {
      if (!mounted || !_isPlaying) return;
      Duration total = _audioDuration;
      if (total <= Duration.zero)
        total = Duration(milliseconds: words.length * 800);
      final ratio =
          position.inMilliseconds / total.inMilliseconds.clamp(1, 999999);
      final newIndex = ((ratio * words.length) - 1).floor().clamp(
        -1,
        words.length - 1,
      );
      if (newIndex != _highlightedWordIndex)
        setState(() => _highlightedWordIndex = newIndex);
    });
  }

  void _stopWordHighlight() {
    _wordHighlightTimer?.cancel();
    _positionSub?.cancel();
    if (mounted)
      setState(() {
        _highlightedWordIndex = -1;
        _audioDuration = Duration.zero;
      });
  }

  // ─────────────────────────────────────────────────────────────
  //  SPEECH INIT
  // ─────────────────────────────────────────────────────────────

  Future<void> _initSpeech() async {
    try {
      _speechReady = await _speech.initialize(
        onError: (e) {
          debugPrint('Speech error: ${e.errorMsg}');
          if (mounted)
            setState(() {
              _isListening = false;
              _phase = 'idle';
              _hideArabic = false;
            });
        },
        onStatus: (s) {
          if (!mounted) return;
          const terminal = {'done', 'notListening', 'doneNoResult'};
          if (terminal.contains(s) && _isListening) {
            setState(() {
              _isListening = false;
              _phase = 'idle';
              _hideArabic = false;
            });
          }
        },
      );
    } catch (_) {
      _speechReady = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  AUDIO
  // ─────────────────────────────────────────────────────────────

  Future<void> _playImam() async {
    if (_isListening) _stopListening();
    final ayah = widget.ayahs[_index];
    final num = ayah['ayahNumber'] as int? ?? (_index + 1);
    final url =
        'https://everyayah.com/data/Alafasy_128kbps/'
        '${widget.surahNumber.toString().padLeft(3, '0')}'
        '${num.toString().padLeft(3, '0')}.mp3';
    try {
      await _player.stop();
      setState(() {
        _isPlaying = true;
        _phase = 'playing';
        _spokenText = '';
        _lastResult = null;
        _wordResults = null;
        _hideArabic = false;
        _imamPlayed = false;
      });
      await _player.play(UrlSource(url));
      _startWordHighlight();
    } catch (e) {
      debugPrint('Audio error: $e');
      setState(() {
        _isPlaying = false;
        _phase = 'idle';
      });
      showSnack(
        'Audio Error',
        'Could not play. Check your connection.',
        isError: true,
      );
    }
  }

  Future<void> _stopImam() async {
    _stopWordHighlight();
    try {
      await _player.stop();
    } catch (_) {}
    if (mounted)
      setState(() {
        _isPlaying = false;
        _phase = 'idle';
      });
  }

  // ─────────────────────────────────────────────────────────────
  //  SPEECH
  // ─────────────────────────────────────────────────────────────

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
    final listenSecs = wc < 5
        ? 20
        : wc < 10
        ? 30
        : wc < 20
        ? 45
        : 60;

    setState(() {
      _isListening = true;
      _phase = 'listening';
      _spokenText = '';
      _hideArabic = true;
    });

    try {
      await _speech.listen(
        localeId: 'ar_SA',
        listenFor: Duration(seconds: listenSecs),
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
      debugPrint('listen() threw: $e');
      _pollTimer?.cancel();
      if (mounted)
        setState(() {
          _isListening = false;
          _phase = 'idle';
          _hideArabic = false;
        });
    }
  }

  void _stopListening({bool revealArabic = false}) {
    _pollTimer?.cancel();
    try {
      _speech.stop();
    } catch (_) {}
    if (mounted)
      setState(() {
        _isListening = false;
        _phase = 'idle';
        if (revealArabic) _hideArabic = false;
      });
  }

  // ─────────────────────────────────────────────────────────────
  //  RECITATION CHECK
  // ─────────────────────────────────────────────────────────────

  Future<void> _checkRecitation() async {
    _stopListening();
    setState(() => _phase = 'checking');

    final correct = widget.ayahs[_index]['arabic']?.toString() ?? '';
    final ratio = MemoriseHelpers.wordOverlap(_spokenText, correct);

    if (ratio >= MemoriseHelpers.kPassThreshold) {
      // ── Pass ──────────────────────────────────────────────────
      setState(() {
        _memorised.add(_index);
        _lastResult = true;
        _wordResults = null;
        _hideArabic = false;
        _transitioning = true;
      });
      HapticFeedback.mediumImpact();
      showSnack(
        'Excellent 🤲',
        MemoriseHelpers.matchDetail(_spokenText, correct),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      if (_index >= widget.ayahs.length - 1) {
        setState(() {
          _phase = 'idle';
          _transitioning = false;
        });
        showSnack('Session Complete! 🎉', 'All ayahs memorised.');
        return;
      }

      setState(() {
        _index++;
        _spokenText = '';
        _lastResult = null;
        _wordResults = null;
        _hideArabic = false;
        _phase = 'idle';
        _transitioning = false;
      });

      if (_subMode == _ImamSubMode.continuous) {
        // Follow Along: auto-play imam for next verse, user taps Recite after
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) _playImam();
      } else {
        // Listen & Repeat: just reset — user taps Play Imam manually
        setState(() => _imamPlayed = false);
      }
    } else {
      // ── Fail ──────────────────────────────────────────────────
      final match = MemoriseHelpers.strictMatch(_spokenText, correct);
      final wordResults = match.wordResults.map<bool?>((r) => r).toList();
      final wrongCount = match.wordResults.where((r) => !r).length;
      setState(() {
        _lastResult = false;
        _wordResults = wordResults;
        _hideArabic = false;
        _phase = 'review';
      });
      HapticFeedback.heavyImpact();
      showSnack(
        'Wrong Words ($wrongCount)',
        MemoriseHelpers.matchDetail(_spokenText, correct),
        isWarning: true,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  NAVIGATION
  // ─────────────────────────────────────────────────────────────

  void _resetForAyah() {
    _stopWordHighlight();
    _spokenText = '';
    _lastResult = null;
    _wordResults = null;
    _hideArabic = false;
    _imamPlayed = false;
    _phase = 'idle';
    _isPlaying = false;
    _transitioning = false;
  }

  void _nextAyah() {
    if (_index >= widget.ayahs.length - 1) return;
    _stopListening();
    _player.stop();
    setState(() {
      _index++;
      _resetForAyah();
    });
  }

  void _prevAyah() {
    if (_index <= 0) return;
    _stopListening();
    _player.stop();
    setState(() {
      _index--;
      _resetForAyah();
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

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
            const SizedBox(height: 8),
            _buildSubModeToggle(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  children: [
                    _buildPhaseChip(),
                    const SizedBox(height: 12),
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
                              _ayahBadge(ayahNum),
                              if (isMem) _memorisedBadge(),
                            ],
                          ),
                          const SizedBox(height: 20),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _hideArabic
                                ? _buildRecitePrompt()
                                : _buildArabicText(arabic),
                          ),
                          const SizedBox(height: 12),
                          Container(height: 0.8, color: border),
                          const SizedBox(height: 12),
                          if (!_hideArabic && english.isNotEmpty)
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
                          if (_spokenText.isNotEmpty && !_hideArabic) ...[
                            const SizedBox(height: 14),
                            _buildSpokenFeedback(_spokenText, _lastResult),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildNavBtn(
                          enabled: _index > 0 && !_isPlaying && !_isListening,
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
                              _index < widget.ayahs.length - 1 &&
                              !_isPlaying &&
                              !_isListening,
                          isNext: true,
                          onTap: _nextAyah,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_transitioning)
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
                      )
                    else
                      _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sub-mode toggle ────────────────────────────────────────────
  Widget _buildSubModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 0.8),
        ),
        child: Row(
          children: [
            _subModeBtn(
              _ImamSubMode.continuous,
              Icons.play_lesson_rounded,
              'Follow Along',
            ),
            _subModeBtn(
              _ImamSubMode.verseByVerse,
              Icons.record_voice_over_rounded,
              'Listen & Repeat',
            ),
          ],
        ),
      ),
    );
  }

  Widget _subModeBtn(_ImamSubMode mode, IconData icon, String label) {
    final active = _subMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: (_isPlaying || _isListening)
            ? null
            : () {
                setState(() {
                  _subMode = mode;
                  _resetForAyah();
                });
                _player.stop();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: active ? btnTxt : ts),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? btnTxt : ts,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Action buttons ─────────────────────────────────────────────
  Widget _buildActionButtons() {
    // ── Review phase ─────────────────────────────────────────────
    if (_phase == 'review') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.colorError.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.colorError.withOpacity(0.28),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.colorError,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Study the highlighted words above,\nthen choose an action below.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppTheme.colorError,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ActionBtn(
                  icon: _imamPlayed
                      ? Icons.hearing_rounded
                      : Icons.play_circle_rounded,
                  label: _imamPlayed ? 'Hear It Again' : 'Hear Imam',
                  filled: false,
                  accent: accent,
                  btnTxt: btnTxt,
                  border: border,
                  onTap: () {
                    setState(() {
                      _spokenText = '';
                      _lastResult = null;
                      _wordResults = null;
                      _hideArabic = false;
                      _imamPlayed = false;
                      _phase = 'idle';
                    });
                    _playImam();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionBtn(
                  icon: Icons.mic_rounded,
                  label: 'Recite Again',
                  filled: true,
                  accent: accent,
                  btnTxt: btnTxt,
                  border: border,
                  onTap: _imamPlayed
                      ? () {
                          setState(() {
                            _spokenText = '';
                            _lastResult = null;
                            _wordResults = null;
                            _hideArabic = true;
                            _phase = 'listening';
                          });
                          _startListening();
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // ── Normal phase ─────────────────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hint — shown after imam played, not listening, not playing
        if (!_hideArabic && !_isListening && !_isPlaying && _imamPlayed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb_outline_rounded, size: 14, color: gold),
                const SizedBox(width: 6),
                Text(
                  'Remember it? Tap Recite when ready.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: gold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

        Row(
          children: [
            // Left button:
            //   - If playing → "Stop Imam"  (stop the audio)
            //   - Otherwise  → "Play Imam"
            Expanded(
              child: ActionBtn(
                icon: _isPlaying
                    ? Icons.stop_circle_rounded
                    : Icons.play_circle_rounded,
                label: _isPlaying ? 'Stop Imam' : 'Play Imam',
                filled: false,
                accent: accent,
                btnTxt: btnTxt,
                border: border,
                onTap: _isListening
                    ? null
                    : _isPlaying
                    ? _stopImam
                    : _playImam,
              ),
            ),
            const SizedBox(width: 12),
            // Right button:
            //   - Disabled until imam has played at least once
            //   - If listening → "Stop"
            //   - Otherwise   → "Recite"
            Expanded(
              child: ActionBtn(
                icon: _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                label: _isListening ? 'Stop' : 'Recite',
                filled: true,
                accent: accent,
                btnTxt: btnTxt,
                border: border,
                onTap: !_imamPlayed || _isPlaying
                    ? null
                    : _isListening
                    ? () => _stopListening(revealArabic: true)
                    : () {
                        setState(() {
                          _hideArabic = true;
                          _spokenText = '';
                          _lastResult = null;
                          _wordResults = null;
                        });
                        _startListening();
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Recite prompt ──────────────────────────────────────────────
  Widget _buildRecitePrompt() {
    return Container(
      key: const ValueKey('recite_prompt'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _isListening
                  ? AppTheme.colorSuccess.withOpacity(0.12)
                  : accent.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isListening
                    ? AppTheme.colorSuccess.withOpacity(0.35)
                    : accent.withOpacity(0.25),
                width: 0.8,
              ),
            ),
            child: Icon(
              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _isListening ? AppTheme.colorSuccess : accent,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isListening ? 'Listening…' : 'Do you remember it?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _isListening ? AppTheme.colorSuccess : tp,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isListening
                ? 'Recite the verse clearly'
                : 'Tap Recite to start — speak when ready',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: _isListening ? AppTheme.colorSuccess : ts,
            ),
          ),
        ],
      ),
    );
  }

  // ── Arabic text — plain or word-highlighted ────────────────────
  Widget _buildArabicText(String arabic) {
    final words = arabic
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return Directionality(
      key: ValueKey('arabic_$_index'),
      textDirection: TextDirection.rtl,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: List.generate(words.length, (i) {
          final reviewResult =
              (_wordResults != null && i < _wordResults!.length)
              ? _wordResults![i]
              : null;
          final isWrong = reviewResult == false;
          final isImamHighlit = _isPlaying && i <= _highlightedWordIndex;
          final color = isWrong
              ? AppTheme.colorError
              : isImamHighlit
              ? AppTheme.colorSuccess
              : gold;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
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
                fontWeight: (isWrong || isImamHighlit)
                    ? FontWeight.w700
                    : FontWeight.normal,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(
      children: [
        GestureDetector(
          onTap: () {
            _player.stop();
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
          'Guided Repetition',
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

  // ── Progress bar ───────────────────────────────────────────────
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

  // ── Phase chip ─────────────────────────────────────────────────
  Widget _buildPhaseChip() {
    final phaseInfo = <String, (String, Color, IconData)>{
      'idle': ('Ready', ts, Icons.radio_button_unchecked),
      'playing': ('Imam Reciting…', accent, Icons.volume_up_rounded),
      'listening': (
        'Listening to you…',
        AppTheme.colorSuccess,
        Icons.mic_rounded,
      ),
      'checking': ('Checking…', gold, Icons.hourglass_top_rounded),
      'review': (
        'Review Mistakes',
        AppTheme.colorError,
        Icons.highlight_rounded,
      ),
    };
    final info =
        phaseInfo[_phase] ?? ('Ready', ts, Icons.radio_button_unchecked);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: info.$2.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: info.$2.withOpacity(0.28), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.$3, size: 12, color: info.$2),
          const SizedBox(width: 6),
          Text(
            info.$1,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: info.$2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ayahBadge(int num) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: accent.withOpacity(0.10),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: accent.withOpacity(0.25), width: 0.6),
    ),
    child: Text(
      'Ayah $num',
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: accent,
      ),
    ),
  );

  Widget _memorisedBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppTheme.colorSuccess.withOpacity(0.10),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: AppTheme.colorSuccess.withOpacity(0.28),
        width: 0.6,
      ),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 11,
          color: AppTheme.colorSuccess,
        ),
        SizedBox(width: 4),
        Text(
          'Memorised',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.colorSuccess,
          ),
        ),
      ],
    ),
  );

  Widget _buildSpokenFeedback(String text, bool? result) {
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
