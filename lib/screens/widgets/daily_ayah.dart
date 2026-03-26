import 'package:flutter/material.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

Widget dailyAyah(
  BuildContext context,
  VoidCallback dailyAyahRefresh,
  bool ayahLoading,
  String ayahText,
  String ayahRef,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
  final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
  final goldColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccentGold;
  final textPrimary = isDark
      ? AppTheme.darkTextPrimary
      : AppTheme.lightTextPrimary;
  final textTertiary = isDark
      ? AppTheme.darkTextTertiary
      : AppTheme.lightTextTertiary;
  final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor, width: 0.8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ─────────────────────────────────────────
        Row(
          children: [
            // Gold icon circle
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: goldColor.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: goldColor.withOpacity(0.25),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Text(
                  "✦",
                  style: TextStyle(fontSize: 13, color: goldColor, height: 1),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DAILY AYAH",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: goldColor,
                      letterSpacing: 1.6,
                    ),
                  ),
                  Text(
                    "Quran — Word of Allah",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // Refresh button
            GestureDetector(
              onTap: dailyAyahRefresh,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withOpacity(0.20),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Divider(color: borderColor, thickness: 0.8),

        const SizedBox(height: 16),

        // ── Content ────────────────────────────────────────────
        if (ayahLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accentColor,
                backgroundColor: accentColor.withOpacity(0.15),
              ),
            ),
          )
        else ...[
          // Ayah text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: goldColor.withOpacity(0.18),
                width: 0.8,
              ),
            ),
            child: Text(
              '"$ayahText"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: textPrimary,
                height: 1.75,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Reference line
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "✦  $ayahRef",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: goldColor,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
