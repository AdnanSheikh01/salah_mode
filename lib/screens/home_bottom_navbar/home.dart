import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart'; // Add this to your pubspec.yaml for easy time formatting
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool prayerLockEnabled = false;
  int lockMinutes = 15;
  bool emergencyUnlocked = false;
  DateTime _nextPrayerTime = DateTime.now();
  String _nextPrayerName = '';
  Madhab _madhab = Madhab.hanafi;
  PrayerTimes? _prayerTimes;
  Duration _remaining = Duration.zero;
  Timer? _timer;
  bool beepOnEnd = false;
  bool _isLoading = true;

  String _ayahText = '';
  String _ayahRef = '';
  bool _ayahLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocationAndPrayers();
    _loadDailyAyah();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Logic & Data Fetching ---

  Future<void> _initLocationAndPrayers() async {
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
    setState(() => _isLoading = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final coordinates = Coordinates(position.latitude, position.longitude);

      // FIX: Use the static method directly
      final params = CalculationMethodParameters.karachi();
      params.madhab = _madhab;

      final date = DateTime.now();
      final prayerTimes = PrayerTimes(
        coordinates: coordinates,
        date: date,
        calculationParameters: params,
      );

      setState(() {
        _prayerTimes = prayerTimes;
        _isLoading = false;
        _updateNextPrayer();
      });
    } catch (e) {
      debugPrint("Error loading prayers: $e");
      setState(() => _isLoading = false);
    }
  }

  void _updateNextPrayer() {
    if (_prayerTimes == null) return;

    final next = _prayerTimes!.nextPrayer();
    DateTime? time;

    // Mapping enum to actual time
    switch (next) {
      case Prayer.fajr:
        time = _prayerTimes!.fajr;
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
      default:
        // If it's after Isha, show tomorrow's Fajr
        time = _prayerTimes!.fajr.add(const Duration(days: 1));
    }

    _nextPrayerName = next.name.toUpperCase();
    _nextPrayerTime = time;
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final diff = _nextPrayerTime.difference(now);

      if (diff.inSeconds <= 0) {
        _loadPrayerTimes(); // Refresh for next cycle
        timer.cancel();
        if (beepOnEnd) SystemSound.play(SystemSoundType.alert);
        return;
      }

      setState(() {
        _remaining = diff;
      });
    });
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

  // --- UI Helpers ---

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "-$hours:$minutes:$seconds";
  }

  String _formatTime(DateTime? time) {
    if (time == null) return "--:--";
    return DateFormat.jm().format(time.toLocal());
  }

  // --- UI Components ---

  Widget _salamHeader() {
    final hour = DateTime.now().hour;

    String subtitle;
    if (hour < 12) {
      subtitle = "Good Morning";
    } else if (hour < 18) {
      subtitle = "Good Afternoon";
    } else {
      subtitle = "Good Evening";
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF009624)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Assalamu Alaikum",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Mohd Adnan • $subtitle",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // SalamCard(),
                  _salamHeader(),
                  const SizedBox(height: 20),
                  _nextPrayerCard(),
                  // NextPrayerCard(
                  //   prayerName: _nextPrayerName,
                  //   prayerTime: _nextPrayerTime,
                  // ),
                  const SizedBox(height: 20),
                  _prayerLockCard(),
                  const SizedBox(height: 20),
                  _prayerGrid(),
                  const SizedBox(height: 20),
                  _quickActions(),
                  const SizedBox(height: 20),
                  _dailyAyah(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _nextPrayerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF009624)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "NEXT PRAYER",
            style: TextStyle(color: Colors.white70, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            _nextPrayerName.isEmpty ? "FETCHING..." : _nextPrayerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatDuration(_remaining),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _prayerLockCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_clock, color: Color(0xFF00E676)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Prayer Focus Mode",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: prayerLockEnabled,
                activeColor: const Color(0xFF00E676),
                onChanged: (v) => setState(() => prayerLockEnabled = v),
              ),
            ],
          ),
          if (prayerLockEnabled) ...[
            const Divider(color: Colors.white10, height: 24),
            const Text(
              "Lock phone for (mins) after Adhan:",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                5,
                10,
                15,
                20,
                30,
              ].map((e) => _durationChip(e)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _durationChip(int minutes) {
    final isSelected = lockMinutes == minutes;
    return ChoiceChip(
      label: Text("$minutes min"),
      selected: isSelected,
      onSelected: (_) => setState(() => lockMinutes = minutes),
      selectedColor: const Color(0xFF00C853),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
      backgroundColor: Colors.white.withOpacity(0.05),
    );
  }

  Widget _prayerGrid() {
    if (_prayerTimes == null) return const SizedBox();

    final prayerData = [
      ["Fajr", _formatTime(_prayerTimes!.fajr)],
      ["Dhuhr", _formatTime(_prayerTimes!.dhuhr)],
      ["Asr", _formatTime(_prayerTimes!.asr)],
      ["Maghrib", _formatTime(_prayerTimes!.maghrib)],
      ["Isha", _formatTime(_prayerTimes!.isha)],
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
      itemBuilder: (_, i) {
        final bool isNext = _nextPrayerName == prayerData[i][0].toUpperCase();
        return Container(
          decoration: BoxDecoration(
            color: isNext
                ? const Color(0xFF00C853).withOpacity(0.1)
                : Colors.white.withOpacity(.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isNext ? const Color(0xFF00C853) : Colors.white10,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                prayerData[i][0],
                style: TextStyle(
                  color: isNext ? const Color(0xFF00E676) : Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                prayerData[i][1],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quickActions() {
    return Row(
      children: const [
        _QuickActionItem(icon: Icons.notifications_active, title: "Adhan"),
        SizedBox(width: 12),
        _QuickActionItem(icon: Icons.menu_book, title: "Quran"),
        SizedBox(width: 12),
        _QuickActionItem(icon: Icons.mosque, title: "Mosques"),
      ],
    );
  }

  Widget _dailyAyah() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "DAILY AYAH",
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF00E676)),
                onPressed: _loadDailyAyah,
                tooltip: "Refresh Ayah",
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_ayahLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(
                color: Color(0xFF00E676),
                strokeWidth: 2,
              ),
            )
          else ...[
            Text(
              _ayahText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _ayahRef,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  const _QuickActionItem({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00E676), size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// // ////////////////////////////////////////////////////////////
// // /// 🌙 SALAM CARD
// // ////////////////////////////////////////////////////////////

// class SalamCard extends StatelessWidget {
//   const SalamCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xff1F8B4C), Color(0xff2ECC71)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(22),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.green.withOpacity(.25),
//             blurRadius: 15,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Row(
//         children: const [
//           CircleAvatar(
//             radius: 26,
//             backgroundColor: Colors.white,
//             child: Icon(Icons.person, color: Color(0xff1F8B4C)),
//           ),
//           SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Assalamu Alaikum",
//                   style: TextStyle(color: Colors.white70, fontSize: 14),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   "Adnan Sheikh",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ////////////////////////////////////////////////////////////
// // /// ⏳ NEXT PRAYER CARD WITH LIVE COUNTDOWN
// // ////////////////////////////////////////////////////////////

// class NextPrayerCard extends StatefulWidget {
//   const NextPrayerCard({
//     super.key,
//     required this.prayerName,
//     required this.prayerTime,
//   });
//   final String prayerName;
//   final DateTime prayerTime;

//   @override
//   State<NextPrayerCard> createState() => _NextPrayerCardState();
// }

// class _NextPrayerCardState extends State<NextPrayerCard> {
//   late Timer _timer;
//   Duration remaining = const Duration(hours: 1, minutes: 12, seconds: 9);

//   bool beepEnabled = true;
//   bool beepPlayed = false;

//   @override
//   void initState() {
//     super.initState();
//     startTimer();
//   }

//   void startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (remaining.inSeconds > 0) {
//         setState(() {
//           remaining -= const Duration(seconds: 1);
//         });
//       } else {
//         if (beepEnabled && !beepPlayed) {
//           beepPlayed = true;
//           debugPrint("🔔 Prayer Time Reached"); // you can add sound here
//         }
//         _timer.cancel();
//       }
//     });
//   }

//   String formatDuration(Duration d) {
//     String two(int n) => n.toString().padLeft(2, '0');
//     return "${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
//   }

//   @override
//   void dispose() {
//     _timer.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xff0F2027), Color(0xff203A43), Color(0xff2C5364)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(22),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(.25),
//             blurRadius: 18,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               const Icon(Icons.access_time, color: Colors.white),
//               const SizedBox(width: 8),
//               const Text(
//                 "Next Prayer",
//                 style: TextStyle(color: Colors.white70, fontSize: 15),
//               ),
//               const Spacer(),
//               Switch(
//                 value: beepEnabled,
//                 onChanged: (v) {
//                   setState(() => beepEnabled = v);
//                 },
//                 activeColor: Colors.white,
//               ),
//             ],
//           ),

//           const SizedBox(height: 12),

//           Text(
//             widget.prayerName,
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 26,
//               fontWeight: FontWeight.bold,
//               letterSpacing: 1,
//             ),
//           ),

//           const SizedBox(height: 6),

//           Text(
//             widget.prayerTime.toLocal().toString().substring(11, 16),
//             style: TextStyle(color: Colors.white70, fontSize: 16),
//           ),

//           const SizedBox(height: 16),

//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(.15),
//               borderRadius: BorderRadius.circular(30),
//             ),
//             child: Text(
//               "${formatDuration(remaining)} remaining",
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 1,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
