import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:salah_mode/screens/widgets/next_prayer_card.dart';

Widget prayerGrid(
  BuildContext context,
  PrayerTimes? prayerTimes,
  String? nextPrayerName,
  Prayer? currentPrayer,
) {
  if (prayerTimes == null) return const SizedBox();

  final prayerData = [
    ["Fajr", formatTime(prayerTimes.fajr)],
    ["Dhuhr", formatTime(prayerTimes.dhuhr)],
    ["Asr", formatTime(prayerTimes.asr)],
    ["Maghrib", formatTime(prayerTimes.maghrib)],
    ["Isha", formatTime(prayerTimes.isha)],
  ];

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: prayerData.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
    ),
    itemBuilder: (context, i) {
      final bool isNext = nextPrayerName == prayerData[i][0].toUpperCase();
      final bool isCurrent =
          currentPrayer?.name.toUpperCase() == prayerData[i][0].toUpperCase();
      return Container(
        decoration: BoxDecoration(
          color: isCurrent
              ? Theme.of(context).colorScheme.primary.withOpacity(0.18)
              : isNext
              ? Theme.of(context).colorScheme.primary.withOpacity(0.10)
              : Theme.of(context).colorScheme.surface.withOpacity(.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNext
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor.withOpacity(.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              prayerData[i][0],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: (isCurrent || isNext)
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              prayerData[i][1],
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    },
  );
}
