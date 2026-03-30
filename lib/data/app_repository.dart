import 'database.dart';
import 'measurement_unit.dart';

export 'database.dart'
    show
        Ingredient,
        MealPlan,
        MealPlanWithRecipe,
        Recipe,
        RecipeIngredientWithDetails;

abstract class AppRepository {
  // ── Recipes ────────────────────────────────────────────────────────────────

  Stream<List<Recipe>> watchAllRecipes();

  Future<int> insertRecipe({
    required String name,
    String? description,
    String? url,
  });

  Future<void> updateRecipe({
    required int id,
    required String name,
    String? description,
    String? url,
  });

  Future<void> deleteRecipe(int id);

  // ── Meal plans ─────────────────────────────────────────────────────────────

  Stream<List<MealPlanWithRecipe>> watchMealPlansForRange(
    DateTime start,
    DateTime end,
  );

  Future<void> setMealPlan(DateTime date, int recipeId);

  Future<void> removeMealPlan(int id);

  // ── Ingredients ────────────────────────────────────────────────────────────

  Stream<List<Ingredient>> watchAllIngredients();

  Future<int> findOrCreateIngredient(String name);

  // ── Recipe ingredients ─────────────────────────────────────────────────────

  Stream<List<RecipeIngredientWithDetails>> watchIngredientsForRecipe(
    int recipeId,
  );

  Future<List<RecipeIngredientWithDetails>> getIngredientsForRecipe(
    int recipeId,
  );

  Future<void> addRecipeIngredient({
    required int recipeId,
    required int ingredientId,
    double? quantity,
    MeasurementUnit? unit,
  });

  Future<void> removeAllRecipeIngredients(int recipeId);
}
