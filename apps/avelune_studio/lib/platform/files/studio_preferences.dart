import 'dart:io';
import 'package:flutter/services.dart';
import '../../features/home/data/legacy_recent_projects_adapter.dart';
import '../../features/home/data/local_recent_projects_adapter.dart';
import '../../features/home/data/memory_recent_projects_adapter.dart';
import '../../features/home/domain/recent_studio_project.dart';

RecentProjectsPort studioRecentProjects() {
  final home = Platform.environment['HOME'];
  final base = Platform.isWindows
      ? Platform.environment['APPDATA']
      : Platform.isMacOS
      ? home == null
            ? null
            : '$home/Library/Application Support'
      : Platform.environment['XDG_CONFIG_HOME'] ??
            (home == null ? null : '$home/.config');
  if (base == null) return MemoryRecentProjectsAdapter();
  final filePath = '$base/Avelune Studio/recent-projects.json';
  if (!Platform.isMacOS) return LocalRecentProjectsAdapter(filePath);
  return LegacyRecentProjectsAdapter(
    filePath,
    resolveLegacyManifest: () => const MethodChannel(
      'map_editor/file_access',
    ).invokeMethod<String>('resolveLastProjectManifestPath'),
  );
}
