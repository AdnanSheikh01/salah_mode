import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/main_screen.dart';

Widget otherLoginHeader(BuildContext context, Future googleLoginFuture) {
  return Column(
    children: [
      Row(
        children: [
          const Expanded(child: Divider(color: Colors.white12, endIndent: 10)),
          const Text("Continue with"),
          const Expanded(child: Divider(indent: 10, color: Colors.white12)),
        ],
      ),
      const SizedBox(height: 20),
      // 🌐 Other login options
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _otherLoginOption(Icons.language, "Google", () {
            _googleLogin(googleLoginFuture);
          }),
          _otherLoginOption(Icons.facebook, "Facebook", () {
            _facebookLogin();
          }),
        ],
      ),
    ],
  );
}

Widget _otherLoginOption(IconData icon, String label, VoidCallback onTap) {
  return Column(
    children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white12,
          child: Icon(icon),
        ),
      ),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(color: Colors.white70)),
    ],
  );
}

// ================= ACTIONS =================
Widget _googleLogin(Future future) {
  return FutureBuilder(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      } else if (snapshot.hasError) {
        Get.snackbar(
          "Login Failed",
          snapshot.error.toString(),
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
        return const Icon(Icons.error, color: Colors.red);
      } else {
        Get.offAll(() => const SalahMainScreen());
        return const Icon(Icons.check, color: Colors.green);
      }
    },
  );
}

Widget _facebookLogin() {
  // Implement Facebook login logic here
  Get.snackbar(
    "Coming Soon",
    "Facebook login will be available in a future update.",
    colorText: Colors.white,
    backgroundColor: Colors.orange,
  );
  return const Icon(Icons.facebook, color: Colors.blue);
}
