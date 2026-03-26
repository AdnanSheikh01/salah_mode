import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/home_bottom_navbar/tasbih/custom.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key});

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> {
  // ── Data ───────────────────────────────────────────────────────
  final List<Map<String, String>> tasbihList = [
    {
      "name": "Subhanallah",
      "arabic": "سُبْحَانَ ٱللَّٰهِ",
      "translation": "Glory be to Allah",
    },
    {
      "name": "Alhamdulillah",
      "arabic": "ٱلْحَمْدُ لِلَّٰهِ",
      "translation": "All praise is due to Allah",
    },
    {
      "name": "Allahu Akbar",
      "arabic": "ٱللَّٰهُ أَكْبَرُ",
      "translation": "Allah is the Greatest",
    },
    {"name": "+ Custom", "arabic": "", "translation": ""},
  ];

  Map<String, int> tasbihCounts = {
    'Subhanallah': 0,
    'Alhamdulillah': 0,
    'Allahu Akbar': 0,
  };
  Map<String, int> tasbihTargets = {};

  String selectedTasbih = 'Subhanallah';
  bool guidedMode = false;
  String? guidedTasbih;
  int? guidedTarget;
  int target = 33;

  final AudioPlayer _player = AudioPlayer();

  // ── Audio ──────────────────────────────────────────────────────
  Future<void> _playTasbihSound() async {
    try {
      await _player.play(AssetSource('beep.mp3'));
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  // ── Counter logic ──────────────────────────────────────────────
  void _increment() {
    HapticFeedback.lightImpact();
    setState(() {
      final current = tasbihCounts[selectedTasbih] ?? 0;
      final localTarget = guidedMode
          ? (guidedTarget ?? target)
          : (selectedTasbih == 'Allahu Akbar'
                ? 34
                : (tasbihTargets[selectedTasbih] ?? target));
      final next = current + 1;
      tasbihCounts[selectedTasbih] = next;

      if (next == localTarget) {
        _playTasbihSound();
        HapticFeedback.heavyImpact();
      }

      if (next >= localTarget) {
        if (guidedMode) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) Get.back(result: true);
          });
        } else {
          Future.delayed(const Duration(milliseconds: 120), () {
            if (mounted) setState(() => tasbihCounts[selectedTasbih] = 0);
          });
        }
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() => tasbihCounts[selectedTasbih] = 0);
  }

  // ── Init ───────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args != null && args is Map) {
      guidedMode = args['guided'] == true;
      guidedTasbih = args['tasbih'];
      guidedTarget = args['target'];
      if (guidedMode && guidedTasbih != null) {
        selectedTasbih = guidedTasbih!;
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final goldColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccentGold;
    final textPrimary = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    final currentCount = tasbihCounts[selectedTasbih] ?? 0;
    final int displayTarget = selectedTasbih == 'Allahu Akbar'
        ? 34
        : (tasbihTargets[selectedTasbih] ?? target);
    final double progress = currentCount / displayTarget;

    // Explicit button style — bypasses theme pill shape
    final _btnStyle = ButtonStyle(
      elevation: MaterialStateProperty.all(0),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(vertical: 14),
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: guidedMode
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: accentColor,
                  size: 20,
                ),
                onPressed: () {
                  Get.snackbar(
                    "Complete Dhikr",
                    "Please complete the tasbih before leaving.",
                    margin: const EdgeInsets.all(16),
                    borderRadius: 14,
                    backgroundColor: isDark
                        ? AppTheme.darkCardAlt
                        : AppTheme.lightCardAlt,
                    colorText: textPrimary,
                    duration: const Duration(seconds: 2),
                  );
                },
              )
            : null,
        title: Text(
          "Digital Tasbih",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Tasbih selector chips ──────────────────────────
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: tasbihList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tasbih = tasbihList[index];
                  final name = tasbih["name"]!;
                  final selected = name == selectedTasbih;

                  return GestureDetector(
                    onTap: () async {
                      if (guidedMode) {
                        Get.snackbar(
                          "Locked",
                          "Please complete the current dhikr first.",
                          margin: const EdgeInsets.all(16),
                          borderRadius: 14,
                          backgroundColor: isDark
                              ? AppTheme.darkCardAlt
                              : AppTheme.lightCardAlt,
                          colorText: textPrimary,
                          duration: const Duration(seconds: 2),
                        );
                        return;
                      }
                      if (name == '+ Custom') {
                        final result = await Get.to(
                          () => const RecommendedDuaPage(),
                        );
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            tasbihList.insert(tasbihList.length - 1, {
                              "name": result['name'],
                              "arabic": result['arabic'] ?? result['name'],
                              "translation": result['translation'] ?? "",
                            });
                            tasbihCounts[result['name']] = 0;
                            tasbihTargets[result['name']] = result['target'];
                            selectedTasbih = result['name'];
                          });
                        }
                      } else {
                        setState(() => selectedTasbih = name);
                      }
                    },
                    onLongPress: () {
                      if (![
                        'Subhanallah',
                        'Alhamdulillah',
                        'Allahu Akbar',
                        '+ Custom',
                      ].contains(name)) {
                        setState(() {
                          tasbihCounts.remove(name);
                          tasbihList.removeWhere((t) => t["name"] == name);
                          selectedTasbih = 'Subhanallah';
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? accentColor
                            : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected
                              ? accentColor
                              : (isDark
                                    ? AppTheme.darkBorder
                                    : AppTheme.lightBorder),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? (isDark
                                        ? AppTheme.darkTextOnAccent
                                        : AppTheme.lightTextOnAccent)
                                  : textSecondary,
                            ),
                          ),

                          // Delete icon for custom entries
                          if (![
                            'Subhanallah',
                            'Alhamdulillah',
                            'Allahu Akbar',
                            '+ Custom',
                          ].contains(name)) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _showDeleteDialog(
                                context,
                                name,
                                isDark,
                                textPrimary,
                                accentColor,
                                _btnStyle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 15,
                                color: selected
                                    ? (isDark
                                          ? AppTheme.darkTextOnAccent
                                          : AppTheme.lightTextOnAccent)
                                    : textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Selected tasbih detail card ────────────────────
            Builder(
              builder: (context) {
                final tasbih = tasbihList.firstWhere(
                  (t) => t["name"] == selectedTasbih,
                  orElse: () => {"name": "", "arabic": "", "translation": ""},
                );
                final arabic = tasbih["arabic"] ?? "";
                final name = tasbih["name"] ?? "";
                final translation = tasbih["translation"] ?? "";

                if (name.isEmpty || name == "+ Custom") return const SizedBox();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkBorder
                            : AppTheme.lightBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      children: [
                        if (arabic.isNotEmpty) ...[
                          Text(
                            arabic,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: goldColor,
                              height: 1.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        if (translation.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            translation,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const Spacer(),

            // ── Counter circle ─────────────────────────────────
            Expanded(
              flex: 4,
              child: Center(
                child: GestureDetector(
                  onTap: _increment,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress ring
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final size = constraints.maxWidth * 0.62;
                          return SizedBox(
                            width: size,
                            height: size,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 7,
                              backgroundColor:
                                  (isDark
                                          ? AppTheme.darkBorder
                                          : AppTheme.lightBorder)
                                      .withOpacity(0.5),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                accentColor,
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                          );
                        },
                      ),

                      // Count + hint
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Tap to count",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textSecondary.withOpacity(0.55),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "$currentCount",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 58,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              height: 1,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (selectedTasbih != '+ Custom')
                            Text(
                              "/ ${selectedTasbih == 'Allahu Akbar' ? 34 : displayTarget}",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: accentColor.withOpacity(0.55),
                              ),
                            ),
                        ],
                      ),

                      // Reset button
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _reset,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.colorError,
                              border: Border.all(
                                color: AppTheme.colorError.withOpacity(0.3),
                                width: 0,
                              ),
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  // ── Delete confirm dialog ──────────────────────────────────────
  Future<void> _showDeleteDialog(
    BuildContext context,
    String name,
    bool isDark,
    Color textPrimary,
    Color accentColor,
    ButtonStyle btnStyle,
  ) async {
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    final confirm = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withOpacity(0.25),
                    width: 0.8,
                  ),
                ),
                child: Icon(Icons.mosque_rounded, color: accentColor, size: 26),
              ),

              const SizedBox(height: 16),

              Text(
                "Remove Tasbih",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Remove "$name" from your dhikr list?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  // Cancel
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(result: false),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: accentColor.withOpacity(0.22),
                            width: 0.8,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Remove
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(result: true),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.colorError,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Remove",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      setState(() {
        tasbihCounts.remove(name);
        tasbihTargets.remove(name);
        tasbihList.removeWhere((t) => t["name"] == name);
        selectedTasbih = 'Subhanallah';
      });
    }
  }
}
