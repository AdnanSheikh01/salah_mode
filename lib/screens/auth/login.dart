import 'package:flutter/material.dart';
import 'package:salah_mode/screens/main_screen.dart';

class SalahAuthScreen extends StatefulWidget {
  const SalahAuthScreen({super.key});

  @override
  State<SalahAuthScreen> createState() => _SalahAuthScreenState();
}

class _SalahAuthScreenState extends State<SalahAuthScreen> {
  int loginType = 0;
  bool obscure = true;
  bool showOtpField = false;

  final TextEditingController mobileController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// 🔝 SCROLLABLE CONTENT
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      /// 🌙 Icon
                      Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.nightlight_round,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Salah Mode",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// 🔘 Tabs
                      if (!showOtpField)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [_tab("Mobile", 0), _tab("Email", 1)],
                          ),
                        ),

                      const SizedBox(height: 40),

                      /// 📱 FORM AREA
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildForm(),
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                    ],
                  ),
                ),
              ),

              /// 🔻 Bottom Signup
              if (!showOtpField)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 FORM SWITCHER
  Widget _buildForm() {
    /// ✅ OTP SCREEN
    if (showOtpField) {
      return Column(
        key: const ValueKey("otp"),
        children: [
          const Text(
            "Enter OTP",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          _textField(
            hint: "Enter 6-digit OTP",
            icon: Icons.verified,
            controller: otpController,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 24),
          _button(
            "Verify OTP",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SalahMainScreen()),
            ),
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () {
              setState(() => showOtpField = false);
            },
            child: const Text(
              "Change Mobile Number",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      );
    }

    /// ✅ NORMAL LOGIN
    if (loginType == 0) {
      return Column(
        key: const ValueKey("mobile"),
        children: [
          _textField(
            hint: "Mobile Number",
            icon: Icons.phone,
            controller: mobileController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          _button(
            "Send OTP",
            onTap: () {
              setState(() => showOtpField = true);
            },
          ),
        ],
      );
    } else {
      return Column(
        key: const ValueKey("email"),
        children: [
          _textField(
            hint: "Email Address",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _textField(
            hint: "Password",
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 24),
          _button("Login"),
        ],
      );
    }
  }

  /// 🔘 Tab
  Widget _tab(String text, int index) {
    final selected = loginType == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => loginType = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF00C853) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔤 TextField
  Widget _textField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: () => setState(() => obscure = !obscure),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// 🔘 Button
  Widget _button(String text, {VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C853),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onTap ?? () {},
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
    );
  }
}
