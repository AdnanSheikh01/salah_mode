import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key});

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> {
  final List<String> tasbihList = [
    'Subhanallah',
    'Alhamdulillah',
    'Allahu Akbar',
    '+ Custom',
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

  Future<void> _playTasbihSound() async {
    try {
      await _player.play(AssetSource('beep.mp3'));
    } catch (_) {
      // fallback to system sound if asset missing
      SystemSound.play(SystemSoundType.alert);
    }
  }

  // 🔧 Replace your current beep logic inside _increment() with this

  void _increment() {
    setState(() {
      final current = tasbihCounts[selectedTasbih] ?? 0;

      final int localTarget = guidedMode
          ? (guidedTarget ?? target)
          : (selectedTasbih == 'Allahu Akbar'
                ? 34
                : (tasbihTargets[selectedTasbih] ?? target));

      final next = current + 1;
      tasbihCounts[selectedTasbih] = next;

      // 🔔 Custom tasbih sound at target
      if (next == localTarget) {
        _playTasbihSound();
        HapticFeedback.heavyImpact();
      }

      // Auto reset after limit
      if (next >= localTarget) {
        if (guidedMode) {
          /// return to Daily Dhikr page
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              Get.back(result: true);
            }
          });
        } else {
          /// normal free tasbih behaviour
          Future.delayed(const Duration(milliseconds: 120), () {
            if (mounted) {
              setState(() {
                tasbihCounts[selectedTasbih] = 0;
              });
            }
          });
        }
      }
    });

    HapticFeedback.lightImpact();
  }

  void _reset() {
    setState(() {
      tasbihCounts[selectedTasbih] = 0;
    });
  }

  @override
  void initState() {
    super.initState();

    /// If opened from Daily Dhikr page
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
  Widget build(BuildContext context) {
    final currentCount = tasbihCounts[selectedTasbih] ?? 0;
    final int displayTarget = selectedTasbih == 'Allahu Akbar'
        ? 34
        : (tasbihTargets[selectedTasbih] ?? target);
    final progress = currentCount / displayTarget;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: guidedMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (guidedMode) {
                    Get.snackbar(
                      "Complete Dhikr",
                      "Please complete the tasbih before leaving.",
                      margin: const EdgeInsets.all(12),
                      borderRadius: 10,
                      backgroundColor: Colors.orange,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );
                  } else {
                    Get.back();
                  }
                },
              )
            : null,

        /// 🕌 Title
        title: Text(
          "Digital Tasbih",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// 📿 Tasbih Selector
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final name = tasbihList[index];
                  final selected = name == selectedTasbih;

                  return GestureDetector(
                    onTap: () async {
                      /// 🚫 Block changing tasbih in guided mode
                      if (guidedMode) {
                        Get.snackbar(
                          "Locked Tasbih",
                          "Please complete the current dhikr first.",
                          margin: const EdgeInsets.all(12),
                          borderRadius: 10,
                          backgroundColor: Colors.orange,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 2),
                        );
                        return;
                      }
                      if (name == '+ Custom') {
                        final nameController = TextEditingController();
                        final targetController = TextEditingController();

                        final result = await showDialog<Map<String, String>>(
                          context: context,
                          builder: (context) {
                            final theme = Theme.of(context);

                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              backgroundColor: theme.colorScheme.surface,
                              title: Text(
                                'Add Custom Tasbih',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: nameController,
                                    style: theme.textTheme.bodyMedium,
                                    decoration: InputDecoration(
                                      labelText: 'Tasbih name',
                                      filled: true,
                                      fillColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: targetController,
                                    keyboardType: TextInputType.number,
                                    style: theme.textTheme.bodyMedium,
                                    decoration: InputDecoration(
                                      labelText: 'Target count',
                                      filled: true,
                                      fillColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              actionsPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                12,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context, {
                                    'name': nameController.text,
                                    'target': targetController.text,
                                  }),
                                  child: const Text('Add'),
                                ),
                              ],
                            );
                          },
                        );

                        if (result != null &&
                            result['name']!.trim().isNotEmpty &&
                            int.tryParse(result['target'] ?? '') != null &&
                            int.parse(result['target']!) > 0) {
                          final newName = result['name']!.trim();
                          final parsedTarget = int.tryParse(
                            result['target'] ?? '',
                          );

                          setState(() {
                            tasbihList.insert(tasbihList.length - 1, newName);
                            tasbihCounts[newName] = 0;
                            tasbihTargets[newName] = parsedTarget!;
                            selectedTasbih = newName;
                          });
                        }
                      } else {
                        setState(() {
                          selectedTasbih = name;
                        });
                      }
                    },
                    child: GestureDetector(
                      onLongPress: () {
                        if (![
                          'Subhanallah',
                          'Alhamdulillah',
                          'Allahu Akbar',
                          '+ Custom',
                        ].contains(name)) {
                          setState(() {
                            tasbihCounts.remove(name);
                            tasbihList.remove(name);
                            selectedTasbih = 'Subhanallah';
                          });
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.green
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: selected
                                  ? Colors.black
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemCount: tasbihList.length,
              ),
            ),

            const Spacer(),

            /// 🔵 Counter Circle
            Expanded(
              flex: 4,
              child: Center(
                child: GestureDetector(
                  onTap: _increment,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 240,
                        width: 240,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.green,
                          ),
                        ),
                      ),

                      /// Count Text + Tap Hint
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Tap to count",
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "$currentCount",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            selectedTasbih == '+ Custom'
                                ? ''
                                : (selectedTasbih == 'Allahu Akbar'
                                      ? '/ 34'
                                      : '/ $displayTarget'),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),

            /// 🔘 Reset Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _reset,
                  icon: Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    "Reset",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
