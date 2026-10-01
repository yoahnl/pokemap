import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

final class RuntimeCaptureSpriteResolver {
  RuntimeCaptureSpriteResolver({
    required this.projectRootDirectory,
    required this.pokemonConfig,
  });

  final String projectRootDirectory;
  final ProjectPokemonConfig pokemonConfig;

  Future<String?> resolve(String itemId) async {
    final normalizedId = itemId.trim();
    if (!pokemonConfig.enabled || normalizedId.isEmpty) return null;
    try {
      final root = await Directory(projectRootDirectory).resolveSymbolicLinks();
      final catalogPath = await _existingProjectFile(
        root,
        pokemonConfig.catalogFiles['items'],
      );
      if (catalogPath == null) return null;
      final catalog = decodeProjectItemCatalog(
        jsonDecode(await File(catalogPath).readAsString()),
      );
      final matches =
          catalog.entries.where((entry) => entry.id == normalizedId);
      if (matches.length != 1) return null;
      final spritePath = matches.single.capture?.animationSpritePath;
      if (spritePath == null ||
          !ProjectCaptureItemDefinition.isValidAnimationSpritePath(
              spritePath)) {
        return null;
      }
      final resolved = await _existingProjectFile(root, spritePath);
      if (resolved == null) return null;
      final bytes = await File(resolved).readAsBytes();
      if (!_hasCaptureSheetHeader(bytes)) return null;
      final decoded = image.decodePng(bytes);
      return decoded?.width == 64 && decoded?.height == 2048 ? resolved : null;
    } on Object {
      return null;
    }
  }

  Future<String?> _existingProjectFile(String root, String? rawPath) async {
    final path = rawPath?.trim();
    if (path == null ||
        path.isEmpty ||
        path.contains('\\') ||
        path.contains('\u0000') ||
        p.posix.isAbsolute(path) ||
        p.windows.isAbsolute(path) ||
        Uri.tryParse(path)?.hasScheme == true ||
        path.split('/').any((segment) =>
            segment.isEmpty || segment == '.' || segment == '..')) {
      return null;
    }
    final file = File(p.join(root, path));
    if (!await file.exists()) return null;
    final resolved = await file.resolveSymbolicLinks();
    return p.isWithin(root, resolved) ? resolved : null;
  }

  bool _hasCaptureSheetHeader(Uint8List bytes) {
    const header = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < 33) return false;
    for (var index = 0; index < header.length; index++) {
      if (bytes[index] != header[index]) return false;
    }
    if (bytes[12] != 73 ||
        bytes[13] != 72 ||
        bytes[14] != 68 ||
        bytes[15] != 82) {
      return false;
    }
    final data = ByteData.sublistView(bytes);
    return data.getUint32(16) == 64 && data.getUint32(20) == 2048;
  }
}
