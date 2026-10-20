import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<SourceEventProjection> _project(String text, {bool qualifiedText = true}) async {
  final profile = SourceInterpretationProfile.fromJson({
    ...syntheticSourceInterpretationProfile.toJson(),
    'sections': {
      ...syntheticSourceInterpretationProfile.sections,
      if (qualifiedText) for (final role in ['Messages', 'MessageConfig', 'DrawText'])
        'events.$role': {'index': 0, 'name': 'Synthetic',
          'sha256': syntheticSourceInterpretationProfile.sections.values.first['sha256']},
    },
  });
  final fixture = await LiteralTileFixture.create(
    scriptsBytes: syntheticInterpretationArchive, interpretationProfile: profile,
    includeEventSystem: true, variableNames: List.generate(40, (i) => 'Variable $i'),
    maps: [LiteralFixtureMap(id: 1, width: 3, height: 3,
      layers: [List.filled(9, 384), List.filled(9, 0), List.filled(9, 0)],
      events: [LiteralFixtureEvent(id: 1, x: 1, y: 1, name: 'Diary', pages: [
        LiteralFixtureEventPage(commands: [
          LiteralFixtureEventCommand(101, [text]),
          const LiteralFixtureEventCommand(122, [38, 38, 1, 0, 1]),
          const LiteralFixtureEventCommand(123, ['A', 0]),
          const LiteralFixtureEventCommand(0, []),
        ]),
        LiteralFixtureEventPage(selfSwitch: 'A', commands: [
          LiteralFixtureEventCommand(101, [text]),
          const LiteralFixtureEventCommand(0, []),
        ]),
      ])])]);
  final analysis = SourceEventAnalyzer.forProject(fixture.source,
      profile: SourceEventProfile.forProject(fixture.source)).analyze();
  return const SourceEventProjector().project(source: fixture.source,
      analysis: analysis, nativeMaps: {1: const MapData(id: 'diary-map', name: 'Diary',
        size: GridSize(width: 3, height: 3), layers: [])});
}

void main() {
  for (final (text, expected, repaired) in [
    ('<i>Who wrote this?</i>', 'Who wrote this?', 0),
    (r'<i>Who wrote this?<\i>', 'Who wrote this?', 1),
    (r'Before <i>one</i> and <i>two<\i>.', 'Before one and two.', 1),
    (r'<i>Line one\nLine two<\i>', 'Line one\nLine two', 1),
  ]) {
    test('plain italic presentation keeps text and facts $text', () async {
      final projection = await _project(text);
      final row = (projection.semanticEvidence['events'] as List).single as Map;
      expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
      final evidence = (row['pages'] as List).expand((p) => p['adaptedCommands'] as List)
          .cast<Map>().where((c) => c['nativeContract'] == 'avelunePlainTextFromSourceItalic').toList();
      expect(evidence, hasLength(2));
      expect(evidence.every((e) => e['sourceItalicStyleParityQualified'] == false &&
          e['sourceRubyRenderingParityQualified'] == false &&
          e['repairedClosingTags'] == repaired && e['rawDataRefs'] is List), isTrue);
      final lines = projection.scenes.expand((s) => s.graph.nodes).map((n) => n.payload)
          .whereType<SceneYarnDialoguePayload>().expand((p) => p.linePolicies)
          .map((p) => p.feedback.plainText).toList();
      expect(lines, [expected, expected]);
      final consequences = projection.scenes.expand((s) => s.graph.nodes).map((n) => n.payload)
          .whereType<SceneActionPayload>().map((p) => p.consequence);
      expect(consequences.whereType<SceneAdjustIntegerFactConsequence>().single.delta, 1);
      expect(consequences.whereType<SceneSetFactConsequence>(), hasLength(1));
    });
  }

  for (final text in [
    '<i>Unclosed', 'Unopened</i>', r'Unopened<\i>',
    '<i><i>Nested</i></i>', '<i class=x>Attribute</i>',
    '<i>Other <b>tag</b></i>', '<i>Other <unknown>tag</unknown></i>',
    '<i>Bad</ i>', r'<i>Bad<\\i>', '<I>Case</I>',
    '<i>One</i></i>', '<i>One</i> >', '<i>One</i> <',
    r'<i>Control\wt[20]<\i>', r'<i>Image\se[Unbound]<\i>',
  ]) {
    test('refuses malformed or mixed italic presentation $text', () async {
      final projection = await _project(text);
      final row = (projection.semanticEvidence['events'] as List).single as Map;
      expect(row['status'], 'quarantinedWholeEvent');
      expect(projection.scenes, isEmpty);
    });
  }

  test('italic adaptation requires the attested text interpreter profile', () async {
    final projection = await _project(r'<i>Diary<\i>', qualifiedText: false);
    expect(projection.scenes, isEmpty);
  });
}
