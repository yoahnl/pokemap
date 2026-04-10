import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart'
    show MacosIcon, MacosPopupButton, MacosPopupMenuItem, ProgressCircle;

import '../../application/errors/application_errors.dart';
import '../../application/models/pokemon_database_index.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Vue de chargement minimale du lot 13.
///
/// On garde un état très simple et honnête :
/// - pas d'overlay complexe ;
/// - pas de skeleton list ;
/// - pas de faux comportement "riche" qui préparerait en douce les lots
///   suivants.
class PokedexWorkspaceLoadingState extends StatelessWidget {
  const PokedexWorkspaceLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DefaultTextStyle(
      style: TextStyle(
        color: subtle,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      child: const PokedexWorkspaceStateFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: ProgressCircle(),
            ),
            SizedBox(height: 14),
            Text(
              'Chargement de la liste Pokédex…',
              key: Key('pokedex-loading-label'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'erreur minimale du lot 13.
///
/// L'objectif n'est pas d'ajouter une UX de récupération riche ; on rend
/// simplement l'erreur lisible, sans masquer qu'un chargement a échoué.
class PokedexWorkspaceErrorState extends StatelessWidget {
  const PokedexWorkspaceErrorState({
    super.key,
    required this.error,
  });

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final message = switch (error) {
      final EditorApplicationException applicationError =>
        applicationError.message,
      _ => error?.toString() ?? 'Erreur inconnue',
    };

    return PokedexWorkspaceStateCard(
      key: const Key('pokedex-error-state'),
      title: 'Pokédex',
      accent: EditorChrome.inspectorJoyCoral,
      titleStyle: TextStyle(
        color: label,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      message: 'Impossible de charger la liste locale des espèces.\n$message',
      messageStyle: TextStyle(
        color: subtle,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
    );
  }
}

/// Etat dédié des lots 14/15 quand les critères locaux ne matchent aucune entrée.
///
/// Il doit rester distinct de l'état "aucune espèce importée" :
/// - ici, la base locale contient des espèces ;
/// - ce sont uniquement les critères courants (recherche et/ou filtres) qui
///   n'ont trouvé aucun match.
/// On garde donc un message sobre, non anxiogène, et différent d'une erreur.
class PokedexWorkspaceNoResultsState extends StatelessWidget {
  const PokedexWorkspaceNoResultsState({
    super.key,
    required this.query,
    this.selectedType,
    this.selectedGeneration,
  });

  final String query;
  final String? selectedType;
  final String? selectedGeneration;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim();
    final activeCriteriaLines = <String>[
      if (normalizedQuery.isNotEmpty)
        'Recherche actuelle : "$normalizedQuery".',
      if (selectedType != null) 'Type : $selectedType.',
      if (selectedGeneration != null) 'Génération : $selectedGeneration.',
    ];
    final suffix = activeCriteriaLines.isEmpty
        ? ''
        : '\n${activeCriteriaLines.join('\n')}';

    return PokedexWorkspaceStateCard(
      key: const Key('pokedex-no-results-state'),
      title: 'Pokédex',
      message: 'Aucun résultat avec les critères actuels.$suffix',
    );
  }
}

/// Vue succès du lot 13.
///
/// Elle reste volontairement limitée à la lecture :
/// - aucune action de ligne ;
/// - aucun clic ouvrant une fiche ;
/// - aucune colonne supplémentaire au-delà du lot.
class PokedexWorkspaceSpeciesList extends StatelessWidget {
  const PokedexWorkspaceSpeciesList({
    super.key,
    required this.entries,
    required this.query,
    required this.onQueryChanged,
    required this.availableTypes,
    required this.selectedType,
    required this.onTypeChanged,
    required this.availableGenerations,
    required this.selectedGeneration,
    required this.onGenerationChanged,
    this.emptyResultsChild,
  });

  final List<PokemonDatabaseIndexEntry> entries;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final List<String> availableTypes;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final List<String> availableGenerations;
  final String selectedGeneration;
  final ValueChanged<String> onGenerationChanged;
  final Widget? emptyResultsChild;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pokédex',
                style: TextStyle(
                  color: label,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Liste simple des espèces importées dans le projet. Les lots 14 et 15 ajoutent uniquement une recherche texte locale et des filtres simples par type/génération : pas de détail, pas d’édition, pas d’import.',
                style: TextStyle(
                  color: subtle,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              // Lot 14 : recherche texte simple, locale et instantanée.
              //
              // Intention volontairement stricte :
              // - aucun aller-retour disque ;
              // - aucun appel service/repository par frappe ;
              // - aucun faux panneau de filtres ;
              // - aucun outillage avancé des lots suivants.
              _PokedexSearchField(
                query: query,
                onChanged: onQueryChanged,
              ),
              const SizedBox(height: 12),
              // Lot 15 : filtres simples, purement locaux, sur la liste déjà
              // chargée en mémoire.
              //
              // On reste volontairement minimal :
              // - type ;
              // - génération ;
              // - pas de filtre activé/désactivé tant qu'aucune donnée lecture
              //   seule stable n'existe côté projet sans anticiper le lot 29.
              _PokedexSimpleFiltersBar(
                availableTypes: availableTypes,
                selectedType: selectedType,
                onTypeChanged: onTypeChanged,
                availableGenerations: availableGenerations,
                selectedGeneration: selectedGeneration,
                onGenerationChanged: onGenerationChanged,
              ),
            ],
          ),
        ),
        const _PokedexListHeader(),
        const SizedBox(height: 8),
        Expanded(
          child: emptyResultsChild ??
              ListView.separated(
                key: const Key('pokedex-species-list'),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _PokedexListRow(entry: entries[index]);
                },
              ),
        ),
      ],
    );
  }
}

class _PokedexSimpleFiltersBar extends StatelessWidget {
  const _PokedexSimpleFiltersBar({
    required this.availableTypes,
    required this.selectedType,
    required this.onTypeChanged,
    required this.availableGenerations,
    required this.selectedGeneration,
    required this.onGenerationChanged,
  });

  final List<String> availableTypes;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final List<String> availableGenerations;
  final String selectedGeneration;
  final ValueChanged<String> onGenerationChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _PokedexFilterDropdown(
          label: 'Type',
          popupKey: const Key('pokedex-type-filter'),
          value: selectedType,
          onChanged: onTypeChanged,
          items: <String>[
            _PokedexFilterDropdown.allTypesValue,
            ...availableTypes,
          ],
          itemLabelBuilder: (value) {
            if (value == _PokedexFilterDropdown.allTypesValue) {
              return 'Tous les types';
            }
            return value;
          },
        ),
        _PokedexFilterDropdown(
          label: 'Génération',
          popupKey: const Key('pokedex-generation-filter'),
          value: selectedGeneration,
          onChanged: onGenerationChanged,
          items: <String>[
            _PokedexFilterDropdown.allGenerationsValue,
            ...availableGenerations,
          ],
          itemLabelBuilder: (value) {
            if (value == _PokedexFilterDropdown.allGenerationsValue) {
              return 'Toutes les générations';
            }
            return 'Génération $value';
          },
        ),
      ],
    );
  }
}

class _PokedexSearchField extends StatefulWidget {
  const _PokedexSearchField({
    required this.query,
    required this.onChanged,
  });

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<_PokedexSearchField> createState() => _PokedexSearchFieldState();
}

class _PokedexSearchFieldState extends State<_PokedexSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _PokedexSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.28);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              color: subtle,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CupertinoTextField.borderless(
                key: const Key('pokedex-search-field'),
                controller: _controller,
                onChanged: widget.onChanged,
                clearButtonMode: OverlayVisibilityMode.editing,
                placeholder: 'Rechercher par nom, id ou numéro dex',
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokedexFilterDropdown extends StatelessWidget {
  const _PokedexFilterDropdown({
    required this.label,
    required this.popupKey,
    required this.value,
    required this.onChanged,
    required this.items,
    required this.itemLabelBuilder,
  });

  static const String allTypesValue = '__all_types__';
  static const String allGenerationsValue = '__all_generations__';

  final String label;
  final Key popupKey;
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> items;
  final String Function(String value) itemLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.28);

    return SizedBox(
      // `MacosPopupButton` réserve de la place pour le libellé et l'icône
      // interne. On donne donc une largeur volontairement confortable pour
      // éviter les overflows de layout, notamment avec les libellés français
      // "Toutes les générations" / "Tous les types".
      width: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: SizedBox(
                width: double.infinity,
                child: MacosPopupButton<String>(
                  key: popupKey,
                  value: value,
                  onChanged: (nextValue) {
                    if (nextValue != null) {
                      onChanged(nextValue);
                    }
                  },
                  items: [
                    for (final item in items)
                      MacosPopupMenuItem<String>(
                        value: item,
                        child: Text(itemLabelBuilder(item)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PokedexListHeader extends StatelessWidget {
  const _PokedexListHeader();

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              'Numéro',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              'Nom',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              'ID',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              'Types',
              style: _headerStyle(subtle),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(Color color) {
    return TextStyle(
      color: color,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.25,
    );
  }
}

class _PokedexListRow extends StatelessWidget {
  const _PokedexListRow({required this.entry});

  final PokemonDatabaseIndexEntry entry;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.35);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Text(
                '#${entry.nationalDex.toString().padLeft(4, '0')}',
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                entry.primaryName,
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                entry.id,
                style: TextStyle(
                  color: subtle,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: entry.types
                    .map((type) => _PokedexTypeChip(label: type))
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokedexTypeChip extends StatelessWidget {
  const _PokedexTypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = EditorChrome.primaryLabel(context);
    final fill = Color.lerp(
      EditorChrome.chipFill(context),
      EditorChrome.accentJade,
      0.18,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Carte de base réutilisée pour "pas de projet", "vide" et "erreur".
///
/// On mutualise uniquement la présentation visuelle commune, sans introduire un
/// système d'état générique plus large que le besoin du lot 13.
class PokedexWorkspaceStateCard extends StatelessWidget {
  const PokedexWorkspaceStateCard({
    super.key,
    required this.title,
    required this.message,
    this.accent = EditorChrome.inspectorJoyAmber,
    this.titleStyle,
    this.messageStyle,
  });

  final String title;
  final String message;
  final Color accent;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return PokedexWorkspaceStateFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(CupertinoColors.white, accent, 0.72)!,
                  Color.lerp(accent, const Color(0xFF1A1408), 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withValues(alpha: 0.82),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: const MacosIcon(
              CupertinoIcons.book_fill,
              color: CupertinoColors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: titleStyle ??
                TextStyle(
                  color: label,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: messageStyle ??
                TextStyle(
                  color: subtle,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class PokedexWorkspaceStateFrame extends StatelessWidget {
  const PokedexWorkspaceStateFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.islandFillElevated(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: EditorChrome.inspectorJoyAmber.withValues(alpha: 0.38),
              width: 1.1,
            ),
            boxShadow: EditorChrome.sectionCardShadows(context),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
            child: child,
          ),
        ),
      ),
    );
  }
}
