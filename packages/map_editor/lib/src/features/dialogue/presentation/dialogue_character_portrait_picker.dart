import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';

typedef DialogueCharacterPortraitChanged =
    void Function(String? characterId, String? portraitStateId);

class DialogueCharacterPortraitPicker extends StatelessWidget {
  const DialogueCharacterPortraitPicker({
    super.key,
    required this.project,
    required this.characterId,
    required this.portraitStateId,
    required this.onChanged,
    this.enabled = true,
  });

  final ProjectManifest project;
  final String? characterId;
  final String? portraitStateId;
  final DialogueCharacterPortraitChanged onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final characters = project.characters.toList()
      ..sort((left, right) => left.name.compareTo(right.name));
    final states = project.characterStudioCatalog.portraitStates.toList()
      ..sort((left, right) {
        final order = left.sortOrder.compareTo(right.sortOrder);
        return order != 0 ? order : left.id.compareTo(right.id);
      });
    final selectedCharacter = characters
        .where((character) => character.id == characterId)
        .firstOrNull;
    final effectiveStateId = _effectiveStateId(selectedCharacter, states);
    final portraitDefined =
        selectedCharacter != null &&
        effectiveStateId != null &&
        selectedCharacter.portraits.any(
          (portrait) => portrait.portraitStateId == effectiveStateId,
        );
    return PokeMapPanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.person_crop_rectangle,
                tone: PokeMapTone.narrative,
                size: 34,
                iconSize: 16,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: PokeMapSectionHeader(
                  title: 'Portrait de dialogue',
                  description: 'Sélection guidée, sans syntaxe Yarn.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<String>(
            key: const ValueKey<String>('dialogue-line-character-picker'),
            label: 'Personnage',
            value: selectedCharacter?.id ?? '',
            items: <PokeMapDropdownItem<String>>[
              const PokeMapDropdownItem<String>(
                value: '',
                label: 'Aucun portrait',
              ),
              for (final character in characters)
                PokeMapDropdownItem<String>(
                  value: character.id,
                  label: character.name,
                ),
            ],
            enabled: enabled,
            compact: true,
            onChanged: (value) {
              if (value.isEmpty) {
                onChanged(null, null);
                return;
              }
              final character = characters
                  .where((entry) => entry.id == value)
                  .firstOrNull;
              final stateId = _defaultStateId(character, states);
              if (character == null || stateId == null) {
                onChanged(null, null);
                return;
              }
              onChanged(character.id, stateId);
            },
          ),
          const SizedBox(height: 8),
          PokeMapDropdownField<String>(
            key: const ValueKey<String>('dialogue-line-portrait-state-picker'),
            label: 'Expression',
            value: effectiveStateId ?? '',
            items: <PokeMapDropdownItem<String>>[
              for (final state in states)
                PokeMapDropdownItem<String>(
                  value: state.id,
                  label: state.displayName,
                ),
            ],
            enabled: enabled && selectedCharacter != null && states.isNotEmpty,
            compact: true,
            onChanged: (value) {
              final character = selectedCharacter;
              if (character != null) onChanged(character.id, value);
            },
          ),
          if (selectedCharacter != null && !portraitDefined) ...[
            const SizedBox(height: 8),
            PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.warning,
              message: 'Portrait non défini pour ${selectedCharacter.name}',
            ),
          ],
        ],
      ),
    );
  }

  String? _effectiveStateId(
    ProjectCharacterEntry? character,
    List<CharacterPortraitStateDefinition> states,
  ) {
    if (character == null) return null;
    final requested = portraitStateId;
    if (requested != null && states.any((state) => state.id == requested)) {
      return requested;
    }
    return _defaultStateId(character, states);
  }

  String? _defaultStateId(
    ProjectCharacterEntry? character,
    List<CharacterPortraitStateDefinition> states,
  ) {
    if (character == null || states.isEmpty) return null;
    for (final state in states) {
      if (character.portraits.any(
        (portrait) => portrait.portraitStateId == state.id,
      )) {
        return state.id;
      }
    }
    final neutral = states.where((state) => state.id == 'neutral').firstOrNull;
    return neutral?.id ?? states.first.id;
  }
}
