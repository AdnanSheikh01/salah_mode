import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:salah_mode/screens/auth/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salah_mode/screens/main_screen.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';
import 'package:salah_mode/screens/widgets/text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _isLoading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  String _friendlyError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Email or password is incorrect.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'Account suspended. Contact support.';
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
        case 'network-request-failed':
          return 'No internet connection.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
      Get.snackbar(
        "Welcome back!",
        "You've successfully signed in.",
        colorText: AppTheme.darkTextPrimary,
        backgroundColor: AppTheme.darkCard,
        icon: const Icon(
          Icons.check_circle_outline,
          color: AppTheme.darkAccentGreen,
        ),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
      Get.offAll(() => const SalahMainScreen());
    } catch (e) {
      Get.snackbar(
        "Sign In Failed",
        _friendlyError(e),
        colorText: AppTheme.darkTextPrimary,
        backgroundColor: AppTheme.darkCard,
        icon: const Icon(Icons.error_outline, color: AppTheme.colorError),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _skip() {
    GetStorage().write('skip', true);
    Get.offAll(() => const SalahMainScreen());
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

    // Explicit button style — overrides the theme's rounded shape completely
    final loginBtnStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.disabled)
            ? accentColor.withOpacity(0.5)
            : accentColor,
      ),
      foregroundColor: MaterialStateProperty.all(btnTextColor),
      elevation: MaterialStateProperty.all(0),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(vertical: 15),
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      // ── Disable theme-level button shape override ─────────────
      body: Stack(
        children: [
          // ── Ambient glows ──────────────────────────────────────
          Positioned(
            top: -100,
            left: -80,
            child: _GlowCircle(
              size: 260,
              color: accentColor.withOpacity(isDark ? 0.08 : 0.06),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _GlowCircle(
              size: 220,
              color: accentColor.withOpacity(isDark ? 0.07 : 0.05),
            ),
          ),

          // ── Content — NOT in SingleChildScrollView directly ────
          // We use SafeArea > Column > Expanded > SingleChildScrollView
          // so content stays top-aligned and doesn't leave dead space
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── Header ───────────────────────
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Log In",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  _SkipButton(
                                    onTap: _skip,
                                    accentColor: accentColor,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              Text(
                                "Welcome back! Please log in to your account.",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: textSecondary,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 14),

                              // ── Ornament divider ─────────────
                              _OrnamentDivider(goldColor: goldColor),

                              const SizedBox(height: 28),

                              // ── Fields card ──────────────────
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  20,
                                  16,
                                  8,
                                ),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 0.8,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    field(
                                      context: context,
                                      controller: _emailController,
                                      hint: "Email address",
                                      obscure: false,
                                      icon: Icons.email_outlined,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Please enter your email address.';
                                        }
                                        final emailRegex = RegExp(
                                          r'^[\w\.-]+@[\w\.-]+\.\w{2,}$',
                                        );
                                        if (!emailRegex.hasMatch(v.trim())) {
                                          return 'Please enter a valid email address.';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 14),

                                    field(
                                      context: context,
                                      controller: _passController,
                                      hint: "Password",
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      obscure: _obscure,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Please enter your password.';
                                        }
                                        if (v.length < 6) {
                                          return 'Password must be at least 6 characters.';
                                        }
                                        return null;
                                      },
                                      onTap: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),

                                    // Forgot password
                                    TextButton(
                                      onPressed: () {
                                        // TODO: forgot password
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        "Forgot password?",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),

                              // ── Log In button ─────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  style: loginBtnStyle,
                                  onPressed: _isLoading ? null : _submit,
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: btnTextColor,
                                            backgroundColor: btnTextColor
                                                .withOpacity(0.25),
                                          ),
                                        )
                                      : Text(
                                          "Log In",
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                            color: btnTextColor,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // ── Sign-up link ──────────────────
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account?",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: textSecondary,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Get.back();
                                        Get.to(() => const SignUpScreen());
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        "Sign Up",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── "or continue with" divider ────
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: borderColor.withOpacity(0.5),
                                      thickness: 0.8,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Text(
                                      "or continue with",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: textSecondary.withOpacity(0.55),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: borderColor.withOpacity(0.5),
                                      thickness: 0.8,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // ── Social buttons ────────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: _SocialButton(
                                      label: "Google",
                                      icon: Icons.language_rounded,
                                      onTap: () {
                                        /* TODO */
                                      },
                                      cardColor: cardColor,
                                      borderColor: borderColor,
                                      accentColor: accentColor,
                                      textSecondary: textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _SocialButton(
                                      label: "Facebook",
                                      icon: Icons.facebook_rounded,
                                      onTap: () {
                                        /* TODO */
                                      },
                                      cardColor: cardColor,
                                      borderColor: borderColor,
                                      accentColor: accentColor,
                                      textSecondary: textSecondary,
                                    ),
                                  ),
                                ],
                              ),

                              // ── No extra SizedBox here — padding handles bottom ──
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
//  WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _SkipButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color accentColor;
  const _SkipButton({required this.onTap, required this.accentColor});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.28), width: 0.8),
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
  );
}

/// Gold ornament — two fade lines with a diamond dot in the center
class _OrnamentDivider extends StatelessWidget {
  final Color goldColor;
  const _OrnamentDivider({required this.goldColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [goldColor.withOpacity(0.0), goldColor.withOpacity(0.55)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
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
          width: 40,
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

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color cardColor;
  final Color borderColor;
  final Color accentColor;
  final Color textSecondary;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.cardColor,
    required this.borderColor,
    required this.accentColor,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: accentColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
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
