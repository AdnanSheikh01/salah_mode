import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/quran/surah_list.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tasbih/tasbih.dart';
import 'package:salah_mode/screens/utils/salah_step.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

class PrayerGuideScreen extends StatefulWidget {
  const PrayerGuideScreen({super.key});
  @override
  State<PrayerGuideScreen> createState() => _PrayerGuideScreenState();
}

class _PrayerGuideScreenState extends State<PrayerGuideScreen>
    with TickerProviderStateMixin {
  int _step = 0;

  // ── Slide + fade transition ────────────────────────────────────
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _buildAnims(forward: true);
  }

  void _buildAnims({required bool forward}) {
    _slideAnim = Tween<Offset>(
      begin: Offset(forward ? 0.16 : -0.16, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward(from: 0);
  }

  // ── Safe accessors ─────────────────────────────────────────────
  int get _total => steps.isEmpty ? 1 : steps.length;
  Map<String, String> get _current {
    try {
      return steps[_step.clamp(0, steps.length - 1)];
    } catch (_) {
      return {};
    }
  }

  String _f(String k) => _current[k] ?? '';

  void _next() {
    if (_step < _total - 1) {
      _buildAnims(forward: true);
      setState(() => _step++);
    } else {
      Get.back();
    }
  }

  void _prev() {
    if (_step > 0) {
      _buildAnims(forward: false);
      setState(() => _step--);
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

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
    final btnTextColor = isDark
        ? AppTheme.darkTextOnAccent
        : AppTheme.lightTextOnAccent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentColor, size: 20),
        title: Text(
          "Prayer Guide",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            children: [
              // ── Progress header ──────────────────────────────────
              _ProgressHeader(
                step: _step,
                total: _total,
                stepTitle: _f('title'),
                position: _f('position'),
                progress: (_step + 1) / _total,
                accentColor: accentColor,
                goldColor: goldColor,
                textPrimary: textPrimary,
                textTertiary: textTertiary,
                borderColor: borderColor,
                cardAltColor: cardAltColor,
              ),

              const SizedBox(height: 12),

              // ── Animated step content ────────────────────────────
              Expanded(
                child: SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _StepCard(
                      stepData: _current,
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
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Navigation ───────────────────────────────────────
              _NavRow(
                step: _step,
                total: _total,
                accentColor: accentColor,
                btnTextColor: btnTextColor,
                borderColor: borderColor,
                textTertiary: textTertiary,
                onPrev: _prev,
                onNext: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PROGRESS HEADER
// ═══════════════════════════════════════════════════════════════════

class _ProgressHeader extends StatelessWidget {
  final int step, total;
  final String stepTitle, position;
  final double progress;
  final Color accentColor,
      goldColor,
      textPrimary,
      textTertiary,
      borderColor,
      cardAltColor;

  const _ProgressHeader({
    required this.step,
    required this.total,
    required this.stepTitle,
    required this.position,
    required this.progress,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textTertiary,
    required this.borderColor,
    required this.cardAltColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                stepTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Position badge
                if (position.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: goldColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: goldColor.withOpacity(0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      position,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: goldColor,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accentColor.withOpacity(0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    "${step + 1} / $total",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Progress bar with moving dot
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: borderColor,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              alignment: Alignment((progress * 2 - 1).clamp(-1.0, 1.0), 0),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withOpacity(0.35),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Step indicator dots
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              total,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: i == step ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i <= step ? accentColor : borderColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STEP CONTENT CARD
// ═══════════════════════════════════════════════════════════════════

class _StepCard extends StatelessWidget {
  final Map<String, String> stepData;
  final Color cardColor, cardAltColor, accentColor, goldColor;
  final Color textPrimary,
      textSecondary,
      textTertiary,
      borderColor,
      btnTextColor;
  final bool isDark;

  const _StepCard({
    required this.stepData,
    required this.cardColor,
    required this.cardAltColor,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderColor,
    required this.btnTextColor,
    required this.isDark,
  });

  String _f(String k) => stepData[k] ?? '';
  bool get _isAfterSalah => _f('title') == "After Salah Dhikr";

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Image ───────────────────────────────────────────
            _SafeImage(
              key: ValueKey(_f('image')),
              path: _f('image'),
              accentColor: accentColor,
            ),

            const SizedBox(height: 14),

            // ── Gold ornament divider ────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 0.7,
                  color: goldColor.withOpacity(0.35),
                ),
                const SizedBox(width: 8),
                Text("✦", style: TextStyle(fontSize: 11, color: goldColor)),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 0.7,
                  color: goldColor.withOpacity(0.35),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Title ────────────────────────────────────────────
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _f('title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Main Arabic ──────────────────────────────────────
            if (_f('arabic').isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accentColor.withOpacity(0.16),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  _f('arabic'),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 24,
                    color: goldColor,
                    height: 1.8,
                  ),
                ),
              ),

            if (_f('translation').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _f('translation'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Duas block ───────────────────────────────────────
            if (_f('dua').isNotEmpty)
              _DuasBlock(
                dua: _f('dua'),
                duaTranslation: _f('duaTranslation'),
                isAfterSalah: _isAfterSalah,
                cardAltColor: cardAltColor,
                accentColor: accentColor,
                goldColor: goldColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                borderColor: borderColor,
                btnTextColor: btnTextColor,
              ),

            // ── Surah Al-Fatiha ──────────────────────────────────
            if (_f('fatihaArabic').isNotEmpty)
              _FatihaBlock(
                arabic: _f('fatihaArabic'),
                translation: _f('fatihaTranslation'),
                cardAltColor: cardAltColor,
                accentColor: accentColor,
                goldColor: goldColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                borderColor: borderColor,
                btnTextColor: btnTextColor,
              ),

            const SizedBox(height: 14),

            // ── Description ──────────────────────────────────────
            if (_f('desc').isNotEmpty)
              Text(
                _f('desc'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: textSecondary,
                  height: 1.55,
                ),
              ),

            const SizedBox(height: 14),

            // ── Hadith block ─────────────────────────────────────
            if (_f('hadith').isNotEmpty)
              _HadithBlock(
                hadith: _f('hadith'),
                cardAltColor: cardAltColor,
                goldColor: goldColor,
                textSecondary: textSecondary,
                borderColor: borderColor,
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SAFE IMAGE
// ═══════════════════════════════════════════════════════════════════

class _SafeImage extends StatelessWidget {
  final String path;
  final Color accentColor;
  const _SafeImage({super.key, required this.path, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return Icon(
        Icons.self_improvement_rounded,
        size: 80,
        color: accentColor.withOpacity(0.30),
      );
    }
    return Image.asset(
      path,
      height: 150,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.self_improvement_rounded,
        size: 80,
        color: accentColor.withOpacity(0.30),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DUAS BLOCK
// ═══════════════════════════════════════════════════════════════════

class _DuasBlock extends StatelessWidget {
  final String dua, duaTranslation;
  final bool isAfterSalah;
  final Color cardAltColor, accentColor, goldColor;
  final Color textPrimary, textSecondary, borderColor, btnTextColor;

  const _DuasBlock({
    required this.dua,
    required this.duaTranslation,
    required this.isAfterSalah,
    required this.cardAltColor,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.btnTextColor,
  });

  @override
  Widget build(BuildContext context) {
    // Split on double newline, preserving non-empty blocks
    final duas = dua
        .split('\n\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final translations = duaTranslation
        .split('\n\n')
        .map((s) => s.trim())
        .toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: cardAltColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isAfterSalah ? "Post-Salah Dhikr" : "Dua in Salah",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...List.generate(duas.length, (i) {
            final duaText = duas[i];
            final t = i < translations.length ? translations[i] : '';
            // Detect Ayat-ul-Kursi block
            final isAyatKursi =
                duaText.contains('آيَةُ الْكُرْسِيِّ') ||
                duaText.contains('اللّٰهُ لَا إِلَٰهَ');
            // Detect tasbih block
            final isTasbih =
                isAfterSalah &&
                (duaText.contains('سُبْحَانَ اللّٰهِ') ||
                    duaText.contains('×'));

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Arabic text — right-aligned
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      duaText,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: isAyatKursi ? 'Amiri' : 'Amiri',
                        fontSize: isAyatKursi ? 18 : 20,
                        color: goldColor,
                        height: 1.9,
                      ),
                    ),
                  ),

                  // Translation
                  if (t.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      t,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],

                  // Tasbih counter shortcut
                  if (isTasbih) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        try {
                          Get.to(() => const TasbihPage());
                        } catch (e) {
                          debugPrint("TasbihPage error: $e");
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.radio_button_checked_rounded,
                              size: 15,
                              color: btnTextColor,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              "Open Tasbih Counter",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: btnTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Divider between blocks
                  if (i < duas.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Divider(
                        color: borderColor,
                        height: 1,
                        thickness: 0.8,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FATIHA BLOCK
// ═══════════════════════════════════════════════════════════════════

class _FatihaBlock extends StatelessWidget {
  final String arabic, translation;
  final Color cardAltColor, accentColor, goldColor;
  final Color textPrimary, textSecondary, borderColor, btnTextColor;

  const _FatihaBlock({
    required this.arabic,
    required this.translation,
    required this.cardAltColor,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.btnTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: cardAltColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goldColor.withOpacity(0.28), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: goldColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Surah Al-Fatiha",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: goldColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Arabic — line by line for readability
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                color: goldColor,
                height: 1.9,
              ),
            ),
          ),

          if (translation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              translation,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: textSecondary,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Open Quran shortcut
          GestureDetector(
            onTap: () {
              try {
                Get.to(() => const SurahListPage());
              } catch (e) {
                debugPrint("SurahListPage error: $e");
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: goldColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: goldColor.withOpacity(0.25),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_rounded, size: 15, color: goldColor),
                  const SizedBox(width: 8),
                  Text(
                    "Recite another Surah",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: goldColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HADITH BLOCK
// ═══════════════════════════════════════════════════════════════════

class _HadithBlock extends StatelessWidget {
  final String hadith;
  final Color cardAltColor, goldColor, textSecondary, borderColor;

  const _HadithBlock({
    required this.hadith,
    required this.cardAltColor,
    required this.goldColor,
    required this.textSecondary,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: cardAltColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goldColor.withOpacity(0.20), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: goldColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Hadith Reference",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: goldColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hadith,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: textSecondary,
              height: 1.65,
              fontStyle: FontStyle.italic,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "✦",
                style: TextStyle(
                  fontSize: 11,
                  color: goldColor.withOpacity(0.50),
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
//  NAVIGATION ROW
// ═══════════════════════════════════════════════════════════════════

class _NavRow extends StatelessWidget {
  final int step, total;
  final Color accentColor, btnTextColor, borderColor, textTertiary;
  final VoidCallback onPrev, onNext;

  const _NavRow({
    required this.step,
    required this.total,
    required this.accentColor,
    required this.btnTextColor,
    required this.borderColor,
    required this.textTertiary,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = step == 0;
    final isLast = step == total - 1;

    return Row(
      children: [
        // Previous
        GestureDetector(
          onTap: isFirst ? null : onPrev,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            decoration: BoxDecoration(
              color: isFirst
                  ? borderColor.withOpacity(0.35)
                  : accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isFirst
                    ? borderColor.withOpacity(0.4)
                    : accentColor.withOpacity(0.30),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 13,
                  color: isFirst ? borderColor : accentColor,
                ),
                const SizedBox(width: 5),
                Text(
                  "Prev",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isFirst ? borderColor : accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Step fraction
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${step + 1} / $total",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accentColor.withOpacity(0.60),
                ),
              ),
              Text(
                steps.isNotEmpty &&
                        step < steps.length &&
                        (steps[step]['position'] ?? '').isNotEmpty
                    ? steps[step]['position']!
                    : '',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: textTertiary.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),

        // Next / Done
        GestureDetector(
          onTap: onNext,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLast ? "Done ✦" : "Next",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: btnTextColor,
                  ),
                ),
                if (!isLast) ...[
                  const SizedBox(width: 5),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: btnTextColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
