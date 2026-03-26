import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For haptics
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

// Assuming these are your local imports
import 'package:salah_mode/screens/widgets/daily_ayah.dart';
import 'package:salah_mode/screens/widgets/next_prayer_card.dart';
import 'package:salah_mode/screens/widgets/prayer_lock.dart';
import 'package:salah_mode/screens/widgets/salam_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // State variables
  bool prayerLockEnabled = false;
  int lockMinutes = 15;
  DateTime _nextPrayerTime = DateTime.now();
  String _nextPrayerName = '';
  PrayerTimes? _prayerTimes;
  Duration _remaining = Duration.zero;
  Timer? _timer;
  final AudioPlayer _adhanPlayer = AudioPlayer();
  String _cityName = 'Loading...';

  String _ayahText = '';
  String _ayahRef = '';
  bool _ayahLoading = true;
  bool _isLocating = false;

  final Map<String, bool> _prayerTicks = {
    'Fajr': false,
    'Dhuhr': false,
    'Asr': false,
    'Maghrib': false,
    'Isha': false,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSequence();
    _loadDailyAyah();
  }

  // --- Optimized Logic ---

  Future<void> _initSequence() async {
    // 1. Check Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 2. Immediate Load (Fastest)
    Position? lastPos = await Geolocator.getLastKnownPosition();
    if (lastPos != null) {
      _calculatePrayers(lastPos);
    }

    // 3. Precise Update (Background)
    _updateLocationSilently();
  }

  Future<void> _updateLocationSilently() async {
    setState(() => _isLocating = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Lower accuracy = much faster
        timeLimit: const Duration(seconds: 5),
      );
      _calculatePrayers(position);
      _loadCityName(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("Silent location update failed: $e");
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _calculatePrayers(Position pos) {
    final coordinates = Coordinates(pos.latitude, pos.longitude);
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;

    final prayerTimes = PrayerTimes(
      coordinates,
      DateComponents.from(DateTime.now()),
      params,
    );

    if (mounted) {
      setState(() {
        _prayerTimes = prayerTimes;
        _updateNextPrayer();
      });
    }
  }

  void _updateNextPrayer() {
    if (_prayerTimes == null) return;
    final next = _prayerTimes!.nextPrayer();

    // Logic for after Isha (tomorrow's Fajr)
    if (next == Prayer.none) {
      _nextPrayerName = "FAJR";
      _nextPrayerTime = _prayerTimes!.fajr.add(const Duration(days: 1));
    } else {
      _nextPrayerName = next.name.toUpperCase();
      _nextPrayerTime = _prayerTimes!.timeForPrayer(next)!;
    }
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final diff = _nextPrayerTime.difference(DateTime.now());
      if (diff.inSeconds <= 0) {
        _updateLocationSilently(); // Refresh when time hits zero
      } else {
        setState(() => _remaining = diff);
      }
    });
  }

  Future<void> _loadCityName(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty && mounted) {
        setState(() => _cityName = placemarks.first.locality ?? "Unknown");
      }
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: () => _updateLocationSilently(),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 10),
              salamHeader(context),

              const SizedBox(height: 25),

              if (_prayerTimes == null)
                _buildSkeletonLoader()
              else ...[
                premiumNextPrayerHeader(
                  context,
                  _nextPrayerTime,
                  _remaining,
                  _nextPrayerName,
                  _cityName,
                  _prayerTimes!,
                ),

                const SizedBox(height: 20),

                // Professional Section Title
                _sectionHeader("UTILITIES", Icons.auto_awesome),
                prayerLockCard(
                  context,
                  prayerLockEnabled,
                  lockMinutes,
                  (v) => setState(() => prayerLockEnabled = v),
                  (m) => setState(() => lockMinutes = m),
                ),

                const SizedBox(height: 20),

                _sectionHeader("DAILY TRACKER", Icons.event_available_rounded),
                prayerTickCard(context, _prayerTicks, (name, value) {
                  HapticFeedback.lightImpact();
                  setState(() => _prayerTicks[name] = value);
                  if (value) _checkAllPrayersCompleted();
                }),

                const SizedBox(height: 20),

                prohibitedTimeCard(context, _prayerTimes!),

                const SizedBox(height: 20),

                dailyAyah(
                  context,
                  () => _loadDailyAyah(),
                  _ayahLoading,
                  _ayahText,
                  _ayahRef,
                ),
                const SizedBox(height: 30),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  void _checkAllPrayersCompleted() {
    if (_prayerTicks.values.every((v) => v)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("MashaAllah! All prayers done."),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _adhanPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

// --- Modified Professional Prohibited Card ---

Widget prohibitedTimeCard(BuildContext context, PrayerTimes prayerTimes) {
  final theme = Theme.of(context);

  // Logic for ranges
  final sunriseStart = prayerTimes.sunrise;
  final sunriseEnd = sunriseStart.add(const Duration(minutes: 15));
  final dhuhrTime = prayerTimes.dhuhr;
  final zawalStart = dhuhrTime.subtract(const Duration(minutes: 10));
  final maghribStart = prayerTimes.maghrib;
  final sunsetStart = maghribStart.subtract(const Duration(minutes: 15));

  String format(DateTime t) => DateFormat.jm().format(t.toLocal());

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Forbidden Times",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "MAKRUH",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _prohibitedRow(
          "Sunrise (Shuruq)",
          "${format(sunriseStart)} - ${format(sunriseEnd)}",
        ),
        _prohibitedRow(
          "Midday (Zawal)",
          "${format(zawalStart)} - ${format(dhuhrTime)}",
        ),
        _prohibitedRow(
          "Sunset (Ghurub)",
          "${format(sunsetStart)} - ${format(maghribStart)}",
        ),

        const SizedBox(height: 20),
        const Divider(color: Colors.white10),
        const SizedBox(height: 12),

        // Full Hadith Text
        Text(
          "HADITH REFERENCE",
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "“There were three times at which the Messenger of Allah (ﷺ) forbade us to pray, or to bury our dead: When the sun begins to rise till it is fully up, when the sun is at its height at midday till it passes over the meridian, and when the sun draws near to setting till it sets.”",
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
            height: 1.5,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "— Sahih Muslim 831",
          style: TextStyle(color: Colors.white24, fontSize: 11),
        ),
      ],
    ),
  );
}

Widget _prohibitedRow(String label, String time) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        const Icon(
          Icons.history_toggle_off_rounded,
          size: 18,
          color: Colors.orangeAccent,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const Spacer(),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

Widget prayerTickCard(
  BuildContext context,
  Map<String, bool> ticks,
  Function(String, bool) onChanged,
) {
  final theme = Theme.of(context);

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A), // Graphite/Obsidian base
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    ),
    child: Column(
      children: [
        ...ticks.keys.map((name) {
          final isDone = ticks[name] ?? false;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onChanged(name, !isDone),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  // Slight glow when checked
                  color: isDone
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: isDone ? theme.colorScheme.primary : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    // Modern Icon Status
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : Icons.panorama_fish_eye_rounded,
                      color: isDone
                          ? theme.colorScheme.primary
                          : Colors.white24,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      name,
                      style: TextStyle(
                        color: isDone ? Colors.white : Colors.white70,
                        fontWeight: isDone
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    // Optional: Add prayer time here if you pass prayerTimes to this widget
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
