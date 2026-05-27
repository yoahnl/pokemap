# NS-HOME-14 — Narrative Studio Shell Header Density / Top Strip Harmonization V0

## 1. Résumé exécutif

NS-HOME-14 densifie le haut de `Narrative Studio / Aperçu` sans changer le modèle métier ni activer d’action future.

Le lot compacte :

- le padding haut du workspace ;
- l’écart entre breadcrumb, titre et corps ;
- le wording du sous-titre interne ;
- la taille du breadcrumb ;
- le mode strip narratif dans `NarrativeWorkspaceCanvas`.

Le contexte reste visible :

```text
PokeMap / Narrative Studio / Aperçu
Aperçu
Vue d’ensemble auteur : métriques et statuts honnêtes.
```

Les affordances NS-HOME-12 restent inchangées : `Aperçu` est l’état courant, les actions futures restent désactivées, aucune validation ou notification fake n’est ajoutée.

## 2. Rappel du scope NS-HOME-14

Scope exécuté :

- réduire la redondance visible entre shell, top strip, breadcrumb et header interne ;
- rapprocher les KPI du haut de page ;
- conserver le contexte auteur ;
- préserver sidebar, top bar, status bar et footer existants ;
- produire des screenshots Visual Gate desktop, focus et medium.

Hors scope respecté :

- aucune refonte complète de top bar ;
- aucune refonte complète de sidebar ;
- aucune nouvelle feature métier ;
- aucun bouton futur activé ;
- aucune donnée runtime joueur ;
- aucun changement `map_core`, runtime, gameplay ou battle.

## 3. Audit de redondance header / top strip / breadcrumb

État audité après NS-HOME-13 :

- top toolbar : identifie déjà le mode `Narrative Studio / Aperçu` et garde les affordances shell ;
- mode strip narratif : donne accès aux workspaces narratifs existants ;
- breadcrumb interne : `PokeMap / Narrative Studio / Aperçu`, informatif et non cliquable ;
- titre interne : `Aperçu` ;
- sous-titre interne : répétait trop de contexte avec une phrase longue.

Décision :

- conserver les quatre couches, car elles ne portent pas la même fonction ;
- compacter plutôt que supprimer ;
- raccourcir le sous-titre interne, car c’était la redondance la plus visible ;
- réduire les espaces verticaux, car les KPI arrivaient encore trop bas dans le viewport focus.

## 4. Fichiers créés / modifiés

Fichiers modifiés :

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Fichiers créés :

```text
reports/narrativeStudio/ui/ns_home_14_narrative_studio_shell_header_density.md
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_desktop.png
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_focus.png
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_medium.png
```

Les screenshots sont non textuels ; leur contenu complet n’est pas recopié dans le rapport. Ils sont listés et confirmés par `file` / `stat`.

## 5. Choix de densité retenus

Choix retenus :

- padding haut du workspace réduit de `18` à `8` ;
- écart header/corps réduit de `14` à `8` ;
- écart breadcrumb/titre réduit de `10` à `6` ;
- titre interne réduit de `26` à `24` ;
- sous-titre interne réduit de `14` à `13` et raccourci ;
- breadcrumb réduit en `11px`, avec padding vertical plus bas ;
- mode strip narratif réduit en padding horizontal/vertical ;
- les gaps entre chips du mode strip passent de `8` à `6`.

Ce qui n’a pas été supprimé :

- breadcrumb, car il clarifie le chemin sans route fictive ;
- titre `Aperçu`, car il ancre la page ;
- sous-titre auteur, car il distingue dashboard auteur et runtime ;
- top strip, car il reste la navigation narrative V0.

## 6. UI / header density réalisé

Dans `NarrativeOverviewWorkspace` :

- la page commence plus haut dans la surface ;
- le header interne est plus compact ;
- les KPI sont visibles plus tôt dans un viewport raisonnable ;
- le wording évite la répétition avec le header shell.

Dans `NarrativeWorkspaceCanvas` :

- le mode strip narratif garde les mêmes destinations ;
- les chips sont plus basses et moins consommatrices en largeur ;
- aucune sémantique d’action n’a été modifiée.

## 7. Actions volontairement non activées

Non activé, conformément au scope :

```text
Nouvelle storyline
Validation narrative
Recherche narrative
Notifications
Paramètres narratifs
```

Aucune validation fake, notification fake, recherche fake ou création de storyline n’a été ajoutée.

## 8. Ce qui reste volontairement hors scope

Reste hors scope :

- top bar finale de l’image cible ;
- sidebar finale de l’image cible ;
- vraie création de storyline ;
- vraie validation narrative globale ;
- vraie recherche ;
- centre de notifications ;
- tags réels ;
- facts réels ;
- données runtime joueur ;
- refonte large de `EditorShellPage`.

## 9. Tests ajoutés / modifiés

Tests modifiés dans `narrative_overview_workspace_test.dart` :

- mise à jour du sous-titre attendu ;
- ajout d’un test de densité vérifiant que la grille KPI reste proche du haut de page dans un viewport `1440 x 720`.

Tests modifiés dans `narrative_overview_shell_navigation_test.dart` :

- ajout d’un test screenshot NS-HOME-14 piloté par dart-define ;
- génération desktop `1600 x 1000` ;
- génération focus `1600 x 700` ;
- génération medium `1180 x 1000`.

## 10. Visual Gate

Screenshots produits :

```text
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_desktop.png
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_focus.png
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_medium.png
```

Méthode :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_14_CAPTURE_HEADER_DENSITY_DESKTOP=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_14_CAPTURE_HEADER_DENSITY_FOCUS=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_14_CAPTURE_HEADER_DENSITY_MEDIUM=true
```

Comparaison visuelle :

- amélioration depuis NS-HOME-13 : le bloc interne commence plus haut, le sous-titre est moins long, le breadcrumb est plus discret, et les KPI sont visibles plus tôt ;
- le contexte `Narrative Studio / Aperçu` reste clair via top toolbar, mode strip, breadcrumb et titre ;
- le mode strip / top toolbar / breadcrumb cohabitent mieux parce que le strip et le header interne consomment moins de hauteur ;
- les actions top bar restent honnêtes : aucune action future n’est activée ;
- le panneau `Structure narrative` reste visible en desktop ;
- le focus montre le haut de page sans overflow visible ;
- le medium reste stable.

Ce qui ne correspond pas encore à l’image cible :

- la top bar finale n’est pas reconstruite ;
- la sidebar finale n’est pas reconstruite ;
- les actions futures restent désactivées ;
- les modules `Facts`, tags et validation réelle restent volontairement indisponibles.

Correction après inspection visuelle :

- après inspection, aucun défaut évident de layout dans le scope n’a nécessité une correction visuelle supplémentaire ;
- une correction technique `const Icon` a été appliquée après analyse ciblée pour supprimer un `prefer_const_constructors` introduit dans un fichier touché.

## 11. Commandes exécutées

```bash
git branch --show-current
git status --short --untracked-files=all
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_14_CAPTURE_HEADER_DENSITY_DESKTOP=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_14_CAPTURE_HEADER_DENSITY_FOCUS=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_14_CAPTURE_HEADER_DENSITY_MEDIUM=true
file reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_desktop.png reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_focus.png reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_medium.png
stat -f '%N %Sm %z' reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_desktop.png reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_focus.png reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_medium.png
cd packages/map_editor && flutter test test/top_toolbar_test.dart
cd packages/map_editor && flutter test test/editor_selectors_test.dart
cd packages/map_editor && flutter test test/status_bar_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart test/status_bar_test.dart
cd packages/map_editor && flutter analyze
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_overview_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
git diff --check
git diff --stat
git diff --name-only
```

## 12. Résultats des tests

### Workspace

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
00:00 +0: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: NarrativeOverviewWorkspace does not present unavailable modules as real data
00:00 +2: NarrativeOverviewWorkspace renders honest upcoming data states and footer metadata
00:00 +3: NarrativeOverviewWorkspace KPI cards consume read model values
00:01 +4: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
00:01 +5: NarrativeOverviewWorkspace keeps KPI cards visible after header density polish
00:01 +6: NarrativeOverviewWorkspace renders an honest empty main story card
00:01 +7: NarrativeOverviewWorkspace renders explicit main story data from the read model
00:01 +8: NarrativeOverviewWorkspace explains missing description and fallback chapters
00:01 +9: NarrativeOverviewWorkspace renders ambiguous main story state explicitly
00:01 +10: NarrativeOverviewWorkspace renders honest narrative module cards
00:01 +11: NarrativeOverviewWorkspace module cards consume read model values
00:01 +12: NarrativeOverviewWorkspace module grid keeps previous overview blocks visible
00:01 +13: NarrativeOverviewWorkspace renders an honest structure inspector panel
00:01 +14: NarrativeOverviewWorkspace structure inspector consumes read model counters and chapters
00:02 +15: NarrativeOverviewWorkspace structure inspector shows clean validation as up to date
00:02 +16: NarrativeOverviewWorkspace structure inspector maps warnings to review state
00:02 +17: NarrativeOverviewWorkspace structure inspector maps errors to blocking state
00:02 +18: NarrativeOverviewWorkspace keeps the structure inspector beside the main column on large desktop
00:02 +19: NarrativeOverviewWorkspace stacks the structure inspector after the main column on medium desktop
00:02 +20: NarrativeOverviewWorkspace keeps V0 unavailable data honest after responsive polish
00:02 +21: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:02 +22: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:02 +23: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:02 +24: NarrativeOverviewWorkspace captures structure inspector screenshot when requested
00:02 +25: NarrativeOverviewWorkspace captures empty states and footer screenshot when requested
00:02 +26: NarrativeOverviewWorkspace captures responsive polish desktop screenshot when requested
00:02 +27: NarrativeOverviewWorkspace captures responsive polish medium screenshot when requested
00:02 +28: All tests passed!
```

### Shell navigation

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:00 +0: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +1: NarrativeLibraryPanel exposes overview without removing existing studios
00:00 +2: EditorShellPage presents coherent Narrative Studio overview chrome
00:01 +3: ProjectExplorerPanel prioritizes narrative navigation in overview mode
00:01 +4: NarrativeOverviewWorkspace captures a full editor shell screenshot when requested
00:01 +5: NarrativeOverviewWorkspace captures NS-HOME-11 sidebar navigation screenshots when requested
00:01 +6: NarrativeOverviewWorkspace captures NS-HOME-12 top bar screenshots when requested
00:01 +7: NarrativeOverviewWorkspace captures NS-HOME-13 breadcrumb header screenshots when requested
00:01 +8: NarrativeOverviewWorkspace captures NS-HOME-14 header density screenshots when requested
00:01 +9: NarrativeOverviewWorkspace captures NS-HOME-10 shell chrome screenshots when requested
00:01 +10: All tests passed!
```

### Top toolbar

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart
00:00 +0: TopToolbar shows the app brand and project workspace label
00:00 +1: TopToolbar falls back to the workspace label when no project is loaded
00:00 +2: TopToolbar shows the toolbar status chip when a status is present
00:00 +3: TopToolbar shows the trainer studio label for the trainer workspace
00:00 +4: TopToolbar uses the French Narrative Studio overview chrome label
00:00 +5: TopToolbar enables project save and disables map history in Path Studio
00:00 +6: TopToolbar shows neutral Save Project when project is clean in Path Studio
00:00 +7: TopToolbar enables project save and disables map history in Environment Studio
00:00 +8: TopToolbar shows Environment Studio in the workspace brand strip
00:00 +9: TopToolbar keeps map save action in map workspace
00:00 +10: All tests passed!
```

### Editor selectors

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart
00:00 +0: editor selectors editorShellSnapshotProvider derives map title and save affordance
00:00 +1: editor selectors editorToolbarSnapshotProvider resolves selected tileset from layer
00:00 +2: editor selectors Path Studio snapshots hide map save and history actions
00:00 +3: editor selectors editorProjectExplorerSnapshotProvider exposes active map selection
00:00 +4: editor selectors editorShellSnapshotProvider exposes trainer studio labels
00:00 +5: editor selectors editorShellSnapshotProvider exposes Pokémon catalogs labels
00:00 +6: editor selectors editorShellSnapshotProvider exposes clean Environment Studio labels
00:00 +7: editor selectors editorTerrainLibrarySnapshotProvider exposes preset selection inputs
00:00 +8: editor selectors editorTilesetPaletteSnapshotProvider exposes palette panel state
00:00 +9: All tests passed!
```

### Status bar

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/status_bar_test.dart
00:00 +0: StatusBar shows ready and zoom when no map is active
00:00 +1: StatusBar shows active map chips and formatted zoom
00:00 +2: StatusBar hides global locale and version metadata in Narrative Overview
00:00 +3: StatusBar prioritizes error text over status text
00:00 +4: StatusBar shows persistent unsaved-project signal when project is dirty
00:00 +5: StatusBar hides unsaved-project signal after project save success
00:00 +6: All tests passed!
```

### Régression combinée

```text
00:04 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:04 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:04 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:04 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures structure inspector screenshot when requested
00:04 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures empty states and footer screenshot when requested
00:04 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures responsive polish desktop screenshot when requested
00:04 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures responsive polish medium screenshot when requested
00:04 +63: All tests passed!
```

## 13. Résultats analyze

Analyse globale :

```text
Analyzing map_editor...
error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
error • The named parameter 'battleEngineMethod' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:72:7 • undefined_named_parameter
error • The named parameter 'effectChance' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:73:7 • undefined_named_parameter
error • The named parameter 'studioFlags' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:74:7 • undefined_named_parameter
error • The named parameter 'battleStageMods' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:75:7 • undefined_named_parameter
error • The named parameter 'moveStatuses' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:76:7 • undefined_named_parameter
error • The named parameter 'psdkStudioMoveId' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:80:9 • undefined_named_parameter
error • The named parameter 'psdkDbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:81:9 • undefined_named_parameter
error • The named parameter 'psdkBattleEngineMethod' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:82:9 • undefined_named_parameter
```

Fin de sortie globale :

```text
info • Unnecessary 'const' keyword • test/ui_panels_smoke_test.dart:74:52 • unnecessary_const

347 issues found. (ran in 2.2s)
```

Interprétation : l’analyse globale échoue sur une dette préexistante hors périmètre NS-HOME-14, principalement autour du convertisseur/catalogue Pokémon SDK et de lints existants.

Analyse ciblée des fichiers modifiés :

```text
Analyzing 4 items...
No issues found! (ran in 1.3s)
```

## 14. Limites

- La top bar finale de l’image cible n’est pas reconstruite.
- La sidebar finale de l’image cible n’est pas reconstruite.
- Le mode strip reste une navigation V0, pas la future sidebar narrative complète.
- Le screenshot focus coupe volontairement le bas de page pour inspecter le haut.
- L’analyse globale reste rouge sur dette hors lot.

## 15. Prochain lot recommandé

```text
NS-HOME-15 — Narrative Studio Header / Navigation Visual QA Bis or Narrative Studio Overview Final Chrome Pass V0
```

Recommandation : si NS-HOME-14 est validé visuellement, passer à un lot de QA visuelle finale du chrome complet avant de démarrer des modules métier supplémentaires.

## 16. Evidence Pack

### Branche

```text
main
```

### Git status initial

Capturé au début du lot :

```text
(aucune sortie)
```

### Git status final

```text
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
?? reports/narrativeStudio/ui/ns_home_14_narrative_studio_shell_header_density.md
?? reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_desktop.png
?? reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_focus.png
?? reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_medium.png
```

### Git diff --stat final

```text
 .../ui/canvas/narrative_overview_workspace.dart    | 26 ++++++-------
 .../src/ui/canvas/narrative_workspace_canvas.dart  | 18 ++++-----
 .../narrative_overview_shell_navigation_test.dart  | 43 ++++++++++++++++++++++
 .../canvas/narrative_overview_workspace_test.dart  | 28 +++++++++++++-
 4 files changed, 91 insertions(+), 24 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non trackés. Les screenshots et le rapport sont donc compensés par `git status --short --untracked-files=all` et les confirmations `file` / `stat`.

### Git diff --name-only final

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

### Git diff --check final

```text
(aucune sortie)
```

### Fichiers créés

```text
reports/narrativeStudio/ui/ns_home_14_narrative_studio_shell_header_density.md
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_desktop.png
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_focus.png
reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_medium.png
```

### Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

### Confirmation screenshots

```text
/Users/karim/Project/pokemonProject/reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_desktop.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
/Users/karim/Project/pokemonProject/reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_focus.png:   PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
/Users/karim/Project/pokemonProject/reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_medium.png:  PNG image data, 1180 x 1000, 8-bit/color RGBA, non-interlaced
/Users/karim/Project/pokemonProject/reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_desktop.png May 27 15:56:13 2026 244834
/Users/karim/Project/pokemonProject/reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_focus.png May 27 15:56:18 2026 170329
/Users/karim/Project/pokemonProject/reports/narrativeStudio/ui/screenshots/ns_home_14_header_density_medium.png May 27 15:56:23 2026 187968
```

### Extraits complets des sections modifiées

#### `narrative_overview_workspace.dart`

```diff
@@ -21,10 +21,10 @@ class NarrativeOverviewWorkspace extends StatelessWidget {
   Widget build(BuildContext context) {
     return ListView(
       key: const ValueKey('narrative-overview-scroll'),
-      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
+      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
       children: [
         const _OverviewPageHeader(),
-        const SizedBox(height: 14),
+        const SizedBox(height: 8),
         _OverviewResponsiveBody(readModel: readModel),
       ],
     );
@@ -43,8 +43,8 @@ class _OverviewPageHeader extends StatelessWidget {
         const Wrap(
           key: ValueKey('narrative-overview-breadcrumb'),
           crossAxisAlignment: WrapCrossAlignment.center,
-          spacing: 7,
-          runSpacing: 4,
+          spacing: 6,
+          runSpacing: 3,
           children: [
             _BreadcrumbSegment(label: 'PokeMap'),
             _BreadcrumbSeparator(),
@@ -53,21 +53,21 @@ class _OverviewPageHeader extends StatelessWidget {
             _BreadcrumbSegment(label: 'Aperçu', current: true),
           ],
         ),
-        const SizedBox(height: 10),
+        const SizedBox(height: 6),
         Text(
           'Aperçu',
           style: TextStyle(
             color: EditorChrome.primaryLabel(context),
-            fontSize: 26,
+            fontSize: 24,
             fontWeight: FontWeight.w800,
           ),
         ),
-        const SizedBox(height: 4),
+        const SizedBox(height: 3),
         Text(
-          'Vue d’ensemble auteur : métriques disponibles, statuts honnêtes et prochaines sections du dashboard.',
+          'Vue d’ensemble auteur : métriques et statuts honnêtes.',
           style: TextStyle(
             color: EditorChrome.subtleLabel(context),
-            fontSize: 14,
+            fontSize: 13,
             fontWeight: FontWeight.w600,
           ),
         ),
@@ -94,18 +94,18 @@ class _BreadcrumbSegment extends StatelessWidget {
       label,
       style: TextStyle(
         color: textColor,
-        fontSize: 12,
+        fontSize: 11,
         fontWeight: current ? FontWeight.w700 : FontWeight.w600,
       ),
     );
     if (!current) {
       return Padding(
-        padding: const EdgeInsets.symmetric(vertical: 3),
+        padding: const EdgeInsets.symmetric(vertical: 2),
         child: child,
       );
     }
     return Container(
-      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
+      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
       decoration: BoxDecoration(
         color: EditorChrome.chipFill(context),
         borderRadius: BorderRadius.circular(999),
@@ -127,7 +127,7 @@ class _BreadcrumbSeparator extends StatelessWidget {
       '/',
       style: TextStyle(
         color: EditorChrome.subtleLabel(context),
-        fontSize: 12,
+        fontSize: 11,
         fontWeight: FontWeight.w600,
       ),
     );
```

#### `narrative_workspace_canvas.dart`

```diff
@@ -221,7 +221,7 @@ class NarrativeWorkspaceCanvas extends ConsumerWidget {
                   ),
                   _NarrativeModeStrip(workspaceMode: workspaceMode),
                   if (workspaceMode == EditorWorkspaceMode.narrativeOverview) ...[
-                    const SizedBox(height: 12),
+                    const SizedBox(height: 8),
                     Expanded(child: NarrativeOverviewWorkspace(readModel: readModel)),
                   ] else ...[
@@ -235,21 +235,21 @@ class _NarrativeModeStrip extends ConsumerWidget {
           _ModeChip(
             label: 'Aperçu',
             selected: workspaceMode == EditorWorkspaceMode.narrativeOverview,
             onTap: () =>
                 controller.setWorkspaceMode(EditorWorkspaceMode.narrativeOverview),
           ),
-          const SizedBox(width: 8),
+          const SizedBox(width: 6),
           _ModeChip(
             label: 'Histoire globale',
             selected: workspaceMode == EditorWorkspaceMode.globalStory,
             onTap: () => controller.setWorkspaceMode(EditorWorkspaceMode.globalStory),
           ),
-          const SizedBox(width: 8),
+          const SizedBox(width: 6),
           _ModeChip(
             label: 'Étape',
             selected: workspaceMode == EditorWorkspaceMode.step,
             onTap: () => controller.setWorkspaceMode(EditorWorkspaceMode.step),
           ),
-          const SizedBox(width: 8),
+          const SizedBox(width: 6),
           _ModeChip(
             label: 'Cinématique',
             selected: workspaceMode == EditorWorkspaceMode.cutscene,
             onTap: () => controller.setWorkspaceMode(EditorWorkspaceMode.cutscene),
           ),
-          const SizedBox(width: 8),
+          const SizedBox(width: 6),
           _ModeChip(
             label: 'Dialogue',
             selected: workspaceMode == EditorWorkspaceMode.dialogue,
@@ -295,7 +295,7 @@ class _ModeChip extends StatelessWidget {
         ? EditorChrome.inspectorJoyCyan
         : EditorChrome.subtleLabel(context);
     return CupertinoButton(
-      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
+      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       minimumSize: Size.zero,
       onPressed: onTap,
       child: Container(
@@ -306,12 +306,12 @@ class _ModeChip extends StatelessWidget {
           borderRadius: BorderRadius.circular(999),
           border: Border.all(color: accent.withValues(alpha: 0.7)),
         ),
-        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
+        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
         child: Text(
           label,
           style: TextStyle(
             color: accent,
-            fontSize: 12,
+            fontSize: 11,
             fontWeight: FontWeight.w700,
           ),
@@ -410,7 +410,7 @@
                         onPressed: () async {
                           await deleteCutsceneWithUserConfirmation(
                             context: context,
                             editorNotifier: editorNotifier,
                             projection: projection,
                             scenarioId: scenario.id,
                             selectedScenarioId: selectedCutscene?.id,
                             onSelectReplacement: onSelectCutscene,
                           );
                         },
-                        child: Icon(
+                        child: const Icon(
                           CupertinoIcons.trash,
                           size: 17,
                           color: EditorChrome.inspectorJoyCoral,
```

#### `narrative_overview_workspace_test.dart`

```diff
@@ -35,7 +35,7 @@ void main() {
       expect(find.text('Aperçu'), findsWidgets);
       expect(
         find.text(
-          'Vue d’ensemble auteur : métriques disponibles, statuts honnêtes et prochaines sections du dashboard.',
+          'Vue d’ensemble auteur : métriques et statuts honnêtes.',
         ),
         findsOneWidget,
       );
@@ -269,6 +269,30 @@ void main() {
     },
   );
 
+  testWidgets(
+    'NarrativeOverviewWorkspace keeps KPI cards visible after header density polish',
+    (tester) async {
+      final readModel = buildNarrativeOverviewReadModel(
+        project: _minimalProject('test_project'),
+      );
+
+      await _pumpOverview(tester, readModel, width: 1440, height: 720);
+
+      final header = find.byKey(const ValueKey('narrative-overview-page-header'));
+      final kpiGrid = find.byKey(const ValueKey('narrative-overview-kpi-grid'));
+
+      expect(header, findsOneWidget);
+      expect(kpiGrid, findsOneWidget);
+      expect(tester.getTopLeft(kpiGrid).dy, lessThanOrEqualTo(165));
+      expect(find.text('Indicateurs auteur'), findsOneWidget);
+      expect(find.text('Histoire principale'), findsOneWidget);
+    },
+  );
+
   testWidgets(
     'NarrativeOverviewWorkspace renders an honest empty main story card',
```

#### `narrative_overview_shell_navigation_test.dart`

```diff
@@ -442,6 +442,49 @@ void main() {
     },
   );
 
+  testWidgets(
+    'NarrativeOverviewWorkspace captures NS-HOME-14 header density screenshots when requested',
+    (tester) async {
+      const captureDesktop =
+          bool.fromEnvironment('NS_HOME_14_CAPTURE_HEADER_DENSITY_DESKTOP');
+      const captureFocus =
+          bool.fromEnvironment('NS_HOME_14_CAPTURE_HEADER_DENSITY_FOCUS');
+      const captureMedium =
+          bool.fromEnvironment('NS_HOME_14_CAPTURE_HEADER_DENSITY_MEDIUM');
+      if (!captureDesktop && !captureFocus && !captureMedium) {
+        return;
+      }
+
+      await _loadShellScreenshotFonts();
+      await pumpEditorShellPage(
+        tester,
+        initialState: EditorState(
+          projectRootPath: '/tmp/ns_home_14_test_project',
+          workspaceMode: EditorWorkspaceMode.narrativeOverview,
+          project: _minimalProject('test_project'),
+        ),
+        surfaceSize: captureMedium
+            ? const Size(1180, 1000)
+            : captureFocus
+                ? const Size(1600, 700)
+                : const Size(1600, 1000),
+      );
+      await tester.pump(const Duration(milliseconds: 100));
+
+      final screenshotFile = File(
+        '../../reports/narrativeStudio/ui/screenshots/'
+        '${captureMedium ? 'ns_home_14_header_density_medium.png' : captureFocus ? 'ns_home_14_header_density_focus.png' : 'ns_home_14_header_density_desktop.png'}',
+      );
+      screenshotFile.parent.createSync(recursive: true);
+      await expectLater(
+        find.byType(EditorShellPage),
+        matchesGoldenFile(screenshotFile.absolute.path),
+      );
+
+      expect(screenshotFile.existsSync(), isTrue);
+    },
+  );
+
   testWidgets(
     'NarrativeOverviewWorkspace captures NS-HOME-10 shell chrome screenshots when requested',
```

## 17. Auto-review critique

Points positifs :

- réduction réelle de hauteur sans supprimer le contexte ;
- tests ciblés sur le seuil KPI ;
- screenshots desktop, focus et medium ;
- analyse ciblée clean après correction ;
- aucune action future activée.

Points de vigilance :

- le seuil `<= 165` est volontairement pragmatique et lié au viewport de test ; il protège la densité sans devenir pixel-perfect ;
- le top strip reste une V0, visuellement encore plus technique que l’image cible ;
- le screenshot focus valide le haut, pas le footer.

## 18. Regard critique sur le prompt

Le prompt est précis et utile : il sépare bien densité, contexte et interdiction de fausses actions.

Le point délicat est la tension entre réduire la redondance et conserver le contexte. La solution retenue évite de supprimer brutalement des couches encore utiles au shell V0 ; elle les rend plus compactes. Pour un futur lot, il serait utile de décider si le mode strip doit migrer vers une navigation latérale plus proche de l’image cible ou rester un strip transitoire.
