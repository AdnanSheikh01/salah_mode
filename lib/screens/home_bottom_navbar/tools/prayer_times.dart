import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';
import 'package:salah_mode/screens/widgets/prayer_time_services.dart';

// ── Prohibited time slot ───────────────────────────────────────────
class _ProhibitedSlot {
  final String label;
  final String reason;
  final DateTime start;
  final DateTime end;

  const _ProhibitedSlot({
    required this.label,
    required this.reason,
    required this.start,
    required this.end,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  Duration get remaining {
    final r = end.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }
}

// ── Prayer row model ───────────────────────────────────────────────
class _PrayerRow {
  final String name;
  final DateTime time;
  final DateTime end;
  final IconData icon;
  final bool isProhibited; // this is itself a prohibited window
  final bool hasProhibited; // a prohibited slot falls within this prayer
  final String? prohibitedTag; // tag text for hasProhibited rows

  const _PrayerRow({
    required this.name,
    required this.time,
    required this.end,
    required this.icon,
    this.isProhibited = false,
    this.hasProhibited = false,
    this.prohibitedTag,
  });
}

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});
  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen>
    with TickerProviderStateMixin {
  late PrayerTimeService _prayerService;

  // ── Raw times from adhan ───────────────────────────────────────
  Map<String, DateTime> _times = {};
  String _nextPrayer = '';
  String _currentPrayer = '';
  DateTime? _currentStart;
  DateTime? _currentEnd;
  String _city = 'Loading...';
  bool _loadingLocation = true;
  bool _refreshing = false;

  // ── Derived display rows + prohibited slots ────────────────────
  List<_PrayerRow> _rows = [];
  List<_ProhibitedSlot> _prohibitedSlots = [];
  _ProhibitedSlot? _activeProhibited;

  // ── Animation ──────────────────────────────────────────────────
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;
  late final Ticker _ticker;

  // ── Tomorrow Fajr cache ────────────────────────────────────────
  DateTime? _tomorrowFajr;
  int? _cacheDay;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressAnim = const AlwaysStoppedAnimation(0);

    _ticker = createTicker((_) {
      if (!mounted) return;
      _tickUpdate();
    });
    _ticker.start();

    _prayerService = PrayerTimeService(onUpdate: _onServiceUpdate);
    _prayerService.init();
  }

  void _tickUpdate() {
    final active = _prohibitedSlots.cast<_ProhibitedSlot?>().firstWhere(
      (s) => s!.isActive,
      orElse: () => null,
    );
    if (active != _activeProhibited) {
      setState(() => _activeProhibited = active);
    }
    _refreshProgress();
  }

  // ── Service callback ───────────────────────────────────────────
  void _onServiceUpdate() {
    if (!mounted) return;
    try {
      final pt = _prayerService.prayerTimes;
      if (pt == null) return;

      // ── Raw adhan times ────────────────────────────────────────
      final raw = <String, DateTime>{
        "Fajr": pt.fajr,
        "Sunrise": pt.sunrise,
        "Dhuhr": pt.dhuhr,
        "Asr": pt.asr,
        "Maghrib": pt.maghrib,
        "Isha": pt.isha,
      };

      // ── Derived times ──────────────────────────────────────────
      final ishraqStart = pt.sunrise.add(const Duration(minutes: 20));
      final chashtStart = pt.sunrise.add(const Duration(minutes: 45));
      final zawalStart = pt.dhuhr.subtract(const Duration(minutes: 10));
      final sunsetStart = pt.maghrib.subtract(const Duration(minutes: 15));

      // ── Prohibited slots (the actual forbidden windows) ────────
      final slots = [
        _ProhibitedSlot(
          label: "Sunrise (Shuruq)",
          reason: "Prayer forbidden until sun fully rises",
          start: pt.sunrise,
          end: ishraqStart, // 20 min after sunrise
        ),
        _ProhibitedSlot(
          label: "Zawal (Solar Noon)",
          reason: "Prayer forbidden at sun's zenith",
          start: zawalStart,
          end: pt.dhuhr,
        ),
        _ProhibitedSlot(
          label: "Sunset (Ghurub)",
          reason: "Prayer forbidden as sun sets",
          start: sunsetStart,
          end: pt.maghrib,
        ),
      ];

      final tFajr = _getTomorrowFajr(pt);

      // ── Build display rows in correct order ────────────────────
      // Each row: name, start, end, icon
      // hasProhibited = a forbidden slot starts EXACTLY at this row's start
      // isProhibited  = this row IS the forbidden window itself
      final rows = <_PrayerRow>[
        // 1. Fajr → Sunrise
        _PrayerRow(
          name: "Fajr",
          time: pt.fajr,
          end: pt.sunrise,
          icon: Icons.wb_twilight_rounded,
        ),

        // 2. Sunrise (prohibited 20 min) — this IS a forbidden window
        _PrayerRow(
          name: "Sunrise",
          time: pt.sunrise,
          end: ishraqStart,
          icon: Icons.wb_sunny_outlined,
          isProhibited: true,
          prohibitedTag: "Forbidden (20 min)",
        ),

        // 3. Ishraq → Chasht start
        _PrayerRow(
          name: "Ishraq",
          time: ishraqStart,
          end: chashtStart,
          icon: Icons.wb_sunny_outlined,
        ),

        // 4. Chasht → Zawal
        _PrayerRow(
          name: "Chasht",
          time: chashtStart,
          end: zawalStart,
          icon: Icons.wb_sunny_rounded,
        ),

        // 5. Zawal (prohibited 10 min) — this IS a forbidden window
        _PrayerRow(
          name: "Zawal",
          time: zawalStart,
          end: pt.dhuhr,
          icon: Icons.do_not_disturb_rounded,
          isProhibited: true,
          prohibitedTag: "Forbidden (10 min)",
        ),

        // 6. Dhuhr → Asr
        _PrayerRow(
          name: "Dhuhr",
          time: pt.dhuhr,
          end: pt.asr,
          icon: Icons.wb_sunny_rounded,
        ),

        // 7. Asr → Sunset forbidden window
        _PrayerRow(
          name: "Asr",
          time: pt.asr,
          end: sunsetStart,
          icon: Icons.light_mode_rounded,
        ),

        // 8. Sunset (prohibited 15 min) — this IS a forbidden window
        _PrayerRow(
          name: "Sunset",
          time: sunsetStart,
          end: pt.maghrib,
          icon: Icons.wb_twilight_rounded,
          isProhibited: true,
          prohibitedTag: "Forbidden (15 min)",
        ),

        // 9. Maghrib → Isha
        _PrayerRow(
          name: "Maghrib",
          time: pt.maghrib,
          end: pt.isha,
          icon: Icons.nights_stay_rounded,
        ),

        // 10. Isha → Tomorrow Fajr
        _PrayerRow(
          name: "Isha",
          time: pt.isha,
          end: tFajr ?? pt.isha.add(const Duration(hours: 5)),
          icon: Icons.dark_mode_rounded,
        ),
      ];

      // Current/next prayer resolution — use raw adhan names
      // but also check if now falls in Ishraq, Chasht, Zawal, Sunset
      final status = _prayerService.getCurrentPrayerStatus();
      String name = (status['name'] as String?) ?? '';
      DateTime? start = status['start'] as DateTime?;
      DateTime? end;

      // Refine: check if now is in Ishraq/Chasht/Zawal/Sunset/Sunrise-prohibited
      final now = DateTime.now();
      if (now.isAfter(pt.sunrise) && now.isBefore(ishraqStart)) {
        name = "Sunrise";
        start = pt.sunrise;
        end = ishraqStart;
      } else if (now.isAfter(ishraqStart) && now.isBefore(chashtStart)) {
        name = "Ishraq";
        start = ishraqStart;
        end = chashtStart;
      } else if (now.isAfter(chashtStart) && now.isBefore(zawalStart)) {
        name = "Chasht";
        start = chashtStart;
        end = zawalStart;
      } else if (now.isAfter(zawalStart) && now.isBefore(pt.dhuhr)) {
        name = "Zawal";
        start = zawalStart;
        end = pt.dhuhr;
      } else if (now.isAfter(sunsetStart) && now.isBefore(pt.maghrib)) {
        name = "Sunset";
        start = sunsetStart;
        end = pt.maghrib;
      } else if (name.isNotEmpty) {
        // Use adhan end
        final row = rows.cast<_PrayerRow?>().firstWhere(
          (r) => r!.name.toLowerCase() == name.toLowerCase(),
          orElse: () => null,
        );
        end = row?.end;
      }

      final active = slots.cast<_ProhibitedSlot?>().firstWhere(
        (s) => s!.isActive,
        orElse: () => null,
      );

      setState(() {
        _times = raw;
        _nextPrayer = _prayerService.nextPrayerName;
        // _remaining removed — computed live via _liveRemaining getter
        _city = _prayerService.cityName.trim().isEmpty
            ? 'Unknown location'
            : _prayerService.cityName;
        _currentPrayer = name;
        _currentStart = start;
        _currentEnd = end;
        _loadingLocation = false;
        _refreshing = false;
        _rows = rows;
        _prohibitedSlots = slots;
        _activeProhibited = active;
      });

      _refreshProgress();
    } catch (e) {
      debugPrint("PrayerTimesScreen error: $e");
      if (mounted)
        setState(() {
          _loadingLocation = false;
          _refreshing = false;
        });
    }
  }

  // ── Tomorrow Fajr ──────────────────────────────────────────────
  DateTime? _getTomorrowFajr(PrayerTimes pt) {
    try {
      final today = DateTime.now().day;
      if (_tomorrowFajr != null && _cacheDay == today) return _tomorrowFajr;
      final params = CalculationMethod.karachi.getParameters()
        ..madhab = Madhab.hanafi;
      final tPt = PrayerTimes(
        pt.coordinates,
        DateComponents.from(DateTime.now().add(const Duration(days: 1))),
        params,
      );
      _tomorrowFajr = tPt.fajr;
      _cacheDay = today;
      return _tomorrowFajr;
    } catch (_) {
      return null;
    }
  }

  // ── Live remaining — recomputed every tick ────────────────────
  // _prayerService.remaining only knows the 5 adhan prayers so it is
  // WRONG for Ishraq / Chasht / Zawal / Sunset windows.
  // We always derive from _currentEnd instead.
  Duration get _liveRemaining {
    try {
      if (_activeProhibited != null) return _activeProhibited!.remaining;
      if (_currentEnd == null) return Duration.zero;
      final r = _currentEnd!.difference(DateTime.now());
      return r.isNegative ? Duration.zero : r;
    } catch (_) {
      return Duration.zero;
    }
  }

  // ── Progress ───────────────────────────────────────────────────
  double _progress() {
    try {
      if (_activeProhibited != null) {
        final s = _activeProhibited!;
        final total = s.end.difference(s.start).inSeconds;
        final passed = DateTime.now().difference(s.start).inSeconds;
        return total <= 0 ? 0 : (passed / total).clamp(0.0, 1.0);
      }
      if (_currentStart == null || _currentEnd == null) return 0;
      final now = DateTime.now();
      if (now.isBefore(_currentStart!)) return 0;
      if (now.isAfter(_currentEnd!)) return 1;
      final total = _currentEnd!.difference(_currentStart!).inSeconds;
      final passed = now.difference(_currentStart!).inSeconds;
      return total <= 0 ? 0 : (passed / total).clamp(0.0, 1.0);
    } catch (_) {
      return 0;
    }
  }

  Color _progressColor(double p) {
    if (_activeProhibited != null) return AppTheme.colorError;
    if (p < 0.5) return AppTheme.colorSuccess;
    if (p < 0.8) return AppTheme.colorWarning;
    return AppTheme.colorError;
  }

  void _refreshProgress() {
    final p = _progress();
    _progressAnim = Tween<double>(
      begin: _progressAnim.value,
      end: p,
    ).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
    _progressCtrl
      ..reset()
      ..forward();
  }

  // ── Formatting ─────────────────────────────────────────────────
  String _fmtTime(DateTime t) {
    try {
      final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
      final m = t.minute.toString().padLeft(2, '0');
      return "$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}";
    } catch (_) {
      return '--:--';
    }
  }

  String _fmtDuration(Duration d) {
    if (d.isNegative || d == Duration.zero) return "00:00:00";
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  void dispose() {
    _ticker.dispose();
    _progressCtrl.dispose();
    try {
      _prayerService.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final cardAltColor = isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final textPrimary = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final textTertiary = isDark
        ? AppTheme.darkTextTertiary
        : AppTheme.lightTextTertiary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final btnTextColor = isDark
        ? AppTheme.darkTextOnAccent
        : AppTheme.lightTextOnAccent;

    final isProhibited = _activeProhibited != null;
    final headerColor = isProhibited ? AppTheme.colorError : accentColor;

    final headerLabel = isProhibited
        ? _activeProhibited!.label
        : _currentPrayer.isEmpty
        ? "Loading..."
        : _currentPrayer;

    final headerCountdown = _fmtDuration(_liveRemaining);

    final headerStart = isProhibited
        ? _fmtTime(_activeProhibited!.start)
        : (_currentStart == null ? '' : _fmtTime(_currentStart!));

    final headerEnd = isProhibited
        ? _fmtTime(_activeProhibited!.end)
        : (_currentEnd == null ? '' : _fmtTime(_currentEnd!));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentColor, size: 20),
        title: Text(
          "Prayer Times",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Header card ────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // City + refresh
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: btnTextColor.withOpacity(0.75),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: btnTextColor.withOpacity(0.80),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _refreshing
                          ? null
                          : () async {
                              if (!mounted) return;
                              setState(() => _refreshing = true);
                              try {
                                await _prayerService
                                    .updateLocationSilently()
                                    .timeout(const Duration(seconds: 15));
                              } catch (_) {
                                if (mounted)
                                  setState(() => _refreshing = false);
                              }
                            },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: btnTextColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: _refreshing
                            ? Padding(
                                padding: const EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: btnTextColor,
                                ),
                              )
                            : Icon(
                                Icons.refresh_rounded,
                                color: btnTextColor,
                                size: 18,
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Center(
                  child: Column(
                    children: [
                      // Prohibited chip
                      if (isProhibited)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: btnTextColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: btnTextColor.withOpacity(0.30),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.block_rounded,
                                size: 12,
                                color: btnTextColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Prohibited Time",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: btnTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Prayer / slot name
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          headerLabel,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: btnTextColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Reason or "Current Prayer"
                      if (isProhibited)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _activeProhibited!.reason,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: btnTextColor.withOpacity(0.78),
                              height: 1.4,
                            ),
                          ),
                        )
                      else
                        Text(
                          "Current Prayer",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: btnTextColor.withOpacity(0.70),
                          ),
                        ),

                      const SizedBox(height: 10),

                      // Countdown pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: btnTextColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isProhibited
                                  ? Icons.timer_off_rounded
                                  : Icons.timer_rounded,
                              color: btnTextColor.withOpacity(0.80),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isProhibited
                                  ? "Ends in $headerCountdown"
                                  : "-$headerCountdown",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: btnTextColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Progress bar
                      Row(
                        children: [
                          Text(
                            headerStart,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: btnTextColor.withOpacity(0.70),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _progressCtrl,
                              builder: (_, __) {
                                final p = _progressAnim.value;
                                return Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: LinearProgressIndicator(
                                        value: p,
                                        minHeight: 6,
                                        backgroundColor: btnTextColor
                                            .withOpacity(0.20),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              _progressColor(p),
                                            ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment(
                                        (p * 2 - 1).clamp(-1.0, 1.0),
                                        0,
                                      ),
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: btnTextColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            headerEnd,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: btnTextColor.withOpacity(0.70),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Prohibited slots horizontal scroll ─────────────────
          if (_prohibitedSlots.isNotEmpty)
            _ProhibitedSection(
              slots: _prohibitedSlots,
              active: _activeProhibited,
              fmtTime: _fmtTime,
              fmtDur: _fmtDuration,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecond: textSecondary,
            ),

          // ── Prayer rows list ───────────────────────────────────
          Expanded(
            child: (_loadingLocation && _rows.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: accentColor,
                          backgroundColor: accentColor.withOpacity(0.15),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Fetching prayer times...",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      if (i >= _rows.length) return const SizedBox.shrink();
                      final row = _rows[i];

                      // Determine if this row is currently active
                      final now = DateTime.now();
                      final isCurrent =
                          now.isAfter(row.time) && now.isBefore(row.end);
                      // Next = the first row whose start is after now
                      final isNext =
                          !isCurrent &&
                          row.time.isAfter(now) &&
                          _rows
                                  .where((r) {
                                    final thisNow = DateTime.now();
                                    return r.time.isAfter(thisNow);
                                  })
                                  .first
                                  .name ==
                              row.name;

                      // ── Tile colors ──────────────────────────────
                      Color tileBg,
                          tileBorder,
                          nameColor,
                          subColor,
                          timeColor,
                          iconBg,
                          iconColor;

                      if (row.isProhibited && isCurrent) {
                        // Active forbidden window
                        tileBg = AppTheme.colorError;
                        tileBorder = AppTheme.colorError;
                        nameColor = Colors.white;
                        subColor = Colors.white70;
                        timeColor = Colors.white70;
                        iconBg = Colors.white24;
                        iconColor = Colors.white;
                      } else if (row.isProhibited) {
                        // Upcoming/past forbidden window
                        tileBg = AppTheme.colorError.withOpacity(0.07);
                        tileBorder = AppTheme.colorError.withOpacity(0.30);
                        nameColor = AppTheme.colorError;
                        subColor = AppTheme.colorError.withOpacity(0.70);
                        timeColor = AppTheme.colorError.withOpacity(0.70);
                        iconBg = AppTheme.colorError.withOpacity(0.10);
                        iconColor = AppTheme.colorError;
                      } else if (isCurrent) {
                        tileBg = accentColor;
                        tileBorder = accentColor;
                        nameColor = btnTextColor;
                        subColor = btnTextColor.withOpacity(0.75);
                        timeColor = btnTextColor.withOpacity(0.85);
                        iconBg = btnTextColor.withOpacity(0.15);
                        iconColor = btnTextColor;
                      } else if (isNext) {
                        tileBg = accentColor.withOpacity(0.10);
                        tileBorder = accentColor.withOpacity(0.35);
                        nameColor = textPrimary;
                        subColor = accentColor;
                        timeColor = textSecondary;
                        iconBg = accentColor.withOpacity(0.18);
                        iconColor = accentColor;
                      } else {
                        tileBg = cardColor;
                        tileBorder = borderColor;
                        nameColor = textPrimary;
                        subColor = textTertiary;
                        timeColor = textSecondary;
                        iconBg = accentColor.withOpacity(0.08);
                        iconColor = accentColor;
                      }

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                        decoration: BoxDecoration(
                          color: tileBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: tileBorder, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: iconBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(row.icon, color: iconColor, size: 20),
                            ),

                            const SizedBox(width: 14),

                            // Name + label + range
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          row.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: nameColor,
                                          ),
                                        ),
                                      ),

                                      // "FORBIDDEN" tag on prohibited rows
                                      if (row.isProhibited) ...[
                                        const SizedBox(width: 7),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (isCurrent
                                                        ? Colors.white
                                                        : AppTheme.colorError)
                                                    .withOpacity(0.18),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color:
                                                  (isCurrent
                                                          ? Colors.white
                                                          : AppTheme.colorError)
                                                      .withOpacity(0.35),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            "FORBIDDEN",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 7,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.3,
                                              color: isCurrent
                                                  ? Colors.white
                                                  : AppTheme.colorError,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),

                                  const SizedBox(height: 3),

                                  Text(
                                    row.isProhibited
                                        ? (row.prohibitedTag ??
                                              "Forbidden window")
                                        : isCurrent
                                        ? "Current"
                                        : isNext
                                        ? "Next prayer"
                                        : "Upcoming",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: subColor,
                                      fontWeight: isCurrent || isNext
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),

                                  const SizedBox(height: 3),

                                  Text(
                                    "${_fmtTime(row.time)}  →  ${_fmtTime(row.end)}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: timeColor,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Time badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: row.isProhibited
                                    ? (isCurrent
                                          ? Colors.white.withOpacity(0.20)
                                          : AppTheme.colorError.withOpacity(
                                              0.10,
                                            ))
                                    : isCurrent
                                    ? btnTextColor.withOpacity(0.15)
                                    : isNext
                                    ? accentColor.withOpacity(0.12)
                                    : cardAltColor,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    (isCurrent || isNext || row.isProhibited)
                                    ? null
                                    : Border.all(
                                        color: borderColor,
                                        width: 0.8,
                                      ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _fmtTime(row.time),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: timeColor,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
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

// ═══════════════════════════════════════════════════════════════════
//  PROHIBITED SLOTS HORIZONTAL SCROLL
// ═══════════════════════════════════════════════════════════════════

class _ProhibitedSection extends StatelessWidget {
  final List<_ProhibitedSlot> slots;
  final _ProhibitedSlot? active;
  final String Function(DateTime) fmtTime;
  final String Function(Duration) fmtDur;
  final Color cardColor, borderColor, textPrimary, textSecond;

  const _ProhibitedSection({
    required this.slots,
    required this.active,
    required this.fmtTime,
    required this.fmtDur,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecond,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.colorError,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Forbidden Prayer Times",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.colorError,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemCount: slots.length,
              itemBuilder: (_, i) {
                final s = slots[i];
                final isActive = s.isActive;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.colorError.withOpacity(0.12)
                        : cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.colorError.withOpacity(0.45)
                          : borderColor,
                      width: isActive ? 1.2 : 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.block_rounded,
                            size: 11,
                            color: isActive
                                ? AppTheme.colorError
                                : textSecond.withOpacity(0.55),
                          ),
                          const SizedBox(width: 5),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 110),
                            child: Text(
                              s.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? AppTheme.colorError
                                    : textPrimary,
                              ),
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.colorError,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "ACTIVE",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        isActive
                            ? "Ends in ${fmtDur(s.remaining)}"
                            : "${fmtTime(s.start)} — ${fmtTime(s.end)}",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: isActive
                              ? AppTheme.colorError.withOpacity(0.80)
                              : textSecond,
                          fontFeatures: const [FontFeature.tabularFigures()],
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
