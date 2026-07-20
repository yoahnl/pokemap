import 'package:map_core/map_core.dart';

import '../../../../application/services/narrative_activity_journal.dart';
import '../../../dialogue/application/dialogue_editor_validation.dart';
import '../cutscene_studio/cutscene_studio_models.dart';
import '../global_story_studio_authoring.dart';
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

enum NarrativeOverviewScopeKind {
  canonicalStoryline,
  legacyScenario,
  empty,
  ambiguous,
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
    required this.scope,
    required this.resumeTarget,
    required this.recentActivities,
    required this.diagnostics,
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
  final NarrativeOverviewScopeSummary scope;
  final NarrativeOverviewResumeTarget? resumeTarget;
  final List<NarrativeActivityEntry> recentActivities;
  final List<NarrativeOverviewDiagnosticSummary> diagnostics;
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
    required this.legacyRemaining,
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
  final NarrativeMetricSummary legacyRemaining;

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
        legacyRemaining,
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
    this.sourceLabel = 'Source indisponible',
  });

  final String id;
  final String label;
  final int? count;
  final NarrativeOverviewAvailability availability;
  final NarrativeOverviewSourceStatus sourceStatus;
  final String emptyStateMessage;
  final String unavailableMessage;
  final String sourceLabel;

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
      sourceLabel: sourceLabel,
    );
  }
}

class NarrativeOverviewScopeSummary {
  const NarrativeOverviewScopeSummary({
    required this.kind,
    required this.sourceLabel,
    required this.storylineCount,
    required this.sideQuestCount,
    this.storylineId,
    this.title,
  });

  final NarrativeOverviewScopeKind kind;
  final String sourceLabel;
  final int storylineCount;
  final int sideQuestCount;
  final String? storylineId;
  final String? title;
}

class NarrativeOverviewResumeTarget {
  const NarrativeOverviewResumeTarget({
    required this.label,
    required this.destination,
    required this.sourceLabel,
    this.assetId,
  });

  final String label;
  final NarrativeActivityDestination destination;
  final String sourceLabel;
  final String? assetId;
}

class NarrativeOverviewDiagnosticSummary {
  const NarrativeOverviewDiagnosticSummary(this.diagnostic);

  final NarrativeProjectDiagnostic diagnostic;

  bool get canQuickFix => diagnostic.hasDeterministicRepair;
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
    this.previewLabels = const <String>[],
    this.sourceLabel = 'ProjectManifest',
  });

  final String id;
  final String label;
  final String description;
  final int? count;
  final NarrativeOverviewAvailability availability;
  final String emptyStateMessage;
  final String? destination;
  final List<NarrativeMetricSummary> secondaryStats;
  final List<String> previewLabels;
  final String sourceLabel;
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
    required this.scope,
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
  final NarrativeOverviewScopeSummary scope;
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
  NarrativeActivityJournal? activityJournal,
  NarrativeOverviewAvailability activityJournalAvailability =
      NarrativeOverviewAvailability.notEvaluated,
  String? activityJournalStatusMessage,
  NarrativeProjectValidationReport? projectValidationReport,
  NarrativeOverviewAvailability validatorAvailability =
      NarrativeOverviewAvailability.notEvaluated,
  String? validatorStatusMessage,
  NarrativeValidationReport? narrativeValidationReport,
  List<NarrativeAuthoringDiagnosticView> authoringDiagnostics =
      const <NarrativeAuthoringDiagnosticView>[],
  List<DialogueValidationIssue> dialogueIssues =
      const <DialogueValidationIssue>[],
}) {
  final canonicalMainStories = project.storylines
      .where((storyline) => storyline.type == StorylineType.main)
      .toList(growable: false);
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
  final worldRuleDiagnostics = diagnoseWorldRules(project);
  final validation = _buildEditorialStatus(
    projectValidationReport: projectValidationReport,
    narrativeValidationReport: narrativeValidationReport,
    authoringDiagnostics: authoringDiagnostics,
    dialogueIssues: dialogueIssues,
  );

  final mainStory = _buildMainStory(
    canonicalMainStories: canonicalMainStories,
    globalStories: globalStories,
    project: project,
    cutsceneScenarioIds: cutsceneScenarioIds,
    validationState: validation,
    authoringDiagnostics: authoringDiagnostics,
    narrativeValidationReport: narrativeValidationReport,
    projectValidationReport: projectValidationReport,
  );
  final scope = _buildScope(
    project: project,
    canonicalMainStories: canonicalMainStories,
    legacyGlobalStories: globalStories,
  );

  final chapters = _buildChaptersMetric(mainStory);
  final scenes = _metricWithCount(
    id: 'scenes',
    label: 'Scènes',
    count: project.scenes.length,
    emptyStateMessage: 'Aucune Scene authorée.',
    unavailableMessage: 'Scenes indisponibles.',
    sourceLabel: 'ProjectManifest.scenes',
  );
  final cutscenes = _metricWithCount(
    id: 'cutscenes',
    label: 'Cinématiques',
    count: project.cinematics.length,
    emptyStateMessage: 'Aucune CinematicAsset canonique.',
    unavailableMessage: 'Cinématiques indisponibles.',
    sourceLabel: 'ProjectManifest.cinematics',
  );
  final cinematicBridges = _metricWithCount(
    id: 'cinematic_bridges',
    label: 'Bridges legacy',
    count: cutsceneScenarioIds.length,
    emptyStateMessage: 'Aucun bridge legacy Scenario/Cutscene.',
    unavailableMessage: 'Bridges legacy indisponibles.',
    sourceLabel: 'ProjectManifest.scenarios (bridges Cutscene Studio)',
  );
  final dialogues = _metricWithCount(
    id: 'dialogues',
    label: 'Dialogues',
    count: project.dialogues.length,
    emptyStateMessage: 'Aucun dialogue défini.',
    unavailableMessage: 'Dialogues indisponibles.',
    sourceLabel: 'ProjectManifest.dialogues',
  );
  final conditions = _metricWithCount(
    id: 'conditions',
    label: 'Conditions narratives',
    count: _countNarrativeConditions(project, allSteps),
    emptyStateMessage: 'Aucune condition narrative définie.',
    unavailableMessage: 'Conditions narratives indisponibles.',
    sourceLabel: 'ProjectManifest.storylines + ProjectManifest.scenarios',
  );
  final worldRules = _metricWithCount(
    id: 'world_rules',
    label: 'Règles du monde',
    count: project.worldRules.length,
    emptyStateMessage: 'Aucune World Rule authorée.',
    unavailableMessage: 'Règles du monde indisponibles.',
    sourceLabel: 'ProjectManifest.worldRules',
  );
  final facts = _metricWithCount(
    id: 'facts',
    label: 'Facts',
    count: project.facts.length,
    emptyStateMessage: 'Aucun Fact authoré.',
    unavailableMessage: 'Facts indisponibles.',
    sourceLabel: 'ProjectManifest.facts',
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
          sourceLabel: 'Validator global non exécuté',
        )
      : _metricWithCount(
          id: 'open_issues',
          label: 'Problèmes ouverts',
          count: validation.blocking + validation.toReview,
          emptyStateMessage: 'Aucun problème ouvert détecté.',
          unavailableMessage: 'Problèmes ouverts indisponibles.',
          sourceLabel: projectValidationReport == null
              ? 'Validation narrative locale'
              : 'NarrativeProjectValidationReport.diagnostics',
        ).copyWithAvailability(NarrativeOverviewAvailability.available);
  final legacyScan = buildNarrativeLegacyMigrationScan(project);
  final legacyRemaining = _metricWithCount(
    id: 'legacy_remaining',
    label: 'Legacy restant',
    count: legacyScan.legacyRemainingCount,
    emptyStateMessage: 'Aucune source legacy Narrative restante.',
    unavailableMessage: 'Inventaire legacy indisponible.',
    sourceLabel: 'NarrativeLegacyMigrationScan schema 1',
  );

  final metrics = NarrativeOverviewMetrics(
    chapters: chapters,
    scenes: scenes,
    cutscenes: cutscenes,
    quests: _metricWithCount(
      id: 'quests',
      label: 'Quêtes annexes',
      count: project.storylines
          .where((storyline) => storyline.type == StorylineType.sideQuest)
          .length,
      emptyStateMessage: 'Aucune Storyline de type sideQuest.',
      unavailableMessage: 'Quêtes annexes indisponibles.',
      sourceLabel: 'ProjectManifest.storylines[type=sideQuest]',
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
      sourceLabel: 'Fichiers Yarn (non chargés par cette projection)',
    ),
    openIssues: openIssues,
    conditions: conditions,
    worldRules: worldRules,
    facts: facts,
    legacyRemaining: legacyRemaining,
  );

  final modules = _buildModules(
    metrics,
    cinematicBridges: cinematicBridges,
    worldRuleDiagnostics: worldRuleDiagnostics,
    worldRulePreviewLabels: [
      for (final rule in project.worldRules.take(3)) rule.label,
    ],
    factPreviewLabels: [
      for (final fact in project.facts.take(3)) fact.label,
    ],
  );
  final projectHealth = _buildProjectHealth(validation, metrics);
  final structureInspector = _buildStructureInspector(
    project: project,
    mainStory: mainStory,
    metrics: metrics,
    editorialStatus: validation,
    scope: scope,
  );
  final recentActivities = List<NarrativeActivityEntry>.unmodifiable(
    activityJournal?.entries.take(5) ?? const <NarrativeActivityEntry>[],
  );
  final diagnostics = List<NarrativeOverviewDiagnosticSummary>.unmodifiable(
    (projectValidationReport?.diagnostics ??
            const <NarrativeProjectDiagnostic>[])
        .take(8)
        .map(NarrativeOverviewDiagnosticSummary.new),
  );
  final resumeTarget = _buildResumeTarget(
    activityJournal: activityJournal,
    scope: scope,
  );

  return NarrativeOverviewReadModel(
    projectName: project.name,
    metrics: metrics,
    mainStory: mainStory,
    modules: modules,
    structureInspector: structureInspector,
    editorialStatus: validation,
    projectHealth: projectHealth,
    scope: scope,
    resumeTarget: resumeTarget,
    recentActivities: recentActivities,
    diagnostics: diagnostics,
    recentActivity: NarrativeOverviewFeatureSummary(
      id: 'recent_activity',
      label: 'Activité récente',
      availability: activityJournal == null
          ? activityJournalAvailability
          : recentActivities.isEmpty
              ? NarrativeOverviewAvailability.empty
              : NarrativeOverviewAvailability.available,
      message: activityJournal == null
          ? activityJournalStatusMessage ?? 'Journal d’activité non chargé.'
          : recentActivities.isEmpty
              ? 'Aucune activité d’authoring enregistrée.'
              : '${recentActivities.length} activité(s) d’authoring récente(s).',
    ),
    notifications: NarrativeOverviewFeatureSummary(
      id: 'notifications',
      label: 'Diagnostics Validator',
      availability: projectValidationReport == null
          ? validatorAvailability
          : diagnostics.isEmpty
              ? NarrativeOverviewAvailability.empty
              : NarrativeOverviewAvailability.available,
      message: projectValidationReport == null
          ? validatorStatusMessage ?? 'Validator global non exécuté.'
          : diagnostics.isEmpty
              ? 'Aucun diagnostic narratif ouvert.'
              : '${diagnostics.length} diagnostic(s) à examiner.',
    ),
    footer: _buildFooter(project),
  );
}

MainStoryOverviewSummary _buildMainStory({
  required List<StorylineAsset> canonicalMainStories,
  required List<ScenarioAsset> globalStories,
  required ProjectManifest project,
  required Set<String> cutsceneScenarioIds,
  required EditorialStatusSummary validationState,
  required List<NarrativeAuthoringDiagnosticView> authoringDiagnostics,
  required NarrativeValidationReport? narrativeValidationReport,
  required NarrativeProjectValidationReport? projectValidationReport,
}) {
  if (canonicalMainStories.length > 1) {
    return _ambiguousMainStory(
      'Plusieurs Storylines principales existent ; choisissez-en une.',
    );
  }
  if (canonicalMainStories.length == 1) {
    return _buildCanonicalMainStory(
      storyline: canonicalMainStories.single,
      project: project,
      validationState: validationState,
      projectValidationReport: projectValidationReport,
    );
  }
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
    return _ambiguousMainStory(
      'Plusieurs histoires legacy existent ; choisissez-en une.',
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
      sourceLabel: 'ScenarioAsset legacy + Step Studio metadata',
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
      sourceLabel: 'ScenarioAsset.bindings + ProjectManifest.dialogues',
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
            sourceLabel: 'Validation narrative locale non exécutée',
          )
        : _metricWithCount(
            id: 'main_story_open_issues',
            label: 'Problèmes ouverts',
            count: scopedIssues,
            emptyStateMessage: 'Aucun problème ouvert pour cette histoire.',
            unavailableMessage: 'Problèmes ouverts indisponibles.',
            sourceLabel: 'Validation narrative locale',
          ),
    canEdit: true,
    availability: NarrativeOverviewAvailability.available,
    sourceStatus: NarrativeOverviewSourceStatus.explicit,
    message: 'Source legacy : conversion vers Storyline recommandée.',
  );
}

MainStoryOverviewSummary _ambiguousMainStory(String message) {
  return MainStoryOverviewSummary(
    title: null,
    description: null,
    chapters: const <NarrativeChapterOverviewSummary>[],
    linkedScenes: const NarrativeMetricSummary(
      id: 'main_story_linked_scenes',
      label: 'Scènes liées',
      count: null,
      availability: NarrativeOverviewAvailability.unavailable,
      sourceStatus: NarrativeOverviewSourceStatus.ambiguous,
      emptyStateMessage: 'Aucune scène liée.',
      unavailableMessage:
          'Plusieurs histoires globales existent ; sélection explicite requise.',
    ),
    linkedDialogues: const NarrativeMetricSummary(
      id: 'main_story_linked_dialogues',
      label: 'Dialogues liés',
      count: null,
      availability: NarrativeOverviewAvailability.unavailable,
      sourceStatus: NarrativeOverviewSourceStatus.ambiguous,
      emptyStateMessage: 'Aucun dialogue lié.',
      unavailableMessage:
          'Plusieurs histoires globales existent ; sélection explicite requise.',
    ),
    openIssues: const NarrativeMetricSummary(
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
    message: message,
  );
}

MainStoryOverviewSummary _buildCanonicalMainStory({
  required StorylineAsset storyline,
  required ProjectManifest project,
  required EditorialStatusSummary validationState,
  required NarrativeProjectValidationReport? projectValidationReport,
}) {
  final chapters = storyline.chapters
      .map(
        (chapter) => NarrativeChapterOverviewSummary(
          id: chapter.id,
          label: chapter.title,
          description: chapter.description ?? '',
          order: chapter.order,
          stepCount: chapter.steps.length,
          status: _canonicalChapterStatus(
            chapter,
            storyline.status,
            validationState,
          ),
          sourceStatus: NarrativeOverviewSourceStatus.explicit,
        ),
      )
      .toList(growable: false)
    ..sort((left, right) => left.order.compareTo(right.order));
  final linkedScenarioIds = storyline.sceneLinks
      .where((link) => link.state == StorylineSceneLinkState.linkedScenario)
      .map((link) => link.sceneRef?.targetId)
      .whereType<String>()
      .toSet();
  final linkedDialogueIds = _collectDialogueIdsFromScenarios(
    project: project,
    scenarioIds: linkedScenarioIds,
  );
  final scopedIssues = projectValidationReport?.diagnostics
      .where((diagnostic) => diagnostic.storylineId == storyline.id)
      .length;

  return MainStoryOverviewSummary(
    title: storyline.title,
    description: storyline.description,
    chapters: chapters,
    linkedScenes: _metricWithCount(
      id: 'main_story_linked_scenes',
      label: 'Scènes liées',
      count: linkedScenarioIds.length,
      emptyStateMessage: 'Aucune scène liée à cette Storyline.',
      unavailableMessage: 'Scènes liées indisponibles.',
      sourceStatus: linkedScenarioIds.isEmpty
          ? NarrativeOverviewSourceStatus.missing
          : NarrativeOverviewSourceStatus.explicit,
      sourceLabel: 'StorylineAsset.sceneLinks',
    ),
    linkedDialogues: _metricWithCount(
      id: 'main_story_linked_dialogues',
      label: 'Dialogues liés',
      count: linkedDialogueIds.length,
      emptyStateMessage: 'Aucun dialogue lié aux scènes de cette Storyline.',
      unavailableMessage: 'Dialogues liés indisponibles.',
      sourceStatus: linkedDialogueIds.isEmpty
          ? NarrativeOverviewSourceStatus.missing
          : NarrativeOverviewSourceStatus.explicit,
      sourceLabel: 'StorylineAsset.sceneLinks + ScenarioAsset.bindings',
    ),
    openIssues: scopedIssues == null
        ? const NarrativeMetricSummary(
            id: 'main_story_open_issues',
            label: 'Problèmes ouverts',
            count: null,
            availability: NarrativeOverviewAvailability.notEvaluated,
            sourceStatus: NarrativeOverviewSourceStatus.missing,
            emptyStateMessage: 'Aucun problème ouvert.',
            unavailableMessage: 'Validator global non exécuté.',
            sourceLabel: 'NarrativeProjectValidationReport non chargé',
          )
        : _metricWithCount(
            id: 'main_story_open_issues',
            label: 'Problèmes ouverts',
            count: scopedIssues,
            emptyStateMessage: 'Aucun problème ouvert pour cette Storyline.',
            unavailableMessage: 'Problèmes ouverts indisponibles.',
            sourceLabel: 'NarrativeProjectValidationReport.diagnostics',
          ),
    canEdit: true,
    availability: NarrativeOverviewAvailability.available,
    sourceStatus: NarrativeOverviewSourceStatus.explicit,
    message: '',
  );
}

NarrativeChapterEditorialStatus _canonicalChapterStatus(
  StorylineChapter chapter,
  StorylineStatus storylineStatus,
  EditorialStatusSummary validation,
) {
  if (chapter.steps.isEmpty ||
      chapter.status == StorylineStatus.draft ||
      storylineStatus == StorylineStatus.draft) {
    return NarrativeChapterEditorialStatus.draft;
  }
  if (validation.notEvaluated) {
    return NarrativeChapterEditorialStatus.notEvaluated;
  }
  if (validation.blocking > 0 || validation.toReview > 0) {
    return NarrativeChapterEditorialStatus.inProgress;
  }
  return NarrativeChapterEditorialStatus.defined;
}

NarrativeOverviewScopeSummary _buildScope({
  required ProjectManifest project,
  required List<StorylineAsset> canonicalMainStories,
  required List<ScenarioAsset> legacyGlobalStories,
}) {
  final sideQuestCount = project.storylines
      .where((storyline) => storyline.type == StorylineType.sideQuest)
      .length;
  if (canonicalMainStories.length > 1) {
    return NarrativeOverviewScopeSummary(
      kind: NarrativeOverviewScopeKind.ambiguous,
      sourceLabel: 'ProjectManifest.storylines[type=main]',
      storylineCount: project.storylines.length,
      sideQuestCount: sideQuestCount,
    );
  }
  if (canonicalMainStories.length == 1) {
    final storyline = canonicalMainStories.single;
    return NarrativeOverviewScopeSummary(
      kind: NarrativeOverviewScopeKind.canonicalStoryline,
      sourceLabel: 'ProjectManifest.storylines',
      storylineCount: project.storylines.length,
      sideQuestCount: sideQuestCount,
      storylineId: storyline.id,
      title: storyline.title,
    );
  }
  if (legacyGlobalStories.length > 1) {
    return NarrativeOverviewScopeSummary(
      kind: NarrativeOverviewScopeKind.ambiguous,
      sourceLabel: 'ProjectManifest.scenarios[scope=globalStory] (legacy)',
      storylineCount: project.storylines.length,
      sideQuestCount: sideQuestCount,
    );
  }
  if (legacyGlobalStories.length == 1) {
    final legacy = legacyGlobalStories.single;
    return NarrativeOverviewScopeSummary(
      kind: NarrativeOverviewScopeKind.legacyScenario,
      sourceLabel: 'ProjectManifest.scenarios[scope=globalStory] (legacy)',
      storylineCount: project.storylines.length,
      sideQuestCount: sideQuestCount,
      storylineId: legacy.id,
      title: legacy.name,
    );
  }
  return NarrativeOverviewScopeSummary(
    kind: NarrativeOverviewScopeKind.empty,
    sourceLabel: 'ProjectManifest.storylines',
    storylineCount: project.storylines.length,
    sideQuestCount: sideQuestCount,
  );
}

NarrativeOverviewResumeTarget _buildResumeTarget({
  required NarrativeActivityJournal? activityJournal,
  required NarrativeOverviewScopeSummary scope,
}) {
  if (activityJournal != null && activityJournal.entries.isNotEmpty) {
    final latest = activityJournal.entries.first;
    return NarrativeOverviewResumeTarget(
      label: latest.label,
      destination: latest.destination,
      sourceLabel: 'Journal d’activité durable',
      assetId: latest.assetId,
    );
  }
  return NarrativeOverviewResumeTarget(
    label: switch (scope.kind) {
      NarrativeOverviewScopeKind.canonicalStoryline =>
        'Reprendre ${scope.title ?? 'la Storyline principale'}',
      NarrativeOverviewScopeKind.legacyScenario =>
        'Convertir ${scope.title ?? 'l’histoire legacy'}',
      NarrativeOverviewScopeKind.ambiguous => 'Choisir la Storyline principale',
      NarrativeOverviewScopeKind.empty => 'Créer la Storyline principale',
    },
    destination: NarrativeActivityDestination.storylines,
    sourceLabel: scope.sourceLabel,
    assetId: scope.storylineId,
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
      sourceLabel: 'Storyline principale ambiguë',
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
    sourceLabel: 'StorylineAsset.chapters / Global Story metadata (legacy)',
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
  String sourceLabel = 'ProjectManifest',
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
    sourceLabel: sourceLabel,
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

int _countNarrativeConditions(
  ProjectManifest project,
  List<StepStudioStep> steps,
) {
  var count = 0;
  for (final storyline in project.storylines) {
    for (final chapter in storyline.chapters) {
      for (final step in chapter.steps) {
        if (step.entryCondition != null) count++;
        if (step.completionCondition != null) count++;
      }
    }
    for (final relationship in storyline.relationships) {
      if (relationship.condition != null) count++;
      final availability = relationship.availability;
      if (availability?.availabilityCondition != null) count++;
      if (availability?.expiresCondition != null) count++;
    }
  }
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
  required NarrativeProjectValidationReport? projectValidationReport,
  required NarrativeValidationReport? narrativeValidationReport,
  required List<NarrativeAuthoringDiagnosticView> authoringDiagnostics,
  required List<DialogueValidationIssue> dialogueIssues,
}) {
  final validationRan = projectValidationReport != null ||
      narrativeValidationReport != null ||
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
  if (projectValidationReport != null) {
    blocking = projectValidationReport.errorCount;
    review = projectValidationReport.warningCount;
  } else if (authoringDiagnostics.isNotEmpty) {
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

  if (projectValidationReport == null) {
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
      projectValidationReport: projectValidationReport,
      narrativeValidationReport: narrativeValidationReport,
      authoringDiagnostics: authoringDiagnostics,
      dialogueIssues: dialogueIssues,
    ),
  );
}

String _diagnosticSourceSummary({
  required NarrativeProjectValidationReport? projectValidationReport,
  required NarrativeValidationReport? narrativeValidationReport,
  required List<NarrativeAuthoringDiagnosticView> authoringDiagnostics,
  required List<DialogueValidationIssue> dialogueIssues,
}) {
  final parts = <String>[];
  if (projectValidationReport != null) {
    parts.add(
      '${projectValidationReport.diagnostics.length} diagnostic(s) Validator global',
    );
  } else if (authoringDiagnostics.isNotEmpty) {
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

List<NarrativeModuleSummary> _buildModules(
  NarrativeOverviewMetrics metrics, {
  required NarrativeMetricSummary cinematicBridges,
  required WorldRuleDiagnosticsReport worldRuleDiagnostics,
  required List<String> worldRulePreviewLabels,
  required List<String> factPreviewLabels,
}) {
  return <NarrativeModuleSummary>[
    NarrativeModuleSummary(
      id: NarrativeOverviewModuleIds.quests,
      label: 'Quêtes annexes',
      description: 'Storylines secondaires et contenus narratifs facultatifs.',
      count: metrics.quests.count,
      availability: metrics.quests.availability,
      emptyStateMessage: metrics.quests.emptyStateMessage,
      destination: 'storylines',
      sourceLabel: metrics.quests.sourceLabel,
    ),
    NarrativeModuleSummary(
      id: NarrativeOverviewModuleIds.cutscenes,
      label: 'Cinématiques',
      description:
          'CinematicAsset canoniques et bridges legacy Cutscene Studio.',
      count: metrics.cutscenes.count,
      availability: metrics.cutscenes.availability,
      emptyStateMessage: metrics.cutscenes.emptyStateMessage,
      destination: 'cinematics_library',
      secondaryStats: <NarrativeMetricSummary>[cinematicBridges],
      sourceLabel: metrics.cutscenes.sourceLabel,
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
      sourceLabel: metrics.dialogues.sourceLabel,
    ),
    NarrativeModuleSummary(
      id: NarrativeOverviewModuleIds.conditions,
      label: 'Conditions narratives',
      description: 'Conditions, déclencheurs et dépendances de récit.',
      count: metrics.conditions.count,
      availability: metrics.conditions.availability,
      emptyStateMessage: metrics.conditions.emptyStateMessage,
      destination: 'step_studio',
      sourceLabel: metrics.conditions.sourceLabel,
    ),
    NarrativeModuleSummary(
      id: NarrativeOverviewModuleIds.worldRules,
      label: 'Règles du monde',
      description: 'Règles authorées qui changent la présence narrative.',
      count: metrics.worldRules.count,
      availability: metrics.worldRules.availability,
      emptyStateMessage: metrics.worldRules.emptyStateMessage,
      destination: 'world_rules_manager',
      secondaryStats: <NarrativeMetricSummary>[
        _worldRuleDiagnosticsMetric(worldRuleDiagnostics),
      ],
      previewLabels: worldRulePreviewLabels,
      sourceLabel: metrics.worldRules.sourceLabel,
    ),
    NarrativeModuleSummary(
      id: NarrativeOverviewModuleIds.facts,
      label: 'Facts',
      description: 'Faits persistants lisibles par les scènes et règles.',
      count: metrics.facts.count,
      availability: metrics.facts.availability,
      emptyStateMessage: metrics.facts.emptyStateMessage,
      destination: 'facts_manager',
      previewLabels: factPreviewLabels,
      sourceLabel: metrics.facts.sourceLabel,
    ),
  ];
}

NarrativeMetricSummary _worldRuleDiagnosticsMetric(
  WorldRuleDiagnosticsReport report,
) {
  final issueCount = report.errorCount + report.warningCount;
  return NarrativeMetricSummary(
    id: 'world_rule_diagnostics',
    label: 'Diagnostics',
    count: issueCount,
    availability: issueCount == 0
        ? NarrativeOverviewAvailability.empty
        : NarrativeOverviewAvailability.available,
    sourceStatus: report.hasDiagnostics
        ? NarrativeOverviewSourceStatus.explicit
        : NarrativeOverviewSourceStatus.missing,
    emptyStateMessage: 'Aucun diagnostic World Rule.',
    unavailableMessage: 'Diagnostics World Rules indisponibles.',
    sourceLabel: 'diagnoseWorldRules(ProjectManifest.worldRules)',
  );
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
  required NarrativeOverviewScopeSummary scope,
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
    scope: scope,
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
      sourceLabel: 'ProjectManifest.name',
    ),
    locale: const NarrativeMetricSummary(
      id: 'footer_locale',
      label: 'Locale',
      count: null,
      availability: NarrativeOverviewAvailability.unavailable,
      sourceStatus: NarrativeOverviewSourceStatus.missing,
      emptyStateMessage: 'Locale non définie.',
      unavailableMessage: 'Locale non définie.',
      sourceLabel: 'Project metadata (absente)',
    ),
    version: const NarrativeMetricSummary(
      id: 'footer_version',
      label: 'Version',
      count: null,
      availability: NarrativeOverviewAvailability.unavailable,
      sourceStatus: NarrativeOverviewSourceStatus.missing,
      emptyStateMessage: 'Version non définie.',
      unavailableMessage: 'Version non définie.',
      sourceLabel: 'Project metadata (absente)',
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
