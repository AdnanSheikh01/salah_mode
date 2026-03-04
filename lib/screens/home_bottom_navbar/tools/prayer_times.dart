import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  late PrayerTimes prayerTimes;
  Map<String, DateTime> times = {};
  String nextPrayerName = "";
  Duration remaining = Duration.zero;
  Timer? _timer;

  String cityName = "Detecting...";
  bool _loadingLocation = true;
  bool _adhanNotified = false;

  Coordinates coordinates = Coordinates(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    _initLocationAndTimes();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 🚀 GOD TIER: get real location
  Future<void> _initLocationAndTimes() async {
    await _detectLocation();
    _calculateTimes();
    _startTicker();
  }

  Future<void> _detectLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          cityName = "Location off";
          _loadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          cityName = "Permission denied";
          _loadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      coordinates = Coordinates(position.latitude, position.longitude);

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        cityName = placemarks.first.locality ?? "Your city";
      }

      setState(() => _loadingLocation = false);
    } catch (e) {
      setState(() {
        cityName = "Unknown location";
        _loadingLocation = false;
      });
    }
  }

  void _calculateTimes() {
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;

    prayerTimes = PrayerTimes.today(coordinates, params);

    times = {
      "Fajr": prayerTimes.fajr,
      "Sunrise": prayerTimes.sunrise,
      "Dhuhr": prayerTimes.dhuhr,
      "Asr": prayerTimes.asr,
      "Maghrib": prayerTimes.maghrib,
      "Isha": prayerTimes.isha,
    };

    _updateNextPrayer();
  }

  void _startTicker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateNextPrayer();
    });
  }

  void _updateNextPrayer() {
    final now = DateTime.now();
    final next = prayerTimes.nextPrayer();
    final nextTime = prayerTimes.timeForPrayer(next);

    if (nextTime != null) {
      setState(() {
        nextPrayerName = next.name.toUpperCase();
        remaining = nextTime.difference(now);
        if (remaining.isNegative) remaining = Duration.zero;
      });
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  String _formatRemaining(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 🌙 Premium Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cityName,
                        style: const TextStyle(color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _detectLocation();
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Next Prayer",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  nextPrayerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatRemaining(remaining),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 📿 Prayer List
          Expanded(
            child: times.isEmpty || _loadingLocation
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: times.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final name = times.keys.elementAt(index);
                      final time = times.values.elementAt(index);

                      final isNext =
                          name.toUpperCase() == nextPrayerName.toUpperCase();

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: isNext
                              ? LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(.7),
                                  ],
                                )
                              : null,
                          color: isNext ? null : Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  color: isNext
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isNext
                                        ? Colors.white
                                        : Colors.grey.shade900,
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            Text(
                              _formatTime(time),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isNext
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isNext
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _adhanNotified = !_adhanNotified;
                                });
                              },
                              icon: Icon(
                                _adhanNotified
                                    ? Icons.volume_up
                                    : Icons.volume_off,
                              ),
                            ),
                          ],
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
