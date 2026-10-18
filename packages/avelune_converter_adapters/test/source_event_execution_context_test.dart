import 'dart:convert';
import 'dart:io';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

List<int> _commonEvents(int trigger) => [
      4,
      8,
      91,
      7,
      48,
      111,
      58,
      20,
      ...utf8.encode('RPG::CommonEvent'),
      6,
      58,
      13,
      ...utf8.encode('@trigger'),
      105,
      trigger == 0 ? 0 : trigger + 5,
    ];

void main() {
  final scriptsPath = Platform.environment['AVELUNE_AC13_SOURCE_SCRIPTS'];
  for (final trigger in [1, 2]) {
    test('automatic common event trigger $trigger refuses the source context',
        () async {
      final fixture = await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,

          scriptsBytes: await File(scriptsPath!).readAsBytes(),
          includeEventSystem: true,
          extraFiles: {
            'Data/CommonEvents.rxdata': _commonEvents(trigger),
            'Data/PluginScripts.rxdata': [4, 8, 91, 0]
          });
      final context = await const SourceEventExecutionContextResolver().read(
          source: fixture.source,
          base: null,
          nativeMaps: const {},
          files: fixture.files);
      expect(context.isQualified, isFalse);
      expect(
          context.refusals, contains('sourceAutomaticCommonEventUnsupported'));
      expect(context.refusals, contains('sourcePluginRouteContextUnsupported'));
    }, skip: scriptsPath == null);
  }

  test('parallel map event refuses the source execution context', () async {
    final fixture = await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,

        scriptsBytes: await File(scriptsPath!).readAsBytes(),
        includeEventSystem: true,
        maps: [
          LiteralFixtureMap(id: 100, width: 2, height: 2, layers: [
            List.filled(4, 384),
            List.filled(4, 0),
            List.filled(4, 0)
          ], events: const [
            LiteralFixtureEvent(
                id: 7,
                x: 0,
                y: 0,
                pages: [LiteralFixtureEventPage(trigger: 4, commands: [])])
          ])
        ],
        extraFiles: {
          'Data/CommonEvents.rxdata': _commonEvents(0),
          'Data/PluginScripts.rxdata': [4, 8, 91, 0]
        });
    final context = await const SourceEventExecutionContextResolver().read(
        source: fixture.source,
        base: null,
        nativeMaps: const {},
        files: fixture.files);
    expect(context.isQualified, isFalse);
    expect(context.refusals, contains('sourceParallelEventUnsupported'));
  }, skip: scriptsPath == null);

  test('ordinary quarantined events do not require an original door context',
      () async {
    final fixture = await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,

        scriptsBytes: await File(scriptsPath!).readAsBytes(),
        includeEventSystem: true,
        maps: [
          LiteralFixtureMap(id: 1, width: 2, height: 2, layers: [
            List.filled(4, 384),
            List.filled(4, 0),
            List.filled(4, 0)
          ], events: const [
            LiteralFixtureEvent(id: 1, x: 0, y: 0, pages: [
              LiteralFixtureEventPage(commands: [
                LiteralFixtureEventCommand(355, ['unsupported_call()'])
              ])
            ])
          ])
        ]);
    final source = fixture.source;
    final result = const SourceEventProjector().project(
        source: source,
        analysis: SourceEventAnalyzer.forProject(source,
                profile: SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
            .analyze(),
        nativeMaps: {
          1: MapData(
              id: 'ordinary-map',
              name: 'Ordinary',
              size: const GridSize(width: 2, height: 2),
              layers: [])
        });
    expect(result.registry.records.single.draftOrNull, isNotNull);
    expect(result.scenes, isEmpty);
    expect(result.allEnabledOriginalEventsHaveExecutionContext, isTrue);
  }, skip: scriptsPath == null);
}
