# NS-HOME-06 — Narrative Overview Module Cards Grid V0

## 1. Résumé exécutif

NS-HOME-06 ajoute la première grille `Modules narratifs` dans
`NarrativeOverviewWorkspace`, sous la carte `Histoire principale`.

La grille est branchée exclusivement sur :

```dart
readModel.modules
```

Elle affiche six modules :

- `Quêtes annexes`
- `Cinématiques`
- `Dialogues`
- `Conditions narratives`
- `Règles du monde`
- `Facts`

Les modules disponibles affichent leurs valeurs issues du read model.
`Quêtes annexes` reste `Hors scope V0` et `Facts` reste
`Nécessite un modèle`. Aucun compteur de l'image cible n'a été repris comme
donnée. Aucune donnée Selbrume n'a été hardcodée.

Screenshot produit :

```text
reports/narrativeStudio/ui/screenshots/ns_home_06_overview_module_cards_grid.png
```

## 2. Rappel du scope NS-HOME-06

Objectif réalisé :

```text
Aperçu
-> KPI cards réelles
-> Histoire principale réelle ou empty state honnête
-> Modules narratifs branchés sur readModel.modules
-> Quêtes/Facts honnêtement indisponibles
-> screenshot
-> critique visuelle
```

Non-objectifs respectés :

- pas de panneau droit `Structure narrative` ;
- pas d'activité récente réelle ;
- pas de notifications ;
- pas de top bar finale ;
- pas de sidebar finale ;
- pas de nouveau provider ;
- pas de repository ;
- pas de lecture disque ;
- pas de parsing Yarn ;
- pas de build_runner ;
- pas de modification `NarrativeOverviewReadModel` ;
- pas de modification `map_core`, `map_runtime`, `map_gameplay` ou
  `map_battle`.

## 3. Fichiers créés / modifiés

Fichiers modifiés :

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

Fichiers créés :

```text
reports/narrativeStudio/ui/screenshots/ns_home_06_overview_module_cards_grid.png
reports/narrativeStudio/ui/ns_home_06_narrative_overview_module_cards_grid.md
```

## 4. UI créée

La section `Modules narratifs` est insérée sous `Histoire principale`.

Structure créée :

- `LayoutBuilder` + `Wrap` responsive ;
- trois colonnes en largeur desktop large ;
- deux colonnes en largeur moyenne ;
- une colonne en largeur plus étroite ;
- six cartes module avec key stable ;
- titre, description, valeur ou état ;
- pill d'availability ;
- secondary stats quand le read model en fournit ;
- affordance non navigante `Studio relié` si une destination existe ;
- affordance `Accès à venir` si aucune destination n'existe.

La grille reste volontairement V0 : elle ne crée aucune navigation nouvelle et
ne prétend pas que les modules sans modèle existent déjà.

## 5. Mapping Module Cards → readModel.modules

| Carte UI | Source exclusive | Décision V0 |
|---|---|---|
| Quêtes annexes | `readModel.modules[id == quests]` | `Hors scope V0`, aucun compteur réel. |
| Cinématiques | `readModel.modules[id == cutscenes]` | Compteur réel depuis cutscenes authorées. |
| Dialogues | `readModel.modules[id == dialogues]` | Compteur réel depuis dialogues projet ; lignes de dialogue restent indisponibles. |
| Conditions narratives | `readModel.modules[id == conditions]` | Compteur réel depuis conditions authorées V0. |
| Règles du monde | `readModel.modules[id == world_rules]` | Compteur réel depuis world changes authorés. |
| Facts | `readModel.modules[id == facts]` | `Nécessite un modèle`, aucun compteur réel. |

Le widget ne lit pas `ProjectManifest`, ne parse pas les scénarios, ne recalcule
pas les world changes et ne fabrique pas de métrique locale.

## 6. Gestion des états available / empty / unavailable / outOfScope / needsModel

Rendu principal :

| Availability | Valeur affichée |
|---|---|
| `available` | `module.count` réel |
| `empty` | `0` réel |
| `unavailable` | `Indisponible` |
| `notEvaluated` | `Non évalué` |
| `outOfScope` | `Hors scope V0` |
| `needsModel` | `Nécessite un modèle` |

Support label :

- `available` : `Disponible`
- `empty` : `module.emptyStateMessage`
- `unavailable` : `module.emptyStateMessage`
- `notEvaluated` : `Validation non lancée`
- `outOfScope` : `module.emptyStateMessage`
- `needsModel` : `module.emptyStateMessage`

Point important :

```text
Quêtes annexes != 0 fake
Facts != 0 fake
Lignes de dialogue != compteur inventé
```

## 7. Ce qui reste volontairement hors scope

Restent hors scope de NS-HOME-06 :

- panneau droit `Structure narrative` ;
- activité récente ;
- notifications ;
- tags ;
- statut éditorial détaillé ;
- top bar finale ;
- sidebar finale ;
- navigation réelle depuis les cartes ;
- création réelle de quête ;
- création réelle de Fact ;
- grilles finales pixel-perfect ;
- progression joueur ;
- sauvegarde joueur.

## 8. Tests ajoutés / modifiés

Le fichier suivant a été enrichi :

```text
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

Couverture ajoutée :

- section `Modules narratifs` rendue ;
- six cartes modules présentes ;
- keys stables `narrative-overview-module-*` ;
- `Quêtes annexes` en `Hors scope V0` ;
- `Facts` en `Nécessite un modèle` ;
- absence de faux `0` pour `Quêtes` et `Facts` ;
- modules disponibles affichant des valeurs issues du read model ;
- secondary stat `Lignes de dialogue` affichée comme `Indisponible` ;
- KPI cards et carte `Histoire principale` toujours visibles ;
- layout moyen sans crash ;
- screenshot NS-HOME-06 générable via `dart-define`.

Les tests existants ont aussi été ajustés pour scroller jusqu'au bloc
`V0 volontairement limitée`, car la nouvelle grille l'abaisse naturellement dans
la page scrollable.

## 9. Visual Gate

Screenshot produit :

```text
reports/narrativeStudio/ui/screenshots/ns_home_06_overview_module_cards_grid.png
```

Méthode utilisée :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --no-test-assets --dart-define=NS_HOME_06_CAPTURE_SCREENSHOT=true --update-goldens --plain-name "NarrativeOverviewWorkspace captures module cards grid screenshot when requested"
```

Sortie :

```text
00:00 +0: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:00 +1: All tests passed!
```

Métadonnées du screenshot :

```text
reports/narrativeStudio/ui/screenshots/ns_home_06_overview_module_cards_grid.png: PNG image data, 1180 x 1220, 8-bit/color RGBA, non-interlaced
May 27 02:23:57 2026 185574
```

Ce qui correspond à l'image cible :

- la grille `Modules narratifs` est sous la carte `Histoire principale` ;
- la grille est en deux lignes de trois colonnes sur capture desktop ;
- les surfaces sont bleu nuit / bleu-gris sombre ;
- les bordures restent subtiles ;
- `Quêtes annexes`, `Cinématiques`, `Dialogues`, `Conditions narratives`,
  `Règles du monde` et `Facts` sont visibles ;
- `Quêtes annexes` et `Facts` ne sont pas affichés comme données réelles ;
- les modules disponibles affichent des compteurs réels issus du read model.

Ce qui ne correspond pas encore :

- la top bar finale n'existe pas ;
- la sidebar finale n'existe pas ;
- le panneau droit `Structure narrative` n'existe pas ;
- les cartes ne sont pas pixel-perfect ;
- l'iconographie reste Cupertino V0 ;
- il n'y a pas de navigation réelle depuis les cartes ;
- le bloc `Activité récente` n'existe pas.

Inspection visuelle :

- la grille est lisible ;
- les états `Hors scope V0` et `Nécessite un modèle` sont compréhensibles ;
- `Quêtes annexes` ne ressemble pas à un compteur réel ;
- `Facts` ne ressemble pas à un compteur réel ;
- pas d'overflow visible sur le screenshot `1180x1220` ;
- hiérarchie lisible : projet -> KPI -> histoire principale -> modules.

Correction faite après inspection :

```text
Aucune correction visuelle supplémentaire n'a été nécessaire après inspection.
```

## 10. Commandes exécutées

Lectures et Gate initial :

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
sed -n '1,220p' AGENTS.md
sed -n '1,220p' agent_rules.md
sed -n '1,180p' skills/README.md
sed -n '1,220p' 'MVP Selbrume/road_map_global.md'
sed -n '1,220p' 'MVP Selbrume/road_map_phase_1.md'
sed -n '1,260p' reports/narrativeStudio/ui/ns_home_00_overview_roadmap_proposal.md
sed -n '1,260p' reports/narrativeStudio/ui/ns_home_01_overview_data_contract.md
sed -n '1,260p' reports/narrativeStudio/ui/ns_home_02_narrative_overview_read_model.md
sed -n '1,220p' reports/narrativeStudio/ui/ns_home_03_narrative_overview_shell_placement.md
sed -n '1,260p' reports/narrativeStudio/ui/ns_home_04_narrative_overview_kpi_cards.md
sed -n '1,260p' reports/narrativeStudio/ui/ns_home_05_narrative_overview_main_story_card.md
```

Tests et screenshot :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --plain-name "NarrativeOverviewWorkspace renders honest narrative module cards"
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --plain-name "NarrativeOverviewWorkspace module cards consume read model values"
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --no-test-assets --dart-define=NS_HOME_06_CAPTURE_SCREENSHOT=true --update-goldens --plain-name "NarrativeOverviewWorkspace captures module cards grid screenshot when requested"
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Analyse et Git :

```bash
cd packages/map_editor && flutter analyze
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_overview_workspace.dart test/ui/canvas/narrative_overview_workspace_test.dart
git diff --check
git status --short --untracked-files=all
git diff --stat
git diff --name-only
```

## 11. Résultats des tests

### RED

Commande :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --plain-name "NarrativeOverviewWorkspace renders honest narrative module cards"
```

Sortie RED :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
00:00 +0: NarrativeOverviewWorkspace renders honest narrative module cards
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Modules narratifs": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:304:7)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1682:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart line 304
The test description was:
  NarrativeOverviewWorkspace renders honest narrative module cards
════════════════════════════════════════════════════════════════════════════════════════════════════
00:00 +0 -1: NarrativeOverviewWorkspace renders honest narrative module cards [E]
  Test failed. See exception logs above.
  The test description was: NarrativeOverviewWorkspace renders honest narrative module cards
  
00:00 +0 -1: Some tests failed.
```

### GREEN ciblé module

Commande :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --plain-name "NarrativeOverviewWorkspace renders honest narrative module cards"
```

Sortie :

```text
00:00 +0: NarrativeOverviewWorkspace renders honest narrative module cards
00:00 +1: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --plain-name "NarrativeOverviewWorkspace module cards consume read model values"
```

Sortie :

```text
00:00 +0: NarrativeOverviewWorkspace module cards consume read model values
00:00 +1: All tests passed!
```

### Test workspace complet

Commande :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
00:00 +0: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: NarrativeOverviewWorkspace does not present unavailable modules as real data
00:00 +2: NarrativeOverviewWorkspace KPI cards consume read model values
00:00 +3: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
00:00 +4: NarrativeOverviewWorkspace renders an honest empty main story card
00:01 +5: NarrativeOverviewWorkspace renders explicit main story data from the read model
00:01 +6: NarrativeOverviewWorkspace explains missing description and fallback chapters
00:01 +7: NarrativeOverviewWorkspace renders ambiguous main story state explicitly
00:01 +8: NarrativeOverviewWorkspace renders honest narrative module cards
00:01 +9: NarrativeOverviewWorkspace module cards consume read model values
00:01 +10: NarrativeOverviewWorkspace module grid keeps previous overview blocks visible
00:01 +11: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:01 +12: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:01 +13: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:01 +14: All tests passed!
```

### Régression NS-HOME-03 / NS-HOME-04 / NS-HOME-05 / NS-HOME-06

Commande :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie :

```text
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace does not present unavailable modules as real data
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace KPI cards consume read model values
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders an honest empty main story card
00:01 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders explicit main story data from the read model
00:01 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace explains missing description and fallback chapters
00:01 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders ambiguous main story state explicitly
00:01 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders honest narrative module cards
00:01 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace module cards consume read model values
00:01 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace module grid keeps previous overview blocks visible
00:01 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:01 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:01 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:02 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:03 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeLibraryPanel exposes overview without removing existing studios
00:03 +16: All tests passed!
```

## 12. Résultats analyze

### Analyse globale

Commande :

```bash
cd packages/map_editor && flutter analyze
```

Résultat :

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
  error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3 • undefined_class
  error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
warning • The library 'package:map_editor/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart' doesn't export a member with the shown name 'showPokedexImportFlowSheet' • lib/src/ui/canvas/pokedex_workspace_views.dart:17:9 • undefined_shown_name
348 issues found. (ran in 3.3s)
```

Interprétation :

```text
Échec global dû à dette préexistante Pokémon SDK / Pokédex hors NS-HOME-06.
Aucune erreur ne pointe vers les fichiers modifiés par ce lot.
```

### Analyse ciblée

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_overview_workspace.dart test/ui/canvas/narrative_overview_workspace_test.dart
```

Sortie :

```text
Analyzing 2 items...

No issues found! (ran in 1.4s)
```

## 13. Limites

- La grille est une V0 visuelle, pas une grille finale pixel-perfect.
- Les actions `Studio relié` ne naviguent pas encore.
- `Quêtes annexes` reste hors scope sans modèle Quest.
- `Facts` reste indisponible sans registre de connaissances.
- `Lignes de dialogue` reste indisponible sans parsing Yarn.
- Le panneau droit `Structure narrative` n'existe pas encore.
- L'écran complet avec sidebar/topbar finale n'est pas encore produit.

## 14. Prochain lot recommandé

Prochain lot exact recommandé :

```text
NS-HOME-07 — Narrative Overview Structure Inspector Panel V0
```

Justification :

```text
Les blocs centraux principaux sont maintenant posés : KPI, Histoire principale,
Modules narratifs. Le prochain bloc majeur de l'image cible est le panneau
`Structure narrative`, qui doit consommer `readModel.structureInspector` sans
inventer description, tags, statuts ou counters Facts.
```

## 15. Evidence Pack

### Git initial

Commande :

```bash
git branch --show-current
```

Sortie :

```text
main
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
Sortie : <vide>
```

Log initial :

```text
e334cdee feat(narrative-studio): add narrative overview main story card
22eaad9c feat(narrative-studio): add narrative overview KPI cards
ac3518ad feat(narrative-studio): add narrative overview shell and workspace
0bc7bb9c docs: update narrative overview read model report
e0b389e7 feat(narrative-studio): add narrative overview read model
ef3224a0 docs: add narrative studio UI home overview data contract
6239b5fd docs: add narrative studio UI home overview roadmap proposal
0e2beef8 docs: add Phase 7 narrative studio information architecture and creator journey design
9a95f1b5 docs: add Phase 7 modern app shell and narrative studio UX inventory audit
1de262a2 docs: add Phase 7 roadmap bootstrap and narrative studio modern UI scope audit
```

### Git final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
?? reports/narrativeStudio/ui/ns_home_06_narrative_overview_module_cards_grid.md
?? reports/narrativeStudio/ui/screenshots/ns_home_06_overview_module_cards_grid.png
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../ui/canvas/narrative_overview_workspace.dart    | 286 +++++++++++++++++++++
 .../canvas/narrative_overview_workspace_test.dart  | 274 +++++++++++++++++++-
 2 files changed, 552 insertions(+), 8 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

### Fichiers créés

```text
reports/narrativeStudio/ui/screenshots/ns_home_06_overview_module_cards_grid.png
reports/narrativeStudio/ui/ns_home_06_narrative_overview_module_cards_grid.md
```

Note : ces fichiers sont non trackés tant que Yoahn/Karim ne les ajoute pas.
`git diff --stat` et `git diff --name-only` ne listent donc pas ces fichiers.

### Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

### Extraits des sections modifiées

Ajout principal dans `NarrativeOverviewWorkspace` :

```dart
_ModuleCardsSection(modules: readModel.modules),
```

Key de la grille :

```dart
key: const ValueKey('narrative-overview-module-grid'),
```

Key de chaque carte :

```dart
key: ValueKey('narrative-overview-module-${module.id}'),
```

Rendu de valeur :

```dart
String _moduleCardValue(NarrativeModuleSummary module) {
  return switch (module.availability) {
    NarrativeOverviewAvailability.available ||
    NarrativeOverviewAvailability.empty =>
      '${module.count ?? 0}',
    NarrativeOverviewAvailability.unavailable => 'Indisponible',
    NarrativeOverviewAvailability.notEvaluated => 'Non évalué',
    NarrativeOverviewAvailability.outOfScope => 'Hors scope V0',
    NarrativeOverviewAvailability.needsModel => 'Nécessite un modèle',
  };
}
```

### Recherche anti-hardcode

Commande :

```bash
rg -n "Selbrume|La brume du phare|Le départ|Le phare|Révélation|Cristal d’écho|42|1 236|1236|24|12|312" packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

Sortie pertinente :

```text
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:116:      expect(find.textContaining('Selbrume'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:117:      expect(find.textContaining('La brume du phare'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:118:      expect(find.text('42'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:119:      expect(find.text('1 236'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:120:      expect(find.text('1236'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:121:      expect(find.text('24'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:122:      expect(find.text('12'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:424:      expect(find.textContaining('Selbrume'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:425:      expect(find.textContaining('La brume du phare'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:426:      expect(find.text('42'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:427:      expect(find.text('24'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:428:      expect(find.text('12'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:429:      expect(find.text('312'), findsNothing);
```

Interprétation :

```text
Les occurrences de noms/chiffres de l'image sont des assertions négatives de
test. Les occurrences numériques dans le widget sont des dimensions/paddings UI,
pas des compteurs affichés comme données.
```

### Confirmations de scope

- Aucun fichier `map_core` modifié.
- Aucun fichier `map_runtime` modifié.
- Aucun fichier `map_gameplay` modifié.
- Aucun fichier `map_battle` modifié.
- `NarrativeOverviewReadModel` non modifié.
- Aucun provider créé.
- Aucun repository créé.
- Aucun faux compteur ajouté.
- Aucune fausse quête créée.
- Aucun faux Fact créé.
- Aucune activité récente créée.
- Aucune notification créée.
- Aucun commit et aucun staging effectués par Codex.

## 16. Auto-review critique

Ai-je ajouté la grille `Modules narratifs` ?

```text
Oui. La grille est rendue sous la carte Histoire principale.
```

Ai-je consommé exclusivement `readModel.modules` ?

```text
Oui. Le widget reçoit `List<NarrativeModuleSummary>` et ne lit aucune source
brute.
```

Ai-je gardé Quêtes et Facts honnêtes ?

```text
Oui. Quêtes reste `Hors scope V0`, Facts reste `Nécessite un modèle`, et aucun
faux zéro n'est affiché pour ces deux modules.
```

Ai-je évité une navigation réelle hors scope ?

```text
Oui. `Studio relié` et `Accès à venir` sont des affordances visuelles non
interactives.
```

Ai-je conservé KPI cards et Histoire principale ?

```text
Oui. Les tests de régression vérifient que ces blocs restent visibles.
```

Ai-je produit et inspecté un screenshot ?

```text
Oui. Le screenshot NS-HOME-06 a été généré, ouvert et inspecté.
```

Ai-je lancé les vérifications ?

```text
Oui. Tests ciblés OK, screenshot OK, analyse ciblée OK, `git diff --check` OK.
L'analyse globale échoue sur dette préexistante hors lot.
```

## 17. Regard critique sur le prompt

Le prompt est bien cadré : il demande la troisième brique visuelle sans pousser
vers une copie complète de l'image. La contrainte `readModel.modules` est la
bonne protection contre les fausses quêtes, les faux Facts et les compteurs
visuellement séduisants mais débranchés.

Le point à surveiller pour NS-HOME-07 sera la taille de
`narrative_overview_workspace.dart`, qui commence à porter plusieurs widgets
privés. Pour le panneau droit, il faudra probablement décider si on reste dans
ce fichier pour un lot encore, ou si on extrait des widgets privés dédiés sans
créer un design system prématuré.
