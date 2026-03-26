import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Widget premiumNextPrayerHeader(
  BuildContext context,
  DateTime nextPrayerTime,
  Duration remaining,
  String prayerName,
  String city,
  PrayerTimes? prayerTimes,
) {
  final theme = Theme.of(context);

  // Formatting current time with seconds for the clock feel
  final nowTime = DateFormat('h:mm:ss a').format(DateTime.now());
  final nextTimeFmt = DateFormat.jm().format(nextPrayerTime.toLocal());

  // Formatting remaining time: HH:mm:ss
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  final hours = twoDigits(remaining.inHours);
  final minutes = twoDigits(remaining.inMinutes.remainder(60));
  final seconds = twoDigits(remaining.inSeconds.remainder(60));

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      /// 🔔 Location Badge
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: Color(0xFF00C853), size: 16),
              const SizedBox(width: 8),
              Text(
                city.isEmpty ? "Locating..." : city,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 24),

      /// 🕐 Digital Clock
      Center(
        child: Text(
          nowTime,
          style: theme.textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
      ),

      const SizedBox(height: 32),

      /// 🔷 Next Prayer Card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.2),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "NEXT: $prayerName",
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Starts at $nextTimeFmt",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Countdown Timer UI
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "-$hours:$minutes:$seconds",
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier', // Monospace for numbers
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  "remaining",
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),

      /// 🕌 Primary Prayer Times
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
          color: theme.colorScheme.surface.withOpacity(.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _prayerItem("Fajr", formatTime(prayerTimes?.fajr)),
            _prayerItem("Dhuhr", formatTime(prayerTimes?.dhuhr)),
            _prayerItem("Asr", formatTime(prayerTimes?.asr)),
            _prayerItem("Maghrib", formatTime(prayerTimes?.maghrib)),
            _prayerItem("Isha", formatTime(prayerTimes?.isha)),
          ],
        ),
      ),

      const SizedBox(height: 16),

      /// 🌅 Sun & Special Times
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surface.withOpacity(.3),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tahajjud is roughly mid-night to Fajr
            _prayerItem("Tahajjud", _calculateTahajjud(prayerTimes)),
            _prayerItem("Sunrise", formatTime(prayerTimes?.sunrise)),
            _prayerItem("Sunset", formatTime(prayerTimes?.maghrib)),
          ],
        ),
      ),
    ],
  );
}

String formatTime(DateTime? time) {
  if (time == null) return "--:--";
  return DateFormat.jm().format(time.toLocal());
}

// Simple logic for Tahajjud (Last 3rd of Night)
String _calculateTahajjud(PrayerTimes? pt) {
  if (pt == null) return "--:--";
  // Rough estimate: Isha + 3 hours or a calculated value
  final tahajjud = pt.fajr.subtract(const Duration(hours: 2));
  return DateFormat.jm().format(tahajjud.toLocal());
}

Widget _prayerItem(String name, String time) {
  return Column(
    children: [
      Text(name, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      const SizedBox(height: 8),
      Icon(
        _getIconForPrayer(name),
        size: 22,
        color: Colors.white.withOpacity(0.9),
      ),
      const SizedBox(height: 8),
      Text(
        time,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}

IconData _getIconForPrayer(String name) {
  switch (name) {
    case "Fajr":
      return Icons.wb_twilight;
    case "Sunrise":
      return Icons.wb_sunny_outlined;
    case "Dhuhr":
      return Icons.wb_sunny;
    case "Asr":
      return Icons.wb_cloudy_outlined;
    case "Maghrib":
    case "Sunset":
      return Icons.wb_twilight_rounded;
    case "Isha":
      return Icons.nightlight_round;
    case "Tahajjud":
      return Icons.auto_awesome;
    default:
      return Icons.access_time;
  }
}
