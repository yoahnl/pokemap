import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/recent_studio_project.dart';
import 'local_recent_projects_adapter.dart';

final class LegacyRecentProjectsAdapter implements RecentProjectsPort {
  LegacyRecentProjectsAdapter(
    this.filePath, {
    required Future<String?> Function() resolveLegacyManifest,
    DateTime Function()? clock,
  }) : _local = LocalRecentProjectsAdapter(filePath),
       _resolveLegacyManifest = resolveLegacyManifest,
       _clock = clock ?? DateTime.now;

  final String filePath;
  final LocalRecentProjectsAdapter _local;
  final Future<String?> Function() _resolveLegacyManifest;
  final DateTime Function() _clock;

  @override
  Future<List<RecentStudioProject>> load() async {
    final hasStudioRecents = await File(filePath).exists();
    final legacyManifest = await _resolveAvailableLegacyManifest();
    final current = await _local.load();
    if (hasStudioRecents || legacyManifest == null) return current;
    if (!p.isAbsolute(legacyManifest) ||
        p.basename(legacyManifest) != 'project.json' ||
        !await File(legacyManifest).exists()) {
      return current;
    }
    final directory = p.dirname(legacyManifest);
    final imported = [
      RecentStudioProject(
        name: p.basename(directory),
        directoryPath: directory,
        lastOpenedAt: _clock(),
      ),
    ];
    await _local.save(imported);
    return imported;
  }

  @override
  Future<void> save(List<RecentStudioProject> entries) => _local.save(entries);

  Future<String?> _resolveAvailableLegacyManifest() async {
    try {
      return await _resolveLegacyManifest();
    } catch (_) {
      return null;
    }
  }
}
