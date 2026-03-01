import 'package:flutter/material.dart';
import 'package:salah_mode/screens/home_bottom_navbar/home.dart';
import 'package:salah_mode/screens/home_bottom_navbar/profile/profile.dart';
import 'package:salah_mode/screens/home_bottom_navbar/qibla.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tasbih.dart';

class SalahMainScreen extends StatefulWidget {
  const SalahMainScreen({super.key});

  @override
  State<SalahMainScreen> createState() => _SalahMainScreenState();
}

class _SalahMainScreenState extends State<SalahMainScreen> {
  int currentIndex = 0;

  final pages = const [HomePage(), TasbihPage(), QiblaPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: pages[currentIndex],
      bottomNavigationBar: _bottomBar(),
    );
  }

  /// 🌙 Glass Bottom Bar
  Widget _bottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, "Home", 0),
          _navItem(Icons.touch_app_rounded, "Tasbih", 1),
          _navItem(Icons.settings_suggest_rounded, "Tools", 2),
          _navItem(Icons.person_rounded, "Profile", 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final selected = currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selected ? const Color(0xFF00E676) : Colors.white54,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF00E676) : Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
