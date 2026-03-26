import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:salah_mode/screens/auth/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salah_mode/screens/main_screen.dart';
import 'package:salah_mode/screens/widgets/other_login_header.dart';

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
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    confirmPassController.dispose();
    super.dispose();
  }

  // ================= SUBMIT =================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passController.text.trim(),
      );
      // Save display name
      await _auth.currentUser?.updateDisplayName(nameController.text.trim());

      Get.snackbar(
        "Success",
        "Account created successfully",
        colorText: Colors.white,
        backgroundColor: Colors.green,
      );

      setState(() => _isLoading = false);
      Get.offAll(() => const SalahMainScreen());
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        "Signup Failed",
        e.toString(),
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    }
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

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Create Account",
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                ),
                                onPressed: () {
                                  final box = GetStorage();
                                  box.write('skip', true);
                                  Get.offAll(() => const SalahMainScreen());
                                },
                                child: Text(
                                  "Skip",
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "Sign up to get started!",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),

                          const SizedBox(height: 30),

                          const SizedBox(height: 20),

                          ..._emailFields(),

                          const SizedBox(height: 28),

                          _isLoading
                              ? Center(child: const CircularProgressIndicator())
                              : SizedBox(
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

                          const SizedBox(height: 20),
                          otherLoginHeader(
                            context,
                            _auth.signInWithPopup(GoogleAuthProvider()),
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
