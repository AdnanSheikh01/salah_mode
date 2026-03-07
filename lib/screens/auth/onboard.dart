import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:salah_mode/screens/main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  final List<Map<String, String>> pages = [
    {
      "title": "Never Miss Salah",
      "desc":
          "Stay connected with your daily prayers and build consistency in your spiritual journey.",
      "icon": "🕌",
    },
    {
      "title": "Smart Prayer Reminders",
      "desc":
          "Get accurate prayer times and beautiful reminders wherever you are.",
      "icon": "⏰",
    },
    {
      "title": "Digital Tasbih Counter",
      "desc":
          "Use the built-in digital tasbih to count your dhikr anytime with a smooth and distraction-free experience.",
      "icon": "📿",
    },
    {
      "title": "Daily Dhikr Focus Mode",
      "desc":
          "Receive daily dhikr notifications and stay focused while the app helps minimize distractions from other apps.",
      "icon": "🌙",
    },
    {
      "title": "Track Your Progress",
      "desc":
          "Monitor your daily prayer performance and stay motivated every day.",
      "icon": "📊",
    },
  ];

  void _finishOnboarding() {
    final box = GetStorage();
    box.write('first_time', false);
    Get.offAll(() => const SalahMainScreen());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF061A22), Color(0xFF0F2C36)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: const Text("Skip"),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() => currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final page = pages[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            page["icon"]!,
                            style: const TextStyle(fontSize: 72),
                          ),
                          const SizedBox(height: 30),

                          Text(
                            page["title"]!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            page["desc"]!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentIndex == index ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentIndex == index
                          ? theme.colorScheme.primary
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Next / Get Started
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: () {
                    if (currentIndex == pages.length - 1) {
                      _finishOnboarding();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    currentIndex == pages.length - 1 ? "Get Started" : "Next",
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
