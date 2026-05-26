# NS-HOME-02 — NarrativeOverviewReadModel V0

## 1. Résumé exécutif

NS-HOME-02 crée le premier socle code de la page d'accueil
`Narrative Studio / Aperçu` : un read model pur côté `map_editor`, sans UI
Flutter, sans provider, sans runtime, sans lecture disque et sans modèle
`map_core`.

API créée :

```dart
NarrativeOverviewReadModel buildNarrativeOverviewReadModel({
  required ProjectManifest project,
  NarrativeValidationReport? narrativeValidationReport,
  List<NarrativeAuthoringDiagnosticView> authoringDiagnostics = const [],
  List<DialogueValidationIssue> dialogueIssues = const [],
})
```

Le builder transforme `ProjectManifest`, les projections narratives existantes,
les métadonnées Global Story / Step Studio / Cutscene Studio et les diagnostics
optionnels en une structure consommable par une future UI. Chaque donnée peut
être `available`, `empty`, `unavailable`, `notEvaluated`, `outOfScope` ou
`needsModel`.

## 2. Rappel du contrat NS-HOME-01

Décisions appliquées :

- dashboard auteur uniquement ;
- aucune lecture de `GameState`, `SaveData`, runtime, battle ou gameplay ;
- aucun compteur hardcodé depuis l'image ;
- aucun nom Selbrume hardcodé ;
- `Quêtes` hors scope V0 ;
- `Facts` nécessite un futur modèle ;
- `Activité récente` hors scope V0 ;
- `Notifications` hors scope V0 ;
- `dialogueLines` indisponible sans lecture/parsing Yarn ;
- `openIssues` vaut `notEvaluated` sans diagnostic fourni ;
- `openIssues = 0` après validation est un vrai zéro disponible, pas un empty
  state ;
- `À jour` n'est produit que si une validation réelle est fournie et sans
  diagnostic.

## 3. Fichiers créés / modifiés

Fichiers créés :

```text
packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
packages/map_editor/test/features/narrative/application/overview/narrative_overview_read_model_test.dart
reports/narrativeStudio/ui/ns_home_02_narrative_overview_read_model.md
```

Fichiers modifiés :

```text
Aucun fichier existant modifié.
```

Le fichier de read model fait 1 133 lignes et le test ciblé 444 lignes. Le
rapport documente donc les sections structurantes, l'API et les comportements
testés plutôt que recopier intégralement ces deux fichiers.

## 4. API créée

```dart
NarrativeOverviewReadModel buildNarrativeOverviewReadModel({
  required ProjectManifest project,
  NarrativeValidationReport? narrativeValidationReport,
  List<NarrativeAuthoringDiagnosticView> authoringDiagnostics =
      const <NarrativeAuthoringDiagnosticView>[],
  List<DialogueValidationIssue> dialogueIssues =
      const <DialogueValidationIssue>[],
})
```

Propriétés importantes :

- fonctionne avec un projet minimal ;
- fonctionne sans validation report ;
- ne lit pas le disque ;
- ne parse pas les fichiers Yarn ;
- ne dépend pas de widget Flutter ;
- ne dépend pas de Riverpod ;
- ne dépend pas du runtime.

## 5. Modèles créés

Enums créées :

```text
NarrativeOverviewAvailability
NarrativeOverviewSourceStatus
NarrativeEditorialValidationState
NarrativeProjectHealthKind
NarrativeChapterEditorialStatus
```

Classes créées :

```text
NarrativeOverviewReadModel
NarrativeOverviewMetrics
NarrativeMetricSummary
MainStoryOverviewSummary
NarrativeChapterOverviewSummary
NarrativeModuleSummary
NarrativeStructureInspectorSummary
EditorialStatusSummary
NarrativeProjectHealthSummary
NarrativeOverviewFeatureSummary
NarrativeOverviewFooterSummary
NarrativeOverviewModuleIds
```

États de disponibilité couverts :

```text
available
empty
unavailable
notEvaluated
outOfScope
needsModel
```

États de source couverts :

```text
explicit
fallback
missing
ambiguous
notApplicable
```

## 6. Calculs réellement implémentés

Calculs V0 implémentés :

- `projectName` depuis `ProjectManifest.name` ;
- dialogues depuis `ProjectManifest.dialogues.length` ;
- global stories depuis `ScenarioAsset.scope == globalStory` ;
- histoire principale si exactement une global story existe ;
- ambiguïté si plusieurs global stories existent ;
- chapitres depuis `GlobalStoryStudioDocument` ;
- source `fallback` si metadata Global Story absente et fallback généré ;
- cinématiques depuis `localEventFlow` + metadata Cutscene Studio reconnue ;
- scènes depuis les cutscenes liées aux steps et résolues vers une cutscene
  authorée ;
- conditions narratives depuis Step Studio, conditions de scénarios et
  conditions de nodes ;
- world rules depuis `StepStudioWorldChange` ;
- dialogues liés à l'histoire principale via nodes de cutscene référencés ;
- diagnostics warning => `À revoir` ;
- diagnostics error => `Bloquant` ;
- validation fournie sans diagnostic => `À jour` ;
- absence de validation => `Non évalué`.

## 7. Données volontairement indisponibles en V0

```text
Quêtes : outOfScope
Facts : needsModel
dialogueLines : unavailable
recentActivity : outOfScope
notifications : outOfScope
footer.locale : unavailable
footer.version : unavailable
```

Raison : aucune source fiable n'existe encore dans le repo pour afficher ces
données comme vraies dans le dashboard auteur.

## 8. Tests ajoutés

Test ciblé créé :

```text
packages/map_editor/test/features/narrative/application/overview/narrative_overview_read_model_test.dart
```

Cas couverts :

1. projet minimal sans données inventées ;
2. global story explicite avec chapitres, cutscene, dialogue, conditions et
   world rule ;
3. chapitres fallback quand la metadata Global Story manque ;
4. plusieurs global stories => main story ambiguë ;
5. warning diagnostic => `À revoir` ;
6. error dialogue diagnostic => `Bloquant` ;
7. distinction `0 réel` vs `unavailable` ;
8. absence de hardcode image / Selbrume.

Les fixtures utilisent des ids génériques :

```text
test_project
test_global_story
test_chapter_1
test_dialogue_1
test_cutscene_1
```

## 9. Commandes exécutées

### Gate 0

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
ef3224a0 docs: add narrative studio UI home overview data contract
6239b5fd docs: add narrative studio UI home overview roadmap proposal
0e2beef8 docs: add Phase 7 narrative studio information architecture and creator journey design
9a95f1b5 docs: add Phase 7 modern app shell and narrative studio UX inventory audit
1de262a2 docs: add Phase 7 roadmap bootstrap and narrative studio modern UI scope audit
1ca0154d docs: add Phase 7 roadmap and P6 checkpoint 01 Selbrume beta slice readiness review
f7612f05 feat(P6-08): add Selbrume playable runtime smoke tests and report
8258c5cb feat(P6-07): add Selbrume beta validator pass tests and report
76820007 feat(P6-06): add Selbrume save/load golden slice tests and report
9ca30c63 docs: add Phase 6 roadmap consistency fix
```

`git status`, `git diff --stat` et `git diff --name-only` étaient vides au
Gate 0.

### RED test

```bash
cd packages/map_editor && flutter test test/features/narrative/application/overview/narrative_overview_read_model_test.dart
```

Sortie pertinente :

```text
Error when reading 'lib/src/features/narrative/application/overview/narrative_overview_read_model.dart': No such file or directory
Error: Method not found: 'buildNarrativeOverviewReadModel'.
00:00 +0 -1: Some tests failed.
```

Le test échouait parce que le read model n'existait pas encore.

### Format

```bash
cd packages/map_editor && dart format lib/src/features/narrative/application/overview/narrative_overview_read_model.dart test/features/narrative/application/overview/narrative_overview_read_model_test.dart
```

Sortie :

```text
Formatted lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
Formatted test/features/narrative/application/overview/narrative_overview_read_model_test.dart
Formatted 2 files (2 changed) in 0.02 seconds.
```

### Test ciblé GREEN

```bash
cd packages/map_editor && flutter test test/features/narrative/application/overview/narrative_overview_read_model_test.dart
```

Sortie :

```text
00:00 +0: buildNarrativeOverviewReadModel represents a minimal project without inventing unavailable data
00:00 +1: buildNarrativeOverviewReadModel projects one explicit global story with authoring metrics
00:00 +2: buildNarrativeOverviewReadModel marks chapters as fallback when Global Story metadata is absent
00:00 +3: buildNarrativeOverviewReadModel does not choose a main story when multiple global stories exist
00:00 +4: buildNarrativeOverviewReadModel maps warning diagnostics to review status
00:00 +5: buildNarrativeOverviewReadModel maps error diagnostics to blocking status
00:00 +6: buildNarrativeOverviewReadModel keeps zero real counts distinct from unavailable data
00:00 +7: buildNarrativeOverviewReadModel does not hardcode image or Selbrume values
00:00 +8: All tests passed!
```

### Analyze global

```bash
cd packages/map_editor && flutter analyze
```

Résultat :

```text
Analyzing map_editor...
348 issues found. (ran in 3.7s)
```

Sortie pertinente des erreurs hors lot :

```text
error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
error • The named parameter 'battleEngineMethod' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:72:7 • undefined_named_parameter
error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3 • undefined_class
error • Undefined class 'PokemonMoveFlags' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:284:3 • undefined_class
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
warning • The library 'package:map_editor/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart' doesn't export a member with the shown name 'showPokedexImportFlowSheet' • lib/src/ui/canvas/pokedex_workspace_views.dart:17:9 • undefined_shown_name
```

Analyse : l'échec global vient d'une dette préexistante hors fichiers NS-HOME-02,
principalement Pokémon SDK / Pokédex. Les fichiers créés par ce lot ne sont pas
cités dans les erreurs.

### Analyze ciblé

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/features/narrative/application/overview/narrative_overview_read_model.dart test/features/narrative/application/overview/narrative_overview_read_model_test.dart
```

Sortie :

```text
Analyzing 2 items...

No issues found! (ran in 1.4s)
```

## 10. Résultats des tests

Test ciblé NS-HOME-02 :

```text
8 tests passés.
```

Analyse ciblée des fichiers NS-HOME-02 :

```text
No issues found.
```

Analyse globale `map_editor` :

```text
Échec dû à dette préexistante hors lot ; aucune erreur introduite par les fichiers NS-HOME-02.
```

## 11. Limites

- `dialogueLines` reste `unavailable` car le builder ne lit pas les fichiers
  Yarn dans ce lot.
- `Quêtes` reste `outOfScope` faute de modèle Quest.
- `Facts` reste `needsModel` faute de registre Fact/lore.
- `Activité récente` reste `outOfScope` faute de journal authoring réel.
- `Notifications` reste `outOfScope` faute de source dashboard réelle.
- `World rules` V0 compte les `StepStudioWorldChange`; les règles de visibilité
  venant des maps ne sont pas calculées car le builder ne reçoit pas de maps
  chargées.
- Aucun export public n'a été ajouté ; le test importe le fichier `src`
  directement, comme d'autres tests internes `map_editor`.

## 12. Prochain lot recommandé

```text
NS-HOME-03 — Narrative Overview Shell Placement V0
```

Objectif recommandé : brancher une entrée `Aperçu` minimale dans le Narrative
Studio / shell existant, sans créer toutes les cards finales et sans nouveaux
compteurs. La future UI devra consommer exclusivement
`NarrativeOverviewReadModel`.

## 13. Evidence Pack

### Branche

`git branch --show-current`

```text
main
```

### Git initial

`git status --short --untracked-files=all` initial

```text
Sortie : <vide>
```

### Git final

`git status --short --untracked-files=all` final

```text
?? packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
?? packages/map_editor/test/features/narrative/application/overview/narrative_overview_read_model_test.dart
?? reports/narrativeStudio/ui/ns_home_02_narrative_overview_read_model.md
```

`git diff --stat` final

```text
Sortie : <vide>
```

`git diff --name-only` final

```text
Sortie : <vide>
```

`git diff --check` final

```text
Sortie : <vide>
```

Note : les fichiers NS-HOME-02 sont non trackés ; `git diff` ne liste donc pas
leur contenu tant qu'ils ne sont pas ajoutés à l'index. Le `git status` final
liste les trois fichiers introduits par ce lot.

### Fichiers créés

```text
packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
packages/map_editor/test/features/narrative/application/overview/narrative_overview_read_model_test.dart
reports/narrativeStudio/ui/ns_home_02_narrative_overview_read_model.md
```

### Fichiers modifiés

```text
Aucun fichier existant modifié.
```

### Sections structurantes du fichier read model

```text
Enums :
- NarrativeOverviewAvailability
- NarrativeOverviewSourceStatus
- NarrativeEditorialValidationState
- NarrativeProjectHealthKind
- NarrativeChapterEditorialStatus

Builder :
- buildNarrativeOverviewReadModel(...)

Helpers principaux :
- _buildMainStory(...)
- _buildChaptersMetric(...)
- _countNarrativeConditions(...)
- _countWorldRules(...)
- _buildEditorialStatus(...)
- _buildModules(...)
- _buildProjectHealth(...)
- _buildStructureInspector(...)
```

### Sections structurantes du fichier test

```text
Groupe :
- buildNarrativeOverviewReadModel

Fixtures :
- _project(...)
- _globalStoryWithDocuments(...)
- _cutsceneScenario(...)

Tests :
- minimal project without unavailable data invented
- explicit global story with authoring metrics
- fallback chapters
- multiple global stories ambiguity
- warning diagnostics
- error diagnostics
- zero real count vs unavailable
- no image/Selbrume hardcode
```

### Confirmations

```text
Aucun widget Flutter créé.
Aucun écran Flutter créé.
Aucun provider Riverpod créé.
Aucun repository disque créé.
Aucun modèle map_core créé.
Aucun fichier generated modifié.
Aucun fichier packages/map_runtime modifié.
Aucun fichier packages/map_gameplay modifié.
Aucun fichier packages/map_battle modifié.
Aucun GameState lu.
Aucun SaveData lu.
Aucun build_runner lancé.
Aucun commit effectué.
Aucun fichier stage.
```

## 14. Auto-review critique

Ai-je créé les read models côté `map_editor` ?

```text
Oui.
```

Ai-je évité les widgets Flutter ?

```text
Oui.
```

Ai-je évité runtime/gameplay/battle ?

```text
Oui.
```

Ai-je évité de modifier `map_core` ?

```text
Oui.
```

Ai-je distingué 0 réel, indisponible, hors scope, futur modèle et non évalué ?

```text
Oui, via NarrativeOverviewAvailability et les tests ciblés.
```

Ai-je refusé quêtes/facts/activité/notifications comme fausses données ?

```text
Oui.
```

Ai-je prouvé que `À jour` n'est produit qu'après validation ?

```text
Oui. Sans diagnostic fourni, le statut reste Non évalué ; avec validation vide,
il devient À jour.
```

Ai-je évité les hardcodes de l'image et de Selbrume ?

```text
Oui. Les tests utilisent uniquement des fixtures génériques.
```

Ai-je lancé les tests ciblés ?

```text
Oui, le test ciblé passe.
```

Ai-je lancé analyze ?

```text
Oui. Analyze global échoue sur dette préexistante hors lot ; analyze ciblé
NS-HOME-02 passe.
```

## 15. Regard critique sur le prompt

Le prompt est bien placé : avant de créer une UI dense et séduisante, il impose
une couche de vérité qui force chaque futur widget à distinguer donnée réelle,
vide, indisponible, non évaluée, hors scope ou nécessitant un modèle futur.

Le point le plus délicat reste `Scènes`, parce que le repo ne possède pas encore
un modèle `Scene` first-class. Le choix V0 retenu est volontairement prudent :
ne compter que les cutscenes liées aux steps et résolues vers une cutscene
authorée. C'est moins spectaculaire que la maquette, mais c'est honnête.
