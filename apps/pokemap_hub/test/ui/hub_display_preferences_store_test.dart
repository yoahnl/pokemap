import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hub-display-prefs-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('persists independent desktop preferences across store recreation',
      () async {
    final store = HubDisplayPreferencesStore(supportRoot: root);
    const macos = HubDisplayPreferences(
      mode: HubDisplayMode.fullscreen,
      windowSize: HubWindowSizePreset.compact,
    );
    const windows = HubDisplayPreferences(
      windowSize: HubWindowSizePreset.spacious,
    );

    await store.save(HubDesktopPlatform.macos, macos);
    await store.save(HubDesktopPlatform.windows, windows);

    final restarted = HubDisplayPreferencesStore(supportRoot: root);
    expect(await restarted.load(HubDesktopPlatform.macos), macos);
    expect(await restarted.load(HubDesktopPlatform.windows), windows);
    expect(
      await restarted.load(HubDesktopPlatform.linux),
      const HubDisplayPreferences(),
    );
  });

  test('uses the last validated backup when the current file is corrupt',
      () async {
    final store = HubDisplayPreferencesStore(supportRoot: root);
    const first = HubDisplayPreferences(
      windowSize: HubWindowSizePreset.compact,
    );
    await store.save(HubDesktopPlatform.macos, first);
    await store.save(
      HubDesktopPlatform.macos,
      const HubDisplayPreferences(mode: HubDisplayMode.fullscreen),
    );
    await File(
      '${root.path}/display-preferences.json',
    ).writeAsString('{corrupt');

    expect(await store.load(HubDesktopPlatform.macos), first);
  });
}
