import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/auth/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salah_mode/screens/main_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();
  final mobileController = TextEditingController();
  final otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool obscure = true;
  int _signupMethod = 0; // 0=email, 1=mobile

  String? _verificationId;

  // ⭐ PREMIUM OTP STATE
  int _resendSeconds = 0;
  Timer? _timer;
  bool _isSendingOtp = false;

  late AnimationController _animController;
  late Animation<double> _fade;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    _slide = Tween<double>(
      begin: 40,
      end: 0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _timer?.cancel();

    nameController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmPassController.dispose();
    mobileController.dispose();
    otpController.dispose();
    super.dispose();
  }

  // ================= SUBMIT =================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (_signupMethod == 0) {
        await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passController.text.trim(),
        );
        // Save display name
        await _auth.currentUser?.updateDisplayName(nameController.text.trim());
      } else {
        if (_verificationId == null) {
          Get.snackbar(
            "Error",
            "Please request OTP first",
            colorText: Colors.white,
            backgroundColor: Colors.red,
          );
          return;
        }

        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: otpController.text.trim(),
        );

        await _auth.signInWithCredential(credential);
        // Save display name for phone user
        if (nameController.text.trim().isNotEmpty) {
          await _auth.currentUser?.updateDisplayName(
            nameController.text.trim(),
          );
        }
      }

      Get.snackbar(
        "Success",
        "Account created successfully",
        colorText: Colors.white,
        backgroundColor: Colors.green,
      );
      Get.offAll(() => const SalahMainScreen());
    } catch (e) {
      Get.snackbar(
        "Signup Failed",
        e.toString(),
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    }
  }

  // ================= OTP TIMER =================

  void _startOtpTimer() {
    _timer?.cancel();
    _resendSeconds = 30;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        height: Get.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF061A22), Color(0xFF0F2C36), Color(0xFF123E4A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: AnimatedBuilder(
              animation: _slide,
              builder: (_, _) {
                return Transform.translate(
                  offset: Offset(0, _slide.value),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          Text(
                            "Create Account",
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "Sign up to get started!",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // 🔀 Toggle
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                _toggle(theme, "Email", 0),
                                _toggle(theme, "Mobile", 1),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          if (_signupMethod == 0)
                            ..._emailFields()
                          else
                            ..._mobileFields(theme),

                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submit,
                              child: const Text("Create Account"),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Already have an account?",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Get.back();
                                    Get.to(() => LoginScreen());
                                  },
                                  child: const Text("Log In"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ================= EMAIL FIELDS =================

  List<Widget> _emailFields() => [
    _field(
      controller: nameController,
      hint: "Name",
      icon: Icons.person_outline,
      validator: (v) => v!.isEmpty ? "Enter your name" : null,
    ),
    const SizedBox(height: 16),
    _field(
      controller: emailController,
      hint: "Email",
      icon: Icons.email_outlined,
      validator: (v) => v!.isEmpty ? "Enter your email" : null,
    ),
    const SizedBox(height: 16),
    _field(
      controller: passController,
      hint: "Password",
      icon: Icons.lock_outline,
      isPassword: true,
      validator: (v) =>
          v!.length < 6 ? "Password must be at least 6 characters" : null,
    ),
    const SizedBox(height: 16),
    _field(
      controller: confirmPassController,
      hint: "Confirm Password",
      icon: Icons.lock_outline,
      isPassword: true,
      validator: (v) =>
          v != passController.text ? "Passwords do not match" : null,
    ),
  ];

  // ================= MOBILE FIELDS =================

  List<Widget> _mobileFields(ThemeData theme) => [
    _field(
      controller: nameController,
      hint: "Name",
      icon: Icons.person_outline,
      validator: (v) => v!.isEmpty ? "Enter your name" : null,
    ),
    const SizedBox(height: 16),
    _field(
      controller: mobileController,
      hint: "Mobile Number",
      icon: Icons.phone_outlined,
      validator: (v) => v!.length < 10 ? "Enter valid mobile" : null,
    ),
    const SizedBox(height: 10),

    // ⭐ PREMIUM OTP BUTTON
    Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: (_resendSeconds > 0 || _isSendingOtp)
            ? null
            : () async {
                if (mobileController.text.length < 10) {
                  Get.snackbar(
                    "Error",
                    "Enter valid mobile number",
                    colorText: Colors.white,
                    backgroundColor: Colors.red,
                  );
                  return;
                }

                setState(() => _isSendingOtp = true);

                await _auth.verifyPhoneNumber(
                  phoneNumber: "+91${mobileController.text.trim()}",
                  verificationCompleted:
                      (PhoneAuthCredential credential) async {
                        await _auth.signInWithCredential(credential);
                      },
                  verificationFailed: (FirebaseAuthException e) {
                    setState(() => _isSendingOtp = false);
                    Get.snackbar(
                      "OTP Failed",
                      e.message ?? "Verification failed",
                      colorText: Colors.white,
                      backgroundColor: Colors.red,
                    );
                  },
                  codeSent: (String verificationId, int? resendToken) {
                    _verificationId = verificationId;
                    _startOtpTimer();
                    setState(() => _isSendingOtp = false);
                    Get.snackbar(
                      "OTP Sent",
                      "Check your mobile for OTP",
                      colorText: Colors.white,
                      backgroundColor: Colors.green,
                    );
                  },
                  codeAutoRetrievalTimeout: (String verificationId) {
                    _verificationId = verificationId;
                  },
                );
              },
        child: Text(
          _isSendingOtp
              ? "Sending..."
              : (_resendSeconds > 0
                    ? "Resend in ${_resendSeconds}s"
                    : "Send OTP"),
          style: TextStyle(color: theme.colorScheme.primary),
        ),
      ),
    ),

    const SizedBox(height: 16),

    _field(
      controller: otpController,
      hint: "OTP",
      icon: Icons.lock_clock_outlined,
      validator: (v) => v!.isEmpty ? "Enter OTP" : null,
    ),
  ];

  // ================= TOGGLE =================

  Widget _toggle(ThemeData theme, String text, int value) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _signupMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _signupMethod == value
                ? theme.colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _signupMethod == value ? Colors.black : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= FIELD =================

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    bool isPassword = false,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
