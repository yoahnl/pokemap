import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/app/di/game_memory_providers.dart';
import 'package:avelune_studio/app/di/presentation_providers.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/domain/storyline_read_port.dart';
import 'package:avelune_studio/features/verification/application/project_verification_controller.dart';
import 'package:avelune_studio/features/verification/domain/verification_port.dart';
import 'package:avelune_studio/features/world/domain/world_port.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_behaviour_source.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_memory.dart';

final class MapBuilderStoryServices {
  MapBuilderStoryServices({
    required WidgetRef ref,
    required ProjectSession session,
    required this.story,
    required bool Function() editable,
    required this._changed,
    required this._verificationProject,
  }) : memory = MapBuilderStoryMemory(
         story,
         editable: () =>
             editable() &&
             session.storage == ProjectSessionStorage.workingCatalog,
       ),
       _narrative = ref.listenManual(
         narrativeIndexPortProvider(session),
         (_, _) {},
       ),
       _world = ref.listenManual(worldPortProvider(session), (_, _) {}),
       _storylines = ref.listenManual(
         storylineReadPortProvider(session),
         (_, _) {},
       ),
       _verification = ref.listenManual(
         verificationPortProvider(session),
         (_, _) {},
       );

  final void Function() _changed;
  final Future<ProjectManifest?> Function() _verificationProject;
  ProjectVerificationController? verification;

  void attach() {
    story.narrative = narrative;
    final storylines = _storylines.read();
    final index = narrative;
    if (storylines != null && index != null) {
      story.trame = StorylineTrameController(
        port: storylines,
        index: index,
        staging: memory,
        source: () => behaviours,
        changed: _changed,
      );
    }
    if (_verification.read() case final port?) {
      verification = ProjectVerificationController(
        port: port,
        loadProject: _verificationProject,
        changed: _changed,
      );
    }
  }

  final MapBuilderStoryBinding story;
  final MapBuilderStoryMemory memory;
  final ProviderSubscription<NarrativeIndexPort?> _narrative;
  final ProviderSubscription<WorldPort?> _world;
  final ProviderSubscription<StorylineReadPort?> _storylines;
  final ProviderSubscription<VerificationPort?> _verification;

  NarrativeIndexPort? get narrative => _narrative.read();

  WorldPort? get world => _world.read();

  MapBuilderStoryBehaviourSource get behaviours =>
      MapBuilderStoryBehaviourSource(story);

  void close() {
    _narrative.close();
    _world.close();
    _storylines.close();
    verification?.cancel();
    _verification.close();
  }
}
