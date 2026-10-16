import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';
import 'support/source_execution_context_variant.dart';

void main() {
  final root = Platform.environment['AVELUNE_EXTERNAL_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_EXTERNAL_SOURCE_SNAPSHOT'];
  group('closed five-map original execution context', () {
    late NormalizedSourceProject source;
    late SourceFilePort files;
    late Map<int, MapData> maps;
    late NativeProjectDraft base;
    setUpAll(() async {
      final fixture = await readExternalOriginalSource(root!, snapshot!);
      source = fixture.source;
      files = fixture.files;
      maps = {
        for (final ir in source.maps)
          ir.map.sourceMapId: MapData(
              id: 'native_${ir.map.sourceMapId}',
              name: ir.map.name,
              size: GridSize(width: ir.map.width, height: ir.map.height),
              layers: const [])
      };
      base = NativeProjectDraft(
          source: source,
          projectName: 'Closed original context',
          parentPath: Directory.systemTemp.path,
          folderName: 'closed-original-context',
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
    });
    test('five original maps qualify with dormant opaque Electrode controllers',
        () async {
      final audit = auditSourceParallelDormancy(
          source: source, profile: SourceEventProfile.kantoForProject(source));
      expect(audit.isQualified, true, reason: audit.refusals.toString());
      final result = await const SourceEventExecutionContextResolver()
          .read(source: source, base: base, nativeMaps: maps, files: files);
      expect(result.isQualified, true, reason: result.refusals.toString());
      expect(
          result.isBoundTo(
              source, SourceEventProfile.kantoForProject(source), maps),
          true);
      expect(result.supportsRouteBarrierOnSourceMap(100), true);
      expect(result.supportsRouteBarrierOnSourceMap(102), true);
      final proof = result.toJson()['proof'] as Map;
      expect(
          (proof['parallelDormancy'] as Map)['controllerEventIds'], [14, 15]);
      expect((proof['parallelDormancy'] as Map)['nativeControllerExecution'],
          false);
      expect(
          (proof['parallelDormancy'] as Map)['nativeSourceWritesToControllerA'],
          isEmpty);
    });
    test(
        'closed native writes remain local and both Centre door programs remain recognized',
        () async {
      final profile = SourceEventProfile.kantoForProject(source);
      final audit =
          auditSourceParallelDormancy(source: source, profile: profile);
      expect(audit.isQualified, true, reason: audit.refusals.toString());
      final writes = (audit.toJson()['nativeWriteSet'] as List).cast<Map>();
      expect(writes, isNotEmpty);
      for (final write in writes
          .where((write) => (write['factId'] as String).contains(':self:'))) {
        expect(write['factId'],
            'source:${source.snapshot.logicalProjectNamespace.value}:map:${write['sourceMapId']}:event:${write['sourceEventId']}:self:A');
        expect(
            write['sourceMapId'] == 205 &&
                [14, 15].contains(write['sourceEventId']),
            false);
      }
      final analysis =
          SourceEventAnalyzer.forProject(source, profile: profile).analyze();
      final doors = sourceDoorEventProjectionCandidates(
          source: source, analysis: analysis);
      expect(
          doors.any(
              (event) => event.sourceMapId == 100 && event.sourceEventId == 8),
          true);
      expect(
          doors.any(
              (event) => event.sourceMapId == 102 && event.sourceEventId == 1),
          true);
      for (final id in [6, 13, 14, 15]) {
        expect(analysis.eventAt(205, id)!.isQuarantined, true);
      }
    });
    for (final mutation in [
      'unguardedController',
      'changedControllerWait',
      'changedSourceWriter',
      'thirdParallel'
    ]) {
      test(
          'freshly reattested $mutation cannot borrow dormant source admission',
          () async {
        final changed = await reattestExecutionVariant(source, files, mutation);
        expect(changed.source.canPlan, true);
        expect(changed.source.snapshot.canonicalHash,
            isNot(source.snapshot.canonicalHash));
        final audit = auditSourceParallelDormancy(
            source: changed.source,
            profile: SourceEventProfile.kantoForProject(changed.source));
        expect(audit.isQualified, false, reason: mutation);
        expect(audit.refusals, isNotEmpty);
        if (mutation == 'thirdParallel') {
          expect(audit.refusals, contains('sourceDormancyUnexpectedParallel'));
        }
      });
    }
    test(
        'initial facts and imported checkpoints cannot make the fresh context executable',
        () async {
      for (final failure in ['fact', 'checkpoint']) {
        final mutated = NativeProjectDraft(
            source: source,
            projectName: base.projectName,
            parentPath: base.parentPath,
            folderName: base.folderName,
            mapIds: base.mapIds,
            artifacts: base.artifacts,
            mutations: [
              ...base.mutations,
              NativeMutation(
                  operationId: ConverterId('initial_fact'),
                  actionId:
                      failure == 'fact' ? 'fact.create' : 'game_save.import',
                  sourceEntityIds: const [],
                  targetEntityIds: [ConverterId('controllerA')],
                  parameters: {'value': true})
            ]);
        final context = await const SourceEventExecutionContextResolver().read(
            source: source, base: mutated, nativeMaps: maps, files: files);
        expect(context.isQualified, false);
        expect(
            context.refusals,
            contains(failure == 'fact'
                ? 'sourceExecutionBaseUnsupported'
                : 'sourceCheckpointImportUnsupported'));
      }
    });
    test(
        'a newly sealed source invalidates the previous context and keeps third parallels refused',
        () async {
      final context = await const SourceEventExecutionContextResolver()
          .read(source: source, base: base, nativeMaps: maps, files: files);
      expect(context.isQualified, true);
      final changed =
          await reattestExecutionVariant(source, files, 'thirdParallel');
      expect(
          context.isBoundTo(changed.source,
              SourceEventProfile.kantoForProject(changed.source), maps),
          false);
      final changedBase = NativeProjectDraft(
          source: changed.source,
          projectName: base.projectName,
          parentPath: base.parentPath,
          folderName: base.folderName,
          mapIds: base.mapIds,
          artifacts: base.artifacts,
          mutations: base.mutations);
      final rejected = await const SourceEventExecutionContextResolver().read(
          source: changed.source,
          base: changedBase,
          nativeMaps: maps,
          files: changed.files);
      expect(rejected.refusals, contains('sourceParallelEventUnsupported'));
      expect(rejected.refusals, contains('sourceParallelDormancyUnqualified'));
      expect(rejected.refusals, contains('sourceExecutionWitnessUnqualified'));
    });
  },
      skip: root == null || snapshot == null
          ? 'Original complete source required.'
          : false);
}
