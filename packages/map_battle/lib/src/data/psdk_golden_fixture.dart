import 'dart:convert';
import 'dart:io';

import '../psdk/psdk_battle.dart';

enum PsdkGoldenActor {
  player,
  opponent,
}

enum PsdkGoldenActionKind {
  fight,
}

const psdkGoldenGateTags = <String>{
  'move_method',
  'effect_family',
  'ability',
  'item',
  'status',
  'field',
  'doubles',
  'runtime_bridge',
};

class PsdkGoldenFixture {
  PsdkGoldenFixture({
    required this.scenarioId,
    required List<String> tags,
    required List<String> psdkSourcePaths,
    required this.sourcePsdkVersion,
    required this.initialBattle,
    required List<PsdkGoldenAction> actions,
    required this.expectedFinalState,
    required this.expectedTimeline,
    required this.expectedAuditDeltas,
    required List<String> notes,
  })  : tags = List<String>.unmodifiable(tags),
        psdkSourcePaths = List<String>.unmodifiable(psdkSourcePaths),
        actions = List<PsdkGoldenAction>.unmodifiable(actions),
        notes = List<String>.unmodifiable(notes);

  factory PsdkGoldenFixture.fromJson(Map<String, Object?> json) {
    final tags = _requiredNonEmptyStringList(json, 'tags');
    final psdkSourcePaths =
        _requiredNonEmptyStringList(json, 'psdkSourcePaths');
    final actions = _requiredNonEmptyList(json, 'actions')
        .map((value) => PsdkGoldenAction.fromJson(
              _asMap(value, 'actions[]'),
            ))
        .toList(growable: false);
    final expectedTimeline = PsdkGoldenExpectedTimeline.fromJson(
      _requiredMap(json, 'expectedTimeline'),
    );
    _validateGateTags(tags);
    return PsdkGoldenFixture(
      scenarioId: _requiredString(json, 'scenarioId'),
      tags: tags,
      psdkSourcePaths: psdkSourcePaths,
      sourcePsdkVersion: _requiredString(json, 'sourcePsdkVersion'),
      initialBattle: PsdkGoldenInitialBattle.fromJson(
        _requiredMap(json, 'initialBattle'),
      ),
      actions: actions,
      expectedFinalState: PsdkGoldenExpectedFinalState.fromJson(
        _requiredMap(json, 'expectedFinalState'),
      ),
      expectedTimeline: expectedTimeline,
      expectedAuditDeltas: json['expectedAuditDeltas'] == null
          ? PsdkGoldenExpectedAuditDeltas.zero
          : PsdkGoldenExpectedAuditDeltas.fromJson(
              _requiredMap(json, 'expectedAuditDeltas'),
            ),
      notes: _requiredList(json, 'notes')
          .map((value) => _asString(value, 'notes[]'))
          .toList(growable: false),
    );
  }

  static Future<PsdkGoldenFixture> load(File file) async {
    final decoded = jsonDecode(await file.readAsString());
    return PsdkGoldenFixture.fromJson(_asMap(decoded, file.path));
  }

  final String scenarioId;
  final List<String> tags;
  final List<String> psdkSourcePaths;
  final String sourcePsdkVersion;
  final PsdkGoldenInitialBattle initialBattle;
  final List<PsdkGoldenAction> actions;
  final PsdkGoldenExpectedFinalState expectedFinalState;
  final PsdkGoldenExpectedTimeline expectedTimeline;
  final PsdkGoldenExpectedAuditDeltas expectedAuditDeltas;
  final List<String> notes;

  PsdkBattleSetup toPsdkSetup() {
    return PsdkBattleSetup.singles(
      player: initialBattle.player.toSetup(),
      opponent: initialBattle.opponent.toSetup(),
      rngSeeds: initialBattle.rngSeeds,
      field: initialBattle.field,
    );
  }

  List<String> compare(PsdkBattleTurnResult result) {
    return <String>[
      ...expectedFinalState.compare(result),
      ...expectedTimeline.compare(result.timeline),
    ];
  }
}

final class PsdkGoldenFixtureCorpus {
  PsdkGoldenFixtureCorpus({
    required List<PsdkGoldenFixture> fixtures,
    required this.summary,
  }) : fixtures = List<PsdkGoldenFixture>.unmodifiable(fixtures);

  static Future<PsdkGoldenFixtureCorpus> load(Directory directory) async {
    final files = <File>[];
    if (await directory.exists()) {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.json')) {
          files.add(entity);
        }
      }
    }
    files.sort((left, right) => left.path.compareTo(right.path));

    final fixtures = <PsdkGoldenFixture>[];
    final scenarioIds = <String>{};
    final tags = <String>{};
    var strictAttacks = 0;
    var portedMethods = 0;
    var portedEffects = 0;

    for (final file in files) {
      final fixture = await PsdkGoldenFixture.load(file);
      final expectedScenarioId = _jsonFileStem(file);
      if (fixture.scenarioId != expectedScenarioId) {
        throw FormatException(
          'Golden fixture scenarioId "${fixture.scenarioId}" must match '
          'filename "$expectedScenarioId".',
        );
      }
      if (!scenarioIds.add(fixture.scenarioId)) {
        throw FormatException(
          'Duplicate golden fixture scenarioId "${fixture.scenarioId}".',
        );
      }
      fixtures.add(fixture);
      tags.addAll(fixture.tags);
      strictAttacks += fixture.expectedAuditDeltas.strictAttacks;
      portedMethods += fixture.expectedAuditDeltas.portedMethods;
      portedEffects += fixture.expectedAuditDeltas.portedEffects;
    }

    return PsdkGoldenFixtureCorpus(
      fixtures: fixtures,
      summary: PsdkGoldenCorpusSummary(
        count: fixtures.length,
        tags: Set<String>.unmodifiable(tags),
        auditDeltas: PsdkGoldenExpectedAuditDeltas(
          strictAttacks: strictAttacks,
          portedMethods: portedMethods,
          portedEffects: portedEffects,
        ),
      ),
    );
  }

  final List<PsdkGoldenFixture> fixtures;
  final PsdkGoldenCorpusSummary summary;
}

final class PsdkGoldenCorpusSummary {
  const PsdkGoldenCorpusSummary({
    required this.count,
    required this.tags,
    required this.auditDeltas,
  });

  final int count;
  final Set<String> tags;
  final PsdkGoldenExpectedAuditDeltas auditDeltas;
}

class PsdkGoldenExpectedAuditDeltas {
  const PsdkGoldenExpectedAuditDeltas({
    required this.strictAttacks,
    required this.portedMethods,
    required this.portedEffects,
  });

  static const zero = PsdkGoldenExpectedAuditDeltas(
    strictAttacks: 0,
    portedMethods: 0,
    portedEffects: 0,
  );

  factory PsdkGoldenExpectedAuditDeltas.fromJson(Map<String, Object?> json) {
    return PsdkGoldenExpectedAuditDeltas(
      strictAttacks: _requiredInt(json, 'strictAttacks'),
      portedMethods: _requiredInt(json, 'portedMethods'),
      portedEffects: _requiredInt(json, 'portedEffects'),
    );
  }

  final int strictAttacks;
  final int portedMethods;
  final int portedEffects;
}

class PsdkGoldenInitialBattle {
  const PsdkGoldenInitialBattle({
    required this.rngSeeds,
    required this.field,
    required this.player,
    required this.opponent,
  });

  factory PsdkGoldenInitialBattle.fromJson(Map<String, Object?> json) {
    final rngSeeds = _requiredMap(json, 'rngSeeds');
    return PsdkGoldenInitialBattle(
      rngSeeds: PsdkBattleRngSeeds(
        moveDamage: _requiredInt(rngSeeds, 'moveDamage'),
        moveCritical: _requiredInt(rngSeeds, 'moveCritical'),
        moveAccuracy: _requiredInt(rngSeeds, 'moveAccuracy'),
        generic: _requiredInt(rngSeeds, 'generic'),
      ),
      field: json['field'] == null
          ? const PsdkBattleFieldState()
          : _fieldFromJson(_requiredMap(json, 'field')),
      player: PsdkGoldenCombatant.fromJson(_requiredMap(json, 'player')),
      opponent: PsdkGoldenCombatant.fromJson(_requiredMap(json, 'opponent')),
    );
  }

  final PsdkBattleRngSeeds rngSeeds;
  final PsdkBattleFieldState field;
  final PsdkGoldenCombatant player;
  final PsdkGoldenCombatant opponent;
}

class PsdkGoldenCombatant {
  PsdkGoldenCombatant({
    required this.id,
    required this.speciesId,
    required this.displayName,
    required this.level,
    required this.maxHp,
    required this.currentHp,
    required this.types,
    required this.stats,
    required List<PsdkBattleMoveData> moves,
  }) : moves = List<PsdkBattleMoveData>.unmodifiable(moves);

  factory PsdkGoldenCombatant.fromJson(Map<String, Object?> json) {
    return PsdkGoldenCombatant(
      id: _requiredString(json, 'id'),
      speciesId: _requiredString(json, 'speciesId'),
      displayName: _requiredString(json, 'displayName'),
      level: _requiredInt(json, 'level'),
      maxHp: _requiredInt(json, 'maxHp'),
      currentHp: _requiredInt(json, 'currentHp'),
      types: _typesFromJson(_requiredMap(json, 'types')),
      stats: _statsFromJson(_requiredMap(json, 'stats')),
      moves: _requiredList(json, 'moves')
          .map((value) => _moveFromJson(_asMap(value, 'moves[]')))
          .toList(growable: false),
    );
  }

  final String id;
  final String speciesId;
  final String displayName;
  final int level;
  final int maxHp;
  final int currentHp;
  final PsdkBattleTypes types;
  final PsdkBattleStats stats;
  final List<PsdkBattleMoveData> moves;

  PsdkBattleCombatantSetup toSetup() {
    return PsdkBattleCombatantSetup(
      id: id,
      speciesId: speciesId,
      displayName: displayName,
      level: level,
      maxHp: maxHp,
      currentHp: currentHp,
      types: types,
      stats: stats,
      moves: moves,
    );
  }
}

class PsdkGoldenAction {
  const PsdkGoldenAction({
    required this.actor,
    required this.kind,
    required this.moveSlot,
  });

  factory PsdkGoldenAction.fromJson(Map<String, Object?> json) {
    final kind = _requiredEnum(
      PsdkGoldenActionKind.values,
      _requiredString(json, 'kind'),
      'kind',
    );
    if (kind != PsdkGoldenActionKind.fight) {
      throw FormatException('Unsupported golden action kind "${kind.name}".');
    }
    return PsdkGoldenAction(
      actor: _requiredEnum(
        PsdkGoldenActor.values,
        _requiredString(json, 'actor'),
        'actor',
      ),
      kind: kind,
      moveSlot: _requiredInt(json, 'moveSlot'),
    );
  }

  final PsdkGoldenActor actor;
  final PsdkGoldenActionKind kind;
  final int moveSlot;
}

class PsdkGoldenExpectedFinalState {
  const PsdkGoldenExpectedFinalState({
    required this.playerCurrentHp,
    required this.opponentCurrentHp,
    this.outcomeKind,
  });

  factory PsdkGoldenExpectedFinalState.fromJson(Map<String, Object?> json) {
    final outcomeName = json['outcomeKind'];
    return PsdkGoldenExpectedFinalState(
      playerCurrentHp: _requiredInt(_requiredMap(json, 'player'), 'currentHp'),
      opponentCurrentHp: _requiredInt(
        _requiredMap(json, 'opponent'),
        'currentHp',
      ),
      outcomeKind: outcomeName == null
          ? null
          : _requiredEnum(
              PsdkBattleOutcomeKind.values,
              _asString(outcomeName, 'outcomeKind'),
              'outcomeKind',
            ),
    );
  }

  final int playerCurrentHp;
  final int opponentCurrentHp;
  final PsdkBattleOutcomeKind? outcomeKind;

  List<String> compare(PsdkBattleTurnResult result) {
    final mismatches = <String>[];
    final player = result.state.battlerAt(psdkPlayerSlot);
    final opponent = result.state.battlerAt(psdkOpponentSlot);
    if (player.currentHp != playerCurrentHp) {
      mismatches.add(
        'player.currentHp expected $playerCurrentHp, got ${player.currentHp}',
      );
    }
    if (opponent.currentHp != opponentCurrentHp) {
      mismatches.add(
        'opponent.currentHp expected $opponentCurrentHp, '
        'got ${opponent.currentHp}',
      );
    }
    final expectedOutcomeKind = outcomeKind;
    if (expectedOutcomeKind != null &&
        result.outcome?.kind != expectedOutcomeKind) {
      mismatches.add(
        'outcomeKind expected ${expectedOutcomeKind.name}, '
        'got ${result.outcome?.kind.name ?? 'none'}',
      );
    }
    return mismatches;
  }
}

class PsdkGoldenExpectedTimeline {
  PsdkGoldenExpectedTimeline({
    required List<String> eventKinds,
    required List<PsdkGoldenExpectedDamageEvent> damageEvents,
    required List<PsdkGoldenExpectedStatusEvent> statusEvents,
    required List<PsdkGoldenExpectedStatStageEvent> statStageEvents,
  })  : eventKinds = List<String>.unmodifiable(eventKinds),
        damageEvents =
            List<PsdkGoldenExpectedDamageEvent>.unmodifiable(damageEvents),
        statusEvents =
            List<PsdkGoldenExpectedStatusEvent>.unmodifiable(statusEvents),
        statStageEvents = List<PsdkGoldenExpectedStatStageEvent>.unmodifiable(
          statStageEvents,
        );

  factory PsdkGoldenExpectedTimeline.fromJson(Map<String, Object?> json) {
    final damageEvents = json['damageEvents'] == null
        ? const <PsdkGoldenExpectedDamageEvent>[]
        : _asList(json['damageEvents'], 'damageEvents')
            .map((value) => PsdkGoldenExpectedDamageEvent.fromJson(
                  _asMap(value, 'damageEvents[]'),
                ))
            .toList(growable: false);
    final statusEvents = json['statusEvents'] == null
        ? const <PsdkGoldenExpectedStatusEvent>[]
        : _asList(json['statusEvents'], 'statusEvents')
            .map((value) => PsdkGoldenExpectedStatusEvent.fromJson(
                  _asMap(value, 'statusEvents[]'),
                ))
            .toList(growable: false);
    final statStageEvents = json['statStageEvents'] == null
        ? const <PsdkGoldenExpectedStatStageEvent>[]
        : _asList(json['statStageEvents'], 'statStageEvents')
            .map((value) => PsdkGoldenExpectedStatStageEvent.fromJson(
                  _asMap(value, 'statStageEvents[]'),
                ))
            .toList(growable: false);
    return PsdkGoldenExpectedTimeline(
      eventKinds: _requiredNonEmptyList(json, 'eventKinds')
          .map((value) => _asString(value, 'eventKinds[]'))
          .toList(growable: false),
      damageEvents: damageEvents,
      statusEvents: statusEvents,
      statStageEvents: statStageEvents,
    );
  }

  final List<String> eventKinds;
  final List<PsdkGoldenExpectedDamageEvent> damageEvents;
  final List<PsdkGoldenExpectedStatusEvent> statusEvents;
  final List<PsdkGoldenExpectedStatStageEvent> statStageEvents;

  List<String> compare(PsdkBattleTimeline timeline) {
    final mismatches = <String>[];
    final actualKinds =
        timeline.events.map((event) => event.kind).toList(growable: false);
    if (!_sameStrings(actualKinds, eventKinds)) {
      mismatches.add(
        'timeline.eventKinds expected $eventKinds, got $actualKinds',
      );
    }

    final actualDamageEvents =
        timeline.events.whereType<PsdkBattleDamageEvent>().toList();
    if (actualDamageEvents.length != damageEvents.length) {
      mismatches.add(
        'timeline.damageEvents length expected ${damageEvents.length}, '
        'got ${actualDamageEvents.length}',
      );
    }
    final count = actualDamageEvents.length < damageEvents.length
        ? actualDamageEvents.length
        : damageEvents.length;
    for (var index = 0; index < count; index += 1) {
      mismatches.addAll(damageEvents[index].compare(
        actualDamageEvents[index],
        index,
      ));
    }

    final actualStatusEvents =
        timeline.events.whereType<PsdkBattleStatusEvent>().toList();
    if (actualStatusEvents.length != statusEvents.length) {
      mismatches.add(
        'timeline.statusEvents length expected ${statusEvents.length}, '
        'got ${actualStatusEvents.length}',
      );
    }
    final statusCount = actualStatusEvents.length < statusEvents.length
        ? actualStatusEvents.length
        : statusEvents.length;
    for (var index = 0; index < statusCount; index += 1) {
      mismatches.addAll(statusEvents[index].compare(
        actualStatusEvents[index],
        index,
      ));
    }

    final actualStatStageEvents =
        timeline.events.whereType<PsdkBattleStatStageEvent>().toList();
    if (actualStatStageEvents.length != statStageEvents.length) {
      mismatches.add(
        'timeline.statStageEvents length expected ${statStageEvents.length}, '
        'got ${actualStatStageEvents.length}',
      );
    }
    final statStageCount = actualStatStageEvents.length < statStageEvents.length
        ? actualStatStageEvents.length
        : statStageEvents.length;
    for (var index = 0; index < statStageCount; index += 1) {
      mismatches.addAll(statStageEvents[index].compare(
        actualStatStageEvents[index],
        index,
      ));
    }
    return mismatches;
  }
}

class PsdkGoldenExpectedDamageEvent {
  const PsdkGoldenExpectedDamageEvent({
    required this.moveId,
    required this.damage,
    required this.remainingHp,
  });

  factory PsdkGoldenExpectedDamageEvent.fromJson(Map<String, Object?> json) {
    return PsdkGoldenExpectedDamageEvent(
      moveId: _requiredString(json, 'moveId'),
      damage: _requiredInt(json, 'damage'),
      remainingHp: _requiredInt(json, 'remainingHp'),
    );
  }

  final String moveId;
  final int damage;
  final int remainingHp;

  List<String> compare(PsdkBattleDamageEvent event, int index) {
    final mismatches = <String>[];
    if (event.moveId != moveId) {
      mismatches.add(
        'timeline.damageEvents[$index].moveId expected $moveId, '
        'got ${event.moveId}',
      );
    }
    if (event.damage != damage) {
      mismatches.add(
        'timeline.damageEvents[$index].damage expected $damage, '
        'got ${event.damage}',
      );
    }
    if (event.remainingHp != remainingHp) {
      mismatches.add(
        'timeline.damageEvents[$index].remainingHp expected $remainingHp, '
        'got ${event.remainingHp}',
      );
    }
    return mismatches;
  }
}

class PsdkGoldenExpectedStatusEvent {
  const PsdkGoldenExpectedStatusEvent({
    required this.moveId,
    required this.status,
  });

  factory PsdkGoldenExpectedStatusEvent.fromJson(Map<String, Object?> json) {
    return PsdkGoldenExpectedStatusEvent(
      moveId: _requiredString(json, 'moveId'),
      status: _requiredEnum(
        PsdkBattleMajorStatus.values,
        _requiredString(json, 'status'),
        'status',
      ),
    );
  }

  final String moveId;
  final PsdkBattleMajorStatus status;

  List<String> compare(PsdkBattleStatusEvent event, int index) {
    final mismatches = <String>[];
    if (event.moveId != moveId) {
      mismatches.add(
        'timeline.statusEvents[$index].moveId expected $moveId, '
        'got ${event.moveId}',
      );
    }
    if (event.status != status) {
      mismatches.add(
        'timeline.statusEvents[$index].status expected ${status.name}, '
        'got ${event.status.name}',
      );
    }
    return mismatches;
  }
}

class PsdkGoldenExpectedStatStageEvent {
  const PsdkGoldenExpectedStatStageEvent({
    required this.stat,
    required this.amount,
    required this.currentStage,
  });

  factory PsdkGoldenExpectedStatStageEvent.fromJson(
    Map<String, Object?> json,
  ) {
    return PsdkGoldenExpectedStatStageEvent(
      stat: _requiredString(json, 'stat'),
      amount: _requiredInt(json, 'amount'),
      currentStage: _requiredInt(json, 'currentStage'),
    );
  }

  final String stat;
  final int amount;
  final int currentStage;

  List<String> compare(PsdkBattleStatStageEvent event, int index) {
    final mismatches = <String>[];
    if (event.stat != stat) {
      mismatches.add(
        'timeline.statStageEvents[$index].stat expected $stat, '
        'got ${event.stat}',
      );
    }
    if (event.amount != amount) {
      mismatches.add(
        'timeline.statStageEvents[$index].amount expected $amount, '
        'got ${event.amount}',
      );
    }
    if (event.currentStage != currentStage) {
      mismatches.add(
        'timeline.statStageEvents[$index].currentStage expected '
        '$currentStage, got ${event.currentStage}',
      );
    }
    return mismatches;
  }
}

PsdkBattleTypes _typesFromJson(Map<String, Object?> json) {
  return PsdkBattleTypes(
    primary: _requiredString(json, 'primary'),
    secondary: _optionalString(json, 'secondary'),
  );
}

PsdkBattleStats _statsFromJson(Map<String, Object?> json) {
  return PsdkBattleStats(
    attack: _requiredInt(json, 'attack'),
    defense: _requiredInt(json, 'defense'),
    specialAttack: _requiredInt(json, 'specialAttack'),
    specialDefense: _requiredInt(json, 'specialDefense'),
    speed: _requiredInt(json, 'speed'),
  );
}

PsdkBattleFieldState _fieldFromJson(Map<String, Object?> json) {
  return PsdkBattleFieldState(
    weather: json['weather'] == null
        ? null
        : _weatherStateFromJson(_requiredMap(json, 'weather')),
    terrain: json['terrain'] == null
        ? null
        : _terrainStateFromJson(_requiredMap(json, 'terrain')),
  );
}

PsdkBattleWeatherState _weatherStateFromJson(Map<String, Object?> json) {
  return PsdkBattleWeatherState(
    id: _requiredEnum(
      PsdkBattleWeatherId.values,
      _requiredString(json, 'id'),
      'weather.id',
    ),
    remainingTurns: _requiredInt(json, 'remainingTurns'),
  );
}

PsdkBattleTerrainState _terrainStateFromJson(Map<String, Object?> json) {
  return PsdkBattleTerrainState(
    id: _requiredEnum(
      PsdkBattleTerrainId.values,
      _requiredString(json, 'id'),
      'terrain.id',
    ),
    remainingTurns: _requiredInt(json, 'remainingTurns'),
  );
}

PsdkBattleMoveData _moveFromJson(Map<String, Object?> json) {
  return PsdkBattleMoveData(
    id: _requiredString(json, 'id'),
    dbSymbol: _requiredString(json, 'dbSymbol'),
    name: _requiredString(json, 'name'),
    type: _requiredString(json, 'type'),
    category: _requiredEnum(
      PsdkBattleMoveCategory.values,
      _requiredString(json, 'category'),
      'category',
    ),
    power: _requiredInt(json, 'power'),
    accuracy: _requiredInt(json, 'accuracy'),
    pp: _requiredInt(json, 'pp'),
    currentPp: _optionalInt(json, 'currentPp'),
    priority: _requiredInt(json, 'priority'),
    criticalRate: _optionalInt(json, 'criticalRate') ?? 1,
    effectChance: _optionalInt(json, 'effectChance'),
    battleEngineMethod: _requiredString(json, 'battleEngineMethod'),
    target: _requiredEnum(
      PsdkBattleMoveTarget.values,
      _requiredString(json, 'target'),
      'target',
    ),
    contact: _optionalBool(json, 'contact') ??
        _optionalBool(json, 'isDirect') ??
        false,
    protectable: _optionalBool(json, 'protectable') ?? true,
    sound: _optionalBool(json, 'sound') ?? false,
    bite: _optionalBool(json, 'bite') ?? false,
    pulse: _optionalBool(json, 'pulse') ?? false,
    ballistics: _optionalBool(json, 'ballistics') ??
        _optionalBool(json, 'ballistic') ??
        false,
    kingRockUtility: _optionalBool(json, 'kingRockUtility') ??
        _optionalBool(json, 'isKingRockUtility') ??
        false,
    heal: _optionalBool(json, 'heal') ?? _optionalBool(json, 'isHeal') ?? false,
    snatchable: _optionalBool(json, 'snatchable') ??
        _optionalBool(json, 'isSnatchable') ??
        false,
    magicCoatAffected: _optionalBool(json, 'magicCoatAffected') ??
        _optionalBool(json, 'isMagicCoatAffected') ??
        false,
    statuses: _statusesFromJson(json['statuses']),
    stageMods: _stageModsFromJson(json['stageMods']),
  );
}

List<PsdkBattleMoveStatus> _statusesFromJson(Object? value) {
  if (value == null) {
    return const <PsdkBattleMoveStatus>[];
  }
  return _asList(value, 'statuses')
      .map((entry) => _statusFromJson(_asMap(entry, 'statuses[]')))
      .toList(growable: false);
}

PsdkBattleMoveStatus _statusFromJson(Map<String, Object?> json) {
  final chance = _requiredInt(json, 'chance');
  final volatileStatus = json['volatileStatus'];
  if (volatileStatus != null) {
    return PsdkBattleMoveStatus.volatile(
      status: _requiredEnum(
        PsdkBattleVolatileStatus.values,
        _asString(volatileStatus, 'volatileStatus'),
        'volatileStatus',
      ),
      chance: chance,
    );
  }
  return PsdkBattleMoveStatus(
    status: _requiredEnum(
      PsdkBattleMajorStatus.values,
      _requiredString(json, 'status'),
      'status',
    ),
    chance: chance,
  );
}

List<PsdkBattleMoveStageMod> _stageModsFromJson(Object? value) {
  if (value == null) {
    return const <PsdkBattleMoveStageMod>[];
  }
  return _asList(value, 'stageMods')
      .map((entry) => _stageModFromJson(_asMap(entry, 'stageMods[]')))
      .toList(growable: false);
}

PsdkBattleMoveStageMod _stageModFromJson(Map<String, Object?> json) {
  return PsdkBattleMoveStageMod(
    stat: _requiredString(json, 'stat'),
    stages: _requiredInt(json, 'stages'),
    chance: _optionalInt(json, 'chance'),
  );
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String field) {
  if (!json.containsKey(field)) {
    throw FormatException('Missing required field "$field".');
  }
  return _asMap(json[field], field);
}

List<Object?> _requiredList(Map<String, Object?> json, String field) {
  if (!json.containsKey(field)) {
    throw FormatException('Missing required field "$field".');
  }
  return _asList(json[field], field);
}

List<Object?> _requiredNonEmptyList(
  Map<String, Object?> json,
  String field,
) {
  final list = _requiredList(json, field);
  if (list.isEmpty) {
    throw FormatException('Expected "$field" to be a non-empty list.');
  }
  return list;
}

List<String> _requiredNonEmptyStringList(
  Map<String, Object?> json,
  String field,
) {
  return _requiredNonEmptyList(json, field)
      .map((value) => _asString(value, '$field[]'))
      .toList(growable: false);
}

String _requiredString(Map<String, Object?> json, String field) {
  if (!json.containsKey(field)) {
    throw FormatException('Missing required field "$field".');
  }
  return _asString(json[field], field);
}

String? _optionalString(Map<String, Object?> json, String field) {
  final value = json[field];
  return value == null ? null : _asString(value, field);
}

int _requiredInt(Map<String, Object?> json, String field) {
  if (!json.containsKey(field)) {
    throw FormatException('Missing required field "$field".');
  }
  return _asInt(json[field], field);
}

int? _optionalInt(Map<String, Object?> json, String field) {
  final value = json[field];
  return value == null ? null : _asInt(value, field);
}

bool? _optionalBool(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  throw FormatException('Expected "$field" to be a bool.');
}

Map<String, Object?> _asMap(Object? value, String field) {
  if (value is Map) {
    return value.map((key, entryValue) {
      if (key is! String) {
        throw FormatException('Expected "$field" map keys to be strings.');
      }
      return MapEntry(key, entryValue);
    });
  }
  throw FormatException('Expected "$field" to be an object.');
}

List<Object?> _asList(Object? value, String field) {
  if (value is List) {
    return value;
  }
  throw FormatException('Expected "$field" to be a list.');
}

String _asString(Object? value, String field) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Expected "$field" to be a non-empty string.');
}

int _asInt(Object? value, String field) {
  if (value is int) {
    return value;
  }
  throw FormatException('Expected "$field" to be an integer.');
}

T _requiredEnum<T extends Enum>(
  Iterable<T> values,
  String name,
  String field,
) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  throw FormatException('Unsupported "$field" value "$name".');
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

void _validateGateTags(List<String> tags) {
  if (!tags.any(psdkGoldenGateTags.contains)) {
    throw FormatException(
      'Expected "tags" to contain at least one PSDK gate tag: '
      '${psdkGoldenGateTags.join(', ')}.',
    );
  }
}

String _jsonFileStem(File file) {
  final path = file.path.replaceAll('\\', '/');
  final filename = path.split('/').last;
  return filename.endsWith('.json')
      ? filename.substring(0, filename.length - '.json'.length)
      : filename;
}
