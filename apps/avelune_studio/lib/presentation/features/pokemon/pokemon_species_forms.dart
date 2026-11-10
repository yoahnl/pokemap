import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'pokemon_draft_controls.dart';
import 'pokemon_ui_parts.dart';

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
    final currentId = '${forms['formId'] ?? ''}';
    final currentForm = StudioPanel(
      title: 'Forme courante',
      children: [
        PokemonSurface(
          emphasized: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${forms['formName'] ?? 'Forme $currentId'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              PokemonDataRow(label: 'Identifiant', value: currentId),
              PokemonPill(
                label: forms['isBaseForm'] == true
                    ? 'Forme de base'
                    : 'Forme liée',
                success: forms['isBaseForm'] == true,
              ),
            ],
          ),
        ),
      ],
    );
    final editor = Column(
      children: [
        StudioPanel(
          title: 'Identifiants et classification',
          children: [
            fields.text('Identifiant de la forme de base', [
              'forms',
              'baseFormId',
            ]),
            fields.text('Identifiant de cette forme', ['forms', 'formId']),
            fields.text('Nom de la forme', ['forms', 'formName']),
            fields.toggle('Forme de base', ['forms', 'isBaseForm']),
            const Divider(height: 24),
            fields.toggle('Obtenable', ['classification', 'isObtainable']),
            fields.toggle('Légendaire', ['classification', 'isLegendary']),
            fields.toggle('Mythique', ['classification', 'isMythical']),
            fields.toggle('Bébé', ['classification', 'isBaby']),
          ],
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, bounds) {
        if (bounds.maxWidth < 760 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return Column(
            children: [currentForm, const SizedBox(height: 12), editor],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: currentForm),
            const SizedBox(width: 12),
            Expanded(child: editor),
          ],
        );
      },
    );
  }
}
