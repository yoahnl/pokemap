import '../../../features/pokemon/application/pokemon_combat_choices.dart';
export '../../../features/pokemon/application/pokemon_combat_choices.dart';

import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_combat_controller.dart';

import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../theme/studio_tokens.dart';

Future<String?> chooseCombatSpecies(
  BuildContext context,
  PokemonWorkspaceIndex index,
) => _chooseCombat(
  context,
  title: 'Choisir une espèce',
  search: 'Rechercher une espèce',
  hint: 'Nom, numéro ou type',
  choices: combatSpeciesChoices(index),
);

Future<String?> chooseCombatMove(
  BuildContext context,
  PokemonWorkspaceIndex index, {
  Iterable<String> exclude = const [],
}) {
  return _chooseCombat(
    context,
    title: 'Choisir une attaque',
    search: 'Rechercher une attaque',
    hint: 'Nom, type ou catégorie',
    choices: combatMoveChoices(index, exclude: exclude),
  );
}

Future<String?> _chooseCombat(
  BuildContext context, {
  required String title,
  required String search,
  required String hint,
  required List<CombatChoice> choices,
}) => showDialog<String>(
  context: context,
  builder: (_) => _CombatChoiceDialog(
    title: title,
    search: search,
    hint: hint,
    choices: choices,
  ),
);

class _CombatChoiceDialog extends StatefulWidget {
  const _CombatChoiceDialog({
    required this.title,
    required this.search,
    required this.hint,
    required this.choices,
  });

  final String title, search, hint;
  final List<CombatChoice> choices;

  @override
  State<_CombatChoiceDialog> createState() => _CombatChoiceDialogState();
}

class _CombatChoiceDialogState extends State<_CombatChoiceDialog> {
  final _query = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matches = combatChoiceSearch(widget.choices, _query.text);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: (MediaQuery.sizeOf(context).height - 48).clamp(240, 560),
        ),
        child: Padding(
          padding: const EdgeInsets.all(StudioMetrics.panelPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              StudioSearchField(
                key: const ValueKey('combat-choice-search'),
                controller: _query,
                focusNode: _focus,
                label: widget.search,
                hint: widget.hint,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Text(
                '${matches.length} sur ${widget.choices.length}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: matches.isEmpty
                    ? const Center(
                        child: Text('Aucun résultat pour cette recherche.'),
                      )
                    : ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (context, position) {
                          final choice = matches[position];
                          return StudioChoice(
                            key: ValueKey('combat-choice-${choice.id}'),
                            label: choice.label,
                            subtitle: choice.details,
                            onTap: () => Navigator.of(context).pop(choice.id),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: StudioButton(
                  label: 'Annuler',
                  secondary: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> chooseTrainerSpecies(
  BuildContext context,
  PokemonCombatController combat,
  PokemonWorkspaceIndex index,
) async {
  final chosen = await chooseCombatSpecies(context, index);
  if (chosen == null) return;
  combat.addTrainerSpecies(chosen);
}
