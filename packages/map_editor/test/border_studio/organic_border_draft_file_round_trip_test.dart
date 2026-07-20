import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_draft_controller.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  test('organic draft and its source links survive project JSON roundtrip',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'bord02_organic_draft_round_trip_',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    final controller = BorderStudioDraftController()
      ..loadFromManifest(_manifest())
      ..createBlueprint(
        id: 'coast',
        name: 'Côte rocheuse',
        template: BorderBlueprintTemplate.organicEdge,
      )
      ..replacePrimitives(<BorderPrimitiveDraft>[_rockPrimitive()]);
    final savedDraft = controller.saveDraft();
    final path = p.join(root.path, 'project.json');
    final repository = FileProjectRepository();

    await repository.saveProject(savedDraft, path);
    final reloaded = await repository.loadProject(path);
    final reloadedController = BorderStudioDraftController(
      manifest: reloaded,
    );

    expect(reloaded.toJson(), savedDraft.toJson());
    final record = reloaded.borderCatalog.recordById('coast')!;
    expect(record.latestPublished, isNull);
    expect(
        record.draft.definition.template, BorderBlueprintTemplate.organicEdge);
    expect(record.draft.definition.primitives.single.sourceElementId,
        'rock-element');
    expect(record.draft.definition.primitives.single.currentMetrics,
        _rockPrimitive().currentMetrics);
    expect(reloadedController.state.diagnosticsAreCurrent, isFalse);
    expect(reloadedController.state.diagnostics.hasErrors, isFalse);
    expect(reloadedController.state.canPublish, isFalse);
    expect(
      reloadedController.state.publicationAvailability.disabledReason,
      contains('aperçu canonique'),
    );
  });
}

ProjectManifest _manifest() => const ProjectManifest(
      name: 'BORD-02 draft roundtrip',
      version: ProjectVersion.v2,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'coast-tileset',
          name: 'Coast',
          relativePath: 'assets/tilesets/coast.png',
        ),
      ],
      elementCategories: <ProjectElementCategory>[
        ProjectElementCategory(id: 'border', name: 'Bordures'),
      ],
      elements: <ProjectElementEntry>[
        ProjectElementEntry(
          id: 'rock-element',
          name: 'Rocher de côte',
          tilesetId: 'coast-tileset',
          categoryId: 'border',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 16, height: 16),
            ),
          ],
        ),
      ],
      borderCatalog: ProjectBorderCatalog.empty(),
    );

BorderPrimitiveDraft _rockPrimitive() => BorderPrimitiveDraft(
      id: 'rock',
      sourceElementId: 'rock-element',
      role: BorderPrimitiveRole.structureLarge,
      weight: 100,
      anchorPx: const BorderPixelPos(x: 8, y: 15),
      transforms: BorderTransformPolicy(
        allowFlipX: true,
        allowedQuarterTurns: const <int>[0],
      ),
      currentMetrics: BorderPrimitiveAssetMetrics(
        assetFingerprint:
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        pixelSize: const GridSize(width: 16, height: 16),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
        defaultAnchorPx: const BorderPixelPos(x: 8, y: 15),
        occupancyMaskRle: 'border-rle-v1:256:1:256',
      ),
    );
