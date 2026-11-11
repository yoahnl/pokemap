@Timeout(Duration(minutes: 3))
library;

import 'package:avelune_studio/features/cinematics/application/cinematic_library_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/cinematic_workspace_owner_fixture.dart';

void main() {
  late CinematicWorkspaceOwnerFixture owner;
  late MapData garden;
  setUp(() async {
    owner = await CinematicWorkspaceOwnerFixture.create();
    garden = await owner.loadMap('jardin');
  });
  tearDown(() => owner.dispose());

  test('the open document wins over the loaded copy of the same map', () {
    final open = garden.copyWith(name: 'Jardin en cours');
    expect(
      cinematicThumbnailMap(mapId: 'jardin', open: open, loaded: garden),
      same(open),
    );
    expect(
      cinematicThumbnailMap(mapId: 'jardin', open: null, loaded: garden),
      same(garden),
    );
  });

  test('a map loaded for a previous choice is never shown for the new one', () {
    expect(
      cinematicThumbnailMap(mapId: 'autre', open: null, loaded: garden),
      isNull,
    );
    expect(
      cinematicThumbnailMap(mapId: 'autre', open: garden, loaded: null),
      isNull,
    );
    expect(
      cinematicThumbnailMap(mapId: null, open: null, loaded: garden),
      isNull,
    );
    expect(
      cinematicThumbnailMap(mapId: 'jardin', open: null, loaded: null),
      isNull,
    );
  });
}
