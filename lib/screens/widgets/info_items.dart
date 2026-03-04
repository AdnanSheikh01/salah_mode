import 'package:flutter/material.dart';

Widget infoItem(BuildContext context, String title, String value) {
  return Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        title,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onBackground.withOpacity(.7),
        ),
      ),
    ],
  );
}
