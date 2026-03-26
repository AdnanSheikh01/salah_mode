import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  DateTime? _lastPressed;

  final pages = const [
    HomePage(),
    TasbihPage(),
    ToolsScreen(),
    LeaderboardScreen(),
    ProfilePage(),
  ];

  /// The Exit Dialog logic with time-based Duas
  void _showExitDialog() {
    HapticFeedback.heavyImpact();

    final hour = DateTime.now().hour;
    String arabic = "", english = "", translation = "";

    if (hour >= 5 && hour < 12) {
      arabic =
          "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ";
      english =
          "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur";
      translation =
          "Praise be to Allah who gave us life after He had given us death";
    } else if (hour >= 12 && hour < 17) {
      arabic = "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ";
      english = "Ya Hayyu Ya Qayyum, bi-rahmatika astagheeth";
      translation =
          "O Ever-Living, O Self-Sustaining, by Your mercy I seek help";
    } else if (hour >= 17 && hour < 21) {
      arabic = "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ";
      english = "Amsayna wa amsal-mulku lillah";
      translation = "Evening has come and the Kingdom belongs to Allah";
    } else {
      arabic = "اللَّهُمَّ بِاسْمِكَ أَمُوتُ وَأَحْيَا";
      english = "Allahumma bismika amutu wa ahya";
      translation = "O Allah, in Your name I die and I live";
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mosque_rounded,
                color: Color(0xFF00C853),
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                "Recite & Reflect",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                arabic,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                english,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF00C853).withOpacity(0.8),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Divider(height: 32, color: Colors.white10),
              Text(
                translation,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Stay"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: _AutoEnableExitButton()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final now = DateTime.now();
        final isDoubleTap =
            _lastPressed != null &&
            now.difference(_lastPressed!) <= const Duration(seconds: 2);

        if (isDoubleTap) {
          _showExitDialog();
        } else {
          _lastPressed = now;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tap again to exit"),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: pages[currentIndex],
        bottomNavigationBar: _bottomBar(),
      ),
    );
  }

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

class _AutoEnableExitButton extends StatefulWidget {
  const _AutoEnableExitButton();
  @override
  State<_AutoEnableExitButton> createState() => _AutoEnableExitButtonState();
}

class _AutoEnableExitButtonState extends State<_AutoEnableExitButton> {
  bool _isEnabled = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Only trigger exit if enabled
      onTap: _isEnabled ? () => SystemNavigator.pop() : null,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 2),
        onEnd: () => setState(() => _isEnabled = true),
        builder: (context, value, child) {
          return Container(
            height: 48,
            clipBehavior: Clip.hardEdge, // Clips the green progress fill
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The Growing Progress Background
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width * 0.4 * value,
                  child: Container(color: const Color(0xFF00C853)),
                ),
                // The Button Label
                Text(
                  "Exit",
                  style: TextStyle(
                    color: _isEnabled ? Colors.white : Colors.white24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
