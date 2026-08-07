import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import 'package:pokemap_hub/app/di/infrastructure_providers.dart';
import 'package:pokemap_hub/features/dashboard/application/services/installed_game_activity_reader.dart';
import 'package:pokemap_hub/features/saves/data/repositories/hub_save_repository_impl.dart';
import 'package:pokemap_hub/features/session/data/repositories/control_profile_repository_impl.dart';
import 'package:pokemap_hub/features/session/data/repositories/installed_game_launch_resolver.dart';
import 'package:pokemap_hub/features/session/domain/repositories/control_profile_repository_interface.dart';
import 'package:pokemap_hub/features/session/domain/repositories/session_launch_repository_interface.dart';

/// Infrastructure wiring for launching an installed game.
final sessionLaunchRepositoryProvider =
    FutureProvider<SessionLaunchRepositoryInterface>((ref) async {
  return InstalledGameLaunchResolver(
    supportRoot: await ref.watch(supportRootProvider.future),
    hostCompatibility: ref.watch(hostCompatibilityProvider),
  );
});

final controlProfileRepositoryProvider =
    FutureProvider<ControlProfileRepositoryInterface>((ref) async {
  return HubControlProfileStore(
    supportRoot: await ref.watch(supportRootProvider.future),
  );
});

/// Builds a save repository for one game, once its identity is known.
///
/// The save store is per-game, so it cannot be a plain provider. This is the
/// only place the interface meets its implementation (rule 6).
final saveRepositoryFactoryProvider = Provider<SaveRepositoryFactory>(
  (ref) => (Directory supportRoot, GameIdentity identity) => HubSaveStore(
        supportRoot: supportRoot,
        identity: identity,
      ),
);
