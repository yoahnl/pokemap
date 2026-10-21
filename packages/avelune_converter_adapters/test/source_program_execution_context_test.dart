import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_adapters/src/source_event_evidence.dart';
import 'package:avelune_converter_adapters/src/source_transfer_program_authority.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<LiteralTileFixture> _fixture({
  bool localParallel = false,
  bool localAutonomy = false,
  bool retained = false,
  bool remoteWriter = false,
}) =>
    LiteralTileFixture.create(
      namespace: 'bounded-program-context',
      interpretationProfile: syntheticSourceInterpretationProfile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      extraFiles: {
        'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = TestPlayer\n'),
        'Graphics/Characters/TestPlayer.png': image
            .encodePng(image.Image(width: 128, height: 192, numChannels: 4)),
        'Data/map_metadata.dat': literalFixtureMarshal(<Object?, Object?>{}),
        'Data/map_connections.dat': literalFixtureMarshal([
          if (retained) [1, 'E', 0, 2, 'W', 0],
        ]),
      },
      maps: [
        LiteralFixtureMap(id: 1, events: [
          for (final id in [1, 3])
            LiteralFixtureEvent(id: id, x: id == 1 ? 0 : 2, y: 0, pages: const [
              LiteralFixtureEventPage(trigger: 1, commands: [
                LiteralFixtureEventCommand(106, [1]),
                LiteralFixtureEventCommand(0, []),
              ]),
            ]),
          LiteralFixtureEvent(id: 2, x: 1, y: 0, pages: [
            LiteralFixtureEventPage(
                trigger: 4,
                selfSwitch: localParallel ? null : 'C',
                moveType: localAutonomy ? 3 : 0,
                autonomousRouteCodes: localAutonomy ? const [45, 0] : const [0],
                commands: const [
                  LiteralFixtureEventCommand(355, ['opaque_controller()']),
                  LiteralFixtureEventCommand(0, []),
                ]),
            const LiteralFixtureEventPage(selfSwitch: 'D', commands: []),
          ]),
        ]),
        LiteralFixtureMap(id: 2, events: [
          const LiteralFixtureEvent(id: 1, x: 0, y: 0, pages: [
            LiteralFixtureEventPage(
                trigger: 4,
                moveType: 3,
                autonomousRouteCodes: [
                  45,
                  0
                ],
                commands: [
                  LiteralFixtureEventCommand(
                      355, ['opaque_remote_controller()']),
                  LiteralFixtureEventCommand(0, []),
                ]),
          ]),
          if (remoteWriter)
            const LiteralFixtureEvent(id: 2, x: 1, y: 0, pages: [
              LiteralFixtureEventPage(commands: [
                LiteralFixtureEventCommand(
                    355, ['pbSetSelfSwitch(2,"C",true,1)']),
                LiteralFixtureEventCommand(0, []),
              ]),
            ]),
        ]),
      ],
    );

Future<NormalizedSourceProject> _source(LiteralTileFixture fixture) =>
    const RmxpSourceNormalizer().normalize(
      snapshot: fixture.snapshot,
      files: fixture.files,
      interpretationProfile: syntheticSourceInterpretationProfile,
      includeEventSystem: true,
      includeConnections: true,
    );

Map<int, MapData> _maps(NormalizedSourceProject source) => {
      for (final map in source.maps)
        map.map.sourceMapId: MapData(
            id: 'native_${map.map.sourceMapId}',
            name: map.map.name,
            size: GridSize(width: map.map.width, height: map.map.height),
            layers: const []),
    };

NativeProjectDraft _base(
        NormalizedSourceProject source, Map<int, MapData> maps) =>
    NativeProjectDraft(
        source: source,
        projectName: 'Bounded programs',
        parentPath: '/private/tmp',
        folderName: 'unused-bounded-programs',
        mapIds: {
          for (final entry in maps.entries) entry.key: entry.value.id
        },
        artifacts: const [],
        mutations: [
          for (final entry in maps.entries)
            NativeMutation(
                operationId: ConverterId('map_${entry.key}'),
                actionId: 'map.save',
                sourceEntityIds: [source.mapIdentity(entry.key)],
                targetEntityIds: [ConverterId(entry.value.id)],
                parameters: {'map': entry.value.toJson()}),
        ]);

void main() {
  test(
      'program contexts preserve the global refusal and bind exact owners and all native maps',
      () async {
    final fixture = await _fixture();
    final source = await _source(fixture);
    final maps = _maps(source);
    final base = _base(source, maps);
    final authority = SourceTransferProgramAuthority.forSource(source);
    final analysis = authority.analysis;
    final programs = sourceSequencePrograms(source: source, analysis: analysis);
    expect(programs, hasLength(2));
    final global = await const SourceEventExecutionContextResolver().read(
        source: source,
        base: base,
        nativeMaps: maps,
        files: fixture.files,
        authority: authority);
    expect(global.isQualified, isFalse);
    expect(global.refusals, contains('sourceParallelEventUnsupported'));
    final contexts = await const SourceEventExecutionContextResolver()
        .readProgramContexts(
            source: source,
            base: base,
            nativeMaps: maps,
            files: fixture.files,
            analysis: analysis,
            eventIdentities: programs.keys.toSet(),
            sequencePrograms: programs,
            authority: authority);
    expect(authority.analysisComputationCount, 1);
    final first = analysis.eventAt(1, 1)!, other = analysis.eventAt(1, 3)!;
    final context = contexts[first.identity]!;
    expect(context.isQualified, isTrue, reason: '${context.refusals}');
    expect(context.programIdentity, first.identity);
    expect(context.programSourceMapIds, {1});
    expect(context.mapIds.keys, {1, 2});
    expect(context.isBoundTo(source, analysis.profile, maps), isTrue);
    expect(
        context.supportsRouteBarrierOnSourceMap(1,
            eventIdentity: first.identity),
        isTrue);
    expect(
        context.supportsRouteBarrierOnSourceMap(2,
            eventIdentity: first.identity),
        isFalse);
    expect(
        context.supportsRouteBarrierOnSourceMap(1,
            eventIdentity: other.identity),
        isFalse);
    expect(context.supportsRouteBarrierOnSourceMap(1), isFalse);
    final encoding = SourceEventEvidenceEncoding(
        enabled: true, limits: const NativeWriteLimits());
    final originals =
        contexts.values.map((context) => context.toJson()).toList();
    final encoded = originals.map(encoding.encodeContext).toList();
    final restored = SourceEventEvidenceEncoding.restoreContexts(
        encoded, encoding.tables!,
        limits: const NativeWriteLimits());
    expect(canonicalJsonOf(restored), canonicalJsonOf(originals));
    expect((encoding.tables!['nativeBindings'] as Map), hasLength(1));
    SourceEventProjection project(
            Map<ConverterId, SourceEventExecutionContext> supplied,
            {SourceEventExecutionContext? generic}) =>
        const SourceEventProjector().project(
            source: source,
            analysis: analysis,
            nativeMaps: maps,
            programContexts: supplied,
            executionContext: generic,
            retentionPolicy: MapInstanceRetentionPolicy(
                viewportWidthTiles: 16,
                viewportHeightTiles: 12,
                marginTiles: 6));
    final swapped = project({other.identity: context});
    expect(
        (swapped.semanticEvidence['events'] as List).cast<Map>().singleWhere(
            (row) => row['sourceIdentity'] == other.identity.value)['status'],
        'quarantinedWholeEvent');
    final generic = project({}, generic: context);
    expect(
        (generic.semanticEvidence['events'] as List)
            .cast<Map>()
            .where((row) =>
                row['locator']['mapId'] == 1 && row['locator']['eventId'] != 2)
            .every((row) => row['status'] == 'quarantinedWholeEvent'),
        isTrue);
    maps[2] = maps[2]!.copyWith(name: 'Changed remote map');
    expect(context.isBoundTo(source, analysis.profile, maps), isFalse);
    final changed = project(contexts);
    expect(
        (changed.semanticEvidence['events'] as List).cast<Map>().singleWhere(
            (row) => row['sourceIdentity'] == first.identity.value)['status'],
        'quarantinedWholeEvent');
  });

  for (final variant in ['parallel', 'autonomy', 'retained', 'writer']) {
    test('bounded programs retain refusal for $variant interference', () async {
      final fixture = await _fixture(
          localParallel: variant == 'parallel',
          localAutonomy: variant == 'autonomy',
          retained: variant == 'retained',
          remoteWriter: variant == 'writer');
      final source = await _source(fixture), maps = _maps(source);
      final authority = SourceTransferProgramAuthority.forSource(source);
      final analysis = authority.analysis;
      final programs =
          sourceSequencePrograms(source: source, analysis: analysis);
      final contexts = await const SourceEventExecutionContextResolver()
          .readProgramContexts(
              source: source,
              base: _base(source, maps),
              nativeMaps: maps,
              files: fixture.files,
              analysis: analysis,
              eventIdentities: programs.keys.toSet(),
              sequencePrograms: programs,
              authority: authority);
      expect(contexts, hasLength(2));
      for (final context in contexts.values) {
        expect(context.isQualified, isFalse);
        expect(
            context.refusals,
            contains(variant == 'autonomy'
                ? 'sourceMapAutonomyContextUnsupported'
                : 'sourceParallelDormancyUnqualified'));
      }
    });
  }

  test('unqualified event identities cannot obtain a bounded program context',
      () async {
    final fixture = await _fixture();
    final source = await _source(fixture), maps = _maps(source);
    final authority = SourceTransferProgramAuthority.forSource(source);
    await expectLater(
        const SourceEventExecutionContextResolver().readProgramContexts(
            source: source,
            base: _base(source, maps),
            nativeMaps: maps,
            files: fixture.files,
            analysis: authority.analysis,
            eventIdentities: {source.eventIdentity(2, 1)},
            authority: authority),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'events.program.binding')));
  });

  test(
      'automatic composition qualifies local finite programs despite remote opaque producers',
      () async {
    final fixture = await _fixture();
    final source = await _source(fixture);
    final literal = await const LiteralTileComposer().compose(
        source: source,
        files: fixture.files,
        selectedSourceMapIds: [1, 2],
        projectName: 'Bounded programs',
        parentPath: '/private/tmp',
        folderName: 'unused-bounded-programs');
    final semantic = (await const SourceSemanticStudyComposer()
        .compose(source: source, base: literal, files: fixture.files))!;
    final composed = (await const SourceEventStudyComposer()
        .compose(source: source, base: semantic, files: fixture.files))!;
    final rows =
        (composed.projection.semanticEvidence['events'] as List).cast<Map>();
    for (final id in [1, 3]) {
      final row = rows.singleWhere((row) =>
          row['locator']['mapId'] == 1 && row['locator']['eventId'] == id);
      expect(row['gaps'], isEmpty);
      expect(row['status'], 'adaptedStaticSemantics');
    }
    final remote = rows.singleWhere((row) => row['locator']['mapId'] == 2);
    expect(remote['status'], 'quarantinedWholeEvent');
    expect(composed.projection.allEnabledOriginalEventsHaveExecutionContext,
        isTrue);
  });
}
