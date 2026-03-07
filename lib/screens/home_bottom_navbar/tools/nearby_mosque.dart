import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/detailed_nearby_mosque.dart';
import 'package:salah_mode/screens/utils/mosque_model.dart';
import 'package:salah_mode/screens/utils/mosque_services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class NearbyMosqueScreen extends StatefulWidget {
  const NearbyMosqueScreen({super.key});

  @override
  State<NearbyMosqueScreen> createState() => _NearbyMosqueScreenState();
}

class _NearbyMosqueScreenState extends State<NearbyMosqueScreen> {
  final MosqueService service = MosqueService();

  List<Mosque> mosques = [];
  bool loading = true;
  String? errorMessage;

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

      if (result.isEmpty) {
        errorMessage = "No mosques found near your location.";
      } else {
        mosques = result;
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
                      initialCenter: LatLng(mosques[0].lat, mosques[0].lon),
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
                            child: const Icon(
                              Icons.mosque,
                              color: Colors.green,
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
                              builder: (_) => MosqueDetailScreen(mosque: m),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
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
                                        if (index == 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              "Nearest",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${m.distance.toStringAsFixed(2)} km • ${walkingTime(m.distance)}",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
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
    );
  }
}
