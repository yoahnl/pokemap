import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/world/domain/world_port.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_catalog_binding.dart';

import '../presentation/map_builder_story_support.dart';
import '../support/map_workspace_fixture.dart';

NarrativeEventRecord recordOnB([int index = 1]) => storyRecord(
  index,
  source: NarrativeEventSourceRef.entityInteract('b', 'luth'),
);

final class BehaviourMapLoader implements WorldMapSelectionPort {
  final reads = <String>[];
  Object? failure;
  Completer<MapData>? gate;

  @override
  Future<MapData> loadMap(ProjectMapEntry entry) async {
    reads.add(entry.id);
    if (failure case final error?) throw error;
    if (gate case final pending?) return pending.future;
    return workspaceMap(entry.id).copyWith(entities: [storyLuth]);
  }
}

MapBuilderStoryCatalogBinding openCatalogue(
  StoryFixture fixture,
  BehaviourMapLoader loader,
) {
  final catalog = MapBuilderStoryCatalogBinding(
    story: fixture.story,
    maps: loader,
    changed: () => fixture.tick.value++,
  );
  addTearDown(catalog.dispose);
  return catalog;
}
