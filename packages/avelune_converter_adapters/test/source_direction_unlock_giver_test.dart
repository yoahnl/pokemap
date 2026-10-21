import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

final _declaredGiverProfile = SourceInterpretationProfile.fromJson({
  ...syntheticSourceInterpretationProfile.toJson(),
  'sections': {
    ...syntheticSourceInterpretationProfile.toJson()['sections'] as Map,
    'walking.Game_Character': {
      'index': 44,
      'name': 'Game_Character',
      'sha256':
          '0cb6a5149f998c053055d3c7726d557fe1a1368fcabe14bb4a7c159f09a686b9'
    },
    'events.Game_Event': {
      'index': 45,
      'name': 'Game_Event',
      'sha256':
          '8c11fb7f170df5ca2aff17725e1dbed031c94deebabdbbae69dd926e24acafa7'
    },
  },
});

LiteralFixtureObject _step(int code) => LiteralFixtureObject(
    'RPG::MoveCommand', {'@code': code, '@parameters': <Object?>[]});
List<LiteralFixtureEventCommand> _route(List<int> codes,
        {bool repeat = false, bool corruptCopy = false}) =>
    [
      LiteralFixtureEventCommand(209, [
        0,
        LiteralFixtureObject('RPG::MoveRoute', {
          '@repeat': repeat,
          '@skippable': false,
          '@list': [...codes.map(_step), _step(0)]
        })
      ]),
      for (final (i, code) in codes.indexed)
        LiteralFixtureEventCommand(
            509, [_step(corruptCopy && i == 0 ? 35 : code)])
    ];
Future<({NormalizedSourceProject source, SourceEventAnalysis analysis})>
    _fixture(
        {bool locked = true,
        bool repeat = false,
        bool corruptCopy = false,
        bool extraScript = false,
        int completedPageDirection = 8,
        String grant = 'pbReceiveItem(:HM01)'}) async {
  final fixture = await LiteralTileFixture.create(
      interpretationProfile: syntheticSourceInterpretationProfile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      switchNames: [
        null,
        for (var i = 1; i <= 62; i++) 'Flag $i'
      ],
      maps: [
        LiteralFixtureMap(id: 186, width: 3, height: 3, layers: [
          List.filled(9, 384),
          List.filled(9, 0),
          List.filled(9, 0)
        ], events: [
          LiteralFixtureEvent(id: 2, x: 1, y: 1, name: 'Captain', pages: [
            LiteralFixtureEventPage(
                characterName: 'Captain',
                direction: 8,
                directionFix: locked,
                commands: [
                  const LiteralFixtureEventCommand(101, ['Feeling ill.']),
                  const LiteralFixtureEventCommand(101, ['Rubbing.']),
                  const LiteralFixtureEventCommand(249, [
                    LiteralFixtureObject('RPG::AudioFile',
                        {'@name': 'Recovery', '@volume': 100, '@pitch': 100})
                  ]),
                  const LiteralFixtureEventCommand(101, ['Recovered.']),
                  ..._route([36, 25], repeat: repeat, corruptCopy: corruptCopy),
                  const LiteralFixtureEventCommand(101, ['Here is a machine.']),
                  const LiteralFixtureEventCommand(
                      111, [12, r'!$bag.has?(:HM01)']),
                  LiteralFixtureEventCommand(355, [grant], indent: 1),
                  const LiteralFixtureEventCommand(0, [], indent: 1),
                  const LiteralFixtureEventCommand(412, []),
                  const LiteralFixtureEventCommand(101, ['Try it outside.']),
                  ..._route([25]),
                  const LiteralFixtureEventCommand(123, ['A', 0]),
                  const LiteralFixtureEventCommand(121, [62, 62, 0]),
                  if (extraScript)
                    const LiteralFixtureEventCommand(355, ['unknownEffect()']),
                  const LiteralFixtureEventCommand(0, [])
                ]),
            LiteralFixtureEventPage(
                characterName: 'Captain',
                direction: completedPageDirection,
                selfSwitch: 'A',
                commands: [
                  const LiteralFixtureEventCommand(101, ['Farewell.']),
                  ..._route([25]),
                  const LiteralFixtureEventCommand(0, [])
                ])
          ])
        ])
      ]);
  return (
    source: fixture.source,
    analysis: SourceEventAnalyzer.forProject(fixture.source,
            profile: SourceEventProfile.forProject(fixture.source,
                interpretationProfile: _declaredGiverProfile))
        .analyze()
  );
}

void main() {
  for (final role in ['walking.Game_Character', 'events.Game_Event']) {
    test('direction unlock rejects changed $role semantics', () async {
      final result = await _fixture();
      final sections = Map<String, Object?>.from(
          _declaredGiverProfile.toJson()['sections'] as Map);
      sections[role] = {...sections[role] as Map, 'sha256': '0' * 64};
      final profile = SourceEventProfile.forProject(result.source,
          interpretationProfile: SourceInterpretationProfile.fromJson(
              {..._declaredGiverProfile.toJson(), 'sections': sections}));
      expect(
          SourceDirectionUnlockGiverProgram.read(
              source: result.source,
              profile: profile,
              sourceMapId: 186,
              event: result.source.maps.single.map.events.single),
          isNull);
      expect(
          SourceEventAnalyzer.forProject(result.source, profile: profile)
              .analyze()
              .eventAt(186, 2)!
              .isQuarantined,
          isTrue);
    });
  }
  test('direction unlock requires an attested walking profile', () async {
    final result = await _fixture();
    final profile = SourceEventProfile.forProject(result.source,
        interpretationProfile: SourceInterpretationProfile.fromJson({
          ..._declaredGiverProfile.toJson(),
          'capabilities': ['events'],
        }));
    final event = result.source.maps.single.map.events.single;
    expect(
        SourceDirectionUnlockGiverProgram.read(
            source: result.source,
            profile: profile,
            sourceMapId: 186,
            event: event),
        isNull);
    expect(
        SourceEventAnalyzer.forProject(result.source, profile: profile)
            .analyze()
            .eventAt(186, 2)!
            .isQuarantined,
        isTrue);
  });
  test('closed machine giver preserves the real direction unlock before facing',
      () async {
    final result = await _fixture();
    final event = result.analysis.eventAt(186, 2)!;
    expect(event.pages.first.graphic!.directionFix, isTrue);
    expect(event.isQuarantined, isFalse,
        reason:
            '${event.pages.first.body.diagnostics.map((d) => d.code).toList()}');
    expect(
        event.pages.first.body.nodes.whereType<SourceInteractionFacingNode>(),
        hasLength(2));
    expect(
        event.pages.first.body.nodes
            .whereType<SourceInteractionFacingNode>()
            .first
            .rawDataRefs,
        hasLength(3));
    expect(event.pages.last.graphic!.directionFix, isFalse);
  });
  for (final defect in [
    'notLocked',
    'repeat',
    'copy',
    'script',
    'pageDirectionChanged',
    'grantMismatch',
    'quantity'
  ]) {
    test('direction unlock giver refuses $defect', () async {
      final result = await _fixture(
          locked: defect != 'notLocked',
          repeat: defect == 'repeat',
          corruptCopy: defect == 'copy',
          extraScript: defect == 'script',
          completedPageDirection: defect == 'pageDirectionChanged' ? 4 : 8,
          grant: defect == 'grantMismatch'
              ? 'pbReceiveItem(:HM04)'
              : defect == 'quantity'
                  ? 'pbReceiveItem(:HM01,2)'
                  : 'pbReceiveItem(:HM01)');
      expect(result.analysis.eventAt(186, 2)!.isQuarantined, isTrue);
    });
  }
}
