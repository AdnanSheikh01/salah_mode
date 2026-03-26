import 'package:flutter/material.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/quran/quran_memorise/quran_full_page.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/quran/quran_memorise/quran_imam_mode.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tools/quran/quran_memorise/quran_self.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

// ─────────────────────────────────────────────────────────────────
//  MODE ENUM
// ─────────────────────────────────────────────────────────────────

enum _MemoriseMode { withImam, selfMode, pageMode }

// ─────────────────────────────────────────────────────────────────
//  ROOT SCREEN — mode selector + dispatcher
// ─────────────────────────────────────────────────────────────────

class QuranMemoriseScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ayahs;
  final String surahName;
  final int surahNumber;

  const QuranMemoriseScreen({
    super.key,
    required this.ayahs,
    required this.surahName,
    required this.surahNumber,
  });

  @override
  State<QuranMemoriseScreen> createState() => _QuranMemoriseScreenState();
}

class _QuranMemoriseScreenState extends State<QuranMemoriseScreen> {
  _MemoriseMode? _selectedMode;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;
  Color get _card => _isDark ? AppTheme.darkCard : AppTheme.lightCard;
  Color get _accent => _isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
  Color get _gold => _isDark ? AppTheme.darkAccent : AppTheme.lightAccentGold;
  Color get _tp =>
      _isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
  Color get _ts =>
      _isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
  Color get _border => _isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
  Color get _btnTxt =>
      _isDark ? AppTheme.darkTextOnAccent : AppTheme.lightTextOnAccent;

  @override
  Widget build(BuildContext context) {
    if (widget.ayahs.isEmpty) {
      return Container(
        color: _bg,
        child: Center(
          child: Text(
            'No ayahs available.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _ts),
          ),
        ),
      );
    }

    // If mode selected, show the correct sub-screen
    if (_selectedMode != null) {
      return _buildModeScreen();
    }

    // Mode selector
    return Container(
      color: _bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Mode',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _tp,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'How would you like to memorise?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _ts,
                ),
              ),
              const SizedBox(height: 28),
              _ModeCard(
                icon: Icons.record_voice_over_rounded,
                title: 'Guided Repetition',
                subtitle:
                    'Imam recites each verse — you listen, then repeat one by one',
                accent: _accent,
                gold: _gold,
                card: _card,
                border: _border,
                tp: _tp,
                ts: _ts,
                btnTxt: _btnTxt,
                onTap: () =>
                    setState(() => _selectedMode = _MemoriseMode.withImam),
              ),
              const SizedBox(height: 14),
              _ModeCard(
                icon: Icons.self_improvement_rounded,
                title: 'Recall & Check',
                subtitle:
                    'Verse is hidden — recite from memory, then see how you did',
                accent: _accent,
                gold: _gold,
                card: _card,
                border: _border,
                tp: _tp,
                ts: _ts,
                btnTxt: _btnTxt,
                onTap: () =>
                    setState(() => _selectedMode = _MemoriseMode.selfMode),
              ),
              const SizedBox(height: 14),
              _ModeCard(
                icon: Icons.menu_book_rounded,
                title: 'Full Page Recitation',
                subtitle:
                    'Read a full page like a Quran — wrong words glow red as you go',
                accent: _accent,
                gold: _gold,
                card: _card,
                border: _border,
                tp: _tp,
                ts: _ts,
                btnTxt: _btnTxt,
                onTap: () =>
                    setState(() => _selectedMode = _MemoriseMode.pageMode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeScreen() {
    switch (_selectedMode!) {
      case _MemoriseMode.withImam:
        return ImamModeScreen(
          ayahs: widget.ayahs,
          surahName: widget.surahName,
          surahNumber: widget.surahNumber,
          onBack: () => setState(() => _selectedMode = null),
        );
      case _MemoriseMode.selfMode:
        return SelfModeScreen(
          ayahs: widget.ayahs,
          surahName: widget.surahName,
          surahNumber: widget.surahNumber,
          onBack: () => setState(() => _selectedMode = null),
        );
      case _MemoriseMode.pageMode:
        return PageModeScreen(
          ayahs: widget.ayahs,
          surahName: widget.surahName,
          surahNumber: widget.surahNumber,
          onBack: () => setState(() => _selectedMode = null),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────
//  MODE CARD WIDGET
// ─────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color accent, gold, card, border, tp, ts, btnTxt;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.gold,
    required this.card,
    required this.border,
    required this.tp,
    required this.ts,
    required this.btnTxt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withOpacity(0.25), width: 0.6),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: tp,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: ts,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: accent),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────

class ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final Color accent, btnTxt, border;
  final VoidCallback? onTap;

  const ActionBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.filled,
    required this.accent,
    required this.btnTxt,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: filled
              ? (enabled ? accent : accent.withOpacity(0.40))
              : accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: filled
              ? null
              : Border.all(color: accent.withOpacity(0.25), width: 0.8),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: filled ? btnTxt : accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: filled ? btnTxt : accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
