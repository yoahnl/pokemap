import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_external_import_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class PokemonExternalImportPanel extends StatefulWidget {
  const PokemonExternalImportPanel({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onImported,
  });

  final PokemonWorkspaceController controller;
  final VoidCallback onBack;
  final VoidCallback onImported;

  @override
  State<PokemonExternalImportPanel> createState() =>
      _PokemonExternalImportPanelState();
}

class _PokemonExternalImportPanelState
    extends State<PokemonExternalImportPanel> {
  String query = '';
  PokemonExternalConflictPolicy policy =
      PokemonExternalConflictPolicy.failOnConflict;

  Future<void> _apply() async {
    if (policy == PokemonExternalConflictPolicy.overwriteExisting &&
        widget.controller.externalPreview?.hasConflicts == true) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remplacer les documents existants ?'),
          content: const Text(
            'Les fichiers concernés seront remplacés après contrôle de leur révision.',
          ),
          actions: [
            StudioButton(
              label: 'Conserver',
              secondary: true,
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            StudioButton(
              label: 'Remplacer',
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final imported = await widget.controller.applyExternal(policy);
    if (imported && mounted) widget.onImported();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final preview = controller.externalPreview;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudioButton(
              label: 'Retour au Pokédex',
              icon: Icons.arrow_back,
              secondary: true,
              onPressed: controller.operationActive ? null : widget.onBack,
            ),
            const SizedBox(height: 12),
            StudioPanel(
              title: 'Importer une espèce externe',
              children: [
                const Text(
                  'La recherche utilise Showdown. La préparation récupère les données PokeAPI et n’écrit rien dans le projet.',
                ),
                const SizedBox(height: 12),
                StudioDraftField(
                  key: const ValueKey('pokemon-external-query'),
                  label: 'Nom ou numéro de Pokédex',
                  value: query,
                  onChanged: (value) => setState(() => query = value),
                ),
                StudioButton(
                  label: 'Rechercher',
                  loading: controller.externalBusy,
                  onPressed: controller.operationActive || query.trim().isEmpty
                      ? null
                      : () => controller.searchExternal(query),
                ),
                if (controller.externalSearch?.message != null)
                  Text(controller.externalSearch!.message!),
                for (final suggestion
                    in controller.externalSearch?.suggestions ??
                        const <PokemonExternalSuggestion>[])
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: StudioButton(
                      label:
                          '${suggestion.name} · #${suggestion.nationalDex} · ${suggestion.id}',
                      secondary: true,
                      onPressed:
                          controller.operationActive ||
                              controller.hasPendingChanges
                          ? null
                          : () => controller.previewExternal(suggestion.id),
                    ),
                  ),
              ],
            ),
            if (preview != null) ...[
              const SizedBox(height: 12),
              StudioPanel(
                title: 'Aperçu · ${preview.name}',
                children: [
                  Text('Identité exacte : ${preview.speciesId}'),
                  for (final document in preview.documents)
                    Text(
                      '${document.family.name} · ${document.relativePath} · '
                      '${document.conflict ? 'existe déjà' : 'nouveau'}',
                    ),
                  for (final warning in preview.warnings) Text(warning),
                  if (preview.hasConflicts)
                    StudioSelect(
                      label: 'Gestion des conflits',
                      value: policy.name,
                      options: const {
                        'failOnConflict': 'Refuser les conflits',
                        'skipExisting': 'Garder les fichiers existants',
                        'overwriteExisting': 'Remplacer après confirmation',
                      },
                      onChanged: (value) => setState(
                        () => policy = PokemonExternalConflictPolicy.values
                            .byName(value),
                      ),
                    ),
                  StudioButton(
                    label: 'Appliquer l’import',
                    loading: controller.externalBusy,
                    onPressed:
                        controller.operationActive ||
                            (preview.hasConflicts &&
                                policy ==
                                    PokemonExternalConflictPolicy
                                        .failOnConflict)
                        ? null
                        : _apply,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
