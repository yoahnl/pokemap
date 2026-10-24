import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/player/runtime_audio_mixer.dart';
import 'package:map_runtime/src/player/runtime_music_loop_points.dart';
import 'package:map_runtime/src/player/runtime_music_service.dart';
import 'package:map_runtime/src/presentation/flame/flame_cinematic_media_playback_adapter.dart';

// BETA-BAT-026 — recette du 2026-08-24 : « la musique est en boucle c'est
// bien, mais on a aussi le jingle de début de combat, ce n'est pas logique ».
//
// Le lecteur bouclait le FICHIER ENTIER : l'intro du morceau revenait à
// chaque tour de boucle. Les pistes du Train portent les points de boucle de
// la convention RPG Maker (`LOOPSTART` / `LOOPLENGTH` en échantillons dans
// les commentaires Vorbis) — la piste de combat sauvage a 14,3 s d'intro.

/// Fabrique un faux .ogg : l'en-tête d'identification Vorbis (pour la
/// fréquence) puis un bloc de commentaires portant les deux tags.
Uint8List _fakeOggBytes({
  required int loopStart,
  required int loopLength,
  int sampleRate = 44100,
  bool withTags = true,
}) {
  final bytes = <int>[
    ...'OggS'.codeUnits,
    0, 0, 0, 0,
    // En-tête d'identification : 0x01 "vorbis", version (4), canaux (1),
    // puis la fréquence en petit-boutiste.
    0x01, ...'vorbis'.codeUnits,
    0, 0, 0, 0,
    2,
    sampleRate & 0xFF,
    (sampleRate >> 8) & 0xFF,
    (sampleRate >> 16) & 0xFF,
    (sampleRate >> 24) & 0xFF,
    0, 0, 0, 0,
    ...'OggS'.codeUnits,
    0x03, ...'vorbis'.codeUnits,
    if (withTags) ...<int>[
      ...'ARTIST=GAME FREAK'.codeUnits,
      0,
      ...'LOOPSTART=$loopStart'.codeUnits,
      0,
      ...'LOOPLENGTH=$loopLength'.codeUnits,
      0,
    ],
    ...'TITLE=Battle'.codeUnits,
  ];
  return Uint8List.fromList(bytes);
}

final class _FakeLoopDriver
    implements FlameCinematicAudioDriver, FlameCinematicAudioLoopDriver {
  final List<({String path, bool loop})> plays = <({String path, bool loop})>[];
  final List<Duration> seeks = <Duration>[];
  final Map<Object, StreamController<void>> _completions =
      <Object, StreamController<void>>{};
  var _nextHandle = 0;
  Completer<void>? seekGate;

  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    plays.add((path: path, loop: loop));
    final handle = 'handle-${_nextHandle++}';
    _completions[handle] = StreamController<void>.broadcast();
    return handle;
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> stop(Object handle) async {
    await _completions.remove(handle)?.close();
  }

  @override
  Stream<void> onComplete(Object handle) => _completions[handle]!.stream;

  @override
  Future<void> seekAndResume(Object handle, Duration position) async {
    seeks.add(position);
    await seekGate?.future;
  }

  void completeTrack(Object handle) => _completions[handle]?.add(null);

  Object get lastHandle => 'handle-${_nextHandle - 1}';
}

final class _LoopTimer implements Timer {
  _LoopTimer(this.callback);
  final void Function() callback;
  var _active = true;

  @override
  bool get isActive => _active;

  @override
  int get tick => _active ? 0 : 1;

  @override
  void cancel() => _active = false;

  void fire() {
    if (!_active) return;
    _active = false;
    callback();
  }
}

/// Un driver SANS la capacité de boucle : il doit garder l'ancien
/// comportement, boucle du fichier entier.
final class _FakePlainDriver implements FlameCinematicAudioDriver {
  final List<({String path, bool loop})> plays = <({String path, bool loop})>[];

  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    plays.add((path: path, loop: loop));
    return 'plain';
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> stop(Object handle) async {}
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('music-loop-test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  String writeTrack({
    required String name,
    required int loopStart,
    required int loopLength,
    int sampleRate = 44100,
    bool withTags = true,
  }) {
    final file = File('${tempDir.path}/$name')
      ..writeAsBytesSync(_fakeOggBytes(
        loopStart: loopStart,
        loopLength: loopLength,
        sampleRate: sampleRate,
        withTags: withTags,
      ));
    return file.path;
  }

  group('lecture des points de boucle', () {
    test('les deux tags et la fréquence sont lus', () {
      final path = writeTrack(
        name: 'wild.ogg',
        loopStart: 630812,
        loopLength: 1745886,
      );

      final points = readRuntimeMusicLoopPoints(path)!;
      expect(points.startSample, 630812);
      expect(points.lengthSamples, 1745886);
      expect(points.sampleRate, 44100);
      // 630812 / 44100 ≈ 14,3 s : c'est l'intro que le joueur entendait
      // revenir à chaque boucle.
      expect(points.start.inMilliseconds, closeTo(14304, 2));
      expect(points.end.inMilliseconds, closeTo(53893, 2));
    });

    test('une piste sans tags ne porte aucun point de boucle', () {
      final path = writeTrack(
        name: 'plain.ogg',
        loopStart: 0,
        loopLength: 0,
        withTags: false,
      );

      expect(readRuntimeMusicLoopPoints(path), isNull);
    });

    test('un fichier absent ne casse pas', () {
      expect(
        readRuntimeMusicLoopPoints('${tempDir.path}/nope.ogg'),
        isNull,
      );
    });

    test('la fréquence de l’en-tête est respectée, pas supposée', () {
      final path = writeTrack(
        name: 'rate.ogg',
        loopStart: 48000,
        loopLength: 96000,
        sampleRate: 48000,
      );

      final points = readRuntimeMusicLoopPoints(path)!;
      expect(points.sampleRate, 48000);
      expect(points.start.inMilliseconds, 1000);
    });
  });

  group('le service ne rejoue plus l’intro', () {
    for (final completionFirst in [false, true]) {
      test(
        'timer and completion coalesce during a held seek '
        '(completion first: $completionFirst)',
        () async {
          final driver = _FakeLoopDriver();
          final timers = <_LoopTimer>[];
          final service = RuntimeMusicService(
            driver: driver,
            loopTimerFactory: (_, callback) {
              final timer = _LoopTimer(callback);
              timers.add(timer);
              return timer;
            },
          );
          addTearDown(service.dispose);
          final path = writeTrack(
            name: 'coalesced.ogg',
            loopStart: 48000,
            loopLength: 96000,
            sampleRate: 48000,
          );
          await service.update(route: RuntimeAudioRoute.overworld, path: path);
          final gate = driver.seekGate = Completer<void>();
          if (completionFirst) {
            driver.completeTrack(driver.lastHandle);
          } else {
            timers.single.fire();
          }
          await Future<void>.delayed(Duration.zero);
          expect(driver.seeks, hasLength(1));
          if (completionFirst) {
            timers.single.fire();
          } else {
            driver.completeTrack(driver.lastHandle);
          }
          await Future<void>.delayed(Duration.zero);
          gate.complete();
          driver.seekGate = null;
          await Future<void>.delayed(Duration.zero);
          expect(driver.seeks, hasLength(1));
          expect(timers, hasLength(2));
          timers.last.fire();
          await Future<void>.delayed(Duration.zero);
          expect(driver.seeks, hasLength(2));
          driver.completeTrack(driver.lastHandle);
          await Future<void>.delayed(Duration.zero);
          expect(driver.seeks, hasLength(3));
        },
      );
    }

    test('a failed seek releases coalescing for completion fallback', () async {
      final driver = _FakeLoopDriver();
      final timers = <_LoopTimer>[];
      final service = RuntimeMusicService(
        driver: driver,
        loopTimerFactory: (_, callback) {
          final timer = _LoopTimer(callback);
          timers.add(timer);
          return timer;
        },
      );
      addTearDown(service.dispose);
      final path = writeTrack(
        name: 'failed-seek.ogg',
        loopStart: 48000,
        loopLength: 96000,
        sampleRate: 48000,
      );
      await service.update(route: RuntimeAudioRoute.overworld, path: path);
      final gate = driver.seekGate = Completer<void>();
      timers.single.fire();
      await Future<void>.delayed(Duration.zero);
      driver.completeTrack(driver.lastHandle);
      await Future<void>.delayed(Duration.zero);
      final failure = StateError('seek unavailable');
      gate.completeError(failure);
      driver.seekGate = null;
      await Future<void>.delayed(Duration.zero);
      expect(driver.seeks, hasLength(1));
      expect(service.lastFailure, same(failure));
      driver.completeTrack(driver.lastHandle);
      await Future<void>.delayed(Duration.zero);
      expect(driver.seeks, hasLength(2));
      expect(timers, hasLength(2));
    });

    for (final action in ['silence', 'change', 'dispose']) {
      test('held loop return preserves $action invalidation', () async {
        final driver = _FakeLoopDriver();
        final timers = <_LoopTimer>[];
        final service = RuntimeMusicService(
          driver: driver,
          fadeDelay: (_) async {},
          loopTimerFactory: (_, callback) {
            final timer = _LoopTimer(callback);
            timers.add(timer);
            return timer;
          },
        );
        addTearDown(service.dispose);
        final first = writeTrack(
          name: 'held-first.ogg',
          loopStart: 48000,
          loopLength: 96000,
          sampleRate: 48000,
        );
        final second = writeTrack(
          name: 'held-second.ogg',
          loopStart: 48000,
          loopLength: 96000,
          sampleRate: 48000,
        );
        await service.update(route: RuntimeAudioRoute.overworld, path: first);
        final firstHandle = driver.lastHandle;
        final gate = driver.seekGate = Completer<void>();
        timers.single.fire();
        await Future<void>.delayed(Duration.zero);
        driver.completeTrack(firstHandle);
        await Future<void>.delayed(Duration.zero);
        final invalidation = action == 'dispose'
            ? service.dispose()
            : service.update(
                route: RuntimeAudioRoute.overworld,
                path: action == 'change' ? second : null,
                immediateStop: true,
              );
        gate.complete();
        driver.seekGate = null;
        await invalidation;
        timers.first.callback();
        driver.completeTrack(firstHandle);
        await Future<void>.delayed(Duration.zero);
        expect(driver.seeks, hasLength(1));
        if (action == 'change') {
          expect(service.playingPath, second);
          timers.last.fire();
          await Future<void>.delayed(Duration.zero);
          expect(driver.seeks, hasLength(2));
        } else {
          expect(service.isPlaying, isFalse);
        }
      });
    }

    test(
        'une piste à points de boucle est jouée SANS boucle native, et '
        'reprend au point de boucle à sa fin', () async {
      final driver = _FakeLoopDriver();
      final service = RuntimeMusicService(
        driver: driver,
        mixer: RuntimeAudioMixer(),
      );
      final path = writeTrack(
        name: 'wild.ogg',
        loopStart: 630812,
        loopLength: 1745886,
      );

      await service.update(route: RuntimeAudioRoute.battle, path: path);

      expect(driver.plays, hasLength(1));
      expect(
        driver.plays.single.loop,
        isFalse,
        reason: 'la boucle native rejouerait l’intro : c’est le service qui '
            'gère la reprise',
      );

      driver.completeTrack(driver.lastHandle);
      await Future<void>.delayed(Duration.zero);

      expect(driver.seeks, hasLength(1));
      expect(
        driver.seeks.single.inMilliseconds,
        closeTo(14304, 2),
        reason: 'la reprise saute l’intro et repart au point de boucle',
      );
    });

    test(
        'recette du 2026-08-25 : la boucle repart à la fin de la RÉGION, pas '
        'à la fin du fichier', () async {
      // « la boucle fonctionne presque mais elle MORD au moment de la
      // boucle ». Attendre `onComplete`, c'est attendre la fin du FICHIER —
      // or la région s'arrête à LOOPSTART+LOOPLENGTH, avant. Mesuré sur le
      // Train : 473 ms de queue jouée en trop sur la piste sauvage, 1,19 s
      // sur celle de dresseur.
      final driver = _FakeLoopDriver();
      final service = RuntimeMusicService(
        driver: driver,
        mixer: RuntimeAudioMixer(),
      );
      final path = writeTrack(
        name: 'wild.ogg',
        loopStart: 630812,
        loopLength: 1745886,
      );

      await service.update(route: RuntimeAudioRoute.battle, path: path);
      expect(driver.seeks, isEmpty, reason: 'rien avant la fin de région');

      // Le retour est programmé sur la fin de la RÉGION — 630812 + 1745886
      // = 2376698 échantillons à 44,1 kHz, soit 53,894 s — et non sur la fin
      // du FICHIER, qui dure 54,366 s. C'est cette différence, 473 ms de
      // queue, que la recette entendait mordre.
      expect(
        service.debugLoopReturnDelay?.inMilliseconds,
        closeTo(53894, 2),
        reason: 'la première passe joue l’intro PUIS la région',
      );

      // Le filet `onComplete` reste branché : si la piste va au bout malgré
      // tout, la boucle repart au lieu de mourir.
      driver.completeTrack(driver.lastHandle);
      await Future<void>.delayed(Duration.zero);
      expect(driver.seeks.single.inMilliseconds, closeTo(14304, 2));
      expect(
        service.debugLoopReturnDelay?.inMilliseconds,
        closeTo(39590, 2),
        reason: 'les tours suivants ne durent que LOOPLENGTH, sans l’intro',
      );
    });

    test('une piste sans tags garde la boucle du fichier entier', () async {
      final driver = _FakeLoopDriver();
      final service = RuntimeMusicService(
        driver: driver,
        mixer: RuntimeAudioMixer(),
      );
      final path = writeTrack(
        name: 'plain.ogg',
        loopStart: 0,
        loopLength: 0,
        withTags: false,
      );

      await service.update(route: RuntimeAudioRoute.battle, path: path);

      expect(driver.plays.single.loop, isTrue);
      driver.completeTrack(driver.lastHandle);
      await Future<void>.delayed(Duration.zero);
      expect(driver.seeks, isEmpty);
    });

    test(
        'un driver sans la capacité de boucle garde l’ancien comportement',
        () async {
      final driver = _FakePlainDriver();
      final service = RuntimeMusicService(
        driver: driver,
        mixer: RuntimeAudioMixer(),
      );
      final path = writeTrack(
        name: 'wild.ogg',
        loopStart: 630812,
        loopLength: 1745886,
      );

      await service.update(route: RuntimeAudioRoute.battle, path: path);

      expect(
        driver.plays.single.loop,
        isTrue,
        reason: 'aucune implémentation existante n’a à changer',
      );
    });

    test('changer de piste tue la boucle de la précédente', () async {
      final driver = _FakeLoopDriver();
      final service = RuntimeMusicService(
        driver: driver,
        mixer: RuntimeAudioMixer(),
      );
      final first = writeTrack(
        name: 'first.ogg',
        loopStart: 630812,
        loopLength: 1745886,
      );
      final second = writeTrack(
        name: 'second.ogg',
        loopStart: 44100,
        loopLength: 88200,
      );

      await service.update(route: RuntimeAudioRoute.battle, path: first);
      final firstHandle = driver.lastHandle;
      await service.update(route: RuntimeAudioRoute.battle, path: second);

      driver.completeTrack(firstHandle);
      await Future<void>.delayed(Duration.zero);

      expect(
        driver.seeks,
        isEmpty,
        reason: 'une piste arrêtée ne doit pas revenir par sa boucle',
      );
    });
  });
}
