import 'package:path/path.dart' as p;

class ProjectTilesetBatchImportItem {
  const ProjectTilesetBatchImportItem({
    required this.sourcePath,
    required this.suggestedName,
  });

  final String sourcePath;
  final String suggestedName;
}

List<ProjectTilesetBatchImportItem> buildProjectTilesetBatchImportPlan(
  Iterable<String> sourcePaths,
) {
  final seenPaths = <String>{};
  final items = <ProjectTilesetBatchImportItem>[];

  for (final sourcePath in sourcePaths) {
    final trimmedPath = sourcePath.trim();
    if (trimmedPath.isEmpty) continue;

    final normalizedPath = p.normalize(trimmedPath);
    if (!seenPaths.add(normalizedPath)) continue;

    final suggestedName = p.basenameWithoutExtension(trimmedPath).trim();
    if (suggestedName.isEmpty) continue;

    items.add(
      ProjectTilesetBatchImportItem(
        sourcePath: trimmedPath,
        suggestedName: suggestedName,
      ),
    );
  }

  return List.unmodifiable(items);
}
