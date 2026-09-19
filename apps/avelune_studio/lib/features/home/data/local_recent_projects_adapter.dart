import 'dart:convert';
import 'dart:io';

import '../domain/recent_studio_project.dart';

class LocalRecentProjectsAdapter implements RecentProjectsPort {
  LocalRecentProjectsAdapter(this.filePath);

  final String filePath;

  @override
  Future<List<RecentStudioProject>> load() async {
    final file = File(filePath);
    if (!await file.exists()) return [];
    final data = jsonDecode(await file.readAsString());
    if (data is! List) throw const FormatException('Invalid recent projects');
    return data.map((entry) {
      if (entry is! Map<String, dynamic> ||
          entry['name'] is! String ||
          entry['directoryPath'] is! String ||
          entry['lastOpenedAt'] is! String) {
        throw const FormatException('Invalid recent project');
      }
      return RecentStudioProject(
        name: entry['name'] as String,
        directoryPath: entry['directoryPath'] as String,
        lastOpenedAt: DateTime.parse(entry['lastOpenedAt'] as String),
      );
    }).toList();
  }

  @override
  Future<void> save(List<RecentStudioProject> entries) async {
    final destination = File(filePath);
    await destination.parent.create(recursive: true);
    final temporary = await destination.parent.createTemp('.recent-projects-');
    try {
      final pending = File('${temporary.path}/pending.json');
      await pending.writeAsString(
        jsonEncode([
          for (final entry in entries)
            {
              'name': entry.name,
              'directoryPath': entry.directoryPath,
              'lastOpenedAt': entry.lastOpenedAt.toUtc().toIso8601String(),
            },
        ]),
        flush: true,
      );
      await pending.rename(destination.path);
    } finally {
      await temporary.delete(recursive: true);
    }
  }
}
