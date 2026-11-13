import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/interaction_edit_session.dart';
import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'dialogue_draft_codec_test.dart' show dialogueFixture;

void main() {
  test('sequence projections keep native owners and revising retains unknown references', () {
    const step = NarrativeSequenceStep(
      kind: NarrativeSequenceKind.facing,
      targetId: 'missing',
      value: false,
      facing: EntityFacing.east,
      milliseconds: 725,
    );
    final changed = step.revise(facing: EntityFacing.west);
    expect(changed.targetId, 'missing');
    expect(changed.value, isFalse);
    expect(changed.milliseconds, 725);
    expect(step.facing, EntityFacing.east);
    final project = ProjectManifest(
      name: 'Cibles',
      maps: [],
      tilesets: [],
      facts: [
        NarrativeFactDefinition(id: 'ready', label: 'Prêt'),
        NarrativeFactDefinition(
          id: 'count',
          label: 'Nombre',
          initialValue: NarrativeValue.integer(1),
        ),
      ],
    );
    expect(
      narrativeSequenceTargets(NarrativeSequenceKind.setFact, project: project),
      {'ready': 'Prêt'},
    );
    final map = workspaceMap('a').copyWith(
      entities: const [
        MapEntity(
          id: 'guide',
          name: 'Guide',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 0, y: 0),
          npc: MapEntityNpcData(),
        ),
      ],
    );
    expect(
      narrativeSequenceTargets(
        NarrativeSequenceKind.facing,
        project: project,
        map: map,
      ),
      {'guide': 'Guide'},
    );
    final story = createStudioStoryline(
      id: 'side',
      title: 'Mission',
      steps: {'finish': 'Fin'},
    );
    expect(
      narrativeSequenceTargets(
        NarrativeSequenceKind.completeStep,
        project: project,
        stories: [story],
      ),
      {'finish': 'Mission · Fin'},
    );
    expect(
      narrativeSequenceTargets(NarrativeSequenceKind.wait, project: project),
      isEmpty,
    );
    expect(project.storylines, isEmpty);
  });
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late _Port port;
  late InteractionEditSession edit;
  setUp(() async {
    maps = MapWorkspaceController(workspaceSession, WorkspaceMemoryPort());
    await maps.initialize();
    port = _Port(maps);
    narrative = NarrativeWorkspaceController(
      maps,
      port,
      () {},
      (manifest, paths) async {},
    );
    edit = InteractionEditSession(
      document: maps.active!,
      dialogue: dialogueFixture(),
      interaction: NarrativeInteractionDraft(
        id: 'evt_00000000-0000-7000-8000-000000000001',
        name: 'Conversation',
        mapId: 'a',
        source: NarrativeEventSourceRef.entityInteract('a', 'chief'),
        dialogueId: 'station',
        branches: {
          'accepted': [
            const NarrativeSequenceStep(
              kind: NarrativeSequenceKind.setFact,
              targetId: 'help',
            ),
          ],
        },
      ),
    );
    narrative.sessions[edit.current.interaction.id] = edit;
    narrative.active = edit;
  });
  tearDown(() => maps.dispose());

}

class _Port implements NarrativePort {
  _Port(this.maps);
  final MapWorkspaceController maps;
  bool fail = false;
  Completer<void>? gate;
  NarrativeDialogueSource? source;
  final publications = <NarrativePublication>[];
  @override
  Future<NarrativeDialogueSource> readDialogue(
    ProjectDialogueEntry entry,
  ) async => source!;
  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) async {
    publications.add(publication);
    await gate?.future;
    if (fail) throw const NarrativeFailure('Conflit externe');
    return NarrativePublicationReceipt(
      beforeManifest: maps.project!,
      manifest: maps.project!,
      savedMap: publication.current,
      revision: 'map-${publications.length}',
      sourceRevisions: {
        for (final source in publication.dialogues)
          source.entry.id: 'source-${publications.length}',
      },
      changedPaths: const [],
    );
  }
}
