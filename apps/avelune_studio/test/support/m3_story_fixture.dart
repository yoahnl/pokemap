import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/dialogue_draft_codec.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';

class M3StoryFixture {
  M3StoryFixture(this.directory, this.session, this.maps, this.receipt);
  final Directory directory;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter maps;
  final NarrativePublicationReceipt receipt;

  static Future<M3StoryFixture> create() async {
    final temporary = await Directory.systemTemp.createTemp(
      'avelune_m3_story_',
    );
    final directory = Directory(await temporary.resolveSymbolicLinks());
    await writeExampleProject(directory);
    final session = ProjectSession(
      sessionId: directory.path,
      name: 'Départ',
      directoryPath: directory.path,
    );
    final maps = LocalMapWorkspaceAdapter();
    final manifest = await maps.loadProject(session);
    final base = await maps.loadMap(session, manifest.maps.first);
    final map = base.map.copyWith(
      entities: [
        ...base.map.entities,
        const MapEntity(
          id: 'chief',
          name: 'Chef de gare',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 8, y: 10),
          npc: MapEntityNpcData(characterId: 'guide'),
        ),
        const MapEntity(
          id: 'traveller',
          name: 'Voyageuse',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 10, y: 10),
          npc: MapEntityNpcData(characterId: 'guide'),
        ),
      ],
      triggers: [
        const MapTrigger(
          id: 'quai',
          name: 'Quai',
          type: TriggerType.event,
          area: MapRect(
            pos: GridPos(x: 11, y: 9),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      ],
    );
    final dialogues = [
      _dialogue('offer', 'Voulez-vous aider au départ ?', choices: true),
      _dialogue('before', 'Je patiente avant le départ.'),
      _dialogue('traveller', 'Merci, ma place est prête !'),
      _dialogue('waiting', 'Retrouvez la voyageuse.'),
      _dialogue('finish', 'Tout est prêt, départ autorisé !'),
      _dialogue('conclusion', 'Merci encore pour votre aide.'),
      _dialogue('zone', 'Bienvenue sur le quai.'),
    ];
    final interactions = [
      _interaction(
        1,
        map.id,
        'chief',
        'offer',
        conditions: [_fact('started', false)],
        branches: {
          'accepted': [
            const NarrativeSequenceStep(
              kind: NarrativeSequenceKind.setFact,
              targetId: 'started',
            ),
            const NarrativeSequenceStep(
              kind: NarrativeSequenceKind.completeStep,
              targetId: 'prepare',
            ),
          ],
          'refused': [],
        },
      ),
      _interaction(
        2,
        map.id,
        'traveller',
        'before',
        conditions: [_fact('started', false)],
      ),
      _interaction(
        3,
        map.id,
        'traveller',
        'traveller',
        conditions: [_fact('started', true), _fact('visited', false)],
        steps: [
          const NarrativeSequenceStep(
            kind: NarrativeSequenceKind.setFact,
            targetId: 'visited',
          ),
          const NarrativeSequenceStep(
            kind: NarrativeSequenceKind.completeStep,
            targetId: 'help',
          ),
        ],
        oneShot: true,
      ),
      _interaction(
        4,
        map.id,
        'chief',
        'waiting',
        conditions: [_fact('started', true), _fact('visited', false)],
      ),
      _interaction(
        5,
        map.id,
        'chief',
        'finish',
        conditions: [_fact('visited', true), _fact('finished', false)],
        steps: [
          const NarrativeSequenceStep(
            kind: NarrativeSequenceKind.facing,
            targetId: 'chief',
            facing: EntityFacing.west,
          ),
          const NarrativeSequenceStep(
            kind: NarrativeSequenceKind.wait,
            milliseconds: 80,
          ),
          const NarrativeSequenceStep(
            kind: NarrativeSequenceKind.setFact,
            targetId: 'finished',
          ),
          const NarrativeSequenceStep(
            kind: NarrativeSequenceKind.completeStep,
            targetId: 'finish',
          ),
        ],
        oneShot: true,
      ),
      _interaction(
        6,
        map.id,
        'chief',
        'conclusion',
        conditions: [_fact('finished', true)],
      ),
      NarrativeInteractionDraft(
        id: _eventId(7),
        name: 'Accueil quai',
        mapId: map.id,
        source: NarrativeEventSourceRef.triggerEnter(map.id, 'quai'),
        dialogueId: 'zone',
        oneShot: true,
      ),
    ].map((draft) => draft.project()).toList();
    final receipt =
        await LocalNarrativeAdapter(session: session, mapAdapter: maps).publish(
          NarrativePublication(
            base: base,
            current: map,
            dialogues: dialogues,
            scenes: interactions.map((item) => item.scene).toList(),
            cinematics: interactions.expand((item) => item.cinematics).toList(),
            events: interactions.map((item) => item.event).toList(),
            facts: [
              for (final entry in {
                'started': 'Aide acceptée',
                'visited': 'Voyageuse prête',
                'finished': 'Départ autorisé',
              }.entries)
                NarrativeFactDefinition(id: entry.key, label: entry.value),
            ],
            storylines: [
              createStudioStoryline(
                id: 'departure',
                title: 'Préparer le départ',
                steps: {
                  'prepare': 'Accepter d’aider',
                  'help': 'Aider la voyageuse',
                  'finish': 'Annoncer le départ',
                },
              ),
            ],
          ),
        );
    return M3StoryFixture(directory, session, maps, receipt);
  }
}

String _eventId(int value) =>
    'evt_019abcde-9000-7000-8000-${value.toString().padLeft(12, '0')}';
NarrativeEventCondition _fact(String id, bool value) =>
    NarrativeEventCondition.fact(id, value);
NarrativeInteractionDraft _interaction(
  int id,
  String mapId,
  String entityId,
  String dialogueId, {
  List<NarrativeEventCondition> conditions = const [],
  List<NarrativeSequenceStep> steps = const [],
  Map<String, List<NarrativeSequenceStep>> branches = const {},
  bool oneShot = false,
}) => NarrativeInteractionDraft(
  id: _eventId(id),
  name: _title(dialogueId),
  mapId: mapId,
  source: NarrativeEventSourceRef.entityInteract(mapId, entityId),
  dialogueId: dialogueId,
  conditions: conditions,
  steps: steps,
  branches: branches,
  oneShot: oneShot,
  order: id,
);

NarrativeDialogueSource _dialogue(
  String id,
  String text, {
  bool choices = false,
}) => const DialogueDraftCodec().encode(
  DialogueDraft(
    entry: ProjectDialogueEntry(
      id: id,
      name: _title(id),
      relativePath: 'dialogues/$id.yarn',
    ),
    branches: [
      DialogueBranchDraft(
        id: 'Start',
        name: 'Début',
        lines: [DialogueLineDraft(text: text)],
        choices: [
          if (choices) ...[
            const DialogueChoiceDraft(
              text: 'Je vous aide',
              targetId: 'Accept',
              outcomeId: 'accepted',
            ),
            const DialogueChoiceDraft(
              text: 'Pas maintenant',
              targetId: 'Refuse',
              outcomeId: 'refused',
            ),
          ],
        ],
      ),
      if (choices) ...[
        const DialogueBranchDraft(
          id: 'Accept',
          name: 'Accepter',
          lines: [
            DialogueLineDraft(text: 'Très bien, retrouvez la voyageuse.'),
          ],
        ),
        const DialogueBranchDraft(
          id: 'Refuse',
          name: 'Refuser',
          lines: [DialogueLineDraft(text: 'Revenez quand vous voulez.')],
        ),
      ],
    ],
  ),
);

String _title(String id) => switch (id) {
  'offer' => 'Proposition du chef de gare',
  'before' => 'Voyageuse · avant le départ',
  'traveller' => 'Aider la voyageuse',
  'waiting' => 'Le chef attend votre retour',
  'finish' => 'Autoriser le départ',
  'conclusion' => 'Remerciements du chef',
  'zone' => 'Accueil sur le quai',
  _ => id,
};
