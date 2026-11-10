import 'package:avelune_studio/features/resources/application/border_pattern_associations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a contour names the pieces it still needs before publication', () {
    final incomplete = BorderPatternAssociations(assigned: ['lineStraight']);
    expect(incomplete.countLabel, '1 / 3 familles de pièces associées');
    expect(
      incomplete.statusLabel,
      'Pièces manquantes avant publication : extrémités, angles.',
    );
    final withCap = BorderPatternAssociations(
      assigned: ['lineStraight', 'lineCap'],
    );
    expect(
      withCap.statusLabel,
      'Pièces manquantes avant publication : angles.',
    );
  });

  test('only the explicit straight mode completes without corners', () {
    final complete = BorderPatternAssociations(
      assigned: ['lineStraight', 'lineCap'],
      straightOnly: true,
    );
    expect(complete.countLabel, '2 / 2 familles de pièces associées');
    expect(
      complete.statusLabel,
      'Associations complètes. Les raccords restent à valider avant publication.',
    );
    final incomplete = BorderPatternAssociations(
      assigned: ['lineStraight'],
      straightOnly: true,
    );
    expect(
      incomplete.statusLabel,
      'Pièces manquantes avant publication : extrémités.',
    );
  });

  test('a directed cliff asks for its inner corner by name', () {
    final directed = BorderPatternAssociations(
      assigned: ['lineStraight', 'lineCap', 'lineCorner'],
      followContourDirection: true,
    );
    expect(directed.countLabel, '3 / 4 familles de pièces associées');
    expect(
      directed.statusLabel,
      'Pièces manquantes avant publication : angle rentrant.',
    );
  });

  test('three associations still require canonical validation', () {
    final complete = BorderPatternAssociations(
      assigned: ['lineCap', 'lineStraight', 'lineCorner'],
    );
    expect(complete.missing, isEmpty);
    expect(complete.countLabel, '3 / 3 familles de pièces associées');
    expect(
      complete.statusLabel,
      'Associations complètes. Les raccords restent à valider avant publication.',
    );
  });
}
