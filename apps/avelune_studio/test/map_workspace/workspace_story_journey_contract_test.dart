import 'dart:io';

import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/narrative/application/dialogue_draft_codec.dart';
import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction_reader.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:avelune_studio/features/stories/application/story_document_commands.dart';
import 'package:avelune_studio/features/stories/application/story_labels.dart';
import 'package:avelune_studio/features/stories/application/story_workspace_controller.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core.dart';

import '../support/m3_story_fixture.dart';
import '../support/ui06_scene_fixture.dart';
import '../support/ui09_runtime_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('scene dialogue navigation preserves the exact start, dirty graph and text without publication', () async {
    final source = await createUi09RuntimeFixture();
    addTearDown(source.dispose);
    final maps = MapWorkspaceController(source.session, source.maps);
    addTearDown(maps.dispose);
    await maps.initialize();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: source.session, mapAdapter: source.maps),
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    final scenes = SceneWorkspaceController(
      maps,
      LocalSceneAdapter(session: source.session, mapAdapter: source.maps),
      narrative: narrative,
      changed: () {},
    );
    addTearDown(scenes.dispose);
    final port = _DialoguePort(
      LocalDialogueAdapter(session: source.session, mapAdapter: source.maps),
    );
    final dialogues = DialogueWorkspaceController(
      narrative,
      port,
      changed: () {},
      sceneDrafts: () => scenes.scenes,
    );
    addTearDown(dialogues.dispose);
    final navigation = WorkspaceNavigationSession(
      controller: maps,
      isActive: () => true,
      changed: () {},
      scenes: () => scenes,
      dialogues: () => dialogues,
    );
    expect(
      await navigation.openScene(
        Ui06SceneFixture.sceneId,
        nodeId: 'conversation',
      ),
      isNull,
    );
    final edit = scenes.active!;
    expect(edit.rename('Rencontre au guichet — brouillon conservé'), isTrue);
    final before = edit.current;
    final payload =
        before.graph.nodes
                .singleWhere((node) => node.id == 'conversation')
                .payload
            as SceneYarnDialoguePayload;
    expect(
      await navigation.openDialogue(
        payload.dialogueId,
        WorkspaceSpace.scene,
        startNode: payload.yarnNodeName,
      ),
      isNull,
    );
    expect(dialogues.activeId, ui09DialogueId);
    expect(dialogues.active!.startNode, 'Accueil');
    final line = dialogues.active!.document.nodes.first.steps
        .whereType<DeLineStep>()
        .first;
    expect(
      dialogues.updateLine(line.id, text: 'Conversation encore en brouillon.'),
      isTrue,
    );
    final dialogueDraft = dialogues.active!.source;
    navigation.returnFromDialogue();
    expect(navigation.space, WorkspaceSpace.scene);
    expect(scenes.active, same(edit));
    expect(edit.current, same(before));
    expect(edit.dirty, isTrue);
    expect(navigation.sceneNodes[before.id], 'conversation');
    expect(dialogues.active!.source, dialogueDraft);
    expect(dialogues.active!.dirty, isTrue);
    expect(
      await navigation.openDialogue(
        payload.dialogueId,
        WorkspaceSpace.scene,
        startNode: payload.yarnNodeName,
      ),
      isNull,
    );
    expect(dialogues.active!.source, dialogueDraft);
    expect(
      dialogues.active!.document.nodes.first.steps
          .whereType<DeLineStep>()
          .first
          .id,
      line.id,
    );
    expect(port.reads, 1);
    expect(port.writes, 0);
    expect(
      (await source.maps.loadProject(source.session)).scenes.single,
      ui09ConsumerScene(),
    );
    expect(
      (await port.delegate.load(ui09DialogueId)).source,
      isNot(contains('Conversation encore en brouillon.')),
    );
  });

  test('advanced interaction routes to its exact scene and failed close preserves both drafts and external bytes', () async {
    final source = await Ui06SceneFixture.create();
    addTearDown(source.dispose);
    final localScenes = LocalSceneAdapter(
      session: source.session,
      mapAdapter: source.maps,
    );
    final decoy = createSceneDraftInProject(
      source.manifest,
      name: source.scene.name,
    ).createdScene;
    await localScenes.publishScene(base: null, current: decoy);
    final maps = MapWorkspaceController(source.session, source.maps);
    addTearDown(maps.dispose);
    await maps.initialize();
    final narrativePort = _NarrativePort(
      LocalNarrativeAdapter(session: source.session, mapAdapter: source.maps),
    );
    final narrative = NarrativeWorkspaceController(
      maps,
      narrativePort,
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    final scenePort = _ScenePort(localScenes);
    final scenes = SceneWorkspaceController(
      maps,
      scenePort,
      narrative: narrative,
      changed: () {},
    );
    addTearDown(scenes.dispose);
    final navigation = WorkspaceNavigationSession(
      controller: maps,
      isActive: () => true,
      changed: () {},
      scenes: () => scenes,
    );
    final map = maps.active!;
    map.commit(map.current.copyWith(name: 'Carte en préparation'));
    final mapDraft = map.current;
    final mapFile = File(
      '${source.directory.path}/${maps.project!.maps.first.relativePath}',
    );
    final mapBytes = await mapFile.readAsBytes();
    expect(await navigation.openScene(decoy.id), isNull);
    expect(scenes.active!.current.id, decoy.id);
    final record = maps.project!.eventRegistry!.records.single;
    expect(readStudioInteraction(record, maps.project!), isNull);
    expect(
      await navigation.openScene(record.definitionOrNull!.sceneId),
      isNull,
    );
    final edit = scenes.active!;
    expect(edit.current, source.scene);
    expect(scenes.sessions.keys, containsAll([decoy.id, source.scene.id]));
    expect(narrativePort.reads, 0);
    expect(narrativePort.writes, 0);
    expect(edit.move('start', 45, 30), isTrue);
    final graphDraft = edit.current;
    expect(edit.undoCount, 1);
    navigation.show(WorkspaceSpace.map);
    expect(map.current, same(mapDraft));
    expect(await navigation.openScene(source.scene.id), isNull);
    expect(scenes.active, same(edit));
    expect(edit.current, same(graphDraft));
    navigation.show(WorkspaceSpace.map);
    var choice = WorkspaceCloseChoice.cancel;
    var prompts = 0;
    final workflow = WorkspaceWorkflow(
      controller: maps,
      isActive: () => true,
      changed: () {},
      resources: () => null,
      narrative: () => narrative,
      scenes: () => scenes,
      confirmClose: () async {
        prompts++;
        return choice;
      },
      flushFocus: () {},
      launchMap: (_, _) async => throw StateError('Unexpected launch'),
    );
    expect(await workflow.allowClose(), isFalse);
    expect(prompts, 1);
    expect(edit.current, same(graphDraft));
    expect(edit.dirty, isTrue);
    final projectFile = File('${source.directory.path}/project.json');
    final external = '${await projectFile.readAsString()}\n';
    await projectFile.writeAsString(external);
    choice = WorkspaceCloseChoice.save;
    expect(await workflow.allowClose(), isFalse);
    expect(scenePort.writes, 1);
    expect(prompts, 2);
    expect(edit.error, isNotNull);
    expect(edit.current, same(graphDraft));
    expect(edit.dirty, isTrue);
    expect(edit.undoCount, 1);
    expect(map.current, same(mapDraft));
    expect(map.dirty, isTrue);
    expect(await mapFile.readAsBytes(), mapBytes);
    expect(await projectFile.readAsString(), external);
    expect(narrativePort.writes, 0);
    expect(await navigation.openScene(source.scene.id), isNull);
    expect(scenes.active, same(edit));
    expect(edit.error, isNotNull);
  });

  test('interaction literal text, story steps and conditional variant publish and survive cold reopening', () async {
    final source = await M3StoryFixture.create();
    addTearDown(() => source.directory.delete(recursive: true));
    final maps = MapWorkspaceController(source.session, source.maps);
    addTearDown(maps.dispose);
    await maps.initialize();
    final port = LocalNarrativeAdapter(
      session: source.session,
      mapAdapter: source.maps,
    );
    final narrative = NarrativeWorkspaceController(
      maps,
      port,
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    final stories = StoryWorkspaceController(
      narrative,
      LocalStoryAdapter(session: source.session, mapAdapter: source.maps),
      changed: () {},
    );
    addTearDown(stories.dispose);
    final map = maps.active!;
    final chief = map.current.entities.singleWhere(
      (entity) => entity.id == 'chief',
    );
    await narrative.openNpc(map, chief);
    final edit = narrative.active!;
    const literal =
        'Voulez-vous aider au départ ?\nTexte littéral <<stop>> et # sans commande.';
    final dialogue = edit.current.dialogue;
    final branch = dialogue.branches.first;
    edit.change(
      dialogue: dialogue.copyWith(
        branches: [
          branch.copyWith(
            lines: [
              DialogueLineDraft(text: literal),
              ...branch.lines.skip(1),
            ],
          ),
          ...dialogue.branches.skip(1),
        ],
      ),
    );
    final dirty = edit.current;
    final workflow = WorkspaceWorkflow(
      controller: maps,
      isActive: () => true,
      changed: () {},
      resources: () => null,
      narrative: () => narrative,
      confirmClose: () async => WorkspaceCloseChoice.cancel,
      flushFocus: () {},
      launchMap: (_, _) async => throw StateError('Unexpected launch'),
    );
    expect(await workflow.allowClose(), isFalse);
    expect(edit.current, same(dirty));
    expect(edit.dirty, isTrue);
    expect(await narrative.save(), isTrue, reason: narrative.error);
    expect(edit.dirty, isFalse);
    final savedDialogue = await port.readDialogue(edit.current.dialogue.entry);
    expect(
      const DialogueDraftCodec()
          .decode(savedDialogue)!
          .branches
          .first
          .lines
          .first
          .text,
      literal,
    );
    final story = stories.create('La visite du quai')!;
    final commands = StoryDocumentCommands(stories);
    commands.addChapter(story.id, 'La visite du quai');
    final chapter = stories.active!.chapters.single;
    for (final title in ['Préparer', 'Rencontrer', 'Revenir']) {
      commands.addStep(story.id, chapter.id, title);
    }
    expect(await stories.save(), isTrue, reason: stories.error);
    expect(stories.dirty, isFalse);
    await narrative.openNpc(map, chief, create: true);
    final variant = narrative.active!;
    final variantDialogue = variant.current.dialogue;
    variant.change(
      dialogue: variantDialogue.copyWith(
        branches: [
          variantDialogue.branches.first.copyWith(
            lines: [const DialogueLineDraft(text: 'Le quai vous attend.')],
          ),
        ],
      ),
      interaction: variant.current.interaction.revise(
        conditions: [
          NarrativeEventCondition.fact(narrative.facts.first.id, true),
        ],
      ),
    );
    final variantId = variant.current.interaction.id;
    expect(variant.current.interaction.conditions, hasLength(1));
    expect(await narrative.save(), isTrue, reason: narrative.error);
    expect(variant.dirty, isFalse);
    final coldMaps = LocalMapWorkspaceAdapter();
    final fresh = await coldMaps.loadProject(source.session);
    final freshStory = fresh.storylines.singleWhere(
      (candidate) => candidate.id == story.id,
    );
    expect(freshStory.title, 'La visite du quai');
    expect(
      orderedStorySteps(freshStory.chapters.single).map((step) => step.title),
      ['Préparer', 'Rencontrer', 'Revenir'],
    );
    final cold = MapWorkspaceController(source.session, coldMaps);
    addTearDown(cold.dispose);
    await cold.initialize();
    final reopened = NarrativeWorkspaceController(
      cold,
      LocalNarrativeAdapter(session: source.session, mapAdapter: coldMaps),
      () {},
      (_, _) async {},
    );
    addTearDown(reopened.dispose);
    final record = fresh.eventRegistry!.records.singleWhere(
      (record) => record.id == variantId,
    );
    expect(await reopened.openRecord(record), isTrue, reason: reopened.error);
    expect(
      reopened.active!.current.interaction.conditions,
      variant.current.interaction.conditions,
    );
    expect(
      reopened.active!.current.dialogue.branches.first.lines.first.text,
      'Le quai vous attend.',
    );
    final original = fresh.dialogues.singleWhere(
      (entry) => entry.id == edit.current.dialogue.entry.id,
    );
    final originalSource = await LocalNarrativeAdapter(
      session: source.session,
      mapAdapter: coldMaps,
    ).readDialogue(original);
    expect(
      const DialogueDraftCodec()
          .decode(originalSource)!
          .branches
          .first
          .lines
          .first
          .text,
      literal,
    );
  });
}

class _ScenePort implements ScenePort {
  _ScenePort(this.delegate);
  final ScenePort delegate;
  int writes = 0;
  @override
  Future<ScenePublicationReceipt> publishScene({
    required SceneAsset? base,
    required SceneAsset current,
  }) {
    writes++;
    return delegate.publishScene(base: base, current: current);
  }
}

class _NarrativePort implements NarrativePort {
  _NarrativePort(this.delegate);
  final NarrativePort delegate;
  int reads = 0, writes = 0;
  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) {
    reads++;
    return delegate.readDialogue(entry);
  }

  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) {
    writes++;
    return delegate.publish(publication);
  }
}

class _DialoguePort implements DialoguePort {
  _DialoguePort(this.delegate);
  final DialoguePort delegate;
  int reads = 0, writes = 0;
  @override
  Future<DialogueSourceSnapshot> load(String id) {
    reads++;
    return delegate.load(id);
  }

  @override
  Future<DialoguePublicationReceipt> publish({
    required String id,
    required DialogueSourceSnapshot? base,
    required ProjectDialogueEntry? entry,
    required String? source,
    List<DialogueLineTextEdit>? lineTextEdits,
  }) {
    writes++;
    return delegate.publish(
      id: id,
      base: base,
      entry: entry,
      source: source,
      lineTextEdits: lineTextEdits,
    );
  }
}
