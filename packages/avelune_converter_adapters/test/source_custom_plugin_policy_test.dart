import 'dart:convert';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

LiteralFixtureUserDefined _tone(double red) {
  final bytes = ByteData(32);
  for (var index = 0; index < 3; index++) {
    bytes.setFloat64(index * 8, red, Endian.little);
  }
  return LiteralFixtureUserDefined('Tone', bytes.buffer.asUint8List());
}

SourceInterpretationProfile _profile(bool exclude) => SourceInterpretationProfile.fromJson({
  ...fixtureSourceInterpretationProfile.toJson(),
  if (exclude) 'customPluginPolicy': 'excludeCustomBehavior',
});

Future<({NormalizedSourceProject source, LiteralFixtureFiles files,
    Map<int, MapData> maps, SourceEventAnalysis analysis, NativeProjectDraft base})>
    _fixture({bool exclude = true, bool plugins = true,
    bool pluginArchive = true, bool automaticCommon = false, bool twoDoors = false,
    List<String> excludedPaths = const []}) async {
  final fixture = await LiteralTileFixture.create(
      interpretationProfile: _profile(exclude),
      scriptsBytes: syntheticInterpretationArchive, includeEventSystem: true,
      commonEvents: automaticCommon ? {1: []} : const {},
      commonEventTriggers: automaticCommon ? {1: 2} : const {},
      maps: [
        LiteralFixtureMap(id: 1, width: 2, height: 2,
            layers: [List.filled(4, 384), List.filled(4, 0), List.filled(4, 0)],
            events: [for (final id in twoDoors ? [1, 2] : [1])
              LiteralFixtureEvent(id: id, x: id - 1, y: 0, pages: [
              LiteralFixtureEventPage(trigger: 1, commands: [
                const LiteralFixtureEventCommand(250, [LiteralFixtureObject('RPG::AudioFile', {
                  '@name': 'Door', '@volume': 80, '@pitch': 100,
                })]),
                LiteralFixtureEventCommand(223, [_tone(-255), 6]),
                const LiteralFixtureEventCommand(106, [8]),
                const LiteralFixtureEventCommand(201, [0, 8, 1, 1, 8, 1]),
                LiteralFixtureEventCommand(223, [_tone(0), 6]),
                const LiteralFixtureEventCommand(0, []),
              ]),
            ])]),
        LiteralFixtureMap(id: 8, width: 2, height: 2,
            layers: [List.filled(4, 384), List.filled(4, 0), List.filled(4, 0)]),
      ], extraFiles: {
        'Data/map_connections.dat': literalFixtureMarshal(<Object?>[]),
        if (pluginArchive) 'Data/PluginScripts.rxdata': literalFixtureMarshal(['custom behavior']),
        if (plugins) 'Plugins/Custom/main.rb': utf8.encode('uninterpreted custom behavior'),
      });
  final original = fixture.snapshot;
  final snapshot = excludedPaths.isEmpty ? original : SourceSnapshot(
      logicalProjectNamespace: original.logicalProjectNamespace,
      policyHash: original.policyHash, entries: original.entries.where((entry) =>
          !excludedPaths.any((path) => entry.relativePath == path ||
              entry.relativePath.startsWith('$path/'))).toList(),
      diagnostics: original.diagnostics, excludedPaths: excludedPaths,
      profileEvidence: original.profileEvidence, state: original.state);
  final files = LiteralFixtureFiles(snapshot, fixture.sourceBytes);
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot, files: files, interpretationProfile: _profile(exclude),
      includeEventSystem: true, includeConnections: true);
  final maps = {for (final map in source.maps)
    map.map.sourceMapId: MapData(id: 'native_${map.map.sourceMapId}',
        name: map.map.name, size: GridSize(width: map.map.width, height: map.map.height))};
  final analysis = SourceEventAnalyzer.forProject(source,
      profile: SourceEventProfile.forProject(source)).analyze();
  final base = NativeProjectDraft(source: source, projectName: 'Plugin policy fixture',
      parentPath: '/private/tmp', folderName: 'Plugin policy fixture',
      mapIds: {for (final entry in maps.entries) entry.key: entry.value.id},
      artifacts: [], mutations: [], compositionEvidence: const {});
  return (source: source, files: files, maps: maps, analysis: analysis, base: base);
}

Future<SourceEventExecutionContext> _context(
    ({NormalizedSourceProject source, LiteralFixtureFiles files,
    Map<int, MapData> maps, SourceEventAnalysis analysis, NativeProjectDraft base}) fixture) async {
  final programs = sourceStaticDoorPrograms(source: fixture.source, analysis: fixture.analysis);
  expect(programs, hasLength(1));
  return const SourceEventExecutionContextResolver().read(
      source: fixture.source, base: fixture.base, nativeMaps: fixture.maps,
      files: fixture.files, staticDoorProgram: programs.values.single,
      staticDoorAnalysis: fixture.analysis);
}

void main() {
  test('strict default refuses custom plugin inventory and a nonempty archive', () async {
    final context = await _context(await _fixture(exclude: false));
    expect(context.isQualified, isFalse);
    expect(context.refusals, containsAll([
      'sourcePluginInventoryUnsupported', 'sourcePluginRouteContextUnsupported',
    ]));
  });

  test('explicit exclusion admits a sealed static door without importing custom behavior', () async {
    final fixture = await _fixture();
    final context = await _context(fixture);
    expect(context.refusals, isEmpty);
    expect(context.isQualified, isTrue);
    final proof = context.toJson()['proof'] as Map;
    expect(proof['sourcePluginContext'], 'explicitCustomBehaviorExcluded');
    expect(proof['customPluginPolicy'], 'excludeCustomBehavior');
    expect(proof['excludedCustomBehavior'], isA<Map>());
    final inventory = proof['excludedCustomBehavior'] as Map;
    expect(inventory['sourceScriptsExecuted'], 0);
    expect(inventory['pluginBehaviorImported'], isFalse);
    final witness = (proof['witnesses'] as List).cast<Map>()
        .singleWhere((row) => row['relativePath'] == 'Data/PluginScripts.rxdata');
    expect(witness['pluginArchiveEmpty'], isFalse);
    expect(witness['sha256'], isNotEmpty);
  });

  test('the strict policy still admits a plugin-free static door', () async {
    final context = await _context(await _fixture(exclude: false,
        plugins: false, pluginArchive: false));
    expect(context.refusals, isEmpty);
    expect((context.toJson()['proof'] as Map)['sourcePluginContext'],
        'freshEmptyPluginArchiveAndNoPluginFiles');
  });

  test('exclusion accepts a cached nonempty plugin witness for a second door', () async {
    final fixture = await _fixture(twoDoors: true);
    final programs = sourceStaticDoorPrograms(source: fixture.source, analysis: fixture.analysis);
    expect(programs, hasLength(2));
    fixture.files.reads.clear();
    final contexts = await const SourceEventExecutionContextResolver().readTransfers(
        source: fixture.source, base: fixture.base, nativeMaps: fixture.maps,
        files: fixture.files, programs: programs, analysis: fixture.analysis);
    expect(contexts, hasLength(2));
    expect(contexts.values.every((context) => context.isQualified), isTrue,
        reason: contexts.values.map((context) => context.refusals).toString());
    final pluginFile = fixture.source.snapshot.entries.singleWhere((entry) =>
        entry.relativePath == 'Data/PluginScripts.rxdata');
    expect(fixture.files.reads.where((id) => id == pluginFile.fileId), hasLength(1));
  });

  test('exclusion cannot reuse a strict context binding', () async {
    final strict = await _fixture(exclude: false, plugins: false, pluginArchive: false);
    final excluded = await _fixture(plugins: false, pluginArchive: false);
    final context = await _context(excluded);
    expect(context.isQualified, isTrue);
    expect(context.isBoundTo(strict.source, strict.analysis.profile, strict.maps), isFalse);
    expect(context.isBoundTo(excluded.source, excluded.analysis.profile, excluded.maps), isTrue);
  });

  test('exclusion still rejects automatic common event execution', () async {
    final context = await _context(await _fixture(automaticCommon: true));
    expect(context.isQualified, isFalse);
    expect(context.refusals, contains('sourceAutomaticCommonEventUnsupported'));
  });

  for (final path in ['Plugins', 'Data/PluginScripts.rxdata']) {
    test('exclusion requires a complete source inventory for $path', () async {
      final context = await _context(await _fixture(excludedPaths: [path]));
      expect(context.isQualified, isFalse);
      expect(context.refusals, contains(path == 'Plugins'
          ? 'sourcePluginInventoryUnsupported' : 'sourceExecutionWitnessUnavailable'));
    });
  }

  test('exclusion verifies the compiled plugin bytes after inventory', () async {
    final fixture = await _fixture();
    fixture.files.overrides['Data/PluginScripts.rxdata'] = literalFixtureMarshal(['changed']);
    await expectLater(_context(fixture), throwsA(isA<NativeWriteException>()
        .having((error) => error.code, 'code', 'events.execution.witness.changed')));
  });
}
