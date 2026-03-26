import 'package:flutter/material.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

// ─────────────────────────────────────────────────────────────────
// APP INFO
// ─────────────────────────────────────────────────────────────────

class AppInfo {
  static const String appName = "Salah Mode";
  static const String version = "1.0.0";
  static const String tagline = "Your Companion for Salah & Spiritual Focus";

  static const List<Map<String, dynamic>> features = [
    {
      "icon": Icons.access_time_rounded,
      "title": "Prayer Times",
      "desc": "Accurate times based on your GPS location",
      "color": AppTheme.fajrColor,
    },
    {
      "icon": Icons.menu_book_rounded,
      "title": "Quran Reader",
      "desc": "Beautiful Quranic reading and memorisation",
      "color": AppTheme.colorSuccess,
    },
    {
      "icon": Icons.blur_circular_rounded,
      "title": "Tasbih Counter",
      "desc": "Track your daily dhikr with ease",
      "color": AppTheme.colorWarning,
    },
    {
      "icon": Icons.mosque_rounded,
      "title": "Nearby Mosques",
      "desc": "Find and verify mosques near you",
      "color": AppTheme.colorInfo,
    },
    {
      "icon": Icons.auto_awesome_rounded,
      "title": "AI Companion",
      "desc": "Islamic guidance powered by AI",
      "color": AppTheme.ishaColor,
    },
    {
      "icon": Icons.leaderboard_rounded,
      "title": "Leaderboard",
      "desc": "Compete with your community in worship",
      "color": AppTheme.asrColor,
    },
  ];

  static const List<Map<String, String>> principles = [
    {
      "arabic": "الإخلاص",
      "title": "Sincerity",
      "desc":
          "Built with the intention of helping Muslims connect with Allah ﷻ",
    },
    {
      "arabic": "الخشوع",
      "title": "Khushu",
      "desc":
          "Every screen is designed to reduce distraction and increase focus",
    },
    {
      "arabic": "الأمانة",
      "title": "Trust",
      "desc": "Your data is private, your experience is ad-free",
    },
  ];
}

// ─────────────────────────────────────────────────────────────────
// ABOUT US PAGE
// ─────────────────────────────────────────────────────────────────

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final cardAltColor = isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final goldColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccentGold;
    final textPrimary = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
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
          "About Salah Mode",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero card ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // App icon
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: btnTextColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: btnTextColor.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.mosque_rounded,
                      size: 36,
                      color: btnTextColor,
                    ),
                  ),

                  const SizedBox(height: 4),
                  Text(
                    AppInfo.appName,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: btnTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppInfo.tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: btnTextColor.withOpacity(0.75),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Version badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: btnTextColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Version ${AppInfo.version}",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: btnTextColor.withOpacity(0.80),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Mission ──────────────────────────────────────────
            _SectionLabel(
              label: "Our Mission",
              goldColor: goldColor,
              textPrimary: textPrimary,
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: goldColor.withOpacity(0.22),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  // Gold ornament
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 0.7,
                        color: goldColor.withOpacity(0.35),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "✦",
                        style: TextStyle(fontSize: 12, color: goldColor),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 28,
                        height: 0.7,
                        color: goldColor.withOpacity(0.35),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.68,
                      ),
                      children: [
                        TextSpan(
                          text:
                              "Salah Mode is a powerful Islamic companion thoughtfully "
                              "designed to help Muslims stay consistent with their daily "
                              "prayers and spiritual routine. In today's fast-paced digital "
                              "world, many believers struggle to maintain focus and discipline "
                              "in their worship. Salah Mode aims to solve this by providing "
                              "a calm, distraction-free environment where users can easily "
                              "access essential Islamic tools in one place.\n\n",
                        ),
                        TextSpan(
                          text: "Our mission",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                        TextSpan(
                          text:
                              " is simple: to use technology in a meaningful way that "
                              "brings Muslims closer to their prayers and to Allah ﷻ. "
                              "We are continuously improving the app to add more beneficial "
                              "features while keeping the experience smooth, beautiful, "
                              "and easy to use.\n\n",
                        ),
                        TextSpan(
                          text:
                              "May Salah Mode be a source of barakah in your daily life.",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontStyle: FontStyle.italic,
                            color: goldColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Features grid ────────────────────────────────────
            _SectionLabel(
              label: "What's Inside",
              goldColor: goldColor,
              textPrimary: textPrimary,
            ),
            const SizedBox(height: 10),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: AppInfo.features
                  .map(
                    (f) => Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (f['color'] as Color).withOpacity(0.20),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: (f['color'] as Color).withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              f['icon'] as IconData,
                              size: 17,
                              color: f['color'] as Color,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            f['title'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            f['desc'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 24),

            // ── Core principles ───────────────────────────────────
            _SectionLabel(
              label: "Our Principles",
              goldColor: goldColor,
              textPrimary: textPrimary,
            ),
            const SizedBox(height: 10),

            ...AppInfo.principles.map(
              (p) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Row(
                  children: [
                    // Arabic word circle
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withOpacity(0.20),
                          width: 0.8,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          p['arabic']!,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 14,
                            color: goldColor,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['title']!,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            p['desc']!,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Ad-free note ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardAltColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.colorSuccess.withOpacity(0.25),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.colorSuccess.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.block_rounded,
                      size: 20,
                      color: AppTheme.colorSuccess,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "100% Ad-Free",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.colorSuccess,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Salah Mode will never show ads. "
                          "Worship should never be interrupted.",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Closing dua ───────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: goldColor.withOpacity(0.25),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "اللَّهُمَّ اجْعَلْنَا مِنَ الْمُصَلِّينَ",
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 20,
                      color: goldColor,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "O Allah, make us among those who establish the prayer.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "May Allah place barakah in your prayers 🤲",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────

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
    crossAxisAlignment: CrossAxisAlignment.center,
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
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
    ],
  );
}
