import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/presentation/features/resources/library/resource_library_view_data.dart';
import 'package:avelune_studio/presentation/features/resources/project_library_catalog_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_border_fixture.dart';

void main() {
  test(
    'the partitioned library uses the dimensions of the composite definitions',
    () async {
      final cache = Directory('/Users/karim/Library/Caches/AveluneQA');
      await cache.create(recursive: true);
      final fixture = await cache.createTemp('resource-dimensions.');
      addTearDown(() => fixture.delete(recursive: true));
      final root = await fixture.resolveSymbolicLinks();
      final spatial = spatialBorderProject();
      final project = spatial.copyWith(
        maps: const [],
        smartTileCatalog: ProjectSmartTileCatalog(
          materials: const [
            ProjectSmartTileMaterial(
              id: 'grass',
              name: 'Herbe',
              connectionGroupId: 'grass',
            ),
          ],
          presets: [
            _terrain,
            _terrain.copyWith(
              id: 'raised-terrain',
              name: 'Terrain en relief',
              rules: const [
                SmartTileRule(
                  id: 'relief',
                  centerMatch: SmartTileSlotMatch.material('grass'),
                  candidates: [
                    SmartTileCandidate(
                      id: 'oak',
                      parts: [
                        SmartTileVisualPart(
                          source: SmartTileVisualSource.model3d(modelId: 'oak'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        environmentPresets: [
          ...spatial.environmentPresets,
          EnvironmentPreset(
            id: 'planar',
            name: 'Ensemble 2D',
            templateId: 'manual',
            sortOrder: 0,
            palette: [
              EnvironmentPaletteItem(
                elementId: spatial.elements.single.id,
                weight: 1,
              ),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
          ),
        ],
      );
      await WorkingProjectCatalog.create(
        store: await CatalogStorageStore.open(projectRoot: root),
        projectId: 'library-dimension',
        project: project,
      );
      final session = ProjectSession(
        sessionId: 'library-dimension',
        name: project.name,
        directoryPath: root,
        storage: ProjectSessionStorage.workingCatalog,
      );
      final adapter = LocalMapWorkspaceAdapter();
      final library = await adapter.readResourceLibrary(session);
      final entries = {
        for (final item in ProjectLibraryCatalogView(library).items)
          item.id: item,
      };
      const expected = {
        'borderBlueprint:fence': {ProjectDimension.threeD},
        'environmentPreset:woodland': {ProjectDimension.threeD},
        'environmentPreset:planar': {ProjectDimension.twoD},
        'smartTilePreset:terrain': {
          ProjectDimension.twoD,
          ProjectDimension.threeD,
        },
        'smartTilePreset:raised-terrain': {ProjectDimension.threeD},
      };
      Map<String, Set<ProjectDimension>> dimensions(
        Iterable<ProjectLibraryItem> items,
      ) => {
        for (final item in items)
          if (expected.containsKey(item.identity))
            item.identity: item.compatibleDimensions,
      };
      expect(dimensions(library.items), expected);
      expect(
        dimensions(ProjectResourceLibrary.fromManifest(project).items),
        expected,
      );
      final indexed = await adapter.readResourceLibraryIndex(session);
      expect(indexed.revision, library.revision);
      expect(
        indexed.items.map((item) => item.identity),
        library.items.map((item) => item.identity),
      );
      expect(dimensions(indexed.items).values, everyElement(isEmpty));
      expect(
        indexed.items
            .singleWhere((item) => item.id == 'oak')
            .compatibleDimensions,
        {ProjectDimension.threeD},
      );
      expect(
        await adapter.readResourceLibraryDimensions(
          session,
          revision: indexed.revision!,
        ),
        expected,
      );
      expect(
        await adapter.readResourceLibraryDimensions(session, revision: 'stale'),
        isNull,
      );
      final refreshed = await adapter.readResourceLibraryItems(
        session,
        library.items
            .where((item) => expected.containsKey(item.identity))
            .map((item) => (kind: item.kind, id: item.id)),
        expectedRevision: library.revision!,
      );
      expect(dimensions(refreshed), expected);
      expect(
        entries['borderBlueprint:fence']?.dimension,
        ResourceLibraryDimension.threeDimensional,
      );
      expect(
        entries['environmentPreset:woodland']?.dimension,
        ResourceLibraryDimension.threeDimensional,
      );
      expect(
        entries['environmentPreset:planar']?.dimension,
        ResourceLibraryDimension.twoDimensional,
      );
      expect(entries['smartTilePreset:terrain']?.dimensionLabel, '2D / 3D');
    },
  );
}

const _terrain = ProjectSmartTilePreset(
  id: 'terrain',
  name: 'Terrain commun',
  usage: SmartTileUsage.terrain,
  topology: SmartTileTopology.uniform,
  coveragePolicy: SmartTileCoveragePolicy.sparse,
  coverageProfile: SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.template,
  ),
  transformPolicy: SmartTileTransformPolicy(),
  defaultMaterialId: 'grass',
  allowedMaterialIds: ['grass'],
);
