import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:salah_mode/screens/utils/theme_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyHadithScreen extends StatefulWidget {
  const DailyHadithScreen({super.key});

  @override
  State<DailyHadithScreen> createState() => _DailyHadithScreenState();
}

class _DailyHadithScreenState extends State<DailyHadithScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────
  final List<Map<String, String>> _hadiths = [];
  int _index = 0;
  bool _loading = true;
  bool _isFavorite = false;
  bool _hasError = false;
  String _errorMsg = '';
  bool _refreshing = false; // manual reload spinner

  // ── Fade animation ─────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── Prefs key ──────────────────────────────────────────────────
  static const _cacheKey = 'hadith_cache';
  static const _favIndexKey = 'hadith_fav_indices';

  // ── Favourites set ─────────────────────────────────────────────
  final Set<int> _favIndices = {};

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadFavourites();
      await _loadFromCache();
      await _fetchFromApi();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  DATA
  // ═══════════════════════════════════════════════════════════════

  void _pickDailyIndex() {
    if (_hadiths.isEmpty) return;
    final t = DateTime.now();
    _index = (t.year * 31 + t.month * 7 + t.day) % _hadiths.length;
  }

  void _nextRandom() {
    if (_hadiths.isEmpty) return;
    int next;
    do {
      next = Random().nextInt(_hadiths.length);
    } while (next == _index && _hadiths.length > 1);
    _index = next;
    _isFavorite = _favIndices.contains(_index);
    _fadeCtrl.forward(from: 0);
    if (mounted) setState(() {});
  }

  Future<void> _loadFavourites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_favIndexKey) ?? [];
      _favIndices.addAll(
        raw.map((e) => int.tryParse(e) ?? -1).where((i) => i >= 0),
      );
    } catch (e) {
      debugPrint("Fav load error: $e");
    }
  }

  Future<void> _saveFavourites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _favIndexKey,
        _favIndices.map((i) => '$i').toList(),
      );
    } catch (_) {}
  }

  Future<void> _toggleFavourite() async {
    if (_hadiths.isEmpty) return;
    if (_favIndices.contains(_index)) {
      _favIndices.remove(_index);
    } else {
      _favIndices.add(_index);
    }
    _isFavorite = _favIndices.contains(_index);
    await _saveFavourites();
    if (mounted) setState(() {});
  }

  // ── Cache ──────────────────────────────────────────────────────
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached == null) return;

      final list = json.decode(cached) as List<dynamic>;
      _hadiths.clear();
      for (final h in list) {
        final entry = _parseEntry(h);
        if (entry != null) _hadiths.add(entry);
      }
      _pickDailyIndex();
      _isFavorite = _favIndices.contains(_index);
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Cache load error: $e");
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(_hadiths));
    } catch (e) {
      debugPrint("Cache save error: $e");
    }
  }

  Map<String, String>? _parseEntry(dynamic h) {
    try {
      if (h == null) return null;

      // ── hadithapi.com field names ──────────────────────────────
      // Primary:   hadithEnglish / hadithArabic
      // Fallbacks: text / arab / arabic / translation
      final arabic =
          (h['hadithArabic'] ?? // hadithapi.com
                  h['arabic'] ?? // ahadith.co.uk + generic
                  h['arab'] ??
                  '')
              .toString()
              .trim();

      final text =
          (h['hadithEnglish'] ?? // hadithapi.com
                  h['english'] ?? // ahadith.co.uk
                  h['text'] ?? // generic
                  h['translation'] ??
                  h['body'] ??
                  '')
              .toString()
              .trim();

      if (arabic.isEmpty && text.isEmpty) return null;

      // Book name: either flat string or nested { bookName: "..." }
      final bookRaw = h['book'];
      final bookName = bookRaw is Map
          ? (bookRaw['bookName'] ?? bookRaw['name'] ?? 'Sahih Muslim')
                .toString()
          : (bookRaw ?? h['reference'] ?? 'Sahih Muslim').toString();

      return {
        'arabic': arabic,
        'translation': text.isNotEmpty ? text : arabic,
        'reference': bookName.trim(),
        'chapter': (h['chapterName'] ?? h['chapter_name'] ?? h['chapter'] ?? '')
            .toString()
            .trim(),
        'number': (h['hadithNumber'] ?? h['number'] ?? '').toString().trim(),
      };
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILT-IN FALLBACK HADITHS
  //  These are always available — no network, no API key needed.
  //  Screen will NEVER show 404 or empty state.
  // ═══════════════════════════════════════════════════════════════

  static const List<Map<String, String>> _builtinHadiths = [
    {
      'arabic':
          'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
      'translation':
          'Actions are judged by intentions, and every person will get the reward according to what he has intended.',
      'reference': 'Sahih Bukhari 1',
      'chapter': 'The Beginning of Revelation',
      'number': '1',
    },
    {
      'arabic': 'الدِّينُ النَّصِيحَةُ',
      'translation':
          'Religion is sincerity (nasihah — sincere advice and well-wishing).',
      'reference': 'Sahih Muslim 95',
      'chapter': 'Faith',
      'number': '95',
    },
    {
      'arabic': 'أَحَبُّ الْأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ',
      'translation':
          'The most beloved deeds to Allah are those that are most consistent, even if they are small.',
      'reference': 'Sahih Bukhari 6464',
      'chapter': 'Good Manners',
      'number': '6464',
    },
    {
      'arabic': 'مَنْ صَمَتَ نَجَا',
      'translation': 'Whoever remains silent is saved.',
      'reference': 'Tirmidhi 2501',
      'chapter': 'Asceticism',
      'number': '2501',
    },
    {
      'arabic':
          'لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ',
      'translation':
          'None of you truly believes until he loves for his brother what he loves for himself.',
      'reference': 'Sahih Bukhari 13',
      'chapter': 'Faith',
      'number': '13',
    },
    {
      'arabic': 'الطَّهُورُ شَطْرُ الْإِيمَانِ',
      'translation': 'Cleanliness is half of faith.',
      'reference': 'Sahih Muslim 223',
      'chapter': 'Purification',
      'number': '223',
    },
    {
      'arabic': 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ',
      'translation':
          'The best among you are those who learn the Quran and teach it.',
      'reference': 'Sahih Bukhari 5027',
      'chapter': 'Virtues of the Quran',
      'number': '5027',
    },
    {
      'arabic':
          'الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ',
      'translation':
          'A Muslim is the one from whose tongue and hand the Muslims are safe.',
      'reference': 'Sahih Bukhari 10',
      'chapter': 'Faith',
      'number': '10',
    },
    {
      'arabic':
          'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ',
      'translation':
          'Whoever believes in Allah and the Last Day should speak good or keep silent.',
      'reference': 'Sahih Bukhari 6018',
      'chapter': 'Good Manners',
      'number': '6018',
    },
    {
      'arabic': 'إِنَّ اللَّهَ رَفِيقٌ يُحِبُّ الرِّفْقَ فِي الْأَمْرِ كُلِّهِ',
      'translation': 'Allah is gentle and loves gentleness in all matters.',
      'reference': 'Sahih Bukhari 6927',
      'chapter': 'Asking Permission',
      'number': '6927',
    },
    {
      'arabic': 'أَقْرَبُ مَا يَكُونُ الْعَبْدُ مِنْ رَبِّهِ وَهُوَ سَاجِدٌ',
      'translation':
          'The closest a servant is to his Lord is when he is in prostration.',
      'reference': 'Sahih Muslim 482',
      'chapter': 'Prayer',
      'number': '482',
    },
    {
      'arabic': 'تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ',
      'translation':
          'Your smile in the face of your brother is an act of charity.',
      'reference': 'Tirmidhi 1956',
      'chapter': 'Good Manners',
      'number': '1956',
    },
    {
      'arabic':
          'إِنَّ اللَّهَ لَا يَنْظُرُ إِلَى صُوَرِكُمْ وَأَمْوَالِكُمْ وَلَكِنْ يَنْظُرُ إِلَى قُلُوبِكُمْ وَأَعْمَالِكُمْ',
      'translation':
          'Allah does not look at your forms or your wealth, but He looks at your hearts and your deeds.',
      'reference': 'Sahih Muslim 2564',
      'chapter': 'Good Manners',
      'number': '2564',
    },
    {
      'arabic': 'مَنْ دَلَّ عَلَى خَيْرٍ فَلَهُ مِثْلُ أَجْرِ فَاعِلِهِ',
      'translation':
          'Whoever guides to good receives the same reward as the one who does it.',
      'reference': 'Sahih Muslim 1893',
      'chapter': 'Leadership',
      'number': '1893',
    },
    {
      'arabic': 'الْكَلِمَةُ الطَّيِّبَةُ صَدَقَةٌ',
      'translation': 'A kind word is charity.',
      'reference': 'Sahih Bukhari 2989',
      'chapter': 'Voluntary Charity',
      'number': '2989',
    },
    {
      'arabic':
          'اتَّقِ اللَّهَ حَيْثُمَا كُنْتَ وَأَتْبِعِ السَّيِّئَةَ الْحَسَنَةَ تَمْحُهَا',
      'translation':
          'Fear Allah wherever you are, and follow up a bad deed with a good one and it will wipe it out.',
      'reference': 'Tirmidhi 1987',
      'chapter': 'Good Manners',
      'number': '1987',
    },
    {
      'arabic':
          'مَنْ نَفَّسَ عَنْ مُؤْمِنٍ كُرْبَةً مِنْ كُرَبِ الدُّنْيَا نَفَّسَ اللَّهُ عَنْهُ كُرْبَةً مِنْ كُرَبِ يَوْمِ الْقِيَامَةِ',
      'translation':
          'Whoever relieves a believer of hardship in this world, Allah will relieve him of hardship on the Day of Judgment.',
      'reference': 'Sahih Muslim 2699',
      'chapter': 'Remembrance of Allah',
      'number': '2699',
    },
    {
      'arabic':
          'صَلَاةُ الرَّجُلِ فِي جَمَاعَةٍ تَزِيدُ عَلَى صَلَاتِهِ فِي بَيْتِهِ وَصَلَاتِهِ فِي سُوقِهِ بِضْعًا وَعِشْرِينَ دَرَجَةً',
      'translation':
          'Prayer in congregation is superior to prayer alone by twenty-seven degrees.',
      'reference': 'Sahih Bukhari 645',
      'chapter': 'The Call to Prayer',
      'number': '645',
    },
    {
      'arabic':
          'لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الْغَضَبِ',
      'translation':
          'The strong man is not the one who overcomes people. The strong man is the one who controls himself when angry.',
      'reference': 'Sahih Bukhari 6114',
      'chapter': 'Good Manners',
      'number': '6114',
    },
    {
      'arabic': 'مَا مَلَأَ آدَمِيٌّ وِعَاءً شَرًّا مِنْ بَطْنٍ',
      'translation':
          'No human ever filled a vessel worse than the stomach. A few morsels that keep his back straight are sufficient.',
      'reference': 'Tirmidhi 2380',
      'chapter': 'Asceticism',
      'number': '2380',
    },
  ];

  // ── API fetch ──────────────────────────────────────────────────
  // Strategy:
  //   1. Load built-in hadiths immediately (always works, no network)
  //   2. Try hadithapi.com if you have an API key (replace placeholder)
  //   3. On any API failure — silently keep showing built-in data
  Future<void> _fetchFromApi({bool isRefresh = false}) async {
    if (!mounted) return;
    if (isRefresh) setState(() => _refreshing = true);

    // ── Step 1: Always load built-ins first ────────────────────────
    // This guarantees the screen is never blank or shows 404.
    if (_hadiths.isEmpty) {
      _hadiths.addAll(_builtinHadiths);
      _pickDailyIndex();
      _isFavorite = _favIndices.contains(_index);
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = false;
        });
        _fadeCtrl.forward(from: 0);
      }
    }

    // ── Step 2: Try hadithapi.com (optional — needs your API key) ──
    // Get a free key at https://hadithapi.com/register
    // Replace 'YOUR_HADITHAPI_KEY' with your actual key.
    // If left as placeholder, the app uses built-in hadiths only.
    const apiKey = 'YOUR_HADITHAPI_KEY';
    if (apiKey == 'YOUR_HADITHAPI_KEY') {
      // No key configured — stay with built-in data
      if (mounted) setState(() => _refreshing = false);
      return;
    }

    try {
      final uri = Uri.https('hadithapi.com', '/api/hadiths', {
        'apiKey': apiKey,
        'book': 'sahih-muslim',
        'paginate': '300',
      });

      debugPrint("Fetching hadiths from: $uri");

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 14));

      debugPrint("Hadith API status: \${response.statusCode}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> raw = [];

        if (data is Map) {
          // hadithapi.com: { hadiths: { current_page: 1, data: [...] } }
          final hadiths = data['hadiths'];
          if (hadiths is Map) {
            raw = (hadiths['data'] as List<dynamic>?) ?? [];
          } else if (hadiths is List) {
            raw = hadiths;
          }
          // Generic fallbacks
          if (raw.isEmpty) {
            final d = data['data'];
            if (d is List) {
              raw = d;
            } else if (d is Map)
              raw = (d['data'] as List<dynamic>?) ?? [];
          }
        } else if (data is List) {
          raw = data;
        }

        if (raw.isNotEmpty) {
          final parsed = <Map<String, String>>[];
          for (final h in raw) {
            final entry = _parseEntry(h);
            if (entry != null) parsed.add(entry);
          }
          if (parsed.isNotEmpty) {
            // Merge API results with built-ins — no duplicates by number
            final existingNums = _hadiths.map((h) => h['number']).toSet();
            for (final p in parsed) {
              if (!existingNums.contains(p['number'])) {
                _hadiths.add(p);
              }
            }
            await _saveToCache();
            _pickDailyIndex();
            _isFavorite = _favIndices.contains(_index);
            debugPrint("Loaded \${parsed.length} hadiths from API.");
          }
        } else {
          debugPrint("API returned no hadiths — staying with built-in data.");
        }
      } else {
        // API returned error — built-in data already loaded, silently ignore
        debugPrint(
          "Hadith API error \${response.statusCode} — using built-in data.",
        );
      }

      if (mounted) {
        setState(() {
          _refreshing = false;
          _hasError = false;
        });
      }
      _fadeCtrl.forward(from: 0);
    } on http.ClientException {
      debugPrint("Hadith network error: \$e — using built-in data.");
      if (mounted) setState(() => _refreshing = false);
    } catch (e) {
      debugPrint("Hadith fetch error: \$e — using built-in data.");
      if (mounted) setState(() => _refreshing = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final cardAltColor = isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final goldColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccentGold;
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentColor, size: 20),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Daily Hadith",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            Text(
              "حديث اليوم",
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 12,
                color: goldColor,
                height: 1.3,
              ),
            ),
          ],
        ),
        actions: [
          // Favourite toggle
          GestureDetector(
            onTap: _hadiths.isEmpty ? null : _toggleFavourite,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _isFavorite ? AppTheme.colorError : textTertiary,
                size: 22,
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: _loading
            ? _ShimmerCard(
                accentColor: accentColor,
                cardColor: cardColor,
                borderColor: borderColor,
                textTertiary: textTertiary,
              )
            : _hasError && _hadiths.isEmpty
            ? _ErrorView(
                message: _errorMsg,
                accentColor: accentColor,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                btnTextColor: btnTextColor,
                onRetry: () {
                  setState(() {
                    _loading = true;
                    _hasError = false;
                  });
                  _fetchFromApi();
                },
              )
            : _MainBody(
                hadiths: _hadiths,
                index: _index,
                isFav: _isFavorite,
                favCount: _favIndices.length,
                fadeAnim: _fadeAnim,
                refreshing: _refreshing,
                accentColor: accentColor,
                goldColor: goldColor,
                cardColor: cardColor,
                cardAltColor: cardAltColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textTertiary: textTertiary,
                btnTextColor: btnTextColor,
                isDark: isDark,
                onShuffle: _nextRandom,
                onRefresh: () => _fetchFromApi(isRefresh: true),
                onCopy: () {
                  if (_hadiths.isEmpty) return;
                  final safe = _index.clamp(0, _hadiths.length - 1);
                  final h = _hadiths[safe];
                  try {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            "${h['translation'] ?? ''}\n— ${h['reference'] ?? ''}",
                      ),
                    );
                    Get.snackbar(
                      "Copied",
                      "Hadith copied to clipboard",
                      backgroundColor: accentColor,
                      colorText: btnTextColor,
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                      duration: const Duration(seconds: 2),
                    );
                  } catch (_) {}
                },
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MAIN BODY
// ═══════════════════════════════════════════════════════════════════

class _MainBody extends StatelessWidget {
  final List<Map<String, String>> hadiths;
  final int index, favCount;
  final bool isFav, refreshing;
  final Animation<double> fadeAnim;
  final Color accentColor, goldColor, cardColor, cardAltColor;
  final Color borderColor,
      textPrimary,
      textSecondary,
      textTertiary,
      btnTextColor;
  final bool isDark;
  final VoidCallback onShuffle, onRefresh, onCopy;

  const _MainBody({
    required this.hadiths,
    required this.index,
    required this.isFav,
    required this.favCount,
    required this.fadeAnim,
    required this.refreshing,
    required this.accentColor,
    required this.goldColor,
    required this.cardColor,
    required this.cardAltColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.btnTextColor,
    required this.isDark,
    required this.onShuffle,
    required this.onRefresh,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    if (hadiths.isEmpty) {
      return Center(
        child: Text(
          "No hadiths available.",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: textSecondary,
          ),
        ),
      );
    }

    final safe = index.clamp(0, hadiths.length - 1);
    final hadith = hadiths[safe];
    final arabic = (hadith['arabic'] ?? '').trim();
    final text = (hadith['translation'] ?? 'No translation available').trim();
    final ref = (hadith['reference'] ?? 'Hadith').trim();
    final chapter = (hadith['chapter'] ?? '').trim();
    final number = (hadith['number'] ?? '').trim();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Today's label ───────────────────────────────────────
          _SectionLabel(
            label: "Today's Hadith",
            sub: "${safe + 1} of ${hadiths.length}",
            goldColor: goldColor,
            textPrimary: textPrimary,
            textTertiary: textTertiary,
          ),

          const SizedBox(height: 12),

          // ── Hadith card ─────────────────────────────────────────
          FadeTransition(
            opacity: fadeAnim,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header strip
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 18,
                          color: btnTextColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ref.isNotEmpty ? ref : "Hadith",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: btnTextColor,
                            ),
                          ),
                        ),
                        if (number.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: btnTextColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "#$number",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: btnTextColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Chapter label
                        if (chapter.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: goldColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: goldColor.withOpacity(0.20),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              chapter,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: goldColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),

                        // Arabic text
                        if (arabic.isNotEmpty) ...[
                          Text(
                            arabic,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 22,
                              color: goldColor,
                              height: 2.0,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Gold ornament divider
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 0.7,
                                color: goldColor.withOpacity(0.35),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "✦",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: goldColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 40,
                                height: 0.7,
                                color: goldColor.withOpacity(0.35),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Translation
                        Text(
                          text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            color: textPrimary,
                            height: 1.70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action row at bottom of card
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Row(
                      children: [
                        // Fav status text
                        if (isFav)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                size: 13,
                                color: AppTheme.colorError,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Saved",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: AppTheme.colorError,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        const Spacer(),
                        // Copy button
                        GestureDetector(
                          onTap: onCopy,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: accentColor.withOpacity(0.22),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.copy_rounded,
                                  size: 13,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "Copy",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Stats row ───────────────────────────────────────────
          Row(
            children: [
              _StatPill(
                icon: Icons.library_books_rounded,
                label: "${hadiths.length} hadiths",
                accentColor: accentColor,
                cardAltColor: cardAltColor,
                borderColor: borderColor,
                textSecondary: textSecondary,
              ),
              const SizedBox(width: 10),
              _StatPill(
                icon: Icons.favorite_rounded,
                label: "$favCount saved",
                accentColor: AppTheme.colorError,
                cardAltColor: cardAltColor,
                borderColor: borderColor,
                textSecondary: textSecondary,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Action buttons ──────────────────────────────────────
          Row(
            children: [
              // Shuffle
              Expanded(
                child: GestureDetector(
                  onTap: onShuffle,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shuffle_rounded,
                          size: 18,
                          color: btnTextColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Random Hadith",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: btnTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Refresh
              GestureDetector(
                onTap: refreshing ? null : onRefresh,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accentColor.withOpacity(0.25),
                      width: 0.8,
                    ),
                  ),
                  child: refreshing
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentColor,
                          ),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          color: accentColor,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Disclaimer ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: goldColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: goldColor.withOpacity(0.18),
                width: 0.8,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "✦ ",
                  style: TextStyle(fontSize: 12, color: goldColor, height: 1.5),
                ),
                Expanded(
                  child: Text(
                    "Hadiths are sourced from Sahih Muslim via API. "
                    "Always verify with a qualified scholar before acting on religious matters.",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHIMMER LOADING CARD
// ═══════════════════════════════════════════════════════════════════

class _ShimmerCard extends StatefulWidget {
  final Color accentColor, cardColor, borderColor, textTertiary;
  const _ShimmerCard({
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.textTertiary,
  });
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _a = Tween<double>(begin: -2, end: 2).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: AnimatedBuilder(
        animation: _a,
        builder: (_, child) => Container(
          width: double.infinity,
          height: 360,
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: widget.borderColor, width: 0.8),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment(_a.value - 1, 0),
              end: Alignment(_a.value + 1, 0),
              colors: [
                widget.textTertiary.withOpacity(0.08),
                widget.textTertiary.withOpacity(0.20),
                widget.textTertiary.withOpacity(0.08),
              ],
            ).createShader(bounds),
            child: child,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header strip
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 14,
                width: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 260,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ERROR VIEW
// ═══════════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  final String message;
  final Color accentColor, cardColor, borderColor;
  final Color textPrimary, textSecondary, btnTextColor;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.btnTextColor,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.colorError.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.colorError.withOpacity(0.25),
                  width: 0.8,
                ),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppTheme.colorError,
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Couldn't Load Hadith",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "Try Again",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: btnTextColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label, sub;
  final Color goldColor, textPrimary, textTertiary;
  const _SectionLabel({
    required this.label,
    required this.sub,
    required this.goldColor,
    required this.textPrimary,
    required this.textTertiary,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 3,
        height: 16,
        decoration: BoxDecoration(
          color: goldColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      const Spacer(),
      Text(
        sub,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: textTertiary,
        ),
      ),
    ],
  );
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor, cardAltColor, borderColor, textSecondary;
  const _StatPill({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.cardAltColor,
    required this.borderColor,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: cardAltColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: borderColor, width: 0.8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: accentColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
      ],
    ),
  );
}
