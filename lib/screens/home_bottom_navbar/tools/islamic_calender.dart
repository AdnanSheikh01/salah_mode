import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

class IslamicCalenderPage extends StatefulWidget {
  const IslamicCalenderPage({super.key});

  @override
  State<IslamicCalenderPage> createState() => _IslamicCalenderPageState();
}

class _IslamicCalenderPageState extends State<IslamicCalenderPage> {
  DateTime _selected = DateTime.now();
  DateTime _visible = DateTime(DateTime.now().year, DateTime.now().month);
  int _moonOffset = 0;
  final _today = DateTime.now();

  // ═══════════════════════════════════════════════════════════════
  //  HIJRI CALCULATION — civil algorithm (safe, null-proof)
  // ═══════════════════════════════════════════════════════════════

  static const List<String> _hijriMonths = [
    "Muharram",
    "Safar",
    "Rabi' al-Awwal",
    "Rabi' al-Thani",
    "Jumada al-Awwal",
    "Jumada al-Thani",
    "Rajab",
    "Sha'ban",
    "Ramadan",
    "Shawwal",
    "Dhul-Qi'dah",
    "Dhul-Hijjah",
  ];

  // Returns a map with day, month (1-12), year, and monthName
  Map<String, dynamic> _toHijri(DateTime date) {
    try {
      final jd = (date.millisecondsSinceEpoch / 86400000) + 2440587.5;
      final days = jd - 1948439.5 + _moonOffset;
      final year = ((30 * days + 10646) ~/ 10631);
      final priorDays = days - (354 * (year - 1) + ((3 + 11 * year) ~/ 30));
      final month = (priorDays / 29.5).ceil().clamp(1, 12);
      final day =
          (days -
                  (354 * (year - 1) +
                      ((3 + 11 * year) ~/ 30) +
                      (29.5 * (month - 1)).floor()) +
                  1)
              .toInt()
              .clamp(1, 30);

      return {
        'day': day,
        'month': month,
        'year': year,
        'monthName': _hijriMonths[(month - 1).clamp(0, 11)],
      };
    } catch (_) {
      return {'day': 1, 'month': 1, 'year': 1446, 'monthName': 'Muharram'};
    }
  }

  String _hijriString(DateTime date) {
    final h = _toHijri(date);
    return "${h['day']} ${h['monthName']} ${h['year']} AH";
  }

  // ── Islamic events ─────────────────────────────────────────────
  // Returns null (no event), event name, or 'Ramadan' for the whole month
  _IslamicEvent? _getEvent(DateTime date) {
    try {
      final h = _toHijri(date);
      final d = h['day'] as int;
      final m = h['month'] as int;

      if (m == 9) return _IslamicEvent.ramadan;
      if (m == 12 && d == 10) return _IslamicEvent.eidAdha;
      if (m == 10 && d == 1) return _IslamicEvent.eidFitr;
      if (m == 1 && d == 10) return _IslamicEvent.ashura;
      if (m == 3 && d == 12) return _IslamicEvent.mawlid;
      if (m == 7 && d == 27) return _IslamicEvent.laylatulMiraj;
      if (m == 8 && d == 15) return _IslamicEvent.shabanFasting;
      if (m == 9 && d == 27) return _IslamicEvent.laylatulQadr;
    } catch (_) {}
    return null;
  }

  // ── Month navigation ───────────────────────────────────────────
  void _changeMonth(int delta) {
    setState(() {
      _visible = DateTime(_visible.year, _visible.month + delta);
    });
  }

  void _jumpToToday() {
    setState(() {
      _selected = _today;
      _visible = DateTime(_today.year, _today.month);
    });
  }

  Future<void> _pickDate() async {
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selected,
        firstDate: DateTime(1900),
        lastDate: DateTime(2200),
        builder: (ctx, child) => Theme(data: Theme.of(ctx), child: child!),
      );
      if (picked != null && mounted) {
        setState(() {
          _selected = picked;
          _visible = DateTime(picked.year, picked.month);
        });
      }
    } catch (e) {
      debugPrint("Date picker error: $e");
    }
  }

  List<DateTime> _buildMonthDays() {
    try {
      final first = DateTime(_visible.year, _visible.month, 1);
      final startOffset = first.weekday % 7; // Sunday = 0
      final start = first.subtract(Duration(days: startOffset));
      return List.generate(42, (i) => start.add(Duration(days: i)));
    } catch (_) {
      return List.generate(42, (i) => DateTime.now().add(Duration(days: i)));
    }
  }

  bool _isToday(DateTime d) =>
      d.year == _today.year && d.month == _today.month && d.day == _today.day;

  bool _isSelected(DateTime d) =>
      d.year == _selected.year &&
      d.month == _selected.month &&
      d.day == _selected.day;

  double _hijriDayProgress() {
    final h = _toHijri(_selected);
    return ((h['day'] as int) / 30).clamp(0.0, 1.0);
  }

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

    final hijri = _hijriString(_selected);
    final gregorian = DateFormat.yMMMMEEEEd().format(_selected);
    final days = _buildMonthDays();
    final h = _toHijri(_selected);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentColor, size: 20),
        title: Text(
          "Islamic Calendar",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _jumpToToday,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withOpacity(0.25),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  "Today",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hijri date hero card ───────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    // Moon phase dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(30, (i) {
                        final filled = i < (h['day'] as int);
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: filled
                                ? btnTextColor.withOpacity(0.90)
                                : btnTextColor.withOpacity(0.20),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      "☽  ${h['monthName']}  ☾",
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 13,
                        color: btnTextColor.withOpacity(0.75),
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        hijri,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: btnTextColor,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      gregorian,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: btnTextColor.withOpacity(0.72),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Progress bar — day in Hijri month
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Day ${h['day']} of ~30",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: btnTextColor.withOpacity(0.65),
                              ),
                            ),
                            Text(
                              "${h['monthName']} ${h['year']} AH",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: btnTextColor.withOpacity(0.65),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _hijriDayProgress(),
                            minHeight: 5,
                            backgroundColor: btnTextColor.withOpacity(0.20),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              btnTextColor.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Today's event banner ───────────────────────────
              Builder(
                builder: (_) {
                  final todayEvent = _getEvent(_today);
                  if (todayEvent == null) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: todayEvent.color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: todayEvent.color.withOpacity(0.30),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          todayEvent.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                todayEvent.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: todayEvent.color,
                                ),
                              ),
                              Text(
                                "Today is a blessed occasion",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ── Month navigator ────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Column(
                  children: [
                    // Month header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _NavBtn(
                          onTap: () => _changeMonth(-1),
                          icon: Icons.chevron_left,
                          color: accentColor,
                          cardAltColor: cardAltColor,
                        ),
                        Column(
                          children: [
                            Text(
                              DateFormat.yMMMM().format(_visible),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              () {
                                try {
                                  final h1 = _toHijri(
                                    DateTime(_visible.year, _visible.month, 1),
                                  );
                                  final h2 = _toHijri(
                                    DateTime(
                                      _visible.year,
                                      _visible.month + 1,
                                      0,
                                    ),
                                  );
                                  return "${h1['monthName']} / ${h2['monthName']} ${h1['year']} AH";
                                } catch (_) {
                                  return '';
                                }
                              }(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: textTertiary,
                              ),
                            ),
                          ],
                        ),
                        _NavBtn(
                          onTap: () => _changeMonth(1),
                          icon: Icons.chevron_right,
                          color: accentColor,
                          cardAltColor: cardAltColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Weekday row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children:
                          ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                              .map(
                                (d) => SizedBox(
                                  width: 38,
                                  child: Text(
                                    d,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: d == "Fri"
                                          ? goldColor
                                          : textTertiary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),

                    const SizedBox(height: 8),

                    // Calendar grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 42,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            childAspectRatio: 0.85,
                          ),
                      itemBuilder: (ctx, index) {
                        if (index >= days.length)
                          return const SizedBox.shrink();
                        final date = days[index];
                        final inMonth = date.month == _visible.month;
                        final isToday = _isToday(date);
                        final isSel = _isSelected(date);
                        final event = _getEvent(date);
                        final isFriday = date.weekday == DateTime.friday;

                        Color bg = Colors.transparent;
                        if (isSel)
                          bg = accentColor;
                        else if (isToday)
                          bg = accentColor.withOpacity(0.18);

                        return GestureDetector(
                          onTap: () => setState(() => _selected = date),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(10),
                              border: event != null && !isSel
                                  ? Border.all(
                                      color: event.color.withOpacity(0.55),
                                      width: 1.2,
                                    )
                                  : isToday && !isSel
                                  ? Border.all(color: accentColor, width: 1)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${date.day}",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: isSel || isToday
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isSel
                                        ? btnTextColor
                                        : !inMonth
                                        ? textTertiary.withOpacity(0.35)
                                        : isFriday
                                        ? goldColor
                                        : isToday
                                        ? accentColor
                                        : textPrimary,
                                  ),
                                ),
                                if (event != null) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? btnTextColor.withOpacity(0.80)
                                          : event.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Selected date event card ────────────────────────
              Builder(
                builder: (_) {
                  final selEvent = _getEvent(_selected);
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selEvent != null
                            ? selEvent.color.withOpacity(0.30)
                            : borderColor,
                        width: selEvent != null ? 1.0 : 0.8,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selEvent != null
                                ? selEvent.color.withOpacity(0.12)
                                : accentColor.withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            selEvent?.emoji ?? "📅",
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selEvent != null
                                    ? selEvent.label
                                    : "No Islamic event",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: selEvent?.color ?? textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _hijriString(_selected),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  "EEEE, d MMMM yyyy",
                                ).format(_selected),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ── Event legend ───────────────────────────────────
              _EventLegend(
                cardColor: cardColor,
                borderColor: borderColor,
                goldColor: goldColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 20),

              // ── Buttons row ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                              color: btnTextColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Select Date",
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
                ],
              ),

              const SizedBox(height: 14),

              // ── Moon offset control ────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.brightness_3_rounded,
                      size: 16,
                      color: goldColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Moon Offset (days)",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(
                        () => _moonOffset = (_moonOffset - 1).clamp(-3, 3),
                      ),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 16,
                          color: accentColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        "$_moonOffset",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(
                        () => _moonOffset = (_moonOffset + 1).clamp(-3, 3),
                      ),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Disclaimer ─────────────────────────────────────
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
                      style: TextStyle(
                        fontSize: 12,
                        color: goldColor,
                        height: 1.6,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Hijri dates are calculated using a civil approximation. "
                        "Actual moon sighting may vary by 1–2 days. "
                        "Adjust Moon Offset to match local sighting.",
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
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ISLAMIC EVENT MODEL
// ═══════════════════════════════════════════════════════════════════

enum _IslamicEvent {
  ramadan,
  eidFitr,
  eidAdha,
  ashura,
  mawlid,
  laylatulMiraj,
  shabanFasting,
  laylatulQadr,
}

extension _IslamicEventExt on _IslamicEvent {
  String get label {
    switch (this) {
      case _IslamicEvent.ramadan:
        return "Ramadan";
      case _IslamicEvent.eidFitr:
        return "Eid al-Fitr";
      case _IslamicEvent.eidAdha:
        return "Eid al-Adha";
      case _IslamicEvent.ashura:
        return "Day of Ashura";
      case _IslamicEvent.mawlid:
        return "Mawlid an-Nabi";
      case _IslamicEvent.laylatulMiraj:
        return "Laylatul Mi'raj";
      case _IslamicEvent.shabanFasting:
        return "15th Sha'ban";
      case _IslamicEvent.laylatulQadr:
        return "Laylatul Qadr (27th)";
    }
  }

  String get emoji {
    switch (this) {
      case _IslamicEvent.ramadan:
        return "🌙";
      case _IslamicEvent.eidFitr:
        return "🎊";
      case _IslamicEvent.eidAdha:
        return "🐑";
      case _IslamicEvent.ashura:
        return "🤲";
      case _IslamicEvent.mawlid:
        return "⭐";
      case _IslamicEvent.laylatulMiraj:
        return "✨";
      case _IslamicEvent.shabanFasting:
        return "🤲";
      case _IslamicEvent.laylatulQadr:
        return "💫";
    }
  }

  Color get color {
    switch (this) {
      case _IslamicEvent.ramadan:
        return AppTheme.colorSuccess;
      case _IslamicEvent.eidFitr:
        return AppTheme.colorWarning;
      case _IslamicEvent.eidAdha:
        return AppTheme.colorWarning;
      case _IslamicEvent.ashura:
        return AppTheme.colorInfo;
      case _IslamicEvent.mawlid:
        return const Color(0xFF9C6FD6);
      case _IslamicEvent.laylatulMiraj:
        return const Color(0xFF5B8FD4);
      case _IslamicEvent.shabanFasting:
        return AppTheme.colorInfo;
      case _IslamicEvent.laylatulQadr:
        return const Color(0xFFD4A84B);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  EVENT LEGEND WIDGET
// ═══════════════════════════════════════════════════════════════════

class _EventLegend extends StatelessWidget {
  final Color cardColor, borderColor, goldColor, textPrimary, textSecondary;
  const _EventLegend({
    required this.cardColor,
    required this.borderColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  static const _items = [
    (_IslamicEvent.ramadan, "🌙", "Ramadan"),
    (_IslamicEvent.eidFitr, "🎊", "Eid al-Fitr"),
    (_IslamicEvent.eidAdha, "🐑", "Eid al-Adha"),
    (_IslamicEvent.ashura, "🤲", "Ashura"),
    (_IslamicEvent.mawlid, "⭐", "Mawlid"),
    (_IslamicEvent.laylatulQadr, "💫", "Laylatul Qadr"),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: goldColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Islamic Events",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: _items.map((item) {
              final event = item.$1;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: event.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "${item.$2} ${item.$3}",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  NAV BUTTON
// ═══════════════════════════════════════════════════════════════════

class _NavBtn extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color, cardAltColor;
  const _NavBtn({
    required this.onTap,
    required this.icon,
    required this.color,
    required this.cardAltColor,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: cardAltColor, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    ),
  );
}
