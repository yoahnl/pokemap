import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

/// L'exécution du plan audio sous l'autorité unique du mixer —
/// BETA-CIN-076.
///
/// Le driver est un fake qui journalise ; le mixer est le VRAI. Chaque canal
/// est enregistré sur sa route cinématique (master/bus/mute/ducking
/// s'appliquent à tout), un hold suspend position-preservée et la reprise ne
/// redémarre jamais un loop, le lifecycle est indépendant du hold, une voix
/// active duck la musique, un média manquant échoue fermé, et la sortie ne
/// laisse ni handle ni callback périmé.
void main() {
  test('a source declares its media type, because a blob carries no extension',
      () async {
    // The blob store is content-addressed: every media lives at
    // `<digest>.blob`. AVFoundation cannot infer a container from that name,
    // so without the catalog's media type the player refuses the file and the
    // cinematic plays silent — in the Studio montage and in the game alike.
    final driver = _RecordingAudioDriver();
    final controller = RuntimePresentationAudioController(
      catalog: ProjectMediaCatalog(
        entries: <ProjectMediaAsset>[
          ProjectMediaAsset(
            id: 'media_theme',
            label: 'Theme',
            kind: ProjectMediaKind.audio,
            sourceAssetId: 'asset_theme',
            technicalMetadata: ProjectMediaTechnicalMetadata(
              mediaType: 'audio/mpeg',
              container: 'mp3',
              codec: 'mp3',
              sizeBytes: 649552,
              durationMilliseconds: 27063,
            ),
          ),
        ],
      ),
      resolveUri: (media) => Uri.file('/project/${media.sourceAssetId}.blob'),
      driver: driver,
      mixer: RuntimeAudioMixer(),
    );
    addTearDown(controller.releaseAll);

    final themed = PresentationCinematicAsset(
      id: 'opening',
      title: 'Opening',
      durationUs: 4000000,
      tracks: <PresentationTrack>[
        PresentationTrack(
          id: 'music',
          label: 'Music',
          kind: PresentationTrackKind.audio,
          clips: <PresentationClip>[
            PresentationAudioClip(
              id: 'theme',
              startUs: 0,
              durationUs: 4000000,
              resourceId: 'media_theme',
              audioKind: PresentationAudioKind.music,
              bus: PresentationAudioBus.music,
            ),
          ],
        ),
      ],
    );

    await controller.synchronize(
      themed,
      const PresentationCinematicEvaluator().evaluate(themed, timeUs: 0),
    );

    expect(driver.handles, hasLength(1));
    expect(driver.handles.single.mimeType, 'audio/mpeg');
  });

  test('a media without technical metadata still plays, type unspecified',
      () async {
    final driver = _RecordingAudioDriver();
    final controller = RuntimePresentationAudioController(
      catalog: ProjectMediaCatalog(
        entries: <ProjectMediaAsset>[
          ProjectMediaAsset(
            id: 'media_theme',
            label: 'Theme',
            kind: ProjectMediaKind.audio,
            sourceAssetId: 'asset_theme',
          ),
        ],
      ),
      resolveUri: (media) => Uri.file('/project/${media.sourceAssetId}.ogg'),
      driver: driver,
      mixer: RuntimeAudioMixer(),
    );
    addTearDown(controller.releaseAll);

    final themed = PresentationCinematicAsset(
      id: 'opening',
      title: 'Opening',
      durationUs: 4000000,
      tracks: <PresentationTrack>[
        PresentationTrack(
          id: 'music',
          label: 'Music',
          kind: PresentationTrackKind.audio,
          clips: <PresentationClip>[
            PresentationAudioClip(
              id: 'theme',
              startUs: 0,
              durationUs: 4000000,
              resourceId: 'media_theme',
              audioKind: PresentationAudioKind.music,
              bus: PresentationAudioBus.music,
            ),
          ],
        ),
      ],
    );

    await controller.synchronize(
      themed,
      const PresentationCinematicEvaluator().evaluate(themed, timeUs: 0),
    );

    expect(driver.handles, hasLength(1));
    expect(driver.handles.single.mimeType, isNull);
  });

  PresentationCinematicAsset asset({bool withVoice = false}) =>
      PresentationCinematicAsset(
        id: 'opening',
        title: 'Opening',
        durationUs: 3000000,
        tracks: [
          PresentationTrack(
            id: 'audio',
            label: 'Audio',
            kind: PresentationTrackKind.audio,
            clips: [
              PresentationAudioClip(
                id: 'theme',
                startUs: 0,
                durationUs: 3000000,
                resourceId: 'media_theme',
                audioKind: PresentationAudioKind.music,
                volume: 0.8,
                loop: true,
                bus: PresentationAudioBus.music,
              ),
              if (withVoice)
                PresentationAudioClip(
                  id: 'narrator',
                  startUs: 1000000,
                  durationUs: 1000000,
                  resourceId: 'media_narrator',
                  audioKind: PresentationAudioKind.voice,
                  bus: PresentationAudioBus.voice,
                ),
            ],
          ),
        ],
      );

  ProjectMediaCatalog catalog() => ProjectMediaCatalog(
        entries: [
          ProjectMediaAsset(
            id: 'media_theme',
            label: 'Theme',
            kind: ProjectMediaKind.audio,
            sourceAssetId: 'asset_theme',
          ),
          ProjectMediaAsset(
            id: 'media_narrator',
            label: 'Narrator',
            kind: ProjectMediaKind.audio,
            sourceAssetId: 'asset_narrator',
          ),
        ],
      );

  ({
    RuntimePresentationAudioController controller,
    _RecordingAudioDriver driver,
    RuntimeAudioMixer mixer,
  }) build() {
    final driver = _RecordingAudioDriver();
    final mixer = RuntimeAudioMixer();
    final controller = RuntimePresentationAudioController(
      catalog: catalog(),
      resolveUri: (media) => Uri.file('/media/${media.id}.ogg'),
      driver: driver,
      mixer: mixer,
    );
    return (controller: controller, driver: driver, mixer: mixer);
  }

  const evaluator = PresentationCinematicEvaluator();

  test('a started channel plays through the mixer authority', () async {
    final harness = build();
    await harness.controller.synchronize(
      asset(),
      evaluator.evaluate(asset(), timeUs: 500000),
    );

    final handle = harness.driver.handles.single;
    expect(handle.loop, isTrue);
    expect(handle.positionUs, 500000);
    expect(
      handle.volume,
      closeTo(0.8, 1e-9),
      reason: 'the mixer applied master × bus × source on registration — the '
          'controller never sets a volume outside the mixer',
    );

    await harness.mixer.transitionTo(const RuntimeAudioMix(musicVolume: 0.5));
    expect(
      handle.volume,
      closeTo(0.4, 1e-9),
      reason: 'mute and volume apply to every source through the mixer',
    );
  });

  test('a hold pauses position-preserving and never restarts the loop',
      () async {
    final harness = build();
    await harness.controller.synchronize(
      asset(),
      evaluator.evaluate(asset(), timeUs: 500000),
    );
    final handle = harness.driver.handles.single;

    await harness.controller.pauseForHold();
    expect(handle.paused, isTrue);

    await harness.controller.resumeFromHold();
    expect(handle.paused, isFalse);
    expect(
      harness.driver.playCalls,
      1,
      reason: 'surviving an interactionHold means resume, NEVER a new play — '
          'a restart would be audible',
    );
    expect(handle.stopped, isFalse);
  });

  test('lifecycle suspension is independent from the hold', () async {
    final harness = build();
    await harness.controller.synchronize(
      asset(),
      evaluator.evaluate(asset(), timeUs: 500000),
    );
    final handle = harness.driver.handles.single;

    await harness.controller.pauseForHold();
    await harness.controller.pauseForLifecycle();
    await harness.controller.resumeFromHold();
    expect(
      handle.paused,
      isTrue,
      reason: 'the app is still backgrounded: releasing the hold alone must '
          'not resume anything',
    );
    await harness.controller.resumeAfterLifecycle();
    expect(handle.paused, isFalse);
    expect(harness.driver.playCalls, 1);
  });

  test('an active voice ducks the music and releases it after', () async {
    final harness = build();
    final voiced = asset(withVoice: true);
    await harness.controller.synchronize(
      voiced,
      evaluator.evaluate(voiced, timeUs: 500000),
    );
    final theme = harness.driver.handles.single;
    expect(harness.controller.isDucking, isFalse);

    await harness.controller.synchronize(
      voiced,
      evaluator.evaluate(voiced, timeUs: 1500000),
    );
    expect(harness.controller.isDucking, isTrue);
    expect(
      theme.volume,
      closeTo(0.8 * 0.35, 1e-9),
      reason: 'voice over music: the music bus is ducked through the mixer',
    );

    await harness.controller.synchronize(
      voiced,
      evaluator.evaluate(voiced, timeUs: 2500000),
    );
    expect(harness.controller.isDucking, isFalse);
    expect(theme.volume, closeTo(0.8, 1e-9));
  });

  test('an authored ambient loop keeps playing through the hold', () async {
    final harness = build();
    final ambient = PresentationCinematicAsset(
      id: 'opening',
      title: 'Opening',
      durationUs: 3000000,
      tracks: [
        PresentationTrack(
          id: 'music',
          label: 'Musique',
          kind: PresentationTrackKind.audio,
          holdPolicy: PresentationHoldTrackPolicy.ambientContinues,
          clips: [
            PresentationAudioClip(
              id: 'theme',
              startUs: 0,
              durationUs: 3000000,
              resourceId: 'media_theme',
              audioKind: PresentationAudioKind.music,
              volume: 0.8,
              loop: true,
            ),
          ],
        ),
        PresentationTrack(
          id: 'sfx',
          label: 'Effets',
          kind: PresentationTrackKind.audio,
          clips: [
            PresentationAudioClip(
              id: 'whoosh',
              startUs: 0,
              durationUs: 3000000,
              resourceId: 'media_narrator',
              audioKind: PresentationAudioKind.soundEffect,
              bus: PresentationAudioBus.effects,
            ),
          ],
        ),
      ],
    );
    await harness.controller.synchronize(
      ambient,
      const PresentationCinematicEvaluator().evaluate(ambient, timeUs: 500000),
    );
    final theme = harness.driver.handles
        .singleWhere((handle) => handle.uri.path.contains('media_theme'));
    final whoosh = harness.driver.handles
        .singleWhere((handle) => handle.uri.path.contains('media_narrator'));

    await harness.controller.pauseForHold();
    expect(
      theme.paused,
      isFalse,
      reason: 'authored ambience continues while the player reads or types',
    );
    expect(
      whoosh.paused,
      isTrue,
      reason: 'frozen tracks freeze — the default policy',
    );

    await harness.controller.pauseForLifecycle();
    expect(
      theme.paused,
      isTrue,
      reason: 'a real pause or background suspends EVERY track, ambience '
          'included',
    );

    await harness.controller.resumeAfterLifecycle();
    expect(theme.paused, isFalse);
    expect(
      whoosh.paused,
      isTrue,
      reason: 'the hold is still active: only the ambience returns',
    );

    await harness.controller.resumeFromHold();
    expect(whoosh.paused, isFalse);
    expect(harness.driver.playCalls, 2);
  });

  test('a media id missing from the catalog fails closed', () async {
    final driver = _RecordingAudioDriver();
    final controller = RuntimePresentationAudioController(
      catalog: ProjectMediaCatalog(),
      resolveUri: (media) => Uri.file('/media/${media.id}.ogg'),
      driver: driver,
      mixer: RuntimeAudioMixer(),
    );
    await expectLater(
      controller.synchronize(
        asset(),
        evaluator.evaluate(asset(), timeUs: 500000),
      ),
      throwsA(
        isA<RuntimePresentationAudioFailure>().having(
          (failure) => failure.diagnosticCode,
          'diagnosticCode',
          PresentationDiagnosticCodes.mediaMissing,
        ),
      ),
    );
    expect(driver.handles, isEmpty);
  });

  test('releasing leaves zero handles and ignores stale completions',
      () async {
    final harness = build();
    final voiced = asset(withVoice: true);
    await harness.controller.synchronize(
      voiced,
      evaluator.evaluate(voiced, timeUs: 1500000),
    );
    expect(harness.controller.activeChannelCount, 2);
    expect(harness.controller.isDucking, isTrue);

    await harness.controller.releaseAll();
    expect(harness.controller.activeChannelCount, 0);
    expect(harness.controller.isDucking, isFalse);
    for (final handle in harness.driver.handles) {
      expect(handle.stopped, isTrue);
    }

    await harness.controller.synchronize(voiced, null);
    expect(
      harness.driver.handles.where((handle) => !handle.stopped),
      isEmpty,
      reason: 'after leaving the presentation no audio handle may survive',
    );
  });

  test('a start racing the release is stopped, not leaked', () async {
    final harness = build();
    final gate = Completer<void>();
    harness.driver.playGate = gate.future;
    final synchronizing = harness.controller.synchronize(
      asset(),
      evaluator.evaluate(asset(), timeUs: 500000),
    );
    await harness.controller.releaseAll();
    gate.complete();
    await synchronizing;
    expect(harness.controller.activeChannelCount, 0);
    expect(
      harness.driver.handles.where((handle) => !handle.stopped),
      isEmpty,
      reason: 'the play completed after the epoch moved on: the stale handle '
          'must be stopped immediately, never registered',
    );
  });
}

final class _FakeAudioHandle {
  _FakeAudioHandle({
    required this.uri,
    required this.loop,
    required this.positionUs,
    required this.volume,
    this.mimeType,
  });

  final Uri uri;
  final bool loop;
  final int positionUs;
  final String? mimeType;
  double volume;
  bool paused = false;
  bool stopped = false;
}

final class _RecordingAudioDriver implements RuntimePresentationAudioDriver {
  final handles = <_FakeAudioHandle>[];
  var playCalls = 0;
  Future<void>? playGate;

  @override
  Future<Object> play(
    Uri source, {
    required double volume,
    required bool loop,
    required Duration position,
    String? mimeType,
  }) async {
    playCalls += 1;
    final gate = playGate;
    if (gate != null) await gate;
    final handle = _FakeAudioHandle(
      uri: source,
      loop: loop,
      positionUs: position.inMicroseconds,
      volume: volume,
      mimeType: mimeType,
    );
    handles.add(handle);
    return handle;
  }

  @override
  Future<void> pause(Object handle) async {
    (handle as _FakeAudioHandle).paused = true;
  }

  @override
  Future<void> resume(Object handle) async {
    (handle as _FakeAudioHandle).paused = false;
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {
    (handle as _FakeAudioHandle).volume = volume;
  }

  @override
  Future<void> stop(Object handle) async {
    (handle as _FakeAudioHandle).stopped = true;
  }
}
