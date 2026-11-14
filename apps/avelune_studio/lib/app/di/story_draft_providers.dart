import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/project_session/domain/project_session.dart';
import '../../features/story_draft/application/story_publication_gateway.dart';
import '../../features/story_draft/application/story_saved_dialogues.dart';
import '../../features/story_draft/domain/story_dialogue_source.dart';
import 'dialogue_providers.dart';
import 'event_providers.dart';
import 'presentation_providers.dart';
import 'scene_providers.dart';
import 'story_providers.dart';

final storyPublicationGatewayProvider = Provider.autoDispose
    .family<StoryPublicationGatewayFactory, ProjectSession>((ref, session) {
      final events = ref.watch(eventPortProvider(session));
      final scenes = ref.watch(scenePortProvider(session));
      final dialogues = ref.watch(dialoguePortProvider(session));
      final facts = ref.watch(worldPortProvider(session));
      final stories = ref.watch(storyPortProvider(session));
      return (draft, saved) => StoryPublicationGateway(
        draft: draft,
        events: events,
        scenes: scenes,
        dialogues: dialogues,
        facts: facts,
        savedDialogues: saved,
        stories: stories,
      );
    });

final storyDialogueLoaderProvider = Provider.autoDispose
    .family<StoryDialogueLoader?, ProjectSession>((ref, session) {
      final port = ref.watch(dialoguePortProvider(session));
      if (port == null) return null;
      return (id) async {
        final snapshot = await port.load(id);
        return StoryDialogueSource(
          entry: snapshot.entry,
          source: snapshot.source,
          revision: snapshot.revision,
        );
      };
    });
