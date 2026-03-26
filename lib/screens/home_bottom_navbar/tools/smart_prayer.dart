import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:salah_mode/screens/utils/point_service.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class _NiyyahEntry {
  final String text;
  final DateTime added;
  bool completed;
  _NiyyahEntry({
    required this.text,
    required this.added,
    this.completed = false,
  });
}

// ─────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────

class SmartCompanionScreen extends StatefulWidget {
  const SmartCompanionScreen({super.key});
  @override
  State<SmartCompanionScreen> createState() => _SmartCompanionScreenState();
}

class _SmartCompanionScreenState extends State<SmartCompanionScreen>
    with TickerProviderStateMixin {
  // ── Tab ───────────────────────────────────────────────────────
  int _tab = 0; // 0=Home 1=Chat 2=Niyyah 3=Insights

  // ── Chat ──────────────────────────────────────────────────────
  final List<_ChatMessage> _messages = [];
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  bool _aiTyping = false;
  bool _chatError = false;

  // ── Niyyah Vault ──────────────────────────────────────────────
  final List<_NiyyahEntry> _niyyahs = [];
  final TextEditingController _niyyahCtrl = TextEditingController();
  bool _niyyahLoaded = false;

  // ── Khushu / streak ───────────────────────────────────────────
  int _streak = 0;
  int _khushuScore = 0; // 0-100, simulated
  int _prayersLogged = 0;
  int _dhikrCount = 0;
  bool _focusActive = false;
  Timer? _focusTimer;
  int _focusSeconds = 0;

  // ── Global Echo ───────────────────────────────────────────────
  int _globalEchoCount = 0;
  bool _echoJoined = false;

  // ── Daily wisdom ──────────────────────────────────────────────
  int _wisdomIndex = 0;
  static const List<Map<String, String>> _wisdoms = [
    {
      "hadith":
          "The most beloved deeds to Allah are those that are consistent, even if they are small.",
      "source": "Sahih Bukhari 6464",
    },
    {
      "hadith": "Whoever does not show mercy will not be shown mercy.",
      "source": "Sahih Bukhari 6013",
    },
    {
      "hadith":
          "The strong man is not the one who overcomes people. The strong man is the one who controls himself when he is angry.",
      "source": "Sahih Bukhari 6114",
    },
    {"hadith": "A kind word is charity.", "source": "Sahih Bukhari 2989"},
    {
      "hadith":
          "None of you truly believes until he wishes for his brother what he wishes for himself.",
      "source": "Sahih Bukhari 13",
    },
    {
      "hadith":
          "The best among you are those who have the best manners and character.",
      "source": "Sahih Bukhari 3559",
    },
    {
      "hadith": "Make things easy and do not make them difficult.",
      "source": "Sahih Bukhari 69",
    },
  ];

  // ── Suggested AI prompts ──────────────────────────────────────
  static const List<String> _quickPrompts = [
    "How can I improve my Khushu in Salah?",
    "What are the virtues of Fajr prayer?",
    "Give me a Dua for anxiety",
    "Explain the meaning of Surah Al-Ikhlas",
    "How many times should I say Subhanallah?",
    "What breaks Wudu?",
    "Dua for a new day",
    "How to perform Tahajjud?",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _pickDailyWisdom();
    _messages.add(
      _ChatMessage(
        text:
            "As-salamu alaykum! 🌙\n\n"
            "I am your Islamic Smart Companion. Ask me anything about prayer, "
            "Duas, Hadith, or Islamic guidance. How can I assist you today?",
        isUser: false,
        time: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    _chatScroll.dispose();
    _niyyahCtrl.dispose();
    _focusTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  PERSISTENCE
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _streak = prefs.getInt('companion_streak') ?? 0;
      _khushuScore = prefs.getInt('companion_khushu') ?? 72;
      _prayersLogged = prefs.getInt('companion_prayers_logged') ?? 0;
      _dhikrCount = prefs.getInt('companion_dhikr') ?? 0;
      _globalEchoCount = prefs.getInt('global_echo_count') ?? 142_847;

      // Load niyyahs
      final raw = prefs.getStringList('niyyah_vault') ?? [];
      _niyyahs.clear();
      for (final r in raw) {
        try {
          final m = jsonDecode(r) as Map<String, dynamic>;
          _niyyahs.add(
            _NiyyahEntry(
              text: m['text'] as String,
              added: DateTime.parse(m['added'] as String),
              completed: m['done'] as bool? ?? false,
            ),
          );
        } catch (_) {}
      }
      _niyyahLoaded = true;
    } catch (e) {
      debugPrint("SmartCompanion load error: $e");
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveNiyyahs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'niyyah_vault',
        _niyyahs
            .map(
              (n) => jsonEncode({
                'text': n.text,
                'added': n.added.toIso8601String(),
                'done': n.completed,
              }),
            )
            .toList(),
      );
    } catch (e) {
      debugPrint("Niyyah save error: $e");
    }
  }

  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('companion_streak', _streak);
      await prefs.setInt('companion_khushu', _khushuScore);
      await prefs.setInt('companion_prayers_logged', _prayersLogged);
      await prefs.setInt('companion_dhikr', _dhikrCount);
      await prefs.setInt('global_echo_count', _globalEchoCount);
    } catch (e) {
      debugPrint("Stats save error: $e");
    }
  }

  void _pickDailyWisdom() {
    final today = DateTime.now();
    _wisdomIndex =
        (today.year + today.month * 31 + today.day) % _wisdoms.length;
  }

  // ═══════════════════════════════════════════════════════════════
  //  AI CHAT  (uses a simple Islamic Q&A fallback)
  // ═══════════════════════════════════════════════════════════════

  Future<void> _sendMessage(String text) async {
    final q = text.trim();
    if (q.isEmpty) return;
    _chatCtrl.clear();
    setState(() {
      _messages.add(_ChatMessage(text: q, isUser: true, time: DateTime.now()));
      _aiTyping = true;
      _chatError = false;
    });
    _scrollToBottom();

    try {
      // ── Try Anthropic Claude API ─────────────────────────────
      const apiUrl = 'https://api.anthropic.com/v1/messages';
      final resp = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'anthropic-version': '2023-06-01',
              'x-api-key': 'YOUR_API_KEY', // replace with env/secure storage
            },
            body: jsonEncode({
              'model': 'claude-3-haiku-20240307',
              'max_tokens': 512,
              'system':
                  'You are an Islamic spiritual companion embedded in the Salah Mode app. '
                  'Answer only questions related to Islam, prayer, Quran, Hadith, Duas, fiqh, and spiritual growth. '
                  'Keep answers concise (3-5 sentences), warm, and authentic. '
                  'Always cite sources when mentioning Hadith. '
                  'If asked anything unrelated to Islam, politely redirect to Islamic topics. '
                  'Use respectful Islamic terminology (ﷺ after Prophet mentions, etc.).',
              'messages': [
                {'role': 'user', 'content': q},
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final answer =
            (data['content'] as List<dynamic>).firstWhere(
                  (b) => b['type'] == 'text',
                  orElse: () => {'text': ''},
                )['text']
                as String? ??
            '';

        if (answer.trim().isEmpty) throw Exception('Empty response');

        setState(() {
          _messages.add(
            _ChatMessage(
              text: answer.trim(),
              isUser: false,
              time: DateTime.now(),
            ),
          );
          _aiTyping = false;
        });
      } else if (resp.statusCode == 401) {
        // API key not configured — fall back gracefully
        _addFallbackResponse(q);
      } else {
        throw Exception('API error ${resp.statusCode}');
      }
    } on TimeoutException {
      if (mounted) _addFallbackResponse(q);
    } catch (e) {
      debugPrint("AI chat error: $e");
      if (mounted) _addFallbackResponse(q);
    }

    _scrollToBottom();
  }

  // ── Smart keyword fallback (no network needed) ────────────────
  void _addFallbackResponse(String question) {
    final q = question.toLowerCase();
    String reply;

    if (q.contains('fajr') || q.contains('dawn')) {
      reply =
          "🌅 Fajr is the most blessed prayer — the angels of the night and day both witness it. "
          "The Prophet ﷺ said: 'Whoever prays the two cool prayers (Fajr and Asr) will enter Paradise.' "
          "(Sahih Bukhari 574)";
    } else if (q.contains('khushu') ||
        q.contains('focus') ||
        q.contains('concentration')) {
      reply =
          "🎯 To improve Khushu: understand the meaning of what you recite, pray as if it's your last prayer, "
          "slow your recitation, and minimize distractions. Ibn al-Qayyim said: 'The heart's presence in Salah "
          "is its essence and spirit.'";
    } else if (q.contains('dua') || q.contains('supplication')) {
      reply =
          "🤲 The best time for Dua is the last third of the night, between Adhan and Iqamah, "
          "and in Sujood. The Prophet ﷺ said: 'The closest a servant is to his Lord is when he is in "
          "prostration, so make plenty of Dua.' (Sahih Muslim 482)";
    } else if (q.contains('tahajjud') ||
        q.contains('night prayer') ||
        q.contains('qiyam')) {
      reply =
          "🌙 Tahajjud is prayed after Isha and before Fajr — ideally in the last third of the night. "
          "Pray at least 2 rak'ahs and make it consistent. Allah descends each night asking: 'Who calls on Me "
          "that I may answer them?' (Sahih Bukhari 1145)";
    } else if (q.contains('wudu') || q.contains('ablution')) {
      reply =
          "💧 Wudu is broken by: passing wind, using the toilet, deep sleep, losing consciousness, "
          "and certain other conditions. It is not broken by touching a woman (according to many scholars) "
          "or by eating cooked food in most madhabs.";
    } else if (q.contains('ikhlas') || q.contains('surah')) {
      reply =
          "📖 Surah Al-Ikhlas (112) declares the absolute oneness of Allah: He is Al-Ahad (the Unique One), "
          "As-Samad (the Eternal Refuge who needs nothing). The Prophet ﷺ said reciting it equals one-third "
          "of the Quran in reward. (Sahih Bukhari 5013)";
    } else if (q.contains('subhan') ||
        q.contains('dhikr') ||
        q.contains('tasbih')) {
      reply =
          "📿 The Prophet ﷺ taught: Say SubhanAllah 33 times, Alhamdulillah 33 times, and Allahu Akbar 34 "
          "times after each prayer. Saying SubhanAllah 100 times has the reward of 1,000 good deeds written. "
          "(Sahih Muslim 2073)";
    } else if (q.contains('anxiety') ||
        q.contains('stress') ||
        q.contains('sad') ||
        q.contains('worry')) {
      reply =
          "🤲 Dua for relief: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ' "
          "(O Allah, I seek refuge in You from worry and grief). "
          "Also: 'حَسْبِيَ اللّٰهُ لَا إِلٰهَ إِلَّا هُوَ، عَلَيْهِ تَوَكَّلْتُ' — "
          "recite 7 times morning and evening for relief. (Abu Dawud 5081)";
    } else {
      reply =
          "جَزَاكَ اللّٰهُ خَيْرًا for your question 🌙\n\n"
          "I am here to help with Islamic topics — prayer, Duas, Hadith, Quran, and spiritual growth. "
          "Could you rephrase or ask something more specific? "
          "I can help with Salah, Dhikr, Fiqh, or daily Islamic guidance.";
    }

    setState(() {
      _messages.add(
        _ChatMessage(text: reply, isUser: false, time: DateTime.now()),
      );
      _aiTyping = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (_chatScroll.hasClients) {
          _chatScroll.animateTo(
            _chatScroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      } catch (_) {}
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  FOCUS TRACKER
  // ═══════════════════════════════════════════════════════════════

  void _toggleFocus(Color accentColor, Color btnTextColor) {
    if (_focusActive) {
      _focusTimer?.cancel();
      setState(() {
        _focusActive = false;
        _focusSeconds = 0;
        _prayersLogged++;
        _khushuScore = (_khushuScore + 2).clamp(0, 100);
        _streak++;
      });
      _saveStats();
      // Award points via service (Firestore sync in background)
      unawaited(PointsService.instance.award(PointEvent.prayerLogged));
      unawaited(PointsService.instance.award(PointEvent.streakDay));
      unawaited(
        PointsService.instance.award(
          PointEvent.khushuUpdate,
          amount: _khushuScore,
        ),
      );
      Get.snackbar(
        "Prayer Logged ✦",
        "MashaAllah! Focus session saved. Keep it up!",
        backgroundColor: AppTheme.colorSuccess,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } else {
      setState(() {
        _focusActive = true;
        _focusSeconds = 0;
      });
      _focusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _focusSeconds++);
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  DHIKR + GLOBAL ECHO
  // ═══════════════════════════════════════════════════════════════

  void _tapDhikr() {
    setState(() {
      _dhikrCount++;
      if (!_echoJoined) {
        _echoJoined = true;
        _globalEchoCount++;
      } else {
        _globalEchoCount++;
      }
    });
    HapticFeedback.lightImpact();
    _saveStats();
    // Award dhikr point (÷10 in composite score — raw count stored)
    unawaited(PointsService.instance.award(PointEvent.dhikrTap));
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

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
    final textTertiary = isDark
        ? AppTheme.darkTextTertiary
        : AppTheme.lightTextTertiary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final inputFill = isDark ? AppTheme.darkInputFill : AppTheme.lightInputFill;
    final btnTextColor = isDark
        ? AppTheme.darkTextOnAccent
        : AppTheme.lightTextOnAccent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(accentColor, goldColor, textPrimary),
      body: IndexedStack(
        index: _tab,
        children: [
          _HomeTab(
            streak: _streak,
            khushuScore: _khushuScore,
            prayersLogged: _prayersLogged,
            dhikrCount: _dhikrCount,
            focusActive: _focusActive,
            focusSeconds: _focusSeconds,
            globalEchoCount: _globalEchoCount,
            echoJoined: _echoJoined,
            wisdom: _wisdoms[_wisdomIndex],
            bgColor: bgColor,
            cardColor: cardColor,
            cardAltColor: cardAltColor,
            accentColor: accentColor,
            goldColor: goldColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textTertiary: textTertiary,
            borderColor: borderColor,
            btnTextColor: btnTextColor,
            isDark: isDark,
            onToggleFocus: () => _toggleFocus(accentColor, btnTextColor),
            onTapDhikr: _tapDhikr,
            onGoToChat: () => setState(() => _tab = 1),
          ),
          _ChatTab(
            messages: _messages,
            aiTyping: _aiTyping,
            chatError: _chatError,
            ctrl: _chatCtrl,
            scrollCtrl: _chatScroll,
            quickPrompts: _quickPrompts,
            bgColor: bgColor,
            cardColor: cardColor,
            cardAltColor: cardAltColor,
            accentColor: accentColor,
            goldColor: goldColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textTertiary: textTertiary,
            borderColor: borderColor,
            inputFill: inputFill,
            btnTextColor: btnTextColor,
            isDark: isDark,
            onSend: _sendMessage,
          ),
          _NiyyahTab(
            niyyahs: _niyyahs,
            ctrl: _niyyahCtrl,
            loaded: _niyyahLoaded,
            bgColor: bgColor,
            cardColor: cardColor,
            cardAltColor: cardAltColor,
            accentColor: accentColor,
            goldColor: goldColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textTertiary: textTertiary,
            borderColor: borderColor,
            inputFill: inputFill,
            btnTextColor: btnTextColor,
            onAdd: (text) {
              setState(() {
                _niyyahs.insert(
                  0,
                  _NiyyahEntry(text: text, added: DateTime.now()),
                );
              });
              _saveNiyyahs();
              // Award 3 points per intention set
              unawaited(PointsService.instance.award(PointEvent.niyyahAdded));
            },
            onToggle: (i) {
              setState(() => _niyyahs[i].completed = !_niyyahs[i].completed);
              _saveNiyyahs();
            },
            onDelete: (i) {
              setState(() => _niyyahs.removeAt(i));
              _saveNiyyahs();
            },
          ),
          _InsightsTab(
            streak: _streak,
            khushuScore: _khushuScore,
            prayersLogged: _prayersLogged,
            dhikrCount: _dhikrCount,
            bgColor: bgColor,
            cardColor: cardColor,
            cardAltColor: cardAltColor,
            accentColor: accentColor,
            goldColor: goldColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textTertiary: textTertiary,
            borderColor: borderColor,
            isDark: isDark,
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selected: _tab,
        accentColor: accentColor,
        bgColor: cardColor,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textTertiary: textTertiary,
        unreadChat: _chatError ? 1 : 0,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }

  AppBar _buildAppBar(Color accent, Color gold, Color textPrimary) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: accent, size: 20),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Smart Companion",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          Text(
            "الرفيق الذكي",
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 12,
              color: gold,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HOME TAB
// ═══════════════════════════════════════════════════════════════════

class _HomeTab extends StatelessWidget {
  final int streak, khushuScore, prayersLogged, dhikrCount, focusSeconds;
  final int globalEchoCount;
  final bool focusActive, echoJoined, isDark;
  final Map<String, String> wisdom;
  final Color bgColor, cardColor, cardAltColor, accentColor, goldColor;
  final Color textPrimary,
      textSecondary,
      textTertiary,
      borderColor,
      btnTextColor;
  final VoidCallback onToggleFocus, onTapDhikr, onGoToChat;

  const _HomeTab({
    required this.streak,
    required this.khushuScore,
    required this.prayersLogged,
    required this.dhikrCount,
    required this.focusActive,
    required this.focusSeconds,
    required this.globalEchoCount,
    required this.echoJoined,
    required this.wisdom,
    required this.isDark,
    required this.bgColor,
    required this.cardColor,
    required this.cardAltColor,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderColor,
    required this.btnTextColor,
    required this.onToggleFocus,
    required this.onTapDhikr,
    required this.onGoToChat,
  });

  String _formatFocusTime() {
    final m = focusSeconds ~/ 60;
    final s = focusSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── AI Companion hero card ───────────────────────────────
          GestureDetector(
            onTap: onGoToChat,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: btnTextColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: btnTextColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "AI Islamic Companion",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: btnTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Ask about prayer, Duas, Hadith & more",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: btnTextColor.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: btnTextColor,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Stats row ────────────────────────────────────────────
          _SectionLabel(
            label: "Your Journey",
            goldColor: goldColor,
            textPrimary: textPrimary,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  value: "$streak",
                  label: "Day Streak",
                  color: AppTheme.colorWarning,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.favorite_rounded,
                  value: "$khushuScore%",
                  label: "Khushu",
                  color: AppTheme.colorError,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.mosque_rounded,
                  value: "$prayersLogged",
                  label: "Prayers",
                  color: AppTheme.colorSuccess,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Focus Tracker ─────────────────────────────────────────
          _SectionLabel(
            label: "Focus Tracker",
            goldColor: goldColor,
            textPrimary: textPrimary,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: focusActive
                    ? AppTheme.colorSuccess.withOpacity(0.50)
                    : borderColor,
                width: focusActive ? 1.5 : 0.8,
              ),
            ),
            child: Column(
              children: [
                // Timer display
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: focusActive
                      ? Column(
                          key: const ValueKey('active'),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.colorSuccess,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  "Salah in Progress",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: AppTheme.colorSuccess,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _formatFocusTime(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey('idle'),
                          children: [
                            Icon(
                              Icons.sensors_rounded,
                              size: 36,
                              color: accentColor.withOpacity(0.60),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Start a Salah session",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: onToggleFocus,
                  child: Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      color: focusActive
                          ? AppTheme.colorError
                          : AppTheme.colorSuccess,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          focusActive
                              ? Icons.stop_circle_rounded
                              : Icons.play_circle_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          focusActive ? "End Prayer" : "Begin Salah",
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

          const SizedBox(height: 20),

          // ── Global Dhikr / Echo ───────────────────────────────────
          _SectionLabel(
            label: "Global Dhikr",
            goldColor: goldColor,
            textPrimary: textPrimary,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onTapDhikr,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Column(
                children: [
                  // Globe icon with pulse
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withOpacity(0.30),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.public_rounded,
                      color: accentColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${_formatEchoCount(globalEchoCount)} Muslims",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "doing Dhikr worldwide right now",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "سُبْحَانَ اللّٰهِ",
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 26,
                      color: goldColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: echoJoined
                          ? AppTheme.colorSuccess.withOpacity(0.10)
                          : accentColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: echoJoined
                            ? AppTheme.colorSuccess.withOpacity(0.30)
                            : accentColor.withOpacity(0.30),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          echoJoined
                              ? Icons.check_circle_rounded
                              : Icons.touch_app_rounded,
                          size: 16,
                          color: echoJoined
                              ? AppTheme.colorSuccess
                              : accentColor,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          echoJoined
                              ? "You joined! Count: $dhikrCount"
                              : "Tap to join the echo",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: echoJoined
                                ? AppTheme.colorSuccess
                                : accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Daily Wisdom ──────────────────────────────────────────
          _SectionLabel(
            label: "Daily Hadith",
            goldColor: goldColor,
            textPrimary: textPrimary,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: goldColor.withOpacity(0.25),
                width: 0.8,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 0.8,
                      color: goldColor.withOpacity(0.35),
                    ),
                    const SizedBox(width: 8),
                    Text("✦", style: TextStyle(fontSize: 12, color: goldColor)),
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 0.8,
                      color: goldColor.withOpacity(0.35),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '"${wisdom['hadith']!}"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: textPrimary,
                    height: 1.65,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: goldColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: goldColor.withOpacity(0.20),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    wisdom['source']!,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: goldColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEchoCount(int n) {
    if (n >= 1_000_000) return '${(n / 1_000_000).toStringAsFixed(1)}M';
    if (n >= 1_000) return '${(n / 1_000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CHAT TAB
// ═══════════════════════════════════════════════════════════════════

class _ChatTab extends StatelessWidget {
  final List<_ChatMessage> messages;
  final bool aiTyping, chatError, isDark;
  final TextEditingController ctrl;
  final ScrollController scrollCtrl;
  final List<String> quickPrompts;
  final Color bgColor, cardColor, cardAltColor, accentColor, goldColor;
  final Color textPrimary,
      textSecondary,
      textTertiary,
      borderColor,
      inputFill,
      btnTextColor;
  final ValueChanged<String> onSend;

  const _ChatTab({
    required this.messages,
    required this.aiTyping,
    required this.chatError,
    required this.isDark,
    required this.ctrl,
    required this.scrollCtrl,
    required this.quickPrompts,
    required this.bgColor,
    required this.cardColor,
    required this.cardAltColor,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderColor,
    required this.inputFill,
    required this.btnTextColor,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Quick prompts ─────────────────────────────────────────
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: quickPrompts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => onSend(quickPrompts[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withOpacity(0.22),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  quickPrompts[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Messages ──────────────────────────────────────────────
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    "Ask me anything about Islam 🌙",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: textTertiary,
                    ),
                  ),
                )
              : ListView.separated(
                  controller: scrollCtrl,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                  itemCount: messages.length + (aiTyping ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    if (i == messages.length && aiTyping) {
                      return _TypingBubble(
                        cardColor: cardColor,
                        accentColor: accentColor,
                        textTertiary: textTertiary,
                      );
                    }
                    if (i >= messages.length) return const SizedBox.shrink();
                    final m = messages[i];
                    return _ChatBubble(
                      message: m,
                      accentColor: accentColor,
                      goldColor: goldColor,
                      cardColor: cardColor,
                      cardAltColor: cardAltColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textTertiary: textTertiary,
                      btnTextColor: btnTextColor,
                    );
                  },
                ),
        ),

        // ── Input bar ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(top: BorderSide(color: borderColor, width: 0.8)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: TextField(
                    controller: ctrl,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: textPrimary,
                    ),
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: onSend,
                    decoration: InputDecoration(
                      hintText: "Ask about Islam...",
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: textTertiary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => onSend(ctrl.text),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: btnTextColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Chat bubble ───────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  final Color accentColor, goldColor, cardColor, cardAltColor;
  final Color textPrimary, textSecondary, textTertiary, btnTextColor;

  const _ChatBubble({
    required this.message,
    required this.accentColor,
    required this.goldColor,
    required this.cardColor,
    required this.cardAltColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.btnTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeStr =
        '${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 12,
                        color: btnTextColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "AI Companion",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: isUser ? accentColor : cardAltColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 18 : 4),
                  topRight: Radius.circular(isUser ? 4 : 18),
                  bottomLeft: const Radius.circular(18),
                  bottomRight: const Radius.circular(18),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: isUser ? btnTextColor : textPrimary,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              timeStr,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────
class _TypingBubble extends StatefulWidget {
  final Color cardColor, accentColor, textTertiary;
  const _TypingBubble({
    required this.cardColor,
    required this.accentColor,
    required this.textTertiary,
  });
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final phase = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
                final opacity = (sin(phase * pi) * 0.7 + 0.3).clamp(0.3, 1.0);
                return Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  NIYYAH TAB
// ═══════════════════════════════════════════════════════════════════

class _NiyyahTab extends StatelessWidget {
  final List<_NiyyahEntry> niyyahs;
  final TextEditingController ctrl;
  final bool loaded;
  final Color bgColor, cardColor, cardAltColor, accentColor, goldColor;
  final Color textPrimary,
      textSecondary,
      textTertiary,
      borderColor,
      inputFill,
      btnTextColor;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onDelete;

  const _NiyyahTab({
    required this.niyyahs,
    required this.ctrl,
    required this.loaded,
    required this.bgColor,
    required this.cardColor,
    required this.cardAltColor,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderColor,
    required this.inputFill,
    required this.btnTextColor,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final completed = niyyahs.where((n) => n.completed).length;

    return Column(
      children: [
        // ── Input ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: TextField(
                    controller: ctrl,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: textPrimary,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        onAdd(v.trim());
                        ctrl.clear();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: "Set your intention for today...",
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: textTertiary,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "نية",
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 18,
                            color: goldColor,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 50,
                        minHeight: 48,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  if (ctrl.text.trim().isNotEmpty) {
                    onAdd(ctrl.text.trim());
                    ctrl.clear();
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.add_rounded, color: btnTextColor, size: 24),
                ),
              ),
            ],
          ),
        ),

        // ── Progress ───────────────────────────────────────────────
        if (niyyahs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: niyyahs.isEmpty ? 0 : completed / niyyahs.length,
                      minHeight: 6,
                      backgroundColor: borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.colorSuccess,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "$completed/${niyyahs.length}",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: textTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

        // ── List ───────────────────────────────────────────────────
        Expanded(
          child: !loaded
              ? const Center(child: CircularProgressIndicator())
              : niyyahs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "نِيَّة",
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 48,
                          color: goldColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Set your first intention above",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 32),
                  itemCount: niyyahs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    if (i >= niyyahs.length) return const SizedBox.shrink();
                    final n = niyyahs[i];
                    return Dismissible(
                      key: ValueKey(
                        '${n.text}_${n.added.millisecondsSinceEpoch}',
                      ),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.colorError.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.colorError.withOpacity(0.30),
                            width: 0.8,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppTheme.colorError,
                          size: 20,
                        ),
                      ),
                      onDismissed: (_) => onDelete(i),
                      child: GestureDetector(
                        onTap: () => onToggle(i),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                          decoration: BoxDecoration(
                            color: n.completed
                                ? AppTheme.colorSuccess.withOpacity(0.07)
                                : cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: n.completed
                                  ? AppTheme.colorSuccess.withOpacity(0.30)
                                  : borderColor,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: n.completed
                                      ? AppTheme.colorSuccess
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: n.completed
                                        ? AppTheme.colorSuccess
                                        : borderColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: n.completed
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  n.text,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: n.completed
                                        ? textTertiary
                                        : textPrimary,
                                    decoration: n.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  INSIGHTS TAB
// ═══════════════════════════════════════════════════════════════════

class _InsightsTab extends StatelessWidget {
  final int streak, khushuScore, prayersLogged, dhikrCount;
  final bool isDark;
  final Color bgColor, cardColor, cardAltColor, accentColor, goldColor;
  final Color textPrimary, textSecondary, textTertiary, borderColor;

  const _InsightsTab({
    required this.streak,
    required this.khushuScore,
    required this.prayersLogged,
    required this.dhikrCount,
    required this.isDark,
    required this.bgColor,
    required this.cardColor,
    required this.cardAltColor,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    // Simulate weekly data
    final weekData = [65, 70, 60, 80, khushuScore, 75, khushuScore];
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Khushu chart ──────────────────────────────────────────
          _SectionLabel(
            label: "Weekly Khushu",
            goldColor: goldColor,
            textPrimary: textPrimary,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Column(
              children: [
                // Bar chart
                SizedBox(
                  height: 100,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final h = (weekData[i] / 100 * 90).clamp(10.0, 90.0);
                      final isToday = i == 4; // Friday
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${weekData[i]}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 9,
                                  color: isToday ? accentColor : textTertiary,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 3),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                height: h,
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? accentColor
                                      : accentColor.withOpacity(0.30),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                days[i],
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: isToday ? accentColor : textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Detailed stats grid ────────────────────────────────────
          _SectionLabel(
            label: "Your Statistics",
            goldColor: goldColor,
            textPrimary: textPrimary,
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _InsightCard(
                icon: Icons.local_fire_department_rounded,
                value: "$streak days",
                label: "Prayer Streak",
                color: AppTheme.colorWarning,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _InsightCard(
                icon: Icons.favorite_rounded,
                value: "$khushuScore%",
                label: "Avg Khushu",
                color: AppTheme.colorError,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _InsightCard(
                icon: Icons.mosque_rounded,
                value: "$prayersLogged",
                label: "Prayers Logged",
                color: AppTheme.colorSuccess,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _InsightCard(
                icon: Icons.blur_circular_rounded,
                value: "$dhikrCount",
                label: "Dhikr Count",
                color: AppTheme.colorInfo,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Improvement tips ──────────────────────────────────────
          _SectionLabel(
            label: "Improvement Tips",
            goldColor: goldColor,
            textPrimary: textPrimary,
          ),
          const SizedBox(height: 10),
          ..._buildTips(
            accentColor,
            cardColor,
            borderColor,
            textPrimary,
            textSecondary,
            textTertiary,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTips(
    Color accent,
    Color card,
    Color border,
    Color tp,
    Color ts,
    Color tt,
  ) {
    final tips = [
      if (khushuScore < 80)
        _Tip(
          icon: Icons.slow_motion_video_rounded,
          color: AppTheme.colorInfo,
          title: "Slow down your recitation",
          body:
              "Reciting slower helps your mind connect to the meaning "
              "of each verse and improves Khushu.",
        ),
      if (streak < 7)
        _Tip(
          icon: Icons.alarm_rounded,
          color: AppTheme.colorWarning,
          title: "Set a Salah reminder",
          body:
              "Consistency is the key. Set reminders for all 5 prayers "
              "to build an unbreakable streak.",
        ),
      _Tip(
        icon: Icons.self_improvement_rounded,
        color: AppTheme.colorSuccess,
        title: "Pray Sunnah prayers",
        body:
            "Adding 2 Sunnah rak'ahs before Fajr is worth more than "
            "the world and everything in it. (Sahih Muslim)",
      ),
    ];

    return tips
        .map(
          (t) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.color.withOpacity(0.20), width: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: t.color.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(t.icon, size: 18, color: t.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: tp,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.body,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: ts,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}

class _Tip {
  final IconData icon;
  final Color color;
  final String title, body;
  const _Tip({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

// ═══════════════════════════════════════════════════════════════════
//  BOTTOM NAV
// ═══════════════════════════════════════════════════════════════════

class _BottomNav extends StatelessWidget {
  final int selected, unreadChat;
  final Color accentColor, bgColor, borderColor, textPrimary, textTertiary;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selected,
    required this.unreadChat,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textTertiary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(Icons.home_rounded, Icons.home_outlined, "Home"),
      _NavItem(Icons.chat_bubble_rounded, Icons.chat_bubble_outline, "AI Chat"),
      _NavItem(Icons.bookmark_rounded, Icons.bookmark_border, "Niyyah"),
      _NavItem(Icons.insights_rounded, Icons.insights_outlined, "Insights"),
    ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final sel = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        sel ? items[i].activeIcon : items[i].icon,
                        size: 24,
                        color: sel ? accentColor : textTertiary,
                      ),
                      if (i == 1 && unreadChat > 0)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.colorError,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel ? accentColor : textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon, icon;
  final String label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}

// ═══════════════════════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color, cardColor, borderColor, textPrimary, textSecondary;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: borderColor, width: 0.8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color, cardColor, borderColor, textPrimary, textSecondary;
  const _InsightCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.20), width: 0.8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color goldColor, textPrimary;
  const _SectionLabel({
    required this.label,
    required this.goldColor,
    required this.textPrimary,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 3,
        height: 16,
        decoration: BoxDecoration(
          color: goldColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
    ],
  );
}
