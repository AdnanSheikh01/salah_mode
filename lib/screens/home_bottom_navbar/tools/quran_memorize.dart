import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QuranMemoriseScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ayahs;
  final String surahName;

  const QuranMemoriseScreen({
    super.key,
    required this.ayahs,
    required this.surahName,
  });

  @override
  State<QuranMemoriseScreen> createState() => _QuranMemoriseScreenState();
}

class _QuranMemoriseScreenState extends State<QuranMemoriseScreen> {
  late int selectedSurah;
  late int currentAyahIndex;
  bool hideAyahMode = false;

  // 🔥 memorisation per surah
  final Map<int, Set<int>> memorisedBySurah = {};

  Set<int> get memorisedAyahs => memorisedBySurah[selectedSurah] ?? <int>{};

  void nextAyah() {
    if (currentAyahIndex < widget.ayahs.length - 1) {
      setState(() => currentAyahIndex++);
    }
  }

  void prevAyah() {
    if (currentAyahIndex > 0) {
      setState(() => currentAyahIndex--);
    }
  }

  void toggleMemorised() {
    final set = memorisedBySurah.putIfAbsent(selectedSurah, () => {});

    setState(() {
      if (set.contains(currentAyahIndex)) {
        set.remove(currentAyahIndex);
      } else {
        set.add(currentAyahIndex);
      }
    });
  }

  double get progress {
    if (widget.ayahs.isEmpty) return 0;
    return memorisedAyahs.length / widget.ayahs.length;
  }

  @override
  void initState() {
    super.initState();
    selectedSurah = widget.surahName.hashCode;
    currentAyahIndex = 0;
    memorisedBySurah[selectedSurah] = {};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          _progressCard(isDark),
          Expanded(child: _ayahCard(isDark)),
          _controls(),
        ],
      ),
    );
  }

  // 🌙 Progress Card
  Widget _progressCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.green.shade900, Colors.teal.shade900]
              : [Colors.green.shade300, Colors.teal.shade300],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                "Memorisation Progress",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: "Continue",
                icon: const Icon(Icons.play_circle_fill_rounded),
                onPressed: () {
                  Get.snackbar(
                    "Continue",
                    "Resuming from Ayah ${currentAyahIndex + 1}",
                  );
                },
              ),
              IconButton(
                tooltip: "Test Mode",
                icon: Icon(
                  hideAyahMode ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => hideAyahMode = !hideAyahMode);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white24,
          ),
          const SizedBox(height: 8),
          Text(
            "${memorisedAyahs.length} / ${widget.ayahs.length} Ayahs",
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // 📜 Ayah Card
  Widget _ayahCard(bool isDark) {
    final isMemorised = memorisedAyahs.contains(currentAyahIndex);
    final ayahNumber =
        widget.ayahs[currentAyahIndex]["ayahNumber"] ?? currentAyahIndex + 1;
    final showBismillahHeader = currentAyahIndex == 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(blurRadius: 12, color: Colors.black.withOpacity(.08)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showBismillahHeader) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.teal.shade600],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontFamily: 'UthmanicHafs',
                        ),
                      ),
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Ayah $ayahNumber",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  hideAyahMode
                      ? Column(
                          children: const [
                            Icon(Icons.psychology_alt_rounded, size: 48),
                            SizedBox(height: 12),
                            Text(
                              "Test yourself",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Recite the ayah from memory",
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : Directionality(
                          textDirection: TextDirection.rtl,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              (() {
                                String arabic =
                                    widget.ayahs[currentAyahIndex]["arabic"]
                                        as String;

                                // remove embedded bismillah when header is shown
                                if (showBismillahHeader) {
                                  arabic = arabic
                                      .replaceFirst(
                                        "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                                        "",
                                      )
                                      .trim();
                                }

                                return arabic;
                              })(),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 30,
                                height: 2.1,
                                fontFamily: 'UthmanicHafs',
                              ),
                            ),
                          ),
                        ),
                  // 🌐 English Translation
                  if (!hideAyahMode &&
                      widget.ayahs[currentAyahIndex]["english"] != null) ...[
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "${widget.ayahs[currentAyahIndex]["ayahNumber"] ?? currentAyahIndex + 1}. ${widget.ayahs[currentAyahIndex]["english"]}",
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: toggleMemorised,
                      icon: Icon(
                        isMemorised
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                      ),
                      label: Text(
                        isMemorised ? "Memorised" : "Mark as Memorised",
                      ),
                    ),
                  ),
                  if (hideAyahMode) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => hideAyahMode = false);
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text("Show Ayah"),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🎮 Controls
  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton(
            heroTag: "prev",
            onPressed: prevAyah,
            child: const Icon(Icons.arrow_back),
          ),
          FloatingActionButton.extended(
            heroTag: "play",
            onPressed: () {
              Get.snackbar("Audio", "Play recitation (connect API)");
            },
            icon: const Icon(Icons.volume_up),
            label: const Text("Play"),
          ),
          FloatingActionButton(
            heroTag: "next",
            onPressed: nextAyah,
            child: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}
