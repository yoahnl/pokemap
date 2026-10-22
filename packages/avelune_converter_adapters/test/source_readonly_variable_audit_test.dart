import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

const _read = r'$player.party[$game_variables[pbGet(29)]].happiness >= 255';

Future<NormalizedSourceProject> _source(String expression,
        {required List<int> scripts,
        required SourceInterpretationProfile profile,
        bool asStatement = false}) async =>
    (await LiteralTileFixture.create(
            scriptsBytes: scripts,
            interpretationProfile: profile,
            includeEventSystem: true,
            variableNames: List.filled(128, ''),
            maps: [
          LiteralFixtureMap(id: 1, events: [
            const LiteralFixtureEvent(id: 1, x: 0, y: 0, pages: [
              LiteralFixtureEventPage(commands: [
                LiteralFixtureEventCommand(122, [7, 7, 0, 0, 3]),
                LiteralFixtureEventCommand(111, [1, 7, 0, 3, 0]),
                LiteralFixtureEventCommand(101, ['Qualified integer dialogue'], indent: 1),
                LiteralFixtureEventCommand(412, []),
                LiteralFixtureEventCommand(0, []),
              ]),
            ]),
            LiteralFixtureEvent(
                id: 2,
                x: 2,
                y: 0,
                name: 'Opaque tutor',
                pages: [
                  LiteralFixtureEventPage(commands: [
                    LiteralFixtureEventCommand(asStatement ? 355 : 111,
                        asStatement ? [expression] : [12, expression]),
                    if (!asStatement) ...[
                      const LiteralFixtureEventCommand(
                          101, ['Still unsupported'],
                          indent: 1),
                      const LiteralFixtureEventCommand(412, []),
                    ],
                    const LiteralFixtureEventCommand(0, []),
                  ]),
                ]),
          ])
        ]))
        .source;

SourceEventProjection _project(NormalizedSourceProject source) =>
    const SourceEventProjector().project(
        source: source,
        analysis: SourceEventAnalyzer.forProject(source,
                profile: SourceEventProfile.forProject(source))
            .analyze(),
        nativeMaps: {
          1: MapData(
              id: 'native',
              name: 'Native',
              size: const GridSize(width: 3, height: 1))
        });

void main() {
  test('synthetic or unrelated source semantics cannot omit the dynamic read',
      () async {
    final profile = SourceInterpretationProfile.fromJson({
      ...syntheticSourceInterpretationProfile.toJson(),
      'sections': {
        ...syntheticSourceInterpretationProfile.toJson()['sections'] as Map,
        'events.Utilities': {
          'index': 0,
          'name': 'Synthetic',
          'sha256': syntheticSourceInterpretationProfile
              .sections.values.first['sha256']
        }
      },
    });
    final source = await _source(_read,
        scripts: syntheticInterpretationArchive, profile: profile);
    final analyzer = SourceEventAnalyzer.forProject(source,
        profile: SourceEventProfile.forProject(source));
    expect(analyzer.profile.isQualified, isTrue);
    final page = source.maps.single.map.events.last.pages.single;
    expect(
        analyzer
            .observeOpaquePageRuby(page, forVariableWriterAudit: true)
            .texts,
        contains(_read));
    expect(jsonEncode(_project(source).semanticEvidence),
        contains('sourceVariableWriterUnqualified'));
  });

  final scriptsPath = Platform.environment['AVELUNE_VARIABLE_READ_SCRIPTS'];
  final profilePath = Platform.environment['AVELUNE_VARIABLE_READ_PROFILE'];
  group('exact source archive read-only variable census', () {
    late List<int> scripts;
    late SourceInterpretationProfile profile;
    setUpAll(() async {
      scripts = await File(scriptsPath!).readAsBytes();
      profile = SourceInterpretationProfile.fromJson(
          jsonDecode(await File(profilePath!).readAsString()));
    });
    test(
        'the closed read no longer poisons other variables and does not activate the tutor',
        () async {
      final source = await _source(_read, scripts: scripts, profile: profile);
      final analyzer = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source));
      final page = source.maps.single.map.events.last.pages.single;
      expect(analyzer.observeOpaquePageRuby(page).texts, [_read]);
      expect(
          analyzer
              .observeOpaquePageRuby(page, forVariableWriterAudit: true)
              .texts,
          isEmpty);
      final projection = _project(source);
      final rows = projection.semanticEvidence['events'] as List;
      expect(rows.first['gaps'], isEmpty);
      expect(rows.last['status'], 'quarantinedWholeEvent');
      expect(rows.last['gaps'], contains('sourceQuarantined'));
      expect(projection.scenes, hasLength(1));
      expect(projection.facts, hasLength(1));
      expect(analyzer.analyze().eventAt(1, 2)!.isQuarantined, isTrue);
    });
    test(
        'a statement with identical syntax keeps the conservative writer guard',
        () async {
      final source = await _source(_read,
          scripts: scripts, profile: profile, asStatement: true);
      expect(jsonEncode(_project(source).semanticEvidence),
          contains('sourceVariableWriterUnqualified'));
    });
    test('a missing Utilities pin keeps the conservative writer guard',
        () async {
      final json = profile.toJson();
      final sections = {...json['sections'] as Map}..remove('events.Utilities');
      final unpinned =
          SourceInterpretationProfile.fromJson({...json, 'sections': sections});
      final source = await _source(_read, scripts: scripts, profile: unpinned);
      expect(jsonEncode(_project(source).semanticEvidence),
          contains('sourceVariableWriterUnqualified'));
    });
    test('a foreign profile binding cannot omit the dynamic read', () async {
      final source = await _source(_read, scripts: scripts, profile: profile);
      final analyzer = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile(
              scriptsArchiveHash: profile.scriptsArchiveHash,
              sourceSnapshotHash: Sha256Hash('0' * 64),
              normalizationHash: source.canonicalHash,
              interpretationProfile: profile));
      final page = source.maps.single.map.events.last.pages.single;
      expect(
          analyzer
              .observeOpaquePageRuby(page, forVariableWriterAudit: true)
              .texts,
          [_read]);
    });
    for (final expression in [
      '$_read; pbSet(7, 1)',
      r'$player.party[$game_variables[foo()]].happiness >= 255',
      r'$player.party[$game_variables[pbGet(29, foo())]].happiness >= 255',
      r'$player.party[$game_variables[pbGet(29)] = 1].happiness >= 255',
      r'$player.party[$game_variables[pbGet(29)] += 1].happiness >= 255',
      r'$player.party[$game_variables[pbGet(29)] ||= 1].happiness >= 255',
      r'$player.party[$game_variables[pbGet(29)] &&= 1].happiness >= 255',
      r'$player.party[$game_variables.[]=(pbGet(29), 1)].happiness >= 255',
      r'$player.party[$game_variables[pbGet(29)].replace([])].happiness >= 255',
    ]) {
      test(
          'opaque call or mutation still poisons the dynamic writer $expression',
          () async {
        final source =
            await _source(expression, scripts: scripts, profile: profile);
        final projection = _project(source);
        expect(projection.scenes, isEmpty);
        expect(jsonEncode(projection.semanticEvidence),
            contains('sourceVariableWriterUnqualified'));
      });
    }
  }, skip: scriptsPath == null || profilePath == null);
}
