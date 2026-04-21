import 'package:flutter/cupertino.dart';

import 'pokedex_workspace.dart';

enum PokemonCatalogSection {
  pokedex,
  moves,
  items,
}

class PokemonCatalogsWorkspace extends StatefulWidget {
  const PokemonCatalogsWorkspace({
    super.key,
    this.initialSection = PokemonCatalogSection.pokedex,
  });

  final PokemonCatalogSection initialSection;

  @override
  State<PokemonCatalogsWorkspace> createState() =>
      _PokemonCatalogsWorkspaceState();
}

class _PokemonCatalogsWorkspaceState extends State<PokemonCatalogsWorkspace> {
  late PokemonCatalogSection _selectedSection;
  bool _didRestoreSection = false;

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialSection;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRestoreSection) return;
    final storedSection = PageStorage.maybeOf(
      context,
    )?.readState(context, identifier: 'pokemon_catalogs_section');
    if (storedSection is String) {
      _selectedSection = PokemonCatalogSection.values.firstWhere(
        (section) => section.name == storedSection,
        orElse: () => widget.initialSection,
      );
    }
    _didRestoreSection = true;
  }

  @override
  Widget build(BuildContext context) {
    final border = CupertinoColors.separator.resolveFrom(context);
    final panelFill = CupertinoColors.systemBackground.resolveFrom(context);
    final chromeFill = CupertinoColors.systemGrey6.resolveFrom(context);
    final accent = CupertinoColors.systemOrange.resolveFrom(context);
    final isPokedexSection = _selectedSection == PokemonCatalogSection.pokedex;
    final shellPadding = isPokedexSection
        ? const EdgeInsets.fromLTRB(4, 4, 4, 0)
        : const EdgeInsets.fromLTRB(18, 18, 18, 16);
    final headerPadding = isPokedexSection
        ? const EdgeInsets.fromLTRB(16, 14, 16, 14)
        : const EdgeInsets.fromLTRB(20, 18, 20, 18);
    final headerGap = isPokedexSection ? 10.0 : 16.0;

    return Padding(
      padding: shellPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: headerPadding,
            decoration: BoxDecoration(
              color: panelFill,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choisissez un catalogue.',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isPokedexSection
                      ? 'Le Pokédex reste le sous-espace actif aujourd’hui, avec les outils déjà branchés pour les espèces et leurs learnsets.'
                      : 'Moves et Items disposent déjà d’une vraie place produit, sans prétendre que leurs catalogues métier sont entièrement branchés dans ce lot.',
                  style: const TextStyle(
                    height: 1.45,
                  ),
                ),
                SizedBox(height: headerGap),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: chromeFill,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  // Le mode éditeur reste `pokedex` pour limiter le blast
                  // radius ; cette navigation locale pose le vrai parent
                  // produit "Catalogues Pokémon" au-dessus des sous-workspaces.
                    child: CupertinoSlidingSegmentedControl<PokemonCatalogSection>(
                    key: const Key('pokemon-catalogs-tabs'),
                    groupValue: _selectedSection,
                    onValueChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSection = value);
                        PageStorage.maybeOf(context)?.writeState(
                          context,
                          value.name,
                          identifier: 'pokemon_catalogs_section',
                        );
                      }
                    },
                    children: const <PokemonCatalogSection, Widget>{
                      PokemonCatalogSection.pokedex: Padding(
                        key: Key('pokemon-catalogs-tab-pokedex'),
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Text('Pokédex'),
                      ),
                      PokemonCatalogSection.moves: Padding(
                        key: Key('pokemon-catalogs-tab-moves'),
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Text('Moves'),
                      ),
                      PokemonCatalogSection.items: Padding(
                        key: Key('pokemon-catalogs-tab-items'),
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Text('Items'),
                      ),
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: IndexedStack(
              index: _selectedSection.index,
              children: const [
                PokedexWorkspace(),
                _PokemonCatalogShellSection(
                  title: 'Moves',
                  subtitle:
                      'Le futur catalogue des capacités du projet vivra ici.',
                  description:
                      'Ce shell prépare un vrai workspace dédié au catalogue des capacités, distinct du Learnset Pokédex. Le branchement catalogue, la sync externe et l’édition ciblée arriveront dans un lot dédié.',
                  readiness:
                      'Structure prête pour accueillir recherche, revue et sync du catalogue des capacités.',
                  liveBridge:
                      'Aujourd’hui, le seul outillage moves réellement branché reste accessible dans Pokédex > Learnset.',
                ),
                _PokemonCatalogShellSection(
                  title: 'Items',
                  subtitle: 'Le futur catalogue des objets du projet vivra ici.',
                  description:
                      'Ce shell pose une structure de workspace propre pour les items, séparée du sac battle et des écrans trainer. Le lot actuel prépare la navigation et l’intention produit sans prétendre que le contenu métier existe déjà.',
                  readiness:
                      'Structure de workspace prête pour un futur catalogue d’objets guidé et éditable.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
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
                      const Text(
                        'État actuel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
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
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
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
        ],
      ),
    );
  }
}
