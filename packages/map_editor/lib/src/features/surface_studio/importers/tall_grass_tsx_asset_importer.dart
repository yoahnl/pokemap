import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'tiled_tsx_animated_tileset_parser.dart';
import 'tiled_tsx_catalog_append.dart';
import 'tiled_tsx_surface_animation_importer.dart';
import 'tiled_tsx_workspace.dart';

final class TallGrassTsxAssetImportResult {
  const TallGrassTsxAssetImportResult({
    required this.manifest,
    required this.errors,
    required this.messages,
    required this.createdTileset,
    required this.tileset,
    required this.importedAnimationCount,
    required this.candidateAnimationIds,
    required this.visualCandidateTileIds,
    required this.sdkParticleTags,
    required this.loadedFileName,
  });

  final ProjectManifest? manifest;
  final List<String> errors;
  final List<String> messages;
  final bool createdTileset;
  final ProjectTilesetEntry? tileset;
  final int importedAnimationCount;
  final List<String> candidateAnimationIds;
  final List<int> visualCandidateTileIds;
  final List<int> sdkParticleTags;
  final String loadedFileName;

  bool get hasErrors => errors.isNotEmpty;
  bool get hasImportedAssets => manifest != null;
}

const _sdkGrassParticleTags = [1, 2];

TallGrassTsxAssetImportResult importTallGrassTsxAssets({
  required ProjectManifest manifest,
  required String? projectRootPath,
  required TiledTsxLoadedFile loadedFile,
}) {
  final audit = parseTiledTsxAnimatedTileset(loadedFile.xml);
  final parserErrors = <String>[
    if (audit.hasErrors) 'Le fichier XML TSX est invalide ou incomplet.',
    ...audit.diagnostics
        .where(
          (diagnostic) =>
              diagnostic.severity == TiledTsxDiagnosticSeverity.error,
        )
        .map((diagnostic) => diagnostic.message),
  ];
  if (parserErrors.isNotEmpty) {
    return _errorResult(
      loadedFileName: loadedFile.fileName,
      errors: parserErrors,
    );
  }

  final imageSource = audit.summary.imageSource.trim();
  if (imageSource.isEmpty) {
    return _errorResult(
      loadedFileName: loadedFile.fileName,
      errors: const ['Le TSX ne référence aucune image tileset.'],
    );
  }

  final existingTileset = _pickMatchingTileset(
    imageSource: imageSource,
    tilesets: manifest.tilesets,
  );
  var createdTileset = false;
  var imageImportMessages = const <String>[];
  late final ProjectTilesetEntry tileset;
  late final List<ProjectTilesetEntry> tilesets;
  if (existingTileset != null) {
    tileset = existingTileset;
    tilesets = manifest.tilesets;
  } else {
    final linked = _createLinkedTileset(
      manifest: manifest,
      projectRootPath: projectRootPath,
      loadedFile: loadedFile,
      imageSource: imageSource,
    );
    if (linked.errors.isNotEmpty || linked.tileset == null) {
      return _errorResult(
        loadedFileName: loadedFile.fileName,
        errors: linked.errors,
      );
    }
    createdTileset = true;
    tileset = linked.tileset!;
    tilesets = [...manifest.tilesets, tileset];
    imageImportMessages = linked.messages;
  }

  final prefix = _slugify(audit.summary.name);
  if (audit.summary.animationCount == 0) {
    return _importStaticTallGrassAtlas(
      manifest: manifest,
      tilesets: tilesets,
      audit: audit,
      loadedFile: loadedFile,
      tileset: tileset,
      atlasId: prefix,
      createdTileset: createdTileset,
      imageImportMessages: imageImportMessages,
    );
  }

  final imported = importTiledTsxSurfaceAnimations(
    audit: audit,
    options: TiledTsxSurfaceAnimationImportOptions(
      atlasId: prefix,
      tilesetId: tileset.id,
      animationIdPrefix: prefix,
      sortOrderBase: manifest.surfaceCatalog.animationCount,
    ),
  );
  if (imported.hasErrors || imported.atlas == null) {
    return _errorResult(
      loadedFileName: loadedFile.fileName,
      tileset: tileset,
      errors: imported.diagnostics
          .where(
            (diagnostic) =>
                diagnostic.severity ==
                TiledTsxSurfaceAnimationImportDiagnosticSeverity.error,
          )
          .map((diagnostic) => diagnostic.message)
          .toList(growable: false),
    );
  }

  final appended = appendTiledTsxSurfaceImportToCatalog(
    catalog: manifest.surfaceCatalog,
    atlas: imported.atlas!,
    animations: imported.animations,
  );
  if (appended.hasErrors || appended.catalog == null) {
    return _errorResult(
      loadedFileName: loadedFile.fileName,
      tileset: tileset,
      errors: appended.errors,
    );
  }

  final next = manifest.copyWith(
    tilesets: tilesets,
    surfaceCatalog: appended.catalog!,
  );
  final candidateAnimationIds = imported.animations
      .map((animation) => animation.id)
      .toList(growable: false);
  return TallGrassTsxAssetImportResult(
    manifest: next,
    errors: const <String>[],
    messages: [
      'Import hautes herbes prêt : ${imported.animations.length} animations candidates ajoutées.',
      ...imageImportMessages,
      'Tileset lié : ${tileset.name} · ${tileset.relativePath}',
      if (createdTileset) 'Entrée tileset ajoutée au manifest projet.',
    ],
    createdTileset: createdTileset,
    tileset: tileset,
    importedAnimationCount: imported.animations.length,
    candidateAnimationIds: candidateAnimationIds,
    visualCandidateTileIds: const <int>[],
    sdkParticleTags: _sdkGrassParticleTags,
    loadedFileName: loadedFile.fileName,
  );
}

TallGrassTsxAssetImportResult _importStaticTallGrassAtlas({
  required ProjectManifest manifest,
  required List<ProjectTilesetEntry> tilesets,
  required TiledTsxTilesetAudit audit,
  required TiledTsxLoadedFile loadedFile,
  required ProjectTilesetEntry tileset,
  required String atlasId,
  required bool createdTileset,
  required List<String> imageImportMessages,
}) {
  final atlas = ProjectSurfaceAtlas(
    id: atlasId,
    name: audit.summary.name,
    tilesetId: tileset.id,
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(
        width: audit.summary.tileWidth,
        height: audit.summary.tileHeight,
      ),
      gridSize: SurfaceAtlasGridSize(
        columns: audit.summary.columns,
        rows: _gridRowsFromImage(audit.summary),
      ),
      layout: SurfaceAtlasLayout.grid,
    ),
    sortOrder: manifest.surfaceCatalog.atlasCount,
  );
  final appended = appendTiledTsxSurfaceImportToCatalog(
    catalog: manifest.surfaceCatalog,
    atlas: atlas,
    animations: const <ProjectSurfaceAnimation>[],
  );
  if (appended.hasErrors || appended.catalog == null) {
    return _errorResult(
      loadedFileName: loadedFile.fileName,
      tileset: tileset,
      errors: appended.errors,
    );
  }

  final visualCandidateTileIds = _extractGrassVisualCandidateTileIds(
    loadedFile.xml,
  );
  final next = manifest.copyWith(
    tilesets: tilesets,
    surfaceCatalog: appended.catalog!,
  );
  return TallGrassTsxAssetImportResult(
    manifest: next,
    errors: const <String>[],
    messages: [
      'Import hautes herbes prêt : atlas statique lié, ${visualCandidateTileIds.length} tuiles candidates extraites.',
      'Particules SDK : TGrass -> 1, TTallGrass -> 2.',
      ...imageImportMessages,
      'Tileset lié : ${tileset.name} · ${tileset.relativePath}',
      if (createdTileset) 'Entrée tileset ajoutée au manifest projet.',
    ],
    createdTileset: createdTileset,
    tileset: tileset,
    importedAnimationCount: 0,
    candidateAnimationIds: const <String>[],
    visualCandidateTileIds: visualCandidateTileIds,
    sdkParticleTags: _sdkGrassParticleTags,
    loadedFileName: loadedFile.fileName,
  );
}

TallGrassTsxAssetImportResult _errorResult({
  required String loadedFileName,
  required List<String> errors,
  ProjectTilesetEntry? tileset,
}) {
  return TallGrassTsxAssetImportResult(
    manifest: null,
    errors: List<String>.unmodifiable(errors),
    messages: const <String>[],
    createdTileset: false,
    tileset: tileset,
    importedAnimationCount: 0,
    candidateAnimationIds: const <String>[],
    visualCandidateTileIds: const <int>[],
    sdkParticleTags: const <int>[],
    loadedFileName: loadedFileName,
  );
}

ProjectTilesetEntry? _pickMatchingTileset({
  required String imageSource,
  required List<ProjectTilesetEntry> tilesets,
}) {
  final sourceBase = p.basename(imageSource).toLowerCase();
  for (final tileset in tilesets) {
    if (p.basename(tileset.relativePath).toLowerCase() == sourceBase) {
      return tileset;
    }
  }
  return null;
}

_LinkedTilesetResult _createLinkedTileset({
  required ProjectManifest manifest,
  required String? projectRootPath,
  required TiledTsxLoadedFile loadedFile,
  required String imageSource,
}) {
  final root = projectRootPath?.trim();
  if (root == null || root.isEmpty) {
    return const _LinkedTilesetResult(
      tileset: null,
      errors: [
        'Projet sans racine disque : impossible de lier automatiquement l’image TSX.',
      ],
    );
  }

  final tsxDirectory = p.dirname(p.absolute(loadedFile.path));
  final imagePath = p.normalize(p.join(tsxDirectory, imageSource));
  if (!File(imagePath).existsSync()) {
    return _LinkedTilesetResult(
      tileset: null,
      errors: ['Image TSX introuvable : $imagePath'],
    );
  }

  final projectRoot = p.normalize(p.absolute(root));
  final normalizedImagePath = p.normalize(p.absolute(imagePath));
  late _ImportedTilesetImage importedImage;
  if (_isWithinOrSame(projectRoot, normalizedImagePath)) {
    importedImage = _ImportedTilesetImage(
      absolutePath: normalizedImagePath,
      relativePath: p
          .relative(normalizedImagePath, from: projectRoot)
          .replaceAll(r'\', '/'),
      messages: const <String>[],
    );
  } else {
    final destination = _projectTilesetImageDestination(
      sourceImagePath: normalizedImagePath,
      projectRoot: projectRoot,
    );
    try {
      importedImage = _copyImageIntoProjectTilesets(
        sourceImagePath: normalizedImagePath,
        destination: destination,
      );
    } on FileSystemException catch (error) {
      importedImage = _ImportedTilesetImage(
        absolutePath: destination.absolutePath,
        relativePath: destination.relativePath,
        messages: [
          'Image TSX non copiée dans le projet : ${_describeFileSystemError(error)}.',
          'Données TSX importées avec l’emplacement prévu : ${destination.relativePath}.',
        ],
      );
    }
  }
  final relativePath = importedImage.relativePath;
  final baseName = p.basenameWithoutExtension(relativePath);
  return _LinkedTilesetResult(
    tileset: ProjectTilesetEntry(
      id: _uniqueTilesetId(
        baseId: _slugify(baseName),
        existingIds: manifest.tilesets.map((tileset) => tileset.id).toSet(),
      ),
      name: _displayName(baseName),
      relativePath: relativePath,
      sortOrder: _nextTilesetSortOrder(manifest.tilesets),
    ),
    errors: const <String>[],
    messages: importedImage.messages,
  );
}

_ProjectTilesetImageDestination _projectTilesetImageDestination({
  required String sourceImagePath,
  required String projectRoot,
}) {
  final ext = p.extension(sourceImagePath).toLowerCase();
  final preferredBase = _sanitizeFileName(
    p.basenameWithoutExtension(sourceImagePath),
  );
  final baseName = preferredBase.isEmpty ? 'tileset' : preferredBase;
  final destinationDir = p.join(projectRoot, 'assets', 'tilesets');

  var fileName = '$baseName$ext';
  var destinationPath = p.join(destinationDir, fileName);
  var suffix = 1;
  while (File(destinationPath).existsSync()) {
    fileName = '${baseName}_$suffix$ext';
    destinationPath = p.join(destinationDir, fileName);
    suffix++;
  }

  return _ProjectTilesetImageDestination(
    absolutePath: destinationPath,
    relativePath: p.posix.join('assets', 'tilesets', fileName),
  );
}

String _describeFileSystemError(FileSystemException error) {
  final osMessage = error.osError?.message.trim();
  if (osMessage != null && osMessage.isNotEmpty) {
    return osMessage;
  }
  final message = error.message.trim();
  return message.isEmpty ? 'accès fichier refusé' : message;
}

bool _isWithinOrSame(String parent, String child) {
  return child == parent || p.isWithin(parent, child);
}

int _gridRowsFromImage(TiledTsxTilesetSummary summary) {
  final tileHeight = summary.tileHeight;
  final imageHeight = summary.imageHeight;
  if (tileHeight <= 0 || imageHeight <= 0) {
    return 1;
  }
  return (imageHeight / tileHeight).ceil();
}

List<int> _extractGrassVisualCandidateTileIds(String xml) {
  if (!_containsGrassWangColor(xml)) {
    return const <int>[];
  }
  final ids = <int>[];
  for (final match in RegExp(r'<wangtile\b([^>]*)>').allMatches(xml)) {
    final attrs = _parseXmlAttributes(match.group(1) ?? '');
    final tileId = int.tryParse(attrs['tileid'] ?? '');
    if (tileId != null) {
      ids.add(tileId);
    }
  }
  return List<int>.unmodifiable(ids);
}

bool _containsGrassWangColor(String xml) {
  for (final match in RegExp(r'<wangcolor\b([^>]*)>').allMatches(xml)) {
    final attrs = _parseXmlAttributes(match.group(1) ?? '');
    final name = (attrs['name'] ?? '').toLowerCase();
    if (name.contains('herbe') || name.contains('grass')) {
      return true;
    }
  }
  return false;
}

Map<String, String> _parseXmlAttributes(String raw) {
  final attrs = <String, String>{};
  final re = RegExp(r'([A-Za-z_:][A-Za-z0-9_:.-]*)\s*=\s*"([^"]*)"');
  for (final match in re.allMatches(raw)) {
    attrs[match.group(1)!] = _decodeXmlEntities(match.group(2)!);
  }
  return attrs;
}

String _decodeXmlEntities(String value) {
  return value
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');
}

int _nextTilesetSortOrder(List<ProjectTilesetEntry> tilesets) {
  if (tilesets.isEmpty) {
    return 0;
  }
  return tilesets
          .map((tileset) => tileset.sortOrder)
          .reduce((a, b) => a > b ? a : b) +
      1;
}

String _uniqueTilesetId({
  required String baseId,
  required Set<String> existingIds,
}) {
  if (!existingIds.contains(baseId)) {
    return baseId;
  }
  var suffix = 2;
  while (existingIds.contains('$baseId-$suffix')) {
    suffix++;
  }
  return '$baseId-$suffix';
}

String _displayName(String value) {
  final cleaned = value
      .trim()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  return cleaned.isEmpty ? 'Tileset TSX' : cleaned;
}

_ImportedTilesetImage _copyImageIntoProjectTilesets({
  required String sourceImagePath,
  required _ProjectTilesetImageDestination destination,
}) {
  final destinationDir = Directory(p.dirname(destination.absolutePath));
  if (!destinationDir.existsSync()) {
    destinationDir.createSync(recursive: true);
  }
  final bytes = File(sourceImagePath).readAsBytesSync();
  File(destination.absolutePath).writeAsBytesSync(bytes, flush: true);
  return _ImportedTilesetImage(
    absolutePath: destination.absolutePath,
    relativePath: destination.relativePath,
    messages: [
      'Image TSX copiée dans le projet : ${destination.relativePath}.',
    ],
  );
}

String _sanitizeFileName(String value) {
  final normalized = value.trim().toLowerCase();
  final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
  return safe.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
}

String _slugify(String value) {
  final lower = value.trim().toLowerCase();
  final slug = lower
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'tsx-import' : slug;
}

final class _LinkedTilesetResult {
  const _LinkedTilesetResult({
    required this.tileset,
    required this.errors,
    this.messages = const <String>[],
  });

  final ProjectTilesetEntry? tileset;
  final List<String> errors;
  final List<String> messages;
}

final class _ProjectTilesetImageDestination {
  const _ProjectTilesetImageDestination({
    required this.absolutePath,
    required this.relativePath,
  });

  final String absolutePath;
  final String relativePath;
}

final class _ImportedTilesetImage {
  const _ImportedTilesetImage({
    required this.absolutePath,
    required this.relativePath,
    required this.messages,
  });

  final String absolutePath;
  final String relativePath;
  final List<String> messages;
}
