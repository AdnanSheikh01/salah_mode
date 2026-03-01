import 'package:flutter/material.dart';
import 'package:salah_mode/screens/home_bottom_navbar/profile/contactform.dart';
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
  final int prayerNumber = 3;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),

            /// 🟢 PROFILE HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C853), Color(0xFF009624)],
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
                      color: Colors.white.withOpacity(.2),
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
                  const Expanded(
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
                        SizedBox(height: 4),
                        Text(
                          "adnan@example.com",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  /// ✏️ Edit
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, color: Colors.white),
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
                        ? Colors.yellow
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

            /// ⚙️ SETTINGS LIST
            _tile(Icons.dark_mode_outlined, "Theme", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SelectionThemePage()),
              );
            }, "Select your preferred theme"),
            _tile(Icons.language_outlined, "Language", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LanguageScreen()),
              );
            }, "Select your preferred language"),

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
            _tile(
              Icons.info_outline,
              "About us",
              () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF0F2027),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (_) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Center(
                            child: Text(
                              "About Salah Mode",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Salah Mode is designed to help Muslims stay connected with their daily prayers. "
                            "Track your salah, use smart tasbih, and get accurate prayer times — all in one place.",
                            style: TextStyle(
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Our mission is to make daily ibadah easier, more consistent, and spiritually uplifting for everyone.",
                            style: TextStyle(
                              color: Colors.white54,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                );
              },
              "Learn more about Salah Mode and our mission.",
            ),

            const SizedBox(height: 10),

            Text("App Version 1.0.0", style: TextStyle(color: Colors.white54)),

            const SizedBox(height: 20),

            /// 🚪 LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {},
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Logout",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// 📊 Stat Card
  Widget _statCard(String title, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.greenAccent),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white54)),
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
        color: Colors.white.withOpacity(.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white54,
        ),
        onTap: onTap,
      ),
    );
  }
}
