import 'package:flutter/material.dart';

import 'package:salah_mode/screens/home_bottom_navbar/tools/quran_details.dart';

Widget surahTile(dynamic surah) {
  return StatefulBuilder(
    builder: (context, setLocal) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuranDetailsScreen(
                surahNumber: surah.number,
                surahName: surah.name,
                totalAyahs: surah.verses,
                revelationType: surah.type,
              ),
            ),
          );
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: 1,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface.withOpacity(.9),
                  Theme.of(context).colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // 🔢 Number badge
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(.35),
                        Theme.of(context).colorScheme.primary.withOpacity(.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    surah.number.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // 📜 Surah info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          final parts = surah.name.split("•");
                          final arabic = parts.isNotEmpty
                              ? parts.first.trim()
                              : surah.name;
                          final english = parts.length > 1
                              ? parts.last.trim()
                              : "";

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                arabic,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              if (english.isNotEmpty)
                                Text(
                                  english,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onBackground,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${surah.verses} verses • ${surah.type}",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onBackground.withOpacity(.6),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.play_circle_fill,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
