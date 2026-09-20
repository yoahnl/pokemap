import 'dart:async';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/interaction_edit_session.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late SceneWorkspaceController scenes;
  late _Port port;
  late SceneAsset base;
  setUp(() async {
    maps = MapWorkspaceController(workspaceSession, WorkspaceMemoryPort());
    await maps.initialize();
    base = createSceneDraftInProject(maps.project!, name: 'Scène').createdScene;
    maps.project = maps.project!.copyWith(scenes: [base]);
    narrative = NarrativeWorkspaceController(
      maps,
      _NoNarrativeWrites(),
      () {},
      (_, _) async {},
    );
    port = _Port(maps);
    scenes = SceneWorkspaceController(
      maps,
      port,
      narrative: narrative,
      changed: () {},
    );
  });
  tearDown(() {
    scenes.dispose();
    narrative.dispose();
    maps.dispose();
  });

  InteractionEditSession interaction() {
    final draft = NarrativeInteractionDraft(
      id: 'linked',
      name: 'Liée',
      mapId: 'a',
      source: NarrativeEventSourceRef.entityInteract('a', 'npc'),
      dialogueId: 'dialogue',
    );
    base = SceneAsset.fromJson({...base.toJson(), 'id': draft.sceneId});
    maps.project = maps.project!.copyWith(scenes: [base]);
    final session = InteractionEditSession(
      document: maps.active!,
      dialogue: DialogueDraft.blank(
        const ProjectDialogueEntry(
          id: 'dialogue',
          name: 'Dialogue',
          relativePath: 'dialogue.yarn',
        ),
      ),
      interaction: draft,
      baseScene: base,
      sceneBaseKnown: true,
    );
    narrative.sessions[draft.id] = session;
    return session;
  }

  test(
    'canonical gestures have one history entry and invalid gestures do nothing',
    () {
      final edit = SceneEditSession(base, base: base);
      expect(edit.connect('node_start', 'completed', 'node_end'), false);
      expect(edit.dirty, false);
      expect(edit.undoCount, 0);
      expect(edit.delete('node_start'), false);
      expect(edit.delete('node_end'), false);
      expect(edit.duplicate('node_start'), false);
      expect(edit.move('node_end', 700, 450), true);
      expect(edit.current.graph, base.graph);
      expect(edit.undoCount, 1);
      edit.restore(redo: false);
      expect(edit.current, base);
      edit.restore(redo: true);
      expect(edit.current.layout.nodeLayouts.last.x, 700);
      expect(edit.duplicate('node_end'), true);
      expect(edit.current.graph.nodes, hasLength(3));
      expect(edit.current.graph.edges, base.graph.edges);
    },
  );

  test('composed failed command has no partial mutation', () {
    final edit = SceneEditSession(base, base: base);
    expect(
      edit.mutate((scene) {
        final next = addSceneNodeDraft(scene, kind: SceneNodeKind.condition);
        return addSceneEdgeDraft(
          next.updatedScene,
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: next.createdNode.id,
        ).updatedScene;
      }),
      false,
    );
    expect(edit.current, base);
    expect(edit.undoCount, 0);
  });

  test(
    'same scene shares session, homonyms get distinct identity, map stays dirty',
    () {
      maps.active!.commit(
        maps.active!.current.copyWith(name: 'Carte modifiée'),
      );
      final map = maps.active!.current;
      expect(scenes.open(base.id), true);
      final first = scenes.active!;
      first.rename('Scène');
      expect(scenes.open(base.id), true);
      expect(scenes.active, same(first));
      final second = scenes.create('Scène')!;
      expect(second.current.id, isNot(base.id));
      expect(maps.active!.current, same(map));
      expect(maps.active!.dirty, true);
      expect(port.writes, 0);
    },
  );

  test('receipt only cleans captured snapshot and never newer edits', () async {
    scenes.open(base.id);
    final edit = scenes.active!;
    edit.rename('Avant');
    port.gate = Completer<void>();
    final saving = scenes.save();
    edit.rename('Après');
    port.gate!.complete();
    expect(await saving, true);
    expect(edit.base!.name, 'Avant');
    expect(edit.current.name, 'Après');
    expect(edit.dirty, true);
  });

  test(
    'late save after disposal cannot replace workspace or clean draft',
    () async {
      scenes.open(base.id);
      final edit = scenes.active!..rename('En cours');
      final project = maps.project;
      port.gate = Completer<void>();
      final saving = scenes.save();
      scenes.dispose();
      port.gate!.complete();
      expect(await saving, false);
      expect(maps.project, same(project));
      expect(edit.dirty, true);
    },
  );

  test(
    'dirty simplified interaction blocks only its graph and remains recoverable',
    () {
      final legacy = interaction();
      legacy.change(dialogue: legacy.current.dialogue.copyWith(branches: []));
      expect(scenes.open(base.id), false);
      expect(scenes.error, contains('interaction modifiée'));
      expect(narrative.sessions.values, contains(legacy));
      expect(legacy.dirty, true);
      expect(scenes.create('Indépendante'), isNotNull);
      legacy.restore(redo: false);
      expect(scenes.open(base.id), true);
    },
  );

  test(
    'graph blocks stale simplified publication and preserves both drafts',
    () async {
      final legacy = interaction();
      expect(scenes.open(base.id), true);
      scenes.active!.move('node_end', 800, 400);
      expect(await narrative.openSession(legacy), false);
      legacy.change(dialogue: legacy.current.dialogue.copyWith(branches: []));
      expect(await narrative.save(), false);
      expect(await scenes.save(), false);
      expect(legacy.dirty, true);
      expect(scenes.active!.dirty, true);
      expect(port.writes, 0);
      legacy.restore(redo: false);
      expect(await scenes.save(), true);
      expect(narrative.sessions, isEmpty);
      expect(legacy.baseScene, base);
      expect(await narrative.openSession(legacy), false);
      expect(narrative.error, contains('scène liée a changé'));
    },
  );

  test(
    'targeted discard preserves other drafts and reopens session catalogue',
    () {
      scenes.open(base.id);
      scenes.active!.rename('Brouillon à abandonner');
      final other = scenes.create('Autre brouillon')!;
      final otherDraft = other.current;
      final map = maps.active!;
      map.commit(map.current.copyWith(name: 'Carte non enregistrée'));
      final mapDraft = map.current;
      final updated = updateSceneNodeLayout(
        base,
        nodeId: 'node_end',
        x: 950,
        y: 480,
      ).updatedScene;
      maps.project = maps.project!.copyWith(scenes: [updated]);
      expect(scenes.discard(base.id), true);
      expect(scenes.open(base.id), true);
      expect(scenes.active!.current, same(updated));
      expect(scenes.active!.dirty, false);
      expect(scenes.sessions[other.current.id], same(other));
      expect(other.current, same(otherDraft));
      expect(other.dirty, true);
      expect(map.current, same(mapDraft));
      expect(map.dirty, true);
      expect(port.writes, 0);
    },
  );

  test(
    'stale simplified base is refused even after graph session is released',
    () async {
      final legacy = interaction();
      final changed = updateSceneNodeLayout(
        base,
        nodeId: 'node_end',
        x: 900,
        y: 100,
      ).updatedScene;
      maps.project = maps.project!.copyWith(scenes: [changed]);
      legacy.change(dialogue: legacy.current.dialogue.copyWith(branches: []));
      expect(await narrative.save(), false);
      expect(narrative.error, contains('scène liée a changé'));
      expect(legacy.dirty, true);
    },
  );
}

class _Port implements ScenePort {
  _Port(this.workspace);
  final MapWorkspaceController workspace;
  int writes = 0;
  Completer<void>? gate;
  @override
  Future<ScenePublicationReceipt> publishScene({
    required SceneAsset? base,
    required SceneAsset current,
  }) async {
    writes++;
    final before = workspace.project!;
    await gate?.future;
    return ScenePublicationReceipt(
      scene: current,
      catalog: ResourceMutationReceipt(
        before: before,
        manifest: before.copyWith(
          scenes: [
            ...before.scenes.where((scene) => scene.id != current.id),
            current,
          ],
        ),
        beforeRevision: 'old',
        revision: 'new',
        changedPaths: ['project.json'],
      ),
    );
  }
}

class _NoNarrativeWrites implements NarrativePort {
  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) =>
      throw StateError('Unexpected read');
  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) => throw StateError('Unexpected write');
}
