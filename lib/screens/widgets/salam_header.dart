import 'package:flutter/material.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

Widget salamHeader(BuildContext context, String userName) {
  final hour = DateTime.now().hour;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // ── Theme-aware colors ─────────────────────────────────────────
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

  // ── Time-based greeting ────────────────────────────────────────
  final String greeting;
  final IconData timeIcon;
  final String arabicGreeting;

  if (hour >= 5 && hour < 12) {
    greeting = "Good Morning";
    timeIcon = Icons.wb_twilight_rounded;
    arabicGreeting = "صَبَاحُ الْخَيْرِ";
  } else if (hour >= 12 && hour < 17) {
    greeting = "Good Afternoon";
    timeIcon = Icons.wb_sunny_rounded;
    arabicGreeting = "السَّلَامُ عَلَيْكُمْ";
  } else if (hour >= 17 && hour < 21) {
    greeting = "Good Evening";
    timeIcon = Icons.nights_stay_rounded;
    arabicGreeting = "مَسَاءُ الْخَيْرِ";
  } else {
    greeting = "Good Night";
    timeIcon = Icons.bedtime_rounded;
    arabicGreeting = "تُصْبِحُ عَلَى خَيْرٍ";
  }

  final bool hasName = userName.trim().isNotEmpty;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor, width: 0.8),
    ),
    child: Row(
      children: [
        // ── Time icon circle ───────────────────────────────────
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.10),
            shape: BoxShape.circle,
            border: Border.all(
              color: accentColor.withOpacity(0.28),
              width: 0.8,
            ),
          ),
          child: Icon(timeIcon, color: accentColor, size: 22),
        ),

        const SizedBox(width: 14),

        // ── Greeting text ──────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Arabic greeting (small, gold)
              Text(
                arabicGreeting,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: hasName ? 12 : 16,
                  color: goldColor,
                  height: 1.4,
                  letterSpacing: 0.5,
                ),
              ),

              if (hasName) ...[
                const SizedBox(height: 2),
                // "Assalamu Alaikum" label
                Text(
                  "Assalamu Alaikum",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: accentColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 1),
                // User name
                Text(
                  userName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    height: 1.2,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 2),
                Text(
                  "Assalamu Alaikum",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 10),

        // ── Greeting pill (top-right) ──────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withOpacity(0.20),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(timeIcon, size: 11, color: accentColor.withOpacity(0.80)),
              const SizedBox(width: 4),
              Text(
                greeting,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: accentColor.withOpacity(0.85),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
