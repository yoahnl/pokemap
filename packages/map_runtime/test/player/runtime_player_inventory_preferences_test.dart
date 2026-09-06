import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  test('favorites survive consumption and only publish after persistence',
      () async {
    final gateway = _Preferences({'old-item'});
    final harness =
        RuntimePlayerTestHarness(inventoryPreferencesGateway: gateway);
    addTearDown(harness.dispose);
    await _openBag(harness);
    expect(harness.coordinator.snapshot.favoriteItemIds, {'old-item'});
    expect(harness.coordinator.snapshot.bagFavoritesAvailable, isTrue);
    gateway.saveGate = Completer<void>();
    final pending = _favorite(harness, 'potion', true);
    await gateway.started.future;
    expect(harness.coordinator.snapshot.favoriteItemIds, {'old-item'});
    gateway.saveGate!.complete();
    expect((await pending).status, RuntimePlayerCommandStatus.accepted);
    expect(
        harness.coordinator.snapshot.favoriteItemIds, {'old-item', 'potion'});
    expect(gateway.saved, {'old-item', 'potion'});
    expect(() => harness.coordinator.snapshot.favoriteItemIds.add('x'),
        throwsUnsupportedError);
    expect((await _favorite(harness, 'potion', false)).status,
        RuntimePlayerCommandStatus.accepted);
    expect(gateway.saved, {'old-item'});
  });

  test('failed persistence keeps the previous favorites and gives a safe error',
      () async {
    final gateway = _Preferences({'old-item'})..failSave = true;
    final harness =
        RuntimePlayerTestHarness(inventoryPreferencesGateway: gateway);
    addTearDown(harness.dispose);
    await _openBag(harness);
    final result = await _favorite(harness, 'potion', true);
    expect(result.status, RuntimePlayerCommandStatus.failed);
    expect(result.safeMessage, isNot(contains('private/path')));
    expect(harness.coordinator.snapshot.favoriteItemIds, {'old-item'});
  });

  test('missing or corrupt preference storage does not prevent launch',
      () async {
    for (final gateway in <_Preferences?>[
      null,
      _Preferences({})..failLoad = true
    ]) {
      final harness =
          RuntimePlayerTestHarness(inventoryPreferencesGateway: gateway);
      addTearDown(harness.dispose);
      await _openBag(harness);
      expect(harness.coordinator.snapshot.bagFavoritesAvailable, isFalse);
      expect((await _favorite(harness, 'potion', true)).status,
          RuntimePlayerCommandStatus.unavailable);
    }
  });

  test('stale revisions, unowned items and non-bag screens cannot write',
      () async {
    final gateway = _Preferences({});
    final harness =
        RuntimePlayerTestHarness(inventoryPreferencesGateway: gateway);
    addTearDown(harness.dispose);
    await _openBag(harness);
    expect(
        (await harness.coordinator.setBagItemFavorite(
                itemId: 'potion', favorite: true, snapshotRevision: 0))
            .status,
        RuntimePlayerCommandStatus.stale);
    expect((await _favorite(harness, 'missing', true)).status,
        RuntimePlayerCommandStatus.unavailable);
    await harness.coordinator
        .requestBack(snapshotRevision: harness.coordinator.snapshot.revision);
    expect((await _favorite(harness, 'potion', true)).status,
        RuntimePlayerCommandStatus.unavailable);
    expect(gateway.saved, isNull);
  });

  test('pending writes cannot publish into a disposed session', () async {
    final gateway = _Preferences({})..saveGate = Completer<void>();
    final harness =
        RuntimePlayerTestHarness(inventoryPreferencesGateway: gateway);
    await _openBag(harness);
    final pending = _favorite(harness, 'potion', true);
    await gateway.started.future;
    await harness.dispose();
    final snapshot = harness.coordinator.snapshot;
    gateway.saveGate!.complete();
    expect((await pending).status, RuntimePlayerCommandStatus.cancelled);
    expect(harness.coordinator.snapshot, same(snapshot));
  });

  test('concurrent toggles serialize and reject the stale second command',
      () async {
    final gateway = _Preferences({})..saveGate = Completer<void>();
    final harness =
        RuntimePlayerTestHarness(inventoryPreferencesGateway: gateway);
    addTearDown(harness.dispose);
    await _openBag(harness);
    final first = _favorite(harness, 'potion', true);
    final second = _favorite(harness, 'potion', false);
    await gateway.started.future;
    gateway.saveGate!.complete();
    expect((await first).status, RuntimePlayerCommandStatus.accepted);
    expect((await second).status, RuntimePlayerCommandStatus.stale);
    expect(gateway.saved, {'potion'});
  });

  test('lifecycle suspension preserves a committed favorite for resume',
      () async {
    final gateway = _Preferences({})..saveGate = Completer<void>();
    final harness =
        RuntimePlayerTestHarness(inventoryPreferencesGateway: gateway);
    addTearDown(harness.dispose);
    await _openBag(harness);
    final pending = _favorite(harness, 'potion', true);
    await gateway.started.future;
    final suspend = harness.coordinator.pauseForLifecycle();
    gateway.saveGate!.complete();
    expect((await pending).status, RuntimePlayerCommandStatus.cancelled);
    await suspend;
    expect(harness.coordinator.snapshot.favoriteItemIds, isEmpty);
    await harness.coordinator.resumeFromLifecycle();
    expect(harness.coordinator.snapshot.favoriteItemIds, {'potion'});
  });
}

Future<RuntimePlayerCommandResult> _favorite(
        RuntimePlayerTestHarness harness, String itemId, bool favorite) =>
    harness.coordinator.setBagItemFavorite(
        itemId: itemId,
        favorite: favorite,
        snapshotRevision: harness.coordinator.snapshot.revision);

Future<void> _openBag(RuntimePlayerTestHarness harness) async {
  await launchHarnessToPlaying(harness);
  harness.adapter.pauseDetails = {
    RuntimePlayerPauseSection.bag: RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.bag,
      title: 'Sac',
      entries: [
        RuntimePlayerDetailEntrySnapshot(
            id: 'potion',
            title: 'Potion',
            bagItem: const RuntimePlayerBagItemSnapshot(
                itemId: 'potion', quantity: 1, sortOrder: 0)),
      ],
    ),
  };
  for (final action in [
    RuntimePlayerAction.openMenu,
    RuntimePlayerAction.openBag
  ]) {
    await harness.coordinator.dispatch(RuntimePlayerCommand(
        action: action,
        snapshotRevision: harness.coordinator.snapshot.revision));
  }
}

final class _Preferences implements PlayerInventoryPreferencesGateway {
  _Preferences(this.initial);

  final Set<String> initial;
  Set<String>? saved;
  bool failLoad = false;
  bool failSave = false;
  Completer<void>? saveGate;
  final started = Completer<void>();

  @override
  Future<Set<String>> load(String gameId) async {
    if (failLoad) throw const FormatException('corrupt');
    return initial;
  }

  @override
  Future<void> save(String gameId, Set<String> favoriteItemIds) async {
    if (!started.isCompleted) started.complete();
    await saveGate?.future;
    if (failSave) throw StateError('/private/path');
    saved = Set.of(favoriteItemIds);
  }
}
