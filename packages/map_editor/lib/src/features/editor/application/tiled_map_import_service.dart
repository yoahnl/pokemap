import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../application/authoring_api/authoring_mutation_adapter.dart';
import '../../../application/authoring_api/authoring_query_adapter.dart';
import '../../../application/authoring_api/editor_receipt_presenter.dart';

final class TiledMapImportServiceException implements Exception {
  const TiledMapImportServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'TiledMapImportServiceException($code): $message';
}

abstract interface class TiledMapSourcePicker {
  Future<String?> pickTmxPath();
}

final class FilePickerTiledMapSourcePicker implements TiledMapSourcePicker {
  const FilePickerTiledMapSourcePicker();

  @override
  Future<String?> pickTmxPath() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['tmx'],
      allowMultiple: false,
      withData: false,
    );
    final path = result?.files.singleOrNull?.path;
    if (path == null || path.trim().isEmpty) return null;
    return p.normalize(p.absolute(path));
  }
}

final class TiledMapImportTilesetSource {
  TiledMapImportTilesetSource({
    required this.source,
    required this.tsxPath,
    required this.tsx,
    required this.document,
    required this.tilesetId,
    required this.assetId,
    required this.logicalPath,
    required Map<String, String> imagePaths,
  }) : imagePaths = Map<String, String>.unmodifiable(imagePaths);

  final String source;
  final String tsxPath;
  final String tsx;
  final TiledTilesetDocument document;
  final String tilesetId;
  final String assetId;
  final String logicalPath;
  final Map<String, String> imagePaths;

  bool get isImageCollection => document.layout is TiledImageCollectionLayout;
}

final class TiledMapImportSource {
  TiledMapImportSource({
    required this.tmxPath,
    required this.tmx,
    required this.document,
    required this.mapId,
    required this.displayName,
    required Iterable<TiledMapImportTilesetSource> tilesets,
  }) : tilesets = List<TiledMapImportTilesetSource>.unmodifiable(tilesets);

  final String tmxPath;
  final String tmx;
  final TiledMapDocument document;
  final String mapId;
  final String displayName;
  final List<TiledMapImportTilesetSource> tilesets;

  int get width => document.width;
  int get height => document.height;
  int get tileLayerCount =>
      _flattenLayers(document.layers).whereType<TiledMapTileLayer>().length;
  int get objectLayerCount =>
      _flattenLayers(document.layers).whereType<TiledMapObjectLayer>().length;
  int get objectCount => _flattenLayers(document.layers)
      .whereType<TiledMapObjectLayer>()
      .fold(0, (count, layer) => count + layer.objects.length);

  List<TiledMapImportLayerChoice> get layerChoices =>
      List<TiledMapImportLayerChoice>.unmodifiable(
        _layerChoices(document.layers),
      );
}

enum TiledMapImportLayerKind { tile, object }

final class TiledMapImportLayerChoice {
  const TiledMapImportLayerChoice({
    required this.sourceLayerId,
    required this.path,
    required this.kind,
    required this.sourceVisible,
  });

  final int sourceLayerId;
  final String path;
  final TiledMapImportLayerKind kind;
  final bool sourceVisible;

  TiledMapLayerImportMode get defaultMode => sourceVisible
      ? TiledMapLayerImportMode.render
      : TiledMapLayerImportMode.hidden;
}

final class TiledMapImportInspection {
  TiledMapImportInspection({
    required this.source,
    required this.plan,
    required Map<String, Object?> preview,
    required this.operationId,
  }) : preview = Map<String, Object?>.unmodifiable(preview);

  final TiledMapImportSource source;
  final EditorAuthoringMutationPlan plan;
  final Map<String, Object?> preview;
  final String operationId;
}

final class TiledMapImportResult {
  const TiledMapImportResult({
    required this.manifest,
    required this.map,
    required this.receiptId,
    required this.snapshotRevision,
  });

  final ProjectManifest manifest;
  final MapData map;
  final String receiptId;
  final String snapshotRevision;
}

/// Resolves one generic TMX dependency closure and delegates the entire import
/// to the canonical, recoverable `map.tiled.import` mutation.
///
/// Machine paths exist only while reading the user-selected dependency graph
/// and staging exact files. Plans, receipts and project documents receive only
/// TMX-relative sources and opaque artifact handles.
final class TiledMapImportService {
  const TiledMapImportService({
    required AuthoringMutationAdapter mutations,
    required AuthoringQueryAdapter queries,
  })  : _mutations = mutations,
        _queries = queries;

  final AuthoringMutationAdapter _mutations;
  final AuthoringQueryAdapter _queries;

  Future<TiledMapImportInspection> inspect({
    required String projectRootPath,
    required String tmxPath,
    String? sourceRootPath,
  }) async {
    final source = await loadTiledMapImportSource(
      tmxPath,
      sourceRootPath: sourceRootPath,
    );
    return inspectSource(
      projectRootPath: projectRootPath,
      source: source,
    );
  }

  Future<TiledMapImportInspection> inspectSource({
    required String projectRootPath,
    required TiledMapImportSource source,
    Map<int, TiledMapLayerImportMode> layerModes =
        const <int, TiledMapLayerImportMode>{},
  }) async {
    final tilesetParameters = <Object?>[];
    final stagedDigests = <String>[];
    final stagedTmx = await _mutations.stageArtifact(
      projectRootPath,
      sourcePath: source.tmxPath,
    );
    stagedDigests.add(stagedTmx.reference.digest);
    for (final tileset in source.tilesets) {
      final imageArtifacts = <Object?>[];
      for (final dependency in tileset.document.dependencyClosure.images) {
        final imagePath = tileset.imagePaths[dependency.source];
        if (imagePath == null) {
          throw TiledMapImportServiceException(
            'map.tiled.image_missing',
            'La dépendance ${dependency.source} n’a pas été résolue.',
          );
        }
        final staged = await _mutations.stageArtifact(
          projectRootPath,
          sourcePath: imagePath,
        );
        if (!staged.reference.mediaType.startsWith('image/')) {
          throw TiledMapImportServiceException(
            'map.tiled.image_media_type_invalid',
            '${dependency.source} n’est pas une image raster reconnue.',
          );
        }
        stagedDigests.add(staged.reference.digest);
        imageArtifacts.add(<String, Object?>{
          'source': dependency.source,
          'artifactHandle': staged.reference.handle,
        });
      }
      tilesetParameters.add(<String, Object?>{
        'source': tileset.source,
        'tsx': tileset.tsx,
        'tilesetId': tileset.tilesetId,
        'assetId': tileset.assetId,
        'logicalPath': tileset.logicalPath,
        'imageArtifacts': imageArtifacts,
      });
    }
    stagedDigests.sort();
    final sortedLayerModes = layerModes.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));
    final layerModeFingerprint = sortedLayerModes
        .map((entry) => '${entry.key}:${entry.value.name}')
        .join('|');
    final fingerprint = sha256
        .convert(
          utf8.encode(
            '${source.mapId}|${sha256.convert(utf8.encode(source.tmx))}|'
            '${stagedDigests.join('|')}|$layerModeFingerprint',
          ),
        )
        .toString()
        .substring(0, 24);
    final idempotencyKey = 'editor-tmx-import-$fingerprint';
    try {
      final plan = await _mutations.plan(
        projectRootPath,
        actionId: 'map.tiled.import',
        parameters: <String, Object?>{
          'mapId': source.mapId,
          'displayName': source.displayName,
          'role': 'exterior',
          'tmxArtifactHandle': stagedTmx.reference.handle,
          'tilesets': tilesetParameters,
          if (sortedLayerModes.isNotEmpty)
            'layerModes': <String, Object?>{
              for (final entry in sortedLayerModes)
                '${entry.key}': entry.value.name,
            },
        },
        idempotencyKey: idempotencyKey,
        requestId: idempotencyKey,
      );
      return TiledMapImportInspection(
        source: source,
        plan: plan,
        preview: plan.preview,
        operationId: '$idempotencyKey-apply',
      );
    } on EditorAuthoringMutationFailure catch (error) {
      throw TiledMapImportServiceException(error.code, error.message);
    }
  }

  Future<TiledMapImportResult> apply(
      TiledMapImportInspection inspection) async {
    try {
      final applied = await _mutations.apply(
        inspection.plan,
        operationId: inspection.operationId,
      );
      final canonical = await _queries.open(inspection.plan.projectRootPath);
      if (canonical.snapshotRevision != applied.snapshotRevision) {
        throw const TiledMapImportServiceException(
          'map.tiled.snapshot_stale',
          'Le snapshot canonique après import TMX est obsolète.',
        );
      }
      final map = canonical.mapById(inspection.source.mapId);
      if (map == null) {
        throw const TiledMapImportServiceException(
          'map.tiled.snapshot_mismatch',
          'La carte importée est absente du snapshot canonique.',
        );
      }
      return TiledMapImportResult(
        manifest: canonical.manifest,
        map: map,
        receiptId: applied.receipt.receiptId,
        snapshotRevision: applied.snapshotRevision,
      );
    } on EditorAuthoringMutationFailure catch (error) {
      throw TiledMapImportServiceException(error.code, error.message);
    }
  }
}

Future<TiledMapImportSource> loadTiledMapImportSource(
  String tmxPath, {
  String? sourceRootPath,
}) async {
  var canonicalPath = p.normalize(p.absolute(tmxPath));
  final tmxFile = File(canonicalPath);
  if (!await tmxFile.exists()) {
    throw const TiledMapImportServiceException(
      'map.tiled.tmx_missing',
      'Le fichier TMX sélectionné est introuvable.',
    );
  }
  final canonicalSourceRoot = await _canonicalSourceRoot(sourceRootPath);
  if (canonicalSourceRoot != null) {
    canonicalPath = await _requireFileWithinSourceRoot(
      tmxFile,
      canonicalSourceRoot,
    );
  }
  late final String tmx;
  late final TiledMapDocument document;
  try {
    tmx = await tmxFile.readAsString();
    document = parseTiledMap(tmx);
  } on TiledMapImportException catch (error) {
    throw TiledMapImportServiceException(error.code, error.message);
  } on FileSystemException {
    throw const TiledMapImportServiceException(
      'map.tiled.tmx_unreadable',
      'Le fichier TMX sélectionné ne peut pas être lu.',
    );
  }

  final tilesets = <TiledMapImportTilesetSource>[];
  for (final reference in document.dependencyClosure.tilesets) {
    var tsxPath = _resolveDependency(canonicalPath, reference.source);
    final tsxFile = File(tsxPath);
    if (!await tsxFile.exists()) {
      throw TiledMapImportServiceException(
        'map.tiled.tsx_missing',
        'Le tileset ${reference.source} référencé par le TMX est introuvable.',
      );
    }
    if (canonicalSourceRoot != null) {
      tsxPath = await _requireFileWithinSourceRoot(
        tsxFile,
        canonicalSourceRoot,
      );
    }
    late final String tsx;
    late final TiledTilesetDocument tilesetDocument;
    try {
      tsx = await tsxFile.readAsString();
      tilesetDocument = parseTiledTileset(tsx);
    } on TiledTilesetImportException catch (error) {
      throw TiledMapImportServiceException(error.code, error.message);
    } on FileSystemException {
      throw TiledMapImportServiceException(
        'map.tiled.tsx_unreadable',
        'Le tileset ${reference.source} ne peut pas être lu.',
      );
    }
    final imagePaths = <String, String>{};
    for (final dependency in tilesetDocument.dependencyClosure.images) {
      var imagePath = _resolveDependency(tsxPath, dependency.source);
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw TiledMapImportServiceException(
          'map.tiled.image_missing',
          'L’image ${dependency.source} référencée par '
              '${reference.source} est introuvable.',
        );
      }
      if (canonicalSourceRoot != null) {
        imagePath = await _requireFileWithinSourceRoot(
          imageFile,
          canonicalSourceRoot,
        );
      }
      imagePaths[dependency.source] = imagePath;
    }
    final suffix = sha256
        .convert(utf8.encode('${reference.source}\u0000$tsx'))
        .toString()
        .substring(0, 10);
    final baseId = '${_slug(tilesetDocument.name)}-$suffix';
    tilesets.add(
      TiledMapImportTilesetSource(
        source: reference.source,
        tsxPath: tsxPath,
        tsx: tsx,
        document: tilesetDocument,
        tilesetId: baseId,
        assetId: '$baseId-image',
        logicalPath: tilesetDocument.layout is TiledImageCollectionLayout
            ? 'assets/tilesets/$baseId'
            : 'assets/tilesets/$baseId.png',
        imagePaths: imagePaths,
      ),
    );
  }
  final mapName = p.basenameWithoutExtension(canonicalPath).trim();
  final mapSuffix = sha256.convert(utf8.encode(tmx)).toString().substring(0, 8);
  return TiledMapImportSource(
    tmxPath: canonicalPath,
    tmx: tmx,
    document: document,
    mapId: '${_slug(mapName)}-$mapSuffix',
    displayName: mapName.isEmpty ? 'Carte Tiled importée' : mapName,
    tilesets: tilesets,
  );
}

Future<String?> _canonicalSourceRoot(String? sourceRootPath) async {
  final normalized = sourceRootPath?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  final directory = Directory(p.normalize(p.absolute(normalized)));
  if (!await directory.exists()) {
    throw const TiledMapImportServiceException(
      'map.tiled.source_root_invalid',
      'La racine source Tiled sélectionnée est introuvable.',
    );
  }
  try {
    return p.normalize(await directory.resolveSymbolicLinks());
  } on FileSystemException {
    throw const TiledMapImportServiceException(
      'map.tiled.source_root_invalid',
      'La racine source Tiled sélectionnée ne peut pas être résolue.',
    );
  }
}

Future<String> _requireFileWithinSourceRoot(
  File file,
  String canonicalSourceRoot,
) async {
  late final String canonicalFile;
  try {
    canonicalFile = p.normalize(await file.resolveSymbolicLinks());
  } on FileSystemException {
    throw const TiledMapImportServiceException(
      'map.tiled.dependency_unreadable',
      'Une dépendance Tiled ne peut pas être résolue.',
    );
  }
  // A selected corpus root is a narrow capability. Canonical paths are checked
  // after symlink resolution so `..` segments and link escapes cannot broaden
  // the dependency closure staged by the editor transport.
  if (canonicalFile != canonicalSourceRoot &&
      !p.isWithin(canonicalSourceRoot, canonicalFile)) {
    throw const TiledMapImportServiceException(
      'map.tiled.dependency_outside_source_root',
      'Une dépendance Tiled sort de la racine source sélectionnée.',
    );
  }
  return canonicalFile;
}

String _resolveDependency(String ownerPath, String source) => p.normalize(
      p.join(
        p.dirname(ownerPath),
        source.replaceAll('/', p.separator),
      ),
    );

Iterable<TiledMapLayer> _flattenLayers(Iterable<TiledMapLayer> layers) sync* {
  for (final layer in layers) {
    yield layer;
    if (layer is TiledMapGroupLayer) yield* _flattenLayers(layer.layers);
  }
}

Iterable<TiledMapImportLayerChoice> _layerChoices(
  Iterable<TiledMapLayer> layers, {
  List<String> parentPath = const <String>[],
  bool parentVisible = true,
}) sync* {
  for (final layer in layers) {
    final name =
        layer.name.trim().isEmpty ? 'Calque ${layer.id}' : layer.name.trim();
    final path = <String>[...parentPath, name];
    final sourceVisible = parentVisible && layer.visible;
    switch (layer) {
      case TiledMapTileLayer():
        yield TiledMapImportLayerChoice(
          sourceLayerId: layer.id,
          path: path.join(' / '),
          kind: TiledMapImportLayerKind.tile,
          sourceVisible: sourceVisible,
        );
      case TiledMapObjectLayer():
        yield TiledMapImportLayerChoice(
          sourceLayerId: layer.id,
          path: path.join(' / '),
          kind: TiledMapImportLayerKind.object,
          sourceVisible: sourceVisible,
        );
      case TiledMapGroupLayer():
        yield* _layerChoices(
          layer.layers,
          parentPath: path,
          parentVisible: sourceVisible,
        );
    }
  }
}

String _slug(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final safe = normalized.isEmpty ? 'tiled' : normalized;
  return safe.length <= 48 ? safe : safe.substring(0, 48);
}
