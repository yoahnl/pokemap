/// Field-wide battle conditions represented by the clean PSDK lane.
///
/// The old legacy battle package has its own `BattleFieldState`; this PSDK
/// contract stays separate so the clean migration does not inherit
/// Showdown-era assumptions. Lot 24 only stores observable field state.
/// Application, expiration, prevention hooks and duration-extending items stay
/// future work.
const _unchanged = Object();

class PsdkBattleFieldState {
  const PsdkBattleFieldState({
    this.terrain,
    this.weather,
  });

  final PsdkBattleTerrainState? terrain;
  final PsdkBattleWeatherState? weather;

  bool get hasTerrain => terrain != null;
  bool get hasWeather => weather != null;

  bool isTerrainActive(PsdkBattleTerrainId id) => terrain?.id == id;
  bool isWeatherActive(PsdkBattleWeatherId id) => weather?.id == id;

  PsdkBattleFieldState withTerrain(
    PsdkBattleTerrainId id, {
    int remainingTurns = 5,
  }) {
    return copyWith(
      terrain: PsdkBattleTerrainState(
        id: id,
        remainingTurns: remainingTurns,
      ),
    );
  }

  PsdkBattleFieldState withWeather(
    PsdkBattleWeatherId id, {
    int remainingTurns = 5,
  }) {
    return copyWith(
      weather: PsdkBattleWeatherState(
        id: id,
        remainingTurns: remainingTurns,
      ),
    );
  }

  PsdkBattleFieldState clearTerrain() => copyWith(terrain: null);

  PsdkBattleFieldState clearWeather() => copyWith(weather: null);

  PsdkBattleFieldState tickEndTurn() {
    return copyWith(
      terrain: terrain?.tickEndTurn(),
      weather: weather?.tickEndTurn(),
    );
  }

  PsdkBattleFieldState copyWith({
    Object? terrain = _unchanged,
    Object? weather = _unchanged,
  }) {
    return PsdkBattleFieldState(
      terrain: identical(terrain, _unchanged)
          ? this.terrain
          : terrain as PsdkBattleTerrainState?,
      weather: identical(weather, _unchanged)
          ? this.weather
          : weather as PsdkBattleWeatherState?,
    );
  }
}

class PsdkBattleTerrainState {
  const PsdkBattleTerrainState({
    required this.id,
    required this.remainingTurns,
  }) : assert(remainingTurns > 0);

  final PsdkBattleTerrainId id;
  final int remainingTurns;

  PsdkBattleTerrainState? tickEndTurn() {
    if (remainingTurns <= 1) {
      return null;
    }
    return PsdkBattleTerrainState(
      id: id,
      remainingTurns: remainingTurns - 1,
    );
  }
}

class PsdkBattleWeatherState {
  const PsdkBattleWeatherState({
    required this.id,
    required this.remainingTurns,
  }) : assert(remainingTurns > 0);

  final PsdkBattleWeatherId id;
  final int remainingTurns;

  PsdkBattleWeatherState? tickEndTurn() {
    if (remainingTurns <= 1) {
      return null;
    }
    return PsdkBattleWeatherState(
      id: id,
      remainingTurns: remainingTurns - 1,
    );
  }
}

enum PsdkBattleTerrainId {
  electricTerrain,
  grassyTerrain,
  mistyTerrain,
  psychicTerrain,
}

extension PsdkBattleTerrainIdSymbol on PsdkBattleTerrainId {
  String get jsonName {
    return switch (this) {
      PsdkBattleTerrainId.electricTerrain => 'electric_terrain',
      PsdkBattleTerrainId.grassyTerrain => 'grassy_terrain',
      PsdkBattleTerrainId.mistyTerrain => 'misty_terrain',
      PsdkBattleTerrainId.psychicTerrain => 'psychic_terrain',
    };
  }
}

enum PsdkBattleWeatherId {
  rain,
  sunny,
  sandstorm,
  hail,
  snow,
  fog,
  hardrain,
  hardsun,
  strongWinds,
}

extension PsdkBattleWeatherIdSymbol on PsdkBattleWeatherId {
  String get jsonName {
    return switch (this) {
      PsdkBattleWeatherId.rain => 'rain',
      PsdkBattleWeatherId.sunny => 'sunny',
      PsdkBattleWeatherId.sandstorm => 'sandstorm',
      PsdkBattleWeatherId.hail => 'hail',
      PsdkBattleWeatherId.snow => 'snow',
      PsdkBattleWeatherId.fog => 'fog',
      PsdkBattleWeatherId.hardrain => 'hardrain',
      PsdkBattleWeatherId.hardsun => 'hardsun',
      PsdkBattleWeatherId.strongWinds => 'strong_winds',
    };
  }

  bool get isHardWeather {
    return switch (this) {
      PsdkBattleWeatherId.hardrain ||
      PsdkBattleWeatherId.hardsun ||
      PsdkBattleWeatherId.strongWinds =>
        true,
      _ => false,
    };
  }
}
