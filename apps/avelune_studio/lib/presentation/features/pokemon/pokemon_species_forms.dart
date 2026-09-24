import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
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
    final otherForms = List<String>.from(forms['otherForms'] as List? ?? []);
    final currentId = '${forms['formId'] ?? ''}';
    final links = StudioPanel(
      title: 'Forme courante et liens',
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
        const SizedBox(height: 16),
        PokemonSectionHeading(
          title: 'Autres formes associées',
          description: 'Ces liens ne créent pas de nouvelle espèce.',
        ),
        if (otherForms.isEmpty)
          const Text('Aucune autre forme associée.')
        else
          for (final id in otherForms)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: PokemonSurface(
                emphasized: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_tree_outlined, size: 18),
                    const SizedBox(width: 9),
                    Expanded(child: Text(_formLabel(id))),
                    PokemonPill(
                      label: _formKnown(id) ? 'Référencée' : 'Non résolue',
                      success: _formKnown(id),
                      warning: !_formKnown(id),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 12),
        StudioDraftField(
          key: const ValueKey('species-forms.otherForms'),
          label: 'Identifiants liés · séparés par une virgule',
          value: otherForms.join(', '),
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
          return Column(children: [links, const SizedBox(height: 12), editor]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: links),
            const SizedBox(width: 12),
            Expanded(child: editor),
          ],
        );
      },
    );
  }

  bool _formKnown(String id) =>
      controller.index?.entries.any((entry) => entry.formIds.contains(id)) ==
      true;

  String _formLabel(String id) {
    final matches =
        controller.index?.entries
            .where((entry) => entry.formIds.contains(id))
            .toList() ??
        const <PokemonSpeciesSummary>[];
    if (matches.length == 1) return '${matches.single.name} · $id';
    return id;
  }
}
