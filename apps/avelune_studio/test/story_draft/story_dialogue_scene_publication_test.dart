import 'package:avelune_studio/features/dialogues/application/dialogue_localization_editing.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft_manifest_reader.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_gateway.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_plan.dart';
import 'package:avelune_studio/features/story_draft/application/story_saved_dialogues.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core.dart';

import '../support/dialogue_adapter_fixture.dart';

void main() {
  for (final refuseFirst in [false, true]) {
    test(
      'one project save reconciles dialogue and scene edits, first refusal=$refuseFirst',
      () async {
        final localization = readLocalizedDialogue(
          source: DialogueAdapterFixture.source,
          sourceLocale: 'fr',
        ).localization;
        final entry = DialogueAdapterFixture.entry.copyWith(
          localization: localization,
        );
        final scene = SceneAsset(
          id: 'scene',
          name: 'Original',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                id: 'talk',
                kind: SceneNodeKind.yarnDialogue,
                payload: SceneYarnDialoguePayload(
                  dialogueId: entry.id,
                  yarnNodeName: 'Accueil',
                  linePolicies: [
                    SceneDialogueLinePolicy(
                      nodeName: 'Accueil',
                      lineIndex: 0,
                      feedback: DialogueLineFeedback(
                        segments: [DialogueTextSegment('Bonjour !')],
                      ),
                    ),
                  ],
                ),
              ),
              SceneNode(id: 'end', kind: SceneNodeKind.end),
            ],
            edges: [
              SceneEdge(
                id: 'first',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'talk',
                kind: SceneEdgeKind.defaultFlow,
              ),
              SceneEdge(
                id: 'last',
                fromNodeId: 'talk',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.defaultFlow,
              ),
            ],
          ),
        );
        final f = await DialogueAdapterFixture.create(
          entries: [entry],
          scenes: [scene],
        );
        addTearDown(f.dispose);
        final snapshot = await f.adapter().load(entry.id);
        final original = StoryDialogueSource(
          entry: snapshot.entry,
          source: snapshot.source,
          revision: snapshot.revision,
        );
        final dialogues = StorySavedDialogues()..remember(original);
        final draft = StoryDraft();
        draft.load(StoryDraftKind.dialogue, entry.id, original);
        draft.load(StoryDraftKind.scene, scene.id, scene);
        final form = DialogueLocalizationEditing(original);
        form.writeSource(localization.units.single.id, 'Salut !');
        draft.put(StoryDraftKind.dialogue, form.build());
        draft.put(
          StoryDraftKind.scene,
          SceneAsset.fromJson({
            ...scene.toJson(),
            'name': 'Renommée',
            'graph': {
              ...scene.graph.toJson(),
              'nodes': [
                for (final node in scene.graph.nodes)
                  if (node.payload case SceneYarnDialoguePayload payload)
                    {
                      ...node.toJson(),
                      'payload': {
                        ...payload.toJson(),
                        'linePolicies': [
                          for (final policy in payload.linePolicies)
                            {
                              ...policy.toJson(),
                              'feedback': {
                                ...policy.feedback.toJson(),
                                'revealIntervalMicros': 1234,
                              },
                            },
                        ],
                      },
                    }
                  else
                    node.toJson(),
              ],
            },
          }),
        );
        var project = await f.readManifest();
        final reader = StoryDraftManifestReader();
        final scenePort = _ScenePort(
          LocalSceneAdapter(session: f.session, mapAdapter: f.maps),
          refuseFirst,
        );
        final gateway = StoryPublicationGateway(
          draft: draft,
          dialogues: f.adapter(),
          scenes: scenePort,
          savedDialogues: dialogues,
        );
        Future<void> save() async {
          final result = await gateway.publish(
            planStoryPublication(
              draft.changes(reader.of(project, beyond: dialogues)),
            ),
            land: (write) async {
              project = (await write()).manifest;
              return reader.of(project, beyond: dialogues);
            },
          );
          expect(result.complete, isTrue);
          expect(draft.dirty(reader.of(project, beyond: dialogues)), isFalse);
        }

        if (refuseFirst) {
          await expectLater(save(), throwsA(isA<StoryPublicationFailed>()));
          expect(
            draft.conflicts(reader.of(project, beyond: dialogues)),
            isEmpty,
          );
          expect(
            draft.currentOf(StoryDraftKind.scene, scene.id)?.name,
            'Renommée',
          );
          expect((await f.readManifest()).scenes.single.name, 'Original');
          expect(_text((await f.readManifest()).scenes.single), 'Salut !');
        }
        await save();
        final reopened = await f.readManifest();
        expect(reopened.scenes.single.name, 'Renommée');
        expect(_text(reopened.scenes.single), 'Salut !');
        expect(
          (reopened.scenes.single.graph.nodes[1].payload
                  as SceneYarnDialoguePayload)
              .linePolicies
              .single
              .feedback
              .revealIntervalMicros,
          1234,
        );
        expect(
          await f.file(entry.relativePath).readAsString(),
          form.build().source,
        );
        draft.undo();
        await save();
        expect((await f.readManifest()).scenes.single.name, 'Original');
        expect(_text((await f.readManifest()).scenes.single), 'Salut !');
        draft.undo();
        await save();
        expect(_text((await f.readManifest()).scenes.single), 'Bonjour !');
        expect(
          await f.file(entry.relativePath).readAsString(),
          original.source,
        );
      },
    );
  }
}

String _text(SceneAsset scene) =>
    (scene.graph.nodes.singleWhere((node) => node.id == 'talk').payload
            as SceneYarnDialoguePayload)
        .linePolicies
        .single
        .feedback
        .plainText;

class _ScenePort implements ScenePort {
  _ScenePort(this.delegate, this.refuse);
  final ScenePort delegate;
  bool refuse;
  @override
  Future<ScenePublicationReceipt> publishScene({
    required SceneAsset? base,
    required SceneAsset current,
  }) {
    if (refuse) {
      refuse = false;
      throw const SceneFailure('Publication refusée pour ce test');
    }
    return delegate.publishScene(base: base, current: current);
  }
}
