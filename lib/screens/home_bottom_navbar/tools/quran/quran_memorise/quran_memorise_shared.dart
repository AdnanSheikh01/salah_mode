import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:salah_mode/screens/utils/theme_data.dart';

// ─────────────────────────────────────────────────────────────────
//  MATCH RESULT  — public so all mode files can use it
// ─────────────────────────────────────────────────────────────────

class MatchResult {
  final double ratio;
  final List<bool> wordResults;
  final List<double> scores;
  const MatchResult(this.ratio, this.wordResults, this.scores);
}

mixin MemoriseHelpers<T extends StatefulWidget> on State<T> {
  // UI Helpers
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get bg => isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;

  Color get card => isDark ? AppTheme.darkCard : AppTheme.lightCard;

  Color get cardAlt => isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt;

  Color get accent => isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

  Color get gold => isDark ? AppTheme.darkAccent : AppTheme.lightAccentGold;

  Color get tp => isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

  Color get ts =>
      isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

  Color get border => isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

  Color get btnTxt =>
      isDark ? AppTheme.darkTextOnAccent : AppTheme.lightTextOnAccent;

  // Logic Constants
  static const double kPassThreshold = 0.82; // Adjust strictly
  static const double kWordThreshold = 0.80;

  static String bare(String s) => s
      .replaceAll(RegExp(r'[ؐ-ًؚ-ٰٟۖ-ۭـ‌‍]'), '') // Removes Harakat/Tashkeel
      .replaceAll(
        RegExp(r'[\u0622\u0623\u0625\u0671]'),
        '\u0627',
      ) // Alif normalization
      .replaceAll('\u0629', '\u0647') // Ta Marbuta -> Ha
      .replaceAll('\u0649', '\u064A') // Alif Maqsura -> Ya
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static int _editDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final prev = List.generate(b.length + 1, (i) => i);
    for (int i = 1; i <= a.length; i++) {
      final curr = [i, ...List.filled(b.length, 0)];
      for (int j = 1; j <= b.length; j++) {
        curr[j] = a[i - 1] == b[j - 1]
            ? prev[j - 1]
            : 1 +
                  [
                    prev[j],
                    curr[j - 1],
                    prev[j - 1],
                  ].reduce((x, y) => x < y ? x : y);
      }
      prev.setAll(0, curr);
    }
    return prev[b.length];
  }

  static double _wordSimilarity(String spoken, String correct) {
    if (correct.isEmpty) return spoken.isEmpty ? 1.0 : 0.0;
    if (spoken.isEmpty) return 0.0;
    final dist = _editDistance(spoken, correct);
    final maxLen = spoken.length > correct.length
        ? spoken.length
        : correct.length;
    return 1.0 - (dist / maxLen);
  }

  static MatchResult strictMatch(String spoken, String correct) {
    final cNorm = bare(correct);
    final sNorm = bare(spoken);
    final cWords = cNorm.split(' ').where((w) => w.isNotEmpty).toList();
    final sWords = sNorm.split(' ').where((w) => w.isNotEmpty).toList();

    // Fix: If actual verse exists but user said nothing/nonsense
    if (cWords.isEmpty) return const MatchResult(0.0, [], []);

    final emptyFail = MatchResult(
      0.0,
      List.filled(cWords.length, false),
      List.filled(cWords.length, 0.0),
    );

    if (sWords.isEmpty) return emptyFail;

    // Guard 1: Basic string similarity (stops completely different sentences)
    final fullSim = _wordSimilarity(sNorm, cNorm);
    if (fullSim < 0.25) return emptyFail;

    // Guard 2: Length ratio check
    final lengthRatio = sWords.length / cWords.length;
    if (lengthRatio < 0.45 || lengthRatio > 2.2) return emptyFail;

    final results = <bool>[];
    final scores = <double>[];
    int matched = 0;

    for (int i = 0; i < cWords.length; i++) {
      final sw = i < sWords.length ? sWords[i] : '';
      final sim = _wordSimilarity(sw, cWords[i]);
      final ok = sim >= kWordThreshold;
      results.add(ok);
      scores.add(sim);
      if (ok) matched++;
    }

    final totalForRatio = sWords.length > cWords.length
        ? sWords.length
        : cWords.length;
    final wordRatio = matched / totalForRatio;

    // Combine word-level and character-level scores
    double combined = (wordRatio * 0.75) + (fullSim * 0.25);

    // Final Hard Gate: If it's pure nonsense, don't let a few lucky characters pass
    if (combined < 0.4) combined = 0.0;

    return MatchResult(combined, results, scores);
  }

  static double wordOverlap(String spoken, String correct) =>
      strictMatch(spoken, correct).ratio;

  static String matchDetail(String spoken, String correct) {
    final m = strictMatch(spoken, correct);
    if (m.wordResults.isEmpty) return "No words recognized";
    final total = m.wordResults.length;
    final correctCount = m.wordResults.where((r) => r).length;
    return '$correctCount/$total words correct · ${(m.ratio * 100).round()}% score';
  }

  // ── Snackbar ────────────────────────────────────────────────────
  void showSnack(
    String title,
    String msg, {
    bool isError = false,
    bool isWarning = false,
  }) {
    if (!mounted) return;
    Get.snackbar(
      title,
      msg,
      backgroundColor: isError
          ? AppTheme.colorError
          : isWarning
          ? AppTheme.colorWarning
          : AppTheme.colorSuccess,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
    );
  }

  // ── Nav button — Opacity handles disabled state clearly ─────────
  Widget buildNavBtn({
    required bool enabled,
    required bool isNext,
    required VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withOpacity(0.25), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isNext) ...[
                Icon(Icons.arrow_back_ios_rounded, size: 13, color: accent),
                const SizedBox(width: 4),
              ],
              Text(
                isNext ? 'Next' : 'Prev',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              if (isNext) ...[
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 13, color: accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
