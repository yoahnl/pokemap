import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'package:pokemap_hub/features/session/domain/entities/save_read_handle.dart';
import 'package:pokemap_hub/features/session/domain/entities/installed_game_launch_context.dart';
import 'package:pokemap_hub/features/saves/domain/repositories/save_repository_interface.dart';

/// Composition bridge from verified Hub handles to the production Flame graph.
///
/// The adapter factory is synchronous, but every filesystem/save lookup stays
/// deferred until session loading and is resolved by Hub-owned services.
final class HubInProcessSessionFactory {
  const HubInProcessSessionFactory({
    required this.launch,
    required this.saves,
    required this.mountGame,
    required this.unmountGame,
    this.preloadedInitialMap,
    this.audioMixer,
    this.presentationCinematicPlayer,
    this.now,
  });

  final InstalledGameLaunchContext launch;
  final SaveRepositoryInterface saves;
  final PlayableMapGameMount mountGame;
  final PlayableMapGameUnmount unmountGame;
  final SessionPreloadedInitialMapLoader? preloadedInitialMap;
  final RuntimeAudioMixer? audioMixer;
  final ScenePresentationCinematicRuntimePlayer? presentationCinematicPlayer;
  final DateTime Function()? now;

  GameSessionAdapter call(GameSessionDescriptor descriptor) {
    if (descriptor.identity != launch.identity ||
        descriptor.installedVersionHandle != launch.installedVersionHandle) {
      throw StateError(
        'The descriptor does not match the verified installed version.',
      );
    }
    if (saves.identity != launch.identity) {
      throw StateError('The save store does not match the launch identity.');
    }
    return InProcessGameSessionAdapter(
      runtimeFactory:
          (preparedDescriptor) => PlayableMapGameSessionRuntime(
            descriptor: preparedDescriptor,
            projectFilePath: () async {
              final file = await launch.assets.resolveReference(launch.project);
              return file.path;
            },
            initialSave: () async {
              if (preparedDescriptor.launchMode ==
                  GameSessionLaunchMode.newGame) {
                return null;
              }
              final selected = await saves.read(
                SaveSlotAddress(
                  gameId: preparedDescriptor.identity.gameId,
                  profileId: preparedDescriptor.profileId,
                  slotId: preparedDescriptor.slotId,
                ),
              );
              if (!selected.canContinue || selected.envelope == null) {
                throw StateError('The selected save is no longer launchable.');
              }
              if (hubSaveReadHandle(selected.envelope!) !=
                  preparedDescriptor.saveReadHandle) {
                throw StateError(
                  'The selected save changed after the launch was authorized.',
                );
              }
              return selected.envelope;
            },
            mountGame: mountGame,
            unmountGame: unmountGame,
            preloadedInitialMap: preloadedInitialMap,
            audioMixer: audioMixer,
            presentationCinematicPlayer: presentationCinematicPlayer,
            now: now,
          ),
    );
  }
}
