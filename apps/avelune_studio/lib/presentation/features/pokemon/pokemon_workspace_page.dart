import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_trainer_species_reader.dart';
import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/application/pokemon_workspace_workflow.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import 'pokemon_moves_library.dart';
import 'pokemon_species_detail.dart';
import 'pokemon_species_library.dart';
import 'pokemon_ui_parts.dart';
import 'pokemon_workspace_tabs.dart';
import 'pokemon_commerce_page.dart';
import 'pokemon_combat_page.dart';
import 'pokemon_draft_dialog.dart';

class PokemonWorkspacePage extends StatefulWidget {
  const PokemonWorkspacePage({
    super.key,
    required this.controller,
    this.pickJson,
    this.pickPng,
    this.onOpenReference,
  });

  final PokemonWorkspaceController? controller;
  final Future<String?> Function()? pickJson;
  final Future<String?> Function()? pickPng;
  final Future<void> Function(String kind, String id, [String? detailId])?
  onOpenReference;

  @override
  State<PokemonWorkspacePage> createState() => _PokemonWorkspacePageState();
}

class _PokemonWorkspacePageState extends State<PokemonWorkspacePage> {
  bool showCompactDetail = false;
  late final _workflow = PokemonWorkspaceWorkflow(
    current: () => widget.controller,
    isActive: () => mounted,
    confirmDraft: () => showPokemonDraftDialog(context),
  );

  Future<bool> _requestViewChange(PokemonWorkspaceView next) =>
      _workflow.requestView(next);

  @override
  void dispose() {
    _workflow.dispose();
    super.dispose();
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudioPageHeader(
              title: 'Pokémon',
              description: 'Espèces, attaques, objets, boutiques et combats du projet courant.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: PokemonWorkspaceTabs(
                controller: controller,
                onViewRequested: _requestViewChange,
              ),
            ),
            if (controller.error != null)
              _message(context, controller.error!, error: true),
            if (controller.notice != null)
              _message(context, controller.notice!),
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
            else if (controller.view == PokemonWorkspaceView.items ||
                controller.view == PokemonWorkspaceView.shops)
              Expanded(
                child: controller.commerce == null
                    ? const PokemonEmptyState(
                        title: 'Catalogue indisponible',
                        description:
                            'Ce projet ne fournit pas le catalogue demandé.',
                      )
                    : PokemonCommercePage(
                        controller: controller,
                        commerce: controller.commerce!,
                        pickJson: widget.pickJson,
                        pickPng: widget.pickPng,
                        onOpenReference: widget.onOpenReference,
                        onViewRequested: _requestViewChange,
                      ),
              )
            else if (controller.view == PokemonWorkspaceView.combats)
              Expanded(
                child: controller.combat == null
                    ? const PokemonEmptyState(
                        title: 'Combats indisponibles',
                        description: 'Ce projet ne fournit pas la préparation des combats.',
                      )
                    : PokemonCombatPage(
                        loadTrainerSpecies: (id) => loadPokemonTrainerSpecies(
                          port: controller.port,
                          index: index,
                          id: id,
                        ),
                        combat: controller.combat!,
                        index: index,
                        onOpenReference: widget.onOpenReference,
                      ),
              )
            else if (controller.view == PokemonWorkspaceView.moves)
              Expanded(child: PokemonMovesLibrary(controller: controller))
            else
              Expanded(
                child:
                    compact &&
                        showCompactDetail &&
                        controller.selectedDraft != null
                    ? PokemonSpeciesDetail(
                        controller: controller,
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
