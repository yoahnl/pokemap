import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('RuntimeInputAuthoritySnapshot', () {
    test('sprint intent participates in observable snapshot equality', () {
      const idle =
          RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld);
      const allowed = RuntimeInputAuthoritySnapshot(
          context: RuntimeInputContext.overworld, sprintAllowed: true);
      const accepted = RuntimeInputAuthoritySnapshot(
          context: RuntimeInputContext.overworld,
          sprintAllowed: true,
          sprintAccepted: true);
      expect(idle.sprintAllowed, isFalse);
      expect(idle.sprintAccepted, isFalse);
      expect(allowed, isNot(idle));
      expect(accepted, isNot(allowed));
      expect({idle, allowed, accepted}, hasLength(3));
      expect(
          accepted,
          const RuntimeInputAuthoritySnapshot(
              context: RuntimeInputContext.overworld,
              sprintAllowed: true,
              sprintAccepted: true));
    });

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

    test('every modal runtime context rejects overworld movement', () {
      for (final context in RuntimeInputContext.values) {
        final snapshot = RuntimeInputAuthoritySnapshot(context: context);

        expect(
          snapshot.acceptsOverworldInput,
          context == RuntimeInputContext.overworld,
          reason: '${context.name} must have one explicit movement policy.',
        );
        expect(
          snapshot.isGameplayLocked,
          context != RuntimeInputContext.overworld,
          reason: '${context.name} must not leak input into the world.',
        );
      }
    });
  });
}
