import 'dart:convert';

import 'package:avelune_converter_adapters/src/source_interaction_program.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

LiteralFixtureObject _step(int code) => LiteralFixtureObject(
    'RPG::MoveCommand', {'@code': code, '@parameters': <Object?>[]});

Future<({LiteralTileFixture fixture, SourceEventAnalysis analysis})> _source({
  int mapId = 17,
  int ownerId = 41,
  int actorId = 73,
  String name = 'Source terminal',
  String? variant,
}) async {
  final move = _step(variant == 'outOfBounds' ? 4 : 2);
  final route = LiteralFixtureObject('RPG::MoveRoute', {
    '@repeat': variant == 'repeat',
    '@skippable': variant != 'nonSkippable',
    '@list': [move, _step(0)],
  });
  final commands = <LiteralFixtureEventCommand>[
    const LiteralFixtureEventCommand(111, [6, -1, 8]),
    const LiteralFixtureEventCommand(101, ['Choose a result.'], indent: 1),
    const LiteralFixtureEventCommand(102, [['Wrong', 'Correct'], 0], indent: 1),
    const LiteralFixtureEventCommand(402, [0, 'Wrong'], indent: 1),
    if (variant == 'bareBarrierBeforeText') ...[
      const LiteralFixtureEventCommand(210, [], indent: 2),
      const LiteralFixtureEventCommand(101, ['Unowned route barrier'], indent: 2),
    ],
    LiteralFixtureEventCommand(209, [variant == 'unboundActor' ? 99 : actorId, route],
        indent: 2),
    LiteralFixtureEventCommand(509, [move], indent: 2),
    if (variant == 'afterRouteEffect')
      const LiteralFixtureEventCommand(123, ['B', 0], indent: 2),
    if (variant == 'immediateBarrier')
      const LiteralFixtureEventCommand(210, [], indent: 2),
    const LiteralFixtureEventCommand(0, [], indent: 2),
    const LiteralFixtureEventCommand(402, [1, 'Correct'], indent: 1),
    if (variant == 'bareBarrierOtherBranch')
      const LiteralFixtureEventCommand(210, [], indent: 2),
    const LiteralFixtureEventCommand(249, [
      LiteralFixtureObject('RPG::AudioFile',
          {'@name': 'Reward', '@volume': 100, '@pitch': 100})
    ], indent: 2),
    const LiteralFixtureEventCommand(106, [20], indent: 2),
    if (variant == 'unknownScript')
      const LiteralFixtureEventCommand(355, ['unrelated_side_effect()'], indent: 2),
    const LiteralFixtureEventCommand(123, ['A', 0], indent: 2),
    const LiteralFixtureEventCommand(0, [], indent: 2),
    const LiteralFixtureEventCommand(404, [], indent: 1),
    const LiteralFixtureEventCommand(0, [], indent: 1),
    const LiteralFixtureEventCommand(412, []),
    if (variant == 'afterChoiceEffect')
      const LiteralFixtureEventCommand(123, ['B', 0]),
    const LiteralFixtureEventCommand(0, []),
  ];
  final fixture = await LiteralTileFixture.create(
      interpretationProfile: syntheticSourceInterpretationProfile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      extraFiles: {'Graphics/Characters/Wall.png': literalFixtureAtlas()},
      maps: [
        LiteralFixtureMap(id: mapId, events: [
          LiteralFixtureEvent(id: ownerId, x: 0, y: 0, name: name, pages: [
            LiteralFixtureEventPage(
                commands: commands, trigger: variant == 'autorun' ? 3 : 0),
            const LiteralFixtureEventPage(commands: [], selfSwitch: 'A'),
          ]),
          LiteralFixtureEvent(id: actorId, x: 2, y: 0, pages: [
            LiteralFixtureEventPage(commands: const [], characterName: 'Wall',
                moveType: variant == 'autonomy' ? 1 : 0),
          ]),
        ]),
      ]);
  return (fixture: fixture,
      analysis: SourceEventAnalyzer.forProject(fixture.source,
          profile: SourceEventProfile.forProject(fixture.source)).analyze());
}

Iterable<SourceEventNode> _nodes(SourceEventBlock block) sync* {
  for (final node in block.nodes) {
    yield node;
    if (node is SourceConditionalNode) {
      yield* _nodes(node.whenTrue);
      yield* _nodes(node.whenFalse);
    }
    final choice = node is SourceChoiceNode ? node :
        node is SourceTextNode ? node.followingChoice : null;
    if (choice != null) {
      for (final branch in choice.branches) { yield* _nodes(branch.body); }
      if (choice.cancelBranch != null) yield* _nodes(choice.cancelBranch!);
    }
  }
}

void main() {
  for (final ids in [(17, 41, 73), (209, 8, 21)]) {
    test('qualifies closed choice with unrelated identifiers $ids', () async {
      final input = await _source(mapId: ids.$1, ownerId: ids.$2,
          actorId: ids.$3, name: 'Unrelated interaction ${ids.$1}');
      final source = input.fixture.source;
      final event = input.analysis.eventAt(ids.$1, ids.$2)!;
      expect(event.isQuarantined, isFalse, reason: jsonEncode([
        for (final diagnostic in input.analysis.diagnostics) diagnostic.toJson()
      ]));
      final program = sourceInteractionPrograms(source: source,
          analysis: input.analysis)[event.identity]!;
      expect(program.actorEventIds, {ids.$3});
      expect(program.isBoundTo(source: source, analysis: input.analysis,
          event: event), isTrue);
      final nodes = _nodes(event.pages.first.body).toList();
      final route = nodes.whereType<SourceForcedMoveRouteNode>().single;
      expect(program.permitsRoute(route), isTrue);
      expect(program.permitsNode(route), isTrue);
      expect(program.toJson()['sourceTemporalParity'], isFalse);
      expect(program.toJson()['nativeRouteCompletion'], 'awaited');
      expect(program.toJson()['sourceScriptsExecuted'], 0);
      expect(() => program.actorEventIds.add(999), throwsUnsupportedError);
    });
  }

  test('qualifies an immediate route barrier without claiming asynchronous parity', () async {
    final input = await _source(variant: 'immediateBarrier');
    final owner = input.analysis.eventAt(17, 41)!;
    final program = sourceInteractionPrograms(source: input.fixture.source,
        analysis: input.analysis)[owner.identity]!;
    expect(program.permitsNode(_nodes(owner.pages.first.body)
        .whereType<SourceMoveRouteBarrierNode>().single), isTrue);
  });

  for (final variant in ['bareBarrierBeforeText', 'bareBarrierOtherBranch']) {
    test('keeps a real map route barrier pending native context for $variant', () async {
      final input = await _source(variant: variant);
      final owner = input.analysis.eventAt(17, 41)!;
      final program = sourceInteractionPrograms(source: input.fixture.source,
          analysis: input.analysis)[owner.identity]!;
      expect(program.permitsNode(_nodes(owner.pages.first.body)
          .whereType<SourceMoveRouteBarrierNode>().single), isTrue);
      expect(program.toJson()['routeBarrier'],
          'nativeWaitForActorRoutesWithQualifiedMapContext');
      expect(program.toJson()['nativeExecutionQualified'], isFalse);
    });
  }

  for (final variant in ['repeat', 'nonSkippable', 'unboundActor',
    'outOfBounds', 'autonomy', 'autorun', 'unknownScript', 'afterRouteEffect',
    'afterChoiceEffect']) {
    test('refuses incomplete or unsupported interaction $variant', () async {
      final input = await _source(variant: variant);
      final owner = input.analysis.eventAt(17, 41)!;
      expect(sourceInteractionPrograms(source: input.fixture.source,
          analysis: input.analysis).containsKey(owner.identity), isFalse);
    });
  }

  test('rejects source-bound program reused with modified event identity or body', () async {
    final input = await _source();
    final source = input.fixture.source;
    final event = input.analysis.eventAt(17, 41)!;
    final program = sourceInteractionPrograms(source: source,
        analysis: input.analysis)[event.identity]!;
    final forged = SourceEventDefinition(sourceMapId: event.sourceMapId,
        sourceEventId: event.sourceEventId, sourceFileId: event.sourceFileId,
        identity: event.identity, name: 'Changed', x: event.x, y: event.y,
        locator: event.locator, pages: event.pages);
    expect(program.isBoundTo(source: source, analysis: input.analysis,
        event: forged), isFalse);
    final first = event.pages.first;
    final changedPage = SourceEventPageAnalysis(sourcePage: first.sourcePage,
        locator: first.locator, condition: first.condition, graphic: first.graphic,
        body: SourceEventBlock(span: first.body.span,
            nodes: [SourceAnnotationNode(first.body.span, ['Changed body'])]),
        rawDataRef: first.rawDataRef, diagnostics: first.diagnostics);
    final changedBody = SourceEventDefinition(sourceMapId: event.sourceMapId,
        sourceEventId: event.sourceEventId, sourceFileId: event.sourceFileId,
        identity: event.identity, name: event.name, x: event.x, y: event.y,
        locator: event.locator, pages: [changedPage, ...event.pages.skip(1)]);
    expect(program.isBoundTo(source: source, analysis: input.analysis,
        event: changedBody), isFalse);
    final other = await _source(mapId: 209);
    expect(program.isBoundTo(source: other.fixture.source,
        analysis: other.analysis, event: other.analysis.eventAt(209, 41)!), isFalse);
  });

  test('refuses a forged actor context and an unbound route', () async {
    final input = await _source();
    final source = input.fixture.source;
    final owner = input.analysis.eventAt(17, 41)!;
    final actor = input.analysis.eventAt(17, 73)!;
    final program = sourceInteractionPrograms(source: source,
        analysis: input.analysis)[owner.identity]!;
    final changedActor = SourceEventDefinition(sourceMapId: actor.sourceMapId,
        sourceEventId: actor.sourceEventId, sourceFileId: actor.sourceFileId,
        identity: actor.identity, name: 'Changed actor', x: actor.x, y: actor.y,
        locator: actor.locator, pages: actor.pages);
    final changedAnalysis = SourceEventAnalysis(profile: input.analysis.profile,
        events: [owner, changedActor], diagnostics: input.analysis.diagnostics);
    expect(program.isBoundTo(source: source, analysis: changedAnalysis,
        event: owner), isFalse);
    final route = _nodes(owner.pages.first.body)
        .whereType<SourceForcedMoveRouteNode>().single;
    final changedRoute = SourceForcedMoveRouteNode(route.span,
        targetSourceCharacterId: 999, repeat: route.repeat,
        skippable: route.skippable, steps: route.steps,
        rawDataRefs: route.rawDataRefs, terminatorNodeId: route.terminatorNodeId,
        profileHash: route.profileHash);
    expect(program.permitsNode(changedRoute), isFalse);
    expect(program.permitsRoute(changedRoute), isFalse);
  });
}
