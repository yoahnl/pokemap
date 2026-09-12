import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('session forwards current interactions and revokes them during teardown',
      () async {
    final runtimes = <_InteractionRuntime>[];
    final controller = GameSessionController(
      adapterFactory: (_) => InProcessGameSessionAdapter(
        runtimeFactory: (descriptor) {
          final runtime = _InteractionRuntime(descriptor.sessionId);
          runtimes.add(runtime);
          return runtime;
        },
      ),
      commitCheckpoint: (_) async {},
    );
    final snapshots = <RuntimeOverworldInteractionSnapshot?>[];
    final subscription =
        controller.overworldInteractionSnapshots.listen(snapshots.add);
    addTearDown(subscription.cancel);
    addTearDown(controller.dispose);

    expect(controller.overworldInteractionSnapshot, isNull);
    expect(
        controller.dispatchOverworldInteraction(
            _interaction('missing').primaryAction!.request),
        isFalse);
    await controller.prepare(_descriptor('session-a'));
    expect(controller.overworldInteractionSnapshot, isNull);
    await controller.start();
    await controller.settle();
    final first = runtimes.single.overworldInteractionSnapshot!;
    final request = first.primaryAction!.request;
    expect(controller.overworldInteractionSnapshot, same(first));
    expect(controller.dispatchOverworldInteraction(request), isTrue);
    expect(runtimes.single.requests, [request]);

    await controller.pause();
    expect(controller.overworldInteractionSnapshot, isNull);
    expect(controller.dispatchOverworldInteraction(request), isFalse);
    await controller.resume();
    expect(controller.overworldInteractionSnapshot, same(first));
    runtimes.single.publish(null);
    await Future<void>.delayed(Duration.zero);
    expect(controller.overworldInteractionSnapshot, isNull);
    expect(snapshots.last, isNull);
    expect(controller.dispatchOverworldInteraction(request), isFalse);

    await controller.returnToTitle(checkpoint: false);
    expect(controller.overworldInteractionSnapshot, isNull);
    expect(controller.dispatchOverworldInteraction(request), isFalse);
    await controller.prepare(_descriptor('session-b'));
    await controller.start();
    await controller.settle();
    expect(controller.overworldInteractionSnapshot!.sessionId, 'session-b');
    expect(controller.dispatchOverworldInteraction(request), isFalse);
    expect(
        controller.dispatchOverworldInteraction(
            runtimes.last.overworldInteractionSnapshot!.primaryAction!.request),
        isTrue);
    await controller.terminate();
    expect(controller.overworldInteractionSnapshot, isNull);
  });

  test('in-process interaction capability rejects absent and stopped runtimes',
      () async {
    final runtime = _InteractionRuntime('session-a');
    final adapter = InProcessGameSessionAdapter(runtimeFactory: (_) => runtime);
    final request = _interaction('session-a').primaryAction!.request;
    expect(adapter.overworldInteractionSnapshot, isNull);
    expect(adapter.dispatchOverworldInteraction(request), isFalse);
    await adapter.prepare(_descriptor('session-a'));
    await adapter.start();
    expect(adapter.dispatchOverworldInteraction(request), isTrue);
    await adapter.stop(GameSessionExitReason.hub);
    expect(adapter.overworldInteractionSnapshot, isNull);
    expect(adapter.dispatchOverworldInteraction(request), isFalse);
    await adapter.dispose();
    expect(adapter.overworldInteractionSnapshot, isNull);
    expect(adapter.dispatchOverworldInteraction(request), isFalse);
  });
}

RuntimeOverworldInteractionSnapshot _interaction(String sessionId) =>
    RuntimeOverworldInteractionSnapshot(
      sessionId: sessionId,
      mapActivationId: '$sessionId:activation',
      mapId: 'map-start',
      primaryAction: RuntimeOverworldInteractionAction(
        request: RuntimeOverworldInteractionRequest(
          sessionId: sessionId,
          mapActivationId: '$sessionId:activation',
          mapId: 'map-start',
          targetKind: RuntimeOverworldInteractionTargetKind.entity,
          targetId: 'npc-guide',
          actionId: 'talk',
        ),
        verb: RuntimeOverworldInteractionVerb.talk,
        targetCell: const GridPos(x: 1, y: 2),
        targetBounds:
            const PixelRect(leftPx: 32, topPx: 64, widthPx: 32, heightPx: 32),
      ),
    );

GameSessionDescriptor _descriptor(String sessionId) => GameSessionDescriptor(
      sessionId: sessionId,
      sessionToken: 'secret',
      identity: GameIdentity(
          gameId: 'org.example.adventure',
          gameVersion: '1.0.0',
          projectFormat: ProjectFormat.v2,
          saveFormat: 1,
          compatibilityId: 'story-v1'),
      profileId: 'player-1',
      slotId: 'slot-1',
      launchMode: GameSessionLaunchMode.newGame,
      installedVersionHandle: 'install-a',
      runtimeApiVersion: '1.0.0',
      grantedCapabilities: const {},
      locale: 'fr-FR',
      accessibility: const GameSessionAccessibilityOptions(),
      initialGameState:
          const GameState(saveId: 'slot-1', currentMapId: 'map-start'),
    );

final class _InteractionRuntime
    implements InProcessGameSessionRuntime, RuntimeOverworldInteractionPort {
  _InteractionRuntime(this.sessionId);
  final String sessionId;
  final _events = StreamController<GameSessionAdapterEvent>.broadcast();
  final _interactions =
      StreamController<RuntimeOverworldInteractionSnapshot?>.broadcast();
  final requests = <RuntimeOverworldInteractionRequest>[];
  @override
  RuntimeOverworldInteractionSnapshot? overworldInteractionSnapshot;
  @override
  Stream<RuntimeOverworldInteractionSnapshot?>
      get overworldInteractionSnapshots => _interactions.stream;
  @override
  Stream<GameSessionAdapterEvent> get events => _events.stream;
  void publish(RuntimeOverworldInteractionSnapshot? snapshot) {
    overworldInteractionSnapshot = snapshot;
    _interactions.add(snapshot);
  }

  @override
  bool dispatchOverworldInteraction(
      RuntimeOverworldInteractionRequest request) {
    if (request != overworldInteractionSnapshot?.primaryAction?.request) {
      return false;
    }
    requests.add(request);
    return true;
  }

  @override
  Future<void> load(GameSessionProgressReporter reportProgress) async =>
      publish(_interaction(sessionId));
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<GameSessionCheckpoint?> captureCheckpoint() async => null;
  @override
  Future<void> lockGameplayForCompletion() async {}
  @override
  Future<void> acknowledgeCompletion({required bool accepted}) async {}
  @override
  Future<void> stop(GameSessionExitReason reason) async {}
  @override
  Future<void> dispose() async {
    await _events.close();
    await _interactions.close();
  }

  @override
  bool handleInput(RuntimeInputEvent event) => false;
}
