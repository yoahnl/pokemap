import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart'
    show spatialBorderAuthoringFixture, context;

void main() {
  test('canonical descriptors expose the typed Border jump property', () {
    for (final id in [
      'border.blueprint.draft.upsert',
      'border.blueprint.publish'
    ]) {
      final descriptor = BorderCatalogActions.descriptors
          .singleWhere((value) => value.id == id);
      final extension = descriptor.extensions['directedJumpBehavior'] as Map?;
      expect(extension, isNotNull, reason: id);
      expect(extension!['property'], 'definition.jumpBehavior');
      expect(extension['owner'], 'borderBlueprint');
      expect(extension['persistedGameplayZone'], false);
      final schema = extension['schema'] as Map;
      expect(schema['additionalProperties'], false);
      final properties = schema['properties'] as Map;
      expect(
          properties.keys,
          unorderedEquals(
              ['side', 'distanceCells', 'durationMs', 'peakHeightPx']));
      expect((properties['side'] as Map)['enum'], ['primary', 'inverted']);
      expect((properties['distanceCells'] as Map)['const'], 2);
      expect(descriptor.extensions['catalogFormatVersion'], 6);
    }
  });

  test(
      'canonical native draft and publication preserve the Border jump behavior',
      () async {
    final fixture = spatialBorderAuthoringFixture();
    final wire = encodeBorderBlueprintRecordJson(
        fixture.project.borderCatalog.records.single,
        formatVersion: 5);
    final jump = BorderJumpBehavior(
        side: BorderLineSide.inverted, durationMs: 750, peakHeightPx: 36);
    ((wire['draft'] as Map)['definition'] as Map)['jumpBehavior'] =
        jump.toJson();
    final draftedMutation = await MapMutationDispatcher.canonical().build(
        context(librarySnapshot([fixture.map], project: fixture.project),
            'border.blueprint.draft.upsert', {'record': wire}));
    final drafted = _manifest(draftedMutation);
    expect(drafted.borderCatalog.formatVersion, 6);
    expect(drafted.borderCatalog.records.single.draft.definition.jumpBehavior,
        jump);
    expect(drafted.borderCatalog.records.single.latestPublished,
        fixture.project.borderCatalog.records.single.latestPublished);
    final publishedMutation = await MapMutationDispatcher.canonical().build(
        context(librarySnapshot([fixture.map], project: drafted),
            'border.blueprint.publish', {'blueprintId': 'fence'}));
    final published = _manifest(publishedMutation);
    expect(published.borderCatalog.formatVersion, 6);
    final record = published.borderCatalog.records.single;
    expect(record.draft.definition.jumpBehavior, jump);
    expect(record.latestPublished!.definition.jumpBehavior, jump);
    final reopened =
        ProjectManifest.fromJson(jsonDecode(jsonEncode(published.toJson())));
    expect(reopened.borderCatalog.records.single, record);
    final appliedMutation = await MapMutationDispatcher.canonical().build(
        context(
            librarySnapshot([fixture.map], project: reopened),
            'border_layer.materialize_apply',
            {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'}));
    final map = MapData.fromJson(jsonDecode(
        utf8.decode(appliedMutation.changeSet.changes.single.afterBytes!)));
    expect(map.spatialScene!.instances, hasLength(3));
    expect(map.gameplayZones, isEmpty);
  });
}

ProjectManifest _manifest(AuthoringMutationDraft mutation) =>
    ProjectManifest.fromJson(
        jsonDecode(utf8.decode(mutation.changeSet.changes.single.afterBytes!)));
