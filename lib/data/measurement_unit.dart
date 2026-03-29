enum MeasurementUnit {
  // Weight
  gram('g'),
  kilogram('kg'),
  ounce('oz'),
  pound('lb'),

  // Volume
  milliliter('ml'),
  liter('l'),
  teaspoon('tsp'),
  tablespoon('tbsp'),
  fluidOunce('fl oz'),
  cup('cup'),

  // Countable / discrete
  piece('pc'),
  slice('slice'),
  clove('clove'),
  strip('strip'),
  sheet('sheet'),
  can('can'),
  bunch('bunch'),
  head('head'),
  stalk('stalk'),
  sprig('sprig'),
  leaf('leaf'),

  // Approximate / seasoning
  pinch('pinch'),
  dash('dash'),
  toTaste('to taste');

  const MeasurementUnit(this.abbreviation);
  final String abbreviation;
}
