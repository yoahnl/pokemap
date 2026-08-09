import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'smart_tile_source_asset_import_service.dart';

final class SmartTileTiledWangSource {
  const SmartTileTiledWangSource({
    required this.tsxPath,
    required this.imagePath,
    required this.imagePaths,
    required this.displayName,
    required this.tsx,
    required this.importId,
    required this.tilesetDocument,
    required this.document,
  });

  final String tsxPath;
  final String imagePath;
  final Map<String, String> imagePaths;
  final String displayName;
  final String tsx;
  final String importId;
  final TiledTilesetDocument tilesetDocument;
  final TiledWangTilesetDocument? document;

  bool get isImageCollection =>
      tilesetDocument.layout is TiledImageCollectionLayout;
}

final class SmartTileTiledWangImportServiceException implements Exception {
  const SmartTileTiledWangImportServiceException(
    this.code,
    this.message, {
    this.relatedPath,
  });

  final String code;
  final String message;
  final String? relatedPath;

  @override
  String toString() =>
      'SmartTileTiledWangImportServiceException($code): $message';
}

abstract interface class SmartTileTiledWangSourcePicker {
  Future<SmartTileTiledWangSource?> pick();
}

typedef SmartTileTiledWangTsxPathPicker = Future<String?> Function();
typedef SmartTileTiledWangDirectoryAuthorizer = Future<String?> Function({
  required String initialDirectory,
});
typedef SmartTileTiledWangSourceLoader = Future<SmartTileTiledWangSource>
    Function(String tsxPath);

final class FilePickerSmartTileTiledWangSourcePicker
    implements SmartTileTiledWangSourcePicker {
  const FilePickerSmartTileTiledWangSourcePicker({
    this.pickTsxPath = _pickSmartTileTiledWangTsxPath,
    this.authorizeDirectory = _authorizeSmartTileTiledWangDirectory,
    this.loadSource = loadSmartTileTiledWangSource,
  });

  final SmartTileTiledWangTsxPathPicker pickTsxPath;
  final SmartTileTiledWangDirectoryAuthorizer authorizeDirectory;
  final SmartTileTiledWangSourceLoader loadSource;

  @override
  Future<SmartTileTiledWangSource?> pick() async {
    final path = await pickTsxPath();
    if (path == null || path.trim().isEmpty) return null;
    try {
      return await loadSource(path);
    } on SmartTileTiledWangImportServiceException catch (error) {
      if (error.code != 'smart_tile.tiled_wang.image_access_denied' ||
          error.relatedPath == null) {
        rethrow;
      }
      final initialDirectory = _commonSourceDirectory(
        p.dirname(path),
        p.dirname(error.relatedPath!),
      );
      final authorizedDirectory = await authorizeDirectory(
        initialDirectory: initialDirectory,
      );
      if (authorizedDirectory == null || authorizedDirectory.trim().isEmpty) {
        throw const SmartTileTiledWangImportServiceException(
          'smart_tile.tiled_wang.source_directory_authorization_cancelled',
          'Import annulé : PokeMap doit pouvoir autoriser le dossier source '
              'qui contient le TSX et ses images.',
        );
      }
      return loadSource(path);
    }
  }
}

Future<String?> _pickSmartTileTiledWangTsxPath() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const <String>['tsx'],
    allowMultiple: false,
    withData: false,
  );
  return result?.files.singleOrNull?.path;
}

Future<String?> _authorizeSmartTileTiledWangDirectory({
  required String initialDirectory,
}) {
  return FilePicker.getDirectoryPath(
    dialogTitle: 'Autoriser le dossier source du tileset',
    initialDirectory: initialDirectory,
  );
}

String _commonSourceDirectory(String first, String second) {
  final firstParts = p.split(p.normalize(p.absolute(first)));
  final secondParts = p.split(p.normalize(p.absolute(second)));
  final length = firstParts.length < secondParts.length
      ? firstParts.length
      : secondParts.length;
  var commonLength = 0;
  while (commonLength < length &&
      firstParts[commonLength] == secondParts[commonLength]) {
    commonLength++;
  }
  if (commonLength == 0) return p.dirname(first);
  return p.normalize(p.joinAll(firstParts.take(commonLength)));
}

Future<SmartTileTiledWangSource> loadSmartTileTiledWangSource(
  String tsxPath,
) async {
  final canonicalPath = p.normalize(p.absolute(tsxPath));
  final file = File(canonicalPath);
  if (!await file.exists()) {
    throw const SmartTileTiledWangImportServiceException(
      'smart_tile.tiled_wang.tsx_missing',
      'Le fichier TSX sélectionné est introuvable.',
    );
  }
  late final String tsx;
  late final TiledTilesetDocument tilesetDocument;
  TiledWangTilesetDocument? document;
  try {
    tsx = await file.readAsString();
    tilesetDocument = parseTiledTileset(tsx);
    if (tilesetDocument.layout is TiledRegularAtlasLayout) {
      document = parseTiledWangTileset(tsx);
    }
  } on TiledTilesetImportException catch (error) {
    throw SmartTileTiledWangImportServiceException(error.code, error.message);
  } on FileSystemException {
    throw const SmartTileTiledWangImportServiceException(
      'smart_tile.tiled_wang.tsx_unreadable',
      'Le fichier TSX sélectionné ne peut pas être lu.',
    );
  }
  final imagePaths = <String, String>{};
  for (final dependency in tilesetDocument.dependencyClosure.images) {
    final imageSource = dependency.source.replaceAll('/', p.separator);
    final imagePath = p.normalize(
      p.join(p.dirname(canonicalPath), imageSource),
    );
    if (!await File(imagePath).exists()) {
      throw SmartTileTiledWangImportServiceException(
        'smart_tile.tiled_wang.image_missing',
        'Une image référencée par le TSX est introuvable : '
            '${dependency.source}',
      );
    }
    late final img.DecodeInfo decodedImage;
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final decoder = img.findDecoderForData(imageBytes);
      final decoded = decoder?.startDecode(imageBytes);
      if (decoded == null) {
        throw const FormatException('Unsupported image');
      }
      decodedImage = decoded;
    } on FileSystemException catch (error) {
      if (_isFileAccessDenied(error)) {
        throw SmartTileTiledWangImportServiceException(
          'smart_tile.tiled_wang.image_access_denied',
          'PokeMap n’a pas l’autorisation de lire l’image '
              '${dependency.source}. Autorisez le dossier source du tileset.',
          relatedPath: imagePath,
        );
      }
      throw SmartTileTiledWangImportServiceException(
        'smart_tile.tiled_wang.image_unreadable',
        'L’image ${dependency.source} ne peut pas être lue.',
      );
    } on FormatException {
      throw SmartTileTiledWangImportServiceException(
        'smart_tile.tiled_wang.image_unreadable',
        'L’image ${dependency.source} n’est pas décodable.',
      );
    }
    if (decodedImage.width != dependency.pixelWidth ||
        decodedImage.height != dependency.pixelHeight) {
      throw SmartTileTiledWangImportServiceException(
        'smart_tile.tiled_wang.image_dimensions_mismatch',
        'Les dimensions réelles de ${dependency.source} ne correspondent '
            'pas au TSX.',
      );
    }
    imagePaths[dependency.source] = imagePath;
  }
  final digest = sha256.convert(utf8.encode(tsx)).toString().substring(0, 12);
  return SmartTileTiledWangSource(
    tsxPath: canonicalPath,
    imagePath: imagePaths.values.first,
    imagePaths: Map<String, String>.unmodifiable(imagePaths),
    displayName: p.basename(canonicalPath),
    tsx: tsx,
    importId: '${_slug(tilesetDocument.name)}-$digest',
    tilesetDocument: tilesetDocument,
    document: document,
  );
}

bool _isFileAccessDenied(FileSystemException error) {
  final errorCode = error.osError?.errorCode;
  return errorCode == 1 || errorCode == 13;
}

final class SmartTileTiledWangImportResult {
  SmartTileTiledWangImportResult({
    required this.manifest,
    required Iterable<String> presetIds,
    required this.receiptId,
  }) : presetIds = List<String>.unmodifiable(presetIds);

  final ProjectManifest manifest;
  final List<String> presetIds;
  final String receiptId;
}

/// Editor orchestration for the single canonical Tiled import boundary.
final class SmartTileTiledWangImportService {
  const SmartTileTiledWangImportService({
    required SmartTileSourceAssetGateway gateway,
  }) : _gateway = gateway;

  final SmartTileSourceAssetGateway _gateway;

  Future<SmartTileTiledWangImportResult> import({
    required String projectRootPath,
    required SmartTileTiledWangSource source,
    required Iterable<TiledWangSetSelection> selections,
  }) async {
    final selected = selections.toList(growable: false);
    final wangDocument = source.document;
    if (wangDocument != null) {
      try {
        compileTiledWangImport(
          document: wangDocument,
          importId: source.importId,
          tilesetId: 'pending-tileset',
          selections: selected,
        );
      } on TiledTilesetImportException catch (error) {
        throw SmartTileTiledWangImportServiceException(
          error.code,
          error.message,
        );
      }
    } else if (selected.isNotEmpty) {
      throw const SmartTileTiledWangImportServiceException(
        'smart_tile.tiled_wang.collection_selection_invalid',
        'Une collection d’images ne demande pas de rôle Wang.',
      );
    }

    final stagedBySource = <String, ContentArtifactRef>{};
    for (final dependency in source.tilesetDocument.dependencyClosure.images) {
      final sourcePath = source.imagePaths[dependency.source];
      if (sourcePath == null) {
        throw SmartTileTiledWangImportServiceException(
          'smart_tile.tiled_wang.image_missing',
          'La dépendance ${dependency.source} n’a pas été résolue.',
        );
      }
      final staged = await _gateway.stageExactFile(
        projectRootPath: projectRootPath,
        sourcePath: sourcePath,
      );
      if (!staged.mediaType.startsWith('image/')) {
        throw const SmartTileTiledWangImportServiceException(
          'smart_tile.tiled_wang.image_media_type_invalid',
          'Toutes les images référencées doivent être des rasters reconnus.',
        );
      }
      stagedBySource[dependency.source] = staged;
    }
    final stagedDigests = stagedBySource.values
        .map((item) => item.digest)
        .toList(growable: false)
      ..sort();
    final suffix = stagedBySource.length == 1
        ? stagedBySource.values.single.hexDigest.substring(0, 16)
        : sha256
            .convert(utf8.encode(stagedDigests.join('|')))
            .toString()
            .substring(0, 16);
    final assetId = 'smart-tile-image-$suffix';
    final tilesetId = 'smart-tile-tileset-$suffix';
    final logicalPath = source.isImageCollection
        ? 'assets/tilesets/$assetId'
        : assetBlobStorageKey(stagedBySource.values.single);
    final expected = wangDocument == null
        ? null
        : compileTiledWangImport(
            document: wangDocument,
            importId: source.importId,
            tilesetId: tilesetId,
            selections: selected,
          );
    final before = await _gateway.load(projectRootPath: projectRootPath);
    final selectionJson = <Object?>[
      for (final selection in selected)
        <String, Object?>{
          'wangSetIndex': selection.wangSetIndex,
          'usage': _usageName(selection.usage),
        },
    ];
    final fingerprint = sha256
        .convert(
          utf8.encode(
            '${source.importId}|$tilesetId|${stagedDigests.join('|')}|'
            '${jsonEncode(selectionJson)}',
          ),
        )
        .toString()
        .substring(0, 20);
    final applied = await _gateway.apply(
      projectRootPath: projectRootPath,
      actionId: 'tileset.tiled.import',
      parameters: <String, Object?>{
        if (!source.isImageCollection)
          'artifactHandle': stagedBySource.values.single.handle,
        if (source.isImageCollection)
          'imageArtifacts': <Object?>[
            for (final dependency
                in source.tilesetDocument.dependencyClosure.images)
              <String, Object?>{
                'source': dependency.source,
                'artifactHandle': stagedBySource[dependency.source]!.handle,
              },
          ],
        'assetId': assetId,
        'logicalPath': logicalPath,
        'tilesetId': tilesetId,
        'displayName': source.tilesetDocument.name,
        'tsx': source.tsx,
        'importId': source.importId,
        'selections': selectionJson,
        'tags': const <String>['smart-tile-source', 'tiled'],
        'usages': const <String>['smart-tiles-studio'],
      },
      expectedRevision: before.revision,
      idempotencyKey: 'smart-tile-tiled-import-$fingerprint',
    );
    final canonical = await _gateway.load(projectRootPath: projectRootPath);
    if (canonical.revision != applied.revision) {
      throw const SmartTileTiledWangImportServiceException(
        'smart_tile.tiled_wang.snapshot_stale',
        'Le snapshot canonique après import TSX/Wang est obsolète.',
      );
    }
    if (expected != null &&
        !_containsExpectedBundle(canonical.manifest, expected)) {
      throw const SmartTileTiledWangImportServiceException(
        'smart_tile.tiled_wang.snapshot_mismatch',
        'Le snapshot canonique ne contient pas exactement l’import TSX/Wang.',
      );
    }
    if (expected == null &&
        !_containsExpectedImageCollection(
          canonical.manifest,
          tilesetId: tilesetId,
          expectedTileIds: source.tilesetDocument.tiles.keys,
        )) {
      throw const SmartTileTiledWangImportServiceException(
        'smart_tile.tiled_wang.snapshot_mismatch',
        'Le snapshot canonique ne contient pas exactement la collection TSX.',
      );
    }
    return SmartTileTiledWangImportResult(
      manifest: canonical.manifest,
      presetIds: expected?.presets.map((preset) => preset.id) ?? const [],
      receiptId: applied.receiptId,
    );
  }
}

bool _containsExpectedImageCollection(
  ProjectManifest manifest, {
  required String tilesetId,
  required Iterable<int> expectedTileIds,
}) {
  final tileset = manifest.tilesets
      .where((candidate) => candidate.id == tilesetId)
      .singleOrNull;
  final source = tileset?.source;
  if (source is! ProjectImageCollectionTilesetSource) return false;
  final expected = expectedTileIds.toList()..sort();
  final actual = source.tileDefinitions.map((tile) => tile.tileId).toList()
    ..sort();
  return _sameInts(expected, actual);
}

bool _sameInts(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _containsExpectedBundle(
  ProjectManifest manifest,
  TiledWangImportBundle expected,
) {
  final catalog = manifest.smartTileCatalog;
  return catalog.atlases.contains(expected.atlas) &&
      expected.materials.every(catalog.materials.contains) &&
      expected.animations.every(catalog.animations.contains) &&
      expected.presets.every(catalog.presets.contains);
}

String _usageName(SmartTileUsage usage) => switch (usage) {
      SmartTileUsage.terrain => 'terrain',
      SmartTileUsage.path => 'path',
      SmartTileUsage.forestSurface => 'forest_surface',
    };

String _slug(String value) {
  final slug = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'tiled-wang' : slug;
}

extension<T> on Iterable<T> {
  T? get singleOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    final value = iterator.current;
    return iterator.moveNext() ? null : value;
  }
}
