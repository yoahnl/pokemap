import 'package:avelune_studio/features/game_memory/data/local_narrative_index_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_gateway.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/data/local_storyline_read_adapter.dart';
import 'package:avelune_studio/features/world/data/local_world_adapter.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_behaviour_source.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';

Future<({MapBuilderStoryBinding story, StorylineTrameController trame})>
openStoryWorkspaceCatalog(
  ProjectSession session, {
  ProjectFileReader? reader,
  AuthoringTransactionFaultInjector? observeWrite,
}) async {
  final reads = reader ?? const LocalProjectFileReader();
  final adapter = LocalMapWorkspaceAdapter(reader: reads);
  final maps = MapWorkspaceController(session, adapter);
  addTearDown(maps.dispose);
  await maps.initialize();
  final story = MapBuilderStoryBinding(
    maps: maps,
    changed: () {},
    view: () => null,
    gateway: (draft, saved) => StoryPublicationGateway(
      draft: draft,
      facts: LocalWorldAdapter(session: session, mapAdapter: adapter),
      stories: LocalStoryAdapter(
        session: session,
        mapAdapter: adapter,
        faultInjector: observeWrite,
        reader: reads,
      ),
      savedDialogues: saved,
    ),
  );
  final trame = StorylineTrameController(
    port: LocalStorylineReadAdapter(session, reader: reads),
    index: LocalNarrativeIndexAdapter(session, reader: reads),
    staging: MapBuilderStoryMemory(story, editable: () => true),
    source: () => MapBuilderStoryBehaviourSource(story),
    changed: () {},
  );
  await trame.open();
  return (story: story, trame: trame);
}
