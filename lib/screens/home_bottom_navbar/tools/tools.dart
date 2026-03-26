import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/duas/duas.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/daily_dhikr.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/daily_hadith.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/islamic_calender.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/nearby_mosque/nearby_mosque.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/ninty_nine_names.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/prayer_guide.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/prayer_times.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/qibla_finder.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/quran/surah_list.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/smart_prayer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const List<_ToolItem> _tools = [
    _ToolItem(
      icon: Icons.track_changes_rounded,
      title: "Daily Dhikr",
      subtitle: "Track your daily dhikr count",
      badge: "NEW",
      category: "Dhikr",
    ),
    _ToolItem(
      icon: Icons.explore_rounded,
      title: "Qibla Finder",
      subtitle: "Find the direction of Kaaba",
      badge: "POPULAR",
      category: "Prayer",
    ),
    _ToolItem(
      icon: Icons.menu_book_rounded,
      title: "Quran",
      subtitle: "Read & memorize the Holy Quran",
      category: "Quran",
    ),
    _ToolItem(
      icon: Icons.access_time_rounded,
      title: "Prayer Times",
      subtitle: "View daily salah timings",
      category: "Prayer",
    ),
    _ToolItem(
      icon: Icons.calendar_month_rounded,
      title: "Islamic Calendar",
      subtitle: "View Hijri date and events",
      category: "Utility",
    ),
    _ToolItem(
      icon: Icons.wb_sunny_rounded,
      title: "99 Names of Allah",
      subtitle: "Read and reflect Asma-ul-Husna",
      category: "Quran",
    ),
    _ToolItem(
      icon: Icons.person_rounded,
      title: "Prayer Guide",
      subtitle: "Prayer tips and techniques",
      badge: "NEW",
      category: "Prayer Guide",
    ),
    _ToolItem(
      icon: Icons.auto_stories_rounded,
      title: "Duas",
      subtitle: "Read daily Masnoon duas",
      badge: "NEW",
      category: "Duas",
    ),
    _ToolItem(
      icon: Icons.format_quote_rounded,
      title: "Daily Hadith",
      subtitle: "Get authentic hadith daily",
      category: "Quran",
    ),
    _ToolItem(
      icon: Icons.mosque_rounded,
      title: "Nearby Mosques",
      subtitle: "Find mosques near you",
      badge: "NEW",
      category: "Utility",
    ),
  ];

  // ── Safe filtered list — never throws ─────────────────────────
  List<_ToolItem> get _filteredTools {
    try {
      if (_query.trim().isEmpty) return _tools;
      final q = _query.toLowerCase().trim();
      return _tools
          .where(
            (e) =>
                e.title.toLowerCase().contains(q) ||
                e.subtitle.toLowerCase().contains(q),
          )
          .toList();
    } catch (_) {
      return _tools; // safe fallback
    }
  }

  // ── Navigation map — safe tap handler ─────────────────────────
  void _handleToolTap(String title) {
    try {
      final routes = <String, VoidCallback>{
        "Daily Dhikr": () => Get.to(() => const DailyDhikrScreen()),
        "Qibla Finder": () => Get.to(() => const QiblaCompassPage()),
        "Quran": () => Get.to(() => const SurahListPage()),
        "Prayer Times": () => Get.to(() => const PrayerTimesScreen()),
        "Islamic Calendar": () => Get.to(() => const IslamicCalenderPage()),
        "99 Names of Allah": () => Get.to(() => const NinetyNineNamesScreen()),
        "Daily Hadith": () => Get.to(() => const DailyHadithScreen()),
        "Nearby Mosques": () => Get.to(() => const NearbyMosqueScreen()),
        "Prayer Guide": () => Get.to(() => const PrayerGuideScreen()),
        "Duas": () => Get.to(() => const DuasScreen()),
      };
      (routes[title] ?? () => Get.to(() => const SmartCompanionScreen()))();
    } catch (e) {
      debugPrint("ToolsScreen: navigation error for '$title': $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    final filtered = _filteredTools;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar ─────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            automaticallyImplyLeading: false,
            toolbarHeight: 56,
            expandedHeight: 56,
            backgroundColor: bgColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 20,
            title: Text(
              "Islamic Tools",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: textPrimary,
              ),
            ),
          ),

          // ── Body ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Search field ──────────────────────────────
                  _SearchField(
                    controller: _searchController,
                    accentColor: accentColor,
                    inputFill: inputFill,
                    textPrimary: textPrimary,
                    textTertiary: textTertiary,
                    borderColor: borderColor,
                    onChanged: (v) {
                      if (mounted) setState(() => _query = v);
                    },
                  ),

                  // ── Recommended section ───────────────────────
                  _SectionTitle(
                    title: "Recommended",
                    goldColor: goldColor,
                    textPrimary: textPrimary,
                  ),

                  const SizedBox(height: 12),

                  _FeaturedTile(
                    icon: Icons.auto_awesome_rounded,
                    title: "Smart Prayer Companion",
                    subtitle: "AI-picked based on your usage",
                    badge: "AI",
                    accentColor: accentColor,
                    btnTextColor: btnTextColor,
                    borderColor: borderColor,
                    cardColor: cardColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      try {
                        Get.to(() => const SmartCompanionScreen());
                      } catch (e) {
                        debugPrint("Navigation error: $e");
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Islamic Tools section ─────────────────────
                  _SectionTitle(
                    title: "Islamic Tools",
                    goldColor: goldColor,
                    textPrimary: textPrimary,
                  ),

                  const SizedBox(height: 12),

                  // Empty state
                  if (filtered.isEmpty)
                    _EmptyState(textTertiary: textTertiary)
                  else
                    // Tool grid — shrinkWrap inside SliverToBoxAdapter is safe
                    AnimationLimiter(
                      child: GridView.builder(
                        itemCount: filtered.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.95,
                            ),
                        itemBuilder: (context, index) {
                          // Guard: index out of range on concurrent state change
                          if (index >= filtered.length) {
                            return const SizedBox.shrink();
                          }
                          final tool = filtered[index];
                          return AnimationConfiguration.staggeredGrid(
                            position: index,
                            columnCount: 2,
                            duration: const Duration(milliseconds: 380),
                            child: ScaleAnimation(
                              child: FadeInAnimation(
                                child: _ToolTile(
                                  tool: tool,
                                  cardColor: cardColor,
                                  accentColor: accentColor,
                                  borderColor: borderColor,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  onTap: () => _handleToolTap(tool.title),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SEARCH FIELD — extracted widget to keep build() clean
// ═══════════════════════════════════════════════════════════════════

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final Color accentColor;
  final Color inputFill;
  final Color textPrimary;
  final Color textTertiary;
  final Color borderColor;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.accentColor,
    required this.inputFill,
    required this.textPrimary,
    required this.textTertiary,
    required this.borderColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: textPrimary,
        ),
        onChanged: onChanged,
        // Prevent excessive rebuilds from keyboard
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search_rounded, color: accentColor, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          hintText: "Search tools...",
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: textTertiary,
          ),
          filled: true,
          fillColor: inputFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accentColor, width: 1.4),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final Color textTertiary;
  const _EmptyState({required this.textTertiary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: textTertiary.withOpacity(0.45),
            ),
            const SizedBox(height: 12),
            Text(
              "No tools found",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SECTION TITLE
// ═══════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color goldColor;
  final Color textPrimary;

  const _SectionTitle({
    required this.title,
    required this.goldColor,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: goldColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FEATURED TILE
// ═══════════════════════════════════════════════════════════════════

class _FeaturedTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color accentColor;
  final Color btnTextColor;
  final Color borderColor;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _FeaturedTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.accentColor,
    required this.btnTextColor,
    required this.borderColor,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Row(
          children: [
            // Icon circle — fixed size, never shrinks
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withOpacity(0.28),
                  width: 0.8,
                ),
              ),
              child: Icon(icon, color: accentColor, size: 21),
            ),

            const SizedBox(width: 14),

            // Text block — Expanded prevents overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Title — Flexible so badge never gets pushed off
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Badge — intrinsic width
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: btnTextColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Arrow — fixed size, never expands
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: textSecondary.withOpacity(0.45),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TOOL GRID TILE
// ═══════════════════════════════════════════════════════════════════

class _ToolTile extends StatelessWidget {
  final _ToolItem tool;
  final Color cardColor;
  final Color accentColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _ToolTile({
    required this.tool,
    required this.cardColor,
    required this.accentColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  Color _badgeBg(String badge) {
    switch (badge) {
      case 'NEW':
        return const Color(0xFF2ECC71);
      case 'POPULAR':
        return const Color(0xFFC8A84B);
      case 'AI':
        return AppTheme.colorInfo;
      default:
        return AppTheme.colorInfo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // LayoutBuilder would be overkill; childAspectRatio=0.95 handles height
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon + badge
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accentColor.withOpacity(0.20),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(tool.icon, size: 28, color: accentColor),
                ),
                if (tool.badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _badgeBg(tool.badge!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tool.badge!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Title — maxLines + ellipsis prevents overflow in narrow cells
            Flexible(
              child: Text(
                tool.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  height: 1.25,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Subtitle — capped at 2 lines
            Flexible(
              child: Text(
                tool.subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: textSecondary.withOpacity(0.7),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DATA MODEL
// ═══════════════════════════════════════════════════════════════════

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
