import 'dart:io';
import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/source_external_projection_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_EXTERNAL_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_EXTERNAL_SOURCE_SNAPSHOT'];
  group('original five-map external transition composition', () {
    late SourceEventStudyComposition result;
    late Directory output;
    setUpAll(() async {
      output =
          await Directory.systemTemp.createTemp('source-six-native-warps-');
      result = await composeExternalOriginalSource(
          sourceRoot: root!,
          snapshotPath: snapshot!,
          outputParentPath: output.path,
          onStage: (stage, ms) {
            final path = Platform.environment['AVELUNE_EXTERNAL_STAGE_TIMINGS'];
            if (path != null) {
              File(path).writeAsStringSync(
                  '${jsonEncode({'stage': stage, 'elapsedMs': ms})}\n',
                  mode: FileMode.append);
            }
          });
      final path = Platform.environment['AVELUNE_EXTERNAL_COMPOSITION_RESULT'];
      if (path != null) {
        File(path).writeAsStringSync(jsonEncode({
          'sourceSnapshotHash':
              result.draft.source.snapshot.canonicalHash.value,
          'mapIds': {
            for (final entry in result.draft.mapIds.entries)
              '${entry.key}': entry.value
          },
          'qualifiedEventCount':
              result.projection.semanticEvidence['qualifiedEventCount'],
          'quarantinedEventCount':
              result.projection.semanticEvidence['quarantinedEventCount'],
          'events': result.projection.semanticEvidence['events'],
          'externalWarps': (result.draft.compositionEvidence['sourceEvents']
              as Map)['externalWarps'],
          'mutationCount': result.draft.mutations.length,
          'artifactCount': result.draft.artifacts.length,
          'mutationActions': [
            for (final mutation in result.draft.mutations) mutation.actionId
          ],
        }));
      }
    });
    tearDownAll(() async {
      if (await output.exists()) await output.delete(recursive: true);
    });
    test(
        'six real transfers use native presentation while unrelated factory content remains quarantined',
        () {
      final rows =
          (result.projection.semanticEvidence['events'] as List).cast<Map>();
      for (final pair in [
        (100, 6),
        (100, 7),
        (100, 13),
        (166, 1),
        (205, 2),
        (205, 4)
      ]) {
        final id = result.draft.source.eventIdentity(pair.$1, pair.$2).value;
        final row = rows.singleWhere((row) => row['sourceIdentity'] == id);
        expect(row['status'], 'adaptedStaticSemantics',
            reason: '$pair ${row['gaps']}');
        final scene = result.projection.scenes.singleWhere((scene) =>
            scene.metadata['sourceEventIdentity'] == id &&
            scene.metadata['sourcePageIndex'] == '0');
        final warp = scene.graph.nodes
            .map((node) => node.payload)
            .whereType<SceneActionPayload>()
            .map((payload) => payload.interactiveCommand)
            .whereType<SceneWarpInteractiveCommand>()
            .single;
        expect(warp.presentation, isNotNull);
      }
      for (final event in result.draft.source.maps
          .where((map) => const {166, 205}.contains(map.map.sourceMapId))
          .expand((map) =>
              map.map.events.map((event) => (map.map.sourceMapId, event)))) {
        if (const [(166, 1), (205, 2), (205, 4)]
            .contains((event.$1, event.$2.sourceEventId))) {
          continue;
        }
        final id = result.draft.source
            .eventIdentity(event.$1, event.$2.sourceEventId)
            .value;
        expect(rows.singleWhere((row) => row['sourceIdentity'] == id)['status'],
            'quarantinedWholeEvent');
        expect(
            result.projection.scenes
                .where((scene) => scene.metadata['sourceEventIdentity'] == id),
            isEmpty);
        expect(
            result.projection.nativeMaps[event.$1]!.entities.where(
                (entity) => entity.properties['sourceEventIdentity'] == id),
            isEmpty);
      }
    });
    test(
        'normal composer binds the two exact images and sound before every scene consumer',
        () {
      final evidence = (result.draft.compositionEvidence['sourceEvents']
          as Map)['externalWarps'] as Map;
      expect(evidence['policy'], 'nativeTransitionsWithoutEscapeState');
      expect(evidence['sourceScriptsExecuted'], 0);
      expect(evidence['fullSourceParityQualified'], false);
      expect(evidence['sourceEscapePoint'], 'notImported');
      expect(evidence['sourceDarkMapMask'], 'notImported');
      expect(evidence['programs'], hasLength(6));
      expect(evidence['illustrations'], hasLength(2));
      final imports = result.draft.mutations
          .where((mutation) =>
              mutation.operationId.value.startsWith('source_warp_'))
          .toList();
      expect(imports.map((mutation) => mutation.actionId), [
        'tileset.import_image',
        'tileset.import_image',
        'element_category.upsert',
        'element.upsert',
        'element.upsert'
      ]);
      for (final sha in [
        '59363afc47d23f051b18ae471e9d6670790316f0ad0140a3fa16c1e1d8646c13',
        '0348feae8e4da3cd8f9e7948c029c84198df1e59931a6f27cad9657f4148cdc8'
      ]) {
        expect(
            result.draft.artifacts
                .where((artifact) => artifact.rawSha256.value == sha),
            hasLength(1));
      }
      for (final mutation in imports.take(2)) {
        expect(mutation.parameters['tileWidth'], 512);
        expect(mutation.parameters['tileHeight'], 384);
        expect(
            result.draft.artifacts.where((artifact) =>
                artifact.handle == mutation.parameters['artifactHandle']),
            hasLength(1));
      }
      final firstMap = result.draft.mutations.indexWhere((mutation) =>
          mutation.actionId == 'map.create' || mutation.actionId == 'map.save');
      for (final mutation in imports) {
        expect(result.draft.mutations.indexOf(mutation), lessThan(firstMap));
      }
      for (final scene in result.projection.scenes.where((scene) =>
          scene.graph.nodes.any((node) =>
              node.payload is SceneActionPayload &&
              (node.payload as SceneActionPayload).interactiveCommand
                  is SceneWarpInteractiveCommand))) {
        final consumer = result.draft.mutations.indexWhere((mutation) =>
            mutation.actionId == 'scene.upsert' &&
            (mutation.parameters['scene'] as Map)['id'] == scene.id);
        expect(consumer, greaterThan(firstMap));
        for (final mutation in imports) {
          expect(result.draft.mutations.indexOf(mutation), lessThan(consumer));
        }
        for (final command in scene.graph.nodes
            .map((node) => node.payload)
            .whereType<SceneActionPayload>()
            .map((action) => action.interactiveCommand)
            .whereType<ScenePlaySoundEffectInteractiveCommand>()) {
          final sound = result.draft.mutations.indexWhere((mutation) =>
              mutation.actionId == 'scene.dialogue.audioMedia.import' &&
              mutation.parameters['mediaId'] == command.mediaAssetId);
          expect(sound, greaterThanOrEqualTo(0));
          expect(sound, lessThan(consumer));
        }
      }
    });
    test(
        'both Centre doors and all five real fixed routes remain admitted in the five-map context',
        () {
      final rows =
          (result.projection.semanticEvidence['events'] as List).cast<Map>();
      for (final pair in [
        (100, 8),
        (102, 1),
        (98, 6),
        (98, 8),
        (98, 11),
        (102, 11),
        (102, 15)
      ]) {
        final id = result.draft.source.eventIdentity(pair.$1, pair.$2).value;
        final row = rows.singleWhere((row) => row['sourceIdentity'] == id);
        expect(row['status'], 'adaptedStaticSemantics',
            reason: '$pair ${row['gaps']}');
        if (pair.$1 == 98 || pair.$2 == 11 || pair.$2 == 15) {
          expect(row['nativeFixedRoute'], isNotNull);
        }
      }
      expect(
          result.projection.allEnabledOriginalEventsHaveExecutionContext, true);
      final qualification = result.projection.semanticEvidence['doorExecutionQualification'] as Map;
      expect(qualification['sourceExecutionContext'], isNull);
      final contexts = (qualification['programExecutionContexts'] as List).cast<Map>();
      for (final pair in [(100, 6), (100, 7), (100, 13), (166, 1), (205, 2), (205, 4)]) {
        final identity = result.draft.source.eventIdentity(pair.$1, pair.$2).value;
        final entry = contexts.singleWhere((entry) => entry['eventIdentity'] == identity);
        expect(entry['executionContextQualified'], isTrue);
        expect((entry['executionContext'] as Map)['programIdentity'], identity);
      }
    });
  },
      skip: root == null || snapshot == null
          ? 'Original complete source required.'
          : false);
}
