import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class PokemonMovesLibrary extends StatefulWidget {
  const PokemonMovesLibrary({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  State<PokemonMovesLibrary> createState() => _PokemonMovesLibraryState();
}

class _PokemonMovesLibraryState extends State<PokemonMovesLibrary> {
  late final search = TextEditingController(text: widget.controller.moveSearch);
  bool showCompactDetail = false;
  bool showCompactSync = false;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final catalog = controller.index!.moves;
    final entries = controller.visibleMoves;
    final move = catalog.entries
        .where((item) => item.id == controller.selectedMoveId)
        .firstOrNull;
    return LayoutBuilder(
      builder: (context, bounds) {
        final compact =
            bounds.maxWidth < 850 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        if (compact && showCompactDetail && move != null) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    StudioButton(
                      label: 'Retour aux attaques',
                      secondary: true,
                      icon: Icons.arrow_back,
                      onPressed: () =>
                          setState(() => showCompactDetail = false),
                    ),
                    if (controller.moveInsertGroup != null)
                      StudioButton(
                        label: 'Choisir cette attaque',
                        onPressed: () => controller.chooseMove(move.id),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: PokemonMoveDetail(move: move),
                  ),
                ),
              ],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: compact
                  ? bounds.maxWidth
                  : (bounds.maxWidth * .4).clamp(300, 440),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attaques · ${catalog.entries.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (compact && !showCompactSync)
                      StudioButton(
                        label: 'Synchroniser le catalogue',
                        secondary: true,
                        onPressed: () => setState(() => showCompactSync = true),
                      )
                    else
                      StudioPanel(
                        title: 'Synchroniser le catalogue',
                        children: [
                          if (compact)
                            StudioButton(
                              label: 'Replier la synchronisation',
                              secondary: true,
                              onPressed: () =>
                                  setState(() => showCompactSync = false),
                            ),
                          const Text(
                            'Télécharge le catalogue Showdown seulement après votre action. '
                            'L’aperçu ne modifie pas le projet.',
                          ),
                          const SizedBox(height: 8),
                          if (controller.hasPendingChanges)
                            const Text(
                              'Enregistrez ou annulez la fiche ouverte avant la synchronisation.',
                            ),
                          if (controller.movesPreview != null) ...[
                            Text(
                              '${controller.movesPreview!.createdIds.length} créations · '
                              '${controller.movesPreview!.updatedIds.length} mises à jour · '
                              '${controller.movesPreview!.unchangedIds.length} inchangées · '
                              '${controller.movesPreview!.preservedLocalOnlyIds.length} locales conservées',
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                StudioButton(
                                  label: 'Appliquer la synchronisation',
                                  onPressed: controller.syncing
                                      ? null
                                      : controller.applyMovesSync,
                                ),
                                StudioButton(
                                  label: 'Annuler l’aperçu',
                                  secondary: true,
                                  onPressed: controller.clearMovesPreview,
                                ),
                              ],
                            ),
                          ] else
                            StudioButton(
                              label: 'Prévisualiser la synchronisation',
                              secondary: true,
                              loading: controller.syncing,
                              onPressed:
                                  controller.operationActive ||
                                      controller.hasPendingChanges
                                  ? null
                                  : controller.previewMovesSync,
                            ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    StudioSearchField(
                      controller: search,
                      onChanged: controller.setMoveSearch,
                      label: 'Rechercher une attaque',
                    ),
                    if (catalog.problem != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          catalog.problem!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    for (final diagnostic in catalog.diagnostics)
                      Text(
                        diagnostic,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: entries.isEmpty
                          ? Center(
                              child: Text(
                                catalog.problem == null
                                    ? 'Aucune attaque trouvée.'
                                    : 'Le catalogue local doit être préparé.',
                              ),
                            )
                          : ListView.builder(
                              key: const PageStorageKey('pokemon-moves-list'),
                              itemCount: entries.length,
                              itemBuilder: (context, index) {
                                final entry = entries[index];
                                return Card(
                                  child: ListTile(
                                    key: ValueKey('move-${entry.id}'),
                                    selected:
                                        entry.id == controller.selectedMoveId,
                                    title: Text(entry.name),
                                    subtitle: Text(
                                      '${entry.id} · ${entry.type ?? 'Type inconnu'}',
                                    ),
                                    onTap: () {
                                      controller.selectMove(entry.id);
                                      if (compact) {
                                        setState(
                                          () => showCompactDetail = true,
                                        );
                                      }
                                    },
                                    trailing: controller.moveInsertGroup != null
                                        ? IconButton(
                                            tooltip: 'Choisir cette attaque',
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                            onPressed: () =>
                                                controller.chooseMove(entry.id),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (!compact) ...[
              const VerticalDivider(width: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: move == null
                      ? const Center(child: Text('Sélectionnez une attaque.'))
                      : SingleChildScrollView(
                          child: PokemonMoveDetail(move: move),
                        ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class PokemonMoveDetail extends StatelessWidget {
  const PokemonMoveDetail({super.key, required this.move});

  final PokemonMoveSummary move;

  @override
  Widget build(BuildContext context) => StudioPanel(
    title: move.name,
    children: [
      Text('Identifiant : ${move.id}'),
      Text('Type : ${move.type ?? 'Non renseigné'}'),
      Text('Catégorie : ${move.category ?? 'Non renseignée'}'),
      Text('Puissance : ${move.power?.toString() ?? 'Non renseignée'}'),
      Text('Précision : ${move.accuracy ?? 'Non renseignée'}'),
      Text('PP : ${move.pp?.toString() ?? 'Non renseignés'}'),
      Text('Priorité : ${move.priority?.toString() ?? 'Non renseignée'}'),
      Text('Cible : ${_targetLabel(move.target)}'),
      if (move.description?.isNotEmpty == true) ...[
        const SizedBox(height: 12),
        Text(move.description!),
      ],
    ],
  );
}

String _targetLabel(String? value) => switch (value?.split('.').last) {
  null => 'Non renseignée',
  'adjacentAlly' => 'Allié adjacent',
  'adjacentAllyOrSelf' => 'Allié adjacent ou utilisateur',
  'adjacentFoe' => 'Adversaire adjacent',
  'all' => 'Tous',
  'allAdjacent' => 'Tous les voisins',
  'allAdjacentFoes' => 'Tous les adversaires voisins',
  'allies' => 'Alliés',
  'allySide' => 'Côté allié',
  'allyTeam' => 'Équipe alliée',
  'any' => 'Une cible au choix',
  'foeSide' => 'Côté adverse',
  'normal' => 'Une cible',
  'randomNormal' => 'Une cible aléatoire',
  'scripted' => 'Définie par le scénario',
  'self' => 'Utilisateur',
  final String other => other,
};
