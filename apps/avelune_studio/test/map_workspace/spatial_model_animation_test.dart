import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/resources/model_animation_controls.dart';

void main() {
  test('placed clips, speed and loop survive edits, duplication and undo', () {
    final model = _model();
    final project = ProjectManifest(
      name: 'Animation',
      maps: [],
      tilesets: [],
      models3d: [model],
    );
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v9,
      size: const GridSize(width: 4, height: 4),
      spatialScene: MapSpatialScene(width: 4, depth: 4),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'test'),
    );
    final commands = SpatialModelEditingCommands(document, project);
    final instance = commands.place(model, const GridPos(x: 1, y: 1));
    commands.update(
      instance.id,
      animationIndex: 1,
      animationLoop: false,
      animationSpeed: .25,
    );
    final animated = commands.selected()!;
    commands.update(instance.id, x: 2.5);
    expect(commands.selected()!.animationIndex, 1);
    expect(commands.selected()!.animationSpeed, .25);
    commands.duplicate(instance.id);
    expect(commands.selected()!.animationIndex, 1);
    expect(commands.selected()!.animationLoop, isFalse);
    expect(commands.selected()!.animationSpeed, .25);
    final beforeInvalid = document.current;
    expect(
      () => commands.update(document.selectedId!, animationIndex: 99),
      throwsStateError,
    );
    expect(
      () => commands.update(document.selectedId!, animationSpeed: 0),
      throwsFormatException,
    );
    expect(document.current, beforeInvalid);
    commands.update(document.selectedId!, clearAnimation: true);
    expect(commands.selected()!.animationIndex, isNull);
    document.restore(redo: false);
    expect(commands.selected()!.animationIndex, 1);
    expect(animated.animationIndex, 1);
    expect(MapData.fromJson(document.current.toJson()), document.current);
  });

  testWidgets(
    'animation UI selects clips and controls temporary preview separately',
    (tester) async {
      int? clip;
      var loop = false, paused = false;
      var speed = 1.0, replayCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: StatefulBuilder(
                builder: (context, setState) => ModelAnimationControls(
                  clips: _model().inspection.animations,
                  animationIndex: clip,
                  loop: loop,
                  speed: speed,
                  paused: paused,
                  onClip: (value) => setState(() => clip = value),
                  onLoop: (value) => setState(() => loop = value),
                  onSpeed: (value) => setState(() => speed = value),
                  onPause: () => setState(() => paused = !paused),
                  onReplay: () => replayCount++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Pose de repos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open · 0.12 s').last);
      await tester.pumpAndSettle();
      expect(clip, 0);
      await tester.tap(find.text('Une fois · garder la pose finale'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('En boucle').last);
      await tester.pumpAndSettle();
      expect(loop, isTrue);
      await tester.tap(find.text('× 1.0'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('× 0.25').last);
      await tester.pumpAndSettle();
      expect(speed, .25);
      await tester.tap(find.text('Pause de l’aperçu'));
      await tester.pump();
      expect(paused, isTrue);
      expect(find.text('Reprendre l’aperçu'), findsOneWidget);
      await tester.tap(find.text('Rejouer'));
      expect(replayCount, 1);
      expect(clip, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

ProjectModel3dEntry _model() => ProjectModel3dEntry(
  id: 'door',
  name: 'Door',
  sourceAssetId: 'model3d_door',
  relativePath: 'assets/models3d/door.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 1, y: 1, z: .1),
    ),
    meshCount: 1,
    triangleCount: 4,
    animations: [
      Model3dAnimation(index: 0, name: 'Open', durationSeconds: .116667),
      Model3dAnimation(index: 1, name: 'Close', durationSeconds: .116667),
    ],
  ),
);
