import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
