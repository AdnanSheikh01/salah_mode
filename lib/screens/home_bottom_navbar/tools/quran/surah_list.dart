import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:salah_mode/screens/home_bottom_navbar/tools/quran/quran_details.dart';

import 'package:salah_mode/screens/utils/theme_data.dart';

// ─────────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────────

class SurahModel {
  final int number;
  final String name;
  final String englishName;
  final String arabicName;
  final int verses;
  final String type;

  const SurahModel({
    required this.number,
    required this.name,
    required this.englishName,
    required this.arabicName,
    required this.verses,
    required this.type,
  });

  factory SurahModel.fromJson(Map<String, dynamic> e) => SurahModel(
    number: e['number'] as int,
    name: e['englishName'] as String? ?? '',
    englishName: e['englishNameTranslation'] as String? ?? '',
    arabicName: e['name'] as String? ?? '',
    verses: e['numberOfAyahs'] as int? ?? 0,
    type: e['revelationType'] as String? ?? '',
  );
}

// ─────────────────────────────────────────────────────────────────
//  FETCH STATE
// ─────────────────────────────────────────────────────────────────

enum _FetchState { loading, success, error, empty }

// ─────────────────────────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────────────────────────

class SurahListPage extends StatefulWidget {
  const SurahListPage({super.key});

  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _FetchState _fetchState = _FetchState.loading;
  List<SurahModel> _surahs = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchSurahs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Network fetch with full error handling ─────────────────────
  Future<void> _fetchSurahs() async {
    if (!mounted) return;
    setState(() {
      _fetchState = _FetchState.loading;
      _errorMessage = '';
    });

    try {
      final response = await http
          .get(Uri.parse('https://api.alquran.cloud/v1/surah'))
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List raw = decoded['data'] as List? ?? [];

        if (raw.isEmpty) {
          setState(() => _fetchState = _FetchState.empty);
          return;
        }

        final parsed = raw
            .map((e) => SurahModel.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          _surahs = parsed;
          _fetchState = _FetchState.success;
        });
      } else {
        _setError(
          'Server returned status ${response.statusCode}. '
          'Please try again shortly.',
        );
      }
    } on TimeoutException {
      _setError('Request timed out. Check your connection and retry.');
    } on SocketException {
      _setError('No internet connection. Please connect and retry.');
    } on FormatException {
      _setError('Received unexpected data from the server.');
    } catch (e) {
      _setError('Something went wrong. Please try again.');
      debugPrint('SurahListPage fetch error: $e');
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _fetchState = _FetchState.error;
      _errorMessage = msg;
    });
  }

  // ── Filtered list ──────────────────────────────────────────────
  List<SurahModel> get _filtered {
    if (_query.isEmpty) return _surahs;
    final q = _query.toLowerCase().trim();
    return _surahs.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.englishName.toLowerCase().contains(q) ||
          s.arabicName.contains(q) ||
          s.number.toString() == q;
    }).toList();
  }

  // ── Theme helpers ──────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bg => _isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;
  Color get _card => _isDark ? AppTheme.darkCard : AppTheme.lightCard;
  Color get _accent => _isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
  // FIX: gold uses darkAccentGold in dark mode, not darkAccent
  Color get _gold => _isDark ? AppTheme.darkAccent : AppTheme.lightAccentGold;
  Color get _tp =>
      _isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
  Color get _ts =>
      _isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
  Color get _border => _isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
  Color get _btnTxt =>
      _isDark ? AppTheme.darkTextOnAccent : AppTheme.lightTextOnAccent;

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 4),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: _accent, size: 20),
        onPressed: () => Get.back(),
      ),
      title: Text(
        "Holy Qur'an",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: _tp,
        ),
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _tp),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: _ts),
                hintText: 'Search by name or number…',
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _ts,
                ),
                border: InputBorder.none,
                isDense: true,
                // FIX: symmetric vertical padding avoids vertical overflow
                // in the search bar on smaller screen heights
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // FIX: AnimatedSwitcher prevents jarring layout shift when the
          // clear icon appears / disappears
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _query.isNotEmpty
                ? GestureDetector(
                    key: const ValueKey('clear'),
                    onTap: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.close_rounded, color: _ts, size: 18),
                    ),
                  )
                : const SizedBox(key: ValueKey('empty'), width: 12),
          ),
        ],
      ),
    );
  }

  // ── Body dispatcher ────────────────────────────────────────────
  Widget _buildBody() {
    switch (_fetchState) {
      case _FetchState.loading:
        return _LoadingView(accentColor: _accent);

      case _FetchState.error:
        return _ErrorView(
          message: _errorMessage,
          accentColor: _accent,
          cardColor: _card,
          borderColor: _border,
          textPrimary: _tp,
          textSecondary: _ts,
          btnTextColor: _btnTxt,
          onRetry: _fetchSurahs,
        );

      case _FetchState.empty:
        return _EmptyView(
          textPrimary: _tp,
          textSecondary: _ts,
          accentColor: _accent,
        );

      case _FetchState.success:
        final list = _filtered;
        if (list.isEmpty) {
          return _NoResultsView(
            query: _query,
            textPrimary: _tp,
            textSecondary: _ts,
          );
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: list.length,
          itemBuilder: (_, i) => _SurahCard(
            surah: list[i],
            accentColor: _accent,
            goldColor: _gold,
            cardColor: _card,
            borderColor: _border,
            textPrimary: _tp,
            textSecondary: _ts,
          ),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────
//  SURAH CARD
// ─────────────────────────────────────────────────────────────────

class _SurahCard extends StatelessWidget {
  final SurahModel surah;
  final Color accentColor, goldColor, cardColor, borderColor;
  final Color textPrimary, textSecondary;

  const _SurahCard({
    required this.surah,
    required this.accentColor,
    required this.goldColor,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  Color get _typeColor =>
      surah.type.toLowerCase() == 'meccan' ? goldColor : accentColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => QuranDetailsScreen(
            surahName: surah.name,
            surahNumber: surah.number,
            totalAyahs: surah.verses,
            revelationType: surah.type,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        // FIX: IntrinsicHeight ensures the number badge stretches to match
        // the card height when the surah name wraps to two lines, preventing
        // a visual height mismatch between badge and text column.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Number badge ──────────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  // FIX: withOpacity → withValues(alpha:)
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    // FIX: withOpacity → withValues(alpha:)
                    color: accentColor.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  surah.number.toString(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // ── English name + meta ───────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // FIX: maxLines + overflow already present — kept
                    Text(
                      surah.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // FIX: Wrap replaces inner Row so that the type-pill
                    // never overflows on narrow screens or large font scales
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${surah.verses} verses',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                        // dot separator
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            // FIX: withOpacity → withValues(alpha:)
                            color: textSecondary.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Meccan / Medinan pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            // FIX: withOpacity → withValues(alpha:)
                            color: _typeColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              // FIX: withOpacity → withValues(alpha:)
                              color: _typeColor.withValues(alpha: 0.28),
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            surah.type,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _typeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── Arabic name ───────────────────────────────────────
              // FIX: Flexible prevents the Arabic text from pushing the
              // chevron off-screen when the name is unusually long
              Flexible(
                child: Text(
                  surah.arabicName,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: goldColor,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ── Chevron ───────────────────────────────────────────
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  STATE VIEWS
// ─────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  final Color accentColor;
  const _LoadingView({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Surahs…',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                // FIX: withOpacity → withValues(alpha:)
                color: AppTheme.colorError.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  // FIX: withOpacity → withValues(alpha:)
                  color: AppTheme.colorError.withValues(alpha: 0.28),
                  width: 0.8,
                ),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppTheme.colorError,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load Surahs',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            // FIX: Flexible prevents this Text from overflowing when the
            // error message is long on a small screen
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: textSecondary,
                  height: 1.6,
                ),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 16, color: btnTextColor),
                    const SizedBox(width: 8),
                    Text(
                      'Try Again',
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
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final Color textPrimary, textSecondary, accentColor;
  const _EmptyView({
    required this.textPrimary,
    required this.textSecondary,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FIX: withOpacity → withValues(alpha:)
          Icon(
            Icons.menu_book_rounded,
            size: 48,
            color: accentColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 14),
          Text(
            'No Surahs Available',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The server returned an empty list.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResultsView extends StatelessWidget {
  final String query;
  final Color textPrimary, textSecondary;
  const _NoResultsView({
    required this.query,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        // FIX: horizontal padding prevents the query string from touching
        // the screen edges when it is very long
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // FIX: withOpacity → withValues(alpha:)
            Icon(
              Icons.search_off_rounded,
              size: 44,
              color: textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            // FIX: maxLines + overflow on the query string
            Text(
              'No results for "$query"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different name or number.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
