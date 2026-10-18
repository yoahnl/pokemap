import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/dialogues/application/dialogue_workspace_controller.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class DialogueTextValuePicker extends StatelessWidget {
  const DialogueTextValuePicker({
    super.key,
    required this.controller,
    required this.targetId,
    this.response = false,
  });
  final DialogueWorkspaceController controller;
  final String targetId;
  final bool response;

  @override
  Widget build(BuildContext context) {
    bool supported(String id) {
      try {
        dialogueFactPlaceholder(id);
        return controller.project.facts.where((fact) => fact.id == id).length ==
            1;
      } on FormatException {
        return false;
      }
    }

    return StudioSelect(
      key: ValueKey('dialogue-text-value-$targetId'),
      label: 'Insérer une valeur',
      value: '',
      options: {
        '': 'Choisir une valeur…',
        'player_name': 'Nom du joueur',
        for (final fact in controller.project.facts.where(
          (fact) => supported(fact.id),
        ))
          'fact:${fact.id}': '${fact.label} (${fact.valueKind.wireName})',
      },
      onChanged: (value) {
        if (value.isNotEmpty) {
          controller.insertTextValue(
            targetId,
            value.startsWith('fact:') ? value.substring(5) : value,
            response: response,
            fact: value.startsWith('fact:'),
          );
        }
      },
    );
  }
}
