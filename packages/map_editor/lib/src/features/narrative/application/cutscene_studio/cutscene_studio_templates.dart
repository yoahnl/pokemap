// Cutscene Studio — gabarits et flow de démo (seeds produit).

import 'cutscene_studio_flow.dart';
import 'cutscene_studio_models.dart';

enum CutsceneStudioTemplateKind {
  npcDialogue,
  mapEnterDialogue,
  npcScript,

  /// Parcours de démo avec branches Oui / Non (Cutscene Studio visuel).
  visualFlowDemo,
}

String cutsceneStudioTemplateLabel(CutsceneStudioTemplateKind kind) {
  return switch (kind) {
    CutsceneStudioTemplateKind.npcDialogue =>
      'Dialogue simple (interaction PNJ)',
    CutsceneStudioTemplateKind.mapEnterDialogue => 'Entrée map -> dialogue',
    CutsceneStudioTemplateKind.npcScript => 'Interaction PNJ -> script',
    CutsceneStudioTemplateKind.visualFlowDemo =>
      'Démo « studio narratif » (flow + question)',
  };
}

/// Cutscene d’exemple alignée sur le wireframe produit (Start → … → question).
CutsceneStudioDocument createCutsceneStudioDemoFlowDocument({
  required String id,
  required String name,
  String? mapId,
  String? entityId,
}) {
  final npcId = entityId ?? 'npc_emma';
  final flow = <CutsceneFlowEntry>[
    CutsceneFlowBlockEntry(
      CutsceneStudioBlock(
        id: 'demo_parler',
        kind: CutsceneStudioBlockKind.dialogue,
        actorId: npcId,
        messageText:
            'Bonjour ! Je suis ravie de t’accueillir. Allons voir le laboratoire.',
      ),
    ),
    CutsceneFlowBlockEntry(
      CutsceneStudioBlock(
        id: 'demo_deplacer',
        kind: CutsceneStudioBlockKind.moveCharacter,
        actorId: npcId,
        destinationTargetKind: kCutsceneStudioMoveTargetSpawn,
        destinationTargetId: npcId,
        waitForCompletion: true,
      ),
    ),
    CutsceneFlowChoiceEntry(
      question: CutsceneStudioBlock(
        id: 'demo_question',
        kind: CutsceneStudioBlockKind.playerQuestion,
        messageText: 'Es-tu prêt à commencer ton aventure ?',
        choiceOptions: const ['Oui', 'Non'],
      ),
      onYes: const <CutsceneFlowEntry>[],
      onNo: const <CutsceneFlowEntry>[],
    ),
  ];
  return CutsceneStudioDocument(
    id: id,
    name: name,
    description: 'Démonstration du Cutscene Studio (composition par blocs).',
    source: CutsceneStudioSourceConfig(
      kind: CutsceneStudioSourceKind.entityInteract,
      mapId: mapId,
      entityId: npcId,
    ),
    blocks: flattenMainTrunkFlowToBlocks(flow),
    cutsceneFlow: flow,
  );
}

CutsceneStudioDocument createCutsceneStudioTemplateDocument({
  required CutsceneStudioTemplateKind template,
  required String id,
  required String name,
  String? description,
  String? mapId,
  String? entityId,
  String? dialogueId,
  String? scriptId,
}) {
  if (template == CutsceneStudioTemplateKind.visualFlowDemo) {
    return createCutsceneStudioDemoFlowDocument(
      id: id,
      name: name,
      mapId: mapId,
      entityId: entityId,
    );
  }
  final source = switch (template) {
    CutsceneStudioTemplateKind.npcDialogue ||
    CutsceneStudioTemplateKind.npcScript =>
      CutsceneStudioSourceConfig(
        kind: CutsceneStudioSourceKind.entityInteract,
        mapId: mapId,
        entityId: entityId,
      ),
    CutsceneStudioTemplateKind.mapEnterDialogue => CutsceneStudioSourceConfig(
        kind: CutsceneStudioSourceKind.mapEnter,
        mapId: mapId,
      ),
    CutsceneStudioTemplateKind.visualFlowDemo =>
      throw StateError('visualFlowDemo handled above'),
  };

  final blocks = switch (template) {
    CutsceneStudioTemplateKind.npcDialogue ||
    CutsceneStudioTemplateKind.mapEnterDialogue =>
      <CutsceneStudioBlock>[
        CutsceneStudioBlock(
          id: 'block_dialogue_1',
          kind: CutsceneStudioBlockKind.dialogue,
          actorId: entityId,
          dialogueId: dialogueId,
        ),
      ],
    CutsceneStudioTemplateKind.npcScript => <CutsceneStudioBlock>[
        CutsceneStudioBlock(
          id: 'block_script_1',
          kind: CutsceneStudioBlockKind.runScript,
          scriptId: scriptId,
        ),
      ],
    CutsceneStudioTemplateKind.visualFlowDemo =>
      throw StateError('visualFlowDemo handled above'),
  };

  return CutsceneStudioDocument(
    id: id,
    name: name,
    description: description?.trim() ?? '',
    source: source,
    blocks: blocks,
  );
}
