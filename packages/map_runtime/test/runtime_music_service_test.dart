import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

final class _FakeAudioDriver implements FlameCinematicAudioDriver {
  final List<String> events = <String>[];
  final Map<Object, double> volumesByHandle = <Object, double>{};
  var _nextHandle = 0;

  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    final handle = 'handle_${_nextHandle++}';
    events.add('play $path loop=$loop');
    volumesByHandle[handle] = volume;
    return handle;
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {
    volumesByHandle[handle] = volume;
    events.add('volume $handle ${volume.toStringAsFixed(2)}');
  }

  @override
  Future<void> stop(Object handle) async {
    events.add('stop $handle');
  }
}

RuntimeMusicService _service(_FakeAudioDriver driver) => RuntimeMusicService(
      driver: driver,
      mixer: RuntimeAudioMixer(),
      fadeDelay: (_) async {},
      fadeSteps: 2,
    );

void main() {
  test('joue la piste demandée en boucle et la retient', () async {
    final driver = _FakeAudioDriver();
    final service = _service(driver);

    await service.update(
      route: RuntimeAudioRoute.overworld,
      path: '/project/audio/town.ogg',
    );

    expect(service.isPlaying, isTrue);
    expect(service.playingPath, '/project/audio/town.ogg');
    expect(driver.events, ['play /project/audio/town.ogg loop=true']);
  });

  test('même chemin → pas de redémarrage (parité autoplay)', () async {
    final driver = _FakeAudioDriver();
    final service = _service(driver);

    await service.update(
      route: RuntimeAudioRoute.overworld,
      path: '/project/audio/town.ogg',
    );
    await service.update(
      route: RuntimeAudioRoute.overworld,
      path: '/project/audio/town.ogg',
    );

    expect(
      driver.events.where((event) => event.startsWith('play')).length,
      1,
    );
  });

  test('changement de piste : fondu de l’ancienne puis nouvelle', () async {
    final driver = _FakeAudioDriver();
    final service = _service(driver);

    await service.update(
      route: RuntimeAudioRoute.overworld,
      path: '/project/audio/town.ogg',
    );
    await service.update(
      route: RuntimeAudioRoute.battle,
      path: '/project/audio/battle.ogg',
    );

    expect(driver.events, [
      'play /project/audio/town.ogg loop=true',
      'volume handle_0 0.40',
      'volume handle_0 0.00',
      'stop handle_0',
      'play /project/audio/battle.ogg loop=true',
    ]);
    expect(service.playingPath, '/project/audio/battle.ogg');
  });

  test('chemin null : fondu vers le silence', () async {
    final driver = _FakeAudioDriver();
    final service = _service(driver);

    await service.update(
      route: RuntimeAudioRoute.overworld,
      path: '/project/audio/town.ogg',
    );
    await service.update(route: RuntimeAudioRoute.overworld, path: null);

    expect(service.isPlaying, isFalse);
    expect(driver.events.last, 'stop handle_0');
  });

  test('un échec de lecture reste un diagnostic, jamais une exception',
      () async {
    final driver = _FakeAudioDriver();
    final service = RuntimeMusicService(
      driver: _ThrowingDriver(),
      mixer: RuntimeAudioMixer(),
      fadeDelay: (_) async {},
    );

    await service.update(
      route: RuntimeAudioRoute.overworld,
      path: '/project/audio/missing.ogg',
    );

    expect(service.isPlaying, isFalse);
    expect(service.lastFailure, isNotNull);
    expect(driver.events, isEmpty);
  });

  test('dispose coupe net et rend le service inerte', () async {
    final driver = _FakeAudioDriver();
    final service = _service(driver);

    await service.update(
      route: RuntimeAudioRoute.overworld,
      path: '/project/audio/town.ogg',
    );
    await service.dispose();
    await service.update(
      route: RuntimeAudioRoute.overworld,
      path: '/project/audio/battle.ogg',
    );

    expect(service.isPlaying, isFalse);
    expect(driver.events.last, 'stop handle_0');
    expect(
      driver.events.where((event) => event.startsWith('play')).length,
      1,
    );
  });
}

final class _ThrowingDriver implements FlameCinematicAudioDriver {
  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    throw StateError('no audio backend in tests');
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> stop(Object handle) async {}
}
