import 'package:flutter/material.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

Widget field({
  required BuildContext context,
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  VoidCallback? onTap,
  String? Function(String?)? validator,
  bool isPassword = false,
  bool showToggle = true,
  bool obscure = true,
  int maxLines = 1,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return TextFormField(
    maxLines: maxLines,
    controller: controller,
    obscureText: isPassword ? obscure : false,
    validator: validator,
    style: TextStyle(
      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
      prefixIcon: Icon(icon, color: theme.colorScheme.primary),
      suffixIcon: (isPassword && showToggle)
          ? IconButton(
              onPressed: onTap,
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            )
          : null,
      filled: true,
      fillColor: isDark ? AppTheme.darkInputFill : AppTheme.lightInputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
