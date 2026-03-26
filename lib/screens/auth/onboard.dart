import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:salah_mode/screens/auth/login.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  late final AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // ── Page data ──────────────────────────────────────────────────
  // Using Unicode symbols instead of emoji for consistency with the
  // Islamic design language across the app
  final List<Map<String, String>> _pages = [
    {
      "symbol": "🕌",
      "title": "Never Miss Salah",
      "desc":
          "Stay connected with your daily prayers and build consistency in your spiritual journey.",
    },
    {
      "symbol": "🌙",
      "title": "Smart Prayer Reminders",
      "desc":
          "Get accurate prayer times and beautiful reminders wherever you are.",
    },
    {
      "symbol": "📿",
      "title": "Digital Tasbih",
      "desc":
          "Count your dhikr anytime with a smooth, distraction-free tasbih experience.",
    },
    {
      "symbol": "✦",
      "title": "Daily Dhikr Focus",
      "desc":
          "Receive daily dhikr notifications and stay focused while Salah Mode minimizes distractions.",
    },
    {
      "symbol": "📊",
      "title": "Track Your Progress",
      "desc":
          "Monitor your daily prayer performance and stay motivated every day.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    GetStorage().write('first_time', false);
    Get.offAll(() => const LoginScreen());
  }

  void _onPageChanged(int index) {
    // Replay fade on each page turn
    _fadeController.reset();
    _fadeController.forward();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
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
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final btnTextColor = isDark
        ? AppTheme.darkTextOnAccent
        : AppTheme.lightTextOnAccent;

    final isLast = _currentIndex == _pages.length - 1;

    // Explicit button style — bypasses theme pill shape
    final nextBtnStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.all(accentColor),
      foregroundColor: MaterialStateProperty.all(btnTextColor),
      elevation: MaterialStateProperty.all(0),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(vertical: 16),
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Ambient glows ──────────────────────────────────────
          Positioned(
            top: -90,
            left: -70,
            child: _GlowCircle(
              size: 240,
              color: accentColor.withOpacity(isDark ? 0.09 : 0.07),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _GlowCircle(
              size: 220,
              color: accentColor.withOpacity(isDark ? 0.08 : 0.05),
            ),
          ),

          // ── Main content ───────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top bar: back arrow + skip ───────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back arrow (hidden on first page)
                      AnimatedOpacity(
                        opacity: _currentIndex > 0 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: GestureDetector(
                          onTap: _currentIndex > 0
                              ? () => _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                )
                              : null,
                          child: Container(
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
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),

                      // Page counter e.g. "2 / 5"
                      Text(
                        "${_currentIndex + 1} / ${_pages.length}",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSecondary.withOpacity(0.6),
                          letterSpacing: 1.0,
                        ),
                      ),

                      // Skip button
                      GestureDetector(
                        onTap: _finishOnboarding,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accentColor.withOpacity(0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            "Skip",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Page content ─────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return FadeTransition(
                        opacity: _fadeAnim,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // ── Icon container ─────────────────
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: goldColor.withOpacity(0.35),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withOpacity(
                                        isDark ? 0.18 : 0.10,
                                      ),
                                      blurRadius: 32,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    page["symbol"]!,
                                    style: TextStyle(
                                      // For the ✦ symbol use gold color,
                                      // for emoji fontSize controls size
                                      fontSize: page["symbol"] == "✦" ? 32 : 48,
                                      color: page["symbol"] == "✦"
                                          ? goldColor
                                          : null,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 36),

                              // ── Ornament ───────────────────────
                              _OrnamentDivider(goldColor: goldColor),

                              const SizedBox(height: 24),

                              // ── Title ──────────────────────────
                              Text(
                                page["title"]!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  height: 1.25,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── Description ────────────────────
                              Text(
                                page["desc"]!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: textSecondary,
                                  height: 1.65,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Dot indicators ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentIndex == index ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? goldColor
                            : borderColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Next / Get Started button ─────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: nextBtnStyle,
                      onPressed: () {
                        if (isLast) {
                          _finishOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast ? "Get Started" : "Next",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: btnTextColor,
                            ),
                          ),
                          if (!isLast) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: btnTextColor,
                            ),
                          ],
                          if (isLast) ...[
                            const SizedBox(width: 8),
                            Text(
                              "✦",
                              style: TextStyle(
                                fontSize: 13,
                                color: btnTextColor.withOpacity(0.8),
                                height: 1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════

/// Two gold fade-lines with a ✦ star in the center
class _OrnamentDivider extends StatelessWidget {
  final Color goldColor;
  const _OrnamentDivider({required this.goldColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
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
          width: 48,
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

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
