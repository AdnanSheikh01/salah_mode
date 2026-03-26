import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

class ContactFormController extends GetxController {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final messageCtrl = TextEditingController();

  final isLoading = false.obs;

  // Pre-fill name and email from Firebase Auth if signed in
  @override
  void onInit() {
    super.onInit();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        nameCtrl.text = user.displayName ?? '';
        emailCtrl.text = user.email ?? '';
      }
    } catch (_) {}
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    messageCtrl.dispose();
    super.onClose();
  }

  // ── Validation ───────────────────────────────────────────────
  String? _validate() {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final message = messageCtrl.text.trim();

    if (name.isEmpty) return "Please enter your name.";
    if (email.isEmpty) return "Please enter your email.";
    if (!GetUtils.isEmail(email)) return "Please enter a valid email address.";
    if (message.isEmpty) return "Please enter a message.";
    if (message.length < 10)
      return "Message is too short. Please provide more detail.";
    return null;
  }

  // ── Submit to Firestore ───────────────────────────────────────
  Future<void> submitForm() async {
    if (isLoading.value) return;

    final error = _validate();
    if (error != null) {
      _snack("Incomplete Form", error, isError: true);
      return;
    }

    try {
      isLoading.value = true;

      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
      final name = nameCtrl.text.trim();

      await FirebaseFirestore.instance.collection('contact_messages').add({
        'uid': uid,
        'name': name,
        'email': emailCtrl.text.trim(),
        'message': messageCtrl.text.trim(),
        'platform': 'flutter_app',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      nameCtrl.clear();
      emailCtrl.clear();
      messageCtrl.clear();

      _snack(
        "Message Sent ✦",
        "JazakAllah Khair $name! We'll get back to you soon.",
        isError: false,
      );
    } on FirebaseException catch (e) {
      debugPrint("Contact Firestore error: $e");
      _snack(
        "Send Failed",
        e.message ?? "A network error occurred. Please try again.",
        isError: true,
      );
    } catch (e) {
      debugPrint("Contact submit error: $e");
      _snack(
        "Something Went Wrong",
        "Please check your connection and try again.",
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _snack(String title, String message, {required bool isError}) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.snackbar(
      title,
      message,
      backgroundColor: isError ? AppTheme.colorError : AppTheme.colorSuccess,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────

class ContactFormPage extends StatelessWidget {
  ContactFormPage({super.key});

  final _ctrl = Get.put(ContactFormController());

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
    final textTertiary = isDark
        ? AppTheme.darkTextTertiary
        : AppTheme.lightTextTertiary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final inputFill = isDark ? AppTheme.darkInputFill : AppTheme.lightInputFill;
    final btnTextColor = isDark
        ? AppTheme.darkTextOnAccent
        : AppTheme.lightTextOnAccent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentColor, size: 20),
        title: Text(
          "Contact Us",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header card ───────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: btnTextColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.support_agent_rounded,
                            color: btnTextColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "We'd love to hear from you",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: btnTextColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "Questions, feedback, or bug reports",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: btnTextColor.withOpacity(0.72),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Section label ─────────────────────────────
                  _SectionLabel(
                    label: "Your Details",
                    goldColor: goldColor,
                    textPrimary: textPrimary,
                  ),
                  const SizedBox(height: 12),

                  // ── Name field ────────────────────────────────
                  _ContactField(
                    controller: _ctrl.nameCtrl,
                    hint: "Your Name",
                    icon: Icons.person_rounded,
                    keyboard: TextInputType.name,
                    accentColor: accentColor,
                    inputFill: inputFill,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),

                  const SizedBox(height: 12),

                  // ── Email field ───────────────────────────────
                  _ContactField(
                    controller: _ctrl.emailCtrl,
                    hint: "Your Email",
                    icon: Icons.email_rounded,
                    keyboard: TextInputType.emailAddress,
                    accentColor: accentColor,
                    inputFill: inputFill,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),

                  const SizedBox(height: 24),

                  // ── Message ───────────────────────────────────
                  _SectionLabel(
                    label: "Your Message",
                    goldColor: goldColor,
                    textPrimary: textPrimary,
                  ),
                  const SizedBox(height: 12),

                  _ContactField(
                    controller: _ctrl.messageCtrl,
                    hint: "Describe your question, feedback, or report...",
                    icon: Icons.chat_bubble_outline_rounded,
                    keyboard: TextInputType.multiline,
                    maxLines: 6,
                    accentColor: accentColor,
                    inputFill: inputFill,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),

                  const SizedBox(height: 24),

                  // ── Contact options row ───────────────────────
                  _SectionLabel(
                    label: "Other Ways to Reach Us",
                    goldColor: goldColor,
                    textPrimary: textPrimary,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _ContactPill(
                          icon: Icons.email_outlined,
                          label: "Email",
                          value: "support@salahmode.app",
                          color: AppTheme.colorInfo,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textTertiary: textTertiary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ContactPill(
                          icon: Icons.schedule_rounded,
                          label: "Response",
                          value: "Within 24–48hrs",
                          color: AppTheme.colorSuccess,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textTertiary: textTertiary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Privacy note ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: goldColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: goldColor.withOpacity(0.18),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "✦ ",
                          style: TextStyle(
                            fontSize: 12,
                            color: goldColor,
                            height: 1.5,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Your message is sent securely. We do not share "
                            "your information with any third party.",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: textSecondary,
                              height: 1.6,
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

          // ── Submit button (pinned) ────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: borderColor, width: 0.8)),
            ),
            child: Obx(() {
              final loading = _ctrl.isLoading.value;
              return GestureDetector(
                onTap: loading ? null : _ctrl.submitForm,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: loading
                        ? accentColor.withOpacity(0.55)
                        : accentColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: loading
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: btnTextColor,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: btnTextColor,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              "Send Message",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: btnTextColor,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CONTACT FIELD
// ═══════════════════════════════════════════════════════════════════

class _ContactField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboard;
  final int maxLines;
  final Color accentColor, inputFill, textPrimary, textSecondary, borderColor;

  const _ContactField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.keyboard,
    required this.accentColor,
    required this.inputFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: textPrimary),
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: textSecondary,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, size: 20, color: accentColor.withOpacity(0.70)),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 50,
          minHeight: 50,
        ),
        alignLabelWithHint: true,
        filled: true,
        fillColor: inputFill,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 14 : 0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 1.4),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color goldColor, textPrimary;
  const _SectionLabel({
    required this.label,
    required this.goldColor,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 3,
        height: 16,
        decoration: BoxDecoration(
          color: goldColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
    ],
  );
}

class _ContactPill extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color, cardColor, borderColor, textPrimary, textTertiary;

  const _ContactPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textTertiary,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.20), width: 0.8),
    ),
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
