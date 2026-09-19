import 'dart:io';
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
  return base == null
      ? MemoryRecentProjectsAdapter()
      : LocalRecentProjectsAdapter('$base/Avelune Studio/recent-projects.json');
}
