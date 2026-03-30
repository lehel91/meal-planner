import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/app_repository.dart';
import '../../data/measurement_unit.dart';
import '../pdf/pdf_service.dart';

class ShoppingListScreen extends StatefulWidget {
  final AppRepository repository;

  const ShoppingListScreen({super.key, required this.repository});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  // Meal plan IDs the user has explicitly turned off (all on by default)
  final Set<int> _deselected = {};

  // Ingredients per recipe ID, loaded lazily
  final Map<int, List<RecipeIngredientWithDetails>> _ingredientsByRecipe = {};

  // Checked-off ingredient keys: 'recipeId_recipeIngredientId'
  final Set<String> _checked = {};

  // Tracks the last plans list to avoid redundant ingredient fetches
  List<MealPlanWithRecipe>? _lastPlans;

  DateTime get _start =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  DateTime get _end => _start.add(const Duration(days: 29));

  Future<void> _loadIngredients(List<MealPlanWithRecipe> plans) async {
    for (final mp in plans) {
      final id = mp.recipe.id;
      if (!_ingredientsByRecipe.containsKey(id)) {
        final list = await widget.repository.getIngredientsForRecipe(id);
        if (mounted) setState(() => _ingredientsByRecipe[id] = list);
      }
    }
  }

  Future<void> _exportPdf(List<MealPlanWithRecipe> selectedPlans) async {
    if (selectedPlans.isEmpty) return;

    final days = selectedPlans.map((mp) => mp.mealPlan.date).toList()..sort();

    final ingredientsByRecipe = <int, List<RecipeIngredientWithDetails>>{};
    for (final mp in selectedPlans) {
      final id = mp.recipe.id;
      if (!ingredientsByRecipe.containsKey(id)) {
        ingredientsByRecipe[id] = _ingredientsByRecipe[id] ??
            await widget.repository.getIngredientsForRecipe(id);
      }
    }

    await PdfService.generateAndShare(days, selectedPlans, ingredientsByRecipe);
  }

  String _checkedKey(int recipeId, int recipeIngredientId) =>
      '${recipeId}_$recipeIngredientId';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        centerTitle: false,
      ),
      body: StreamBuilder<List<MealPlanWithRecipe>>(
        stream: widget.repository.watchMealPlansForRange(_start, _end),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allPlans = snapshot.data!;

          // Load ingredients whenever the plans list changes
          if (!identical(_lastPlans, allPlans)) {
            _lastPlans = allPlans;
            _loadIngredients(allPlans);
          }

          if (allPlans.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No meals planned',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Add meals to your plan first',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }

          final selectedPlans = allPlans
              .where((mp) => !_deselected.contains(mp.mealPlan.id))
              .toList();

          // Unique recipes in chronological order + how many times each appears
          final recipeCounts = <int, int>{};
          final orderedRecipes = <Recipe>[];
          for (final mp in selectedPlans) {
            recipeCounts[mp.recipe.id] =
                (recipeCounts[mp.recipe.id] ?? 0) + 1;
            if (recipeCounts[mp.recipe.id] == 1) {
              orderedRecipes.add(mp.recipe);
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DayChips(
                plans: allPlans,
                deselected: _deselected,
                onToggle: (id) => setState(() {
                  if (_deselected.contains(id)) {
                    _deselected.remove(id);
                  } else {
                    _deselected.add(id);
                  }
                }),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      selectedPlans.isEmpty
                          ? 'No days selected'
                          : '${selectedPlans.length} day${selectedPlans.length == 1 ? '' : 's'} selected',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                    const Spacer(),
                    if (selectedPlans.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _exportPdf(selectedPlans),
                        icon: const Icon(Icons.picture_as_pdf_outlined,
                            size: 16),
                        label: const Text('Export PDF'),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: selectedPlans.isEmpty
                    ? const Center(
                        child: Text('No days selected',
                            style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: orderedRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = orderedRecipes[index];
                          return _RecipeGroup(
                            recipe: recipe,
                            count: recipeCounts[recipe.id]!,
                            ingredients: _ingredientsByRecipe[recipe.id],
                            checked: _checked,
                            onToggle: (key) => setState(() {
                              if (_checked.contains(key)) {
                                _checked.remove(key);
                              } else {
                                _checked.add(key);
                              }
                            }),
                            checkedKey: _checkedKey,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayChips extends StatelessWidget {
  final List<MealPlanWithRecipe> plans;
  final Set<int> deselected;
  final ValueChanged<int> onToggle;

  const _DayChips({
    required this.plans,
    required this.deselected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: plans.map((mp) {
          final selected = !deselected.contains(mp.mealPlan.id);
          final label =
              '${DateFormat('E d MMM').format(mp.mealPlan.date)}  ·  ${mp.recipe.name}';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => onToggle(mp.mealPlan.id),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecipeGroup extends StatelessWidget {
  final Recipe recipe;
  final int count;
  final List<RecipeIngredientWithDetails>? ingredients;
  final Set<String> checked;
  final ValueChanged<String> onToggle;
  final String Function(int recipeId, int recipeIngredientId) checkedKey;

  const _RecipeGroup({
    required this.recipe,
    required this.count,
    required this.ingredients,
    required this.checked,
    required this.onToggle,
    required this.checkedKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 3),
          child: Row(
            children: [
              Text(
                recipe.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (count > 1) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '×$count',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (ingredients == null)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: LinearProgressIndicator(),
          )
        else if (ingredients!.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('No ingredients added',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          )
        else
          ...ingredients!.map((item) {
            final key = checkedKey(recipe.id, item.recipeIngredient.id);
            final isChecked = checked.contains(key);
            return CheckboxListTile(
              value: isChecked,
              onChanged: (_) => onToggle(key),
              title: Text(
                _formatIngredient(item),
                style: isChecked
                    ? const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      )
                    : null,
              ),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            );
          }),
      ],
    );
  }

  String _formatIngredient(RecipeIngredientWithDetails item) {
    if (item.quantity == null && item.unit == null) return item.ingredient.name;
    final rawQty =
        item.quantity != null ? item.quantity! * count : null;
    final qty = rawQty != null
        ? (rawQty % 1 == 0
            ? rawQty.toInt().toString()
            : double.parse(rawQty.toStringAsFixed(4)).toString())
        : '';
    final unit = item.unit?.abbreviation ?? '';
    return '$qty${unit.isNotEmpty ? ' $unit' : ''} ${item.ingredient.name}'
        .trim();
  }
}
