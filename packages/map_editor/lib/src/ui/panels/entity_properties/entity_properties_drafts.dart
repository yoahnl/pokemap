part of 'package:map_editor/src/ui/panels/entity_properties_panel.dart';

/// Draft mutable d'une paire clé/valeur avant sérialisation sur l'entité.
///
/// Le panneau garde des contrôleurs séparés pour éviter d'écrire dans le
/// modèle tant que l'utilisateur n'a pas validé.
class _EntityPropertyDraft {
  _EntityPropertyDraft({
    required this.keyController,
    required this.valueController,
  });

  factory _EntityPropertyDraft.empty() {
    return _EntityPropertyDraft(
      keyController: TextEditingController(),
      valueController: TextEditingController(),
    );
  }

  final TextEditingController keyController;
  final TextEditingController valueController;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

/// Draft local pour les waypoints PNJ.
class _NpcWaypointDraft {
  _NpcWaypointDraft({
    required this.xController,
    required this.yController,
  });

  final TextEditingController xController;
  final TextEditingController yController;

  void dispose() {
    xController.dispose();
    yController.dispose();
  }
}

/// Une ligne « dialogue conditionnel » dans l’inspecteur (état mutable).
///
/// Les ids métier ([refMenuId], [dialogueMenuId]) viennent des menus — pas de
/// saisie libre. Seul [startNode] reste un champ texte optionnel.
class _NpcConditionalDialogueRowDraft {
  _NpcConditionalDialogueRowDraft({
    required this.conditionKind,
    required this.refMenuId,
    required this.dialogueMenuId,
    required this.startNode,
  });

  factory _NpcConditionalDialogueRowDraft.fromModel(
    MapEntityConditionalDialogue model,
  ) {
    final when = model.when;
    final dialogue = model.dialogue;
    final dialogueId = dialogue.dialogueId.trim();
    return _NpcConditionalDialogueRowDraft(
      conditionKind: when.kind,
      refMenuId: when.refId.trim().isEmpty
          ? kNpcRuntimeRefNoneMenuId
          : when.refId.trim(),
      dialogueMenuId:
          dialogueId.isEmpty ? _kDialogueNoneMenuId : dialogueId,
      startNode: TextEditingController(text: dialogue.startNode ?? ''),
    );
  }

  factory _NpcConditionalDialogueRowDraft.empty() {
    return _NpcConditionalDialogueRowDraft(
      conditionKind: MapEntityRuntimePredicateKind.storyFlagSet,
      refMenuId: kNpcRuntimeRefNoneMenuId,
      dialogueMenuId: _kDialogueNoneMenuId,
      startNode: TextEditingController(),
    );
  }

  MapEntityRuntimePredicateKind conditionKind;
  String refMenuId;
  String dialogueMenuId;
  final TextEditingController startNode;

  void dispose() {
    startNode.dispose();
  }
}
