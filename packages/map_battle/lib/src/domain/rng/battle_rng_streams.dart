import '../../psdk/domain/psdk_battle_rng.dart';
import 'battle_seeded_rng.dart';

/// Snapshot of the four independent PSDK-style battle RNG streams.
final class BattleRngSeeds {
  const BattleRngSeeds({
    required this.moveDamage,
    required this.moveCritical,
    required this.moveAccuracy,
    required this.generic,
  });

  factory BattleRngSeeds.fromPsdk(PsdkBattleRngSeeds seeds) {
    return BattleRngSeeds(
      moveDamage: seeds.moveDamage,
      moveCritical: seeds.moveCritical,
      moveAccuracy: seeds.moveAccuracy,
      generic: seeds.generic,
    );
  }

  final int moveDamage;
  final int moveCritical;
  final int moveAccuracy;
  final int generic;

  PsdkBattleRngSeeds get psdkSeeds {
    return PsdkBattleRngSeeds(
      moveDamage: moveDamage,
      moveCritical: moveCritical,
      moveAccuracy: moveAccuracy,
      generic: generic,
    );
  }
}

enum BattleRngStreamKind {
  moveDamage,
  moveCritical,
  moveAccuracy,
  generic,
}

/// Independent RNG streams mirroring Pokemon SDK's battle logic.
///
/// Damage, critical hits, accuracy and generic effects advance separately.
/// This lets the engine replay one category without accidentally shifting all
/// later random checks.
final class BattleRngStreams {
  const BattleRngStreams({
    required this.moveDamage,
    required this.moveCritical,
    required this.moveAccuracy,
    required this.generic,
  });

  factory BattleRngStreams.fromSeeds({
    required int moveDamageSeed,
    required int moveCriticalSeed,
    required int moveAccuracySeed,
    required int genericSeed,
  }) {
    return BattleRngStreams(
      moveDamage: BattleRngStream(seed: moveDamageSeed),
      moveCritical: BattleRngStream(seed: moveCriticalSeed),
      moveAccuracy: BattleRngStream(seed: moveAccuracySeed),
      generic: BattleRngStream(seed: genericSeed),
    );
  }

  factory BattleRngStreams.fromSeedSnapshot(BattleRngSeeds seeds) {
    return BattleRngStreams.fromSeeds(
      moveDamageSeed: seeds.moveDamage,
      moveCriticalSeed: seeds.moveCritical,
      moveAccuracySeed: seeds.moveAccuracy,
      genericSeed: seeds.generic,
    );
  }

  factory BattleRngStreams.fromPsdkSeeds(PsdkBattleRngSeeds seeds) {
    return BattleRngStreams.fromSeedSnapshot(BattleRngSeeds.fromPsdk(seeds));
  }

  factory BattleRngStreams.fromPsdk(PsdkBattleRngStreams streams) {
    return BattleRngStreams(
      moveDamage: BattleRngStream(seed: streams.moveDamage.seed),
      moveCritical: BattleRngStream(seed: streams.moveCritical.seed),
      moveAccuracy: BattleRngStream(seed: streams.moveAccuracy.seed),
      generic: BattleRngStream(seed: streams.generic.seed),
    );
  }

  final BattleRngStream moveDamage;
  final BattleRngStream moveCritical;
  final BattleRngStream moveAccuracy;
  final BattleRngStream generic;

  BattleRngSeeds get seeds {
    return BattleRngSeeds(
      moveDamage: moveDamage.seed,
      moveCritical: moveCritical.seed,
      moveAccuracy: moveAccuracy.seed,
      generic: generic.seed,
    );
  }

  PsdkBattleRngStreams get psdkStreams {
    return PsdkBattleRngStreams(
      moveDamage: PsdkBattleRngStream(seed: moveDamage.seed),
      moveCritical: PsdkBattleRngStream(seed: moveCritical.seed),
      moveAccuracy: PsdkBattleRngStream(seed: moveAccuracy.seed),
      generic: PsdkBattleRngStream(seed: generic.seed),
    );
  }

  BattleRngStream stream(BattleRngStreamKind kind) {
    return switch (kind) {
      BattleRngStreamKind.moveDamage => moveDamage,
      BattleRngStreamKind.moveCritical => moveCritical,
      BattleRngStreamKind.moveAccuracy => moveAccuracy,
      BattleRngStreamKind.generic => generic,
    };
  }

  BattleRngStreams copyWith({
    BattleRngStream? moveDamage,
    BattleRngStream? moveCritical,
    BattleRngStream? moveAccuracy,
    BattleRngStream? generic,
  }) {
    return BattleRngStreams(
      moveDamage: moveDamage ?? this.moveDamage,
      moveCritical: moveCritical ?? this.moveCritical,
      moveAccuracy: moveAccuracy ?? this.moveAccuracy,
      generic: generic ?? this.generic,
    );
  }

  BattleRngStreams replace({
    required BattleRngStreamKind kind,
    required BattleRngStream stream,
  }) {
    return switch (kind) {
      BattleRngStreamKind.moveDamage => copyWith(moveDamage: stream),
      BattleRngStreamKind.moveCritical => copyWith(moveCritical: stream),
      BattleRngStreamKind.moveAccuracy => copyWith(moveAccuracy: stream),
      BattleRngStreamKind.generic => copyWith(generic: stream),
    };
  }
}
