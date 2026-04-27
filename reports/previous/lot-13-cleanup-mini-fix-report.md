# Lot 13 - Mini-fix de nettoyage

## 1. Résumé exécutif

Ce mini-fix ne change pas le comportement produit du lot 13.

Il corrige uniquement une dette de propreté réelle :

- les noms de fichiers ne mentent plus ;
- le widget public `PokedexWorkspace` est beaucoup plus lisible ;
- la composition de chargement par défaut a été sortie du widget UI principal ;
- le comportement `species dir absent => état vide` n'est plus piloté par un `contains(...)` sur un message d'erreur ;
- le couplage direct du widget principal à l'infrastructure a été réduit sans introduire de nouvelle architecture lourde.

Le comportement produit conservé strictement :

- liste simple lecture seule ;
- colonnes `numéro / nom / id / types` ;
- états `loading / vide / erreur / succès` ;
- aucune recherche ;
- aucun filtre ;
- aucun tri utilisateur ;
- aucun détail ;
- aucune édition ;
- aucun import.

## 2. Problèmes exacts avant mini-fix

### 2.1 Nom de fichier mensonger

Le fichier `packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart` ne correspondait plus du tout à son rôle réel.

Problème :

- ce n'était plus un placeholder ;
- le lot 13 avait déjà livré une vraie vue de liste ;
- garder le mot `placeholder` rendait la review et la maintenance trompeuses.

Même problème côté test :

- `packages/map_editor/test/pokedex_placeholder_ui_test.dart`

### 2.2 Fichier UI principal trop gros

Le fichier mélangeait :

- le widget public ;
- la logique de composition des futures ;
- la logique de chargement par défaut ;
- la décision produit "species absent => vide" ;
- tous les widgets de présentation de liste et d'états.

Conséquence :

- lecture moins claire ;
- responsabilité trop concentrée ;
- coût de review inutilement élevé.

### 2.3 Logique fragile pilotée par message d'erreur

Le comportement `species absent => vide` reposait sur :

```dart
if (error.message.contains('Pokemon species directory')) {
  return const <PokemonDatabaseIndexEntry>[];
}
```

Problèmes :

- dépendance au wording texte d'une exception ;
- couplage implicite fragile ;
- moins lisible qu'un pré-contrôle explicite du dossier.

### 2.4 Couplage direct UI -> infra

Le widget UI principal instanciait directement :

- `FileProjectRepository`
- `FilePokemonReadRepository`
- `PokemonDatabaseIndex`
- `ProjectFileSystem`

Ce n'était pas catastrophique, mais trop collé au widget principal pour un écran aussi simple.

## 3. Objectif exact du mini-fix

Corriger la dette de propreté sans changer le scope produit du lot 13.

En pratique :

- renommer honnêtement les fichiers ;
- alléger significativement le fichier principal ;
- sortir la composition de chargement par défaut du widget principal ;
- remplacer la logique `contains(...)` par une décision explicite et robuste ;
- garder le diff local, minimal et reviewable ;
- ne toucher à rien d'autre si ce n'est pas strictement nécessaire.

## 4. Décisions retenues

### 4.1 Renommage honnête

Renommages réalisés :

- `packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart`
  -> `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
- `packages/map_editor/test/pokedex_placeholder_ui_test.dart`
  -> `packages/map_editor/test/pokedex_workspace_ui_test.dart`

### 4.2 Séparation locale en trois fichiers

Au lieu d'un gros fichier unique, le mini-fix découpe localement la surface Pokédex en trois fichiers :

- `pokedex_workspace.dart`
  - widget public lisible ;
  - composition des états UI ;
  - aucune instanciation infra directe.
- `pokedex_workspace_loader.dart`
  - composition de chargement par défaut ;
  - pré-contrôle explicite du dossier `species` ;
  - réutilisation du service applicatif existant.
- `pokedex_workspace_views.dart`
  - widgets de présentation ;
  - liste, lignes, état loading, état erreur, carte d'état.

Pourquoi c'est le bon compromis :

- plus propre ;
- plus reviewable ;
- toujours local ;
- pas de nouvelle architecture globale ;
- pas de provider/notifier Pokédex dédié ;
- pas de mini-framework.

### 4.3 Pré-contrôle explicite du dossier `species`

Le comportement `species absent => vide` est désormais décidé avant l'appel au service, dans le loader local :

```dart
final project = await projectRepository.loadProject(workspace.projectManifestPath);
final speciesDirectoryRelativePath = project.pokemon.speciesDir.trim();

if (speciesDirectoryRelativePath.isNotEmpty) {
  final speciesDirectoryPath = workspace.resolveProjectRelativePath(
    speciesDirectoryRelativePath,
  );
  if (!await Directory(speciesDirectoryPath).exists()) {
    return const <PokemonDatabaseIndexEntry>[];
  }
}
```

Pourquoi c'est mieux :

- plus robuste ;
- explicite ;
- indépendant du wording texte d'une exception ;
- ne change pas le contrat du service du lot 11 ;
- ne transforme pas l'infrastructure en système plus lourd.

### 4.4 Réduction du couplage direct du widget principal à l'infra

Le widget `PokedexWorkspace` n'instancie plus directement :

- `FileProjectRepository`
- `FilePokemonReadRepository`
- `PokemonDatabaseIndex`

Le widget principal dépend désormais d'un `loader` :

```dart
class PokedexWorkspace extends ConsumerWidget {
  const PokedexWorkspace({
    super.key,
    this.loader = loadPokedexEntriesForWorkspace,
  });

  final PokedexEntryLoader loader;
}
```

Pourquoi c'est mieux :

- le widget public est plus lisible ;
- la composition concrète existe toujours, mais hors du widget principal ;
- les tests conservent une injection locale simple ;
- aucune couche d'injection globale n'a été ajoutée.

## 5. Ce qui a été changé

### 5.1 Nouveau fichier principal UI

`packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`

Contient maintenant :

- le widget public `PokedexWorkspace` ;
- un body stateful très petit ;
- la composition des quatre états UI.

Extrait :

```dart
class PokedexWorkspace extends ConsumerWidget {
  const PokedexWorkspace({
    super.key,
    this.loader = loadPokedexEntriesForWorkspace,
  });

  final PokedexEntryLoader loader;

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

### 5.2 Nouveau loader local

`packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`

Rôle :

- centraliser la composition par défaut ;
- garder la logique locale au périmètre Pokédex ;
- faire le pré-contrôle explicite du dossier `species`.

Extrait :

```dart
Future<List<PokemonDatabaseIndexEntry>> loadPokedexEntriesForWorkspace(
  ProjectWorkspace workspace,
) async {
  final projectRepository = FileProjectRepository();
  const pokemonReadRepository = FilePokemonReadRepository();
  final project = await projectRepository.loadProject(workspace.projectManifestPath);
  final speciesDirectoryRelativePath = project.pokemon.speciesDir.trim();

  if (speciesDirectoryRelativePath.isNotEmpty) {
    final speciesDirectoryPath = workspace.resolveProjectRelativePath(
      speciesDirectoryRelativePath,
    );
    if (!await Directory(speciesDirectoryPath).exists()) {
      return const <PokemonDatabaseIndexEntry>[];
    }
  }

  final service = PokemonDatabaseIndex(
    projectRepository: projectRepository,
    pokemonReadRepository: pokemonReadRepository,
  );
  return service.build(workspace);
}
```

### 5.3 Vues extraites

`packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`

Rôle :

- sortir le bruit visuel du fichier principal ;
- garder les widgets de présentation simples ;
- ne rien ajouter au scope.

Widgets extraits :

- `PokedexWorkspaceLoadingState`
- `PokedexWorkspaceErrorState`
- `PokedexWorkspaceSpeciesList`
- `PokedexWorkspaceStateCard`
- `PokedexWorkspaceStateFrame`

### 5.4 Import mis à jour

`packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`

Changement strictement nécessaire :

- import du nouveau fichier `pokedex_workspace.dart`.

### 5.5 Test renommé et adapté

`packages/map_editor/test/pokedex_workspace_ui_test.dart`

Changements :

- import du nouveau fichier UI ;
- même couverture utile du lot 13 ;
- ajout d'un test ciblé sur `species dir absent => vide` via le loader.

Extrait du test ciblé :

```dart
test(
  'returns an empty list when the configured species directory does not exist yet',
  () async {
    final tempProjectRoot =
        await Directory.systemTemp.createTemp('pokedex_loader_test_');
    try {
      final workspace = ProjectFileSystem(tempProjectRoot.path);
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );

      await createProjectUseCase.execute(
        'Pokedex Loader Project',
        tempProjectRoot.path,
      );

      final entries = await loadPokedexEntriesForWorkspace(workspace);
      expect(entries, isEmpty);
    } finally {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    }
  },
);
```

## 6. Ce qui n'a volontairement PAS été changé

Je n'ai volontairement pas rouvert les fichiers suivants pour ce mini-fix, sauf impact strict du renommage/import :

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/application/services/pokemon_database_index.dart`
- `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/lib/src/application/models/pokemon_database_index.dart`

Pourquoi :

- le mini-fix demandé était un nettoyage local du lot 13 ;
- rouvrir ces fichiers aurait créé du churn hors sujet ;
- le problème principal n'était ni dans le service applicatif du lot 11, ni dans l'UI shell, mais dans le nommage et la structure locale du workspace Pokédex.

## 7. Pourquoi c'est mieux sans changer le scope produit

### 7.1 Noms de fichiers honnêtes

Le nom reflète enfin le rôle réel :

- `pokedex_workspace.dart`
- `pokedex_workspace_ui_test.dart`

### 7.2 Widget principal plus lisible

Le widget principal n'est plus un bloc monolithique mêlant :

- infrastructure ;
- état ;
- rendu ;
- gestion d'erreur ;
- widgets de présentation.

### 7.3 Logique absente du dossier `species` plus robuste

On n'attend plus une erreur pour ensuite interpréter son texte.

On décide explicitement :

- si le dossier n'existe pas encore ;
- alors on rend un état vide.

### 7.4 Couplage réduit sans architecture lourde

Le chargement par défaut est déplacé, mais reste local.

Il n'y a toujours :

- ni provider Pokédex dédié ;
- ni notifier Pokédex dédié ;
- ni état Pokédex dédié ;
- ni framework supplémentaire.

### 7.5 Comportement produit inchangé

La UI finale reste strictement celle du lot 13 :

- simple ;
- lecture seule ;
- sans détail ;
- sans action ;
- sans recherche ;
- sans filtre ;
- sans préparation cachée du lot 14.

## 8. Fichiers modifiés par ce mini-fix

### 8.1 Modifiés

- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`

### 8.2 Supprimés

- `packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart`
- `packages/map_editor/test/pokedex_placeholder_ui_test.dart`

### 8.3 Créés

- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `reports/lot-13-cleanup-mini-fix-report.md`

## 9. Commandes réellement exécutées

### 9.1 Audit / recherche

Recherches et lectures ciblées sur :

- `packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart`
- `packages/map_editor/test/pokedex_placeholder_ui_test.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/application/models/pokemon_database_index.dart`

Recherches exactes utilisées :

```sh
rg "pokedex_placeholder_workspace|pokedex_placeholder_ui_test|PokedexWorkspace|PokedexPlaceholderWorkspace" packages/map_editor
```

```sh
rg "message\.contains\('Pokemon species directory'\)|contains\('Pokemon species directory'\)" packages/map_editor
```

```sh
rg "PokedexWorkspace\(|loadPokedexEntriesForWorkspace|PokedexWorkspaceSpeciesList|PokedexWorkspaceLoadingState" packages/map_editor
```

```sh
rg "speciesDir|pokemon\.speciesDir|ProjectManifest\(|pokemon:" packages/map_editor/test
```

### 9.2 Format

```sh
dart format "packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart" "packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart" "packages/map_editor/test/pokedex_workspace_ui_test.dart"
```

Puis relance ciblée :

```sh
dart format "lib/src/ui/canvas/pokedex_workspace_loader.dart"
```

### 9.3 Tests

```sh
flutter test test/pokedex_workspace_ui_test.dart
```

```sh
flutter test test/pokemon_database_index_test.dart
```

### 9.4 Analyse

```sh
flutter analyze lib/src/ui/canvas/pokedex_workspace.dart lib/src/ui/canvas/pokedex_workspace_loader.dart lib/src/ui/canvas/pokedex_workspace_views.dart lib/src/ui/canvas/editor_canvas_host.dart test/pokedex_workspace_ui_test.dart test/pokemon_database_index_test.dart
```

### 9.5 Git lecture seule

```sh
git status --short
```

```sh
git diff --stat
```

```sh
git diff --stat -- "packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart" "packages/map_editor/test/pokedex_workspace_ui_test.dart" "packages/map_editor/test/pokedex_placeholder_ui_test.dart"
```

```sh
git status --short -- "packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart" "packages/map_editor/test/pokedex_workspace_ui_test.dart" "packages/map_editor/test/pokedex_placeholder_ui_test.dart"
```

### 9.6 Contrôle lints IDE

Contrôle réalisé via `ReadLints` sur les fichiers touchés.

## 10. Résultats réels

### 10.1 Tests UI du mini-fix

Commande :

```sh
flutter test test/pokedex_workspace_ui_test.dart
```

Résultat réel :

```text
+6: All tests passed!
```

Points couverts :

- présence de l'entrée Pokédex ;
- rendu de la liste simple ;
- loading ;
- empty ;
- error ;
- comportement `species dir absent => vide`.

### 10.2 Test du pipeline impacté

Commande :

```sh
flutter test test/pokemon_database_index_test.dart
```

Résultat réel :

```text
+10: All tests passed!
```

### 10.3 Analyse ciblée

Commande :

```sh
flutter analyze lib/src/ui/canvas/pokedex_workspace.dart lib/src/ui/canvas/pokedex_workspace_loader.dart lib/src/ui/canvas/pokedex_workspace_views.dart lib/src/ui/canvas/editor_canvas_host.dart test/pokedex_workspace_ui_test.dart test/pokemon_database_index_test.dart
```

Résultat réel :

```text
No issues found! (ran in 1.5s)
```

### 10.4 ReadLints

Résultat réel :

```text
No linter errors found.
```

### 10.5 Incident de tooling rencontré

Pendant une tentative de validation parallèle, Flutter a rencontré un conflit sur le dossier :

- `packages/map_editor/macos/Flutter/ephemeral/Packages/.packages`

Conséquence :

- les commandes Flutter parallèles ont été relancées séquentiellement ;
- les résultats finaux retenus dans ce rapport sont bien ceux des relances séquentielles réussies.

## 11. État git utile

### 11.1 État global actuel du worktree

Commande :

```sh
git status --short
```

Résultat réel observé à la fin :

```text
 M packages/map_editor/lib/src/application/models/pokemon_database_index.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_state.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 D packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 D packages/map_editor/test/pokedex_placeholder_ui_test.dart
 M packages/map_editor/test/pokemon_database_index_test.dart
?? packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
?? packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart
?? packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
?? packages/map_editor/test/pokedex_workspace_ui_test.dart
?? reports/lot-13-pokedex-simple-list-report.md
```

Lecture honnête :

- le worktree était déjà dirty à cause du lot 13 précédent ;
- ce mini-fix n'a pas rouvert tous ces fichiers ;
- le `status` global mélange donc le lot 13 initial et ce mini-fix de nettoyage.

### 11.2 État git focalisé sur le mini-fix

Commande :

```sh
git status --short -- "packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart" "packages/map_editor/test/pokedex_workspace_ui_test.dart" "packages/map_editor/test/pokedex_placeholder_ui_test.dart"
```

Résultat réel :

```text
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 D packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart
 D packages/map_editor/test/pokedex_placeholder_ui_test.dart
?? packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
?? packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart
?? packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
?? packages/map_editor/test/pokedex_workspace_ui_test.dart
```

### 11.3 Diff stat focalisé

Commande :

```sh
git diff --stat -- "packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart" "packages/map_editor/lib/src/ui/canvas/pokedex_placeholder_workspace.dart" "packages/map_editor/test/pokedex_workspace_ui_test.dart" "packages/map_editor/test/pokedex_placeholder_ui_test.dart"
```

Résultat réel :

```text
.../lib/src/ui/canvas/editor_canvas_host.dart      |   9 +-
.../ui/canvas/pokedex_placeholder_workspace.dart   | 110 -------------------
.../test/pokedex_placeholder_ui_test.dart          | 120 ---------------------
3 files changed, 4 insertions(+), 235 deletions(-)
```

Lecture honnête :

- ce `diff --stat` ne montre pas les nouveaux fichiers non suivis ;
- il met surtout en évidence la suppression des anciens fichiers mensongers ;
- les nouveaux fichiers créés apparaissent correctement dans le `git status --short` focalisé.

## 12. Lecture honnête du diff

Ce mini-fix reste local et maîtrisé :

- un import mis à jour ;
- deux fichiers mensongers supprimés ;
- trois nouveaux fichiers UI locaux créés ;
- un test renommé et adapté.

Le changement le plus important n'est pas une nouvelle feature, mais une meilleure répartition locale :

- `workspace` ;
- `loader` ;
- `views`.

Le diff reste raisonnable et reviewable parce qu'il :

- ne touche pas au runtime ;
- ne touche pas à `project.json` ;
- ne touche pas à la sauvegarde ;
- ne rouvre pas les services applicatifs existants ;
- ne crée pas de système Pokédex global.

## 13. Pourquoi ce mini-fix ne commence pas le lot 14

Je n'ai ajouté :

- ni recherche ;
- ni filtres ;
- ni tri utilisateur ;
- ni détail ;
- ni édition ;
- ni import ;
- ni toolbar riche ;
- ni action de ligne ;
- ni provider/notifier/state Pokédex dédié.

Le mini-fix améliore uniquement :

- le nommage ;
- la lisibilité ;
- la robustesse de la décision `species absent => vide` ;
- la propreté de la composition.

## 14. Conclusion honnête

Le mini-fix atteint l'objectif demandé :

- les noms de fichiers ne mentent plus ;
- le widget principal est nettement plus lisible ;
- la composition de chargement est sortie du widget principal ;
- la logique `species dir absent => vide` n'est plus pilotée par `contains(...)` ;
- le couplage direct du widget principal à l'infrastructure a été réduit proprement ;
- aucune feature produit supplémentaire n'a été ajoutée.

Le nettoyage reste volontairement local et pragmatique.

Je n'ai pas essayé de "mieux architecturer le Pokédex" au-delà de ce qui était demandé.

## 15. Checklist d'autocontrôle finale

- [x] Je n’ai pas commencé le lot 14
- [x] Je n’ai ajouté ni recherche ni filtres ni tri utilisateur
- [x] Je n’ai ajouté ni détail ni édition ni import
- [x] J’ai renommé les fichiers mensongers
- [x] J’ai supprimé le pilotage par `contains(...)` sur un message d’erreur
- [x] J’ai réduit le couplage direct du widget principal à l’infra
- [x] Le widget principal est plus lisible qu’avant
- [x] Je n’ai pas élargi le scope architectural inutilement
- [x] Les tests ciblés passent
- [x] L’analyse ciblée passe
- [x] Je n’ai exécuté aucune commande git d’écriture
