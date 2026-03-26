import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';
import 'package:salah_mode/screens/widgets/names.dart';

class NinetyNineNamesScreen extends StatefulWidget {
  const NinetyNineNamesScreen({super.key});

  @override
  State<NinetyNineNamesScreen> createState() => _NinetyNineNamesScreenState();
}

class _NinetyNineNamesScreenState extends State<NinetyNineNamesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // ── Shimmer controller for Allah card ─────────────────────────
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _shimmerAnim = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ── Filter — first name (Allah) is always shown separately ────
  List<Map<String, String>> get _filtered {
    try {
      final all = names.skip(1).toList(); // skip index 0 = Allah
      if (_query.trim().isEmpty) return all;
      final q = _query.toLowerCase().trim();
      return all.where((e) {
        return (e['transliteration'] ?? '').toLowerCase().contains(q) ||
            (e['meaning'] ?? '').toLowerCase().contains(q) ||
            (e['arabic'] ?? '').contains(_query) ||
            (e['tafseer'] ?? '').toLowerCase().contains(q);
      }).toList();
    } catch (_) {
      return names.skip(1).toList();
    }
  }

  // Show Allah card in search only if query matches
  bool get _showAllahCard {
    if (_query.trim().isEmpty) return true;
    final q = _query.toLowerCase().trim();
    final first = names.isNotEmpty ? names[0] : null;
    if (first == null) return false;
    return (first['transliteration'] ?? '').toLowerCase().contains(q) ||
        (first['meaning'] ?? '').toLowerCase().contains(q) ||
        (first['arabic'] ?? '').contains(_query) ||
        (first['tafseer'] ?? '').toLowerCase().contains(q);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _query = '');
  }

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
    final inputFill = isDark ? AppTheme.darkInputFill : AppTheme.lightInputFill;
    final btnTextColor = isDark
        ? AppTheme.darkTextOnAccent
        : AppTheme.lightTextOnAccent;

    final filtered = _filtered;
    final allahEntry = names.isNotEmpty ? names[0] : null;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentColor, size: 20),
        title: Text(
          "99 Names of Allah",
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
          // ── Search ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: textPrimary,
              ),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: "Search by name, meaning or tafseer...",
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: textTertiary,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.search_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : GestureDetector(
                        onTap: _clearSearch,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.close_rounded,
                            color: textTertiary,
                            size: 18,
                          ),
                        ),
                      ),
                filled: true,
                fillColor: inputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: accentColor, width: 1.4),
                ),
              ),
            ),
          ),

          if (_query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Row(
                children: [
                  Text(
                    "${(_showAllahCard ? 1 : 0) + filtered.length} result${((_showAllahCard ? 1 : 0) + filtered.length) == 1 ? '' : 's'}",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: textTertiary,
                    ),
                  ),
                ],
              ),
            ),

          // ── List ───────────────────────────────────────────────
          Expanded(
            child: (!_showAllahCard && filtered.isEmpty)
                ? _EmptyState(
                    accentColor: accentColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onClear: _clearSearch,
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: (_showAllahCard ? 1 : 0) + filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      // ── Allah hero card at position 0 ──────────
                      if (_showAllahCard && index == 0) {
                        return allahEntry == null
                            ? const SizedBox.shrink()
                            : _AllahHeroCard(
                                entry: allahEntry,
                                shimmerAnim: _shimmerAnim,
                                accentColor: accentColor,
                                goldColor: goldColor,
                                btnTextColor: btnTextColor,
                                borderColor: borderColor,
                                isDark: isDark,
                              );
                      }

                      // ── Regular name cards ─────────────────────
                      final i = index - (_showAllahCard ? 1 : 0);
                      if (i < 0 || i >= filtered.length) {
                        return const SizedBox.shrink();
                      }
                      return _NameCard(
                        item: filtered[i],
                        index: i,
                        cardColor: cardColor,
                        accentColor: accentColor,
                        goldColor: goldColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        textTertiary: textTertiary,
                        borderColor: borderColor,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ALLAH HERO CARD — majestic, full-width, animated shimmer
// ═══════════════════════════════════════════════════════════════════

class _AllahHeroCard extends StatefulWidget {
  final Map<String, String> entry;
  final Animation<double> shimmerAnim;
  final Color accentColor, goldColor, btnTextColor, borderColor;
  final bool isDark;

  const _AllahHeroCard({
    required this.entry,
    required this.shimmerAnim,
    required this.accentColor,
    required this.goldColor,
    required this.btnTextColor,
    required this.borderColor,
    required this.isDark,
  });

  @override
  State<_AllahHeroCard> createState() => _AllahHeroCardState();
}

class _AllahHeroCardState extends State<_AllahHeroCard> {
  bool _expanded = false;

  String _f(String k) => widget.entry[k] ?? '';

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final gold = widget.goldColor;
    final btnTxt = widget.btnTextColor;
    final tafseer = _f('tafseer');

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      onLongPress: () {
        try {
          Clipboard.setData(
            ClipboardData(
              text:
                  "${_f('arabic')} — ${_f('transliteration')}\n${_f('meaning')}",
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Copied: ${_f('transliteration')}",
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              ),
              backgroundColor: accent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (_) {}
      },
      child: AnimatedBuilder(
        animation: widget.shimmerAnim,
        builder: (_, child) {
          // Rotating shimmer gradient
          final shimmerX = widget.shimmerAnim.value;
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment(shimmerX - 1, -1),
                end: Alignment(shimmerX + 1, 1),
                colors: widget.isDark
                    ? [
                        const Color(0xFF0D2B1A),
                        const Color(0xFF1A4A2E),
                        const Color(0xFF0D2B1A),
                      ]
                    : [
                        const Color(0xFF1A6B45),
                        const Color(0xFF0E4F30),
                        const Color(0xFF1A6B45),
                      ],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: Border.all(color: gold.withOpacity(0.35), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // ── Decorative geometric circles ─────────────────
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.goldColor.withOpacity(0.07),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.goldColor.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: btnTxt.withOpacity(0.04),
                  ),
                ),
              ),

              // ── Main content ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Number badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: btnTxt.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: btnTxt.withOpacity(0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        "الاسم الأول • Name #1",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: btnTxt.withOpacity(0.80),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── The Name: ٱللَّهُ ─────────────────────────
                    // Custom shimmer text paint
                    AnimatedBuilder(
                      animation: widget.shimmerAnim,
                      builder: (_, __) => ShaderMask(
                        shaderCallback: (bounds) {
                          final t = (widget.shimmerAnim.value + 2) / 4;
                          return LinearGradient(
                            colors: [
                              gold.withOpacity(0.70),
                              Colors.white,
                              gold,
                              Colors.white.withOpacity(0.85),
                              gold.withOpacity(0.70),
                            ],
                            stops: [
                              (t - 0.3).clamp(0.0, 1.0),
                              (t - 0.1).clamp(0.0, 1.0),
                              t.clamp(0.0, 1.0),
                              (t + 0.1).clamp(0.0, 1.0),
                              (t + 0.3).clamp(0.0, 1.0),
                            ],
                          ).createShader(bounds);
                        },
                        child: Text(
                          "ٱللَّهُ",
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 80,
                            fontWeight: FontWeight.w700,
                            color: Colors.white, // overridden by ShaderMask
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Gold ornament divider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _OrnamentDot(color: gold.withOpacity(0.40)),
                        const SizedBox(width: 8),
                        _OrnamentDot(color: gold.withOpacity(0.70)),
                        const SizedBox(width: 8),
                        Text("✦", style: TextStyle(fontSize: 14, color: gold)),
                        const SizedBox(width: 8),
                        _OrnamentDot(color: gold.withOpacity(0.70)),
                        const SizedBox(width: 8),
                        _OrnamentDot(color: gold.withOpacity(0.40)),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Transliteration
                    Text(
                      "Allah",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: btnTxt,
                        letterSpacing: 2.0,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Meaning
                    Text(
                      "The One True God · The Greatest Name",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: btnTxt.withOpacity(0.72),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Glory text in Arabic
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: btnTxt.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: btnTxt.withOpacity(0.18),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        "لَا إِلَٰهَ إِلَّا ٱللَّهُ",
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 22,
                          color: gold,
                          height: 1.8,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "There is no god but Allah",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: btnTxt.withOpacity(0.60),
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    // ── Expandable tafseer ───────────────────────
                    if (tafseer.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        child: _expanded
                            ? Column(
                                children: [
                                  Divider(
                                    color: btnTxt.withOpacity(0.18),
                                    thickness: 0.8,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    tafseer,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: btnTxt.withOpacity(0.78),
                                      height: 1.7,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: btnTxt.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: btnTxt.withOpacity(0.20),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          _expanded ? "Hide tafseer ▲" : "Read tafseer ▼",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: btnTxt.withOpacity(0.75),
                          ),
                        ),
                      ),
                    ],
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

// ── Tiny ornament dot ──────────────────────────────────────────────
class _OrnamentDot extends StatelessWidget {
  final Color color;
  const _OrnamentDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 4,
    height: 4,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  REGULAR NAME CARD
// ═══════════════════════════════════════════════════════════════════

class _NameCard extends StatefulWidget {
  final Map<String, String> item;
  final int index;
  final Color cardColor, accentColor, goldColor;
  final Color textPrimary, textSecondary, textTertiary, borderColor;

  const _NameCard({
    required this.item,
    required this.index,
    required this.cardColor,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderColor,
  });

  @override
  State<_NameCard> createState() => _NameCardState();
}

class _NameCardState extends State<_NameCard> {
  bool _expanded = false;
  String _f(String k) => widget.item[k] ?? '';

  Color _numColor() {
    try {
      final idx = int.tryParse(_f('index')) ?? (widget.index + 2);
      const hues = [0.44, 0.56, 0.62, 0.70, 0.78, 0.83];
      final hue = hues[idx % hues.length];
      return HSLColor.fromAHSL(1.0, hue * 360, 0.45, 0.45).toColor();
    } catch (_) {
      return widget.accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final numColor = _numColor();
    final tafseer = _f('tafseer');
    final hasTafseer = tafseer.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (hasTafseer) setState(() => _expanded = !_expanded);
      },
      onLongPress: () {
        try {
          Clipboard.setData(
            ClipboardData(
              text:
                  "${_f('arabic')} — ${_f('transliteration')}\n${_f('meaning')}",
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Copied: ${_f('transliteration')}",
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              ),
              backgroundColor: widget.accentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (_) {}
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: widget.borderColor, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Number badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: numColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: numColor.withOpacity(0.30),
                      width: 0.8,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _f('index').isEmpty ? "${widget.index + 2}" : _f('index'),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: numColor,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Name + meaning
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _f('transliteration'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: widget.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _f('meaning'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: widget.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Arabic
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _f('arabic'),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: widget.goldColor,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Tafseer
            if (hasTafseer) ...[
              const SizedBox(height: 8),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                child: _expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(
                            color: widget.borderColor,
                            thickness: 0.8,
                            height: 1,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 3,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: widget.accentColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tafseer,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: widget.textSecondary,
                                    height: 1.65,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _expanded ? "Hide ▲" : "Tafseer ▼",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: widget.accentColor.withOpacity(0.65),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final Color accentColor, textPrimary, textSecondary;
  final VoidCallback onClear;

  const _EmptyState({
    required this.accentColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: accentColor.withOpacity(0.40),
          ),
          const SizedBox(height: 14),
          Text(
            "No names found",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Try searching in Arabic or English",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accentColor.withOpacity(0.25),
                  width: 0.8,
                ),
              ),
              child: Text(
                "Clear search",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
