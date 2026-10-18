import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<LiteralTileFixture> _fixture(int map,
        {bool writer = false,
        bool unguarded = false,
        Map<String, List<int>> extra = const {}}) =>
    LiteralTileFixture.create(
        namespace: 'generic-context-$map',
        scriptsBytes: syntheticInterpretationArchive,
        interpretationProfile: syntheticSourceInterpretationProfile,
        includeEventSystem: true,
        extraFiles: {
          'Data/map_connections.dat': literalFixtureMarshal([]),
          ...extra
        },
        maps: [
          LiteralFixtureMap(id: map, events: [
            LiteralFixtureEvent(
                id: map + 3,
                x: 0,
                y: 0,
                name: 'Dormant device $map',
                pages: [
                  LiteralFixtureEventPage(
                      trigger: 4,
                      selfSwitch: unguarded ? null : 'C',
                      commands: const [
                        LiteralFixtureEventCommand(
                            355, ['opaque_controller()']),
                        LiteralFixtureEventCommand(0, [])
                      ]),
                  const LiteralFixtureEventPage(
                      selfSwitch: 'D',
                      commands: [LiteralFixtureEventCommand(0, [])])
                ]),
            if (writer)
              LiteralFixtureEvent(id: map + 4, x: 1, y: 0, pages: [
                LiteralFixtureEventPage(commands: [
                  LiteralFixtureEventCommand(
                      355, ['pbSetSelfSwitch(${map + 3},"C",true)']),
                  const LiteralFixtureEventCommand(0, [])
                ])
              ])
          ])
        ]);

Future<NormalizedSourceProject> _source(LiteralTileFixture fixture) =>
    const RmxpSourceNormalizer().normalize(
        snapshot: fixture.snapshot,
        files: fixture.files,
        includeEventSystem: true,
        includeConnections: true,
        interpretationProfile: syntheticSourceInterpretationProfile);

Future<SourceEventExecutionContext> _context(
    NormalizedSourceProject source, SourceFilePort files) {
  final maps = {
    for (final ir in source.maps)
      ir.map.sourceMapId: MapData(
          id: 'native_${ir.map.sourceMapId}',
          name: ir.map.name,
          size: GridSize(width: ir.map.width, height: ir.map.height),
          layers: const [])
  };
  final base = NativeProjectDraft(
      source: source,
      projectName: 'Generic context',
      parentPath: Directory.systemTemp.path,
      folderName: 'generic-context',
      mapIds: {
        for (final entry in maps.entries) entry.key: entry.value.id
      },
      artifacts: const [],
      mutations: [
        for (final entry in maps.entries)
          NativeMutation(
              operationId: ConverterId('map_${entry.key}'),
              actionId: 'map.save',
              sourceEntityIds: const [],
              targetEntityIds: [
                ConverterId(entry.value.id)
              ],
              parameters: {
                'mapId': entry.value.id,
                'map': entry.value.toJson()
              })
      ]);
  return const SourceEventExecutionContextResolver()
      .read(source: source, base: base, nativeMaps: maps, files: files);
}

final class _ChangedFiles implements SourceFilePort {
  _ChangedFiles(this.original, this.changed);
  final SourceFilePort original;
  final ConverterId changed;
  @override
  Future<List<int>> read(ConverterId id) async =>
      [...await original.read(id), if (id == changed) 0];
}

void main() {
  test('excluded optional execution archives are unknown rather than absent',
      () async {
    for (final excluded in [
      'Data/PluginScripts.rxdata',
      'Data/CommonEvents.rxdata'
    ]) {
      final fixture = await _fixture(67);
      final sealed = fixture.snapshot;
      final snapshot = SourceSnapshot(
          logicalProjectNamespace: sealed.logicalProjectNamespace,
          policyHash: sealed.policyHash,
          entries: sealed.entries,
          diagnostics: sealed.diagnostics,
          excludedPaths: [excluded],
          profileEvidence: sealed.profileEvidence,
          state: sealed.state);
      final source = await const RmxpSourceNormalizer().normalize(
          snapshot: snapshot,
          files: fixture.files,
          includeEventSystem: true,
          includeConnections: true,
          interpretationProfile: syntheticSourceInterpretationProfile);
      final context = await _context(source, fixture.files);
      expect(context.isQualified, isFalse);
      expect(context.refusals, contains('sourceExecutionWitnessUnavailable'));
    }
  });
  final pluginArchivePath =
      Platform.environment['AVELUNE_EXECUTION_PLUGIN_ARCHIVE_PATH'];
  test(
      'an explicit executable plugin oracle is refused independently of declared program identities',
      () async {
    final bytes = await File(pluginArchivePath!).readAsBytes();
    final fixture =
        await _fixture(53, extra: {'Data/PluginScripts.rxdata': bytes});
    final context = await _context(await _source(fixture), fixture.files);
    expect(context.isQualified, isFalse);
    expect(context.refusals, ['sourcePluginRouteContextUnsupported']);
    final sealed = fixture.snapshot.entries.singleWhere(
        (entry) => entry.relativePath == 'Data/PluginScripts.rxdata');
    expect(sealed.sha256, literalFixtureHash(bytes));
  }, skip: pluginArchivePath == null);
  test('fresh contexts and dormant guards follow two relocated projects',
      () async {
    for (final map in [7, 83]) {
      final fixture = await _fixture(map);
      final source = await _source(fixture);
      final profile = SourceEventProfile.forProject(source);
      final audit =
          auditSourceParallelDormancy(source: source, profile: profile);
      expect(audit.isQualified, isTrue, reason: audit.refusals.toString());
      expect(
          audit.permitsDormantParallelPage(
              map, map + 3, source.maps.single.map.events.first.pages.first),
          isTrue);
      expect(
          audit.permitsDormantParallelPage(map + 1, map + 3,
              source.maps.single.map.events.first.pages.first),
          isFalse);
      final context = await _context(source, fixture.files);
      expect(context.isQualified, isTrue, reason: context.refusals.toString());
      expect(context.supportsRouteBarrierOnSourceMap(map), isTrue);
      expect(context.supportsRouteBarrierOnSourceMap(map + 1), isFalse);
    }
  });
  test(
      'executable cross event writers and unguarded parallel pages refuse dormancy',
      () async {
    for (final variant in [(true, false), (false, true)]) {
      final fixture =
          await _fixture(17, writer: variant.$1, unguarded: variant.$2);
      final source = await _source(fixture);
      final audit = auditSourceParallelDormancy(
          source: source, profile: SourceEventProfile.forProject(source));
      expect(audit.isQualified, isFalse);
      final context = await _context(source, fixture.files);
      expect(context.isQualified, isFalse);
      expect(context.refusals, contains('sourceParallelDormancyUnqualified'));
    }
  });
  test(
      'empty plugin archives qualify but executable plugins and automatic common events refuse',
      () async {
    for (final variant in ['empty', 'plugin', 'inventory', 'common']) {
      final fixture = await _fixture(29, extra: {
        'Data/PluginScripts.rxdata': literalFixtureMarshal(
            variant == 'plugin' ? ['untrusted executable'] : []),
        'Data/CommonEvents.rxdata': literalFixtureMarshal([
          null,
          if (variant == 'common')
            const LiteralFixtureObject('RPG::CommonEvent', {
              '@id': 1,
              '@name': 'Automatic job',
              '@trigger': 1,
              '@switch_id': 1,
              '@list': [
                LiteralFixtureObject('RPG::EventCommand',
                    {'@code': 0, '@indent': 0, '@parameters': <Object?>[]})
              ]
            })
        ]),
        if (variant == 'inventory') 'Plugins/unknown.rb': [35, 35],
      });
      final source = await _source(fixture);
      expect(source.canPlan, isTrue,
          reason: '$variant ${source.diagnostics.map((d) => d.toJson())}');
      final context = await _context(source, fixture.files);
      expect(context.isQualified, variant == 'empty',
          reason: context.refusals.toString());
      if (variant == 'plugin') {
        expect(
            context.refusals, contains('sourcePluginRouteContextUnsupported'));
      }
      if (variant == 'inventory') {
        expect(context.refusals, contains('sourcePluginInventoryUnsupported'));
      }
      if (variant == 'common') {
        expect(context.refusals,
            contains('sourceAutomaticCommonEventUnsupported'));
      }
    }
  });
  test(
      'a fresh witness read rejects changed map bytes after the sealed inventory',
      () async {
    final fixture = await _fixture(41);
    final source = await _source(fixture);
    final id = source.maps.single.map.sourceFileId;
    await expectLater(
        _context(source, _ChangedFiles(fixture.files, id)),
        throwsA(isA<NativeWriteException>().having(
            (e) => e.code, 'code', 'events.execution.witness.changed')));
  });
}
