import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('does not expose removed cinematic migration candidates', () {
    final project = ProjectManifest(
      name: 'legacy_project',
      maps: const [],
      tilesets: const [],
      scenarios: const [
        ScenarioAsset(
          id: 'story',
          name: 'Story',
          scope: ScenarioScope.globalStory,
          entryNodeId: 'start',
        ),
        ScenarioAsset(
          id: 'intro',
          name: 'Intro legacy',
          entryNodeId: 'start',
          metadata: {'authoring.cutsceneSchema': 'cutscene-studio-v0'},
        ),
      ],
    );

    final scan = buildNarrativeLegacyMigrationScan(
      project,
      legacyMapEventCount: 2,
      eventBlockerCount: 1,
    );

    expect(scan.legacyRemainingCount, 3);
    expect(scan.domain(NarrativeLegacyDomain.storyline).remainingCount, 1);
    expect(scan.domain(NarrativeLegacyDomain.event).remainingCount, 2);
    expect(scan.domain(NarrativeLegacyDomain.cinematic).remainingCount, 0);
    expect(scan.backupRequired, isTrue);
  });

  test('resumes generic migration work after an interruption', () {
    final project = ProjectManifest(
      name: 'legacy_project',
      maps: const [],
      tilesets: const [],
    );
    final transaction = NarrativeLegacyMigrationTransaction.start(project);
    final afterStory = transaction.applyDomain(
      NarrativeLegacyDomain.storyline,
      (current) => current.copyWith(name: 'after-story'),
    );
    final interrupted = afterStory.applyDomain(
      NarrativeLegacyDomain.event,
      (_) => throw StateError('simulated interruption'),
    );

    expect(interrupted.status, NarrativeLegacyTransactionStatus.interrupted);
    final resumed = interrupted.resume().applyDomain(
      NarrativeLegacyDomain.event,
      (current) => current.copyWith(name: 'after-event'),
    );
    expect(resumed.completedDomains, [
      NarrativeLegacyDomain.storyline,
      NarrativeLegacyDomain.event,
    ]);
    expect(resumed.rollback(), project);
  });
}
