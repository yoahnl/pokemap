import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_ramp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_ramp_editor.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';

void main() {
  test('the slope eraser cannot detach an automatic stair ramp', () {
    final (document, commands, model) = fixture();
    commands.place(model, const GridPos(x: 3, y: 5));
    final before = document.current;
    final stroke = SpatialTerrainStroke(
      source: before,
      models: commands.project.models3d,
      mode: SpatialTerrainMode.ramp,
      level: 0,
      erase: true,
      origin: const GridPos(x: 3, y: 4),
    );
    expect(stroke.error, contains('escalier'));
    expect(stroke.preview, before);
    expect(stroke.commit, throwsStateError);
    expect(document.current, before);
  });

  testWidgets(
    'automatic ramps direct the user to the stair rather than editable slope fields',
    (tester) async {
      final (document, commands, model) = fixture();
      commands.place(model, const GridPos(x: 3, y: 5));
      final view = MapWorkspaceViewState();
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 350,
                child: SpatialRampEditor(
                  document: document,
                  project: commands.project,
                  view: view,
                  onChanged: () {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Pente liée à un escalier'), findsOneWidget);
      expect(find.byKey(const ValueKey('spatial-ramp-preview')), findsNothing);
      final ramp = document.current.spatialScene!.navigation.ramps.single;
      expect(
        () => SpatialRampEditingCommands(
          document,
          project: commands.project,
        ).preview(ramp.copyWith(highLevel: 8)),
        throwsFormatException,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'duplicating onto a higher plateau anchors both the model and its ramp',
    () {
      final (document, commands, model) = fixture();
      final raised = const SpatialMapOperations().setLevels(document.current, [
        const SpatialCellLevel(x: 4, z: 5, level: 4),
      ]);
      document.commit(raised);
      final source = commands.place(model, const GridPos(x: 3, y: 5));
      commands.duplicate(source.id);
      expect(commands.selected()!.position.y, 1);
      final ramp = document.current.spatialScene!.navigation.ramps
          .where((ramp) => ramp.surfaceInstanceId == commands.selected()!.id)
          .single;
      expect(ramp.lowLevel, 4);
      expect(ramp.highLevel, 8);
      final copied = document.current;
      document.restore(redo: false);
      expect(document.current.spatialScene!.instances, hasLength(1));
      document.restore(redo: true);
      expect(document.current, copied);
    },
  );
  test('one placement binds stairs and one move rotates both with undo redo and deletion', () {
    final (document, commands, model) = fixture();
    final instance = commands.place(model, const GridPos(x: 3, y: 5));
    expect(
      document.current.spatialScene!.navigation.ramps.single.surfaceInstanceId,
      instance.id,
    );
    final placed = document.current;
    commands.update(instance.id, x: 7.5, z: 7.5, rotation: 90);
    final moved = document.current;
    expect(
      moved.spatialScene!.navigation.ramps.single.direction,
      SpatialRampDirection.west,
    );
    expect(moved.spatialScene!.navigation.ramps.single.x, 5.5);
    document.restore(redo: false);
    expect(document.current, placed);
    document.restore(redo: true);
    expect(document.current, moved);
    commands.delete(instance.id);
    expect(document.current.spatialScene!.instances, isEmpty);
    expect(document.current.spatialScene!.navigation.ramps, isEmpty);
    document.restore(redo: false);
    expect(document.current, moved);
  });

  test('stair duplication finds an adjacent free place and creates a distinct ramp', () {
    final (document, commands, model) = fixture();
    final instance = commands.place(model, const GridPos(x: 3, y: 5));
    commands.duplicate(instance.id);
    final scene = document.current.spatialScene!;
    expect(scene.instances, hasLength(2));
    expect(scene.navigation.ramps, hasLength(2));
    expect(
      scene.navigation.ramps.map((ramp) => ramp.surfaceInstanceId).toSet(),
      hasLength(2),
    );
    expect(commands.selected()!.position, isNot(instance.position));
    expect(MapData.fromJson(document.current.toJson()), document.current);
  });

  test('moving stairs never anchors the base on its own sloping surface', () {
    final (document, commands, model) = fixture();
    final instance = commands.place(model, const GridPos(x: 3, y: 5));
    commands.update(instance.id, rotation: 180);
    commands.update(instance.id, x: 3.75, z: 5.75);
    expect(commands.selected()!.position.y, 0);
    expect(document.current.spatialScene!.navigation.ramps.single.lowLevel, 0);
  });
}

(EditableMapDocument, SpatialModelEditingCommands, ProjectModel3dEntry)
fixture() {
  final model = ProjectModel3dEntry(
    id: 'stairs',
    name: 'Escalier',
    sourceAssetId: 'stair-source',
    relativePath: 'assets/models3d/stairs.glb',
    inspection: Model3dInspection(
      bounds: Model3dBounds(
        min: Model3dVector3(x: -.5, y: 0, z: -2),
        max: Model3dVector3(x: .5, y: 1, z: 0),
      ),
      meshCount: 1,
      triangleCount: 4,
    ),
    rampProfile: Model3dRampProfile(
      x: -.5,
      z: -2,
      width: 1,
      depth: 2,
      lowHeight: 0,
      highHeight: 1,
      direction: SpatialRampDirection.north,
    ),
  );
  final map = MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v9,
    size: const GridSize(width: 12, height: 12),
    spatialScene: MapSpatialScene(width: 12, depth: 12, levelHeight: .25),
  );
  final document = EditableMapDocument(
    MapWorkspaceDocument(map: map, mapId: map.id, revision: 'test'),
  );
  return (
    document,
    SpatialModelEditingCommands(
      document,
      ProjectManifest(
        name: 'Stairs',
        maps: [],
        tilesets: [],
        models3d: [model],
      ),
    ),
    model,
  );
}
