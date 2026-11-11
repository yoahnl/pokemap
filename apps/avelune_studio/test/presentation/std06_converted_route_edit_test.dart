import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_actor_action_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  final referencePath = Platform.environment['AVELUNE_STD06_DOOR_REFERENCE'];
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Studio edits and publishes an actual converted arrival route',
    () async {
      final reference = jsonDecode(
        await File(referencePath!).readAsString(),
      ) as Map<String, dynamic>;
      final projectPath = reference['projectFilePath'] as String;
      final sessions = LocalProjectSessionAdapter();
      final session = await sessions.open(projectPath);
      addTearDown(() => sessions.close(session));
      final maps = LocalMapWorkspaceAdapter();
      final project = await maps.loadProject(session);
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
      final ready = Completer<void>();
      late SceneActorActionDraft draft;
      draft = SceneActorActionDraft(
        project: project,
        commandId: NarrativeCommandIds.actorRoute,
        current: original,
        changed: () {
          if (!draft.loading && !ready.isCompleted) ready.complete();
        },
        loadMap: (id) async => (await maps.loadMap(
          session,
          project.maps.singleWhere((entry) => entry.id == id),
        )).map,
      );
      addTearDown(draft.dispose);
      await ready.future;
      draft.steps.first.durationText = '375';
      final edited = draft.payload;
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
                {...current.toJson(), 'payload': edited.toJson()}
              else
                current.toJson(),
          ],
        },
      });
      final adapter = LocalSceneAdapter(session: session, mapAdapter: maps);
      final publication = await adapter.publishScene(
        base: source,
        current: updated,
      );
      expect(publication.scene, updated);
      final reopened = await maps.loadProject(session);
      expect(
        reopened.scenes.singleWhere((scene) => scene.id == source.id),
        updated,
      );
      final marker = File(
        '${File(referencePath).parent.path}/studio-edit.json',
      );
      await marker.writeAsString(
        jsonEncode({
          'kind': 'std06StudioEditedConvertedRoute',
          'projectFilePath': '$projectPath/project.json',
          'sceneId': source.id,
          'nodeId': node.id,
          'durationMs': 375,
          'publishedThrough': 'LocalSceneAdapter.scene.upsert',
          'reopenVerified': true,
        }),
      );
    },
    skip: referencePath == null,
  );
}
