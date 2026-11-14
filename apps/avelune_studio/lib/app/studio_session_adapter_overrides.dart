import 'dart:io';

import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_catalog_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_connection_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/platform/files/native_resource_image_picker.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter_riverpod/misc.dart';

import '../features/resources/data/local_resource_pack_adapter.dart';
import '../platform/files/native_resource_pack_picker.dart';
import '../features/regional_map/data/local_regional_map_adapter.dart';
import '../features/game_export/data/studio_game_export_controller.dart';
import '../features/pokemon/data/local_pokemon_workspace_adapter.dart';
import '../features/pokemon/data/local_pokemon_commerce_adapter.dart';
import '../features/pokemon/data/local_pokemon_combat_adapter.dart';
import '../platform/files/native_pokemon_json_picker.dart';
import '../platform/files/native_pokemon_png_picker.dart';
import '../platform/files/native_game_export_picker.dart';
import '../features/cinematics/data/local_cinematic_adapter.dart';
import '../features/presentations/data/local_presentation_adapter.dart';
import '../features/verification/data/local_verification_adapter.dart';
import '../features/world/data/local_world_adapter.dart';
import '../features/game_memory/data/local_narrative_index_adapter.dart';
import '../platform/files/native_presentation_media_picker.dart';
import '../features/dialogues/data/local_dialogue_adapter.dart';
import '../features/events/data/local_event_adapter.dart';
import '../features/scenes/data/local_scene_adapter.dart';
import '../features/stories/data/local_story_adapter.dart';

List<Override> studioSessionAdapterOverrides() => [
  mapWorkspacePortProvider.overrideWith(
    (ref, session) => LocalMapWorkspaceAdapter(),
  ),
  mapConnectionPortProvider.overrideWith(
    (ref, session) => LocalMapConnectionAdapter(
      ref.watch(mapWorkspacePortProvider(session)) as LocalMapWorkspaceAdapter,
    ),
  ),
  mapCatalogPortProvider.overrideWith(
    (ref, session) => LocalMapCatalogAdapter(
      ref.watch(mapWorkspacePortProvider(session)) as LocalMapWorkspaceAdapter,
    ),
  ),
  resourcePortProvider.overrideWith((ref, session) {
    final port = LocalResourceAdapter(
      session: session,
      mapAdapter: ref.watch(
        mapWorkspacePortProvider(session),
      ) as LocalMapWorkspaceAdapter,
    );
    ref.onDispose(port.dispose);
    return port;
  }),
  resourcePackPortProvider.overrideWith((ref, session) {
    final port = LocalResourcePackAdapter(
      session: session,
      mapAdapter: ref.watch(
        mapWorkspacePortProvider(session),
      ) as LocalMapWorkspaceAdapter,
      resources:
          ref.watch(resourcePortProvider(session)) as LocalResourceAdapter,
    );
    ref.onDispose(port.dispose);
    return port;
  }),
  resourcePackLicensePickerProvider.overrideWithValue(
    const NativeResourcePackPicker().chooseLicenseDocuments,
  ),
  resourcePackPickerProvider.overrideWithValue(
    const NativeResourcePackPicker().choose,
  ),
  pokemonPortProvider.overrideWith((ref, session) {
    final port = LocalPokemonWorkspaceAdapter(
      session: session,
      mapAdapter: ref.watch(
        mapWorkspacePortProvider(session),
      ) as LocalMapWorkspaceAdapter,
    );
    ref.onDispose(port.dispose);
    return port;
  }),
  pokemonCommercePortProvider.overrideWith(
    (ref, session) => LocalPokemonCommerceAdapter(
      session: session,
      mapAdapter: ref.watch(
        mapWorkspacePortProvider(session),
      ) as LocalMapWorkspaceAdapter,
    ),
  ),
  pokemonCombatPortProvider.overrideWith(
    (ref, session) => LocalPokemonCombatAdapter(
      session: session,
      mapAdapter: ref.watch(
        mapWorkspacePortProvider(session),
      ) as LocalMapWorkspaceAdapter,
    ),
  ),
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
  regionalMapPortProvider.overrideWith(
    (ref, session) => LocalRegionalMapAdapter(
      session: session,
      mapAdapter: ref.watch(
        mapWorkspacePortProvider(session),
      ) as LocalMapWorkspaceAdapter,
    ),
  ),
  narrativePortProvider.overrideWith(
    (ref, session) => LocalNarrativeAdapter(
      session: session,
      mapAdapter: ref.watch(
        mapWorkspacePortProvider(session),
      ) as LocalMapWorkspaceAdapter,
    ),
  ),
  workspaceVisualsLoaderProvider.overrideWithValue(StudioMapResources.load),
  workspaceRuntimeBuilderProvider.overrideWithValue((session, port) {
    final saves = StudioPlaytestSession();
    return (entry, revision, controls, close) => StudioPlaytestView(
      session: session,
      entry: entry,
      expectedRevision: revision,
      port: port,
      onClose: close,
      controls: controls,
      testSession: saves,
    );
  }),
  scenePortProvider.overrideWith(
    (ref, session) => LocalSceneAdapter(
      session: session,
      mapAdapter: ref.watch(
        mapWorkspacePortProvider(session),
      ) as LocalMapWorkspaceAdapter,
    ),
  ),
  storyPortProvider.overrideWith(
    (ref, session) => LocalStoryAdapter(
      session: session,
      mapAdapter: ref.watch(
        mapWorkspacePortProvider(session),
      ) as LocalMapWorkspaceAdapter,
    ),
  ),
  eventPortProvider.overrideWith(
    (ref, session) => LocalEventAdapter(
      session: session,
      mapAdapter: ref.watch(
        mapWorkspacePortProvider(session),
      ) as LocalMapWorkspaceAdapter,
    ),
  ),
  dialoguePortProvider.overrideWith(
    (ref, session) => LocalDialogueAdapter(
      session: session,
      mapAdapter: ref.watch(
        mapWorkspacePortProvider(session),
      ) as LocalMapWorkspaceAdapter,
    ),
  ),
  presentationMediaPickerProvider.overrideWithValue(
    const NativePresentationMediaPicker().choose,
  ),
  presentationPortProvider.overrideWith(
    (ref, session) => LocalPresentationAdapter(
      session: session,
      mapAdapter: ref.watch(
        mapWorkspacePortProvider(session),
      ) as LocalMapWorkspaceAdapter,
    ),
  ),
  worldPortProvider.overrideWith(
    (ref, session) => LocalWorldAdapter(
      session: session,
      mapAdapter: ref.watch(
        mapWorkspacePortProvider(session),
      ) as LocalMapWorkspaceAdapter,
    ),
  ),
  narrativeIndexPortProvider.overrideWith(
    (ref, session) => LocalNarrativeIndexAdapter(session),
  ),
  verificationPortProvider.overrideWith(
    (ref, session) => LocalVerificationAdapter(
      session: session,
      mapAdapter: ref.watch(
        mapWorkspacePortProvider(session),
      ) as LocalMapWorkspaceAdapter,
    ),
  ),
  cinematicPortProvider.overrideWith(
    (ref, session) => LocalCinematicAdapter(
      session: session,
      mapAdapter: ref.watch(
        mapWorkspacePortProvider(session),
      ) as LocalMapWorkspaceAdapter,
    ),
  ),
];
