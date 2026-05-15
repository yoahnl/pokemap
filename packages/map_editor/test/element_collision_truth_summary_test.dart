import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/element_collision_truth_summary.dart';

void main() {
  group('summarizeElementCollisionTruth', () {
    test('returns fineMask when collisionMask exists', () {
      final summary = summarizeElementCollisionTruth(
        ElementCollisionProfile(
          collisionMask: _mask(),
          cells: const [GridPos(x: 4, y: 4)],
        ),
      );

      expect(summary.mode, ElementCollisionTruthMode.fineMask);
      expect(summary.title, contains('Collision fine'));
      expect(summary.description, contains('gameplay'));
      expect(summary.description, contains('masque de collision fin'));
      expect(summary.detail, contains('grille'));
      expect(summary.detail, contains('projection'));
      expect(summary.hasCollisionMask, isTrue);
      expect(summary.hasLegacyCells, isTrue);
    });

    test('returns legacyCells when only cells exist', () {
      final summary = summarizeElementCollisionTruth(
        const ElementCollisionProfile(
          cells: [GridPos(x: 0, y: 0)],
        ),
      );

      expect(summary.mode, ElementCollisionTruthMode.legacyCells);
      expect(summary.title, contains('Collision par grille'));
      expect(summary.description, contains('fallback'));
      expect(summary.description, contains('cellules'));
      expect(summary.hasCollisionMask, isFalse);
      expect(summary.hasLegacyCells, isTrue);
    });

    test('visualMask alone does not make collision active', () {
      final summary = summarizeElementCollisionTruth(
        ElementCollisionProfile(visualMask: _mask()),
      );

      expect(summary.mode, ElementCollisionTruthMode.empty);
      expect(summary.title, contains('Aucune collision active'));
      expect(summary.description, contains('ne bloque pas'));
      expect(summary.hasVisualMask, isTrue);
      expect(summary.notes.join(' '), contains('aperçu/analyse'));
      expect(summary.notes.join(' '), contains('ne bloque pas'));
    });

    test('occlusionMask alone does not make collision active', () {
      final summary = summarizeElementCollisionTruth(
        ElementCollisionProfile(occlusionMask: _mask()),
      );

      expect(summary.mode, ElementCollisionTruthMode.empty);
      expect(summary.title, contains('Aucune collision active'));
      expect(summary.hasOcclusionMask, isTrue);
      expect(summary.notes.join(' '), contains('occlusion'));
      expect(summary.notes.join(' '), contains('ne bloque pas'));
    });

    test('returns empty when profile is null', () {
      final summary = summarizeElementCollisionTruth(null);

      expect(summary.mode, ElementCollisionTruthMode.empty);
      expect(summary.title, 'Aucune collision active');
      expect(summary.hasCollisionMask, isFalse);
      expect(summary.hasLegacyCells, isFalse);
      expect(summary.hasVisualMask, isFalse);
      expect(summary.hasOcclusionMask, isFalse);
    });
  });
}

ElementCollisionPixelMask _mask() {
  return ElementCollisionPixelMask(
    widthPx: 1,
    heightPx: 1,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: 1,
      heightPx: 1,
      solidPixels: const [true],
    ),
  );
}
