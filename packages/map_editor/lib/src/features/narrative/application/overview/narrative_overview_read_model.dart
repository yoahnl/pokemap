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
