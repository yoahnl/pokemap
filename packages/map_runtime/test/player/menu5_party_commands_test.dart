import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  for (final command in [
    const RuntimePlayerPauseCommand.equipHeldItem(
      itemTargetId: 'leftovers',
      partyTargetId: 'pokemon.member',
    ),
    const RuntimePlayerPauseCommand.unequipHeldItem(
      partyTargetId: 'pokemon.member',
    ),
  ]) {
    test('${command.kind.name} refreshes party without opening bag', () async {
      final harness = RuntimePlayerTestHarness();
      addTearDown(harness.dispose);
      await _openParty(harness);
      final updated = RuntimePlayerDetailEntrySnapshot(
        id: 'pokemon.member',
        title: 'Updated member',
      );
      harness.adapter.pauseDetails = _details(updated);

      final result = await _dispatch(harness, command);

      expect(result.status, RuntimePlayerCommandStatus.accepted);
      expect(harness.adapter.pauseCommands, [command]);
      expect(harness.coordinator.snapshot.pauseSection,
          RuntimePlayerPauseSection.party);
      final detail = harness.coordinator.snapshot
          .pauseDetailFor(RuntimePlayerPauseSection.party)!;
      expect(detail.entries.single, same(updated));
      expect(detail.message, harness.adapter.pauseCommandResult.safeMessage);
      expect(harness.coordinator.snapshot.logicalSelectionId, 'pause.party');
    });
  }

  test('held item remains available with party visible and bag hidden',
      () async {
    final harness = RuntimePlayerTestHarness(
      defaultVisiblePauseActions: {ProjectPauseActionId.party},
    );
    addTearDown(harness.dispose);
    await _openParty(harness);

    final result = await _dispatch(
      harness,
      const RuntimePlayerPauseCommand.unequipHeldItem(
        partyTargetId: 'pokemon.member',
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(
        harness.coordinator.snapshot
            .isActionEnabled(RuntimePlayerAction.openBag),
        isFalse);
    expect(harness.adapter.pauseCommands, hasLength(1));
  });

  test('refused held item publishes safe feedback on the current party',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await _openParty(harness);
    harness.adapter.pauseCommandResult = const RuntimePlayerPauseCommandResult(
      status: RuntimePlayerPauseCommandStatus.unavailable,
      safeMessage: 'Cette cible n’est plus disponible.',
    );

    final result = await _dispatch(
      harness,
      const RuntimePlayerPauseCommand.unequipHeldItem(
        partyTargetId: 'pokemon.removed',
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.unavailable);
    expect(harness.coordinator.snapshot.pauseSection,
        RuntimePlayerPauseSection.party);
    expect(
        harness.coordinator.snapshot
            .pauseDetailFor(RuntimePlayerPauseSection.party)!
            .message,
        'Cette cible n’est plus disponible.');
  });

  for (final command in [
    const RuntimePlayerPauseCommand.useBagItem(
      itemTargetId: 'potion',
      partyTargetId: 'pokemon.member',
    ),
    const RuntimePlayerPauseCommand.reorderPartyMember(
      partyTargetId: 'pokemon.member',
      secondPartyTargetId: 'pokemon.other',
    ),
  ]) {
    test('party bag channel rejects ${command.kind.name}', () async {
      final harness = RuntimePlayerTestHarness();
      addTearDown(harness.dispose);
      await _openParty(harness);

      final result = await _dispatch(harness, command);

      expect(result.status, RuntimePlayerCommandStatus.unavailable);
      expect(harness.adapter.pauseCommands, isEmpty);
    });
  }

  test('bag channel rejects a reorder payload even while bag is open',
      () async {
    final harness = RuntimePlayerTestHarness();
    addTearDown(harness.dispose);
    await _openParty(harness);
    await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.openBag,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ));

    final result = await _dispatch(
      harness,
      const RuntimePlayerPauseCommand.setPartyLead(
        partyTargetId: 'pokemon.member',
      ),
    );

    expect(result.status, RuntimePlayerCommandStatus.unavailable);
    expect(harness.adapter.pauseCommands, isEmpty);
  });

  for (final command in [
    const RuntimePlayerPauseCommand.equipHeldItem(
      itemTargetId: 'leftovers',
      partyTargetId: 'pokemon.member',
    ),
    const RuntimePlayerPauseCommand.reorderPartyMember(
      partyTargetId: 'pokemon.member',
      secondPartyTargetId: 'pokemon.other',
    ),
  ]) {
    test('${command.kind.name} is dispatched once during delayed refresh',
        () async {
      final harness = RuntimePlayerTestHarness();
      addTearDown(harness.dispose);
      await _openParty(harness);
      final started = Completer<void>();
      final pending = Completer<
          Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>>();
      harness.adapter.pauseDetailsLoader = () {
        started.complete();
        return pending.future;
      };
      final action =
          command.kind == RuntimePlayerPauseCommandKind.reorderPartyMember
              ? RuntimePlayerAction.reorderParty
              : RuntimePlayerAction.useBagItem;
      final envelope = RuntimePlayerCommand(
        action: action,
        snapshotRevision: harness.coordinator.snapshot.revision,
        payload: command,
      );
      final first = harness.coordinator.dispatch(envelope);
      final second = harness.coordinator.dispatch(envelope);
      await started.future;
      expect(harness.adapter.pauseCommands, [command]);
      pending.complete(harness.adapter.pauseDetails);

      expect((await first).status, RuntimePlayerCommandStatus.accepted);
      expect((await second).status, RuntimePlayerCommandStatus.stale);
      expect(harness.adapter.pauseCommands, [command]);
    });
  }
}

Future<void> _openParty(RuntimePlayerTestHarness harness) async {
  await launchHarnessToPlaying(harness);
  harness.adapter.pauseDetails = _details(RuntimePlayerDetailEntrySnapshot(
    id: 'pokemon.member',
    title: 'Member',
  ));
  for (final action in [
    RuntimePlayerAction.openMenu,
    RuntimePlayerAction.openParty,
  ]) {
    await harness.coordinator.dispatch(RuntimePlayerCommand(
      action: action,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ));
  }
}

Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot> _details(
  RuntimePlayerDetailEntrySnapshot member,
) =>
    {
      RuntimePlayerPauseSection.party: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.party,
        title: 'Équipe',
        entries: [member],
      ),
    };

Future<RuntimePlayerCommandResult> _dispatch(
  RuntimePlayerTestHarness harness,
  RuntimePlayerPauseCommand command,
) =>
    harness.coordinator.dispatch(RuntimePlayerCommand(
      action: RuntimePlayerAction.useBagItem,
      snapshotRevision: harness.coordinator.snapshot.revision,
      payload: command,
    ));
