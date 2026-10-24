import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_camera_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_commit_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('the real 3D map inspector exposes camera authoring', (
    tester,
  ) async {
    final map = MapData(
      id: 'room',
      name: 'Room',
      version: ProjectVersion.v9,
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(width: 8, depth: 8),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'initial', mapId: map.id),
    );
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    final project = ProjectManifest(
      name: 'World',
      maps: const [],
      tilesets: const [],
      settings: ProjectSettings(dimension: ProjectDimension.threeD),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: MapWorkspaceInspector(
            project: project,
            document: document,
            visuals: WorkspaceTestVisuals(),
            view: view,
            onChanged: () {},
          ),
        ),
      ),
    );
    expect(find.byType(MapCameraPanel), findsOneWidget);
    expect(find.text('Caméra du jeu'), findsOneWidget);
    expect(find.text('Perspective'), findsOneWidget);
    expect(find.text('Orthographique'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  Future<EditableMapDocument> pump(WidgetTester tester) async {
    final map = MapData(
      id: 'room',
      name: 'Room',
      version: ProjectVersion.v9,
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(width: 8, depth: 8),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'initial', mapId: map.id),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 320,
              child: StatefulBuilder(
                builder: (context, rebuild) => MapCameraPanel(
                  document: document,
                  onChanged: () => rebuild(() {}),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return document;
  }

  testWidgets('camera projection is an undoable no-code map setting', (
    tester,
  ) async {
    final document = await pump(tester);
    final original = document.current;
    expect(find.text('Perspective'), findsOneWidget);
    await tester.tap(find.text('Orthographique'));
    await tester.pumpAndSettle();
    expect(
      document.current.spatialScene!.camera.projection,
      SpatialCameraProjection.orthographic,
    );
    expect(find.text('Hauteur visible en cases'), findsOneWidget);
    expect(find.text('Champ de vision en degrés'), findsNothing);
    expect(document.canUndo, isTrue);
    document.restore(redo: false);
    expect(document.current, original);
    document.restore(redo: true);
    expect(
      document.current.spatialScene!.camera.projection,
      SpatialCameraProjection.orthographic,
    );
  });

  testWidgets('invalid camera size is rejected without document mutation', (
    tester,
  ) async {
    final document = await pump(tester);
    await tester.tap(find.text('Orthographique'));
    await tester.pumpAndSettle();
    final source = document.current;
    final field = find.byWidgetPredicate(
      (widget) =>
          widget is StudioCommitField &&
          widget.label == 'Hauteur visible en cases',
    );
    final text = find.descendant(of: field, matching: find.byType(TextField));
    await tester.ensureVisible(text);
    await tester.enterText(text, '0');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(document.current, source);
    expect(document.error, isNotNull);
    await tester.enterText(text, '16');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(document.current.spatialScene!.camera.orthographicHeight, 16);
    expect(document.error, isNull);
  });
}
