import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';

class MadhabSelectionScreen extends StatefulWidget {
  final Madhab currentMadhab;
  final ValueChanged<Madhab>? onChanged;

  const MadhabSelectionScreen({
    super.key,
    this.currentMadhab = Madhab.shafi,
    this.onChanged,
  });

  @override
  State<MadhabSelectionScreen> createState() => _MadhabSelectionScreenState();
}

class _MadhabSelectionScreenState extends State<MadhabSelectionScreen> {
  late Madhab _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentMadhab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        foregroundColor: Colors.white,
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "Select Madhab",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose your juristic method for prayer times",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),

            _madhabTile(
              context,
              title: "Hanafi",
              subtitle: "Later Asr time",
              value: Madhab.hanafi,
            ),

            const SizedBox(height: 16),

            _madhabTile(
              context,
              title: "Shafi",
              subtitle: "Earlier Asr time",
              value: Madhab.shafi,
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  widget.onChanged?.call(_selected);
                  Navigator.pop(context);
                },
                child: const Text(
                  "Save",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _madhabTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Madhab value,
  }) {
    final selected = _selected == value;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() => _selected = value);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(.18)
              : Colors.white.withOpacity(.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.white.withOpacity(.08),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: Colors.white70),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
