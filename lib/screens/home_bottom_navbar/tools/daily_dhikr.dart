import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tasbih/tasbih.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';
import 'package:speech_to_text/speech_to_text.dart';

class DailyDhikrScreen extends StatefulWidget {
  const DailyDhikrScreen({super.key});

  @override
  State<DailyDhikrScreen> createState() => _DailyDhikrScreenState();
}

class _DailyDhikrScreenState extends State<DailyDhikrScreen> {
  int _step = 0;
  bool _showAyatulKursi = false;
  bool _ayatCompleted = false;
  final List<bool> _completed = [false, false, false];

  // ── Speech ─────────────────────────────────────────────────────
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _spokenText = '';

  // ── Ayatul Kursi key words for matching ───────────────────────
  static const List<String> _ayatKeyPhrases = [
    "الله لا إله إلا هو",
    "الحي القيوم",
    "لا تأخذه سنة ولا نوم",
    "له ما في السماوات",
    "من ذا الذي يشفع",
    "يعلم ما بين أيديهم",
    "وسع كرسيه",
    "العلي العظيم",
  ];

  // ── Full Ayatul Kursi text ─────────────────────────────────────
  static const String _ayatulKursiFull =
      "ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ ۚ "
      "لَا تَأْخُذُهُۥ سِنَةٌۭ وَلَا نَوْمٌۭ ۚ لَّهُۥ مَا فِى ٱلسَّمَٰوَٰتِ "
      "وَمَا فِى ٱلْأَرْضِ ۗ مَن ذَا ٱلَّذِى يَشْفَعُ عِندَهُۥٓ إِلَّا بِإِذْنِهِۦ ۚ "
      "يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَىْءٍۢ "
      "مِّنْ عِلْمِهِۦٓ إِلَّا بِمَا شَآءَ ۚ وَسِعَ كُرْسِيُّهُ ٱلسَّمَٰوَٰتِ وَٱلْأَرْضَ ۖ "
      "وَلَا يَـُٔودُهُۥ حِفْظُهُمَا ۚ وَهُوَ ٱلْعَلِىُّ ٱلْعَظِيمُ";

  // ── Quiz questions ─────────────────────────────────────────────
  static const List<Map<String, dynamic>> _quizQuestions = [
    {
      "q": "What does 'Al-Hayy Al-Qayyum' mean?",
      "options": [
        "The Forgiving, the Merciful",
        "The Ever-Living, the Self-Sustaining",
        "The All-Knowing, the All-Seeing",
        "The First, the Last",
      ],
      "answer": 1,
    },
    {
      "q": "What does Ayatul Kursi say about Allah's sleep?",
      "options": [
        "He sleeps for a moment",
        "He rests at night",
        "Neither drowsiness nor sleep overtakes Him",
        "He only rests on Fridays",
      ],
      "answer": 2,
    },
    {
      "q": "What is the 'Kursi' (footstool) described to encompass?",
      "options": [
        "The earth only",
        "The heavens only",
        "The heavens and the earth",
        "The universe and beyond",
      ],
      "answer": 2,
    },
    {
      "q": "According to Ayatul Kursi, who can intercede with Allah?",
      "options": [
        "Any righteous person",
        "Only prophets",
        "No one at all",
        "Only those He permits",
      ],
      "answer": 3,
    },
    {
      "q": "Which surah does Ayatul Kursi belong to?",
      "options": [
        "Surah Al-Fatiha",
        "Surah Al-Baqarah",
        "Surah Al-Imran",
        "Surah An-Nisa",
      ],
      "answer": 1,
    },
  ];

  // ── Dhikr steps ────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _dhikrSteps = [
    {
      "title": "SubhanAllah",
      "tasbihKey": "Subhanallah",
      "count": "33 Times",
      "arabic": "سُبْحَانَ اللّٰهِ",
      "translation": "Glory be to Allah",
      "target": 33,
    },
    {
      "title": "Alhamdulillah",
      "tasbihKey": "Alhamdulillah",
      "count": "33 Times",
      "arabic": "اَلْحَمْدُ لِلّٰهِ",
      "translation": "All praise belongs to Allah",
      "target": 33,
    },
    {
      "title": "Allahu Akbar",
      "tasbihKey": "Allahu Akbar",
      "count": "34 Times",
      "arabic": "اَللّٰهُ أَكْبَرُ",
      "translation": "Allah is the Greatest",
      "target": 34,
    },
  ];

  // ── Navigation ─────────────────────────────────────────────────
  void _nextStep() {
    if (!mounted) return;
    if (_step < _dhikrSteps.length - 1) {
      setState(() => _step++);
    } else {
      setState(() => _showAyatulKursi = true);
    }
  }

  // ── Speech recognition ─────────────────────────────────────────
  Future<void> _startListening() async {
    if (_ayatCompleted || !mounted) return;

    bool available = false;
    try {
      available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _isListening = false);
          _snack(
            "Speech Error",
            error.errorMsg.isNotEmpty ? error.errorMsg : "Unknown error.",
            isError: true,
          );
        },
      );
    } catch (_) {
      _snack(
        "Mic Error",
        "Could not initialise speech recognition.",
        isError: true,
      );
      return;
    }

    if (!available) {
      _snack(
        "Not Available",
        "Speech recognition is not available on this device.",
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isListening = true;
      _spokenText = '';
    });

    try {
      _speech.listen(
        localeId: 'ar_SA',
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 6),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        onResult: (result) {
          if (!mounted) return;
          setState(() => _spokenText = result.recognizedWords);
          if (result.finalResult) _checkFullAyah();
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isListening = false);
      _snack(
        "Listening Error",
        "Could not start. Please try again.",
        isError: true,
      );
    }
  }

  void _stopListening() {
    try {
      _speech.stop();
    } catch (_) {}
    if (mounted) setState(() => _isListening = false);
  }

  // ── Full Ayah check — requires majority of key phrases ─────────
  void _checkFullAyah() {
    final text = _spokenText.trim();
    if (text.isEmpty) return;

    int matched = _ayatKeyPhrases
        .where((phrase) => text.contains(phrase))
        .length;

    // Require at least 5 out of 8 key phrases (≈60%)
    if (matched >= 5) {
      _stopListening();
      if (!mounted) return;
      setState(() => _ayatCompleted = true);
      _showRewardDialog();
    } else {
      _snack(
        "Keep Going",
        "Continue reciting — $matched/${_ayatKeyPhrases.length} phrases recognised. "
            "Speak clearly and complete the full Ayah.",
        isWarning: true,
      );
    }
  }

  // ── Open quiz ──────────────────────────────────────────────────
  void _openQuiz() {
    Get.to(
      () => _AyatulKursiQuiz(
        questions: _quizQuestions,
        onPassed: () {
          Get.back();
          if (mounted) {
            setState(() => _ayatCompleted = true);
            _showRewardDialog();
          }
        },
      ),
    );
  }

  // ── Snackbar helper ────────────────────────────────────────────
  void _snack(
    String title,
    String msg, {
    bool isError = false,
    bool isWarning = false,
  }) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.snackbar(
      title,
      msg,
      backgroundColor: isError
          ? AppTheme.colorError
          : isWarning
          ? AppTheme.colorWarning
          : (isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt),
      colorText: (isError || isWarning)
          ? Colors.white
          : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 4),
    );
  }

  // ── Reward dialog ──────────────────────────────────────────────
  void _showRewardDialog() {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final goldColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccentGold;
    final textPrimary = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final textSecond = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final btnTxt = isDark
        ? AppTheme.darkTextOnAccent
        : AppTheme.lightTextOnAccent;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.colorSuccess.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.colorSuccess.withOpacity(0.30),
                    width: 0.8,
                  ),
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: AppTheme.colorSuccess,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Ayatul Kursi Completed!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "+50 Barakah Points Earned",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: goldColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "May Allah accept your dhikr. Ameen.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: textSecond,
                ),
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Close",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: btnTxt,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      _speech.stop();
      _speech.cancel();
    } catch (_) {}
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final cardAltColor = isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final goldColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccentGold;
    final textPrimary = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final btnTextColor = isDark
        ? AppTheme.darkTextOnAccent
        : AppTheme.lightTextOnAccent;

    final safeStep = _step.clamp(0, _dhikrSteps.length - 1);
    final current = _dhikrSteps[safeStep];
    final doneCount = _completed.where((e) => e).length;
    final remaining = _showAyatulKursi
        ? (_ayatCompleted ? 0 : 1)
        : (_dhikrSteps.length - doneCount) + 1;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: accentColor,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Daily Dhikr",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Streak banner ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.colorSuccess.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.colorSuccess.withOpacity(0.30),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppTheme.colorSuccess,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        remaining == 0
                            ? "All Dhikr completed! Streak maintained. +50 Barakah Points!"
                            : remaining == 1
                            ? "Complete 1 more dhikr to earn +50 Barakah Points."
                            : "Complete ${remaining - 1} more dhikr to maintain your streak.",
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Step dots ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_dhikrSteps.length, (i) {
                  final isActive = i == safeStep && !_showAyatulKursi;
                  final isDone = _completed[i];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: isActive ? 22 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppTheme.colorSuccess
                          : isActive
                          ? accentColor
                          : borderColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // ── Dhikr card ─────────────────────────────────
              if (!_showAyatulKursi)
                _DhikrCard(
                  current: current,
                  isCompleted: _completed[safeStep],
                  cardColor: cardColor,
                  accentColor: accentColor,
                  goldColor: goldColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                  btnTextColor: btnTextColor,
                  onStartTasbih: () async {
                    final target = (current['target'] as int?) ?? 33;
                    try {
                      final result = await Get.to(
                        () => const TasbihPage(),
                        arguments: {
                          'guided': true,
                          'tasbih': current['tasbihKey'],
                          'target': target,
                        },
                      );
                      if (result == true && mounted) {
                        setState(() => _completed[safeStep] = true);
                        if (safeStep == _dhikrSteps.length - 1) _nextStep();
                      }
                    } catch (e) {
                      debugPrint("TasbihPage nav error: $e");
                    }
                  },
                ),

              // ── Ayatul Kursi card ──────────────────────────
              if (_showAyatulKursi)
                _AyatulKursiCard(
                  ayatulKursiFull: _ayatulKursiFull,
                  cardColor: cardColor,
                  cardAltColor: cardAltColor,
                  accentColor: accentColor,
                  goldColor: goldColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                ),

              const SizedBox(height: 20),

              // ── Word-by-word speech display ────────────────
              if (_showAyatulKursi && _spokenText.trim().isNotEmpty)
                _WordByWordDisplay(
                  spokenText: _spokenText,
                  cardAltColor: cardAltColor,
                  borderColor: borderColor,
                  goldColor: goldColor,
                  textSecondary: textSecondary,
                ),

              const SizedBox(height: 20),

              // ── Next step button ───────────────────────────
              if (!_showAyatulKursi && _completed[safeStep])
                Align(
                  alignment: Alignment.centerRight,
                  child: _ThemedButton(
                    label: safeStep == _dhikrSteps.length - 1
                        ? "Read Ayatul Kursi"
                        : "Next",
                    accentColor: accentColor,
                    btnTextColor: btnTextColor,
                    icon: Icons.arrow_forward_rounded,
                    onTap: _nextStep,
                  ),
                ),

              // ── Ayatul Kursi actions ───────────────────────
              if (_showAyatulKursi && !_ayatCompleted) ...[
                // Recite button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      size: 18,
                      color: btnTextColor,
                    ),
                    label: Text(
                      _isListening
                          ? "Listening... tap to stop"
                          : "Recite Ayatul Kursi",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: btnTextColor,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(accentColor),
                      foregroundColor: MaterialStateProperty.all(btnTextColor),
                      elevation: MaterialStateProperty.all(0),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    onPressed: _isListening ? _stopListening : _startListening,
                  ),
                ),

                const SizedBox(height: 12),

                // Can't talk → quiz button
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      if (_isListening) _stopListening();
                      _openQuiz();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accentColor.withOpacity(0.25),
                          width: 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz_rounded,
                            size: 16,
                            color: accentColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Can't Talk? Take the Quiz Instead",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // ── Completed badge ────────────────────────────
              if (_showAyatulKursi && _ayatCompleted)
                Center(child: _CompletedBadge(color: AppTheme.colorSuccess)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  WORD-BY-WORD SPEECH DISPLAY
// ═══════════════════════════════════════════════════════════════════

class _WordByWordDisplay extends StatelessWidget {
  final String spokenText;
  final Color cardAltColor, borderColor, goldColor, textSecondary;

  const _WordByWordDisplay({
    required this.spokenText,
    required this.cardAltColor,
    required this.borderColor,
    required this.goldColor,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final words = spokenText.trim().split(RegExp(r'\s+'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardAltColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic_rounded, size: 13, color: goldColor),
              const SizedBox(width: 6),
              Text(
                "Recognising — word by word",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: goldColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Wrap renders each word as a chip so it never overflows
          Wrap(
            spacing: 6,
            runSpacing: 6,
            textDirection: TextDirection.rtl,
            children: words.map((word) {
              if (word.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: goldColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: goldColor.withOpacity(0.25),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  word,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    color: goldColor,
                    height: 1.6,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  AYATUL KURSI QUIZ SCREEN
// ═══════════════════════════════════════════════════════════════════

class _AyatulKursiQuiz extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final VoidCallback onPassed;

  const _AyatulKursiQuiz({required this.questions, required this.onPassed});

  @override
  State<_AyatulKursiQuiz> createState() => _AyatulKursiQuizState();
}

class _AyatulKursiQuizState extends State<_AyatulKursiQuiz> {
  int _current = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  bool _showResult = false;

  void _select(int index) {
    if (_answered) return;
    final correct = widget.questions[_current]['answer'] as int;
    setState(() {
      _selected = index;
      _answered = true;
      if (index == correct) _score++;
    });
  }

  void _next() {
    if (_current < widget.questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
        _answered = false;
      });
    } else {
      setState(() => _showResult = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final goldColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccentGold;
    final textPrimary = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final btnTextColor = isDark
        ? AppTheme.darkTextOnAccent
        : AppTheme.lightTextOnAccent;

    final passed = _score >= 3; // pass = 3/5 or better

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: accentColor,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Ayatul Kursi Quiz",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: _showResult
            ? _ResultView(
                score: _score,
                total: widget.questions.length,
                passed: passed,
                accentColor: accentColor,
                goldColor: goldColor,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                btnTextColor: btnTextColor,
                onClaim: passed ? widget.onPassed : null,
                onRetry: passed
                    ? null
                    : () => setState(() {
                        _current = 0;
                        _score = 0;
                        _selected = null;
                        _answered = false;
                        _showResult = false;
                      }),
              )
            : _QuestionView(
                questionIndex: _current,
                total: widget.questions.length,
                q: widget.questions[_current],
                selected: _selected,
                answered: _answered,
                accentColor: accentColor,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                btnTextColor: btnTextColor,
                onSelect: _select,
                onNext: _answered ? _next : null,
              ),
      ),
    );
  }
}

// ── Question view ─────────────────────────────────────────────────
class _QuestionView extends StatelessWidget {
  final int questionIndex, total;
  final Map<String, dynamic> q;
  final int? selected;
  final bool answered;
  final Color accentColor, cardColor, borderColor;
  final Color textPrimary, textSecondary, btnTextColor;
  final ValueChanged<int> onSelect;
  final VoidCallback? onNext;

  const _QuestionView({
    required this.questionIndex,
    required this.total,
    required this.q,
    required this.selected,
    required this.answered,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.btnTextColor,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final options = q['options'] as List;
    final correct = q['answer'] as int;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          Row(
            children: [
              Text(
                "Question ${questionIndex + 1} of $total",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                "${((questionIndex / total) * 100).round()}%",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: questionIndex / total,
              minHeight: 4,
              backgroundColor: borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 24),

          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Text(
              q['q'] as String,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Options
          ...List.generate(options.length, (i) {
            final isSelected = selected == i;
            final isCorrect = i == correct;
            Color borderC = borderColor;
            Color bgC = cardColor;
            Color textC = textPrimary;
            IconData? icon;

            if (answered) {
              if (isCorrect) {
                borderC = AppTheme.colorSuccess;
                bgC = AppTheme.colorSuccess.withOpacity(0.10);
                textC = AppTheme.colorSuccess;
                icon = Icons.check_circle_rounded;
              } else if (isSelected) {
                borderC = AppTheme.colorError;
                bgC = AppTheme.colorError.withOpacity(0.08);
                textC = AppTheme.colorError;
                icon = Icons.cancel_rounded;
              }
            } else if (isSelected) {
              borderC = accentColor;
              bgC = accentColor.withOpacity(0.08);
              textC = accentColor;
            }

            return GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: bgC,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderC, width: 0.9),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        options[i] as String,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textC,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 10),
                      Icon(icon, size: 18, color: textC),
                    ],
                  ],
                ),
              ),
            );
          }),

          if (answered && onNext != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: onNext,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    questionIndex < 4 ? "Next Question" : "See Results",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: btnTextColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Result view ───────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final int score, total;
  final bool passed;
  final Color accentColor, goldColor, cardColor, borderColor;
  final Color textPrimary, textSecondary, btnTextColor;
  final VoidCallback? onClaim;
  final VoidCallback? onRetry;

  const _ResultView({
    required this.score,
    required this.total,
    required this.passed,
    required this.accentColor,
    required this.goldColor,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.btnTextColor,
    required this.onClaim,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final resultColor = passed ? AppTheme.colorSuccess : AppTheme.colorError;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: resultColor.withOpacity(0.30),
                width: 0.8,
              ),
            ),
            child: Icon(
              passed ? Icons.emoji_events_rounded : Icons.replay_rounded,
              color: resultColor,
              size: 36,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            passed ? "Quiz Passed!" : "Not Quite There",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "$score out of $total correct",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              color: resultColor,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            passed
                ? "MashaAllah! You know Ayatul Kursi well."
                : "You need 3/5 to pass. Review the Ayah and try again.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          if (passed && onClaim != null)
            GestureDetector(
              onTap: onClaim,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Claim Reward +50 Barakah",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: btnTextColor,
                  ),
                ),
              ),
            ),

          if (!passed && onRetry != null)
            GestureDetector(
              onTap: onRetry,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Try Again",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: btnTextColor,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentColor.withOpacity(0.22),
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                "Back to Dhikr",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _DhikrCard extends StatelessWidget {
  final Map<String, dynamic> current;
  final bool isCompleted;
  final Color cardColor, accentColor, goldColor;
  final Color textPrimary, textSecondary, borderColor, btnTextColor;
  final VoidCallback onStartTasbih;

  const _DhikrCard({
    required this.current,
    required this.isCompleted,
    required this.cardColor,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.btnTextColor,
    required this.onStartTasbih,
  });

  @override
  Widget build(BuildContext context) {
    final title = (current['title'] as String?) ?? '';
    final count = (current['count'] as String?) ?? '';
    final arabic = (current['arabic'] as String?) ?? '';
    final translation = (current['translation'] as String?) ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withOpacity(0.25),
                width: 0.8,
              ),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            arabic,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: goldColor,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            translation,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          isCompleted
              ? _CompletedBadge(color: AppTheme.colorSuccess)
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(accentColor),
                      foregroundColor: MaterialStateProperty.all(btnTextColor),
                      elevation: MaterialStateProperty.all(0),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    onPressed: onStartTasbih,
                    child: Text(
                      "Start Tasbih",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: btnTextColor,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _AyatulKursiCard extends StatelessWidget {
  final String ayatulKursiFull;
  final Color cardColor, cardAltColor, accentColor, goldColor;
  final Color textPrimary, textSecondary, borderColor;

  const _AyatulKursiCard({
    required this.ayatulKursiFull,
    required this.cardColor,
    required this.cardAltColor,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        children: [
          Text(
            "Ayatul Kursi",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "آية الكرسي",
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 15,
              color: goldColor,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: borderColor, thickness: 0.8),
          const SizedBox(height: 14),
          Text(
            ayatulKursiFull,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              color: goldColor,
              height: 2.0,
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: borderColor, thickness: 0.8),
          const SizedBox(height: 10),
          Text(
            "Allah! There is no deity except Him, the Ever-Living, the Self-Sustaining. "
            "Neither drowsiness overtakes Him nor sleep.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemedButton extends StatelessWidget {
  final String label;
  final Color accentColor, btnTextColor;
  final IconData icon;
  final VoidCallback onTap;

  const _ThemedButton({
    required this.label,
    required this.accentColor,
    required this.btnTextColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: btnTextColor,
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 15, color: btnTextColor),
          ],
        ),
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  final Color color;
  const _CompletedBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            "Completed",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
