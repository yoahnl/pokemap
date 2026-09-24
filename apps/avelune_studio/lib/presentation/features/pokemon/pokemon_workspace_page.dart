import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import 'pokemon_external_import_panel.dart';
import 'pokemon_import_preview.dart';
import 'pokemon_moves_library.dart';
import 'pokemon_species_detail.dart';
import 'pokemon_species_library.dart';
import 'pokemon_ui_parts.dart';
import 'pokemon_workspace_tabs.dart';

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
      return const PokemonEmptyState(
        title: 'Pokédex indisponible',
        description: 'Ouvrez un projet pour consulter ses espèces.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 930 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        final index = controller.index;
        final showPokedexActions =
            controller.view == PokemonWorkspaceView.pokedex &&
            controller.importPreview == null &&
            !showExternalImport;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudioPageHeader(
              title: 'Pokémon',
              description: 'Espèces et attaques du projet courant.',
              actions: [
                if (showPokedexActions && widget.pickJson != null)
                  StudioButton(
                    label: 'Importer un JSON',
                    secondary: true,
                    icon: Icons.file_upload_outlined,
                    onPressed: controller.operationActive ? null : _pickImport,
                  ),
                if (showPokedexActions)
                  StudioButton(
                    label: 'Importer depuis une source',
                    secondary: true,
                    icon: Icons.cloud_download_outlined,
                    onPressed: controller.operationActive
                        ? null
                        : () => setState(() => showExternalImport = true),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: PokemonWorkspaceTabs(controller: controller),
            ),
            if (controller.error != null)
              _message(context, controller.error!, error: true),
            if (controller.notice != null)
              _message(context, controller.notice!),
            if (controller.externalResult case final result?)
              _message(
                context,
                '${result.noChange ? 'Aucun document importé' : 'Import ${result.speciesId}'} : '
                '${result.created} créé(s), '
                '${result.overwritten} remplacé(s), '
                '${result.skipped} conservé(s), '
                '${result.excluded} exclu(s) sans rattachement. '
                '${result.warnings.join(' ')}',
              ),
            if (controller.loading && index == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (index == null)
              Expanded(
                child: PokemonEmptyState(
                  title: 'Lecture impossible',
                  description: 'Le Pokédex du projet n’a pas pu être chargé.',
                  icon: Icons.error_outline,
                  action: StudioButton(
                    label: 'Réessayer la lecture',
                    onPressed: () => controller.load(refresh: true),
                  ),
                ),
              )
            else if (!index.enabled)
              const Expanded(
                child: PokemonEmptyState(
                  title: 'Pokémon désactivé',
                  description:
                      'La configuration Pokémon est désactivée dans ce projet.',
                  icon: Icons.block_outlined,
                ),
              )
            else if (controller.view == PokemonWorkspaceView.moves)
              Expanded(child: PokemonMovesLibrary(controller: controller))
            else if (controller.importPreview != null)
              Expanded(child: PokemonImportPreviewPanel(controller: controller))
            else if (showExternalImport)
              Expanded(
                child: PokemonExternalImportPanel(
                  controller: controller,
                  onBack: () => setState(() => showExternalImport = false),
                  onImported: () => setState(() => showExternalImport = false),
                ),
              )
            else
              Expanded(
                child:
                    compact &&
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
                                : (constraints.maxWidth * .28).clamp(300, 360),
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

  Widget _message(BuildContext context, String value, {bool error = false}) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: PokemonSurface(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.info_outline,
              size: 17,
              color: error ? colors.error : colors.tertiary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(value)),
          ],
        ),
      ),
    );
  }
}
