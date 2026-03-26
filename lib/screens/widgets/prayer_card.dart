import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

Widget prayerCard(
  BuildContext context,
  DateTime nextPrayerTime,
  Duration remaining,
  String prayerName,
  String city,
  PrayerTimes? prayerTimes,
) {
  // ── Safe guard: never let remaining go negative ────────────────
  final safeRemaining = remaining.isNegative ? Duration.zero : remaining;

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
  final cardAltColor = isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt;
  final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
  final textPrimary = isDark
      ? AppTheme.darkTextPrimary
      : AppTheme.lightTextPrimary;
  final textSecondary = isDark
      ? AppTheme.darkTextSecondary
      : AppTheme.lightTextSecondary;
  final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
  final bannerOnColor = isDark
      ? AppTheme.darkTextOnAccent
      : AppTheme.lightTextOnAccent;

  // ── Safe current time (never throws) ──────────────────────────
  String nowTime;
  try {
    final currentMoment = nextPrayerTime.subtract(safeRemaining);
    nowTime = DateFormat('h:mm:ss a').format(currentMoment);
  } catch (_) {
    nowTime = DateFormat('h:mm:ss a').format(DateTime.now());
  }

  // ── Prayer state (all null-safe) ───────────────────────────────
  final currentPrayer = _getCurrentPrayer(prayerTimes);
  final currentPrayerName = (currentPrayer['name'] ?? '--');
  final currentPrayerTime = (currentPrayer['time'] ?? '--:--');
  final currentPrayerEndTime = _getCurrentPrayerEndTime(
    prayerTimes,
    currentPrayerName,
  );
  final currentPrayerEndFmt = formatTime(currentPrayerEndTime);

  final prohibited = _getProhibitedTime(prayerTimes);
  final isProhibitedNow = (prohibited['active'] as bool?) ?? false;
  final prohibitedFrom = (prohibited['from'] as String?) ?? '--:--';
  final prohibitedTo = (prohibited['to'] as String?) ?? '--:--';

  final upcomingProhibited = _getUpcomingProhibitedTime(prayerTimes);
  final showProhibitedWarning = _isProhibitedJustAfterPrayer(
    prayerTimes,
    currentPrayerEndTime,
  );
  final upcomingFrom = (upcomingProhibited['from'] as String?) ?? '--:--';
  final upcomingTo = (upcomingProhibited['to'] as String?) ?? '--:--';

  // ── Effective countdown ────────────────────────────────────────
  final now = DateTime.now();
  DateTime effectiveEndTime = nextPrayerTime;

  try {
    DateTime? nextEvent;
    if (isProhibitedNow) {
      nextEvent = _getProhibitedEndDateTime(prayerTimes);
    } else {
      final candidates = <DateTime>[
        ..._getNextPrayerStartTime(prayerTimes, now) != null
            ? [_getNextPrayerStartTime(prayerTimes, now)!]
            : [],
        ..._getUpcomingProhibitedStartDateTime(prayerTimes) != null
            ? [_getUpcomingProhibitedStartDateTime(prayerTimes)!]
            : [],
        ?currentPrayerEndTime,
      ]..sort();
      if (candidates.isNotEmpty) nextEvent = candidates.first;
    }
    if (nextEvent != null) effectiveEndTime = nextEvent;
  } catch (_) {
    // Keep effectiveEndTime = nextPrayerTime on any error
  }

  final effectiveRemaining = effectiveEndTime.difference(now).isNegative
      ? Duration.zero
      : effectiveEndTime.difference(now);

  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hh = twoDigits(effectiveRemaining.inHours.clamp(0, 99));
  final mm = twoDigits(effectiveRemaining.inMinutes.remainder(60));
  final ss = twoDigits(effectiveRemaining.inSeconds.remainder(60));

  // ── Banner colors ──────────────────────────────────────────────
  final activeBannerBg = isProhibitedNow ? AppTheme.colorError : accentColor;
  final bannerTextColor = isProhibitedNow ? Colors.white : bannerOnColor;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ── Location badge ─────────────────────────────────────────
      Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded, color: accentColor, size: 15),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  city.trim().isEmpty ? "Locating..." : city,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 24),

      // ── Digital clock ──────────────────────────────────────────
      Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            nowTime,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -1.0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),

      const SizedBox(height: 28),

      // ── Active prayer / prohibited banner ──────────────────────
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: activeBannerBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: prayer info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label row
                  Row(
                    children: [
                      if (isProhibitedNow) ...[
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: bannerTextColor,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          isProhibitedNow
                              ? "Prohibited Time"
                              : currentPrayerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: bannerTextColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Time range
                  Text(
                    isProhibitedNow
                        ? "$prohibitedFrom  →  $prohibitedTo"
                        : "$currentPrayerTime  →  $currentPrayerEndFmt",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: bannerTextColor.withOpacity(0.75),
                    ),
                  ),

                  // Upcoming prohibited warning
                  if (!isProhibitedNow && showProhibitedWarning) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "Prohibited Time",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: bannerTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$upcomingFrom → $upcomingTo",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: bannerTextColor.withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right: countdown — shrinkable, never overflows
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "-$hh:$mm:$ss",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: bannerTextColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Text(
                  "remaining",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: bannerTextColor.withOpacity(0.65),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // ── 5 daily prayers row ────────────────────────────────────
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: cardAltColor,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
          border: Border(
            left: BorderSide(color: borderColor, width: 0.8),
            right: BorderSide(color: borderColor, width: 0.8),
            bottom: BorderSide(color: borderColor, width: 0.8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _prayerItem("Fajr", formatTime(prayerTimes?.fajr), isDark),
            _prayerItem("Dhuhr", formatTime(prayerTimes?.dhuhr), isDark),
            _prayerItem("Asr", formatTime(prayerTimes?.asr), isDark),
            _prayerItem("Maghrib", formatTime(prayerTimes?.maghrib), isDark),
            _prayerItem("Isha", formatTime(prayerTimes?.isha), isDark),
          ],
        ),
      ),

      const SizedBox(height: 14),

      // ── Sun & special times row ────────────────────────────────
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _prayerItem("Tahajjud", _calculateTahajjud(prayerTimes), isDark),
            _prayerItem("Sunrise", formatTime(prayerTimes?.sunrise), isDark),
            _prayerItem("Sunset", formatTime(prayerTimes?.maghrib), isDark),
          ],
        ),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════
//  PRAYER ITEM  — intrinsically sized, never overflows
// ═══════════════════════════════════════════════════════════════════

Widget _prayerItem(String name, String time, bool isDark) {
  final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
  final textPrimary = isDark
      ? AppTheme.darkTextPrimary
      : AppTheme.lightTextPrimary;
  final textTertiary = isDark
      ? AppTheme.darkTextTertiary
      : AppTheme.lightTextTertiary;

  return Flexible(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: textTertiary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Icon(_getIconForPrayer(name), size: 18, color: accentColor),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            time,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  HELPERS — all null-safe
// ═══════════════════════════════════════════════════════════════════

String formatTime(DateTime? time) {
  if (time == null) return "--:--";
  try {
    return DateFormat.jm().format(time.toLocal());
  } catch (_) {
    return "--:--";
  }
}

String _calculateTahajjud(PrayerTimes? pt) {
  if (pt == null) return "--:--";
  try {
    final nextDayFajr = pt.fajr.add(const Duration(days: 1));
    final nightDuration = nextDayFajr.difference(pt.maghrib);
    if (nightDuration.inSeconds <= 0) return "--:--";
    final lastThirdStart = nextDayFajr.subtract(
      Duration(seconds: (nightDuration.inSeconds / 3).round()),
    );
    return DateFormat.jm().format(lastThirdStart.toLocal());
  } catch (_) {
    return "--:--";
  }
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

/// Extracted so it can be called from both the main function and the
/// candidate-list builder — no duplicate local function definition.
DateTime? _getNextPrayerStartTime(PrayerTimes? pt, DateTime now) {
  if (pt == null) return null;
  try {
    final list = [
      pt.fajr,
      pt.dhuhr,
      pt.asr,
      pt.maghrib,
      pt.isha,
      pt.fajr.add(const Duration(days: 1)),
    ];
    for (final t in list) {
      if (now.isBefore(t)) return t;
    }
  } catch (_) {}
  return null;
}

Map<String, String> _getCurrentPrayer(PrayerTimes? pt) {
  if (pt == null) return {"name": "--", "time": "--:--"};
  try {
    final now = DateTime.now();
    final ishraqStart = pt.sunrise.add(const Duration(minutes: 15));
    final chashtStart = pt.sunrise.add(const Duration(minutes: 45));

    final prayerList = [
      {"name": "Fajr", "time": pt.fajr},
      {"name": "Ishraq", "time": ishraqStart},
      {"name": "Chasht", "time": chashtStart},
      {"name": "Dhuhr", "time": pt.dhuhr},
      {"name": "Asr", "time": pt.asr},
      {"name": "Maghrib", "time": pt.maghrib},
      {"name": "Isha", "time": pt.isha},
    ];

    for (int i = 0; i < prayerList.length; i++) {
      final start = prayerList[i]["time"] as DateTime;
      final end = (i == prayerList.length - 1)
          ? pt.fajr.add(const Duration(days: 1))
          : prayerList[i + 1]["time"] as DateTime;

      if (now.isAfter(start) && now.isBefore(end)) {
        return {
          "name": prayerList[i]["name"] as String,
          "time": formatTime(start),
        };
      }
    }
    return {"name": "Isha", "time": formatTime(pt.isha)};
  } catch (_) {
    return {"name": "--", "time": "--:--"};
  }
}

DateTime? _getCurrentPrayerEndTime(PrayerTimes? pt, String? prayerName) {
  if (pt == null || prayerName == null || prayerName == "--") return null;
  try {
    switch (prayerName) {
      case "Fajr":
        return pt.sunrise;
      case "Ishraq":
        return pt.sunrise.add(const Duration(minutes: 45));
      case "Chasht":
        return pt.dhuhr.subtract(const Duration(minutes: 10));
      case "Dhuhr":
        return pt.asr;
      case "Asr":
        return pt.maghrib.subtract(const Duration(minutes: 10));
      case "Maghrib":
        return pt.isha;
      case "Isha":
        return pt.fajr.add(const Duration(days: 1));
      default:
        return null;
    }
  } catch (_) {
    return null;
  }
}

Map<String, dynamic> _getProhibitedTime(PrayerTimes? pt) {
  final _empty = {"active": false, "from": "", "to": ""};
  if (pt == null) return _empty;
  try {
    final now = DateTime.now();
    final sunriseEnd = pt.sunrise.add(const Duration(minutes: 15));
    final zawalStart = pt.dhuhr.subtract(const Duration(minutes: 10));
    final maghribStart = pt.maghrib.subtract(const Duration(minutes: 10));

    if (now.isAfter(pt.sunrise) && now.isBefore(sunriseEnd)) {
      return {
        "active": true,
        "from": formatTime(pt.sunrise),
        "to": formatTime(sunriseEnd),
      };
    }
    if (now.isAfter(zawalStart) && now.isBefore(pt.dhuhr)) {
      return {
        "active": true,
        "from": formatTime(zawalStart),
        "to": formatTime(pt.dhuhr),
      };
    }
    if (now.isAfter(maghribStart) && now.isBefore(pt.maghrib)) {
      return {
        "active": true,
        "from": formatTime(maghribStart),
        "to": formatTime(pt.maghrib),
      };
    }
    return _empty;
  } catch (_) {
    return _empty;
  }
}

Map<String, dynamic> _getUpcomingProhibitedTime(PrayerTimes? pt) {
  final _empty = {"active": false, "from": "", "to": ""};
  if (pt == null) return _empty;
  try {
    final now = DateTime.now();
    final list = [
      {"from": pt.sunrise, "to": pt.sunrise.add(const Duration(minutes: 15))},
      {"from": pt.dhuhr.subtract(const Duration(minutes: 10)), "to": pt.dhuhr},
      {
        "from": pt.maghrib.subtract(const Duration(minutes: 10)),
        "to": pt.maghrib,
      },
    ];
    for (final p in list) {
      final from = p["from"] as DateTime;
      final to = p["to"] as DateTime;
      if (now.isBefore(from)) {
        return {"active": true, "from": formatTime(from), "to": formatTime(to)};
      }
    }
    return _empty;
  } catch (_) {
    return _empty;
  }
}

bool _isProhibitedJustAfterPrayer(PrayerTimes? pt, DateTime? prayerEndTime) {
  if (pt == null || prayerEndTime == null) return false;
  try {
    final list = [
      pt.sunrise,
      pt.dhuhr.subtract(const Duration(minutes: 10)),
      pt.maghrib.subtract(const Duration(minutes: 10)),
    ];
    for (final t in list) {
      final diff = t.difference(prayerEndTime).inMinutes;
      if (diff >= 0 && diff <= 15) return true;
    }
  } catch (_) {}
  return false;
}

DateTime? _getUpcomingProhibitedStartDateTime(PrayerTimes? pt) {
  if (pt == null) return null;
  try {
    final now = DateTime.now();
    final list = [
      pt.sunrise,
      pt.dhuhr.subtract(const Duration(minutes: 10)),
      pt.maghrib.subtract(const Duration(minutes: 10)),
    ];
    for (final t in list) {
      if (now.isBefore(t)) return t;
    }
  } catch (_) {}
  return null;
}

DateTime? _getProhibitedEndDateTime(PrayerTimes? pt) {
  if (pt == null) return null;
  try {
    final now = DateTime.now();
    if (now.isAfter(pt.sunrise) &&
        now.isBefore(pt.sunrise.add(const Duration(minutes: 15)))) {
      return pt.sunrise.add(const Duration(minutes: 15));
    }
    if (now.isAfter(pt.dhuhr.subtract(const Duration(minutes: 10))) &&
        now.isBefore(pt.dhuhr)) {
      return pt.dhuhr;
    }
    if (now.isAfter(pt.maghrib.subtract(const Duration(minutes: 10))) &&
        now.isBefore(pt.maghrib)) {
      return pt.maghrib;
    }
  } catch (_) {}
  return null;
}
