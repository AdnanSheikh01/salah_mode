import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// ---------------- CONTROLLER ----------------
class ContactFormController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final messageController = TextEditingController();

  final isLoading = false.obs;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    messageController.dispose();
    super.onClose();
  }

  Future<void> submitForm() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final message = messageController.text.trim();

    if (name.trim().isEmpty || email.trim().isEmpty || message.trim().isEmpty) {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
      Get.snackbar(
        "Error!",
        "Please fill all fields",
        colorText: Colors.white,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
      );
      return;
    }

    if (!GetUtils.isEmail(email)) {
      Get.snackbar(
        "Invalid Email",
        "Please enter a valid email address",
        colorText: Colors.white,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
      );
      return;
    }

    try {
      isLoading.value = true;

      // 🔹 Dummy delay (replace with Firebase later)
      await Future.delayed(const Duration(seconds: 2));

      Get.snackbar(
        "Success",
        "Your message has been sent (dummy)",
        colorText: Colors.white,
        backgroundColor: Colors.green.withOpacity(0.9),
      );

      nameController.clear();
      emailController.clear();
      messageController.clear();
    } catch (e) {
      Get.snackbar(
        "Error!",
        "Something went wrong",
        colorText: Colors.white,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
      );
    } finally {
      isLoading.value = false;
    }
  }
}

/// ---------------- UI PAGE ----------------
class ContactFormPage extends StatelessWidget {
  ContactFormPage({super.key});

  final ContactFormController controller = Get.put(ContactFormController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        title: Text(
          "Contact Us",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              /// Title
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "We'd love to hear from you",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// Name
              _buildField(
                controller: controller.nameController,
                hint: "Your Name",
                icon: Icons.person,
              ),

              const SizedBox(height: 16),

              /// Email
              _buildField(
                controller: controller.emailController,
                hint: "Your Email",
                icon: Icons.email,
              ),

              const SizedBox(height: 16),

              /// Message
              _buildField(
                controller: controller.messageController,
                hint: "Your Message",
                icon: Icons.message,
                maxLines: 5,
              ),

              const SizedBox(height: 30),

              /// Submit Button
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : Text(
                            "Send Message",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ---------------- TEXT FIELD WIDGET ----------------
  static Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.surface.withOpacity(.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          color: Theme.of(Get.context!).colorScheme.onBackground,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Theme.of(Get.context!).colorScheme.primary,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(
              Get.context!,
            ).colorScheme.onBackground.withOpacity(.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
