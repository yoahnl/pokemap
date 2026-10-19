import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

Future<NormalizedSourceProject> _source({
  Set<int> blockedCells = const {5, 6},
  String eventName = 'Bookshelf size(2,1)',
  int x = 1,
  bool through = false,
  int trigger = 0,
  List<LiteralFixtureEvent> extraEvents = const [],
}) async {
  final fixture = await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,

      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      maps: [
        LiteralFixtureMap(id: 1, width: 4, height: 3, layers: [
          List.filled(12, 384),
          List.filled(12, 0),
          List.generate(12, (index) => blockedCells.contains(index) ? 400 : 0),
        ], events: [
          LiteralFixtureEvent(id: 1, x: x, y: 1, name: eventName, pages: [
            LiteralFixtureEventPage(through: through, trigger: trigger, commands: const [
              LiteralFixtureEventCommand(101, ['Books.']),
              LiteralFixtureEventCommand(0, []),
            ]),
          ]),
          ...extraEvents,
        ]),
      ],
      tilesets: [LiteralFixtureTileset(id: 1, passages: const {400: 15})]);
  return fixture.source;
}

SourceEventAnalysis _analysis(NormalizedSourceProject source) =>
    SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
        .analyze();

SourceEventTouchResolution _resolve(NormalizedSourceProject source,
    {int width = 2, int height = 1,
    SourceSemanticContext context = const SourceSemanticContext()}) {
  final analysis = _analysis(source);
  final event = analysis.eventAt(1, 1)!;
  return SourceSemanticResolver.forProject(source).resolveStaticActionFootprint(
      event: event, page: event.pages.single, mapEvents: analysis.events,
      width: width, height: height, context: context);
}

void main() {
  for (final trigger in [0, 1, 2, 3, 4]) {
    test('static bump footprint accepts only player-touch trigger $trigger', () async {
      final source = await _source(trigger: trigger);
      final analysis = _analysis(source);
      final event = analysis.eventAt(1, 1)!;
      final resolver = SourceSemanticResolver.forProject(source);
      final result = resolver.resolveStaticBumpFootprint(event: event,
        page: event.pages.single, mapEvents: analysis.events, width: 2, height: 1);
      expect(result.kind, trigger == 1 ? SourceEventTouchKind.front : SourceEventTouchKind.unqualified);
      if (trigger == 1) expect(_resolve(source).kind, SourceEventTouchKind.unqualified);
    });
  }

  test('static action footprint proves both cells with the sealed source', () async {
    final result = _resolve(await _source());
    expect(result.kind, SourceEventTouchKind.front);
    expect(result.reason, 'stationaryFootprintTilesBlocked');
    expect(result.trace.where((step) =>
        step.reason == SourcePassageReason.allDirectionsBlocked), hasLength(2));
  });

  for (final blocked in [<int>{5}, <int>{6}, <int>{}]) {
    test('static action footprint refuses a passable occupied cell $blocked', () async {
      expect(_resolve(await _source(blockedCells: blocked)).kind,
          SourceEventTouchKind.unqualified);
    });
  }

  for (final dimensions in [(0, 1), (1, 1), (3, 1), (2, 0), (2, 2)]) {
    test('static action footprint rejects unsupported or mismatched $dimensions',
        () async {
      expect(_resolve(await _source(), width: dimensions.$1,
          height: dimensions.$2).kind, SourceEventTouchKind.unqualified);
    });
  }

  for (final name in ['Bookshelf size(0,1)', 'Bookshelf size(2,0)',
    'Bookshelf size(2,1) size(2,1)', 'Bookshelf size(99999999999999999999,1)']) {
    test('static action footprint refuses invalid source directive $name', () async {
      expect(_resolve(await _source(eventName: name)).kind,
          SourceEventTouchKind.unqualified);
    });
  }

  test('static action footprint refuses out of bounds and through pages', () async {
    expect(_resolve(await _source(x: 3)).kind, SourceEventTouchKind.unqualified);
    expect(_resolve(await _source(through: true)).kind,
        SourceEventTouchKind.unqualified);
  });

  test('static action footprint refuses an overlapping event from either side',
      () async {
    for (final x in [0, 1, 2]) {
      final source = await _source(extraEvents: [
        LiteralFixtureEvent(id: 2, x: x, y: 1, name: 'Other size(2,1)',
            pages: const [LiteralFixtureEventPage(commands: [])]),
      ]);
      expect(_resolve(source).kind, SourceEventTouchKind.unqualified,
          reason: 'Overlapping event starts at $x');
    }
  });

  test('static action footprint refuses unknown movement context and missing raw page',
      () async {
    final source = await _source();
    expect(_resolve(source,
        context: const SourceSemanticContext(mode: SourceMovementMode.surf)).kind,
        SourceEventTouchKind.unqualified);
    final analysis = _analysis(source);
    final event = analysis.eventAt(1, 1)!;
    final original = event.pages.single;
    final page = SourceEventPageAnalysis(sourcePage: original.sourcePage,
        locator: original.locator, condition: original.condition,
        graphic: original.graphic, body: original.body,
        rawDataRef: null, diagnostics: original.diagnostics);
    final replacement = SourceEventDefinition(sourceMapId: event.sourceMapId,
        sourceEventId: event.sourceEventId, sourceFileId: event.sourceFileId,
        identity: event.identity, name: event.name, x: event.x, y: event.y,
        locator: event.locator, pages: [page]);
    final resolver = SourceSemanticResolver.forProject(source);
    expect(resolver.resolveStaticActionFootprint(event: replacement,
        page: page, mapEvents: [replacement], width: 2, height: 1).kind,
        SourceEventTouchKind.unqualified);
  });

  test('static action footprint does not weaken the existing touch footprint gate',
      () async {
    final source = await _source();
    final analysis = _analysis(source);
    final event = analysis.eventAt(1, 1)!;
    final resolver = SourceSemanticResolver.forProject(source);
    expect(resolver.resolveEventTouch(cell: resolver.cellAt(1, 1, 1),
        event: event, page: event.pages.single, mapEvents: analysis.events).kind,
        SourceEventTouchKind.unqualified);
  });
}
