import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/driver/selbrume_evaluation_driver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('driver starts the real Selbrume project headlessly', () async {
    final driver = await SelbrumeEvaluationDriver.start(
      projectRoot: Directory(
        p.join(_findRepositoryRoot().path, 'selbrume'),
      ),
    );
    addTearDown(driver.dispose);

    final snapshot = driver.snapshot();

    expect(snapshot.currentMapId, 'map_bourg_selbrume');
    expect(snapshot.party, isEmpty);
    expect(driver.game.debugFlowPhaseName, 'overworld');

    await driver.createCheckpoint('fresh-game');
    await driver.probeSetMoney(snapshot.money + 123);
    expect(driver.snapshot().money, snapshot.money + 123);

    await driver.probeLoadCheckpoint('fresh-game');
    expect(driver.snapshot().money, snapshot.money);
  });

  test('Phase 6 roster commands commit through the real runtime state',
      () async {
    final driver = await SelbrumeEvaluationDriver.start(
      projectRoot: Directory(
        p.join(_findRepositoryRoot().path, 'selbrume'),
      ),
      runId: 'pmcp-071-roster',
    );
    addTearDown(driver.dispose);
    await driver.probeSeedParty(<Map<String, Object?>>[
      const PlayerPokemon(
        speciesId: 'squirtle',
        natureId: 'hardy',
        abilityId: 'torrent',
        currentHp: 1,
      ).toJson(),
      const PlayerPokemon(
        speciesId: 'bulbasaur',
        natureId: 'hardy',
        abilityId: 'overgrow',
      ).toJson(),
    ]);

    await driver.swapPartyMembers(0, 1);
    expect(driver.snapshot().party.first['speciesId'], 'bulbasaur');
    await driver.setLeadPokemon(1);
    expect(driver.snapshot().party.first['speciesId'], 'squirtle');

    await driver.depositPartyPokemon(1, boxId: 'box-01');
    expect(driver.snapshot().party, hasLength(1));
    expect(driver.snapshot().storage.single['speciesId'], 'bulbasaur');
    await driver.withdrawPcSlot('box-01', 0);
    expect(driver.snapshot().party, hasLength(2));
    expect(driver.snapshot().storage, isEmpty);

    await driver.probeSeedBag(const <String, int>{'potion': 1});
    await driver.useBagItem('potion', 0);
    expect(driver.snapshot().party.first['currentHp'], greaterThan(1));
    expect(driver.snapshot().bag['potion'] ?? 0, 0);
  });
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}
