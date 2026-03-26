import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:salah_mode/screens/auth/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salah_mode/screens/auth/onboard.dart';
import 'package:salah_mode/screens/main_screen.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _loaderController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    // ── Entry animation ──────────────────────────────────────────
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Tasbih ring rotation (2.4s full loop) ────────────────────
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // ── Center star pulse ────────────────────────────────────────
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _entryController.forward();
    _goNext();
  }

  void _goNext() {
    Timer(const Duration(seconds: 3), () async {
      final user = FirebaseAuth.instance.currentUser;
      final box = GetStorage();
      final isFirstTime = box.read('first_time') ?? true;
      final bool skipped = box.read('skip') ?? false;

      if (!mounted) return;

      if (isFirstTime) {
        Get.offAll(() => const OnboardingScreen());
      } else if (skipped) {
        Get.offAll(() => const SalahMainScreen());
      } else if (user != null) {
        Get.offAll(() => const SalahMainScreen());
      } else {
        Get.offAll(() => const LoginScreen());
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _loaderController.dispose();
    _pulseController.dispose();
    super.dispose();
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
    final borderColor = isDark
        ? AppTheme.darkBorderAccent
        : AppTheme.lightBorderAccent;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Ambient background glows ───────────────────────────
          Positioned(
            top: -90,
            left: -70,
            child: _GlowCircle(
              size: 240,
              color: accentColor.withOpacity(isDark ? 0.10 : 0.08),
            ),
          ),
          Positioned(
            bottom: -110,
            right: -90,
            child: _GlowCircle(
              size: 280,
              color: accentColor.withOpacity(isDark ? 0.10 : 0.07),
            ),
          ),
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Center(
              child: _GlowCircle(
                size: 320,
                color: accentColor.withOpacity(
                  isDark ? 0.07 * _glowAnim.value : 0.05 * _glowAnim.value,
                ),
              ),
            ),
          ),

          // ── Corner geometric stars ─────────────────────────────
          Positioned(
            top: 48,
            right: 24,
            child: Opacity(
              opacity: isDark ? 0.06 : 0.05,
              child: _IslamicStar(size: 80, color: accentColor),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 20,
            child: Opacity(
              opacity: isDark ? 0.06 : 0.05,
              child: _IslamicStar(size: 60, color: accentColor),
            ),
          ),

          // ── Main content ───────────────────────────────────────
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Mosque icon ────────────────────────────
                        AnimatedBuilder(
                          animation: _glowAnim,
                          builder: (_, child) => Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cardColor,
                              border: Border.all(
                                color: borderColor.withOpacity(
                                  0.3 + 0.35 * _glowAnim.value,
                                ),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(
                                    isDark
                                        ? 0.20 * _glowAnim.value
                                        : 0.12 * _glowAnim.value,
                                  ),
                                  blurRadius: 48,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                          child: Icon(
                            Icons.mosque_rounded,
                            size: 68,
                            color: accentColor,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── Gold ornament divider ──────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _OrnamentLine(color: goldColor),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Icon(
                                Icons.star_rounded,
                                size: 10,
                                color: goldColor,
                              ),
                            ),
                            _OrnamentLine(color: goldColor),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── App name ───────────────────────────────
                        Text(
                          "Salah Mode",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: 1.0,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ── Arabic subtitle ────────────────────────
                        Text(
                          "صلاة • ذكر • إيمان",
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: goldColor,
                            height: 1.8,
                            letterSpacing: 1.5,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Tagline ────────────────────────────────
                        Text(
                          "Build a beautiful habit of\nconsistent Salah and daily Dhikr",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: textSecondary,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 52),

                        // ── Tasbih loader (replaces CircularProgressIndicator) ──
                        _TasbihLoader(
                          rotationController: _loaderController,
                          pulseController: _pulseController,
                          goldColor: goldColor,
                          accentColor: accentColor,
                        ),

                        const SizedBox(height: 18),

                        // ── Bismillah under loader ─────────────────
                        Text(
                          "بِسْمِ اللَّهِ",
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            color: goldColor.withOpacity(0.75),
                            letterSpacing: 1.2,
                            height: 1.8,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "LOADING",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: textSecondary.withOpacity(0.5),
                            letterSpacing: 3.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
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
//  TASBIH LOADER
//  — 12 gold beads rotating around a ring, wave-opacity effect,
//    pulsing 4-pointed star in the center
// ═══════════════════════════════════════════════════════════════════

class _TasbihLoader extends StatelessWidget {
  final AnimationController rotationController;
  final AnimationController pulseController;
  final Color goldColor;
  final Color accentColor;

  const _TasbihLoader({
    required this.rotationController,
    required this.pulseController,
    required this.goldColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating bead ring
          AnimatedBuilder(
            animation: rotationController,
            builder: (_, __) => Transform.rotate(
              angle: rotationController.value * 2 * pi,
              child: CustomPaint(
                size: const Size(72, 72),
                painter: _TasbihPainter(
                  progress: rotationController.value,
                  goldColor: goldColor,
                ),
              ),
            ),
          ),

          // Pulsing center star
          AnimatedBuilder(
            animation: pulseController,
            builder: (_, __) {
              final scale = 0.85 + 0.15 * pulseController.value;
              final opacity = 0.50 + 0.50 * pulseController.value;
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: CustomPaint(
                    size: const Size(22, 22),
                    painter: _StarPainter(color: goldColor),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Paints 12 beads on a ring with a travelling brightness wave ────
class _TasbihPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0, drives the wave position
  final Color goldColor;

  const _TasbihPainter({required this.progress, required this.goldColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const beadCount = 12;
    const ringRadius = 28.0;
    const beadRadius = 3.2;

    // Faint dashed guide ring
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color = goldColor.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    for (int i = 0; i < beadCount; i++) {
      final angle = (i / beadCount) * 2 * pi - pi / 2; // start at top
      final beadOffset = Offset(
        center.dx + ringRadius * cos(angle),
        center.dy + ringRadius * sin(angle),
      );

      // How close is this bead to the "bright" spot?
      double diff = ((i / beadCount) - progress).abs();
      if (diff > 0.5) diff = 1.0 - diff;
      final t = 1.0 - (diff * 2.0).clamp(0.0, 1.0);
      final opacity = 0.15 + 0.85 * t;
      final radius = beadRadius * (0.72 + 0.42 * t);

      canvas.drawCircle(
        beadOffset,
        radius,
        Paint()
          ..color = goldColor.withOpacity(opacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_TasbihPainter old) =>
      old.progress != progress || old.goldColor != goldColor;
}

// ── Draws a 4-pointed star ─────────────────────────────────────────
class _StarPainter extends CustomPainter {
  final Color color;
  const _StarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = size.width / 2;
    final inner = outer * 0.42;
    final path = Path();

    for (int i = 0; i < 8; i++) {
      final r = i.isEven ? outer : inner;
      final angle = (i * pi / 4) - pi / 2;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}

// ═══════════════════════════════════════════════════════════════════
//  HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════

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

class _OrnamentLine extends StatelessWidget {
  final Color color;
  const _OrnamentLine({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withOpacity(0.0), color.withOpacity(0.7)],
      ),
    ),
  );
}

class _IslamicStar extends StatelessWidget {
  final double size;
  final Color color;
  const _IslamicStar({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size * 0.65,
          height: size * 0.65,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: size * 0.65,
            height: size * 0.65,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    ),
  );
}
