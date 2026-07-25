import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('snapshot exposes enabled and disabled actions explicitly', () {
    final snapshot = RuntimePlayerSnapshot(
      revision: 7,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Contract Test',
      pauseSection: RuntimePlayerPauseSection.root,
      actions: <RuntimePlayerActionAvailability>[
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.resume,
        ),
        RuntimePlayerActionAvailability.disabled(
          RuntimePlayerAction.openPokedex,
          reason: 'Le Pokédex n’est pas encore disponible.',
        ),
      ],
      logicalSelectionId: 'pause.resume',
      activeInputSource: PlayerInputSource.keyboard,
    );

    expect(snapshot.isActionEnabled(RuntimePlayerAction.resume), isTrue);
    expect(snapshot.isActionEnabled(RuntimePlayerAction.openPokedex), isFalse);
    expect(
      snapshot.unavailableReasonFor(RuntimePlayerAction.openPokedex),
      'Le Pokédex n’est pas encore disponible.',
    );
    expect(snapshot.logicalSelectionId, 'pause.resume');
    expect(snapshot.activeInputSource, PlayerInputSource.keyboard);
  });

  test('next increments the revision and preserves unchanged player state', () {
    final snapshot = RuntimePlayerSnapshot(
      revision: 3,
      phase: RuntimePlayerPhase.playing,
      gameTitle: 'Contract Test',
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu),
      ],
    );

    final next = snapshot.next(
      phase: RuntimePlayerPhase.paused,
      pauseSection: RuntimePlayerPauseSection.root,
      logicalSelectionId: 'pause.resume',
    );

    expect(next.revision, 4);
    expect(next.phase, RuntimePlayerPhase.paused);
    expect(next.gameTitle, 'Contract Test');
    expect(next.pauseSection, RuntimePlayerPauseSection.root);
    expect(next.logicalSelectionId, 'pause.resume');
    expect(
      next.isActionEnabled(RuntimePlayerAction.openMenu),
      isTrue,
    );
  });

  test('snapshot owns immutable action state', () {
    final actions = <RuntimePlayerActionAvailability>[
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.newGame,
      ),
    ];
    final snapshot = RuntimePlayerSnapshot(
      revision: 0,
      phase: RuntimePlayerPhase.title,
      gameTitle: 'Contract Test',
      actions: actions,
    );

    actions.clear();

    expect(snapshot.actions, hasLength(1));
    expect(
      () => snapshot.actions.add(
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.returnToHost,
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('commands retain the exact source snapshot revision', () {
    const command = RuntimePlayerCommand(
      action: RuntimePlayerAction.load,
      snapshotRevision: 11,
      payload: RuntimePlayerLoadSlot(
        profileId: 'player',
        slotId: 'slot_2',
      ),
    );

    expect(command.action, RuntimePlayerAction.load);
    expect(command.snapshotRevision, 11);
    expect(
      command.payload,
      const RuntimePlayerLoadSlot(
        profileId: 'player',
        slotId: 'slot_2',
      ),
    );
  });

  test('invalid revisions and contradictory availability are rejected', () {
    expect(
      () => RuntimePlayerSnapshot(
        revision: -1,
        phase: RuntimePlayerPhase.boot,
        gameTitle: 'Contract Test',
      ),
      throwsArgumentError,
    );
    expect(
      () => RuntimePlayerCommand(
        action: RuntimePlayerAction.cancel,
        snapshotRevision: -1,
      ),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => RuntimePlayerActionAvailability.disabled(
        RuntimePlayerAction.openMap,
        reason: '  ',
      ),
      throwsArgumentError,
    );
  });

  test('duplicate action declarations are rejected', () {
    expect(
      () => RuntimePlayerSnapshot(
        revision: 0,
        phase: RuntimePlayerPhase.title,
        gameTitle: 'Contract Test',
        actions: <RuntimePlayerActionAvailability>[
          const RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.newGame,
          ),
          RuntimePlayerActionAvailability.disabled(
            RuntimePlayerAction.newGame,
            reason: 'Indisponible.',
          ),
        ],
      ),
      throwsArgumentError,
    );
  });
}
