import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import 'pokedex_workspace.dart';

class PokemonCatalogsWorkspace extends ConsumerWidget {
  const PokemonCatalogsWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(editorPokemonCatalogSectionProvider);

    return switch (section) {
      PokemonCatalogSection.pokedex => const Padding(
          padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: PokedexWorkspace(),
        ),
      PokemonCatalogSection.moves => const Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: _PokemonCatalogShellSection(
            title: 'Moves',
            subtitle: 'Le futur catalogue des capacités du projet vivra ici.',
            description:
                'Ce shell prépare un vrai workspace dédié au catalogue des capacités, distinct du Learnset Pokédex. Le branchement catalogue, la sync externe et l’édition ciblée arriveront dans un lot dédié.',
            readiness:
                'Structure prête pour accueillir recherche, revue et sync du catalogue des capacités.',
            liveBridge:
                'Aujourd’hui, le seul outillage moves réellement branché reste accessible dans Pokédex > Learnset.',
          ),
        ),
      PokemonCatalogSection.items => const Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: _PokemonCatalogShellSection(
            title: 'Items',
            subtitle: 'Le futur catalogue des objets du projet vivra ici.',
            description:
                'Ce shell pose une structure de workspace propre pour les items, séparée du sac battle et des écrans trainer. Le lot actuel prépare la navigation et l’intention produit sans prétendre que le contenu métier existe déjà.',
            readiness:
                'Structure de workspace prête pour un futur catalogue d’objets guidé et éditable.',
          ),
        ),
    };
  }
}

class _PokemonCatalogShellSection extends StatelessWidget {
  const _PokemonCatalogShellSection({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.readiness,
    this.liveBridge,
  });

  final String title;
  final String subtitle;
  final String description;
  final String readiness;
  final String? liveBridge;

  @override
  Widget build(BuildContext context) {
    final border = CupertinoColors.separator.resolveFrom(context);
    final panelFill = CupertinoColors.systemBackground.resolveFrom(context);
    final mutedFill = CupertinoColors.systemGrey6.resolveFrom(context);
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        decoration: BoxDecoration(
          color: panelFill,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: subtle,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: mutedFill,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    readiness,
                    style: TextStyle(
                      color: subtle,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  if (liveBridge != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: panelFill,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: border),
                      ),
                      child: Text(
                        liveBridge!,
                        style: TextStyle(
                          color: subtle,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
