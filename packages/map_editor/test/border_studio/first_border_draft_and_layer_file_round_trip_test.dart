import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'BORD-01 persists and reloads the first draft and empty layer exactly',
    () async {
      final projectRoot = await Directory.systemTemp.createTemp(
        'bord01_first_draft_round_trip_',
      );
      addTearDown(() async {
        if (await projectRoot.exists()) {
          await projectRoot.delete(recursive: true);
        }
      });

      final sourceManifest = _manifest();
      final sourceMap = _map();
      final firstDraft = _firstDraft();

      // This is the BORD-01 migration boundary: neither V1 source owns Border
      // data before the single coordinated preparation action.
      expect(sourceManifest.version, ProjectVersion.v6);
      expect(sourceManifest.borderCatalog.isEmpty, isTrue);
      expect(sourceMap.version, ProjectVersion.v6);
      expect(sourceMap.layers.whereType<BorderLayer>(), isEmpty);

      final prepared = prepareFirstBorderDraftAndLayer(
        manifest: sourceManifest,
        map: sourceMap,
        draftRecord: firstDraft,
        layerId: 'borders',
        layerName: 'Bordures',
      );

      expect(prepared.manifest.version, ProjectVersion.v6);
      expect(prepared.manifest.borderCatalog.records, <BorderBlueprintRecord>[
        firstDraft,
      ]);
      expect(
        prepared.manifest.borderCatalog.records.single.latestPublished,
        isNull,
      );
      expect(prepared.manifest.borderCatalog.visualSnapshots, isEmpty);
      expect(prepared.map.version, ProjectVersion.v6);
      expect(prepared.map.layers, hasLength(1));
      final preparedLayer = prepared.map.layers.whereType<BorderLayer>().single;
      expect(preparedLayer.content, BorderLayerContent.emptyContent);
      expect(preparedLayer.content.isEmpty, isTrue);

      final manifestPath = p.join(projectRoot.path, 'project.json');
      final mapPath = p.join(projectRoot.path, 'maps', 'port.json');
      final projectRepository = FileProjectRepository();
      final mapRepository = FileMapRepository();

      await projectRepository.saveProject(prepared.manifest, manifestPath);
      await mapRepository.saveMap(
        prepared.map,
        mapPath,
        projectDialogueContext: prepared.manifest,
      );

      final reloadedManifest =
          await projectRepository.loadProject(manifestPath);
      final reloadedMap = await mapRepository.loadMap(mapPath);

      // Object equality proves value semantics; JSON equality guards the exact
      // persisted BORD-01 contract against normalization during disk reload.
      expect(reloadedManifest, prepared.manifest);
      expect(reloadedManifest.toJson(), prepared.manifest.toJson());
      expect(reloadedMap, prepared.map);
      expect(reloadedMap.toJson(), prepared.map.toJson());

      expect(reloadedManifest.version, ProjectVersion.v6);
      expect(reloadedManifest.borderCatalog.records.single, firstDraft);
      expect(
        reloadedManifest.borderCatalog.records.single.latestPublished,
        isNull,
      );
      expect(reloadedManifest.borderCatalog.visualSnapshots, isEmpty);
      expect(reloadedMap.version, ProjectVersion.v6);
      expect(reloadedMap.layers, hasLength(1));
      final reloadedLayer = reloadedMap.layers.whereType<BorderLayer>().single;
      expect(reloadedLayer.content, BorderLayerContent.emptyContent);
      expect(reloadedLayer.content.isEmpty, isTrue);

      // Preparation and persistence must not back-write either immutable V1
      // source while producing the two independent V2 documents.
      expect(sourceManifest.version, ProjectVersion.v6);
      expect(sourceManifest.borderCatalog.isEmpty, isTrue);
      expect(sourceMap.version, ProjectVersion.v6);
      expect(sourceMap.layers.whereType<BorderLayer>(), isEmpty);
    },
  );
}

ProjectManifest _manifest() => const ProjectManifest(
      name: 'BORD-01 disk acceptance',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'port',
          name: 'Port',
          relativePath: 'maps/port.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[],
      globalProperties: <String, dynamic>{
        'acceptanceMarker': 'manifest',
      },
    );

MapData _map() => const MapData(
      id: 'port',
      name: 'Port',
      size: GridSize(width: 2, height: 2),
      mapMetadata: MapMetadata(
        displayName: 'Port des Brisants',
        tags: <String>['coast'],
      ),
      properties: <String, dynamic>{
        'acceptanceMarker': 'map',
      },
    );

BorderBlueprintRecord _firstDraft() => BorderBlueprintRecord(
      id: 'coast',
      draft: BorderBlueprintDraft(
        baseRevision: 0,
        definition:
            BorderBlueprintDefinition<BorderPrimitiveDraft, BorderGroundDraft>(
          name: 'Coast',
          previewSeed: BorderSignedInt64.zero,
          template: BorderBlueprintTemplate.organicEdge,
          primitives: const <BorderPrimitiveDraft>[],
          defaults: BorderGenerationParams(
            irregularityPermille: 0,
            detailDensityPermille: 0,
            variationPermille: 0,
            maxOverlapPx: 0,
            gapTolerancePx: 0,
            depthRows: 1,
          ),
          sortOrder: 0,
        ),
      ),
    );
