import 'package:flutter/material.dart';
import 'package:salah_mode/screens/home_bottom_navbar/home.dart';
import 'package:salah_mode/screens/home_bottom_navbar/profile/profile.dart';
import 'package:salah_mode/screens/home_bottom_navbar/rank_screen.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/tools.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tasbih.dart';

class SalahMainScreen extends StatefulWidget {
  const SalahMainScreen({super.key});

  @override
  State<SalahMainScreen> createState() => _SalahMainScreenState();
}

class _SalahMainScreenState extends State<SalahMainScreen> {
  int currentIndex = 0;

  final pages = const [
    HomePage(),
    TasbihPage(),
    ToolsScreen(),
    LeaderboardScreen(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        color: Theme.of(context).colorScheme.surface.withOpacity(.2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, "Home", 0),
          _navItem(Icons.touch_app_rounded, "Tasbih", 1),
          _navItem(Icons.settings_suggest_rounded, "Tools", 2),
          _navItem(Icons.leaderboard, "Rank", 3),
          _navItem(Icons.person_rounded, "Profile", 4),
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
            color: selected
                ? Colors.green
                : Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(.6),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.green
                  : Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
