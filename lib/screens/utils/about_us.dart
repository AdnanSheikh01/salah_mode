import 'package:flutter/material.dart';

/// 📌 App description (reuse anywhere)
class AppInfo {
  static const String appName = "Salah Mode";

  static const String brief =
      "Salah Mode is a powerful Islamic companion thoughtfully designed to help Muslims stay consistent with their daily prayers and spiritual routine. In today’s fast‑paced digital world, many believers struggle to maintain focus and discipline in their worship. Salah Mode aims to solve this by providing a calm, distraction‑free environment where users can easily access essential Islamic tools in one place.\n\n"
      "With accurate prayer times based on your location, the app ensures you never miss an important salah. The beautifully designed Quran section supports both reading and memorisation, making it ideal for learners and Huffaz alike. The integrated tasbih counter allows you to keep track of your dhikr with ease, while additional Islamic utilities enhance your daily ibadah experience.\n\n"
      "What makes Salah Mode truly special is its *clean, focused, and spiritually mindful design*. Every screen is crafted to reduce noise and increase khushu (concentration) during worship. Whether you are at home, at work, or travelling, Salah Mode acts as your reliable companion on the journey of faith.\n\n"
      "**Our mission** is simple: to use technology in a meaningful way that brings Muslims closer to their prayers and to Allah ﷻ. We are continuously improving the app to add more beneficial features while keeping the experience smooth, beautiful, and easy to use.\n\n"
      "*May Salah Mode be a source of barakah in your daily life.*";
}

/// 🕌 About Us Screen
class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About Salah Mode")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppInfo.appName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: _buildFormattedText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _buildFormattedText(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium!;
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);
    final italicStyle = baseStyle.copyWith(fontStyle: FontStyle.italic);

    return [
      TextSpan(
        text:
            "Salah Mode is a powerful Islamic companion thoughtfully designed to help Muslims stay consistent with their daily prayers and spiritual routine. In today’s fast‑paced digital world, many believers struggle to maintain focus and discipline in their worship. Salah Mode aims to solve this by providing a calm, distraction‑free environment where users can easily access essential Islamic tools in one place.\n\n",
      ),
      TextSpan(
        text:
            "With accurate prayer times based on your location, the app ensures you never miss an important salah. The beautifully designed Quran section supports both reading and memorisation, making it ideal for learners and Huffaz alike. The integrated tasbih counter allows you to keep track of your dhikr with ease, while additional Islamic utilities enhance your daily ibadah experience.\n\n",
      ),
      TextSpan(text: "What makes Salah Mode truly special is its "),
      TextSpan(
        text: "clean, focused, and spiritually mindful design",
        style: italicStyle,
      ),
      TextSpan(
        text:
            ". Every screen is crafted to reduce noise and increase khushu (concentration) during worship. Whether you are at home, at work, or travelling, Salah Mode acts as your reliable companion on the journey of faith.\n\n",
      ),
      TextSpan(text: "Our mission", style: boldStyle),
      TextSpan(
        text:
            " is simple: to use technology in a meaningful way that brings Muslims closer to their prayers and to Allah ﷻ. We are continuously improving the app to add more beneficial features while keeping the experience smooth, beautiful, and easy to use.\n\n",
      ),
      TextSpan(
        text: "May Salah Mode be a source of barakah in your daily life.",
        style: italicStyle,
      ),
    ];
  }
}
