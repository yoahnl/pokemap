import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'pokemon_species_thumbnail.dart';
import 'pokemon_ui_parts.dart';

class PokemonSpeciesHeader extends StatelessWidget {
  const PokemonSpeciesHeader({
    super.key,
    required this.controller,
    this.onBack,
    this.showSaveControls = true,
  });

  final PokemonWorkspaceController controller;
  final VoidCallback? onBack;
  final bool showSaveControls;

  @override
  Widget build(BuildContext context) {
    final draft = controller.selectedDraft!;
    final species = draft.document(PokemonDocumentFamily.species)!;
    final names = (species['names'] as Map?)?.cast<String, dynamic>() ?? {};
    final title = '${names['fr'] ?? names['en'] ?? draft.id}';
    final entry = controller.index?.entries
        .where((candidate) => candidate.id == draft.id)
        .firstOrNull;
    final types = (species['typing'] as Map?)?['types'] as List? ?? const [];
    final active =
        (species['classification'] as Map?)?['isEnabledInProject'] == true;
    return LayoutBuilder(
      builder: (context, bounds) {
        final compact =
            bounds.maxWidth < 650 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        final image = PokemonSurface(
          emphasized: true,
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: compact ? 88 : 120,
            height: compact ? 88 : 120,
            child: entry == null
                ? const Icon(Icons.image_not_supported_outlined, size: 36)
                : PokemonSpeciesThumbnail(
                    entry: entry,
                    port: controller.port,
                    size: compact ? 88 : 120,
                  ),
          ),
        );
        final identity = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onBack != null)
              StudioButton(
                label: 'Retour au Pokédex',
                secondary: true,
                icon: Icons.arrow_back,
                onPressed: onBack,
              ),
            Text(
              '#${species['nationalDex']?.toString().padLeft(3, '0') ?? '—'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 3),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            Text(draft.id, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: [
                for (final type in types)
                  PokemonPill(label: pokemonTypeLabel('$type')),
                PokemonPill(
                  label: active ? 'Activée' : 'Désactivée',
                  icon: active ? Icons.circle : Icons.circle_outlined,
                  success: active,
                  warning: !active,
                ),
              ],
            ),
          ],
        );
        final save = showSaveControls
            ? PokemonSpeciesSaveControls(controller: controller)
            : null;
        return PokemonSurface(
          emphasized: true,
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        image,
                        const SizedBox(width: 14),
                        Expanded(child: identity),
                      ],
                    ),
                    if (save != null) ...[const SizedBox(height: 12), save],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    image,
                    const SizedBox(width: 18),
                    Expanded(child: identity),
                    const SizedBox(width: 8),
                    if (save != null) SizedBox(width: 290, child: save),
                  ],
                ),
        );
      },
    );
  }
}

class PokemonSpeciesSaveControls extends StatelessWidget {
  const PokemonSpeciesSaveControls({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final draft = controller.selectedDraft!;
    final state = controller.saving
        ? 'Enregistrement…'
        : draft.dirty
        ? 'Modifications non enregistrées'
        : controller.lastSavedSpeciesId == draft.id
        ? 'Enregistré'
        : 'Aucune modification';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Annuler',
              icon: const Icon(Icons.undo),
              onPressed: draft.canUndo ? controller.undo : null,
            ),
            IconButton(
              tooltip: 'Rétablir',
              icon: const Icon(Icons.redo),
              onPressed: draft.canRedo ? controller.redo : null,
            ),
            PokemonPill(
              label: state,
              icon: controller.saving
                  ? Icons.hourglass_top
                  : draft.dirty
                  ? Icons.edit_outlined
                  : Icons.check_circle_outline,
              warning: draft.dirty,
              success:
                  controller.lastSavedSpeciesId == draft.id && !draft.dirty,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            StudioButton(
              label: 'Annuler les modifications',
              secondary: true,
              onPressed: draft.dirty && !controller.mutationActive
                  ? controller.discardSelectedSpecies
                  : null,
            ),
            StudioButton(
              label: 'Enregistrer',
              icon: Icons.save_outlined,
              loading: controller.saving,
              onPressed: draft.dirty && !controller.mutationActive
                  ? () => controller.saveActiveOwner()
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
