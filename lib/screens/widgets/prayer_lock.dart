import 'package:flutter/material.dart';

Widget prayerLockCard(
  BuildContext context,
  bool prayerLockEnabled,
  int lockMinutes,
  Function(bool) onToggle,
  Function(int) onDurationChange,
) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withOpacity(.6),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lock_clock,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Prayer Focus Mode",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Switch(
              value: prayerLockEnabled,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (v) => onToggle(v),
            ),
          ],
        ),
        if (prayerLockEnabled) ...[
          Divider(
            color: Theme.of(context).dividerColor.withOpacity(.2),
            height: 24,
          ),
          Text(
            "Lock phone for (mins) after Adhan:",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [5, 10, 15, 20, 30]
                .map(
                  (e) =>
                      _durationChip(context, e, onDurationChange, lockMinutes),
                )
                .toList(),
          ),
        ],
      ],
    ),
  );
}

Widget _durationChip(
  BuildContext context,
  int minutes,
  Function(int) onSelected,
  int lockMinutes,
) {
  final isSelected = lockMinutes == minutes;
  return ChoiceChip(
    label: Text("$minutes min"),
    selected: isSelected,
    onSelected: (_) => onSelected(minutes),
    selectedColor: Theme.of(context).colorScheme.primary,
    labelStyle: TextStyle(
      color: isSelected
          ? Colors.white
          : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(.7),
    ),
    backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(.4),
  );
}
