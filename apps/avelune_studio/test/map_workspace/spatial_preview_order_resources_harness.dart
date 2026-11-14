import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_atmosphere_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_runtime/map_runtime.dart';

import '../support/map_workspace_fixture.dart';
import 'spatial_preview_order_resources_reads.dart';

final class PreviewOrderHarness {
  late Directory root;
  late ProjectManifest project;
  late EditableMapDocument document;
  late ProfiledVisuals visuals;
  final reads = PreviewReads();
  final view = MapEditingViewportSession();
  final controller = MapWorkspaceController(
    workspaceSession,
    WorkspaceMemoryPort(),
  );

  static Future<PreviewOrderHarness> create() async {
    final h = PreviewOrderHarness();
    h.root = await Directory.systemTemp.createTemp('spatial-preview-order-');
    await Directory('${h.root.path}/maps').create();
    await Directory('${h.root.path}/assets').create();
    final map = MapData(
      id: 'a',
      name: 'A',
      version: ProjectVersion.v9,
      size: const GridSize(width: 2, height: 2),
      spatialScene: MapSpatialScene(width: 2, depth: 2),
      entities: const [
        MapEntity(
          id: 'npc',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 0, y: 0),
          npc: MapEntityNpcData(characterId: 'guide'),
        ),
      ],
      layers: [
        for (final id in ['one', 'two'])
          SmartTileLayer(
            id: id,
            name: id,
            presetId: id,
            usage: SmartTileUsage.terrain,
            materialPalette: ['', 'grass'],
            field: const SmartTileField.cell(semanticCells: [1, 1, 1, 1]),
          ),
      ],
    );
    h.project = ProjectManifest(
      name: 'Preview',
      settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      version: ProjectVersion.v9,
      maps: const [
        ProjectMapEntry(id: 'a', name: 'A', relativePath: 'maps/a.json'),
      ],
      tilesets: [
        for (final id in ['one', 'two', 'fresh'])
          ProjectTilesetEntry(id: id, name: id, relativePath: '$id.png'),
      ],
      characters: const [
        ProjectCharacterEntry(id: 'guide', name: 'Guide', tilesetId: 'one'),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const [
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'grass',
          ),
        ],
        atlases: [
          for (final id in ['one', 'two', 'fresh'])
            ProjectSmartTileAtlas(
              id: id,
              name: id,
              tilesetId: id,
              columns: 1,
              rows: 1,
            ),
        ],
        presets: [
          for (final id in ['one', 'two', 'fresh']) _preset(id),
        ],
      ),
    );
    await File('${h.root.path}/project.json')
        .writeAsString(jsonEncode(h.project.toJson()));
    await File('${h.root.path}/maps/a.json')
        .writeAsString(jsonEncode(map.toJson()));
    await File('${h.root.path}/maps/a.atmosphere.json').writeAsString(
      jsonEncode(
        SpatialAtmosphereDocument(
          mapId: 'a',
          settings: SpatialAtmosphereSettings(),
        ).toJson(),
      ),
    );
    await File('${h.root.path}/assets/.pokemap-assets.json')
        .writeAsString('${jsonEncode(AssetCatalog().toJson())}${' ' * 890000}');
    for (final entry in [
      'one.png',
      'two.png',
      'new.png',
      'fresh.png',
    ].indexed) {
      final image = img.Image(width: 32, height: 32)
        ..setPixelRgb(0, 0, entry.$1 * 80, 0, 0);
      await File('${h.root.path}/${entry.$2}')
          .writeAsBytes(img.encodePng(image));
    }
    h.document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: 'a', revision: 'initial'),
    );
    h.document.atmosphere = await MapAtmosphereController.open(
      workspaceSession,
      'a',
      _AtmospherePort(),
    );
    h.visuals = ProfiledVisuals(h);
    return h;
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpatialMapEditingViewport(
              document: document,
              controller: controller,
              project: project,
              visuals: visuals,
              view: view,
              onChanged: () {},
            ),
          ),
        ),
      );
      await visuals.pending;
    });
    await tester.pump();
    if (visuals.loadFailure != null) {
      throw StateError(visuals.loadFailure.toString());
    }
  }

  Future<void> dispose() async {
    view.dispose();
    controller.dispose();
    document.atmosphere?.dispose();
    await root.delete(recursive: true);
  }
}

final class ProfiledVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  ProfiledVisuals(this.h);
  final PreviewOrderHarness h;
  Future<void> pending = Future.value();
  final profiles = <RuntimeMapBundleLoadProfile>[];
  var disposals = 0;
  int? lastRaster;
  List<String> loadedPaths = [];
  Object? loadFailure;

  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) {
    final result = _load(map);
    pending = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        loadFailure = error;
      },
    );
    return result;
  }

  Future<SpatialNpcPreview> _load(MapData map) async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: '${h.root.path}/project.json',
      mapId: map.id,
      preloadedManifest: h.project,
      profileSink: profiles.add,
    );
    loadedPaths = bundle.runtimeImageAbsolutePathsById.values.toList();
    final bytes = <int>[];
    for (final path in bundle.runtimeImageAbsolutePathsById.values) {
      bytes.addAll(await File(path).readAsBytes());
    }
    lastRaster = Object.hashAll(bytes);
    return SpatialNpcPreview({}, () => disposals++);
  }

  @override
  Future<Uint8List> readGroundImage(String id) async => Uint8List(0);
  @override
  Future<Uint8List> readModel(String id) async => Uint8List(0);
}

final class _AtmospherePort implements MapAtmospherePort {
  @override
  Future<MapAtmosphereState> loadAtmosphere(
    ProjectSession session,
    String mapId,
  ) async => MapAtmosphereState(
    settings: SpatialAtmosphereSettings(),
    revision: 'initial',
  );
  @override
  Future<MapAtmosphereState> saveAtmosphere(
    ProjectSession session,
    String mapId,
    SpatialAtmosphereSettings settings,
    String expectedRevision,
  ) async => MapAtmosphereState(settings: settings, revision: 'saved');
}

ProjectSmartTilePreset _preset(String id) => ProjectSmartTilePreset(
  id: id,
  name: id,
  usage: SmartTileUsage.terrain,
  topology: SmartTileTopology.uniform,
  templateHint: SmartTileTemplateHint.simple,
  coveragePolicy: SmartTileCoveragePolicy.sparse,
  coverageProfile: const SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.template,
  ),
  transformPolicy: const SmartTileTransformPolicy(),
  defaultMaterialId: 'grass',
  allowedMaterialIds: ['grass'],
  rules: [
    SmartTileRule(
      id: 'fill',
      centerMatch: const SmartTileSlotMatch.material('grass'),
      candidates: [
        SmartTileCandidate(
          id: 'fill',
          parts: [
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(atlasId: id, column: 0, row: 0),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
