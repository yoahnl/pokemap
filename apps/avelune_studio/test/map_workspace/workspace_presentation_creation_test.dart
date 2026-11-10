import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:avelune_studio/features/presentations/data/local_presentation_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/scenes/domain/scene_presentation_creation_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/cinematic_adapter_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CinematicAdapterFixture files;
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late SceneWorkspaceController scenes;
  late PresentationWorkspaceController presentations;
  late WorkspaceNavigationSession navigation;
  late ScenePresentationCreationRequest creation;
  var active = true;

  setUp(() async {
    final parent = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
    );
    await parent.create(recursive: true);
    files = await IOOverrides.runZoned(
      () => CinematicAdapterFixture.create(scenes: [_scene()]),
      getSystemTempDirectory: () => parent,
    );
    maps = MapWorkspaceController(files.session, files.maps);
    await maps.initialize();
    narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: files.session, mapAdapter: files.maps),
      () {},
      (_, _) async {},
    );
    scenes = SceneWorkspaceController(
      maps,
      LocalSceneAdapter(session: files.session, mapAdapter: files.maps),
      changed: () {},
    );
    expect(scenes.open('scene'), isTrue);
    final base = scenes.active!.current;
    scenes.active!.rename('Scène encore en brouillon');
    creation = ScenePresentationCreationRequest(
      baseScene: base,
      scene: scenes.active!.current,
      targetNodeId: 'end',
    );
    presentations = PresentationWorkspaceController(
      narrative,
      LocalPresentationAdapter(session: files.session, mapAdapter: files.maps),
      changed: () {},
      sceneDrafts: () => scenes.scenes,
    );
    active = true;
    navigation = WorkspaceNavigationSession(
      controller: maps,
      isActive: () => active && !maps.isDisposed,
      changed: () {},
      scenes: () => scenes,
      presentations: () => presentations,
    )..space = WorkspaceSpace.scene;
  });

  tearDown(() async {
    presentations.dispose();
    scenes.dispose();
    narrative.dispose();
    maps.dispose();
    await files.dispose();
  });

  test('linked creation retains the source draft and publishes the exact scene only on save', () async {
    final before = await files.file('project.json').readAsBytes();
    await navigation.createScenePresentation(
      creation,
      askName: () async => 'Départ lié',
    );
    final draft = presentations.active!;
    expect(navigation.space, WorkspaceSpace.presentation);
    expect(navigation.presentationOrigin.space, WorkspaceSpace.scene);
    expect(navigation.presentationOrigin.documentId, 'scene');
    expect(draft.asset.title, 'Départ lié');
    expect(draft.dirty, isTrue);
    expect(draft.link!.baseScene, same(creation.baseScene));
    expect(draft.link!.scene, same(creation.scene));
    expect(draft.link!.targetNodeId, 'end');
    expect(scenes.active!.current, same(creation.scene));
    expect(scenes.active!.dirty, isTrue);
    expect(await files.file('project.json').readAsBytes(), before);
    expect(await presentations.save(), isTrue, reason: presentations.error);
    final saved = await files.readManifest();
    final linked = saved.scenes.single.graph.nodes.singleWhere(
      (node) => node.id == draft.link!.nodeId,
    );
    expect(
      (linked.payload as ScenePresentationCinematicPayload)
          .presentationCinematicId,
      draft.asset.id,
    );
    expect(saved.scenes.single.name, creation.scene.name);
    final reopened = await LocalPresentationAdapter(
      session: files.session,
      mapAdapter: files.maps,
    ).load(draft.asset.id);
    expect(reopened.asset, draft.asset);
  });

  test(
    'cancelling the name or closing the owner creates no presentation',
    () async {
      final before = await files.file('project.json').readAsBytes();
      await navigation.createScenePresentation(
        creation,
        askName: () async => null,
      );
      expect(presentations.active, isNull);
      await navigation.createScenePresentation(
        creation,
        askName: () async {
          active = false;
          return 'Trop tard';
        },
      );
      expect(presentations.active, isNull);
      expect(navigation.space, WorkspaceSpace.scene);
      expect(await files.file('project.json').readAsBytes(), before);
    },
  );

  test(
    'a changed source while naming refuses creation without publishing',
    () async {
      final before = await files.file('project.json').readAsBytes();
      await navigation.createScenePresentation(
        creation,
        askName: () async {
          scenes.active!.rename('Révision suivante');
          return 'Refusée';
        },
      );
      expect(presentations.active, isNull);
      expect(navigation.space, WorkspaceSpace.scene);
      expect(await files.file('project.json').readAsBytes(), before);
    },
  );

  test(
    'a newer destination invalidates a pending name before creation',
    () async {
      final naming = Completer<String?>();
      final requested = Completer<void>();
      final pending = navigation.createScenePresentation(
        creation,
        askName: () {
          requested.complete();
          return naming.future;
        },
      );
      await requested.future;
      navigation.show(WorkspaceSpace.story);
      naming.complete('Trop tard');
      await pending;
      expect(presentations.active, isNull);
      expect(navigation.space, WorkspaceSpace.story);
    },
  );
}

SceneAsset _scene() => SceneAsset(
  id: 'scene',
  name: 'Introduction',
  executionProfile: SceneExecutionProfile.preSession,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(
          sceneOutcomeId: 'ready',
          outcomePolicy: SceneOutcomePolicy.progression,
        ),
      ),
    ],
    edges: [
      SceneEdge(
        id: 'edge',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
  declaredOutcomes: [SceneOutcome(id: 'ready', label: 'Prêt')],
);
