import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/narrative/application/dialogue_portrait_selection.dart';
import '../../../features/narrative/domain/dialogue_draft.dart';

class DialoguePortraitChoice extends StatelessWidget {
  const DialoguePortraitChoice({
    super.key,
    required this.project,
    required this.line,
    required this.onChanged,
  });
  final ProjectManifest project;
  final DialogueLineDraft line;
  final ValueChanged<DialogueLineDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final selection = DialoguePortraitSelection.of(project, line);
    if (selection == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DropdownButtonFormField<String>(
        key: ValueKey(
          'portrait-${selection.characterId}-${line.portraitStateId}',
        ),
        initialValue: line.portraitStateId ?? '',
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Portrait de cette réplique',
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('Sans portrait')),
          for (final MapEntry(key: id, value: label)
              in selection.states.entries)
            DropdownMenuItem(
              value: id,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (selection.missing)
            DropdownMenuItem(
              value: line.portraitStateId,
              enabled: false,
              child: const Text(
                'Portrait introuvable · choisissez un autre portrait',
              ),
            ),
        ],
        onChanged: (state) =>
            onChanged(DialoguePortraitSelection.choose(line, state)),
      ),
    );
  }
}
