import 'dart:collection';

import 'package:meta/meta.dart' show immutable;

import '../models/cinematic_asset.dart';
import '../models/project_manifest.dart';
import '../models/scenario_asset.dart';
import '../models/scene_asset.dart';
import 'legacy_scenario_source_projection.dart';

const _cutsceneSchemaKey = 'authoring.cutsceneSchema';
const _sourceScenarioKey = 'migration.sourceScenarioId';
const _migrationSchemaKey = 'migration.schemaVersion';
const _migrationSchemaVersion = '1';

enum CinematicLegacyMigrationCandidateStatus {
  ready,
  alreadyMigrated,
  blocked,
}

enum CinematicLegacyMigrationDisposition { migrated, noChange, rejected }

@immutable
final class CinematicLegacyMigrationCandidate {
  CinematicLegacyMigrationCandidate({
    required this.sourceScenarioId,
    required this.sourceTitle,
    required this.targetCinematicId,
    required this.status,
    required this.draft,
    required this.sceneReferenceCount,
    required List<String> lossRisks,
    required List<String> dependencies,
  })  : lossRisks = List.unmodifiable(lossRisks),
        dependencies = List.unmodifiable(dependencies);

  final String sourceScenarioId;
  final String sourceTitle;
  final String targetCinematicId;
  final CinematicLegacyMigrationCandidateStatus status;
  final CinematicAsset draft;
  final int sceneReferenceCount;
  final List<String> lossRisks;
  final List<String> dependencies;

  bool get canApply => status == CinematicLegacyMigrationCandidateStatus.ready;
}

@immutable
final class CinematicLegacyMigrationPlan {
  CinematicLegacyMigrationPlan({
    required List<CinematicLegacyMigrationCandidate> candidates,
  }) : candidates = List.unmodifiable(candidates);

  final List<CinematicLegacyMigrationCandidate> candidates;

  int get readyCount => candidates.where((item) => item.canApply).length;

  int get alreadyMigratedCount => candidates
      .where(
        (item) =>
            item.status ==
            CinematicLegacyMigrationCandidateStatus.alreadyMigrated,
      )
      .length;

  int get blockedCount => candidates
      .where(
        (item) =>
            item.status == CinematicLegacyMigrationCandidateStatus.blocked,
      )
      .length;

  int get lossRiskCount =>
      candidates.fold(0, (sum, item) => sum + item.lossRisks.length);
}

CinematicLegacyMigrationPlan buildCinematicLegacyMigrationPlan(
  ProjectManifest project,
) {
  final canonicalById = {
    for (final cinematic in project.cinematics) cinematic.id: cinematic,
  };
  final candidates = <CinematicLegacyMigrationCandidate>[];
  for (final scenario in project.scenarios) {
    final schema = scenario.metadata[_cutsceneSchemaKey]?.trim();
    if (schema == null || schema.isEmpty) continue;

    final targetId = _cinematicIdFor(scenario.id);
    final existing = canonicalById[targetId];
    final alreadyMigrated = existing?.metadata[_sourceScenarioKey] ==
            scenario.id &&
        existing?.metadata[_migrationSchemaKey] == _migrationSchemaVersion &&
        existing?.legacyBridge?.scenarioId == scenario.id;
    final lossRisks = <String>[
      if (scenario.nodes.isNotEmpty)
        'Le flow Scenario contient ${scenario.nodes.length} nœud(s) dont la '
            'conversion Cinematic n’est pas attestée.',
      if (scenario.edges.isNotEmpty)
        'Le flow Scenario contient ${scenario.edges.length} transition(s) '
            'dont la linéarisation n’est pas attestée.',
    ];
    final dependencies = <String>{
      for (final node in scenario.nodes) ...[
        if (node.binding.mapId case final String mapId) 'map:$mapId',
        if (node.binding.entityId case final String entityId)
          'entity:$entityId',
        if (node.binding.dialogueId case final String dialogueId)
          'dialogue:$dialogueId',
        if (node.binding.scriptId case final String scriptId)
          'script:$scriptId',
      ],
    }.toList()
      ..sort();
    final sceneReferences = _countSceneReferences(project, scenario.id);
    final status = alreadyMigrated
        ? CinematicLegacyMigrationCandidateStatus.alreadyMigrated
        : existing != null || lossRisks.isNotEmpty
            ? CinematicLegacyMigrationCandidateStatus.blocked
            : CinematicLegacyMigrationCandidateStatus.ready;
    final draft = existing ??
        CinematicAsset(
          id: targetId,
          title: scenario.name.trim().isEmpty ? scenario.id : scenario.name,
          description: scenario.description.trim().isEmpty
              ? 'Migration du Cutscene Studio legacy ${scenario.id}.'
              : scenario.description,
          timeline: CinematicTimeline(),
          notes:
              'Source legacy conservée pour rollback. Vérifier la timeline avant publication.',
          metadata: {
            _sourceScenarioKey: scenario.id,
            _migrationSchemaKey: _migrationSchemaVersion,
            'migration.sourceFingerprint': _scenarioFingerprint(scenario),
          },
          legacyBridge: CinematicLegacyBridge(
            sourceKind: CinematicLegacyBridgeSourceKind.cutsceneStudio,
            scenarioId: scenario.id,
            cutsceneSchema: schema,
            notes: 'Bridge visible jusqu’à validation puis retrait du reader.',
          ),
        );
    candidates.add(
      CinematicLegacyMigrationCandidate(
        sourceScenarioId: scenario.id,
        sourceTitle: scenario.name,
        targetCinematicId: targetId,
        status: status,
        draft: draft,
        sceneReferenceCount: sceneReferences,
        lossRisks: lossRisks,
        dependencies: dependencies,
      ),
    );
  }
  candidates.sort(
    (left, right) => left.sourceScenarioId.compareTo(right.sourceScenarioId),
  );
  return CinematicLegacyMigrationPlan(candidates: candidates);
}

@immutable
final class CinematicLegacyMigrationResult {
  const CinematicLegacyMigrationResult({
    required this.before,
    required this.after,
    required this.disposition,
    this.message,
  });

  final ProjectManifest before;
  final ProjectManifest after;
  final CinematicLegacyMigrationDisposition disposition;
  final String? message;

  ProjectManifest rollback() => before;
}

CinematicLegacyMigrationResult applyCinematicLegacyMigration(
  ProjectManifest project,
  CinematicLegacyMigrationCandidate candidate,
) {
  if (candidate.status ==
      CinematicLegacyMigrationCandidateStatus.alreadyMigrated) {
    return CinematicLegacyMigrationResult(
      before: project,
      after: project,
      disposition: CinematicLegacyMigrationDisposition.noChange,
      message: 'Cette source possède déjà un reçu de migration canonique.',
    );
  }
  if (!candidate.canApply || candidate.lossRisks.isNotEmpty) {
    return CinematicLegacyMigrationResult(
      before: project,
      after: project,
      disposition: CinematicLegacyMigrationDisposition.rejected,
      message: 'La preview contient une collision ou un risque de perte.',
    );
  }
  final currentPlan = buildCinematicLegacyMigrationPlan(project);
  final current = currentPlan.candidates.where(
    (item) => item.sourceScenarioId == candidate.sourceScenarioId,
  );
  if (current.length != 1 ||
      !current.single.canApply ||
      current.single.targetCinematicId != candidate.targetCinematicId) {
    return CinematicLegacyMigrationResult(
      before: project,
      after: project,
      disposition: CinematicLegacyMigrationDisposition.rejected,
      message: 'Le projet a changé depuis la preview. Relancer le dry-run.',
    );
  }

  try {
    final after = project.copyWith(
      cinematics: [...project.cinematics, candidate.draft],
      scenes: [
        for (final scene in project.scenes)
          _rewriteSceneCinematicReference(
            scene,
            fromId: candidate.sourceScenarioId,
            toId: candidate.targetCinematicId,
          ),
      ],
    );
    return CinematicLegacyMigrationResult(
      before: project,
      after: after,
      disposition: CinematicLegacyMigrationDisposition.migrated,
    );
  } on Object catch (error) {
    return CinematicLegacyMigrationResult(
      before: project,
      after: project,
      disposition: CinematicLegacyMigrationDisposition.rejected,
      message: 'Projection invalide : $error',
    );
  }
}

enum NarrativeLegacyDomain { storyline, event, cinematic }

@immutable
final class NarrativeLegacyMigrationDomainScan {
  const NarrativeLegacyMigrationDomainScan({
    required this.domain,
    required this.remainingCount,
    required this.readyCount,
    required this.blockerCount,
    required this.lossRiskCount,
    required this.dependencyCount,
  });

  final NarrativeLegacyDomain domain;
  final int remainingCount;
  final int readyCount;
  final int blockerCount;
  final int lossRiskCount;
  final int dependencyCount;
}

@immutable
final class NarrativeLegacyMigrationScan {
  NarrativeLegacyMigrationScan({
    required this.schemaVersion,
    required this.minimumProjectVersion,
    required List<NarrativeLegacyMigrationDomainScan> domains,
  }) : domains = List.unmodifiable(domains);

  final int schemaVersion;
  final String minimumProjectVersion;
  final List<NarrativeLegacyMigrationDomainScan> domains;

  NarrativeLegacyMigrationDomainScan domain(NarrativeLegacyDomain domain) =>
      domains.singleWhere((item) => item.domain == domain);

  int get legacyRemainingCount =>
      domains.fold(0, (sum, item) => sum + item.remainingCount);

  int get blockerCount =>
      domains.fold(0, (sum, item) => sum + item.blockerCount);

  int get lossRiskCount =>
      domains.fold(0, (sum, item) => sum + item.lossRiskCount);

  bool get backupRequired => legacyRemainingCount > 0;

  bool get canApply =>
      legacyRemainingCount > 0 && blockerCount == 0 && lossRiskCount == 0;

  bool get canRetireLegacyReaders => legacyRemainingCount == 0;
}

NarrativeLegacyMigrationScan buildNarrativeLegacyMigrationScan(
  ProjectManifest project, {
  int legacyMapEventCount = 0,
  int eventBlockerCount = 0,
}) {
  if (legacyMapEventCount < 0 || eventBlockerCount < 0) {
    throw ArgumentError('Legacy counters cannot be negative.');
  }
  final importedStories = {
    for (final storyline in project.storylines)
      if (storyline.legacySource?.metadata['imported'] == 'true')
        storyline.legacySource?.sourceId,
  };
  final remainingStories = project.scenarios
      .where((scenario) => scenario.scope == ScenarioScope.globalStory)
      .where((scenario) => !importedStories.contains(scenario.id))
      .length;
  final cinematicPlan = buildCinematicLegacyMigrationPlan(project);
  final legacyScenarioEventSourceCount = project.scenarios.fold<int>(
    0,
    (sum, scenario) =>
        sum + scenario.nodes.where(isLegacyScenarioSourceNode).length,
  );
  final legacyEventClaimCount = project.eventRegistry?.legacyClaims.length ?? 0;
  final eventRemainingCount = legacyMapEventCount +
      legacyScenarioEventSourceCount +
      legacyEventClaimCount;
  final remainingCinematics = cinematicPlan.candidates
      .where(
        (candidate) =>
            candidate.status !=
            CinematicLegacyMigrationCandidateStatus.alreadyMigrated,
      )
      .length;
  return NarrativeLegacyMigrationScan(
    schemaVersion: 1,
    minimumProjectVersion: 'v1',
    domains: [
      NarrativeLegacyMigrationDomainScan(
        domain: NarrativeLegacyDomain.storyline,
        remainingCount: remainingStories,
        readyCount: remainingStories,
        blockerCount: 0,
        lossRiskCount: 0,
        dependencyCount: 0,
      ),
      NarrativeLegacyMigrationDomainScan(
        domain: NarrativeLegacyDomain.event,
        remainingCount: eventRemainingCount,
        readyCount: eventBlockerCount == 0 ? eventRemainingCount : 0,
        blockerCount: eventBlockerCount,
        lossRiskCount: eventBlockerCount,
        dependencyCount: legacyEventClaimCount,
      ),
      NarrativeLegacyMigrationDomainScan(
        domain: NarrativeLegacyDomain.cinematic,
        remainingCount: remainingCinematics,
        readyCount: cinematicPlan.readyCount,
        blockerCount: cinematicPlan.blockedCount,
        lossRiskCount: cinematicPlan.lossRiskCount,
        dependencyCount: cinematicPlan.candidates.fold(
          0,
          (sum, item) => sum + item.dependencies.length,
        ),
      ),
    ],
  );
}

enum NarrativeLegacyTransactionStatus { active, interrupted }

@immutable
final class NarrativeLegacyMigrationTransaction {
  NarrativeLegacyMigrationTransaction._({
    required this.original,
    required this.current,
    required this.status,
    required List<NarrativeLegacyDomain> completedDomains,
    this.interruptionMessage,
  }) : completedDomains = List.unmodifiable(completedDomains);

  factory NarrativeLegacyMigrationTransaction.start(ProjectManifest project) =>
      NarrativeLegacyMigrationTransaction._(
        original: project,
        current: project,
        status: NarrativeLegacyTransactionStatus.active,
        completedDomains: const [],
      );

  final ProjectManifest original;
  final ProjectManifest current;
  final NarrativeLegacyTransactionStatus status;
  final List<NarrativeLegacyDomain> completedDomains;
  final String? interruptionMessage;

  NarrativeLegacyMigrationTransaction applyDomain(
    NarrativeLegacyDomain domain,
    ProjectManifest Function(ProjectManifest current) operation,
  ) {
    if (status != NarrativeLegacyTransactionStatus.active) {
      throw StateError(
          'Resume the transaction before applying another domain.');
    }
    if (completedDomains.contains(domain)) {
      return this;
    }
    try {
      final next = operation(current);
      return NarrativeLegacyMigrationTransaction._(
        original: original,
        current: next,
        status: NarrativeLegacyTransactionStatus.active,
        completedDomains: [...completedDomains, domain],
      );
    } on Object catch (error) {
      return NarrativeLegacyMigrationTransaction._(
        original: original,
        current: current,
        status: NarrativeLegacyTransactionStatus.interrupted,
        completedDomains: completedDomains,
        interruptionMessage: '$error',
      );
    }
  }

  NarrativeLegacyMigrationTransaction resume() {
    if (status == NarrativeLegacyTransactionStatus.active) return this;
    return NarrativeLegacyMigrationTransaction._(
      original: original,
      current: current,
      status: NarrativeLegacyTransactionStatus.active,
      completedDomains: completedDomains,
    );
  }

  ProjectManifest rollback() => original;
}

int _countSceneReferences(ProjectManifest project, String sourceId) =>
    project.scenes
        .expand((scene) => scene.graph.nodes)
        .where(
          (node) =>
              node.payload is SceneCinematicPayload &&
              (node.payload as SceneCinematicPayload).cinematicId == sourceId,
        )
        .length;

SceneAsset _rewriteSceneCinematicReference(
  SceneAsset scene, {
  required String fromId,
  required String toId,
}) {
  var changed = false;
  final nodes = [
    for (final node in scene.graph.nodes)
      if (node.payload is SceneCinematicPayload &&
          (node.payload as SceneCinematicPayload).cinematicId == fromId)
        (() {
          changed = true;
          return SceneNode(
            id: node.id,
            kind: node.kind,
            title: node.title,
            description: node.description,
            payload: SceneCinematicPayload(cinematicId: toId),
          );
        })()
      else
        node,
  ];
  if (!changed) return scene;
  return SceneAsset(
    id: scene.id,
    name: scene.name,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: nodes,
      edges: scene.graph.edges,
    ),
    layout: scene.layout,
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );
}

String _cinematicIdFor(String sourceId) {
  final normalized = sourceId
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9_]+'), '_')
      .replaceAll(RegExp('_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return 'cinematic_${normalized.isEmpty ? 'legacy' : normalized}';
}

String _scenarioFingerprint(ScenarioAsset scenario) {
  final values = <String>[
    scenario.id,
    scenario.name,
    scenario.description,
    scenario.entryNodeId,
    scenario.nodes.length.toString(),
    scenario.edges.length.toString(),
    ...SplayTreeMap<String, String>.from(scenario.metadata).entries.map(
          (entry) => '${entry.key}=${entry.value}',
        ),
  ];
  var hash = 0x811c9dc5;
  for (final unit in values.join('\u0000').codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
