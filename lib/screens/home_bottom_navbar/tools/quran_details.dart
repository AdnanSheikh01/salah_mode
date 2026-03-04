import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:salah_mode/screens/home_bottom_navbar/tools/quran_memorize.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/quran_read.dart';

class QuranDetailsScreen extends StatefulWidget {
  const QuranDetailsScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.totalAyahs,
    required this.revelationType,
  });
  final int surahNumber;
  final String surahName;
  final int totalAyahs;
  final String revelationType;

  @override
  State<QuranDetailsScreen> createState() => _QuranDetailsScreenState();
}

class _QuranDetailsScreenState extends State<QuranDetailsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _ayahs = [];
  int _totalAyahs = 0;
  int _totalWords = 0;
  String _revelationType = "";
  int juzNumber = 0;
  int rukuNumber = 0;

  Future<void> _fetchAyahs() async {
    try {
      // Fetch Arabic
      final arResponse = await http.get(
        Uri.parse(
          "https://api.alquran.cloud/v1/surah/${widget.surahNumber}/ar.quran-uthmani",
        ),
      );

      // Fetch English
      final enResponse = await http.get(
        Uri.parse(
          "https://api.alquran.cloud/v1/surah/${widget.surahNumber}/en.asad",
        ),
      );

      if (arResponse.statusCode == 200 && enResponse.statusCode == 200) {
        final arData = json.decode(arResponse.body);
        final enData = json.decode(enResponse.body);

        final List arAyahs = List.from(arData["data"]["ayahs"]);
        _revelationType = arData["data"]["revelationType"]?.toString() ?? "";
        final List enAyahs = List.from(enData["data"]["ayahs"]);

        _ayahs = List.generate(arAyahs.length, (index) {
          return {
            "arabic": arAyahs[index]["text"].toString(),
            "english": enAyahs[index]["text"].toString(),
            "juz": arAyahs[index]["juz"],
            "ayahNumber": arAyahs[index]["numberInSurah"],
            "ruku": arAyahs[index]["ruku"],
          };
        });
        if (_ayahs.isNotEmpty) {
          juzNumber = _ayahs.first['juz'] ?? 0;
          rukuNumber = _ayahs.first['ruku'] ?? 0;
        }
        _totalWords = _ayahs.fold<int>(0, (sum, ayah) {
          final text = ayah["arabic"]?.toString() ?? "";
          final words = text.trim().isEmpty
              ? 0
              : text.trim().split(RegExp(r'\s+')).length;
          return sum + words;
        });
      }
    } catch (e) {
      debugPrint("Ayah fetch error: $e");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _totalAyahs = widget.totalAyahs;
    _revelationType = widget.revelationType;
    _fetchAyahs();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.surahName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "Surah ${widget.surahNumber}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(.85),
                ),
              ),
            ],
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(.9),
                  Theme.of(context).colorScheme.primary.withOpacity(.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 4,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.menu_book_rounded), text: 'Read Quran'),
              Tab(
                icon: Icon(Icons.psychology_alt_rounded),
                text: 'Memorisation',
              ),
            ],
          ),
        ),

        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  QuranReadPage(
                    surahName: widget.surahName,
                    surahNumber: widget.surahNumber,
                    totalAyahs: widget.totalAyahs,
                    revelationType: widget.revelationType,
                    totalWords: _totalWords,
                    ayahs: _ayahs,
                  ),
                  QuranMemoriseScreen(
                    ayahs: _ayahs,
                    surahName: widget.surahName,
                  ),
                ],
              ),
      ),
    );
  }
}
