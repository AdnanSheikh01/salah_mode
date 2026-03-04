import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:salah_mode/screens/widgets/surah_tile.dart';

class SurahListPage extends StatefulWidget {
  const SurahListPage({super.key});

  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";
  bool _isLoading = true;
  List<_Surah> _surahs = [];

  @override
  void initState() {
    super.initState();
    _fetchSurahs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSurahs() async {
    try {
      final response = await http.get(
        Uri.parse("https://api.alquran.cloud/v1/surah"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data["data"];

        _surahs = list
            .map(
              (e) => _Surah(
                number: e["number"],
                name: "${e["name"]} • ${e["englishName"]}",
                verses: e["numberOfAyahs"],
                type: e["revelationType"],
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint("Surah fetch error: $e");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<_Surah> get _filteredSurahs {
    final source = _surahs;

    if (_query.isEmpty) return source;

    return source
        .where(
          (s) =>
              s.name.toLowerCase().contains(_query.toLowerCase()) ||
              s.number.toString() == _query,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 🌟 Premium AppBar
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            foregroundColor: Theme.of(context).colorScheme.onBackground,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                "Holy Quran 📖",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor,
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🔍 Premium Search
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).inputDecorationTheme.fillColor ??
                          Colors.white.withOpacity(.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      decoration: InputDecoration(
                        icon: Icon(
                          Icons.search,
                          color: Theme.of(
                            context,
                          ).colorScheme.onBackground.withOpacity(.6),
                        ),
                        hintText: "Search Surah by name or number...",
                        hintStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onBackground.withOpacity(.6),
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (v) {
                        setState(() => _query = v);
                      },
                    ),
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),

          // 📖 Surah List
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 30),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (_isLoading) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  }

                  if (_filteredSurahs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text(
                          "No Surah found",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onBackground.withOpacity(.6),
                          ),
                        ),
                      ),
                    );
                  }

                  final surah = _filteredSurahs[index];
                  return surahTile(surah);
                },
                childCount: _filteredSurahs.isEmpty
                    ? 1
                    : _filteredSurahs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= DATA MODEL =================
class _Surah {
  final int number;
  final String name;
  final int verses;
  final String type;

  const _Surah({
    required this.number,
    required this.name,
    required this.verses,
    required this.type,
  });
}
