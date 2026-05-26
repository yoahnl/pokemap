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
## 16. Evidence Pack bis — contenus des fichiers créés

### 16.1 Contenu complet du read model

Chemin : `packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../../dialogue/application/dialogue_editor_validation.dart';
import '../cutscene_studio/cutscene_studio_models.dart';
import '../global_story_studio_authoring.dart';
import '../narrative_workspace_projection.dart';
import '../step_studio_authoring.dart';

enum NarrativeOverviewAvailability {
  available,
  empty,
  unavailable,
  notEvaluated,
  outOfScope,
  needsModel,
}

enum NarrativeOverviewSourceStatus {
  explicit,
  fallback,
  missing,
  ambiguous,
  notApplicable,
}

enum NarrativeEditorialValidationState {
  notEvaluated,
  upToDate,
  toReview,
  blocking,
}

enum NarrativeProjectHealthKind {
  notEvaluated,
  healthy,
  reviewNeeded,
  blocked,
}

enum NarrativeChapterEditorialStatus {
  defined,
  inProgress,
  draft,
  notEvaluated,
}

final class NarrativeOverviewModuleIds {
  const NarrativeOverviewModuleIds._();

  static const quests = 'quests';
  static const cutscenes = 'cutscenes';
  static const dialogues = 'dialogues';
  static const conditions = 'conditions';
  static const worldRules = 'world_rules';
  static const facts = 'facts';
}

class NarrativeOverviewReadModel {
  const NarrativeOverviewReadModel({
    required this.projectName,
    required this.metrics,
    required this.mainStory,
    required this.modules,
    required this.structureInspector,
    required this.editorialStatus,
    required this.projectHealth,
    required this.recentActivity,
    required this.notifications,
    required this.footer,
  });

  final String projectName;
  final NarrativeOverviewMetrics metrics;
  final MainStoryOverviewSummary mainStory;
  final List<NarrativeModuleSummary> modules;
  final NarrativeStructureInspectorSummary structureInspector;
  final EditorialStatusSummary editorialStatus;
  final NarrativeProjectHealthSummary projectHealth;
  final NarrativeOverviewFeatureSummary recentActivity;
  final NarrativeOverviewFeatureSummary notifications;
  final NarrativeOverviewFooterSummary footer;
}

class NarrativeOverviewMetrics {
  const NarrativeOverviewMetrics({
    required this.chapters,
    required this.scenes,
    required this.cutscenes,
    required this.quests,
    required this.dialogues,
    required this.dialogueLines,
    required this.openIssues,
    required this.conditions,
    required this.worldRules,
    required this.facts,
  });

  final NarrativeMetricSummary chapters;
  final NarrativeMetricSummary scenes;
  final NarrativeMetricSummary cutscenes;
  final NarrativeMetricSummary quests;
  final NarrativeMetricSummary dialogues;
  final NarrativeMetricSummary dialogueLines;
  final NarrativeMetricSummary openIssues;
  final NarrativeMetricSummary conditions;
  final NarrativeMetricSummary worldRules;
  final NarrativeMetricSummary facts;

  List<NarrativeMetricSummary> get all => <NarrativeMetricSummary>[
        chapters,
        scenes,
        cutscenes,
        quests,
        dialogues,
        dialogueLines,
        openIssues,
        conditions,
        worldRules,
        facts,
      ];
}

class NarrativeMetricSummary {
  const NarrativeMetricSummary({
    required this.id,
    required this.label,
    required this.count,
    required this.availability,
    required this.sourceStatus,
    required this.emptyStateMessage,
    required this.unavailableMessage,
  });

  final String id;
  final String label;
  final int? count;
  final NarrativeOverviewAvailability availability;
  final NarrativeOverviewSourceStatus sourceStatus;
  final String emptyStateMessage;
  final String unavailableMessage;

  bool get hasRealCount =>
      availability == NarrativeOverviewAvailability.available ||
      availability == NarrativeOverviewAvailability.empty;

  NarrativeMetricSummary copyWithAvailability(
    NarrativeOverviewAvailability availability,
  ) {
    return NarrativeMetricSummary(
      id: id,
      label: label,
      count: count,
      availability: availability,
      sourceStatus: sourceStatus,
      emptyStateMessage: emptyStateMessage,
      unavailableMessage: unavailableMessage,
    );
  }
}

class MainStoryOverviewSummary {
  const MainStoryOverviewSummary({
    required this.title,
    required this.description,
    required this.chapters,
    required this.linkedScenes,
    required this.linkedDialogues,
    required this.openIssues,
    required this.canEdit,
    required this.availability,
    required this.sourceStatus,
    required this.message,
  });

  final String? title;
  final String? description;
  final List<NarrativeChapterOverviewSummary> chapters;
  final NarrativeMetricSummary linkedScenes;
  final NarrativeMetricSummary linkedDialogues;
  final NarrativeMetricSummary openIssues;
  final bool canEdit;
  final NarrativeOverviewAvailability availability;
  final NarrativeOverviewSourceStatus sourceStatus;
  final String message;

  NarrativeOverviewSourceStatus get sourceQuality => sourceStatus;
}

class NarrativeChapterOverviewSummary {
  const NarrativeChapterOverviewSummary({
    required this.id,
    required this.label,
    required this.description,
    required this.order,
    required this.stepCount,
    required this.status,
    required this.sourceStatus,
  });

  final String id;
  final String label;
  final String description;
  final int order;
  final int stepCount;
  final NarrativeChapterEditorialStatus status;
  final NarrativeOverviewSourceStatus sourceStatus;
}

class NarrativeModuleSummary {
  const NarrativeModuleSummary({
    required this.id,
    required this.label,
    required this.description,
    required this.count,
    required this.availability,
    required this.emptyStateMessage,
    required this.destination,
    this.secondaryStats = const <NarrativeMetricSummary>[],
  });

  final String id;
  final String label;
  final String description;
  final int? count;
  final NarrativeOverviewAvailability availability;
  final String emptyStateMessage;
  final String? destination;
  final List<NarrativeMetricSummary> secondaryStats;
}

class NarrativeStructureInspectorSummary {
  const NarrativeStructureInspectorSummary({
    required this.projectName,
    required this.globalStatusLabel,
    required this.description,
    required this.tags,
    required this.counters,
    required this.chapters,
    required this.editorialStatus,
    required this.descriptionAvailability,
    required this.tagsAvailability,
  });

  final String projectName;
  final String globalStatusLabel;
  final String? description;
  final List<String> tags;
  final List<NarrativeMetricSummary> counters;
  final List<NarrativeChapterOverviewSummary> chapters;
  final EditorialStatusSummary editorialStatus;
  final NarrativeOverviewAvailability descriptionAvailability;
  final NarrativeOverviewAvailability tagsAvailability;
}

class EditorialStatusSummary {
  const EditorialStatusSummary({
    required this.validationState,
    required this.upToDate,
    required this.toReview,
    required this.blocking,
    required this.notEvaluated,
    required this.diagnosticSourceSummary,
  });

  final NarrativeEditorialValidationState validationState;
  final bool upToDate;
  final int toReview;
  final int blocking;
  final bool notEvaluated;
  final String diagnosticSourceSummary;
}

class NarrativeProjectHealthSummary {
  const NarrativeProjectHealthSummary({
    required this.healthKind,
    required this.validationState,
    required this.blockingIssueCount,
    required this.reviewIssueCount,
    required this.unavailableCriticalMetricCount,
  });

  final NarrativeProjectHealthKind healthKind;
  final NarrativeEditorialValidationState validationState;
  final int blockingIssueCount;
  final int reviewIssueCount;
  final int unavailableCriticalMetricCount;
}

class NarrativeOverviewFeatureSummary {
  const NarrativeOverviewFeatureSummary({
    required this.id,
    required this.label,
    required this.availability,
    required this.message,
  });

  final String id;
  final String label;
  final NarrativeOverviewAvailability availability;
  final String message;
}

class NarrativeOverviewFooterSummary {
  const NarrativeOverviewFooterSummary({
    required this.project,
    required this.locale,
    required this.version,
  });

  final NarrativeMetricSummary project;
  final NarrativeMetricSummary locale;
  final NarrativeMetricSummary version;
}

NarrativeOverviewReadModel buildNarrativeOverviewReadModel({
  required ProjectManifest project,
  NarrativeValidationReport? narrativeValidationReport,
  List<NarrativeAuthoringDiagnosticView> authoringDiagnostics =
      const <NarrativeAuthoringDiagnosticView>[],
  List<DialogueValidationIssue> dialogueIssues =
      const <DialogueValidationIssue>[],
}) {
  final projection = buildNarrativeWorkspaceProjection(project);
  final globalStories = project.scenarios
      .where((scenario) => scenario.scope == ScenarioScope.globalStory)
      .toList(growable: false);
  final localEventFlows = project.scenarios
      .where((scenario) => scenario.scope == ScenarioScope.localEventFlow)
      .toList(growable: false);
  final cutsceneScenarioIds = localEventFlows
      .where(_hasCutsceneStudioMetadata)
      .map((scenario) => scenario.id)
      .toSet();
  final allStepContexts = _buildStepContexts(globalStories);
  final allSteps = allStepContexts
      .expand((context) => context.stepDocument.steps)
      .toList(growable: false);
  final validation = _buildEditorialStatus(
    narrativeValidationReport: narrativeValidationReport,
    authoringDiagnostics: authoringDiagnostics,
    dialogueIssues: dialogueIssues,
  );

  final mainStory = _buildMainStory(
    globalStories: globalStories,
    project: project,
    cutsceneScenarioIds: cutsceneScenarioIds,
    validationState: validation,
    authoringDiagnostics: authoringDiagnostics,
    narrativeValidationReport: narrativeValidationReport,
  );

  final chapters = _buildChaptersMetric(mainStory);
  final scenes = _metricWithCount(
    id: 'scenes',
    label: 'Scènes',
    count: _countLinkedResolvedScenes(projection.steps, cutsceneScenarioIds),
    emptyStateMessage: 'Aucune scène narrative liée.',
    unavailableMessage:
        'Les scènes nécessitent des liens Step Studio vers des cutscenes.',
  );
  final cutscenes = _metricWithCount(
    id: 'cutscenes',
    label: 'Cinématiques',
    count: cutsceneScenarioIds.length,
    emptyStateMessage: 'Aucune cinématique authorée.',
    unavailableMessage: 'Cinématiques indisponibles.',
  );
  final dialogues = _metricWithCount(
    id: 'dialogues',
    label: 'Dialogues',
    count: project.dialogues.length,
    emptyStateMessage: 'Aucun dialogue défini.',
    unavailableMessage: 'Dialogues indisponibles.',
  );
  final conditions = _metricWithCount(
    id: 'conditions',
    label: 'Conditions narratives',
    count: _countNarrativeConditions(project, allSteps),
    emptyStateMessage: 'Aucune condition narrative définie.',
    unavailableMessage: 'Conditions narratives indisponibles.',
  );
  final worldRules = _metricWithCount(
    id: 'world_rules',
    label: 'Règles du monde',
    count: _countWorldRules(allSteps),
    emptyStateMessage: 'Aucune règle du monde définie.',
    unavailableMessage: 'Règles du monde indisponibles.',
  );
  final openIssues = validation.notEvaluated
      ? const NarrativeMetricSummary(
          id: 'open_issues',
          label: 'Problèmes ouverts',
          count: null,
          availability: NarrativeOverviewAvailability.notEvaluated,
          sourceStatus: NarrativeOverviewSourceStatus.missing,
          emptyStateMessage: 'Aucun problème ouvert détecté.',
          unavailableMessage:
              'Non évalué : lancez la validation pour connaître les problèmes.',
        )
      : _metricWithCount(
          id: 'open_issues',
          label: 'Problèmes ouverts',
          count: validation.blocking + validation.toReview,
          emptyStateMessage: 'Aucun problème ouvert détecté.',
          unavailableMessage: 'Problèmes ouverts indisponibles.',
        ).copyWithAvailability(NarrativeOverviewAvailability.available);

  final metrics = NarrativeOverviewMetrics(
    chapters: chapters,
    scenes: scenes,
    cutscenes: cutscenes,
    quests: const NarrativeMetricSummary(
      id: 'quests',
      label: 'Quêtes',
      count: null,
      availability: NarrativeOverviewAvailability.outOfScope,
      sourceStatus: NarrativeOverviewSourceStatus.notApplicable,
      emptyStateMessage: 'Les quêtes ne sont pas encore modélisées.',
      unavailableMessage: 'Compteur de quêtes hors scope V0.',
    ),
    dialogues: dialogues,
    dialogueLines: const NarrativeMetricSummary(
      id: 'dialogue_lines',
      label: 'Lignes de dialogue',
      count: null,
      availability: NarrativeOverviewAvailability.unavailable,
      sourceStatus: NarrativeOverviewSourceStatus.missing,
      emptyStateMessage: 'Aucune ligne de dialogue calculée.',
      unavailableMessage:
          'Le nombre de lignes nécessite la lecture des fichiers Yarn.',
    ),
    openIssues: openIssues,
    conditions: conditions,
    worldRules: worldRules,
    facts: const NarrativeMetricSummary(
      id: 'facts',
      label: 'Facts',
      count: null,
      availability: NarrativeOverviewAvailability.needsModel,
      sourceStatus: NarrativeOverviewSourceStatus.notApplicable,
      emptyStateMessage: 'Les Facts ne sont pas encore modélisés.',
      unavailableMessage:
          'Compteur Facts indisponible sans registre de connaissances.',
    ),
  );

  final modules = _buildModules(metrics);
  final projectHealth = _buildProjectHealth(validation, metrics);
  final structureInspector = _buildStructureInspector(
    project: project,
    mainStory: mainStory,
    metrics: metrics,
    editorialStatus: validation,
  );

  return NarrativeOverviewReadModel(
    projectName: project.name,
    metrics: metrics,
    mainStory: mainStory,
    modules: modules,
    structureInspector: structureInspector,
    editorialStatus: validation,
    projectHealth: projectHealth,
    recentActivity: const NarrativeOverviewFeatureSummary(
      id: 'recent_activity',
      label: 'Activité récente',
      availability: NarrativeOverviewAvailability.outOfScope,
      message: 'Aucun journal d’activité réel n’existe en V0.',
    ),
    notifications: const NarrativeOverviewFeatureSummary(
      id: 'notifications',
      label: 'Notifications',
      availability: NarrativeOverviewAvailability.outOfScope,
      message: 'Aucune source de notifications dashboard n’existe en V0.',
    ),
    footer: _buildFooter(project),
  );
}

MainStoryOverviewSummary _buildMainStory({
  required List<ScenarioAsset> globalStories,
  required ProjectManifest project,
  required Set<String> cutsceneScenarioIds,
  required EditorialStatusSummary validationState,
  required List<NarrativeAuthoringDiagnosticView> authoringDiagnostics,
  required NarrativeValidationReport? narrativeValidationReport,
}) {
  if (globalStories.isEmpty) {
    return const MainStoryOverviewSummary(
      title: null,
      description: null,
      chapters: <NarrativeChapterOverviewSummary>[],
      linkedScenes: NarrativeMetricSummary(
        id: 'main_story_linked_scenes',
        label: 'Scènes liées',
        count: 0,
        availability: NarrativeOverviewAvailability.empty,
        sourceStatus: NarrativeOverviewSourceStatus.missing,
        emptyStateMessage: 'Aucune scène liée.',
        unavailableMessage: 'Aucune histoire principale.',
      ),
      linkedDialogues: NarrativeMetricSummary(
        id: 'main_story_linked_dialogues',
        label: 'Dialogues liés',
        count: 0,
        availability: NarrativeOverviewAvailability.empty,
        sourceStatus: NarrativeOverviewSourceStatus.missing,
        emptyStateMessage: 'Aucun dialogue lié.',
        unavailableMessage: 'Aucune histoire principale.',
      ),
      openIssues: NarrativeMetricSummary(
        id: 'main_story_open_issues',
        label: 'Problèmes ouverts',
        count: null,
        availability: NarrativeOverviewAvailability.notEvaluated,
        sourceStatus: NarrativeOverviewSourceStatus.missing,
        emptyStateMessage: 'Aucun problème ouvert.',
        unavailableMessage: 'Non évalué.',
      ),
      canEdit: false,
      availability: NarrativeOverviewAvailability.empty,
      sourceStatus: NarrativeOverviewSourceStatus.missing,
      message: 'Aucune histoire principale définie.',
    );
  }

  if (globalStories.length > 1) {
    return const MainStoryOverviewSummary(
      title: null,
      description: null,
      chapters: <NarrativeChapterOverviewSummary>[],
      linkedScenes: NarrativeMetricSummary(
        id: 'main_story_linked_scenes',
        label: 'Scènes liées',
        count: null,
        availability: NarrativeOverviewAvailability.unavailable,
        sourceStatus: NarrativeOverviewSourceStatus.ambiguous,
        emptyStateMessage: 'Aucune scène liée.',
        unavailableMessage:
            'Plusieurs histoires globales existent ; sélection explicite requise.',
      ),
      linkedDialogues: NarrativeMetricSummary(
        id: 'main_story_linked_dialogues',
        label: 'Dialogues liés',
        count: null,
        availability: NarrativeOverviewAvailability.unavailable,
        sourceStatus: NarrativeOverviewSourceStatus.ambiguous,
        emptyStateMessage: 'Aucun dialogue lié.',
        unavailableMessage:
            'Plusieurs histoires globales existent ; sélection explicite requise.',
      ),
      openIssues: NarrativeMetricSummary(
        id: 'main_story_open_issues',
        label: 'Problèmes ouverts',
        count: null,
        availability: NarrativeOverviewAvailability.unavailable,
        sourceStatus: NarrativeOverviewSourceStatus.ambiguous,
        emptyStateMessage: 'Aucun problème ouvert.',
        unavailableMessage:
            'Plusieurs histoires globales existent ; sélection explicite requise.',
      ),
      canEdit: false,
      availability: NarrativeOverviewAvailability.unavailable,
      sourceStatus: NarrativeOverviewSourceStatus.ambiguous,
      message: 'Plusieurs histoires principales possibles.',
    );
  }

  final story = globalStories.single;
  final stepParse = parseStepStudioDocumentFromGlobalScenario(story);
  final globalParse = parseGlobalStoryStudioDocumentFromGlobalScenario(
    story,
    stepDocument: stepParse.document,
  );
  final chapterSource = globalParse.usedLegacyFallback
      ? NarrativeOverviewSourceStatus.fallback
      : NarrativeOverviewSourceStatus.explicit;
  final chapters = globalParse.document.chapters
      .map(
        (chapter) => NarrativeChapterOverviewSummary(
          id: chapter.id,
          label: chapter.name.trim().isEmpty ? chapter.id : chapter.name,
          description: chapter.description,
          order: chapter.order,
          stepCount: chapter.stepIds.length,
          status: _chapterStatusFor(chapter, validationState),
          sourceStatus: chapterSource,
        ),
      )
      .toList(growable: false)
    ..sort((a, b) => a.order.compareTo(b.order));

  final linkedCutsceneIds = stepParse.document.steps
      .expand((step) => step.cutscenes.map((link) => link.cutsceneId))
      .where((id) => id.trim().isNotEmpty)
      .toSet();
  final resolvedSceneIds =
      linkedCutsceneIds.where(cutsceneScenarioIds.contains).toSet();
  final linkedDialogues = _collectDialogueIdsFromScenarios(
    project: project,
    scenarioIds: resolvedSceneIds,
  );
  final scopedIssues = validationState.notEvaluated
      ? null
      : _countMainStoryIssues(
          story.id,
          narrativeValidationReport: narrativeValidationReport,
          authoringDiagnostics: authoringDiagnostics,
        );

  return MainStoryOverviewSummary(
    title: story.name.trim().isEmpty ? story.id : story.name,
    description:
        story.description.trim().isEmpty ? null : story.description.trim(),
    chapters: chapters,
    linkedScenes: _metricWithCount(
      id: 'main_story_linked_scenes',
      label: 'Scènes liées',
      count: resolvedSceneIds.length,
      emptyStateMessage: 'Aucune scène liée à cette histoire.',
      unavailableMessage: 'Scènes liées indisponibles.',
      sourceStatus: resolvedSceneIds.isEmpty
          ? NarrativeOverviewSourceStatus.missing
          : NarrativeOverviewSourceStatus.explicit,
    ),
    linkedDialogues: _metricWithCount(
      id: 'main_story_linked_dialogues',
      label: 'Dialogues liés',
      count: linkedDialogues.length,
      emptyStateMessage: 'Aucun dialogue lié à cette histoire.',
      unavailableMessage: 'Dialogues liés indisponibles.',
      sourceStatus: linkedDialogues.isEmpty
          ? NarrativeOverviewSourceStatus.missing
          : NarrativeOverviewSourceStatus.explicit,
    ),
    openIssues: scopedIssues == null
        ? const NarrativeMetricSummary(
            id: 'main_story_open_issues',
            label: 'Problèmes ouverts',
            count: null,
            availability: NarrativeOverviewAvailability.notEvaluated,
            sourceStatus: NarrativeOverviewSourceStatus.missing,
            emptyStateMessage: 'Aucun problème ouvert.',
            unavailableMessage: 'Non évalué : lancez la validation narrative.',
          )
        : _metricWithCount(
            id: 'main_story_open_issues',
            label: 'Problèmes ouverts',
            count: scopedIssues,
            emptyStateMessage: 'Aucun problème ouvert pour cette histoire.',
            unavailableMessage: 'Problèmes ouverts indisponibles.',
          ),
    canEdit: true,
    availability: NarrativeOverviewAvailability.available,
    sourceStatus: NarrativeOverviewSourceStatus.explicit,
    message: '',
  );
}

List<_StepContext> _buildStepContexts(List<ScenarioAsset> globalStories) {
  return globalStories
      .map(
        (scenario) => _StepContext(
          scenario: scenario,
          stepDocument: parseStepStudioDocumentFromGlobalScenario(
            scenario,
          ).document,
        ),
      )
      .toList(growable: false);
}

NarrativeMetricSummary _buildChaptersMetric(
  MainStoryOverviewSummary mainStory,
) {
  if (mainStory.availability == NarrativeOverviewAvailability.unavailable) {
    return const NarrativeMetricSummary(
      id: 'chapters',
      label: 'Chapitres',
      count: null,
      availability: NarrativeOverviewAvailability.unavailable,
      sourceStatus: NarrativeOverviewSourceStatus.ambiguous,
      emptyStateMessage: 'Aucun chapitre défini.',
      unavailableMessage:
          'Plusieurs histoires globales existent ; sélection explicite requise.',
    );
  }
  final count = mainStory.chapters.length;
  return NarrativeMetricSummary(
    id: 'chapters',
    label: 'Chapitres',
    count: count,
    availability: count == 0
        ? NarrativeOverviewAvailability.empty
        : NarrativeOverviewAvailability.available,
    sourceStatus: mainStory.chapters.isEmpty
        ? NarrativeOverviewSourceStatus.missing
        : mainStory.chapters.first.sourceStatus,
    emptyStateMessage: 'Aucun chapitre défini.',
    unavailableMessage: 'Chapitres indisponibles.',
  );
}

NarrativeMetricSummary _metricWithCount({
  required String id,
  required String label,
  required int count,
  required String emptyStateMessage,
  required String unavailableMessage,
  NarrativeOverviewSourceStatus sourceStatus =
      NarrativeOverviewSourceStatus.explicit,
}) {
  return NarrativeMetricSummary(
    id: id,
    label: label,
    count: count,
    availability: count == 0
        ? NarrativeOverviewAvailability.empty
        : NarrativeOverviewAvailability.available,
    sourceStatus: sourceStatus,
    emptyStateMessage: emptyStateMessage,
    unavailableMessage: unavailableMessage,
  );
}

bool _hasCutsceneStudioMetadata(ScenarioAsset scenario) {
  if (scenario.scope != ScenarioScope.localEventFlow) {
    return false;
  }
  final schema = scenario.metadata[kCutsceneStudioSchemaMetadataKey]?.trim();
  final flow = scenario.metadata[kCutsceneStudioFlowMetadataKey]?.trim();
  return (schema != null && schema.isNotEmpty) ||
      (flow != null && flow.isNotEmpty);
}

int _countLinkedResolvedScenes(
  List<NarrativeStepSummary> steps,
  Set<String> cutsceneScenarioIds,
) {
  return steps
      .expand((step) => step.linkedCutsceneIds)
      .where(cutsceneScenarioIds.contains)
      .toSet()
      .length;
}

int _countNarrativeConditions(
  ProjectManifest project,
  List<StepStudioStep> steps,
) {
  var count = 0;
  for (final step in steps) {
    if (_activationHasDependency(step.activation)) {
      count++;
    }
    if (_completionHasDependency(step.completion)) {
      count++;
    }
  }
  for (final scenario in project.scenarios) {
    if (scenario.activationCondition != null) {
      count++;
    }
    for (final node in scenario.nodes) {
      if (node.payload.condition != null) {
        count++;
      }
    }
  }
  return count;
}

bool _activationHasDependency(StepStudioActivationRule activation) {
  return switch (activation.mode) {
    StepStudioActivationMode.atGameStart ||
    StepStudioActivationMode.afterPreviousStep =>
      false,
    StepStudioActivationMode.afterStep =>
      (activation.stepId ?? '').trim().isNotEmpty,
    StepStudioActivationMode.afterOutcome =>
      (activation.outcomeId ?? '').trim().isNotEmpty,
    StepStudioActivationMode.afterCutscene =>
      (activation.cutsceneId ?? '').trim().isNotEmpty,
    StepStudioActivationMode.whenFlagTrue =>
      (activation.flagName ?? '').trim().isNotEmpty,
  };
}

bool _completionHasDependency(StepStudioCompletionRule completion) {
  return switch (completion.mode) {
    StepStudioCompletionMode.manual => false,
    StepStudioCompletionMode.whenCutsceneEnds =>
      (completion.cutsceneId ?? '').trim().isNotEmpty,
    StepStudioCompletionMode.whenOutcomeEmitted =>
      (completion.outcomeId ?? '').trim().isNotEmpty,
    StepStudioCompletionMode.whenInteractionDone =>
      (completion.interactionId ?? '').trim().isNotEmpty,
    StepStudioCompletionMode.whenFlagTrue =>
      (completion.flagName ?? '').trim().isNotEmpty,
  };
}

int _countWorldRules(List<StepStudioStep> steps) {
  return steps.fold<int>(
    0,
    (sum, step) => sum + step.worldChanges.length,
  );
}

Set<String> _collectDialogueIdsFromScenarios({
  required ProjectManifest project,
  required Set<String> scenarioIds,
}) {
  final knownDialogueIds = project.dialogues.map((entry) => entry.id).toSet();
  final out = <String>{};
  for (final scenario in project.scenarios) {
    if (!scenarioIds.contains(scenario.id)) {
      continue;
    }
    for (final node in scenario.nodes) {
      final bindingDialogueId = (node.binding.dialogueId ?? '').trim();
      if (knownDialogueIds.contains(bindingDialogueId)) {
        out.add(bindingDialogueId);
      }
      final paramDialogueId = (node.payload.params['dialogueId'] ?? '').trim();
      if (knownDialogueIds.contains(paramDialogueId)) {
        out.add(paramDialogueId);
      }
    }
  }
  return out;
}

EditorialStatusSummary _buildEditorialStatus({
  required NarrativeValidationReport? narrativeValidationReport,
  required List<NarrativeAuthoringDiagnosticView> authoringDiagnostics,
  required List<DialogueValidationIssue> dialogueIssues,
}) {
  final validationRan = narrativeValidationReport != null ||
      authoringDiagnostics.isNotEmpty ||
      dialogueIssues.isNotEmpty;
  if (!validationRan) {
    return const EditorialStatusSummary(
      validationState: NarrativeEditorialValidationState.notEvaluated,
      upToDate: false,
      toReview: 0,
      blocking: 0,
      notEvaluated: true,
      diagnosticSourceSummary: 'Aucune validation fournie.',
    );
  }

  var blocking = 0;
  var review = 0;
  if (authoringDiagnostics.isNotEmpty) {
    for (final diagnostic in authoringDiagnostics) {
      switch (diagnostic.severity) {
        case NarrativeValidationSeverity.error:
          blocking++;
        case NarrativeValidationSeverity.warning:
          review++;
      }
    }
  } else {
    for (final diagnostic in narrativeValidationReport?.diagnostics ??
        const <NarrativeValidationDiagnostic>[]) {
      switch (diagnostic.severity) {
        case NarrativeValidationSeverity.error:
          blocking++;
        case NarrativeValidationSeverity.warning:
          review++;
      }
    }
  }

  for (final issue in dialogueIssues) {
    switch (issue.severity) {
      case DialogueValidationSeverity.error:
        blocking++;
      case DialogueValidationSeverity.warning:
        review++;
      case DialogueValidationSeverity.info:
        break;
    }
  }

  final state = blocking > 0
      ? NarrativeEditorialValidationState.blocking
      : review > 0
          ? NarrativeEditorialValidationState.toReview
          : NarrativeEditorialValidationState.upToDate;

  return EditorialStatusSummary(
    validationState: state,
    upToDate: state == NarrativeEditorialValidationState.upToDate,
    toReview: review,
    blocking: blocking,
    notEvaluated: false,
    diagnosticSourceSummary: _diagnosticSourceSummary(
      narrativeValidationReport: narrativeValidationReport,
      authoringDiagnostics: authoringDiagnostics,
      dialogueIssues: dialogueIssues,
    ),
  );
}

String _diagnosticSourceSummary({
  required NarrativeValidationReport? narrativeValidationReport,
  required List<NarrativeAuthoringDiagnosticView> authoringDiagnostics,
  required List<DialogueValidationIssue> dialogueIssues,
}) {
  final parts = <String>[];
  if (authoringDiagnostics.isNotEmpty) {
    parts.add('${authoringDiagnostics.length} diagnostic(s) auteur');
  } else if (narrativeValidationReport != null) {
    parts.add('${narrativeValidationReport.count} diagnostic(s) narratif(s)');
  }
  if (dialogueIssues.isNotEmpty) {
    parts.add('${dialogueIssues.length} diagnostic(s) dialogue');
  }
  return parts.isEmpty
      ? 'Validation exécutée sans diagnostic.'
      : parts.join(', ');
}

int _countMainStoryIssues(
  String scenarioId, {
  required NarrativeValidationReport? narrativeValidationReport,
  required List<NarrativeAuthoringDiagnosticView> authoringDiagnostics,
}) {
  if (authoringDiagnostics.isNotEmpty) {
    return authoringDiagnostics
        .where((diagnostic) => diagnostic.scenarioId == scenarioId)
        .length;
  }
  return narrativeValidationReport?.diagnostics
          .where((diagnostic) => diagnostic.scenarioId == scenarioId)
          .length ??
      0;
}

NarrativeChapterEditorialStatus _chapterStatusFor(
  GlobalStoryChapter chapter,
  EditorialStatusSummary validationState,
) {
  if (validationState.notEvaluated) {
    return NarrativeChapterEditorialStatus.notEvaluated;
  }
  if (chapter.stepIds.isEmpty) {
    return NarrativeChapterEditorialStatus.draft;
  }
  if (validationState.blocking > 0 || validationState.toReview > 0) {
    return NarrativeChapterEditorialStatus.inProgress;
  }
  return NarrativeChapterEditorialStatus.defined;
}

List<NarrativeModuleSummary> _buildModules(NarrativeOverviewMetrics metrics) {
  return <NarrativeModuleSummary>[
    const NarrativeModuleSummary(
      id: NarrativeOverviewModuleIds.quests,
      label: 'Quêtes annexes',
      description:
          'Quêtes secondaires, objectifs facultatifs et contenus exploratoires.',
      count: null,
      availability: NarrativeOverviewAvailability.outOfScope,
      emptyStateMessage: 'Les quêtes ne sont pas encore modélisées en V0.',
      destination: null,
    ),
    NarrativeModuleSummary(
      id: NarrativeOverviewModuleIds.cutscenes,
      label: 'Cinématiques',
      description: 'Séquences cinématiques et moments clés de l’histoire.',
      count: metrics.cutscenes.count,
      availability: metrics.cutscenes.availability,
      emptyStateMessage: metrics.cutscenes.emptyStateMessage,
      destination: 'cutscene_studio',
    ),
    NarrativeModuleSummary(
      id: NarrativeOverviewModuleIds.dialogues,
      label: 'Dialogues',
      description: 'Conversations, choix et répliques des personnages.',
      count: metrics.dialogues.count,
      availability: metrics.dialogues.availability,
      emptyStateMessage: metrics.dialogues.emptyStateMessage,
      destination: 'dialogue_studio',
      secondaryStats: <NarrativeMetricSummary>[metrics.dialogueLines],
    ),
    NarrativeModuleSummary(
      id: NarrativeOverviewModuleIds.conditions,
      label: 'Conditions narratives',
      description: 'Conditions, déclencheurs et dépendances de récit.',
      count: metrics.conditions.count,
      availability: metrics.conditions.availability,
      emptyStateMessage: metrics.conditions.emptyStateMessage,
      destination: 'step_studio',
    ),
    NarrativeModuleSummary(
      id: NarrativeOverviewModuleIds.worldRules,
      label: 'Règles du monde',
      description: 'Règles authorées qui changent la présence narrative.',
      count: metrics.worldRules.count,
      availability: metrics.worldRules.availability,
      emptyStateMessage: metrics.worldRules.emptyStateMessage,
      destination: 'step_studio',
    ),
    const NarrativeModuleSummary(
      id: NarrativeOverviewModuleIds.facts,
      label: 'Facts',
      description: 'Base de connaissances narrative et lore authoré.',
      count: null,
      availability: NarrativeOverviewAvailability.needsModel,
      emptyStateMessage:
          'Les Facts nécessitent un futur registre de connaissances.',
      destination: null,
    ),
  ];
}

NarrativeProjectHealthSummary _buildProjectHealth(
  EditorialStatusSummary editorialStatus,
  NarrativeOverviewMetrics metrics,
) {
  final unavailableCriticalMetricCount = <NarrativeMetricSummary>[
    metrics.chapters,
    metrics.scenes,
    metrics.cutscenes,
    metrics.dialogues,
    metrics.conditions,
    metrics.worldRules,
  ].where((metric) {
    return metric.availability == NarrativeOverviewAvailability.unavailable ||
        metric.availability == NarrativeOverviewAvailability.notEvaluated;
  }).length;

  final healthKind = switch (editorialStatus.validationState) {
    NarrativeEditorialValidationState.notEvaluated =>
      NarrativeProjectHealthKind.notEvaluated,
    NarrativeEditorialValidationState.blocking =>
      NarrativeProjectHealthKind.blocked,
    NarrativeEditorialValidationState.toReview =>
      NarrativeProjectHealthKind.reviewNeeded,
    NarrativeEditorialValidationState.upToDate =>
      unavailableCriticalMetricCount == 0
          ? NarrativeProjectHealthKind.healthy
          : NarrativeProjectHealthKind.reviewNeeded,
  };

  return NarrativeProjectHealthSummary(
    healthKind: healthKind,
    validationState: editorialStatus.validationState,
    blockingIssueCount: editorialStatus.blocking,
    reviewIssueCount: editorialStatus.toReview,
    unavailableCriticalMetricCount: unavailableCriticalMetricCount,
  );
}

NarrativeStructureInspectorSummary _buildStructureInspector({
  required ProjectManifest project,
  required MainStoryOverviewSummary mainStory,
  required NarrativeOverviewMetrics metrics,
  required EditorialStatusSummary editorialStatus,
}) {
  return NarrativeStructureInspectorSummary(
    projectName: project.name,
    globalStatusLabel: _globalStatusLabel(editorialStatus.validationState),
    description: null,
    tags: const <String>[],
    counters: <NarrativeMetricSummary>[
      metrics.chapters,
      metrics.scenes,
      metrics.cutscenes,
      metrics.dialogues,
      metrics.facts,
    ],
    chapters: mainStory.chapters,
    editorialStatus: editorialStatus,
    descriptionAvailability: NarrativeOverviewAvailability.unavailable,
    tagsAvailability: NarrativeOverviewAvailability.needsModel,
  );
}

String _globalStatusLabel(NarrativeEditorialValidationState state) {
  return switch (state) {
    NarrativeEditorialValidationState.notEvaluated => 'Non évalué',
    NarrativeEditorialValidationState.upToDate => 'À jour',
    NarrativeEditorialValidationState.toReview => 'À revoir',
    NarrativeEditorialValidationState.blocking => 'Bloquant',
  };
}

NarrativeOverviewFooterSummary _buildFooter(ProjectManifest project) {
  return NarrativeOverviewFooterSummary(
    project: NarrativeMetricSummary(
      id: 'footer_project',
      label: 'Projet',
      count: null,
      availability: NarrativeOverviewAvailability.available,
      sourceStatus: NarrativeOverviewSourceStatus.explicit,
      emptyStateMessage: '',
      unavailableMessage: project.name,
    ),
    locale: const NarrativeMetricSummary(
      id: 'footer_locale',
      label: 'Locale',
      count: null,
      availability: NarrativeOverviewAvailability.unavailable,
      sourceStatus: NarrativeOverviewSourceStatus.missing,
      emptyStateMessage: 'Locale non définie.',
      unavailableMessage: 'Locale non définie.',
    ),
    version: const NarrativeMetricSummary(
      id: 'footer_version',
      label: 'Version',
      count: null,
      availability: NarrativeOverviewAvailability.unavailable,
      sourceStatus: NarrativeOverviewSourceStatus.missing,
      emptyStateMessage: 'Version non définie.',
      unavailableMessage: 'Version non définie.',
    ),
  );
}

class _StepContext {
  const _StepContext({
    required this.scenario,
    required this.stepDocument,
  });

  final ScenarioAsset scenario;
  final StepStudioDocument stepDocument;
}
```

### 16.2 Contenu complet du test ciblé

Chemin : `packages/map_editor/test/features/narrative/application/overview/narrative_overview_read_model_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_editor_validation.dart';
import 'package:map_editor/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart';
import 'package:map_editor/src/features/narrative/application/global_story_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/application/overview/narrative_overview_read_model.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';

void main() {
  group('buildNarrativeOverviewReadModel', () {
    test('represents a minimal project without inventing unavailable data', () {
      final model = buildNarrativeOverviewReadModel(
        project: _project(name: 'test_project'),
      );

      expect(model.projectName, 'test_project');
      expect(model.mainStory.availability, NarrativeOverviewAvailability.empty);
      expect(
          model.mainStory.sourceStatus, NarrativeOverviewSourceStatus.missing);
      expect(model.mainStory.canEdit, isFalse);

      expect(model.metrics.dialogues.count, 0);
      expect(model.metrics.dialogues.availability,
          NarrativeOverviewAvailability.empty);
      expect(model.metrics.dialogueLines.count, isNull);
      expect(
        model.metrics.dialogueLines.availability,
        NarrativeOverviewAvailability.unavailable,
      );
      expect(model.metrics.quests.count, isNull);
      expect(model.metrics.quests.availability,
          NarrativeOverviewAvailability.outOfScope);
      expect(model.metrics.facts.count, isNull);
      expect(model.metrics.facts.availability,
          NarrativeOverviewAvailability.needsModel);
      expect(model.metrics.openIssues.count, isNull);
      expect(
        model.metrics.openIssues.availability,
        NarrativeOverviewAvailability.notEvaluated,
      );

      expect(model.editorialStatus.validationState,
          NarrativeEditorialValidationState.notEvaluated);
      expect(model.editorialStatus.notEvaluated, isTrue);
      expect(model.projectHealth.healthKind,
          NarrativeProjectHealthKind.notEvaluated);
      expect(model.recentActivity.availability,
          NarrativeOverviewAvailability.outOfScope);
      expect(model.notifications.availability,
          NarrativeOverviewAvailability.outOfScope);
    });

    test('projects one explicit global story with authoring metrics', () {
      final project = _project(
        name: 'test_project',
        scenarios: <ScenarioAsset>[
          _globalStoryWithDocuments(),
          _cutsceneScenario(
            id: 'test_cutscene_1',
            dialogueId: 'test_dialogue_1',
          ),
        ],
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'test_dialogue_1',
            name: 'Test Dialogue',
            relativePath: 'dialogues/test_dialogue_1.yarn',
          ),
        ],
      );

      final model = buildNarrativeOverviewReadModel(project: project);

      expect(model.metrics.chapters.count, 2);
      expect(model.metrics.chapters.availability,
          NarrativeOverviewAvailability.available);
      expect(
        model.metrics.chapters.sourceStatus,
        NarrativeOverviewSourceStatus.explicit,
      );
      expect(model.metrics.scenes.count, 1);
      expect(model.metrics.cutscenes.count, 1);
      expect(model.metrics.dialogues.count, 1);
      expect(model.metrics.conditions.count, 3);
      expect(model.metrics.worldRules.count, 1);

      expect(model.mainStory.availability,
          NarrativeOverviewAvailability.available);
      expect(model.mainStory.title, 'Test Global Story');
      expect(model.mainStory.description, 'A generic test story.');
      expect(model.mainStory.canEdit, isTrue);
      expect(model.mainStory.chapters, hasLength(2));
      expect(model.mainStory.chapters.first.id, 'test_chapter_1');
      expect(model.mainStory.chapters.first.label, 'Chapter One');
      expect(model.mainStory.linkedScenes.count, 1);
      expect(model.mainStory.linkedDialogues.count, 1);
      expect(model.mainStory.openIssues.availability,
          NarrativeOverviewAvailability.notEvaluated);

      final cutsceneModule = model.modules.singleWhere(
          (module) => module.id == NarrativeOverviewModuleIds.cutscenes);
      expect(cutsceneModule.count, 1);
      expect(
          cutsceneModule.availability, NarrativeOverviewAvailability.available);

      final factsModule = model.modules.singleWhere(
          (module) => module.id == NarrativeOverviewModuleIds.facts);
      expect(factsModule.count, isNull);
      expect(
          factsModule.availability, NarrativeOverviewAvailability.needsModel);
    });

    test('marks chapters as fallback when Global Story metadata is absent', () {
      final project = _project(
        scenarios: const <ScenarioAsset>[
          ScenarioAsset(
            id: 'test_global_story',
            name: 'Fallback Global Story',
            description: 'Fallback metadata test.',
            scope: ScenarioScope.globalStory,
            entryNodeId: 'start',
            metadata: <String, String>{
              'step.id': 'test_step_1',
              'step.name': 'Fallback Step',
              'step.cutsceneIds': 'test_cutscene_1',
            },
          ),
          ScenarioAsset(
            id: 'test_cutscene_1',
            name: 'Test Cutscene',
            scope: ScenarioScope.localEventFlow,
            entryNodeId: 'start',
            metadata: <String, String>{
              kCutsceneStudioSchemaMetadataKey: kCutsceneStudioSchemaVersion,
            },
          ),
        ],
      );

      final model = buildNarrativeOverviewReadModel(project: project);

      expect(model.mainStory.title, 'Fallback Global Story');
      expect(
          model.mainStory.sourceStatus, NarrativeOverviewSourceStatus.explicit);
      expect(model.metrics.chapters.count, 1);
      expect(model.metrics.chapters.sourceStatus,
          NarrativeOverviewSourceStatus.fallback);
      expect(model.mainStory.chapters.single.sourceStatus,
          NarrativeOverviewSourceStatus.fallback);
    });

    test('does not choose a main story when multiple global stories exist', () {
      final model = buildNarrativeOverviewReadModel(
        project: _project(
          scenarios: const <ScenarioAsset>[
            ScenarioAsset(
              id: 'test_global_story_a',
              name: 'A',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
            ),
            ScenarioAsset(
              id: 'test_global_story_b',
              name: 'B',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
            ),
          ],
        ),
      );

      expect(model.mainStory.availability,
          NarrativeOverviewAvailability.unavailable);
      expect(model.mainStory.sourceStatus,
          NarrativeOverviewSourceStatus.ambiguous);
      expect(model.mainStory.canEdit, isFalse);
      expect(model.mainStory.title, isNull);
    });

    test('maps warning diagnostics to review status', () {
      final model = buildNarrativeOverviewReadModel(
        project: _project(),
        narrativeValidationReport: NarrativeValidationReport(
          diagnostics: const <NarrativeValidationDiagnostic>[
            NarrativeValidationDiagnostic(
              severity: NarrativeValidationSeverity.warning,
              kind: NarrativeValidationDiagnosticKind
                  .scenarioChoiceNodeRuntimeUnsupported,
              message: 'Choice node is not runtime-supported yet.',
              path: 'scenarios.test.nodes.choice',
            ),
          ],
        ),
      );

      expect(model.metrics.openIssues.count, 1);
      expect(model.editorialStatus.validationState,
          NarrativeEditorialValidationState.toReview);
      expect(model.editorialStatus.toReview, 1);
      expect(model.editorialStatus.blocking, 0);
      expect(model.projectHealth.healthKind,
          NarrativeProjectHealthKind.reviewNeeded);
    });

    test('maps error diagnostics to blocking status', () {
      final model = buildNarrativeOverviewReadModel(
        project: _project(),
        dialogueIssues: const <DialogueValidationIssue>[
          DialogueValidationIssue(
            severity: DialogueValidationSeverity.error,
            message: 'Réplique vide.',
          ),
        ],
      );

      expect(model.metrics.openIssues.count, 1);
      expect(model.editorialStatus.validationState,
          NarrativeEditorialValidationState.blocking);
      expect(model.editorialStatus.blocking, 1);
      expect(
          model.projectHealth.healthKind, NarrativeProjectHealthKind.blocked);
    });

    test('keeps zero real counts distinct from unavailable data', () {
      final model = buildNarrativeOverviewReadModel(
        project: _project(
          name: 'plain_test_project',
          scenarios: const <ScenarioAsset>[
            ScenarioAsset(
              id: 'plain_global_story',
              name: 'Plain Story',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
            ),
          ],
        ),
        narrativeValidationReport: NarrativeValidationReport(
            diagnostics: const <NarrativeValidationDiagnostic>[]),
      );

      expect(model.metrics.dialogues.count, 0);
      expect(model.metrics.dialogues.availability,
          NarrativeOverviewAvailability.empty);
      expect(model.metrics.cutscenes.count, 0);
      expect(model.metrics.cutscenes.availability,
          NarrativeOverviewAvailability.empty);
      expect(model.metrics.openIssues.count, 0);
      expect(model.metrics.openIssues.availability,
          NarrativeOverviewAvailability.available);
      expect(model.editorialStatus.validationState,
          NarrativeEditorialValidationState.upToDate);

      expect(model.metrics.dialogueLines.count, isNull);
      expect(model.metrics.dialogueLines.availability,
          NarrativeOverviewAvailability.unavailable);
    });

    test('does not hardcode image or Selbrume values', () {
      final model = buildNarrativeOverviewReadModel(
        project: _project(
          name: 'plain_test_project',
          scenarios: <ScenarioAsset>[
            _globalStoryWithDocuments(
              name: 'Plain Test Story',
              description: 'No image copy here.',
            ),
          ],
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'test_dialogue_1',
              name: 'Test Dialogue',
              relativePath: 'dialogues/test_dialogue_1.yarn',
            ),
          ],
        ),
      );

      expect(model.projectName, 'plain_test_project');
      expect(model.mainStory.title, 'Plain Test Story');
      expect(model.mainStory.description, 'No image copy here.');
      expect(model.projectName, isNot('Selbrume'));
      expect(model.mainStory.title, isNot('La brume du phare'));

      final realCounts = <int?>[
        model.metrics.chapters.count,
        model.metrics.scenes.count,
        model.metrics.cutscenes.count,
        model.metrics.quests.count,
        model.metrics.dialogues.count,
        model.metrics.dialogueLines.count,
        model.metrics.openIssues.count,
        model.metrics.conditions.count,
        model.metrics.worldRules.count,
        model.metrics.facts.count,
      ].whereType<int>().toSet();

      expect(realCounts.contains(42), isFalse);
      expect(realCounts.contains(1236), isFalse);
      expect(realCounts.contains(24), isFalse);
      expect(realCounts.contains(12), isFalse);
    });
  });
}

ProjectManifest _project({
  String name = 'test_project',
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  List<ProjectDialogueEntry> dialogues = const <ProjectDialogueEntry>[],
}) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: name,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: scenarios,
    dialogues: dialogues,
  );
}

ScenarioAsset _globalStoryWithDocuments({
  String name = 'Test Global Story',
  String description = 'A generic test story.',
}) {
  const stepDocument = StepStudioDocument(
    globalStoryScenarioId: 'test_global_story',
    steps: <StepStudioStep>[
      StepStudioStep(
        id: 'test_step_1',
        name: 'Step One',
        description: 'First test step.',
        order: 0,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.atGameStart,
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.whenCutsceneEnds,
          cutsceneId: 'test_cutscene_1',
        ),
        cutscenes: <StepStudioCutsceneLink>[
          StepStudioCutsceneLink(
            cutsceneId: 'test_cutscene_1',
            role: StepStudioCutsceneRole.main,
          ),
        ],
        worldChanges: <StepStudioWorldChange>[
          StepStudioWorldChange(
            mapId: 'test_map',
            entityId: 'test_entity',
            presenceRule: StepStudioPresenceRule.visibleAfterStepCompletion,
          ),
        ],
      ),
      StepStudioStep(
        id: 'test_step_2',
        name: 'Step Two',
        description: 'Second test step.',
        order: 1,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.afterStep,
          stepId: 'test_step_1',
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.whenOutcomeEmitted,
          outcomeId: 'progression.test_step_2.done',
        ),
        outcomes: <StepStudioOutcomeDefinition>[
          StepStudioOutcomeDefinition(
            label: 'Done',
            scope: StepStudioOutcomeScope.progression,
            outcomeId: 'progression.test_step_2.done',
          ),
        ],
      ),
    ],
  );

  const globalStoryDocument = GlobalStoryStudioDocument(
    globalStoryScenarioId: 'test_global_story',
    entryStepId: 'test_step_1',
    nodes: <GlobalStoryStepNode>[
      GlobalStoryStepNode(
        stepId: 'test_step_1',
        links: <GlobalStoryStepLink>[
          GlobalStoryStepLink(toStepId: 'test_step_2'),
        ],
      ),
      GlobalStoryStepNode(stepId: 'test_step_2'),
    ],
    chapters: <GlobalStoryChapter>[
      GlobalStoryChapter(
        id: 'test_chapter_1',
        name: 'Chapter One',
        description: 'First chapter.',
        stepIds: <String>['test_step_1'],
        order: 0,
      ),
      GlobalStoryChapter(
        id: 'test_chapter_2',
        name: 'Chapter Two',
        description: 'Second chapter.',
        stepIds: <String>['test_step_2'],
        order: 1,
      ),
    ],
  );

  return ScenarioAsset(
    id: 'test_global_story',
    name: name,
    description: description,
    scope: ScenarioScope.globalStory,
    entryNodeId: 'start',
    metadata: <String, String>{
      kStepStudioSchemaMetadataKey: kStepStudioSchemaVersion,
      kStepStudioDocumentMetadataKey: stepDocument.toMetadataJson(),
      kGlobalStoryStudioSchemaMetadataKey: kGlobalStoryStudioSchemaVersion,
      kGlobalStoryStudioDocumentMetadataKey:
          globalStoryDocument.toMetadataJson(),
    },
  );
}

ScenarioAsset _cutsceneScenario({
  required String id,
  String? dialogueId,
}) {
  return ScenarioAsset(
    id: id,
    name: 'Test Cutscene',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'start',
    metadata: const <String, String>{
      kCutsceneStudioSchemaMetadataKey: kCutsceneStudioSchemaVersion,
    },
    nodes: <ScenarioNode>[
      if (dialogueId != null)
        ScenarioNode(
          id: 'open_dialogue',
          payload: const ScenarioNodePayload(actionKind: 'openDialogue'),
          binding: ScenarioNodeBinding(dialogueId: dialogueId),
        ),
    ],
  );
}
```

### 16.3 Commandes de vérification relancées

`cd packages/map_editor && flutter test test/features/narrative/application/overview/narrative_overview_read_model_test.dart`

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

`cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/features/narrative/application/overview/narrative_overview_read_model.dart test/features/narrative/application/overview/narrative_overview_read_model_test.dart`

```text
Analyzing 2 items...

No issues found! (ran in 2.3s)
```

### 16.4 Git final bis

`git status --short --untracked-files=all`

```text
 M reports/narrativeStudio/ui/ns_home_02_narrative_overview_read_model.md
```

`git diff --stat`

```text
 .../ui/ns_home_02_narrative_overview_read_model.md | 1645 ++++++++++++++++++++
 1 file changed, 1645 insertions(+)
```

`git diff --name-only`

```text
reports/narrativeStudio/ui/ns_home_02_narrative_overview_read_model.md
```

`git diff --check`

```text
Sortie : <vide>
```

Note : le contenu complet du read model et du test ciblé est reproduit ci-dessus pour compenser toute limite d'audit liée aux fichiers non trackés ou à un diff Git incomplet. Dans l'état observé pendant NS-HOME-02-bis, les fichiers code/test NS-HOME-02 étaient déjà présents et n'ont pas été modifiés par ce bis.
