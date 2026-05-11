import 'package:flutter_test/flutter_test.dart';
import 'package:meal_planner/data/database.dart';
import 'package:meal_planner/data/measurement_unit.dart';
import 'package:meal_planner/features/shopping_list/shopping_list_utils.dart';

// ── Test helpers ──────────────────────────────────────────────────────────────

RecipeIngredientWithDetails _item(
  String name, {
  double? quantity,
  MeasurementUnit? unit,
  int id = 1,
  int recipeId = 1,
}) {
  return RecipeIngredientWithDetails(
    recipeIngredient: RecipeIngredient(
      id: id,
      recipeId: recipeId,
      ingredientId: id,
      quantity: quantity,
      unit: unit,
    ),
    ingredient: Ingredient(id: id, name: name),
  );
}

MealPlanWithRecipe _plan(int recipeId, String recipeName) {
  return MealPlanWithRecipe(
    mealPlan: MealPlan(
      id: recipeId,
      date: DateTime(2025, 1, recipeId),
      recipeId: recipeId,
    ),
    recipe: Recipe(
      id: recipeId,
      name: recipeName,
      createdAt: DateTime(2025),
    ),
  );
}

// ── aggregateShoppingList ─────────────────────────────────────────────────────

void main() {
  group('aggregateShoppingList', () {
    test('returns empty list for empty input', () {
      expect(aggregateShoppingList([], {}), isEmpty);
    });

    test('returns empty list when recipe has no ingredients', () {
      final plans = [_plan(1, 'Pasta')];
      final result = aggregateShoppingList(plans, {1: []});
      expect(result, isEmpty);
    });

    test('returns single item unchanged', () {
      final plans = [_plan(1, 'Pasta')];
      final ingredients = {
        1: [_item('Tomato', quantity: 2, unit: MeasurementUnit.piece)],
      };
      final result = aggregateShoppingList(plans, ingredients);
      expect(result, hasLength(1));
      expect(result.first.name, 'Tomato');
      expect(result.first.quantity, 2);
      expect(result.first.unit, MeasurementUnit.piece);
    });

    test('aggregates quantities for same ingredient and unit across plans', () {
      final plans = [_plan(1, 'Pasta'), _plan(2, 'Soup')];
      final ingredients = {
        1: [_item('Onion', quantity: 1, unit: MeasurementUnit.piece)],
        2: [_item('Onion', quantity: 2, unit: MeasurementUnit.piece, id: 2, recipeId: 2)],
      };
      final result = aggregateShoppingList(plans, ingredients);
      expect(result, hasLength(1));
      expect(result.first.quantity, 3);
    });

    test('does not aggregate same ingredient with different units', () {
      final plans = [_plan(1, 'Pasta'), _plan(2, 'Soup')];
      final ingredients = {
        1: [_item('Flour', quantity: 200, unit: MeasurementUnit.gram)],
        2: [_item('Flour', quantity: 1, unit: MeasurementUnit.kilogram, id: 2, recipeId: 2)],
      };
      final result = aggregateShoppingList(plans, ingredients);
      expect(result, hasLength(2));
    });

    test('does not aggregate when one entry has null quantity', () {
      final plans = [_plan(1, 'Pasta'), _plan(2, 'Soup')];
      final ingredients = {
        1: [_item('Salt', unit: MeasurementUnit.pinch)],
        2: [_item('Salt', quantity: 1, unit: MeasurementUnit.pinch, id: 2, recipeId: 2)],
      };
      final result = aggregateShoppingList(plans, ingredients);
      // null quantity entry survives but quantity is not summed
      expect(result, hasLength(1));
      expect(result.first.quantity, isNull);
    });

    test('result is sorted alphabetically by name', () {
      final plans = [_plan(1, 'Pasta')];
      final ingredients = {
        1: [
          _item('Zucchini', id: 1),
          _item('Apple', id: 2),
          _item('Milk', id: 3),
        ],
      };
      final result = aggregateShoppingList(plans, ingredients);
      final names = result.map((i) => i.name).toList();
      expect(names, ['Apple', 'Milk', 'Zucchini']);
    });

    test('skips recipe ids not present in ingredientsByRecipe', () {
      final plans = [_plan(1, 'Pasta'), _plan(2, 'Soup')];
      final ingredients = {
        1: [_item('Tomato', quantity: 1)],
        // recipe 2 is absent from the map
      };
      final result = aggregateShoppingList(plans, ingredients);
      expect(result, hasLength(1));
    });

    test('aggregates decimal quantities correctly', () {
      final plans = [_plan(1, 'Pasta'), _plan(2, 'Soup')];
      final ingredients = {
        1: [_item('Oil', quantity: 0.5, unit: MeasurementUnit.tablespoon)],
        2: [_item('Oil', quantity: 0.5, unit: MeasurementUnit.tablespoon, id: 2, recipeId: 2)],
      };
      final result = aggregateShoppingList(plans, ingredients);
      expect(result.first.quantity, closeTo(1.0, 0.0001));
    });
  });

  // ── formatShoppingItemLabel ─────────────────────────────────────────────────

  group('formatShoppingItemLabel', () {
    test('formats integer quantity without decimal point', () {
      final item = ShoppingItem(name: 'Tomato', quantity: 2, unit: MeasurementUnit.piece);
      expect(formatShoppingItemLabel(item), '2 pc Tomato');
    });

    test('formats decimal quantity', () {
      final item = ShoppingItem(name: 'Oil', quantity: 0.5, unit: MeasurementUnit.tablespoon);
      expect(formatShoppingItemLabel(item), '0.5 tbsp Oil');
    });

    test('omits quantity when null', () {
      final item = ShoppingItem(name: 'Salt', unit: MeasurementUnit.pinch);
      expect(formatShoppingItemLabel(item), 'pinch Salt');
    });

    test('omits unit when null', () {
      final item = ShoppingItem(name: 'Egg', quantity: 3);
      expect(formatShoppingItemLabel(item), '3 Egg');
    });

    test('returns only name when quantity and unit are both null', () {
      final item = ShoppingItem(name: 'Pepper');
      expect(formatShoppingItemLabel(item), 'Pepper');
    });
  });

  // ── formatIngredientLabel ───────────────────────────────────────────────────

  group('formatIngredientLabel', () {
    test('returns name only when quantity and unit are both null', () {
      final item = _item('Pepper');
      expect(formatIngredientLabel(item, 1), 'Pepper');
    });

    test('formats with unit and quantity', () {
      final item = _item('Milk', quantity: 2, unit: MeasurementUnit.cup);
      expect(formatIngredientLabel(item, 1), '2 cup Milk');
    });

    test('multiplies quantity by count', () {
      final item = _item('Egg', quantity: 2, unit: MeasurementUnit.piece);
      expect(formatIngredientLabel(item, 3), '6 pc Egg');
    });

    test('formats whole number result without decimal', () {
      final item = _item('Flour', quantity: 1.5, unit: MeasurementUnit.cup);
      expect(formatIngredientLabel(item, 2), '3 cup Flour');
    });

    test('formats decimal result correctly', () {
      final item = _item('Oil', quantity: 0.5, unit: MeasurementUnit.tablespoon);
      expect(formatIngredientLabel(item, 1), '0.5 tbsp Oil');
    });

    test('shows unit even when quantity is null', () {
      final item = _item('Salt', unit: MeasurementUnit.pinch);
      expect(formatIngredientLabel(item, 2), 'pinch Salt');
    });

    test('handles quantity-only item (no unit)', () {
      final item = _item('Egg', quantity: 1);
      expect(formatIngredientLabel(item, 4), '4 Egg');
    });
  });
}
