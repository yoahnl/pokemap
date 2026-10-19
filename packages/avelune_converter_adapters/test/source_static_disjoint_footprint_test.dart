import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<SourceEventTouchResolution> _resolve({
  required String name,
  required int x,
  required int y,
  int tileId = 0,
  int moveType = 0,
  bool attestNeighbor = true,
}) async {
  final fixture = await LiteralTileFixture.create(
    interpretationProfile: syntheticSourceInterpretationProfile,
    scriptsBytes: syntheticInterpretationArchive,
    includeEventSystem: true,
    maps: [
      LiteralFixtureMap(
        id: 1,
        width: 8,
        height: 6,
        layers: [
          List.filled(48, 384),
          List.filled(48, 0),
          List.generate(48, (index) => {28, 29}.contains(index) ? 400 : 0),
        ],
        events: [
          const LiteralFixtureEvent(
            id: 1,
            x: 4,
            y: 3,
            name: 'Wall Map size(2,1)',
            pages: [LiteralFixtureEventPage(commands: [])],
          ),
          LiteralFixtureEvent(
            id: 2,
            x: x,
            y: y,
            name: name,
            pages: [
              LiteralFixtureEventPage(
                tileId: tileId,
                moveType: moveType,
                variableId: 6,
                variableThreshold: 1,
                commands: const [],
              ),
            ],
          ),
        ],
      ),
    ],
    tilesets: [LiteralFixtureTileset(id: 1, passages: const {400: 15})],
  );
  final source = fixture.source;
  final analysis = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  final event = analysis.eventAt(1, 1)!;
  final neighbor = analysis.eventAt(1, 2)!;
  final mapEvents = [
    event,
    if (attestNeighbor)
      neighbor
    else
      SourceEventDefinition(
        sourceMapId: neighbor.sourceMapId,
        sourceEventId: neighbor.sourceEventId,
        sourceFileId: neighbor.sourceFileId,
        identity: neighbor.identity,
        name: neighbor.name,
        x: neighbor.x,
        y: neighbor.y,
        locator: neighbor.locator,
        pages: [
          for (final page in neighbor.pages)
            SourceEventPageAnalysis(
              sourcePage: page.sourcePage,
              locator: page.locator,
              condition: page.condition,
              graphic: page.graphic,
              body: page.body,
              rawDataRef: null,
              diagnostics: page.diagnostics,
            ),
        ],
      ),
  ];
  return SourceSemanticResolver.forProject(source).resolveStaticActionFootprint(
    event: event,
    page: event.pages.single,
    mapEvents: mapEvents,
    width: 2,
    height: 1,
  );
}

void main() {
  test('disjoint footprint still requires raw source attestation', () async {
    final result = await _resolve(
      name: 'Monitor size(2,2)',
      x: 0,
      y: 3,
      attestNeighbor: false,
    );
    expect(result.kind, SourceEventTouchKind.unqualified);
  });

  for (final sample in [
    (name: 'Monitor size(2,2)', x: 0, y: 3, tileId: 0),
    (name: 'Monitor size(2,2)', x: 4, y: 1, tileId: 0),
    (name: 'Monitor size(2,2)', x: 4, y: 5, tileId: 400),
  ]) {
    test('disjoint stationary footprint does not refuse wall interaction $sample',
        () async {
      final result = await _resolve(
        name: sample.name,
        x: sample.x,
        y: sample.y,
        tileId: sample.tileId,
      );
      expect(result.kind, SourceEventTouchKind.front, reason: result.reason);
      expect(result.reason, 'stationaryFootprintTilesBlocked');
    });
  }

  for (final sample in [
    (name: 'Monitor size(2,2)', x: 4, y: 3, tileId: 0, moveType: 0),
    (name: 'Monitor size(2,2)', x: 4, y: 4, tileId: 0, moveType: 0),
    (name: 'Monitor size(2,2)', x: 0, y: 3, tileId: 400, moveType: 1),
    (name: 'Monitor size(2,2)', x: 7, y: 3, tileId: 0, moveType: 0),
    (name: 'Monitor size(2,2)', x: 0, y: 0, tileId: 0, moveType: 0),
    (name: 'Monitor size(0,2)', x: 0, y: 3, tileId: 0, moveType: 0),
    (name: 'Monitor size(2,2) size(1,1)', x: 0, y: 3, tileId: 0, moveType: 0),
  ]) {
    test('unsafe neighboring footprint remains unqualified $sample', () async {
      final result = await _resolve(
        name: sample.name,
        x: sample.x,
        y: sample.y,
        tileId: sample.tileId,
        moveType: sample.moveType,
      );
      expect(result.kind, SourceEventTouchKind.unqualified);
    });
  }
}
