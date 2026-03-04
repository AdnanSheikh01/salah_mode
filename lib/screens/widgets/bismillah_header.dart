import 'package:flutter/material.dart';

Widget bismillahHeader(bool showBismillah) {
  if (!showBismillah) return const SizedBox();

  return Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.green.shade400, Colors.teal.shade600],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Center(
      child: Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        style: TextStyle(
          fontFamily: 'Uthmanic',
          fontSize: 26,
          color: Colors.white,
          height: 2,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
