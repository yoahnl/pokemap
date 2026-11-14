import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../application/spatial_border_commands_test.dart' show borderDocument;
import '../support/border_catalog_fixture.dart';
import '../support/map_workspace_fixture.dart';
import '../support/spatial_border_fixture.dart';

({ProjectManifest project, MapData map}) eraseFixture(
  bool spatial, {
  Model3dVector3? offset,
}) {
  final project = spatial
      ? spatialBorderProject()
      : workspaceProject.copyWith(borderCatalog: testBorderCatalog());
  final source = spatial
      ? spatialBorderMap().copyWith(
          spatialScene: spatialBorderMap().spatialScene!.copyWith(
            instances: [
              SpatialModelInstance(
                id: 'foreign',
                modelId: 'oak',
                position: Model3dVector3(x: .5, y: 0, z: .5),
              ),
            ],
          ),
        )
      : workspaceMap('a');
  final document = borderDocument(source);
  final commands = MapBorderEditingCommands(document, project);
  commands.finish(
    MapBorderDrawingDraft.start(
      mapId: source.id,
      mapSize: source.size,
      blueprintId: spatial ? 'fence' : 'muret',
      origin: const GridPos(x: 2, y: 5),
      sourceMap: source,
      sourceProject: project,
      featureId: 'line',
      seed: BorderSignedInt64.fromInt(17),
    ).addAngle(const GridPos(x: 8, y: 5)),
  );
  if (offset != null) {
    commands.setSpatialOffset(
      layerId: 'studio-bordures',
      featureId: 'line',
      offset: offset,
      source: traceFeature(document.current),
    );
    commands.applyExisting(
      commands.previewExisting(layerId: 'studio-bordures', featureId: 'line'),
      source: document.current,
      sourceProject: project,
    );
  }
  return (project: project, map: document.current);
}

BorderFeature traceFeature(MapData map) =>
    map.layers.whereType<BorderLayer>().single.content.features.single;

void expectSplit(MapData map) {
  final feature = traceFeature(map);
  final strokes = (feature.geometry as BorderStrokeGeometry).strokes;
  expect(strokes, hasLength(2));
  expect(strokes.map((stroke) => stroke.points.length), [3, 3]);
  expect(
    strokes.expand((stroke) => stroke.points),
    isNot(contains(const GridPos(x: 5, y: 5))),
  );
  expect(feature.materialization, isNotNull);
}

typedef EraseHost = ({
  EditableMapDocument document,
  MapEditingViewportSession view,
  ProjectManifest project,
  EraseVisuals visuals,
  VoidCallback refresh,
});

void armErase(EraseHost host) {
  final feature = MapBorderEditingCommands(
    host.document,
    host.project,
  ).visibleFeatures.first;
  host.view.prepareBorderErase((
    layerId: feature.layer.id,
    featureId: feature.feature.id,
  ));
  host.refresh();
}

Future<EraseHost> pumpEraseHost(
  WidgetTester tester,
  bool spatial, {
  Model3dVector3? offset,
}) async {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final fixture = eraseFixture(spatial, offset: offset);
  final document = borderDocument(fixture.map);
  final view = MapEditingViewportSession()
    ..tool = StudioMapTool.border
    ..borderBlueprintId = spatial ? 'fence' : 'muret';
  final controller = MapWorkspaceController(
    workspaceSession,
    WorkspaceMemoryPort(),
  )..project = fixture.project;
  final visuals = EraseVisuals();
  addTearDown(view.dispose);
  addTearDown(controller.dispose);
  late VoidCallback refresh;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            refresh = () => setState(() {});
            return Column(
              children: [
                Expanded(
                  child: spatial
                      ? SpatialMapEditingViewport(
                          document: document,
                          controller: controller,
                          project: fixture.project,
                          visuals: visuals,
                          view: view,
                          onChanged: refresh,
                        )
                      : MapEditingViewport2D(
                          document: document,
                          project: fixture.project,
                          visuals: visuals,
                          view: view,
                          onChanged: refresh,
                          gestureGeneration: 0,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return (
    document: document,
    view: view,
    project: fixture.project,
    visuals: visuals,
    refresh: refresh,
  );
}

class EraseVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  MapData? renderedMap;
  @override
  Widget canvas(
    MapData map, {
    MapPlacedElement? placedElementPreview,
    Color? collisionColor,
  }) {
    renderedMap = map;
    return const SizedBox.expand();
  }

  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}
