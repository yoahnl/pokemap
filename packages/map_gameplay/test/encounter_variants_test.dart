import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

const _entry =
    ProjectEncounterEntry(speciesId: 'fallback', minLevel: 2, maxLevel: 2);
const _source = EncounterSource(
    kind: EncounterSourceKind.gameplayZone,
    id: 'source',
    priority: 0,
    encounter: EncounterZonePayload(encounterTableId: 'route'));
final _factContext = ScriptEvaluationContext(
  narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts([
    NarrativeFactDefinition(
        id: 'edition',
        label: 'Edition',
        initialValue: NarrativeValue.string('heartgold')),
  ]),
);

ProjectEncounterTable _table(
        {List<ProjectEncounterEntry> entries = const [],
        List<ProjectEncounterVariant> variants = const [],
        EncounterKind kind = EncounterKind.walk,
        double chance = 1}) =>
    ProjectEncounterTable(
        id: 'route',
        name: 'Route',
        encounterKind: kind,
        chancePerStep: chance,
        entries: entries,
        variants: variants);

ProjectEncounterVariant _variant(String id,
        {int priority = 0,
        List<LocalTimeWindow> windows = const [],
        String? edition,
        List<ProjectEncounterEntry>? entries}) =>
    ProjectEncounterVariant(
      id: id,
      name: id,
      priority: priority,
      timeWindows: windows,
      conditions: edition == null
          ? []
          : [
              ScriptConditionFactory.factEquals(
                  'edition', NarrativeValue.string(edition)),
            ],
      entries: entries ??
          [ProjectEncounterEntry(speciesId: id, minLevel: 3, maxLevel: 3)],
    );

GameState _state(String edition, {bool repel = false}) => GameState(
      saveId: 'test',
      narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
          valuesByFactId: {'edition': NarrativeValue.string(edition)}),
      party: const PlayerParty(members: [
        PlayerPokemon(
            individualId: 'lead',
            speciesId: 'lead',
            natureId: 'hardy',
            abilityId: 'none',
            level: 4)
      ]),
      repelState: repel
          ? RepelState.active(itemId: 'repel', steps: 10)
          : const RepelState.empty(),
    );

GameplayEncounterCheckResult _check(
  ProjectEncounterTable table, {
  int? minute,
  GameState? state,
  Random? random,
}) {
  final project = ProjectManifest(
      name: 'Test', maps: [], tilesets: [], encounterTables: [table]);
  const map =
      MapData(id: 'map', name: 'Map', size: GridSize(width: 1, height: 1));
  return checkEncounterFromSource(
    world: GameplayWorldState.initial(
        map: map, project: project, playerPos: const GridPos(x: 0, y: 0)),
    project: project,
    source: EncounterSource(
        kind: _source.kind,
        id: _source.id,
        priority: 0,
        encounter: EncounterZonePayload(
            encounterTableId: 'route', encounterKind: table.encounterKind)),
    encounterKind: table.encounterKind,
    gameState: state,
    conditionContext: _factContext,
    encounterContext: minute == null
        ? null
        : EncounterEvaluationContext(localMinuteOfDay: minute),
    random: random ?? Random(1),
  );
}

void main() {
  test('no variants preserves the baseline RNG and fallback', () {
    final rng = _CountingRandom();
    final result = _check(_table(entries: [_entry]), random: rng);
    expect(result.encounter?.speciesId, 'fallback');
    expect(result.encounter?.variantId, isNull);
    expect(rng.calls, ['double', 'int:1', 'int:1']);
  });

  for (final edition in ['heartgold', 'soulsilver']) {
    for (final (minute, period) in [
      (0, 'night'),
      (239, 'night'),
      (240, 'morning'),
      (599, 'morning'),
      (600, 'day'),
      (1199, 'day'),
      (1200, 'night'),
      (1439, 'night')
    ]) {
      test('$edition at minute $minute selects $period through persisted fact',
          () {
        final table = _table(variants: [
          for (final version in ['heartgold', 'soulsilver']) ...[
            _variant('$version-morning', edition: version, windows: [
              const LocalTimeWindow(startMinute: 240, endMinute: 600)
            ]),
            _variant('$version-day', edition: version, windows: [
              const LocalTimeWindow(
                  startMinute: 600, endMinute: 1200)
            ]),
            _variant('$version-night', edition: version, windows: [
              const LocalTimeWindow(
                  startMinute: 1200, endMinute: 240)
            ]),
          ],
        ]);
        final restored = GameState.fromJson(_state(edition).toJson());
        final result = _check(ProjectEncounterTable.fromJson(table.toJson()),
            minute: minute, state: restored);
        expect(result.encounter?.speciesId, '$edition-$period');
        expect(result.encounter?.variantId, '$edition-$period');
        expect(GameplayEncounter.fromJson(result.encounter!.toJson()).variantId,
            '$edition-$period');
      });
    }
  }

  test('higher priority wins independently of authored order', () {
    final variants = [_variant('low'), _variant('high', priority: 5)];
    for (final order in [variants, variants.reversed.toList()]) {
      expect(
          _check(_table(entries: [_entry], variants: order))
              .encounter
              ?.speciesId,
          'high');
    }
  });

  test('an equal-priority overlap refuses before RNG', () {
    final rng = _CountingRandom();
    final result =
        _check(_table(variants: [_variant('a'), _variant('b')]), random: rng);
    expect(result.status, GameplayEncounterCheckStatus.ambiguousVariant);
    expect(rng.calls, isEmpty);
    expect(result.encounter, isNull);
  });

  test('no match refuses without RNG; an explicit fallback is usable', () {
    final variants = [_variant('only', edition: 'soulsilver')];
    final rng = _CountingRandom();
    expect(
        _check(_table(variants: variants),
                state: _state('heartgold'), random: rng)
            .status,
        GameplayEncounterCheckStatus.noEligibleVariant);
    expect(rng.calls, isEmpty);
    expect(
        _check(_table(entries: [_entry], variants: variants),
                state: _state('heartgold'))
            .encounter
            ?.speciesId,
        'fallback');
  });

  test('typed version conditions require a resolver even under negation', () {
    final conditioned = _variant('chosen').copyWith(conditions: [
      ScriptConditionFactory.not(ScriptConditionFactory.factEquals('edition', const NarrativeValue.string('soulsilver'))),
    ]);
    final result = resolveEncounterVariant(table: _table(entries: [_entry], variants: [conditioned]), gameState: _state('heartgold'));
    expect(result.refusal, GameplayEncounterCheckStatus.conditionContextUnavailable);
  });

  test('missing temporal context refuses rather than selecting a fallback', () {
    final rng = _CountingRandom();
    expect(
        _check(
                _table(entries: [
                  _entry
                ], variants: [
                  _variant('timed', windows: [
                    const LocalTimeWindow(
                        startMinute: 100, endMinute: 200)
                  ]),
                ]),
                random: rng)
            .status,
        GameplayEncounterCheckStatus.encounterTimeUnavailable);
    expect(rng.calls, isEmpty);
  });

  for (final kind in [
    EncounterKind.walk,
    EncounterKind.surf,
    EncounterKind.oldRod,
    EncounterKind.goodRod,
    EncounterKind.superRod,
    EncounterKind.headbutt
  ]) {
    test(
        '$kind uses selected weights, inclusive levels, authored rate and Repel',
        () {
      final variant = _variant('chosen', entries: const [
        ProjectEncounterEntry(
            speciesId: 'a', minLevel: 2, maxLevel: 4, weight: 3),
        ProjectEncounterEntry(
            speciesId: 'b', minLevel: 5, maxLevel: 6, weight: 1),
      ]);
      final table = _table(kind: kind, chance: .25, variants: [variant]);
      final failed = _CountingRandom(roll: .25);
      expect(_check(table, random: failed).status,
          GameplayEncounterCheckStatus.rollFailed);
      expect(failed.calls, ['double']);
      final low = _CountingRandom(integers: [0, 0]);
      final lowResult =
          _check(table, random: low, state: _state('heartgold', repel: true));
      expect(low.calls, ['double', 'int:4', 'int:3']);
      expect(
          lowResult.status,
          {EncounterKind.walk, EncounterKind.surf}.contains(kind)
              ? GameplayEncounterCheckStatus.repelled
              : GameplayEncounterCheckStatus.triggered);
      final high = _check(table,
          random: _CountingRandom(integers: [3, 1]),
          state: _state('heartgold', repel: true));
      expect(high.encounter?.speciesId, 'b');
      expect(high.encounter?.level, 6);
      final equal = _check(table,
          random: _CountingRandom(integers: [0, 2]),
          state: _state('heartgold', repel: true));
      expect(equal.encounter?.level, 4);
    });
  }
}

final class _CountingRandom implements Random {
  _CountingRandom({this.roll = 0, this.integers = const [0, 0]});
  final double roll;
  final List<int> integers;
  final List<String> calls = [];
  int index = 0;
  @override
  double nextDouble() {
    calls.add('double');
    return roll;
  }

  @override
  int nextInt(int max) {
    calls.add('int:$max');
    return integers[index++ % integers.length] % max;
  }

  @override
  bool nextBool() => throw StateError('Unexpected RNG operation');
}
