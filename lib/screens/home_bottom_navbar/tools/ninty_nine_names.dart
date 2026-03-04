import 'package:flutter/material.dart';
import 'package:salah_mode/screens/widgets/names.dart';

class NinetyNineNamesScreen extends StatefulWidget {
  const NinetyNineNamesScreen({super.key});

  @override
  State<NinetyNineNamesScreen> createState() => _NinetyNineNamesScreenState();
}

class _NinetyNineNamesScreenState extends State<NinetyNineNamesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String query = "";

  List<Map<String, String>> get filteredNames {
    if (query.isEmpty) return names;
    return names.where((e) {
      return e["transliteration"]!.toLowerCase().contains(
            query.toLowerCase(),
          ) ||
          e["meaning"]!.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "99 Names of Allah",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔍 Premium Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: "Search names...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => query = "");
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          // 📜 Names list
          Expanded(
            child: filteredNames.isEmpty
                ? const Center(child: Text("No names found"))
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredNames.length,
                    itemBuilder: (context, index) {
                      final item = filteredNames[index];
                      final originalIndex = names.indexOf(item);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: theme.colorScheme.surface,

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.05),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              child: Text("${originalIndex + 1}"),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item["transliteration"]!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item["meaning"]!,
                                    style: TextStyle(color: theme.hintColor),
                                  ),
                                ],
                              ),
                            ),

                            Text(
                              item["arabic"]!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
