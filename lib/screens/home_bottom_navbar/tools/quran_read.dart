import 'package:flutter/material.dart';
import 'package:salah_mode/screens/widgets/bismillah_header.dart';
import 'package:salah_mode/screens/widgets/info_items.dart';
import 'package:salah_mode/screens/widgets/mini_chip.dart';

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
  bool get _showBismillah => widget.surahNumber != 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(.18),
                  Theme.of(context).colorScheme.primary.withOpacity(.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(.30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(.25),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // 🌟 Surah title line
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Surah Overview",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 📊 Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    infoItem(context, "Ayahs", widget.totalAyahs.toString()),
                    infoItem(context, "Words", widget.totalWords.toString()),
                    infoItem(
                      context,
                      "Type",
                      widget.revelationType.isEmpty
                          ? "-"
                          : widget.revelationType,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Insert Bismillah header above ayah list
          bismillahHeader(_showBismillah),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.ayahs.length,
              itemBuilder: (context, index) {
                final actualIndex = index;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.surface.withOpacity(.95),
                        Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              miniChip(
                                'Juz ${widget.ayahs[actualIndex]["juz"] ?? '-'}',
                                Icons.menu_book,
                                context,
                              ),
                              const SizedBox(width: 6),
                              miniChip(
                                'Ruku ${widget.ayahs[actualIndex]["ruku"] ?? '-'}',
                                Icons.bookmark,
                                context,
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Ayah ${widget.ayahs[actualIndex]["ayahNumber"] ?? actualIndex + 1}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Clean duplicated Bismillah for surahs that already show header
                      Builder(
                        builder: (context) {
                          String arabicText =
                              widget.ayahs[actualIndex]["arabic"] ?? "";

                          // 🔥 Remove embedded Bismillah for surahs that already show header
                          if (_showBismillah &&
                              widget.surahNumber != 1 &&
                              widget.ayahs[actualIndex]["ayahNumber"] == 1) {
                            arabicText = arabicText
                                .replaceFirst(
                                  "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                                  "",
                                )
                                .trim();
                          }

                          return Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              arabicText,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontSize: 28,
                                height: 2.2,
                                fontFamily: 'UthmanicHafs',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${widget.ayahs[actualIndex]["ayahNumber"] ?? actualIndex + 1}. ${widget.ayahs[actualIndex]["english"]}",
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(.85),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
