import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

class DuaDetailScreen extends StatelessWidget {
  final Map<String, String> dua;

  const DuaDetailScreen({super.key, required this.dua});

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

    final name = (dua['name'] ?? '').trim();
    final arabic = (dua['arabic'] ?? '').trim();
    final transliteration = (dua['english'] ?? dua['transliteration'] ?? '')
        .trim();
    final translation = (dua['translation'] ?? '').trim();
    final when = (dua['when'] ?? '').trim();
    final reference = (dua['reference'] ?? '').trim();
    final refNo = (dua['refNo'] ?? '').trim();
    final refFull = [reference, refNo].where((s) => s.isNotEmpty).join(' ');

    void copyToClipboard() {
      try {
        final parts = <String>[];
        if (arabic.isNotEmpty) parts.add(arabic);
        if (transliteration.isNotEmpty) parts.add(transliteration);
        if (translation.isNotEmpty) parts.add(translation);
        if (refFull.isNotEmpty) parts.add('— $refFull');
        Clipboard.setData(ClipboardData(text: parts.join('\n\n')));
        Get.snackbar(
          "Copied ✦",
          "Dua copied to clipboard",
          backgroundColor: accentColor,
          colorText: btnTextColor,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        debugPrint("Copy error: $e");
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentColor, size: 20),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
            Text(
              "دعاء",
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 12,
                color: goldColor,
                height: 1.3,
              ),
            ),
          ],
        ),
        actions: [
          // Copy button in AppBar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: copyToClipboard,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withOpacity(0.25),
                    width: 0.8,
                  ),
                ),
                child: Icon(Icons.copy_rounded, size: 16, color: accentColor),
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── "When to recite" pill ───────────────────────────
            if (when.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accentColor.withOpacity(0.20),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.schedule_rounded, size: 15, color: accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        when,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Arabic card ──────────────────────────────────────
            if (arabic.isNotEmpty) ...[
              _SectionLabel(
                label: "Arabic",
                sub: "العربية",
                goldColor: goldColor,
                textPrimary: textPrimary,
              ),
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
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
                    // Gold ornament
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 0.7,
                          color: goldColor.withOpacity(0.35),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "✦",
                          style: TextStyle(fontSize: 11, color: goldColor),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 0.7,
                          color: goldColor.withOpacity(0.35),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Text(
                      arabic,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 26,
                        color: goldColor,
                        height: 2.0,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Copy arabic only button
                    GestureDetector(
                      onTap: () {
                        try {
                          Clipboard.setData(ClipboardData(text: arabic));
                          Get.snackbar(
                            "Copied",
                            "Arabic text copied",
                            backgroundColor: accentColor,
                            colorText: btnTextColor,
                            margin: const EdgeInsets.all(16),
                            borderRadius: 12,
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                          );
                        } catch (_) {}
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: goldColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: goldColor.withOpacity(0.22),
                            width: 0.7,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 12,
                              color: goldColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Copy Arabic",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: goldColor,
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
            ],

            // ── Transliteration ──────────────────────────────────
            if (transliteration.isNotEmpty) ...[
              _SectionLabel(
                label: "Transliteration",
                sub: "النطق",
                goldColor: goldColor,
                textPrimary: textPrimary,
              ),
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardAltColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Text(
                  transliteration,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: textPrimary,
                    height: 1.7,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Translation ──────────────────────────────────────
            if (translation.isNotEmpty) ...[
              _SectionLabel(
                label: "Translation",
                sub: "الترجمة",
                goldColor: goldColor,
                textPrimary: textPrimary,
              ),
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Text(
                  translation,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: textPrimary,
                    height: 1.68,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Reference ────────────────────────────────────────
            if (refFull.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: goldColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: goldColor.withOpacity(0.18),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 14,
                      color: goldColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        refFull,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Copy all button ──────────────────────────────────
            GestureDetector(
              onTap: copyToClipboard,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy_all_rounded, size: 18, color: btnTextColor),
                    const SizedBox(width: 9),
                    Text(
                      "Copy Full Dua",
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

            const SizedBox(height: 16),

            // ── Tip card ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentColor.withOpacity(0.15),
                  width: 0.8,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: accentColor.withOpacity(0.70),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Recite this dua with full presence of heart (khushu). "
                      "The best times are after Fajr, before sleep, and in sujood.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SECTION LABEL
// ═══════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label, sub;
  final Color goldColor, textPrimary;

  const _SectionLabel({
    required this.label,
    required this.sub,
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
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        sub,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 14,
          color: goldColor,
          height: 1.2,
        ),
      ),
    ],
  );
}
