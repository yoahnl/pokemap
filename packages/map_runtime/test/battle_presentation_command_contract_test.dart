import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('BattlePresentationCommand', () {
    test('accepts an enabled entry from the current snapshot', () {
      final snapshot = _snapshot();

      final result = validateBattlePresentationCommand(
        snapshot,
        const BattleSelectEntryCommand(
          snapshotRevision: 7,
          expectedMode: BattleCommandOverlayMode.pokemon,
          entryIndex: 1,
        ),
      );

      expect(result.accepted, isTrue);
      expect(result.rejection, isNull);
    });

    test('rejects stale, mismatched and disabled commands', () {
      final snapshot = _snapshot();

      expect(
        validateBattlePresentationCommand(
          snapshot,
          const BattleSelectEntryCommand(
            snapshotRevision: 6,
            expectedMode: BattleCommandOverlayMode.pokemon,
            entryIndex: 1,
          ),
        ).rejection,
        BattlePresentationCommandRejection.staleSnapshot,
      );
      expect(
        validateBattlePresentationCommand(
          snapshot,
          const BattleSelectEntryCommand(
            snapshotRevision: 7,
            expectedMode: BattleCommandOverlayMode.bag,
            entryIndex: 1,
          ),
        ).rejection,
        BattlePresentationCommandRejection.modeMismatch,
      );
      expect(
        validateBattlePresentationCommand(
          snapshot,
          const BattleSelectEntryCommand(
            snapshotRevision: 7,
            expectedMode: BattleCommandOverlayMode.pokemon,
            entryIndex: 0,
          ),
        ).rejection,
        BattlePresentationCommandRejection.entryDisabled,
      );
    });

    test('forced replacement cannot be dismissed with back', () {
      final snapshot = _snapshot();

      expect(snapshot.phase, BattlePresentationPhase.forcedReplacement);
      expect(snapshot.forcedReplacement, isTrue);
      expect(
        validateBattlePresentationCommand(
          snapshot,
          const BattleBackCommand(
            snapshotRevision: 7,
            expectedMode: BattleCommandOverlayMode.pokemon,
          ),
        ).rejection,
        BattlePresentationCommandRejection.backUnavailable,
      );
    });
  });
}

BattleCommandOverlaySnapshot _snapshot() {
  return BattleCommandOverlaySnapshot(
    revision: 7,
    phase: BattlePresentationPhase.forcedReplacement,
    forcedReplacement: true,
    mode: BattleCommandOverlayMode.pokemon,
    panelRect: const Rect.fromLTWH(8, 120, 304, 180),
    enemyHud: _hud(isPlayerSide: false),
    playerHud: _hud(isPlayerSide: true),
    battleLabel: 'COMBAT',
    title: 'ÉQUIPE',
    prompt: 'Choisissez un remplaçant.',
    narrationLines: const <String>[],
    entries: const <BattleCommandOverlayEntry>[
      BattleCommandOverlayEntry(
        index: 0,
        kind: BattleCommandOverlayEntryKind.party,
        primaryLabel: 'Bulbizarre',
        secondaryLabel: 'K.O.',
        enabled: false,
        selected: false,
        tone: BattleCommandOverlayEntryTone.disabled,
      ),
      BattleCommandOverlayEntry(
        index: 1,
        kind: BattleCommandOverlayEntryKind.party,
        primaryLabel: 'Carapuce',
        secondaryLabel: 'PV 31/31',
        enabled: true,
        selected: true,
        tone: BattleCommandOverlayEntryTone.switching,
      ),
    ],
    interactionsEnabled: true,
    canGoBack: false,
  );
}

BattleCommandOverlayHudSnapshot _hud({required bool isPlayerSide}) {
  return BattleCommandOverlayHudSnapshot(
    rect: const Rect.fromLTWH(8, 8, 140, 54),
    ownerLabel: isPlayerSide ? 'JOUEUR' : 'ENNEMI',
    speciesLabel: isPlayerSide ? 'Bulbizarre' : 'Roucool',
    level: 5,
    currentHp: 20,
    maxHp: 20,
    isPlayerSide: isPlayerSide,
  );
}
