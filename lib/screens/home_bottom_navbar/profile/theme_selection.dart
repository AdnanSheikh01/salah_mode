import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectionThemePage extends StatefulWidget {
  const SelectionThemePage({super.key});

  @override
  State<SelectionThemePage> createState() => _SelectionThemePageState();
}

class _SelectionThemePageState extends State<SelectionThemePage> {
  ThemeMode _mode = ThemeMode.system;
  bool _loading = true;

  static const _kThemeKey = 'app_theme_mode';

  @override
  void initState() {
    super.initState();
    _loadSavedTheme();
  }

  // ─────────────────────────────────────────────────────────────
  //  PERSISTENCE
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kThemeKey);
      ThemeMode mode = ThemeMode.system;
      if (saved == 'light') mode = ThemeMode.light;
      if (saved == 'dark') mode = ThemeMode.dark;
      if (mounted)
        setState(() {
          _mode = mode;
          _loading = false;
        });
    } catch (e) {
      debugPrint("Theme load error: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applyTheme(ThemeMode mode) async {
    setState(() => _mode = mode);
    Get.changeThemeMode(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
          ? 'dark'
          : 'system';
      await prefs.setString(_kThemeKey, value);
    } catch (e) {
      debugPrint("Theme save error: $e");
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Re-read theme on every build so switching reflects immediately
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
          "Appearance",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),

      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: accentColor,
                backgroundColor: accentColor.withOpacity(0.15),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Current mode preview ─────────────────────
                  _ModePreviewCard(
                    isDark: isDark,
                    currentMode: _mode,
                    accentColor: accentColor,
                    goldColor: goldColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    btnTextColor: btnTextColor,
                  ),

                  const SizedBox(height: 24),

                  // ── Section label ────────────────────────────
                  Row(
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
                        "Choose Theme",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Theme options ────────────────────────────
                  _ThemeCard(
                    title: "System Default",
                    subtitle: "Follows your device appearance automatically",
                    icon: Icons.brightness_auto_rounded,
                    selected: _mode == ThemeMode.system,
                    accentColor: accentColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textTertiary: textTertiary,
                    btnTextColor: btnTextColor,
                    previewColors: const [Color(0xFF1A6B45), Color(0xFFC8A84B)],
                    onTap: () => _applyTheme(ThemeMode.system),
                  ),

                  const SizedBox(height: 12),

                  _ThemeCard(
                    title: "Light Mode",
                    subtitle: "Warm parchment — ideal for daytime reading",
                    icon: Icons.wb_sunny_rounded,
                    selected: _mode == ThemeMode.light,
                    accentColor: accentColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textTertiary: textTertiary,
                    btnTextColor: btnTextColor,
                    previewColors: const [
                      Color(0xFFF5F0E8),
                      Color(0xFF1A6B45),
                      Color(0xFF8B6914),
                    ],
                    onTap: () => _applyTheme(ThemeMode.light),
                  ),

                  const SizedBox(height: 12),

                  _ThemeCard(
                    title: "Dark Mode",
                    subtitle: "Deep forest emerald — easy on eyes at night",
                    icon: Icons.nightlight_round,
                    selected: _mode == ThemeMode.dark,
                    accentColor: accentColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textTertiary: textTertiary,
                    btnTextColor: btnTextColor,
                    previewColors: const [
                      Color(0xFF0E1A14),
                      Color(0xFFC8A84B),
                      Color(0xFF152B1E),
                    ],
                    onTap: () => _applyTheme(ThemeMode.dark),
                  ),

                  const SizedBox(height: 28),

                  // ── Tip card ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: goldColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: goldColor.withOpacity(0.18),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "✦ ",
                          style: TextStyle(
                            fontSize: 12,
                            color: goldColor,
                            height: 1.5,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Dark Mode is recommended for Tahajjud and late night prayers "
                            "to protect your eyesight and preserve your night vision.",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
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
//  CURRENT MODE PREVIEW CARD
// ═══════════════════════════════════════════════════════════════════

class _ModePreviewCard extends StatelessWidget {
  final bool isDark;
  final ThemeMode currentMode;
  final Color accentColor, goldColor, cardColor, borderColor;
  final Color textPrimary, textSecondary, btnTextColor;

  const _ModePreviewCard({
    required this.isDark,
    required this.currentMode,
    required this.accentColor,
    required this.goldColor,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.btnTextColor,
  });

  String get _modeLabel {
    switch (currentMode) {
      case ThemeMode.light:
        return "Light Mode";
      case ThemeMode.dark:
        return "Dark Mode";
      case ThemeMode.system:
        return "System Default";
    }
  }

  IconData get _modeIcon {
    switch (currentMode) {
      case ThemeMode.light:
        return Icons.wb_sunny_rounded;
      case ThemeMode.dark:
        return Icons.nightlight_round;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
            child: Icon(_modeIcon, color: btnTextColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Active Theme",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: btnTextColor.withOpacity(0.70),
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _modeLabel,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: btnTextColor,
                  ),
                ),
              ],
            ),
          ),
          // Mini palette preview
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ColorDot(
                    color: isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg,
                  ),
                  const SizedBox(width: 4),
                  _ColorDot(
                    color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                  ),
                  const SizedBox(width: 4),
                  _ColorDot(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                isDark ? "صلاة" : "صلاة",
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  color: btnTextColor.withOpacity(0.80),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withOpacity(0.30), width: 1),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  THEME OPTION CARD
// ═══════════════════════════════════════════════════════════════════

class _ThemeCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool selected;
  final List<Color> previewColors;
  final Color accentColor, cardColor, borderColor;
  final Color textPrimary, textSecondary, textTertiary, btnTextColor;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.previewColors,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.btnTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? accentColor.withOpacity(0.08) : cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accentColor.withOpacity(0.50) : borderColor,
            width: selected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            // Icon circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? accentColor : accentColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected ? btnTextColor : accentColor,
              ),
            ),

            const SizedBox(width: 14),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: selected ? accentColor : textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Color swatch preview
                  Row(
                    children: [
                      ...previewColors.map(
                        (c) => Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor, width: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Check / unselected indicator
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? Container(
                      key: const ValueKey('check'),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: btnTextColor,
                      ),
                    )
                  : Container(
                      key: const ValueKey('empty'),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
