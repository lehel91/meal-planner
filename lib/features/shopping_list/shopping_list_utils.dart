import '../../data/database.dart';
import '../../data/measurement_unit.dart';

class ShoppingItem {
  final String name;
  final double? quantity;
  final MeasurementUnit? unit;

  ShoppingItem({required this.name, this.quantity, this.unit});
}

List<ShoppingItem> aggregateShoppingList(
  List<MealPlanWithRecipe> mealPlans,
  Map<int, List<RecipeIngredientWithDetails>> ingredientsByRecipe,
) {
  final aggregated = <String, ShoppingItem>{};

  for (final mp in mealPlans) {
    final items = ingredientsByRecipe[mp.recipe.id] ?? [];
    for (final item in items) {
      final key = '${item.ingredient.name}__${item.unit?.name ?? 'none'}';
      final existing = aggregated[key];
      if (existing != null) {
        if (existing.quantity != null && item.quantity != null) {
          aggregated[key] = ShoppingItem(
            name: existing.name,
            quantity: existing.quantity! + item.quantity!,
            unit: existing.unit,
          );
        }
      } else {
        aggregated[key] = ShoppingItem(
          name: item.ingredient.name,
          quantity: item.quantity,
          unit: item.unit,
        );
      }
    }
  }

  return aggregated.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}

String formatShoppingItemLabel(ShoppingItem item) {
  final qty = item.quantity != null
      ? (item.quantity! % 1 == 0
          ? item.quantity!.toInt().toString()
          : double.parse(item.quantity!.toStringAsFixed(4)).toString())
      : '';
  final unit = item.unit?.abbreviation ?? '';
  return [qty, unit, item.name].where((s) => s.isNotEmpty).join(' ');
}

String formatIngredientLabel(RecipeIngredientWithDetails item, int count) {
  if (item.quantity == null && item.unit == null) return item.ingredient.name;
  final rawQty = item.quantity != null ? item.quantity! * count : null;
  final qty = rawQty != null
      ? (rawQty % 1 == 0
          ? rawQty.toInt().toString()
          : double.parse(rawQty.toStringAsFixed(4)).toString())
      : '';
  final unit = item.unit?.abbreviation ?? '';
  return '$qty${unit.isNotEmpty ? ' $unit' : ''} ${item.ingredient.name}'.trim();
}
