import 'package:flutter/material.dart';

import '../../data/app_repository.dart';

class RecipePickerSheet extends StatefulWidget {
  final AppRepository repository;

  const RecipePickerSheet({super.key, required this.repository});

  @override
  State<RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends State<RecipePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search recipes...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Recipe>>(
                stream: widget.repository.watchAllRecipes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final filtered = snapshot.data!
                      .where((r) => r.name.toLowerCase().contains(_query))
                      .toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No recipes found'));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final recipe = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(recipe.name[0].toUpperCase()),
                        ),
                        title: Text(recipe.name),
                        subtitle: recipe.description != null
                            ? Text(recipe.description!,
                                maxLines: 1, overflow: TextOverflow.ellipsis)
                            : null,
                        trailing: recipe.url != null
                            ? Icon(Icons.link,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () => Navigator.pop(context, recipe),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
