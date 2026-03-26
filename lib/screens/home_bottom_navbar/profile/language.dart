import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language_code');

    if (saved != null) {
      setState(() => _selectedLanguageCode = saved);
      Get.updateLocale(Locale(saved));
    }
  }

  Future<void> _saveLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('language_code', code);

    setState(() {
      _selectedLanguageCode = code;
    });

    Get.updateLocale(Locale(code));
  }

  String _selectedLanguageCode = "en";

  final List<Map<String, String>> _languages = const [
    {"name": "English", "native": "English", "code": "en"},
    {"name": "Urdu", "native": "اردو", "code": "ur"},
    {"name": "Hindi", "native": "हिन्दी", "code": "hi"},
    {"name": "Spanish", "native": "Español", "code": "es"},
    {"name": "Indonesian", "native": "Bahasa Indonesia", "code": "id"},
    {"name": "Turkish", "native": "Türkçe", "code": "tr"},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: Get.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.tertiary,
            theme.colorScheme.background,
            theme.colorScheme.onBackground,
          ],

          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          centerTitle: true,
          title: Text(
            "Language",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Choose your preferred language",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(.75),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .3,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _languages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lang = _languages[index];
                    final isSelected = _selectedLanguageCode == lang["code"];

                    return _languageTile(
                      context,
                      title: lang["name"]!,
                      native: lang["native"]!,
                      selected: isSelected,
                      onTap: () {
                        final code = lang["code"]!;
                        _saveLanguage(code);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageTile(
    BuildContext context, {
    required String title,
    required String native,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(.18),
                    Theme.of(context).colorScheme.primary.withOpacity(.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(.3),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.language,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(.7),
              size: 26,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    native,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(.65),
                    ),
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
