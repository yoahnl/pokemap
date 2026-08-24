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
  }

  void completeTrack(Object handle) => _completions[handle]?.add(null);

  Object get lastHandle => 'handle-${_nextHandle - 1}';
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
