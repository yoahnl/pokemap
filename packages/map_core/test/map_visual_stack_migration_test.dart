import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('map visual stack migration', () {
    test('previews legacy and canonical plans without mutating the map', () {
      final map = _legacyMap();

      final preview = previewMapVisualStackMigration(map);

      expect(preview.status, MapVisualStackMigrationStatus.ready);
      expect(preview.canApply, isTrue);
      expect(preview.before, same(map));
      expect(preview.before.visualStack, isNull);
      expect(preview.after, isNot(same(map)));
      expect(preview.after.version, ProjectVersion.v3);
      expect(preview.after.visualStack, MapVisualStackConfig.canonicalV1);
      expect(
        preview.beforePlan?.semantics,
        MapVisualCompositionSemantics.legacyRuntimeV1,
      );
      expect(
        preview.afterPlan?.semantics,
        MapVisualCompositionSemantics.canonicalV1,
      );
      expect(preview.diagnostics, isEmpty);
      expect(map.visualStack, isNull);
    });

    test('reports composition differences in a stable order', () {
      final first = previewMapVisualStackMigration(_legacyMap());
      final second = previewMapVisualStackMigration(_legacyMap());

      final firstKeys = first.differences
          .map((difference) => difference.stableKey)
          .toList(growable: false);
      final secondKeys = second.differences
          .map((difference) => difference.stableKey)
          .toList(growable: false);

      expect(
        firstKeys,
        const <String>[
          'moved:surfaceLayer:surface:0->1',
          'moved:shadows:1->2',
          'moved:tileBackgroundLayer:ground:2->0',
        ],
      );
      expect(secondKeys, firstKeys);
    });

    test('applies the reviewed canonical semantics and safe map format', () {
      final map = _legacyMap();
      final preview = previewMapVisualStackMigration(map);

      final migrated = applyMapVisualStackMigration(
        map: map,
        preview: preview,
      );

      expect(migrated.version, ProjectVersion.v3);
      expect(migrated.visualStack, MapVisualStackConfig.canonicalV1);
      expect(
        migrated.copyWith(
          version: map.version,
          visualStack: null,
        ),
        map,
      );
    });

    test('refuses a preview after the source map changed', () {
      final map = _legacyMap();
      final preview = previewMapVisualStackMigration(map);

      expect(
        () => applyMapVisualStackMigration(
          map: map.copyWith(name: 'Changed after preview'),
          preview: preview,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('stale'),
          ),
        ),
      );
    });

    test('blocks an unknown future semantics version without fallback', () {
      final map = _legacyMap().copyWith(
        visualStack: MapVisualStackConfig(semanticsVersion: 2),
      );

      final preview = previewMapVisualStackMigration(map);

      expect(preview.status, MapVisualStackMigrationStatus.blocked);
      expect(preview.canApply, isFalse);
      expect(preview.before, same(map));
      expect(preview.after, same(map));
      expect(preview.beforePlan, isNull);
      expect(preview.afterPlan, isNull);
      expect(preview.differences, isEmpty);
      expect(
        preview.diagnostics.map((diagnostic) => diagnostic.code),
        const <MapVisualCompositionDiagnosticCode>[
          MapVisualCompositionDiagnosticCode.unsupportedSemanticsVersion,
        ],
      );
      expect(
        () => applyMapVisualStackMigration(map: map, preview: preview),
        throwsStateError,
      );
      expect(
        map.visualStack?.semanticsVersion,
        2,
        reason: 'An unsupported map must not be rewritten as legacy or v1.',
      );
    });

    test('rerun is an exact no-op and returns the same map', () {
      final firstPreview = previewMapVisualStackMigration(_legacyMap());
      final migrated = applyMapVisualStackMigration(
        map: firstPreview.before,
        preview: firstPreview,
      );

      final rerun = previewMapVisualStackMigration(migrated);
      final result = applyMapVisualStackMigration(
        map: migrated,
        preview: rerun,
      );

      expect(rerun.status, MapVisualStackMigrationStatus.noChange);
      expect(rerun.canApply, isFalse);
      expect(rerun.before, same(migrated));
      expect(rerun.after, same(migrated));
      expect(rerun.differences, isEmpty);
      expect(result, same(migrated));
    });
  });
}

MapData _legacyMap() => const MapData(
      id: 'legacy-visual-stack',
      name: 'Legacy visual stack',
      size: GridSize(width: 1, height: 1),
      layers: <MapLayer>[
        SurfaceLayer(id: 'surface', name: 'Surface'),
        TileLayer(id: 'ground', name: 'Ground'),
      ],
    );
