import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/utils/point_service.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MosqueDetailPage extends StatefulWidget {
  final String mosqueId;
  final String mosqueName;

  const MosqueDetailPage({
    super.key,
    required this.mosqueId,
    required this.mosqueName,
  });

  @override
  State<MosqueDetailPage> createState() => _MosqueDetailPageState();
}

class _MosqueDetailPageState extends State<MosqueDetailPage> {
  bool _editMode = false;
  bool _loading = true;
  bool _submitting = false;
  int _barakah = 0;
  int _pending = 0;

  // ── Prayer times ───────────────────────────────────────────────
  Map<String, String> _times = {};

  // ── Facilities ─────────────────────────────────────────────────
  static const Map<String, Map<String, dynamic>> _facilityMeta = {
    "Wudu Area": {"icon": Icons.water_drop_rounded, "key": "wudu"},
    "Wheelchair Access": {
      "icon": Icons.accessible_rounded,
      "key": "wheelchair",
    },
    "Women Prayer Area": {"icon": Icons.woman_rounded, "key": "women"},
    "Parking": {"icon": Icons.local_parking_rounded, "key": "parking"},
    "A/C": {"icon": Icons.ac_unit_rounded, "key": "ac"},
    "Quran Library": {"icon": Icons.menu_book_rounded, "key": "library"},
  };
  Map<String, bool> _facilities = {};

  // ── Prayer display config ──────────────────────────────────────
  static const List<Map<String, String>> _prayers = [
    {
      "name": "Fajr",
      "adhan": "fajrAdhan",
      "jamaat": "fajrJamaat",
      "arabic": "الفجر",
    },
    {
      "name": "Dhuhr",
      "adhan": "zuhrAdhan",
      "jamaat": "zuhrJamaat",
      "arabic": "الظهر",
    },
    {
      "name": "Asr",
      "adhan": "asrAdhan",
      "jamaat": "asrJamaat",
      "arabic": "العصر",
    },
    {
      "name": "Maghrib",
      "adhan": "maghribAdhan",
      "jamaat": "maghribJamaat",
      "arabic": "المغرب",
    },
    {
      "name": "Isha",
      "adhan": "ishaAdhan",
      "jamaat": "ishaJamaat",
      "arabic": "العشاء",
    },
    {
      "name": "Jumua",
      "adhan": "jumuaKhutbah",
      "jamaat": "jumuaJamaat",
      "arabic": "الجمعة",
    },
  ];

  String _k(String field) => "${widget.mosqueId}_$field";

  // ── Barakah rank ───────────────────────────────────────────────
  _RankInfo _rank() {
    if (_barakah >= 500) {
      return _RankInfo(
        "Ummah Builder",
        Icons.mosque_rounded,
        AppTheme.colorWarning,
      );
    }
    if (_barakah >= 200) {
      return _RankInfo(
        "Mosque Guardian",
        Icons.shield_rounded,
        AppTheme.colorInfo,
      );
    }
    if (_barakah >= 100) {
      return _RankInfo(
        "Mosque Keeper",
        Icons.verified_rounded,
        AppTheme.colorSuccess,
      );
    }
    if (_barakah >= 50) {
      return _RankInfo(
        "Mosque Helper",
        Icons.handshake_rounded,
        const Color(0xFF9C6FD6),
      );
    }
    if (_barakah >= 10) {
      return _RankInfo(
        "Contributor",
        Icons.volunteer_activism,
        AppTheme.colorSuccess,
      );
    }
    return _RankInfo(
      "New Helper",
      Icons.star_outline_rounded,
      const Color(0xFF888888),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ─────────────────────────────────────────────────────────────
  //  DATA
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _barakah = prefs.getInt('barakah_points') ?? 0;

      // Times
      _times = {};
      for (final p in _prayers) {
        _times[p['adhan']!] = prefs.getString(_k(p['adhan']!)) ?? '--:--';
        _times[p['jamaat']!] = prefs.getString(_k(p['jamaat']!)) ?? '--:--';
      }

      // Facilities
      _facilities = {};
      for (final entry in _facilityMeta.entries) {
        _facilities[entry.key] =
            prefs.getBool(_k(entry.value['key'] as String)) ?? false;
      }
    } catch (e) {
      debugPrint("MosqueDetail loadData error: $e");
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in _times.entries) {
        await prefs.setString(_k(entry.key), entry.value);
      }
    } catch (e) {
      debugPrint("Save times error: $e");
    }
  }

  Future<void> _pickTime(String timeKey) async {
    try {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (picked == null || !mounted) return;
      // Store as 12-hour with AM/PM e.g. "7:30 AM", "12:05 PM"
      final h12 = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final formatted =
          "$h12:${picked.minute.toString().padLeft(2, '0')} $period";
      setState(() {
        _times[timeKey] = formatted;
        _pending += 5;
      });
      await _saveTimes();
    } catch (e) {
      debugPrint("Time picker error: $e");
    }
  }

  Future<void> _toggleFacility(String facility, bool val) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metaKey = (_facilityMeta[facility]?['key'] as String?) ?? facility;
      setState(() {
        _facilities[facility] = val;
        _pending += 2;
      });
      await prefs.setBool(_k(metaKey), val);
    } catch (e) {
      debugPrint("Facility toggle error: $e");
    }
  }

  Future<void> _submitChanges() async {
    if (_pending <= 0 || _submitting) return;
    if (!mounted) return;
    setState(() => _submitting = true);
    try {
      await SharedPreferences.getInstance();
      // Award via PointsService — writes locally + syncs Firestore in background
      await PointsService.instance.award(
        PointEvent.mosqueEdit,
        amount: _pending,
      );
      final earned = _pending;
      _barakah += earned;
      _pending = 0;
      // Local prefs write still kept for immediate UI; service handles Firestore

      if (mounted) setState(() => _submitting = false);

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
      final btnTextColor = isDark
          ? AppTheme.darkTextOnAccent
          : AppTheme.lightTextOnAccent;

      Get.snackbar(
        "Barakah Earned 🌟",
        "JazakAllah Khair! +$earned points added. Your update helped the Ummah.",
        backgroundColor: accentColor,
        colorText: btnTextColor,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint("Submit error: $e");
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
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

    if (_loading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: accentColor,
            backgroundColor: accentColor.withOpacity(0.15),
          ),
        ),
      );
    }

    final rank = _rank();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentColor, size: 20),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.mosqueName,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _editMode = !_editMode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _editMode
                      ? accentColor
                      : accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withOpacity(0.30),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _editMode ? Icons.check_rounded : Icons.edit_rounded,
                      size: 14,
                      color: _editMode ? btnTextColor : accentColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _editMode ? "Done" : "Edit",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _editMode ? btnTextColor : accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Barakah / rank card ────────────────────────────────
          _RankCard(
            rank: rank,
            barakah: _barakah,
            pending: _pending,
            cardColor: cardColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          const SizedBox(height: 20),

          // ── Edit mode banner ───────────────────────────────────
          if (_editMode)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withOpacity(0.25),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Tap any time to update it. Each edit earns Barakah Points!",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Prayer times section ───────────────────────────────
          _SectionLabel(
            label: "Prayer Times",
            goldColor: goldColor,
            textPrimary: textPrimary,
          ),

          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Column(
              children: List.generate(_prayers.length, (i) {
                final p = _prayers[i];
                final isLast = i == _prayers.length - 1;
                return Column(
                  children: [
                    _PrayerRow(
                      name: p['name']!,
                      arabic: p['arabic']!,
                      adhanTime: _times[p['adhan']!] ?? '--:--',
                      jamaatTime: _times[p['jamaat']!] ?? '--:--',
                      editMode: _editMode,
                      accentColor: accentColor,
                      goldColor: goldColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textTertiary: textTertiary,
                      onTapAdhan: () => _pickTime(p['adhan']!),
                      onTapJamaat: () => _pickTime(p['jamaat']!),
                    ),
                    if (!isLast)
                      Divider(
                        color: borderColor,
                        height: 1,
                        thickness: 0.8,
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          // ── Facilities section ─────────────────────────────────
          _SectionLabel(
            label: "Facilities",
            goldColor: goldColor,
            textPrimary: textPrimary,
          ),

          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Column(
              children: List.generate(_facilityMeta.length, (i) {
                final entry = _facilityMeta.entries.elementAt(i);
                final name = entry.key;
                final icon = entry.value['icon'] as IconData;
                final enabled = _facilities[name] ?? false;
                final isLast = i == _facilityMeta.length - 1;

                return Column(
                  children: [
                    _FacilityRow(
                      name: name,
                      icon: icon,
                      enabled: enabled,
                      editMode: _editMode,
                      accentColor: accentColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                      onChanged: (val) => _toggleFacility(name, val),
                    ),
                    if (!isLast)
                      Divider(
                        color: borderColor,
                        height: 1,
                        thickness: 0.8,
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          // ── Submit button ──────────────────────────────────────
          if (_pending > 0)
            GestureDetector(
              onTap: _submitting ? null : _submitChanges,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _submitting
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: btnTextColor,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.volunteer_activism_rounded,
                            size: 18,
                            color: btnTextColor,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Submit & Earn +$_pending Barakah Points",
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

          const SizedBox(height: 16),

          // ── Disclaimer ─────────────────────────────────────────
          Container(
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
                    "Prayer times are community-sourced. Always confirm with "
                    "the mosque directly for the most accurate timings.",
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
//  RANK INFO MODEL
// ═══════════════════════════════════════════════════════════════════

class _RankInfo {
  final String title;
  final IconData icon;
  final Color color;
  const _RankInfo(this.title, this.icon, this.color);
}

// ═══════════════════════════════════════════════════════════════════
//  RANK CARD
// ═══════════════════════════════════════════════════════════════════

class _RankCard extends StatelessWidget {
  final _RankInfo rank;
  final int barakah, pending;
  final Color cardColor, borderColor, textPrimary, textSecondary;

  const _RankCard({
    required this.rank,
    required this.barakah,
    required this.pending,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: rank.color.withOpacity(0.30), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: rank.color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: rank.color.withOpacity(0.30),
                width: 0.8,
              ),
            ),
            child: Icon(rank.icon, color: rank.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank.title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: rank.color,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      "⭐ $barakah Barakah Points",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (pending > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.colorSuccess.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.colorSuccess.withOpacity(0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          "+$pending pending",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.colorSuccess,
                          ),
                        ),
                      ),
                    ],
                  ],
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
//  PRAYER ROW
// ═══════════════════════════════════════════════════════════════════

class _PrayerRow extends StatelessWidget {
  final String name, arabic, adhanTime, jamaatTime;
  final bool editMode;
  final Color accentColor, goldColor, textPrimary, textSecondary, textTertiary;
  final VoidCallback onTapAdhan, onTapJamaat;

  const _PrayerRow({
    required this.name,
    required this.arabic,
    required this.adhanTime,
    required this.jamaatTime,
    required this.editMode,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.onTapAdhan,
    required this.onTapJamaat,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          // Prayer name + Arabic
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                Text(
                  arabic,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 13,
                    color: goldColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Adhan time
          _TimeChip(
            label: "Adhan",
            time: adhanTime,
            editMode: editMode,
            accentColor: accentColor,
            textPrimary: textPrimary,
            textTertiary: textTertiary,
            onTap: onTapAdhan,
          ),

          const SizedBox(width: 10),

          // Jamaat time
          _TimeChip(
            label: "Jamaat",
            time: jamaatTime,
            editMode: editMode,
            accentColor: accentColor,
            textPrimary: textPrimary,
            textTertiary: textTertiary,
            onTap: onTapJamaat,
          ),
        ],
      ),
    );
  }
}

// ── Time chip ─────────────────────────────────────────────────────
class _TimeChip extends StatelessWidget {
  final String label, time;
  final bool editMode;
  final Color accentColor, textPrimary, textTertiary;
  final VoidCallback onTap;

  const _TimeChip({
    required this.label,
    required this.time,
    required this.editMode,
    required this.accentColor,
    required this.textPrimary,
    required this.textTertiary,
    required this.onTap,
  });

  bool get _isSet => time.isNotEmpty && time != '--:--' && time != '';

  // Split "7:30 AM" → ("7:30", "AM")  or  ("7:30", "")  for old data
  String get _timePart {
    final parts = time.split(' ');
    return parts.isNotEmpty ? parts[0] : time;
  }

  String get _periodPart {
    final parts = time.split(' ');
    return parts.length >= 2 ? parts[1] : '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: editMode ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: editMode ? accentColor.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: editMode
                ? accentColor.withOpacity(0.30)
                : _isSet
                ? accentColor.withOpacity(0.15)
                : textTertiary.withOpacity(0.15),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label (Adhan / Jamaat)
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                color: textTertiary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            // Time digits + optional edit icon
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isSet ? _timePart : '--:--',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _isSet ? textPrimary : textTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (editMode) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.edit_rounded, size: 10, color: accentColor),
                ],
              ],
            ),
            // AM / PM badge — only when a time is set
            if (_isSet && _periodPart.isNotEmpty) ...[
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: _periodPart == 'AM'
                      ? accentColor.withOpacity(0.12)
                      : const Color(0xFF9C6FD6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _periodPart,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: _periodPart == 'AM'
                        ? accentColor
                        : const Color(0xFF9C6FD6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FACILITY ROW
// ═══════════════════════════════════════════════════════════════════

class _FacilityRow extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool enabled, editMode;
  final Color accentColor, textPrimary, textSecondary, borderColor;
  final ValueChanged<bool> onChanged;

  const _FacilityRow({
    required this.name,
    required this.icon,
    required this.enabled,
    required this.editMode,
    required this.accentColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: enabled
                  ? accentColor.withOpacity(0.10)
                  : borderColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 17,
              color: enabled ? accentColor : textSecondary.withOpacity(0.50),
            ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: enabled ? textPrimary : textSecondary,
              ),
            ),
          ),
          // Toggle
          Switch(
            value: enabled,
            onChanged: editMode ? onChanged : null,
            activeColor: accentColor,
            activeTrackColor: accentColor.withOpacity(0.30),
            inactiveThumbColor: textSecondary.withOpacity(0.40),
            inactiveTrackColor: borderColor,
            trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SECTION LABEL
// ═══════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color goldColor, textPrimary;
  const _SectionLabel({
    required this.label,
    required this.goldColor,
    required this.textPrimary,
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
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
    ],
  );
}
