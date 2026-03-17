import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Recipes, MealPlans])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

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
