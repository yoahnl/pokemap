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
    required this.displayName,
    required this.tsx,
    required this.importId,
    required this.document,
  });

  final String tsxPath;
  final String imagePath;
  final String displayName;
  final String tsx;
  final String importId;
  final TiledWangTilesetDocument document;
}

final class SmartTileTiledWangImportServiceException implements Exception {
  const SmartTileTiledWangImportServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() =>
      'SmartTileTiledWangImportServiceException($code): $message';
}

abstract interface class SmartTileTiledWangSourcePicker {
  Future<SmartTileTiledWangSource?> pick();
}

final class FilePickerSmartTileTiledWangSourcePicker
    implements SmartTileTiledWangSourcePicker {
  const FilePickerSmartTileTiledWangSourcePicker();

  @override
  Future<SmartTileTiledWangSource?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['tsx'],
      allowMultiple: false,
      withData: false,
    );
    final path = result?.files.singleOrNull?.path;
    if (path == null || path.trim().isEmpty) return null;
    return loadSmartTileTiledWangSource(path);
  }
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
  late final TiledWangTilesetDocument document;
  try {
    tsx = await file.readAsString();
    document = parseTiledWangTileset(tsx);
  } on TiledTilesetImportException catch (error) {
    throw SmartTileTiledWangImportServiceException(error.code, error.message);
  } on FileSystemException {
    throw const SmartTileTiledWangImportServiceException(
      'smart_tile.tiled_wang.tsx_unreadable',
      'Le fichier TSX sélectionné ne peut pas être lu.',
    );
  }
  final imageSource = document.imageSource.replaceAll('/', p.separator);
  final imagePath = p.normalize(
    p.isAbsolute(imageSource)
        ? imageSource
        : p.join(p.dirname(canonicalPath), imageSource),
  );
  if (!await File(imagePath).exists()) {
    throw SmartTileTiledWangImportServiceException(
      'smart_tile.tiled_wang.image_missing',
      'L’image atlas référencée par le TSX est introuvable : '
          '${document.imageSource}',
    );
  }
  late final img.Image decodedImage;
  try {
    final imageBytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw const FormatException('Unsupported image');
    }
    decodedImage = decoded;
  } on FileSystemException {
    throw const SmartTileTiledWangImportServiceException(
      'smart_tile.tiled_wang.image_unreadable',
      'L’image atlas référencée par le TSX ne peut pas être lue.',
    );
  } on FormatException {
    throw const SmartTileTiledWangImportServiceException(
      'smart_tile.tiled_wang.image_unreadable',
      'L’image atlas référencée par le TSX n’est pas décodable.',
    );
  }
  if (decodedImage.width != document.imageWidth ||
      decodedImage.height != document.imageHeight) {
    throw const SmartTileTiledWangImportServiceException(
      'smart_tile.tiled_wang.image_dimensions_mismatch',
      'Les dimensions réelles de l’image ne correspondent pas au TSX.',
    );
  }
  final digest = sha256.convert(utf8.encode(tsx)).toString().substring(0, 12);
  return SmartTileTiledWangSource(
    tsxPath: canonicalPath,
    imagePath: imagePath,
    displayName: p.basename(canonicalPath),
    tsx: tsx,
    importId: '${_slug(document.name)}-$digest',
    document: document,
  );
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
    try {
      compileTiledWangImport(
        document: source.document,
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

    final staged = await _gateway.stageExactFile(
      projectRootPath: projectRootPath,
      sourcePath: source.imagePath,
    );
    if (!staged.mediaType.startsWith('image/')) {
      throw const SmartTileTiledWangImportServiceException(
        'smart_tile.tiled_wang.image_media_type_invalid',
        'L’atlas référencé par le TSX doit être une image reconnue.',
      );
    }
    final suffix = staged.hexDigest.substring(0, 16);
    final assetId = 'smart-tile-image-$suffix';
    final tilesetId = 'smart-tile-tileset-$suffix';
    final logicalPath = assetBlobStorageKey(staged);
    final expected = compileTiledWangImport(
      document: source.document,
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
            '${source.importId}|$tilesetId|${staged.digest}|'
            '${jsonEncode(selectionJson)}',
          ),
        )
        .toString()
        .substring(0, 20);
    final applied = await _gateway.apply(
      projectRootPath: projectRootPath,
      actionId: 'tileset.tiled.import',
      parameters: <String, Object?>{
        'artifactHandle': staged.handle,
        'assetId': assetId,
        'logicalPath': logicalPath,
        'tilesetId': tilesetId,
        'displayName': source.document.name,
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
    if (!_containsExpectedBundle(canonical.manifest, expected)) {
      throw const SmartTileTiledWangImportServiceException(
        'smart_tile.tiled_wang.snapshot_mismatch',
        'Le snapshot canonique ne contient pas exactement l’import TSX/Wang.',
      );
    }
    return SmartTileTiledWangImportResult(
      manifest: canonical.manifest,
      presetIds: expected.presets.map((preset) => preset.id),
      receiptId: applied.receiptId,
    );
  }
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
