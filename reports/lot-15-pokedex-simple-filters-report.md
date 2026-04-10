# Rapport Lot 15 - Pokédex simple filters

## Résumé exécutif

Le lot 15 a été implémenté de manière strictement locale dans le workspace Pokédex existant.

Ce qui a été fait :
- ajout de filtres simples `type` et `génération` dans la vue Pokédex ;
- cumul des filtres avec la recherche texte du lot 14 ;
- conservation d'un filtrage instantané en mémoire, sans nouveau pipeline ;
- conservation de l'ordre existant des entrées ;
- maintien d'un état distinct `aucun résultat` ;
- ajout de tests ciblés sur les nouveaux comportements ;
- extension minimale de la projection légère `PokemonDatabaseIndexEntry` avec `genIntroduced`, donnée déjà présente dans `PokemonSpeciesFile`.

Ce qui n'a pas été fait :
- aucun filtre `activé/désactivé` n'a été ajouté ;
- aucun détail espèce ;
- aucune édition ;
- aucun import ;
- aucune persistance des filtres ;
- aucun provider/notifier/state Pokédex dédié ;
- aucun changement de runtime, de sauvegarde ou de `project.json`.

Verdict honnête sur `activé/désactivé` :
- point volontairement non implémenté ;
- l'audit n'a trouvé aucune donnée lecture seule stable dans le pipeline Pokédex actuel permettant ce filtre sans inventer le lot 29 ;
- implémenter ce filtre aurait obligé à tricher sur la roadmap, ce qui a été refusé.

## Objectif exact du lot

Objectif produit du lot 15 :
- enrichir doucement la liste Pokédex existante avec des filtres simples ;
- garder un comportement lecture seule ;
- rester local au workspace UI ;
- ne pas dériver vers les lots 16+ ou 29.

Objectif technique retenu :
- réutiliser la structure lot 13/14 déjà en place ;
- continuer à charger la liste une seule fois ;
- appliquer recherche + filtres localement sur les entrées déjà chargées ;
- exposer `genIntroduced` via la projection légère existante seulement parce que cette donnée est déjà présente dans les species locales et qu'elle est strictement nécessaire au filtre génération.

## Audit de l'existant

### Fichiers inspectés

- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `packages/map_editor/lib/src/application/models/pokemon_database_index.dart`
- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `packages/map_editor/lib/src/application/services/pokemon_database_index.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`
- `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/test/pokemon_database_index_test.dart`
- `packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart`

### Architecture observée

Le workspace Pokédex actuel repose déjà sur une structure locale et pragmatique :

- `pokedex_workspace.dart` :
  - porte l'état local de la recherche lot 14 ;
  - charge la liste via un `FutureBuilder` unique ;
  - distingue correctement `loading`, `error`, `empty`, `success`, `no results`.

- `pokedex_workspace_views.dart` :
  - contient les widgets de présentation ;
  - intègre déjà le champ de recherche et l'état `no results`.

- `PokemonDatabaseIndexEntry` :
  - représente la projection légère utilisée par le workspace ;
  - contient déjà `id`, `nationalDex`, `primaryName`, `types`, `refs`.

- `PokemonDatabaseIndex` + repository de lecture :
  - fournissent déjà une projection légère depuis les species locales ;
  - évitent learnsets, évolutions et médias ;
  - constituent le pipeline existant à réutiliser.

### Données déjà disponibles

Disponibles directement dans la projection UI existante :
- `id`
- `nationalDex`
- `primaryName`
- `types`
- `refs`

Disponibles dans la source de vérité locale déjà lue par l'index :
- `genIntroduced` dans `PokemonSpeciesFile`

Non trouvées proprement dans la projection/Pokédex pipeline actuel :
- `isEnabledInProject`
- `enabled/disabled`
- tout autre équivalent lecture seule stable branché au projet

### Audit spécifique du filtre activé/désactivé

Recherche réalisée sur le code :
- `genIntroduced|generation|isEnabledInProject|enabled|disabled|active|inactive`

Constat :
- présence claire de `genIntroduced` dans les modèles Pokémon ;
- aucune présence d'un champ d'activation Pokédex projet exploitable dans le pipeline léger ;
- la roadmap indique que le vrai champ de contrôle projet arrive seulement au lot 29.

Conclusion d'audit :
- `génération` peut être branchée proprement ;
- `activé/désactivé` ne peut pas être branché honnêtement sans anticiper le lot 29 ;
- il fallait donc refuser ce sous-point au lieu de simuler un filtre mensonger.

## Décisions d'architecture

### Décision 1 - garder l'état local au workspace

Décision :
- l'état `query`, `selectedType`, `selectedGeneration` reste dans `_PokedexWorkspaceBodyState`.

Pourquoi :
- cohérent avec le lot 14 ;
- aucun besoin de partager cet état hors du workspace ;
- évite un provider/notifier/state object Pokédex dédié ;
- respecte la consigne de filtrage local sur données déjà chargées.

### Décision 2 - ne pas créer de pipeline parallèle

Décision :
- réutiliser `PokemonDatabaseIndexEntry` et le pipeline `PokemonDatabaseIndex`.

Pourquoi :
- ce pipeline existe déjà et alimente la liste ;
- le lot 15 n'a pas besoin d'une nouvelle façade ;
- le coût minimal acceptable est seulement d'élargir la projection légère avec `genIntroduced`.

### Décision 3 - exposer `genIntroduced` dans la projection légère

Décision :
- ajout de `genIntroduced` à `PokemonDatabaseIndexEntry`.

Pourquoi :
- la donnée existe déjà dans `PokemonSpeciesFile` ;
- elle est strictement nécessaire au filtre génération ;
- cela reste un petit élargissement du contrat léger existant ;
- cela évite de relire les species depuis la UI ou d'inventer un second modèle.

### Décision 4 - refuser le filtre activé/désactivé

Décision :
- aucune UI, aucun faux menu, aucune simulation.

Pourquoi :
- pas de donnée lecture seule stable déjà branchée ;
- pas de persistance projet existante pour ce besoin ;
- la roadmap réserve explicitement l'activation/désactivation au lot 29 ;
- ajouter quoi que ce soit ici aurait été un débordement hors périmètre.

### Décision 5 - garder une UI minimale

Décision :
- ajouter deux menus simples `Type` et `Génération` au-dessus de la liste ;
- pas de toolbar riche ;
- pas de chips complexes de filtres ;
- pas de compteur sophistiqué ;
- pas de tri.

Pourquoi :
- solution lisible et sobre ;
- cohérente avec le style desktop existant ;
- diff reviewable.

## Gestion spécifique du filtre activé/désactivé

### Audit réel

Points vérifiés :
- projection `PokemonDatabaseIndexEntry`
- modèles species
- services de lecture/indexation
- occurrences `enabled/disabled/active/inactive/isEnabledInProject`

Résultat :
- aucune donnée Pokédex projet équivalente à `isEnabledInProject` n'est déjà disponible dans le pipeline de lecture simple utilisé par le workspace.

### Décision prise

- ne pas implémenter le filtre `activé/désactivé`.

### Justification stricte vis-à-vis de la roadmap

- le lot 29 annonce explicitement `Activer/désactiver une espèce dans le projet` ;
- ce lot introduit le vrai champ `isEnabledInProject` et la persistance associée ;
- le lot 15 ne peut pas prétendre filtrer sur une donnée qui n'existe pas encore dans le projet ;
- toute simulation aurait été du faux fonctionnel.

### Impact UI volontaire

- aucun contrôle `Activé` / `Désactivé` n'est affiché ;
- les tests vérifient explicitement cette absence volontaire.

## Périmètre inclus

- filtre simple par `type`
- filtre simple par `génération`
- cumul `recherche texte + filtres`
- cumul `type + génération`
- restauration de la liste complète quand aucun filtre n'est actif
- état `aucun résultat` enrichi pour rappeler les critères actifs
- tests ciblés
- rapport détaillé

## Périmètre exclu

- filtre `activé/désactivé`
- lot 16 détail espèce
- lot 17 learnset
- lot 18 évolutions
- lot 19 médias
- lot 20+ import
- lot 29 activation/désactivation persistée
- tri avancé
- toolbar Pokédex riche
- navigation vers une fiche détail
- édition inline
- persistance d'état de filtre
- cache global
- watcher fichiers
- nouvelle architecture Pokédex globale

## Liste exacte des fichiers modifiés

### Modifiés

- `packages/map_editor/lib/src/application/models/pokemon_database_index.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `packages/map_editor/test/pokemon_database_index_test.dart`

### Créé

- `reports/lot-15-pokedex-simple-filters-report.md`

### Volontairement non touchés

- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`
- `packages/map_editor/lib/src/application/services/pokemon_database_index.dart`
- `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `project.json`

## Explication fichier par fichier

### `packages/map_editor/lib/src/application/models/pokemon_database_index.dart`

Modification :
- ajout de `genIntroduced` à `PokemonDatabaseIndexEntry` ;
- propagation depuis `PokemonSpeciesFile` dans `fromSpeciesEntry`.

Justification :
- nécessaire au filtre génération ;
- donnée déjà présente dans la source lue par l'index ;
- changement minimal du contrat léger existant.

Code :

```dart
class PokemonDatabaseIndexEntry {
  const PokemonDatabaseIndexEntry({
    required this.id,
    required this.nationalDex,
    required this.primaryName,
    required this.genIntroduced,
    required this.types,
    required this.refs,
  });

  final String id;
  final int nationalDex;
  final String primaryName;
  final int genIntroduced;
  final List<String> types;
  final PokemonDatabaseIndexRefs refs;

  factory PokemonDatabaseIndexEntry.fromSpeciesEntry({
    required PokemonSpeciesIndexEntry speciesIndexEntry,
    required PokemonSpeciesFile species,
  }) {
    return PokemonDatabaseIndexEntry(
      id: speciesIndexEntry.id,
      nationalDex: speciesIndexEntry.nationalDex,
      primaryName: speciesIndexEntry.primaryName,
      genIntroduced: species.genIntroduced,
      types: List<String>.from(speciesIndexEntry.types),
      refs: PokemonDatabaseIndexRefs(
        learnset: species.learnsetRef.trim(),
        evolution: species.evolutionRef.trim(),
        spriteSet: species.spriteSetRef.trim(),
        cry: species.cryRef.trim(),
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`

Modifications :
- ajout de l'état local des filtres ;
- construction de la liste des types/générations disponibles ;
- filtrage cumulé `recherche + type + génération` ;
- réinitialisation locale des filtres quand le contexte projet change ;
- adaptation du `no results`.

Justification :
- point naturel d'intégration de l'état local ;
- aucun nouveau provider ;
- aucun nouveau `FutureBuilder` ;
- aucun nouveau service.

Code clé :

```dart
String _searchQuery = '';
String _selectedType = _allTypesFilterValue;
String _selectedGeneration = _allGenerationsFilterValue;

final filteredEntries = _filterEntries(entries);
```

```dart
final matchesType = !hasTypeFilter ||
    entry.types.any((type) => type.toLowerCase() == typeFilter);
final matchesGeneration = !hasGenerationFilter ||
    entry.genIntroduced.toString() == _selectedGeneration;

return matchesSearch && matchesType && matchesGeneration;
```

Pourquoi cette solution reste dans le scope :
- la recherche lot 14 est conservée telle quelle ;
- les filtres sont strictement locaux ;
- l'ordre des entrées n'est jamais modifié ;
- aucun état global n'est introduit.

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`

Modifications :
- ajout d'une barre de filtres simples ;
- ajout de deux menus `Type` et `Génération` ;
- adaptation du message descriptif ;
- adaptation de `PokedexWorkspaceNoResultsState` pour afficher les critères actifs ;
- largeur volontairement plus confortable sur les menus pour éviter les overflows de layout en français.

Justification :
- lieu naturel de la présentation ;
- pas d'action métier ajoutée ;
- pas de feature riche ;
- sobriété maintenue.

Code clé :

```dart
_PokedexSimpleFiltersBar(
  availableTypes: availableTypes,
  selectedType: selectedType,
  onTypeChanged: onTypeChanged,
  availableGenerations: availableGenerations,
  selectedGeneration: selectedGeneration,
  onGenerationChanged: onGenerationChanged,
),
```

```dart
message: 'Aucun résultat avec les critères actuels.$suffix',
```

```dart
width: 360,
```

Pourquoi ce dernier point existe :
- les libellés français `Toutes les générations` et `Tous les types` provoquaient un overflow dans `MacosPopupButton` ;
- la correction retenue est purement de layout, locale et sans impact fonctionnel.

### `packages/map_editor/test/pokedex_workspace_ui_test.dart`

Modifications :
- factorisation d'un helper `buildEntry` ;
- ajout d'un helper `selectPopupFilter` ;
- wrapping du harness de test dans `MaterialApp` pour fournir les localizations nécessaires à `MacosPopupButton` lors des taps ;
- ajout des tests lot 15 ciblés ;
- vérification explicite de l'absence du filtre `activé/désactivé`.

Justification :
- tests comportementaux réels ;
- pas de snapshots mous ;
- verrouillage du scope.

Nouveaux comportements testés :
- présence des filtres ;
- filtre par type ;
- filtre par génération ;
- cumul recherche + filtres ;
- cumul de filtres simples ;
- restauration de la liste complète ;
- état `aucun résultat` avec critères ;
- absence volontaire du filtre `activé/désactivé`.

Code clé :

```dart
Future<void> selectPopupFilter(
  WidgetTester tester, {
  required Key popupKey,
  required String itemLabel,
}) async {
  await tester.tap(find.byKey(popupKey));
  await tester.pumpAndSettle();
  await tester.tap(find.text(itemLabel).last);
  await tester.pumpAndSettle();
}
```

```dart
expect(find.byKey(const Key('pokedex-type-filter')), findsOneWidget);
expect(find.byKey(const Key('pokedex-generation-filter')), findsOneWidget);
expect(find.textContaining('Activé'), findsNothing);
expect(find.textContaining('Désactivé'), findsNothing);
```

### `packages/map_editor/test/pokemon_database_index_test.dart`

Modification :
- ajout d'une assertion sur `genIntroduced`.

Justification :
- verrouiller le petit élargissement de projection introduit pour le lot 15 ;
- garantir que l'information vient bien du pipeline existant.

Code :

```dart
expect(bulbasaur.genIntroduced, 1);
```

## Code intégral des fichiers modifiés

### `packages/map_editor/lib/src/application/models/pokemon_database_index.dart`

```dart
import 'pokemon_project_data_models.dart';

class PokemonDatabaseIndexRefs {
  const PokemonDatabaseIndexRefs({
    required this.learnset,
    required this.evolution,
    required this.spriteSet,
    required this.cry,
  });

  final String learnset;
  final String evolution;
  final String spriteSet;
  final String cry;
}

class PokemonDatabaseIndexEntry {
  const PokemonDatabaseIndexEntry({
    required this.id,
    required this.nationalDex,
    required this.primaryName,
    required this.genIntroduced,
    required this.types,
    required this.refs,
  });

  final String id;
  final int nationalDex;
  final String primaryName;
  final int genIntroduced;
  final List<String> types;
  final PokemonDatabaseIndexRefs refs;

  factory PokemonDatabaseIndexEntry.fromSpeciesEntry({
    required PokemonSpeciesIndexEntry speciesIndexEntry,
    required PokemonSpeciesFile species,
  }) {
    return PokemonDatabaseIndexEntry(
      id: speciesIndexEntry.id,
      nationalDex: speciesIndexEntry.nationalDex,
      primaryName: speciesIndexEntry.primaryName,
      genIntroduced: species.genIntroduced,
      types: List<String>.from(speciesIndexEntry.types),
      refs: PokemonDatabaseIndexRefs(
        learnset: species.learnsetRef.trim(),
        evolution: species.evolutionRef.trim(),
        spriteSet: species.spriteSetRef.trim(),
        cry: species.cryRef.trim(),
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`

Le fichier complet est trop long pour être recopié utilement ici ligne par ligne sans nuire à la lisibilité du rapport.
Les extraits ci-dessous couvrent toute la logique nouvelle du lot 15.

```dart
const String _allTypesFilterValue = '__all_types__';
const String _allGenerationsFilterValue = '__all_generations__';

class _PokedexWorkspaceBodyState extends State<_PokedexWorkspaceBody> {
  late Future<List<PokemonDatabaseIndexEntry>> _entriesFuture;
  String _searchQuery = '';
  String _selectedType = _allTypesFilterValue;
  String _selectedGeneration = _allGenerationsFilterValue;
```

```dart
if (oldWidget.projectRootPath != widget.projectRootPath ||
    oldWidget.loader != widget.loader) {
  _entriesFuture = _buildEntriesFuture();
  _searchQuery = '';
  _selectedType = _allTypesFilterValue;
  _selectedGeneration = _allGenerationsFilterValue;
}
```

```dart
final availableTypes = _buildAvailableTypes(entries);
final availableGenerations = _buildAvailableGenerations(entries);
final filteredEntries = _filterEntries(entries);
```

```dart
List<PokemonDatabaseIndexEntry> _filterEntries(
  List<PokemonDatabaseIndexEntry> entries,
) {
  final normalizedQuery = _searchQuery.trim();
  final normalizedTextQuery = normalizedQuery.toLowerCase();
  final normalizedDexQuery = _normalizeDexQuery(normalizedQuery);
  final hasExactDexQuery = RegExp(r'^\d+$').hasMatch(normalizedDexQuery);

  final typeFilter = _selectedType.toLowerCase();
  final hasTypeFilter = _selectedType != _allTypesFilterValue;
  final hasGenerationFilter =
      _selectedGeneration != _allGenerationsFilterValue;

  return entries.where((entry) {
    final matchesSearch = _matchesSearchQuery(
      entry: entry,
      normalizedQuery: normalizedQuery,
      normalizedTextQuery: normalizedTextQuery,
      normalizedDexQuery: normalizedDexQuery,
      hasExactDexQuery: hasExactDexQuery,
    );

    final matchesType = !hasTypeFilter ||
        entry.types.any((type) => type.toLowerCase() == typeFilter);
    final matchesGeneration = !hasGenerationFilter ||
        entry.genIntroduced.toString() == _selectedGeneration;

    return matchesSearch && matchesType && matchesGeneration;
  }).toList(growable: false);
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`

Extraits complets des parties nouvelles :

```dart
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
```

```dart
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
```

```dart
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
```

### `packages/map_editor/test/pokedex_workspace_ui_test.dart`

Extraits importants :

```dart
child: MaterialApp(
  home: CupertinoPageScaffold(
    child: SizedBox(
      width: 1280,
      height: 900,
      child: child,
    ),
  ),
),
```

```dart
PokemonDatabaseIndexEntry buildEntry({
  required String id,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
  required int genIntroduced,
}) {
  return PokemonDatabaseIndexEntry(
    id: id,
    nationalDex: nationalDex,
    primaryName: primaryName,
    genIntroduced: genIntroduced,
    types: types,
    refs: PokemonDatabaseIndexRefs(
      learnset: id,
      evolution: id,
      spriteSet: id,
      cry: id,
    ),
  );
}
```

```dart
testWidgets('filters instantly by type', (tester) async {
  ...
  await selectPopupFilter(
    tester,
    popupKey: const Key('pokedex-type-filter'),
    itemLabel: 'fire',
  );

  expect(find.text('Charmander'), findsOneWidget);
  expect(find.text('Bulbasaur'), findsNothing);
});
```

```dart
testWidgets('filters instantly by generation', (tester) async {
  ...
  await selectPopupFilter(
    tester,
    popupKey: const Key('pokedex-generation-filter'),
    itemLabel: 'Génération 3',
  );

  expect(find.text('Treecko'), findsOneWidget);
  expect(find.text('Bulbasaur'), findsNothing);
});
```

```dart
testWidgets('shows no results when simple filters eliminate the list',
    (tester) async {
  ...
  await selectPopupFilter(
    tester,
    popupKey: const Key('pokedex-type-filter'),
    itemLabel: 'poison',
  );
  await selectPopupFilter(
    tester,
    popupKey: const Key('pokedex-generation-filter'),
    itemLabel: 'Génération 1',
  );
  await tester.enterText(
    find.byKey(const Key('pokedex-search-field')),
    'zzz',
  );
  await tester.pump();

  expect(find.byKey(const Key('pokedex-no-results-state')), findsOneWidget);
  expect(find.textContaining('Aucun résultat avec les critères actuels.'),
      findsOneWidget);
  expect(find.textContaining('Recherche actuelle : "zzz".'), findsOneWidget);
  expect(find.textContaining('Type : poison.'), findsOneWidget);
  expect(find.textContaining('Génération : 1.'), findsOneWidget);
});
```

### `packages/map_editor/test/pokemon_database_index_test.dart`

Extrait important :

```dart
expect(bulbasaur.types, <String>['grass', 'poison']);
expect(bulbasaur.genIntroduced, 1);
```

## Commandes réellement exécutées

### Audit / recherche

```bash
ls "/Users/karim/.cursor/projects/Users-karim-Project-pokemonProject/terminals"
```

```bash
rg "genIntroduced|generation|isEnabledInProject|enabled|disabled|active|inactive"
```

```bash
rg "PulldownButton|PopupButton|MacosPopupButton|MacosPulldownButton|CupertinoSlidingSegmentedControl|SegmentedControl|PopupMenuButton"
```

```bash
rg "PokemonDatabaseIndexEntry\("
```

### Format

```bash
dart format "packages/map_editor/lib/src/application/models/pokemon_database_index.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart" "packages/map_editor/test/pokedex_workspace_ui_test.dart" "packages/map_editor/test/pokemon_database_index_test.dart"
```

### Tests

```bash
cd packages/map_editor && flutter test test/pokedex_workspace_ui_test.dart
```

```bash
cd packages/map_editor && flutter test test/pokemon_database_index_test.dart
```

### Analyse

```bash
cd packages/map_editor && flutter analyze lib/src/application/models/pokemon_database_index.dart lib/src/ui/canvas/pokedex_workspace.dart lib/src/ui/canvas/pokedex_workspace_views.dart test/pokedex_workspace_ui_test.dart test/pokemon_database_index_test.dart
```

### Git lecture seule

```bash
git status --short
```

```bash
git diff --stat
```

## Résultats réels

### Format

Résultat :
- succès

Sortie notable :

```text
Formatted packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
Formatted packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
Formatted packages/map_editor/test/pokedex_workspace_ui_test.dart
Formatted 5 files (3 changed) in 0.02 seconds.
```

### Tests index

Commande :

```bash
cd packages/map_editor && flutter test test/pokemon_database_index_test.dart
```

Résultat :
- succès

Sortie finale :

```text
+10: All tests passed!
```

### Tests widget Pokédex

Commande :

```bash
cd packages/map_editor && flutter test test/pokedex_workspace_ui_test.dart
```

Résultat final :
- succès

Sortie finale :

```text
+18: All tests passed!
```

### Analyse

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/application/models/pokemon_database_index.dart lib/src/ui/canvas/pokedex_workspace.dart lib/src/ui/canvas/pokedex_workspace_views.dart test/pokedex_workspace_ui_test.dart test/pokemon_database_index_test.dart
```

Résultat :
- succès

Sortie :

```text
Analyzing 5 items...
No issues found! (ran in 1.4s)
```

## Erreurs intermédiaires réellement rencontrées

### Erreur 1 - overflow de layout dans `MacosPopupButton`

Symptôme :
- `flutter test test/pokedex_workspace_ui_test.dart` échouait avec :

```text
A RenderFlex overflowed by 7.8 pixels on the right.
A RenderFlex overflowed by 112 pixels on the right.
```

Cause :
- largeur trop courte pour les libellés de menus, notamment en français.

Correction :
- largeur du dropdown portée à `360`.

Pourquoi cette correction est proportionnée :
- pure correction de layout ;
- aucun impact architectural ;
- aucune modification de comportement produit.

### Erreur 2 - `No MaterialLocalizations found`

Symptôme :
- les tests tapant sur `MacosPopupButton` échouaient avec :

```text
No MaterialLocalizations found.
MacosPopupButton<String> widgets require MaterialLocalizations ...
```

Cause :
- le harness de test utilisait `CupertinoApp` seul ;
- les interactions du popup ont besoin des localizations fournies par `MaterialApp`.

Correction :
- remplacement du wrapper de test par `MaterialApp`.

Important :
- aucun changement de prod ;
- correction strictement limitée au harness de test.

### Erreur 3 - tentative inutile avec `flutter_localizations`

Symptôme :
- ajout initial de `package:flutter_localizations/flutter_localizations.dart` ;
- compilation échouée :

```text
Couldn't resolve the package 'flutter_localizations'
```

Cause :
- dépendance non déclarée dans ce package ;
- et surtout non nécessaire ici.

Correction :
- suppression de cet import ;
- conservation de `MaterialApp` simple, suffisant dans les tests.

### Erreur 4 - test `no results` initialement mal construit

Symptôme logique :
- un test essayait de sélectionner une génération absente de la liste des options, ce qui n'était pas réaliste.

Correction :
- le test a été réécrit pour provoquer `no results` via la combinaison :
  - filtre type valide ;
  - filtre génération valide ;
  - recherche texte non matchante.

Pourquoi c'est meilleur :
- scénario fidèle au comportement réel de l'UI ;
- pas de dépendance à une option inexistante.

## État git utile

### `git status --short`

```text
 M packages/map_editor/lib/src/application/models/pokemon_database_index.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
 M packages/map_editor/test/pokedex_workspace_ui_test.dart
 M packages/map_editor/test/pokemon_database_index_test.dart
```

### `git diff --stat`

```text
 .../application/models/pokemon_database_index.dart |  14 +-
 .../lib/src/ui/canvas/pokedex_workspace.dart       | 164 +++++--
 .../lib/src/ui/canvas/pokedex_workspace_views.dart | 195 +++++++-
 .../map_editor/test/pokedex_workspace_ui_test.dart | 491 +++++++++++++++++----
 .../test/pokemon_database_index_test.dart          |   4 +
 5 files changed, 731 insertions(+), 137 deletions(-)
```

### Lecture honnête du diff

- le diff reste concentré sur le workspace Pokédex et ses tests ;
- le volume élevé vient surtout du fichier de tests, enrichi avec plusieurs scénarios ciblés ;
- aucun fichier runtime/sauvegarde/import n'a été touché ;
- aucun fichier Git n'a été écrit.

## Limites restantes

- aucun filtre `activé/désactivé` n'est disponible ;
- aucune vue détail espèce ;
- aucune édition ;
- aucune persistance des filtres ;
- aucune logique learnset/évolutions/médias ;
- aucune navigation de ligne ;
- aucune action de masse ;
- aucune feature du lot 16+.

Limite principale liée à la roadmap :
- le filtre `activé/désactivé` dépend en pratique du lot 29, qui doit introduire le vrai champ projet et sa persistance.

## Conclusion honnête

Le lot 15 a été livré dans une version strictement cadrée et honnête :
- `type` et `génération` fonctionnent ;
- ils sont cumulables entre eux et avec la recherche texte ;
- la liste reste lecture seule ;
- l'état `aucun résultat` reste propre ;
- l'implémentation reste locale et sans architecture spéculative.

Le sous-point `activé/désactivé` n'a pas été implémenté, volontairement, parce que la donnée nécessaire n'existe pas encore proprement dans le pipeline actuel sans anticiper le lot 29. C'est une limitation assumée, explicitement documentée, et conforme à la consigne "pas de bullshit".

## Checklist d'autocontrôle finale

### Scope

- [x] J’ai implémenté uniquement le lot 15
- [x] Je n’ai pas commencé le lot 16
- [x] Je n’ai pas commencé le lot 29
- [x] Je n’ai ajouté ni détail, ni édition, ni import
- [x] Je n’ai pas modifié `project.json`
- [x] Je n’ai pas modifié le runtime
- [x] Je n’ai pas modifié la sauvegarde

### Architecture

- [x] J’ai audité l’existant avant de coder
- [x] J’ai réutilisé la structure du lot 13/14
- [x] Je n’ai pas créé de pipeline parallèle
- [x] Je n’ai pas créé de provider/notifier/state Pokédex dédié
- [x] Le filtrage reste local et simple

### Filtres

- [x] Le filtre type fonctionne
- [x] Le filtre génération fonctionne
- [x] Les filtres sont cumulables
- [x] La recherche texte continue de fonctionner avec les filtres
- [x] La liste complète revient si on retire les filtres
- [x] L’état aucun résultat reste propre
- [x] Le cas activé/désactivé a été traité honnêtement

### Qualité

- [x] Le code est formaté
- [x] Les tests ciblés passent
- [x] L’analyse ciblée passe
- [x] Le rapport markdown a été créé
- [x] Le rapport contient le code et les explications
- [x] Aucune commande Git d’écriture n’a été exécutée
