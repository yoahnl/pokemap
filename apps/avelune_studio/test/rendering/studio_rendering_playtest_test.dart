import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/rendering/application/studio_rendering_preferences.dart';
import 'package:avelune_studio/platform/playtest/studio_game_playtest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

import '../../tool/create_example_project.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => AveluneFrameRate.setLimit(60));
  tearDown(() => AveluneFrameRate.setLimit(60));

  test(
    'playtest options await the same global preference persistence',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final before = await fixture.project.readAsBytes();
      await fixture.game.player.initialize();
      await fixture.openOptions();
      final initial = fixture.game.player.snapshot.preferences!;
      expect(initial.targetFramesPerSecond, 90);
      expect(
        fixture.game.player.snapshot.defaultPreferences.targetFramesPerSecond,
        60,
      );
      final presentation = fixture.game.presentation.controller;
      var completed = false;
      final updating = fixture.game.player
          .dispatch(
            RuntimePlayerCommand(
              action: RuntimePlayerAction.updatePreferences,
              snapshotRevision: fixture.game.player.snapshot.revision,
              payload: initial.copyWith(targetFramesPerSecond: 45),
            ),
          )
          .then((result) {
            completed = true;
            return result;
          });
      await fixture.store.writeStarted.future;

      expect(AveluneFrameRate.limit, 45);
      expect(completed, isFalse);
      expect(fixture.preferences.saving, isTrue);
      fixture.store.pending.complete();
      final result = await updating;

      expect(result.status, RuntimePlayerCommandStatus.accepted);
      expect(fixture.store.value, 45);
      expect(fixture.store.reads, 1);
      expect(fixture.store.writes, [45]);
      expect(fixture.game.presentation.controller, same(presentation));
      expect(await fixture.project.readAsBytes(), before);
    },
  );

  test(
    'failed playtest preference save rolls back and remains failed',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      await fixture.game.player.initialize();
      await fixture.openOptions();
      final initial = fixture.game.player.snapshot.preferences!;
      final updating = fixture.game.player.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.updatePreferences,
          snapshotRevision: fixture.game.player.snapshot.revision,
          payload: initial.copyWith(targetFramesPerSecond: 30),
        ),
      );
      await fixture.store.writeStarted.future;
      fixture.store.pending.completeError(StateError('Disk unavailable'));
      final result = await updating;

      expect(result.status, RuntimePlayerCommandStatus.failed);
      expect(AveluneFrameRate.limit, 90);
      expect(fixture.preferences.limit, 90);
      expect(fixture.store.value, 90);
      expect(
        fixture.game.player.snapshot.preferences!.targetFramesPerSecond,
        90,
      );
      expect(fixture.preferences.error, isNotNull);
    },
  );

  test(
    'an older playtest write cannot replace a newer queued Studio choice',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      await fixture.game.player.initialize();
      await fixture.openOptions();
      final initial = fixture.game.player.snapshot.preferences!;
      final updating = fixture.game.player.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.updatePreferences,
          snapshotRevision: fixture.game.player.snapshot.revision,
          payload: initial.copyWith(targetFramesPerSecond: 45),
        ),
      );
      await fixture.store.writeStarted.future;
      final newer = fixture.preferences.setLimit(120);
      expect(AveluneFrameRate.limit, 120);
      fixture.store.pending.complete();
      final result = await updating;
      await fixture.store.secondWriteStarted.future;
      final limitAfterOlderWrite = AveluneFrameRate.limit;
      fixture.store.pendingWrites[1].complete();
      await newer;

      expect(result.status, RuntimePlayerCommandStatus.accepted);
      expect(limitAfterOlderWrite, 120);
      expect(AveluneFrameRate.limit, 120);
      expect(fixture.preferences.limit, 120);
      expect(
        fixture.game.player.snapshot.preferences!.targetFramesPerSecond,
        120,
      );
      expect(fixture.store.value, 120);
      expect(fixture.store.writes, [45, 120]);
      expect(fixture.store.reads, 1);
    },
  );

  test(
    'an audio-only save cannot overwrite a Studio choice made during audio IO',
    () async {
      final fixture = await _Fixture.create(controlWrites: false);
      addTearDown(fixture.dispose);
      await fixture.game.player.initialize();
      await fixture.openOptions();
      final audioStarted = Completer<void>();
      final releaseAudio = Completer<void>();
      addTearDown(() {
        if (!releaseAudio.isCompleted) releaseAudio.complete();
      });
      final channel = Object();
      await fixture.game.audioMixer.register(
        channel: channel,
        route: RuntimeAudioRoute.title,
        applyImmediately: false,
        setVolume: (_) async {
          if (!audioStarted.isCompleted) audioStarted.complete();
          await releaseAudio.future;
        },
      );
      addTearDown(() => fixture.game.audioMixer.unregister(channel));
      final initial = fixture.game.player.snapshot.preferences!;
      final updating = fixture.game.player.dispatch(
        RuntimePlayerCommand(
          action: RuntimePlayerAction.updatePreferences,
          snapshotRevision: fixture.game.player.snapshot.revision,
          payload: initial.copyWith(
            audioMix: const RuntimeAudioMix(masterVolume: .25),
          ),
        ),
      );
      await audioStarted.future;
      await fixture.preferences.setLimit(120);
      releaseAudio.complete();
      final result = await updating;

      expect(result.status, RuntimePlayerCommandStatus.accepted);
      expect(AveluneFrameRate.limit, 120);
      expect(fixture.store.value, 120);
      expect(fixture.store.writes, [120]);
      expect(fixture.store.reads, 1);
      expect(
        fixture.game.player.snapshot.preferences!.targetFramesPerSecond,
        120,
      );
      expect(fixture.game.audioMixer.mix.masterVolume, .25);
    },
  );

  test('a frame-rate-only choice does not touch live audio channels', () async {
    final fixture = await _Fixture.create(controlWrites: false);
    addTearDown(fixture.dispose);
    await fixture.game.player.initialize();
    await fixture.openOptions();
    var audioCalls = 0;
    final channel = Object();
    await fixture.game.audioMixer.register(
      channel: channel,
      route: RuntimeAudioRoute.title,
      applyImmediately: false,
      setVolume: (_) async {
        audioCalls++;
        throw StateError('Audio must remain untouched');
      },
    );
    addTearDown(() => fixture.game.audioMixer.unregister(channel));
    final initial = fixture.game.player.snapshot.preferences!;

    final result = await fixture.game.player.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.updatePreferences,
        snapshotRevision: fixture.game.player.snapshot.revision,
        payload: initial.copyWith(targetFramesPerSecond: 45),
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(audioCalls, 0);
    expect(AveluneFrameRate.limit, 45);
    expect(fixture.store.writes, [45]);
  });

  test(
    'an active options snapshot follows a global Studio change without saving',
    () async {
      final fixture = await _Fixture.create(controlWrites: false);
      addTearDown(fixture.dispose);
      await fixture.game.player.initialize();
      await fixture.openOptions();

      await fixture.preferences.setLimit(120);
      await fixture.game.player.settle();

      expect(
        fixture.game.player.snapshot.preferences!.targetFramesPerSecond,
        120,
      );
      expect(fixture.store.reads, 1);
      expect(fixture.store.writes, [120]);
    },
  );
}

class _Fixture {
  _Fixture(this.root, this.store, this.preferences, this.game);

  final Directory root;
  final _Store store;
  final StudioRenderingPreferences preferences;
  final StudioGamePlaytest game;

  File get project => File('${root.path}/project.json');

  static Future<_Fixture> create({bool controlWrites = true}) async {
    final root = await Directory.systemTemp.createTemp('studio-fps-playtest-');
    await writeExampleProject(root);
    final store = _Store(controlWrites: controlWrites);
    final preferences = StudioRenderingPreferences(store);
    await preferences.load();
    final game = await StudioGamePlaytest.prepare(
      projectFilePath: '${root.path}/project.json',
      renderingPreferences: preferences,
      onExit: () async {},
      mountGame: (_) async {},
      unmountGame: (_) async {},
      mountSpatial: (_) async {},
      unmountSpatial: (_) async {},
    );
    return _Fixture(root, store, preferences, game);
  }

  Future<void> openOptions() async {
    final result = await game.player.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.openOptions,
        snapshotRevision: game.player.snapshot.revision,
      ),
    );
    expect(result.status, RuntimePlayerCommandStatus.accepted);
  }

  Future<void> dispose() async {
    await game.dispose();
    preferences.dispose();
    await root.delete(recursive: true);
  }
}

final class _Store implements StudioRenderingPreferencesStore {
  _Store({required this.controlWrites});

  final bool controlWrites;
  int value = 90;
  int reads = 0;
  final writes = <int>[];
  final writeStarted = Completer<void>();
  final secondWriteStarted = Completer<void>();
  final pending = Completer<void>();
  final pendingWrites = <Completer<void>>[];

  @override
  Future<int?> load() async {
    reads++;
    return value;
  }

  @override
  Future<void> save(int limit) async {
    writes.add(limit);
    if (!writeStarted.isCompleted) writeStarted.complete();
    if (writes.length == 2) secondWriteStarted.complete();
    if (controlWrites) {
      final completion = writes.length == 1 ? pending : Completer<void>();
      pendingWrites.add(completion);
      await completion.future;
    }
    value = limit;
  }
}
