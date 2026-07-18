import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_loader/src/runtime_project_launch_map.dart';

void main() {
  test('New Game start map overrides stale host preferences', () {
    final selection = resolveRuntimeHostProjectMapSelection(
      _manifest(
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_story_start',
        ),
      ),
      preferredMapId: 'map_sorted_first',
    );

    expect(
      selection.maps.map((entry) => entry.id),
      orderedEquals(<String>['map_sorted_first', 'map_story_start']),
      reason: 'The picker remains sorted independently from launch policy.',
    );
    expect(selection.selectedMapId, 'map_story_start');
  });

  test('versioned launch save map overrides New Game start map', () {
    final manifest = _manifest(
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'map_story_start',
      ),
    );

    expect(
      resolveRuntimeHostProjectMapSelection(
        manifest,
        versionedLaunchMapId: 'map_sorted_first',
        preferredMapId: 'map_story_start',
      ).selectedMapId,
      'map_sorted_first',
    );
  });

  test('legacy projects preserve valid preference and sorted fallback', () {
    final manifest = _manifest(newGame: const ProjectNewGameConfig());

    expect(
      resolveRuntimeHostProjectMapSelection(
        manifest,
        preferredMapId: 'map_story_start',
      ).selectedMapId,
      'map_story_start',
    );
    expect(
      resolveRuntimeHostProjectMapSelection(
        manifest,
        preferredMapId: 'missing_map',
      ).selectedMapId,
      'map_sorted_first',
    );
  });
}

ProjectManifest _manifest({required ProjectNewGameConfig newGame}) {
  return ProjectManifest(
    name: 'Launch map test',
    newGame: newGame,
    tilesets: const <ProjectTilesetEntry>[],
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map_story_start',
        name: 'Story start',
        relativePath: 'maps/story_start.json',
        sortOrder: 20,
      ),
      ProjectMapEntry(
        id: 'map_sorted_first',
        name: 'Aardvark',
        relativePath: 'maps/sorted_first.json',
        sortOrder: 10,
      ),
    ],
  );
}
