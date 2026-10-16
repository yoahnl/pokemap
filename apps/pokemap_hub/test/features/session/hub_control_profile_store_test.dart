import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/features/session/data/repositories/control_profile_repository_impl.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hub-control-profile-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('bicycle rebind persists on disk and incomplete pre-1 profiles reset', () async {
    final store = HubControlProfileStore(supportRoot: root);
    final profile = PlayerControlProfile.standard.rebind(device: PlayerControlDevice.keyboard,
      control: RuntimeInputControl.bicycle, inputId: 'keyQ').profile;
    await store.save(profile);
    final cold = HubControlProfileStore(supportRoot: root);
    expect((await cold.load()).bindingFor(PlayerControlDevice.keyboard, RuntimeInputControl.bicycle), 'keyQ');
    final incomplete = profile.toJson();
    for (final device in ['keyboard', 'gamepad', 'touch']) {
      (incomplete[device] as Map).remove('bicycle');
    }
    await File('${root.path}/control-profile.json').writeAsString(jsonEncode(incomplete));
    expect(await cold.load(), PlayerControlProfile.standard);
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
