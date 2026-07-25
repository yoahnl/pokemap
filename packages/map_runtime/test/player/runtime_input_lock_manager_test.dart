import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('RuntimeInputLockManager', () {
    test('only the owner can release a token and release is idempotent', () {
      final manager = RuntimeInputLockManager();
      final pause = manager.acquire(
        owner: RuntimeInputLockOwner.pauseMenu,
        surface: RuntimeInputSurface.pause,
      );

      expect(
        manager.release(
          owner: RuntimeInputLockOwner.playerService,
          token: pause,
        ),
        isFalse,
      );
      expect(manager.snapshot.activeSurface, RuntimeInputSurface.pause);
      expect(
        manager.release(
          owner: RuntimeInputLockOwner.pauseMenu,
          token: pause,
        ),
        isTrue,
      );
      expect(
        manager.release(
          owner: RuntimeInputLockOwner.pauseMenu,
          token: pause,
        ),
        isFalse,
      );
      expect(manager.snapshot.acceptsOverworldInput, isTrue);
    });

    test('background layers over pause and reveals pause when released', () {
      final manager = RuntimeInputLockManager();
      final pause = manager.acquire(
        owner: RuntimeInputLockOwner.pauseMenu,
        surface: RuntimeInputSurface.pause,
      );
      final background = manager.acquire(
        owner: RuntimeInputLockOwner.lifecycle,
        surface: RuntimeInputSurface.background,
      );

      expect(manager.snapshot.activeSurface, RuntimeInputSurface.background);
      expect(
        manager.snapshot.isOwnedBy(RuntimeInputLockOwner.pauseMenu),
        isTrue,
      );

      manager.release(
        owner: RuntimeInputLockOwner.lifecycle,
        token: background,
      );
      expect(manager.snapshot.activeSurface, RuntimeInputSurface.pause);

      manager.release(
        owner: RuntimeInputLockOwner.pauseMenu,
        token: pause,
      );
      expect(manager.snapshot.activeSurface, RuntimeInputSurface.world);
    });

    test('background layers over dialogue without releasing dialogue', () {
      final manager = RuntimeInputLockManager();
      final dialogue = manager.acquire(
        owner: RuntimeInputLockOwner.dialogue,
        surface: RuntimeInputSurface.dialogue,
      );
      final background = manager.acquire(
        owner: RuntimeInputLockOwner.lifecycle,
        surface: RuntimeInputSurface.background,
      );

      manager.release(
        owner: RuntimeInputLockOwner.lifecycle,
        token: background,
      );

      expect(manager.snapshot.activeSurface, RuntimeInputSurface.dialogue);
      expect(
        manager.snapshot.isOwnedBy(RuntimeInputLockOwner.dialogue),
        isTrue,
      );
      expect(
        manager.release(
          owner: RuntimeInputLockOwner.dialogue,
          token: dialogue,
        ),
        isTrue,
      );
    });

    test('combat and progression outrank service pause and world', () {
      final manager = RuntimeInputLockManager();
      final pause = manager.acquire(
        owner: RuntimeInputLockOwner.pauseMenu,
        surface: RuntimeInputSurface.pause,
      );
      final service = manager.acquire(
        owner: RuntimeInputLockOwner.playerService,
        surface: RuntimeInputSurface.playerService,
      );
      final battle = manager.acquire(
        owner: RuntimeInputLockOwner.battle,
        surface: RuntimeInputSurface.battle,
      );
      final progression = manager.acquire(
        owner: RuntimeInputLockOwner.postBattleProgression,
        surface: RuntimeInputSurface.progression,
      );

      expect(manager.snapshot.activeSurface, RuntimeInputSurface.progression);
      manager.release(
        owner: RuntimeInputLockOwner.postBattleProgression,
        token: progression,
      );
      expect(manager.snapshot.activeSurface, RuntimeInputSurface.battle);
      manager.release(owner: RuntimeInputLockOwner.battle, token: battle);
      expect(manager.snapshot.activeSurface, RuntimeInputSurface.playerService);
      manager.release(
        owner: RuntimeInputLockOwner.playerService,
        token: service,
      );
      expect(manager.snapshot.activeSurface, RuntimeInputSurface.pause);
      manager.release(owner: RuntimeInputLockOwner.pauseMenu, token: pause);
      expect(manager.snapshot.activeSurface, RuntimeInputSurface.world);
    });

    test('runLocked releases a service token when the action throws', () async {
      final manager = RuntimeInputLockManager();

      await expectLater(
        manager.runLocked<void>(
          owner: RuntimeInputLockOwner.playerService,
          surface: RuntimeInputSurface.playerService,
          action: () => throw StateError('service failed'),
        ),
        throwsStateError,
      );

      expect(manager.snapshot.acceptsOverworldInput, isTrue);
      expect(manager.snapshot.activeTokens, isEmpty);
    });
  });
}
