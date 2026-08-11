import 'package:map_core/map_core.dart';

import 'game_state_mutations.dart';
import 'items/item_catalog_snapshot.dart';
import 'player_storage_operations.dart';

final class SandboxIsolationException implements Exception {
  const SandboxIsolationException(this.message);

  final String message;

  @override
  String toString() => 'SandboxIsolationException: $message';
}

/// Compile-time boundary used by adapters before exposing any persistence UI.
/// This Phase-5 sandbox deliberately has no production-save write capability.
final class SandboxProductionWriteGuard {
  const SandboxProductionWriteGuard();

  bool get canWriteProduction => false;

  Never assertCanWriteProduction() {
    throw const SandboxIsolationException(
      'Sandbox state cannot be written to a production save repository.',
    );
  }
}

final class SandboxPlayerState {
  SandboxPlayerState._({
    required this.sandboxId,
    required this.baseline,
    required this.state,
    required this.generation,
    required this.lastOperation,
  });

  final String sandboxId;
  final GameState baseline;
  final GameState state;
  final int generation;
  final Map<String, Object?> lastOperation;

  bool get productionWriteAllowed => false;

  Map<String, Object?> toJson() => {
        'sandboxId': sandboxId,
        'generation': generation,
        'productionWriteAllowed': productionWriteAllowed,
        'state': state.toJson(),
        'lastOperation': lastOperation,
      };
}

final class SandboxSaveInspection {
  const SandboxSaveInspection({
    required this.saveId,
    required this.saveFormat,
    required this.checksumValid,
    required this.stateKeys,
    required this.productionWriteAllowed,
  });

  final String saveId;
  final int saveFormat;
  final bool checksumValid;
  final List<String> stateKeys;
  final bool productionWriteAllowed;

  Map<String, Object?> toJson() => {
        'saveId': saveId,
        'saveFormat': saveFormat,
        'checksumValid': checksumValid,
        'stateKeys': stateKeys,
        'productionWriteAllowed': productionWriteAllowed,
      };
}

final class SandboxStateDiffEntry {
  const SandboxStateDiffEntry({
    required this.path,
    required this.before,
    required this.after,
  });

  final String path;
  final Object? before;
  final Object? after;

  Map<String, Object?> toJson() => {
        'path': path,
        'before': before,
        'after': after,
      };
}

final class SandboxStateDiff {
  SandboxStateDiff(Iterable<SandboxStateDiffEntry> entries)
      : entries = List.unmodifiable(
          entries.toList()
            ..sort((left, right) => left.path.compareTo(right.path)),
        );

  final List<SandboxStateDiffEntry> entries;

  Map<String, Object?> toJson() => {
        'entries': [for (final entry in entries) entry.toJson()],
        'productionStateMutated': false,
      };
}

final class SandboxPlayerStateService {
  const SandboxPlayerStateService({
    this.mutations = const GameStateMutations(),
    this.storage = const PlayerStorageOperations(),
    this.codec = const SaveEnvelopeCodec(),
  });

  final GameStateMutations mutations;
  final PlayerStorageOperations storage;
  final SaveEnvelopeCodec codec;

  SandboxPlayerState open({
    required String sandboxId,
    required GameState state,
  }) {
    final normalizedId = sandboxId.trim();
    if (normalizedId.isEmpty || normalizedId != sandboxId) {
      throw ArgumentError.value(sandboxId, 'sandboxId', 'must be nonblank');
    }
    final baseline = _copyState(state);
    return SandboxPlayerState._(
      sandboxId: sandboxId,
      baseline: baseline,
      state: _copyState(baseline),
      generation: 0,
      lastOperation: const {'kind': 'open', 'success': true},
    );
  }

  SandboxPlayerState giveItem(
    SandboxPlayerState sandbox, {
    required String itemId,
    required int quantity,
  }) =>
      _next(
        sandbox,
        mutations.giveItem(sandbox.state, itemId, quantity),
        kind: 'bag.give',
      );

  SandboxPlayerState consumeItem(
    SandboxPlayerState sandbox, {
    required String itemId,
    required int quantity,
  }) =>
      _next(
        sandbox,
        mutations.consumeItem(sandbox.state, itemId, quantity),
        kind: 'bag.consume',
      );

  SandboxPlayerState recoverParty(
    SandboxPlayerState sandbox, {
    required Map<int, int> maxHpByPartyIndex,
    Map<int, Map<String, int>> maxPpByPartyIndex = const {},
  }) =>
      _next(
        sandbox,
        mutations.recoverParty(
          sandbox.state,
          maxHpByPartyIndex: maxHpByPartyIndex,
          maxPpByPartyIndex: maxPpByPartyIndex,
        ),
        kind: 'party.recover',
      );

  SandboxPlayerState deposit(
    SandboxPlayerState sandbox, {
    required int partyIndex,
    String? boxId,
    bool requireUsablePartyMember = true,
  }) {
    final result = storage.deposit(
      state: sandbox.state,
      partyIndex: partyIndex,
      boxId: boxId,
      requireUsablePartyMember: requireUsablePartyMember,
    );
    return _next(
      sandbox,
      result.state,
      kind: 'pc.deposit',
      success: result.isSuccess,
      failure: result.failure?.name,
    );
  }

  SandboxPlayerState withdraw(
    SandboxPlayerState sandbox, {
    required String boxId,
    required int boxIndex,
  }) {
    final result = storage.withdraw(
      state: sandbox.state,
      boxId: boxId,
      boxIndex: boxIndex,
    );
    return _next(
      sandbox,
      result.state,
      kind: 'pc.withdraw',
      success: result.isSuccess,
      failure: result.failure?.name,
    );
  }

  SandboxPlayerState purchase(
    SandboxPlayerState sandbox, {
    required ShopDefinition shop,
    required String itemId,
    required int quantity,
  }) {
    final result = mutations.purchaseFromShop(
      sandbox.state,
      shop: shop,
      itemId: itemId,
      quantity: quantity,
    );
    return _next(
      sandbox,
      result.state,
      kind: 'shop.purchase',
      success: result.isSuccess,
      failure: result.failure?.name,
    );
  }

  SandboxPlayerState sell(
    SandboxPlayerState sandbox, {
    required ShopDefinition shop,
    required String expectedStateId,
    required String itemId,
    required int quantity,
    required ItemCatalogSnapshot itemCatalog,
  }) {
    final result = mutations.sellToResolvedShop(
      sandbox.state,
      shop: shop,
      expectedStateId: expectedStateId,
      itemId: itemId,
      quantity: quantity,
      itemCatalog: itemCatalog,
    );
    return _next(
      sandbox,
      result.state,
      kind: 'shop.sell',
      success: result.isSuccess,
      failure: result.failure?.name,
    );
  }

  SandboxStateDiff diff(SandboxPlayerState sandbox) {
    final entries = <SandboxStateDiffEntry>[];
    _diffJson(sandbox.baseline.toJson(), sandbox.state.toJson(), '', entries);
    return SandboxStateDiff(entries);
  }

  SandboxSaveInspection inspectEnvelope(SaveEnvelope envelope) {
    final keys = envelope.state.keys.toList()..sort();
    return SandboxSaveInspection(
      saveId: envelope.saveId,
      saveFormat: envelope.saveFormat,
      checksumValid: codec.verifyChecksum(envelope),
      stateKeys: keys,
      productionWriteAllowed: false,
    );
  }

  SaveEnvelope migrateEnvelope({
    required SaveMigrationEngine engine,
    required SaveEnvelope source,
    required GameIdentity targetIdentity,
    required String newSaveId,
    required DateTime updatedAt,
  }) =>
      engine.migrate(
        source: source,
        targetIdentity: targetIdentity,
        newSaveId: newSaveId,
        updatedAt: updatedAt,
      );

  SandboxPlayerState _next(
    SandboxPlayerState sandbox,
    GameState state, {
    required String kind,
    bool success = true,
    String? failure,
  }) =>
      SandboxPlayerState._(
        sandboxId: sandbox.sandboxId,
        baseline: sandbox.baseline,
        state: _copyState(state),
        generation: sandbox.generation + (success ? 1 : 0),
        lastOperation: {
          'kind': kind,
          'success': success,
          if (failure != null) 'failure': failure,
        },
      );
}

GameState _copyState(GameState state) =>
    GameState.fromJson(Map<String, dynamic>.from(state.toJson()));

void _diffJson(
  Object? before,
  Object? after,
  String path,
  List<SandboxStateDiffEntry> entries,
) {
  if (before is Map && after is Map) {
    final keys = {
      ...before.keys.whereType<String>(),
      ...after.keys.whereType<String>()
    }.toList()
      ..sort();
    for (final key in keys) {
      _diffJson(
          before[key], after[key], '$path/${_pointerToken(key)}', entries);
    }
    return;
  }
  if (before is List && after is List) {
    final length = before.length > after.length ? before.length : after.length;
    for (var index = 0; index < length; index++) {
      _diffJson(
        index < before.length ? before[index] : null,
        index < after.length ? after[index] : null,
        '$path/$index',
        entries,
      );
    }
    return;
  }
  if (before != after) {
    entries.add(SandboxStateDiffEntry(
      path: path.isEmpty ? '/' : path,
      before: before,
      after: after,
    ));
  }
}

String _pointerToken(String value) =>
    value.replaceAll('~', '~0').replaceAll('/', '~1');
