import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geocoding/geocoding.dart';

class PrayerTimeService {
  PrayerTimes? prayerTimes;
  String nextPrayerName = "";
  DateTime nextPrayerTime = DateTime.now();
  Duration remaining = Duration.zero;
  String cityName = "Loading...";
  Timer? _timer;
  bool _initialized = false;

  final VoidCallback onUpdate;

  PrayerTimeService({required this.onUpdate});

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("Location permanently denied");
      return;
    }

    Position? lastPos = await Geolocator.getLastKnownPosition();

    if (lastPos != null) {
      _calculatePrayers(lastPos);
      _loadCityName(lastPos.latitude, lastPos.longitude);
    }

    updateLocationSilently();
  }

  Future<void> updateLocationSilently() async {
    try {
      Position position;

      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (_) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 8),
        );
      }
      _calculatePrayers(position);
      _loadCityName(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("Silent location update failed: $e");
    } finally {
      onUpdate();
    }
  }

  void _calculatePrayers(Position pos) {
    final coordinates = Coordinates(pos.latitude, pos.longitude);
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;

    final pt = PrayerTimes(
      coordinates,
      DateComponents.from(DateTime.now()),
      params,
    );

    prayerTimes = pt;
    _updateNextPrayer();
    onUpdate();
  }

  void _updateNextPrayer() {
    if (prayerTimes == null) return;
    final next = prayerTimes!.nextPrayer();

    // Logic for after Isha (tomorrow's Fajr)
    if (next == Prayer.none) {
      nextPrayerName = "FAJR";
      nextPrayerTime = prayerTimes!.fajr.add(const Duration(days: 1));
    } else {
      nextPrayerName = next.name.toUpperCase();
      nextPrayerTime = prayerTimes!.timeForPrayer(next)!;
    }
    _startCountdown();
  }

  Map<String, dynamic> getCurrentPrayerStatus() {
    if (prayerTimes == null) {
      return {"name": "--", "start": null, "end": null};
    }

    final now = DateTime.now();

    final prayers = [
      {"name": "Fajr", "time": prayerTimes!.fajr},
      {"name": "Dhuhr", "time": prayerTimes!.dhuhr},
      {"name": "Asr", "time": prayerTimes!.asr},
      {"name": "Maghrib", "time": prayerTimes!.maghrib},
      {"name": "Isha", "time": prayerTimes!.isha},
    ];

    for (int i = 0; i < prayers.length; i++) {
      final start = prayers[i]["time"] as DateTime;
      final end = (i == prayers.length - 1)
          ? prayerTimes!.fajr.add(const Duration(days: 1))
          : prayers[i + 1]["time"] as DateTime;

      if (now.isAfter(start) && now.isBefore(end)) {
        return {"name": prayers[i]["name"], "start": start, "end": end};
      }
    }

    return {
      "name": "Isha",
      "start": prayerTimes!.isha,
      "end": prayerTimes!.fajr.add(const Duration(days: 1)),
    };
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final diff = nextPrayerTime.difference(DateTime.now());
      if (diff.inSeconds <= 0) {
        _updateNextPrayer();
        onUpdate();
      } else {
        remaining = diff;
        onUpdate();
      }
    });
  }

  Future<void> _loadCityName(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        cityName = placemarks.first.locality ?? "Unknown";
        onUpdate();
      }
    } catch (_) {}
  }

  void dispose() {
    _timer?.cancel();
  }
}
