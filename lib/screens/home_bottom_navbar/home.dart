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
import 'package:salah_mode/screens/widgets/prayer_grid.dart';
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
  Prayer? _currentPrayer;

  String _ayahText = '';
  String _ayahRef = '';
  bool _ayahLoading = true;

  bool _initialized = false;

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
        _currentPrayer = prayerTimes.currentPrayer();
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
                  nextPrayerCard(
                    context,
                    _nextPrayerTime,
                    _remaining,
                    _nextPrayerName,
                    _cityName,
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
                  prayerGrid(
                    context,
                    _prayerTimes,
                    _nextPrayerName,
                    _currentPrayer,
                  ),
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
