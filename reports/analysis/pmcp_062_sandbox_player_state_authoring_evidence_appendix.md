# PMCP-062 — Created Dart files appendix

This appendix records the complete contents of every Dart file created by PMCP-062.

## `packages/map_gameplay/lib/src/sandbox_player_state.dart`

```dart
import 'package:map_core/map_core.dart';

import 'game_state_mutations.dart';
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
    required String categoryId,
    required int quantity,
  }) {
    final result = mutations.purchaseFromShop(
      sandbox.state,
      shop: shop,
      itemId: itemId,
      categoryId: categoryId,
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
  }) {
    final result = mutations.sellToResolvedShop(
      sandbox.state,
      shop: shop,
      expectedStateId: expectedStateId,
      itemId: itemId,
      quantity: quantity,
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
```

## `packages/map_gameplay/test/sandbox_player_state_service_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('sandbox player state', () {
    test('gameplay mutations change only the detached sandbox copy', () {
      const baseline = GameState(
        saveId: 'production-save',
        currentMapId: 'start',
        party: PlayerParty(
          members: [
            PlayerPokemon(
              speciesId: 'sproutle',
              level: 5,
              natureId: 'hardy',
              abilityId: 'overgrow',
              currentHp: 0,
            ),
          ],
        ),
      );
      final service = const SandboxPlayerStateService();
      final opened = service.open(sandboxId: 'test-run', state: baseline);
      final withItem = service.giveItem(opened, itemId: 'potion', quantity: 2);
      final healed = service.recoverParty(
        withItem,
        maxHpByPartyIndex: const {0: 20},
      );

      expect(baseline.bag.entries, isEmpty);
      expect(baseline.party.members.single.currentHp, 0);
      expect(healed.state.bag.entries.single.quantity, 2);
      expect(healed.state.party.members.single.currentHp, 20);
      expect(healed.productionWriteAllowed, isFalse);
      expect(healed.generation, 2);
    });

    test('diff reports changed JSON paths without exposing a write port', () {
      const baseline = GameState(saveId: 'save', currentMapId: 'start');
      final service = const SandboxPlayerStateService();
      final opened = service.open(sandboxId: 'diff-run', state: baseline);
      final updated = service.giveItem(opened, itemId: 'potion', quantity: 1);

      final diff = service.diff(updated);

      expect(diff.entries, isNotEmpty);
      expect(
          diff.entries.any((entry) => entry.path.startsWith('/bag')), isTrue);
      expect(
        () => const SandboxProductionWriteGuard().assertCanWriteProduction(),
        throwsA(isA<SandboxIsolationException>()),
      );
    });

    test('save inspector and migration delegate to canonical core contracts',
        () {
      const codec = SaveEnvelopeCodec();
      final sourceIdentity = GameIdentity(
        gameId: 'com.pokemap.sandbox',
        gameVersion: '1.0.0',
        projectFormat: ProjectFormat.v2,
        saveFormat: 0,
        compatibilityId: 'campaign-v1',
      );
      final source = codec.create(
        identity: sourceIdentity,
        profileId: 'profile',
        slotId: 'slot',
        saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
        createdAt: DateTime.utc(2026, 7, 31, 10),
        updatedAt: DateTime.utc(2026, 7, 31, 10),
        status: SaveStatus.active,
        playTimeSeconds: 10,
        origin: SaveOrigin(
          kind: SaveOriginKind.manualImport,
          importedAt: DateTime.utc(2026, 7, 31, 10),
        ),
        state: const {'legacy': true},
      );
      final engine = SaveMigrationEngine(
        migrations: [
          SaveStateMigration(
            fromFormat: 0,
            toFormat: 1,
            migrate: (state) => {...state, 'migrated': true},
          ),
        ],
      );
      final targetIdentity = GameIdentity(
        gameId: 'com.pokemap.sandbox',
        gameVersion: '1.1.0',
        projectFormat: ProjectFormat.v2,
        saveFormat: 1,
        compatibilityId: 'campaign-v1',
      );
      const service = SandboxPlayerStateService();

      final inspection = service.inspectEnvelope(source);
      final migrated = service.migrateEnvelope(
        engine: engine,
        source: source,
        targetIdentity: targetIdentity,
        newSaveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c2',
        updatedAt: DateTime.utc(2026, 7, 31, 11),
      );

      expect(inspection.checksumValid, isTrue);
      expect(migrated.saveFormat, 1);
      expect(migrated.state['migrated'], isTrue);
      expect(source.state.containsKey('migrated'), isFalse);
    });
  });
}
```
## `packages/map_authoring/lib/src/domains/gameplay/sandbox_player_state_actions.dart`

```dart
import '../../contracts/action_descriptor.dart';

/// Public MCP/action catalog for the detached gameplay sandbox. These actions
/// are deliberately absent from the project mutation dispatcher.
abstract final class SandboxPlayerStateActions {
  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final entry in const [
      ('sandbox.state.inspect', AuthoringRiskLevel.readOnly),
      ('sandbox.state.diff', AuthoringRiskLevel.readOnly),
      ('sandbox.save.migrate', AuthoringRiskLevel.low),
      ('sandbox.party.recover', AuthoringRiskLevel.low),
      ('sandbox.pc.deposit', AuthoringRiskLevel.low),
      ('sandbox.pc.withdraw', AuthoringRiskLevel.low),
      ('sandbox.bag.give', AuthoringRiskLevel.low),
      ('sandbox.bag.consume', AuthoringRiskLevel.low),
      ('sandbox.shop.purchase', AuthoringRiskLevel.low),
      ('sandbox.shop.sell', AuthoringRiskLevel.low),
    ])
      AuthoringActionDescriptor(
        id: entry.$1,
        version: 1,
        summary: 'Operate on detached sandbox player state only',
        inputSchemaId: 'pokemap.authoring/${entry.$1}.input.v1',
        outputSchemaId: 'pokemap.authoring/${entry.$1}.output.v1',
        riskLevel: entry.$2,
        resourceKinds: const ['sandboxPlayerState'],
        capabilityIds: const ['authoring.sandbox.playerState'],
        requiredPermissions: const [AuthoringPermission.playtestControl],
        guarantees: const [AuthoringGuarantee.dryRun],
        extensions: const {'productionWriteAllowed': false},
      ),
  ]);
}
```

## `packages/map_authoring/test/domains/gameplay/sandbox_player_state_actions_test.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  test('sandbox action catalog is explicitly non-production', () {
    expect(
      SandboxPlayerStateActions.descriptors.map((entry) => entry.id),
      containsAll({
        'sandbox.state.inspect',
        'sandbox.state.diff',
        'sandbox.party.recover',
        'sandbox.pc.deposit',
        'sandbox.pc.withdraw',
        'sandbox.bag.give',
        'sandbox.shop.purchase',
      }),
    );
    expect(
      SandboxPlayerStateActions.descriptors.every(
        (entry) => !entry.requiredPermissions.contains(
          AuthoringPermission.projectWrite,
        ),
      ),
      isTrue,
    );
    expect(
      AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((entry) => entry.id),
      isNot(contains('sandbox.bag.give')),
      reason: 'sandbox operations must not enter project mutations',
    );
  });
}
```
