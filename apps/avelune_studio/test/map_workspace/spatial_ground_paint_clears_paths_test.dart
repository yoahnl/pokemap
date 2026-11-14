import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('painting a ground over a path shows the ground and undoes at once', () {
    final grass = _preset('grass', SmartTileUsage.terrain);
    final project = ProjectManifest(
      name: 'Sols',
      version: ProjectVersion.v9,
      maps: const [
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
      ],
      tilesets: const [],
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile(),
      ),
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const [
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Herbe',
            connectionGroupId: 'grass',
          ),
          ProjectSmartTileMaterial(
            id: 'sand',
            name: 'Sable',
            connectionGroupId: 'sand',
          ),
        ],
        presets: [grass, _preset('sand', SmartTileUsage.path)],
      ),
    );
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v9,
      size: const GridSize(width: 2, height: 2),
      spatialScene: MapSpatialScene(width: 2, depth: 2),
      layers: [
        _layer('sand', SmartTileUsage.path, [1, 1, 1, 1]),
        _layer('grass', SmartTileUsage.terrain, [0, 0, 0, 0]),
      ],
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
    );
    final view = MapWorkspaceEditingState()..prepareTerrainPainting(grass);

    final stroke = MapCanvasStroke.start(
      map: document.current,
      project: project,
      view: view,
      commands: MapEditingCommands(document, project),
      origin: const GridPos(x: 1, y: 0),
    )!;
    document.commit(stroke.commit());

    expect(_cells(document.current, 'grass'), [0, 1, 0, 0]);
    expect(_cells(document.current, 'sand'), [1, 0, 1, 1]);
    expect(document.undoCount, 1);

    document.restore(redo: false);
    expect(document.current, map);
  });
}

ProjectSmartTilePreset _preset(String id, SmartTileUsage usage) =>
    ProjectSmartTilePreset(
      id: id,
      name: id,
      usage: usage,
      topology: SmartTileTopology.uniform,
      templateHint: SmartTileTemplateHint.simple,
      boundaryPolicy: SmartTileBoundaryPolicy.empty,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: const SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: const SmartTileTransformPolicy(),
      defaultMaterialId: id,
      allowedMaterialIds: [id],
    );

SmartTileLayer _layer(String id, SmartTileUsage usage, List<int> cells) =>
    SmartTileLayer(
      id: id,
      name: id,
      presetId: id,
      usage: usage,
      materialPalette: ['', id],
      field: SmartTileField.cell(semanticCells: cells),
    );

List<int> _cells(MapData map, String id) => smartTileSemanticCells(
  map.layers.whereType<SmartTileLayer>().firstWhere((layer) => layer.id == id),
);
