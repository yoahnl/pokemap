import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('RuntimeInputAuthoritySnapshot', () {
    test('overworld accepts runtime and overworld input without external lock',
        () {
      const snapshot = RuntimeInputAuthoritySnapshot(
        context: RuntimeInputContext.overworld,
      );

      expect(snapshot.acceptsRuntimeInput, isTrue);
      expect(snapshot.acceptsOverworldInput, isTrue);
      expect(snapshot.isGameplayLocked, isFalse);
    });

    test('pause menu lock blocks every runtime input source', () {
      const snapshot = RuntimeInputAuthoritySnapshot(
        context: RuntimeInputContext.overworld,
        externalLocks: <RuntimeExternalInputLock>{
          RuntimeExternalInputLock.pauseMenu,
        },
      );

      expect(snapshot.acceptsRuntimeInput, isFalse);
      expect(snapshot.acceptsOverworldInput, isFalse);
      expect(snapshot.isGameplayLocked, isTrue);
    });

    test('dialogue accepts routed input but never overworld movement', () {
      const snapshot = RuntimeInputAuthoritySnapshot(
        context: RuntimeInputContext.dialogue,
      );

      expect(snapshot.acceptsRuntimeInput, isTrue);
      expect(snapshot.acceptsOverworldInput, isFalse);
      expect(snapshot.isGameplayLocked, isTrue);
    });
  });
}
