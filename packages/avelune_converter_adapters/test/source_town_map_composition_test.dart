import 'dart:convert';
import 'dart:io';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'support/source_town_map_original_fixture.dart';

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final root = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  test(
      'normal map composition uses original regional catalog only for the qualified wall map',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('town-map-native-composition-');
    addTearDown(() => temporary.delete(recursive: true));
    final composition = await composeOriginalTownMapSource(
        archivePath: archive!,
        sourceRoot: root!,
        outputParentPath: temporary.path);
    final sourceEvents =
        composition.draft.compositionEvidence['sourceEvents'] as Map;
    final town = sourceEvents['townMap'] as Map;
    expect(town['pointCount'], 90);
    expect(town['sourceWallMap'], true);
    expect(town['flyEnabled'], false);
    final rows =
        (composition.projection.semanticEvidence['events'] as List).cast<Map>();
    final wall =
        rows.singleWhere((row) => (row['locator'] as Map)['eventId'] == 6);
    expect(wall['status'], 'adaptedStaticSemantics', reason: '${wall['gaps']}');
    expect(composition.projection.semanticEvidence['usedTownMap'], true);
    final mutation = composition.draft.mutations.singleWhere((m) =>
        m.actionId == 'asset.import' &&
        (m.parameters['usages'] as List?)?.contains('converter.sourceEvents') ==
            true);
    final companion = composition.draft.artifacts
        .singleWhere((a) => a.handle == mutation.parameters['artifactHandle']);
    final preserved =
        (jsonDecode(utf8.decode(companion.bytes))['preservedSourceFiles']
                as List)
            .cast<Map>();
    expect(preserved.any((row) => row['relativePath'] == 'Data/town_map.dat'),
        true);
    final image = town['image'] as Map;
    expect(
        preserved.any((row) =>
            row['rawSha256'] == image['sha256'] ||
            row['fileHash'] == image['sha256']),
        true);
    expect(
        composition.draft.artifacts
            .any((a) => a.rawSha256.value == image['sha256']),
        true);
    expect(
        composition.draft.mutations
            .where((m) => m.actionId == 'regionalMap.region.upsert'),
        hasLength(1));
    expect(
        composition.draft.mutations
            .where((m) => m.actionId == 'regionalMap.poi.upsert'),
        hasLength(90));
    final mutations = composition.draft.mutations;
    final sourceMapId = composition.draft.mapIds[102]!;
    final mapIndex = mutations.indexWhere((mutation) =>
        mutation.actionId == 'map.save' &&
        (mutation.parameters['map'] as Map)['id'] == sourceMapId);
    final imageIndex = mutations.indexWhere((mutation) =>
        mutation.actionId == 'asset.import' &&
        mutation.parameters['artifactHandle'] == image['artifactHandle']);
    final regionIndex = mutations.indexWhere(
        (mutation) => mutation.actionId == 'regionalMap.region.upsert');
    final currentPointIndex = mutations.indexWhere((mutation) =>
        mutation.actionId == 'regionalMap.poi.upsert' &&
        ((mutation.parameters['poi'] as Map)['mapIds'] as List)
            .contains(sourceMapId));
    expect(mapIndex, greaterThanOrEqualTo(0));
    expect(imageIndex, greaterThanOrEqualTo(0));
    expect(regionIndex, greaterThan(imageIndex));
    expect(regionIndex, greaterThan(mapIndex));
    expect(currentPointIndex, greaterThan(regionIndex));
    final scene = composition.projection.scenes.singleWhere((scene) =>
        scene.metadata['sourcePageIndex'] == '0' &&
        scene.metadata['sourceEventIdentity'] == wall['sourceIdentity']);
    expect(
        scene.graph.nodes
            .map((n) => n.payload)
            .whereType<SceneActionPayload>()
            .single
            .interactiveCommand!
            .kind
            .name,
        'openRegionalMap');
  },
      skip: archive == null || root == null
          ? 'Original source and archive required.'
          : false,
      timeout: const Timeout(Duration(minutes: 3)));
}
