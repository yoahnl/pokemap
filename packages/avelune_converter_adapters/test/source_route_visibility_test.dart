import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<SourceEventAnalysis> _analysis(Object? opacity) async {
  final step = LiteralFixtureObject('RPG::MoveCommand', {
    '@code': 42,
    '@parameters': [opacity]
  });
  final end = LiteralFixtureObject(
      'RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]});
  final fixture = await LiteralTileFixture.create(
      interpretationProfile: syntheticSourceInterpretationProfile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      maps: [
        LiteralFixtureMap(id: 1, width: 3, height: 3, layers: [
          List.filled(9, 384),
          List.filled(9, 0),
          List.filled(9, 0)
        ], events: [
          LiteralFixtureEvent(id: 1, x: 1, y: 1, pages: [
            LiteralFixtureEventPage(commands: [
              LiteralFixtureEventCommand(209, [
                -1,
                LiteralFixtureObject('RPG::MoveRoute', {
                  '@repeat': false,
                  '@skippable': false,
                  '@list': [step, end]
                })
              ]),
              LiteralFixtureEventCommand(509, [step]),
              const LiteralFixtureEventCommand(210, []),
            ])
          ])
        ])
      ]);
  return SourceEventAnalyzer.forProject(fixture.source,
          profile: SourceEventProfile.forProject(fixture.source))
      .analyze();
}

void main() {
  for (final opacity in [0, 255]) {
    test('source literal opacity $opacity has exact boolean visibility',
        () async {
      final analysis = await _analysis(opacity);
      final event = analysis.events.single;
      expect(event.isQuarantined, isFalse);
      final route = event.pages.single.body.nodes
          .whereType<SourceForcedMoveRouteNode>()
          .single;
      expect(route.steps.single.sourceCode, 42);
      expect(
          route.steps.single.kind,
          opacity == 0
              ? SourceMoveRouteStepKind.hide
              : SourceMoveRouteStepKind.show);
      expect(route.steps.single.rawDataRef.toJson(), isNotEmpty);
    });
  }
  for (final opacity in <Object?>[1, 128, -1, 256, '0', null]) {
    test('source opacity $opacity refuses lossy visibility adaptation',
        () async {
      final analysis = await _analysis(opacity);
      expect(analysis.events.single.isQuarantined, isTrue);
      expect(
          analysis.events.single.pages.single.body.nodes
              .whereType<SourceForcedMoveRouteNode>(),
          isEmpty);
    });
  }
}
