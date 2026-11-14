import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../game_memory/game_memory_catalog_fixture.dart';
import '../pokemon/pokemon_scoped_save_counting_reader.dart';

void main() {
  test(
    'opening a simulation reads nothing beyond the open story space',
    () async {
      final session = await openGameMemoryCatalog(unrelated: 100);
      final reader = CountingReader();
      final maps = MapWorkspaceController(
        session,
        LocalMapWorkspaceAdapter(reader: reader),
      );
      addTearDown(maps.dispose);
      await maps.initialize();
      await maps.activate(
        maps.project!.maps.singleWhere((entry) => entry.id == 'town'),
      );
      final view = MapEditingViewportSession();
      addTearDown(view.dispose);
      final story = MapBuilderStoryBinding(
        maps: maps,
        changed: () {},
        view: () => view,
      );
      await story.prepare();
      expect(story.error, isNull);
      reader.clear();

      final report = story.simulate(
        NarrativeEventSimulationInput(
          targetEventId: memoryTalkEvent,
          factNarrativeValues: {'fact_met': const NarrativeValue.boolean(true)},
        ),
      );

      expect(report, isNotNull);
      expect(
        report!.candidates.map((candidate) => candidate.eventId),
        contains(memoryTalkEvent),
      );
      expect(reader.paths, isEmpty);
      expect(maps.dirty, isFalse);
      expect(story.dirty, isFalse);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
