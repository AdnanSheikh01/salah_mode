import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salah_mode/screens/home_bottom_navbar/home.dart';
import 'package:salah_mode/screens/home_bottom_navbar/leaderboard_screen.dart';
import 'package:salah_mode/screens/home_bottom_navbar/profile/profile.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/tools.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tasbih/tasbih.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

class SalahMainScreen extends StatefulWidget {
  const SalahMainScreen({super.key});

  @override
  State<SalahMainScreen> createState() => _SalahMainScreenState();
}

class _SalahMainScreenState extends State<SalahMainScreen> {
  int _currentIndex = 0;
  DateTime? _lastPressed;

  final _pages = const [
    HomePage(),
    TasbihPage(),
    ToolsScreen(),
    LeaderboardScreen(),
    ProfilePage(),
  ];

  // ── Time-based dua for exit dialog ────────────────────────────
  ({String arabic, String transliteration, String translation}) _getDua() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return (
        arabic:
            "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ",
        transliteration:
            "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur",
        translation:
            "Praise be to Allah who gave us life after He had given us death",
      );
    } else if (hour >= 12 && hour < 17) {
      return (
        arabic: "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ",
        transliteration: "Ya Hayyu Ya Qayyum, bi-rahmatika astagheeth",
        translation:
            "O Ever-Living, O Self-Sustaining, by Your mercy I seek help",
      );
    } else if (hour >= 17 && hour < 21) {
      return (
        arabic: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ",
        transliteration: "Amsayna wa amsal-mulku lillah",
        translation: "Evening has come and the Kingdom belongs to Allah",
      );
    } else {
      return (
        arabic: "اللَّهُمَّ بِاسْمِكَ أَمُوتُ وَأَحْيَا",
        transliteration: "Allahumma bismika amutu wa ahya",
        translation: "O Allah, in Your name I die and I live",
      );
    }
  }

  void _showExitDialog() {
    HapticFeedback.heavyImpact();
    final dua = _getDua();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final goldColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccentGold;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Mosque icon ──────────────────────────────────
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withOpacity(0.28),
                    width: 0.8,
                  ),
                ),
                child: Icon(Icons.mosque_rounded, color: accentColor, size: 26),
              ),

              const SizedBox(height: 14),

              // ── "Recite & Reflect" label ──────────────────────
              Text(
                "RECITE & REFLECT",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textSecondary.withOpacity(0.55),
                  letterSpacing: 2.0,
                ),
              ),

              const SizedBox(height: 20),

              // ── Gold ornament ────────────────────────────────
              _OrnamentDivider(goldColor: goldColor),

              const SizedBox(height: 20),

              // ── Arabic text ──────────────────────────────────
              Text(
                dua.arabic,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: goldColor,
                  height: 2.0,
                ),
              ),

              const SizedBox(height: 14),

              // ── Transliteration ──────────────────────────────
              Text(
                dua.transliteration,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: accentColor.withOpacity(0.80),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 12),

              Divider(color: borderColor, thickness: 0.8),

              const SizedBox(height: 10),

              // ── Translation ──────────────────────────────────
              Text(
                dua.translation,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: textSecondary.withOpacity(0.65),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // ── Action buttons ───────────────────────────────
              Row(
                children: [
                  // Stay button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentColor.withOpacity(0.22),
                            width: 0.8,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Stay",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Exit button (animated fill)
                  const Expanded(child: _AutoEnableExitButton()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        final isDoubleTap =
            _lastPressed != null &&
            now.difference(_lastPressed!) <= const Duration(seconds: 2);

        if (isDoubleTap) {
          _showExitDialog();
        } else {
          _lastPressed = now;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Tap again to exit",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              backgroundColor: isDark
                  ? AppTheme.darkCardAlt
                  : AppTheme.lightCardAlt,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: _pages[_currentIndex],
        bottomNavigationBar: _BottomBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          isDark: isDark,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BOTTOM NAV BAR
// ═══════════════════════════════════════════════════════════════════

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  static const _items = [
    (icon: Icons.home_rounded, label: "Home"),
    (icon: Icons.touch_app_rounded, label: "Tasbih"),
    (icon: Icons.settings_suggest_rounded, label: "Tools"),
    (icon: Icons.leaderboard_rounded, label: "Rank"),
    (icon: Icons.person_rounded, label: "Profile"),
  ];

  const _BottomBar({
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final inactiveColor = isDark
        ? AppTheme.darkTextTertiary
        : AppTheme.lightTextTertiary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final selected = currentIndex == i;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? accentColor.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      item.icon,
                      key: ValueKey(selected),
                      size: 22,
                      color: selected ? accentColor : inactiveColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? accentColor : inactiveColor,
                    ),
                  ),
                  // Active indicator dot
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: selected ? 4 : 0,
                    height: selected ? 4 : 0,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
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

// ═══════════════════════════════════════════════════════════════════
//  EXIT BUTTON  — animated fill over 2 seconds
// ═══════════════════════════════════════════════════════════════════

class _AutoEnableExitButton extends StatefulWidget {
  const _AutoEnableExitButton();

  @override
  State<_AutoEnableExitButton> createState() => _AutoEnableExitButtonState();
}

class _AutoEnableExitButtonState extends State<_AutoEnableExitButton> {
  bool _isEnabled = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final cardColor = isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt;
    final btnText = isDark
        ? AppTheme.darkTextOnAccent
        : AppTheme.lightTextOnAccent;

    return GestureDetector(
      onTap: _isEnabled ? () => SystemNavigator.pop() : null,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 2),
        onEnd: () => setState(() => _isEnabled = true),
        builder: (context, value, _) {
          return Container(
            height: 46,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withOpacity(0.22),
                width: 0.8,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated fill
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: Duration.zero,
                    width: (MediaQuery.of(context).size.width * 0.38) * value,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.85),
                    ),
                  ),
                ),
                // Label
                Text(
                  "Exit",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _isEnabled
                        ? btnText
                        : (isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHARED HELPERS
// ═══════════════════════════════════════════════════════════════════

class _OrnamentDivider extends StatelessWidget {
  final Color goldColor;
  const _OrnamentDivider({required this.goldColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [goldColor.withOpacity(0.0), goldColor.withOpacity(0.55)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '✦',
            style: TextStyle(
              fontSize: 10,
              color: goldColor.withOpacity(0.80),
              height: 1,
            ),
          ),
        ),
        Container(
          width: 44,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [goldColor.withOpacity(0.55), goldColor.withOpacity(0.0)],
            ),
          ),
        ),
      ],
    );
  }
}
