import 'package:avelune_converter_adapters/src/source_sequence_program.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

LiteralFixtureObject _step(int code) => LiteralFixtureObject(
    'RPG::MoveCommand', {'@code': code, '@parameters': <Object?>[]});
List<LiteralFixtureEventCommand> _route(int target, List<int> codes,
        {bool barrier = false, bool repeat = false, bool skippable = false}) =>
    [
      LiteralFixtureEventCommand(209, [
        target,
        LiteralFixtureObject('RPG::MoveRoute', {
          '@repeat': repeat,
          '@skippable': skippable,
          '@list': [for (final code in codes) _step(code), _step(0)]
        })
      ]),
      for (final code in codes) LiteralFixtureEventCommand(509, [_step(code)]),
      if (barrier) const LiteralFixtureEventCommand(210, []),
    ];
Future<NormalizedSourceProject> _source(
    {String item = 'POTION',
    int threshold = 2,
    int actor = 7,
    int exclamationActor = 7,
    int upwardCode = 4,
    bool repeat = false,
    bool skippable = false,
    bool barrier = true,
    bool terminal = true,
    int quantity = 1,
    bool extra = false}) async {
  final profile = SourceInterpretationProfile.fromJson({
    ...syntheticSourceInterpretationProfile.toJson(),
    'sections': {
      ...syntheticSourceInterpretationProfile.sections,
      'events.Utilities':
          syntheticSourceInterpretationProfile.sections['events.Interpreter']
    },
  });
  final fixture = await LiteralTileFixture.create(
      interpretationProfile: profile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      maps: [
        LiteralFixtureMap(id: 1, width: 13, height: 12, layers: [
          List.filled(156, 384),
          List.filled(156, 0),
          List.filled(156, 0)
        ], events: [
          LiteralFixtureEvent(id: 3, x: 4, y: 0, name: 'Delivery', pages: [
            LiteralFixtureEventPage(
                trigger: 3,
                variableId: 1,
                variableThreshold: threshold,
                commands: [
                  const LiteralFixtureEventCommand(
                      108, ['An original delivery.']),
                  const LiteralFixtureEventCommand(106, [8]),
                  ..._route(actor, [16], repeat: repeat, skippable: skippable),
                  LiteralFixtureEventCommand(
                      355, ['pbExclaim(get_character($exclamationActor))']),
                  const LiteralFixtureEventCommand(101, ['Hello there.']),
                  ..._route(
                      -1, [upwardCode, upwardCode, upwardCode, upwardCode],
                      barrier: barrier),
                  ..._route(-1, [17]),
                  ..._route(actor, [18]),
                  const LiteralFixtureEventCommand(
                      101, ['You know the recipient?']),
                  const LiteralFixtureEventCommand(
                      101, ['Please deliver this.']),
                  LiteralFixtureEventCommand(355, [
                    'pbReceiveItem(:$item${quantity == 1 ? '' : ',$quantity'})'
                  ]),
                  if (extra)
                    const LiteralFixtureEventCommand(355, ['unknownEffect()']),
                  const LiteralFixtureEventCommand(123, ['A', 0]),
                ]),
            if (terminal)
              const LiteralFixtureEventPage(selfSwitch: 'A', commands: []),
          ])
        ])
      ]);
  return fixture.source;
}

SourceEventAnalysis _analysis(NormalizedSourceProject s) =>
    SourceEventAnalyzer.forProject(s, profile: SourceEventProfile.forProject(s))
        .analyze();
void main() {
  for (final item in ['POTION', 'OAKPARCEL']) {
    test('finite giver is structural and preserves source item $item',
        () async {
      final source = await _source(item: item);
      final a = _analysis(source);
      final programs = sourceSequencePrograms(source: source, analysis: a);
      expect(programs, hasLength(1));
      final program = programs.values.single;
      expect(program.finiteItemGiver, isTrue);
      expect(program.auxiliaryActorEventId, 7);
      expect(
          program.isBoundTo(
              source: source, analysis: a, event: a.events.single),
          isTrue);
      expect(
          a.events.single.pages.first.body.nodes
              .whereType<SourcePickupNode>()
              .single
              .sourceSymbol,
          item);
    });
  }
  final cases = <String, Future<NormalizedSourceProject> Function()>{
    'dynamic repeat': () => _source(repeat: true),
    'skippable replacement': () => _source(skippable: true),
    'mismatched emote target': () => _source(exclamationActor: 8),
    'sideways movement': () => _source(upwardCode: 3),
    'unjoined player movement': () => _source(barrier: false),
    'missing terminal page': () => _source(terminal: false),
    'already active zero threshold': () => _source(threshold: 0),
    'partial bag grant': () => _source(quantity: 2),
    'opaque side effect': () => _source(extra: true),
  };
  for (final entry in cases.entries) {
    test('finite giver refuses ${entry.key}', () async {
      final s = await entry.value();
      expect(
          sourceSequencePrograms(source: s, analysis: _analysis(s)), isEmpty);
    });
  }
}
