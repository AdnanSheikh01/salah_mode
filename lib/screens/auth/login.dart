import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/auth/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:salah_mode/screens/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final mobileController = TextEditingController();
  final otpController = TextEditingController();
  int _loginMethod = 0; // 0 = email, 1 = mobile
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  int _resendSeconds = 0;
  Timer? _timer;
  bool _isSendingOtp = false;

  bool obscure = true;

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
    nameController.dispose();
    emailController.dispose();
    passController.dispose();
    mobileController.dispose();
    otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (_loginMethod == 0) {
        // Email login
        await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passController.text.trim(),
        );
      } else {
        // Mobile OTP verify
        if (_verificationId == null) {
          Get.snackbar(
            "Error",
            "Please request OTP first",
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }

        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: otpController.text.trim(),
        );

        await _auth.signInWithCredential(credential);
      }

      Get.snackbar(
        "Success",
        "Logged in successfully",
        snackPosition: SnackPosition.BOTTOM,
      );

      // Navigate to main screen
      Get.offAll(() => const SalahMainScreen());
    } catch (e) {
      Get.snackbar(
        "Login Failed",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

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

                          /// 🌙 Title
                          Text(
                            "Log In to Salah Mode",
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Welcome back! Please log in to your account.",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // 🔀 Login method toggle
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _loginMethod = 0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _loginMethod == 0
                                            ? theme.colorScheme.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Email",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _loginMethod == 0
                                                ? Colors.black
                                                : Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _loginMethod = 1),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _loginMethod == 1
                                            ? theme.colorScheme.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Mobile",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _loginMethod == 1
                                                ? Colors.black
                                                : Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          if (_loginMethod == 0) ...[
                            /// 📧 Email
                            _field(
                              controller: emailController,
                              hint: "Email",
                              icon: Icons.email_outlined,
                              validator: (v) =>
                                  v!.isEmpty ? "Enter your email" : null,
                            ),

                            const SizedBox(height: 16),

                            /// 🔒 Password
                            _field(
                              controller: passController,
                              hint: "Password",
                              icon: Icons.lock_outline,
                              isPassword: true,
                              validator: (v) => v!.length < 6
                                  ? "Password must be at least 6 characters"
                                  : null,
                            ),
                          ] else ...[
                            /// 📱 Mobile
                            _field(
                              controller: mobileController,
                              hint: "Mobile Number",
                              icon: Icons.phone_outlined,
                              validator: (v) =>
                                  v!.length < 10 ? "Enter valid mobile" : null,
                            ),

                            const SizedBox(height: 10),
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
                                            snackPosition: SnackPosition.BOTTOM,
                                          );
                                          return;
                                        }

                                        setState(() => _isSendingOtp = true);

                                        await _auth.verifyPhoneNumber(
                                          phoneNumber:
                                              "+91${mobileController.text.trim()}",
                                          verificationCompleted:
                                              (
                                                PhoneAuthCredential credential,
                                              ) async {
                                                await _auth
                                                    .signInWithCredential(
                                                      credential,
                                                    );
                                              },
                                          verificationFailed:
                                              (FirebaseAuthException e) {
                                                setState(
                                                  () => _isSendingOtp = false,
                                                );
                                                Get.snackbar(
                                                  "OTP Failed",
                                                  e.message ??
                                                      "Verification failed",
                                                  snackPosition:
                                                      SnackPosition.BOTTOM,
                                                );
                                              },
                                          codeSent:
                                              (
                                                String verificationId,
                                                int? resendToken,
                                              ) {
                                                _verificationId =
                                                    verificationId;
                                                _startOtpTimer();
                                                setState(
                                                  () => _isSendingOtp = false,
                                                );
                                                Get.snackbar(
                                                  "OTP Sent",
                                                  "Check your mobile for OTP",
                                                  snackPosition:
                                                      SnackPosition.BOTTOM,
                                                );
                                              },
                                          codeAutoRetrievalTimeout:
                                              (String verificationId) {
                                                _verificationId =
                                                    verificationId;
                                              },
                                        );
                                      },
                                child: Text(
                                  _isSendingOtp
                                      ? "Sending..."
                                      : (_resendSeconds > 0
                                            ? "Resend in ${_resendSeconds}s"
                                            : "Send OTP"),
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            /// 🔢 OTP
                            _field(
                              controller: otpController,
                              hint: "OTP",
                              icon: Icons.lock_clock_outlined,
                              validator: (v) => v!.isEmpty ? "Enter OTP" : null,
                            ),
                          ],

                          const SizedBox(height: 28),

                          // 🚀 Sign up button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _submit,
                              child: const Text(
                                "Log In",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 🔁 Login link
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account?"),
                                TextButton(
                                  onPressed: () {
                                    Get.back();
                                    Get.to(() => const SignUpScreen());
                                  },
                                  child: const Text("Sign Up"),
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
