import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DailyHadithScreen extends StatefulWidget {
  const DailyHadithScreen({super.key});

  @override
  State<DailyHadithScreen> createState() => _DailyHadithScreenState();
}

class _DailyHadithScreenState extends State<DailyHadithScreen>
    with SingleTickerProviderStateMixin {
  final RxInt currentIndex = 0.obs;
  final RxBool isFavorite = false.obs;
  final RxBool isLoading = true.obs;

  final List<Map<String, String>> hadithList = [];

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // ================= INIT =================

  @override
  void initState() {
    super.initState();
    _initAnimation();

    // 🔥 Delay plugin calls until Flutter engine is fully ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFromCache();
      _fetchHadithFromApi();
    });
  }

  void _initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  // ================= DAILY HADITH =================

  void _loadDailyHadith() {
    if (hadithList.isEmpty) return;

    final today = DateTime.now();
    final seed = today.year + today.month + today.day;
    currentIndex.value = seed % hadithList.length;
  }

  // ================= SHUFFLE =================

  void _nextRandomHadith() {
    if (hadithList.isEmpty) return; // ✅ prevents RangeError

    final random = Random();
    currentIndex.value = random.nextInt(hadithList.length);
    isFavorite.value = false;
    _controller.forward(from: 0);
  }

  // ================= CACHE LOAD =================

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString("hadith_cache");

      if (cached != null) {
        final List<dynamic> decoded = json.decode(cached);

        hadithList.clear();

        for (var h in decoded) {
          hadithList.add({
            "arabic": h["arabic"] ?? "",
            "translation": h["translation"] ?? "",
            "reference": h["reference"] ?? "",
          });
        }

        _loadDailyHadith();
        isLoading.value = false;
        if (!mounted) return;
        setState(() {});
      }
    } catch (e) {
      debugPrint("Cache load error: $e");
    }
  }

  // ================= CACHE SAVE =================

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("hadith_cache", json.encode(hadithList));
    } catch (e) {
      debugPrint("Cache save error: $e");
    }
  }

  // ================= API FETCH =================

  Future<void> _fetchHadithFromApi() async {
    try {
      isLoading.value = true;

      final response = await http
          .get(
            Uri.parse(
              "https://hadithapi.com/api/hadiths?apiKey=2y10vttIa6bmGq0KYF6UlZgRgDCUb276cKCM67jDMFy6ctuTgGt9D3ru&book=sahih-muslim&paginate=300",
            ),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 🔍 handle multiple possible JSON structures safely
        List<dynamic> hadiths = [];

        if (data is Map && data["hadiths"] != null) {
          hadiths = data["hadiths"];
        } else if (data is Map &&
            data["data"] != null &&
            data["data"]["hadiths"] != null) {
          hadiths = data["data"]["hadiths"];
        } else {
          debugPrint("Unexpected Hadith JSON structure");
        }

        hadithList.clear();

        for (var h in hadiths) {
          if (h == null) continue;

          final arabicText = (h["arab"] ?? h["arabic"] ?? "").toString().trim();

          final translationText = (h["text"] ?? h["translation"] ?? "")
              .toString()
              .trim();

          hadithList.add({
            // ✅ if Arabic not available, keep empty (UI will handle)
            "arabic": arabicText,
            // ✅ always ensure some readable text exists
            "translation": translationText.isNotEmpty
                ? translationText
                : arabicText,
            "reference": "Sahih Muslim",
          });
        }

        await _saveToCache();

        _loadDailyHadith();
        isLoading.value = false;
        if (!mounted) return;
        setState(() {});
      } else {
        // stop loading if API fails
        isLoading.value = false;
        if (!mounted) return;
        setState(() {});
      }
    } catch (e) {
      debugPrint("Hadith API error: $e");
      isLoading.value = false; // 🔥 prevent infinite shimmer
      if (!mounted) return;
      setState(() {});
    }
  }

  // ================= SHIMMER =================

  Widget _buildShimmer(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 24, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Container(height: 24, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Container(height: 2, width: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Container(height: 16, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Container(height: 16, color: Colors.grey.shade300),
        ],
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Hadith"),
        centerTitle: true,
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                isFavorite.value ? Icons.favorite : Icons.favorite_border,
                color: isFavorite.value ? Colors.red : null,
              ),
              onPressed: () => isFavorite.toggle(),
            ),
          ),
        ],
      ),

      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          onPressed: isLoading.value ? null : _nextRandomHadith,
          icon: const Icon(Icons.shuffle),
          label: const Text("New Hadith"),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              // 🔄 Show shimmer only while loading
              if (isLoading.value) {
                return _buildShimmer(theme);
              }

              // 📭 If loading finished but no data
              if (hadithList.isEmpty) {
                return Center(
                  child: Text(
                    "No hadith available",
                    style: TextStyle(color: theme.hintColor, fontSize: 16),
                  ),
                );
              }

              final safeIndex = hadithList.isEmpty
                  ? 0
                  : currentIndex.value.clamp(0, hadithList.length - 1);
              final hadith = hadithList[safeIndex];

              return FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    color: theme.colorScheme.surface.withOpacity(.95),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.15),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 42,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      if ((hadith["arabic"] ?? "").trim().isNotEmpty)
                        Text(
                          hadith["arabic"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.8,
                            letterSpacing: .5,
                          ),
                        ),
                      const SizedBox(height: 24),
                      Container(
                        height: 2,
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: theme.colorScheme.primary.withOpacity(.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        (hadith["translation"] ?? "No translation available"),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          color: theme.colorScheme.onSurface.withOpacity(.8),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacity(.15),
                              theme.colorScheme.primary.withOpacity(.05),
                            ],
                          ),
                        ),
                        child: Text(
                          (hadith["reference"] ?? "Hadith"),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
