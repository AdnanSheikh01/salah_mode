import 'package:flutter/material.dart';

import 'package:salah_mode/screens/home_bottom_navbar/tools/quran/quran_details.dart';

Widget surahTile(BuildContext context, dynamic surah) {
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
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              color: Theme.of(context).colorScheme.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
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
                    final english = parts.length > 1 ? parts.last.trim() : "";

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          arabic,
                          textDirection: TextDirection.rtl,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (english.isNotEmpty)
                          Text(
                            english,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 3),
                Text(
                  "${surah.verses} verses • ${surah.type}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 18,
          ),
        ],
      ),
    ),
  );
}
