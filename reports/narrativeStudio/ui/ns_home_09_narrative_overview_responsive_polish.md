# NS-HOME-09 — Narrative Overview Responsive Polish / Full Shell Visual Gate V0

## 1. Résumé exécutif

NS-HOME-09 stabilise la page `Narrative Studio / Aperçu` comme écran complet sans ajouter de nouvelle donnée métier.

Le lot :

- compacte le bloc `Projet` en bande de synthèse ;
- réduit les espacements globaux sans casser la lisibilité ;
- affine les hauteurs des KPI, modules, empty states et du panneau `Structure narrative` ;
- ajoute des repères de layout testables pour la colonne principale et le panneau ;
- valide le layout desktop large avec panneau à droite ;
- valide le layout medium avec panneau empilé ;
- produit trois screenshots : desktop, medium et full shell éditeur.

Aucun read model, modèle `map_core`, runtime, gameplay ou battle n’a été modifié. Aucune donnée fake n’a été ajoutée.

## 2. Rappel du scope NS-HOME-09

Objectif du lot : polish UI, responsive, densité, scroll, lisibilité, Visual Gate.

Non-objectifs respectés :

- pas de nouvelle feature métier ;
- pas de top bar finale de l’image cible ;
- pas de sidebar finale de l’image cible ;
- pas de vraie activité récente ;
- pas de notifications réelles ;
- pas de tags réels ;
- pas de `FR` / `v0.3.0` dans le footer Overview ;
- pas de hardcode Selbrume, chiffres image ou données cible.

## 3. Fichiers créés / modifiés

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_empty_states.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`

Fichiers créés :

- `reports/narrativeStudio/ui/screenshots/ns_home_09_overview_responsive_polish_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_09_overview_responsive_polish_medium.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_09_overview_full_shell.png`
- `reports/narrativeStudio/ui/ns_home_09_narrative_overview_responsive_polish.md`

## 4. UI / responsive polish réalisé

Dans `NarrativeOverviewWorkspace` :

- ajout de `narrative-overview-scroll` ;
- ajout de `narrative-overview-main-column` ;
- ajout de `narrative-overview-structure-column` ;
- remplacement du bloc `Projet` en section card par une bande compacte `_ProjectSummaryStrip` ;
- réduction du padding général de page ;
- réduction des gaps entre blocs de `12` à `10` px ;
- largeur du panneau structure desktop ajustée de `360` à `348` px ;
- KPI resserrés mais conservés à `148` px pour éviter les overflows ;
- modules resserrés à `minHeight: 168` ;
- carte `Histoire principale` légèrement plus dense ;
- suppression de `_OverviewLine`, devenu inutile.

Dans `NarrativeOverviewStructureInspector` :

- padding réduit ;
- identité compacte ;
- gaps internes réduits ;
- compteurs et tuiles éditoriales légèrement densifiés.

Dans `NarrativeOverviewUnavailableDataSection` :

- padding réduit ;
- tiles V0 réduites à `minHeight: 112` ;
- footer metadata un peu plus discret.

## 5. Choix de layout et breakpoints

Le breakpoint existant est conservé :

- si `constraints.maxWidth >= 1180` : layout en deux colonnes, contenu principal à gauche, panneau `Structure narrative` à droite ;
- sinon : layout empilé, contenu principal puis panneau.

Ce choix reste le plus sûr pour V0 : le panneau est interne au workspace et ne réactive pas le panneau droit global de l’éditeur. Le screenshot full shell confirme que le workspace Overview cohabite avec le chrome éditeur existant.

## 6. Ce qui reste volontairement hors scope

Restent hors scope :

- top bar finale de l’image cible ;
- sidebar finale Narrative Studio ;
- actions globales `Nouvelle storyline`, `Aperçu`, `Valider` ;
- activité récente réelle ;
- notifications réelles ;
- registre Facts ;
- registre tags ;
- locale/version réelles pour le footer Overview ;
- modification du status bar global existant.

Note visuelle : le screenshot full shell montre encore `Locale : FR` et `v0.3.0` dans le status bar global existant de l’éditeur. Ce n’est pas le footer Overview créé par NS-HOME-08/09 et ce lot ne modifie pas ce chrome global.

## 7. Tests ajoutés / modifiés

Ajouts dans `narrative_overview_workspace_test.dart` :

- test desktop large : le panneau structure est à droite de la colonne principale ;
- test medium : le panneau structure est empilé sous la colonne principale ;
- test anti-fake après polish : Facts, activité récente, notifications, `FR`, `v0.3.0`, Selbrume et chiffres image restent absents ;
- capture screenshot desktop NS-HOME-09 ;
- capture screenshot medium NS-HOME-09 ;
- helper `_storyOverviewReadModel()`.

Ajout dans `narrative_overview_shell_navigation_test.dart` :

- capture full shell via `pumpEditorShellPage` ;
- chargement de polices pour rendre le screenshot full shell lisible en widget test.

## 8. Visual Gate

Screenshots produits :

- Desktop large : `reports/narrativeStudio/ui/screenshots/ns_home_09_overview_responsive_polish_desktop.png`
- Medium responsive : `reports/narrativeStudio/ui/screenshots/ns_home_09_overview_responsive_polish_medium.png`
- Full shell éditeur : `reports/narrativeStudio/ui/screenshots/ns_home_09_overview_full_shell.png`

Méthode :

- `matchesGoldenFile(...absolute.path)` avec `--update-goldens` ;
- widget screenshot pour desktop/medium ;
- harness `EditorShellPage` existant pour le full shell.

Comparaison honnête :

- Correspond à l’image cible : hiérarchie Overview, KPI, Histoire principale, Modules, panneau Structure narrative, empty states et footer visibles dans une page cohérente.
- Amélioration depuis NS-HOME-08 : le bloc `Projet` ne consomme plus une carte haute, la page respire mieux, le panneau droit est plus dense, le footer est visible sans ressembler à une grosse section.
- Medium : le panneau est empilé et lisible ; le screenshot utilise `1180 x 2400` pour inclure le panneau complet.
- Full shell : top toolbar, project explorer, workspace et status bar existants sont visibles ; le contenu Overview est partiellement visible car la capture shell reste à `1600 x 1000`.
- Hors scope : alignement final top bar/sidebar avec l’image cible, status bar global, actions globales.

Problème corrigé après inspection :

- La première compression KPI à `138` px provoquait un overflow sur `Problèmes ouverts` / `Validation non lancée`. La hauteur a été remontée à `148` px.

## 9. Commandes exécutées

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_HOME_09_CAPTURE_DESKTOP_SCREENSHOT=true --dart-define=NS_HOME_09_CAPTURE_MEDIUM_SCREENSHOT=true test/ui/canvas/narrative_overview_workspace_test.dart
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_HOME_09_CAPTURE_FULL_SHELL=true test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter analyze
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_overview_workspace.dart lib/src/ui/canvas/narrative_overview_structure_inspector.dart lib/src/ui/canvas/narrative_overview_empty_states.dart test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
git diff --check
```

## 10. Résultats des tests

Test workspace final :

```text
00:00 +0: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
...
00:02 +27: All tests passed!
```

Tests combinés finaux :

```text
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
...
00:02 +30: All tests passed!
```

Screenshots desktop/medium :

```text
00:00 +0: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
...
00:02 +27: All tests passed!
```

Screenshot full shell :

```text
00:00 +0: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +1: NarrativeLibraryPanel exposes overview without removing existing studios
00:00 +2: NarrativeOverviewWorkspace captures a full editor shell screenshot when requested
00:01 +3: All tests passed!
```

## 11. Résultats analyze

`flutter analyze` global échoue sur une dette préexistante hors NS-HOME-09 :

```text
Analyzing map_editor...
  error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
  error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
  error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3 • undefined_class
  error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
  warning • The library 'package:map_editor/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart' doesn't export a member with the shown name 'showPokedexImportFlowSheet' • lib/src/ui/canvas/pokedex_workspace_views.dart:17:9 • undefined_shown_name
348 issues found. (ran in 3.3s)
```

Analyse ciblée NS-HOME-09 :

```text
Analyzing 5 items...

No issues found! (ran in 1.4s)
```

## 12. Limites

- Le full shell screenshot montre le chrome éditeur existant, dont le status bar global n’est pas encore aligné avec le contrat footer Overview.
- Le rendu full shell est un smoke visuel de layout, pas une capture exhaustive de toute la page scrollée.
- Les icônes de screenshot widget restent rendues sobrement par le contexte de test ; cela ne bloque pas la vérification de layout.
- La page n’a pas encore la top bar/sidebar finale de l’image cible.

## 13. Prochain lot recommandé

Recommandation :

```text
NS-HOME-10 — Narrative Studio Shell Chrome Alignment V0
```

Objectif recommandé : aligner progressivement le chrome autour de l’Overview, sans refonte globale : entrée sidebar, vocabulaire `Aperçu`, statut global, actions shell honnêtes, et clarification du status bar global pour éviter la confusion avec le footer metadata.

Justification : NS-HOME-09 montre que la page interne tient ; le prochain risque visible est maintenant le chrome autour de la page, notamment le status bar global qui affiche encore des métadonnées non issues du read model Overview.

## 14. Evidence Pack

### Git initial

```bash
git branch --show-current
```

```text
main
```

```bash
git status --short --untracked-files=all
```

```text

```

### Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_empty_states.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

### Fichiers créés

```text
reports/narrativeStudio/ui/screenshots/ns_home_09_overview_responsive_polish_desktop.png
reports/narrativeStudio/ui/screenshots/ns_home_09_overview_responsive_polish_medium.png
reports/narrativeStudio/ui/screenshots/ns_home_09_overview_full_shell.png
reports/narrativeStudio/ui/ns_home_09_narrative_overview_responsive_polish.md
```

### Statut screenshots

```text
May 27 03:37:39 2026 326870 reports/narrativeStudio/ui/screenshots/ns_home_09_overview_responsive_polish_desktop.png
May 27 03:38:57 2026 326690 reports/narrativeStudio/ui/screenshots/ns_home_09_overview_responsive_polish_medium.png
May 27 03:40:18 2026 251961 reports/narrativeStudio/ui/screenshots/ns_home_09_overview_full_shell.png
```

### Extraits de diff significatifs

`narrative_overview_workspace.dart` :

```diff
+      key: const ValueKey('narrative-overview-scroll'),
+      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
+      key: const ValueKey('narrative-overview-main-column'),
+              SizedBox(
+                key: const ValueKey('narrative-overview-structure-column'),
+                width: 348,
+                child: structureInspector,
+              ),
+        _ProjectSummaryStrip(
+          projectName: readModel.projectName,
+          editorialStatusLabel: _editorialStatusLabel(
+            readModel.editorialStatus.validationState,
+          ),
+          projectHealthLabel: _projectHealthLabel(
+            readModel.projectHealth.healthKind,
+          ),
+        ),
```

`narrative_overview_structure_inspector.dart` :

```diff
-      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
+      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
-          const SizedBox(height: 16),
+          const SizedBox(height: 12),
-          width: 58,
-          height: 58,
+          width: 52,
+          height: 52,
```

`narrative_overview_empty_states.dart` :

```diff
-      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
+      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
-      constraints: const BoxConstraints(minHeight: 126),
+      constraints: const BoxConstraints(minHeight: 112),
-      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
+      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
```

Tests :

```diff
+    'NarrativeOverviewWorkspace keeps the structure inspector beside the main column on large desktop',
+    'NarrativeOverviewWorkspace stacks the structure inspector after the main column on medium desktop',
+    'NarrativeOverviewWorkspace keeps V0 unavailable data honest after responsive polish',
+    'NarrativeOverviewWorkspace captures responsive polish desktop screenshot when requested',
+    'NarrativeOverviewWorkspace captures responsive polish medium screenshot when requested',
+    'NarrativeOverviewWorkspace captures a full editor shell screenshot when requested',
```

### Git final à jour après création du rapport

Les fichiers PNG et le rapport sont non trackés ; `git diff` ne liste que les fichiers déjà trackés.

```bash
git status --short --untracked-files=all
```

```text
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_empty_states.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
?? reports/narrativeStudio/ui/ns_home_09_narrative_overview_responsive_polish.md
?? reports/narrativeStudio/ui/screenshots/ns_home_09_overview_full_shell.png
?? reports/narrativeStudio/ui/screenshots/ns_home_09_overview_responsive_polish_desktop.png
?? reports/narrativeStudio/ui/screenshots/ns_home_09_overview_responsive_polish_medium.png
```

```bash
git diff --stat
```

```text
 .../ui/canvas/narrative_overview_empty_states.dart |  16 +-
 .../narrative_overview_structure_inspector.dart    |  40 ++--
 .../ui/canvas/narrative_overview_workspace.dart    | 215 ++++++++++++-------
 .../narrative_overview_shell_navigation_test.dart  |  54 +++++
 .../canvas/narrative_overview_workspace_test.dart  | 228 +++++++++++++++++++++
 5 files changed, 450 insertions(+), 103 deletions(-)
```

```bash
git diff --name-only
```

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_empty_states.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

```bash
git diff --check
```

```text

```

## 15. Auto-review critique

- Scope respecté : aucune donnée métier ajoutée, aucun read model touché.
- Bon point : le Visual Gate a trouvé et corrigé un overflow KPI réel.
- Point à surveiller : le fichier `narrative_overview_workspace.dart` reste dense ; un futur lot pourrait extraire des composants partagés si l’écran continue à grossir.
- Point produit : le full shell révèle une tension entre footer Overview honnête et status bar global existant.

## 16. Regard critique sur le prompt

Le prompt est utilement strict : il empêche de transformer un lot polish en nouvelle feature. La seule ambiguïté est le `Full Shell Visual Gate` : il demande de vérifier le shell complet tout en interdisant top bar/sidebar/status bar finale. Le compromis adopté est de capturer le shell existant, documenter ses limites, et ne pas le modifier dans ce lot.
