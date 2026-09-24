import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import 'pokemon_draft_controls.dart';

class PokemonSpeciesFormsEditor extends StatelessWidget {
  const PokemonSpeciesFormsEditor({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final fields = PokemonDraftControls(
      controller,
      PokemonDocumentFamily.species,
    );
    final forms = (fields.data['forms'] as Map?)?.cast<String, dynamic>() ?? {};
    return Column(
      children: [
        StudioPanel(
          title: 'Forme et classification',
          children: [
            fields.text('Identifiant de la forme de base', [
              'forms',
              'baseFormId',
            ]),
            fields.text('Identifiant de cette forme', ['forms', 'formId']),
            fields.text('Nom de la forme', ['forms', 'formName']),
            fields.toggle('Forme de base', ['forms', 'isBaseForm']),
            StudioDraftField(
              key: const ValueKey('species-forms.otherForms'),
              label: 'Autres identifiants de forme · séparés par une virgule',
              value: (forms['otherForms'] as List? ?? const []).join(', '),
              onChanged: (value) =>
                  controller.edit(PokemonDocumentFamily.species, (json) {
                    final current = Map<String, dynamic>.from(
                      json['forms'] as Map? ?? {},
                    );
                    current['otherForms'] = value
                        .split(',')
                        .map((item) => item.trim())
                        .where((item) => item.isNotEmpty)
                        .toList();
                    json['forms'] = current;
                  }),
            ),
            const Text('Ces liens ne créent pas de nouvelle espèce.'),
            fields.toggle('Obtenable', ['classification', 'isObtainable']),
            fields.toggle('Légendaire', ['classification', 'isLegendary']),
            fields.toggle('Mythique', ['classification', 'isMythical']),
            fields.toggle('Bébé', ['classification', 'isBaby']),
          ],
        ),
      ],
    );
  }
}
