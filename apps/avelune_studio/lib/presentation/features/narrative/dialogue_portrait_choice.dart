import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
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
    final character = project.characters
        .where((entry) => entry.id == line.speakerId)
        .firstOrNull;
    if (character == null || character.portraits.isEmpty) {
      return const SizedBox();
    }
    final definitions = {
      for (final state in project.characterStudioCatalog.portraitStates)
        state.id: state.displayName,
    };
    final states = character.portraits
        .map((entry) => entry.portraitStateId)
        .toSet();
    final missing =
        line.portraitStateId != null && !states.contains(line.portraitStateId);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DropdownButtonFormField<String>(
        key: ValueKey('portrait-${character.id}-${line.portraitStateId}'),
        initialValue: line.portraitStateId ?? '',
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Portrait de cette réplique',
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('Sans portrait')),
          for (final id in states)
            DropdownMenuItem(
              value: id,
              child: Text(
                definitions[id] ?? 'Portrait sans libellé',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (missing)
            DropdownMenuItem(
              value: line.portraitStateId,
              enabled: false,
              child: const Text(
                'Portrait introuvable · choisissez un autre portrait',
              ),
            ),
        ],
        onChanged: (state) => onChanged(
          DialogueLineDraft(
            text: line.text,
            speakerId: line.speakerId,
            portraitStateId: state == null || state.isEmpty ? null : state,
          ),
        ),
      ),
    );
  }
}
