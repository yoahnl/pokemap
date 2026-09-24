import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_external_import_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import 'pokemon_external_preview_pane.dart';
import 'pokemon_ui_parts.dart';

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
            'Les fichiers concernés seront remplacés après contrôle '
            'de leur révision.',
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
    if (preview != null) {
      return PokemonExternalPreviewPane(
        preview: preview,
        policy: policy,
        busy: controller.externalBusy,
        onPolicyChanged: (value) => setState(() => policy = value),
        onBack: controller.operationActive
            ? null
            : controller.clearExternalPreview,
        onApply:
            controller.operationActive ||
                (preview.hasConflicts &&
                    policy == PokemonExternalConflictPolicy.failOnConflict)
            ? null
            : _apply,
      );
    }
    final suggestions =
        controller.externalSearch?.suggestions ??
        const <PokemonExternalSuggestion>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: CustomScrollView(
        key: const PageStorageKey('pokemon-external-search'),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StudioButton(
                      label: 'Retour au Pokédex',
                      icon: Icons.arrow_back,
                      secondary: true,
                      onPressed: controller.operationActive
                          ? null
                          : widget.onBack,
                    ),
                    Text(
                      'Importer une espèce externe',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PokemonSurface(
                  emphasized: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PokemonSectionHeading(
                        title: 'Rechercher une espèce',
                        description:
                            'Recherche explicite dans la source Showdown. '
                            'La préparation utilise aussi PokeAPI, sans écriture '
                            'dans votre projet avant confirmation.',
                      ),
                      LayoutBuilder(
                        builder: (context, bounds) {
                          final field = StudioDraftField(
                            key: const ValueKey('pokemon-external-query'),
                            label: 'Nom ou numéro de Pokédex',
                            value: query,
                            onChanged: (value) => setState(() => query = value),
                          );
                          final button = StudioButton(
                            label: 'Rechercher',
                            icon: Icons.search,
                            loading: controller.externalBusy,
                            onPressed:
                                controller.operationActive ||
                                    query.trim().isEmpty
                                ? null
                                : () => controller.searchExternal(query),
                          );
                          if (bounds.maxWidth < 460) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                field,
                                const SizedBox(height: 8),
                                button,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(child: field),
                              const SizedBox(width: 10),
                              button,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PokemonSectionHeading(
                  title: 'Résultats de recherche',
                  description: controller.externalSearch == null
                      ? 'Aucun accès distant avant votre recherche.'
                      : '${suggestions.length} résultat(s) pour « $query ».',
                ),
              ],
            ),
          ),
          if (controller.externalBusy && suggestions.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (suggestions.isEmpty)
            SliverToBoxAdapter(
              child: PokemonEmptyState(
                title: controller.externalSearch == null
                    ? 'Lancez une recherche'
                    : 'Aucune espèce trouvée',
                description:
                    controller.externalSearch?.message ??
                    'Votre bibliothèque locale reste disponible.',
                icon: Icons.search_off_outlined,
              ),
            )
          else
            SliverList.builder(
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: InkWell(
                      key: ValueKey('pokemon-external-${suggestion.id}'),
                      onTap:
                          controller.operationActive ||
                              controller.hasPendingChanges
                          ? null
                          : () => controller.previewExternal(suggestion.id),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.pets_outlined),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${suggestion.name} · #${suggestion.nationalDex} '
                                '· ${suggestion.id}',
                              ),
                            ),
                            if (suggestion.generation != null)
                              PokemonPill(
                                label: 'Gén. ${suggestion.generation}',
                              ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
