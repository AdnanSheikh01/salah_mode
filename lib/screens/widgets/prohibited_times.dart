import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

Widget prohibitedTimeCard(
  BuildContext context,
  PrayerTimes prayerTimes,
  String sunrise,
  String zawal,
  String sunset,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
  final goldColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccentGold;
  final textPrimary = isDark
      ? AppTheme.darkTextPrimary
      : AppTheme.lightTextPrimary;
  final textSecondary = isDark
      ? AppTheme.darkTextSecondary
      : AppTheme.lightTextSecondary;

  final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

  // ── Safe string fallback ───────────────────────────────────────
  String safeTime(String t) => t.trim().isEmpty ? "--:--" : t.trim();

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor, width: 0.8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header row ─────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.colorError.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.colorError.withOpacity(0.25),
                  width: 0.8,
                ),
              ),
              child: const Icon(
                Icons.block_rounded,
                size: 17,
                color: AppTheme.colorError,
              ),
            ),

            const SizedBox(width: 10),

            // Title — Flexible so it never overflows
            Expanded(
              child: Text(
                "Forbidden Times",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // MAKRUH badge — intrinsic size, never stretches
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.colorError.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.colorError.withOpacity(0.25),
                  width: 0.8,
                ),
              ),
              child: Text(
                "MAKRUH",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colorError,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // ── Three time rows ────────────────────────────────────
        _ProhibitedRow(
          label: "Sunrise (Shuruq)",
          time: safeTime(sunrise),
          textSecondary: textSecondary,
          borderColor: borderColor,
          showDivider: true,
        ),
        _ProhibitedRow(
          label: "Midday (Zawal)",
          time: safeTime(zawal),
          textSecondary: textSecondary,
          borderColor: borderColor,
          showDivider: true,
        ),
        _ProhibitedRow(
          label: "Sunset (Ghurub)",
          time: safeTime(sunset),
          textSecondary: textSecondary,
          borderColor: borderColor,
          showDivider: false,
        ),

        const SizedBox(height: 18),

        Divider(color: borderColor, thickness: 0.8),

        const SizedBox(height: 14),

        // ── Hadith label ───────────────────────────────────────
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
            Flexible(
              child: Text(
                "HADITH REFERENCE",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: goldColor,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Hadith text block ──────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Text(
            '"There were three times at which the Messenger of Allah (ﷺ) '
            'forbade us to pray, or to bury our dead: When the sun begins '
            'to rise till it is fully up, when the sun is at its height at '
            'midday till it passes over the meridian, and when the sun draws '
            'near to setting till it sets."',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: textSecondary,
              height: 1.7,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Source line ────────────────────────────────────────
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "✦  Sahih Muslim 831",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: goldColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  PROHIBITED TIME ROW  — widget class, never causes overflow
// ═══════════════════════════════════════════════════════════════════

class _ProhibitedRow extends StatelessWidget {
  final String label;
  final String time;
  final Color textSecondary;
  final Color borderColor;
  final bool showDivider;

  const _ProhibitedRow({
    required this.label,
    required this.time,
    required this.textSecondary,
    required this.borderColor,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon circle
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.colorError.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_toggle_off_rounded,
                  size: 15,
                  color: AppTheme.colorError,
                ),
              ),

              const SizedBox(width: 10),

              // Label — Flexible: shrinks before time pill overflows
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Time pill — intrinsic width, never wraps
              Container(
                constraints: const BoxConstraints(minWidth: 80, maxWidth: 130),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.colorError.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.colorError.withOpacity(0.20),
                    width: 0.8,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    time,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.colorError,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (showDivider)
          Divider(
            color: borderColor.withOpacity(0.5),
            thickness: 0.8,
            height: 1,
          ),
      ],
    );
  }
}
