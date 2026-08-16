import 'package:meta/meta.dart' show immutable;

import '../models/project_manifest.dart';
import '../models/scenario_asset.dart';
import 'legacy_scenario_source_projection.dart';

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
  final legacyScenarioEventSourceCount = project.scenarios.fold<int>(
    0,
    (sum, scenario) =>
        sum + scenario.nodes.where(isLegacyScenarioSourceNode).length,
  );
  final legacyEventClaimCount = project.eventRegistry?.legacyClaims.length ?? 0;
  final eventRemainingCount =
      legacyMapEventCount +
      legacyScenarioEventSourceCount +
      legacyEventClaimCount;
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
      const NarrativeLegacyMigrationDomainScan(
        domain: NarrativeLegacyDomain.cinematic,
        remainingCount: 0,
        readyCount: 0,
        blockerCount: 0,
        lossRiskCount: 0,
        dependencyCount: 0,
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
        'Resume the transaction before applying another domain.',
      );
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
