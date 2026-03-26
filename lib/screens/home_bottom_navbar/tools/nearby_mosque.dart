import 'dart:developer';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/detailed_nearby_mosque.dart';
import 'package:salah_mode/screens/utils/mosque_model.dart';
import 'package:salah_mode/screens/utils/mosque_services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NearbyMosqueScreen extends StatefulWidget {
  const NearbyMosqueScreen({super.key});

  @override
  State<NearbyMosqueScreen> createState() => _NearbyMosqueScreenState();
}

class _NearbyMosqueScreenState extends State<NearbyMosqueScreen> {
  final MosqueService service = MosqueService();

  List<Mosque> mosques = [];
  Map<String, int> verifyVotes = {};
  List<Mosque> userAddedMosques = [];
  bool loading = true;
  String? errorMessage;

  // Helper to generate a unique mosque id
  String mosqueId(Mosque m) => "${m.name}_${m.lat}_${m.lon}";

  String walkingTime(double distanceKm) {
    // average walking speed ≈ 5 km/h
    double minutes = (distanceKm / 5) * 60;
    return "${minutes.round()} min walk";
  }

  @override
  void initState() {
    super.initState();
    loadMosques();
  }

  Future<void> loadMosques() async {
    try {
      setState(() {
        loading = true;
        errorMessage = null;
      });

      final result = await service.fetchNearbyMosques();
      await loadUserMosques();

      // Always merge API mosques with user-added mosques
      mosques = [...result, ...userAddedMosques];

      // Only show error if there are truly no mosques at all
      if (mosques.isEmpty) {
        errorMessage = "No mosques found near your location.";
      } else {
        await loadVerification();
      }

      log("Mosques found: ${mosques.length}");
    } catch (e) {
      log("Mosque loading error: $e");
      errorMessage =
          "Unable to load nearby mosques. Please check location or internet.";
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> loadVerification() async {
    final prefs = await SharedPreferences.getInstance();
    for (var m in mosques) {
      verifyVotes[mosqueId(m)] = prefs.getInt("verify_${mosqueId(m)}") ?? 0;
    }
    if (mounted) setState(() {});
  }

  Future<void> loadUserMosques() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("user_mosques");

    if (data != null) {
      final List decoded = jsonDecode(data);
      userAddedMosques = decoded.map((e) {
        return Mosque(
          name: e["name"],
          lat: e["lat"],
          lon: e["lon"],
          distance: 0,
        );
      }).toList();
    }
  }

  Future<void> saveUserMosques() async {
    final prefs = await SharedPreferences.getInstance();

    final data = userAddedMosques
        .map((m) => {"name": m.name, "lat": m.lat, "lon": m.lon})
        .toList();

    await prefs.setString("user_mosques", jsonEncode(data));
  }

  Future<void> addMosque() async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Masjid"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter masjid name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              child: const Text("Add"),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                double lat = mosques.isNotEmpty ? mosques.first.lat : 28.6139;
                double lon = mosques.isNotEmpty ? mosques.first.lon : 77.2090;

                final newMosque = Mosque(
                  name: name,
                  lat: lat,
                  lon: lon,
                  distance: 0,
                );

                setState(() {
                  userAddedMosques.add(newMosque);
                  mosques.add(newMosque);
                  verifyVotes[name] = 0;
                });

                await saveUserMosques();

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> verifyMosque(Mosque mosque) async {
    final prefs = await SharedPreferences.getInstance();
    final id = mosqueId(mosque);
    int current = verifyVotes[id] ?? 0;
    current += 1;
    verifyVotes[id] = current;
    await prefs.setInt("verify_$id", current);

    if (mounted) setState(() {});
  }

  bool isVerified(Mosque mosque) {
    return (verifyVotes[mosqueId(mosque)] ?? 0) >= 3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Nearby Mosques",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: loadMosques,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                /// MAP
                Container(
                  height: 250,
                  margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: mosques.isNotEmpty
                          ? LatLng(mosques.first.lat, mosques.first.lon)
                          : const LatLng(28.6139, 77.2090),
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: "com.example.salah_mode",
                      ),
                      MarkerLayer(
                        markers: mosques.map((m) {
                          return Marker(
                            point: LatLng(m.lat, m.lon),
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.mosque,
                              color: isVerified(m)
                                  ? Colors.green
                                  : Colors.orange,
                              size: 30,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                /// LIST
                Expanded(
                  child: ListView.builder(
                    itemCount: mosques.length,
                    itemBuilder: (context, index) {
                      Mosque m = mosques[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MosqueDetailPage(
                                mosqueName: m.name,
                                mosqueId: mosqueId(m),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: index == 0
                                  ? Colors.green.withOpacity(0.25)
                                  : Colors.grey.withOpacity(0.08),
                            ),
                            color: index == 0
                                ? Colors.green.withOpacity(0.12)
                                : Theme.of(context).cardColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.mosque,
                                  color: Colors.green,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (isVerified(m))
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          "Verified",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    if (!isVerified(m))
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          "${(3 - (verifyVotes[mosqueId(m)] ?? 0)).clamp(0, 3)} confirmations needed",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  Icon(
                                    index == 0
                                        ? Icons.explore
                                        : Icons.navigation_outlined,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(height: 6),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.directions,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      final url = Uri.parse(
                                        "https://www.google.com/maps/dir/?api=1&destination=${m.lat},${m.lon}&travelmode=walking",
                                      );
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.verified_outlined,
                                      size: 20,
                                    ),
                                    tooltip: "Verify mosque info",
                                    onPressed: () {
                                      verifyMosque(m);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        tooltip: "Add Masjid",
        onPressed: addMosque,
        child: const Icon(Icons.add),
      ),
    );
  }
}
