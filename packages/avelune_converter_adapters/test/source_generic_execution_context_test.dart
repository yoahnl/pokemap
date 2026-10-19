import 'dart:io';
import 'dart:typed_data';

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
        bool twoDoors = false,
        bool remoteParallel = false,
        bool remoteWriter = false,
        bool remoteDoorTarget = false,
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
              ]),
            if (twoDoors)
              for (var index = 0; index < 2; index++)
                LiteralFixtureEvent(id: map + 5 + index, x: index + 1, y: 0,
                    pages: [LiteralFixtureEventPage(trigger: 1, commands: [
                      const LiteralFixtureEventCommand(250, [LiteralFixtureObject('RPG::AudioFile',
                        {'@name': 'Exit Door', '@volume': 80, '@pitch': 100})]),
                      LiteralFixtureEventCommand(223, [_tone(-255), 0]),
                      const LiteralFixtureEventCommand(106, [1]),
                      LiteralFixtureEventCommand(201, [0,
                        remoteDoorTarget && index == 1 ? map + 100 : map, 1, 0, 0, 0]),
                      LiteralFixtureEventCommand(223, [_tone(0), 0]),
                      const LiteralFixtureEventCommand(0, []),
                    ])])
          ]),
          if (remoteParallel || remoteWriter)
            LiteralFixtureMap(id: map + 100, events: [
              if (remoteParallel)
                LiteralFixtureEvent(id: 1, x: 0, y: 0, pages: const [
                  LiteralFixtureEventPage(trigger: 4, commands: [
                    LiteralFixtureEventCommand(355, ['opaque_remote_controller()']),
                    LiteralFixtureEventCommand(0, [])])]),
              if (remoteWriter)
                LiteralFixtureEvent(id: 2, x: 1, y: 0, pages: [
                  LiteralFixtureEventPage(commands: [
                    LiteralFixtureEventCommand(355,
                        ['pbSetSelfSwitch(${map + 3},"C",true,$map)']),
                    const LiteralFixtureEventCommand(0, [])])]),
            ])
        ]);

LiteralFixtureUserDefined _tone(double channel) {
  final bytes = ByteData(32);
  for (var index = 0; index < 3; index++) {
    bytes.setFloat64(index * 8, channel, Endian.little);
  }
  return LiteralFixtureUserDefined('Tone', bytes.buffer.asUint8List());
}

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
  test('local dormancy scopes retain remote native writers and reject unsafe destinations', () async {
    for (final remoteWriter in [false, true]) {
      final fixture = await _fixture(83, twoDoors: true,
          remoteParallel: !remoteWriter, remoteWriter: remoteWriter,
          remoteDoorTarget: !remoteWriter);
      final source = await _source(fixture);
      final profile = SourceEventProfile.forProject(source);
      final auditor = SourceParallelDormancyAuditor.forProject(source, profile: profile);
      expect(auditor.audit().isQualified, isFalse);
      final local = auditor.audit(activeSourceMapIds: {83});
      expect(local.activeSourceMapIds, {83});
      expect(local.isQualified, !remoteWriter, reason: local.refusals.toString());
      expect(local.permitsDormantParallelPage(183, 86,
          source.maps.first.map.events.first.pages.first), isFalse);
      expect(() => local.activeSourceMapIds.add(183), throwsUnsupportedError);
      expect(auditor.audit(activeSourceMapIds: {999}).isQualified, isFalse);
      final analysis = SourceEventAnalyzer.forProject(source, profile: profile).analyze();
      final programs = sourceStaticDoorPrograms(source: source, analysis: analysis);
      expect(programs, hasLength(2));
      final maps = {for (final map in source.maps)
        map.map.sourceMapId: MapData(id: 'native_${map.map.sourceMapId}', name: map.map.name,
            size: GridSize(width: map.map.width, height: map.map.height), layers: const [])};
      final base = NativeProjectDraft(source: source, projectName: 'Scoped doors',
          parentPath: Directory.systemTemp.path, folderName: 'scoped-doors',
          mapIds: {for (final entry in maps.entries) entry.key: entry.value.id},
          artifacts: const [], mutations: [for (final entry in maps.entries)
            NativeMutation(operationId: ConverterId('map_${entry.key}'), actionId: 'map.save',
                sourceEntityIds: const [], targetEntityIds: [ConverterId(entry.value.id)],
                parameters: {'mapId': entry.value.id, 'map': entry.value.toJson()})]);
      final omittedActors = SourceEventAnalysis(profile: profile,
          events: analysis.events.where((event) => programs.containsKey(event.identity)).toList(),
          diagnostics: const []);
      final batch = await const SourceEventExecutionContextResolver().readStaticTransfers(
          source: source, base: base, nativeMaps: maps, files: fixture.files,
          programs: programs, analysis: omittedActors);
      for (final entry in programs.entries) {
        final single = await const SourceEventExecutionContextResolver().read(
            source: source, base: base, nativeMaps: maps, files: fixture.files,
            staticDoorProgram: entry.value, staticDoorAnalysis: analysis);
        expect(batch[entry.key]!.toJson(), single.toJson());
        expect(single.isQualified, !remoteWriter && entry.value.targetSourceMapId == 83,
            reason: single.refusals.toString());
      }
      if (remoteWriter) {
        expect(local.refusals, contains('sourceDormancyControllerWriterExecutable'));
      }
    }
  });
  test('batched doors retain independent source dormancy proofs and refusals', () async {
    for (final (writer, unguarded) in [(false, false), (true, false), (false, true)]) {
      final fixture = await _fixture(83, writer: writer, unguarded: unguarded, twoDoors: true);
      final source = await _source(fixture);
      final analysis = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source)).analyze();
      final programs = sourceStaticDoorPrograms(source: source, analysis: analysis);
      expect(programs, hasLength(2));
      final maps = {83: MapData(id: 'native_83', name: 'Native test map',
          size: const GridSize(width: 3, height: 1), layers: const [])};
      final base = NativeProjectDraft(source: source, projectName: 'Door proof',
          parentPath: Directory.systemTemp.path, folderName: 'door-proof',
          mapIds: const {83: 'native_83'}, artifacts: const [], mutations: [
            NativeMutation(operationId: ConverterId('map_83'), actionId: 'map.save',
                sourceEntityIds: const [], targetEntityIds: [ConverterId('native_83')],
                parameters: {'mapId': 'native_83', 'map': maps[83]!.toJson()})]);
      final omittedActors = SourceEventAnalysis(profile: analysis.profile,
          events: analysis.events.where((event) => programs.containsKey(event.identity)).toList(),
          diagnostics: const []);
      final batch = await const SourceEventExecutionContextResolver().readStaticTransfers(
          source: source, base: base, nativeMaps: maps, files: fixture.files,
          programs: programs, analysis: omittedActors);
      for (final entry in programs.entries) {
        final individual = await const SourceEventExecutionContextResolver().read(
            source: source, base: base, nativeMaps: maps, files: fixture.files,
            staticDoorProgram: entry.value, staticDoorAnalysis: analysis);
        expect(batch[entry.key]!.toJson(), individual.toJson());
        expect(batch[entry.key]!.isQualified, !writer && !unguarded,
            reason: batch[entry.key]!.refusals.toString());
      }
      final changed = _ChangedFiles(fixture.files, source.maps.single.map.sourceFileId);
      await expectLater(const SourceEventExecutionContextResolver().readStaticTransfers(
          source: source, base: base, nativeMaps: maps, files: changed,
          programs: programs, analysis: analysis),
          throwsA(isA<NativeWriteException>().having((error) => error.code,
              'code', 'events.execution.witness.changed')));
    }
  });
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
