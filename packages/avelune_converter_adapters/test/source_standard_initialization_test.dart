import 'dart:convert';

import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:avelune_converter_adapters/src/source_system_entry_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

const _body = [
  LiteralFixtureEventCommand(122, [1, 1, 0, 1, 3]),
  LiteralFixtureEventCommand(122, [1, 1, 5, 0, 3]),
  LiteralFixtureEventCommand(111, [1, 1, 0, 0, 0]),
  LiteralFixtureEventCommand(123, ['A', 1], indent: 1),
  LiteralFixtureEventCommand(123, ['B', 1], indent: 1),
  LiteralFixtureEventCommand(411, []),
  LiteralFixtureEventCommand(123, ['B', 0], indent: 1),
  LiteralFixtureEventCommand(412, []),
  LiteralFixtureEventCommand(355, ['setTempSwitchOn("A")']),
];

Future<
    ({
      NormalizedSourceProject source,
      SourceEventDefinition event,
      SourceEventProjection projection
    })> _project({
  List<LiteralFixtureEventCommand> commands = _body,
  String switchName = 's:tsOff?("A")',
  bool highest = true,
  bool retained = true,
  bool visible = false,
  bool through = false,
  int trigger = 3,
}) async {
  final fixture = await LiteralTileFixture.create(
      namespace: 'standard-initialization',
      scriptsBytes: syntheticInterpretationArchive,
      interpretationProfile: syntheticSourceInterpretationProfile,
      includeEventSystem: true,
      switchNames: [
        null,
        switchName
      ],
      variableNames: [
        null,
        'Scratch',
        'Other',
        'Epoch'
      ],
      maps: [
        LiteralFixtureMap(id: 71, events: [
          LiteralFixtureEvent(
              id: 9,
              name: 'Original custom actor',
              x: 1,
              y: 0,
              pages: [
                const LiteralFixtureEventPage(commands: [
                  LiteralFixtureEventCommand(355, ['unqualified_interview()'])
                ]),
                const LiteralFixtureEventPage(selfSwitch: 'B', commands: [
                  LiteralFixtureEventCommand(355, ['unqualified_phone()'])
                ]),
                LiteralFixtureEventPage(
                    globalSwitch: 1,
                    trigger: trigger,
                    characterName: visible ? 'Original actor' : '',
                    through: through,
                    commands: commands),
                if (!highest) const LiteralFixtureEventPage(commands: []),
              ]),
        ]),
      ]);
  final analysis = SourceEventAnalyzer.forProject(fixture.source,
          profile: SourceEventProfile.forProject(fixture.source))
      .analyze();
  final projection = const SourceEventProjector().project(
      source: fixture.source,
      analysis: analysis,
      nativeMaps: {
        71: MapData(
            id: 'native',
            name: 'Native',
            size: const GridSize(width: 3, height: 1),
            layers: []),
      },
      retentionPolicy: retained
          ? MapInstanceRetentionPolicy(
              viewportWidthTiles: 20, viewportHeightTiles: 15, marginTiles: 1)
          : null);
  return (
    source: fixture.source,
    event: analysis.events.single,
    projection: projection
  );
}

void main() {
  test('an invisible through initializer retains its nonblocking anchor',
      () async {
    final projection = (await _project(through: true)).projection;
    expect(projection.scenes, hasLength(1));
    expect(projection.nativeMaps[71]!.entities.single.blocksMovement, isFalse);
  });
  test(
      'a highest standard initializer executes while custom pages stay quarantined',
      () async {
    final result = await _project();
    final projection = result.projection;
    final row = (projection.semanticEvidence['events'] as List).single as Map;
    expect(result.event.isQuarantined, isTrue);
    expect(row['status'], 'partiallyAdapted');
    expect(row['nativeStandardInitializationPages'], [2]);
    expect(sourceSystemEntryEventsQualified(result.source, projection, 71),
        isTrue);
    expect(row['gaps'], isNotEmpty);
    expect(projection.semanticEvidence['qualifiedEventCount'], 0);
    expect(projection.semanticEvidence['partiallyAdaptedEventCount'], 1);
    expect(projection.semanticEvidence['quarantinedEventCount'], 0);
    expect(projection.staticSemanticsQualified, isFalse);
    expect(projection.scenes, hasLength(1));
    expect(projection.scenes.single.metadata['sourcePageIndex'], '2');
    expect(buildSceneRuntimePlan(projection.scenes.single).canBuild, isTrue);
    expect(
        projection.registry.records
            .where((record) => record.definitionOrNull != null),
        hasLength(1));
    expect(
        projection.registry.records
            .where((record) => record.definitionOrNull == null),
        hasLength(1));
    final anchor = projection.nativeMaps[71]!.entities.single;
    expect(anchor.kind, MapEntityKind.custom);
    expect(anchor.blocksMovement, isFalse);
    expect(anchor.npc, isNull);
    final definition = projection.registry.records
        .singleWhere((record) => record.definitionOrNull != null)
        .definitionOrNull!;
    expect(definition.source,
        NarrativeEventSourceRef.entityAutorun('native', anchor.id));
    expect(definition.conditionExpression.toJson().toString(),
        contains('mapEventInstanceBoolean'));
    final effects = projection.scenes.single.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((payload) => payload.consequence)
        .whereType<SceneConsequence>()
        .toList();
    expect(effects.whereType<SceneCalculateIntegerFactsConsequence>(),
        hasLength(2));
    expect(
        effects
            .whereType<SceneSetMapEventInstanceBooleanConsequence>()
            .single
            .key,
        'A');
    expect(
        effects
            .whereType<SceneSetMapEventInstanceBooleanConsequence>()
            .single
            .value,
        isTrue);
    expect(
        projection.facts
            .where((fact) => fact.valueKind == NarrativeValueKind.integer),
        hasLength(2));
    final serialized = jsonEncode(projection.scenes.single.toJson());
    expect(serialized, isNot(contains('unqualified_interview')));
    expect(serialized, isNot(contains('unqualified_phone')));
  });

  for (final entry in <String, List<LiteralFixtureEventCommand>>{
    'unknown body': [
      ..._body.take(_body.length - 1),
      const LiteralFixtureEventCommand(355, ['unknown_effect()']),
      _body.last
    ],
    'missing terminator': _body.take(_body.length - 1).toList(),
    'wrong terminator': [
      ..._body.take(_body.length - 1),
      const LiteralFixtureEventCommand(355, ['setTempSwitchOn("B")'])
    ],
    'input': [
      const LiteralFixtureEventCommand(103, [1, 3]),
      _body.last
    ],
    'random': [
      const LiteralFixtureEventCommand(122, [1, 1, 0, 2, 0, 2]),
      _body.last
    ],
    'wait': [
      const LiteralFixtureEventCommand(106, [1]),
      _body.last
    ],
    'transfer': [
      const LiteralFixtureEventCommand(201, [0, 71, 1, 0, 0, 1]),
      _body.last
    ],
    'exit': [const LiteralFixtureEventCommand(115, []), _body.last],
  }.entries) {
    test('a partial initializer refuses ${entry.key}', () async {
      expect(
          (await _project(commands: entry.value)).projection.scenes, isEmpty);
    });
  }

  test('a partial initializer requires the negative temporary guard', () async {
    expect((await _project(switchName: 's:tsOn?("A")')).projection.scenes,
        isEmpty);
    expect(
        (await _project(switchName: 'Ordinary source switch'))
            .projection
            .scenes,
        isEmpty);
  });

  test('a lower priority initializer is not detached from page arbitration',
      () async {
    expect((await _project(highest: false)).projection.scenes, isEmpty);
  });

  test('a partial initializer requires the map instance retention contract',
      () async {
    expect((await _project(retained: false)).projection.scenes, isEmpty);
  });

  test('a partial initializer cannot promote a visible or parallel actor',
      () async {
    expect((await _project(visible: true)).projection.scenes, isEmpty);
    expect((await _project(trigger: 4)).projection.scenes, isEmpty);
  });
}
