# Lot 8b-fix — Pokemon Catalogs Navigation Correction

## A. Resume executif honnete

Le correctif est reussi.

Le lot 8b avait correctement introduit le parent produit `Catalogues Pokemon`, mais la navigation finale etait encore interpretee comme un switch interne dans le canvas central. Ce correctif remet la hierarchie attendue :

```text
Catalogues Pokemon
  Pokedex
  Moves
  Items
```

La section active vit maintenant dans `EditorState`, le `CupertinoSlidingSegmentedControl` a ete retire du canvas, et le `World Explorer` pilote directement le sous-workspace affiche.

Ce lot ne branche toujours pas de vrai catalogue `Moves` ni `Items`. Les deux restent des shells honnetes.

## B. Probleme initial

Le lot 8b affichait `Pokedex / Moves / Items` dans un `CupertinoSlidingSegmentedControl` au centre du canvas `PokemonCatalogsWorkspace`.

Cela donnait l'impression que :

- `Moves` et `Items` etaient des onglets internes du Pokédex ;
- la navigation n'etait pas pilotee par l'etat editeur ;
- la hiérarchie produit `Catalogues Pokemon -> enfants` n'etait pas respectee.

La structure attendue etait pourtant :

```text
Catalogues Pokemon
  Pokedex
  Moves
  Items
```

avec selection depuis l'explorer, pas depuis un switch local dans le canvas.

## C. Etat git initial

Commandes executees avant modification :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Sorties exactes :

```text
git status --short --untracked-files=all
?? examples/.DS_Store
```

```text
git diff --stat
<aucune sortie>
```

```text
git ls-files --others --exclude-standard
examples/.DS_Store
```

## D. Fichiers lus

- `reports/lot-8b-pokemon-catalogs-workspace-shell-report.md`
- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart`
- `packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`
- `packages/map_editor/test/top_toolbar_test.dart`
- `packages/map_editor/test/editor_selectors_test.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `packages/map_editor/test/ui_panels_smoke_test.dart`
- `packages/map_editor/test/editor_workspace_controller_test.dart`
- `packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart`
- `packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`

## E. Fichiers modifies/crees

Modifies :

- `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.g.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart`
- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/test/editor_selectors_test.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`
- `packages/map_editor/test/editor_workspace_controller_test.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart`
- `packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart`

Crees :

- `packages/map_editor/lib/src/features/editor/state/models/pokemon_catalog_section.dart`

## F. Decision architecture

La section active vit maintenant dans `EditorState` sous la forme :

```dart
pokemonCatalogSection: PokemonCatalogSection.pokedex | moves | items
```

Choix retenu :

- `EditorWorkspaceMode.pokedex` reste le mode parent pour limiter le blast radius ;
- `PokemonCatalogSection` devient la source de verite du sous-workspace actif ;
- `EditorWorkspaceController` et `EditorNotifier` exposent la navigation ;
- `ProjectExplorerPanel` pilote la selection ;
- `PokemonCatalogsWorkspace` ne garde plus aucun etat local de section.

Pourquoi c'est meilleur que `PageStorage` local :

- la navigation n'est plus cachee dans le widget central ;
- l'explorer, le canvas et le shell lisent la meme verite ;
- le remount du widget ne fait plus perdre la section active ;
- on respecte la hierarchie produit parent/enfants au lieu d'un systeme d'onglets locaux.

Choix UX complementaire :

- le bouton parent `Catalogues Pokemon` de la toolbar revient explicitement sur `Pokedex` ;
- les entrees enfants de l'explorer ouvrent `Pokedex`, `Moves` ou `Items` directement.

## G. UX obtenue

Dans `World Explorer`, l'utilisateur voit maintenant :

```text
Catalogues Pokemon
  Pokedex
  Moves
  Items
```

Comportement obtenu :

- cliquer sur `Pokedex` affiche le vrai `PokedexWorkspace` ;
- cliquer sur `Moves` affiche le shell `Moves` ;
- cliquer sur `Items` affiche le shell `Items` ;
- l'entree active est marquee comme selectionnee ;
- le canvas central n'affiche plus de `CupertinoSlidingSegmentedControl` ;
- le header global reste `Catalogues Pokemon` ;
- le toggle inspecteur droit reste absent sur ce workspace.

## H. Tests ajoutes/adaptes

Tests adaptes :

- `packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart`
- `packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`
- `packages/map_editor/test/editor_selectors_test.dart`
- `packages/map_editor/test/editor_workspace_controller_test.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`

Ce qu'ils prouvent :

- le canvas n'affiche plus de `pokemon-catalogs-tabs` ;
- la section `pokedex` affiche toujours le vrai Pokédex ;
- les sections `moves` et `items` affichent leurs shells sans crash ;
- l'explorer affiche bien trois enfants cliquables ;
- cliquer sur un enfant met a jour `workspaceMode` et `pokemonCatalogSection` ;
- la section active survit au remount du widget car elle vit dans l'etat editeur ;
- le bouton parent `Catalogues Pokemon` normalise bien vers `Pokedex` via le controller ;
- le shell garde l'entete global et l'absence d'inspecteur droit ;
- les smokes Pokédex/UI existants restent verts.

## I. Validations executees

Tests rouges d'abord :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/pokemon_catalogs_workspace_ui_test.dart test/pokemon_catalogs_project_explorer_entry_test.dart test/editor_workspace_controller_test.dart test/editor_shell_page_smoke_test.dart test/editor_selectors_test.dart
```

Resultat :

- echec attendu ;
- causes verifiees : `pokemonCatalogSection` absent dans `EditorState`, `selectPokemonCatalogSection` absent dans `EditorWorkspaceController`, snapshot explorer incomplet.

Regeneration necessaire apres ajout du champ Freezed :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter pub run build_runner build --delete-conflicting-outputs --build-filter="lib/src/features/editor/state/editor_state.freezed.dart"
```

Puis regeneration complete du package pour restaurer la surface generated existante :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter pub run build_runner build --delete-conflicting-outputs
```

Resultat :

- succes ;
- `editor_state.freezed.dart` mis a jour ;
- fichiers generated Riverpod restaures, dont `editor_notifier.g.dart`.

Analyse ciblee executee :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter analyze --no-pub lib/src/ui/canvas/pokemon_catalogs_workspace.dart lib/src/ui/panels/project_explorer_panel.dart lib/src/features/editor/state/editor_state.dart lib/src/features/editor/state/editor_notifier.dart lib/src/features/editor/state/editor_selectors.dart lib/src/features/editor/application/editor_workspace_controller.dart lib/src/features/editor/state/models/pokemon_catalog_section.dart test/pokemon_catalogs_workspace_ui_test.dart test/pokemon_catalogs_project_explorer_entry_test.dart test/editor_shell_page_smoke_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart test/pokedex_workspace_ui_test.dart test/ui_panels_smoke_test.dart test/editor_workspace_controller_test.dart
```

Resultat :

- succes ;
- `No issues found!`

Validation complementaire pendant integration :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/pokemon_catalogs_workspace_ui_test.dart test/editor_workspace_controller_test.dart
```

Resultat :

- succes ;
- verification du fix review `toolbar -> pokedex` + remount.

Validation canonique demandee :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/pokemon_catalogs_workspace_ui_test.dart test/pokemon_catalogs_project_explorer_entry_test.dart test/editor_shell_page_smoke_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart test/pokedex_workspace_ui_test.dart test/ui_panels_smoke_test.dart
```

Resultat :

- succes ;
- `All tests passed!`

## J. Review separee

Review separee reelle demandee a un agent distinct.

Findings retournes :

1. `Toolbar catalog button should normalize back to Pokédex root`
2. `Remount regression coverage was removed`

Traitement :

- finding 1 corrige ;
  - `selectPokedexWorkspace()` remet maintenant `pokemonCatalogSection` a `pokedex`
- finding 2 corrige ;
  - un test de remount a ete ajoute dans `pokemon_catalogs_workspace_ui_test.dart`

Aucun finding supplementaire n'est reste ouvert apres correction.

## K. Limites restantes

- `Moves` reste un shell produit, pas un vrai catalogue metier ;
- `Items` reste un shell produit, pas un vrai catalogue metier ;
- `Catalogues Pokemon` continue d'utiliser `EditorWorkspaceMode.pokedex` comme parent interne pour rester minimal ;
- la toolbar parent ouvre maintenant `Pokedex` par choix UX explicite ; elle n'ouvre plus la derniere section visitee.

## L. Etat git final exact

Commandes executees :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Sorties exactes :

```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.g.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/features/editor/state/editor_state.dart
 M packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart
 M packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/test/editor_selectors_test.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/editor_workspace_controller_test.dart
 M packages/map_editor/test/pokedex_workspace_ui_test.dart
 M packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart
 M packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart
?? examples/.DS_Store
?? packages/map_editor/lib/src/features/editor/state/models/pokemon_catalog_section.dart
?? reports/lot-8b-fix-pokemon-catalogs-navigation-correction-report.md
```

```text
git diff --stat
 .../application/editor_workspace_controller.dart   |  17 +-
 .../src/features/editor/state/editor_notifier.dart |   7 +
 .../features/editor/state/editor_notifier.g.dart   |   2 +-
 .../features/editor/state/editor_selectors.dart    |  10 +
 .../src/features/editor/state/editor_state.dart    |   4 +
 .../editor/state/editor_state.freezed.dart         |  29 +-
 .../src/ui/canvas/pokemon_catalogs_workspace.dart  | 345 ++++++---------------
 .../lib/src/ui/panels/project_explorer_panel.dart  |  56 ++--
 .../map_editor/test/editor_selectors_test.dart     |   2 +
 .../test/editor_shell_page_smoke_test.dart         |   9 +-
 .../test/editor_workspace_controller_test.dart     |  19 ++
 .../map_editor/test/pokedex_workspace_ui_test.dart |   5 +-
 ...kemon_catalogs_project_explorer_entry_test.dart |  84 ++++-
 .../test/pokemon_catalogs_workspace_ui_test.dart   | 150 +++++----
 14 files changed, 399 insertions(+), 340 deletions(-)
```

```text
git ls-files --others --exclude-standard
examples/.DS_Store
packages/map_editor/lib/src/features/editor/state/models/pokemon_catalog_section.dart
reports/lot-8b-fix-pokemon-catalogs-navigation-correction-report.md
```

## M. Decision finale

Correctif reussi.

`Catalogues Pokemon` est maintenant un vrai parent de navigation avec trois enfants `Pokedex`, `Moves` et `Items`, pilotes par l'etat editeur. Le switch interne du canvas a disparu, le vrai Pokédex reste fonctionnel, les shells `Moves` et `Items` restent honnetes, et la surface de validation demandee est verte.

## Checklist finale

- [x] ai-je supprime le switch interne `Pokedex / Moves / Items` du canvas ?
- [x] ai-je affiche `Pokedex / Moves / Items` comme entrees enfants de `Catalogues Pokemon` dans l’explorer ?
- [x] ai-je stocke la section active dans l’etat editeur ou une source de verite equivalente ?
- [x] ai-je conserve `Pokedex` fonctionnel ?
- [x] ai-je conserve `Moves` comme shell honnete ?
- [x] ai-je conserve `Items` comme shell honnete ?
- [x] ai-je evite de toucher `map_battle` / `map_runtime` ?
- [x] ai-je ajoute des tests sur la navigation reelle ?
- [x] ai-je verifie qu’il n’y a plus de segmented control interne ?
- [x] ai-je relance les validations utiles ?
- [x] ai-je evite toute ecriture Git ?
- [x] ai-je fourni un rapport complet ?
