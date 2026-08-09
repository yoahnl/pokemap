import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  final identity = GameIdentity(
    gameId: 'com.pokemap.contract-test',
    gameVersion: '1.2.0',
    projectFormat: ProjectFormat.v1,
    saveFormat: 1,
    compatibilityId: 'contract-test-v1',
  );

  test('a host-neutral game source creates a scoped session descriptor',
      () async {
    final source = _MemoryGameSource(identity);

    final descriptor = await source.createSessionDescriptor(
      launchMode: GameSessionLaunchMode.continueGame,
      profileId: 'player',
      slotId: 'slot_1',
      saveReadHandle: 'opaque-save-revision',
    );

    expect(source.identity, identity);
    expect(source.displayTitle, 'Contract Test');
    expect(descriptor.identity, identity);
    expect(descriptor.profileId, 'player');
    expect(descriptor.slotId, 'slot_1');
    expect(descriptor.saveReadHandle, 'opaque-save-revision');
  });

  test('save gateway keeps storage paths and payloads behind opaque handles',
      () async {
    final address = SaveSlotAddress(
      gameId: identity.gameId,
      profileId: 'player',
      slotId: 'slot_1',
    );
    final summary = PlayerSaveSummary(
      address: address,
      updatedAt: DateTime.utc(2026, 7, 25, 10),
      playTimeSeconds: 42,
      status: SaveStatus.active,
      canContinue: true,
      locationLabel: 'Hanazuki',
    );
    final gateway = _MemorySaveGateway(identity, summary);

    expect(await gateway.readLatestSummary(), same(summary));
    expect(await gateway.readSummary(address), same(summary));
    expect(await gateway.openReadHandle(address), 'opaque-save-revision');
    expect(summary.address, address);
    expect(summary.playTimeSeconds, 42);
    expect(summary.locationLabel, 'Hanazuki');
    expect(summary.safeUnavailableReason, isNull);
  });

  test('player preferences and external exit are host-owned ports', () async {
    final gateway = _MemoryPreferencesGateway(
      const PlayerPreferencesSnapshot(
        locale: 'fr',
        accessibility: GameSessionAccessibilityOptions(
          reducedMotion: true,
          textScale: 1.25,
          hapticsEnabled: false,
        ),
        highContrast: true,
        showInputHints: false,
      ),
    );
    final exit = _MemoryExternalExit();

    final loaded = await gateway.load();
    await gateway.save(
      const PlayerPreferencesSnapshot(
        locale: 'en',
        accessibility: GameSessionAccessibilityOptions(),
      ),
    );
    await exit.returnToHost();

    expect(loaded.locale, 'fr');
    expect(loaded.accessibility.reducedMotion, isTrue);
    expect(loaded.highContrast, isTrue);
    expect(loaded.showInputHints, isFalse);
    expect(gateway.current.locale, 'en');
    expect(exit.calls, 1);
  });

  test('save summaries reject invalid timelines', () {
    final address = SaveSlotAddress(
      gameId: identity.gameId,
      profileId: 'player',
      slotId: 'slot_1',
    );

    expect(
      () => PlayerSaveSummary(
        address: address,
        updatedAt: DateTime.utc(2026, 7, 25),
        playTimeSeconds: -1,
        status: SaveStatus.active,
        canContinue: false,
      ),
      throwsArgumentError,
    );
  });
}

final class _MemoryGameSource implements RuntimeGameSource {
  _MemoryGameSource(this.identity);

  @override
  final GameIdentity identity;

  @override
  String get displayTitle => 'Contract Test';

  @override
  Future<GameSessionDescriptor> createSessionDescriptor({
    required GameSessionLaunchMode launchMode,
    required String profileId,
    required String slotId,
    String? saveReadHandle,
    GameSessionPlayerIdentity? initialPlayerIdentity,
  }) async {
    return GameSessionDescriptor(
      sessionId: 'session-1',
      sessionToken: 'secret-token',
      identity: identity,
      profileId: profileId,
      slotId: slotId,
      launchMode: launchMode,
      installedVersionHandle: 'installed-version',
      saveReadHandle: saveReadHandle,
      runtimeApiVersion: '1.0.0',
      grantedCapabilities: const <String>{},
      locale: 'fr',
      accessibility: const GameSessionAccessibilityOptions(),
      initialPlayerIdentity: initialPlayerIdentity,
    );
  }
}

final class _MemorySaveGateway implements PlayerSaveGateway {
  _MemorySaveGateway(this.identity, this.summary);

  @override
  final GameIdentity identity;
  final PlayerSaveSummary summary;

  @override
  Future<void> commit(GameSessionCheckpointCommit request) async {}

  @override
  Future<String?> openReadHandle(SaveSlotAddress address) async {
    return address == summary.address ? 'opaque-save-revision' : null;
  }

  @override
  Future<PlayerSaveSummary?> readLatestSummary() async => summary;

  @override
  Future<PlayerSaveSummary?> readSummary(SaveSlotAddress address) async {
    return address == summary.address ? summary : null;
  }
}

final class _MemoryPreferencesGateway implements PlayerPreferencesGateway {
  _MemoryPreferencesGateway(this.current);

  PlayerPreferencesSnapshot current;

  @override
  Future<PlayerPreferencesSnapshot> load() async => current;

  @override
  Future<void> save(PlayerPreferencesSnapshot preferences) async {
    current = preferences;
  }
}

final class _MemoryExternalExit implements RuntimeExternalExit {
  int calls = 0;

  @override
  Future<void> returnToHost() async {
    calls++;
  }
}
