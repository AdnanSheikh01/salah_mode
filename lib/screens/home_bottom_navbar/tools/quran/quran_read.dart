import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salah_mode/screens/utils/theme_data.dart';

// ─────────────────────────────────────────────────────────────────
//  PREFS KEYS
// ─────────────────────────────────────────────────────────────────

String _lastSeenKey(int surah) => 'quran_lastSeen_$surah';
String _bookmarksKey(int surah) => 'quran_bookmarks_$surah';

// ─────────────────────────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────────────────────────

class QuranReadPage extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final int totalAyahs;
  final int totalWords;
  final String revelationType;
  final List<Map<String, dynamic>> ayahs;

  const QuranReadPage({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.totalAyahs,
    required this.revelationType,
    required this.totalWords,
    required this.ayahs,
  });

  @override
  State<QuranReadPage> createState() => _QuranReadPageState();
}

class _QuranReadPageState extends State<QuranReadPage> {
  // ── Scroll ─────────────────────────────────────────────────────
  final ScrollController _scrollCtrl = ScrollController();
  double _scrollProgress = 0.0;

  // ── Audio ──────────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _completeSub;

  int? _playingIndex;
  bool _playFullSurah = false;
  bool _isPlaying = false;

  // ── Ayahs (deep copy) ──────────────────────────────────────────
  late List<Map<String, dynamic>> _ayahs;

  // ── Translation ────────────────────────────────────────────────
  bool _translationLoading = false;
  String _translationError = '';

  // ── Bismillah translation per language ────────────────────────
  static const Map<String, String> _bismillahTranslations = {
    'English': 'In the name of Allah, the Most Gracious, the Most Merciful',
    'Hindi': 'अल्लाह के नाम से शुरू, जो बड़ा मेहरबान और रहम वाला है',
    'Urdu': 'اللہ کے نام سے جو بڑا مہربان نہایت رحم والا ہے',
  };
  String _bismillahTranslation =
      'In the name of Allah, the Most Gracious, the Most Merciful';

  // ── Bookmarks ──────────────────────────────────────────────────
  Set<int> _bookmarkedAyahs = {};

  // ── Last seen ──────────────────────────────────────────────────
  int? _lastSeenAyahIndex;
  bool _showLastSeenBanner = false;

  // ── Font size ──────────────────────────────────────────────────
  double _arabicFontSize = 26.0;
  static const double _fontMin = 18.0;
  static const double _fontMax = 40.0;

  // ── Reciters ───────────────────────────────────────────────────
  static const List<Map<String, String>> _reciters = [
    {'name': 'Mishary Alafasy', 'folder': 'Alafasy_128kbps'},
    {'name': 'Abdul Basit', 'folder': 'Abdul_Basit_Murattal_192kbps'},
    {'name': 'Maher Al Muaiqly', 'folder': 'Maher_AlMuaiqly_128kbps'},
  ];
  String _selectedReciter = 'Alafasy_128kbps';

  // ── Translations ───────────────────────────────────────────────
  static const Map<String, String> _translations = {
    'English': 'en.asad',
    'Hindi': 'hi.hindi',
    'Urdu': 'ur.jalandhry',
  };
  String _selectedTranslation = 'English';

  // ── Surah 9 (At-Tawbah) has no Bismillah ──────────────────────
  bool get _showBismillah => widget.surahNumber != 9;

  // ── Theme helpers ──────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bg => _isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;
  Color get _card => _isDark ? AppTheme.darkCard : AppTheme.lightCard;
  Color get _cardAlt => _isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt;
  Color get _accent => _isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
  Color get _gold => _isDark ? AppTheme.darkAccent : AppTheme.lightAccentGold;
  Color get _tp =>
      _isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
  Color get _ts =>
      _isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
  Color get _border => _isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
  Color get _btnTxt =>
      _isDark ? AppTheme.darkTextOnAccent : AppTheme.lightTextOnAccent;

  // ─────────────────────────────────────────────────────────────
  //  BISMILLAH STRIP — robust, encoding-agnostic
  //
  //  Strategy: remove ALL Arabic diacritic marks (harakat) and
  //  Unicode combining characters from both the candidate text and
  //  our reference bare string, then check if the normalised text
  //  starts with the normalised Bismillah.  If yes, find the split
  //  point in the *original* string by counting the bare characters
  //  consumed and slicing after them.
  // ─────────────────────────────────────────────────────────────

  static String _stripBismillah(String raw) {
    if (raw.isEmpty) return raw;

    // Bare (diacritic-free) Bismillah root letters only
    const bareRef = 'بسم الله الرحمن الرحيم';

    final bareRaw = _bare(raw);

    if (!bareRaw.startsWith(bareRef)) return raw;

    // Walk the original string, counting how many bare characters
    // we consume until we've matched all of bareRef
    int bareConsumed = 0;
    int originalPos = 0;
    final refLen = bareRef.length;

    while (originalPos < raw.length && bareConsumed < refLen) {
      final ch = raw[originalPos];
      if (!_isDiacritic(ch)) {
        bareConsumed++;
      }
      originalPos++;
    }

    // Trim leading whitespace AND any orphaned combining diacritics
    // (e.g. the kasra left behind from the meem of الرَّحِيمِ after slicing).
    var result = raw.substring(originalPos);
    result = result.replaceFirst(
      RegExp(r'^[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640\s]+'),
      '',
    );
    return result;
  }

  /// Remove Arabic combining diacritics (U+0610–U+061A, U+064B–U+065F,
  /// U+0670, Quranic annotation signs U+06D6–U+06ED, tatweel U+0640).
  static String _bare(String s) => s.replaceAll(
    RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'),
    '',
  );

  static bool _isDiacritic(String ch) {
    final cp = ch.codeUnitAt(0);
    return (cp >= 0x0610 && cp <= 0x061A) ||
        (cp >= 0x064B && cp <= 0x065F) ||
        cp == 0x0670 ||
        (cp >= 0x06D6 && cp <= 0x06ED) ||
        cp == 0x0640;
  }

  // ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Deep copy — never mutate parent's list
    _ayahs = widget.ayahs.map((e) => Map<String, dynamic>.from(e)).toList();

    // ── Fix: API prepends Bismillah to ayahs[0] for every surah
    //    except Surah 1 (Bismillah IS ayah 1) and Surah 9 (no Bismillah).
    //    We strip it by normalising both strings to bare Arabic letters
    //    (removing all diacritics / Unicode combining marks) before
    //    comparing — this survives any API encoding variation.
    // ──────────────────────────────────────────────────────────────
    if (_ayahs.isNotEmpty &&
        widget.surahNumber != 1 &&
        widget.surahNumber != 9) {
      _ayahs[0]['arabic'] = _stripBismillah(
        _ayahs[0]['arabic']?.toString() ?? '',
      );
    }

    // Configure audio for background playback
    _player.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          audioFocus: AndroidAudioFocus.gain,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );

    // Track completion for auto-advance
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      if (_playFullSurah && _playingIndex != null) {
        final next = _playingIndex! + 1;
        if (next < _ayahs.length) {
          _playAyah(next);
        } else {
          if (mounted) {
            setState(() {
              _playingIndex = null;
              _playFullSurah = false;
              _isPlaying = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _playingIndex = null;
            _isPlaying = false;
          });
        }
      }
    });

    // Scroll progress
    _scrollCtrl.addListener(_onScroll);

    // Load persisted data
    _loadPrefs();
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    _player.stop();
    _player.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Scroll progress tracker ────────────────────────────────────
  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    if (max <= 0) return;
    final progress = (_scrollCtrl.offset / max).clamp(0.0, 1.0);
    if ((progress - _scrollProgress).abs() > 0.005) {
      setState(() => _scrollProgress = progress);
    }

    // Save last seen based on scroll position
    final approxIndex = (progress * (_ayahs.length - 1)).round();
    _saveLastSeen(approxIndex);
  }

  // ── Prefs: load ────────────────────────────────────────────────
  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getInt(_lastSeenKey(widget.surahNumber));
      final bookmarkList =
          prefs.getStringList(_bookmarksKey(widget.surahNumber)) ?? [];

      if (!mounted) return;
      setState(() {
        _lastSeenAyahIndex = lastSeen;
        _showLastSeenBanner = lastSeen != null && lastSeen > 0;
        _bookmarkedAyahs = bookmarkList.map(int.parse).toSet();
      });
    } catch (e) {
      debugPrint('Prefs load error: $e');
    }
  }

  // ── Prefs: save last seen ──────────────────────────────────────
  Future<void> _saveLastSeen(int index) async {
    if (index == _lastSeenAyahIndex) return;
    _lastSeenAyahIndex = index;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSeenKey(widget.surahNumber), index);
    } catch (_) {}
  }

  // ── Prefs: toggle bookmark ─────────────────────────────────────
  Future<void> _toggleBookmark(int index) async {
    setState(() {
      if (_bookmarkedAyahs.contains(index)) {
        _bookmarkedAyahs.remove(index);
      } else {
        _bookmarkedAyahs.add(index);
      }
    });
    HapticFeedback.lightImpact();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _bookmarksKey(widget.surahNumber),
        _bookmarkedAyahs.map((e) => e.toString()).toList(),
      );
    } catch (_) {}
  }

  // ── Scroll to last seen ────────────────────────────────────────
  void _jumpToLastSeen() {
    if (_lastSeenAyahIndex == null) return;
    setState(() => _showLastSeenBanner = false);

    // Approximate item height
    const itemHeight = 220.0;
    final offset = (_lastSeenAyahIndex! * itemHeight).clamp(
      0.0,
      _scrollCtrl.position.maxScrollExtent,
    );
    _scrollCtrl.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  TRANSLATION
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadTranslation(String lang) async {
    if (!mounted) return;
    setState(() {
      _translationLoading = true;
      _translationError = '';
      _selectedTranslation = lang;
    });

    final code = _translations[lang];
    if (code == null) {
      _setTranslationError('Unknown translation.');
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.alquran.cloud/v1/surah/${widget.surahNumber}/$code',
            ),
          )
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (response.statusCode != 200) {
        _setTranslationError(
          'Translation unavailable (HTTP ${response.statusCode}).',
        );
        return;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final List? raw =
          (data['data'] as Map<String, dynamic>?)?['ayahs'] as List?;

      if (raw == null || raw.length != _ayahs.length) {
        _setTranslationError('Translation data is incomplete.');
        return;
      }

      for (int i = 0; i < _ayahs.length; i++) {
        _ayahs[i]['translation'] =
            (raw[i] as Map<String, dynamic>)['text']?.toString() ?? '';
      }

      if (mounted) {
        setState(() {
          _translationLoading = false;
          // Update Bismillah header translation to match selected language
          _bismillahTranslation =
              _bismillahTranslations[lang] ??
              _bismillahTranslations['English']!;
        });
      }
    } on TimeoutException {
      _setTranslationError('Request timed out.');
    } on SocketException {
      _setTranslationError('No internet connection.');
    } on FormatException {
      _setTranslationError('Unexpected response from server.');
    } catch (e) {
      debugPrint('Translation fetch error: $e');
      _setTranslationError('Could not load translation.');
    }
  }

  void _setTranslationError(String msg) {
    if (!mounted) return;
    setState(() {
      _translationLoading = false;
      _translationError = msg;
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  AUDIO
  // ─────────────────────────────────────────────────────────────

  Future<void> _playAyah(int index) async {
    if (index < 0 || index >= _ayahs.length) return;

    final ayahNum = _ayahs[index]['ayahNumber'] as int? ?? (index + 1);
    final surahStr = widget.surahNumber.toString().padLeft(3, '0');
    final ayahStr = ayahNum.toString().padLeft(3, '0');
    final url =
        'https://everyayah.com/data/$_selectedReciter/$surahStr$ayahStr.mp3';

    try {
      await _player.stop();
      await _player.play(UrlSource(url));
      if (mounted) {
        setState(() {
          _playingIndex = index;
          _isPlaying = true;
        });
      }

      // Auto-scroll to playing ayah
      _scrollToIndex(index);
    } catch (e) {
      debugPrint('Audio play error: $e');
      if (mounted) {
        setState(() {
          _playingIndex = null;
          _isPlaying = false;
          _playFullSurah = false;
        });
        Get.snackbar(
          'Playback Error',
          'Could not play this ayah. Check your connection.',
          backgroundColor: AppTheme.colorError,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _playFull() async {
    _playFullSurah = true;
    await _playAyah(0);
  }

  Future<void> _stopAudio() async {
    try {
      await _player.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _playingIndex = null;
        _playFullSurah = false;
        _isPlaying = false;
      });
    }
  }

  void _playPrev() {
    if (_playingIndex == null || _playingIndex! <= 0) return;
    _playAyah(_playingIndex! - 1);
  }

  void _playNext() {
    if (_playingIndex == null || _playingIndex! >= _ayahs.length - 1) return;
    _playAyah(_playingIndex! + 1);
  }

  void _scrollToIndex(int index) {
    if (!_scrollCtrl.hasClients) return;
    const itemHeight = 220.0;
    final offset = (index * itemHeight).clamp(
      0.0,
      _scrollCtrl.position.maxScrollExtent,
    );
    _scrollCtrl.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (_) => _stopAudio(),
      child: Container(
        color: _bg,
        child: Column(
          children: [
            // Reading progress bar
            _buildProgressBar(),

            // Controls
            _buildControls(),

            // Last seen banner
            if (_showLastSeenBanner) _buildLastSeenBanner(),

            // Translation error
            if (_translationError.isNotEmpty) _buildErrorBanner(),

            // Ayah list
            Expanded(child: _buildAyahList()),

            // Mini player (visible only when audio is active)
            if (_isPlaying || _playingIndex != null) _buildMiniPlayer(),
          ],
        ),
      ),
    );
  }

  // ── Progress bar ───────────────────────────────────────────────
  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: _scrollProgress,
        minHeight: 3,
        backgroundColor: _border,
        valueColor: AlwaysStoppedAnimation<Color>(_accent),
      ),
    );
  }

  // ── Controls ───────────────────────────────────────────────────
  Widget _buildControls() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          // Row 1: Reciter + Translation + Font controls
          Row(
            children: [
              Expanded(
                child: _ThemedDropdown<String>(
                  label: 'Reciter',
                  value: _selectedReciter,
                  items: _reciters
                      .map(
                        (r) => DropdownMenuItem(
                          value: r['folder'],
                          child: Text(
                            r['name']!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: _tp,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedReciter = v);
                    if (_isPlaying && _playingIndex != null) {
                      _playAyah(_playingIndex!);
                    }
                  },
                  accentColor: _accent,
                  cardAltColor: _cardAlt,
                  borderColor: _border,
                  textColor: _tp,
                  secondaryColor: _ts,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ThemedDropdown<String>(
                  label: 'Translation',
                  value: _selectedTranslation,
                  items: _translations.keys
                      .map(
                        (lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(
                            lang,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: _tp,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null && v != _selectedTranslation) {
                      _loadTranslation(v);
                    }
                  },
                  accentColor: _accent,
                  cardAltColor: _cardAlt,
                  borderColor: _border,
                  textColor: _tp,
                  secondaryColor: _ts,
                ),
              ),
              const SizedBox(width: 10),
              // Font size controls
              _FontSizeControls(
                onDecrease: () {
                  if (_arabicFontSize > _fontMin) {
                    setState(() => _arabicFontSize -= 2);
                  }
                },
                onIncrease: () {
                  if (_arabicFontSize < _fontMax) {
                    setState(() => _arabicFontSize += 2);
                  }
                },
                accentColor: _accent,
                cardAltColor: _cardAlt,
                borderColor: _border,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Play full surah button
          GestureDetector(
            onTap: _isPlaying ? _stopAudio : _playFull,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: _btnTxt,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isPlaying ? 'Stop Surah' : 'Play Full Surah',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _btnTxt,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Last seen banner ───────────────────────────────────────────
  Widget _buildLastSeenBanner() {
    final ayahNum = (_lastSeenAyahIndex ?? 0) + 1;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withOpacity(0.28), width: 0.8),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: _accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Continue from Ayah $ayahNum',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _accent,
              ),
            ),
          ),
          GestureDetector(
            onTap: _jumpToLastSeen,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Go',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _btnTxt,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _showLastSeenBanner = false),
            child: Icon(Icons.close_rounded, size: 16, color: _ts),
          ),
        ],
      ),
    );
  }

  // ── Translation error banner ───────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.colorError.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.colorError.withOpacity(0.28),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.colorError,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _translationError,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppTheme.colorError,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _loadTranslation(_selectedTranslation),
            child: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.colorError,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ── Ayah list ──────────────────────────────────────────────────
  Widget _buildAyahList() {
    if (_translationLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(_accent),
                backgroundColor: _accent.withOpacity(0.12),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading translation…',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _ts),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      // +1 for Bismillah header item
      itemCount: _ayahs.length + (_showBismillah ? 1 : 0),
      itemBuilder: (_, i) {
        // Index 0 is Bismillah header if shown
        if (_showBismillah && i == 0) return _buildBismillahHeader();
        final ayahIndex = _showBismillah ? i - 1 : i;
        return _AyahCard(
          ayah: _ayahs[ayahIndex],
          index: ayahIndex,
          isPlaying: _playingIndex == ayahIndex,
          isBookmarked: _bookmarkedAyahs.contains(ayahIndex),
          arabicFontSize: _arabicFontSize,
          onPlay: () {
            _playFullSurah = false;
            _playAyah(ayahIndex);
          },
          onStop: _stopAudio,
          onBookmark: () => _toggleBookmark(ayahIndex),
          cardColor: _card,
          accentColor: _accent,
          goldColor: _gold,
          borderColor: _border,
          textPrimary: _tp,
          textSecondary: _ts,
        );
      },
    );
  }

  // ── Bismillah header card ──────────────────────────────────────
  Widget _buildBismillahHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.30), width: 0.8),
      ),
      child: Column(
        children: [
          // Decorative top ornament
          Row(
            children: [
              Expanded(
                child: Container(height: 0.6, color: _gold.withOpacity(0.25)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.star_rounded,
                  size: 12,
                  color: _gold.withOpacity(0.50),
                ),
              ),
              Expanded(
                child: Container(height: 0.6, color: _gold.withOpacity(0.25)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 28,
              color: _gold,
              height: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _bismillahTranslation,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: _ts,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(height: 0.6, color: _gold.withOpacity(0.25)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.star_rounded,
                  size: 12,
                  color: _gold.withOpacity(0.50),
                ),
              ),
              Expanded(
                child: Container(height: 0.6, color: _gold.withOpacity(0.25)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Mini player bottom bar ─────────────────────────────────────
  Widget _buildMiniPlayer() {
    final idx = _playingIndex ?? 0;
    final ayahNum = idx < _ayahs.length
        ? (_ayahs[idx]['ayahNumber'] as int? ?? idx + 1)
        : idx + 1;
    final arabic = idx < _ayahs.length
        ? (_ayahs[idx]['arabic']?.toString() ?? '')
        : '';
    final short = arabic.length > 40 ? '${arabic.substring(0, 40)}…' : arabic;

    return Container(
      decoration: BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _border, width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Playing indicator dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),

            // Ayah info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ayah $ayahNum • ${widget.surahName}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _tp,
                    ),
                  ),
                  Text(
                    short,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13,
                      color: _gold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Prev
            _MiniPlayerBtn(
              icon: Icons.skip_previous_rounded,
              onTap: _playPrev,
              enabled: (_playingIndex ?? 0) > 0,
              accentColor: _accent,
              cardAltColor: _cardAlt,
              borderColor: _border,
            ),
            const SizedBox(width: 6),

            // Play / Stop
            GestureDetector(
              onTap: _isPlaying
                  ? _stopAudio
                  : () => _playAyah(_playingIndex ?? 0),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 18,
                  color: _btnTxt,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Next
            _MiniPlayerBtn(
              icon: Icons.skip_next_rounded,
              onTap: _playNext,
              enabled: (_playingIndex ?? 0) < _ayahs.length - 1,
              accentColor: _accent,
              cardAltColor: _cardAlt,
              borderColor: _border,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MINI PLAYER BUTTON
// ═══════════════════════════════════════════════════════════════════

class _MiniPlayerBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final Color accentColor, cardAltColor, borderColor;

  const _MiniPlayerBtn({
    required this.icon,
    required this.onTap,
    required this.enabled,
    required this.accentColor,
    required this.cardAltColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: cardAltColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? accentColor : accentColor.withOpacity(0.30),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FONT SIZE CONTROLS
// ═══════════════════════════════════════════════════════════════════

class _FontSizeControls extends StatelessWidget {
  final VoidCallback onDecrease, onIncrease;
  final Color accentColor, cardAltColor, borderColor;

  const _FontSizeControls({
    required this.onDecrease,
    required this.onIncrease,
    required this.accentColor,
    required this.cardAltColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardAltColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.text_decrease_rounded, onDecrease),
          Container(width: 0.8, height: 20, color: borderColor),
          _btn(Icons.text_increase_rounded, onIncrease),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Icon(icon, size: 16, color: accentColor),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  THEMED DROPDOWN
// ═══════════════════════════════════════════════════════════════════

class _ThemedDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final Color accentColor, cardAltColor, borderColor, textColor, secondaryColor;

  const _ThemedDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.accentColor,
    required this.cardAltColor,
    required this.borderColor,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cardAltColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: accentColor,
          ),
          dropdownColor: cardAltColor,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: textColor,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  AYAH CARD
// ═══════════════════════════════════════════════════════════════════

class _AyahCard extends StatelessWidget {
  final Map<String, dynamic> ayah;
  final int index;
  final bool isPlaying;
  final bool isBookmarked;
  final double arabicFontSize;
  final VoidCallback onPlay, onStop, onBookmark;
  final Color cardColor, accentColor, goldColor, borderColor;
  final Color textPrimary, textSecondary;

  const _AyahCard({
    required this.ayah,
    required this.index,
    required this.isPlaying,
    required this.isBookmarked,
    required this.arabicFontSize,
    required this.onPlay,
    required this.onStop,
    required this.onBookmark,
    required this.cardColor,
    required this.accentColor,
    required this.goldColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final arabic = ayah['arabic']?.toString() ?? '';
    final translation =
        (ayah['translation']?.toString().isNotEmpty == true
                ? ayah['translation']
                : ayah['english'])
            ?.toString() ??
        '';
    final ayahNum = ayah['ayahNumber'] as int? ?? (index + 1);

    final bgColor = isPlaying ? accentColor.withOpacity(0.08) : cardColor;
    final borderC = isPlaying ? accentColor.withOpacity(0.30) : borderColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderC, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top row: ayah number | bookmark | play ────────────
          Row(
            children: [
              // Ayah number badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accentColor.withOpacity(0.25),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  '$ayahNum',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),

              const Spacer(),

              // Bookmark button
              GestureDetector(
                onTap: onBookmark,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isBookmarked
                        ? goldColor.withOpacity(0.12)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isBookmarked
                        ? Border.all(
                            color: goldColor.withOpacity(0.30),
                            width: 0.6,
                          )
                        : null,
                  ),
                  child: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 16,
                    color: isBookmarked ? goldColor : textSecondary,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Play / stop button
              GestureDetector(
                onTap: isPlaying ? onStop : onPlay,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withOpacity(0.25),
                      width: 0.6,
                    ),
                  ),
                  child: Icon(
                    isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    size: 16,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Arabic text ───────────────────────────────────────
          Text(
            arabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: arabicFontSize,
              color: goldColor,
              height: 2.0,
            ),
          ),

          const SizedBox(height: 10),

          Container(height: 0.8, color: borderColor),

          const SizedBox(height: 10),

          // ── Translation ───────────────────────────────────────
          Text(
            translation,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
