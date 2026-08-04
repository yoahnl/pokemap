import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_pattern_authoring.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_pattern_authoring_service.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:path/path.dart' as p;

void main() {
  final licensedForestPng =
      Platform.environment['POKEMAP_STN07_ERW_FOREST_PNG'];

  test(
    'STN-07 authors, persists, paints and resolves an organic forest',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_stn07_forest_',
      );
      final projectRoot = await Directory(
        p.join(sandbox.path, 'project'),
      ).create();
      await _writeProject(projectRoot);
      final transports = <_EditorTransports>[];
      addTearDown(() async {
        for (final transport in transports.reversed) {
          await transport.close();
        }
        if (await sandbox.exists()) await sandbox.delete(recursive: true);
      });

      final first = _EditorTransports.open();
      transports.add(first);
      final pattern = compileSmartTileAtlasPattern(
        id: 'organic-grove',
        name: 'Bosquet organique',
        usage: SmartTileUsage.forestSurface,
        atlas: _atlas,
        selection: const SmartTilePatternAtlasSelection(
          startColumn: 0,
          startRow: 0,
          endColumn: 1,
          endRow: 1,
        ),
        anchorColumn: 0,
        anchorRow: 0,
        repeatMode: SmartTilePatternRepeatMode.stamp,
        cellProfiles: <GridPos, SmartTilePatternCellProfile>{
          const GridPos(x: 0, y: 0): const SmartTilePatternCellProfile(
            channel: SmartTileRenderChannel.canopy,
          ),
          const GridPos(x: 1, y: 0): const SmartTilePatternCellProfile(
            channel: SmartTileRenderChannel.canopy,
          ),
          const GridPos(x: 0, y: 1): const SmartTilePatternCellProfile(
            channel: SmartTileRenderChannel.understory,
            collision: SmartTilePatternCollision.blocked,
          ),
          const GridPos(x: 1, y: 1): const SmartTilePatternCellProfile(
            channel: SmartTileRenderChannel.shadow,
            collision: SmartTilePatternCollision.passable,
          ),
        },
      );
      final authored = await SmartTilePatternAuthoringService(
        gateway: CanonicalSmartTilePatternAuthoringGateway(
          mutations: first.mutations,
          queries: first.queries,
        ),
      ).upsert(
        projectRootPath: projectRoot.path,
        pattern: pattern,
      );
      expect(authored.pattern, pattern);

      final paintPlan = await first.mutations.plan(
        projectRoot.path,
        actionId: 'smart_tile.pattern.paint',
        parameters: const <String, Object?>{
          'mapId': 'forest-map',
          'layerId': 'forest',
          'patternId': 'organic-grove',
          'strokeId': 'grove-1',
          'collisionLayerId': 'collision',
          'selection': <String, Object?>{
            'kind': 'stamp',
            'anchor': <String, int>{'x': 1, 'y': 1},
          },
        },
        idempotencyKey: 'stn07_paint',
        requestId: 'stn07_paint',
      );
      await first.mutations.apply(
        paintPlan,
        operationId: 'stn07_apply',
      );
      await first.close();

      // Reopen every transport so the acceptance proof reads project.json and
      // map.json instead of trusting an in-memory editor session.
      final reopened = _EditorTransports.open();
      transports.add(reopened);
      final disk = await reopened.queries.open(projectRoot.path);
      final map =
          disk.maps.singleWhere((candidate) => candidate.id == 'forest-map');
      final forest = map.layers.whereType<SmartTileLayer>().single;
      final collision = map.layers.whereType<CollisionLayer>().single;

      expect(
        disk.manifest.smartTileCatalog.patterns.single,
        pattern,
      );
      expect(forest.patternStrokes.single.patternId, pattern.id);
      expect(collision.collisions[2 * map.size.width + 1], isTrue);
      expect(collision.collisions[2 * map.size.width + 2], isFalse);

      final background = resolveSmartTileLayerVisuals(
        map: map,
        layer: forest,
        catalog: disk.manifest.smartTileCatalog,
        pass: SmartTileVisualPass.background,
      );
      final foreground = resolveSmartTileLayerVisuals(
        map: map,
        layer: forest,
        catalog: disk.manifest.smartTileCatalog,
        pass: SmartTileVisualPass.foreground,
      );
      expect(
        background.map((visual) => visual.channel),
        containsAll(<SmartTileRenderChannel>[
          SmartTileRenderChannel.ground,
          SmartTileRenderChannel.understory,
          SmartTileRenderChannel.shadow,
        ]),
      );
      expect(
        foreground.map((visual) => visual.channel),
        everyElement(SmartTileRenderChannel.canopy),
      );
      expect(
        foreground.map((visual) => GridPos(x: visual.cellX, y: visual.cellY)),
        containsAll(<GridPos>[
          const GridPos(x: 1, y: 1),
          const GridPos(x: 2, y: 1),
        ]),
      );

      final visualPlan = buildMapVisualCompositionPlan(map);
      expect(visualPlan.diagnostics, isEmpty);
      expect(visualPlan.plan, isNotNull);
      expect(
        visualPlan.plan!.steps.map((step) => step.kind),
        contains(MapVisualCompositionStepKind.smartTileLayer),
      );
    },
  );

  test(
    'projects a user-owned ERW tree into canopy, trunk and collision masks',
    () async {
      final bytes = await File(licensedForestPng!).readAsBytes();
      final image = img.decodeImage(bytes);
      expect(image, isNotNull);
      expect(image!.width % 32, 0);
      expect(image.height % 32, 0);
      final columns = image.width ~/ 32;
      final rows = image.height ~/ 32;
      final atlas = ProjectSmartTileAtlas(
        id: 'licensed-erw-tree-atlas',
        name: 'Arbre ERW local',
        tilesetId: 'licensed-erw-tree',
        columns: columns,
        rows: rows,
      );
      final profiles = <GridPos, SmartTilePatternCellProfile>{
        for (var y = 0; y < rows; y++)
          for (var x = 0; x < columns; x++)
            GridPos(x: x, y: y): SmartTilePatternCellProfile(
              channel: y < rows - 2
                  ? SmartTileRenderChannel.canopy
                  : SmartTileRenderChannel.understory,
              collision: y == rows - 1 && x == columns ~/ 2
                  ? SmartTilePatternCollision.blocked
                  : SmartTilePatternCollision.inherit,
            ),
      };
      final pattern = compileSmartTileAtlasPattern(
        id: 'licensed-erw-tree-pattern',
        name: 'Arbre ERW local',
        usage: SmartTileUsage.forestSurface,
        atlas: atlas,
        selection: SmartTilePatternAtlasSelection(
          startColumn: 0,
          startRow: 0,
          endColumn: columns - 1,
          endRow: rows - 1,
        ),
        anchorColumn: columns ~/ 2,
        anchorRow: rows - 1,
        repeatMode: SmartTilePatternRepeatMode.stamp,
        cellProfiles: profiles,
      );
      final projection = projectSmartTilePatternAtlasSelection(pattern);

      expect(pattern.width, columns);
      expect(pattern.height, rows);
      expect(
        pattern.cells
            .where((cell) =>
                cell.parts.single.channel == SmartTileRenderChannel.canopy)
            .length,
        columns * (rows - 2),
      );
      expect(
        pattern.cells.where(
          (cell) => cell.collision == SmartTilePatternCollision.blocked,
        ),
        hasLength(1),
      );
      expect(projection, isNotNull);
      expect(projection!.cellProfiles, profiles);
    },
    skip: licensedForestPng == null
        ? 'Set POKEMAP_STN07_ERW_FOREST_PNG to a locally licensed tree PNG.'
        : false,
  );
}

Future<void> _writeProject(Directory root) async {
  final manifest = ProjectManifest(
    name: 'STN-07 organic forest',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'forest-map',
        name: 'Forêt',
        relativePath: 'maps/forest.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'forest-tileset',
        name: 'Forêt synthétique',
        relativePath: 'assets/forest.png',
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: const <ProjectSmartTileAtlas>[_atlas],
      materials: const <ProjectSmartTileMaterial>[_material],
      presets: const <ProjectSmartTilePreset>[_preset],
    ),
  );
  const map = MapData(
    id: 'forest-map',
    name: 'Forêt',
    version: ProjectVersion.v6,
    size: GridSize(width: 4, height: 4),
    visualStack: MapVisualStackConfig.canonicalV1,
    layers: <MapLayer>[
      SmartTileLayer(
        id: 'forest',
        name: 'Forêt organique',
        presetId: 'forest-preset',
        usage: SmartTileUsage.forestSurface,
        materialPalette: <String>['', 'forest-material'],
        field: SmartTileField.cell(
          semanticCells: <int>[
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
          ],
        ),
      ),
      CollisionLayer(
        id: 'collision',
        name: 'Collisions',
        collisions: <bool>[
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
        ],
      ),
    ],
  );
  final mapFile = File(p.join(root.path, 'maps', 'forest.json'));
  await mapFile.parent.create(recursive: true);
  await File(p.join(root.path, 'project.json')).writeAsString(
    jsonEncode(manifest.toJson()),
    flush: true,
  );
  await mapFile.writeAsString(jsonEncode(map.toJson()), flush: true);
}

const _atlas = ProjectSmartTileAtlas(
  id: 'forest-atlas',
  name: 'Atlas forêt',
  tilesetId: 'forest-tileset',
  columns: 2,
  rows: 2,
);

const _material = ProjectSmartTileMaterial(
  id: 'forest-material',
  name: 'Forêt',
  connectionGroupId: 'forest',
);

const _preset = ProjectSmartTilePreset(
  id: 'forest-preset',
  name: 'Sol forestier',
  usage: SmartTileUsage.forestSurface,
  topology: SmartTileTopology.uniform,
  templateHint: SmartTileTemplateHint.simple,
  coveragePolicy: SmartTileCoveragePolicy.complete,
  coverageProfile: SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.template,
  ),
  transformPolicy: SmartTileTransformPolicy(),
  defaultMaterialId: 'forest-material',
  allowedMaterialIds: <String>['forest-material'],
  rules: <SmartTileRule>[
    SmartTileRule(
      id: 'forest-ground',
      centerMatch: SmartTileSlotMatch.material('forest-material'),
      candidates: <SmartTileCandidate>[
        SmartTileCandidate(
          id: 'forest-ground-frame',
          parts: <SmartTileVisualPart>[
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(
                  atlasId: 'forest-atlas',
                  column: 0,
                  row: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

final class _EditorTransports {
  _EditorTransports._({required this.queries, required this.mutations});

  factory _EditorTransports.open() {
    const reader = EditorProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    return _EditorTransports._(
      queries: queries,
      mutations: AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      ),
    );
  }

  final AuthoringQueryAdapter queries;
  final AuthoringMutationAdapter mutations;
  bool _closed = false;

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await mutations.closeAll();
    await queries.closeAll();
  }
}
