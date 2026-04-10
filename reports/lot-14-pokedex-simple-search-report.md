# Lot 14 - Recherche texte simple Pokédex

## A. Résumé exécutif

Le lot 14 a été implémenté strictement comme un raffinement UI local du lot 13.

Ce qui a été ajouté :

- un champ de recherche texte visible au-dessus de la liste Pokédex ;
- un filtrage instantané en mémoire sur la liste déjà chargée ;
- un matching simple sur :
  - `primaryName`
  - `id`
  - `nationalDex`
- un état distinct `aucun résultat` quand la recherche ne matche aucune entrée.

Ce qui n'a pas été ajouté :

- aucun filtre complexe ;
- aucun tri utilisateur ;
- aucun détail ;
- aucune édition ;
- aucun import ;
- aucun provider/notifier/state Pokédex dédié ;
- aucun pipeline parallèle de lecture.

## B. Objectif exact

Objectif produit du lot 14 :

- rendre la liste du lot 13 exploitable avec une recherche texte simple ;
- garder un comportement instantané, lisible et prévisible ;
- rester sur une liste lecture seule ;
- ne pas faire apparaître de logique des lots 15+.

## C. Audit de l’existant

### C.1 Structure lot 13 déjà en place

Structure UI existante auditée :

- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`

Constat :

- le chargement local était déjà correctement isolé ;
- le widget principal possédait déjà un stateful body local ;
- la liste finale était déjà rendue dans une vue dédiée ;
- les états `loading / empty / error / success` étaient déjà présents.

Conclusion :

- le bon point d’intégration pour la recherche était le state local du workspace ;
- il n’y avait aucune raison de toucher aux services applicatifs ;
- il n’y avait aucune raison de modifier le loader pour implémenter la recherche.

### C.2 Pipeline de lecture déjà suffisant

Le lot 13 fournit déjà :

- une liste d’entrées chargée une fois ;
- `id`, `nationalDex`, `primaryName`, `types` ;
- un ordre déjà établi par le pipeline existant.

Conclusion :

- le lot 14 devait filtrer la liste déjà chargée, en mémoire ;
- aucune relecture disque par frappe n’était justifiée ;
- aucun nouveau FutureBuilder de recherche n’était justifié.

### C.3 Fichiers volontairement non touchés

Aucun besoin n’a été trouvé pour modifier :

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

## D. Décisions d’architecture

### D.1 Recherche strictement locale au workspace

Décision retenue :

- stocker la query dans l’état local de `_PokedexWorkspaceBodyState`.

Pourquoi :

- c’est un raffinement purement UI ;
- on évite un provider/notifier/state Pokédex dédié ;
- on reste dans le plus petit changement cohérent.

### D.2 Filtrage sur la liste déjà chargée

Décision retenue :

- filtrer localement la liste `entries` déjà résolue par le `FutureBuilder`.

Pourquoi :

- aucun aller-retour disque à chaque frappe ;
- aucun appel repository/service supplémentaire ;
- aucun comportement asynchrone parasite ;
- comportement instantané et prévisible.

### D.3 Matching dex exact

Décision retenue :

- si la query normalisée dex est strictement numérique, alors comparer exactement :
  - `entry.nationalDex.toString()`
  - `entry.nationalDex.toString().padLeft(4, '0')`

Pourquoi :

- `1` ne doit pas matcher `10`, `11`, `21` ;
- le comportement reste simple, lisible et stable.

### D.4 État `aucun résultat` distinct

Décision retenue :

- garder deux états séparés :
  - `aucune espèce importée`
  - `aucun résultat`

Pourquoi :

- ce ne sont pas le même signal produit ;
- un projet vide ne doit pas être confondu avec une recherche trop restrictive ;
- on garde une UX honnête et non ambiguë.

### D.5 Champ visible même sans résultat

Décision retenue :

- quand la recherche ne matche rien, le champ reste visible.

Pourquoi :

- l’utilisateur peut corriger la query immédiatement ;
- on évite un état frustrant où le champ disparaît au moment où il est nécessaire.

## E. Périmètre inclus

- champ de recherche simple dans le workspace Pokédex ;
- filtrage local en mémoire ;
- matching par nom ;
- matching par id ;
- matching dex exact ;
- query vide = liste complète ;
- état `aucun résultat` distinct ;
- tests ciblés du lot 14 ;
- commentaires de cadrage dans le code ;
- rapport complet.

## F. Périmètre exclu

- filtre par type ;
- filtre par génération ;
- tri utilisateur ;
- fiche détail ;
- clic ligne -> détail ;
- édition ;
- import ;
- toolbar riche ;
- pagination ;
- cache global ;
- watcher fichier ;
- provider Pokédex ;
- notifier Pokédex ;
- state object Pokédex ;
- nouvelle couche application ;
- modification de `project.json` ;
- changement runtime ;
- changement sauvegarde ;
- changement import externe.

## G. Liste exacte des fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`

## H. Justification fichier par fichier

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`

Pourquoi touché :

- c’est le bon endroit pour stocker la query locale ;
- c’est l’endroit naturel pour filtrer la liste déjà chargée ;
- c’est l’endroit où distinguer `empty` et `no results`.

Pourquoi cela reste dans le lot 14 :

- state local uniquement ;
- aucun nouveau système de gestion d’état ;
- aucun appel disque supplémentaire.

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`

Pourquoi touché :

- pour ajouter le champ de recherche ;
- pour ajouter l’état `aucun résultat` ;
- pour garder la vue de liste compatible avec une liste déjà filtrée.

Pourquoi cela reste dans le lot 14 :

- uniquement de la présentation et de l’interaction UI locale ;
- aucune feature hors scope.

### `packages/map_editor/test/pokedex_workspace_ui_test.dart`

Pourquoi touché :

- pour couvrir les comportements demandés du lot 14 ;
- pour verrouiller le matching par nom, id, dex, query vide et état sans résultat.

Pourquoi cela reste dans le lot 14 :

- tests ciblés, proportionnés et orientés comportement réel ;
- aucune régression vers une logique de lot 15+.

## I. Code produit et explication

### I.1 État de query local

```dart
class _PokedexWorkspaceBodyState extends State<_PokedexWorkspaceBody> {
  late Future<List<PokemonDatabaseIndexEntry>> _entriesFuture;
  String _searchQuery = '';
```

Explication :

- la query reste locale au workspace ;
- aucun provider/notifier Pokédex n’est ajouté ;
- c’est strictement suffisant pour le lot 14.

### I.2 Filtrage local en mémoire

```dart
final filteredEntries = _filterEntries(entries, _searchQuery);
```

Explication :

- `entries` vient du lot 13 ;
- la recherche se fait après chargement, en mémoire ;
- aucune relecture disque à chaque frappe.

### I.3 Règle dex exacte

```dart
final normalizedDexQuery = _normalizeDexQuery(normalizedQuery);
final hasExactDexQuery = RegExp(r'^\d+$').hasMatch(normalizedDexQuery);

final matchesDex = hasExactDexQuery && _matchesExactDexQuery(
  entry: entry,
  normalizedDexQuery: normalizedDexQuery,
);
```

Puis :

```dart
bool _matchesExactDexQuery({
  required PokemonDatabaseIndexEntry entry,
  required String normalizedDexQuery,
}) {
  final rawDex = entry.nationalDex.toString();
  final paddedDex = entry.nationalDex.toString().padLeft(4, '0');
  return normalizedDexQuery == rawDex || normalizedDexQuery == paddedDex;
}
```

Explication :

- `1`, `0001`, `#1`, `#0001` sont acceptés ;
- le matching dex est exact, jamais `contains` ;
- on évite les faux positifs numériques.

### I.4 Champ de recherche

```dart
_PokedexSearchField(
  query: query,
  onChanged: onQueryChanged,
),
```

Extrait de configuration :

```dart
CupertinoTextField.borderless(
  key: const Key('pokedex-search-field'),
  controller: _controller,
  onChanged: widget.onChanged,
  clearButtonMode: OverlayVisibilityMode.editing,
  placeholder: 'Rechercher par nom, id ou numéro dex',
  padding: EdgeInsets.zero,
)
```

Explication :

- composant sobre et cohérent avec l’éditeur ;
- pas de toolbar riche ;
- pas de panneau de filtres ;
- placeholder explicite conforme à la demande.

### I.5 État `aucun résultat`

```dart
class PokedexWorkspaceNoResultsState extends StatelessWidget {
  const PokedexWorkspaceNoResultsState({
    super.key,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim();
    final suffix = normalizedQuery.isEmpty
        ? ''
        : '\nRecherche actuelle : "$normalizedQuery".';

    return PokedexWorkspaceStateCard(
      key: const Key('pokedex-no-results-state'),
      title: 'Pokédex',
      message: 'Aucun résultat pour cette recherche.$suffix',
    );
  }
}
```

Explication :

- état distinct de `pokedex-empty-state` ;
- sobre ;
- ni erreur, ni faux vide projet.

## J. Tests ajoutés / adaptés

Tests explicitement couverts dans `packages/map_editor/test/pokedex_workspace_ui_test.dart` :

- affichage du champ de recherche ;
- filtre instantané par nom ;
- filtre instantané par id ;
- filtre instantané par numéro dex ;
- query vide = liste complète ;
- recherche sans résultat = état dédié ;
- absence de glissement vers les lots suivants.

Assertions explicites conservées/ajoutées :

- pas de texte `Filter`
- pas de texte `Edit`
- pas de texte `Delete`
- plus de recherche locale visible
- aucun détail ou import n’introduit.

## K. Commandes réellement exécutées

### K.1 Format

Commande demandée exécutée :

```sh
dart format "packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart" "packages/map_editor/test/pokedex_workspace_ui_test.dart"
```

Elle a été relancée plusieurs fois après corrections locales.

### K.2 Tests

Commande demandée exécutée :

```sh
cd packages/map_editor && flutter test test/pokedex_workspace_ui_test.dart
```

### K.3 Analyse

Commande demandée exécutée :

```sh
cd packages/map_editor && flutter analyze lib/src/ui/canvas/pokedex_workspace.dart lib/src/ui/canvas/pokedex_workspace_views.dart test/pokedex_workspace_ui_test.dart
```

### K.4 Contrôle git lecture seule

Commandes exécutées :

```sh
git status --short
```

```sh
git diff --stat
```

### K.5 Contrôle lints IDE

Contrôle exécuté via `ReadLints` sur :

- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`

## L. Résultats réels

### L.1 Format

Résultat réel final :

```text
Formatted 3 files (0 changed) in 0.01 seconds.
```

### L.2 Tests UI

Résultat réel final :

```text
+12: All tests passed!
```

### L.3 Analyse ciblée

Résultat réel final :

```text
No issues found! (ran in 3.3s)
```

### L.4 ReadLints

Résultat réel :

```text
No linter errors found.
```

### L.5 Échecs intermédiaires rencontrés et corrigés

#### Échec 1

Problème :

- ambiguïté sur `OverlayVisibilityMode` entre Flutter et `macos_ui`.

Message réel observé :

```text
Error: 'OverlayVisibilityMode' is imported from both ...
```

Correction :

- import `macos_ui` réduit à `show MacosIcon, ProgressCircle`.

#### Échec 2

Problème :

- tentative erronée avec `CupertinoOverlayVisibilityMode`, symbole non défini.

Message réel observé :

```text
Undefined name 'CupertinoOverlayVisibilityMode'
```

Correction :

- retour à `OverlayVisibilityMode.editing` après nettoyage de l’import ambigu.

#### Échec 3

Problème :

- test `no results` initialement trop strict sur un texte exact alors que le
  message complet incluait aussi la query.

Correction :

- passage à `find.textContaining('Aucun résultat pour cette recherche.')`.

## M. État git utile

Commande :

```sh
git status --short && git diff --stat
```

Résultat réel sur les fichiers du lot 14 :

```text
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
 M packages/map_editor/test/pokedex_workspace_ui_test.dart
 .../lib/src/ui/canvas/pokedex_workspace.dart       |  90 +++++-
 .../lib/src/ui/canvas/pokedex_workspace_views.dart | 146 +++++++++-
 .../map_editor/test/pokedex_workspace_ui_test.dart | 314 +++++++++++++++++++++
 3 files changed, 539 insertions(+), 11 deletions(-)
```

Lecture honnête :

- le diff est local au périmètre autorisé ;
- aucun fichier hors périmètre n’a été touché ;
- le volume visible côté test est important parce que la couverture demandée du lot 14 a été ajoutée de manière explicite.

## N. Limites restantes

Ce qui relève toujours des lots suivants :

- filtres par type ;
- filtres par génération ;
- tri utilisateur ;
- détail espèce ;
- sélection de ligne ouvrant une fiche ;
- édition ;
- import ;
- actions de masse ;
- toolbar avancée ;
- pagination ;
- cache plus riche.

## O. Conclusion honnête

Le lot 14 est livré comme une extension locale, propre et strictement cadrée du lot 13 :

- recherche texte visible ;
- filtrage instantané sur la liste déjà chargée ;
- matching par nom, id et numéro dex ;
- règle dex exacte ;
- état `aucun résultat` distinct ;
- aucune feature supplémentaire.

Je n’ai pas touché aux services, aux repositories, au runtime, à la sauvegarde ni à `project.json`.

## P. Checklist d’autocontrôle finale

### Scope

- [x] J’ai implémenté uniquement le lot 14
- [x] Je n’ai pas commencé le lot 15
- [x] Je n’ai pas commencé le lot 16
- [x] Je n’ai ajouté ni filtre complexe, ni tri utilisateur, ni détail, ni édition, ni import
- [x] Je n’ai pas modifié `project.json`
- [x] Je n’ai pas modifié le runtime
- [x] Je n’ai pas modifié la sauvegarde

### Architecture

- [x] J’ai réutilisé la structure actuelle du lot 13
- [x] Je n’ai pas créé de provider/notifier/state Pokédex dédié
- [x] Je n’ai pas recréé un pipeline parallèle de lecture
- [x] Le filtrage se fait localement sur la liste déjà chargée
- [x] Le matching dex est exact et prévisible
- [x] “Aucun résultat” est distinct de “aucune espèce importée”

### UI

- [x] Le champ de recherche est visible
- [x] La recherche par nom fonctionne
- [x] La recherche par id fonctionne
- [x] La recherche par numéro dex fonctionne
- [x] Le filtre est instantané
- [x] La query vide restaure la liste complète
- [x] L’écran reste sobre et lecture seule
- [x] Aucune fausse feature des lots suivants n’a été ajoutée

### Qualité

- [x] Le code est formaté
- [x] Les tests ciblés passent
- [x] L’analyse ciblée passe
- [x] Le rapport markdown a été créé
- [x] Le rapport contient les résultats réels
- [x] Je n’ai exécuté aucune commande Git d’écriture
