import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// Même ordre explicite que le Lot 28 / `surface.dart` (ne pas utiliser
/// `values` pour construire l’attendu — teste vraiment l’intention).
const List<SurfaceVariantRole> kExpectedSurfaceVariantRoleOrder = [
  SurfaceVariantRole.isolated,
  SurfaceVariantRole.endNorth,
  SurfaceVariantRole.endEast,
  SurfaceVariantRole.endSouth,
  SurfaceVariantRole.endWest,
  SurfaceVariantRole.horizontal,
  SurfaceVariantRole.vertical,
  SurfaceVariantRole.cornerNE,
  SurfaceVariantRole.cornerSE,
  SurfaceVariantRole.cornerSW,
  SurfaceVariantRole.cornerNW,
  SurfaceVariantRole.innerCornerNE,
  SurfaceVariantRole.innerCornerSE,
  SurfaceVariantRole.innerCornerSW,
  SurfaceVariantRole.innerCornerNW,
  SurfaceVariantRole.teeNorth,
  SurfaceVariantRole.teeEast,
  SurfaceVariantRole.teeSouth,
  SurfaceVariantRole.teeWest,
  SurfaceVariantRole.cross,
];

void main() {
  group('SurfaceVariantRole', () {
    test('SurfaceVariantRole.values is exactly the expected order', () {
      expect(
        List<SurfaceVariantRole>.from(SurfaceVariantRole.values),
        kExpectedSurfaceVariantRoleOrder,
      );
    });

    test('standardSurfaceVariantRoleOrder matches expected explicit list', () {
      expect(standardSurfaceVariantRoleOrder, kExpectedSurfaceVariantRoleOrder);
    });

    test('standard list covers all enum values once (set + length)', () {
      final fromEnum = SurfaceVariantRole.values.toSet();
      final fromStandard = standardSurfaceVariantRoleOrder.toSet();
      expect(standardSurfaceVariantRoleOrder.length, SurfaceVariantRole.values.length);
      expect(standardSurfaceVariantRoleOrder.length, fromStandard.length);
      expect(fromEnum, fromStandard);
      for (final v in SurfaceVariantRole.values) {
        expect(standardSurfaceVariantRoleOrder.where((e) => e == v).length, 1);
      }
    });

    test('standardSurfaceVariantRoleOrder is not growable (const list)', () {
      // Liste `const` : tentative de mutation → UnsupportedError (runtime).
      expect(
        () => standardSurfaceVariantRoleOrder.add(SurfaceVariantRole.cross),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('export: types from map_core only', () {
      expect(SurfaceVariantRole.cross, isA<SurfaceVariantRole>());
      expect(standardSurfaceVariantRoleOrder, isA<List<SurfaceVariantRole>>());
    });

    test('ProjectManifest toJson: no surface* top-level keys', () {
      const manifest = ProjectManifest(
        name: 'L28',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'Map',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
      );
      final map = manifest.toJson();
      for (final key in <String>[
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(map.containsKey(key), isFalse, reason: key);
      }
    });

    test('TerrainPathVariant still available; cross names align (no conversion)', () {
      expect(TerrainPathVariant.cross, isA<TerrainPathVariant>());
      expect(SurfaceVariantRole.cross, isA<SurfaceVariantRole>());
      expect(SurfaceVariantRole.cross.name, TerrainPathVariant.cross.name);
    });
  });
}
