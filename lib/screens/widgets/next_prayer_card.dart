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

  final nowTime = DateFormat('h:mm:ss a').format(DateTime.now());
  final nextTime = TimeOfDay.fromDateTime(nextPrayerTime).format(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      /// 🔔 Top Row
      Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.10),
                theme.colorScheme.surface.withOpacity(.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 18),
              const SizedBox(width: 6),

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

      const SizedBox(height: 32),

      /// 🕐 Current Time
      Center(
        child: Text(
          nowTime,
          style: theme.textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      const SizedBox(height: 32),

      /// 🔷 Next Prayer Card
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
          ),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.10),
              Theme.of(context).colorScheme.surface.withOpacity(.9),
            ],
          ),
        ),
        child: Row(
          children: [
            /// Prayer Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayerName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "$nextTime - 7:30 PM",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(Icons.volume_up, color: Colors.white),
              onPressed: () {},
            ),

            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
      ),

      /// 🕌 All Prayer Times
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
          ),
          color: Theme.of(context).colorScheme.surface.withOpacity(.25),
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

      SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          color: Theme.of(context).colorScheme.surface.withOpacity(.25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _prayerItem("Tahajjud", formatTime(prayerTimes?.sunrise)),
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

Widget _prayerItem(String name, String? time) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        name,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 10),
      Icon(
        name == "Fajr"
            ? Icons.wb_twilight
            : name == "Dhuhr"
            ? Icons.wb_sunny
            : name == "Asr"
            ? Icons.wb_cloudy
            : name == "Maghrib" || name == "Sunset"
            ? Icons.nights_stay
            : Icons.dark_mode,
        size: 26,
        color: Colors.white.withOpacity(.85),
      ),
      const SizedBox(height: 10),
      Text(
        time ?? "--:--",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}
