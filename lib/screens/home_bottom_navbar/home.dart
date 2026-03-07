import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  bool prayerLockEnabled = false;
  int lockMinutes = 15;
  bool emergencyUnlocked = false;
  DateTime _nextPrayerTime = DateTime.now();
  String _nextPrayerName = '';
  final Madhab _madhab = Madhab.hanafi;
  PrayerTimes? _prayerTimes;
  Duration _remaining = Duration.zero;
  Timer? _timer;
  bool beepOnEnd = false;
  final AudioPlayer _adhanPlayer = AudioPlayer();
  String _cityName = '';
  Prayer? currentPrayer;

  String _ayahText = '';
  String _ayahRef = '';
  bool _ayahLoading = true;

  bool _initialized = false;
  final Map<String, bool> _prayerTicks = {
    'Fajr': false,
    'Dhuhr': false,
    'Asr': false,
    'Maghrib': false,
    'Isha': false,
  };

  void _checkAllPrayersCompleted() {
    final allDone = _prayerTicks.values.every((v) => v);

    if (allDone && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: const Text(
            "🏆 All prayers completed today! MashaAllah",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLocationAndPrayers();
    _loadDailyAyah();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPrayerTimes();
    }
  }

  // --- Logic & Data Fetching ---

  Future<void> _initLocationAndPrayers() async {
    if (_initialized) return;
    _initialized = true;
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    await _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final coordinates = Coordinates(position.latitude, position.longitude);
      await _loadCityName(position.latitude, position.longitude);

      final params = CalculationMethod.karachi.getParameters();
      params.madhab = _madhab;

      final date = DateComponents.from(DateTime.now());
      final prayerTimes = PrayerTimes(coordinates, date, params);

      setState(() {
        _prayerTimes = prayerTimes;
        currentPrayer = prayerTimes.currentPrayer();
        _updateNextPrayer();
      });
    } catch (e) {
      debugPrint("Error loading prayers: $e");
    }
  }

  Future<void> _loadCityName(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _cityName = place.locality ?? place.subAdministrativeArea ?? '';
        });
      }
    } catch (_) {}
  }

  void _updateNextPrayer() {
    if (_prayerTimes == null) return;

    final next = _prayerTimes!.nextPrayer();
    DateTime? time;

    switch (next) {
      case Prayer.fajr:
        time = _prayerTimes!.fajr;
        break;
      case Prayer.sunrise:
        time = _prayerTimes!.sunrise;
        break;
      case Prayer.dhuhr:
        time = _prayerTimes!.dhuhr;
        break;
      case Prayer.asr:
        time = _prayerTimes!.asr;
        break;
      case Prayer.maghrib:
        time = _prayerTimes!.maghrib;
        break;
      case Prayer.isha:
        time = _prayerTimes!.isha;
        break;
      case Prayer.none:
        // After Isha → next is tomorrow Fajr
        time = _prayerTimes!.fajr.add(const Duration(days: 1));
        break;
    }

    _nextPrayerName = next == Prayer.none ? 'FAJR' : next.name.toUpperCase();
    _nextPrayerTime = time;
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final now = DateTime.now();
      final diff = _nextPrayerTime.difference(now);

      if (diff.inSeconds <= 0) {
        timer.cancel();
        await _playAdhan();
        _loadPrayerTimes();
        return;
      }

      if (!mounted) return;
      setState(() {
        _remaining = diff;
      });
    });
  }

  Future<void> _playAdhan() async {
    try {
      await _adhanPlayer.play(AssetSource('audio/adhan.mp3'));
    } catch (e) {
      debugPrint('Adhan play error: $e');
    }
  }

  Future<void> _loadDailyAyah() async {
    setState(() => _ayahLoading = true);

    try {
      // Random ayah with English translation
      final response = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/ayah/random/en.asad'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ayah = data['data'];

        setState(() {
          _ayahText = ayah['text'] ?? '';
          _ayahRef =
              '— ${ayah['surah']['englishName']} ${ayah['numberInSurah']}';
          _ayahLoading = false;
        });
      } else {
        throw Exception('Failed to load ayah');
      }
    } catch (e) {
      debugPrint('Ayah API error: $e');
      setState(() {
        _ayahText = 'Unable to load Ayah';
        _ayahRef = '';
        _ayahLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadPrayerTimes();
              await _loadDailyAyah();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                salamHeader(context),
                const SizedBox(height: 20),
                if (_prayerTimes == null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
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
                  prayerLockCard(
                    context,
                    prayerLockEnabled,
                    lockMinutes,
                    (v) => setState(() => prayerLockEnabled = v),
                    (m) => setState(() => lockMinutes = m),
                  ),
                  const SizedBox(height: 20),

                  prayerTickCard(context, _prayerTicks, (name, value) {
                    setState(() => _prayerTicks[name] = value);
                    _checkAllPrayersCompleted();
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
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔹 Title
        /// 🔹 Header Row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Prayer Tracker",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        /// 🔹 Prayer list
        ...ticks.keys.map((name) {
          final isDone = ticks[name] ?? false;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(name, !isDone),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDone
                      ? theme.colorScheme.primary.withOpacity(0.12)
                      : Colors.transparent,
                  border: Border.all(
                    color: isDone ? theme.colorScheme.primary : Colors.white12,
                    width: isDone ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    /// Prayer name
                    Expanded(
                      child: Text(
                        name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    /// Checkbox icon
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isDone
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        key: ValueKey(isDone),
                        color: isDone
                            ? theme.colorScheme.primary
                            : Colors.white54,
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

Widget prohibitedTimeCard(BuildContext context, PrayerTimes prayerTimes) {
  final theme = Theme.of(context);

  final sunrise = TimeOfDay.fromDateTime(prayerTimes.sunrise).format(context);
  final dhuhr = TimeOfDay.fromDateTime(prayerTimes.dhuhr).format(context);
  final maghrib = TimeOfDay.fromDateTime(prayerTimes.maghrib).format(context);

  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.block, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Text(
              "Prohibited Prayer Times",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        /// Timeline bar showing forbidden zones
        Builder(
          builder: (context) {
            final fajr = prayerTimes.fajr;
            final sunrise = prayerTimes.sunrise;
            final dhuhr = prayerTimes.dhuhr;
            final asr = prayerTimes.asr;
            final maghrib = prayerTimes.maghrib;

            double _segment(DateTime start, DateTime end) {
              final total = end.difference(start).inMinutes.toDouble();
              if (total <= 0) return 0;
              return total;
            }

            final fajrForbidden = _segment(fajr, sunrise);
            final dhuhrForbidden = 10.0; // small peak period
            final asrForbidden = _segment(asr, maghrib);

            final safe1 = _segment(sunrise, dhuhr);
            final safe2 = _segment(dhuhr, asr);

            final total =
                fajrForbidden + safe1 + dhuhrForbidden + safe2 + asrForbidden;

            Widget buildPart(double value, Color color) {
              return Expanded(
                flex: (value * 1000 ~/ total).clamp(1, 1000),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(color: color),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final now = DateTime.now();
                    final start = fajr;
                    final end = maghrib;

                    double progress = 0;
                    if (now.isAfter(start) && now.isBefore(end)) {
                      final totalSeconds = end.difference(start).inSeconds;
                      final passedSeconds = now.difference(start).inSeconds;
                      progress = passedSeconds / totalSeconds;
                    }

                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Row(
                          children: [
                            buildPart(fajrForbidden, Colors.orange),
                            buildPart(safe1, Colors.green),
                            buildPart(dhuhrForbidden, Colors.orange),
                            buildPart(safe2, Colors.green),
                            buildPart(asrForbidden, Colors.orange),
                          ],
                        ),
                        Positioned(
                          left: constraints.maxWidth * progress,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Morning", style: TextStyle(fontSize: 11)),
                    Text("Noon", style: TextStyle(fontSize: 11)),
                    Text("Evening", style: TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),

        /// Time blocks
        _prohibitedTile("After Fajr until Sunrise", "7:00 AM - $sunrise"),
        _prohibitedTile("When Sun is at its peak", "1:30 PM - $dhuhr"),
        _prohibitedTile("After Asr until Maghrib", "4:00 PM - $maghrib"),

        const SizedBox(height: 16),

        /// Hadith
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            "The Messenger of Allah ﷺ forbade prayer after Fajr until the sun rises and after Asr until the sun sets.\n\n— Sahih al-Bukhari 586",
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ),
      ],
    ),
  );
}

Widget _prohibitedTile(String title, String time) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        const Icon(Icons.schedule, size: 18, color: Colors.orange),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(time, style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );
}
