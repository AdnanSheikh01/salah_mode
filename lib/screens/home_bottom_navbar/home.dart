import 'package:adhan/adhan.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';
import 'package:salah_mode/screens/widgets/prohibited_times.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salah_mode/screens/widgets/daily_ayah.dart';
import 'package:salah_mode/screens/widgets/prayer_card.dart';
import 'package:salah_mode/screens/widgets/prayer_lock.dart';
import 'package:salah_mode/screens/widgets/salam_header.dart';
import 'package:salah_mode/screens/widgets/prayer_time_services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver,
        TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────
  bool prayerLockEnabled = false;
  int lockMinutes = 15;

  DateTime _nextPrayerTime = DateTime.now();
  String _nextPrayerName = '';
  PrayerTimes? _prayerTimes;
  Duration _remaining = Duration.zero;
  String _cityName = 'Loading...';

  final AudioPlayer _adhanPlayer = AudioPlayer();
  late PrayerTimeService _prayerService;

  late DateTime sunriseStart;
  late DateTime sunriseEnd;
  late DateTime sunsetStart;
  late DateTime zawalStart;
  late DateTime maghribStart;
  late DateTime dhuhrTime;

  String _ayahText = '';
  String _ayahRef = '';
  bool _ayahLoading = true;

  String _fmt(DateTime t) => DateFormat.jm().format(t.toLocal());

  final Map<String, bool> _prayerTicks = {
    'Fajr': false,
    'Dhuhr': false,
    'Asr': false,
    'Maghrib': false,
    'Isha': false,
  };

  @override
  bool get wantKeepAlive => true;

  // ── Lifecycle ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _prayerService = PrayerTimeService(
      onUpdate: () {
        if (!mounted) return;
        setState(() {
          _prayerTimes = _prayerService.prayerTimes;
          _nextPrayerName = _prayerService.nextPrayerName;
          _nextPrayerTime = _prayerService.nextPrayerTime;
          _remaining = _prayerService.remaining;
          _cityName = _prayerService.cityName;
          sunriseStart = _prayerTimes!.sunrise;
          sunriseEnd = sunriseStart.add(const Duration(minutes: 15));
          dhuhrTime = _prayerTimes!.dhuhr;
          zawalStart = dhuhrTime.subtract(const Duration(minutes: 10));
          maghribStart = _prayerTimes!.maghrib;
          sunsetStart = maghribStart.subtract(const Duration(minutes: 15));
        });
      },
    );

    _prayerService.init();
    _loadDailyAyah();
    _loadPrayerTicks();
  }

  @override
  void dispose() {
    _adhanPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _prayerService.dispose();
    super.dispose();
  }

  // ── Data helpers ───────────────────────────────────────────────
  final _userName = FirebaseAuth.instance.currentUser?.displayName;

  Future<void> _loadPrayerTicks() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (final key in _prayerTicks.keys) {
        _prayerTicks[key] = prefs.getBool('tick_$key') ?? false;
      }
    });
  }

  Future<void> _savePrayerTick(String name, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tick_$name', value);
  }

  Future<void> _loadDailyAyah() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/ayah/random/en.asad'),
      );
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body)['data'];
        setState(() {
          _ayahText = data['text'];
          _ayahRef =
              "— ${data['surah']['englishName']} ${data['numberInSurah']}";
          _ayahLoading = false;
        });
      }
    } catch (_) {}
  }

  void _checkAllPrayersCompleted() {
    if (!_prayerTicks.values.every((v) => v)) return;
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark
        ? AppTheme.darkAccentGreen
        : AppTheme.lightAccent;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "MashaAllah! All prayers completed today 🤲",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextOnAccent,
          ),
        ),
        backgroundColor: accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final bgColor = isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: accentColor,
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          onRefresh: () async {
            try {
              await _prayerService.updateLocationSilently().timeout(
                const Duration(seconds: 10),
              );
            } catch (_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Location taking too long. Showing last known prayer times.",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  backgroundColor: isDark
                      ? AppTheme.darkCardAlt
                      : AppTheme.lightCardAlt,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 10),

              // ── Greeting header ────────────────────────────────
              salamHeader(context, _userName ?? ""),

              const SizedBox(height: 24),

              // ── Skeleton or live content ───────────────────────
              if (_prayerTimes == null)
                _buildSkeletonLoader(isDark)
              else ...[
                prayerCard(
                  context,
                  _nextPrayerTime,
                  _remaining,
                  _nextPrayerName,
                  _cityName,
                  _prayerTimes!,
                ),

                const SizedBox(height: 24),

                _sectionHeader(
                  context,
                  "UTILITIES",
                  Icons.auto_awesome_rounded,
                  isDark,
                ),

                prayerLockCard(
                  context,
                  prayerLockEnabled,
                  lockMinutes,
                  (v) => setState(() => prayerLockEnabled = v),
                  (m) => setState(() => lockMinutes = m),
                ),

                const SizedBox(height: 24),

                _sectionHeader(
                  context,
                  "DAILY TRACKER",
                  Icons.event_available_rounded,
                  isDark,
                ),

                prayerTickCard(context, _prayerTicks, _prayerTimes!, (
                  name,
                  value,
                ) async {
                  HapticFeedback.lightImpact();
                  setState(() => _prayerTicks[name] = value);
                  await _savePrayerTick(name, value);
                  if (value) _checkAllPrayersCompleted();
                }),

                const SizedBox(height: 24),

                prohibitedTimeCard(
                  context,
                  _prayerTimes!,
                  "${_fmt(sunriseStart)} - ${_fmt(sunriseEnd)}",
                  "${_fmt(zawalStart)} - ${_fmt(dhuhrTime)}",
                  "${_fmt(sunsetStart)} - ${_fmt(maghribStart)}",
                ),

                const SizedBox(height: 24),

                dailyAyah(
                  context,
                  _loadDailyAyah,
                  _ayahLoading,
                  _ayahText,
                  _ayahRef,
                ),

                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────
  Widget _sectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    bool isDark,
  ) {
    final color = isDark
        ? AppTheme.darkTextTertiary
        : AppTheme.lightTextTertiary;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 7),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  // ── Skeleton loader ────────────────────────────────────────────
  Widget _buildSkeletonLoader(bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCardAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 0.8,
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
          backgroundColor: (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
              .withOpacity(0.15),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PRAYER TICK CARD
// ═══════════════════════════════════════════════════════════════════

Widget prayerTickCard(
  BuildContext context,
  Map<String, bool> ticks,
  PrayerTimes prayerTimes,
  Function(String, bool) onChanged,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
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

  final now = DateTime.now();

  // Completion count for the progress indicator
  final completedCount = ticks.values.where((v) => v).length;
  final totalCount = ticks.length;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor, width: 0.8),
    ),
    child: Column(
      children: [
        // ── Progress bar ─────────────────────────────────────────
        Row(
          children: [
            Text(
              "$completedCount / $totalCount prayers",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              completedCount == totalCount ? "MashaAllah! ✦" : "Keep going",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: completedCount == totalCount
                    ? accentColor
                    : textTertiary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Thin progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: completedCount / totalCount,
            minHeight: 4,
            backgroundColor: borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ),

        const SizedBox(height: 14),

        Divider(color: borderColor, thickness: 0.8),

        // ── Prayer rows ──────────────────────────────────────────
        ...ticks.keys.map((name) {
          final isDone = ticks[name] ?? false;

          final DateTime prayerTime;
          switch (name) {
            case 'Fajr':
              prayerTime = prayerTimes.fajr;
              break;
            case 'Dhuhr':
              prayerTime = prayerTimes.dhuhr;
              break;
            case 'Asr':
              prayerTime = prayerTimes.asr;
              break;
            case 'Maghrib':
              prayerTime = prayerTimes.maghrib;
              break;
            case 'Isha':
              prayerTime = prayerTimes.isha;
              break;
            default:
              prayerTime = prayerTimes.fajr;
          }

          final canTick = now.isAfter(prayerTime);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: GestureDetector(
              onTap: () {
                if (canTick) {
                  onChanged(name, !isDone);
                } else {
                  HapticFeedback.mediumImpact();
                  if (!ScaffoldMessenger.of(context).mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "$name prayer starts at ${_formatPrayerTime(prayerTime)}",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                      backgroundColor: isDark
                          ? AppTheme.darkCardAlt
                          : AppTheme.lightCardAlt,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDone
                      ? accentColor.withOpacity(0.08)
                      : Colors.transparent,
                  border: Border.all(
                    color: isDone
                        ? accentColor.withOpacity(0.30)
                        : borderColor.withOpacity(0.5),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    // Check icon
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isDone
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        key: ValueKey(isDone),
                        color: isDone
                            ? accentColor
                            : (canTick
                                  ? textTertiary
                                  : textTertiary.withOpacity(0.35)),
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Prayer name
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
                        color: isDone ? textPrimary : textSecondary,
                      ),
                    ),

                    // "Not yet" label for future prayers
                    if (!canTick) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: borderColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "upcoming",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            color: textTertiary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Prayer time
                    Text(
                      _formatPrayerTime(prayerTime),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDone ? accentColor : textTertiary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    ),
  );
}

String _formatPrayerTime(DateTime time) => DateFormat.jm().format(time);
