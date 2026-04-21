# Lot 8b — Pokemon Catalogs Workspace Shell Report

## A. Resume executif honnete

Le lot 8b remplace la perception produit trop etroite du workspace `Pokédex` par une structure UX parent **Catalogues Pokemon** dans `map_editor`, sans ouvrir le chantier data complet pour `Moves` et `Items`.

Ce qui a ete fait :
- le shell editor et la toolbar affichent maintenant **Catalogues Pokemon** comme verite UX du workspace ;
- le canvas `pokedex` monte un nouveau parent `PokemonCatalogsWorkspace` ;
- ce parent expose trois sections claires : `Pokédex`, `Moves`, `Items` ;
- le vrai `PokedexWorkspace` existant reste le sous-espace fonctionnel reel ;
- `Moves` et `Items` ont des shells propres, honnetes, sans faux contenu ;
- le shell memorise l'onglet courant via `PageStorage` ;
- le shell editor n'affiche plus d'inspecteur droit vide sur ce workspace, ce qui evite un overlap/layout break sur la vraie UI Pokédex ;
- des tests UI/smoke/selectors ont ete ajoutes ou adaptes.

Ce qui n'a pas ete fait :
- aucun vrai catalogue data `Moves` ;
- aucun vrai catalogue data `Items` ;
- aucune sync PokeAPI ;
- aucune refonte du domaine Pokemon ;
- aucun changement `map_runtime`, `map_battle`, `map_core`, host, gameplay.

Pourquoi :
- le lot vise d'abord une structure produit/navigation saine et relisible ;
- les contenus reellement branches pour `Moves` et `Items` viendront dans les lots suivants.

## B. Etat git initial

Commande :
```bash
git status --short --untracked-files=all
```

Sortie initiale :
```text
?? examples/.DS_Store
```

Commande :
```bash
git diff --stat
```

Sortie initiale :
```text
```

Commande :
```bash
git ls-files --others --exclude-standard
```

Sortie initiale :
```text
examples/.DS_Store
```

## C. Fichiers lus

- `AGENTS.md`
- `packages/map_editor/README.md`
- `packages/map_editor/pubspec.yaml`
- `reports/lot-7-battle-pokemon-menu-end-to-end-report.md`
- `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart`
- `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_list_panel.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `packages/map_editor/test/top_toolbar_test.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`
- `packages/map_editor/test/editor_selectors_test.dart`
- `packages/map_editor/test/ui_panels_smoke_test.dart`
- `packages/map_editor/test/shell_chrome_test_harness.dart`

## D. Fichiers modifies

Fichiers suivis modifies :
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/test/editor_selectors_test.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`
- `packages/map_editor/test/shell_chrome_test_harness.dart`
- `packages/map_editor/test/top_toolbar_test.dart`

Fichiers crees :
- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace.dart`
- `packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart`
- `packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart`

## E. Fichiers volontairement non touches

- `packages/map_battle/**`
- `packages/map_runtime/**`
- `examples/playable_runtime_host/**`
- `packages/map_editor` hors surface du workspace catalogues
- `packages/map_core/**`
- `packages/map_gameplay/**`
- `examples/.DS_Store` preexistant hors scope

## F. Decision produit retenue

Nom produit retenu : **Catalogues Pokemon**.

Structure retenue :
- le mode interne reste `EditorWorkspaceMode.pokedex` pour limiter le blast radius ;
- l'UX expose maintenant un parent **Catalogues Pokemon** ;
- ce parent contient trois sections :
  - `Pokédex`
  - `Moves`
  - `Items`
- `Pokédex` reste le sous-espace reel et deja fonctionnel ;
- `Moves` et `Items` sont volontairement des shells honnetes ;
- dans le `ProjectExplorerPanel`, la carte/tuile est renommee `Catalogues Pokemon`, tout en conservant une sous-entree `Pokédex` deja branchee pour la continuite.

Pourquoi ce choix :
- il remplace le naming trop etroit sans renommer agressivement toute l'architecture interne ;
- il pose un vrai point d'entree extensible pour les lots 8c et 8d ;
- il garde Pokédex fonctionnel sans faux framework de navigation.

## G. Description UX reelle obtenue

Ce que voit l'utilisateur :
- dans l'explorer projet, une carte `Catalogues Pokemon` apparait a la place de l'ancien cadrage purement `Pokédex` ;
- dans la toolbar et le header shell, le workspace s'appelle `Catalogues Pokemon` ;
- quand on ouvre ce workspace, le shell parent affiche un message d'orientation et un segmented control `Pokédex / Moves / Items` ;
- `Pokédex` ouvre toujours le vrai workspace existant, avec sa liste/detail/outils actuels ;
- `Moves` ouvre un shell produit propre, avec un etat honnete et une indication explicite que le seul outillage reellement branche reste aujourd'hui dans `Pokédex > Learnset` ;
- `Items` ouvre un shell produit propre, avec un etat honnete et sans pretendre que le catalogue est deja branche ;
- l'onglet choisi est restaure si on quitte puis reouvre le workspace pendant la meme session shell ;
- le panneau droit vide est masque pour ce workspace, car le vrai detail existe deja dans le stage Pokédex lui-meme.

Navigation :
- entree principale : explorer projet ou toolbar ;
- navigation interne : segmented control local ;
- retour/continuite : le shell garde le dernier sous-onglet via `PageStorage`.

## H. Decoupage reel 7b / 7c / 7d equivalent pour le lot 8b

Decoupage reel effectue :
- audit de la surface actuelle `Pokédex` et du wiring workspace ;
- TDD rouge sur le nouvel espace catalogues et sur le naming shell ;
- introduction du parent `PokemonCatalogsWorkspace` ;
- adaptation du shell/editor chrome/explorer/toolbar ;
- ajout d'un smoke shell pour verifier le vrai montage dans `EditorShellPage` ;
- review separee et corrections de coherence UX/layout.

## I. Tests ajoutes / adaptes

Tests ajoutes :
- `packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart`
- `packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart`

Tests adaptes :
- `packages/map_editor/test/top_toolbar_test.dart`
- `packages/map_editor/test/editor_selectors_test.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`
- `packages/map_editor/test/shell_chrome_test_harness.dart`

Ce qu'ils prouvent :
- le workspace parent expose bien `Pokédex / Moves / Items` ;
- `Pokédex` reste le workspace reel par defaut ;
- `Moves` et `Items` s'ouvrent sans crash ;
- `Moves` n'induit plus en erreur sur l'endroit ou vit l'outillage reel actuel ;
- l'explorer affiche bien une carte `Catalogues Pokemon` ;
- le shell/header/top toolbar utilisent `Catalogues Pokemon` ;
- le shell editor monte vraiment le parent catalogues ;
- le panneau droit/toggle n'apparait plus sur ce workspace ;
- l'onglet `Moves`/`Items` est restaure apres remount du workspace ;
- les smokes Pokédex et panels existants restent verts.

## J. Validations executees

Commandes executees :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/pokemon_catalogs_workspace_ui_test.dart test/pokedex_workspace_ui_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart
```
Resultat : rouge au debut, comme attendu, a cause du fichier workspace manquant et des anciens labels.

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter analyze --no-pub lib/src/ui/canvas/pokemon_catalogs_workspace.dart lib/src/ui/canvas/editor_canvas_host.dart lib/src/features/editor/state/editor_selectors.dart lib/src/ui/shared/top_toolbar.dart lib/src/ui/editor_shell_page.dart lib/src/ui/panels/project_explorer_panel.dart test/pokemon_catalogs_workspace_ui_test.dart test/pokedex_workspace_ui_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart
```
Resultat : vert apres correction des warnings.

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/editor_shell_page_smoke_test.dart
```
Resultat : rouge pendant l'implementation, ce qui a revele un vrai overflow et la presence inutile de l'inspecteur droit vide ; vert apres correction.

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter analyze --no-pub lib/src/ui/canvas/pokemon_catalogs_workspace.dart lib/src/ui/canvas/editor_canvas_host.dart lib/src/features/editor/state/editor_selectors.dart lib/src/ui/shared/top_toolbar.dart lib/src/ui/editor_shell_page.dart lib/src/ui/panels/project_explorer_panel.dart test/pokemon_catalogs_workspace_ui_test.dart test/pokemon_catalogs_project_explorer_entry_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart test/editor_shell_page_smoke_test.dart test/shell_chrome_test_harness.dart
```
Resultat : `No issues found!`

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/pokemon_catalogs_project_explorer_entry_test.dart test/pokemon_catalogs_workspace_ui_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart test/editor_shell_page_smoke_test.dart test/ui_panels_smoke_test.dart test/pokedex_workspace_ui_test.dart
```
Resultat : `All tests passed!`

## K. Resultats obtenus

- le naming produit `Catalogues Pokemon` est visible dans le shell editor, la toolbar et l'explorer ;
- `EditorCanvasHost` monte un parent workspace coherent sans renommer agressivement `EditorWorkspaceMode.pokedex` ;
- `Moves` et `Items` existent comme vrais shells honnetes ;
- la continuite utilisateur avec le vrai Pokédex est preservee ;
- le lot n'a pas rouvert le domaine data complet ;
- aucun package hors `map_editor` n'a ete touche.

## L. Decisions retenues / rejetees

Retenues :
- garder `EditorWorkspaceMode.pokedex` en interne ;
- introduire un parent UI `PokemonCatalogsWorkspace` ;
- garder `Pokédex` comme sous-espace reel ;
- faire de `Moves` et `Items` des shells honnetes ;
- masquer le panneau droit vide pour ce workspace ;
- memoriser l'onglet courant via `PageStorage`.

Rejetees :
- renommer l'enum/mode interne `pokedex` partout ;
- deplacer les outils moves existants hors Pokédex dans ce lot ;
- ouvrir un vrai catalogue data `Moves` ou `Items` ;
- refactorer la navigation globale de l'editeur ;
- toucher `map_runtime`, `map_battle`, `map_core`, host.

## M. Limites restantes

- `Moves` et `Items` restent des shells produit, pas des catalogues reels ;
- l'outillage moves reel vit encore dans `Pokédex > Learnset` ;
- le shell `Items` n'est qu'une structure preparatoire ;
- aucune sync externe ni import live n'est branchee dans ce lot ;
- la persistance d'onglet utilise `PageStorage`, donc elle reste limitee au cycle du shell courant et ne devient pas une preference globale du projet.

## N. Retour du reviewer separe

Review separee reelle demandee et lancee.

Retour utile recu :
- le reviewer a signale que le shell `Moves` pointait vers un placeholder alors que le seul outillage reel vivant autour des moves restait dans `Pokédex > Learnset` ;
- il a signale le doublon de chrome `Catalogues Pokemon` entre le shell editor et le hero block interne ;
- il a signale l'absence de test sur la disparition de l'inspecteur/toggle droit ;
- il a note que l'internal naming `pokedex` etait acceptable si la copie utilisateur restait coherente.

Corrections appliquees suite a la review :
- le hero block du parent a ete compacté pour ne plus dupliquer le chrome shell ;
- le shell `Moves` explique explicitement ou vit aujourd'hui le seul outillage moves branche ;
- le smoke shell verifie maintenant que le toggle d'inspecteur droit n'apparait pas sur ce workspace ;
- le dernier tooltip toolbar a ete aligne sur `Catalogues Pokemon` ;
- l'onglet selectionne est maintenant restaure apres remount.

Retour non retenu tel quel :
- `examples/.DS_Store` a ete signale comme bruit hors scope. Il est volontairement laisse intact, conformement aux contraintes de ne pas toucher la dirtiness hors sujet.

## O. Autocritique finale

Le lot reste petit et sain, ce qui etait l'objectif, mais il y a eu un vrai aller-retour utile sur le shell : la premiere version du parent etait trop decorative, dupliquait le header et reduisait l'espace du Pokédex reel. Le smoke shell a permis d'attraper ce defaut tot.

Le compromis le plus discutable reste l'explorer : la carte parent s'appelle `Catalogues Pokemon`, mais la sous-ligne cliquable reste `Pokédex` pour garder de la continuite avec la seule sous-surface reellement branchee. Je considere ce choix sain pour 8b, tant que 8c/8d viennent vite donner une realite pleine a `Moves` et `Items`.

## P. Critique explicite du prompt

Le prompt etait globalement bon, mais il y avait une ambiguite reelle sur “remplacer l'entree/tuile/intitule trop centre sur Pokédex” : cela pouvait vouloir dire renommer la carte parent, la sous-entree cliquable, ou les deux. Je l'ai interprete comme un changement de **verite produit du workspace** et de la **carte parent** dans l'explorer, tout en laissant la sous-entree `Pokédex` visible pour la continuite puisque c'est le seul sous-espace deja reellement complet.

Autre point un peu sous-optimal : la demande d'inclure le contenu complet de tous les fichiers modifies dans le report rend le document tres lourd. Je l'ai respectee via l'annexe, mais ce n'est pas le format le plus lisible pour une revue humaine rapide.

## Q. Etat git final exact

Commande :
```bash
git status --short --untracked-files=all
```

Sortie finale :
```text
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/editor_selectors_test.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
 M packages/map_editor/test/top_toolbar_test.dart
?? examples/.DS_Store
?? packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace.dart
?? packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart
?? packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart
```

Commande :
```bash
git diff --stat
```

Sortie finale :
```text
 .../features/editor/state/editor_selectors.dart    |  4 +-
 .../lib/src/ui/canvas/editor_canvas_host.dart      |  6 +--
 .../map_editor/lib/src/ui/editor_shell_page.dart   | 52 +++++++++++++---------
 .../lib/src/ui/panels/project_explorer_panel.dart  | 13 ++----
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  |  7 +--
 .../map_editor/test/editor_selectors_test.dart     | 18 ++++++++
 .../test/editor_shell_page_smoke_test.dart         | 31 +++++++++++++
 .../map_editor/test/shell_chrome_test_harness.dart |  3 +-
 packages/map_editor/test/top_toolbar_test.dart     |  2 +-
 9 files changed, 91 insertions(+), 45 deletions(-)
```

Commande :
```bash
git ls-files --others --exclude-standard
```

Sortie finale :
```text
examples/.DS_Store
packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace.dart
packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart
packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart
```

## R. Checklist d'autocontrole

- [x] ai-je bien remplace la logique UX trop centree sur “Pokédex” par une vraie structure “Catalogues Pokemon” ?
- [x] ai-je bien garde Pokédex fonctionnel ?
- [x] ai-je bien introduit Moves et Items comme shells propres ?
- [x] ai-je evite de mentir sur un contenu encore non implemente ?
- [x] ai-je evite d'ouvrir trop tot le chantier data complet ?
- [x] ai-je limite le blast radius ?
- [x] ai-je ajoute des tests utiles ?
- [x] ai-je fait une review separee reelle ?
- [x] ai-je evite toute ecriture Git ?
- [x] ai-je fourni un rapport honnete et complet ?

## S. Decision finale

**Lot 8b reussi.**

Le projet dispose maintenant d'un vrai shell produit **Catalogues Pokemon** dans `map_editor`, avec une navigation claire entre `Pokédex`, `Moves` et `Items`, sans rouvrir prematurement le chantier data complet. `Pokédex` reste fonctionnel, `Moves` et `Items` existent comme shells honnetes, et le blast radius est reste limite a `map_editor`.

## Annexe — Contenu complet des fichiers modifies/crees


### `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../application/models/terrain_selection_mode.dart';
import '../tools/editor_tool.dart';
import 'editor_notifier.dart';
import 'editor_state.dart';

/// Snapshot léger du shell.
///
/// On évite ainsi de faire rebuild le shell entier sur chaque champ de
/// `EditorState`, tout en gardant un contrat lisible côté UI.
typedef EditorShellSnapshot = ({
  EditorWorkspaceMode workspaceMode,
  String workspaceTitle,
  String workspaceSubtitle,
  bool canUndoMap,
  bool canRedoMap,
  bool isSaving,
  bool canSaveMap,
});

/// Snapshot ciblé pour la toolbar.
///
/// Il contient uniquement les champs réellement lus par `TopToolbar`.
typedef EditorToolbarSnapshot = ({
  ProjectManifest? project,
  String? projectRootPath,
  ProjectSettings settings,
  MapData? activeMap,
  EditorWorkspaceMode workspaceMode,
  ProjectTilesetEntry? selectedTilesetEntry,
  MapLayer? activeLayer,
  EditorToolType activeTool,
  TerrainSelectionMode terrainSelectionMode,
  TerrainType selectedTerrainType,
  MapEntityKind selectedEntityKind,
  CollisionBrushSizeMode collisionBrushSizeMode,
  bool isSaving,
  bool isDirty,
  bool canUndoMap,
  bool canRedoMap,
  String? statusMessage,
});

/// Snapshot ciblé pour le Project Explorer.
typedef EditorProjectExplorerSnapshot = ({
  ProjectManifest? project,
  ProjectSettings settings,
  EditorWorkspaceMode workspaceMode,
  ProjectTilesetEntry? selectedTilesetEntry,
  String? activeMapId,
});

/// Snapshot léger pour les racines des panneaux terrain/path.
typedef EditorTerrainLibrarySnapshot = ({
  ProjectManifest? project,
  ProjectSettings settings,
  List<ProjectTilesetEntry> tilesets,
  TerrainType selectedTerrainType,
  Map<TerrainType, String> selectedTerrainPresetByType,
  String? selectedTerrainPresetId,
  String? selectedPathPresetId,
});

/// Snapshot léger pour la racine du panneau palette tileset.
typedef EditorTilesetPaletteSnapshot = ({
  ProjectManifest? project,
  ProjectSettings settings,
  MapData? activeMap,
  ProjectTilesetEntry? selectedTilesetEntry,
  String? projectRootPath,
  String? activeLayerId,
  EditorBrush activeBrush,
  PaletteCategory? paletteCategoryFilter,
  String? selectedTilesetElementGroupId,
  TilesElementsPanelMode tilesElementsPanelMode,
  String? selectedPlacedElementInstanceId,
});

final editorWorkspaceModeProvider = Provider<EditorWorkspaceMode>((ref) {
  return ref.watch(editorNotifierProvider.select((s) => s.workspaceMode));
});

final editorProjectManifestProvider = Provider<ProjectManifest?>((ref) {
  return ref.watch(editorNotifierProvider.select((s) => s.project));
});

final editorProjectRootPathProvider = Provider<String?>((ref) {
  return ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));
});

final editorSelectedTilesetEntryProvider =
    Provider<ProjectTilesetEntry?>((ref) {
  return ref.watch(
    editorNotifierProvider.select(_resolveSelectedTilesetEntryFromState),
  );
});

final editorActiveLayerProvider = Provider<MapLayer?>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final map = state.activeMap;
      final activeLayerId = state.activeLayerId;
      if (map == null || activeLayerId == null) {
        return null;
      }
      for (final layer in map.layers) {
        if (layer.id == activeLayerId) {
          return layer;
        }
      }
      return null;
    }),
  );
});

final editorShellSnapshotProvider = Provider<EditorShellSnapshot>((ref) {
  final workspaceMode = ref.watch(editorWorkspaceModeProvider);
  final activeMap = ref.watch(
    editorNotifierProvider.select((s) => s.activeMap),
  );
  final selectedTileset = ref.watch(editorSelectedTilesetEntryProvider);
  final canUndoMap = ref.watch(
    editorNotifierProvider.select((s) => s.canUndoMap),
  );
  final canRedoMap = ref.watch(
    editorNotifierProvider.select((s) => s.canRedoMap),
  );
  final isSaving = ref.watch(
    editorNotifierProvider.select((s) => s.isSaving),
  );

  final workspaceTitle = switch (workspaceMode) {
    EditorWorkspaceMode.map => activeMap?.name ?? 'Map Workspace',
    EditorWorkspaceMode.tileset => selectedTileset?.name ?? 'Tileset Studio',
    EditorWorkspaceMode.trainer => 'Trainer Studio',
    EditorWorkspaceMode.pokedex => 'Catalogues Pokémon',
    EditorWorkspaceMode.globalStory => 'Global Story Workspace',
    EditorWorkspaceMode.step => 'Step Studio',
    EditorWorkspaceMode.cutscene => 'Cutscene Studio',
    EditorWorkspaceMode.dialogue => 'Dialogue Studio',
  };

  final workspaceSubtitle = switch (workspaceMode) {
    EditorWorkspaceMode.map => activeMap == null
        ? 'Open a map to start building your world.'
        : '${activeMap.size.width} x ${activeMap.size.height} tiles  •  ${activeMap.layers.length} layers',
    EditorWorkspaceMode.tileset => selectedTileset == null
        ? 'Select a tileset to browse and curate your library.'
        : 'Visual library editing for tiles, elements and groups.',
    EditorWorkspaceMode.trainer =>
      'Create trainers, teams and battle-ready rosters without editing raw JSON.',
    EditorWorkspaceMode.pokedex =>
      'Pokédex, Moves et Items réunis dans un même pôle de catalogues Pokémon.',
    EditorWorkspaceMode.globalStory =>
      'Macro narrative progression: arcs, milestones and high-level branches.',
    EditorWorkspaceMode.step =>
      'Step logic workspace: progression rules, expected outcomes, linked cutscenes.',
    EditorWorkspaceMode.cutscene =>
      'Scene execution workspace: dialogue, movement, waits, local branching.',
    EditorWorkspaceMode.dialogue =>
      'Conversation authoring: visual blocks, preview, Yarn export — not a raw script IDE.',
  };

  return (
    workspaceMode: workspaceMode,
    workspaceTitle: workspaceTitle,
    workspaceSubtitle: workspaceSubtitle,
    canUndoMap: canUndoMap,
    canRedoMap: canRedoMap,
    isSaving: isSaving,
    canSaveMap: activeMap != null && !isSaving,
  );
});

final editorToolbarSnapshotProvider = Provider<EditorToolbarSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      return (
        project: project,
        projectRootPath: state.projectRootPath,
        settings: project?.settings ?? const ProjectSettings(),
        activeMap: state.activeMap,
        workspaceMode: state.workspaceMode,
        selectedTilesetEntry: _resolveSelectedTilesetEntryFromState(state),
        activeLayer: _resolveActiveLayerFromState(state),
        activeTool: state.activeTool,
        terrainSelectionMode: state.terrainSelectionMode,
        selectedTerrainType: state.selectedTerrainType,
        selectedEntityKind: state.selectedEntityKind,
        collisionBrushSizeMode: state.collisionBrushSizeMode,
        isSaving: state.isSaving,
        isDirty: state.isDirty,
        canUndoMap: state.canUndoMap,
        canRedoMap: state.canRedoMap,
        statusMessage: state.statusMessage,
      );
    }),
  );
});

final editorProjectExplorerSnapshotProvider =
    Provider<EditorProjectExplorerSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      return (
        project: project,
        settings: project?.settings ?? const ProjectSettings(),
        workspaceMode: state.workspaceMode,
        selectedTilesetEntry: _resolveSelectedTilesetEntryFromState(state),
        activeMapId: state.activeMap?.id,
      );
    }),
  );
});

final editorTerrainLibrarySnapshotProvider =
    Provider<EditorTerrainLibrarySnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      return (
        project: project,
        settings: project?.settings ?? const ProjectSettings(),
        tilesets: project?.tilesets ?? const <ProjectTilesetEntry>[],
        selectedTerrainType: state.selectedTerrainType,
        selectedTerrainPresetByType: state.selectedTerrainPresetByType,
        selectedTerrainPresetId: state.selectedTerrainPresetId,
        selectedPathPresetId: state.selectedPathPresetId,
      );
    }),
  );
});

final editorTilesetPaletteSnapshotProvider =
    Provider<EditorTilesetPaletteSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      return (
        project: project,
        settings: project?.settings ?? const ProjectSettings(),
        activeMap: state.activeMap,
        selectedTilesetEntry: _resolveSelectedTilesetEntryFromState(state),
        projectRootPath: state.projectRootPath,
        activeLayerId: state.activeLayerId,
        activeBrush: state.activeBrush,
        paletteCategoryFilter: state.paletteCategoryFilter,
        selectedTilesetElementGroupId: state.selectedTilesetElementGroupId,
        tilesElementsPanelMode: state.tilesElementsPanelMode,
        selectedPlacedElementInstanceId: state.selectedPlacedElementInstanceId,
      );
    }),
  );
});

MapLayer? _resolveActiveLayerFromState(EditorState state) {
  final map = state.activeMap;
  final activeLayerId = state.activeLayerId;
  if (map == null || activeLayerId == null) {
    return null;
  }
  for (final layer in map.layers) {
    if (layer.id == activeLayerId) {
      return layer;
    }
  }
  return null;
}

ProjectTilesetEntry? _resolveSelectedTilesetEntryFromState(EditorState state) {
  final project = state.project;
  if (project == null) {
    return null;
  }

  final selectedId = state.selectedTilesetEditorId;
  if (selectedId != null) {
    for (final tileset in project.tilesets) {
      if (tileset.id == selectedId) {
        return tileset;
      }
    }
  }

  final activeLayer = _resolveActiveLayerFromState(state);
  if (activeLayer is TileLayer) {
    final layerTilesetId = activeLayer.tilesetId?.trim();
    if (layerTilesetId != null && layerTilesetId.isNotEmpty) {
      for (final tileset in project.tilesets) {
        if (tileset.id == layerTilesetId) {
          return tileset;
        }
      }
    }
  }

  final brushTilesetId = _resolveActiveBrushTilesetId(state, project);
  if (brushTilesetId != null) {
    for (final tileset in project.tilesets) {
      if (tileset.id == brushTilesetId) {
        return tileset;
      }
    }
  }

  if (project.tilesets.isEmpty) {
    return null;
  }
  return project.tilesets.first;
}

String? _resolveActiveBrushTilesetId(
  EditorState state,
  ProjectManifest project,
) {
  final brush = state.activeBrush;
  if (brush is TileEditorBrush) {
    return brush.tilesetId;
  }
  if (brush is PaletteEntryEditorBrush) {
    return brush.tilesetId;
  }
  if (brush is ProjectElementEditorBrush) {
    for (final element in project.elements) {
      if (element.id == brush.elementId) {
        return element.tilesetId;
      }
    }
  }
  return null;
}

```


### `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import 'map_canvas.dart';
import 'narrative_workspace_canvas.dart';
import 'pokemon_catalogs_workspace.dart';
import 'tileset_editor_canvas.dart';
import '../panels/trainer_library_panel.dart';

class EditorCanvasHost extends ConsumerWidget {
  const EditorCanvasHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceMode = ref.watch(editorWorkspaceModeProvider);

    return switch (workspaceMode) {
      EditorWorkspaceMode.map => const MapCanvas(),
      EditorWorkspaceMode.tileset => const TilesetEditorCanvas(),
      EditorWorkspaceMode.trainer => const TrainerLibraryPanel(),
      EditorWorkspaceMode.pokedex => const PokemonCatalogsWorkspace(),
      EditorWorkspaceMode.globalStory ||
      EditorWorkspaceMode.step ||
      EditorWorkspaceMode.cutscene ||
      EditorWorkspaceMode.dialogue =>
        const NarrativeWorkspaceCanvas(),
    };
  }
}

```


### `packages/map_editor/lib/src/ui/editor_shell_page.dart`

```dart
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';
import 'package:map_editor/src/ui/panels/narrative_inspector_panel.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';
import 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
import 'package:map_editor/src/ui/shared/status_bar.dart';
import 'package:map_editor/src/ui/shared/top_toolbar.dart';

import '../features/editor/state/editor_notifier.dart';
import '../features/editor/state/editor_selectors.dart';
import '../features/editor/state/editor_state.dart';

class EditorShellPage extends ConsumerStatefulWidget {
  const EditorShellPage({super.key});

  @override
  ConsumerState<EditorShellPage> createState() => _EditorShellPageState();
}

class _EditorShellPageState extends ConsumerState<EditorShellPage> {
  Timer? _toastTimer;
  String? _toastMessage;
  bool _toastIsError = false;
  bool _didAttemptProjectAutoRestore = false;

  /// When false, the right ResizablePane (map / tileset / narrative inspector) is omitted so the center stage uses full width.
  bool _rightInspectorVisible = true;

  @override
  void initState() {
    super.initState();
    // Provider mutations are intentionally deferred after the first frame:
    // auto-restore loads a project (state mutation), and Riverpod disallows
    // mutating providers during build/init lifecycle phases.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didAttemptProjectAutoRestore) {
        return;
      }
      _didAttemptProjectAutoRestore = true;
      await ref
          .read(editorNotifierProvider.notifier)
          .restoreLastOpenedProjectIfAny();
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _flashToast(String message, {required bool isError}) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastIsError = isError;
    });
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _toastMessage = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shell = ref.watch(editorShellSnapshotProvider);
    final workspaceMode = shell.workspaceMode;
    final notifier = ref.read(editorNotifierProvider.notifier);
    final supportsRightInspector = workspaceMode != EditorWorkspaceMode.pokedex;

    ref.listen(editorNotifierProvider.select((s) => s.errorMessage),
        (prev, next) {
      if (next != null) {
        _flashToast(next, isError: true);
      }
    });

    ref.listen(editorNotifierProvider.select((s) => s.statusMessage),
        (prev, next) {
      if (next != null) {
        _flashToast(next, isError: false);
      }
    });

    final isNarrativeWorkspace = switch (workspaceMode) {
      EditorWorkspaceMode.globalStory ||
      EditorWorkspaceMode.step ||
      EditorWorkspaceMode.cutscene ||
      EditorWorkspaceMode.dialogue =>
        true,
      _ => false,
    };

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true): _UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
            _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, meta: true): _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, control: true): _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, meta: true): _SaveIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, control: true): _SaveIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _UndoIntent: CallbackAction<_UndoIntent>(
            onInvoke: (_) {
              if (_isTextInputFocused()) return null;
              if (!shell.canUndoMap) return null;
              notifier.undoMap();
              return null;
            },
          ),
          _RedoIntent: CallbackAction<_RedoIntent>(
            onInvoke: (_) {
              if (_isTextInputFocused()) return null;
              if (!shell.canRedoMap) return null;
              notifier.redoMap();
              return null;
            },
          ),
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) {
              if (_isTextInputFocused()) return null;
              if (!shell.canSaveMap) return null;
              notifier.saveActiveMap();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: EditorChrome.appRootDecoration(context),
                child: Stack(
                  children: [
                    const Positioned(
                      left: -120,
                      top: -120,
                      child: _AmbientGlow(
                        size: 460,
                        color: EditorChrome.accentPrimary,
                        opacity: 0.14,
                      ),
                    ),
                    const Positioned(
                      right: -100,
                      top: 40,
                      child: _AmbientGlow(
                        size: 400,
                        color: EditorChrome.accentLilac,
                        opacity: 0.1,
                      ),
                    ),
                    const Positioned(
                      right: -120,
                      top: 90,
                      child: _AmbientGlow(
                        size: 420,
                        color: EditorChrome.accentWarm,
                        opacity: 0.13,
                      ),
                    ),
                    const Positioned(
                      left: 140,
                      bottom: -160,
                      child: _AmbientGlow(
                        size: 520,
                        color: EditorChrome.accentJade,
                        opacity: 0.1,
                      ),
                    ),
                    const Positioned(
                      right: 220,
                      bottom: -140,
                      child: _AmbientGlow(
                        size: 420,
                        color: EditorChrome.accentCoral,
                        opacity: 0.09,
                      ),
                    ),
                    MacosWindow(
                      child: MacosScaffold(
                        backgroundColor: const Color(0x00000000),
                        toolBar: buildMapEditorToolbar(context, ref),
                        children: [
                          ResizablePane.noScrollBar(
                            key: ValueKey<bool>(isNarrativeWorkspace),
                            resizableSide: ResizableSide.right,
                            minSize: isNarrativeWorkspace ? 200 : 240,
                            maxSize: isNarrativeWorkspace ? 460 : 520,
                            startSize: isNarrativeWorkspace ? 268 : 344,
                            decoration: const BoxDecoration(
                              color: MacosColors.transparent,
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                isNarrativeWorkspace ? 12 : 16,
                                isNarrativeWorkspace ? 16 : 18,
                                isNarrativeWorkspace ? 10 : 12,
                                isNarrativeWorkspace ? 16 : 18,
                              ),
                              child: const ProjectExplorerPanel(),
                            ),
                          ),
                          ContentArea(
                            builder: (context, scrollController) {
                              return Column(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        isNarrativeWorkspace ? 10 : 18,
                                        isNarrativeWorkspace ? 12 : 18,
                                        isNarrativeWorkspace ? 10 : 18,
                                        isNarrativeWorkspace ? 6 : 8,
                                      ),
                                      child: EditorIsland(
                                        radius: 36,
                                        tint: EditorChrome.islandCoolTint,
                                        child: Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            isNarrativeWorkspace ? 12 : 18,
                                            isNarrativeWorkspace ? 12 : 18,
                                            isNarrativeWorkspace ? 12 : 18,
                                            isNarrativeWorkspace ? 10 : 16,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _WorkspaceStageHeader(
                                                title: shell.workspaceTitle,
                                                subtitle:
                                                    shell.workspaceSubtitle,
                                                workspaceMode: workspaceMode,
                                                rightPanelVisible:
                                                    _rightInspectorVisible,
                                                showRightPanelToggle:
                                                    supportsRightInspector,
                                                onToggleRightPanel: () {
                                                  setState(() {
                                                    _rightInspectorVisible =
                                                        !_rightInspectorVisible;
                                                  });
                                                },
                                              ),
                                              SizedBox(
                                                height: isNarrativeWorkspace
                                                    ? 12
                                                    : 18,
                                              ),
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(26),
                                                  child: Padding(
                                                    padding: EdgeInsets.all(
                                                      isNarrativeWorkspace
                                                          ? 8
                                                          : 14,
                                                    ),
                                                    child:
                                                        const EditorCanvasHost(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const StatusBar(),
                                ],
                              );
                            },
                          ),
                          if (supportsRightInspector && _rightInspectorVisible)
                            ResizablePane.noScrollBar(
                              key: ValueKey<String>(
                                'editor_right_${isNarrativeWorkspace ? 'n' : 'm'}',
                              ),
                              resizableSide: ResizableSide.left,
                              minSize: isNarrativeWorkspace ? 220 : 240,
                              maxSize: 620,
                              startSize: isNarrativeWorkspace ? 292 : 336,
                              decoration: const BoxDecoration(
                                color: MacosColors.transparent,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 18, 16, 18),
                                child: EditorIsland(
                                  radius: 32,
                                  tint: switch (workspaceMode) {
                                    EditorWorkspaceMode.map =>
                                      EditorChrome.islandNeutralTint,
                                    EditorWorkspaceMode.tileset =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.trainer =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.pokedex =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.globalStory =>
                                      EditorChrome.islandCoolTint,
                                    EditorWorkspaceMode.step =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.cutscene =>
                                      EditorChrome.islandNeutralTint,
                                    EditorWorkspaceMode.dialogue =>
                                      EditorChrome.islandCoolTint,
                                  },
                                  child: switch (workspaceMode) {
                                    EditorWorkspaceMode.map =>
                                      const MapInspectorPanel(),
                                    EditorWorkspaceMode.tileset =>
                                      const TilesetPalettePanel(),
                                    EditorWorkspaceMode.trainer =>
                                      const _EmptyWorkspaceInspector(),
                                    // Le Pokédex du lot 13 n'a toujours pas de
                                    // panneau d'inspection dédié :
                                    // pas de détail espèce, pas d'édition.
                                    // On réutilise donc un panneau neutre vide
                                    // pour éviter d'introduire une nouvelle
                                    // structure latérale ou une fausse logique.
                                    EditorWorkspaceMode.pokedex =>
                                      const _EmptyWorkspaceInspector(),
                                    EditorWorkspaceMode.globalStory ||
                                    EditorWorkspaceMode.step ||
                                    EditorWorkspaceMode.cutscene ||
                                    EditorWorkspaceMode.dialogue =>
                                      const NarrativeInspectorPanel(),
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_toastMessage != null)
                Positioned(
                  right: 24,
                  bottom: 72,
                  child: _EditorToastBanner(
                    message: _toastMessage!,
                    isError: _toastIsError,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorToastBanner extends StatelessWidget {
  const _EditorToastBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final tint = isError
        ? EditorChrome.errorTint(context)
        : EditorChrome.statusTint(context);
    final accent = isError
        ? EditorChrome.inspectorJoyCoral
        : EditorChrome.inspectorJoyMint;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: EditorIsland(
        radius: 18,
        tint: tint,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(CupertinoColors.white, accent, 0.75)!,
                      Color.lerp(accent, const Color(0xFF102010), 0.35)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.88),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: MacosIcon(
                  isError
                      ? CupertinoIcons.exclamationmark_triangle_fill
                      : CupertinoIcons.check_mark_circled_solid,
                  color: CupertinoColors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceStageHeader extends StatelessWidget {
  const _WorkspaceStageHeader({
    required this.title,
    required this.subtitle,
    required this.workspaceMode,
    required this.rightPanelVisible,
    required this.showRightPanelToggle,
    required this.onToggleRightPanel,
  });

  final String title;
  final String subtitle;
  final EditorWorkspaceMode workspaceMode;
  final bool rightPanelVisible;
  final bool showRightPanelToggle;
  final VoidCallback onToggleRightPanel;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    final chipFill = EditorChrome.chipFill(context);
    final chipAccent = switch (workspaceMode) {
      EditorWorkspaceMode.map => EditorChrome.inspectorJoyHoney,
      EditorWorkspaceMode.tileset => EditorChrome.inspectorJoyLilac,
      EditorWorkspaceMode.trainer => EditorChrome.accentCoral,
      EditorWorkspaceMode.pokedex => EditorChrome.inspectorJoyAmber,
      EditorWorkspaceMode.globalStory => EditorChrome.inspectorJoyCyan,
      EditorWorkspaceMode.step => EditorChrome.inspectorJoyMint,
      EditorWorkspaceMode.cutscene => EditorChrome.inspectorJoyCoral,
      EditorWorkspaceMode.dialogue => EditorChrome.inspectorJoyBlue,
    };
    final chipAccent2 = switch (workspaceMode) {
      EditorWorkspaceMode.map => EditorChrome.inspectorJoyApricot,
      EditorWorkspaceMode.tileset => EditorChrome.inspectorJoyPlum,
      EditorWorkspaceMode.trainer => EditorChrome.inspectorJoyCoral,
      EditorWorkspaceMode.pokedex => EditorChrome.accentWarm,
      EditorWorkspaceMode.globalStory => EditorChrome.inspectorJoyBlue,
      EditorWorkspaceMode.step => EditorChrome.accentJade,
      EditorWorkspaceMode.cutscene => EditorChrome.inspectorJoyCoral,
      EditorWorkspaceMode.dialogue => EditorChrome.inspectorJoyCyan,
    };

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(CupertinoColors.white, chipAccent, 0.72)!,
                Color.lerp(chipAccent2, const Color(0xFF1A0A08), 0.38)!,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: chipAccent.withValues(alpha: 0.88),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: MacosIcon(
            switch (workspaceMode) {
              EditorWorkspaceMode.map => CupertinoIcons.map,
              EditorWorkspaceMode.tileset => CupertinoIcons.square_grid_2x2,
              EditorWorkspaceMode.trainer => CupertinoIcons.person_3_fill,
              EditorWorkspaceMode.pokedex => CupertinoIcons.book,
              EditorWorkspaceMode.globalStory => CupertinoIcons.link,
              EditorWorkspaceMode.step => CupertinoIcons.flag,
              EditorWorkspaceMode.cutscene => CupertinoIcons.play_rectangle,
              EditorWorkspaceMode.dialogue => CupertinoIcons.text_bubble,
            },
            color: CupertinoColors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: label,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtle,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (showRightPanelToggle) ...[
          MacosTooltip(
            message:
                rightPanelVisible ? 'Hide right panel' : 'Show right panel',
            child: MacosIconButton(
              semanticLabel:
                  rightPanelVisible ? 'Hide right panel' : 'Show right panel',
              icon: MacosIcon(
                rightPanelVisible ? Icons.open_in_full : Icons.close_fullscreen,
                color: label.withValues(alpha: 0.85),
                size: 18,
              ),
              backgroundColor: CupertinoColors.transparent,
              hoverColor: chipAccent.withValues(alpha: 0.12),
              onPressed: onToggleRightPanel,
              boxConstraints: const BoxConstraints(
                minWidth: 34,
                maxWidth: 34,
                minHeight: 34,
                maxHeight: 34,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Color.lerp(chipFill, chipAccent, 0.22),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: chipAccent.withValues(alpha: 0.65),
              width: 1,
            ),
          ),
          child: Text(
            switch (workspaceMode) {
              EditorWorkspaceMode.map => 'Scene',
              EditorWorkspaceMode.tileset => 'Library',
              EditorWorkspaceMode.trainer => 'Trainer',
              EditorWorkspaceMode.pokedex => 'Catalogues',
              EditorWorkspaceMode.globalStory => 'Global',
              EditorWorkspaceMode.step => 'Step',
              EditorWorkspaceMode.cutscene => 'Cutscene',
              EditorWorkspaceMode.dialogue => 'Dialogue',
            },
            style: TextStyle(
              color: chipAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.4),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.38, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Panneau droit volontairement neutre pour les workspaces qui n'ont pas
/// encore d'inspecteur réel.
///
/// Pour le lot 12, cela permet de garder la structure visuelle existante de
/// l'éditeur sans inventer un inspecteur Pokédex artificiel, ni brancher une
/// logique future avant l'heure.
class _EmptyWorkspaceInspector extends StatelessWidget {
  const _EmptyWorkspaceInspector();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Cette section n’a pas encore d’inspecteur dédié.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

bool _isTextInputFocused() {
  final focusedContext = FocusManager.instance.primaryFocus?.context;
  if (focusedContext == null) return false;
  return focusedContext.widget is EditableText ||
      focusedContext.findAncestorWidgetOfExactType<EditableText>() != null;
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

```


### `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import 'project_explorer/dialogs/import_tileset_dialog.dart';
import 'project_explorer/dialogs/tileset_library_dialogs.dart';
import 'project_explorer/dialogs/world_group_dialogs.dart';
import 'project_explorer/widgets/sidebar_header_action.dart';
import 'project_explorer/widgets/tree/tileset_tree_nodes.dart';
import 'project_explorer/widgets/tree/world_tree_nodes.dart';
import 'character_library_panel.dart';
import 'narrative_library_panel.dart';
import 'terrain_editor_panel.dart';
import 'trainer_library_panel.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_section_card.dart';

class ProjectExplorerPanel extends ConsumerStatefulWidget {
  const ProjectExplorerPanel({super.key});

  @override
  ConsumerState<ProjectExplorerPanel> createState() =>
      _ProjectExplorerPanelState();
}

class _ProjectExplorerPanelState extends ConsumerState<ProjectExplorerPanel> {
  bool _expandTileLib = true;
  bool _expandPokedex = true;
  bool _expandNarrative = true;
  bool _expandWorld = true;
  bool _expandTerrains = true;
  bool _expandPaths = true;
  bool _expandTrainers = false;
  bool _expandCharacters = false;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(editorProjectExplorerSnapshotProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = snapshot.project;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: project == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 2),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Open a project to browse your world, maps and tilesets.',
                              style: TextStyle(
                                color: CupertinoColors.placeholderText
                                    .resolveFrom(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    primary: false,
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 10),
                        _buildTree(context, project, snapshot, notifier),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    const explorerAccent = EditorChrome.inspectorJoyCyan;
    const explorerDeep = EditorChrome.inspectorJoyPlum;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(CupertinoColors.white, explorerAccent, 0.78)!,
                  Color.lerp(explorerDeep, const Color(0xFF140818), 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: explorerAccent.withValues(alpha: 0.88),
                width: 1.15,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              CupertinoIcons.square_stack_3d_up,
              size: 18,
              color: CupertinoColors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'World Explorer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cartes, tilesets, surfaces — dialogues dans Dialogue Studio',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTree(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final rootMaps = project.maps.where((m) => m.groupId == null).toList();
    final rootGroups =
        project.groups.where((g) => g.parentGroupId == null).toList();

    final worldChildren = <Widget>[
      ...rootGroups.map(
        (g) => GroupNode(
          group: g,
          project: project,
          snapshot: snapshot,
          notifier: notifier,
          depth: 0,
        ),
      ),
      if (rootMaps.isNotEmpty) ...[
        const EditorSidebarSectionTitle('UNGROUPED MAPS', leftInset: 6),
        ...rootMaps.map(
          (m) => MapNode(
            map: m,
            snapshot: snapshot,
            notifier: notifier,
            depth: 0,
          ),
        ),
      ],
      if (rootGroups.isEmpty && rootMaps.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'World is empty',
                style: TextStyle(
                  color: CupertinoColors.placeholderText.resolveFrom(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              PushButton(
                controlSize: ControlSize.regular,
                onPressed: () => showCreateGroupDialog(context, notifier),
                child: const Text('Add City or Route'),
              ),
            ],
          ),
        ),
    ];

    final screenH = MediaQuery.sizeOf(context).height;
    final hTileset = (screenH * 0.30).clamp(240.0, 400.0);
    final hPokedex = (screenH * 0.22).clamp(180.0, 260.0);
    final hNarrative = (screenH * 0.34).clamp(260.0, 460.0);
    final hWorld = (screenH * 0.30).clamp(240.0, 400.0);
    final hTerrains = (screenH * 0.36).clamp(280.0, 500.0);
    final hPaths = (screenH * 0.36).clamp(280.0, 500.0);
    final hTrainers = (screenH * 0.18).clamp(180.0, 240.0);
    final hCharacters = (screenH * 0.35).clamp(260.0, 480.0);
    const explorerTileRadius = 28.0;
    final actionIcon = CupertinoColors.white.withValues(alpha: 0.92);
    final actionHover = CupertinoColors.white.withValues(alpha: 0.16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Tileset Library',
          subtitle: 'Folders, imports, and map painting',
          icon: CupertinoIcons.square_grid_2x2,
          accentColor: EditorChrome.inspectorJoyBlue,
          badgeText: '${project.tilesets.length}',
          expanded: _expandTileLib,
          onToggle: () => setState(() => _expandTileLib = !_expandTileLib),
          expandedHeight: hTileset,
          headerTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SidebarHeaderAction(
                enabled: true,
                icon: CupertinoIcons.photo_on_rectangle,
                tooltip: 'Import tileset',
                onPressed: () =>
                    showImportTilesetDialog(context, snapshot, notifier),
                iconColor: actionIcon,
                hoverFill: actionHover,
              ),
              const SizedBox(width: 6),
              SidebarHeaderAction(
                enabled: true,
                icon: CupertinoIcons.plus_circle_fill,
                tooltip: 'New folder',
                onPressed: () => promptNewTilesetLibraryFolder(
                  context,
                  notifier,
                ),
                iconColor: actionIcon,
                hoverFill: actionHover,
              ),
            ],
          ),
          child: _buildTilesetsIsland(context, project, snapshot, notifier),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Catalogues Pokémon',
          subtitle: 'Pokédex, Moves et Items dans un espace guidé unique',
          icon: CupertinoIcons.book_fill,
          accentColor: EditorChrome.inspectorJoyAmber,
          expanded: _expandPokedex,
          onToggle: () => setState(() => _expandPokedex = !_expandPokedex),
          expandedHeight: hPokedex,
          child: _buildPokedexPlaceholderCard(context, snapshot, notifier),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Narrative Studio',
          subtitle:
              'Global Story, Steps, Cutscenes and outcomes (opens central workspaces)',
          icon: CupertinoIcons.link_circle_fill,
          accentColor: EditorChrome.inspectorJoyCyan,
          badgeText: '${project.scenarios.length}',
          expanded: _expandNarrative,
          onToggle: () => setState(() => _expandNarrative = !_expandNarrative),
          expandedHeight: hNarrative,
          child: const NarrativeLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'World Maps',
          subtitle:
              'Maps jouables et contenu monde (events, entités, warps, triggers)',
          icon: CupertinoIcons.map_fill,
          accentColor: EditorChrome.inspectorJoyPlum,
          badgeText: '${project.maps.length}',
          expanded: _expandWorld,
          onToggle: () => setState(() => _expandWorld = !_expandWorld),
          expandedHeight: hWorld,
          headerTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SidebarHeaderAction(
                enabled: true,
                icon: CupertinoIcons.folder_badge_plus,
                tooltip: 'New root group',
                onPressed: () => showCreateGroupDialog(context, notifier),
                iconColor: actionIcon,
                hoverFill: actionHover,
              ),
            ],
          ),
          child: _buildWorldIslandBody(context, worldChildren),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Terrain Library',
          subtitle: 'Base ground presets',
          icon: CupertinoIcons.map,
          accentColor: EditorChrome.accentJade,
          badgeText: '${project.terrainPresets.length}',
          expanded: _expandTerrains,
          onToggle: () => setState(() => _expandTerrains = !_expandTerrains),
          expandedHeight: hTerrains,
          child: const TerrainLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Path Library',
          subtitle: 'Surface overlays: roads, water, tall grass...',
          icon: CupertinoIcons.arrow_branch,
          accentColor: EditorChrome.accentWarm,
          badgeText: '${project.pathPresets.length}',
          expanded: _expandPaths,
          onToggle: () => setState(() => _expandPaths = !_expandPaths),
          expandedHeight: hPaths,
          child: const PathLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Trainer Studio',
          subtitle: 'Battle rosters and teams (opens the central workspace)',
          icon: CupertinoIcons.person_2_fill,
          accentColor: EditorChrome.accentCoral,
          badgeText: '${project.trainers.length}',
          expanded: _expandTrainers,
          onToggle: () => setState(() => _expandTrainers = !_expandTrainers),
          expandedHeight: hTrainers,
          child: const TrainerLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Character Library',
          subtitle: 'Overworld sprites for the player and NPCs',
          icon: CupertinoIcons.person_crop_circle,
          accentColor: EditorChrome.inspectorJoyCyan,
          badgeText: '${project.characters.length}',
          expanded: _expandCharacters,
          onToggle: () =>
              setState(() => _expandCharacters = !_expandCharacters),
          expandedHeight: hCharacters,
          child: const CharacterLibraryPanel(embedded: true),
        ),
      ],
    );
  }

  Widget _buildTilesetsIsland(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 8),
      child: _buildTilesetsSection(context, project, snapshot, notifier),
    );
  }

  Widget _buildPokedexPlaceholderCard(
    BuildContext context,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final selected = snapshot.workspaceMode == EditorWorkspaceMode.pokedex;
    final subtle = CupertinoColors.placeholderText.resolveFrom(context);

    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EditorSidebarListRow(
            key: const Key('pokedex-explorer-entry'),
            selected: selected,
            onTap: notifier.selectPokedexWorkspace,
            leading: const MacosIcon(CupertinoIcons.book),
            title: const Text('Pokédex'),
            subtitle: const Text(
              'Recherche, import, détail et édition locale des espèces',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Text(
              'Cette entrée ouvre le pôle Catalogues Pokémon du projet. Le sous-espace Pokédex est déjà fonctionnel, tandis que Moves et Items sont préparés comme shells propres pour les prochains lots.',
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldIslandBody(
    BuildContext context,
    List<Widget> worldChildren,
  ) {
    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: worldChildren,
      ),
    );
  }

  Widget _buildTilesetsSection(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final selectedTilesetId = snapshot.selectedTilesetEntry?.id;
    final tree = buildTilesetLibraryTree(project);

    String scopeLabel(ProjectTilesetEntry t) {
      if (t.scope == TilesetScope.global) return 'Global';
      final gid = t.groupId;
      if (gid == null) return 'Group';
      for (final g in project.groups) {
        if (g.id == gid) return g.name;
      }
      return 'Group';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TilesetLibraryRootDropStrip(project: project, notifier: notifier),
        if (project.tilesets.isEmpty && project.tilesetFolders.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Text(
              'No tilesets yet. Import an image or create folders to organize your library.',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
                fontSize: 12,
              ),
            ),
          ),
        ...tree.rootFolders.map(
          (branch) => TilesetLibraryFolderNode(
            branch: branch,
            depth: 0,
            project: project,
            notifier: notifier,
            selectedTilesetId: selectedTilesetId,
            scopeLabel: scopeLabel,
          ),
        ),
        ...tree.rootTilesets.map(
          (tileset) => TilesetNode(
            tileset: tileset,
            project: project,
            notifier: notifier,
            selected: selectedTilesetId == tileset.id,
            leftIndent: 14,
            scopeLabel: scopeLabel(tileset),
          ),
        ),
      ],
    );
  }
}

```


### `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`

```dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/models/terrain_selection_mode.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/tools/editor_tool.dart';
import 'cupertino_editor_widgets.dart';
import 'top_toolbar/dialogs/top_toolbar_dialogs.dart';
import 'top_toolbar/widgets/toolbar_brand.dart';
import 'top_toolbar/widgets/toolbar_capsules.dart';

/// Exposé pour [MacosScaffold.toolBar], qui attend un [ToolBar] typé (pas un [ConsumerWidget]).
ToolBar buildMapEditorToolbar(BuildContext context, WidgetRef ref) =>
    TopToolbar.buildToolBar(context, ref);

/// Barre d’outils native [macos_ui] pour [MacosScaffold].
class TopToolbar extends ConsumerWidget {
  const TopToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      TopToolbar.buildToolBar(context, ref);

  static List<MacosPulldownMenuEntry> _terrainPulldownItems(
    EditorNotifier notifier,
  ) {
    return TerrainType.values
        .where((t) => t.isBackgroundPaintable)
        .map(
          (terrain) => MacosPulldownMenuItem(
            label: _terrainTypeLabel(terrain),
            title: Text(_terrainTypeLabel(terrain)),
            onTap: () => notifier.selectTerrainType(terrain),
          ),
        )
        .toList();
  }

  static List<MacosPulldownMenuEntry> _entityKindPulldownItems(
    EditorNotifier notifier,
  ) {
    return MapEntityKind.values
        .map(
          (kind) => MacosPulldownMenuItem(
            label: _entityKindLabel(kind),
            title: Text(_entityKindLabel(kind)),
            onTap: () => notifier.selectEntityKind(kind),
          ),
        )
        .toList(growable: false);
  }

  static ToolBar buildToolBar(BuildContext context, WidgetRef ref) {
    final toolbar = ref.watch(editorToolbarSnapshotProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final settings = toolbar.settings;
    final subtle = EditorChrome.subtleLabel(context);

    final map = toolbar.activeMap;
    final isMapWorkspace = toolbar.workspaceMode == EditorWorkspaceMode.map;
    final hasTilesets = (toolbar.project?.tilesets.isNotEmpty ?? false);
    final firstTilesetId =
        hasTilesets ? toolbar.project!.tilesets.first.id : null;
    final hasMapCanvas = map != null;
    final showWorldTools = isMapWorkspace && hasMapCanvas;
    final activeLayer = toolbar.activeLayer;

    final canEraseOnActiveLayer = activeLayer is TileLayer ||
        activeLayer is CollisionLayer ||
        activeLayer is TerrainLayer ||
        activeLayer is PathLayer;

    final showTerrainTypePulldown = activeLayer is TerrainLayer &&
        toolbar.activeTool == EditorToolType.terrainPaint &&
        toolbar.terrainSelectionMode == TerrainSelectionMode.terrain;
    final showEntityKindPulldown =
        toolbar.activeTool == EditorToolType.entityPlacement;
    final showContextStrip =
        showWorldTools && (showTerrainTypePulldown || showEntityKindPulldown);

    final showCollisionBrushSize = activeLayer is CollisionLayer &&
        (toolbar.activeTool == EditorToolType.collisionPaint ||
            toolbar.activeTool == EditorToolType.eraser);

    final actions = <ToolbarItem>[
      _groupItem(
        context,
        overflowLabel: 'Project',
        children: [
          ToolbarCapsuleButton(
            icon: CupertinoIcons.folder_badge_plus,
            tooltip: 'New Project',
            onPressed: () => showTopToolbarNewProjectDialog(
              context,
              notifier,
            ),
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.folder_open,
            tooltip: 'Open Project',
            onPressed: () async {
              final selectedDirectory =
                  await FilePicker.platform.getDirectoryPath();
              if (selectedDirectory != null) {
                final manifestPath = p.join(selectedDirectory, 'project.json');
                await notifier.loadProject(manifestPath);
              }
            },
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.placemark,
            tooltip: 'New Map',
            onPressed:
                toolbar.project != null && toolbar.projectRootPath != null
                    ? () => showTopToolbarNewMapDialog(
                          context,
                          notifier,
                          defaultWidth: settings.defaultMapWidth,
                          defaultHeight: settings.defaultMapHeight,
                        )
                    : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.gear,
            tooltip: 'Project Settings',
            onPressed: toolbar.project != null
                ? () => showTopToolbarProjectSettingsDialog(
                      context,
                      notifier,
                      toolbar.project!,
                    )
                : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.rectangle_arrow_up_right_arrow_down_left,
            tooltip: 'Resize Map',
            onPressed: isMapWorkspace && toolbar.activeMap != null
                ? () => showTopToolbarResizeMapDialog(
                      context,
                      notifier,
                      currentWidth: toolbar.activeMap!.size.width,
                      currentHeight: toolbar.activeMap!.size.height,
                    )
                : null,
          ),
        ],
      ),
      _groupItem(
        context,
        overflowLabel: 'History',
        children: [
          if (toolbar.isSaving)
            const SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: ProgressCircle(),
              ),
            )
          else
            ToolbarCapsuleButton(
              icon: CupertinoIcons.floppy_disk,
              tooltip: 'Save Map',
              selected: toolbar.isDirty,
              onPressed: toolbar.activeMap != null
                  ? () => notifier.saveActiveMap()
                  : null,
            ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.arrow_uturn_left,
            tooltip: 'Undo',
            onPressed: toolbar.canUndoMap ? notifier.undoMap : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.arrow_uturn_right,
            tooltip: 'Redo',
            onPressed: toolbar.canRedoMap ? notifier.redoMap : null,
          ),
        ],
      ),
      _groupItem(
        context,
        overflowLabel: 'Workspace',
        children: [
          ToolbarCapsuleButton(
            icon: CupertinoIcons.map,
            tooltip: 'Switch to map workspace',
            selected: isMapWorkspace,
            onPressed: notifier.selectMapWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.square_grid_2x2,
            tooltip: 'Switch to tileset workspace',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.tileset,
            onPressed: hasTilesets
                ? () => notifier.selectTilesetWorkspace(
                      toolbar.selectedTilesetEntry?.id ?? firstTilesetId,
                    )
                : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.person_3_fill,
            tooltip: 'Switch to Trainer Studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.trainer,
            onPressed: toolbar.project != null
                ? notifier.selectTrainerWorkspace
                : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.book,
            tooltip: 'Switch to Catalogues Pokémon',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.pokedex,
            onPressed: toolbar.project != null
                ? notifier.selectPokedexWorkspace
                : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.link,
            tooltip: 'Switch to global story workspace',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.globalStory,
            onPressed: notifier.selectGlobalStoryWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.flag,
            tooltip: 'Switch to Step Studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.step,
            onPressed: notifier.selectStepWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.play_rectangle,
            tooltip: 'Switch to Cutscene Studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.cutscene,
            onPressed: notifier.selectCutsceneWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.text_bubble,
            tooltip: 'Switch to dialogue studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.dialogue,
            onPressed: notifier.selectDialogueWorkspace,
          ),
        ],
      ),
      if (showWorldTools)
        _groupItem(
          context,
          overflowLabel: 'Painting Tools',
          children: [
            ToolbarCapsuleButton(
              icon: CupertinoIcons.selection_pin_in_out,
              tooltip: 'Selection Tool',
              selected: toolbar.activeTool == EditorToolType.selection,
              onPressed: () => notifier.selectTool(EditorToolType.selection),
            ),
            if (activeLayer is TileLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.paintbrush,
                tooltip: 'Tile Paint Tool',
                selected: toolbar.activeTool == EditorToolType.tilePaint,
                onPressed: () => notifier.selectTool(EditorToolType.tilePaint),
              ),
            if (activeLayer is TerrainLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.tree,
                tooltip: 'Terrain Paint Tool',
                selected: toolbar.activeTool == EditorToolType.terrainPaint &&
                    toolbar.terrainSelectionMode ==
                        TerrainSelectionMode.terrain,
                onPressed: () =>
                    notifier.selectTool(EditorToolType.terrainPaint),
              ),
            if (activeLayer is PathLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.map,
                tooltip: 'Path Paint Tool',
                selected: toolbar.activeTool == EditorToolType.terrainPaint &&
                    toolbar.terrainSelectionMode == TerrainSelectionMode.path,
                onPressed: notifier.selectPathPaintMode,
              ),
            if (activeLayer is CollisionLayer) ...[
              ToolbarCapsuleButton(
                icon: CupertinoIcons.square_grid_2x2,
                tooltip: 'Collision Paint Tool',
                selected: toolbar.activeTool == EditorToolType.collisionPaint,
                onPressed: () => notifier.selectTool(
                  EditorToolType.collisionPaint,
                ),
              ),
              if (showCollisionBrushSize)
                ToolbarCapsuleButton(
                  icon: toolbar.collisionBrushSizeMode ==
                          CollisionBrushSizeMode.singleTile
                      ? CupertinoIcons.number
                      : CupertinoIcons.square_grid_3x2,
                  tooltip: toolbar.collisionBrushSizeMode ==
                          CollisionBrushSizeMode.singleTile
                      ? 'Collision Brush Size: 1x1'
                      : 'Collision Brush Size: Brush Footprint',
                  selected:
                      toolbar.activeTool == EditorToolType.collisionPaint ||
                          toolbar.activeTool == EditorToolType.eraser,
                  onPressed: notifier.toggleCollisionBrushSizeMode,
                ),
            ],
            if (canEraseOnActiveLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.delete,
                tooltip: 'Eraser Tool',
                selected: toolbar.activeTool == EditorToolType.eraser,
                onPressed: () => notifier.selectTool(EditorToolType.eraser),
              ),
          ],
        ),
      if (showWorldTools)
        _groupItem(
          context,
          overflowLabel: 'Gameplay Tools',
          children: [
            ToolbarCapsuleButton(
              icon: CupertinoIcons.sparkles,
              tooltip: 'Entity Tool',
              selected: toolbar.activeTool == EditorToolType.entityPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.entityPlacement,
              ),
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.flag,
              tooltip: 'Event Tool',
              selected: toolbar.activeTool == EditorToolType.eventPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.eventPlacement,
              ),
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.square,
              tooltip: 'Trigger Tool',
              selected: toolbar.activeTool == EditorToolType.triggerPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.triggerPlacement,
              ),
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.arrow_branch,
              tooltip: 'Warp Tool',
              selected: toolbar.activeTool == EditorToolType.warpPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.warpPlacement,
              ),
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.leaf_arrow_circlepath,
              tooltip: 'Gameplay Zone Tool',
              selected:
                  toolbar.activeTool == EditorToolType.gameplayZonePlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.gameplayZonePlacement,
              ),
            ),
          ],
        ),
      if (showContextStrip)
        _groupItem(
          context,
          overflowLabel: 'Context',
          children: [
            if (showTerrainTypePulldown)
              ToolbarCapsulePulldown(
                label: _terrainTypeLabel(toolbar.selectedTerrainType),
                items: _terrainPulldownItems(notifier),
              ),
            if (showEntityKindPulldown)
              ToolbarCapsulePulldown(
                label: _entityKindLabel(toolbar.selectedEntityKind),
                items: _entityKindPulldownItems(notifier),
              ),
          ],
        ),
      _groupItem(
        context,
        overflowLabel: 'View',
        children: [
          ToolbarCapsuleButton(
            icon: CupertinoIcons.minus_circle,
            tooltip: 'Zoom Out',
            onPressed: () => notifier.zoom(-0.1),
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.plus_circle,
            tooltip: 'Zoom In',
            onPressed: () => notifier.zoom(0.1),
          ),
        ],
      ),
      const ToolBarSpacer(spacerUnits: 4),
      if (toolbar.statusMessage != null)
        CustomToolbarItem(
          inToolbarBuilder: (_) => Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color.lerp(
                EditorChrome.badgeFill(context),
                EditorChrome.chipFill(context),
                0.45,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              toolbar.statusMessage!,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          inOverflowedBuilder: (_) => const ToolbarOverflowMenuItem(
            label: 'Status',
            onPressed: null,
          ),
        ),
    ];

    return ToolBar(
      title: TopToolbarBrand(
        projectName: toolbar.project?.name,
        workspaceLabel: switch (toolbar.workspaceMode) {
          EditorWorkspaceMode.map => 'World Editor',
          EditorWorkspaceMode.tileset => 'Tileset Studio',
          EditorWorkspaceMode.trainer => 'Trainer Studio',
          EditorWorkspaceMode.pokedex => 'Catalogues Pokémon',
          EditorWorkspaceMode.globalStory => 'Global Story',
          EditorWorkspaceMode.step => 'Step Studio',
          EditorWorkspaceMode.cutscene => 'Cutscene Studio',
          EditorWorkspaceMode.dialogue => 'Dialogue Studio',
        },
      ),
      titleWidth: 236,
      automaticallyImplyLeading: false,
      centerTitle: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      dividerColor: MacosColors.transparent,
      decoration: BoxDecoration(
        color: EditorChrome.toolbarBarFill(context),
      ),
      actions: actions,
    );
  }

  static CustomToolbarItem _groupItem(
    BuildContext context, {
    required String overflowLabel,
    required List<Widget> children,
  }) {
    return CustomToolbarItem(
      inToolbarBuilder: (_) => ToolbarCapsuleGroup(children: children),
      inOverflowedBuilder: (_) => ToolbarOverflowMenuItem(
        label: overflowLabel,
        onPressed: null,
      ),
    );
  }

  static String _terrainTypeLabel(TerrainType type) {
    return switch (type) {
      TerrainType.none => 'None',
      TerrainType.grass => 'Grass Base',
      TerrainType.dirt => 'Dirt Base',
      TerrainType.sand => 'Sand Base',
      TerrainType.rock => 'Rock Base',
      TerrainType.stone => 'Stone Base',
      TerrainType.indoor => 'Indoor Base',
    };
  }

  static String _entityKindLabel(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => 'NPC',
      MapEntityKind.sign => 'Sign',
      MapEntityKind.item => 'Item',
      MapEntityKind.spawn => 'Spawn',
      MapEntityKind.custom => 'Custom',
    };
  }
}

```


### `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace.dart`

```dart
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

```


### `packages/map_editor/test/editor_selectors_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_selectors.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('editor selectors', () {
    test('editorShellSnapshotProvider derives map title and save affordance',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 12, height: 8),
          layers: [
            TileLayer(
              id: 'ground',
              name: 'Ground',
              tilesetId: 'world',
              tiles: [],
            ),
          ],
        ),
        canUndoMap: true,
      );

      final shell = container.read(editorShellSnapshotProvider);
      expect(shell.workspaceTitle, 'Starter Town');
      expect(shell.workspaceSubtitle, contains('12 x 8 tiles'));
      expect(shell.canUndoMap, isTrue);
      expect(shell.canSaveMap, isTrue);
    });

    test('editorToolbarSnapshotProvider resolves selected tileset from layer',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'world',
              name: 'World',
              relativePath: 'tilesets/world.json',
            ),
          ],
        ),
        activeMap: MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 8, height: 8),
          layers: [
            TileLayer(
              id: 'ground',
              name: 'Ground',
              tilesetId: 'world',
              tiles: [],
            ),
          ],
        ),
        activeLayerId: 'ground',
      );

      final toolbar = container.read(editorToolbarSnapshotProvider);
      expect(toolbar.selectedTilesetEntry?.id, 'world');
      expect(toolbar.activeLayer, isA<TileLayer>());
    });

    test('editorProjectExplorerSnapshotProvider exposes active map selection',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.pokedex,
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
        activeMap: MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 8, height: 8),
          layers: [],
        ),
      );

      final snapshot = container.read(editorProjectExplorerSnapshotProvider);
      expect(snapshot.workspaceMode, EditorWorkspaceMode.pokedex);
      expect(snapshot.activeMapId, 'town');
      expect(snapshot.project?.name, 'demo');
    });

    test('editorShellSnapshotProvider exposes trainer studio labels', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.trainer,
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
      );

      final shell = container.read(editorShellSnapshotProvider);
      expect(shell.workspaceTitle, 'Trainer Studio');
      expect(
        shell.workspaceSubtitle,
        contains('battle-ready rosters'),
      );
    });

    test('editorShellSnapshotProvider exposes Pokémon catalogs labels', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.pokedex,
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
      );

      final shell = container.read(editorShellSnapshotProvider);
      expect(shell.workspaceTitle, 'Catalogues Pokémon');
      expect(shell.workspaceSubtitle, contains('Pokédex, Moves et Items'));
    });

    test('editorTerrainLibrarySnapshotProvider exposes preset selection inputs',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'world',
              name: 'World',
              relativePath: 'tilesets/world.json',
            ),
          ],
        ),
        selectedTerrainType: TerrainType.grass,
        selectedTerrainPresetId: 'terrain.grass',
        selectedPathPresetId: 'path.route',
      );

      final snapshot = container.read(editorTerrainLibrarySnapshotProvider);
      expect(snapshot.project?.name, 'demo');
      expect(snapshot.tilesets.map((entry) => entry.id), ['world']);
      expect(snapshot.selectedTerrainPresetId, 'terrain.grass');
      expect(snapshot.selectedPathPresetId, 'path.route');
    });

    test('editorTilesetPaletteSnapshotProvider exposes palette panel state',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/project',
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'world',
              name: 'World',
              relativePath: 'tilesets/world.json',
            ),
          ],
        ),
        activeMap: MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 8, height: 8),
          layers: [
            TileLayer(
              id: 'ground',
              name: 'Ground',
              tilesetId: 'world',
              tiles: [],
            ),
          ],
        ),
        activeLayerId: 'ground',
        activeBrush: EditorBrush.tile(tileId: 7, tilesetId: 'world'),
        paletteCategoryFilter: PaletteCategory.floors,
        selectedTilesetElementGroupId: 'group_a',
        tilesElementsPanelMode: TilesElementsPanelMode.placedInstances,
        selectedPlacedElementInstanceId: 'instance_1',
      );

      final snapshot = container.read(editorTilesetPaletteSnapshotProvider);
      expect(snapshot.selectedTilesetEntry?.id, 'world');
      expect(snapshot.projectRootPath, '/tmp/project');
      expect(snapshot.activeLayerId, 'ground');
      expect(snapshot.paletteCategoryFilter, PaletteCategory.floors);
      expect(
        snapshot.tilesElementsPanelMode,
        TilesElementsPanelMode.placedInstances,
      );
      expect(snapshot.selectedPlacedElementInstanceId, 'instance_1');
    });
  });
}

```


### `packages/map_editor/test/editor_shell_page_smoke_test.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  group('EditorShellPage smoke', () {
    testWidgets('renders map workspace chrome and toggles the right panel',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_smoke',
          project: buildShellChromeProject(),
        ),
      );

      expect(find.text('Map Workspace'), findsOneWidget);
      expect(
        find.text('Open a map to start building your world.'),
        findsOneWidget,
      );
      expect(find.text('Ready'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Hide right panel',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Hide right panel',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Show right panel',
        ),
        findsOneWidget,
      );
    });

    testWidgets('updates the workspace header for tileset mode',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_tileset',
          project: buildShellChromeProject(
            tilesets: const <ProjectTilesetEntry>[
              ProjectTilesetEntry(
                id: 'indoor',
                name: 'Indoor',
                relativePath: 'tilesets/indoor.json',
              ),
            ],
          ),
          workspaceMode: EditorWorkspaceMode.tileset,
          selectedTilesetEditorId: 'indoor',
        ),
      );

      expect(find.text('Indoor'), findsAtLeastNWidgets(1));
      expect(
        find.text(
          'Visual library editing for tiles, elements and groups.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders the trainer studio workspace chrome', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_trainer',
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.trainer,
        ),
      );

      expect(find.text('Trainer Studio'), findsWidgets);
      expect(
        find.textContaining('battle-ready rosters'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('trainer-library-new-trainer-button')),
        findsOneWidget,
      );
    });

    testWidgets('renders the Pokémon catalogs workspace shell', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_catalogs',
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.pokedex,
        ),
        overrides: [
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );

      expect(find.text('Catalogues Pokémon'), findsWidgets);
      expect(find.byKey(const Key('pokemon-catalogs-tabs')), findsOneWidget);
      expect(find.textContaining('Pokédex est encore vide'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              (widget.semanticLabel == 'Hide right panel' ||
                  widget.semanticLabel == 'Show right panel'),
        ),
        findsNothing,
      );
    });

    testWidgets('renders shell chrome with an error state already present',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_error',
          project: buildShellChromeProject(),
          errorMessage: 'Shell render failure',
        ),
      );

      expect(find.text('Shell render failure'), findsOneWidget);
    });
  });
}

```


### `packages/map_editor/test/shell_chrome_test_harness.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';
import 'package:map_editor/src/ui/shared/status_bar.dart';
import 'package:map_editor/src/ui/shared/top_toolbar.dart';

ProjectManifest buildShellChromeProject({
  String name = 'Demo Project',
  List<ProjectMapEntry> maps = const <ProjectMapEntry>[],
  List<ProjectTilesetEntry> tilesets = const <ProjectTilesetEntry>[],
}) {
  return ProjectManifest(
    name: name,
    maps: maps,
    tilesets: tilesets,
  );
}

MapData buildShellChromeMap({
  String id = 'route_1',
  String name = 'Route 1',
  int width = 20,
  int height = 15,
  List<MapLayer> layers = const <MapLayer>[],
}) {
  return MapData(
    id: id,
    name: name,
    size: GridSize(width: width, height: height),
    layers: layers,
  );
}

Future<ProviderContainer> pumpEditorShellPage(
  WidgetTester tester, {
  required EditorState initialState,
  Size surfaceSize = const Size(1600, 1000),
  List<Override> overrides = const <Override>[],
}) async {
  final container = ProviderContainer(overrides: overrides);
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    editorStateSubscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump();
    container.dispose();
  });

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // The shell auto-restore schedules a post-frame call into the notifier.
  // Tests seed a concrete editor state up front so the restore path exits
  // immediately and the shell stays focused on UI contracts only.
  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MacosApp(
        home: EditorShellPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  return container;
}

Future<ProviderContainer> pumpTopToolbarHarness(
  WidgetTester tester, {
  required EditorState initialState,
  Size surfaceSize = const Size(1280, 220),
}) async {
  final container = ProviderContainer();
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    editorStateSubscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump();
    container.dispose();
  });

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MacosApp(
        home: _TopToolbarHarness(),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  return container;
}

Future<ProviderContainer> pumpStatusBarHarness(
  WidgetTester tester, {
  required EditorState initialState,
  Size surfaceSize = const Size(900, 180),
}) async {
  final container = ProviderContainer();
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    editorStateSubscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump();
    container.dispose();
  });

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MacosApp(
        home: _StatusBarHarness(),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  return container;
}

class _TopToolbarHarness extends ConsumerWidget {
  const _TopToolbarHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CupertinoPageScaffold(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 1200,
          child: TopToolbar(
            key: Key('top-toolbar-under-test'),
          ),
        ),
      ),
    );
  }
}

class _StatusBarHarness extends StatelessWidget {
  const _StatusBarHarness();

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 860,
          child: StatusBar(),
        ),
      ),
    );
  }
}

```


### `packages/map_editor/test/top_toolbar_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  group('TopToolbar', () {
    testWidgets('shows the app brand and project workspace label',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_project',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.pokedex,
        ),
      );

      expect(find.text('RPG Map Editor'), findsOneWidget);
      expect(find.text('Pokemon Map  •  Catalogues Pokémon'), findsOneWidget);
    });

    testWidgets('falls back to the workspace label when no project is loaded',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: const EditorState(),
      );

      expect(find.text('RPG Map Editor'), findsOneWidget);
      expect(find.text('World Editor'), findsOneWidget);
    });

    testWidgets('shows the toolbar status chip when a status is present',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_status',
          project: buildShellChromeProject(),
          statusMessage: 'Map saved',
        ),
      );

      expect(find.text('Map saved'), findsOneWidget);
    });

    testWidgets('shows the trainer studio label for the trainer workspace',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_trainer',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.trainer,
        ),
      );

      expect(find.text('Pokemon Map  •  Trainer Studio'), findsOneWidget);
    });
  });
}

```


### `packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

void main() {
  testWidgets('ProjectExplorerPanel shows a Catalogues Pokémon entry tile',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokemon_catalogs_project_explorer',
      project: ProjectManifest(
        name: 'catalogs_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
    );

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 980);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 360,
                height: 900,
                child: ProjectExplorerPanel(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Catalogues Pokémon'), findsOneWidget);
    expect(
      find.text('Pokédex, Moves et Items dans un espace guidé unique'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pokedex-explorer-entry')), findsOneWidget);
    expect(find.text('Pokédex'), findsWidgets);
  });
}

```


### `packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/pokemon_catalogs_workspace.dart';

Future<void> _pumpCatalogsWorkspace(
  WidgetTester tester, {
  required ProviderContainer container,
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 980));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosApp(
        home: MacosTheme(
          data: MacosThemeData.light(),
          child: const CupertinoPageScaffold(
            child: SizedBox.expand(
              child: PokemonCatalogsWorkspace(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

ProjectManifest _project() {
  return const ProjectManifest(
    name: 'Catalogs Test Project',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'lab',
        name: 'Lab',
        relativePath: 'maps/lab.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
  );
}

Widget _buildCatalogsHost({
  required ProviderContainer container,
  required PageStorageBucket bucket,
  required bool showWorkspace,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MacosApp(
      home: MacosTheme(
        data: MacosThemeData.light(),
        child: CupertinoPageScaffold(
          child: PageStorage(
            bucket: bucket,
            child: SizedBox.expand(
              child: showWorkspace
                  ? const PokemonCatalogsWorkspace()
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('PokemonCatalogsWorkspace', () {
    testWidgets(
        'shows Catalogues Pokémon navigation and defaults to the real Pokédex workspace',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/pokemon_catalogs_workspace_test',
        project: _project(),
        workspaceMode: EditorWorkspaceMode.pokedex,
      );

      await _pumpCatalogsWorkspace(
        tester,
        container: container,
      );

      expect(find.text('Choisissez un catalogue.'), findsOneWidget);
      expect(find.byKey(const Key('pokemon-catalogs-tabs')), findsOneWidget);
      expect(find.byKey(const Key('pokemon-catalogs-tab-pokedex')),
          findsOneWidget);
      expect(
          find.byKey(const Key('pokemon-catalogs-tab-moves')), findsOneWidget);
      expect(
          find.byKey(const Key('pokemon-catalogs-tab-items')), findsOneWidget);
      expect(find.textContaining('Pokédex est encore vide'), findsOneWidget);
    });

    testWidgets('opens the Moves shell without crashing', (tester) async {
      final container = ProviderContainer(
        overrides: [
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/pokemon_catalogs_moves_test',
        project: _project(),
        workspaceMode: EditorWorkspaceMode.pokedex,
      );

      await _pumpCatalogsWorkspace(
        tester,
        container: container,
      );

      await tester.tap(find.byKey(const Key('pokemon-catalogs-tab-moves')));
      await tester.pumpAndSettle();

      expect(find.text('Moves'), findsWidgets);
      expect(
        find.text('Le futur catalogue des capacités du projet vivra ici.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Pokédex > Learnset'),
        findsOneWidget,
      );
      expect(find.textContaining('lot dédié'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens the Items shell without crashing', (tester) async {
      final container = ProviderContainer(
        overrides: [
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/pokemon_catalogs_items_test',
        project: _project(),
        workspaceMode: EditorWorkspaceMode.pokedex,
      );

      await _pumpCatalogsWorkspace(
        tester,
        container: container,
      );

      await tester.tap(find.byKey(const Key('pokemon-catalogs-tab-items')));
      await tester.pumpAndSettle();

      expect(find.text('Items'), findsWidgets);
      expect(
        find.text('Le futur catalogue des objets du projet vivra ici.'),
        findsOneWidget,
      );
      expect(find.textContaining('structure de workspace'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('restores the selected section after remounting the workspace',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );
      addTearDown(container.dispose);
      final bucket = PageStorageBucket();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/pokemon_catalogs_restore_test',
        project: _project(),
        workspaceMode: EditorWorkspaceMode.pokedex,
      );

      await tester.binding.setSurfaceSize(const Size(1440, 980));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildCatalogsHost(
          container: container,
          bucket: bucket,
          showWorkspace: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('pokemon-catalogs-tab-moves')));
      await tester.pumpAndSettle();
      expect(find.text('Moves'), findsWidgets);

      await tester.pumpWidget(
        _buildCatalogsHost(
          container: container,
          bucket: bucket,
          showWorkspace: false,
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        _buildCatalogsHost(
          container: container,
          bucket: bucket,
          showWorkspace: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Le futur catalogue des capacités du projet vivra ici.'),
          findsOneWidget);
    });
  });
}

```
