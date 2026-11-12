import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_preview_source.dart';
import 'package:avelune_studio/features/resources/application/resource_usage_category.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_connections.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_resource_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';

ProjectTilesetEntry _sheet(String id) => ProjectTilesetEntry(
  id: id,
  name: id,
  relativePath: '$id.png',
  source: ProjectTilesetSource.regularAtlas(
    assetId: id,
    pixelWidth: 128,
    pixelHeight: 128,
    tileWidth: 32,
    tileHeight: 32,
  ),
);

ProjectSmartTilePreset _preset(
  String id,
  SmartTileUsage usage,
  String material,
  List<String> allowed,
) => ProjectSmartTilePreset(
  id: id,
  name: id,
  usage: usage,
  topology: SmartTileTopology.cardinal4,
  coveragePolicy: SmartTileCoveragePolicy.complete,
  coverageProfile: const SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.template,
  ),
  transformPolicy: const SmartTileTransformPolicy(),
  defaultMaterialId: material,
  allowedMaterialIds: allowed,
  rules: [
    for (var mask = 0; mask < 16; mask++)
      terrainConnectionRule(
        mask,
        SmartTileFrameRef(
          atlasId: mask == 0 ? 'atlas_near' : 'atlas_far',
          column: 1,
          row: 1,
        ),
        material,
      ),
  ],
);

ProjectSmartTileMaterial _material(String id, [PathSurfaceKind? kind]) =>
    ProjectSmartTileMaterial(
      id: id,
      name: id,
      connectionGroupId: id,
      pathSurfaceKind: kind,
    );

void main() {
  late Directory root;
  late LocalProjectSessionAdapter sessions;
  late ProjectSession session;
  late MapWorkspaceController workspace;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('studio_terrain_listing_');
    sessions = LocalProjectSessionAdapter();
    await writeExampleProject(root);
    for (final id in ['jardin', 'clairiere']) {
      final mapFile = File('${root.path}/maps/$id.json');
      final map = MapData.fromJson(
        jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
      );
      await mapFile.writeAsString(
        jsonEncode(
          MapData(
            id: map.id,
            name: map.name,
            version: ProjectVersion.v9,
            size: const GridSize(width: 8, height: 6),
            spatialScene: MapSpatialScene(
              width: 8,
              depth: 6,
              heightLevels: List.filled(48, 0),
            ),
          ).toJson(),
        ),
      );
    }
    final file = File('${root.path}/project.json');
    final source = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()),
    );
    await file.delete();
    final near = _sheet('near_sheet');
    final far = _sheet('far_sheet');
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'terrain-listing-test',
      project: source.copyWith(
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        tilesets: [...source.tilesets, near, far],
        smartTileCatalog: ProjectSmartTileCatalog(
          atlases: [
            terrainAtlas(near, 'atlas_near'),
            terrainAtlas(far, 'atlas_far'),
          ],
          materials: [
            _material('grass'),
            _material('flowers'),
            _material('sea', PathSurfaceKind.water),
            _material('foam', PathSurfaceKind.water),
          ],
          presets: [
            _preset('meadow', SmartTileUsage.terrain, 'grass', [
              'grass',
              'flowers',
            ]),
            _preset('river', SmartTileUsage.path, 'sea', ['sea', 'foam']),
          ],
        ),
        resourceLibraryCatalog: ResourceLibraryCatalog(
          families: [ResourceFamily(id: 'family_meadows', name: 'Prairies')],
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'smartTilePreset',
              resourceId: 'meadow',
              familyId: 'family_meadows',
              description: 'Herbe haute',
            ),
          ],
        ),
      ),
    );
    session = await sessions.open(await root.resolveSymbolicLinks());
    expect(session.storage, ProjectSessionStorage.workingCatalog);
    workspace = MapWorkspaceController(session, LocalMapWorkspaceAdapter());
    await workspace.initialize();
    expect(workspace.error, isNull);
  });

  tearDown(() async {
    workspace.dispose();
    await sessions.close(session);
    await root.delete(recursive: true);
  });

  Set<String> ids<T>(Iterable<T> values, String Function(T) id) =>
      values.map(id).toSet();

  ResourceItem item(String id) =>
      resourceCatalog(workspace.project!).singleWhere((item) => item.id == id);

  test(
    'the palette lists terrains with only what their tile and category need',
    () async {
      await workspace.ensureResourceKind(
        'smartTilePreset',
        placeableOnly: true,
      );

      final project = workspace.project!;
      final catalog = project.smartTileCatalog;
      expect(ids(catalog.presets, (preset) => preset.id), {'meadow', 'river'});
      expect(ids(catalog.materials, (material) => material.id), {'sea'});
      expect(ids(catalog.atlases, (atlas) => atlas.id), {'atlas_near'});
      expect(
        ids(project.tilesets, (tileset) => tileset.id),
        allOf(contains('near_sheet'), isNot(contains('far_sheet'))),
      );
      expect(
        project.resourceLibraryCatalog
            .entryFor('smartTilePreset', 'meadow')
            ?.description,
        'Herbe haute',
      );
      expect(
        project.resourceLibraryCatalog.families.map((family) => family.id),
        contains('family_meadows'),
      );
      expect(
        resourceUsageCategory(item('meadow'), project),
        ResourceUsageCategory.ground,
      );
      expect(
        resourceUsageCategory(item('river'), project),
        ResourceUsageCategory.water,
      );
      expect(
        resourcePreviewSource(item('meadow'), workspace.visualProject!),
        isA<TileFramePreviewSource>(),
      );
      expect(
        workspace.hasResourceClosure('smartTilePreset', 'meadow'),
        isFalse,
      );
    },
  );

  test('a chosen terrain resolves its whole closure and keeps it across categories', () async {
    await workspace.ensureResourceKind('smartTilePreset', placeableOnly: true);

    await workspace.ensureResourceClosure('smartTilePreset', 'meadow');

    expect(workspace.hasResourceClosure('smartTilePreset', 'meadow'), isTrue);
    expect(workspace.hasResourceClosure('smartTilePreset', 'river'), isFalse);
    Set<String> materials() => ids(
      workspace.project!.smartTileCatalog.materials,
      (material) => material.id,
    );
    expect(materials(), containsAll(['grass', 'flowers', 'sea']));
    expect(materials(), isNot(contains('foam')));
    expect(
      ids(workspace.project!.smartTileCatalog.atlases, (atlas) => atlas.id),
      {'atlas_near', 'atlas_far'},
    );
    expect(
      ids(workspace.visualProject!.tilesets, (tileset) => tileset.id),
      contains('far_sheet'),
    );

    await workspace.ensureResourceKind('model3d', placeableOnly: true);

    expect(materials(), containsAll(['grass', 'flowers']));
    expect(workspace.hasResourceClosure('smartTilePreset', 'meadow'), isTrue);
  });

  test(
    'choosing a listed terrain resolves it before arming the brush',
    () async {
      final state = MapWorkspaceEditingState();
      final binding = MapBuilderResourceBinding(
        maps: workspace,
        view: () => state,
        visuals: () => null,
        isActive: () => true,
        changed: () {},
      );
      await binding.load();
      expect(workspace.active, isNotNull);
      expect(
        workspace.hasResourceClosure('smartTilePreset', 'meadow'),
        isFalse,
      );

      await binding.use(item('meadow'));

      expect(binding.problem, isNull);
      expect(binding.armed?.id, 'meadow');
      expect(state.tool, StudioMapTool.terrain);
      expect(state.terrainMaterialId, 'grass');
      expect(workspace.hasResourceClosure('smartTilePreset', 'meadow'), isTrue);
      expect(
        ids(
          workspace.project!.smartTileCatalog.materials,
          (material) => material.id,
        ),
        containsAll(['grass', 'flowers']),
      );
    },
  );

  test('a full family load still resolves every terrain dependency', () async {
    await workspace.ensureResourceKind('smartTilePreset');

    expect(
      ids(
        workspace.project!.smartTileCatalog.materials,
        (material) => material.id,
      ),
      {'grass', 'flowers', 'sea', 'foam'},
    );
    expect(workspace.hasResourceClosure('smartTilePreset', 'river'), isTrue);
  });
}
