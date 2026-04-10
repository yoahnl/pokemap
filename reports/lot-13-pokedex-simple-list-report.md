# Lot 13 - Liste simple des espèces importées

## A. Résumé exécutif

Le lot 13 a été implémenté en restant centré sur un seul objectif produit : remplacer le placeholder central du lot 12 par une première vraie vue Pokédex utile, en lecture seule, alimentée par les données locales déjà présentes dans le projet.

Le résultat livré est volontairement limité :

- la tuile `Pokédex` existante continue de servir de point d'entrée ;
- le workspace central affiche désormais une liste simple ;
- les colonnes visibles sont strictement `numéro dex`, `nom`, `id`, `types` ;
- les états minimaux `loading`, `succès`, `vide`, `erreur` sont gérés ;
- aucun détail espèce, aucune recherche, aucun filtre, aucune édition, aucun import n'ont été ajoutés.

L'intégration réutilise le pipeline local du lot 11 au lieu d'en créer un nouveau. Le seul élargissement de projection demandé pour la UI est l'ajout de `types` dans `PokemonDatabaseIndexEntry`, car cette donnée est nécessaire à la liste du lot 13 et elle est déjà disponible dans la projection légère lue depuis `species/`.

## B. Objectif exact du lot

Objectif produit du lot 13 :

- afficher dans l'éditeur une vraie liste simple des espèces importées ;
- charger cette liste à partir des JSON locaux du projet ;
- afficher uniquement `nationalDex`, `primaryName`, `id`, `types` ;
- fournir des états UI honnêtes et minimaux ;
- s'arrêter immédiatement là.

Ce lot ne devait pas commencer :

- le lot 14 ;
- le lot 15 ;
- le lot 16 ;
- ni aucune architecture intermédiaire "future-ready" masquée.

## C. Audit de l'existant

### C.1 Point d'entrée UI du lot 12

Le lot 12 avait déjà branché :

- le mode `EditorWorkspaceMode.pokedex` ;
- la navigation `selectPokedexWorkspace()` ;
- le routage central via `EditorCanvasHost` ;
- l'entrée dans `ProjectExplorerPanel` ;
- l'entrée dans `top_toolbar.dart` ;
- un widget central `PokedexPlaceholderWorkspace`.

Conclusion d'audit :

- le bon point d'intégration était de conserver exactement ce branchement ;
- il fallait uniquement remplacer le contenu central du workspace ;
- il ne fallait pas inventer un nouveau router, un nouveau registre, ni un nouveau point d'entrée.

### C.2 Pipeline local de lecture déjà prêt

L'audit des briques Pokémon existantes a montré :

- `PokemonDatabaseIndex` lit le `speciesDir` configuré par le projet ;
- `PokemonReadRepository.listDatabaseIndexEntries(...)` fournit déjà une projection légère triable pour une liste ;
- `PokemonSpeciesIndexEntry` contient déjà `id`, `nationalDex`, `primaryName`, `types`, `relativePath` ;
- `PokemonDatabaseIndexEntry` ne contenait pas encore `types` ;
- le lot 11 avait déjà des tests de lecture workspace vs `Directory.current`, de non-mutation de `project.json`, et d'absence de lecture learnsets/evolutions/media.

Conclusion d'audit :

- la réutilisation du lot 11 était la bonne direction ;
- le plus petit changement cohérent était d'étendre `PokemonDatabaseIndexEntry` avec `types` ;
- il ne fallait pas créer une deuxième façade applicative ou un deuxième pipeline UI dédié à la liste.

### C.3 Pattern UI existant

L'audit de la UI de `map_editor` a montré :

- usage fréquent de `FutureBuilder` pour des lectures ponctuelles simples ;
- usage de cartes/états sobres avec `EditorChrome` ;
- usage de listes légères, plus cohérent ici qu'un tableau riche ou une data-grid ;
- absence d'intérêt produit à introduire un notifier/provider Pokédex dédié pour un lot de lecture simple.

Conclusion d'audit :

- le bon pattern était un widget central local avec `FutureBuilder` ;
- les états `loading / vide / erreur` devaient rester compacts ;
- la liste devait rester une simple colonne de lignes stylées, pas une feature complexe.

## D. Décisions d'architecture retenues

### D.1 Réutilisation du lot 12

Le fichier central du lot 12 a été conservé comme point d'évolution :

- `pokedex_placeholder_workspace.dart` a gardé son rôle de surface centrale Pokédex ;
- son contenu a été remplacé par un vrai workspace lecture seule ;
- cela garde le diff local et reviewable.

### D.2 Réutilisation du lot 11

Le lot 13 réutilise `PokemonDatabaseIndex` pour charger la liste locale.

Décision retenue :

- ne pas réintroduire de parsing JSON UI ;
- ne pas créer une nouvelle façade "liste Pokédex" parallèle ;
- ne pas détourner `PokemonSpeciesIndexEntry.fromJson(...)` ;
- propager simplement `types` dans `PokemonDatabaseIndexEntry`.

Pourquoi c'est cohérent :

- `types` est déjà connu par la projection légère du lot 11 ;
- la UI du lot 13 a besoin de `types` ;
- l'ajout ne force ni learnset, ni évolution, ni média, ni lecture détaillée supplémentaire.

### D.3 États UI minimaux

Le workspace central gère uniquement :

- `loading` ;
- `success` avec liste ;
- `success` avec liste vide ;
- `error`.

Aucune logique supplémentaire n'a été introduite :

- pas de pagination ;
- pas de recherche ;
- pas de tri utilisateur ;
- pas de cache ;
- pas de watcher filesystem ;
- pas de panneau détail ;
- pas d'action par ligne.

### D.4 Traitement local de l'absence de dossier `species`

Le widget central convertit localement l'absence de dossier `species` en état vide, au lieu d'exposer une erreur brute.

Pourquoi au niveau UI :

- le service générique de lecture n'a pas été modifié ;
- on évite d'élargir le contrat général du lot 11 ;
- la décision produit du lot 13 concerne seulement l'expérience de l'écran Pokédex.

## E. Périmètre inclus

- conservation du point d'entrée Pokédex du lot 12 ;
- remplacement du placeholder central par une liste simple ;
- réutilisation du pipeline local d'indexation ;
- ajout de `types` dans la projection d'index exposée à la UI ;
- affichage strict de `numéro / nom / id / types` ;
- états `loading / vide / erreur / succès` ;
- tests ciblés de la UI ;
- mise à jour ciblée du test du lot 11 impacté ;
- commentaires de cadrage dans le code ;
- rapport détaillé.

## F. Périmètre explicitement exclu

- recherche texte ;
- filtres ;
- tri configurable ;
- détail espèce ;
- édition ;
- import manuel ;
- toolbar Pokédex riche ;
- tabs ;
- panneau détail latéral ;
- learnsets ;
- évolutions ;
- médias ;
- validation métier avancée ;
- cache applicatif ;
- provider Pokédex dédié ;
- notifier Pokédex dédié ;
- state object Pokédex dédié ;
- controller/view-model dédié ;
- modification de `project.json` ;
- modification runtime ;
- modification sauvegarde ;
- modification import ;
- nouveau pipeline parallèle ;
- nouvelle abstraction spéculative.

## G. Liste exacte des fichiers modifiés

- `packages/map_editor/lib/src/application/models/pokemon_database_index.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/test/pokedex_placeholder_ui_test.dart`
- `packages/map_editor/test/pokemon_database_index_test.dart`

## H. Fichiers volontairement non touchés

- `packages/map_editor/lib/src/application/services/pokemon_database_index.dart`
- `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `packages/map_editor/test/list_pokedex_entries_use_case_test.dart`
- `project.json`
- tout le runtime ;
- toute la sauvegarde ;
- toute la logique learnset/evolution/media.

### Pourquoi ces fichiers sont restés intacts

- le service du lot 11 était déjà correct pour le scope ;
- le contrat historique de `PokemonSpeciesIndexEntry` ne devait pas être réouvert ;
- aucun besoin fonctionnel du lot 13 n'imposait de modifier les repositories ou le reader ;
- `list_pokedex_entries_use_case.dart` n'a pas été retenu comme point d'intégration, car il portait déjà des champs hors scope (`isStarterEligible`, `genIntroduced`) et aurait tiré le lot 13 dans une direction plus large que nécessaire.

## I. Justification fichier par fichier

### `packages/map_editor/lib/src/application/models/pokemon_database_index.dart`

Pourquoi touché :

- le lot 13 doit afficher les `types` ;
- la projection d'index utilisée par la UI ne les exposait pas encore.

Pourquoi c'était nécessaire :

- sans `types`, la UI devait soit relire plus de données ailleurs, soit construire un pipeline parallèle ;
- ces deux options auraient élargi inutilement le scope.

Pourquoi cela reste dans le lot 13 :

- on ajoute uniquement un champ déjà disponible dans la projection légère ;
- on ne commence aucune donnée hors scope.

### `packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart`

Pourquoi touché :

- c'était le point central exact branché au lot 12 ;
- il fallait remplacer le placeholder vide par la vraie liste simple.

Pourquoi c'était nécessaire :

- c'est le point d'intégration le plus local ;
- cela évite toute nouvelle convention.

Pourquoi cela reste dans le lot 13 :

- le widget se limite à lire et afficher ;
- pas de recherche, pas de détail, pas d'édition.

### `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`

Pourquoi touché :

- pour router `EditorWorkspaceMode.pokedex` vers le nouveau workspace réel du lot 13.

Pourquoi cela reste dans le lot 13 :

- simple mise à jour du routage existant ;
- aucune nouvelle logique métier.

### `packages/map_editor/lib/src/features/editor/state/editor_state.dart`

Pourquoi touché :

- pour mettre à jour les commentaires de cadrage du mode `pokedex`.

Pourquoi cela reste dans le lot 13 :

- uniquement documentation d'intention ;
- aucun changement de contrat structurel.

### `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

Pourquoi touché :

- pour aligner les commentaires de `selectPokedexWorkspace()` avec le nouveau rôle du lot 13.

Pourquoi cela reste dans le lot 13 :

- aucune lecture ajoutée dans le notifier ;
- navigation seule conservée.

### `packages/map_editor/lib/src/ui/editor_shell_page.dart`

Pourquoi touché :

- pour ajuster les textes descriptifs autour du workspace Pokédex ;
- pour rester honnête sur ce que le lot 13 affiche réellement.

Pourquoi cela reste dans le lot 13 :

- aucun inspecteur riche ajouté ;
- toujours pas de fiche détail.

### `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`

Pourquoi touché :

- pour mettre à jour les textes du point d'entrée Pokédex ;
- pour refléter le passage du placeholder vide à la liste simple.

Pourquoi cela reste dans le lot 13 :

- la carte reste une simple entrée de navigation ;
- aucun compteur, aucun résumé riche, aucun faux bouton.

### `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`

Pourquoi touché :

- pour aligner le tooltip et les commentaires de navigation avec le lot 13.

Pourquoi cela reste dans le lot 13 :

- aucun outil Pokédex supplémentaire n'a été ajouté.

### `packages/map_editor/test/pokedex_placeholder_ui_test.dart`

Pourquoi touché :

- pour remplacer les tests du placeholder lot 12 par des tests utiles au lot 13.

Pourquoi cela reste dans le lot 13 :

- les tests vérifient uniquement la tuile, la liste simple, le loading, le vide et l'erreur ;
- ils n'ouvrent aucune fiche détail et ne testent aucune édition.

### `packages/map_editor/test/pokemon_database_index_test.dart`

Pourquoi touché :

- pour verrouiller l'ajout de `types` dans la projection d'index réutilisée par la UI.

Pourquoi cela reste dans le lot 13 :

- ce test couvre exactement l'impact minimal induit par la nouvelle UI ;
- il ne change pas le scope du service lui-même.

## J. Code produit et explication

### J.1 Ajout minimal de `types` dans l'index réutilisé par la UI

```dart
class PokemonDatabaseIndexEntry {
  const PokemonDatabaseIndexEntry({
    required this.id,
    required this.nationalDex,
    required this.primaryName,
    required this.types,
    required this.refs,
  });

  final String id;
  final int nationalDex;
  final String primaryName;
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

Explication :

- le champ manquant pour le lot 13 était `types` ;
- il est récupéré depuis `PokemonSpeciesIndexEntry`, déjà léger et déjà construit ;
- aucune relecture additionnelle n'est introduite.

### J.2 Workspace central lecture seule

```dart
class PokedexWorkspace extends ConsumerWidget {
  const PokedexWorkspace({
    super.key,
    this.loader,
  });

  final PokedexEntryLoader? loader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectRootPath =
        ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));

    return _PokedexWorkspaceBody(
      projectRootPath: projectRootPath,
      loader: loader,
    );
  }
}
```

Explication :

- le widget lit uniquement `projectRootPath` depuis l'état éditeur existant ;
- il ne crée pas de notifier ou de provider Pokédex dédié ;
- l'injection `loader` existe uniquement pour les tests UI ciblés.

### J.3 États minimaux du lot 13

```dart
return FutureBuilder<List<PokemonDatabaseIndexEntry>>(
  future: _loadFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const _PokedexLoadingState();
    }

    if (snapshot.hasError) {
      return _PokedexErrorState(error: snapshot.error);
    }

    final entries = snapshot.data ?? const <PokemonDatabaseIndexEntry>[];
    if (entries.isEmpty) {
      return const _PokedexStateCard(
        key: Key('pokedex-empty-state'),
        title: 'Pokédex',
        message:
            'Aucune espèce importée pour le moment. Les prochains imports ou seeds rempliront cette liste.',
      );
    }

    return _PokedexSpeciesList(entries: entries);
  },
);
```

Explication :

- exactement quatre états ;
- aucun sous-état riche ;
- aucun faux workflow.

### J.4 Liste stricte `numéro / nom / id / types`

```dart
Row(
  children: [
    SizedBox(width: 88, child: Text('Numéro')),
    Expanded(flex: 3, child: Text('Nom')),
    Expanded(flex: 2, child: Text('ID')),
    Expanded(flex: 3, child: Text('Types')),
  ],
)
```

Et pour chaque ligne :

```dart
Row(
  children: [
    SizedBox(width: 88, child: Text('#${entry.nationalDex.toString().padLeft(4, '0')}')),
    Expanded(flex: 3, child: Text(entry.primaryName)),
    Expanded(flex: 2, child: Text(entry.id)),
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
)
```

Explication :

- seules les quatre colonnes demandées sont visibles ;
- `refs` n'est pas exposé ;
- aucun autre indicateur produit n'est affiché.

### J.5 Tests UI ajoutés

```dart
testWidgets('renders the simple species list with only number name id and types', ...)
testWidgets('shows a loading state before the species list resolves', ...)
testWidgets('shows an empty state when no species files are present', ...)
testWidgets('shows an error state when species loading fails', ...)
```

Explication :

- les tests du widget restent concentrés sur le comportement écran ;
- la preuve de lecture locale réelle reste couverte par le test de service du lot 11 déjà existant, relancé après l'ajout de `types`.

## K. Tests ajoutés / adaptés

### K.1 Tests UI Pokédex

`packages/map_editor/test/pokedex_placeholder_ui_test.dart`

Ajouts/adaptations :

- présence de l'entrée Pokédex dans l'éditeur ;
- rendu de la liste simple avec seulement `numéro / nom / id / types` ;
- état `loading` ;
- état `vide` ;
- état `erreur`.

### K.2 Test du pipeline réutilisé

`packages/map_editor/test/pokemon_database_index_test.dart`

Ajout/adaptation :

- vérification explicite que `PokemonDatabaseIndex` expose aussi `types`, désormais nécessaire à la liste simple du lot 13.

## L. Vérification des critères d’acceptation

### L.1 La liste se charge depuis les JSON locaux

Statut : `OK`

Justification :

- la UI réelle charge via `PokemonDatabaseIndex` ;
- le test de service rejoué prouve encore la lecture workspace réelle, l'absence de dépendance à `Directory.current`, l'absence de mutation de `project.json`, et l'absence de lecture learnsets/evolutions/media.

### L.2 La vue montre bien uniquement numéro / nom / id / types

Statut : `OK`

Justification :

- le header et les lignes ne contiennent que ces quatre champs ;
- aucun autre champ Pokémon n'est affiché.

### L.3 Pas encore d’édition

Statut : `OK`

Justification :

- aucun bouton d'action ;
- aucun onTap par ligne ;
- aucun inspecteur dédié de détail.

### L.4 Pas encore de filtres complexes

Statut : `OK`

Justification :

- aucune recherche ;
- aucun filtre ;
- aucun tri utilisateur.

### L.5 États UI minimaux indispensables

Statut : `OK`

Justification :

- `loading` ;
- `success` avec liste ;
- `success` avec liste vide ;
- `error`.

## M. Commandes réellement exécutées

### M.1 Audit / lecture / recherche

Audit réalisé majoritairement via lectures directes et recherches ciblées sur :

- `packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/application/services/pokemon_database_index.dart`
- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart`
- `packages/map_editor/test/list_pokedex_entries_use_case_test.dart`

Recherches ciblées utilisées :

- `FutureBuilder<|AsyncValue|CircularProgressIndicator|ProgressCircle|No project loaded|Error|empty|Aucun|Load a project|Failed to|throwsA`
- `FutureBuilder<|AsyncValue|ProgressCircle|loading|errorMessage|statusMessage`
- `ListPokedexEntriesUseCase|PokedexListEntry`
- `Directory.current|monorepo root|workspace project|not Directory.current`
- `PokemonDatabaseIndexEntry\(`
- `pokedex-placeholder-workspace|PokedexPlaceholderWorkspace|PokedexWorkspace`

### M.2 Format

```sh
dart format "packages/map_editor/lib/src/application/models/pokemon_database_index.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart" "packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart" "packages/map_editor/lib/src/features/editor/state/editor_state.dart" "packages/map_editor/lib/src/features/editor/state/editor_notifier.dart" "packages/map_editor/lib/src/ui/editor_shell_page.dart" "packages/map_editor/lib/src/ui/shared/top_toolbar.dart" "packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart" "packages/map_editor/test/pokedex_placeholder_ui_test.dart" "packages/map_editor/test/pokemon_database_index_test.dart"
```

Puis plusieurs relances ciblées de :

```sh
dart format "test/pokedex_placeholder_ui_test.dart"
```

### M.3 Tests

Commandes réellement exécutées :

```sh
flutter test test/pokedex_placeholder_ui_test.dart --plain-name "ProjectExplorerPanel shows a Pokédex entry tile"
```

```sh
flutter test test/pokedex_placeholder_ui_test.dart
```

```sh
flutter test test/pokemon_database_index_test.dart
```

Des tentatives intermédiaires plus larges ont aussi été exécutées pendant le débogage des tests :

```sh
flutter test test/pokedex_placeholder_ui_test.dart test/pokemon_database_index_test.dart
```

```sh
flutter test test/pokedex_placeholder_ui_test.dart --plain-name "loads and displays the simple species list from local project data"
```

```sh
flutter test test/pokedex_placeholder_ui_test.dart --plain-name "shows an empty state when no species files are present"
```

```sh
flutter test test/pokedex_placeholder_ui_test.dart --plain-name "shows an error state when species loading fails"
```

### M.4 Analyse

```sh
flutter analyze lib/src/application/models/pokemon_database_index.dart lib/src/ui/canvas/pokedex_placeholder_workspace.dart lib/src/ui/canvas/editor_canvas_host.dart lib/src/features/editor/state/editor_state.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/editor_shell_page.dart lib/src/ui/shared/top_toolbar.dart lib/src/ui/panels/project_explorer_panel.dart test/pokedex_placeholder_ui_test.dart test/pokemon_database_index_test.dart
```

### M.5 Git lecture seule

```sh
git status --short
```

```sh
git diff --stat
```

## N. Résultats réels

### N.1 Format

Résultat :

- format exécuté avec succès ;
- fichiers touchés correctement formatés.

### N.2 Tests widget Pokédex

Résultat final :

```text
+5: All tests passed!
```

Tests couverts :

- présence de la tuile Pokédex ;
- rendu de la liste simple ;
- loading ;
- vide ;
- erreur.

### N.3 Tests du pipeline réutilisé

Résultat final :

```text
+10: All tests passed!
```

Points couverts explicitement :

- `PokemonSpeciesIndexEntry.fromJson` garde son contrat historique ;
- index minimal ;
- erreurs explicites ;
- lecture depuis le workspace et pas `Directory.current` ;
- non-mutation de `project.json` ;
- pas de lecture learnsets/evolutions/media ;
- ajout de `types` disponible pour la UI.

### N.4 Analyse ciblée

Résultat final :

```text
No issues found! (ran in 3.2s)
```

### N.5 Incident outil rencontré pendant la validation

Observation honnête :

- une tentative de commande enchaînée `flutter test ... && flutter test ...` a déclenché un crash outil Flutter lié au dossier `macos/Flutter/ephemeral/...`;
- ce crash ne provenait pas du code du lot 13 mais du tooling local ;
- les tests ciblés relancés séparément ensuite ont tous passé ;
- l'analyse ciblée relancée ensuite a aussi passé.

## O. État Git

### O.1 `git status --short`

```text
M packages/map_editor/lib/src/application/models/pokemon_database_index.dart
M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
M packages/map_editor/lib/src/features/editor/state/editor_state.dart
M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
M packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart
M packages/map_editor/lib/src/ui/editor_shell_page.dart
M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
M packages/map_editor/test/pokedex_placeholder_ui_test.dart
M packages/map_editor/test/pokemon_database_index_test.dart
```

### O.2 `git diff --stat`

```text
.../application/models/pokemon_database_index.dart |  14 +
.../src/features/editor/state/editor_notifier.dart |  14 +-
.../src/features/editor/state/editor_state.dart    |  12 +-
.../lib/src/ui/canvas/editor_canvas_host.dart      |   7 +-
.../ui/canvas/pokedex_placeholder_workspace.dart   | 616 ++++++++++++++++++---
.../map_editor/lib/src/ui/editor_shell_page.dart   |  15 +-
.../lib/src/ui/panels/project_explorer_panel.dart  |  12 +-
.../map_editor/lib/src/ui/shared/top_toolbar.dart  |  14 +-
.../test/pokedex_placeholder_ui_test.dart          | 221 ++++++--
.../test/pokemon_database_index_test.dart          |  36 +-
10 files changed, 784 insertions(+), 177 deletions(-)
```

### O.3 Lecture honnête du diff

Le diff est local au périmètre demandé, mais il est mécaniquement dominé par un fichier :

- `pokedex_placeholder_workspace.dart` concentre l'essentiel du volume car le placeholder lot 12 a été remplacé par le vrai workspace du lot 13 ;
- le reste des fichiers ne contient que des ajustements d'intégration, de texte ou de tests ;
- aucun chantier transversal hors périmètre n'a été ouvert.

## P. Limites restantes

Ce qui relève toujours explicitement des lots suivants :

- recherche ;
- filtres ;
- tri configurable ;
- fiche détail espèce ;
- sélection de ligne ouvrant un détail ;
- édition ;
- import manuel ;
- affichage learnsets ;
- affichage évolutions ;
- affichage médias ;
- panneau d'inspection Pokédex dédié ;
- outils de maintenance Pokédex ;
- validation métier avancée.

Ce qu'il ne faut pas faire maintenant :

- ajouter un provider/notifier Pokédex dédié sans besoin métier clair ;
- enrichir les lignes avec des champs supplémentaires ;
- transformer cette liste en pseudo-tableau riche ;
- introduire des actions ligne par ligne ;
- mélanger la UI du lot 13 avec les responsabilités des lots 14+.

## Q. Bundle de review

Aucun bundle de review séparé n'a été généré.

## R. Conclusion honnête

Le lot 13 est livré comme une première UI Pokédex réellement utile mais volontairement minimale :

- la tuile Pokédex existante ouvre maintenant une liste simple ;
- la liste est alimentée via les données locales du projet réutilisant le pipeline du lot 11 ;
- seuls `numéro`, `nom`, `id`, `types` sont affichés ;
- les états `loading`, `vide`, `erreur`, `succès` sont gérés ;
- aucun glissement vers une fiche détail, une édition, une recherche ou des filtres n'a été introduit.

Le principal compromis assumé est le suivant :

- `PokemonDatabaseIndexEntry` a été enrichi de `types` ;
- cet élargissement reste strictement justifié par le lot 13 ;
- il évite un pipeline parallèle plus large et reste compatible avec la discipline de scope demandée.

## S. Checklist d’autocontrôle

### S.1 Scope

- [x] J’ai bien implémenté uniquement le lot 13
- [x] Je n’ai pas commencé le lot 14
- [x] Je n’ai pas commencé le lot 15
- [x] Je n’ai pas commencé le lot 16
- [x] Je n’ai ajouté aucune recherche
- [x] Je n’ai ajouté aucun filtre
- [x] Je n’ai ajouté aucune édition
- [x] Je n’ai ajouté aucune vue détail
- [x] Je n’ai ajouté aucun import
- [x] Je n’ai ajouté aucune logique learnset/evolution/media dans la UI
- [x] Je n’ai pas modifié `project.json`
- [x] Je n’ai pas modifié le runtime
- [x] Je n’ai pas modifié la sauvegarde

### S.2 Architecture

- [x] J’ai audité l’existant avant de coder
- [x] J’ai réutilisé le lot 11 au lieu de recréer un pipeline
- [x] J’ai réutilisé le point d’entrée du lot 12
- [x] Je n’ai pas introduit de nouvelle abstraction spéculative
- [x] Le diff reste local et limité

### S.3 UI

- [x] La liste affiche bien `numéro / nom / id / types`
- [x] L’état `loading` existe
- [x] L’état `vide` existe
- [x] L’état `erreur` existe
- [x] La vue reste simple et lisible
- [x] Il n’y a aucun faux bouton ou fausse feature

### S.4 Qualité

- [x] Les tests ciblés passent
- [x] L’analyse ciblée passe
- [x] Le code est formaté
- [x] Le rapport markdown a été créé
- [x] Le rapport contient le code et ses explications

### S.5 Honnêteté

- [x] Je n’ai pas survendu le résultat
- [x] J’ai documenté clairement ce qui relève du lot 14+
- [x] J’ai signalé les limites restantes
- [x] Je n’ai exécuté aucune commande Git d’écriture
