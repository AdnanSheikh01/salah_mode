import 'package:flutter/material.dart';

class SelectionThemePage extends StatelessWidget {
  const SelectionThemePage({super.key});

  ThemeMode _getThemeMode(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // This is only for UI highlight; replace with your real controller later
    if (brightness == Brightness.dark) {
      return ThemeMode.dark;
    }
    return ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = _getThemeMode(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          "Select Theme",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose your appearance",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _themeCard(
              context,
              title: "System Default",
              icon: Icons.phone_android,
              selected: currentMode == ThemeMode.system,
              onTap: () {
                // TODO: connect with your theme controller
              },
            ),
            const SizedBox(height: 16),
            _themeCard(
              context,
              title: "Light Theme",
              icon: Icons.light_mode,
              selected: currentMode == ThemeMode.light,
              onTap: () {
                // TODO: connect with your theme controller
              },
            ),
            const SizedBox(height: 16),
            _themeCard(
              context,
              title: "Dark Theme",
              icon: Icons.dark_mode,
              selected: currentMode == ThemeMode.dark,
              onTap: () {
                // TODO: connect with your theme controller
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(.18)
              : Colors.white.withOpacity(.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.white.withOpacity(.08),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white70,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
