import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'package:pokemap_hub/features/saves/domain/entities/save_storage_diagnostic.dart';

/// Every filesystem boundary check the save store relies on.
///
/// Extracted from [HubSaveStore] verbatim. These guards are the only thing
/// standing between a crafted slot id and a write outside the support root:
/// symlink refusal, resolved-path containment, and game-scope enforcement.
/// Do not relax them.
final class SavePathGuard {
  const SavePathGuard({
    required this.supportRoot,
    required this.identity,
  });

  final Directory supportRoot;
  final GameIdentity identity;

  void assertAddressScope(SaveSlotAddress address) {
    if (address.gameId != identity.gameId) {
      throw SaveStorageException(
        SaveStorageErrorCode.outOfScope,
        'Address ${address.gameId} is outside ${identity.gameId}.',
      );
    }
  }

  Future<Directory?> safeSlotDirectory(
    SaveSlotAddress address, {
    required bool create,
  }) async {
    final profile = await safeProfileDirectory(
      address.profileId,
      create: create,
    );
    if (profile == null) return null;
    return safeChildDirectory(profile, address.slotId, create: create);
  }

  Future<Directory?> safeProfileDirectory(
    String profileId, {
    required bool create,
  }) async {
    GameIdentity.validateLocalId(profileId, path: r'$.profileId');
    final game = await safeGameDirectory(create: create);
    if (game == null) return null;
    return safeChildDirectory(game, profileId, create: create);
  }

  Future<Directory?> safeGameDirectory({required bool create}) async {
    GameIdentity.validateGameId(identity.gameId);
    final root = await safeSupportRoot(create: create);
    if (root == null) return null;
    final saves = await safeChildDirectory(root, 'saves', create: create);
    if (saves == null) return null;
    return safeChildDirectory(saves, identity.gameId, create: create);
  }

  Future<Directory?> safeSupportRoot({required bool create}) async {
    if (!await supportRoot.exists()) {
      if (!create) return null;
      await supportRoot.create(recursive: true);
    }
    if (await FileSystemEntity.isLink(supportRoot.path)) {
      throw const SaveStorageException(
        SaveStorageErrorCode.pathEscapesRoot,
        'Support root must not be a symbolic link.',
      );
    }
    return supportRoot;
  }

  Future<Directory?> safeChildDirectory(
    Directory parent,
    String name, {
    required bool create,
  }) async {
    final child = Directory(p.join(parent.path, name));
    final type = await FileSystemEntity.type(child.path, followLinks: false);
    if (type == FileSystemEntityType.link ||
        (type != FileSystemEntityType.notFound &&
            type != FileSystemEntityType.directory)) {
      throw SaveStorageException(
        SaveStorageErrorCode.pathEscapesRoot,
        'Unsafe save path component "$name".',
      );
    }
    if (type == FileSystemEntityType.notFound) {
      if (!create) return null;
      await child.create();
    }
    final rootResolved = await supportRoot.resolveSymbolicLinks();
    final childResolved = await child.resolveSymbolicLinks();
    if (childResolved != rootResolved &&
        !p.isWithin(rootResolved, childResolved)) {
      throw SaveStorageException(
        SaveStorageErrorCode.pathEscapesRoot,
        'Resolved save path escapes the PokeMap support root.',
      );
    }
    return child;
  }

  Future<void> rejectLink(String path) async {
    if (await FileSystemEntity.type(path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw SaveStorageException(
        SaveStorageErrorCode.pathEscapesRoot,
        'Save file path is a symbolic link: $path',
      );
    }
  }
}
