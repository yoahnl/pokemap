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
