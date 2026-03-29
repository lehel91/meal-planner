import 'package:drift/drift.dart';

import 'measurement_unit.dart';

class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get url => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class MealPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get recipeId => integer().references(Recipes, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {date},
      ];
}

class Ingredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class RecipeIngredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeId => integer().references(Recipes, #id)();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  RealColumn get quantity => real().nullable()();
  IntColumn get unit => intEnum<MeasurementUnit>().nullable()();
}
