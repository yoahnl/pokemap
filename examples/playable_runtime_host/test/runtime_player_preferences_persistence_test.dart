import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_loader/src/runtime_startup_host.dart';

void main() {
  test('standalone settings survive gateway recreation and failed writes',
      () async {
    final root = await Directory.systemTemp.createTemp('menu8-preferences-');
    addTearDown(() async {
      if (!Platform.isWindows) await Process.run('chmod', ['u+w', root.path]);
      await root.delete(recursive: true);
    });
    final file = File('${root.path}/preferences.json');
    final first = StandalonePlayerPreferencesGateway(
      audioMixer: RuntimeAudioMixer(),
      preferencesFile: () async => file,
    );
    final changed = (await first.load()).copyWith(
      locale: 'en',
      dialogueTextSpeed: RuntimeDialogueTextSpeed.fast,
      menuEffects: RuntimePlayerMenuEffects.opaque,
      highContrast: true,
      audioMix: const RuntimeAudioMix(masterVolume: 0.5, musicVolume: 0.4),
    );
    await first.save(changed);
    final mixer = RuntimeAudioMixer();
    final second = StandalonePlayerPreferencesGateway(
      audioMixer: mixer,
      preferencesFile: () async => file,
    );
    final restored = await second.load();
    expect(second.defaultPreferences.locale, 'fr');
    expect(second.defaultPreferences.audioMix.masterVolume, 1);
    expect(second.defaultPreferences.audioMix.musicVolume, 1);
    expect(second.defaultPreferences.audioMix.effectsVolume, 1);
    expect(restored.locale, 'en');
    expect(restored.dialogueTextSpeed, RuntimeDialogueTextSpeed.fast);
    expect(restored.menuEffects, RuntimePlayerMenuEffects.opaque);
    expect(restored.highContrast, isTrue);
    expect(mixer.mix.masterVolume, 0.5);
    if (Platform.isWindows) return;
    final before = await file.readAsBytes();
    expect((await Process.run('chmod', ['a-w', root.path])).exitCode, 0);
    await expectLater(
      second.save(restored.copyWith(audioMix: const RuntimeAudioMix(masterVolume: 0))),
      throwsA(isA<FileSystemException>()),
    );
    expect(mixer.mix.masterVolume, 0.5);
    expect(await file.readAsBytes(), before);
    expect((await second.load()).audioMix.masterVolume, 0.5);
  });
}
