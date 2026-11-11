import 'dart:typed_data';

import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';

import '../domain/dialogue_port.dart';
import 'dialogue_workspace_controller.dart';

const dialogueDefaultResponseLabel = 'Nouvelle réponse';
const dialogueDefaultLineText = 'Bonjour !';
const dialogueDefaultNarrationText = 'Une nouvelle narration.';
const dialogueChoiceStarterLabels = ['Oui', 'Non'];

String dialogueJumpTargetTitle(List<DialogueEditorStep> steps) =>
    steps.whereType<DeJumpStep>().firstOrNull?.targetTitle ?? '';

String dialoguePreviewStartLabel(DialogueEditSession? session) =>
    session?.startNode ??
    session?.entry.defaultStartNode ??
    'départ du document';

bool dialoguePreviewCanContinue(DialoguePreviewState preview) =>
    preview.line != null && preview.error == null && !preview.ended;

bool dialogueOutcomeEmitted(DialogueEditSession session, String outcomeId) =>
    session.document.documentOutcomes().any((o) => o.id == outcomeId);

Future<Uint8List?>? readDialoguePortrait(
  DialoguePort port,
  String? characterId,
  String? stateId,
) =>
    port is DialoguePortraitPort && characterId != null && stateId != null
    ? (port as DialoguePortraitPort).readPortrait(characterId, stateId)
    : null;

extension DialogueWorkspaceAuthoring on DialogueWorkspaceController {
  String? addDefaultLine(String nodeId, {required bool narration}) => addLine(
    nodeId,
    text: narration ? dialogueDefaultNarrationText : dialogueDefaultLineText,
    narration: narration,
  );

  String? addChoiceWithStarterResponses(String nodeId) {
    final choice = addChoice(nodeId);
    if (choice == null) return null;
    for (final label in dialogueChoiceStarterLabels) {
      addResponse(choice, label);
    }
    return choice;
  }

  String? addDefaultResponse(String choiceId) =>
      addResponse(choiceId, dialogueDefaultResponseLabel);

  String? addOutcomeAssigned(String label, {String? branchId}) {
    final id = addOutcome(label);
    if (id != null && branchId != null) assignOutcome(branchId, id);
    return id;
  }

  String? nodeIdForTitle(String title) => active?.document.nodes
      .where((node) => node.title == title)
      .firstOrNull
      ?.id;

  bool disconnectNodeJump(String nodeId) {
    final jump = active?.document
        .nodeById(nodeId)
        ?.steps
        .whereType<DeJumpStep>()
        .firstOrNull;
    return jump == null ? false : disconnectJump(jump.id);
  }

  Map<String, String> get lineCharacterChoices => {
    '': 'Sans personnage',
    for (final character in project.characters) character.id: character.name,
  };

  bool selectLineCharacter(String lineId, String characterId) {
    final character = project.characters
        .where((entry) => entry.id == characterId)
        .firstOrNull;
    return updateLine(
      lineId,
      characterId: characterId,
      clearPortrait: characterId.isEmpty,
      speaker: character?.name,
      portraitStateId: character?.portraits.firstOrNull?.portraitStateId,
    );
  }

  Map<String, String>? expressionChoices(DeLineStep line) {
    final character = project.characters
        .where((entry) => entry.id == line.characterId)
        .firstOrNull;
    if (character == null || character.portraits.isEmpty) return null;
    final names = {
      for (final state in project.characterStudioCatalog.portraitStates)
        state.id: state.displayName,
    };
    return {
      '': 'Sans portrait',
      for (final portrait in character.portraits)
        portrait.portraitStateId:
            names[portrait.portraitStateId] ?? portrait.portraitStateId,
    };
  }

  bool lineHasNoPreparedPortrait(DeLineStep line) =>
      !project.characters.any(
        (entry) => entry.id == line.characterId && entry.portraits.isNotEmpty,
      );

  List<ProjectDialogueEntry> filteredEntries({
    required String query,
    required String folderId,
  }) {
    final needle = query.trim().toLowerCase();
    return entries
        .where(
          (entry) =>
              entry.name.toLowerCase().contains(needle) &&
              (folderId.isEmpty || entry.folderId == folderId),
        )
        .toList();
  }

  String libraryFolderName(ProjectDialogueEntry entry) =>
      project.dialogueFolders
          .where((folder) => folder.id == entry.folderId)
          .firstOrNull
          ?.name ??
      'Dialogues du projet';

  String libraryStatus(String dialogueId) {
    final session = this.session(dialogueId);
    return session == null
        ? 'Contenu à ouvrir'
        : '${session.document.nodes.length} suites${session.dirty ? ' · brouillon' : ''}';
  }
}
