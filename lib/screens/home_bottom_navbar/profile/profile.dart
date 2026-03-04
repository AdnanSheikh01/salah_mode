import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/home_bottom_navbar/profile/contactform.dart';
import 'package:salah_mode/screens/utils/about_us.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:salah_mode/screens/home_bottom_navbar/profile/language.dart';
import 'package:salah_mode/screens/home_bottom_navbar/profile/madhab_selection.dart';
import 'package:salah_mode/screens/home_bottom_navbar/profile/themeselection.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final int prayerNumber = 2;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              const SizedBox(height: 10),

              /// 🟢 PROFILE HEADER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    /// 👤 Avatar
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withOpacity(.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 16),

                    /// 🧾 Name & Email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Adnan Sheikh",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("adnan@example.com"),
                        ],
                      ),
                    ),

                    /// ✏️ Edit
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.edit,
                        color: Colors.white.withOpacity(.8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// 📊 STATS
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      "Prayers Done",
                      "$prayerNumber/5",
                      Icons.mosque,
                      color: prayerNumber == 4 || prayerNumber == 5
                          ? Colors.green
                          : prayerNumber == 3
                          ? Colors.yellow[700]
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      "Streak",
                      "0 days",
                      Icons.local_fire_department,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard("Quran Read", "2h 30m", Icons.menu_book),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              /// 💚 SUPPORT APP (SPECIAL)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    // TODO: add support link / donation page
                  },
                  child: Row(
                    children: [
                      Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Support the App",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Donate to support Salah Mode",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              /// ⚙️ SETTINGS LIST
              _tile(Icons.dark_mode_outlined, "Theme", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SelectionThemePage(
                      currentMode: ThemeMode.system,
                      onChanged: (_) {},
                    ),
                  ),
                );
              }, "Select your preferred theme"),
              _tile(
                Icons.language_outlined,
                "Language",
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LanguageScreen()),
                  );
                },
                "Select your preferred language",
              ),

              _tile(
                Icons.menu_book,
                "Madhab",
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MadhabSelectionScreen()),
                  );
                },
                "Choose your preferred prayer calculation method",
              ),
              _tile(
                Icons.ios_share_outlined,
                "Share App",
                () {
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          "🕌 Salah Mode — Stay Connected with Your Salah\n\n✨ Track prayers\n📿 Smart tasbih\n⏰ Accurate prayer times\n\nDownload now and strengthen your daily ibadah:\nhttps://play.google.com/store/apps/details?id=com.example.salah_mode",
                    ),
                  );
                },
                "Let your friends know about Salah Mode!",
              ),
              _tile(Icons.star, "Rate us", () async {
                const url =
                    "https://play.google.com/store/apps/details?id=com.example.salah_mode";
                final uri = Uri.parse(url);

                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  debugPrint("Could not launch Play Store");
                }
              }, "Love the app? Leave us a review!"),
              _tile(Icons.support_agent, "Contact us", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ContactFormPage()),
                );
              }, "Need help? We're here for you!"),

              _tile(Icons.info_outline, "About us", () {
                Get.to(() => const AboutUsPage());
              }, "Learn more about Salah Mode"),

              const SizedBox(height: 10),

              Text(
                "App Version 1.0.0",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(.6),
                ),
              ),

              const SizedBox(height: 20),

              /// 🚪 LOGOUT BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {},
                  icon: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.onError,
                  ),
                  label: Text(
                    "Logout",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onError,
                    ),
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

  /// 📊 Stat Card
  Widget _statCard(String title, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color ?? Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.6),
            ),
          ),
        ],
      ),
    );
  }

  /// ⚙️ Setting Tile
  Widget _tile(
    IconData icon,
    String title,
    VoidCallback onTap,
    String subtitle,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(.3),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.6),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(.5),
        ),
        onTap: onTap,
      ),
    );
  }
}
