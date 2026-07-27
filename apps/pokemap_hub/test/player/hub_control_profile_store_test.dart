import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/src/player/hub_control_profile_store.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hub-control-profile-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('persists a valid profile and restores defaults after corrupt data',
      () async {
    final store = HubControlProfileStore(supportRoot: root);
    final customized = PlayerControlProfile.standard
        .rebind(
          device: PlayerControlDevice.keyboard,
          control: RuntimeInputControl.primary,
          inputId: 'keyZ',
        )
        .profile;

    await store.save(customized);
    expect(await store.load(), customized);

    await File('${root.path}/control-profile.json').writeAsString('{broken');
    expect(await store.load(), PlayerControlProfile.standard);
  });
}
