import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/auth/login.dart';
import 'package:salah_mode/screens/home_bottom_navbar/profile/contact_form.dart';
import 'package:salah_mode/screens/home_bottom_navbar/profile/donation.dart';
import 'package:salah_mode/screens/home_bottom_navbar/profile/about_us.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salah_mode/screens/home_bottom_navbar/profile/language.dart';
import 'package:salah_mode/screens/home_bottom_navbar/profile/madhab_selection.dart';
import 'package:salah_mode/screens/home_bottom_navbar/profile/theme_selection.dart';
import 'package:salah_mode/l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int prayerNumber = 0;
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadPrayerCount();
  }

  Future<void> _loadPrayerCount() async {
    final prefs = await SharedPreferences.getInstance();
    int count = 0;
    for (final key in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
      if (prefs.getBool('tick_$key') ?? false) count++;
    }
    if (mounted) setState(() => prayerNumber = count);
  }

  // ── Prayer count color ─────────────────────────────────────────
  Color _prayerColor(bool isDark) {
    if (prayerNumber >= 4) return AppTheme.colorSuccess;
    if (prayerNumber == 3) return AppTheme.colorWarning;
    return AppTheme.colorError;
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
    final btnTextColor = isDark
        ? AppTheme.darkTextOnAccent
        : AppTheme.lightTextOnAccent;

    final loc = AppLocalizations.of(context)!;

    // Explicit button style — bypasses theme pill shape
    final _logoutBtnStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.all(AppTheme.colorError),
      foregroundColor: MaterialStateProperty.all(Colors.white),
      elevation: MaterialStateProperty.all(0),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(vertical: 15),
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // ── Profile header card ──────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: user == null
                          // Guest state
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.welcome,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: btnTextColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Login to sync your prayers & progress",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: btnTextColor.withOpacity(0.78),
                                  ),
                                ),
                              ],
                            )
                          // Logged in state
                          : Row(
                              children: [
                                // Avatar circle
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: btnTextColor.withOpacity(0.18),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: btnTextColor.withOpacity(0.35),
                                      width: 1.2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    (user?.displayName?.isNotEmpty == true)
                                        ? user!.displayName![0].toUpperCase()
                                        : "U",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: btnTextColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        user?.displayName ?? "User",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: btnTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        user?.email ?? "Signed in",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: btnTextColor.withOpacity(0.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),

                    const SizedBox(width: 12),

                    // Login or edit button
                    user == null
                        ? GestureDetector(
                            onTap: () => Get.to(() => const LoginScreen()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: btnTextColor.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: btnTextColor.withOpacity(0.30),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                loc.login,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: btnTextColor,
                                ),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: btnTextColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                color: btnTextColor.withOpacity(0.85),
                                size: 17,
                              ),
                            ),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Stats row ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: loc.prayersDone,
                      value: "$prayerNumber/5",
                      icon: Icons.mosque_rounded,
                      accentColor: _prayerColor(isDark),
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textTertiary: textTertiary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: loc.streak,
                      value: "0 days",
                      icon: Icons.local_fire_department_rounded,
                      accentColor: AppTheme.colorWarning,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textTertiary: textTertiary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: loc.quranRead,
                      value: "2h 30m",
                      icon: Icons.menu_book_rounded,
                      accentColor: accentColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textTertiary: textTertiary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ── Support banner ───────────────────────────────
              GestureDetector(
                onTap: () => Get.to(() => const DonationScreen()),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: btnTextColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: btnTextColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.supporttheapp,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: btnTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Donate to support Salah Mode",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: btnTextColor.withOpacity(0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: btnTextColor.withOpacity(0.75),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Settings section label ───────────────────────
              _SettingsSectionLabel(
                goldColor: goldColor,
                textPrimary: textPrimary,
              ),

              const SizedBox(height: 12),

              // ── Setting tiles ────────────────────────────────
              _SettingTile(
                icon: Icons.dark_mode_outlined,
                title: loc.theme,
                subtitle: "Choose your preferred theme",
                accentColor: accentColor,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SelectionThemePage()),
                ),
              ),
              _SettingTile(
                icon: Icons.language_rounded,
                title: loc.language,
                subtitle: "Select your preferred language",
                accentColor: accentColor,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LanguageScreen()),
                ),
              ),
              _SettingTile(
                icon: Icons.menu_book_rounded,
                title: loc.madhab,
                subtitle: "Choose your prayer calculation method",
                accentColor: accentColor,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MadhabSelectionScreen()),
                ),
              ),
              _SettingTile(
                icon: Icons.ios_share_rounded,
                title: loc.shareApp,
                subtitle: "Let your friends know about Salah Mode!",
                accentColor: accentColor,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        "🕌 Salah Mode — Stay Connected with Your Salah\n\n"
                        "✨ Track prayers\n📿 Smart tasbih\n⏰ Accurate prayer times\n\n"
                        "Download now:\nhttps://play.google.com/store/apps/details?id=com.example.salah_mode",
                  ),
                ),
              ),
              _SettingTile(
                icon: Icons.star_rounded,
                title: loc.rateUs,
                subtitle: "Love the app? Leave us a review!",
                accentColor: accentColor,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () async {
                  final uri = Uri.parse(
                    "https://play.google.com/store/apps/details?id=com.example.salah_mode",
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              _SettingTile(
                icon: Icons.support_agent_rounded,
                title: loc.contactUs,
                subtitle: "Need help? We're here for you",
                accentColor: accentColor,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ContactFormPage()),
                ),
              ),
              _SettingTile(
                icon: Icons.info_outline_rounded,
                title: loc.aboutUs,
                subtitle: "Learn more about Salah Mode",
                accentColor: accentColor,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onTap: () => Get.to(() => const AboutUsPage()),
                showDivider: false,
              ),

              const SizedBox(height: 16),

              // Version
              Text(
                "Version 1.0.0",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: textTertiary.withOpacity(0.55),
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 20),

              // ── Logout button ────────────────────────────────
              if (user != null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: _logoutBtnStyle,
                    onPressed: () => Get.dialog(
                      _LogoutDialog(
                        accentColor: accentColor,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        btnTextColor: btnTextColor,
                        onLogout: () async {
                          await FirebaseAuth.instance.signOut();
                          if (mounted) setState(() => user = null);
                          Get.back();
                        },
                        loc: loc,
                      ),
                    ),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      loc.logout,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STAT CARD
// ═══════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textTertiary;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textTertiary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SETTINGS SECTION LABEL
// ═══════════════════════════════════════════════════════════════════

class _SettingsSectionLabel extends StatelessWidget {
  final Color goldColor;
  final Color textPrimary;
  const _SettingsSectionLabel({
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
        Text(
          "Settings",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SETTING TILE
// ═══════════════════════════════════════════════════════════════════

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withOpacity(0.22),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(icon, color: accentColor, size: 17),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: textSecondary.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: textSecondary.withOpacity(0.40),
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const SizedBox(height: 10),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  LOGOUT DIALOG
// ═══════════════════════════════════════════════════════════════════

class _LogoutDialog extends StatelessWidget {
  final Color accentColor;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color btnTextColor;
  final VoidCallback onLogout;
  final AppLocalizations loc;

  const _LogoutDialog({
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.btnTextColor,
    required this.onLogout,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 340),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Transform.scale(
          scale: value.clamp(0.0, 1.0),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon ──────────────────────────────────────────
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withOpacity(0.18),
                          width: 1,
                        ),
                      ),
                    ),
                    // Middle ring
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withOpacity(0.07),
                        border: Border.all(
                          color: accentColor.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                    ),
                    // Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withOpacity(0.12),
                      ),
                      child: Icon(
                        Icons.mosque_rounded,
                        color: accentColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Text(
                loc.leaveSalahMode,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Are you sure you want to sign out?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              Divider(color: borderColor, thickness: 0.8),

              const SizedBox(height: 18),

              // ── Buttons ───────────────────────────────────────
              Row(
                children: [
                  // Stay
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentColor.withOpacity(0.22),
                            width: 0.8,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          loc.stay,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Sign out
                  Expanded(
                    child: GestureDetector(
                      onTap: onLogout,
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.colorError,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          loc.logout,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
