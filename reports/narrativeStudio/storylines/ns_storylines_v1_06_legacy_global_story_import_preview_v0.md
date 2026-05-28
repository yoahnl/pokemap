# NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0

## 1. Executive summary

NS-STORYLINES-V1-06 est livré. `map_core` expose une API pure `buildLegacyGlobalStoryImportPreview(ProjectManifest)` qui scanne les `ScenarioAsset(scope == globalStory)`, produit des candidats `StorylineAsset(type: main, status: draft)` et remonte des issues stables, sans mutation du manifest.

Le lot reste une preview : aucun import appliqué, aucun write dans `ProjectManifest.storylines`, aucun mapping `localEventFlow -> sideQuest`, aucune UI, aucun runtime.

## 2. Inputs read

- AGENTS.md
- agent_rules.md
- skills/README.md
- reports/narrativeStudio/storylines/road_map_storylines.md
- reports/narrativeStudio/storylines/ns_storylines_v1_05_project_manifest_storylines_integration_v0.md
- reports/narrativeStudio/storylines/ns_storylines_v1_04_storyline_asset_json_codec_v0.md
- reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md
- reports/narrativeStudio/storylines/ns_storylines_v1_02_storyline_authoring_data_shape_contract.md
- reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md
- packages/map_core/lib/src/models/project_manifest.dart
- packages/map_core/lib/src/models/storyline_asset.dart
- packages/map_core/lib/src/models/scenario_asset.dart
- packages/map_core/lib/src/models/script_conditions.dart
- packages/map_core/lib/map_core.dart
- packages/map_core/lib/src/authoring/
- packages/map_core/test/project_manifest_storylines_test.dart
- packages/map_core/test/storyline_asset_json_test.dart
- packages/map_core/test/storyline_asset_test.dart
- packages/map_core/test/scenario_assets_test.dart
- packages/map_core/test/

Fichiers attendus mais absents :

```text
Sortie : <vide>
```

## 3. Implementation summary

- Création de `packages/map_core/lib/src/authoring/storyline_legacy_import_preview.dart`.
- Export public ajouté dans `packages/map_core/lib/map_core.dart`.
- Création de `packages/map_core/test/storyline_legacy_import_preview_test.dart`.
- Roadmap mise à jour pour marquer V1-06 `DONE` et recommander V1-07.

## 4. Preview API

API livrée :

```dart
StorylineLegacyGlobalStoryImportPreview buildLegacyGlobalStoryImportPreview(
  ProjectManifest manifest,
)
```

Objets publics :

- `StorylineLegacyGlobalStoryImportPreview` : `candidates`, `issues`, `hasCandidates`, `hasBlockingIssues`.
- `StorylineLegacyGlobalStoryImportCandidate` : `sourceScenarioId`, `sourceScenarioName`, `draftStoryline`, `issues`.

Les diagnostics réutilisent `StorylineValidationIssue`, ce qui évite une deuxième taxonomie d'issues dans `map_core`.

## 5. Candidate mapping behavior

Mapping `ScenarioAsset.globalStory -> StorylineAsset` :

- `id` : `legacy_<scenario.id>` ou `legacy_global_story` si l'id source est vide.
- `type` : `StorylineType.main`.
- `status` : `StorylineStatus.draft`.
- `title` : `ScenarioAsset.name`, avec fallback technique `Imported global story` si vide.
- `description` : `ScenarioAsset.description` si non vide.
- `legacySource.kind` : `scenario.globalStory`.
- `legacySource.sourceId` : `ScenarioAsset.id`.
- `metadata.legacyImportPreview` : `true`.

Ce candidat reste hors manifest.

## 6. Legacy metadata handling

Metadata lues :

- `authoring.globalStoryStudioDocument` pour les chapters.
- `authoring.stepStudioDocument` pour les steps.

Si les deux documents sont lisibles, la preview importe :

- `GlobalStoryChapter.id/name/description/order/stepIds` vers `StorylineChapter`.
- `StepStudioStep.id/name/description/order` vers `StorylineStep` quand la step est référencée par un chapter.

Si une metadata est absente ou invalide, la preview garde un candidat minimal et ajoute une issue. Aucun chapter, step, scene link, outcome, fact ou world rule fake n'est créé.

## 7. Diagnostics / issues

Rule ids stables couverts :

- `noLegacyGlobalStoryFound`
- `multipleLegacyGlobalStoriesFound`
- `existingStorylinesPresent`
- `candidateIdAlreadyExists`
- `missingGlobalStoryMetadata`
- `invalidGlobalStoryMetadata`
- `missingStepStudioMetadata`
- `invalidStepStudioMetadata`
- `missingReferencedStep`
- `unassignedLegacyStep`
- `declaredOutcomesNotMapped`
- `localEventFlowIgnored`

Les messages sont en anglais côté `map_core`, cohérents avec un diagnostic core non localisé.

## 8. No-mutation guarantees

La preview ne modifie pas :

- `ProjectManifest`
- `ProjectManifest.storylines`
- `ProjectManifest.scenarios`
- `ScenarioAsset`
- `StorylineAsset` existants

Les tests comparent `manifest.toJson()` avant/après sur les cas d'import minimal et d'import chapters/steps.

## 9. localEventFlow exclusion

Les `ScenarioAsset(scope == localEventFlow)` sont scannés uniquement pour produire une issue informative `localEventFlowIgnored`. Ils ne génèrent jamais de candidat et ne deviennent jamais `StorylineType.sideQuest`.

## 10. Non-goals confirmed

- Aucun `ProjectManifest` modifié.
- Aucun `ProjectManifest.storylines` rempli automatiquement.
- Aucun `StorylineAsset` modifié.
- Aucun `ScenarioAsset` modifié.
- Aucun `ScriptCondition` modifié.
- Aucun generated file modifié.
- Aucun build_runner lancé.
- Aucun apply/import mutateur ajouté.
- Aucun `localEventFlow` mappé en `sideQuest`.
- Aucune UI / runtime / gameplay / battle modifiée.
- V1-07 non démarré.

## 11. Tests added

Test créé :

- `packages/map_core/test/storyline_legacy_import_preview_test.dart`

Couverture :

- aucun `globalStory` ;
- import minimal d'un `globalStory` ;
- exclusion `localEventFlow` ;
- `globalStory + localEventFlow` ;
- plusieurs `globalStory` ;
- manifest avec storylines existantes ;
- collision d'id candidat ;
- import chapters/steps depuis metadata lisibles ;
- step référencée absente ;
- step legacy non assignée ;
- declared outcomes non mappés ;
- metadata legacy invalide ;
- no-mutation JSON avant/après.

## 12. Commands run

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
# lectures et recherches context-mode sur les fichiers obligatoires et modèles legacy
dart format lib/src/authoring/storyline_legacy_import_preview.dart test/storyline_legacy_import_preview_test.dart
cd packages/map_core && dart test --reporter json test/storyline_legacy_import_preview_test.dart | tail -n 1
cd packages/map_core && dart test --reporter json test/project_manifest_storylines_test.dart | tail -n 1
cd packages/map_core && dart test --reporter json test/storyline_asset_json_test.dart | tail -n 1
cd packages/map_core && dart test --reporter json test/storyline_asset_test.dart | tail -n 1
cd packages/map_core && dart test --reporter json test/scenario_assets_test.dart | tail -n 1
cd packages/map_core && dart analyze lib/src/authoring/storyline_legacy_import_preview.dart test/storyline_legacy_import_preview_test.dart
cd packages/map_core && dart test --reporter json | tail -n 1
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

## 13. Roadmap update

`reports/narrativeStudio/storylines/road_map_storylines.md` a été mis à jour :

- `NS-STORYLINES-V1-06` marqué `DONE`.
- Résumé de la preview legacy ajouté.
- Tests et analyse listés.
- No-mutation, no-UI, no-runtime et exclusion `localEventFlow` confirmés.
- Prochain lot recommandé : `NS-STORYLINES-V1-07 — Create Main Storyline Flow V0`.

## 14. Evidence Pack

### Git branch initiale

```text
main
```

### Git status initial exact

```text
Sortie : <vide>
```

### Git diff --stat initial

```text
Sortie : <vide>
```

### Git diff --name-only initial

```text
Sortie : <vide>
```

### Git diff --check initial

```text
Sortie : <vide>
```

### Liste des fichiers lus

- AGENTS.md
- agent_rules.md
- skills/README.md
- reports/narrativeStudio/storylines/road_map_storylines.md
- reports/narrativeStudio/storylines/ns_storylines_v1_05_project_manifest_storylines_integration_v0.md
- reports/narrativeStudio/storylines/ns_storylines_v1_04_storyline_asset_json_codec_v0.md
- reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md
- reports/narrativeStudio/storylines/ns_storylines_v1_02_storyline_authoring_data_shape_contract.md
- reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md
- packages/map_core/lib/src/models/project_manifest.dart
- packages/map_core/lib/src/models/storyline_asset.dart
- packages/map_core/lib/src/models/scenario_asset.dart
- packages/map_core/lib/src/models/script_conditions.dart
- packages/map_core/lib/map_core.dart
- packages/map_core/lib/src/authoring/
- packages/map_core/test/project_manifest_storylines_test.dart
- packages/map_core/test/storyline_asset_json_test.dart
- packages/map_core/test/storyline_asset_test.dart
- packages/map_core/test/scenario_assets_test.dart
- packages/map_core/test/

### Liste des fichiers absents mais attendus

```text
Sortie : <vide>
```

### Contenu complet de storyline_legacy_import_preview.dart

```dart
import 'dart:collection';
import 'dart:convert';

import '../models/project_manifest.dart';
import '../models/scenario_asset.dart';
import '../models/storyline_asset.dart';

const String _globalStoryDocumentMetadataKey =
    'authoring.globalStoryStudioDocument';
const String _stepStudioDocumentMetadataKey = 'authoring.stepStudioDocument';
const String _legacyGlobalStorySourceKind = 'scenario.globalStory';

StorylineLegacyGlobalStoryImportPreview buildLegacyGlobalStoryImportPreview(
  ProjectManifest manifest,
) {
  final previewIssues = <StorylineValidationIssue>[];
  final candidates = <StorylineLegacyGlobalStoryImportCandidate>[];
  final globalStories = manifest.scenarios
      .where((scenario) => scenario.scope == ScenarioScope.globalStory)
      .toList(growable: false);
  final localEventFlows = manifest.scenarios
      .where((scenario) => scenario.scope == ScenarioScope.localEventFlow)
      .toList(growable: false);

  if (globalStories.isEmpty) {
    previewIssues.add(
      _issue(
        severity: StorylineValidationSeverity.info,
        targetRef: 'manifest',
        ruleId: 'noLegacyGlobalStoryFound',
        message: 'No legacy globalStory scenario found.',
      ),
    );
  }

  if (globalStories.length > 1) {
    previewIssues.add(
      _issue(
        severity: StorylineValidationSeverity.warning,
        targetRef: 'manifest.scenarios',
        ruleId: 'multipleLegacyGlobalStoriesFound',
        message:
            'Multiple legacy globalStory scenarios found; no main story is selected automatically.',
      ),
    );
  }

  if (manifest.storylines.isNotEmpty) {
    previewIssues.add(
      _issue(
        severity: StorylineValidationSeverity.warning,
        targetRef: 'manifest.storylines',
        ruleId: 'existingStorylinesPresent',
        message:
            'Project already contains StorylineAsset entries; preview will not merge or replace them.',
      ),
    );
  }

  for (final scenario in localEventFlows) {
    previewIssues.add(
      _issue(
        severity: StorylineValidationSeverity.info,
        targetRef: 'scenario:${scenario.id}',
        ruleId: 'localEventFlowIgnored',
        message:
            'localEventFlow scenarios are ignored by legacy global story import preview.',
      ),
    );
  }

  final existingStorylineIds =
      manifest.storylines.map((storyline) => storyline.id).toSet();
  for (final scenario in globalStories) {
    candidates.add(
      _buildCandidate(
        scenario: scenario,
        existingStorylineIds: existingStorylineIds,
      ),
    );
  }

  return StorylineLegacyGlobalStoryImportPreview(
    candidates: candidates,
    issues: previewIssues,
  );
}

class StorylineLegacyGlobalStoryImportPreview {
  StorylineLegacyGlobalStoryImportPreview({
    List<StorylineLegacyGlobalStoryImportCandidate> candidates =
        const <StorylineLegacyGlobalStoryImportCandidate>[],
    List<StorylineValidationIssue> issues = const <StorylineValidationIssue>[],
  })  : candidates =
            List<StorylineLegacyGlobalStoryImportCandidate>.unmodifiable(
          candidates,
        ),
        issues = List<StorylineValidationIssue>.unmodifiable(issues);

  final List<StorylineLegacyGlobalStoryImportCandidate> candidates;
  final List<StorylineValidationIssue> issues;

  bool get hasCandidates => candidates.isNotEmpty;

  bool get hasBlockingIssues {
    return _hasBlockingIssue(issues) ||
        candidates.any((candidate) => _hasBlockingIssue(candidate.issues));
  }
}

class StorylineLegacyGlobalStoryImportCandidate {
  StorylineLegacyGlobalStoryImportCandidate({
    required this.sourceScenarioId,
    required this.sourceScenarioName,
    required this.draftStoryline,
    List<StorylineValidationIssue> issues = const <StorylineValidationIssue>[],
  }) : issues = List<StorylineValidationIssue>.unmodifiable(issues);

  final String sourceScenarioId;
  final String sourceScenarioName;
  final StorylineAsset draftStoryline;
  final List<StorylineValidationIssue> issues;
}

StorylineLegacyGlobalStoryImportCandidate _buildCandidate({
  required ScenarioAsset scenario,
  required Set<String> existingStorylineIds,
}) {
  final issues = <StorylineValidationIssue>[];
  final candidateId = _candidateIdForScenario(scenario.id);

  if (existingStorylineIds.contains(candidateId)) {
    issues.add(
      _issue(
        severity: StorylineValidationSeverity.blocking,
        targetRef: 'storyline:$candidateId',
        ruleId: 'candidateIdAlreadyExists',
        message:
            'Generated legacy import candidate id already exists in manifest.storylines.',
      ),
    );
  }

  final stepDocument = _readStepStudioDocument(scenario, issues);
  final globalDocument = _readGlobalStoryDocument(scenario, issues);
  final importedChapters = _buildChapters(
    scenario: scenario,
    globalDocument: globalDocument,
    stepDocument: stepDocument,
    issues: issues,
  );

  if (scenario.declaredOutcomes.isNotEmpty) {
    issues.add(
      _issue(
        severity: StorylineValidationSeverity.info,
        targetRef: 'scenario:${scenario.id}',
        ruleId: 'declaredOutcomesNotMapped',
        message:
            'Scenario declares outcomes, but preview does not map outcomes without explicit scene links.',
      ),
    );
  }

  final draft = StorylineAsset(
    id: candidateId,
    type: StorylineType.main,
    status: StorylineStatus.draft,
    title: _titleFromScenario(scenario),
    description: _descriptionFromScenario(scenario),
    chapters: importedChapters,
    legacySource: StorylineLegacySource(
      kind: _legacyGlobalStorySourceKind,
      sourceId: scenario.id,
      metadata: const <String, String>{'preview': 'true'},
    ),
    metadata: const <String, String>{'legacyImportPreview': 'true'},
  );

  return StorylineLegacyGlobalStoryImportCandidate(
    sourceScenarioId: scenario.id,
    sourceScenarioName: scenario.name,
    draftStoryline: draft,
    issues: issues,
  );
}

List<StorylineChapter> _buildChapters({
  required ScenarioAsset scenario,
  required _LegacyGlobalStoryDocument? globalDocument,
  required _LegacyStepStudioDocument? stepDocument,
  required List<StorylineValidationIssue> issues,
}) {
  if (globalDocument == null) {
    return const <StorylineChapter>[];
  }

  final stepById = <String, _LegacyStepStudioStep>{
    if (stepDocument != null)
      for (final step in stepDocument.steps) step.id: step,
  };
  final referencedStepIds = <String>{};
  final importedStepIds = <String>{};
  final chapters = <StorylineChapter>[];

  for (var index = 0; index < globalDocument.chapters.length; index += 1) {
    final chapter = globalDocument.chapters[index];
    final chapterId = chapter.id.trim().isNotEmpty
        ? chapter.id.trim()
        : 'legacy_chapter_${index + 1}';
    if (chapter.id.trim().isEmpty) {
      issues.add(
        _issue(
          severity: StorylineValidationSeverity.warning,
          targetRef: 'scenario:${scenario.id}',
          ruleId: 'invalidGlobalStoryMetadata',
          message:
              'Legacy chapter is missing an id; preview generated a stable chapter id from list order.',
        ),
      );
    }

    final title = chapter.name.trim().isNotEmpty
        ? chapter.name.trim()
        : 'Imported chapter ${index + 1}';
    if (chapter.name.trim().isEmpty) {
      issues.add(
        _issue(
          severity: StorylineValidationSeverity.warning,
          targetRef: 'chapter:$chapterId',
          ruleId: 'invalidGlobalStoryMetadata',
          message:
              'Legacy chapter is missing a title; preview used a technical fallback title.',
        ),
      );
    }

    final steps = <StorylineStep>[];
    for (final stepId in chapter.stepIds) {
      referencedStepIds.add(stepId);
      final legacyStep = stepById[stepId];
      if (legacyStep == null) {
        issues.add(
          _issue(
            severity: StorylineValidationSeverity.warning,
            targetRef: 'chapter:$chapterId',
            ruleId: 'missingReferencedStep',
            message:
                'Legacy chapter references a step that is missing from Step Studio metadata.',
          ),
        );
        continue;
      }
      if (importedStepIds.contains(legacyStep.id)) {
        issues.add(
          _issue(
            severity: StorylineValidationSeverity.warning,
            targetRef: 'step:${legacyStep.id}',
            ruleId: 'invalidGlobalStoryMetadata',
            message:
                'Legacy step is referenced more than once; preview imports only the first occurrence.',
          ),
        );
        continue;
      }
      importedStepIds.add(legacyStep.id);
      steps.add(
        StorylineStep(
          id: legacyStep.id,
          title: legacyStep.name.trim().isNotEmpty
              ? legacyStep.name.trim()
              : 'Imported step ${legacyStep.id}',
          description: legacyStep.description.trim().isEmpty
              ? null
              : legacyStep.description.trim(),
          order: legacyStep.order,
        ),
      );
    }

    chapters.add(
      StorylineChapter(
        id: chapterId,
        title: title,
        description:
            chapter.description.trim().isEmpty ? null : chapter.description,
        order: chapter.order >= 0 ? chapter.order : index,
        steps: steps,
      ),
    );
  }

  if (stepDocument != null) {
    final unassigned = stepDocument.steps.where(
      (step) => !referencedStepIds.contains(step.id),
    );
    for (final step in unassigned) {
      issues.add(
        _issue(
          severity: StorylineValidationSeverity.warning,
          targetRef: 'step:${step.id}',
          ruleId: 'unassignedLegacyStep',
          message:
              'Legacy Step Studio step is not assigned to any Global Story chapter.',
        ),
      );
    }
  }

  return chapters;
}

_LegacyGlobalStoryDocument? _readGlobalStoryDocument(
  ScenarioAsset scenario,
  List<StorylineValidationIssue> issues,
) {
  final raw = scenario.metadata[_globalStoryDocumentMetadataKey]?.trim();
  if (raw == null || raw.isEmpty) {
    issues.add(
      _issue(
        severity: StorylineValidationSeverity.warning,
        targetRef: 'scenario:${scenario.id}',
        ruleId: 'missingGlobalStoryMetadata',
        message:
            'Legacy globalStory scenario has no Global Story Studio metadata; preview creates a minimal candidate.',
      ),
    );
    return null;
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException(
          'global story metadata root is not an object');
    }
    return _LegacyGlobalStoryDocument.fromJson(_jsonObject(decoded));
  } catch (_) {
    issues.add(
      _issue(
        severity: StorylineValidationSeverity.error,
        targetRef: 'scenario:${scenario.id}',
        ruleId: 'invalidGlobalStoryMetadata',
        message:
            'Legacy globalStory scenario has invalid Global Story Studio metadata; preview keeps the candidate minimal.',
      ),
    );
    return null;
  }
}

_LegacyStepStudioDocument? _readStepStudioDocument(
  ScenarioAsset scenario,
  List<StorylineValidationIssue> issues,
) {
  final raw = scenario.metadata[_stepStudioDocumentMetadataKey]?.trim();
  if (raw == null || raw.isEmpty) {
    issues.add(
      _issue(
        severity: StorylineValidationSeverity.warning,
        targetRef: 'scenario:${scenario.id}',
        ruleId: 'missingStepStudioMetadata',
        message:
            'Legacy globalStory scenario has no Step Studio metadata; preview cannot import steps.',
      ),
    );
    return null;
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('step studio metadata root is not an object');
    }
    return _LegacyStepStudioDocument.fromJson(_jsonObject(decoded));
  } catch (_) {
    issues.add(
      _issue(
        severity: StorylineValidationSeverity.error,
        targetRef: 'scenario:${scenario.id}',
        ruleId: 'invalidStepStudioMetadata',
        message:
            'Legacy globalStory scenario has invalid Step Studio metadata; preview cannot import steps.',
      ),
    );
    return null;
  }
}

String _candidateIdForScenario(String scenarioId) {
  final trimmed = scenarioId.trim();
  return trimmed.isEmpty ? 'legacy_global_story' : 'legacy_$trimmed';
}

String _titleFromScenario(ScenarioAsset scenario) {
  final trimmed = scenario.name.trim();
  return trimmed.isEmpty ? 'Imported global story' : trimmed;
}

String? _descriptionFromScenario(ScenarioAsset scenario) {
  final trimmed = scenario.description.trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool _hasBlockingIssue(List<StorylineValidationIssue> issues) {
  return issues.any(
    (issue) => issue.severity == StorylineValidationSeverity.blocking,
  );
}

StorylineValidationIssue _issue({
  required StorylineValidationSeverity severity,
  required String targetRef,
  required String ruleId,
  required String message,
}) {
  return StorylineValidationIssue(
    severity: severity,
    targetRef: targetRef,
    ruleId: ruleId,
    message: message,
  );
}

Map<String, dynamic> _jsonObject(Map<Object?, Object?> json) {
  return json.map((key, value) {
    if (key is! String) {
      throw const FormatException('JSON object key is not a string');
    }
    return MapEntry(key, value);
  });
}

List<String> _readStringList(Object? json) {
  if (json is! List) {
    return const <String>[];
  }
  return [
    for (final item in json)
      if (item is String && item.trim().isNotEmpty) item.trim(),
  ];
}

String _readString(Object? value) => value?.toString().trim() ?? '';

int _readOrder(Object? value, int fallback) {
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

class _LegacyGlobalStoryDocument {
  _LegacyGlobalStoryDocument(
      {required List<_LegacyGlobalStoryChapter> chapters})
      : chapters = UnmodifiableListView<_LegacyGlobalStoryChapter>(chapters);

  factory _LegacyGlobalStoryDocument.fromJson(Map<String, dynamic> json) {
    final rawChapters = json['chapters'];
    if (rawChapters is! List) {
      return _LegacyGlobalStoryDocument(
        chapters: const <_LegacyGlobalStoryChapter>[],
      );
    }
    final chapters = <_LegacyGlobalStoryChapter>[];
    for (var index = 0; index < rawChapters.length; index += 1) {
      final raw = rawChapters[index];
      if (raw is Map) {
        chapters.add(
          _LegacyGlobalStoryChapter.fromJson(_jsonObject(raw), index),
        );
      }
    }
    return _LegacyGlobalStoryDocument(chapters: chapters);
  }

  final List<_LegacyGlobalStoryChapter> chapters;
}

class _LegacyGlobalStoryChapter {
  const _LegacyGlobalStoryChapter({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    required this.stepIds,
  });

  factory _LegacyGlobalStoryChapter.fromJson(
    Map<String, dynamic> json,
    int index,
  ) {
    return _LegacyGlobalStoryChapter(
      id: _readString(json['id']),
      name: _readString(json['name']),
      description: _readString(json['description']),
      order: _readOrder(json['order'], index),
      stepIds: _readStringList(json['stepIds']),
    );
  }

  final String id;
  final String name;
  final String description;
  final int order;
  final List<String> stepIds;
}

class _LegacyStepStudioDocument {
  _LegacyStepStudioDocument({required List<_LegacyStepStudioStep> steps})
      : steps = UnmodifiableListView<_LegacyStepStudioStep>(steps);

  factory _LegacyStepStudioDocument.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'];
    if (rawSteps is! List) {
      return _LegacyStepStudioDocument(
        steps: const <_LegacyStepStudioStep>[],
      );
    }
    final steps = <_LegacyStepStudioStep>[];
    for (var index = 0; index < rawSteps.length; index += 1) {
      final raw = rawSteps[index];
      if (raw is Map) {
        final step = _LegacyStepStudioStep.fromJson(_jsonObject(raw), index);
        if (step.id.isNotEmpty) {
          steps.add(step);
        }
      }
    }
    steps.sort((a, b) => a.order.compareTo(b.order));
    return _LegacyStepStudioDocument(steps: steps);
  }

  final List<_LegacyStepStudioStep> steps;
}

class _LegacyStepStudioStep {
  const _LegacyStepStudioStep({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
  });

  factory _LegacyStepStudioStep.fromJson(
    Map<String, dynamic> json,
    int index,
  ) {
    return _LegacyStepStudioStep(
      id: _readString(json['id']),
      name: _readString(json['name']),
      description: _readString(json['description']),
      order: _readOrder(json['order'], index),
    );
  }

  final String id;
  final String name;
  final String description;
  final int order;
}

```

### Contenu complet de storyline_legacy_import_preview_test.dart

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('buildLegacyGlobalStoryImportPreview', () {
    test('reports no legacy globalStory when manifest has none', () {
      final preview = buildLegacyGlobalStoryImportPreview(_manifest());

      expect(preview.candidates, isEmpty);
      expect(preview.hasCandidates, isFalse);
      expect(preview.issues, _containsRule('noLegacyGlobalStoryFound'));
    });

    test('builds a minimal main draft candidate from globalStory', () {
      final scenario = _globalStory(
        id: 'global_story',
        name: 'Audit Global Story',
        description: 'Legacy description',
      );
      final manifest = _manifest(scenarios: [scenario]);
      final before = jsonEncode(manifest.toJson());

      final preview = buildLegacyGlobalStoryImportPreview(manifest);
      final after = jsonEncode(manifest.toJson());

      expect(preview.candidates, hasLength(1));
      final candidate = preview.candidates.single;
      expect(candidate.sourceScenarioId, 'global_story');
      expect(candidate.sourceScenarioName, 'Audit Global Story');
      expect(candidate.draftStoryline.id, 'legacy_global_story');
      expect(candidate.draftStoryline.type, StorylineType.main);
      expect(candidate.draftStoryline.status, StorylineStatus.draft);
      expect(candidate.draftStoryline.title, 'Audit Global Story');
      expect(candidate.draftStoryline.description, 'Legacy description');
      expect(candidate.draftStoryline.chapters, isEmpty);
      expect(candidate.draftStoryline.legacySource, isNotNull);
      expect(
          candidate.draftStoryline.legacySource!.kind, 'scenario.globalStory');
      expect(candidate.draftStoryline.legacySource!.sourceId, 'global_story');
      expect(candidate.issues, _containsRule('missingGlobalStoryMetadata'));
      expect(candidate.issues, _containsRule('missingStepStudioMetadata'));
      expect(after, before);
    });

    test('ignores localEventFlow and never creates a side quest', () {
      final manifest = _manifest(
        scenarios: [
          _localEventFlow(id: 'local_story_like_flow', name: 'Looks Narrative'),
        ],
      );

      final preview = buildLegacyGlobalStoryImportPreview(manifest);

      expect(preview.candidates, isEmpty);
      expect(preview.issues, _containsRule('localEventFlowIgnored'));
      expect(
        preview.candidates.where(
          (candidate) =>
              candidate.draftStoryline.type == StorylineType.sideQuest,
        ),
        isEmpty,
      );
    });

    test('imports only globalStory when localEventFlow also exists', () {
      final manifest = _manifest(
        scenarios: [
          _globalStory(id: 'main_global', name: 'Main Global'),
          _localEventFlow(id: 'local_flow', name: 'Local Flow'),
        ],
      );

      final preview = buildLegacyGlobalStoryImportPreview(manifest);

      expect(preview.candidates, hasLength(1));
      expect(preview.candidates.single.sourceScenarioId, 'main_global');
      expect(preview.issues, _containsRule('localEventFlowIgnored'));
      expect(preview.candidates.single.draftStoryline.type, StorylineType.main);
    });

    test('builds one candidate per globalStory and reports multiples', () {
      final preview = buildLegacyGlobalStoryImportPreview(
        _manifest(
          scenarios: [
            _globalStory(id: 'global_one', name: 'Global One'),
            _globalStory(id: 'global_two', name: 'Global Two'),
          ],
        ),
      );

      expect(preview.candidates, hasLength(2));
      expect(preview.issues, _containsRule('multipleLegacyGlobalStoriesFound'));
      expect(
        preview.candidates.map((candidate) => candidate.draftStoryline.id),
        containsAll(['legacy_global_one', 'legacy_global_two']),
      );
    });

    test('previews with existing storylines without mutating them', () {
      final existing = StorylineAsset(
        id: 'existing_story',
        type: StorylineType.main,
        title: 'Existing',
      );
      final manifest = _manifest(
        scenarios: [_globalStory(id: 'global_story', name: 'Global')],
        storylines: [existing],
      );
      final before = jsonEncode(manifest.toJson());

      final preview = buildLegacyGlobalStoryImportPreview(manifest);
      final after = jsonEncode(manifest.toJson());

      expect(preview.candidates, hasLength(1));
      expect(preview.issues, _containsRule('existingStorylinesPresent'));
      expect(manifest.storylines.single, same(existing));
      expect(after, before);
    });

    test('reports candidate id collision without silently changing id', () {
      final existing = StorylineAsset(
        id: 'legacy_global_story',
        type: StorylineType.main,
        title: 'Existing',
      );

      final preview = buildLegacyGlobalStoryImportPreview(
        _manifest(
          scenarios: [_globalStory(id: 'global_story', name: 'Global')],
          storylines: [existing],
        ),
      );

      expect(preview.candidates, hasLength(1));
      expect(
          preview.candidates.single.draftStoryline.id, 'legacy_global_story');
      expect(
        preview.candidates.single.issues,
        _containsRule('candidateIdAlreadyExists'),
      );
      expect(preview.hasBlockingIssues, isTrue);
    });

    test('imports legacy chapters and attached steps when metadata is valid',
        () {
      final manifest = _manifest(
        scenarios: [
          _globalStory(
            id: 'global_story',
            name: 'Global',
            metadata: {
              'authoring.globalStoryStudioDocument': _globalStoryDocumentJson(
                chapters: [
                  {
                    'id': 'chapter_intro',
                    'name': 'Intro chapter',
                    'description': 'Chapter description',
                    'order': 2,
                    'stepIds': ['step_intro', 'missing_step'],
                  },
                ],
              ),
              'authoring.stepStudioDocument': _stepStudioDocumentJson(
                steps: [
                  {
                    'id': 'step_intro',
                    'name': 'Intro step',
                    'description': 'Step description',
                    'order': 3,
                  },
                  {
                    'id': 'step_unassigned',
                    'name': 'Unassigned step',
                    'description': '',
                    'order': 4,
                  },
                ],
              ),
            },
            declaredOutcomes: ['legacy.outcome'],
          ),
        ],
      );
      final before = jsonEncode(manifest.toJson());

      final preview = buildLegacyGlobalStoryImportPreview(manifest);
      final after = jsonEncode(manifest.toJson());

      final storyline = preview.candidates.single.draftStoryline;
      expect(storyline.chapters, hasLength(1));
      final chapter = storyline.chapters.single;
      expect(chapter.id, 'chapter_intro');
      expect(chapter.title, 'Intro chapter');
      expect(chapter.description, 'Chapter description');
      expect(chapter.order, 2);
      expect(chapter.steps, hasLength(1));
      expect(chapter.steps.single.id, 'step_intro');
      expect(chapter.steps.single.title, 'Intro step');
      expect(chapter.steps.single.description, 'Step description');
      expect(chapter.steps.single.order, 3);
      expect(preview.candidates.single.issues,
          _containsRule('missingReferencedStep'));
      expect(preview.candidates.single.issues,
          _containsRule('unassignedLegacyStep'));
      expect(preview.candidates.single.issues,
          _containsRule('declaredOutcomesNotMapped'));
      expect(after, before);
    });

    test('reports invalid legacy metadata without throwing', () {
      final preview = buildLegacyGlobalStoryImportPreview(
        _manifest(
          scenarios: [
            _globalStory(
              id: 'global_story',
              name: 'Global',
              metadata: const {
                'authoring.globalStoryStudioDocument': '[',
                'authoring.stepStudioDocument': '[',
              },
            ),
          ],
        ),
      );

      expect(preview.candidates, hasLength(1));
      expect(preview.candidates.single.draftStoryline.chapters, isEmpty);
      expect(preview.candidates.single.issues,
          _containsRule('invalidGlobalStoryMetadata'));
      expect(preview.candidates.single.issues,
          _containsRule('invalidStepStudioMetadata'));
    });
  });
}

Matcher _containsRule(String ruleId) {
  return contains(
    isA<StorylineValidationIssue>().having(
      (issue) => issue.ruleId,
      'ruleId',
      ruleId,
    ),
  );
}

ProjectManifest _manifest({
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  List<StorylineAsset> storylines = const <StorylineAsset>[],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    scenarios: scenarios,
    storylines: storylines,
  );
}

ScenarioAsset _globalStory({
  required String id,
  required String name,
  String description = '',
  Map<String, String> metadata = const <String, String>{},
  List<String> declaredOutcomes = const <String>[],
}) {
  return ScenarioAsset(
    id: id,
    name: name,
    description: description,
    scope: ScenarioScope.globalStory,
    entryNodeId: 'start',
    declaredOutcomes: declaredOutcomes,
    nodes: const [ScenarioNode(id: 'start', type: ScenarioNodeType.start)],
    metadata: metadata,
  );
}

ScenarioAsset _localEventFlow({
  required String id,
  required String name,
}) {
  return ScenarioAsset(
    id: id,
    name: name,
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'start',
    nodes: const [ScenarioNode(id: 'start', type: ScenarioNodeType.start)],
  );
}

String _globalStoryDocumentJson(
    {required List<Map<String, Object?>> chapters}) {
  return jsonEncode({
    'schemaVersion': 'global_story_studio_v1.1',
    'globalStoryScenarioId': 'global_story',
    'entryStepId': '',
    'nodes': <Object?>[],
    'chapters': chapters,
  });
}

String _stepStudioDocumentJson({required List<Map<String, Object?>> steps}) {
  return jsonEncode({
    'schemaVersion': 'step_studio_v1',
    'globalStoryScenarioId': 'global_story',
    'steps': steps,
  });
}

```

### Diff complet de map_core.dart

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 1d96bad5..db91ee66 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -77,6 +77,7 @@ export 'src/authoring/narrative_outcome_authoring_operations.dart';
 export 'src/authoring/narrative_predicate_authoring_draft.dart';
 export 'src/authoring/narrative_scenario_authoring_draft.dart';
 export 'src/authoring/narrative_validator_authoring_adapter.dart';
+export 'src/authoring/storyline_legacy_import_preview.dart';
 export 'src/read_models/narrative_reference_picker_read_models.dart';
 export 'src/operations/static_shadow_geometry.dart';
 export 'src/operations/static_shadow_family_projection.dart';
```

### Diff complet de road_map_storylines.md

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 6f1058db..90fd844b 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -307,7 +307,7 @@ Interprétation V0 :
 | NS-STORYLINES-V1-03 | StorylineAsset Pure Model V0 | core model / pure dart | DONE | NS-STORYLINES-V1-04 |
 | NS-STORYLINES-V1-04 | StorylineAsset JSON Codec V0 | core codec | DONE | NS-STORYLINES-V1-05 |
 | NS-STORYLINES-V1-05 | ProjectManifest.storylines Integration V0 | core manifest | DONE | NS-STORYLINES-V1-06 |
-| NS-STORYLINES-V1-06 | Legacy GlobalStory Import Preview V0 | migration preview | TODO | NS-STORYLINES-V1-07 |
+| NS-STORYLINES-V1-06 | Legacy GlobalStory Import Preview V0 | migration preview | DONE | NS-STORYLINES-V1-07 |
 | NS-STORYLINES-V1-07 | Create Main Storyline Flow V0 | editor authoring | TODO | NS-STORYLINES-V1-08 |
 
 ## 9. Detailed lots
@@ -707,6 +707,24 @@ Interprétation V0 :
 - Statut : DONE.
 - Prochain lot attendu : NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0.
 
+### NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0
+
+- Type : core authoring / pure Dart / legacy preview / tests.
+- Objectif : proposer une preview non destructive de conversion des anciens `ScenarioAsset(scope == globalStory)` vers des `StorylineAsset(type: main)` drafts.
+- Résultat : API pure `buildLegacyGlobalStoryImportPreview(ProjectManifest)` livrée dans `map_core`.
+- Mapping : chaque `globalStory` legacy produit un candidat draft `StorylineAsset` avec id déterministe `legacy_<scenario.id>`, type `main`, status `draft`, titre/description issus du scénario et `legacySource.kind = scenario.globalStory`.
+- Metadata legacy : chapitres et steps sont importés quand les metadata `authoring.globalStoryStudioDocument` et `authoring.stepStudioDocument` sont lisibles ; sinon le candidat reste minimal avec issues stables.
+- Diagnostics : issues stables via `StorylineValidationIssue` pour aucun globalStory, multiples globalStory, storylines existantes, collision d'id, metadata absente/invalide, step manquante, step non assignée, outcomes non mappés et `localEventFlow` ignoré.
+- Non-mutation : la preview ne modifie jamais `ProjectManifest`, `ProjectManifest.storylines`, `ProjectManifest.scenarios` ou les assets existants.
+- Non-promotion : `ScenarioAsset(scope == localEventFlow)` est explicitement ignoré et ne devient jamais une `sideQuest`.
+- Fichiers créés/modifiés : `packages/map_core/lib/src/authoring/storyline_legacy_import_preview.dart`, `packages/map_core/test/storyline_legacy_import_preview_test.dart`, `packages/map_core/lib/map_core.dart`, `reports/narrativeStudio/storylines/ns_storylines_v1_06_legacy_global_story_import_preview_v0.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
+- Tests exécutés : `dart test test/storyline_legacy_import_preview_test.dart`, `dart test test/project_manifest_storylines_test.dart`, `dart test test/storyline_asset_json_test.dart`, `dart test test/storyline_asset_test.dart`, `dart test test/scenario_assets_test.dart`, `dart test`.
+- Analyse exécutée : `dart analyze lib/src/authoring/storyline_legacy_import_preview.dart test/storyline_legacy_import_preview_test.dart`.
+- Non-objectifs confirmés : aucun `ProjectManifest` modifié, aucun `StorylineAsset` modifié, aucun `ScenarioAsset` modifié, aucun build_runner, aucune UI, aucun runtime, aucun import/apply mutateur.
+- Dépendances : NS-STORYLINES-V1-05.
+- Statut : DONE.
+- Prochain lot attendu : NS-STORYLINES-V1-07 — Create Main Storyline Flow V0.
+
 ## 10. Update protocol for every future lot
 
 Chaque futur lot Storylines doit :
@@ -823,10 +841,10 @@ Décision temporaire :
 ## 13. Current status
 
 ```text
-Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 MANIFEST STORYLINES DONE
-Current lot: NS-STORYLINES-V1-05
+Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 LEGACY IMPORT PREVIEW DONE
+Current lot: NS-STORYLINES-V1-06
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0
+Next recommended lot: NS-STORYLINES-V1-07 — Create Main Storyline Flow V0
 ```
 
 | Lot | Status | Last update | Notes |
@@ -851,7 +869,7 @@ Next recommended lot: NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview
 | NS-STORYLINES-V1-03 | DONE | 2026-05-28 | StorylineAsset Pure Model V0 livré dans `map_core`, sans JSON/manifest/UI. |
 | NS-STORYLINES-V1-04 | DONE | 2026-05-28 | StorylineAsset JSON Codec V0 livré, sans manifest/migration/UI. |
 | NS-STORYLINES-V1-05 | DONE | 2026-05-28 | ProjectManifest.storylines Integration V0 livré avec compatibilité vieux JSON et sans migration legacy. |
-| NS-STORYLINES-V1-06 | TODO | 2026-05-28 | Legacy GlobalStory Import Preview V0. |
+| NS-STORYLINES-V1-06 | DONE | 2026-05-28 | Legacy GlobalStory Import Preview V0 livré : candidats non destructifs depuis `globalStory`, issues stables, `localEventFlow` ignoré. |
 | NS-STORYLINES-V1-07 | TODO | 2026-05-28 | Create Main Storyline Flow V0. |
 
 ## 14. V1 Creation Readiness Notes
@@ -887,6 +905,16 @@ Suite V1 documentaire recommandée :
 
 ## 15. Changelog
 
+### 2026-05-28 — NS-STORYLINES-V1-06
+
+- Preview d'import legacy livrée dans `map_core` via `buildLegacyGlobalStoryImportPreview(ProjectManifest)`.
+- Les `ScenarioAsset(scope == globalStory)` produisent des candidats `StorylineAsset(type: main, status: draft)` sans mutation du manifest.
+- Les metadata legacy Global Story / Step Studio sont importées quand elles sont lisibles ; sinon des issues stables signalent les limites.
+- `localEventFlow` est explicitement ignoré et n'est jamais promu en `sideQuest`.
+- Tests ajoutés pour aucun / un / plusieurs globalStory, existing storylines, collision d'id, import chapters/steps, missing step, outcomes non mappés, invalid metadata et no-mutation JSON.
+- Non-objectifs respectés : aucun `ProjectManifest`, `StorylineAsset`, `ScenarioAsset`, generated file, build_runner, UI ou runtime modifié.
+- Prochain lot recommandé : `NS-STORYLINES-V1-07 — Create Main Storyline Flow V0`.
+
 ### 2026-05-28 — NS-STORYLINES-V1-05
 
 - `ProjectManifest.storylines: List<StorylineAsset>` intégré dans `map_core`.
```

### Sortie exacte dart format

```text
Formatted lib/src/authoring/storyline_legacy_import_preview.dart
Formatted test/storyline_legacy_import_preview_test.dart
Formatted 2 files (2 changed) in 0.01 seconds.
```

### Sorties exactes des tests ciblés

`cd packages/map_core && dart test --reporter json test/storyline_legacy_import_preview_test.dart | tail -n 1`

```text
{"success":true,"type":"done","time":461}
```

`cd packages/map_core && dart test --reporter json test/project_manifest_storylines_test.dart | tail -n 1`

```text
{"success":true,"type":"done","time":362}
```

`cd packages/map_core && dart test --reporter json test/storyline_asset_json_test.dart | tail -n 1`

```text
{"success":true,"type":"done","time":370}
```

`cd packages/map_core && dart test --reporter json test/storyline_asset_test.dart | tail -n 1`

```text
{"success":true,"type":"done","time":397}
```

`cd packages/map_core && dart test --reporter json test/scenario_assets_test.dart | tail -n 1`

```text
{"success":true,"type":"done","time":347}
```

### Sortie exacte de dart analyze

```text
Analyzing storyline_legacy_import_preview.dart, storyline_legacy_import_preview_test.dart...
No issues found!
```

### Sortie exacte du test complet map_core

`cd packages/map_core && dart test --reporter json | tail -n 1`

```text
{"success":true,"type":"done","time":5184}
```

### Git status final exact

```text
 M packages/map_core/lib/map_core.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? packages/map_core/lib/src/authoring/storyline_legacy_import_preview.dart
?? packages/map_core/test/storyline_legacy_import_preview_test.dart
?? reports/narrativeStudio/storylines/ns_storylines_v1_06_legacy_global_story_import_preview_v0.md
```

### Git diff --stat final

```text
 packages/map_core/lib/map_core.dart                |  1 +
 .../storylines/road_map_storylines.md              | 38 +++++++++++++++++++---
 2 files changed, 34 insertions(+), 5 deletions(-)
```

### Git diff --name-only final

```text
packages/map_core/lib/map_core.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

### Git diff --check final

```text
Sortie : <vide>
```

### Auto-review critique

- Scope : conforme, limité au fichier authoring, test, export public, roadmap et rapport.
- Mutation : aucune API d'application/import mutateur ajoutée ; tests JSON avant/après couvrent le no-mutation.
- Metadata legacy : parseur volontairement local et minimal, calé sur les clés JSON existantes ; pas de dépendance `map_editor` introduite dans `map_core`.
- Scene links/outcomes : non mappés volontairement faute de source de scène claire ; issue informative pour `declaredOutcomes`.
- `git diff --stat` / `git diff --name-only` ne listent pas les fichiers untracked par nature ; `git status final` les liste explicitement.
- Risque restant : la future application d'import devra gérer décisions UX de fusion/remplacement quand `manifest.storylines` existe déjà.

## 15. Self-review

Le pont legacy est prêt sans traversée automatique : un ancien `globalStory` devient un candidat lisible avec issues, le manifest reste intact, `localEventFlow` reste exclu, et les tests ciblés + test complet `map_core` passent. V1-07 peut se concentrer sur le flow de création principal sans mélanger migration et UI.
