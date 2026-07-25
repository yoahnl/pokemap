import 'dart:async';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late GameIdentity identity;
  late HubSaveStore store;
  late SaveEnvelope checkpoint;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pokemap-lifecycle-');
    identity = GameIdentity(
      gameId: 'games.example.lifecycle',
      gameVersion: '1.0.0',
      projectFormat: ProjectFormat.v2,
      saveFormat: 1,
      compatibilityId: 'campaign-v1',
    );
    store = HubSaveStore(supportRoot: root, identity: identity);
    checkpoint = _checkpoint(identity);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('background suspends first, commits checkpoint, then acknowledges',
      () async {
    final calls = <String>[];
    final coordinator = HubSaveLifecycleCoordinator(
      suspendSession: () async => calls.add('suspend'),
      captureCheckpoint: () async {
        calls.add('capture');
        return checkpoint;
      },
      persistCheckpoint: (save) async {
        calls.add('persist');
        await store.write(save);
      },
      validateSession: () async => true,
      resumeSession: () async => calls.add('resume'),
      checkpointTimeout: const Duration(seconds: 1),
    );

    final result = await coordinator.onBackgrounded();

    expect(result.code, HubLifecycleResultCode.checkpointSaved);
    expect(result.acknowledged, isTrue);
    expect(calls, <String>['suspend', 'capture', 'persist']);
    expect(
      (await store.read(checkpoint.address)).envelope,
      checkpoint,
    );
  });

  test('timeout acknowledges background and preserves the previous save',
      () async {
    final previous = _checkpoint(identity, marker: 'previous');
    await store.write(previous);
    final capture = Completer<SaveEnvelope?>();
    final coordinator = HubSaveLifecycleCoordinator(
      suspendSession: () async {},
      captureCheckpoint: () => capture.future,
      persistCheckpoint: store.write,
      validateSession: () async => true,
      resumeSession: () async {},
      checkpointTimeout: const Duration(milliseconds: 20),
    );

    final result = await coordinator.onBackgrounded();

    expect(result.code, HubLifecycleResultCode.checkpointTimedOut);
    expect(result.acknowledged, isTrue);
    expect(
      (await store.read(previous.address)).envelope!.state['marker'],
      'previous',
    );
  });

  test('coalesces concurrent background notifications', () async {
    var suspends = 0;
    var captures = 0;
    final gate = Completer<void>();
    final coordinator = HubSaveLifecycleCoordinator(
      suspendSession: () async => suspends++,
      captureCheckpoint: () async {
        captures++;
        await gate.future;
        return checkpoint;
      },
      persistCheckpoint: store.write,
      validateSession: () async => true,
      resumeSession: () async {},
      checkpointTimeout: const Duration(seconds: 1),
    );

    final first = coordinator.onBackgrounded();
    final second = coordinator.onBackgrounded();
    expect(identical(first, second), isTrue);
    gate.complete();
    await Future.wait(<Future<HubLifecycleResult>>[first, second]);

    expect(suspends, 1);
    expect(captures, 1);
  });

  test('foreground resumes only after session/version revalidation', () async {
    var resumed = false;
    final coordinator = HubSaveLifecycleCoordinator(
      suspendSession: () async {},
      captureCheckpoint: () async => null,
      persistCheckpoint: store.write,
      validateSession: () async => false,
      resumeSession: () async => resumed = true,
      checkpointTimeout: const Duration(seconds: 1),
    );

    final result = await coordinator.onForegrounded();

    expect(result.code, HubLifecycleResultCode.sessionInvalid);
    expect(resumed, isFalse);
  });

  test('exit waits for commit or requires explicit abandonment', () async {
    final coordinator = HubSaveLifecycleCoordinator(
      suspendSession: () async {},
      captureCheckpoint: () async => throw StateError('capture failed'),
      persistCheckpoint: store.write,
      validateSession: () async => true,
      resumeSession: () async {},
      checkpointTimeout: const Duration(seconds: 1),
    );

    final blocked = await coordinator.requestExit(
      abandonUnsavedChanges: false,
    );
    final abandoned = await coordinator.requestExit(
      abandonUnsavedChanges: true,
    );

    expect(blocked.code, HubLifecycleResultCode.exitBlocked);
    expect(blocked.acknowledged, isFalse);
    expect(abandoned.code, HubLifecycleResultCode.exitAllowedAfterAbandon);
    expect(abandoned.acknowledged, isTrue);
  });

  test('successful foreground revalidation resumes clocks and input', () async {
    final calls = <String>[];
    final coordinator = HubSaveLifecycleCoordinator(
      suspendSession: () async {},
      captureCheckpoint: () async => null,
      persistCheckpoint: store.write,
      validateSession: () async {
        calls.add('validate');
        return true;
      },
      resumeSession: () async => calls.add('resume'),
      checkpointTimeout: const Duration(seconds: 1),
    );

    final result = await coordinator.onForegrounded();

    expect(result.code, HubLifecycleResultCode.sessionResumed);
    expect(calls, <String>['validate', 'resume']);
  });
}

SaveEnvelope _checkpoint(
  GameIdentity identity, {
  String marker = 'checkpoint',
}) =>
    const SaveEnvelopeCodec().create(
      identity: identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
      createdAt: DateTime.utc(2026, 7, 25, 10),
      updatedAt: DateTime.utc(2026, 7, 25, 10),
      status: SaveStatus.active,
      playTimeSeconds: 1,
      state: <String, Object?>{'marker': marker},
    );
