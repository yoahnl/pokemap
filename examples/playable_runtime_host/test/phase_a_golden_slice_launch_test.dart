import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playable_runtime_host/src/runtime_launch_save.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the versioned Phase A golden slice exposes a real launch save',
      () async {
    final projectFilePath =
        '${Directory.current.path}${Platform.pathSeparator}golden_battle_slice${Platform.pathSeparator}project.json';

    final save = await loadRuntimeHostLaunchSaveData(
      projectFilePath: projectFilePath,
    );

    expect(save, isNotNull);
    expect(save!.currentMapId, equals('golden_field'));
    expect(save.party.members, hasLength(2));
    expect(save.party.members.first.speciesId, equals('sproutle'));
  });
}
