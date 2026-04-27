// Tests unitaires — modèle [SurfaceStudioSelection] (Lot 58, pur Dart via flutter_test).
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';

void main() {
  group('SurfaceStudioSelection (Lot 58 model)', () {
    test('1. none — aucune sélection', () {
      const s = SurfaceStudioSelection.none();
      expect(s.isNone, isTrue);
      expect(s.kind, isNull);
      expect(s.id, isNull);
    });

    test('2. sélection atlas', () {
      final s = SurfaceStudioSelection.atlas('water-atlas');
      expect(s.isAtlas, isTrue);
      expect(s.isAnimation, isFalse);
      expect(s.isPreset, isFalse);
      expect(s.matchesAtlas('water-atlas'), isTrue);
      expect(s.matchesAtlas('other'), isFalse);
    });

    test('3. sélection animation', () {
      final s = SurfaceStudioSelection.animation('water-loop');
      expect(s.isAnimation, isTrue);
      expect(s.isAtlas, isFalse);
      expect(s.isPreset, isFalse);
      expect(s.matchesAnimation('water-loop'), isTrue);
      expect(s.matchesAnimation('x'), isFalse);
    });

    test('4. sélection preset', () {
      final s = SurfaceStudioSelection.preset('water-surface');
      expect(s.isPreset, isTrue);
      expect(s.isAtlas, isFalse);
      expect(s.isAnimation, isFalse);
      expect(s.matchesPreset('water-surface'), isTrue);
      expect(s.matchesPreset('x'), isFalse);
    });

    test('5. id vide refusé', () {
      expect(
        () => SurfaceStudioSelection.atlas(''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => SurfaceStudioSelection.animation('   '),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => SurfaceStudioSelection.preset(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('6. égalité de valeur', () {
      expect(
        SurfaceStudioSelection.atlas('a'),
        SurfaceStudioSelection.atlas('a'),
      );
      expect(
        SurfaceStudioSelection.atlas('a'),
        isNot(equals(SurfaceStudioSelection.animation('a'))),
      );
      expect(
        SurfaceStudioSelection.atlas('a'),
        isNot(equals(SurfaceStudioSelection.atlas('b'))),
      );
    });

    test('7. hashCode cohérent', () {
      final a = SurfaceStudioSelection.atlas('a');
      final a2 = SurfaceStudioSelection.atlas('a');
      expect(a.hashCode, a2.hashCode);
    });
  });
}
