import 'package:flutter_test/flutter_test.dart';
import 'package:meal_planner/data/measurement_unit.dart';

void main() {
  group('MeasurementUnit', () {
    test('every unit has a non-empty abbreviation', () {
      for (final unit in MeasurementUnit.values) {
        expect(unit.abbreviation, isNotEmpty,
            reason: '${unit.name} has an empty abbreviation');
      }
    });

    test('abbreviations are unique', () {
      final abbreviations = MeasurementUnit.values.map((u) => u.abbreviation);
      final unique = abbreviations.toSet();
      expect(unique.length, MeasurementUnit.values.length,
          reason: 'Duplicate abbreviations found');
    });

    test('spot-check common abbreviations', () {
      expect(MeasurementUnit.gram.abbreviation, 'g');
      expect(MeasurementUnit.kilogram.abbreviation, 'kg');
      expect(MeasurementUnit.teaspoon.abbreviation, 'tsp');
      expect(MeasurementUnit.tablespoon.abbreviation, 'tbsp');
      expect(MeasurementUnit.liter.abbreviation, 'l');
      expect(MeasurementUnit.milliliter.abbreviation, 'ml');
      expect(MeasurementUnit.cup.abbreviation, 'cup');
      expect(MeasurementUnit.piece.abbreviation, 'pc');
    });
  });
}
