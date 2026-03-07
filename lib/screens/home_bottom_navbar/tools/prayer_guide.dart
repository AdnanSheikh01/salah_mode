import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/home_bottom_navbar/surah_list.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tasbih.dart';
import 'package:salah_mode/screens/utils/salah_step.dart';

class PrayerGuideScreen extends StatefulWidget {
  const PrayerGuideScreen({super.key});

  @override
  State<PrayerGuideScreen> createState() => _PrayerGuideScreenState();
}

class _PrayerGuideScreenState extends State<PrayerGuideScreen> {
  int currentStep = 0;

  void nextStep() {
    if (currentStep < steps.length - 1) {
      setState(() {
        currentStep++;
      });
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = steps[currentStep];

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text("Prayer Guide"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// Step Indicator
            Column(
              children: [
                Text(
                  "Step ${currentStep + 1} of ${steps.length}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: (currentStep + 1) / steps.length,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF5FE3C3)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// Main Card
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEEF6F2), Color(0xFFDFF3EA)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// Image
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Image.asset(
                          step["image"]!,
                          key: ValueKey(step["image"]),
                          height: 160,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Title
                      Text(
                        step["title"]!,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),

                      const SizedBox(height: 14),

                      /// Arabic
                      Text(
                        step["arabic"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontFamily: "Amiri",
                          color: Color(0xFF2E7D32),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// Translation
                      Text(
                        step["translation"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            step["title"] == "After Salah Dhikr"
                                ? const Text(
                                    "Dhikr after Salah",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  )
                                : const Text(
                                    "Dua in Salah",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                            const SizedBox(height: 6),
                            Builder(
                              builder: (_) {
                                final duas = (step["dua"] ?? "").split("\n\n");
                                final translations =
                                    (step["duaTranslation"] ?? "").split(
                                      "\n\n",
                                    );

                                return Column(
                                  children: List.generate(duas.length, (index) {
                                    final translation =
                                        index < translations.length
                                        ? translations[index]
                                        : "";

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            duas[index],
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontFamily: "Amiri",
                                              color: Colors.black87,
                                            ),
                                          ),
                                          // Translation text, if any
                                          if (translation.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                translation,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                          // Show Tasbih button after Allahu Akbar 34×
                                          if (step["title"] ==
                                                  "After Salah Dhikr" &&
                                              duas[index].contains("34")) ...[
                                            const SizedBox(height: 10),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF2E7D32,
                                                ),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 18,
                                                      vertical: 10,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                              ),
                                              onPressed: () {
                                                Get.to(
                                                  () => const TasbihPage(),
                                                );
                                              },
                                              icon: const Icon(Icons.favorite),
                                              label: const Text(
                                                "Open Tasbih Counter",
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                            // Tasbih button is now shown after Allahu Akbar 34× above
                            if (step["fatihaArabic"] != null) ...[
                              const SizedBox(height: 14),
                              const Text(
                                "Surah Al‑Fatiha",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                step["fatihaArabic"]!,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontFamily: "Amiri",
                                  color: Colors.black87,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                step["fatihaTranslation"]!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black54,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                              // Add Surah button after Surah Al‑Fatiha
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () {
                                  Get.to(() => const SurahListPage());
                                },
                                icon: const Icon(Icons.menu_book),
                                label: const Text("Recite another Surah"),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      /// Description
                      Text(
                        step["desc"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Hadith",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              step["hadith"]!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5FE3C3),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: previousStep,
                  child: const Text("Previous"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5FE3C3),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    if (currentStep == steps.length - 1) {
                      Get.back(); // exit page when finished
                    } else {
                      nextStep();
                    }
                  },
                  child: Text(
                    currentStep == steps.length - 1 ? "Done" : "Next",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
