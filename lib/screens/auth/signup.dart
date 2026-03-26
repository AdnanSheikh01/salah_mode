import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:salah_mode/screens/auth/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salah_mode/screens/main_screen.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';
import 'package:salah_mode/screens/widgets/text_field.dart';

// NOTE: otherLoginHeader removed — it injects a duplicate "Continue with"
// header. Social buttons are rebuilt inline to match the Islamic theme.

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _isLoading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

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
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // ── Firebase error → friendly message ─────────────────────────
  String _friendlyError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account with this email already exists. Try logging in instead.';
        case 'invalid-email':
          return 'The email address doesn\'t appear to be valid. Please check the format.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters with letters and numbers.';
        case 'operation-not-allowed':
          return 'Account creation is currently unavailable. Please try again later.';
        case 'network-request-failed':
          return 'No internet connection. Please check and try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment before trying again.';
        default:
          return 'Something went wrong. Please try again in a moment.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  // ── Submit ─────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passController.text.trim(),
          );
      await credential.user?.updateDisplayName(_nameController.text.trim());

      Get.snackbar(
        "Account Created!",
        "Welcome to Salah Mode, ${_nameController.text.trim()}. May your prayers be accepted.",
        colorText: AppTheme.darkTextPrimary,
        backgroundColor: AppTheme.darkCard,
        icon: const Icon(
          Icons.check_circle_outline,
          color: AppTheme.darkAccentGreen,
        ),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
      Get.offAll(() => const SalahMainScreen());
    } catch (e) {
      Get.snackbar(
        "Sign Up Failed",
        _friendlyError(e),
        colorText: AppTheme.darkTextPrimary,
        backgroundColor: AppTheme.darkCard,
        icon: const Icon(Icons.error_outline, color: AppTheme.colorError),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
      debugPrint("Signup error: $e");
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

    // Explicit button style — bypasses theme shape override
    final submitBtnStyle = ButtonStyle(
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
      body: Stack(
        children: [
          // ── Ambient glows (mirror login screen) ───────────────
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

          // ── Content ───────────────────────────────────────────
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
                              // ── Header row ─────────────────
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Create Account",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 26,
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
                                "Sign up to start your journey of consistent Salah.",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: textSecondary,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 14),

                              // ── Ornament divider ────────────
                              _OrnamentDivider(goldColor: goldColor),

                              const SizedBox(height: 28),

                              // ── Fields card ─────────────────
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
                                  children: [
                                    // Full name
                                    field(
                                      context: context,
                                      controller: _nameController,
                                      hint: "Full Name",
                                      obscure: false,
                                      icon: Icons.person_outline,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Please enter your full name.';
                                        }
                                        if (v.trim().length < 2) {
                                          return 'Name must be at least 2 characters.';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 14),

                                    // Email
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

                                    // Password
                                    field(
                                      context: context,
                                      controller: _passController,
                                      hint: "Password",
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      obscure: _obscure,
                                      onTap: () =>
                                          setState(() => _obscure = !_obscure),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Please enter a password.';
                                        }
                                        if (v.length < 6) {
                                          return 'Password must be at least 6 characters.';
                                        }
                                        if (!RegExp(r'[A-Za-z]').hasMatch(v)) {
                                          return 'Password must include at least one letter.';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 14),

                                    // Confirm password
                                    field(
                                      context: context,
                                      controller: _confirmPassController,
                                      hint: "Confirm Password",
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      obscure: _obscureConfirm,
                                      showToggle: true,
                                      onTap: () => setState(
                                        () =>
                                            _obscureConfirm = !_obscureConfirm,
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Please confirm your password.';
                                        }
                                        if (v != _passController.text) {
                                          return 'Passwords don\'t match.';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),

                              // ── Create Account button ───────
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  style: submitBtnStyle,
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
                                          "Create Account",
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

                              // ── Login link ──────────────────
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Already have an account?",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: textSecondary,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Get.back();
                                        Get.to(() => const LoginScreen());
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
                                        "Log In",
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

                              // ── "or continue with" divider ──
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

                              // ── Social buttons ──────────────
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
//  LOCAL WIDGETS  (identical to LoginScreen — extract to shared file
//  e.g. lib/screens/widgets/auth_widgets.dart to avoid duplication)
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

/// Two gold fade-lines with a ✦ star in the center
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
