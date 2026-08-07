import 'dart:io';

import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_state.dart';

/// Bounded, symlink-safe measurement of Hub-owned application data.
final class HubDirectoryStorageReader {
  const HubDirectoryStorageReader({
    required this.supportRoot,
    this.maxEntries = 100000,
  });

  final Directory supportRoot;
  final int maxEntries;

  Future<HubStorageSnapshot> call() async {
    final type = await FileSystemEntity.type(
      supportRoot.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound) {
      return const HubStorageSnapshot();
    }
    if (type != FileSystemEntityType.directory) {
      throw const FileSystemException('Unsafe Hub storage root.');
    }
    var entries = 0;
    var bytes = 0;
    await for (final entity
        in supportRoot.list(recursive: true, followLinks: false)) {
      if (++entries > maxEntries) break;
      if (entity is! File) continue;
      final entityType = await FileSystemEntity.type(
        entity.path,
        followLinks: false,
      );
      if (entityType != FileSystemEntityType.file) continue;
      bytes += await entity.length();
    }
    return HubStorageSnapshot(usedBytes: bytes);
  }
}
