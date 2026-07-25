import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  late Directory root;
  late HubPreferencesStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hub-preferences-');
    store = HubPreferencesStore(supportRoot: root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('preferences survive restart through an atomic current file', () async {
    final expected = const PlayerPreferences().copyWith(
      language: PlayerLanguage.fr,
      theme: PlayerThemePreference.dark,
      textScale: 1.25,
      reducedMotion: true,
      highContrast: true,
    );

    await store.save(expected);
    final read = await HubPreferencesStore(supportRoot: root).load();

    expect(read.preferences, expected);
    expect(read.source, HubPreferencesSource.current);
    expect(
      await File(p.join(root.path, 'preferences.json')).exists(),
      isTrue,
    );
  });

  test('corrupt current file recovers the last valid preferences', () async {
    await store.save(
      const PlayerPreferences().copyWith(language: PlayerLanguage.fr),
    );
    await store.save(
      const PlayerPreferences().copyWith(language: PlayerLanguage.en),
    );
    await File(p.join(root.path, 'preferences.json')).writeAsString('{broken');

    final read = await store.load();

    expect(read.source, HubPreferencesSource.backup);
    expect(read.preferences.language, PlayerLanguage.fr);
    expect(read.currentCorrupt, isTrue);
  });

  test('unsafe support roots are rejected without following a symlink',
      () async {
    final target = await Directory.systemTemp.createTemp('hub-prefs-target-');
    final link = Link(p.join(root.path, 'unsafe-link'));
    await link.create(target.path);
    addTearDown(() async {
      if (await link.exists()) await link.delete();
      if (await target.exists()) await target.delete(recursive: true);
    });

    final unsafe = HubPreferencesStore(supportRoot: Directory(link.path));

    expect(unsafe.load(), throwsA(isA<HubPreferencesStorageException>()));
  });

  test('unsafe preference files cannot redirect writes outside the Hub',
      () async {
    final outside = File('${root.path}.outside.json');
    addTearDown(() async {
      if (await outside.exists()) await outside.delete();
    });
    await outside.writeAsString('outside remains unchanged');
    await Link(p.join(root.path, 'preferences.json')).create(outside.path);

    await expectLater(
      store.save(const PlayerPreferences()),
      throwsA(isA<HubPreferencesStorageException>()),
    );

    expect(await outside.readAsString(), 'outside remains unchanged');
  });
}
