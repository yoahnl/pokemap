import 'dart:io';

import 'package:map_battle/map_battle.dart';

import '../../../tool/performance/benchmark_support.dart';

const _fixtureDescriptor = <String, Object?>{
  'kind': 'deterministic-singles-independent-turn',
  'player': <String, Object?>{
    'species': 'charmander',
    'hp': 44,
    'speed': 65,
    'move': 'scratch',
    'power': 180,
  },
  'opponent': <String, Object?>{
    'species': 'bulbasaur',
    'hp': 18,
    'speed': 45,
    'move': 'scratch',
    'power': 20,
  },
  'rngSeeds': <int>[1, 2, 3, 4],
};

Future<void> main(List<String> arguments) async {
  try {
    final cli = PerformanceCli.parse(
      arguments,
      allowed: const <String>{'warmups', 'samples', 'turns', 'output'},
    );
    final warmups = cli.nonNegativeInt('warmups', fallback: 5);
    final samples = cli.positiveInt('samples', fallback: 30);
    final turns = cli.positiveInts(
      'turns',
      fallback: '100,500,1000,2000,5000',
      singularLabel: 'turn count',
    );
    final outputPath = cli.requiredValue('output');
    validatedPackageOutput(outputPath, packageName: 'map_battle');
    final fixtureFingerprint = stableFingerprint(_fixtureDescriptor);
    final setup = _setup();
    final results = <Map<String, Object?>>[];

    for (final turnCount in turns) {
      for (var index = 0; index < warmups; index += 1) {
        _measure(setup, turnCount);
      }
      final measured = <({int elapsedUs, String checksum, int events})>[
        for (var index = 0; index < samples; index += 1)
          _measure(setup, turnCount),
      ];
      final checksum = measured.first.checksum;
      if (measured.any((sample) => sample.checksum != checksum)) {
        throw StateError('Unstable battle result for $turnCount turns.');
      }
      results.add(<String, Object?>{
        'turnCount': turnCount,
        'turnSemantics': 'independent-engine-submit',
        'datasetFingerprint': fixtureFingerprint,
        'battleChecksum': checksum,
        'timelineEventCount': measured.first.events,
        'rssBytesAfterSamples': ProcessInfo.currentRss,
        ...percentileFields(
          measured.map((sample) => sample.elapsedUs).toList(growable: false),
        ),
      });
    }

    final receipt = await performanceReceipt(
      benchmark: 'battle_turn_baseline',
      warmups: warmups,
      sampleCount: samples,
      arguments: <String>['benchmark/battle_turn_baseline.dart', ...arguments],
      metadata: <String, Object?>{
        'turnCounts': turns,
        'fixtureFingerprint': fixtureFingerprint,
      },
      results: results,
    );
    await writePerformanceReceipt(
      outputPath: outputPath,
      packageName: 'map_battle',
      receipt: receipt,
    );
  } on FormatException catch (error) {
    stderr.writeln('battle_turn_baseline: ${error.message}');
    exitCode = 64;
  }
}

// Each submission starts from the same deterministic setup. This measures the
// engine's turn path without letting a terminal battle shorten later samples.
({int elapsedUs, String checksum, int events}) _measure(
  PsdkBattleSetup setup,
  int turns,
) {
  var eventCount = 0;
  final stopwatch = Stopwatch()..start();
  for (var index = 0; index < turns; index += 1) {
    final result = BattleEngine(setup: BattleEngineSetup.fromPsdk(setup))
        .submit(const BattleDecision.fight(moveSlot: 0));
    eventCount += result.timeline.events.length;
  }
  stopwatch.stop();
  return (
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: stableFingerprint(<Object?>[turns, eventCount]),
    events: eventCount,
  );
}

PsdkBattleSetup _setup() => PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player-charmander',
        speciesId: 'charmander',
        speed: 65,
        hp: 44,
        movePower: 180,
      ),
      opponent: _combatant(
        id: 'opponent-bulbasaur',
        speciesId: 'bulbasaur',
        speed: 45,
        hp: 18,
        movePower: 20,
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 2,
        moveAccuracy: 3,
        generic: 4,
      ),
    );

PsdkBattleCombatantSetup _combatant({
  required String id,
  required String speciesId,
  required int speed,
  required int hp,
  required int movePower,
}) =>
    PsdkBattleCombatantSetup(
      id: id,
      speciesId: speciesId,
      displayName: speciesId,
      level: 10,
      maxHp: hp,
      currentHp: hp,
      types: const PsdkBattleTypes(primary: 'normal'),
      stats: PsdkBattleStats(
        attack: 64,
        defense: 49,
        specialAttack: 60,
        specialDefense: 50,
        speed: speed,
      ),
      moves: <PsdkBattleMoveData>[_move(movePower)],
    );

PsdkBattleMoveData _move(int power) => PsdkBattleMoveData(
      id: 'scratch',
      dbSymbol: 'scratch',
      name: 'Scratch',
      type: 'normal',
      category: PsdkBattleMoveCategory.physical,
      power: power,
      accuracy: 100,
      pp: 35,
      priority: 0,
      battleEngineMethod: 's_basic',
      target: PsdkBattleMoveTarget.adjacentFoe,
    );
