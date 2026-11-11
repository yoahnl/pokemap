import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => StudioSelect(
    key: ValueKey('dialogue-text-value-$targetId'),
    label: 'Insérer une valeur',
    value: '',
    options: {'': 'Choisir une valeur…', ...controller.textValueChoices},
    onChanged: (value) {
      if (value.isNotEmpty) {
        controller.insertTextValueChoice(targetId, value, response: response);
      }
    },
  );
}
