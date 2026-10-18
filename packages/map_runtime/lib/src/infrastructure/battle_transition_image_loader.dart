import 'dart:io';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'tile_image_loader.dart';

Future<ui.Image?> loadProjectBattleTransitionImage(
    String reference, String projectRootDirectory) async {
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
      return await loadImageFromFilePath(resolved);
    } on Object {
      return null;
    }
  } on FileSystemException {
    return null;
  }
}
