import 'package:avelune_studio/features/home/application/home_navigation_host.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('a navigation requested before publish is queued and replayed once', () {
    final host = HomeNavigationHost();
    final opened = <(String, String?)>[];
    host.navigate('map', 'a');
    expect(host.hasPendingNavigation, isTrue);
    expect(opened, isEmpty);
    host.publish(
      availableMaps: const [(id: 'a', name: 'Bourg')],
      testAvailable: true,
      navigate: (destination, mapId) => opened.add((destination, mapId)),
      guard: () async => true,
    );
    expect(opened, [('map', 'a')]);
    expect(host.hasPendingNavigation, isFalse);
    host.publish(
      availableMaps: const [],
      testAvailable: true,
      navigate: (destination, mapId) => opened.add((destination, mapId)),
      guard: () async => true,
    );
    expect(opened, [('map', 'a')]);
  });

  test('only the latest navigation requested before publish survives', () {
    final host = HomeNavigationHost();
    final opened = <(String, String?)>[];
    host.navigate('map', 'a');
    host.navigate('resources');
    host.publish(
      availableMaps: const [],
      testAvailable: false,
      navigate: (destination, mapId) => opened.add((destination, mapId)),
      guard: () async => true,
    );
    expect(opened, [('resources', null)]);
  });

  test('a navigation after publish reaches the host immediately', () {
    final host = HomeNavigationHost();
    final opened = <(String, String?)>[];
    host.publish(
      availableMaps: const [],
      testAvailable: false,
      navigate: (destination, mapId) => opened.add((destination, mapId)),
      guard: () async => true,
    );
    expect(host.connected, isTrue);
    host.navigate('gameExport');
    expect(opened, [('gameExport', null)]);
    expect(host.hasPendingNavigation, isFalse);
  });

  test('reset drops the host and a queued navigation', () {
    final host = HomeNavigationHost();
    final opened = <String>[];
    host.navigate('map', 'a');
    host.reset();
    host.publish(
      availableMaps: const [],
      testAvailable: false,
      navigate: (destination, _) => opened.add(destination),
      guard: () async => true,
    );
    expect(opened, isEmpty);
    host.reset();
    expect(host.connected, isFalse);
    host.navigate('map');
    expect(opened, isEmpty);
    expect(host.hasPendingNavigation, isTrue);
  });

  test(
    'publish exposes the switch guard, maps and test availability',
    () async {
      final host = HomeNavigationHost();
      var allowed = false;
      host.publish(
        availableMaps: const [
          (id: 'a', name: 'Bourg'),
          (id: 'b', name: 'Forêt'),
        ],
        testAvailable: true,
        navigate: (_, _) {},
        guard: () async => allowed,
      );
      expect(host.maps.map((map) => map.id), ['a', 'b']);
      expect(host.canTest, isTrue);
      expect(await host.allowSwitch!(), isFalse);
      allowed = true;
      expect(await host.allowSwitch!(), isTrue);
      host.reset();
      expect(host.allowSwitch, isNull);
      expect(host.maps, isEmpty);
      expect(host.canTest, isFalse);
    },
  );

  test('the new game falls back to the library configuration', () {
    final library = workspaceProject.copyWith(
      newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'a'),
    );
    const explicit = ProjectNewGameConfig(enabled: true, startMapId: 'b');
    final host = HomeNavigationHost();
    host.publish(
      availableMaps: const [],
      library: library,
      testAvailable: false,
      navigate: (_, _) {},
      guard: () async => true,
    );
    expect(host.newGame, library.newGame);
    expect(host.newGame!.startMapId, 'a');
    host.publish(
      availableMaps: const [],
      library: library,
      startConfig: explicit,
      testAvailable: false,
      navigate: (_, _) {},
      guard: () async => true,
    );
    expect(host.newGame, explicit);
    host.publish(
      availableMaps: const [],
      testAvailable: false,
      navigate: (_, _) {},
      guard: () async => true,
    );
    expect(host.newGame, isNull);
    expect(host.mapLibrary, isNull);
  });

  test('library optimization state is replaced then cleared by reset', () {
    final host = HomeNavigationHost();
    void optimize() {}
    host.updateLibraryOptimization(onOptimize: optimize, busy: true);
    expect(host.optimizingLibrary, isTrue);
    expect(host.onOptimizeLibrary, same(optimize));
    expect(host.libraryOptimizationError, isNull);
    host.updateLibraryOptimization(error: 'Échec de l’optimisation');
    expect(host.optimizingLibrary, isFalse);
    expect(host.onOptimizeLibrary, isNull);
    expect(host.libraryOptimizationError, 'Échec de l’optimisation');
    host.updateLibraryOptimization(onOptimize: optimize, busy: true);
    host.reset();
    expect(host.optimizingLibrary, isFalse);
    expect(host.onOptimizeLibrary, isNull);
    expect(host.libraryOptimizationError, isNull);
  });
}
