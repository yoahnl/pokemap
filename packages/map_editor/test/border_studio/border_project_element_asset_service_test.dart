import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import '../support/riverpod_notifier_harness.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_project_element_asset_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_draft.dart';
import 'package:path/path.dart' as p;

void main() {
  group('BorderProjectElementAssetService', () {
    late Directory projectRoot;

    setUp(() async {
      projectRoot = await Directory.systemTemp.createTemp(
        'pokemap_border_project_element_',
      );
    });

    tearDown(() async {
      if (await projectRoot.exists()) {
        await projectRoot.delete(recursive: true);
      }
    });

    test(
      'loads and crops every project element frame before preparing a primitive',
      () async {
        final atlas = File(
          p.join(projectRoot.path, 'assets', 'tilesets', 'coast.png'),
        );
        await atlas.parent.create(recursive: true);
        await atlas.writeAsBytes(_twoTileAtlas(), flush: true);
        final manifest = _manifest();

        final result = await const BorderProjectElementAssetService().prepare(
          manifest: manifest,
          projectRootPath: projectRoot.path,
          sourceElementId: 'coast-rock',
          primitiveId: 'structure-large-0',
          role: BorderPrimitiveRole.structureLarge,
          weight: 750,
          transforms: BorderTransformPolicy(
            allowFlipX: true,
            allowedQuarterTurns: const <int>[0, 1, 2, 3],
          ),
        );

        expect(result.sourceElement.id, 'coast-rock');
        expect(result.preparation.sourceElementId, 'coast-rock');
        expect(result.preparation.snapshot.frames, hasLength(2));
        expect(
          result.preparation.snapshot.frames.map((frame) => frame.durationMs),
          <int>[100, 80],
        );
        expect(
          result.preparation.metrics.pixelSize,
          const GridSize(width: 2, height: 1),
        );
        expect(result.primitive.id, 'structure-large-0');
        expect(result.primitive.sourceElementId, 'coast-rock');
        expect(result.primitive.role, BorderPrimitiveRole.structureLarge);
        expect(result.primitive.weight, 750);
        expect(result.primitive.transforms.allowFlipX, isTrue);
        expect(result.primitive.currentMetrics, result.preparation.metrics);
        expect(
          result.primitive.anchorPx,
          result.preparation.metrics.defaultAnchorPx,
        );
      },
    );

    test(
      'reanalyzes changed source pixels after reload and supports explicit removal',
      () async {
        final atlas = File(
          p.join(projectRoot.path, 'assets', 'tilesets', 'coast.png'),
        );
        await atlas.parent.create(recursive: true);
        await atlas.writeAsBytes(_twoTileAtlas(), flush: true);
        const service = BorderProjectElementAssetService();
        final controller = mountBorderStudioDraftController(
          manifest: _manifest(),
        );
        controller.createBlueprint(
          id: 'coast-blueprint',
          name: 'Coast',
          template: BorderBlueprintTemplate.organicEdge,
        );
        final first = await service.prepare(
          manifest: _manifest(),
          projectRootPath: projectRoot.path,
          sourceElementId: 'coast-rock',
          primitiveId: 'structure-large-0',
          role: BorderPrimitiveRole.structureLarge,
          weight: 750,
          transforms: BorderTransformPolicy(
            allowFlipX: true,
            allowedQuarterTurns: const <int>[0, 1, 2, 3],
          ),
        );
        controller.addPreparedPrimitive(first.primitive);
        final savedManifest = controller.saveDraft();

        // A fresh controller models reopening the project: the persisted
        // fingerprint is the baseline until the source is explicitly read.
        final reloaded = mountBorderStudioDraftController(
          manifest: savedManifest,
        );
        await atlas.writeAsBytes(_changedTwoTileAtlas(), flush: true);
        final refreshed = await service.reanalyze(
          manifest: savedManifest,
          projectRootPath: projectRoot.path,
          primitive: first.primitive,
        );
        expect(
          refreshed.primitive.currentMetrics.assetFingerprint,
          isNot(first.primitive.currentMetrics.assetFingerprint),
        );
        expect(refreshed.primitive.id, first.primitive.id);
        expect(
          refreshed.primitive.sourceElementId,
          first.primitive.sourceElementId,
        );
        expect(refreshed.primitive.role, first.primitive.role);
        expect(refreshed.primitive.weight, first.primitive.weight);
        expect(refreshed.primitive.transforms, first.primitive.transforms);

        reloaded.replacePrimitiveAfterReanalysis(refreshed.primitive);

        expect(reloaded.state.requiresSourceReanalysis, isFalse);
        expect(reloaded.state.requiresRepublish, isTrue);
        expect(
          reloaded.state.diagnostics.diagnostics.single.code,
          borderStudioSourceRepublishRequiredDiagnosticCode,
        );
        expect(
          reloaded.state.workingDraft!.blueprint.definition.primitives.single,
          refreshed.primitive,
        );

        reloaded.removePrimitive('structure-large-0');
        expect(
          reloaded.state.workingDraft!.blueprint.definition.primitives,
          isEmpty,
        );
        expect(
          () => reloaded.removePrimitive('structure-large-0'),
          throwsArgumentError,
        );
      },
    );

    test('reanalyze preserves the primitive authored orientation', () async {
      final atlas = File(
        p.join(projectRoot.path, 'assets', 'tilesets', 'coast.png'),
      );
      await atlas.parent.create(recursive: true);
      await atlas.writeAsBytes(_twoTileAtlas(), flush: true);
      const service = BorderProjectElementAssetService();
      final prepared = await service.prepare(
        manifest: _manifest(),
        projectRootPath: projectRoot.path,
        sourceElementId: 'coast-rock',
        primitiveId: 'oriented',
        role: BorderPrimitiveRole.structureLarge,
        weight: 750,
        transforms: BorderTransformPolicy(
          allowFlipX: true,
          allowedQuarterTurns: const <int>[0, 1, 2, 3],
        ),
      );
      final oriented = BorderPrimitiveDraft(
        id: prepared.primitive.id,
        sourceElementId: prepared.primitive.sourceElementId,
        role: prepared.primitive.role,
        authoredOrientation: BorderPrimitiveOrientation.south,
        weight: prepared.primitive.weight,
        anchorPx: prepared.primitive.anchorPx,
        transforms: prepared.primitive.transforms,
        currentMetrics: prepared.primitive.currentMetrics,
      );

      final refreshed = await service.reanalyze(
        manifest: _manifest(),
        projectRootPath: projectRoot.path,
        primitive: oriented,
      );

      expect(
        refreshed.primitive.authoredOrientation,
        BorderPrimitiveOrientation.south,
      );
    });

    test(
      'rejects an element ID that is absent from the project manifest',
      () async {
        final manifest = _manifest().copyWith(
          elements: const <ProjectElementEntry>[],
        );

        await expectLater(
          const BorderProjectElementAssetService().prepare(
            manifest: manifest,
            projectRootPath: projectRoot.path,
            sourceElementId: 'coast-rock',
            primitiveId: 'structure-large-0',
            role: BorderPrimitiveRole.structureLarge,
            weight: 750,
            transforms: BorderTransformPolicy(
              allowFlipX: false,
              allowedQuarterTurns: const <int>[0],
            ),
          ),
          throwsA(
            isA<BorderProjectElementAssetException>()
                .having(
                  (error) => error.code,
                  'code',
                  BorderProjectElementAssetErrorCode.missingElement,
                )
                .having(
                  (error) => error.sourceElementId,
                  'sourceElementId',
                  'coast-rock',
                ),
          ),
        );
      },
    );

    test('rejects a tileset path that escapes the project root', () async {
      final manifest = _manifest().copyWith(
        tilesets: <ProjectTilesetEntry>[
          _manifest().tilesets.single.copyWith(relativePath: '../coast.png'),
        ],
      );

      await expectLater(
        const BorderProjectElementAssetService().prepare(
          manifest: manifest,
          projectRootPath: projectRoot.path,
          sourceElementId: 'coast-rock',
          primitiveId: 'structure-large-0',
          role: BorderPrimitiveRole.structureLarge,
          weight: 750,
          transforms: BorderTransformPolicy(
            allowFlipX: false,
            allowedQuarterTurns: const <int>[0],
          ),
        ),
        throwsA(
          isA<BorderProjectElementAssetException>().having(
            (error) => error.code,
            'code',
            BorderProjectElementAssetErrorCode.unsafeTilesetPath,
          ),
        ),
      );
    });
  });
}

ProjectManifest _manifest() => ProjectManifest(
  name: 'Border asset test',
  maps: const <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'coast',
      name: 'Coast',
      relativePath: 'assets/tilesets/coast.png',
      transparentColor: TilesetTransparentColor(red: 255, green: 0, blue: 255),
    ),
  ],
  elements: const <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'coast-rock',
      name: 'Coast rock',
      tilesetId: 'coast',
      categoryId: 'coast',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        ),
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 1, y: 0, width: 1, height: 1),
          durationMs: 80,
        ),
      ],
    ),
  ],
  settings: const ProjectSettings(tileWidth: 2, tileHeight: 1),
);

Uint8List _twoTileAtlas() {
  final image = img.Image(width: 4, height: 1, numChannels: 4);
  image
    ..setPixelRgba(0, 0, 255, 0, 255, 255)
    ..setPixelRgba(1, 0, 120, 110, 100, 255)
    ..setPixelRgba(2, 0, 90, 80, 70, 255)
    ..setPixelRgba(3, 0, 60, 50, 40, 255);
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _changedTwoTileAtlas() {
  final image = img.Image(width: 4, height: 1, numChannels: 4);
  image
    ..setPixelRgba(0, 0, 255, 0, 255, 255)
    ..setPixelRgba(1, 0, 10, 20, 30, 255)
    ..setPixelRgba(2, 0, 40, 50, 60, 255)
    ..setPixelRgba(3, 0, 70, 80, 90, 255);
  return Uint8List.fromList(img.encodePng(image));
}
