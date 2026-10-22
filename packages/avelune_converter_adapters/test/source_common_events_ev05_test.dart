import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<({LiteralTileFixture fixture, SourceEventAnalysis analysis, SourceEventProjection projection})>
    _source(List<LiteralFixtureEventCommand> commands,
    {Map<int, List<LiteralFixtureEventCommand>> common = const {},
    Map<int, int> triggers = const {}, bool helperPin = false,
    bool readVariableOne = false,
    List<String?> switchNames = const [null, 'Original door opened', 'Original reward consumed'],
    List<LiteralFixtureEventCommand>? sibling}) async {
  final profile = helperPin ? SourceInterpretationProfile.fromJson({
    ...syntheticSourceInterpretationProfile.toJson(),
    'sections': {...syntheticSourceInterpretationProfile.sections,
      'events.Utilities': syntheticSourceInterpretationProfile.sections['events.Interpreter']},
  }) : syntheticSourceInterpretationProfile;
  final fixture = await LiteralTileFixture.create(
    interpretationProfile: profile, scriptsBytes: syntheticInterpretationArchive,
    includeEventSystem: true, commonEvents: common, commonEventTriggers: triggers,
    switchNames: switchNames,
    maps: [LiteralFixtureMap(id: 1, events: [
      LiteralFixtureEvent(id: 1, x: 1, y: 0, pages: [LiteralFixtureEventPage(commands: [
        ...commands,
        if (readVariableOne) ...const [
          LiteralFixtureEventCommand(111, [1, 1, 0, 9, 0]),
          LiteralFixtureEventCommand(101, ['Variable consumed'], indent: 1),
          LiteralFixtureEventCommand(412, []),
        ],
      ])]),
      if (sibling != null) LiteralFixtureEvent(id: 2, x: 2, y: 0,
        pages: [LiteralFixtureEventPage(commands: sibling)]),
    ])]);
  final analysis = SourceEventAnalyzer.forProject(fixture.source,
      profile: SourceEventProfile.forProject(fixture.source)).analyze();
  final projection = const SourceEventProjector().project(source: fixture.source,
    analysis: analysis, nativeMaps: {1: MapData(id: 'map', name: 'Map',
      size: const GridSize(width: 3, height: 1), layers: [])});
  return (fixture: fixture, analysis: analysis, projection: projection);
}

Future<({GameState state, List<String> shown})> _run(SourceEventProjection projection,
    {String choice = 'choice_0'}) async {
  var state = const GameState(saveId: 'ev05');
  final resolver = NarrativeFactRuntimeResolver.fromFacts(projection.facts);
  final writer = NarrativeFactRuntimeWriter(resolver);
  final shown = <String>[];
  final plan = buildSceneRuntimePlan(SceneAsset.fromJson(jsonDecode(
      jsonEncode(projection.scenes.single.toJson())) as Map<String, dynamic>));
  expect(plan.plan, isNotNull);
  final execution = await SceneRuntimeExecutor(callbacks: SceneRuntimeExecutionCallbacks(
    evaluateCondition: (intent) {
      final source = intent.conditionSource!;
      final resolved = resolver.resolve(factId: source.sourceId,
        runtimeState: state.narrativeFactRuntimeState, storyFlags: state.storyFlags)
        as NarrativeFactRuntimeResolved;
      return resolved.narrativeValue.matches(source.resolvedFactOperator,
        source.resolvedExpectedFactValue) ? 'true' : 'false';
    },
    showDialogue: (intent) {
      final document = const YarnDialogueCompiler().compile(projection.dialogueSources[intent.dialogueId]!);
      shown.addAll(document.nodes.single.steps.whereType<RuntimeDialogueLine>().map((line) => line.text));
      return intent.declaredOutputPortIds.contains(choice) ? choice : 'completed';
    },
    applyConsequence: (consequence) {
      final set = consequence as SceneSetFactConsequence;
      final written = writer.setFactValue(gameState: state, factId: set.factId, value: set.narrativeValue);
      expect(written.success, isTrue);
      state = written.gameState;
      return 'completed';
    },
    startBattle: (_) => throw StateError('No battle'),
    playCinematic: (_) => throw StateError('No cinematic'),
    executeInteractiveCommand: (_) => throw StateError('No interactive command'),
  )).execute(plan.plan!);
  expect(execution.status, SceneRuntimeExecutionStatus.completed);
  return (state: GameState.fromJson(jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>), shown: shown);
}

void main() {
  test('EV05 common exit returns to caller, nested calls preserve owner and locators', () async {
    final source = await _source(const [
      LiteralFixtureEventCommand(101, ['Before']), LiteralFixtureEventCommand(117, [1]),
      LiteralFixtureEventCommand(101, ['After'])], common: const {
      1: [LiteralFixtureEventCommand(101, ['Common']), LiteralFixtureEventCommand(117, [2]),
        LiteralFixtureEventCommand(115, []), LiteralFixtureEventCommand(101, ['Unreachable'])],
      2: [LiteralFixtureEventCommand(123, ['A', 0]), LiteralFixtureEventCommand(101, ['Nested'])],
    });
    expect(source.analysis.events.single.isQuarantined, isFalse);
    final call = source.analysis.events.single.pages.single.body.nodes[1] as SourceCommonEventCallNode;
    expect((call.sourceMapId, call.sourceEventId), (1, 1));
    expect(call.body.span.locator.file, 'Data/CommonEvents.rxdata');
    expect(call.body.span.locator.eventId, isNull);
    expect(call.body.span.locator.mapId, isNull);
    final nested = call.body.nodes[1] as SourceCommonEventCallNode;
    final self = nested.body.nodes.first as SourceSelfSwitchNode;
    expect(self.factId, endsWith(':map:1:event:1:self:A'));
    expect(source.projection.scenes, hasLength(1), reason: jsonEncode(source.projection.semanticEvidence));
    expect((await _run(source.projection)).shown, ['Before', 'Common', 'Nested', 'After']);
  });

  test('EV05 repeated common calls keep distinct native dialogue identities', () async {
    final source = await _source(const [LiteralFixtureEventCommand(117, [1]),
      LiteralFixtureEventCommand(117, [1])], common: const {
      1: [LiteralFixtureEventCommand(101, ['Repeated'])]});
    expect(source.projection.dialogueSources, hasLength(2));
    expect(source.projection.dialogues.map((dialogue) => dialogue.id).toSet(), hasLength(2));
    expect((await _run(source.projection)).shown, ['Repeated', 'Repeated']);
  });

  test('EV05 child return resumes its parent and caller in the native executor', () async {
    final source = await _source(const [LiteralFixtureEventCommand(117, [2]),
      LiteralFixtureEventCommand(101, ['Caller resumed'])], common: const {
      2: [LiteralFixtureEventCommand(101, ['Parent']), LiteralFixtureEventCommand(117, [7]),
        LiteralFixtureEventCommand(101, ['Parent resumed'])],
      7: [LiteralFixtureEventCommand(101, ['Child']), LiteralFixtureEventCommand(115, []),
        LiteralFixtureEventCommand(101, ['Never'])]});
    final call = source.analysis.events.single.pages.single.body.nodes.first as SourceCommonEventCallNode;
    expect(call.commonEventId, 2);
    expect(call.sourceEventId, 1);
    expect(call.body.span.locator.eventId, isNull);
    expect((await _run(source.projection)).shown, ['Parent', 'Child', 'Parent resumed', 'Caller resumed']);
  });

  test('EV05 repeated choices and conditional exits preserve every local return', () async {
    final source = await _source(const [LiteralFixtureEventCommand(117, [1]),
      LiteralFixtureEventCommand(117, [1]), LiteralFixtureEventCommand(101, ['Caller'])],
      common: const {1: [LiteralFixtureEventCommand(102, [['Return', 'Continue'], 0]),
        LiteralFixtureEventCommand(402, [0, 'Return']),
        LiteralFixtureEventCommand(115, [], indent: 1),
        LiteralFixtureEventCommand(402, [1, 'Continue']),
        LiteralFixtureEventCommand(101, ['Continued'], indent: 1),
        LiteralFixtureEventCommand(404, []), LiteralFixtureEventCommand(101, ['Tail'])]});
    expect(source.projection.dialogues.map((entry) => entry.id).toSet(), hasLength(source.projection.dialogues.length));
    expect((await _run(source.projection)).shown, ['Caller']);
    expect((await _run(source.projection, choice: 'choice_1')).shown,
      ['Continued', 'Tail', 'Continued', 'Tail', 'Caller']);
  });

  test('EV05 common calls with transfers keep the whole event quarantined', () async {
    final source = await _source(const [LiteralFixtureEventCommand(201, [0, 1, 0, 0, 0, 0]),
      LiteralFixtureEventCommand(117, [1])], common: const {1: [LiteralFixtureEventCommand(123, ['A', 0])]});
    expect(source.projection.scenes, isEmpty);
    expect(jsonEncode(source.projection.semanticEvidence), contains('sourceCommonEventMapContextUnsupported'));
  });

  test('EV05 common gift stays unsupported without a page-bound original contract', () async {
    final source = await _source(const [LiteralFixtureEventCommand(117, [1])],
      common: const {1: [LiteralFixtureEventCommand(355, ['pbAddPokemon(:PIKACHU, 5)'])]});
    expect(source.projection.scenes, isEmpty);
  });

  for (final tamper in ['id', 'body', 'owner', 'span']) {
    test('EV05 forged text-only common $tamper cannot bypass source reanalysis', () async {
      final source = await _source(const [LiteralFixtureEventCommand(117, [2])],
        common: const {2: [LiteralFixtureEventCommand(101, ['Original'])]});
      final event = source.analysis.events.single;
      final page = event.pages.single;
      final call = page.body.nodes.single as SourceCommonEventCallNode;
      final changed = SourceCommonEventCallNode(tamper == 'span' ? call.body.span : call.span,
        commonEventId: tamper == 'id' ? 9 : call.commonEventId,
        sourceMapId: call.sourceMapId, sourceEventId: tamper == 'owner' ? 7 : call.sourceEventId,
        body: tamper == 'body' ? SourceEventBlock(nodes: [SourceTextNode(call.body.span, 'Forged')],
          span: call.body.span) : call.body);
      final analysis = SourceEventAnalysis(profile: source.analysis.profile, diagnostics: [], events: [
        SourceEventDefinition(sourceMapId: event.sourceMapId, sourceEventId: event.sourceEventId,
          sourceFileId: event.sourceFileId, identity: event.identity, name: event.name,
          x: event.x, y: event.y, locator: event.locator, pages: [
            SourceEventPageAnalysis(sourcePage: page.sourcePage, locator: page.locator,
              condition: page.condition, graphic: page.graphic, rawDataRef: page.rawDataRef,
              body: SourceEventBlock(nodes: [changed], span: page.body.span), diagnostics: [])])]);
      final projection = const SourceEventProjector().project(source: source.fixture.source,
        analysis: analysis, nativeMaps: {1: MapData(id: 'map', name: 'Map',
          size: const GridSize(width: 3, height: 1), layers: [])});
      expect(projection.scenes, isEmpty);
      expect(jsonEncode(projection.semanticEvidence), contains('sourceNumericControlSourceMismatch'));
    });
  }

  for (final tamper in ['switchValue', 'switchFactIds', 'switchRange', 'waitDuration', 'waitProfile']) {
    test('EV05 common semantic fingerprint rejects $tamper at the original span', () async {
      final wait = tamper.startsWith('wait');
      final source = await _source(const [LiteralFixtureEventCommand(117, [2])],
        common: {2: [wait ? const LiteralFixtureEventCommand(106, [1])
          : const LiteralFixtureEventCommand(121, [1, 1, 0])]});
      if (!wait) expect(source.projection.scenes, hasLength(1));
      final event = source.analysis.events.single;
      final page = event.pages.single;
      final call = page.body.nodes.single as SourceCommonEventCallNode;
      final original = call.body.nodes.single;
      final SourceEventNode changed;
      if (original is SourceSwitchNode) {
        changed = SourceSwitchNode(original.span,
          firstId: original.firstId, lastId: tamper == 'switchRange' ? 2 : original.lastId,
          value: tamper == 'switchValue' ? !original.value : original.value,
          factIds: tamper == 'switchFactIds' ? ['source:forged:switch:1'] : original.factIds);
      } else {
        final node = original as SourceWaitNode;
        changed = SourceWaitNode(node.span,
          durationTicks: tamper == 'waitDuration' ? 2 : node.durationTicks,
          profileHash: tamper == 'waitProfile' ? canonicalHashOf('forged') : node.profileHash);
      }
      final forged = SourceCommonEventCallNode(call.span, commonEventId: call.commonEventId,
        sourceMapId: call.sourceMapId, sourceEventId: call.sourceEventId,
        body: SourceEventBlock(nodes: [changed], span: call.body.span));
      final analysis = SourceEventAnalysis(profile: source.analysis.profile, diagnostics: [], events: [
        SourceEventDefinition(sourceMapId: event.sourceMapId, sourceEventId: event.sourceEventId,
          sourceFileId: event.sourceFileId, identity: event.identity, name: event.name,
          x: event.x, y: event.y, locator: event.locator, pages: [
            SourceEventPageAnalysis(sourcePage: page.sourcePage, locator: page.locator,
              condition: page.condition, graphic: page.graphic, rawDataRef: page.rawDataRef,
              body: SourceEventBlock(nodes: [forged], span: page.body.span), diagnostics: [])])]);
      final projection = const SourceEventProjector().project(source: source.fixture.source,
        analysis: analysis, nativeMaps: {1: MapData(id: 'map', name: 'Map',
          size: const GridSize(width: 3, height: 1), layers: [])});
      expect(projection.scenes, isEmpty);
      expect(jsonEncode(projection.semanticEvidence), contains('sourceNumericControlSourceMismatch'));
    });
  }

  for (final example in <String, Map<int, List<LiteralFixtureEventCommand>>>{
    'missing': {}, 'recursive': {1: [const LiteralFixtureEventCommand(117, [1])]},
    'mutually recursive': {1: [const LiteralFixtureEventCommand(117, [2])],
      2: [const LiteralFixtureEventCommand(117, [1])]},
    'opaque': {1: [const LiteralFixtureEventCommand(101, ['Safe prefix']),
      const LiteralFixtureEventCommand(355, ['unknown_plugin()'])]},
    'label': {1: [const LiteralFixtureEventCommand(118, ['label'])]},
  }.entries) {
    test('EV05 ${example.key} common call quarantines caller atomically', () async {
      final source = await _source(const [LiteralFixtureEventCommand(101, ['Before']),
        LiteralFixtureEventCommand(117, [1])], common: example.value);
      expect(source.analysis.events.single.isQuarantined, isTrue);
      expect(source.projection.scenes, isEmpty);
      expect(source.projection.dialogues, isEmpty);
    });
  }

  for (final trigger in [1, 2]) {
    test('EV05 automatic common trigger $trigger remains refused', () async {
      final source = await _source(const [LiteralFixtureEventCommand(117, [1])],
        common: const {1: [LiteralFixtureEventCommand(101, ['Automatic'])]}, triggers: {1: trigger});
      expect(source.analysis.events.single.isQuarantined, isTrue);
      expect(source.projection.scenes, isEmpty);
    });
  }

  test('EV05 qualified common integer writer uses native facts', () async {
    final source = await _source(const [LiteralFixtureEventCommand(117, [1])],
      common: const {1: [LiteralFixtureEventCommand(122, [1, 1, 0, 0, 9]) ]});
    expect(source.projection.scenes, hasLength(1), reason: jsonEncode(source.projection.semanticEvidence));
    expect(source.projection.facts.single.initialValue, NarrativeValue.integer(0));
    final executed = await _run(source.projection);
    final value = NarrativeFactRuntimeResolver.fromFacts(source.projection.facts).resolve(
      factId: source.projection.facts.single.id, runtimeState: executed.state.narrativeFactRuntimeState,
      storyFlags: executed.state.storyFlags) as NarrativeFactRuntimeResolved;
    expect(value.narrativeValue, NarrativeValue.integer(9));
  });

  test('EV05 opaque sibling common writer keeps variable consumers refused', () async {
    final source = await _source(const [LiteralFixtureEventCommand(117, [1])],
      readVariableOne: true, common: const {1: [LiteralFixtureEventCommand(122, [1, 1, 0, 0, 9])],
        2: [LiteralFixtureEventCommand(355, [r'pbSet(1, "string")'])]});
    expect(source.projection.scenes, isEmpty);
    expect(jsonEncode(source.projection.semanticEvidence), contains('sourceVariableWriterUnqualified'));
  });

  for (final script in ['pbCommonEvent(1)', 'self.pbCommonEvent(1)',
    r'$game_temp.common_event_id = 1', 'pbCommonEvent(variable)',
    r'$game_temp.common_event_id = selected']) {
    test('EV05 opaque common invocation revokes represented writers: $script', () async {
      final source = await _source(const [LiteralFixtureEventCommand(117, [1])],
        readVariableOne: true, common: const {1: [LiteralFixtureEventCommand(122, [1, 1, 0, 0, 9])]},
        sibling: [LiteralFixtureEventCommand(355, [script])]);
      expect(source.projection.scenes, isEmpty);
      expect(jsonEncode(source.projection.semanticEvidence), contains('sourceVariableWriterUnqualified'));
    });
  }

  for (final origin in ['switch', 'common', 'condition', 'route']) {
    test('EV05 opaque $origin common invocation enters the writer census', () async {
      final source = await _source(const [LiteralFixtureEventCommand(117, [1])],
        switchNames: [null, origin == 'switch' ? 's:pbCommonEvent(1)' : 'Ordinary'],
        readVariableOne: true, common: {1: const [LiteralFixtureEventCommand(122, [1, 1, 0, 0, 9])],
          if (origin == 'common') 2: const [LiteralFixtureEventCommand(355, ['pbCommonEvent(1)'])]},
        sibling: switch (origin) {
          'condition' => const [LiteralFixtureEventCommand(111, [12, 'pbCommonEvent(1)']),
            LiteralFixtureEventCommand(412, [])],
          'route' => const [LiteralFixtureEventCommand(209, [0, LiteralFixtureObject('RPG::MoveRoute', {
            '@repeat': false, '@skippable': false, '@list': [
              LiteralFixtureObject('RPG::MoveCommand', {'@code': 45, '@parameters': ['pbCommonEvent(1)']}),
              LiteralFixtureObject('RPG::MoveCommand', {'@code': 0, '@parameters': []})]})])],
          _ => null,
        });
      expect(source.projection.scenes, isEmpty);
      expect(jsonEncode(source.projection.semanticEvidence), contains('sourceVariableWriterUnqualified'));
    });
  }

  test('EV05 literal opaque invocation of another common leaves unrelated variable native', () async {
    final source = await _source(const [LiteralFixtureEventCommand(117, [1])],
      common: const {1: [LiteralFixtureEventCommand(122, [1, 1, 0, 0, 9])],
        2: [LiteralFixtureEventCommand(101, ['Other common'])]},
      sibling: const [LiteralFixtureEventCommand(355, ['pbCommonEvent(2)'])]);
    expect(source.projection.scenes, hasLength(1));
    final executed = await _run(source.projection);
    final value = NarrativeFactRuntimeResolver.fromFacts(source.projection.facts).resolve(
      factId: source.projection.facts.single.id, runtimeState: executed.state.narrativeFactRuntimeState,
      storyFlags: executed.state.storyFlags) as NarrativeFactRuntimeResolved;
    expect(value.narrativeValue, NarrativeValue.integer(9));
  });

  test('EV05 opaque invocation revocation closes transitive represented callees', () async {
    final source = await _source(const [LiteralFixtureEventCommand(117, [1]),
      LiteralFixtureEventCommand(117, [3])], readVariableOne: true, common: const {
      1: [LiteralFixtureEventCommand(122, [1, 1, 0, 0, 9])],
      2: [LiteralFixtureEventCommand(355, ['pbCommonEvent(3)'])],
      3: [LiteralFixtureEventCommand(117, [1])],
    });
    expect(source.projection.scenes, isEmpty);
    expect(jsonEncode(source.projection.semanticEvidence), contains('sourceVariableWriterUnqualified'));
  });

  for (final helper in ['pbReceiveItem(:POTION)', 'pbAddPokemon(:PIKACHU, 5)']) {
    test('EV05 common page-bound helper has explicit atomic AST refusal: $helper', () async {
      final source = await _source(const [LiteralFixtureEventCommand(117, [1]),
        LiteralFixtureEventCommand(117, [2])], common: {
        1: [LiteralFixtureEventCommand(355, [helper])],
        2: const [LiteralFixtureEventCommand(355, ['pbReceiveItem(:ANTIDOTE)'])]});
      expect(source.analysis.events.single.isQuarantined, isTrue);
      expect(source.analysis.events.single.pages.single.body.nodes.whereType<SourceCommonEventCallNode>(), isEmpty);
      expect(source.analysis.diagnostics.map((entry) => entry.code),
        contains('events.common_event_page_bound_program_unsupported'));
      expect(source.projection.scenes, isEmpty);
    });
  }

  test('EV05 opaque transitive caller cannot certify a shared common writer', () async {
    final source = await _source(const [LiteralFixtureEventCommand(117, [1])], readVariableOne: true, common: const {
      1: [LiteralFixtureEventCommand(122, [1, 1, 0, 0, 9])],
      2: [LiteralFixtureEventCommand(117, [1])],
      3: [LiteralFixtureEventCommand(355, ['unknown_plugin()']), LiteralFixtureEventCommand(117, [2])],
    });
    expect(source.projection.scenes, isEmpty);
    expect(jsonEncode(source.projection.semanticEvidence), contains('sourceVariableWriterUnqualified'));
  });

  test('EV05 refused map caller cannot certify a shared common writer', () async {
    final source = await _source(const [LiteralFixtureEventCommand(117, [1])],
      readVariableOne: true, common: const {1: [LiteralFixtureEventCommand(122, [1, 1, 0, 0, 9])]},
      sibling: const [LiteralFixtureEventCommand(117, [1]), LiteralFixtureEventCommand(355, ['unknown_plugin()'])]);
    expect(source.projection.scenes, isEmpty);
    expect(jsonEncode(source.projection.semanticEvidence), contains('sourceVariableWriterUnqualified'));
  });

  test('EV05 pbSet and pbGet literals require Utilities witness and compile native facts', () async {
    const commands = [LiteralFixtureEventCommand(355, ['pbSet(1, 7)']),
      LiteralFixtureEventCommand(111, [12, 'pbGet(1) >= 7']),
      LiteralFixtureEventCommand(101, ['Yes'], indent: 1), LiteralFixtureEventCommand(412, [])];
    final absent = await _source(commands);
    expect(absent.projection.scenes, isEmpty);
    final admitted = await _source(commands, helperPin: true);
    expect(admitted.projection.scenes, hasLength(1), reason: jsonEncode(admitted.projection.semanticEvidence));
    expect(admitted.projection.facts, hasLength(1));
    expect((await _run(admitted.projection)).shown, ['Yes']);
  });

  for (final script in ['pbSet(1, 100000000)', 'pbSet(1, -100000000)',
    'pbSet(1, "7")', 'pbSet(1, :ABRA)', 'pbSet(variable, 7)',
    'pbSet(1, 7)\nunknown_plugin()', 'pbCommonEvent(1)']) {
    test('EV05 unsupported helper is refused: $script', () async {
      final source = await _source([LiteralFixtureEventCommand(355, [script])], helperPin: true);
      expect(source.projection.scenes, isEmpty);
    });
  }

  test('EV05 common depth and expansion budgets refuse boundedly', () async {
    final deep = await _source(const [LiteralFixtureEventCommand(117, [1])],
      common: {for (var id = 1; id <= 18; id++) id: [LiteralFixtureEventCommand(117, [id + 1])]});
    expect(deep.projection.scenes, isEmpty);
    expect(deep.analysis.diagnostics.map((diagnostic) => diagnostic.code),
      contains('events.common_event_depth_exceeded'));
    final wide = await _source(const [LiteralFixtureEventCommand(117, [1])], common: {
      for (var id = 1; id < 15; id++) id: [LiteralFixtureEventCommand(117, [id + 1]),
        LiteralFixtureEventCommand(117, [id + 1])],
      15: [const LiteralFixtureEventCommand(101, ['Leaf'])]});
    expect(wide.projection.scenes, isEmpty);
    expect(wide.analysis.diagnostics.map((diagnostic) => diagnostic.code),
      contains('events.common_event_command_budget_exceeded'));
  });
}
