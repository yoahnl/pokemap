import 'dart:io';

import 'package:path/path.dart' as p;

Future<Directory> ensureRuntimeProjectsDirectory({
  required Future<Directory> Function() getDocumentsDirectory,
}) async {
  final documentsDirectory = await getDocumentsDirectory();
  final projectsDirectory = Directory(
    p.join(documentsDirectory.path, 'playable_projects'),
  );
  if (!await projectsDirectory.exists()) {
    await projectsDirectory.create(recursive: true);
  }
  return projectsDirectory;
}

Future<String> importRuntimeProjectToRuntimeProjectsDirectory({
  required String projectJsonPath,
  required Directory projectsDirectory,
}) async {
  final projectDir = Directory(p.dirname(projectJsonPath));
  final projectName = p.basename(projectDir.path);
  final targetDir = Directory(p.join(projectsDirectory.path, projectName));
  final sourcePath = p.normalize(p.absolute(projectDir.path));
  final targetPath = p.normalize(p.absolute(targetDir.path));

  if (sourcePath != targetPath && await targetDir.exists()) {
    await targetDir.delete(recursive: true);
  }
  if (sourcePath != targetPath) {
    await _copyDirectory(projectDir, targetDir);
  }

  final mapsDir = Directory(p.join(targetDir.path, 'maps'));
  if (!await mapsDir.exists()) {
    throw Exception(
      'Le dossier maps/ est manquant après copie. '
      'Source: ${projectDir.path}, Cible: ${targetDir.path}',
    );
  }

  return p.join(targetDir.path, 'project.json');
}

Future<void> _copyDirectory(Directory source, Directory target) async {
  if (!await target.exists()) {
    await target.create(recursive: true);
  }
  await for (final entity in source.list(recursive: true)) {
    final relativePath = p.relative(entity.path, from: source.path);
    final newPath = p.join(target.path, relativePath);
    if (entity is File) {
      final newFile = File(newPath);
      await newFile.parent.create(recursive: true);
      await entity.copy(newPath);
    } else if (entity is Directory) {
      final newDir = Directory(newPath);
      await newDir.create(recursive: true);
    }
  }
}
