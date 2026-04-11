import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart'
    show MacosIcon, MacosPopupButton, MacosPopupMenuItem, ProgressCircle;

import '../../application/errors/application_errors.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokedex_species_detail.dart';
import '../../application/models/pokemon_project_data_models.dart';
import '../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
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
    this.selectedStatus,
  });

  final String query;
  final String? selectedType;
  final String? selectedGeneration;
  final String? selectedStatus;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim();
    final normalizedStatus = switch (selectedStatus) {
      _PokedexFilterDropdown.enabledOnlyValue => 'Activées',
      _PokedexFilterDropdown.disabledOnlyValue => 'Désactivées',
      _ => selectedStatus,
    };
    final activeCriteriaLines = <String>[
      if (normalizedQuery.isNotEmpty)
        'Recherche actuelle : "$normalizedQuery".',
      if (selectedType != null) 'Type : $selectedType.',
      if (selectedGeneration != null) 'Génération : $selectedGeneration.',
      if (normalizedStatus != null) 'Statut : $normalizedStatus.',
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
/// Elle reste volontairement en lecture seule, mais la phase 5 ajoute une
/// vraie sélection locale de ligne pour ouvrir la fiche détail.
class PokedexWorkspaceSpeciesList extends StatelessWidget {
  const PokedexWorkspaceSpeciesList({
    super.key,
    required this.entries,
    required this.selectedSpeciesId,
    required this.onEntrySelected,
    required this.query,
    required this.onQueryChanged,
    required this.availableTypes,
    required this.selectedType,
    required this.onTypeChanged,
    required this.availableGenerations,
    required this.selectedGeneration,
    required this.onGenerationChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    this.emptyResultsChild,
  });

  final List<PokemonDatabaseIndexEntry> entries;
  final String? selectedSpeciesId;
  final ValueChanged<PokemonDatabaseIndexEntry> onEntrySelected;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final List<String> availableTypes;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final List<String> availableGenerations;
  final String selectedGeneration;
  final ValueChanged<String> onGenerationChanged;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
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
                'Liste locale des espèces importées dans le projet. La phase 8A ajoute un statut activée/désactivée et une édition locale de métadonnées simples, sans toucher learnset, évolutions ou médias.',
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
              // - statut activée/désactivée, désormais alimenté par la vraie
              //   donnée persistée `classification.isEnabledInProject`.
              _PokedexSimpleFiltersBar(
                availableTypes: availableTypes,
                selectedType: selectedType,
                onTypeChanged: onTypeChanged,
                availableGenerations: availableGenerations,
                selectedGeneration: selectedGeneration,
                onGenerationChanged: onGenerationChanged,
                selectedStatus: selectedStatus,
                onStatusChanged: onStatusChanged,
              ),
            ],
          ),
        ),
        const _PokedexListHeader(),
        const SizedBox(height: 8),
        Expanded(
          child: emptyResultsChild != null
              ? SingleChildScrollView(child: emptyResultsChild)
              : ListView.separated(
                  key: const Key('pokedex-species-list'),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _PokedexListRow(
                      entry: entry,
                      isSelected: selectedSpeciesId == entry.id,
                      onPressed: () => onEntrySelected(entry),
                    );
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
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final List<String> availableTypes;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final List<String> availableGenerations;
  final String selectedGeneration;
  final ValueChanged<String> onGenerationChanged;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

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
              return 'Tous types';
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
              return 'Toutes gén.';
            }
            return 'Génération $value';
          },
        ),
        _PokedexFilterDropdown(
          label: 'Statut',
          popupKey: const Key('pokedex-status-filter'),
          value: selectedStatus,
          onChanged: onStatusChanged,
          items: const <String>[
            _PokedexFilterDropdown.allStatusesValue,
            _PokedexFilterDropdown.enabledOnlyValue,
            _PokedexFilterDropdown.disabledOnlyValue,
          ],
          itemLabelBuilder: (value) {
            switch (value) {
              case _PokedexFilterDropdown.allStatusesValue:
                return 'Toutes';
              case _PokedexFilterDropdown.enabledOnlyValue:
                return 'Activées';
              case _PokedexFilterDropdown.disabledOnlyValue:
                return 'Désactivées';
            }
            return value;
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
  static const String allStatusesValue = '__all_statuses__';
  static const String enabledOnlyValue = '__enabled_only__';
  static const String disabledOnlyValue = '__disabled_only__';

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
      width: 240,
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
  const _PokedexListRow({
    required this.entry,
    required this.isSelected,
    required this.onPressed,
  });

  final PokemonDatabaseIndexEntry entry;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final surface = isSelected
        ? Color.lerp(
            EditorChrome.islandFillElevated(context),
            EditorChrome.accentJade,
            0.12,
          )!
        : EditorChrome.islandFillElevated(context);
    final border = isSelected
        ? EditorChrome.accentJade.withValues(alpha: 0.65)
        : EditorChrome.accentWarm.withValues(alpha: 0.35);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return CupertinoButton(
      key: Key('pokedex-row-${entry.id}'),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: isSelected ? 1.4 : 1),
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

class PokedexWorkspaceDetailPane extends StatelessWidget {
  const PokedexWorkspaceDetailPane({
    super.key,
    required this.selectedEntry,
    required this.selectedTabId,
    required this.onTabChanged,
    required this.detailFuture,
    required this.onSaveMetadata,
  });

  final PokemonDatabaseIndexEntry? selectedEntry;
  final String selectedTabId;
  final ValueChanged<String> onTabChanged;
  final Future<PokedexSpeciesDetail>? detailFuture;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;

  @override
  Widget build(BuildContext context) {
    final entry = selectedEntry;
    if (entry == null || detailFuture == null) {
      return const PokedexWorkspaceStateCard(
        key: Key('pokedex-detail-empty-state'),
        title: 'Fiche espèce',
        message:
            'Sélectionnez une espèce dans la liste pour afficher son overview, ses formes, son learnset, ses évolutions et ses médias.',
      );
    }

    return FutureBuilder<PokedexSpeciesDetail>(
      future: detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PokedexWorkspaceStateCard(
            key: Key('pokedex-detail-loading-state'),
            title: 'Fiche espèce',
            message: 'Chargement de la fiche Pokédex locale…',
          );
        }

        if (snapshot.hasError) {
          final message = switch (snapshot.error) {
            final EditorApplicationException applicationError =>
              applicationError.message,
            _ => snapshot.error?.toString() ?? 'Erreur inconnue',
          };
          return PokedexWorkspaceStateCard(
            key: const Key('pokedex-detail-error-state'),
            title: 'Fiche espèce',
            accent: EditorChrome.inspectorJoyCoral,
            message: 'Impossible de charger la fiche de ${entry.id}.\n$message',
          );
        }

        final detail = snapshot.data;
        if (detail == null) {
          return const PokedexWorkspaceStateCard(
            title: 'Fiche espèce',
            message: 'Aucune donnée Pokédex détaillée disponible.',
          );
        }

        return _PokedexSpeciesDetailView(
          entry: entry,
          detail: detail,
          selectedTabId: selectedTabId,
          onTabChanged: onTabChanged,
          onSaveMetadata: onSaveMetadata,
        );
      },
    );
  }
}

class _PokedexSpeciesDetailView extends StatelessWidget {
  const _PokedexSpeciesDetailView({
    required this.entry,
    required this.detail,
    required this.selectedTabId,
    required this.onTabChanged,
    required this.onSaveMetadata,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final String selectedTabId;
  final ValueChanged<String> onTabChanged;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.35);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      key: const Key('pokedex-detail-pane'),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              entry.primaryName,
              style: TextStyle(
                color: label,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '#${entry.nationalDex.toString().padLeft(4, '0')} • ${entry.id}',
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.types
                  .map((type) => _PokedexTypeChip(label: type))
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            CupertinoSlidingSegmentedControl<String>(
              key: const Key('pokedex-detail-tabs'),
              groupValue: selectedTabId,
              onValueChanged: (value) {
                if (value != null) {
                  onTabChanged(value);
                }
              },
              children: const <String, Widget>{
                'overview': Padding(
                  key: Key('pokedex-tab-overview'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Overview'),
                ),
                'forms': Padding(
                  key: Key('pokedex-tab-forms'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Formes'),
                ),
                'learnset': Padding(
                  key: Key('pokedex-tab-learnset'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Learnset'),
                ),
                'evolutions': Padding(
                  key: Key('pokedex-tab-evolutions'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Évolutions'),
                ),
                'media': Padding(
                  key: Key('pokedex-tab-media'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Médias'),
                ),
              },
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _PokedexDetailTabBody(
                entry: entry,
                detail: detail,
                selectedTabId: selectedTabId,
                onSaveMetadata: onSaveMetadata,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokedexDetailTabBody extends StatelessWidget {
  const _PokedexDetailTabBody({
    required this.entry,
    required this.detail,
    required this.selectedTabId,
    required this.onSaveMetadata,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final String selectedTabId;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;

  @override
  Widget build(BuildContext context) {
    return switch (selectedTabId) {
      'forms' => _PokedexFormsTab(detail: detail),
      'learnset' => _PokedexLearnsetTab(detail: detail),
      'evolutions' => _PokedexEvolutionTab(detail: detail),
      'media' => _PokedexMediaTab(detail: detail),
      _ => _PokedexOverviewTab(
          entry: entry,
          detail: detail,
          onSaveMetadata: onSaveMetadata,
        ),
    };
  }
}

class _PokedexOverviewTab extends StatelessWidget {
  const _PokedexOverviewTab({
    required this.entry,
    required this.detail,
    required this.onSaveMetadata,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;

  @override
  Widget build(BuildContext context) {
    final species = detail.species;

    return SingleChildScrollView(
      key: const Key('pokedex-overview-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Identité',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Nom principal',
                  value: entry.primaryName,
                ),
                _PokedexPropertyLine(label: 'ID', value: species.id),
                _PokedexPropertyLine(
                  label: 'Numéro national',
                  value: species.nationalDex.toString(),
                ),
                _PokedexPropertyLine(
                  label: 'Nom espèce',
                  value: _localizedValue(species.speciesName),
                ),
                _PokedexPropertyLine(
                  label: 'Génération',
                  value: species.genIntroduced.toString(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexEditableMetadataSection(
            species: species,
            onSave: onSaveMetadata,
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Stats',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(label: 'HP', value: species.baseStats.hp),
                _StatChip(label: 'ATK', value: species.baseStats.atk),
                _StatChip(label: 'DEF', value: species.baseStats.def),
                _StatChip(label: 'SPA', value: species.baseStats.spa),
                _StatChip(label: 'SPD', value: species.baseStats.spd),
                _StatChip(label: 'SPE', value: species.baseStats.spe),
                _StatChip(label: 'BST', value: species.baseStats.bst),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Talents',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Talent principal',
                  value: species.abilities.primary,
                ),
                _PokedexPropertyLine(
                  label: 'Talent secondaire',
                  value: species.abilities.secondary ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'Talent caché',
                  value: species.abilities.hidden ?? 'Aucun',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Références locales',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Learnset',
                  value: species.refs.learnset,
                ),
                _PokedexPropertyLine(
                  label: 'Évolution',
                  value: species.refs.evolution,
                ),
                _PokedexPropertyLine(
                  label: 'Média',
                  value: species.refs.media,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PokedexEditableMetadataSection extends StatefulWidget {
  const _PokedexEditableMetadataSection({
    required this.species,
    required this.onSave,
  });

  final PokemonSpeciesFile species;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSave;

  @override
  State<_PokedexEditableMetadataSection> createState() =>
      _PokedexEditableMetadataSectionState();
}

class _PokedexEditableMetadataSectionState
    extends State<_PokedexEditableMetadataSection> {
  final Map<String, TextEditingController> _nameControllers =
      <String, TextEditingController>{};
  late TextEditingController _flavorTextController;
  late List<String> _orderedLocales;
  late bool _isEnabledInProject;
  late bool _starterEligible;
  late bool _giftOnly;
  late bool _tradeOnly;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _flavorTextController = TextEditingController();
    _replaceDraftFromSpecies(widget.species);
  }

  @override
  void didUpdateWidget(covariant _PokedexEditableMetadataSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.species != widget.species) {
      // Dès qu'une nouvelle espèce est relue depuis le workspace, on considère
      // qu'elle devient la nouvelle vérité locale :
      // - après sélection d'une autre ligne ;
      // - après sauvegarde réussie et rechargement ;
      // - après changement de filtres qui force une nouvelle fiche.
      //
      // On jette donc proprement tout draft local restant.
      _replaceDraftFromSpecies(widget.species);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    _flavorTextController.dispose();
    super.dispose();
  }

  void _replaceDraftFromSpecies(PokemonSpeciesFile species) {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    _nameControllers.clear();

    _orderedLocales = _orderedLocaleKeys(species.names);
    for (final locale in _orderedLocales) {
      _nameControllers[locale] = TextEditingController(
        text: species.names[locale] ?? '',
      );
    }

    _flavorTextController.value = TextEditingValue(
      text: species.dexContent.flavorText ?? '',
      selection: TextSelection.collapsed(
        offset: (species.dexContent.flavorText ?? '').length,
      ),
    );
    _isEnabledInProject = species.classification.isEnabledInProject;
    _starterEligible = species.gameplayFlags.starterEligible;
    _giftOnly = species.gameplayFlags.giftOnly;
    _tradeOnly = species.gameplayFlags.tradeOnly;
  }

  Future<void> _saveDraft() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      await widget.onSave(
        UpdatePokedexSpeciesMetadataRequest(
          speciesId: widget.species.id,
          isEnabledInProject: _isEnabledInProject,
          names: <String, String>{
            for (final locale in _orderedLocales)
              locale: _nameControllers[locale]?.text ?? '',
          },
          flavorText: _flavorTextController.text,
          starterEligible: _starterEligible,
          giftOnly: _giftOnly,
          tradeOnly: _tradeOnly,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _saveErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = switch (error) {
        final EditorApplicationException applicationError =>
          applicationError.message,
        _ => error.toString(),
      };

      setState(() {
        _isSaving = false;
        _saveErrorMessage = message;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _replaceDraftFromSpecies(widget.species);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final species = widget.species;

    return _PokedexDetailSectionCard(
      title: 'Métadonnées locales',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing) ...[
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-enabled-switch-row'),
              label: 'Activée dans le projet',
              description:
                  'Le filtre liste et le statut local utilisent ce booléen persistant.',
              value: _isEnabledInProject,
              switchKey: const Key('pokedex-enabled-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _isEnabledInProject = value),
            ),
            const SizedBox(height: 12),
            for (final locale in _orderedLocales) ...[
              _PokedexEditorTextField(
                label: 'Nom (${locale.toUpperCase()})',
                fieldKey: Key('pokedex-name-field-$locale'),
                controller: _nameControllers[locale]!,
                enabled: !_isSaving,
              ),
              const SizedBox(height: 10),
            ],
            _PokedexEditorTextField(
              label: 'Texte Pokédex',
              fieldKey: const Key('pokedex-flavor-text-field'),
              controller: _flavorTextController,
              enabled: !_isSaving,
              minLines: 3,
              maxLines: 6,
              placeholder: 'Texte local affiché dans la fiche Pokédex',
            ),
            const SizedBox(height: 12),
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-starter-eligible-switch-row'),
              label: 'Starter éligible',
              value: _starterEligible,
              switchKey: const Key('pokedex-starter-eligible-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _starterEligible = value),
            ),
            const SizedBox(height: 10),
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-gift-only-switch-row'),
              label: 'Obtenu par cadeau',
              value: _giftOnly,
              switchKey: const Key('pokedex-gift-only-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _giftOnly = value),
            ),
            const SizedBox(height: 10),
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-trade-only-switch-row'),
              label: 'Échange uniquement',
              value: _tradeOnly,
              switchKey: const Key('pokedex-trade-only-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _tradeOnly = value),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CupertinoButton.filled(
                  key: const Key('pokedex-save-metadata-button'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  onPressed: _isSaving ? null : _saveDraft,
                  child: Text(_isSaving ? 'Enregistrement…' : 'Enregistrer'),
                ),
                const SizedBox(width: 10),
                CupertinoButton(
                  key: const Key('pokedex-cancel-metadata-button'),
                  onPressed: _isSaving ? null : _cancelEditing,
                  child: const Text('Annuler'),
                ),
              ],
            ),
            if (_saveErrorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _saveErrorMessage!,
                key: const Key('pokedex-metadata-save-error'),
                style: const TextStyle(
                  color: EditorChrome.inspectorJoyCoral,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ] else ...[
            _PokedexPropertyLine(
              label: 'Statut projet',
              value: species.classification.isEnabledInProject
                  ? 'Activée'
                  : 'Désactivée',
            ),
            for (final locale in _orderedLocaleKeys(species.names))
              _PokedexPropertyLine(
                label: 'Nom (${locale.toUpperCase()})',
                value: (species.names[locale]?.trim().isNotEmpty ?? false)
                    ? species.names[locale]!.trim()
                    : 'Valeur vide',
              ),
            _PokedexPropertyLine(
              label: 'Texte Pokédex',
              value: species.dexContent.flavorText?.trim().isNotEmpty == true
                  ? species.dexContent.flavorText!.trim()
                  : 'Aucun texte local',
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FlagChip(
                  label: species.gameplayFlags.starterEligible
                      ? 'Starter éligible'
                      : 'Starter non éligible',
                ),
                _FlagChip(
                  label: species.gameplayFlags.giftOnly
                      ? 'Obtenu par cadeau'
                      : 'Pas cadeau uniquement',
                ),
                _FlagChip(
                  label: species.gameplayFlags.tradeOnly
                      ? 'Échange uniquement'
                      : 'Pas échange uniquement',
                ),
              ],
            ),
            const SizedBox(height: 14),
            CupertinoButton(
              key: const Key('pokedex-edit-metadata-button'),
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _replaceDraftFromSpecies(widget.species);
                  _isEditing = true;
                  _saveErrorMessage = null;
                });
              },
              child: const Text('Modifier'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PokedexBooleanEditorRow extends StatelessWidget {
  const _PokedexBooleanEditorRow({
    super.key,
    required this.label,
    required this.value,
    required this.switchKey,
    required this.onChanged,
    this.description,
  });

  final String label;
  final bool value;
  final Key switchKey;
  final ValueChanged<bool>? onChanged;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        CupertinoSwitch(
          key: switchKey,
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PokedexEditorTextField extends StatelessWidget {
  const _PokedexEditorTextField({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.enabled,
    this.minLines = 1,
    this.maxLines = 1,
    this.placeholder,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final int minLines;
  final int maxLines;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.28);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1),
          ),
          child: CupertinoTextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            minLines: minLines,
            maxLines: maxLines,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            placeholder: placeholder,
            placeholderStyle: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PokedexFormsTab extends StatelessWidget {
  const _PokedexFormsTab({required this.detail});

  final PokedexSpeciesDetail detail;

  @override
  Widget build(BuildContext context) {
    final species = detail.species;
    final forms = species.forms;
    final classification = species.classification;
    final currentFormId = forms.formId.isEmpty ? 'base' : forms.formId;
    final baseFormId = forms.baseFormId.isEmpty ? species.id : forms.baseFormId;

    return SingleChildScrollView(
      key: const Key('pokedex-forms-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Formes',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Forme courante',
                  value: forms.formName == null || forms.formName!.isEmpty
                      ? currentFormId
                      : '${forms.formName} ($currentFormId)',
                ),
                _PokedexPropertyLine(
                  label: 'Forme de base',
                  value: baseFormId,
                ),
                _PokedexPropertyLine(
                  label: 'Est la forme de base',
                  value: forms.isBaseForm ? 'Oui' : 'Non',
                ),
                _PokedexPropertyLine(
                  label: 'Autres formes',
                  value: forms.otherForms.isEmpty
                      ? 'Aucune autre forme locale'
                      : forms.otherForms.join(', '),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Classification',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FlagChip(
                  label: classification.isEnabledInProject
                      ? 'Activée dans le projet'
                      : 'Désactivée dans le projet',
                ),
                _FlagChip(
                  label: classification.isObtainable
                      ? 'Obtenable'
                      : 'Non obtenable',
                ),
                if (classification.isLegendary)
                  const _FlagChip(label: 'Légendaire'),
                if (classification.isMythical)
                  const _FlagChip(label: 'Mythique'),
                if (classification.isBaby) const _FlagChip(label: 'Bébé'),
                if (!classification.isLegendary &&
                    !classification.isMythical &&
                    !classification.isBaby)
                  const _FlagChip(label: 'Aucun flag rare'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Flags gameplay simples',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (species.gameplayFlags.starterEligible)
                  const _FlagChip(label: 'Starter éligible'),
                if (species.gameplayFlags.giftOnly)
                  const _FlagChip(label: 'Obtenu par cadeau'),
                if (species.gameplayFlags.tradeOnly)
                  const _FlagChip(label: 'Échange uniquement'),
                if (!species.gameplayFlags.starterEligible &&
                    !species.gameplayFlags.giftOnly &&
                    !species.gameplayFlags.tradeOnly)
                  const _FlagChip(label: 'Aucun flag gameplay'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PokedexLearnsetTab extends StatelessWidget {
  const _PokedexLearnsetTab({required this.detail});

  final PokedexSpeciesDetail detail;

  @override
  Widget build(BuildContext context) {
    final learnset = detail.learnset;
    if (learnset == null) {
      return const _PokedexMissingSection(
        key: Key('pokedex-learnset-missing'),
        title: 'Learnset',
        message: 'Aucun learnset local trouvé pour cette espèce.',
      );
    }

    return SingleChildScrollView(
      key: const Key('pokedex-learnset-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Moves de départ',
            child: Text(
              learnset.startingMoves.isEmpty
                  ? 'Aucun move de départ déclaré.'
                  : learnset.startingMoves.join(', '),
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Moves à réapprendre',
            child: Text(
              learnset.relearnMoves.isEmpty
                  ? 'Aucun move à réapprendre déclaré.'
                  : learnset.relearnMoves.join(', '),
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Level-up',
            child: learnset.levelUp.isEmpty
                ? const Text('Aucune entrée level-up.')
                : Column(
                    children: learnset.levelUp
                        .map(
                          (entry) => _PokedexPropertyLine(
                            label: '${entry.moveId} • niveau ${entry.level}',
                            value:
                                '${entry.versionGroup} • source ${entry.source}',
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'TM', entries: learnset.tm),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Tutor', entries: learnset.tutor),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Egg', entries: learnset.egg),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Event', entries: learnset.event),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Transfer', entries: learnset.transfer),
        ],
      ),
    );
  }
}

class _PokedexEvolutionTab extends StatelessWidget {
  const _PokedexEvolutionTab({required this.detail});

  final PokedexSpeciesDetail detail;

  @override
  Widget build(BuildContext context) {
    final evolution = detail.evolution;
    if (evolution == null) {
      return const _PokedexMissingSection(
        key: Key('pokedex-evolutions-missing'),
        title: 'Évolutions',
        message: 'Aucune donnée d’évolution locale trouvée pour cette espèce.',
      );
    }

    return SingleChildScrollView(
      key: const Key('pokedex-evolutions-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Pré-évolution',
            child: Text(evolution.preEvolution?.trim().isNotEmpty == true
                ? evolution.preEvolution!
                : 'Aucune'),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Évolutions suivantes',
            child: evolution.evolutions.isEmpty
                ? const Text('Aucune évolution déclarée.')
                : Column(
                    children: evolution.evolutions
                        .map(
                          (entry) => _PokedexPropertyLine(
                            label: entry.targetSpeciesId,
                            value: _describeEvolution(entry),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PokedexMediaTab extends StatelessWidget {
  const _PokedexMediaTab({required this.detail});

  final PokedexSpeciesDetail detail;

  @override
  Widget build(BuildContext context) {
    final media = detail.media;
    if (media == null) {
      return const _PokedexMissingSection(
        key: Key('pokedex-media-missing'),
        title: 'Médias',
        message: 'Aucune donnée média locale trouvée pour cette espèce.',
      );
    }

    final defaultVariant = media.variants[media.defaultFormId];

    return SingleChildScrollView(
      key: const Key('pokedex-media-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Variant par défaut',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Forme par défaut',
                  value: media.defaultFormId,
                ),
                _PokedexPropertyLine(
                  label: 'front',
                  value: defaultVariant?.frontStatic ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'back',
                  value: defaultVariant?.backStatic ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'front shiny',
                  value: defaultVariant?.frontShinyStatic ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'back shiny',
                  value: defaultVariant?.backShinyStatic ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'icon',
                  value: defaultVariant?.icon ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'party',
                  value: defaultVariant?.party ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'portrait',
                  value: defaultVariant?.portrait ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'cry',
                  value: defaultVariant?.cry ?? 'Aucun',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Animations',
            child: defaultVariant == null || defaultVariant.animations.isEmpty
                ? const Text('Aucune animation locale déclarée.')
                : Column(
                    children: defaultVariant.animations.entries
                        .map(
                          (entry) => _PokedexPropertyLine(
                            label: entry.key,
                            value:
                                '${entry.value.animationId} • ${entry.value.sheet}',
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 12),
          const _PokedexDetailSectionCard(
            title: 'Contrat média',
            child: Text(
              'Les médias Pokémon restent de simples références locales vers assets/pokemon/... et n’utilisent jamais de GIF.',
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnsetMoveSection extends StatelessWidget {
  const _LearnsetMoveSection({
    required this.title,
    required this.entries,
  });

  final String title;
  final List<PokemonLearnsetMoveEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: title,
      child: entries.isEmpty
          ? Text('Aucune entrée $title.')
          : Column(
              children: entries
                  .map(
                    (entry) => _PokedexPropertyLine(
                      label: entry.moveId,
                      value: entry.versionGroup,
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _PokedexMissingSection extends StatelessWidget {
  const _PokedexMissingSection({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: title,
      child: Text(message),
    );
  }
}

class _PokedexDetailSectionCard extends StatelessWidget {
  const _PokedexDetailSectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = Color.lerp(
      EditorChrome.islandFillElevated(context),
      CupertinoColors.black,
      0.06,
    )!;
    final border = EditorChrome.accentWarm.withValues(alpha: 0.24);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: DefaultTextStyle(
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PokedexPropertyLine extends StatelessWidget {
  const _PokedexPropertyLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final fill = EditorChrome.islandFillElevated(context);
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: subtle,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = EditorChrome.primaryLabel(context);
    final fill = Color.lerp(
      EditorChrome.chipFill(context),
      EditorChrome.accentWarm,
      0.18,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.35),
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

String _localizedValue(Map<String, String> values) {
  for (final key in const <String>['fr', 'en']) {
    final value = values[key]?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return values.values.firstWhere(
    (value) => value.trim().isNotEmpty,
    orElse: () => 'Aucune valeur locale',
  );
}

List<String> _orderedLocaleKeys(Map<String, String> values) {
  final locales = values.keys
      .map((key) => key.trim())
      .where((key) => key.isNotEmpty)
      .toSet()
      .toList(growable: false);

  // On garde un ordre stable et lisible dans la UI :
  // - `fr` puis `en` si présents, car ce sont les locales déjà privilégiées
  //   ailleurs dans le Pokédex ;
  // - puis le reste en ordre alphabétique pour éviter tout mouvement arbitraire
  //   des champs entre deux rebuilds.
  locales.sort((left, right) {
    final leftPriority = switch (left) {
      'fr' => 0,
      'en' => 1,
      _ => 2,
    };
    final rightPriority = switch (right) {
      'fr' => 0,
      'en' => 1,
      _ => 2,
    };
    final priorityCompare = leftPriority.compareTo(rightPriority);
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    return left.compareTo(right);
  });

  return locales;
}

String _describeEvolution(PokemonEvolutionEntry entry) {
  final explicit = _localizedValue(entry.conditionText);
  if (explicit != 'Aucune valeur locale') {
    return explicit;
  }
  if (entry.minLevel != null) {
    return 'Évolue au niveau ${entry.minLevel}';
  }
  if (entry.itemId != null && entry.itemId!.trim().isNotEmpty) {
    return 'Évolue avec ${entry.itemId}';
  }
  if (entry.requiredMoveId != null && entry.requiredMoveId!.trim().isNotEmpty) {
    return 'Évolue avec le move ${entry.requiredMoveId}';
  }
  if (entry.method.trim().isNotEmpty) {
    return 'Méthode : ${entry.method}';
  }
  return 'Condition non précisée';
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
