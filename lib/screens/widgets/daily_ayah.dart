import 'package:flutter/material.dart';

Widget dailyAyah(
  BuildContext context,
  VoidCallback dailyAyahRefresh,
  bool ayahLoading,
  String ayahText,
  String ayahRef,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    width: double.infinity,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withOpacity(.5),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.2)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "DAILY AYAH",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: dailyAyahRefresh,
              tooltip: "Refresh Ayah",
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (ayahLoading)
          Padding(
            padding: const EdgeInsets.all(12),
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 2,
            ),
          )
        else ...[
          Text(
            ayahText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(ayahRef, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );
}
