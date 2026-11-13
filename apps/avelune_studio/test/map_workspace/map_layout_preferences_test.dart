import 'dart:io';

import 'package:avelune_studio/features/map_workspace/coordination/map_layout_preferences.dart';
import 'package:avelune_studio/platform/files/local_map_layout_preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FailingStore implements MapLayoutPreferencesStore {
  @override
  Future<MapLayoutSnapshot?> load() async => null;

  @override
  Future<void> save(MapLayoutSnapshot snapshot) async =>
      throw const FileSystemException('disque plein');
}

void main() {
  test('layout owner publishes shared choices to every map consumer', () {
    final layout = MapLayoutPreferences(MemoryMapLayoutPreferencesStore());
    addTearDown(layout.dispose);
    final first = <MapLayoutSnapshot>[];
    final second = <MapLayoutSnapshot>[];
    MapLayoutSnapshot snapshot() => (
      mapOnly: layout.mapOnly,
      navigatorCollapsed: layout.navigatorCollapsed,
    );
    layout.addListener(() => first.add(snapshot()));
    layout.addListener(() => second.add(snapshot()));

    layout.update(mapOnly: true);
    layout.update(navigatorCollapsed: true);

    expect(first, second);
    expect(first, [
      (mapOnly: true, navigatorCollapsed: false),
      (mapOnly: true, navigatorCollapsed: true),
    ]);
    expect(MapLayoutPreferences().mapOnly, isFalse);
  });

  test('layout choices survive a reopening through the Studio file', () async {
    final directory = await Directory.systemTemp.createTemp('layout-prefs-');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/layout-preferences.json';
    final layout = MapLayoutPreferences(LocalMapLayoutPreferencesStore(path));
    await layout.load();
    layout.update(mapOnly: true, navigatorCollapsed: true);
    await layout.saved;
    final reopened = MapLayoutPreferences(LocalMapLayoutPreferencesStore(path));
    await reopened.load();
    expect(reopened.mapOnly, isTrue);
    expect(reopened.navigatorCollapsed, isTrue);
    expect(reopened.error, isNull);
  });

  test('a corrupt file or a failed write keeps the session usable', () async {
    final directory = await Directory.systemTemp.createTemp('layout-prefs-');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/layout-preferences.json';
    File(path).writeAsStringSync('{"schemaVersion": 9}');
    final corrupt = MapLayoutPreferences(LocalMapLayoutPreferencesStore(path));
    await corrupt.load();
    expect(corrupt.mapOnly, isFalse);
    expect(corrupt.error, isNotNull);

    final failing = MapLayoutPreferences(_FailingStore());
    await failing.load();
    failing.update(mapOnly: true);
    await failing.saved;
    expect(failing.mapOnly, isTrue);
    expect(failing.error, contains('enregistrer'));
  });
}
