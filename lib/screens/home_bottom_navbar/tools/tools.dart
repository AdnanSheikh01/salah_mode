import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/daily_dhikr.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/daily_hadith.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/islamic_calender.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/nearby_mosque.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/ninty_nine_names.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/prayer_guide.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/prayer_times.dart';

import 'package:salah_mode/screens/home_bottom_navbar/tools/qibla_finder.dart';
import 'package:salah_mode/screens/home_bottom_navbar/surah_list.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/smart_prayer.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = "";

  final List<_ToolItem> _tools = [
    _ToolItem(
      icon: Icons.track_changes,
      title: "Daily Dhikr",
      subtitle: "Track your daily dhikr count",
      badge: "NEW",
      category: "Dhikr",
    ),
    _ToolItem(
      icon: Icons.explore,
      title: "Qibla Finder",
      subtitle: "Find the direction of Kaaba",
      badge: "POPULAR",
      category: "Prayer",
    ),
    _ToolItem(
      icon: Icons.menu_book,
      title: "Quran",
      subtitle: "Read/Memorize the Holy Quran",
      category: "Quran",
    ),
    _ToolItem(
      icon: Icons.access_time,
      title: "Prayer Times",
      subtitle: "View daily salah timings",
      category: "Prayer",
    ),
    _ToolItem(
      icon: Icons.calendar_month,
      title: "Islamic Calendar",
      subtitle: "View Hijri date and events",
      category: "Utility",
    ),
    _ToolItem(
      icon: Icons.wb_sunny,
      title: "99 Names of Allah",
      subtitle: "Read and reflect Asma-ul-Husna",
      category: "Quran",
    ),
    _ToolItem(
      icon: Icons.person,
      title: "Prayer Guide",
      subtitle: "Prayer Tips and Techniques",
      badge: "NEW",
      category: "Prayer Guide",
    ),
    _ToolItem(
      icon: Icons.auto_stories,
      title: "Daily Hadith",
      subtitle: "Get authentic hadith daily",
      category: "Quran",
    ),
    _ToolItem(
      icon: Icons.mosque,
      title: "Nearby Mosques",
      subtitle: "Find mosques near you",
      badge: "NEW",
      category: "Utility",
    ),
  ];

  List<_ToolItem> get _filteredTools {
    if (_query.isEmpty) return _tools;
    return _tools
        .where(
          (e) =>
              e.title.toLowerCase().contains(_query.toLowerCase()) ||
              e.subtitle.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            expandedHeight: 120,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              title: Text(
                "Discover Tools ✨",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor,
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // SEARCH
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      hintText: "Search tools...",
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(.6),
                      hintStyle: TextStyle(
                        color: Theme.of(context).hintColor.withOpacity(.7),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.green, width: 1.4),
                      ),
                    ),
                    onChanged: (v) {
                      setState(() => _query = v);
                    },
                  ),
                ),

                _sectionTitle("Recommended for You 🧠"),
                const SizedBox(height: 12),
                _premiumTile(
                  icon: Icons.star,
                  title: "Smart Prayer Companion",
                  subtitle: "AI-picked based on your usage",
                  badge: "AI",
                  onTap: _openSmartCompanion,
                ),
                const SizedBox(height: 28),

                _sectionTitle("Islamic Tools"),
                const SizedBox(height: 16),

                if (_filteredTools.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        "No tools found",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),

                ..._filteredTools.map(
                  (tool) => _premiumTile(
                    icon: tool.icon,
                    title: tool.title,
                    subtitle: tool.subtitle,
                    badge: tool.badge,
                    onTap: () {
                      if (tool.title == "Daily Dhikr") {
                        _openDailyDhikr();
                      } else if (tool.title == "Qibla Finder") {
                        _openQiblaFinder();
                      } else if (tool.title == "Quran") {
                        _openQuranPage();
                      } else if (tool.title == "Prayer Times") {
                        _openPrayerTimes();
                      } else if (tool.title == "Islamic Calendar") {
                        _openIslamicCalender();
                      } else if (tool.title == "99 Names of Allah") {
                        _openNintyNineNamesPage();
                      } else if (tool.title == "Daily Hadith") {
                        _opendailyHadith();
                      } else if (tool.title == "Nearby Mosques") {
                        _openNearbyMosques();
                      } else if (tool.title == "Prayer Guide") {
                        _openPrayerGuide();
                      } else {
                        _openSmartCompanion();
                      }
                    },
                  ),
                ),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(Get.context!).colorScheme.onSurface,
        fontSize: 19,
        fontWeight: FontWeight.bold,
        letterSpacing: .3,
      ),
    );
  }

  static Widget _premiumTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            scale: 1,
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).cardColor,
                    Theme.of(context).colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.35),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.tealAccent.withOpacity(.35),
                          Colors.tealAccent.withOpacity(.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(.7),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFB74D), Color(0xFFFF7043)],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- ACTIONS ----------

  void _opendailyHadith() {
    Get.to(() => const DailyHadithScreen());
  }

  void _openQiblaFinder() {
    Get.to(() => const QiblaCompassPage());
  }

  void _openQuranPage() {
    Get.to(() => const SurahListPage());
  }

  void _openPrayerTimes() {
    Get.to(() => const PrayerTimesScreen());
  }

  void _openIslamicCalender() {
    Get.to(() => const IslamicCalenderPage());
  }

  void _openNintyNineNamesPage() {
    Get.to(() => const NinetyNineNamesScreen());
  }

  void _openDailyDhikr() {
    Get.to(() => const DailyDhikrScreen());
  }

  void _openNearbyMosques() {
    Get.to(() => const NearbyMosqueScreen());
  }

  void _openPrayerGuide() {
    Get.to(() => const PrayerGuideScreen());
  }

  void _openSmartCompanion() {
    Get.to(() => const SmartCompanionScreen());
  }
}

class _ToolItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final String category;

  const _ToolItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.category,
  });
}
