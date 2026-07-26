import 'package:map_core/map_core.dart';

final class ProjectGameplayReadinessCollection {
  const ProjectGameplayReadinessCollection({
    required this.report,
    required this.issues,
  });

  final ProjectGameplayReadinessReport report;
  final List<String> issues;

  bool get isReady => issues.isEmpty && report.isPlayable;
}

/// Host-side FG-180 collector joining disk/execution provenance to pure Core.
final class ProjectGameplayReadinessCollector {
  const ProjectGameplayReadinessCollector();

  ProjectGameplayReadinessCollection collect({
    required ProjectManifest project,
    required MvpReleaseEvidenceReceipt receipt,
    required String expectedCommit,
    required String actualProjectTreeHashSha256,
    required Iterable<ProjectCapabilityTruthRecord> capabilityTruth,
  }) {
    final issues = <String>[];
    final capabilityTruthReport = ProjectCapabilityTruthReport.evaluate(
      capabilityTruth,
      requiredCapabilityIds: requiredNarrativeCommandCapabilityIds(),
    );
    for (final issue in capabilityTruthReport.issues) {
      issues.add(
        'Capability truth ${issue.code.name} for '
        '${issue.capabilityId}: ${issue.message}',
      );
    }
    if (receipt.releaseCandidateCommit != expectedCommit.toLowerCase()) {
      issues.add(
        'Receipt commit ${receipt.releaseCandidateCommit} does not match '
        'expected commit ${expectedCommit.toLowerCase()}.',
      );
    }
    if (receipt.projectTreeHashSha256 !=
        actualProjectTreeHashSha256.toLowerCase()) {
      issues.add(
        'Receipt project tree hash does not match the current project tree hash.',
      );
    }
    if (receipt.exitCode != 0) {
      issues.add('Journey command failed with exit code ${receipt.exitCode}.');
    }

    final byCriterion =
        <MvpProductCriterion, List<MvpProductCriterionEvidence>>{};
    for (final observation in receipt.criteria) {
      byCriterion
          .putIfAbsent(
              observation.criterion, () => <MvpProductCriterionEvidence>[])
          .add(observation);
    }
    for (final criterion in MvpProductCriterion.values) {
      final count = byCriterion[criterion]?.length ?? 0;
      if (count == 0) {
        issues.add('Missing executed observation for ${criterion.id}.');
      } else if (count > 1) {
        issues.add('Duplicate executed observations for ${criterion.id}.');
      }
    }

    final provenanceFailed = issues.isNotEmpty;
    final effectiveProductEvidence = receipt.criteria
        .map(
          (evidence) => provenanceFailed
              ? MvpProductCriterionEvidence(
                  criterion: evidence.criterion,
                  status: MvpProductCriterionStatus.failed,
                  summary: '${evidence.summary} Receipt provenance is invalid.',
                  source: evidence.source,
                )
              : evidence,
        )
        .toList(growable: false);
    final report = ProjectGameplayReadinessReport.evaluateProductCriteria(
      productEvidence: effectiveProductEvidence,
      projectEvidence: _inspectProject(
        project,
        capabilityTruth: capabilityTruthReport,
      ),
    );
    return ProjectGameplayReadinessCollection(
      report: report,
      issues: List.unmodifiable(issues),
    );
  }
}

List<ProjectGameplayReadinessEvidence> _inspectProject(
  ProjectManifest project, {
  required ProjectCapabilityTruthReport capabilityTruth,
}) {
  final mapIds = project.maps.map((map) => map.id).toSet();
  final hasStartState = project.newGame.enabled &&
      project.newGame.startMapId.trim().isNotEmpty &&
      mapIds.contains(project.newGame.startMapId);
  final hasStarter = project.newGame.starterOptions.isNotEmpty &&
      (project.newGame.starterSelectionSceneId?.trim().isNotEmpty ?? false);
  final hasPlayablePartyPath =
      hasStarter || project.newGame.initialParty.isNotEmpty;
  final hasEncounterTables = project.encounterTables.isNotEmpty;
  final hasTrainers = project.trainers.isNotEmpty;
  final hasShopItems = project.shops.any((shop) => shop.entries.isNotEmpty);
  final sceneNodes =
      project.scenes.expand((scene) => scene.graph.nodes).toList();
  final hasEventCommands = sceneNodes.any(
    (node) => node.kind == SceneNodeKind.action,
  );
  final hasConditionalProgression = project.facts.isNotEmpty &&
      sceneNodes.any((node) => node.kind == SceneNodeKind.condition);
  final hasFieldAbilityUnlock = sceneNodes.any((node) {
    final payload = node.payload;
    return payload is SceneActionPayload &&
        payload.consequence?.kind == SceneConsequenceKind.unlockFieldAbility;
  });
  final hasStoryEnd = project.storylines.isNotEmpty &&
      project.scenes.any(
        (scene) => scene.graph.nodes.any(
          (node) =>
              node.kind == SceneNodeKind.end && node.payload is SceneEndPayload,
        ),
      );
  final checks =
      <ProjectGameplayReadinessCheck, ({bool passed, String detail})>{
    ProjectGameplayReadinessCheck.startState: (
      passed: hasStartState,
      detail: 'New Game references an existing start map.',
    ),
    ProjectGameplayReadinessCheck.starterConfiguration: (
      passed: hasStarter,
      detail: 'Starter options and their selection Scene are authored.',
    ),
    ProjectGameplayReadinessCheck.playablePartyPath: (
      passed: hasPlayablePartyPath && project.maps.length >= 3,
      detail: 'A party path and at least three project maps are authored.',
    ),
    ProjectGameplayReadinessCheck.encounterTables: (
      passed: hasEncounterTables,
      detail: 'Encounter tables are present.',
    ),
    ProjectGameplayReadinessCheck.trainerReferences: (
      passed: hasTrainers,
      detail: 'Trainer definitions are present.',
    ),
    ProjectGameplayReadinessCheck.shopItems: (
      passed: hasShopItems,
      detail: 'At least one shop has an item.',
    ),
    ProjectGameplayReadinessCheck.eventCommands: (
      passed: hasEventCommands &&
          project.dialogues.isNotEmpty &&
          capabilityTruth.isPassing,
      detail: capabilityTruth.isPassing
          ? 'Scene actions and dialogue assets are authored; every promoted '
              'command has authoring, contract, runtime, player and test proof.'
          : 'Capability truth gate failed: '
              '${capabilityTruth.issues.map((issue) => issue.code.name).join(', ')}.',
    ),
    ProjectGameplayReadinessCheck.requiredFlagsReachable: (
      passed: hasConditionalProgression,
      detail: 'Facts and conditional Scene nodes are authored.',
    ),
    ProjectGameplayReadinessCheck.fieldAbilityUnlockReachable: (
      passed: hasFieldAbilityUnlock,
      detail: 'A typed field-ability unlock consequence is authored.',
    ),
    ProjectGameplayReadinessCheck.storyEndReachable: (
      passed: hasStoryEnd,
      detail: 'Storylines and Scene terminal nodes are authored.',
    ),
    ProjectGameplayReadinessCheck.battleBridgeCoverage: (
      passed: hasEncounterTables && hasTrainers,
      detail: 'Wild encounter and trainer battle inputs are authored.',
    ),
  };
  return checks.entries
      .map(
        (entry) => ProjectGameplayReadinessEvidence(
          check: entry.key,
          status: entry.value.passed
              ? ProjectGameplayReadinessEvidenceStatus.passed
              : ProjectGameplayReadinessEvidenceStatus.failed,
          summary: entry.value.passed
              ? entry.value.detail
              : 'Project inspection failed: ${entry.value.detail}',
          source: 'project.json',
        ),
      )
      .toList(growable: false);
}
