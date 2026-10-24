import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:avelune_converter_adapters/src/source_system_entry_binding.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

void main() {
  Future<LiteralTileFixture> fixture(
          {int mapId = 73,
          Object? x = 1,
          Object? y = 0,
          Object? declaredMap = 73,
          bool system = true}) =>
      LiteralTileFixture.create(
          namespace: 'source-system-start',
          maps: [LiteralFixtureMap(id: mapId)],
          includeEventSystem: system,
          systemFields: {
            '@start_map_id': declaredMap,
            '@start_x': x,
            '@start_y': y
          },
          scriptsBytes: syntheticInterpretationArchive,
          interpretationProfile: fixtureSourceInterpretationProfile);

  test(
      'derives arbitrary source System coordinates without an intro convention',
      () async {
    final source = (await fixture()).source;
    final start = sourceSystemStart(source)!;
    expect(start.sourceMapId, 73);
    expect(start.x, 1);
    expect(start.y, 0);
    expect(start.isBoundTo(source), isTrue);
    expect(sourceFreshEntryProgram(source), isNull);
    expect(start.isBoundTo((await fixture(x: 2)).source), isFalse);
  });
  Future<bool> permits(
      {int? switchId, int trigger = 3, bool adapted = false, bool introFactory = false}) async {
    final f = await LiteralTileFixture.create(
        namespace: 'source-system-auto',
        maps: [
          LiteralFixtureMap(id: 89, events: [
            LiteralFixtureEvent(id: 3, x: 0, y: 0, pages: [
              LiteralFixtureEventPage(
                  globalSwitch: switchId,
                  trigger: trigger,
                  commands: [
                    const LiteralFixtureEventCommand(
                        355, ['unknown_source_script'])
                  ])
            ])
          ])
        ],
        includeEventSystem: true,
        scriptsBytes: syntheticInterpretationArchive,
        interpretationProfile: fixtureSourceInterpretationProfile);
    final event = f.source.eventIdentity(89, 3);
    final p = SourceEventProjection(
        nativeMaps: const {},
        registry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [],
            legacyClaims: []),
        facts: [],
        scenes: [],
        dialogues: [],
        dialogueSources: {},
        worldRules: [],
        itemCatalog: null,
        artifacts: [],
        mutations: [],
        semanticEvidence: {
          'events': [
            {
              'sourceIdentity': event.value,
              'status': adapted ? 'adaptedStaticSemantics' : 'quarantined',
              'gaps': [], if(introFactory) 'nativeIntroduction': {'requiresNativeFreshEntryFactory':true}
            }
          ]
        },
        staticSemanticsQualified: true,
        allEnabledOriginalEventsHaveExecutionContext: true);
    return sourceSystemEntryEventsQualified(f.source, p, 89);
  }

  test('an unadapted active autorun cannot be bypassed by a direct start',
      () async {
    expect(await permits(), isFalse);
  });
  test('an initially inactive autorun does not invent a blocking intro',
      () async {
    expect(await permits(switchId: 1), isTrue);
  });
  test('active adapted autoruns remain executable', () async {
    expect(await permits(adapted: true), isTrue);
  });
  test('a closed intro factory cannot be bypassed by a direct System start',() async {
    expect(await permits(adapted:true,introFactory:true),isFalse);
  });
  test('a nonautomatic quarantined event does not block a source start',
      () async {
    expect(await permits(trigger: 0), isTrue);
  });
  test('an unadapted active parallel event prevents a partial source startup',
      () async {
    expect(await permits(trigger: 4), isFalse);
  });
  test('missing System cannot invent a start', () async {
    expect(sourceSystemStart((await fixture(system: false)).source), isNull);
  });
  test('absent map is rejected', () async {
    expect(sourceSystemStart((await fixture(declaredMap: 74)).source), isNull);
  });
  for (final coordinates in [
    ("1", 0),
    (1, "0"),
    (-1, 0),
    (3, 0),
    (1, -1),
    (1, 1)
  ]) {
    test('invalid coordinates $coordinates are rejected', () async {
      expect(
          sourceSystemStart(
              (await fixture(x: coordinates.$1, y: coordinates.$2)).source),
          isNull);
    });
  }
}
