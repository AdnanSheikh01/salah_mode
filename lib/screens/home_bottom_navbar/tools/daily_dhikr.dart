import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tasbih.dart';
import 'package:speech_to_text/speech_to_text.dart';

class DailyDhikrScreen extends StatefulWidget {
  const DailyDhikrScreen({super.key});

  @override
  State<DailyDhikrScreen> createState() => _DailyDhikrScreenState();
}

class _DailyDhikrScreenState extends State<DailyDhikrScreen> {
  int step = 0;
  bool showAyatulKursi = false;
  bool ayatulKursiCompleted = false;
  List<bool> completedSteps = [false, false, false];

  final SpeechToText speech = SpeechToText();
  bool isListening = false;
  String spokenText = "";

  final String ayatulKursiFull =
      "الله لا إله إلا هو الحي القيوم لا تأخذه سنة ولا نوم له ما في السماوات وما في الأرض "
      "من ذا الذي يشفع عنده إلا بإذنه يعلم ما بين أيديهم وما خلفهم ولا يحيطون بشيء من "
      "علمه إلا بما شاء وسع كرسيه السماوات والأرض ولا يؤوده حفظهما وهو العلي العظيم";

  final List<Map<String, dynamic>> dhikrSteps = [
    {
      "title": "SubhanAllah",
      "tasbihKey": "Subhanallah",
      "count": "33 Times",
      "arabic": "سُبْحَانَ اللّٰهِ",
      "translation": "Glory be to Allah",
    },
    {
      "title": "Alhamdulillah",
      "tasbihKey": "Alhamdulillah",
      "count": "33 Times",
      "arabic": "اَلْحَمْدُ لِلّٰهِ",
      "translation": "All praise belongs to Allah",
    },
    {
      "title": "Allahu Akbar",
      "tasbihKey": "Allahu Akbar",
      "count": "34 Times",
      "arabic": "اَللّٰهُ أَكْبَرُ",
      "translation": "Allah is the Greatest",
    },
  ];

  void nextStep() {
    if (step < dhikrSteps.length - 1) {
      setState(() {
        step++;
      });
    } else {
      setState(() {
        showAyatulKursi = true;
      });
    }
  }

  void startListening() async {
    if (ayatulKursiCompleted) return;

    bool available = await speech.initialize(
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          setState(() {
            isListening = false;
          });
        }
      },
      onError: (error) {
        setState(() {
          isListening = false;
        });

        Get.snackbar(
          "Speech Error",
          error.errorMsg,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
    );

    if (!available) {
      Get.snackbar(
        "Microphone Error",
        "Speech recognition is not available on this device",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      isListening = true;
    });

    // Reset spoken text before listening
    spokenText = "";

    speech.listen(
      localeId: "ar_SA",
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
      onResult: (result) {
        setState(() {
          spokenText = result.recognizedWords;
        });

        if (result.finalResult) {
          checkAyatulKursi();
        }
      },
    );
  }

  void stopListening() {
    speech.stop();
    setState(() {
      isListening = false;
    });
  }

  void checkAyatulKursi() {
    String text = spokenText.trim();

    if (text.isEmpty) return;

    if (text.contains("الله") ||
        text.contains("الحي القيوم") ||
        text.contains("وسع كرسيه")) {
      stopListening();

      setState(() {
        ayatulKursiCompleted = true;
      });

      showRewardDialog();
    } else {
      Get.snackbar(
        "Try Again",
        "Recite Ayatul Kursi clearly",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  void showRewardDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xff1f3b4d),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              const Text(
                "Ayatul Kursi Recited Successfully",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "+50 Barakah Points Earned",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = dhikrSteps[step];
    final remainingTasbih =
        dhikrSteps.length - completedSteps.where((e) => e == true).length;
    final remaining = showAyatulKursi
        ? (ayatulKursiCompleted ? 0 : 1)
        : remainingTasbih + 1; // +1 because Ayatul Kursi still remains

    return Scaffold(
      backgroundColor: const Color(0xff0f2027),

      appBar: AppBar(
        title: const Text("Daily Dhikr"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// STREAK INFO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.green.withOpacity(0.12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        remaining == 0
                            ? "All Dhikr completed today. Your streak is maintained and +50 Barakah Points earned!"
                            : remaining == 1
                            ? "Complete $remaining more dhikr to earn +50 Barakah Points too."
                            : "Complete ${remaining - 1} more dhikr to maintain your streak.",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// STEP INDICATOR
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  dhikrSteps.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: step >= index ? Colors.green : Colors.white24,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              /// DHIKR CARD
              if (!showAyatulKursi)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xff1f3b4d), Color(0xff27475a)],
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        current["title"],
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        current["count"],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 25),

                      Text(
                        current["arabic"],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 36,
                          fontFamily: "Amiri",
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        current["translation"],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// OPEN COUNTER BUTTON
                      completedSteps[step]
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    "Completed",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () async {
                                int target = current["title"] == "Allahu Akbar"
                                    ? 34
                                    : 33;

                                final result = await Get.to(
                                  () => const TasbihPage(),
                                  arguments: {
                                    "guided": true,
                                    "tasbih": current["tasbihKey"],
                                    "target": target,
                                  },
                                );

                                if (result == true) {
                                  setState(() {
                                    completedSteps[step] = true;
                                  });

                                  /// If last tasbih completed → move to next dua automatically
                                  if (step == dhikrSteps.length - 1) {
                                    nextStep();
                                  }
                                }
                              },
                              child: const Text(
                                "Start Tasbih",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                    ],
                  ),
                ),

              /// AYATUL KURSI STEP
              if (showAyatulKursi)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xff1f3b4d), Color(0xff27475a)],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Ayatul Kursi",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        ayatulKursiFull,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontFamily: "Amiri",
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Allah! There is no deity except Him, the Ever-Living, the Sustainer of existence.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              /// NEXT STEP BUTTON
              if (!showAyatulKursi && completedSteps[step])
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: nextStep,
                    child: Text(
                      step == dhikrSteps.length - 1
                          ? "Read Ayatul Kursi"
                          : "Next",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),

              if (showAyatulKursi)
                Align(
                  alignment: Alignment.centerRight,
                  child: ayatulKursiCompleted
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                "Completed",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          icon: Icon(isListening ? Icons.mic : Icons.mic_none),
                          label: Text(
                            isListening
                                ? "Listening..."
                                : "Recite Ayatul Kursi",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            if (isListening) {
                              stopListening();
                            } else {
                              startListening();
                            }
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
