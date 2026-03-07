import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MosqueDetailPage extends StatefulWidget {
  const MosqueDetailPage({super.key});

  @override
  State<MosqueDetailPage> createState() => _MosqueDetailPageState();
}

class _MosqueDetailPageState extends State<MosqueDetailPage> {
  bool editMode = false;

  int barakahPoints = 0;
  int pendingPoints = 0;

  Map<String, String> times = {};

  Map<String, bool> facilities = {
    "Wudu Area": false,
    "Wheelchair Access": false,
    "Women Prayer Area": false,
    "Parking": false,
  };

  @override
  void initState() {
    super.initState();
    loadTimes();
    loadFacilities();
  }

  String randomTime(int hour) {
    final r = Random();
    int minute = r.nextInt(60);
    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  }

  Future<void> loadTimes() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString("fajrAdhan") == null) {
      times = {
        "fajrAdhan": randomTime(5),
        "fajrJamaat": randomTime(5),
        "zuhrAdhan": randomTime(13),
        "zuhrJamaat": randomTime(13),
        "asrAdhan": randomTime(16),
        "asrJamaat": randomTime(16),
        "maghribAdhan": randomTime(18),
        "maghribJamaat": randomTime(18),
        "ishaAdhan": randomTime(20),
        "ishaJamaat": randomTime(20),
      };

      saveTimes();
    } else {
      times = {
        "fajrAdhan": prefs.getString("fajrAdhan")!,
        "fajrJamaat": prefs.getString("fajrJamaat")!,
        "zuhrAdhan": prefs.getString("zuhrAdhan")!,
        "zuhrJamaat": prefs.getString("zuhrJamaat")!,
        "asrAdhan": prefs.getString("asrAdhan")!,
        "asrJamaat": prefs.getString("asrJamaat")!,
        "maghribAdhan": prefs.getString("maghribAdhan")!,
        "maghribJamaat": prefs.getString("maghribJamaat")!,
        "ishaAdhan": prefs.getString("ishaAdhan")!,
        "ishaJamaat": prefs.getString("ishaJamaat")!,
      };
    }

    setState(() {});
  }

  Future<void> loadFacilities() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool("facility_wudu") == null) {
      final r = Random();

      facilities = {
        "Wudu Area": r.nextBool(),
        "Wheelchair Access": r.nextBool(),
        "Women Prayer Area": r.nextBool(),
        "Parking": r.nextBool(),
      };

      prefs.setBool("facility_wudu", facilities["Wudu Area"]!);
      prefs.setBool("facility_wheelchair", facilities["Wheelchair Access"]!);
      prefs.setBool("facility_women", facilities["Women Prayer Area"]!);
      prefs.setBool("facility_parking", facilities["Parking"]!);
    } else {
      facilities = {
        "Wudu Area": prefs.getBool("facility_wudu") ?? false,
        "Wheelchair Access": prefs.getBool("facility_wheelchair") ?? false,
        "Women Prayer Area": prefs.getBool("facility_women") ?? false,
        "Parking": prefs.getBool("facility_parking") ?? false,
      };
    }

    setState(() {});
  }

  Future<void> saveTimes() async {
    final prefs = await SharedPreferences.getInstance();

    times.forEach((key, value) {
      prefs.setString(key, value);
    });
  }

  Future<void> changeTime(String key) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      String newTime =
          "${picked.hour}:${picked.minute.toString().padLeft(2, '0')}";

      setState(() {
        times[key] = newTime;
        pendingPoints += 5;
      });

      saveTimes();

      Get.snackbar(
        "Change Saved",
        "Submit changes to earn Barakah points",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget prayerRow(String prayer, String adhanKey, String jamaatKey) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(prayer),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: editMode ? () => changeTime(adhanKey) : null,
              child: Column(
                children: [const Text("Adhan"), Text(times[adhanKey] ?? "--")],
              ),
            ),

            GestureDetector(
              onTap: editMode ? () => changeTime(jamaatKey) : null,
              child: Column(
                children: [
                  const Text("Jamaat"),
                  Text(times[jamaatKey] ?? "--"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mosque Details"),
        actions: [
          IconButton(
            icon: Icon(editMode ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                editMode = !editMode;
              });
            },
          ),
        ],
      ),

      body: times.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Prayer Times",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                prayerRow("Fajr", "fajrAdhan", "fajrJamaat"),
                prayerRow("Zuhr", "zuhrAdhan", "zuhrJamaat"),
                prayerRow("Asr", "asrAdhan", "asrJamaat"),
                prayerRow("Maghrib", "maghribAdhan", "maghribJamaat"),
                prayerRow("Isha", "ishaAdhan", "ishaJamaat"),

                const SizedBox(height: 30),

                const Text(
                  "Accessibility",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                ...facilities.keys.map((key) {
                  IconData icon;

                  if (key == "Wudu Area") {
                    icon = Icons.water_drop;
                  } else if (key == "Wheelchair Access") {
                    icon = Icons.accessible;
                  } else if (key == "Women Prayer Area") {
                    icon = Icons.woman;
                  } else {
                    icon = Icons.local_parking;
                  }

                  bool value = facilities[key]!;

                  return GestureDetector(
                    onTap: editMode
                        ? () async {
                            final prefs = await SharedPreferences.getInstance();
                            bool newVal = !value;

                            setState(() {
                              facilities[key] = newVal;
                              pendingPoints += 2;
                            });

                            if (key == "Wudu Area")
                              prefs.setBool("facility_wudu", newVal);
                            if (key == "Wheelchair Access")
                              prefs.setBool("facility_wheelchair", newVal);
                            if (key == "Women Prayer Area")
                              prefs.setBool("facility_women", newVal);
                            if (key == "Parking")
                              prefs.setBool("facility_parking", newVal);
                          }
                        : null,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 6,
                            color: Colors.black.withOpacity(0.06),
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.green.withOpacity(0.15),
                            child: Icon(icon, color: Colors.green),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              key,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            value ? Icons.check_circle : Icons.cancel,
                            color: value ? Colors.green : Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 30),

                Column(
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Barakah Points: $barakahPoints",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (pendingPoints > 0)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.volunteer_activism),
                        label: Text(
                          "Submit & Earn $pendingPoints Barakah Points",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            barakahPoints += pendingPoints;
                            pendingPoints = 0;
                          });

                          Get.snackbar(
                            "Barakah Earned",
                            "Your contribution earned rewards!",
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
