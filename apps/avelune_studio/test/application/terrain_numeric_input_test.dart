import 'package:avelune_studio/features/terrains/application/terrain_numeric_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'terrain numeric input accepts trimmed decimal points and French commas',
    () {
      expect(terrainFiniteNumber(' 1,5 '), 1.5);
      expect(terrainFiniteNumber('0,125'), .125);
      expect(terrainFiniteNumber('-0,375'), -.375);
      expect(terrainFiniteNumber('-2.25'), -2.25);
      expect(terrainFiniteNumber('0,2'), .2);
    },
  );

  test(
    'terrain numeric input rejects nonfinite values and incomplete input',
    () {
      for (final raw in ['NaN', 'Infinity', '-Infinity', '', ' ', '1,2,3']) {
        expect(terrainFiniteNumber(raw), isNull, reason: raw);
      }
    },
  );
}
