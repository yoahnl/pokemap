import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_actor_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  final referencePath = Platform.environment['AVELUNE_STD06_DOOR_REFERENCE'];
  testWidgets('Studio edits and publishes an actual converted arrival route', (
    tester,
  ) async {
    final reference = (await tester.runAsync(
      () async =>
          jsonDecode(await File(referencePath!).readAsString())
              as Map<String, dynamic>,
    ))!;
    final projectPath = reference['projectFilePath'] as String;
    final sessions = LocalProjectSessionAdapter();
    final session = (await tester.runAsync(() => sessions.open(projectPath)))!;
    addTearDown(() => sessions.close(session));
    final maps = LocalMapWorkspaceAdapter();
    final project = (await tester.runAsync(() => maps.loadProject(session)))!;
    final source = project.scenes.firstWhere(
      (scene) => scene.graph.nodes.any(
        (node) =>
            node.payload is SceneActionPayload &&
            (node.payload as SceneActionPayload).interactiveCommand
                is SceneActorRouteInteractiveCommand,
      ),
    );
    final node = source.graph.nodes.firstWhere(
      (node) =>
          node.payload is SceneActionPayload &&
          (node.payload as SceneActionPayload).interactiveCommand
              is SceneActorRouteInteractiveCommand,
    );
    final original = node.payload as SceneActionPayload;
    SceneActionPayload? edited;
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: SceneActorActionForm(
                project: project,
                commandId: NarrativeCommandIds.actorRoute,
                current: original,
                loadMap: (id) async => (await maps.loadMap(
                  session,
                  project.maps.singleWhere((entry) => entry.id == id),
                )).map,
                onApply: (payload) => edited = payload as SceneActionPayload,
              ),
            ),
          ),
        ),
      ),
    );
    for (var tick = 0; tick < 100; tick++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
      final buttons = tester.widgetList<StudioButton>(
        find.byType(StudioButton),
      );
      if (buttons.any(
        (button) =>
            button.label == 'Appliquer l’action' && button.onPressed != null,
      )) {
        break;
      }
    }
    final duration = find.descendant(
      of: find.byKey(const ValueKey('actor-step-0-duration')),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(duration);
    await tester.enterText(duration, '375');
    await tester.pump();
    final apply = find.byWidgetPredicate(
      (widget) =>
          widget is StudioButton && widget.label == 'Appliquer l’action',
    );
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pump();
    expect(edited, isNotNull);
    final command =
        edited!.interactiveCommand as SceneActorRouteInteractiveCommand;
    expect(
      command.steps.whereType<SceneActorMoveStep>().single.durationMs,
      375,
    );
    final updated = SceneAsset.fromJson({
      ...source.toJson(),
      'graph': {
        ...source.graph.toJson(),
        'nodes': [
          for (final current in source.graph.nodes)
            if (current.id == node.id)
              {...current.toJson(), 'payload': edited!.toJson()}
            else
              current.toJson(),
        ],
      },
    });
    final adapter = LocalSceneAdapter(session: session, mapAdapter: maps);
    final publication = await tester.runAsync(
      () => adapter.publishScene(base: source, current: updated),
    );
    expect(publication!.scene, updated);
    final reopened = (await tester.runAsync(() => maps.loadProject(session)))!;
    expect(
      reopened.scenes.singleWhere((scene) => scene.id == source.id),
      updated,
    );
    final marker = File('${File(referencePath!).parent.path}/studio-edit.json');
    await tester.runAsync(
      () => marker.writeAsString(
        jsonEncode({
          'kind': 'std06StudioEditedConvertedRoute',
          'projectFilePath': '$projectPath/project.json',
          'sceneId': source.id,
          'nodeId': node.id,
          'durationMs': 375,
          'publishedThrough': 'LocalSceneAdapter.scene.upsert',
          'reopenVerified': true,
        }),
      ),
    );
  }, skip: referencePath == null);
}
