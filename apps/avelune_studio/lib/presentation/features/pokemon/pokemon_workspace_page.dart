import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'pokemon_species_library.dart';
import 'pokemon_species_detail.dart';
import 'pokemon_moves_library.dart';
import 'pokemon_import_preview.dart';
import 'pokemon_external_import_panel.dart';

class PokemonWorkspacePage extends StatefulWidget {
  const PokemonWorkspacePage({
    super.key,
    required this.controller,
    this.pickJson,
    this.pickPng,
  });

  final PokemonWorkspaceController? controller;
  final Future<String?> Function()? pickJson;
  final Future<String?> Function()? pickPng;

  @override
  State<PokemonWorkspacePage> createState() => _PokemonWorkspacePageState();
}

class _PokemonWorkspacePageState extends State<PokemonWorkspacePage> {
  bool showCompactDetail = false;
  bool showExternalImport = false;

  Future<void> _pickImport() async {
    final controller = widget.controller!;
    if (controller.hasPendingChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enregistrez ou annulez la fiche avant l’import.'),
        ),
      );
      return;
    }
    final path = await widget.pickJson?.call();
    if (!mounted || path == null) return;
    await controller.prepareJsonImport(path);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller == null) {
      return const Center(
        child: Text('Le Pokédex est indisponible pour ce projet.'),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 850 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        final index = controller.index;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudioPageHeader(
              title: 'Pokémon',
              description:
                  'Préparez les espèces et leurs attaques pour ce projet.',
              actions: [
                if (controller.view == PokemonWorkspaceView.pokedex &&
                    widget.pickJson != null)
                  StudioButton(
                    label: 'Importer un JSON',
                    secondary: true,
                    icon: Icons.file_upload_outlined,
                    onPressed: controller.operationActive ? null : _pickImport,
                  ),
                if (controller.view == PokemonWorkspaceView.pokedex)
                  StudioButton(
                    label: 'Importer depuis une source',
                    secondary: true,
                    icon: Icons.cloud_download_outlined,
                    onPressed: controller.operationActive
                        ? null
                        : () => setState(() => showExternalImport = true),
                  ),
                if (controller.selectedDraft?.dirty == true)
                  StudioButton(
                    label: 'Enregistrer',
                    icon: Icons.save_outlined,
                    loading: controller.saving,
                    onPressed: controller.mutationActive
                        ? null
                        : () => controller.save(),
                  ),
                if (controller.selectedDraft?.dirty == true)
                  StudioButton(
                    label: 'Annuler les modifications',
                    secondary: true,
                    onPressed: controller.mutationActive
                        ? null
                        : controller.discardSelected,
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StudioTabs<PokemonWorkspaceView>(
                items: const {
                  PokemonWorkspaceView.pokedex: 'Pokédex',
                  PokemonWorkspaceView.moves: 'Attaques',
                },
                selected: controller.view,
                onChanged: controller.setView,
              ),
            ),
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  controller.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (controller.notice != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(controller.notice!),
              ),
            if (controller.importPreview != null)
              PokemonImportPreviewPanel(controller: controller),
            if (controller.externalResult case final result?)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: StudioPanel(
                  title: 'Import terminé · ${result.speciesId}',
                  children: [
                    Text(
                      '${result.created} document(s) créé(s) · '
                      '${result.overwritten} remplacé(s) · '
                      '${result.skipped} conservé(s)',
                    ),
                    for (final warning in result.warnings) Text(warning),
                  ],
                ),
              ),
            if (controller.loading && index == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (index == null)
              Expanded(
                child: Center(
                  child: StudioButton(
                    label: 'Réessayer la lecture',
                    onPressed: () => controller.load(refresh: true),
                  ),
                ),
              )
            else if (!index.enabled)
              const Expanded(
                child: Center(
                  child: Text(
                    'La configuration Pokémon est désactivée pour ce projet.',
                  ),
                ),
              )
            else if (showExternalImport &&
                controller.view == PokemonWorkspaceView.pokedex)
              Expanded(
                child: PokemonExternalImportPanel(
                  controller: controller,
                  onBack: () => setState(() => showExternalImport = false),
                  onImported: () => setState(() => showExternalImport = false),
                ),
              )
            else
              Expanded(
                child: controller.view == PokemonWorkspaceView.moves
                    ? PokemonMovesLibrary(controller: controller)
                    : compact &&
                          showCompactDetail &&
                          controller.selectedDraft != null
                    ? PokemonSpeciesDetail(
                        controller: controller,
                        pickPng: widget.pickPng,
                        onBack: () => setState(() => showCompactDetail = false),
                      )
                    : Row(
                        children: [
                          SizedBox(
                            width: compact
                                ? constraints.maxWidth
                                : (constraints.maxWidth * .36).clamp(290, 420),
                            child: PokemonSpeciesLibrary(
                              controller: controller,
                              onSelected: () {
                                if (compact) {
                                  setState(() => showCompactDetail = true);
                                }
                              },
                            ),
                          ),
                          if (!compact) ...[
                            const VerticalDivider(width: 1),
                            Expanded(
                              child: PokemonSpeciesDetail(
                                controller: controller,
                                pickPng: widget.pickPng,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
          ],
        );
      },
    );
  }
}
