import 'dart:io';

import 'package:file_picker/file_picker.dart';

enum ConverterPathKind { sourceFolder, sourceProject, destinationParent }

typedef ConverterPathPicker = Future<String?> Function(ConverterPathKind kind);
typedef ConverterFolderOpener = Future<void> Function(String directory);

Future<String?> pickConverterPath(ConverterPathKind kind) async {
  if (kind == ConverterPathKind.sourceProject) {
    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['rxproj'],
      dialogTitle: 'Choisir Game.rxproj',
    );
    return selection?.files.single.path;
  }
  return FilePicker.getDirectoryPath(
    dialogTitle: kind == ConverterPathKind.sourceFolder
        ? 'Choisir le projet RPG Maker XP'
        : 'Choisir le dossier parent de la conversion',
  );
}

Future<void> openConverterFolder(String directory) async {
  final result = await Process.run('/usr/bin/open', [directory]);
  if (result.exitCode != 0) {
    throw FileSystemException('Impossible d’ouvrir ce dossier.', directory);
  }
}
