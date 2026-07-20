import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('cross-domain checkpoint resumes without replay and rolls back exactly',
      () {
    const before = ProjectManifest(
      surfaceCatalog: ProjectSurfaceCatalog.empty(),
      name: 'before',
      maps: [],
      tilesets: [],
    );
    final storylineCheckpoint =
        NarrativeLegacyMigrationTransaction.start(before).applyDomain(
      NarrativeLegacyDomain.storyline,
      (project) => project.copyWith(name: 'storyline-migrated'),
    );
    final interrupted = storylineCheckpoint.applyDomain(
      NarrativeLegacyDomain.event,
      (_) => throw StateError('disk interrupted'),
    );

    expect(interrupted.current.name, 'storyline-migrated');
    expect(interrupted.interruptionMessage, contains('disk interrupted'));
    final replaySafe = interrupted.resume().applyDomain(
          NarrativeLegacyDomain.storyline,
          (_) => throw StateError('must not replay'),
        );
    final completed = replaySafe.applyDomain(
      NarrativeLegacyDomain.event,
      (project) => project.copyWith(name: 'event-migrated'),
    );

    expect(completed.current.name, 'event-migrated');
    expect(completed.completedDomains, [
      NarrativeLegacyDomain.storyline,
      NarrativeLegacyDomain.event,
    ]);
    expect(completed.rollback(), before);
  });
}
