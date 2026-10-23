import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

List<int> _scriptArchive(List<List<int>> sections) {
  List<int> size(int value) => value == 0 ? [0] : value < 123 ? [value + 5] : [2, value & 255, value >> 8];
  List<int> bytes(List<int> value) => [34, ...size(value.length), ...value];
  return [4, 8, 91, ...size(sections.length),
    for (var i = 0; i < sections.length; i++) ...[
      91, 8, 105, ...size(i), ...bytes(utf8.encode('Section $i')), ...bytes(zlib.encode(sections[i])),
    ],
  ];
}

Future<({LiteralTileFixture fixture, SourceEventAnalysis analysis, SourceEventProjection projection})>
    _source(List<LiteralFixtureEventCommand> commands,
        {List<LiteralFixtureEventCommand>? sibling, int maximumMoney = 123,
        Map<int, List<LiteralFixtureEventCommand>> common = const {},
        int eventId = 1, String name = 'Original numeric event'}) async {
  final settings = utf8.encode('module Settings\n  MAX_MONEY = $maximumMoney\nend\n');
  final archive = _scriptArchive([syntheticInterpretationSection, settings]);
  final profile = SourceInterpretationProfile.fromJson({
    ...syntheticSourceInterpretationProfile.toJson(),
    'scriptsArchive': {'relativePath': 'Data/Scripts.rxdata', 'sha256': literalFixtureHash(archive).value},
    'sections': {
      for (final entry in syntheticSourceInterpretationProfile.sections.entries)
        entry.key: {...entry.value, 'name': 'Section 0'},
      'events.Settings': {'index': 1, 'name': 'Section 1', 'sha256': literalFixtureHash(settings).value},
    },
  });
  final fixture = await LiteralTileFixture.create(
    interpretationProfile: profile, scriptsBytes: archive, includeEventSystem: true,
    variableNames: [null, for (var i = 1; i <= 6; i++) 'Variable $i'],
    commonEvents: common,
    maps: [LiteralFixtureMap(id: 1, events: [
      LiteralFixtureEvent(id: eventId, name: name, x: 1, y: 0,
        pages: [LiteralFixtureEventPage(commands: commands)]),
      if (sibling != null) LiteralFixtureEvent(id: eventId + 1, x: 2, y: 0,
        pages: [LiteralFixtureEventPage(commands: sibling)]),
    ])]);
  final analysis = SourceEventAnalyzer.forProject(fixture.source,
    profile: SourceEventProfile.forProject(fixture.source)).analyze();
  final projection = const SourceEventProjector().project(source: fixture.source,
    analysis: analysis, nativeMaps: {1: MapData(id: 'native', name: 'Native',
      size: const GridSize(width: 3, height: 1), layers: [])});
  return (fixture: fixture, analysis: analysis, projection: projection);
}

Future<({GameState state, List<String> text})> _run(SourceEventProjection projection,
    {GameState initial = const GameState(saveId: 'original')}) async {
  var state = initial;
  final resolver = NarrativeFactRuntimeResolver.fromFacts(projection.facts);
  final writer = NarrativeFactRuntimeWriter(resolver);
  final integers = SceneIntegerOperations(resolver);
  final shown = <String>[];
  final plan = buildSceneRuntimePlan(projection.scenes.single);
  expect(plan.plan, isNotNull);
  final result = await SceneRuntimeExecutor(callbacks: SceneRuntimeExecutionCallbacks(
    evaluateCondition: (intent) {
      final condition = intent.conditionSource!;
      if (condition.sourceKind == SceneConditionSourceKind.integerComparison) {
        return integers.compare(state, condition) ? 'true' : 'false';
      }
      final resolved = resolver.resolve(factId: condition.sourceId,
        runtimeState: state.narrativeFactRuntimeState, storyFlags: state.storyFlags)
        as NarrativeFactRuntimeResolved;
      return resolved.narrativeValue.matches(condition.resolvedFactOperator,
        condition.resolvedExpectedFactValue) ? 'true' : 'false';
    },
    showDialogue: (intent) {
      final doc = const YarnDialogueCompiler().compile(projection.dialogueSources[intent.dialogueId]!);
      shown.addAll(doc.nodes.single.steps.whereType<RuntimeDialogueLine>().map((line) => line.text));
      return 'completed';
    },
    applyConsequence: (consequence) {
      switch (consequence) {
        case SceneCalculateIntegerFactsConsequence():
          final written = integers.calculate(state, consequence);
          expect(written.success, isTrue, reason: '${written.error}');
          state = written.gameState;
        case SceneAdjustMoneyConsequence():
          final written = integers.adjustMoney(state, consequence);
          expect(written.success, isTrue, reason: '${written.error}');
          state = written.gameState;
        case SceneSetFactConsequence():
          final written = writer.setFactValue(gameState: state,
            factId: consequence.factId, value: consequence.narrativeValue);
          expect(written.success, isTrue);
          state = written.gameState;
        default:
          throw StateError('Unexpected effect ${consequence.kind}');
      }
      return 'completed';
    },
    executeInteractiveCommand: (_) => 'completed',
    startBattle: (_) => throw StateError('No battle'),
    playCinematic: (_) => throw StateError('No cinematic'),
  )).execute(plan.plan!);
  expect(result.status, SceneRuntimeExecutionStatus.completed);
  return (state: GameState.fromJson(jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>), text: shown);
}

int _value(SourceEventProjection projection, GameState state, int variable) {
  final fact = projection.facts.singleWhere((fact) => fact.description.endsWith('variable:$variable'));
  final result = NarrativeFactRuntimeResolver.fromFacts(projection.facts).resolve(
    factId: fact.id, runtimeState: state.narrativeFactRuntimeState, storyFlags: state.storyFlags)
    as NarrativeFactRuntimeResolved;
  return result.narrativeValue.intValue;
}

void main() {
  test('STD04 automatic range calculations snapshot operands and serialize RNG', () async {
    final source = await _source(const [
      LiteralFixtureEventCommand(122, [1, 1, 0, 0, 8]),
      LiteralFixtureEventCommand(122, [2, 2, 0, 1, 1]),
      LiteralFixtureEventCommand(122, [1, 3, 1, 1, 2]),
      LiteralFixtureEventCommand(122, [4, 5, 0, 2, 10, 20]),
      LiteralFixtureEventCommand(111, [1, 1, 1, 2, 0]),
      LiteralFixtureEventCommand(101, ['Equal'], indent: 1),
      LiteralFixtureEventCommand(412, []),
    ]);
    expect(source.projection.scenes, hasLength(1), reason: jsonEncode(source.projection.semanticEvidence['events']));
    final played = await _run(source.projection);
    expect([for (var id = 1; id <= 3; id++) _value(source.projection, played.state, id)], [16, 16, 8]);
    expect(_value(source.projection, played.state, 4), _value(source.projection, played.state, 5));
    expect(played.text, ['Equal']);
    final repeated = await _run(source.projection);
    expect(repeated.state.sceneRandomState, played.state.sceneRandomState);
  });

  test('STD04 native number input preserves source cancellation and integer Fact', () async {
    final source = await _source(const [LiteralFixtureEventCommand(103, [2, 3])]);
    expect(source.projection.scenes, hasLength(1), reason: jsonEncode(source.projection.semanticEvidence['events']));
    final commands = source.projection.scenes.single.graph.nodes.map((node) => node.payload)
      .whereType<SceneActionPayload>().map((payload) => payload.interactiveCommand)
      .whereType<SceneInputIntegerToFactInteractiveCommand>();
    expect(commands.single.digits, 3);
    expect(commands.single.cancellationPolicy, SceneIntegerCancellationPolicy.restoreInitialAndComplete);
    expect(commands.single.allowCancel, isTrue);
    expect(source.projection.facts.single.valueKind, NarrativeValueKind.integer);
  });

  test('STD04 debit clamps and continues with the attested configurable money limit', () async {
    final source = await _source(const [
      LiteralFixtureEventCommand(125, [1, 0, 200]),
      LiteralFixtureEventCommand(101, ['Continued']),
      LiteralFixtureEventCommand(125, [0, 0, 999]),
    ], maximumMoney: 321);
    expect(sourceEventMoneyMaximum(source.fixture.source), 321);
    expect(source.projection.scenes, hasLength(1), reason: jsonEncode(source.projection.semanticEvidence['events']));
    final played = await _run(source.projection,
      initial: const GameState(saveId: 'money', trainerProfile: TrainerProfile(name: 'Player', money: 50)));
    expect(played.text, ['Continued']);
    expect(played.state.trainerProfile.money, 321);
  });

  test('STD04 variable money uses signed mutation and source conditions', () async {
    final source = await _source(const [
      LiteralFixtureEventCommand(122, [2, 2, 0, 0, -10]),
      LiteralFixtureEventCommand(125, [1, 1, 2]),
      LiteralFixtureEventCommand(111, [7, 10, 0]),
      LiteralFixtureEventCommand(101, ['Enough'], indent: 1),
      LiteralFixtureEventCommand(412, []),
    ]);
    expect(source.projection.scenes, hasLength(1), reason: jsonEncode(source.projection.semanticEvidence['events']));
    final played = await _run(source.projection);
    expect(played.state.trainerProfile.money, 10);
    expect(played.text, ['Enough']);
  });

  test('STD04 common computations remain generic across names and IDs', () async {
    for (final id in [1, 67]) {
      final source = await _source(const [LiteralFixtureEventCommand(117, [3])],
        eventId: id, name: 'Independent $id', common: const {3: [
          LiteralFixtureEventCommand(122, [1, 1, 3, 0, 2]),
          LiteralFixtureEventCommand(101, ['After']),
        ]});
      expect(source.projection.scenes, hasLength(1), reason: jsonEncode(source.projection.semanticEvidence['events']));
      expect((await _run(source.projection)).text, ['After']);
    }
  });

  test('STD04 opaque writers of a calculation operand block dependent conversion', () async {
    final source = await _source(const [LiteralFixtureEventCommand(122, [1, 1, 0, 1, 2])], sibling: const [
      LiteralFixtureEventCommand(355, ['unknown_effect()']),
      LiteralFixtureEventCommand(122, [2, 2, 0, 0, 42]),
    ]);
    expect(source.projection.scenes, isEmpty);
    expect(jsonEncode(source.projection.semanticEvidence['events']), contains('sourceVariableWriterUnqualified'));
  });

  test('STD04 finite control preserves reachable order in the automatic projection', () async {
    final source = await _source(const [
      LiteralFixtureEventCommand(112, []),
      LiteralFixtureEventCommand(122, [1, 1, 3, 0, 2], indent: 1),
      LiteralFixtureEventCommand(101, ['Once'], indent: 1),
      LiteralFixtureEventCommand(113, [], indent: 1),
      LiteralFixtureEventCommand(355, ['unreachable_effect()'], indent: 1),
      LiteralFixtureEventCommand(413, []),
      LiteralFixtureEventCommand(119, ['End']),
      LiteralFixtureEventCommand(355, ['unreachable_effect()']),
      LiteralFixtureEventCommand(118, ['End']),
      LiteralFixtureEventCommand(101, ['After']),
    ]);
    expect(source.projection.scenes, hasLength(1), reason: jsonEncode(source.projection.semanticEvidence['events']));
    expect((await _run(source.projection)).text, ['Once', 'After']);
  });

  test('STD04 represented input is a safe writer for later calculations', () async {
    final source = await _source(const [
      LiteralFixtureEventCommand(103, [2, 3]),
      LiteralFixtureEventCommand(122, [1, 1, 0, 1, 2]),
    ]);
    expect(source.projection.scenes, hasLength(1), reason: jsonEncode(source.projection.semanticEvidence['events']));
  });

  test('STD04 dependent writer refusal propagates through every calculation target', () async {
    final source = await _source(const [LiteralFixtureEventCommand(122, [1, 1, 0, 1, 2])], sibling: const [
      LiteralFixtureEventCommand(122, [2, 2, 0, 1, 3]),
      LiteralFixtureEventCommand(355, [r'$game_variables[3] = opaque()']),
    ]);
    expect(source.projection.scenes, isEmpty);
    expect(jsonEncode(source.projection.semanticEvidence['events']), contains('sourceVariableWriterUnqualified'));
  });

  for (final operation in [1, 2, 3, 4, 5]) {
    test('STD04 calculation $operation reads the previous target value', () async {
      final source = await _source([LiteralFixtureEventCommand(122, [1, 1, operation, 0, 2])], sibling: const [
        LiteralFixtureEventCommand(355, ['unknown_effect()']),
        LiteralFixtureEventCommand(122, [1, 1, 0, 0, 42]),
      ]);
      expect(source.projection.scenes, isEmpty);
      expect(jsonEncode(source.projection.semanticEvidence['events']), contains('sourceVariableWriterUnqualified'));
    });
  }

  test('STD04 refused balance writers block dependent game reads', () async {
    final source = await _source(const [LiteralFixtureEventCommand(122, [1, 1, 0, 7, 2])], sibling: const [
      LiteralFixtureEventCommand(355, ['unknown_effect()']),
      LiteralFixtureEventCommand(125, [0, 0, 100]),
    ]);
    expect(source.projection.scenes, isEmpty);
    expect(jsonEncode(source.projection.semanticEvidence['events']), contains('sourceMoneyWriterUnqualified'));
  });

  test('STD04 equal literal assignment preserves a numeric input outside calculation bounds', () async {
    final source = await _source(const [LiteralFixtureEventCommand(122, [1, 1, 0, 0, 123456789])]);
    final fact = source.projection.facts.single;
    final initial = NarrativeFactRuntimeWriter(NarrativeFactRuntimeResolver.fromFacts([fact])).setFactValue(
      gameState: const GameState(saveId: 'input'), factId: fact.id, value: NarrativeValue.integer(123456789)).gameState;
    final result = await _run(source.projection, initial: initial);
    expect(_value(source.projection, result.state, 1), 123456789);
  });

  test('STD04 unrepresented common balance writers also poison money predicates', () async {
    final source = await _source(const [
      LiteralFixtureEventCommand(111, [7, 100, 0]),
      LiteralFixtureEventCommand(101, ['Enough'], indent: 1),
      LiteralFixtureEventCommand(412, []),
    ], common: const {2: [LiteralFixtureEventCommand(125, [0, 0, 100])]});
    expect(source.projection.scenes, isEmpty);
    expect(jsonEncode(source.projection.semanticEvidence['events']), contains('sourceMoneyWriterUnqualified'));
  });

  test('STD04 unrepresented direct party mutations block the allowlisted count', () async {
    final source = await _source(const [LiteralFixtureEventCommand(122, [1, 1, 0, 7, 1])], sibling: const [
      LiteralFixtureEventCommand(355, [r'$player.party.clear']),
    ]);
    expect(source.projection.scenes, isEmpty);
    expect(jsonEncode(source.projection.semanticEvidence['events']), contains('sourcePartyWriterUnqualified'));
  });

  test('STD04 unrepresented common party writers block the allowlisted count', () async {
    final source = await _source(const [LiteralFixtureEventCommand(122, [1, 1, 0, 7, 1])],
      common: const {2: [LiteralFixtureEventCommand(129, [1, 0])]});
    expect(source.projection.scenes, isEmpty);
    expect(jsonEncode(source.projection.semanticEvidence['events']), contains('sourcePartyWriterUnqualified'));
  });
}
