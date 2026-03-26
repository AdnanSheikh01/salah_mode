import 'package:flutter/material.dart';

import 'package:salah_mode/data/duas/all_duas.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/duas/details_duas.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key});

  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen>
    with SingleTickerProviderStateMixin {
  String _search = '';
  Set<String> _favourites = {};
  bool _showFavsOnly = false;
  String? _activeCategory; // null = All
  bool favsLoaded = false;

  final TextEditingController _searchCtrl = TextEditingController();

  static const _kFavKey = 'duas_favourites';

  // ── All unique categories ─────────────────────────────────────
  late final List<String> _categories;

  @override
  void initState() {
    super.initState();
    _categories = duas.map((d) => (d['category'] ?? 'General')).toSet().toList()
      ..sort();
    _loadFavourites();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  PERSISTENCE
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadFavourites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kFavKey) ?? [];
      if (mounted) {
        setState(() {
          _favourites = raw.toSet();
          favsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Dua fav load error: $e");
      if (mounted) setState(() => favsLoaded = true);
    }
  }

  Future<void> _toggleFavourite(String duaName) async {
    setState(() {
      if (_favourites.contains(duaName)) {
        _favourites.remove(duaName);
      } else {
        _favourites.add(duaName);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kFavKey, _favourites.toList());
    } catch (e) {
      debugPrint("Dua fav save error: $e");
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  FILTER LOGIC
  // ─────────────────────────────────────────────────────────────

  Map<String, List<Map<String, String>>> get _groupedDuas {
    final query = _search.toLowerCase().trim();

    // Step 1: start from all or favourites
    Iterable<Map<String, dynamic>> pool = _showFavsOnly
        ? duas.where((d) => _favourites.contains(d['name']))
        : duas;

    // Step 2: filter by active category tab
    if (_activeCategory != null) {
      pool = pool.where((d) => d['category'] == _activeCategory);
    }

    // Step 3: text search
    if (query.isNotEmpty) {
      final matchedCats = pool
          .where((d) => (d['category'] ?? '').toLowerCase().contains(query))
          .map((d) => d['category'])
          .toSet();

      pool = pool.where((d) {
        if (matchedCats.contains(d['category'])) return true;
        return (d['name'] ?? '').toLowerCase().contains(query) ||
            (d['when'] ?? '').toLowerCase().contains(query) ||
            (d['arabic'] ?? '').contains(query);
      });
    }

    // Step 4: group by category
    final grouped = <String, List<Map<String, String>>>{};
    for (final d in pool) {
      final cat = (d['category'] ?? 'General') as String;
      grouped
          .putIfAbsent(cat, () => [])
          .add(Map<String, String>.from(d as Map));
    }
    return grouped;
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

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
    final inputFill = isDark ? AppTheme.darkInputFill : AppTheme.lightInputFill;
    final btnTextColor = isDark
        ? AppTheme.darkTextOnAccent
        : AppTheme.lightTextOnAccent;

    final grouped = _groupedDuas;
    final totalFiltered = grouped.values.fold(0, (s, l) => s + l.length);

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
              "Daily Duas",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            Text(
              "الأدعية اليومية",
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
          // Favourites toggle
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _showFavsOnly = !_showFavsOnly),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _showFavsOnly
                      ? AppTheme.colorError.withOpacity(0.12)
                      : accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _showFavsOnly
                        ? AppTheme.colorError.withOpacity(0.30)
                        : accentColor.withOpacity(0.20),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showFavsOnly
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 15,
                      color: _showFavsOnly ? AppTheme.colorError : accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _favourites.isEmpty ? "Saved" : "${_favourites.length}",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _showFavsOnly
                            ? AppTheme.colorError
                            : accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: _SearchBar(
              controller: _searchCtrl,
              accentColor: accentColor,
              inputFill: inputFill,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textTertiary: textTertiary,
              borderColor: borderColor,
              onChanged: (v) => setState(() => _search = v),
              onClear: () {
                _searchCtrl.clear();
                setState(() => _search = '');
              },
            ),
          ),
          SizedBox(height: 8),

          // ── Category chips ───────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _categories.length + 1, // +1 for "All"
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final isAll = i == 0;
                final cat = isAll ? null : _categories[i - 1];
                final label = isAll ? 'All' : cat!;
                final sel = _activeCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _activeCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? accentColor : cardAltColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? accentColor : borderColor,
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          color: sel ? btnTextColor : textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // ── Stats row ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Row(
              children: [
                Text(
                  _showFavsOnly
                      ? "$totalFiltered saved dua${totalFiltered == 1 ? '' : 's'}"
                      : "Total $totalFiltered dua${totalFiltered == 1 ? '' : 's'
                                  " available"}",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: textTertiary,
                  ),
                ),
                const Spacer(),
                if (_search.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _search = '');
                    },
                    child: Text(
                      "Clear",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── List ─────────────────────────────────────────────────
          Expanded(
            child: grouped.isEmpty
                ? _EmptyState(
                    showFavsOnly: _showFavsOnly,
                    search: _search,
                    accentColor: accentColor,
                    goldColor: goldColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onClearSearch: () {
                      _searchCtrl.clear();
                      setState(() {
                        _search = '';
                        _showFavsOnly = false;
                      });
                    },
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: grouped.length,
                    itemBuilder: (_, catIdx) {
                      final category = grouped.keys.elementAt(catIdx);
                      final catDuas = grouped[category]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category header
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 10),
                            child: Row(
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
                                  category,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "${catDuas.length}",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Dua tiles
                          ...List.generate(catDuas.length, (i) {
                            final dua = catDuas[i];
                            final name = dua['name'] ?? '';
                            final isFav = _favourites.contains(name);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _DuaTile(
                                dua: dua,
                                isFav: isFav,
                                cardColor: cardColor,
                                accentColor: accentColor,
                                goldColor: goldColor,
                                borderColor: borderColor,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                textTertiary: textTertiary,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DuaDetailScreen(dua: dua),
                                    ),
                                  );
                                },
                                onFavTap: () => _toggleFavourite(name),
                              ),
                            );
                          }),
                        ],
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
//  SEARCH BAR  (StatefulWidget — preserves focus on parent rebuild)
// ═══════════════════════════════════════════════════════════════════

class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Color accentColor,
      inputFill,
      textPrimary,
      textSecondary,
      textTertiary,
      borderColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.accentColor,
    required this.inputFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderColor,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCtrlChanged);
  }

  void _onCtrlChanged() {
    final has = widget.controller.text.isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCtrlChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: widget.textPrimary,
      ),
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: "Search dua by name, category or occasion...",
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: widget.textSecondary,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(
            Icons.search_rounded,
            size: 20,
            color: widget.accentColor.withOpacity(0.60),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        suffixIcon: _hasText
            ? GestureDetector(
                onTap: widget.onClear,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: widget.textTertiary,
                  ),
                ),
              )
            : null,
        filled: true,
        fillColor: widget.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: widget.borderColor, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: widget.accentColor, width: 1.4),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DUA TILE
// ═══════════════════════════════════════════════════════════════════

class _DuaTile extends StatelessWidget {
  final Map<String, String> dua;
  final bool isFav;
  final Color cardColor, accentColor, goldColor, borderColor;
  final Color textPrimary, textSecondary, textTertiary;
  final VoidCallback onTap, onFavTap;

  const _DuaTile({
    required this.dua,
    required this.isFav,
    required this.cardColor,
    required this.accentColor,
    required this.goldColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.onTap,
    required this.onFavTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withOpacity(0.20),
                  width: 0.8,
                ),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: accentColor,
              ),
            ),

            const SizedBox(width: 12),

            // Name + when
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dua['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dua['when'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Fav + chevron
            Row(
              children: [
                GestureDetector(
                  onTap: onFavTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey(isFav),
                        size: 18,
                        color: isFav ? AppTheme.colorError : textTertiary,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: textTertiary,
                ),
              ],
            ),
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
  final bool showFavsOnly;
  final String search;
  final Color accentColor, goldColor, textPrimary, textSecondary;
  final VoidCallback onClearSearch;

  const _EmptyState({
    required this.showFavsOnly,
    required this.search,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final isFavEmpty = showFavsOnly && search.isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isFavEmpty ? "🤲" : "🔍",
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              isFavEmpty ? "No Saved Duas Yet" : "No Duas Found",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFavEmpty
                  ? "Tap ♡ on any dua to save it for quick access"
                  : "Try a different search term or category",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            if (!isFavEmpty) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onClearSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Clear Filters",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkTextOnAccent
                          : AppTheme.lightTextOnAccent,
                    ),
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
