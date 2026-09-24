import 'dart:io';

import '../features/game_export/data/studio_game_export_controller.dart';
import '../features/pokemon/data/local_pokemon_workspace_adapter.dart';
import '../platform/files/native_pokemon_json_picker.dart';
import '../platform/files/native_pokemon_png_picker.dart';
import '../platform/files/native_game_export_picker.dart';
import 'package:flutter/widgets.dart';
import '../features/cinematics/data/local_cinematic_adapter.dart';
import '../features/presentations/data/local_presentation_adapter.dart';
import '../features/verification/data/local_verification_adapter.dart';
import '../features/world/data/local_world_adapter.dart';
import '../platform/files/native_presentation_media_picker.dart';
import '../features/dialogues/data/local_dialogue_adapter.dart';
import '../features/events/data/local_event_adapter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'di/home_providers.dart';
import '../features/scenes/data/local_scene_adapter.dart';
import '../features/stories/data/local_story_adapter.dart';
import '../platform/files/studio_preferences.dart';

import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/app/studio_app.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/platform/files/native_project_directory_picker.dart';
import 'package:avelune_studio/platform/files/native_resource_image_picker.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/shell/studio_workspace_host.dart';

class StudioBootstrap extends StatelessWidget {
  const StudioBootstrap({super.key});

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      recentProjectsPortProvider.overrideWith((ref) => studioRecentProjects()),
      projectSessionPortProvider.overrideWith(
        (ref) => LocalProjectSessionAdapter(),
      ),
      projectDirectoryPickerProvider.overrideWithValue(
        const NativeProjectDirectoryPicker().choose,
      ),
      mapWorkspacePortProvider.overrideWith(
        (ref, session) => LocalMapWorkspaceAdapter(),
      ),
      resourcePortProvider.overrideWith((ref, session) {
        final port = LocalResourceAdapter(
          session: session,
          mapAdapter:
              ref.watch(mapWorkspacePortProvider(session))
                  as LocalMapWorkspaceAdapter,
        );
        ref.onDispose(port.dispose);
        return port;
      }),
      pokemonPortProvider.overrideWith((ref, session) {
        final port = LocalPokemonWorkspaceAdapter(
          session: session,
          mapAdapter:
              ref.watch(mapWorkspacePortProvider(session))
                  as LocalMapWorkspaceAdapter,
        );
        ref.onDispose(port.dispose);
        return port;
      }),
      pokemonJsonPickerProvider.overrideWithValue(
        const NativePokemonJsonPicker().choose,
      ),
      pokemonPngPickerProvider.overrideWithValue(
        const NativePokemonPngPicker().choose,
      ),
      resourceImagePickerProvider.overrideWithValue(
        const NativeResourceImagePicker().choose,
      ),
      gameExportPortProvider.overrideWith((ref, session) {
        final port = StudioGameExportController(
          projectRoot: Directory(session.directoryPath),
          projectName: session.name,
        );
        ref.onDispose(port.dispose);
        return port;
      }),
      gameExportPickerProvider.overrideWithValue(pickNativeGameExportFile),
      narrativePortProvider.overrideWith(
        (ref, session) => LocalNarrativeAdapter(
          session: session,
          mapAdapter:
              ref.watch(mapWorkspacePortProvider(session))
                  as LocalMapWorkspaceAdapter,
        ),
      ),
      workspaceVisualsLoaderProvider.overrideWithValue(StudioMapResources.load),
      scenePortProvider.overrideWith(
        (ref, session) => LocalSceneAdapter(
          session: session,
          mapAdapter:
              ref.watch(mapWorkspacePortProvider(session))
                  as LocalMapWorkspaceAdapter,
        ),
      ),
      storyPortProvider.overrideWith(
        (ref, session) => LocalStoryAdapter(
          session: session,
          mapAdapter:
              ref.watch(mapWorkspacePortProvider(session))
                  as LocalMapWorkspaceAdapter,
        ),
      ),
      eventPortProvider.overrideWith(
        (ref, session) => LocalEventAdapter(
          session: session,
          mapAdapter:
              ref.watch(mapWorkspacePortProvider(session))
                  as LocalMapWorkspaceAdapter,
        ),
      ),
      dialoguePortProvider.overrideWith(
        (ref, session) => LocalDialogueAdapter(
          session: session,
          mapAdapter:
              ref.watch(mapWorkspacePortProvider(session))
                  as LocalMapWorkspaceAdapter,
        ),
      ),
      presentationMediaPickerProvider.overrideWithValue(
        const NativePresentationMediaPicker().choose,
      ),
      presentationPortProvider.overrideWith(
        (ref, session) => LocalPresentationAdapter(
          session: session,
          mapAdapter:
              ref.watch(mapWorkspacePortProvider(session))
                  as LocalMapWorkspaceAdapter,
        ),
      ),
      worldPortProvider.overrideWith(
        (ref, session) => LocalWorldAdapter(
          session: session,
          mapAdapter:
              ref.watch(mapWorkspacePortProvider(session))
                  as LocalMapWorkspaceAdapter,
        ),
      ),
      verificationPortProvider.overrideWith(
        (ref, session) => LocalVerificationAdapter(
          session: session,
          mapAdapter:
              ref.watch(mapWorkspacePortProvider(session))
                  as LocalMapWorkspaceAdapter,
        ),
      ),
      cinematicPortProvider.overrideWith(
        (ref, session) => LocalCinematicAdapter(
          session: session,
          mapAdapter:
              ref.watch(mapWorkspacePortProvider(session))
                  as LocalMapWorkspaceAdapter,
        ),
      ),
      workspaceRuntimeBuilderProvider.overrideWithValue((session, port) {
        final testSession = StudioPlaytestSession();
        return (entry, revision, close) => StudioPlaytestView(
          session: session,
          entry: entry,
          expectedRevision: revision,
          port: port,
          onClose: close,
          testSession: testSession,
        );
      }),
    ],
    child: StudioApp(
      workspaceBuilder: (session, close, guard) => StudioWorkspaceHost(
        key: ValueKey(session.sessionId),
        session: session,
        onClose: close,
        registerExitGuard: guard,
      ),
    ),
  );
}
