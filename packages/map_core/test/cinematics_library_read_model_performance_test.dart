import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('characterizes search sort and grouping for 1000 cinematics', () {
    final project = ProjectManifest(
      name: 'cinematics_scale_fixture',
      maps: const [
        ProjectMapEntry(
          id: 'map_port',
          name: 'Port Selbrume',
          relativePath: 'port.json',
        ),
      ],
      tilesets: const [],
      cinematics: [
        for (var index = 0; index < 1000; index++)
          CinematicAsset(
            id: 'cinematic_${index.toString().padLeft(4, '0')}',
            title: 'Plan $index',
            mapId: 'map_port',
            tags: [index.isEven ? 'rival' : 'ambiance'],
            timeline: CinematicTimeline(
              steps: [
                CinematicTimelineStep(
                  id: 'step_$index',
                  kind: CinematicTimelineStepKind.wait,
                  durationMs: 100 + index,
                ),
              ],
            ),
          ),
      ],
    );

    final stopwatch = Stopwatch()..start();
    final readModel = buildCinematicsLibraryReadModel(project);
    final builtMicros = stopwatch.elapsedMicroseconds;
    stopwatch.reset();
    final matches = readModel.queryEntries(
      const CinematicsLibraryQuery(
        searchText: 'rival port',
        sort: CinematicsLibrarySort.durationDescending,
      ),
    );
    final groups = readModel.groupEntries(
      const CinematicsLibraryQuery(
        searchText: 'rival port',
        sort: CinematicsLibrarySort.durationDescending,
      ),
    );
    final queryMicros = stopwatch.elapsedMicroseconds;
    stopwatch.stop();

    expect(readModel.canonicalEntries, hasLength(1000));
    expect(matches, hasLength(500));
    expect(matches.first.id, 'cinematic_0998');
    expect(groups, hasLength(1));
    expect(groups.single.entries, hasLength(500));
    // Observational baseline only. NSC-00 intentionally delegates the strict
    // cross-machine budget to NSC-74 instead of inventing one after the fact.
    // ignore: avoid_print
    print(
      'NSC-62 library baseline: buildMicros=$builtMicros, '
      'queryAndGroupMicros=$queryMicros, assets=1000, matches=500',
    );
  }, timeout: const Timeout(Duration(seconds: 10)));
}
