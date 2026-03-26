import 'package:flutter/material.dart';

class SmartCompanionScreen extends StatefulWidget {
  const SmartCompanionScreen({super.key});

  @override
  State<SmartCompanionScreen> createState() => _SmartCompanionScreenState();
}

class _SmartCompanionScreenState extends State<SmartCompanionScreen> {
  // Mock data for features
  final List<String> _niyyahVault = [
    "To pray with sincerity",
    "To reach the mosque early",
  ];

  final List<Map<String, dynamic>> _tools = [
    {
      "title": "Focus Tracker",
      "icon": Icons.sensors,
      "desc": "Track Salah stillness",
    },
    {
      "title": "Niyyah Vault",
      "icon": Icons.lock_outline,
      "desc": "Set your intentions",
    },
    {
      "title": "Khushu Insights",
      "icon": Icons.analytics,
      "desc": "Prayer quality map",
    },
    {
      "title": "Dua Planner",
      "icon": Icons.edit_note,
      "desc": "AI-suggested Duas",
    },
    {
      "title": "Global Echo",
      "icon": Icons.public,
      "desc": "Join collective Dhikr",
    },
    {
      "title": "Daily Wisdom",
      "icon": Icons.lightbulb,
      "desc": "Contextual Hadith",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Companion"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSmartAssistantCard(Theme.of(context)),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: _tools.length,
              itemBuilder: (context, index) => _toolCard(_tools[index]),
            ),
          ],
        ),
      ),
    );
  }

  // --- Logic Handler for all Features ---
  void _handleToolTap(BuildContext context, String title) {
    switch (title) {
      case "Focus Tracker":
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Focus Tracker"),
            content: const Text(
              "Place your phone on the prayer mat. The app will simulate tracking stillness during Salah.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Stillness tracking started")),
                  );
                },
                child: const Text("Start"),
              ),
            ],
          ),
        );
        break;

      case "Niyyah Vault":
        _showNiyyahVault(context);
        break;

      case "Khushu Insights":
        showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text("Khushu Insights"),
            content: Text(
              "Your last prayer focus score was 85%. Try slowing your recitation and reflecting on the meanings.",
            ),
          ),
        );
        break;

      case "Dua Planner":
        showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text("Dua Planner"),
            content: Text(
              "Suggested Duas today:\n• Dua for patience\n• Dua for guidance\n• Dua for gratitude",
            ),
          ),
        );
        break;

      case "Global Echo":
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "You joined thousands of Muslims doing Dhikr worldwide.",
            ),
          ),
        );
        break;

      case "Daily Wisdom":
        showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text("Daily Wisdom"),
            content: Text(
              "The Prophet ﷺ said: 'The most beloved deeds to Allah are those that are consistent even if small.'",
            ),
          ),
        );
        break;
    }
  }

  void _showNiyyahVault(BuildContext context) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Your Niyyah Vault",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              ..._niyyahVault.map(
                (n) => ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(n),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: "Add new intention",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    setState(() {
                      _niyyahVault.add(controller.text);
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Save Niyyah"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI Components
  Widget _buildSmartAssistantCard(ThemeData theme) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Row(
      children: [
        Icon(Icons.auto_awesome, color: Colors.white, size: 40),
        SizedBox(width: 16),
        Text(
          "AI Spiritual Mentor",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  Widget _toolCard(Map<String, dynamic> tool) => InkWell(
    onTap: () => _handleToolTap(context, tool["title"]),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(tool["icon"], color: Theme.of(context).colorScheme.primary),
          const Spacer(),
          Text(
            tool["title"],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            tool["desc"],
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}
