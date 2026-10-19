import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<({SourceEventAnalysis analysis, SourceEventProjection projection})> _read(
    List<LiteralFixtureEventCommand> commands) async {
  final fixture = await LiteralTileFixture.create(
    interpretationProfile: syntheticSourceInterpretationProfile,
    scriptsBytes: syntheticInterpretationArchive,
    includeEventSystem: true,
    maps: [LiteralFixtureMap(id: 1, events: [
      LiteralFixtureEvent(id: 1, x: 0, y: 0, pages: [
        LiteralFixtureEventPage(commands: commands),
      ]),
    ])],
  );
  final analysis = SourceEventAnalyzer.forProject(fixture.source,
      profile: SourceEventProfile.forProject(fixture.source)).analyze();
  final projection = const SourceEventProjector().project(
      source: fixture.source, analysis: analysis, nativeMaps: {
        1: MapData(id: 'map', name: 'Map',
            size: const GridSize(width: 3, height: 1), layers: []),
      });
  return (analysis: analysis, projection: projection);
}

Set<String> _gaps(SourceEventProjection projection) =>
    ((projection.semanticEvidence['events'] as List).single as Map)['gaps']
        .cast<String>().toSet();

void main() {
  for (final route in [false, true]) {
    test('sound pitch has its own capability refusal, route=$route', () async {
      const audio = LiteralFixtureObject('RPG::AudioFile',
          {'@name': 'MissingSound', '@volume': 80, '@pitch': 120});
      const step = LiteralFixtureObject('RPG::MoveCommand',
          {'@code': 44, '@parameters': [audio]});
      final result = await _read([
        if (!route) const LiteralFixtureEventCommand(250, [audio]),
        if (route) ...[
          const LiteralFixtureEventCommand(209, [-1,
            LiteralFixtureObject('RPG::MoveRoute', {
              '@repeat': false, '@skippable': true, '@list': [step,
                LiteralFixtureObject('RPG::MoveCommand',
                    {'@code': 0, '@parameters': []}),
              ],
            }),
          ]),
          const LiteralFixtureEventCommand(509, [step]),
          const LiteralFixtureEventCommand(210, []),
        ],
      ]);
      expect(result.analysis.events.single.isQuarantined, isFalse);
      expect(_gaps(result.projection), contains('sourceSoundPitchUnsupported'));
      expect(_gaps(result.projection), contains('sourceSoundBindingMissing'));
      expect(result.projection.scenes, isEmpty);
    });
  }

  test('actor appearance command remains refused with a precise capability', () async {
    final result = await _read(const [
      LiteralFixtureEventCommand(322, [1, 'Actor', 0, 'Battler', 0]),
    ]);
    final unknown = result.analysis.events.single.pages.single.body.nodes.single
        as SourceUnknownNode;
    expect(unknown.reason, 'events.actor_appearance_unsupported');
    expect(_gaps(result.projection), contains('sourceActorAppearanceUnsupported'));
    expect(result.projection.scenes, isEmpty);
  });

  test('route appearance remains refused without discarding its command', () async {
    const step = LiteralFixtureObject('RPG::MoveCommand',
        {'@code': 41, '@parameters': ['Actor', 0, 2, 0]});
    final result = await _read(const [
      LiteralFixtureEventCommand(209, [0,
        LiteralFixtureObject('RPG::MoveRoute', {
          '@repeat': false, '@skippable': true, '@list': [step,
            LiteralFixtureObject('RPG::MoveCommand',
                {'@code': 0, '@parameters': []}),
          ],
        }),
      ]),
      LiteralFixtureEventCommand(509, [step]),
      LiteralFixtureEventCommand(210, []),
    ]);
    final unknown = result.analysis.events.single.pages.single.body.nodes.first
        as SourceUnknownNode;
    expect(unknown.reason, 'events.move_route_appearance_unsupported');
    expect(unknown.command.code, 209);
    expect(_gaps(result.projection), contains('sourceRouteAppearanceUnsupported'));
    expect(result.projection.scenes, isEmpty);
  });
}
