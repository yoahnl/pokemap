import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

enum ConverterPathKind {
  sourceFolder,
  sourceProject,
  sharedDataFolder,
  destinationParent,
  planFile,
}

typedef ConverterPathPicker = Future<String?> Function(ConverterPathKind kind);
typedef ConverterFolderOpener = Future<void> Function(String directory);
typedef ConverterPlanSavePicker = Future<String?> Function();

Future<LocalReviewSessionStore> openConverterReviewSessionStore() async {
  final support = await getApplicationSupportDirectory();
  return LocalReviewSessionStore(
    rootPath: path.join(support.path, 'review-sessions'),
  );
}

Future<String?> pickConverterPath(ConverterPathKind kind) async {
  if (kind == ConverterPathKind.planFile) {
    return _pickPlanWithParentAccess(() async {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Charger un plan de conversion local',
      );
      return selection?.files.single.path;
    });
  }
  if (kind == ConverterPathKind.sourceProject) {
    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['rxproj'],
      dialogTitle: 'Choisir Game.rxproj',
    );
    return selection?.files.single.path;
  }
  return FilePicker.getDirectoryPath(
    dialogTitle: switch (kind) {
      ConverterPathKind.sourceFolder => 'Choisir le projet RPG Maker XP',
      ConverterPathKind.sharedDataFolder => 'Choisir les fichiers partagés',
      _ => 'Choisir le dossier parent de la conversion',
    },
  );
}

Future<String?> pickConverterPlanSavePath() => _pickPlanWithParentAccess(
  () => FilePicker.saveFile(
    type: FileType.custom,
    allowedExtensions: ['json'],
    fileName: 'avelune-plan.json',
    dialogTitle: 'Enregistrer un nouveau plan de conversion',
  ),
);

Future<String?> _pickPlanWithParentAccess(
  Future<String?> Function() pickFile,
) async {
  final selected = await pickFile();
  if (selected == null ||
      !path.isAbsolute(selected) ||
      path.normalize(selected) != selected ||
      selected.contains('\u0000') ||
      path.extension(selected).toLowerCase() != '.json') {
    return null;
  }
  final parent = path.dirname(selected);
  if (parent == path.rootPrefix(parent)) {
    return null;
  }
  final authorized = await FilePicker.getDirectoryPath(
    dialogTitle: 'Autoriser le dossier contenant le plan sélectionné',
    initialDirectory: parent,
  );
  if (authorized == null || !path.isAbsolute(authorized)) {
    return null;
  }
  try {
    final canonicalParent = await Directory(parent).resolveSymbolicLinks();
    if (canonicalParent == path.rootPrefix(canonicalParent)) {
      return null;
    }
    final canonicalAuthorized = await Directory(authorized)
        .resolveSymbolicLinks();
    if (!path.equals(canonicalParent, canonicalAuthorized)) {
      return null;
    }
    return path.join(canonicalParent, path.basename(selected));
  } on FileSystemException {
    return null;
  }
}

Future<void> openConverterFolder(String directory) async {
  final result = await Process.run('/usr/bin/open', [directory]);
  if (result.exitCode != 0) {
    throw FileSystemException('Impossible d’ouvrir ce dossier.', directory);
  }
}
