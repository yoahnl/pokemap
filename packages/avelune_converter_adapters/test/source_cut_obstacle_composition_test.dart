import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'support/source_cut_original_fixture.dart';

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final root = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  test(
      'normal source workflow publishes four Route 10 locked Cut objects and attested definitions',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('original-cut-composition-');
    addTearDown(() => temporary.delete(recursive: true));
    final composition = await composeOriginalCutSource(
        archivePath: archive!,
        sourceRoot: root!,
        outputParentPath: temporary.path,
        sourceMapIds: const {100});
    final draft = composition.draft;
    final evidence = draft.compositionEvidence['sourceEvents'] as Map;
    final cut = evidence['cutObstacles'] as Map;
    expect(cut['initialPlayerStateMutated'], false);
    expect(cut['audioSourceParity'], false);
    expect(
        composition.projection.nativeMaps.values
            .expand((map) => map.entities)
            .where((entity) => entity.fieldObstacle != null),
        hasLength(4));
    expect(draft.mapIds.keys.toSet(), {100});
    final badge = draft.mutations.singleWhere(
        (mutation) => mutation.actionId == 'campaign.badge.upsert');
    expect((badge.parameters['value'] as Map)['fieldAbilityUnlock'], 'cut');
    expect((badge.parameters['value'] as Map)['label'], 'Cascade Badge');
    final element = draft.mutations.singleWhere((mutation) =>
        mutation.actionId == 'element.upsert' &&
        ((mutation.parameters['element'] as Map)['id'] as String)
            .startsWith('source_cut_tree_element_'));
    final tilesetIndex = draft.mutations.indexWhere((mutation) =>
        mutation.actionId == 'tileset.import_image' &&
        (mutation.parameters['tilesetId'] as String)
            .startsWith('source_cut_tree_'));
    final elementIndex = draft.mutations.indexOf(element);
    final objectIndex = draft.mutations.indexWhere((mutation) =>
        mutation.actionId == 'entity.upsert' &&
        (mutation.parameters['entity'] as Map)['fieldObstacle'] != null);
    expect(tilesetIndex, greaterThanOrEqualTo(0));
    expect(elementIndex, greaterThan(tilesetIndex));
    expect(objectIndex, greaterThan(elementIndex));
    expect(
        draft.mutations.where((mutation) =>
            mutation.actionId.contains('award_badge') ||
            mutation.actionId.contains('unlock_field') ||
            mutation.actionId.contains('learn_move')),
        isEmpty);
    final companionMutation = draft.mutations.singleWhere((mutation) =>
        mutation.actionId == 'asset.import' &&
        (mutation.parameters['usages'] as List?)
                ?.contains('converter.sourceEvents') ==
            true);
    final companion = draft.artifacts.singleWhere((artifact) =>
        artifact.handle == companionMutation.parameters['artifactHandle']);
    final companionJson = jsonDecode(utf8.decode(companion.bytes)) as Map;
    final preserved =
        (companionJson['preservedSourceFiles'] as List).cast<Map>();
    expect(
        preserved.any((file) => file['relativePath'] == 'Data/Map026.rxdata'),
        true);
    expect(
        draft.artifacts.any((artifact) =>
            artifact.rawSha256.value ==
            '68271cc5662b112111bec29ea8122466712535a4fd2381262a20a65064e974cb'),
        true);
  },
      skip: archive == null || root == null
          ? 'Requires exact original source fixtures.'
          : false,
      timeout: const Timeout(Duration(minutes: 5)));
}
