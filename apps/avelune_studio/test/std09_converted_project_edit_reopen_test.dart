import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/scenes/application/scene_dialogue_results.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final referencePath = Platform.environment['AVELUNE_STD09_STUDIO_REFERENCE'];

  test('STD09 Studio publishes converted dialogue condition door and route then closes and reopens', () async {
    final reference = jsonDecode(
      await File(referencePath!).readAsString(),
    ) as Map<String, dynamic>;
    expect(reference['kind'], 'std09OriginalPublicWorkflow');
    expect(reference['writerVerified'], isTrue);
    expect(reference['sourceScriptsExecuted'], 0);
    final original = Directory(reference['projectPath'] as String);
    final before = await _hashes(original);
    final temporary = await Directory.systemTemp.createTemp(
      'std09-studio-edit-',
    );
    addTearDown(() => temporary.delete(recursive: true));
    final copy = Directory(
      '${await temporary.resolveSymbolicLinks()}/converted',
    );
    await copy.create();
    for (final entity
        in await original.list(recursive: true, followLinks: false).toList()) {
      final destination =
          '${copy.path}/${entity.path.substring(original.path.length + 1)}';
      if (entity is Directory) {
        await Directory(destination).create(recursive: true);
      } else {
        expect(
          entity,
          isA<File>(),
          reason: 'Qualification copies only regular project resources.',
        );
        await File(destination).parent.create(recursive: true);
        await (entity as File).copy(destination);
      }
    }
    final editors = await _StudioEditors.open(copy.path);
    addTearDown(editors.close);
    final initial = editors.maps.project!;
    final nativeOwners = {
      for (final value in reference['nativeEntities'] as List)
        (value as Map<String, dynamic>)['sourceIdentity'] as String,
    };
    final convertedScenes = initial.scenes
        .where(
          (scene) =>
              nativeOwners.contains(scene.metadata['sourceEventIdentity']),
        )
        .toList();
    expect(convertedScenes, isNotEmpty);
    final routeScene = convertedScenes.firstWhere(
      (scene) => scene.graph.nodes.any((node) {
        final command = _command(node);
        return command is SceneActorRouteInteractiveCommand &&
            command.steps.any((step) => step is SceneActorMoveStep);
      }),
    );
    final doorScene = convertedScenes.firstWhere(
      (scene) =>
          scene.metadata['sourceEventIdentity'] ==
              routeScene.metadata['sourceEventIdentity'] &&
          scene.graph.nodes.any(
            (node) => _command(node) is SceneWarpInteractiveCommand,
          ),
    );
    final dialogueId = initial.dialogues.first.id;
    expect(
      await editors.dialogues.open(dialogueId),
      isTrue,
      reason: editors.dialogues.error,
    );
    final line = editors.dialogues.active!.document.nodes
        .expand((node) => node.steps)
        .whereType<DeLineStep>()
        .first;
    final editedText = '${line.body} — STD09 Studio';
    expect(editors.dialogues.updateLine(line.id, text: editedText), isTrue);
    expect(
      await editors.dialogues.save(),
      isTrue,
      reason: editors.dialogues.error,
    );
    expect(editors.dialogues.active!.dirty, isFalse);

    expect(
      await editors.events.prepare(),
      isTrue,
      reason: editors.events.error,
    );
    final conditional = editors.events.records.firstWhere(
      (record) => record.definitionOrNull?.conditions.isNotEmpty == true,
    );
    final expression = NarrativeEventConditionExpression.not(
      conditional.expression,
    );
    expect(
      editors.events.setExpression(conditional.id, expression),
      isTrue,
      reason: editors.events.error,
    );
    if (conditional.enabledOrNull == true) {
      expect(
        editors.events.setEnabled(conditional.id, true),
        isTrue,
        reason: editors.events.error,
      );
    }
    expect(await editors.events.save(), isTrue, reason: editors.events.error);
    final editedEvent = editors.events.record(conditional.id)!;
    expect(editedEvent.expression, expression);
    expect(editedEvent.enabledOrNull, conditional.enabledOrNull);

    final expectedScenes = <String, SceneAsset>{};
    SceneAsset currentScene(String id) =>
        expectedScenes[id] ??
        editors.maps.project!.scenes.singleWhere((scene) => scene.id == id);
    final doorBase = currentScene(doorScene.id);
    final doorNode = doorBase.graph.nodes.firstWhere(
      (node) => _command(node) is SceneWarpInteractiveCommand,
    );
    final door = _command(doorNode) as SceneWarpInteractiveCommand;
    final facing = door.arrivalFacing == EntityFacing.north
        ? EntityFacing.south
        : EntityFacing.north;
    final editedDoor = SceneInteractiveCommand.fromJson({
      ...door.toJson(),
      'arrivalFacing': facing.name,
    });
    expectedScenes[doorBase.id] = _replaceCommand(
      doorBase,
      doorNode.id,
      editedDoor,
    );
    final routeBase = currentScene(routeScene.id);
    final routeNode = routeBase.graph.nodes.firstWhere((node) {
      final command = _command(node);
      return command is SceneActorRouteInteractiveCommand &&
          command.steps.any((step) => step is SceneActorMoveStep);
    });
    final route = _command(routeNode) as SceneActorRouteInteractiveCommand;
    final moveIndex = route.steps.indexWhere(
      (step) => step is SceneActorMoveStep,
    );
    final move = route.steps[moveIndex] as SceneActorMoveStep;
    final duration = move.durationMs == 375 ? 425 : 375;
    final editedRoute = SceneInteractiveCommand.fromJson({
      ...route.toJson(),
      'steps': [
        for (final (index, step) in route.steps.indexed)
          if (index == moveIndex)
            {...step.toJson(), 'durationMs': duration}
          else
            step.toJson(),
      ],
    });
    expectedScenes[routeBase.id] = _replaceCommand(
      routeBase,
      routeNode.id,
      editedRoute,
    );
    for (final scene in expectedScenes.values) {
      expect(
        editors.scenes.open(scene.id),
        isTrue,
        reason: editors.scenes.error,
      );
      expect(editors.scenes.active!.commit(scene), isTrue);
      expect(await editors.scenes.save(), isTrue, reason: editors.scenes.error);
      expect(editors.scenes.active!.dirty, isFalse);
    }
    final afterPublication = await editors.adapter.loadProject(editors.session);
    expect(afterPublication.maps, initial.maps);
    expect(afterPublication.trainers, initial.trainers);
    expect(afterPublication.encounterTables, initial.encounterTables);
    for (final scene in initial.scenes.where(
      (scene) => !expectedScenes.containsKey(scene.id),
    )) {
      final after = afterPublication.scenes.singleWhere(
        (value) => value.id == scene.id,
      );
      expect(after.graph.edges, scene.graph.edges);
      expect(after.metadata, scene.metadata);
    }
    await editors.close();

    final reopened = await _StudioEditors.open(copy.path);
    addTearDown(reopened.close);
    expect(
      await reopened.dialogues.open(dialogueId),
      isTrue,
      reason: reopened.dialogues.error,
    );
    expect(
      reopened.dialogues.active!.document.nodes
          .expand((node) => node.steps)
          .whereType<DeLineStep>()
          .where((value) => value.id == line.id)
          .single
          .body,
      editedText,
    );
    expect(
      await reopened.events.prepare(),
      isTrue,
      reason: reopened.events.error,
    );
    expect(reopened.events.record(conditional.id), editedEvent);
    for (final scene in expectedScenes.values) {
      expect(
        reopened.scenes.open(scene.id),
        isTrue,
        reason: reopened.scenes.error,
      );
      expect(reopened.scenes.active!.current, scene);
      expect(reopened.scenes.active!.dirty, isFalse);
    }
    expect(
      _command(
        reopened.maps.project!.scenes
            .singleWhere((scene) => scene.id == doorScene.id)
            .graph
            .nodes
            .singleWhere((node) => node.id == doorNode.id),
      ),
      editedDoor,
    );
    expect(
      _command(
        reopened.maps.project!.scenes
            .singleWhere((scene) => scene.id == routeScene.id)
            .graph
            .nodes
            .singleWhere((node) => node.id == routeNode.id),
      ),
      editedRoute,
    );
    expect(await _hashes(original), before);
    final receiptPath = Platform.environment['AVELUNE_STD09_STUDIO_RECEIPT'];
    if (receiptPath != null) {
      final receipt = File(receiptPath);
      expect(await receipt.exists(), isFalse);
      await receipt.writeAsString(
        jsonEncode({
          'kind': 'std09CurrentStudioControllerPublicationAndReopen',
          'reference': referencePath,
          'originalProjectPath': original.path,
          'dialogueId': dialogueId,
          'lineId': line.id,
          'eventId': conditional.id,
          'doorSceneId': doorScene.id,
          'doorNodeId': doorNode.id,
          'arrivalFacing': facing.name,
          'routeSceneId': routeScene.id,
          'routeNodeId': routeNode.id,
          'routeDurationMs': duration,
          'sessionClosedAndReopened': true,
          'originalProjectUnchanged': true,
          'graphicalApplicationJourneyVerified': false,
          'otherOsProcessVerified': false,
        }),
      );
    }
  }, skip: referencePath == null);
}

SceneInteractiveCommand? _command(SceneNode node) =>
    node.payload is SceneActionPayload
    ? (node.payload as SceneActionPayload).interactiveCommand
    : null;

SceneAsset _replaceCommand(
  SceneAsset scene,
  String nodeId,
  SceneInteractiveCommand command,
) => SceneAsset.fromJson({
  ...scene.toJson(),
  'graph': {
    ...scene.graph.toJson(),
    'nodes': [
      for (final node in scene.graph.nodes)
        if (node.id == nodeId)
          {
            ...node.toJson(),
            'payload': {
              ...(node.payload as SceneActionPayload).toJson(),
              'interactiveCommand': command.toJson(),
            },
          }
        else
          node.toJson(),
    ],
  },
});

Future<Map<String, String>> _hashes(Directory root) async => {
  for (final file
      in await root
          .list(recursive: true, followLinks: false)
          .where((entity) => entity is File)
          .cast<File>()
          .toList())
    file.path.substring(root.path.length + 1): sha256
        .convert(await file.readAsBytes())
        .toString(),
};

final class _StudioEditors {
  _StudioEditors(
    this.sessions,
    this.session,
    this.adapter,
    this.maps,
    this.narrative,
    this.scenes,
    this.dialogues,
    this.events,
  );

  final LocalProjectSessionAdapter sessions;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter adapter;
  final MapWorkspaceController maps;
  final NarrativeWorkspaceController narrative;
  final SceneWorkspaceController scenes;
  final DialogueWorkspaceController dialogues;
  final EventWorkspaceController events;
  bool closed = false;

  static Future<_StudioEditors> open(String root) async {
    final sessions = LocalProjectSessionAdapter();
    final session = await sessions.open(root);
    final adapter = LocalMapWorkspaceAdapter();
    final maps = MapWorkspaceController(session, adapter);
    await maps.initialize();
    expect(maps.error, isNull);
    await maps.materializeProject();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: session, mapAdapter: adapter),
      () {},
      (_, _) async {},
    );
    final scenes = SceneWorkspaceController(
      maps,
      LocalSceneAdapter(session: session, mapAdapter: adapter),
      narrative: narrative,
      changed: () {},
    );
    final dialogues = DialogueWorkspaceController(
      narrative,
      LocalDialogueAdapter(session: session, mapAdapter: adapter),
      changed: () {},
      sceneDrafts: () =>
          scenes.sessions.values.map((value) => value.current).toList(),
    );
    dialogues.onPublished = (id, _) => scenes.refreshDialogueResults(id);
    final events = EventWorkspaceController(
      narrative,
      LocalEventAdapter(session: session, mapAdapter: adapter),
      changed: () {},
    );
    return _StudioEditors(
      sessions,
      session,
      adapter,
      maps,
      narrative,
      scenes,
      dialogues,
      events,
    );
  }

  Future<void> close() async {
    if (closed) return;
    closed = true;
    events.dispose();
    dialogues.dispose();
    scenes.dispose();
    narrative.dispose();
    maps.dispose();
    await sessions.close(session);
  }
}
