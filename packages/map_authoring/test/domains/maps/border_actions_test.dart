import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderActions', () {
    test('refuses a blueprint without a published revision', () {
      final manifest = ProjectManifest(
        name: 'Border test',
        maps: const [],
        tilesets: const [],
        borderCatalog: ProjectBorderCatalog(
          records: [_draftOnlyRecord()],
        ),
      );

      expect(
        () => const BorderActions().requirePublishedBlueprint(
          manifest,
          'draft-border',
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'border.blueprint_not_published',
          ),
        ),
      );
    });

    test('stroke draw adapts canonical core editing and preserves base stroke',
        () {
      final base = BorderStrokeGeometry(
        strokes: [
          BorderStroke(
            id: 'existing',
            points: const [GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)],
            closed: false,
          ),
        ],
      );

      final edited = const BorderActions().editStroke(
        base,
        mode: BorderStrokeEditingMode.draw,
        sampledPoints: const [GridPos(x: 2, y: 2), GridPos(x: 2, y: 4)],
      );

      expect(edited.strokes, hasLength(2));
      expect(edited.strokes.first.id, 'existing');
      expect(edited.strokes.last.points, const [
        GridPos(x: 2, y: 2),
        GridPos(x: 2, y: 3),
        GridPos(x: 2, y: 4),
      ]);
    });

    test('preview fingerprint changes with revision and feature seed', () {
      final result = BorderResolutionResult(
        materialization: null,
        diagnosticReport: BorderDiagnosticsReport(
          diagnostics: [
            BorderDiagnostic(
              code: 'border.test.expected_error',
              severity: BorderDiagnosticSeverity.error,
              phase: BorderDiagnosticPhase.authoring,
              scope: BorderDiagnosticScope.feature,
              suggestedAction: 'border.test.fix',
            ),
          ],
        ),
      );
      BorderPreviewArtifact artifact(String revision, String seed) =>
          BorderPreviewArtifact(
            mapId: 'map',
            layerId: 'border',
            featureId: 'feature',
            projectRevision: revision,
            seed: seed,
            blueprintId: 'blueprint',
            blueprintRevision: 2,
            resolverVersion: 1,
            result: result,
          );

      final baseline = artifact('map-revision-1', '37');
      expect(
          artifact('map-revision-1', '37').fingerprint, baseline.fingerprint);
      expect(
        artifact('map-revision-2', '37').fingerprint,
        isNot(baseline.fingerprint),
      );
      expect(
        artifact('map-revision-1', '38').fingerprint,
        isNot(baseline.fingerprint),
      );
    });

    test('canonical dispatcher exposes feature, relink, materialize and resize',
        () {
      final ids = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll(<String>{
          'border_layer.feature_create',
          'border_layer.feature_delete',
          'border_layer.stroke_add',
          'border_layer.stroke_update',
          'border_layer.relink_apply',
          'border_layer.materialize_apply',
          'border_layer.resize_apply',
        }),
      );
    });
  });
}

BorderBlueprintRecord _draftOnlyRecord() => BorderBlueprintRecord(
      id: 'draft-border',
      draft: BorderBlueprintDraft(
        baseRevision: 0,
        definition: BorderBlueprintDraftDefinition(
          name: 'Draft border',
          previewSeed: BorderSignedInt64.zero,
          template: BorderBlueprintTemplate.masonryLine,
          primitives: const [],
          defaults: BorderGenerationParams(
            irregularityPermille: 0,
            detailDensityPermille: 0,
            variationPermille: 0,
            maxOverlapPx: 0,
            gapTolerancePx: 0,
            depthRows: 1,
          ),
          ground: null,
          categoryId: null,
          sortOrder: 0,
        ),
      ),
    );
