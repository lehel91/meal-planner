import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'measurement_unit.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Recipes, MealPlans, Ingredients, RecipeIngredients])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(ingredients);
            await m.createTable(recipeIngredients);
          }
        },
      );

  // ── Recipes ──────────────────────────────────────────────────────────────

  Stream<List<Recipe>> watchAllRecipes() =>
      (select(recipes)..orderBy([(r) => OrderingTerm.asc(r.name)])).watch();

  Future<int> insertRecipe(RecipesCompanion recipe) =>
      into(recipes).insert(recipe);

  Future<bool> updateRecipe(RecipesCompanion recipe) =>
      update(recipes).replace(recipe);

  Future<int> deleteRecipe(int id) =>
      (delete(recipes)..where((r) => r.id.equals(id))).go();

  // ── Meal plans ────────────────────────────────────────────────────────────

  Stream<List<MealPlanWithRecipe>> watchMealPlansForRange(
    DateTime start,
    DateTime end,
  ) {
    final query = (select(mealPlans)
          ..where((m) => m.date.isBetweenValues(start, end)))
        .join([innerJoin(recipes, recipes.id.equalsExp(mealPlans.recipeId))]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => MealPlanWithRecipe(
                  mealPlan: row.readTable(mealPlans),
                  recipe: row.readTable(recipes),
                ),
              )
              .toList(),
        );
  }

  Future<MealPlan?> getMealPlanForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return (select(mealPlans)..where((m) => m.date.equals(normalized)))
        .getSingleOrNull();
  }

  Future<void> setMealPlan(DateTime date, int recipeId) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final existing = await getMealPlanForDate(normalized);
    if (existing != null) {
      await (update(mealPlans)..where((m) => m.id.equals(existing.id)))
          .write(MealPlansCompanion(recipeId: Value(recipeId)));
    } else {
      await into(mealPlans).insert(MealPlansCompanion(
        date: Value(normalized),
        recipeId: Value(recipeId),
      ));
    }
  }

  Future<int> removeMealPlan(int id) =>
      (delete(mealPlans)..where((m) => m.id.equals(id))).go();

  // ── Ingredients ───────────────────────────────────────────────────────────

  Stream<List<Ingredient>> watchAllIngredients() =>
      (select(ingredients)..orderBy([(i) => OrderingTerm.asc(i.name)])).watch();

  Future<int> insertIngredient(IngredientsCompanion ingredient) =>
      into(ingredients).insert(ingredient);

  Future<bool> updateIngredient(IngredientsCompanion ingredient) =>
      update(ingredients).replace(ingredient);

  Future<int> deleteIngredient(int id) =>
      (delete(ingredients)..where((i) => i.id.equals(id))).go();

  // ── Recipe ingredients ────────────────────────────────────────────────────

  Stream<List<RecipeIngredientWithDetails>> watchIngredientsForRecipe(
    int recipeId,
  ) {
    final query = (select(recipeIngredients)
          ..where((ri) => ri.recipeId.equals(recipeId)))
        .join([
      innerJoin(
        ingredients,
        ingredients.id.equalsExp(recipeIngredients.ingredientId),
      )
    ]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => RecipeIngredientWithDetails(
                  recipeIngredient: row.readTable(recipeIngredients),
                  ingredient: row.readTable(ingredients),
                ),
              )
              .toList(),
        );
  }

  Future<int> addRecipeIngredient(RecipeIngredientsCompanion entry) =>
      into(recipeIngredients).insert(entry);

  Future<bool> updateRecipeIngredient(RecipeIngredientsCompanion entry) =>
      update(recipeIngredients).replace(entry);

  Future<int> removeRecipeIngredient(int id) =>
      (delete(recipeIngredients)..where((ri) => ri.id.equals(id))).go();

  Future<void> removeAllRecipeIngredients(int recipeId) =>
      (delete(recipeIngredients)
            ..where((ri) => ri.recipeId.equals(recipeId)))
          .go();

  Future<List<RecipeIngredientWithDetails>> getIngredientsForRecipe(
    int recipeId,
  ) {
    final query = (select(recipeIngredients)
          ..where((ri) => ri.recipeId.equals(recipeId)))
        .join([
      innerJoin(
        ingredients,
        ingredients.id.equalsExp(recipeIngredients.ingredientId),
      )
    ]);
    return query.get().then(
          (rows) => rows
              .map(
                (row) => RecipeIngredientWithDetails(
                  recipeIngredient: row.readTable(recipeIngredients),
                  ingredient: row.readTable(ingredients),
                ),
              )
              .toList(),
        );
  }

  Future<int> findOrCreateIngredient(String name) async {
    final existing = await (select(ingredients)
          ..where((i) => i.name.equals(name)))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    return into(ingredients).insert(IngredientsCompanion(name: Value(name)));
  }
}

class RecipeIngredientWithDetails {
  final RecipeIngredient recipeIngredient;
  final Ingredient ingredient;

  RecipeIngredientWithDetails({
    required this.recipeIngredient,
    required this.ingredient,
  });

  MeasurementUnit? get unit => recipeIngredient.unit;
  double? get quantity => recipeIngredient.quantity;
}

class MealPlanWithRecipe {
  final MealPlan mealPlan;
  final Recipe recipe;

  MealPlanWithRecipe({required this.mealPlan, required this.recipe});
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'meal_planner.db'));
    return NativeDatabase.createInBackground(file);
  });
}
