import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import '../support/presentation_controller_fixture.dart';

void main() {
  test(
    'dirty scene cue survives undo, direct deletion and late scene changes block save',
    () async {
      final f = await PresentationControllerFixture.create();
      final scenes = <SceneAsset>[];
      final c = PresentationWorkspaceController(
        f.narrative,
        f.port,
        changed: () {},
        sceneDrafts: () => scenes,
      );
      addTearDown(() async {
        c.dispose();
        await f.dispose();
      });
      expect(await c.create(title: 'Introduction'), true);
      final id = c.activeId!;
      expect(
        c.applyBatch([
          PresentationCommand('presentationTrack.create', {
            'track': {
              'id': 'markers',
              'label': 'Repères',
              'kind': 'marker',
              'clips': [],
            },
          }),
          PresentationCommand('presentationClip.create', {
            'trackId': 'markers',
            'clip': encodePresentationClip(
              PresentationMarkerClip(
                id: 'cue',
                startUs: 1000000,
                label: 'Question',
                markerKind: PresentationMarkerKind.interactionCue,
              ),
            ),
          }),
        ]),
        true,
        reason: c.error,
      );
      scenes.add(_consumer(id, 'cue'));
      final before = c.active!.asset;
      c.undo();
      expect(c.active!.asset, before);
      expect(c.error, contains('repère'));
      expect(
        c.apply('presentationClip.delete', {
          'trackId': 'markers',
          'clipId': 'cue',
        }),
        false,
      );
      expect(c.active!.asset, before);
      scenes[0] = _consumer(id, 'missing');
      expect(await c.save(), false);
      expect(c.error, contains('absent'));
      expect((await f.files.readManifest()).presentationCinematics, isEmpty);
      expect(c.dirty, true);
      scenes.clear();
      expect(await c.save(), true, reason: c.error);
    },
  );

  test('create and duplicate suspend the previous preview', () async {
    final f = await PresentationControllerFixture.create();
    addTearDown(f.dispose);
    var suspended = 0;
    f.controller.suspendPreview = () => suspended++;
    await f.controller.create(title: 'A');
    final a = f.controller.activeId!;
    await f.controller.duplicate(a);
    expect(suspended, 2);
    await f.controller.open(a);
    expect(suspended, 3);
  });
}

SceneAsset _consumer(String id, String marker) => SceneAsset(
  id: 'scene',
  name: 'Brouillon de scène',
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
        payload: ScenePresentationCinematicPayload(
          presentationCinematicId: id,
          interactionCueBindings: [
            ScenePresentationInteractionCueBinding(
              markerId: marker,
              awaitableNodeId: 'confirm',
            ),
          ],
        ),
      ),
    ],
    edges: [],
  ),
);
