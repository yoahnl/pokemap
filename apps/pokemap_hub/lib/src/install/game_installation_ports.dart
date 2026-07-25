import 'dart:io';

import 'package:map_distribution/map_distribution.dart';

import '../library/game_library.dart';

typedef HubAvailableDiskBytes = Future<int> Function(Directory supportRoot);

typedef GamePackageLoadSmoke = Future<void> Function(
  Directory stagedVersionRoot,
  GamePackageManifest manifest,
);

final class SaveUpdatePreparation {
  const SaveUpdatePreparation({
    this.rollbackSnapshotAvailable = false,
  });

  final bool rollbackSnapshotAvailable;
}

typedef PrepareGameSavesForUpdate = Future<SaveUpdatePreparation> Function(
  InstalledGamePointer current,
  GamePackageManifest candidate,
);

typedef RestoreGameSavesForRollback = Future<void> Function(
  String gameId,
  InstalledGamePointer target,
);
