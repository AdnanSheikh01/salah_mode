import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

// ─────────────────────────────────────────────────────────────────
// MADHAB METADATA
// ─────────────────────────────────────────────────────────────────

class _MadhabInfo {
  final Madhab value;
  final String name;
  final String asrTime;
  final String desc;
  final String scholars;
  final Color color;

  const _MadhabInfo({
    required this.value,
    required this.name,
    required this.asrTime,
    required this.desc,
    required this.scholars,
    required this.color,
  });
}

const List<_MadhabInfo> _madhabs = [
  _MadhabInfo(
    value: Madhab.hanafi,
    name: "Hanafi",
    asrTime: "Later Asr",
    desc:
        "Asr begins when the shadow of an object is twice its length. "
        "Followed by the majority of Muslims in South Asia, Turkey & Central Asia.",
    scholars: "Imam Abu Hanifa · Imam Abu Yusuf · Imam Muhammad",
    color: AppTheme.colorInfo,
  ),
  _MadhabInfo(
    value: Madhab.shafi,
    name: "Shafi'i",
    asrTime: "Earlier Asr",
    desc:
        "Asr begins when the shadow of an object equals its length. "
        "Followed widely in Southeast Asia, East Africa & parts of the Arab world.",
    scholars: "Imam Al-Shafi'i · Imam Al-Nawawi · Imam Al-Ghazali",
    color: AppTheme.colorSuccess,
  ),
];

// ─────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────

class MadhabSelectionScreen extends StatefulWidget {
  final Madhab currentMadhab;
  final ValueChanged<Madhab>? onChanged;

  const MadhabSelectionScreen({
    super.key,
    this.currentMadhab = Madhab.shafi,
    this.onChanged,
  });

  @override
  State<MadhabSelectionScreen> createState() => _MadhabSelectionScreenState();
}

class _MadhabSelectionScreenState extends State<MadhabSelectionScreen> {
  late Madhab _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentMadhab;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      widget.onChanged?.call(_selected);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Madhab save error: $e");
      if (mounted) setState(() => _saving = false);
    }
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentColor, size: 20),
        title: Text(
          "Select Madhab",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Intro card ─────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: goldColor.withOpacity(0.22),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "✦ ",
                          style: TextStyle(
                            fontSize: 13,
                            color: goldColor,
                            height: 1.5,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Your Madhab affects the Asr prayer time calculation. "
                            "Choose the juristic school you follow.",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: textSecondary,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Section label ──────────────────────────────
                  Row(
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
                        "Choose Your School",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Madhab cards ───────────────────────────────
                  ...List.generate(_madhabs.length, (i) {
                    final m = _madhabs[i];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i < _madhabs.length - 1 ? 12 : 0,
                      ),
                      child: _MadhabCard(
                        info: m,
                        selected: _selected == m.value,
                        accentColor: accentColor,
                        cardColor: cardColor,
                        cardAltColor: cardAltColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        textTertiary: textTertiary,
                        btnTextColor: btnTextColor,
                        onTap: () => setState(() => _selected = m.value),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // ── Asr comparison card ────────────────────────
                  _AsrComparisonCard(
                    selected: _selected,
                    cardColor: cardColor,
                    cardAltColor: cardAltColor,
                    borderColor: borderColor,
                    goldColor: goldColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textTertiary: textTertiary,
                  ),

                  const SizedBox(height: 20),

                  // ── Scholarly note ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accentColor.withOpacity(0.18),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: accentColor.withOpacity(0.70),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Both Hanafi and Shafi'i madhabs are valid and widely followed. "
                            "Consult a local scholar if you are unsure which to follow.",
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

          // ── Save button ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: borderColor, width: 0.8)),
            ),
            child: GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _saving
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
                            Icons.check_rounded,
                            size: 18,
                            color: btnTextColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Save Madhab",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MADHAB CARD
// ═══════════════════════════════════════════════════════════════════

class _MadhabCard extends StatelessWidget {
  final _MadhabInfo info;
  final bool selected;
  final Color accentColor, cardColor, cardAltColor, borderColor;
  final Color textPrimary, textSecondary, textTertiary, btnTextColor;
  final VoidCallback onTap;

  const _MadhabCard({
    required this.info,
    required this.selected,
    required this.accentColor,
    required this.cardColor,
    required this.cardAltColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.btnTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? info.color.withOpacity(0.07) : cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? info.color.withOpacity(0.55) : borderColor,
            width: selected ? 1.5 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────────────
            Row(
              children: [
                // Madhab icon circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: selected ? info.color : info.color.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 22,
                    color: selected ? Colors.white : info.color,
                  ),
                ),

                const SizedBox(width: 12),

                // Name + Arabic
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: selected ? info.color : textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Asr time badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: info.color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: info.color.withOpacity(0.25),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          info.asrTime,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: info.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Check indicator
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: selected
                      ? Container(
                          key: const ValueKey('on'),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: info.color,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        )
                      : Container(
                          key: const ValueKey('off'),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                        ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Description ───────────────────────────────────────
            Text(
              info.desc,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: textSecondary,
                height: 1.55,
              ),
            ),

            const SizedBox(height: 10),

            // ── Scholars row ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: info.color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: info.color.withOpacity(0.15),
                  width: 0.6,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_rounded, size: 12, color: info.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      info.scholars,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ASR COMPARISON CARD
// ═══════════════════════════════════════════════════════════════════

class _AsrComparisonCard extends StatelessWidget {
  final Madhab selected;
  final Color cardColor, cardAltColor, borderColor, goldColor;
  final Color textPrimary, textSecondary, textTertiary;

  const _AsrComparisonCard({
    required this.selected,
    required this.cardColor,
    required this.cardAltColor,
    required this.borderColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
  });

  @override
  Widget build(BuildContext context) {
    // Simulate Asr times for a visual comparison
    // Hanafi Asr ≈ 30-60 min later than Shafi'i depending on season
    const shafiPct = 0.52; // earlier = fraction through day
    const hanafiPct = 0.62; // later

    return Container(
      padding: const EdgeInsets.all(16),
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
                "Asr Time Comparison",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Timeline bar
          SizedBox(
            height: 56,
            child: Stack(
              children: [
                // Track
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Shafi'i marker
                Positioned(
                  left: MediaQuery.of(context).size.width * shafiPct - 60,
                  top: 0,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.colorSuccess.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.colorSuccess.withOpacity(0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          "Shafi'i",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.colorSuccess,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 2,
                        height: 12,
                        color: AppTheme.colorSuccess,
                      ),
                    ],
                  ),
                ),

                // Hanafi marker
                Positioned(
                  left: MediaQuery.of(context).size.width * hanafiPct - 60,
                  top: 0,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.colorInfo.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.colorInfo.withOpacity(0.35),
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          "Hanafi",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.colorInfo,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 2,
                        height: 12,
                        color: AppTheme.colorInfo,
                      ),
                    ],
                  ),
                ),

                // Sun icon at bottom
                Positioned(
                  top: 12,
                  left: 0,
                  child: Text("🌅", style: const TextStyle(fontSize: 14)),
                ),
                Positioned(
                  top: 12,
                  right: 0,
                  child: Text("🌆", style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 13,
                color: selected == Madhab.shafi
                    ? AppTheme.colorSuccess
                    : textTertiary,
              ),
              const SizedBox(width: 5),
              Text(
                "Your current Madhab: ",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: textTertiary,
                ),
              ),
              Text(
                selected == Madhab.hanafi ? "Hanafi" : "Shafi'i",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected == Madhab.hanafi
                      ? AppTheme.colorInfo
                      : AppTheme.colorSuccess,
                ),
              ),
              Text(
                " Asr time",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
