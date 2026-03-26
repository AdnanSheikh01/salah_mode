import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MosqueDetailPage extends StatefulWidget {
  final String mosqueId;
  final String mosqueName;

  const MosqueDetailPage({
    super.key,
    required this.mosqueId,
    required this.mosqueName,
  });

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

  String key(String field) => "${widget.mosqueId}_$field";

  String getRank() {
    if (barakahPoints >= 200) return "Ummah Builder";
    if (barakahPoints >= 100) return "Mosque Guardian";
    if (barakahPoints >= 50) return "Mosque Helper";
    if (barakahPoints >= 10) return "Contributor";
    return "New Helper";
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    barakahPoints = prefs.getInt("barakah_points") ?? 0;

    times = {
      "fajrAdhan": prefs.getString(key("fajrAdhan")) ?? "--",
      "fajrJamaat": prefs.getString(key("fajrJamaat")) ?? "--",
      "zuhrAdhan": prefs.getString(key("zuhrAdhan")) ?? "--",
      "zuhrJamaat": prefs.getString(key("zuhrJamaat")) ?? "--",
      "asrAdhan": prefs.getString(key("asrAdhan")) ?? "--",
      "asrJamaat": prefs.getString(key("asrJamaat")) ?? "--",
      "maghribAdhan": prefs.getString(key("maghribAdhan")) ?? "--",
      "maghribJamaat": prefs.getString(key("maghribJamaat")) ?? "--",
      "ishaAdhan": prefs.getString(key("ishaAdhan")) ?? "--",
      "ishaJamaat": prefs.getString(key("ishaJamaat")) ?? "--",
    };

    facilities = {
      "Wudu Area": prefs.getBool(key("wudu")) ?? false,
      "Wheelchair Access": prefs.getBool(key("wheelchair")) ?? false,
      "Women Prayer Area": prefs.getBool(key("women")) ?? false,
      "Parking": prefs.getBool(key("parking")) ?? false,
    };

    setState(() {});
  }

  Future<void> saveTimes() async {
    final prefs = await SharedPreferences.getInstance();

    for (var entry in times.entries) {
      await prefs.setString(key(entry.key), entry.value);
    }
  }

  Future<void> changeTime(String keyName) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      String newTime =
          "${picked.hour}:${picked.minute.toString().padLeft(2, '0')}";

      setState(() {
        times[keyName] = newTime;
        pendingPoints += 5;
      });

      saveTimes();
    }
  }

  Widget prayerRow(String prayer, String adhanKey, String jamaatKey) {
    return Card(
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

  Future<void> submitChanges() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      barakahPoints += pendingPoints;
      pendingPoints = 0;
    });

    await prefs.setInt("barakah_points", barakahPoints);

    Get.snackbar(
      "Barakah Earned",
      "JazakAllah Khair! Your update helped the Ummah.",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (times.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mosqueName),
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

      body: ListView(
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
            "Facilities",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          ...facilities.keys.map((facility) {
            bool value = facilities[facility]!;

            return SwitchListTile(
              title: Text(facility),
              value: value,
              onChanged: editMode
                  ? (val) async {
                      final prefs = await SharedPreferences.getInstance();

                      setState(() {
                        facilities[facility] = val;
                        pendingPoints += 2;
                      });

                      await prefs.setBool(key(facility), val);
                    }
                  : null,
            );
          }),

          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text("Rank: ${getRank()}"),
                const SizedBox(height: 6),
                Text(
                  "Barakah Points: $barakahPoints",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (pendingPoints > 0)
            ElevatedButton.icon(
              icon: const Icon(Icons.volunteer_activism),
              label: Text("Submit & Earn $pendingPoints Barakah Points"),
              onPressed: submitChanges,
            ),
        ],
      ),
    );
  }
}
