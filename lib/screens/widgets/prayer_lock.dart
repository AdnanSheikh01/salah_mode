import 'package:flutter/material.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

Widget prayerLockCard(
  BuildContext context,
  bool prayerLockEnabled,
  int lockMinutes,
  Function(bool) onToggle,
  Function(int) onDurationChange,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
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

  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor, width: 0.8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ─────────────────────────────────────────
        Row(
          children: [
            // Icon pill
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withOpacity(0.25),
                  width: 0.8,
                ),
              ),
              child: Icon(
                Icons.lock_clock_rounded,
                color: accentColor,
                size: 18,
              ),
            ),

            const SizedBox(width: 12),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Prayer Focus Mode",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    "Block apps when Salah time occurs",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: textSecondary.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),

            // Switch
            Transform.scale(
              scale: 0.9,
              child: Switch(
                value: prayerLockEnabled,
                onChanged: onToggle,
                activeColor: isDark
                    ? AppTheme.darkTextOnAccent
                    : AppTheme.lightTextOnAccent,
                activeTrackColor: accentColor,
                inactiveThumbColor: textSecondary.withOpacity(0.5),
                inactiveTrackColor: borderColor,
                trackOutlineColor: MaterialStateProperty.all(
                  Colors.transparent,
                ),
              ),
            ),
          ],
        ),

        // ── Duration picker (shown when enabled) ───────────────
        if (prayerLockEnabled) ...[
          const SizedBox(height: 14),

          Divider(color: borderColor, thickness: 0.8),

          const SizedBox(height: 12),

          Text(
            "Lock phone after Adhan for:",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),

          const SizedBox(height: 12),

          // Duration chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [5, 10, 15, 20, 30]
                .map(
                  (mins) => _durationChip(
                    context: context,
                    minutes: mins,
                    selected: lockMinutes == mins,
                    onSelected: onDurationChange,
                    accentColor: accentColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textSecondary: textSecondary,
                    btnTextColor: btnTextColor,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    ),
  );
}

// ── Duration chip ──────────────────────────────────────────────────
Widget _durationChip({
  required BuildContext context,
  required int minutes,
  required bool selected,
  required Function(int) onSelected,
  required Color accentColor,
  required Color cardColor,
  required Color borderColor,
  required Color textSecondary,
  required Color btnTextColor,
}) {
  return GestureDetector(
    onTap: () => onSelected(minutes),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? accentColor : cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? accentColor : borderColor,
          width: selected ? 0 : 0.8,
        ),
      ),
      child: Text(
        "$minutes min",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? btnTextColor : textSecondary,
        ),
      ),
    ),
  );
}
