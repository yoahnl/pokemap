import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:avelune_studio/features/scenes/domain/scene_presentation_creation_request.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';
import '../support/presentation_controller_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MapWorkspaceController maps;
  late SceneWorkspaceController scenes;
  late _NoWrites port;
  late SceneAsset base, worldScene;
  late String presentationNode, worldNode;
  setUp(() async {
    maps = MapWorkspaceController(workspaceSession, WorkspaceMemoryPort());
    await maps.initialize();
    var scene = createSceneDraftInProject(
      maps.project!,
      name: 'Origine',
    ).createdScene;
    scene = SceneAsset.fromJson({
      ...scene.toJson(),
      'executionProfile': 'preSession',
    });
    final linked = addSceneLinkedAssetNodeDraft(
      scene,
      payload: ScenePresentationCinematicPayload(
        presentationCinematicId: 'same-id',
      ),
      title: 'Présentation liée',
    );
    presentationNode = linked.createdNode.id;
    final world = addSceneLinkedAssetNodeDraft(
      createSceneDraftInProject(
        maps.project!,
        name: 'Scène sur carte',
      ).createdScene,
      payload: SceneCinematicPayload(cinematicId: 'same-id'),
      title: 'Carte liée',
    );
    worldNode = world.createdNode.id;
    base = linked.updatedScene;
    worldScene = world.updatedScene;
    maps.project = maps.project!.copyWith(
      scenes: [base, worldScene],
      presentationCinematics: [asset('Disque')],
      cinematics: [
        CinematicAsset(
          id: 'same-id',
          title: 'Carte',
          timeline: CinematicTimeline(),
        ),
      ],
    );
    port = _NoWrites();
    scenes = SceneWorkspaceController(maps, port, changed: () {});
    scenes.open(base.id);
  });
  tearDown(() {
    scenes.dispose();
    maps.dispose();
  });

  test(
    'typed linked requests preserve the exact native scene draft and selection',
    () {
      final navigation = WorkspaceNavigationSession(
        controller: maps,
        isActive: () => true,
        changed: () {},
        scenes: () => scenes,
      );
      final session = scenes.active!;
      expect(session.rename('Brouillon conservé'), isTrue);
      navigation.selectSceneNode(session.current, presentationNode);
      final before = session.current;
      final presentation =
          before.graph.nodes
                  .singleWhere((node) => node.id == presentationNode)
                  .payload
              as ScenePresentationCinematicPayload;
      final creation = ScenePresentationCreationRequest(
        baseScene: session.base!,
        scene: before,
        targetNodeId: navigation.sceneNodes[before.id]!,
      );
      expect(presentation.presentationCinematicId, 'same-id');
      expect(creation.baseScene, same(base));
      expect(creation.scene, same(before));
      expect(creation.targetNodeId, presentationNode);
      expect(scenes.open(worldScene.id), isTrue);
      navigation.selectSceneNode(worldScene, worldNode);
      final cinematic =
          scenes.active!.current.graph.nodes
                  .singleWhere((node) => node.id == worldNode)
                  .payload
              as SceneCinematicPayload;
      expect(cinematic.cinematicId, 'same-id');
      expect(scenes.open(base.id), isTrue);
      expect(scenes.active, same(session));
      expect(session.current, same(before));
      expect(session.dirty, isTrue);
      expect(navigation.sceneNodes[base.id], presentationNode);
      expect(port.writes, 0);
    },
  );

  test('presentation owner keeps draft precedence and the existing catalogue fallback without publication', () async {
    final fixture = await PresentationControllerFixture.create();
    addTearDown(fixture.dispose);
    final owner = fixture.controller;
    expect(await owner.create(title: 'Disque'), isTrue, reason: owner.error);
    expect(await owner.save(), isTrue, reason: owner.error);
    final id = owner.activeId!;
    final saved = owner.active!.asset;
    final before = await fixture.files.file('project.json').readAsBytes();
    expect(owner.rename('Texte du brouillon'), isTrue);
    final draft = owner.active!.asset;
    expect(owner.assetFor(id), same(draft));
    expect(owner.active!.dirty, isTrue);
    final catalogueOwner = PresentationWorkspaceController(
      fixture.narrative,
      fixture.port,
      changed: () {},
    );
    addTearDown(catalogueOwner.dispose);
    expect(catalogueOwner.sessions, isEmpty);
    expect(catalogueOwner.assetFor(id), saved);
    expect(owner.assetFor('missing'), isNull);
    expect(catalogueOwner.assetFor('missing'), isNull);
    expect(owner.active!.asset, same(draft));
    expect(await fixture.files.file('project.json').readAsBytes(), before);
  });
}

PresentationCinematicAsset asset(String title) => PresentationCinematicAsset(
  id: 'same-id',
  title: title,
  durationUs: 2000000,
);

class _NoWrites implements ScenePort {
  int writes = 0;
  @override
  Future<ScenePublicationReceipt> publishScene({
    required SceneAsset? base,
    required SceneAsset current,
  }) async {
    writes++;
    throw StateError('Navigation cannot publish the scene');
  }
}
