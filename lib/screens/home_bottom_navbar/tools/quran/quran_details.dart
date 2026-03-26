import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:salah_mode/screens/home_bottom_navbar/tools/quran/quran_memorise/quran_memorize.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/quran/quran_read.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

class QuranDetailsScreen extends StatefulWidget {
  const QuranDetailsScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.totalAyahs,
    required this.revelationType,
  });

  final int surahNumber;
  final String surahName;
  final int totalAyahs;
  final String revelationType;

  @override
  State<QuranDetailsScreen> createState() => _QuranDetailsScreenState();
}

class _QuranDetailsScreenState extends State<QuranDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  bool _loading = true;
  bool _hasError = false;
  String _errorMsg = '';

  List<Map<String, dynamic>> _ayahs = [];
  int _totalWords = 0;
  int _juzStart = 0;

  static const _base = 'https://api.alquran.cloud/v1/surah';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetchAyahs();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  FETCH  — parallel requests, single timeout, graceful error
  // ─────────────────────────────────────────────────────────────

  Future<void> _fetchAyahs() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
      _errorMsg = '';
    });

    try {
      final n = widget.surahNumber;

      // Fire all 3 requests in parallel
      final results = await Future.wait([
        http.get(Uri.parse('$_base/$n/ar.quran-uthmani')),
        http.get(Uri.parse('$_base/$n/en.asad')),
        http.get(Uri.parse('$_base/$n/hi.hindi')),
      ]).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      final arRes = results[0];
      final enRes = results[1];
      final hiRes = results[2];

      // Check status codes
      if (arRes.statusCode != 200) {
        _setError('Arabic text unavailable (status ${arRes.statusCode}).');
        return;
      }
      if (enRes.statusCode != 200) {
        _setError(
          'English translation unavailable (status ${enRes.statusCode}).',
        );
        return;
      }
      // Hindi is optional — don't fail if it's missing
      final hiOk = hiRes.statusCode == 200;

      // Decode
      final arData = json.decode(arRes.body) as Map<String, dynamic>;
      final enData = json.decode(enRes.body) as Map<String, dynamic>;
      final hiData = hiOk
          ? json.decode(hiRes.body) as Map<String, dynamic>
          : null;

      final List arAyahs = arData['data']['ayahs'] as List;
      final List enAyahs = enData['data']['ayahs'] as List;
      final List hiAyahs = hiOk
          ? (hiData!['data']['ayahs'] as List)
          : List.filled(arAyahs.length, null);

      if (arAyahs.isEmpty) {
        _setError('No ayahs found for this surah.');
        return;
      }

      // Count total words across all Arabic ayahs
      int words = 0;
      for (final a in arAyahs) {
        words += (a['text'] as String? ?? '').trim().split(' ').length;
      }

      _ayahs = List.generate(
        arAyahs.length,
        (i) => {
          'arabic': (arAyahs[i]['text'] ?? '').toString(),
          'english': (enAyahs[i]['text'] ?? '').toString(),
          'hindi': (hiAyahs[i]?['text'] ?? '').toString(),
          'ayahNumber': arAyahs[i]['numberInSurah'] ?? (i + 1),
          'juz': arAyahs[i]['juz'] ?? 0,
          'ruku': arAyahs[i]['ruku'] ?? 0,
        },
      );

      _totalWords = words;
      _juzStart = (_ayahs.isNotEmpty ? _ayahs.first['juz'] as int? : null) ?? 0;

      if (mounted) setState(() => _loading = false);
    } on TimeoutException {
      _setError('Request timed out. Check your connection and try again.');
    } on http.ClientException catch (e) {
      _setError('Network error: ${e.message}');
    } on FormatException {
      _setError('Unexpected response from server.');
    } catch (e) {
      debugPrint("QuranDetails fetch error: $e");
      _setError('Could not load surah. Please try again.');
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _hasError = true;
      _errorMsg = msg;
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: accentColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: btnTextColor, size: 20),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.surahName,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: btnTextColor,
                ),
              ),
            ),
            Text(
              "سورة ${widget.surahNumber}",
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 12,
                color: btnTextColor.withOpacity(0.80),
                height: 1.3,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: btnTextColor,
          unselectedLabelColor: btnTextColor.withOpacity(0.55),
          indicatorColor: btnTextColor,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: accentColor, // same as bg = invisible divider
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded), text: 'Read'),
            Tab(icon: Icon(Icons.psychology_alt_rounded), text: 'Memorise'),
          ],
        ),
      ),

      body: _loading
          ? _LoadingView(accentColor: accentColor, textSecondary: textSecondary)
          : _hasError
          ? _ErrorView(
              message: _errorMsg,
              accentColor: accentColor,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              btnTextColor: btnTextColor,
              onRetry: _fetchAyahs,
            )
          : Column(
              children: [
                // ── Surah info strip ──────────────────────────
                Container(
                  color: bgColor,
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _InfoChip(
                        label: '${widget.totalAyahs} Ayahs',
                        icon: Icons.format_list_numbered_rounded,
                        accentColor: accentColor, // ← was color: btnTextColor
                      ),
                      _InfoChip(
                        label: widget.revelationType,
                        icon: widget.revelationType.toLowerCase() == 'meccan'
                            ? Icons.location_on_rounded
                            : Icons.mosque_rounded,
                        accentColor: accentColor, // ← was color: btnTextColor
                      ),
                      if (_juzStart > 0)
                        _InfoChip(
                          label: 'Juz $_juzStart',
                          icon: Icons.bookmark_rounded,
                          accentColor: accentColor, // ← was color: btnTextColor
                        ),
                      _InfoChip(
                        label: '$_totalWords words',
                        icon: Icons.text_fields_rounded,
                        accentColor: accentColor, // ← words chip uses gold
                      ),
                    ],
                  ),
                ),

                // ── Tab content ───────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      QuranReadPage(
                        surahName: widget.surahName,
                        surahNumber: widget.surahNumber,
                        totalAyahs: widget.totalAyahs,
                        revelationType: widget.revelationType,
                        totalWords: _totalWords,
                        ayahs: _ayahs,
                      ),
                      QuranMemoriseScreen(
                        ayahs: _ayahs,
                        surahName: widget.surahName,
                        surahNumber: widget.surahNumber,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  INFO CHIP  (used in surah strip)
// ═══════════════════════════════════════════════════════════════════

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor; // ← was: color

  const _InfoChip({
    required this.label,
    required this.icon,
    required this.accentColor, // ← was: color
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.10), // tinted bg
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.28), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accentColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  LOADING VIEW
// ═══════════════════════════════════════════════════════════════════

class _LoadingView extends StatelessWidget {
  final Color accentColor, textSecondary;
  const _LoadingView({required this.accentColor, required this.textSecondary});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          strokeWidth: 2.5,
          color: accentColor,
          backgroundColor: accentColor.withOpacity(0.15),
        ),
        const SizedBox(height: 16),
        Text(
          "Loading Surah...",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Fetching Arabic, English & Hindi",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: textSecondary.withOpacity(0.60),
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  ERROR VIEW
// ═══════════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  final String message;
  final Color accentColor, cardColor, borderColor;
  final Color textPrimary, textSecondary, btnTextColor;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.btnTextColor,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.colorError.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.colorError.withOpacity(0.25),
                width: 0.8,
              ),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AppTheme.colorError,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "Could Not Load Surah",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 17, color: btnTextColor),
                  const SizedBox(width: 8),
                  Text(
                    "Try Again",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: btnTextColor,
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
