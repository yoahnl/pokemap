# NS-STORYLINES-03 — Storylines Workspace Shell Layout V0

## 1. Executive summary

NS-STORYLINES-03 introduit le premier shell visuel Storylines V0 branché sur `EditorWorkspaceMode.globalStory`.

Résultat livré :

- `NarrativeWorkspaceCanvas` rend maintenant `StorylinesWorkspace` pour le mode `globalStory`.
- Le shell Storylines V0 affiche trois zones : panneau secondaire, zone centrale, inspecteur placeholder.
- Les données affichées viennent du `ScenarioAsset globalStory` et de la projection narrative : nom, description, nombre de storylines globales, nombre d'étapes liées.
- Les fonctionnalités futures restent read-only / disabled / à venir.
- `Maps` reste absent de la sidebar interne Narrative Studio.
- Aucun `map_core`, runtime, gameplay ou battle n'a été modifié.
- Aucun `Color(0x...)` ou `Colors.*` n'a été ajouté dans les fichiers du lot.

Statut : **DONE**.

Prochain lot recommandé : `NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0`.

## 2. Inputs read

Fichiers de gouvernance et rapports lus :

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/storylines/road_map_storylines.md
reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md
reports/narrativeStudio/storylines/ns_storylines_01_read_model_data_contract_v0.md
reports/narrativeStudio/storylines/ns_storylines_02_current_global_story_characterization_anti_fake_tests_v0.md
reports/narrativeStudio/ui/ns_home_checkpoint_narrative_overview_acceptance_v0.md
reports/narrativeStudio/ui/ns_home_15_internal_shell_sidebar_architecture.md
```

Fichiers code inspectés :

```text
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart
packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/global_story_studio/global_story_studio_shell.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart
packages/map_editor/test/storylines_current_global_story_characterization_test.dart
```

Design system inspecté :

```text
packages/map_editor/lib/src/ui/design_system/design_system.dart
packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart
packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart
packages/map_editor/lib/src/theme/pokemap_color_tokens.dart
packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
packages/map_editor/lib/src/ui/shared/editor_visual_tokens.dart
```

Fichiers attendus absents : aucun des fichiers obligatoires ci-dessus n'était absent.

## 3. Implementation summary

Fichier créé :

```text
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
```

Le nouveau widget `StorylinesWorkspace` :

- reçoit `NarrativeWorkspaceProjection` et `selectedGlobalStoryId` ;
- sélectionne le scénario global courant ou le premier scénario global disponible ;
- dérive les étapes liées via `projection.steps.where((step) => step.globalScenarioId == selectedStory.id)` ;
- rend un `PokeMapPageSurface` en trois colonnes ;
- affiche un panneau secondaire Storylines ;
- affiche une zone centrale read-only ;
- affiche un inspecteur placeholder read-only.

Fichier modifié :

```text
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
```

Le mode `EditorWorkspaceMode.globalStory` est branché sur `StorylinesWorkspace`. Les anciens fichiers Global Story Studio ne sont pas supprimés.

Tests créés / adaptés :

```text
packages/map_editor/test/storylines_workspace_shell_test.dart
packages/map_editor/test/storylines_current_global_story_characterization_test.dart
```

La roadmap vivante a été mise à jour :

```text
reports/narrativeStudio/storylines/road_map_storylines.md
```

## 4. Design System Gate

Primitives utilisées dans le nouveau shell :

```text
PokeMapPageSurface
PokeMapInspectorPanel
PokeMapStatusTile
PokeMapIconTile
PokeMapTone
context.pokeMapColors
```

Mini audit :

```text
- Aucun widget générique de type card/pill/panel/tile créé localement pour Storylines.
- Aucun mini design system Storylines ajouté.
- Aucun Color(0x...) ajouté.
- Aucun Colors.* ajouté.
- Les surfaces passent par PokeMapPageSurface / PokeMapInspectorPanel.
- Les tons passent par PokeMapTone.
- Les couleurs texte passent par context.pokeMapColors.
```

Recherche demandée :

```text
Commande :
printf 'FULL_SCOPE_MATCHES\n' && rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas packages/map_editor/lib/src/features/narrative packages/map_editor/lib/src/ui/design_system | wc -l && printf 'ADDED_MATCHES_IN_DIFF\n' && git diff -U0 -- packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart | grep '^+' | grep -Ev '^\+\+\+' | grep -E 'Color\(0x|Colors\.' || true

Sortie exacte :
FULL_SCOPE_MATCHES
     249
ADDED_MATCHES_IN_DIFF
```

Interprétation :

- 249 occurrences existent déjà dans le périmètre large demandé.
- Aucune occurrence ajoutée dans le diff des fichiers du lot.

## 5. Data source / anti-fake guarantees

Données affichées autorisées :

| Zone | Donnée affichée | Source |
|---|---|---|
| Panneau secondaire | nombre de storylines globales | `projection.globalStories.length` |
| Panneau secondaire | titre de la storyline | `NarrativeScenarioSummary.name`, issu de `ScenarioAsset.name` |
| Zone centrale | titre | `NarrativeScenarioSummary.name` |
| Zone centrale | description | `NarrativeScenarioSummary.description`, issu de `ScenarioAsset.description` |
| Zone centrale / inspecteur | nombre d'étapes | dérivé de `projection.steps` filtré par `globalScenarioId` |
| Inspecteur | source | label prudent `ScenarioAsset globalStory` |

Données explicitement non ajoutées :

```text
Histoire globale
La brume du phare
Le port
Les marais
Le phare
Les cristaux de sel
Le Goélise du port
La cabane du phare
Mystère
Exploration
Phare
Côtiers
5 chapitres
27 scènes
412 dialogues
18 facts
3 problèmes
RÈGLES DU MONDE AFFECTÉES
DERNIÈRE ACTIVITÉ
```

Le test `storylines_workspace_shell_test.dart` vérifie l'absence des chaînes cible interdites avec une fixture neutre.

## 6. Disabled actions

Actions et zones futures visibles mais non fonctionnelles :

```text
Créer une quête annexe — À venir
Créer un chapitre — À venir
Graph — à venir
Chapitres — à venir
Inspecteur Storyline — à venir
Tags — À venir
Règles du monde — Non branché
Valider — Désactivé
```

Le header interne existant conserve :

```text
Nouvelle storyline
Valider
Recherche
Notifications
Paramètres
```

Ces actions restent désactivées par le contrat du header. Le test ajouté tape `Nouvelle storyline` et `Valider` avec `warnIfMissed: false`, puis vérifie que le workspace reste `EditorWorkspaceMode.globalStory`.

## 7. Sidebar / Maps guardrail

La règle NS-HOME reste intacte :

```text
ProjectExplorerPanel = sidebar globale PokeMap
NarrativeStudioSidebar = sidebar interne Narrative Studio
```

Ce lot :

- ne modifie pas `ProjectExplorerPanel` ;
- ne modifie pas `NarrativeStudioSidebar` ;
- ne réintroduit pas `Maps` dans la sidebar interne ;
- ne transforme pas `localEventFlow` en quête annexe Storylines.

Les tests vérifient :

```text
expect(find.text('Maps'), findsNothing);
expect(find.text('Audit Local Event Flow'), findsNothing);
```

## 8. Tests added or modified

Fichier créé :

```text
packages/map_editor/test/storylines_workspace_shell_test.dart
```

Couvertures :

- shell Storylines V0 visible ;
- trois régions visibles ;
- données réelles de fixture affichées ;
- données cible absentes ;
- `Maps` absent ;
- actions futures header non mutantes ;
- garde-fou source sans `Color(0x...)` / `Colors.*` ;
- Visual Gate par screenshots/goldens.

Fichier modifié :

```text
packages/map_editor/test/storylines_current_global_story_characterization_test.dart
```

Adaptation :

- le test NS-STORYLINES-02 ne caractérise plus l'ancien rendu `STRUCTURE / Votre récit / FIL NARRATIF` ;
- il préserve les garanties essentielles : rendu globalStory, données issues du manifest/metadata, anti-fake, séparation `globalStory` / `localEventFlow`, absence de `Maps`.

## 9. Visual Gate

Méthode :

```text
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart
```

Le test `writes Visual Gate screenshots` utilise `matchesGoldenFile` pour produire / vérifier les screenshots sous `reports/narrativeStudio/storylines/screenshots/`.

Captures produites :

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_desktop.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_focus.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_panels.png
```

Dimensions vérifiées :

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_desktop.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_focus.png:   PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_panels.png:  PNG image data, 1180 x 1000, 8-bit/color RGBA, non-interlaced
```

Analyse visuelle :

- Desktop 1600x1000 : le layout trois zones est visible ; la sidebar interne Narrative Studio reste intacte ; le shell Storylines est clairement dans la zone workspace ; les actions restent read-only / disabled.
- Focus 1600x700 : le haut du shell reste lisible ; la zone centrale et l'inspecteur restent visibles ; pas d'overflow observé.
- Panels 1180x1000 : largeur medium acceptable ; les trois zones restent présentes ; le contenu est plus compact mais stable.

Limite Visual Gate :

- Les screenshots Flutter golden utilisent la police de test Ahem ; les textes apparaissent en barres. Le gate valide donc layout / densité / overflow / structure, pas la typographie finale.

## 10. Roadmap update

Roadmap mise à jour :

```text
reports/narrativeStudio/storylines/road_map_storylines.md
```

Changements :

- `NS-STORYLINES-03` marqué `DONE`.
- Résumé du shell livré ajouté.
- Fichiers créés/modifiés listés.
- Tests/analyse/Visual Gate listés.
- Design System Gate confirmé.
- Absence de fake data confirmée.
- Prochain lot recommandé : `NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0`.

## 11. Commands run

### Tests

```text
Commande :
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart

Sortie exacte :
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-03 Storylines shell V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-03 Storylines shell V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-03 Storylines shell V0 storylines UI source keeps raw colors out of the feature
00:00 +3: NS-STORYLINES-03 Storylines shell V0 writes Visual Gate screenshots
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +4: All tests passed!
```

```text
Commande :
cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart

Sortie exacte :
Waiting for another flutter command to release the startup lock...
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
00:00 +0: NS-STORYLINES-02 current Global Story characterization renders the current Storylines shell from manifest and authoring metadata
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-02 current Global Story characterization keeps globalStory and localEventFlow separated in the current projection
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +2: All tests passed!
```

```text
Commande :
cd packages/map_editor && flutter test test/global_story_studio_workspace_test.dart

Sortie exacte :
Waiting for another flutter command to release the startup lock...
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/global_story_studio_workspace_test.dart
00:00 +0: GlobalStoryStudioWorkspace defers global/step selection callbacks after frame (provider-safe)
[step_studio_trace] action=apply_document scenario=global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=global_story contains_emma=false contains_empty_entity=false
00:00 +1: GlobalStoryStudioWorkspace can create a step from the shell without exceptions
[step_studio_trace] action=apply_document scenario=global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=global_story contains_emma=false contains_empty_entity=false
00:00 +2: All tests passed!
```

```text
Commande :
cd packages/map_editor && flutter test test/narrative_workspace_projection_test.dart

Sortie exacte :
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_projection_test.dart
00:00 +0: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:00 +1: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:00 +2: All tests passed!
```

### Analyze

```text
Commande :
cd packages/map_editor && flutter analyze

Sortie exacte pertinente :
Waiting for another flutter command to release the startup lock...
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
  error • The named parameter 'psdkScriptClass' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:83:9 • undefined_named_parameter
  error • The named parameter 'psdkScriptPath' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:84:9 • undefined_named_parameter
  error • The named parameter 'psdkAnimationId' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:85:9 • undefined_named_parameter
  error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3 • undefined_class
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:242:23 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:243:25 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:244:31 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:245:45 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:246:24 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:250:9 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:251:40 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:252:20 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:253:22 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:254:19 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:255:17 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:256:22 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:257:17 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:258:17 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:259:21 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:260:20 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:261:12 • undefined_identifier
  error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:265:38 • undefined_class
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:267:7 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:268:7 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:270:7 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:271:7 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:272:7 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:274:7 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:275:7 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:276:7 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:278:7 • undefined_identifier
  error • Undefined name 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:279:7 • undefined_identifier
  error • Undefined class 'PokemonMoveFlags' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:284:3 • undefined_class
  error • The name 'PokemonMoveFlags' isn't a class • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:286:20 • creation_with_non_type
  error • The method 'PokemonMoveFlags' isn't defined for the type 'PokemonSdkMoveCatalogConverter' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:295:12 • undefined_method
  error • The name 'PokemonMoveBattleStageMod' isn't a type, so it can't be used as a type argument • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:339:8 • non_type_as_type_argument
  error • The name 'PokemonMoveBattleStageMod' isn't a type, so it can't be used as a type argument • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:347:21 • non_type_as_type_argument
  error • The method 'PokemonMoveBattleStageMod' isn't defined for the type 'PokemonSdkMoveCatalogConverter' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:361:14 • undefined_method
  error • The name 'PokemonMoveStatus' isn't a type, so it can't be used as a type argument • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:383:8 • non_type_as_type_argument
  error • The name 'PokemonMoveStatus' isn't a type, so it can't be used as a type argument • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:389:21 • non_type_as_type_argument
  error • The method 'PokemonMoveStatus' isn't defined for the type 'PokemonSdkMoveCatalogConverter' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:403:14 • undefined_method
348 issues found. (ran in 3.6s)
```

Analyse ciblée :

```text
Commande :
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart

Sortie exacte :
Analyzing 4 items...

No issues found! (ran in 3.0s)
```

### Formatting / Git checks

```text
Commande :
dart format packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart

Résultat :
formatage appliqué puis revérifié implicitement par les tests/analyse ciblée.
```

```text
Commande :
git diff --check

Résultat final :
Voir Evidence Pack final ci-dessous.
```

## 12. Evidence Pack

### Git initial

```text
Commande :
git branch --show-current

Sortie exacte :
main
```

```text
Commande :
git status --short --untracked-files=all

Sortie initiale exacte :
<vide>
```

```text
Commande :
git diff --stat

Sortie initiale exacte :
<vide>
```

```text
Commande :
git diff --name-only

Sortie initiale exacte :
<vide>
```

```text
Commande :
git diff --check

Sortie initiale exacte :
<vide>
```

### Git final

Captures finales après création de ce rapport :

```text
git status final exact:
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/storylines_current_global_story_characterization_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
?? packages/map_editor/test/storylines_workspace_shell_test.dart
?? reports/narrativeStudio/storylines/ns_storylines_03_storylines_workspace_shell_layout_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_desktop.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_focus.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_panels.png

git diff --stat final:
 .../src/ui/canvas/narrative_workspace_canvas.dart  | 39 +-----------------
 ...current_global_story_characterization_test.dart | 46 +++++++---------------
 .../storylines/road_map_storylines.md              | 31 ++++++++++++---
 3 files changed, 42 insertions(+), 74 deletions(-)

git diff --name-only final:
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/storylines_current_global_story_characterization_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md

git diff --check final:
<vide>
```

Note : `git diff` ne liste pas les fichiers non trackés. Les fichiers créés non trackés sont donc compensés ci-dessous par contenu complet ou description binaire.

### Fichiers créés

```text
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_desktop.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_focus.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_panels.png
reports/narrativeStudio/storylines/ns_storylines_03_storylines_workspace_shell_layout_v0.md
```

Les screenshots sont des fichiers PNG binaires ; leur contenu complet n'est pas reproduit sous forme texte. Leur présence, chemin et dimensions sont fournis dans la section Visual Gate.

### Contenu complet du fichier créé : storylines_workspace.dart

```dart
import 'package:flutter/cupertino.dart';

import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';

class StorylinesWorkspace extends StatelessWidget {
  const StorylinesWorkspace({
    super.key,
    required this.projection,
    required this.selectedGlobalStoryId,
  });

  final NarrativeWorkspaceProjection projection;
  final String? selectedGlobalStoryId;

  @override
  Widget build(BuildContext context) {
    final selectedStory = _selectedStory;
    final relatedSteps = selectedStory == null
        ? <NarrativeStepSummary>[]
        : projection.steps
            .where((step) => step.globalScenarioId == selectedStory.id)
            .toList(growable: false);

    return PokeMapPageSurface(
      key: const ValueKey('storylines-workspace-shell'),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 240,
            child: _StorylinesSecondaryPanel(
              selectedStory: selectedStory,
              globalStoryCount: projection.globalStories.length,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StorylineMainPanel(
              selectedStory: selectedStory,
              stepCount: relatedSteps.length,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 280,
            child: _StorylineInspectorPlaceholder(
              selectedStory: selectedStory,
              stepCount: relatedSteps.length,
            ),
          ),
        ],
      ),
    );
  }

  NarrativeScenarioSummary? get _selectedStory {
    for (final story in projection.globalStories) {
      if (story.id == selectedGlobalStoryId) {
        return story;
      }
    }
    return projection.globalStories.isEmpty
        ? null
        : projection.globalStories.first;
  }
}

class _StorylinesSecondaryPanel extends StatelessWidget {
  const _StorylinesSecondaryPanel({
    required this.selectedStory,
    required this.globalStoryCount,
  });

  final NarrativeScenarioSummary? selectedStory;
  final int globalStoryCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapInspectorPanel(
      key: const ValueKey('storylines-secondary-panel'),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Text(
          'Storylines',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapStatusTile(
            label: 'Storylines globales',
            value: '$globalStoryCount',
            icon: CupertinoIcons.link,
            tone: PokeMapTone.narrative,
          ),
          const SizedBox(height: 12),
          if (selectedStory == null)
            Text(
              'Aucun scénario global disponible.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            )
          else
            PokeMapStatusTile(
              label: selectedStory!.name,
              value: 'Source réelle',
              icon: CupertinoIcons.book,
              tone: PokeMapTone.narrative,
            ),
          const SizedBox(height: 12),
          const PokeMapStatusTile(
            label: 'Créer une quête annexe',
            value: 'À venir',
            icon: CupertinoIcons.lock,
            tone: PokeMapTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _StorylineMainPanel extends StatelessWidget {
  const _StorylineMainPanel({
    required this.selectedStory,
    required this.stepCount,
  });

  final NarrativeScenarioSummary? selectedStory;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final description = selectedStory?.description.trim();
    return PokeMapInspectorPanel(
      key: const ValueKey('storylines-main-panel'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.link,
                tone: PokeMapTone.narrative,
                size: 42,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedStory?.name ?? 'Storyline non disponible',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description == null || description.isEmpty
                          ? 'Description non renseignée dans le scénario.'
                          : description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const PokeMapStatusTile(
                label: 'Mode lecture seule',
                value: 'Storylines V0',
                icon: CupertinoIcons.lock,
                tone: PokeMapTone.info,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              PokeMapStatusTile(
                label: 'Étapes réelles',
                value: '$stepCount',
                icon: CupertinoIcons.list_bullet,
                tone: PokeMapTone.narrative,
              ),
              const PokeMapStatusTile(
                label: 'Graph — à venir',
                value: 'Placeholder',
                icon: CupertinoIcons.arrow_branch,
                tone: PokeMapTone.neutral,
              ),
              const PokeMapStatusTile(
                label: 'Chapitres — à venir',
                value: 'Read model prochain',
                icon: CupertinoIcons.square_list,
                tone: PokeMapTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 360,
            child: PokeMapPageSurface(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zone centrale Storyline',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Le graph macro et les chapitres resteront read-only tant que leurs sources ne sont pas stabilisées.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const PokeMapStatusTile(
                    label: 'Créer un chapitre',
                    value: 'À venir',
                    icon: CupertinoIcons.lock,
                    tone: PokeMapTone.neutral,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorylineInspectorPlaceholder extends StatelessWidget {
  const _StorylineInspectorPlaceholder({
    required this.selectedStory,
    required this.stepCount,
  });

  final NarrativeScenarioSummary? selectedStory;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapInspectorPanel(
      key: const ValueKey('storylines-inspector-placeholder'),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Text(
          'Inspecteur Storyline — à venir',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapStatusTile(
            label: 'Source',
            value: selectedStory == null
                ? 'Aucun scénario'
                : 'ScenarioAsset globalStory',
            icon: CupertinoIcons.doc_text,
            tone: PokeMapTone.narrative,
          ),
          const SizedBox(height: 10),
          PokeMapStatusTile(
            label: 'Étapes',
            value: '$stepCount',
            icon: CupertinoIcons.list_bullet,
            tone: PokeMapTone.info,
          ),
          const SizedBox(height: 10),
          const PokeMapStatusTile(
            label: 'Tags',
            value: 'À venir',
            icon: CupertinoIcons.tag,
            tone: PokeMapTone.neutral,
          ),
          const SizedBox(height: 10),
          const PokeMapStatusTile(
            label: 'Règles du monde',
            value: 'Non branché',
            icon: CupertinoIcons.lock,
            tone: PokeMapTone.neutral,
          ),
          const SizedBox(height: 18),
          const PokeMapStatusTile(
            label: 'Valider',
            value: 'Désactivé',
            icon: CupertinoIcons.shield,
            tone: PokeMapTone.neutral,
          ),
        ],
      ),
    );
  }
}
```

### Contenu complet du fichier créé : storylines_workspace_shell_test.dart

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/application/global_story_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';

void main() {
  group('NS-STORYLINES-03 Storylines shell V0', () {
    testWidgets(
      'renders a read-only three-pane shell from real global story data',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1600, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final harness = await _pumpStorylinesShell(tester);

        expect(find.byKey(const ValueKey('storylines-workspace-shell')),
            findsOneWidget);
        expect(find.byKey(const ValueKey('storylines-secondary-panel')),
            findsOneWidget);
        expect(find.byKey(const ValueKey('storylines-main-panel')),
            findsOneWidget);
        expect(find.byKey(const ValueKey('storylines-inspector-placeholder')),
            findsOneWidget);

        expect(find.text('Audit Story From Scenario'), findsWidgets);
        expect(find.text('Audit description from scenario'), findsOneWidget);
        expect(find.text('Mode lecture seule'), findsOneWidget);
        expect(find.text('Storylines V0'), findsWidgets);
        expect(find.text('Graph — à venir'), findsOneWidget);
        expect(find.text('Chapitres — à venir'), findsOneWidget);
        expect(find.text('Inspecteur Storyline — à venir'), findsOneWidget);
        expect(find.text('Audit Local Event Flow'), findsNothing);

        for (final forbidden in _targetOnlyStrings) {
          expect(
            find.text(forbidden),
            findsNothing,
            reason: '$forbidden must not be injected in Storylines shell V0.',
          );
        }

        expect(find.text('Maps'), findsNothing);
        expect(find.text('Facts'), findsOneWidget);
        expect(find.text('Règles du monde'), findsWidgets);
        expect(find.text('Validateur'), findsOneWidget);

        expect(
          harness.container.read(editorNotifierProvider).workspaceMode,
          EditorWorkspaceMode.globalStory,
        );
      },
    );

    testWidgets(
      'keeps future header actions disabled and non-mutating',
      (tester) async {
        final harness = await _pumpStorylinesShell(tester);

        await tester.tap(
          find.byKey(
            const ValueKey('narrative-studio-header-action-new-storyline'),
          ),
          warnIfMissed: false,
        );
        await tester.pump();

        await tester.tap(
          find.byKey(const ValueKey('narrative-studio-header-action-validate')),
          warnIfMissed: false,
        );
        await tester.pump();

        expect(
          harness.container.read(editorNotifierProvider).workspaceMode,
          EditorWorkspaceMode.globalStory,
        );
        expect(find.text('Audit Story From Scenario'), findsWidgets);
      },
    );

    test('storylines UI source keeps raw colors out of the feature', () {
      final source = File('lib/src/ui/canvas/storylines_workspace.dart');
      expect(source.existsSync(), isTrue);

      final contents = source.readAsStringSync();

      expect(contents.contains('Color(0x'), isFalse);
      expect(contents.contains('Colors.'), isFalse);
    });

    testWidgets('writes Visual Gate screenshots', (tester) async {
      await _pumpStorylinesShell(
        tester,
        surfaceSize: const Size(1600, 1000),
      );
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_03_shell_desktop.png',
        ),
      );

      await _pumpStorylinesShell(
        tester,
        surfaceSize: const Size(1600, 700),
      );
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_03_shell_focus.png',
        ),
      );

      await _pumpStorylinesShell(
        tester,
        surfaceSize: const Size(1180, 1000),
      );
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_03_shell_panels.png',
        ),
      );
    });
  });
}

const _targetOnlyStrings = <String>[
  'La brume du phare',
  'Les cristaux de sel',
  'Le Goélise du port',
  'La cabane du phare',
  'Mystère',
  'Exploration',
  'Phare',
  'Côtiers',
  '412',
  '18',
  'RÈGLES DU MONDE AFFECTÉES',
  'DERNIÈRE ACTIVITÉ',
];

Future<_StorylinesHarness> _pumpStorylinesShell(
  WidgetTester tester, {
  Size surfaceSize = const Size(1600, 1000),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer();
  addTearDown(container.dispose);
  final editorSubscription = container.listen(
    editorNotifierProvider,
    (_, __) {},
  );
  addTearDown(editorSubscription.close);

  container.read(editorNotifierProvider.notifier).state = EditorState(
    project: _auditProject(),
    workspaceMode: EditorWorkspaceMode.globalStory,
  );
  container
      .read(narrativeWorkspaceControllerProvider.notifier)
      .openGlobalStory(scenarioId: 'audit_global_story');

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: surfaceSize.width,
            height: surfaceSize.height,
            child: const NarrativeWorkspaceCanvas(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();

  return _StorylinesHarness(container);
}

ProjectManifest _auditProject() {
  const stepDocument = StepStudioDocument(
    globalStoryScenarioId: 'audit_global_story',
    steps: <StepStudioStep>[
      StepStudioStep(
        id: 'audit_step',
        name: 'Audit Step From Metadata',
        description: 'Audit Step Detail From Metadata',
        order: 0,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.atGameStart,
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.manual,
        ),
      ),
    ],
  );
  const globalDocument = GlobalStoryStudioDocument(
    globalStoryScenarioId: 'audit_global_story',
    entryStepId: 'audit_step',
    nodes: <GlobalStoryStepNode>[
      GlobalStoryStepNode(stepId: 'audit_step'),
    ],
    chapters: <GlobalStoryChapter>[
      GlobalStoryChapter(
        id: 'audit_chapter',
        name: 'Audit Chapter From Metadata',
        description: 'Audit chapter description from metadata',
        stepIds: <String>['audit_step'],
        order: 0,
      ),
    ],
  );

  final globalScenario = applyGlobalStoryStudioDocumentToGlobalScenario(
    applyStepStudioDocumentToGlobalScenario(
      const ScenarioAsset(
        id: 'audit_global_story',
        name: 'Audit Story From Scenario',
        description: 'Audit description from scenario',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
      ),
      stepDocument,
    ),
    globalDocument,
    stepDocument: stepDocument,
  );

  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'Audit Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: <ScenarioAsset>[
      globalScenario,
      const ScenarioAsset(
        id: 'audit_local_event_flow',
        name: 'Audit Local Event Flow',
        description: 'Audit local flow must not become a side quest',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'local_start',
      ),
    ],
  );
}

class _StorylinesHarness {
  const _StorylinesHarness(this.container);

  final ProviderContainer container;
}
```

### Diff complet des fichiers modifiés

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart b/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
index fe4eac3e..df99eb51 100644
--- a/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
+++ b/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
@@ -11,10 +11,10 @@ import '../../features/narrative/state/narrative_workspace_state.dart';
 import '../shared/cupertino_editor_widgets.dart';
 import 'cutscene_studio_workspace.dart';
 import 'dialogue_studio_workspace.dart';
-import 'global_story_studio_workspace.dart';
 import 'narrative_overview_workspace.dart';
 import 'narrative_studio_shell.dart';
 import 'step_studio_workspace.dart';
+import 'storylines_workspace.dart';

 /// Workspace central du studio narratif.
 ///
@@ -110,44 +110,9 @@ class NarrativeWorkspaceCanvas extends ConsumerWidget {
           onOpenCutscenes: openCutscene,
           onOpenDialogues: openDialogue,
         ),
-      EditorWorkspaceMode.globalStory => GlobalStoryStudioWorkspace(
-          editorNotifier: editorNotifier,
-          project: editor.project,
+      EditorWorkspaceMode.globalStory => StorylinesWorkspace(
           projection: projection,
           selectedGlobalStoryId: narrative.selectedGlobalStoryId,
-          selectedStepId: narrative.selectedStepId,
-          onSelectGlobalStory: (scenarioId) {
-            if (scenarioId == null || scenarioId.trim().isEmpty) {
-              return;
-            }
-            narrativeController.selectGlobalStory(scenarioId);
-            narrativeController.openGlobalStory(scenarioId: scenarioId);
-          },
-          onSelectStep: (stepId) {
-            if (stepId == null || stepId.trim().isEmpty) {
-              return;
-            }
-            final step = projection.steps
-                .where((item) => item.id == stepId)
-                .cast<NarrativeStepSummary?>()
-                .firstWhere((item) => item != null, orElse: () => null);
-            narrativeController.selectStep(stepId);
-            if (step != null) {
-              narrativeController.selectGlobalStory(step.globalScenarioId);
-            }
-          },
-          onOpenStepStudio: (stepId) {
-            final step = projection.steps
-                .where((item) => item.id == stepId)
-                .cast<NarrativeStepSummary?>()
-                .firstWhere((item) => item != null, orElse: () => null);
-            narrativeController.selectStep(stepId);
-            narrativeController.openStep(
-              stepId: stepId,
-              globalScenarioId: step?.globalScenarioId,
-            );
-            editorNotifier.selectStepWorkspace();
-          },
         ),
       EditorWorkspaceMode.step => _StepWorkspaceBody(
           projection: projection,
diff --git a/packages/map_editor/test/storylines_current_global_story_characterization_test.dart b/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
index bbe2e101..25e6af2c 100644
--- a/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
+++ b/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
@@ -1,4 +1,3 @@
-import 'package:flutter/cupertino.dart';
 import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:flutter_riverpod/flutter_riverpod.dart';
@@ -14,7 +13,7 @@ import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
 void main() {
   group('NS-STORYLINES-02 current Global Story characterization', () {
     testWidgets(
-      'renders the legacy Global Story Studio from manifest and authoring metadata',
+      'renders the current Storylines shell from manifest and authoring metadata',
       (tester) async {
         await tester.binding.setSurfaceSize(const Size(1600, 1000));
         addTearDown(() => tester.binding.setSurfaceSize(null));
@@ -28,37 +27,28 @@ void main() {
             findsOneWidget);
         expect(find.byKey(const ValueKey('narrative-studio-header')),
             findsOneWidget);
+        expect(find.byKey(const ValueKey('storylines-workspace-shell')),
+            findsOneWidget);

         expect(find.text('Storylines'), findsWidgets);
-        expect(find.text('Audit Story From Scenario'), findsOneWidget);
-        expect(_chapterFieldWithText('Audit Chapter From Metadata'),
-            findsOneWidget);
-        expect(find.text('Audit Step From Metadata'), findsWidgets);
-        expect(find.text('Audit Step Detail From Metadata'), findsWidgets);
-
-        // Current characterization: ScenarioAsset.description is present in
-        // the projection, but the legacy screen does not render it yet.
-        expect(find.text('Audit description from scenario'), findsNothing);
-
-        expect(find.text('STRUCTURE'), findsOneWidget);
-        expect(find.text('Votre récit'), findsOneWidget);
-        expect(find.text('FIL NARRATIF'), findsOneWidget);
-        expect(find.text('Progression globale'), findsOneWidget);
-        expect(find.text('DÉTAIL DE L’ÉTAPE'), findsOneWidget);
-
-        // Legacy Global Story Studio actions are characterized, not removed.
-        expect(find.text('Réinitialiser'), findsOneWidget);
-        expect(find.text('Tester'), findsOneWidget);
+        expect(find.text('Audit Story From Scenario'), findsWidgets);
+        expect(find.text('Audit description from scenario'), findsOneWidget);
+        expect(find.text('Étapes réelles'), findsOneWidget);
+        expect(find.text('1'), findsWidgets);
+
+        expect(find.text('Mode lecture seule'), findsOneWidget);
+        expect(find.text('Graph — à venir'), findsOneWidget);
+        expect(find.text('Chapitres — à venir'), findsOneWidget);
         expect(find.text('Valider'), findsWidgets);
-        expect(find.text('+ Nouvelle étape'), findsOneWidget);

-        // Future Storylines action exists only in the internal header shell.
+        // Future Storylines action exists in the internal header shell, but is
+        // disabled by the widget contract.
         expect(find.text('Nouvelle storyline'), findsOneWidget);

         // NS-HOME guardrail: Maps is not an internal Narrative Studio entry.
         expect(find.text('Maps'), findsNothing);
         expect(find.text('Facts'), findsOneWidget);
-        expect(find.text('Règles du monde'), findsOneWidget);
+        expect(find.text('Règles du monde'), findsWidgets);
         expect(find.text('Validateur'), findsOneWidget);

         // localEventFlow is available to the projection, but is not displayed
@@ -127,14 +117,6 @@ const _targetOnlyStrings = <String>[
   'DERNIÈRE ACTIVITÉ',
 ];

-Finder _chapterFieldWithText(String value) {
-  return find.byWidgetPredicate(
-    (widget) =>
-        widget is CupertinoTextField && widget.controller?.text == value,
-    description: 'CupertinoTextField with text "$value"',
-  );
-}
-
 Future<void> _pumpGlobalStoryCanvas(
   WidgetTester tester,
   ProjectManifest project,
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index a4e2a8f3..1dae538f 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -291,7 +291,7 @@ Interprétation V0 :
 |---|---|---|---|---|
 | NS-STORYLINES-01 | Storylines Read Model / Data Contract V0 | core/design | DONE | NS-STORYLINES-02 |
 | NS-STORYLINES-02 | Current Global Story Characterization / Anti-Fake Tests V0 | test/audit | DONE | NS-STORYLINES-03 |
-| NS-STORYLINES-03 | Storylines Workspace Shell Layout V0 | editor UI | TODO | NS-STORYLINES-04 |
+| NS-STORYLINES-03 | Storylines Workspace Shell Layout V0 | editor UI | DONE | NS-STORYLINES-04 |
 | NS-STORYLINES-04 | Storylines Secondary List Panel Read-only V0 | editor UI | TODO | NS-STORYLINES-05 |
 | NS-STORYLINES-05 | Storyline Header / Tabs / KPI Read-only V0 | editor UI | TODO | NS-STORYLINES-06 |
 | NS-STORYLINES-06 | Storyline Graph Read-only Placeholder V0 | editor UI / visual gate | TODO | NS-STORYLINES-07 |
@@ -364,7 +364,16 @@ Interprétation V0 :
 - Visual Gate : desktop + focus.
 - Risques : créer un shell visuel sans source de données.
 - Design system impact : fort ; bloquer si primitive manquante.
-- Statut : TODO.
+- Statut : DONE.
+- Résultat NS-STORYLINES-03 : premier shell Storylines V0 livré et branché sur `EditorWorkspaceMode.globalStory`, avec panneau secondaire, zone centrale et inspecteur placeholder.
+- Fichiers créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, captures Visual Gate sous `reports/narrativeStudio/storylines/screenshots/`.
+- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`, `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
+- Données : `ScenarioAsset.name`, `ScenarioAsset.description`, nombre réel de global stories et nombre dérivé de steps affichés ; aucune donnée cible hardcodée.
+- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/global_story_studio_workspace_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
+- Analyse exécutée : `flutter analyze` global lancé et échoué sur dette préexistante ; analyse ciblée des fichiers touchés propre.
+- Visual Gate : `ns_storylines_03_shell_desktop.png`, `ns_storylines_03_shell_focus.png`, `ns_storylines_03_shell_panels.png`.
+- Design System Gate : confirmé ; primitives `PokeMapPageSurface`, `PokeMapInspectorPanel`, `PokeMapStatusTile`, `PokeMapIconTile`, `PokeMapTone` utilisées ; aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers du lot.
+- Fake data : aucune donnée Selbrume/cible ajoutée ; actions futures affichées disabled/read-only.
 - Prochain lot attendu : NS-STORYLINES-04.

 ### NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0
@@ -628,9 +637,9 @@ Décision temporaire :

 ```text
 Roadmap status: ACTIVE
-Current lot: NS-STORYLINES-02
+Current lot: NS-STORYLINES-03
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-03 — Storylines Workspace Shell Layout V0
+Next recommended lot: NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0
 ```

 | Lot | Status | Last update | Notes |
@@ -639,7 +648,7 @@ Next recommended lot: NS-STORYLINES-03 — Storylines Workspace Shell Layout V0
 | NS-STORYLINES-ROADMAP-00 | DONE | 2026-05-27 | Roadmap vivante créée. |
 | NS-STORYLINES-01 | DONE | 2026-05-27 | Contrat de données Storylines V0 documenté ; aucun code/test modifié. |
 | NS-STORYLINES-02 | DONE | 2026-05-27 | Tests de caractérisation anti-fake ajoutés ; ancien Global Story Studio verrouillé sans code production. |
-| NS-STORYLINES-03 | TODO | 2026-05-27 | UI shell après contrat/tests. |
+| NS-STORYLINES-03 | DONE | 2026-05-28 | Shell Storylines V0 read-only livré avec layout 3 zones, anti-fake, captures Visual Gate et tests ciblés. |
 | NS-STORYLINES-04 | TODO | 2026-05-27 | Secondary list read-only. |
 | NS-STORYLINES-05 | TODO | 2026-05-27 | Header/tabs/KPI read-only. |
 | NS-STORYLINES-06 | TODO | 2026-05-27 | Graph read-only placeholder. |
@@ -652,6 +661,18 @@ Next recommended lot: NS-STORYLINES-03 — Storylines Workspace Shell Layout V0

 ## 14. Changelog

+### 2026-05-28 — NS-STORYLINES-03
+
+- Création de `StorylinesWorkspace`, premier shell Storylines V0 read-only.
+- Branchement de `EditorWorkspaceMode.globalStory` vers le shell Storylines V0 dans `NarrativeWorkspaceCanvas`.
+- Conservation des anciens fichiers Global Story Studio sans suppression.
+- Adaptation du test de caractérisation NS-STORYLINES-02 pour préserver les garanties anti-fake sur le nouveau shell.
+- Ajout de `storylines_workspace_shell_test.dart` couvrant le shell, les données réelles, les actions disabled, l'absence de Maps et le gate anti-couleurs.
+- Production des captures Visual Gate desktop, focus et medium/panels.
+- Confirmation : aucune donnée cible hardcodée, aucune action future activée, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers du lot.
+- Tests ciblés Storylines / Global Story / Projection passés ; analyse ciblée clean.
+- Prochain lot recommandé : `NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0`.
+
 ### 2026-05-27 — NS-STORYLINES-02

 - Ajout du test `storylines_current_global_story_characterization_test.dart`.
```

### Contenu complet du rapport créé

Le présent fichier est le rapport créé. Son contenu complet correspond à l'ensemble des sections `1` à `13` de ce document. Une auto-inclusion littérale du rapport dans lui-même créerait une récursion infinie ; l'evidence utile et vérifiable est donc intégrée directement dans les sections ci-dessus.

## 13. Self-review

Points validés :

- Le shell Storylines V0 existe et est branché sur `EditorWorkspaceMode.globalStory`.
- Le rendu reste read-only et anti-fake.
- Les anciens fichiers Global Story Studio ne sont pas supprimés.
- Les tests NS-STORYLINES-02 gardent leurs garanties essentielles.
- `Maps` n'est pas réintroduit dans la sidebar interne.
- Les actions futures restent disabled / non mutantes.
- Les tests ciblés passent.
- L'analyse ciblée passe.
- Le Visual Gate produit trois captures.
- La roadmap est mise à jour.

Limites :

- `flutter analyze` global échoue encore sur une dette préexistante hors Storylines, notamment `pokemon_sdk_move_catalog_converter.dart`.
- Le shell n'implémente pas encore la liste riche, le graph, les KPI, l'inspecteur final ni l'onglet Chapitres. C'est volontairement hors scope NS-STORYLINES-03.
- Les screenshots golden utilisent Ahem ; ils valident surtout la structure et l'absence d'overflow.

Auto-review critique :

- Le choix de `PokeMapStatusTile` évite de créer des cards locales et respecte le design system, mais le shell reste encore très placeholder.
- Le branchement remplace le rendu visible de l'ancien workspace tout en conservant ses fichiers et ses tests propres ; c'est le bon niveau de bascule pour ce lot.
- Le prochain lot doit se concentrer sur le panneau secondaire read-only, sans réintroduire quêtes annexes fake ni recherche active.
