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
