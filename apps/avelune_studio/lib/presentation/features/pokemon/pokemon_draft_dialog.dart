import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_button.dart';

enum PokemonDraftDecision { stay, discard, save }

Future<PokemonDraftDecision?> showPokemonDraftDialog(BuildContext context) =>
    showDialog<PokemonDraftDecision>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Conserver le brouillon Pokémon ?'),
        content: const Text(
          'La fiche contient des modifications non enregistrées.',
        ),
        actions: [
          StudioButton(
            label: 'Rester',
            secondary: true,
            onPressed: () =>
                Navigator.pop(dialogContext, PokemonDraftDecision.stay),
          ),
          StudioButton(
            label: 'Annuler les modifications',
            secondary: true,
            onPressed: () =>
                Navigator.pop(dialogContext, PokemonDraftDecision.discard),
          ),
          StudioButton(
            label: 'Enregistrer',
            onPressed: () =>
                Navigator.pop(dialogContext, PokemonDraftDecision.save),
          ),
        ],
      ),
    );
