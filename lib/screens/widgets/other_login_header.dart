import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:salah_mode/screens/main_screen.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

Widget otherLoginHeader(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Divider(
              color: isDark ? Colors.white12 : Colors.black12,
              endIndent: 10,
            ),
          ),
          const Text("Continue with"),
          Expanded(
            child: Divider(
              indent: 10,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _otherLoginOption(context, Icons.language, "Google", _googleLogin),
          _otherLoginOption(
            context,
            Icons.facebook,
            "Facebook",
            _facebookLogin,
          ),
        ],
      ),
    ],
  );
}

Widget _otherLoginOption(
  BuildContext context,
  IconData icon,
  String label,
  VoidCallback onTap,
) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

  return Column(
    children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: accentColor.withValues(alpha: 0.12),
          child: Icon(icon, color: accentColor),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        style: TextStyle(
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
      ),
    ],
  );
}

// ─── Google Login ─────────────────────────────────────────────────────────────

Future<void> _googleLogin() async {
  try {
    // Force account picker to show on every tap
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return; // user cancelled

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Both tokens are required — if either is null Firebase will reject it
    if (googleAuth.accessToken == null || googleAuth.idToken == null) {
      Get.snackbar(
        "Google Login Failed",
        "Could not retrieve authentication tokens. Please try again.",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return;
    }

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);

    debugPrint("Google login success: ${userCredential.user?.email}");

    Get.offAll(() => const SalahMainScreen());
  } on FirebaseAuthException catch (e) {
    Get.snackbar(
      "Google Login Failed",
      _firebaseAuthErrorMessage(e.code),
      colorText: Colors.white,
      backgroundColor: Colors.red,
    );
    debugPrint("FirebaseAuthException [${e.code}]: ${e.message}");
  } catch (e) {
    Get.snackbar(
      "Google Login Failed",
      "An unexpected error occurred. Please try again.",
      colorText: Colors.white,
      backgroundColor: Colors.red,
    );
    debugPrint("Google login error: $e");
  }
}

// ─── Facebook Login ───────────────────────────────────────────────────────────

Future<void> _facebookLogin() async {
  try {
    // Trigger the Facebook login dialog
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    switch (result.status) {
      case LoginStatus.success:
        final AccessToken accessToken = result.accessToken!;

        final AuthCredential credential = FacebookAuthProvider.credential(
          accessToken.tokenString,
        );

        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(credential);

        debugPrint("Facebook login success: ${userCredential.user?.email}");

        Get.offAll(() => const SalahMainScreen());

      case LoginStatus.cancelled:
        // User closed the dialog — do nothing
        debugPrint("Facebook login cancelled by user.");

      case LoginStatus.failed:
        Get.snackbar(
          "Facebook Login Failed",
          result.message ?? "Something went wrong. Please try again.",
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
        debugPrint("Facebook login failed: ${result.message}");

      case LoginStatus.operationInProgress:
        // A login attempt is already running — ignore duplicate taps
        debugPrint("Facebook login already in progress.");
    }
  } on FirebaseAuthException catch (e) {
    // Handles the case where the Facebook email is already linked
    // to a different sign-in method (e.g. Google or email/password)
    if (e.code == 'account-exists-with-different-credential') {
      Get.snackbar(
        "Account Already Exists",
        "An account with this email already exists. Try signing in with Google or email/password.",
        colorText: Colors.white,
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      );
    } else {
      Get.snackbar(
        "Facebook Login Failed",
        _firebaseAuthErrorMessage(e.code),
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    }
    debugPrint("FirebaseAuthException [${e.code}]: ${e.message}");
  } catch (e) {
    Get.snackbar(
      "Facebook Login Failed",
      "An unexpected error occurred. Please try again.",
      colorText: Colors.white,
      backgroundColor: Colors.red,
    );
    debugPrint("Facebook login error: $e");
  }
}

// ─── Helper: human-readable Firebase error messages ──────────────────────────

String _firebaseAuthErrorMessage(String code) {
  switch (code) {
    case 'account-exists-with-different-credential':
      return "An account already exists with the same email but a different sign-in method.";
    case 'invalid-credential':
      return "The credential is invalid or has expired. Please try again.";
    case 'operation-not-allowed':
      return "This sign-in method is not enabled. Contact support.";
    case 'user-disabled':
      return "This account has been disabled. Contact support.";
    case 'user-not-found':
      return "No account found with these credentials.";
    case 'network-request-failed':
      return "Network error. Please check your connection and try again.";
    default:
      return "Authentication failed. Please try again.";
  }
}
