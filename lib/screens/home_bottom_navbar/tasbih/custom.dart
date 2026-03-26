import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';
import 'package:translator/translator.dart';

class RecommendedDuaPage extends StatelessWidget {
  const RecommendedDuaPage({super.key});

  final List<Map<String, dynamic>> duas = const [
    {
      "name": "SubhanAllahi wa bihamdihi",
      "arabic": "سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ",
      "translation": "Glory be to Allah and praise be to Him",
    },
    {
      "name": "SubhanAllahi al-Azim",
      "arabic": "سُبْحَانَ اللّٰهِ الْعَظِيمِ",
      "translation": "Glory be to Allah, the Most Great",
    },
    {
      "name": "SubhanAllahi wa bihamdihi SubhanAllahil Azim",
      "arabic": "سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ سُبْحَانَ اللّٰهِ الْعَظِيمِ",
      "translation":
          "Glory be to Allah and praise be to Him, glory be to Allah the Most Great",
    },
    {
      "name": "Allahumma inni zalamtu nafsi zulman kathiran",
      "arabic": "اللّٰهُمَّ إِنِّي ظَلَمْتُ نَفْسِي ظُلْمًا كَثِيرًا",
      "translation": "O Allah, I have greatly wronged myself",
    },
    {
      "name": "Allahumma anta as-salam wa minkas-salam",
      "arabic": "اللّٰهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ",
      "translation": "O Allah, You are Peace and from You comes peace",
    },
    {
      "name": "La ilaha illa Allah",
      "arabic": "لَا إِلٰهَ إِلَّا اللّٰهُ",
      "translation": "There is no deity worthy of worship except Allah",
    },
    {
      "name": "La ilaha illa Allah wahdahu la sharika lah",
      "arabic": "لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ",
      "translation": "There is no god but Allah alone, without partner",
    },
    {
      "name": "La hawla wa la quwwata illa billah",
      "arabic": "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ",
      "translation": "There is no power and no strength except with Allah",
    },
    {
      "name": "Astaghfirullah",
      "arabic": "أَسْتَغْفِرُ اللّٰهَ",
      "translation": "I seek forgiveness from Allah",
    },
    {
      "name": "Astaghfirullaha wa atubu ilayh",
      "arabic": "أَسْتَغْفِرُ اللّٰهَ وَأَتُوبُ إِلَيْهِ",
      "translation": "I seek Allah's forgiveness and repent to Him",
    },
    {
      "name": "Allahumma salli ala Muhammad",
      "arabic": "اللّٰهُمَّ صَلِّ عَلَى مُحَمَّدٍ",
      "translation": "O Allah, send blessings upon Muhammad",
    },
    {
      "name": "Allahumma barik ala Muhammad",
      "arabic": "اللّٰهُمَّ بَارِكْ عَلَى مُحَمَّدٍ",
      "translation": "O Allah, bless Muhammad",
    },
    {
      "name": "Allahumma salli wa sallim ala nabiyyina Muhammad",
      "arabic": "اللّٰهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ",
      "translation":
          "O Allah, send prayers and peace upon our Prophet Muhammad",
    },
    {
      "name": "HasbiyaAllahu la ilaha illa Huwa",
      "arabic": "حَسْبِيَ اللّٰهُ لَا إِلٰهَ إِلَّا هُوَ",
      "translation": "Allah is sufficient for me; there is no deity except Him",
    },
    {
      "name": "La ilaha illa anta subhanaka inni kuntu minaz-zalimin",
      "arabic":
          "لَا إِلٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ",
      "translation":
          "There is no deity except You; glory be to You, I was among the wrongdoers",
    },
    {
      "name": "Allahumma innaka afuwwun tuhibbul afwa fafu anni",
      "arabic": "اللّٰهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي",
      "translation":
          "O Allah, You are Most Forgiving and love forgiveness, so forgive me",
    },
    {
      "name": "Allahumma inni as'aluka al-jannah",
      "arabic": "اللّٰهُمَّ إِنِّي أَسْأَلُكَ الْجَنَّةَ",
      "translation": "O Allah, I ask You for Paradise",
    },
    {
      "name": "Allahumma ajirni min an-naar",
      "arabic": "اللّٰهُمَّ أَجِرْنِي مِنَ النَّارِ",
      "translation": "O Allah, protect me from the Hellfire",
    },
    {
      "name": "Rabbi ighfir li",
      "arabic": "رَبِّ اغْفِرْ لِي",
      "translation": "My Lord, forgive me",
    },
    {
      "name": "Rabbi zidni ilma",
      "arabic": "رَبِّ زِدْنِي عِلْمًا",
      "translation": "My Lord, increase me in knowledge",
    },
    {
      "name": "Allahumma inni as'aluka al-afiyah",
      "arabic": "اللّٰهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ",
      "translation": "O Allah, I ask You for well-being",
    },
    {
      "name": "Allahumma inni a'udhu bika min al-hammi wal-hazan",
      "arabic": "اللّٰهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ",
      "translation": "O Allah, I seek refuge in You from worry and sadness",
    },
    {
      "name": "Allahumma inni as'aluka rizqan tayyiban",
      "arabic": "اللّٰهُمَّ إِنِّي أَسْأَلُكَ رِزْقًا طَيِّبًا",
      "translation": "O Allah, grant me pure and lawful provision",
    },
    {
      "name": "Allahumma inni as'aluka ilman nafi'an",
      "arabic": "اللّٰهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا",
      "translation": "O Allah, grant me beneficial knowledge",
    },
    {
      "name":
          "Rabbana atina fid-dunya hasanah wa fil-akhirati hasanah wa qina adhaban-nar",
      "arabic":
          "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
      "translation":
          "Our Lord, give us good in this world and good in the Hereafter and protect us from the punishment of the Fire",
    },
    {
      "name": "Rabbi inni lima anzalta ilayya min khairin faqir",
      "arabic": "رَبِّ إِنِّي لِمَا أَنْزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ",
      "translation":
          "My Lord, indeed I am in need of whatever good You send down to me",
    },
    {
      "name": "Allahumma thabbit qalbi ala dinik",
      "arabic": "اللّٰهُمَّ ثَبِّتْ قَلْبِي عَلَى دِينِكَ",
      "translation": "O Allah, keep my heart firm upon Your religion",
    },
    {
      "name": "Allahumma inni as'aluka al-huda wat-tuqa wal-afafa wal-ghina",
      "arabic":
          "اللّٰهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى",
      "translation":
          "O Allah, I ask You for guidance, piety, chastity, and self-sufficiency",
    },
  ];

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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: accentColor,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Recommended Dhikr",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: duas.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          // ── "Custom Tasbih" tile (index 0) ───────────────────
          if (index == 0) {
            return GestureDetector(
              onTap: () => _showCustomDialog(
                context,
                isDark,
                cardColor,
                accentColor,
                goldColor,
                textPrimary,
                textSecondary,
                borderColor,
                btnTextColor,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: btnTextColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
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
                            "Custom Tasbih",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: btnTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Create your own dhikr with custom count",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: btnTextColor.withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: btnTextColor.withOpacity(0.70),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Dua tile ─────────────────────────────────────────
          final dua = duas[index - 1];

          return GestureDetector(
            onTap: () => _showCountDialog(
              context,
              dua,
              isDark,
              cardColor,
              accentColor,
              goldColor,
              textPrimary,
              textSecondary,
              borderColor,
              btnTextColor,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dua["arabic"] != null) ...[
                          Text(
                            dua["arabic"],
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: goldColor,
                              height: 1.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          dua["name"],
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dua["translation"],
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: textSecondary.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Count picker dialog ────────────────────────────────────────
  Future<void> _showCountDialog(
    BuildContext context,
    Map<String, dynamic> dua,
    bool isDark,
    Color cardColor,
    Color accentColor,
    Color goldColor,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color btnTextColor,
  ) async {
    final controller = TextEditingController();

    final result = await Get.dialog<int>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Arabic
              if (dua["arabic"] != null)
                Center(
                  child: Text(
                    dua["arabic"],
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: goldColor,
                      height: 2.0,
                    ),
                  ),
                ),

              const SizedBox(height: 6),

              Center(
                child: Text(
                  dua["name"],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Set count target",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: "e.g. 33",
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    color: textSecondary.withOpacity(0.4),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _dialogBtn(
                      label: "Cancel",
                      color: accentColor.withOpacity(0.08),
                      textColor: accentColor,
                      borderColor: accentColor.withOpacity(0.22),
                      onTap: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dialogBtn(
                      label: "Add",
                      color: accentColor,
                      textColor: btnTextColor,
                      borderColor: accentColor,
                      onTap: () {
                        final count = int.tryParse(controller.text);
                        if (count != null && count > 0) {
                          Get.back(result: count);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      Get.back(
        result: {
          "name": dua["name"],
          "arabic": dua["arabic"],
          "translation": dua["translation"],
          "target": result,
        },
      );
    }
  }

  // ── Custom tasbih creation dialog ──────────────────────────────
  Future<void> _showCustomDialog(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color accentColor,
    Color goldColor,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color btnTextColor,
  ) async {
    final nameController = TextEditingController();
    final arabicController = TextEditingController();
    final translationController = TextEditingController();
    final countController = TextEditingController();
    final translator = GoogleTranslator();
    final formKey = GlobalKey<FormState>();

    final result = await Get.dialog<Map<String, dynamic>>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withOpacity(0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.mosque_rounded,
                      color: accentColor,
                      size: 26,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "Create Custom Tasbih",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tasbih name
                  TextFormField(
                    controller: nameController,
                    style: TextStyle(fontFamily: 'Poppins', color: textPrimary),
                    decoration: const InputDecoration(
                      labelText: "Tasbih / Dhikr name",
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "Please enter tasbih name"
                        : null,
                    onChanged: (value) async {
                      if (value.trim().isEmpty) {
                        translationController.clear();
                        arabicController.clear();
                        return;
                      }
                      try {
                        final en = await translator.translate(value, to: 'en');
                        translationController.text = en.text;
                        final ar = await translator.translate(value, to: 'ar');
                        arabicController.text = ar.text;
                      } catch (_) {}
                    },
                  ),

                  const SizedBox(height: 12),

                  // Arabic (auto)
                  TextField(
                    controller: arabicController,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      color: goldColor,
                    ),
                    decoration: const InputDecoration(
                      labelText: "Arabic (auto-generated)",
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Translation (auto)
                  TextField(
                    controller: translationController,
                    style: TextStyle(fontFamily: 'Poppins', color: textPrimary),
                    decoration: const InputDecoration(
                      labelText: "English (auto-generated)",
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Count
                  TextFormField(
                    controller: countController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontFamily: 'Poppins', color: textPrimary),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? "Please enter count" : null,
                    decoration: const InputDecoration(
                      labelText: "Target count",
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _dialogBtn(
                          label: "Cancel",
                          color: accentColor.withOpacity(0.08),
                          textColor: accentColor,
                          borderColor: accentColor.withOpacity(0.22),
                          onTap: () => Get.back(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dialogBtn(
                          label: "Add",
                          color: accentColor,
                          textColor: btnTextColor,
                          borderColor: accentColor,
                          onTap: () {
                            if (formKey.currentState!.validate()) {
                              final count = int.tryParse(countController.text);
                              if (count != null && count > 0) {
                                Get.back(
                                  result: {
                                    "name": nameController.text,
                                    "arabic": arabicController.text,
                                    "translation": translationController.text,
                                    "target": count,
                                  },
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result != null) Get.back(result: result);
  }
}

// ── Reusable dialog button ─────────────────────────────────────────
Widget _dialogBtn({
  required String label,
  required Color color,
  required Color textColor,
  required Color borderColor,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    ),
  );
}
