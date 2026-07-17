import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_project_element_asset_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_publication_candidate_builder.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_publication_coordinator.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Selbrume individual-stone cliff is publication ready', () async {
    final projectRoot = p.normalize(
      p.join(Directory.current.path, '..', '..', 'selbrume'),
    );
    var manifest = ProjectManifest.fromJson(
      jsonDecode(
        await File(p.join(projectRoot, 'project.json')).readAsString(),
      ) as Map<String, Object?>,
    );
    var record = manifest.borderCatalog.recordById('border-blueprint-2')!;
    const assetService = BorderProjectElementAssetService();
    final refreshedPrimitives = <BorderPrimitiveDraft>[];
    for (final primitive in record.draft.definition.primitives) {
      final refreshed = await assetService.reanalyze(
        manifest: manifest,
        projectRootPath: projectRoot,
        primitive: primitive,
      );
      refreshedPrimitives.add(refreshed.primitive);
    }
    final definition = record.draft.definition;
    record = BorderBlueprintRecord(
      id: record.id,
      draft: BorderBlueprintDraft(
        baseRevision: record.draft.baseRevision,
        definition: BorderBlueprintDraftDefinition(
          name: definition.name,
          previewSeed: definition.previewSeed,
          template: definition.template,
          primitives: refreshedPrimitives,
          defaults: definition.defaults,
          ground: definition.ground,
          categoryId: definition.categoryId,
          sortOrder: definition.sortOrder,
        ),
      ),
      latestPublished: record.latestPublished,
      isDeprecated: record.isDeprecated,
    );
    manifest = replaceProjectBorderCatalog(
      manifest,
      ProjectBorderCatalog(
        formatVersion: manifest.borderCatalog.formatVersion,
        records: <BorderBlueprintRecord>[
          for (final candidate in manifest.borderCatalog.records)
            if (candidate.id == record.id) record else candidate,
        ],
        visualSnapshots: manifest.borderCatalog.visualSnapshots,
      ),
    );
    final coordinator = BorderStudioPublicationCoordinator(
      prepareProjectElementAsset: assetService.prepare,
      buildCandidate: const BorderPublicationCandidateBuilder().build,
      resolveCanonicalGallery: ({
        required blueprintId,
        required blueprintRevision,
        required visualSnapshots,
        required tileSizePx,
        required resolverVersion,
      }) =>
          BorderStudioCanonicalGalleryResolution.fromCore(
        resolveBorderCanonicalGallery(
          blueprintId: blueprintId,
          blueprintRevision: blueprintRevision,
          visualSnapshots: visualSnapshots,
          tileSizePx: tileSizePx,
          resolverVersion: resolverVersion,
        ),
      ),
      publishRequest: (_) => throw UnsupportedError('prepare only'),
    );

    final preview = await coordinator.prepare(
      manifest: manifest,
      projectRootPath: projectRoot,
      draftRecord: record,
    );
    final diagnostics = preview.diagnostics.diagnostics
        .map(
          (item) => '${item.severity.name}: ${item.code} '
              '${item.parameters}',
        )
        .join('\n');

    expect(preview.diagnostics.hasErrors, isFalse, reason: diagnostics);
    expect(
      preview.canonicalGalleryCases.every(
        (item) => item.resolution.canApply,
      ),
      isTrue,
      reason: diagnostics,
    );

    final map = MapData.fromJson(
      jsonDecode(
        await File(
          p.join(projectRoot, 'maps', 'map_bourg_selbrume.json'),
        ).readAsString(),
      ) as Map<String, Object?>,
    );
    final candidateManifest = preview.candidate.nextManifest;
    final targetRevision = candidateManifest.borderCatalog
        .recordById('border-blueprint-2')!
        .latestPublished!;
    expect(targetRevision.definition.defaults.depthRows, 2);
    expect(targetRevision.definition.defaults.maxOverlapPx, 4);
    expect(targetRevision.definition.defaults.allowAutoRotation, isFalse);
    expect(
      targetRevision.definition.primitives
          .where(
            (primitive) => primitive.role == BorderPrimitiveRole.structureLarge,
          )
          .length,
      6,
    );
    expect(
      targetRevision.definition.primitives
          .where(
            (primitive) =>
                primitive.role == BorderPrimitiveRole.structureMedium,
          )
          .length,
      6,
    );
    for (final primitive in targetRevision.definition.primitives.where(
      (primitive) =>
          primitive.role == BorderPrimitiveRole.structureLarge ||
          primitive.role == BorderPrimitiveRole.structureMedium,
    )) {
      expect(
        primitive.publishedMetrics.opaqueBounds.width,
        greaterThanOrEqualTo(
          primitive.publishedMetrics.opaqueBounds.height,
        ),
        reason: '${primitive.id} should remain a squat individual stone.',
      );
    }
    final borderLayer = map.layers
        .whereType<BorderLayer>()
        .singleWhere((layer) => layer.id == 'l_border_bordures');
    final feature = borderLayer.content.featureById('border_feature')!;
    final resolution = resolveBorderFeature(
      BorderResolutionRequest(
        mapSize: map.size,
        tileSizePx: GridSize(
          width: candidateManifest.settings.tileWidth,
          height: candidateManifest.settings.tileHeight,
        ),
        blueprintId: 'border-blueprint-2',
        blueprintRevision: targetRevision,
        feature: feature,
        visualSnapshots: candidateManifest.borderCatalog.visualSnapshots,
        resolverVersion: borderResolverVersion,
      ),
    );
    final resolutionDiagnostics = resolution.diagnosticReport.diagnostics
        .map(
          (item) => '${item.severity.name}: ${item.code} '
              '${item.parameters}',
        )
        .join('\n');
    expect(
      resolution.canApply,
      isTrue,
      reason: resolutionDiagnostics,
    );
    final placements = resolution.materialization!.placements;
    expect(
      placements.where(
        (placement) => placement.drawBand == BorderDrawBand.outerAccent,
      ),
      isNotEmpty,
    );
    expect(
      placements.where(
        (placement) => placement.drawBand == BorderDrawBand.structure,
      ),
      isNotEmpty,
    );
    expect(
      placements.map((placement) => placement.transform.quarterTurns),
      everyElement(0),
    );
  });
}
