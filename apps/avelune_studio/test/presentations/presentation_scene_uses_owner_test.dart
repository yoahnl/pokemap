import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/presentation_workspace_owner_fixture.dart';

void main() {
  late PresentationWorkspaceOwnerFixture owner;
  late PresentationWorkspaceController controller;
  final drafts = <SceneAsset>[];
  setUp(() async {
    owner = await PresentationWorkspaceOwnerFixture.create();
    drafts.clear();
    controller = PresentationWorkspaceController(
      owner.narrative,
      owner.port,
      changed: () {},
      sceneDrafts: () => drafts,
    );
    expect(await controller.open(owner.asset.id), isTrue);
  });
  tearDown(() async {
    controller.dispose();
    await owner.dispose();
  });

  String presentationId() => controller.active!.asset.id;

  void saveScenes(List<SceneAsset> scenes) =>
      owner.maps.project = owner.maps.project!.copyWith(scenes: scenes);

  test(
    'scene uses merge saved scenes with drafts and follow the selected interaction cue',
    () {
      final id = presentationId();
      final marker = controller.addMarker(timeUs: 1000000, interaction: true)!;
      saveScenes([_scene('saved', id, cue: marker), _scene('other', 'elsewhere')]);
      drafts.add(_scene('draft', id, cue: 'unrelated'));

      expect(
        [for (final use in controller.sceneUses(id)) use.scene.id],
        ['saved', 'draft'],
      );
      expect(
        controller.sceneUses(id).map((use) => use.node.id).toSet(),
        {'presentation'},
      );

      final cue = controller.active!.asset.tracks
          .expand((track) => track.clips)
          .singleWhere((clip) => clip.id == marker);
      expect(
        [for (final use in controller.sceneUses(id, selected: cue)) use.scene.id],
        ['saved'],
      );
      final text = controller.active!.asset.tracks
          .expand((track) => track.clips)
          .singleWhere((clip) => clip.id == 'title.clip');
      expect(controller.sceneUses(id, selected: text), hasLength(2));

      drafts
        ..clear()
        ..add(_scene('saved', id));
      expect(
        [for (final use in controller.sceneUses(id, selected: cue)) use.scene.name],
        isEmpty,
      );
    },
  );

  test('the scenario preview only offers saved scenes and resolves the preferred one', () {
    final id = presentationId();
    drafts.add(_scene('draft', id));
    expect(controller.scenarioScenes(id), isEmpty);

    saveScenes([_scene('first', id), _scene('unrelated', 'elsewhere')]);
    final single = controller.scenarioScenes(id);
    expect(single.map((scene) => scene.id), ['first']);
    expect(presentationScenarioScene(single, null)?.id, 'first');
    expect(presentationScenarioScene(single, 'missing')?.id, 'first');

    saveScenes([_scene('first', id), _scene('second', id)]);
    final several = controller.scenarioScenes(id);
    expect(several.map((scene) => scene.id), ['first', 'second']);
    expect(presentationScenarioScene(several, 'second')?.id, 'second');
    expect(presentationScenarioScene(several, null), isNull);
    expect(presentationScenarioScene(several, 'missing'), isNull);
    expect(presentationScenarioScene(const [], null), isNull);
    expect(presentationScenarioUnlinkedError, contains('enregistrez'));
  });
}

SceneAsset _scene(String id, String presentationId, {String? cue}) => SceneAsset(
  id: id,
  name: 'Scène $id',
  executionProfile: SceneExecutionProfile.preSession,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'confirm',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.preSessionInteraction(
          ScenePreSessionInteractionSpec.confirmation(
            prompt: SceneInteractionPrompt(
              localizationKey: 'confirm',
              fallbackText: 'Continuer ?',
            ),
          ),
        ),
      ),
      SceneNode(
        id: 'presentation',
        kind: SceneNodeKind.presentationCinematic,
        title: 'Ouverture',
        payload: ScenePresentationCinematicPayload(
          presentationCinematicId: presentationId,
          interactionCueBindings: [
            if (cue != null)
              ScenePresentationInteractionCueBinding(
                markerId: cue,
                awaitableNodeId: 'confirm',
              ),
          ],
        ),
      ),
    ],
    edges: [],
  ),
);
