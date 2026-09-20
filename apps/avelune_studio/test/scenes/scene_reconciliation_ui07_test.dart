import 'dart:async';
import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/interaction_edit_session.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late SceneWorkspaceController scenes;
  late _Port port;
  late InteractionEditSession interaction;
  setUp(() async {
    maps = MapWorkspaceController(workspaceSession, WorkspaceMemoryPort());
    await maps.initialize();
    final draft = NarrativeInteractionDraft(
      id: 'evt_019abcde-9000-7000-8000-000000000701',
      name: 'Rencontre',
      mapId: 'a',
      source: NarrativeEventSourceRef.entityInteract('a', 'npc'),
      dialogueId: 'greeting',
    );
    final base = draft.project().scene;
    maps.project = maps.project!.copyWith(scenes: [base]);
    port = _Port(maps);
    narrative = NarrativeWorkspaceController(
      maps,
      port,
      () {},
      (_, _) async {},
    );
    scenes = SceneWorkspaceController(
      maps,
      port,
      narrative: narrative,
      changed: () {},
    );
    interaction = InteractionEditSession(
      document: maps.active!,
      interaction: draft,
      baseScene: base,
      sceneBaseKnown: true,
      dialogue: DialogueDraft(
        entry: const ProjectDialogueEntry(
          id: 'greeting',
          name: 'Accueil',
          relativePath: 'greeting.yarn',
        ),
        branches: [
          DialogueBranchDraft(
            id: 'Start',
            name: 'Début',
            lines: [DialogueLineDraft(text: 'Bonjour')],
          ),
        ],
      ),
    );
    narrative.sessions[draft.id] = interaction;
    narrative.active = interaction;
    scenes.open(base.id);
  });
  tearDown(() {
    scenes.dispose();
    narrative.dispose();
    maps.dispose();
  });

  test(
    'clean graph reconciles simplified publication and saves from new base',
    () async {
      final graph = scenes.active!;
      graph.rename('Ancien historique');
      graph.restore(redo: false);
      expect(graph.canRedo, true);
      final other = scenes.create('Autre scène sale')!;
      await maps.activate(workspaceEntries.last);
      final map = maps.active!;
      map.commit(map.current.copyWith(name: 'Carte sale sans rapport'));
      final mapDraft = map.current;
      final otherDraft = other.current;
      interaction.change(
        interaction: interaction.current.interaction.revise(
          name: 'Rencontre publiée S1',
        ),
      );
      expect(await narrative.save(document: interaction.document), true);
      final published = maps.project!.scenes.single;
      expect(graph.current, published);
      expect(scenes.open(published.id), true);
      expect(scenes.active, same(graph));
      expect(graph.current, published);
      expect(graph.base, published);
      expect(graph.dirty, false);
      expect(graph.canUndo, false);
      expect(graph.canRedo, false);
      expect(map.current, same(mapDraft));
      expect(other.current, same(otherDraft));
      expect(other.dirty, true);
      graph.rename('Modification graphique S2');
      expect(await scenes.save(graph), true);
      expect(port.lastSceneBase, published);
      expect(graph.dirty, false);
    },
  );

  test('dirty graph survives a newer catalogue and keeps conflict base', () {
    final graph = scenes.active!;
    final original = graph.base;
    graph.rename('Brouillon graphique');
    final draft = graph.current;
    final updated = SceneAsset.fromJson({
      ...original!.toJson(),
      'name': 'Externe S1',
    });
    maps.acceptResources(
      maps.project!,
      maps.project!.copyWith(scenes: [updated]),
    );
    scenes.open(original.id);
    expect(scenes.active, same(graph));
    expect(graph.current, same(draft));
    expect(graph.base, same(original));
    expect(graph.dirty, true);
    expect(graph.canUndo, true);
  });

  test(
    'pending graph save retains captured base and later local changes',
    () async {
      final graph = scenes.active!;
      graph.rename('Snapshot en publication');
      final snapshot = graph.current;
      port.gate = Completer<void>();
      final saving = scenes.save();
      graph.rename('Modification pendant publication');
      final newer = graph.current;
      scenes.open(graph.current.id);
      port.gate!.complete();
      expect(await saving, true);
      expect(graph.current, same(newer));
      expect(graph.base, same(snapshot));
      expect(graph.dirty, true);
    },
  );

  test('disposed graph cannot reconcile or accept deferred receipt', () async {
    final graph = scenes.active!;
    graph.rename('Publication différée');
    port.gate = Completer<void>();
    final saving = scenes.save();
    scenes.dispose();
    final before = maps.project;
    port.gate!.complete();
    expect(await saving, false);
    expect(maps.project, same(before));
    expect(graph.dirty, true);
    expect(scenes.open(graph.current.id), false);
  });
}

class _Port implements NarrativePort, ScenePort {
  _Port(this.maps);
  final MapWorkspaceController maps;
  Completer<void>? gate;
  SceneAsset? lastSceneBase;
  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) =>
      throw StateError('Unexpected read');
  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication value,
  ) async => NarrativePublicationReceipt(
    beforeManifest: maps.project!,
    manifest: maps.project!.copyWith(scenes: value.scenes),
    savedMap: value.current,
    revision: 'narrative',
    sourceRevisions: {},
    changedPaths: ['project.json'],
  );
  @override
  Future<ScenePublicationReceipt> publishScene({
    required SceneAsset? base,
    required SceneAsset current,
  }) async {
    lastSceneBase = base;
    final before = maps.project!;
    if (before.scenes.where((scene) => scene.id == current.id).firstOrNull !=
        base) {
      throw const SceneFailure('Base périmée');
    }
    await gate?.future;
    return ScenePublicationReceipt(
      scene: current,
      catalog: ResourceMutationReceipt(
        before: before,
        manifest: before.copyWith(scenes: [current]),
        beforeRevision: 'old',
        revision: 'new',
        changedPaths: ['project.json'],
      ),
    );
  }
}
