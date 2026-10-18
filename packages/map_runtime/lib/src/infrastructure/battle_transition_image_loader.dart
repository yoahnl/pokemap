import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_ui_image.dart';

Future<RuntimeUiImageLease?> loadProjectBattleTransitionImage(
  String reference,
  String projectRootDirectory, {
  RuntimeResourceBudget? resourceBudget,
  bool Function()? isCurrent,
}) async {
  validateBattleTransitionAssetReference(reference);
  if (!reference.startsWith('project:')) return null;
  try {
    final root = await Directory(projectRootDirectory).resolveSymbolicLinks();
    final file = File(p.join(root, reference.substring('project:'.length)));
    final resolved = await file.resolveSymbolicLinks();
    if (!p.isWithin(root, resolved)) {
      throw const FormatException('Battle transition image escapes its project.');
    }
    if (await FileSystemEntity.type(resolved, followLinks: false) != FileSystemEntityType.file) {
      return null;
    }
    try {
      return await loadRuntimeUiImageFromFilePath(
        resolved,
        resourceBudget: resourceBudget,
        isCurrent: isCurrent,
      );
    } on Object {
      return null;
    }
  } on FileSystemException {
    return null;
  }
}
