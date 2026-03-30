import 'package:drift/drift.dart' show Value;

import 'app_repository.dart';
import 'database.dart';
import 'measurement_unit.dart';

class DriftRepository implements AppRepository {
  final AppDatabase _db;

  DriftRepository(this._db);

  // ── Recipes ────────────────────────────────────────────────────────────────

  @override
  Stream<List<Recipe>> watchAllRecipes() => _db.watchAllRecipes();

  @override
  Future<int> insertRecipe({
    required String name,
    String? description,
    String? url,
  }) =>
      _db.insertRecipe(RecipesCompanion(
        name: Value(name),
        description: Value(description),
        url: Value(url),
      ));

  @override
  Future<void> updateRecipe({
    required int id,
    required String name,
    String? description,
    String? url,
  }) =>
      _db.updateRecipe(RecipesCompanion(
        id: Value(id),
        name: Value(name),
        description: Value(description),
        url: Value(url),
      ));

  @override
  Future<void> deleteRecipe(int id) => _db.deleteRecipe(id);

  // ── Meal plans ─────────────────────────────────────────────────────────────

  @override
  Stream<List<MealPlanWithRecipe>> watchMealPlansForRange(
    DateTime start,
    DateTime end,
  ) =>
      _db.watchMealPlansForRange(start, end);

  @override
  Future<void> setMealPlan(DateTime date, int recipeId) =>
      _db.setMealPlan(date, recipeId);

  @override
  Future<void> removeMealPlan(int id) => _db.removeMealPlan(id);

  // ── Ingredients ────────────────────────────────────────────────────────────

  @override
  Stream<List<Ingredient>> watchAllIngredients() => _db.watchAllIngredients();

  @override
  Future<int> findOrCreateIngredient(String name) =>
      _db.findOrCreateIngredient(name);

  // ── Recipe ingredients ─────────────────────────────────────────────────────

  @override
  Stream<List<RecipeIngredientWithDetails>> watchIngredientsForRecipe(
    int recipeId,
  ) =>
      _db.watchIngredientsForRecipe(recipeId);

  @override
  Future<List<RecipeIngredientWithDetails>> getIngredientsForRecipe(
    int recipeId,
  ) =>
      _db.getIngredientsForRecipe(recipeId);

  @override
  Future<void> addRecipeIngredient({
    required int recipeId,
    required int ingredientId,
    double? quantity,
    MeasurementUnit? unit,
  }) =>
      _db.addRecipeIngredient(RecipeIngredientsCompanion(
        recipeId: Value(recipeId),
        ingredientId: Value(ingredientId),
        quantity: Value(quantity),
        unit: Value(unit),
      ));

  @override
  Future<void> removeAllRecipeIngredients(int recipeId) =>
      _db.removeAllRecipeIngredients(recipeId);
}
