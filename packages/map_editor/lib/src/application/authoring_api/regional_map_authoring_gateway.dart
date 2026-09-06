import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'authoring_mutation_adapter.dart';
import 'authoring_query_adapter.dart';
import 'presentation_studio_add_authoring_gateway.dart';

final class RegionalMapImageOption {
  const RegionalMapImageOption({
    required this.assetId,
    required this.path,
    required this.label,
  });

  final String assetId;
  final String path;
  final String label;
}

final class RegionalMapAuthoringSnapshot {
  const RegionalMapAuthoringSnapshot({
    required this.manifest,
    required this.revision,
    required this.images,
  });

  final ProjectManifest manifest;
  final String revision;
  final List<RegionalMapImageOption> images;
}

final class RegionalMapAuthoringGateway {
  RegionalMapAuthoringGateway({
    required AuthoringMutationAdapter mutations,
    required AuthoringQueryAdapter queries,
  }) : _mutations = mutations,
       _queries = queries;

  final AuthoringMutationAdapter _mutations;
  final AuthoringQueryAdapter _queries;
  int _sequence = 0;

  String createIdentity(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${++_sequence}';

  Future<RegionalMapAuthoringSnapshot> load(String root) async {
    await _queries.invalidate(root);
    final session = await _queries.open(root);
    final labels = <String, String>{
      for (final media in _list(session, 'presentationMedia'))
        if (media['sourceAssetId'] is String && media['label'] is String)
          media['sourceAssetId']! as String: media['label']! as String,
    };
    final images = <RegionalMapImageOption>[];
    for (final record in _list(session, 'asset')) {
      final artifact = record['artifact'];
      if (artifact is! Map ||
          !const {
            'image/png',
            'image/jpeg',
            'image/webp',
            'image/gif',
          }.contains(artifact['mediaType'])) {
        continue;
      }
      final id = record['id']! as String;
      final path = record['logicalPath']! as String;
      images.add(
        RegionalMapImageOption(
          assetId: id,
          path: path,
          label: labels[id] ?? p.posix.basename(path),
        ),
      );
    }
    images.sort((a, b) => a.label.compareTo(b.label));
    return RegionalMapAuthoringSnapshot(
      manifest: session.manifest,
      revision: session.snapshotRevision,
      images: List.unmodifiable(images),
    );
  }

  Future<Uint8List?> imageBytes(String root, String path) async {
    final session = await _queries.open(root);
    final asset = _list(
      session,
      'asset',
    ).where((record) => record['logicalPath'] == path).firstOrNull;
    if (asset == null) return null;
    final bytes = session.assetBytes(asset['id']! as String);
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  Future<RegionalMapAuthoringSnapshot> saveRegion(
    String root,
    RegionalMapAuthoringSnapshot before,
    ProjectRegionDefinition region,
  ) => _apply(root, before, 'regionalMap.region.upsert', {
    'region': region.toJson(),
  });

  Future<RegionalMapAuthoringSnapshot> savePoint(
    String root,
    RegionalMapAuthoringSnapshot before,
    ProjectRegionPointOfInterest point,
  ) => _apply(root, before, 'regionalMap.poi.upsert', {'poi': point.toJson()});

  Future<RegionalMapAuthoringSnapshot> deleteRegion(
    String root,
    RegionalMapAuthoringSnapshot before,
    String regionId,
  ) => _apply(root, before, 'regionalMap.region.delete', {
    'regionId': regionId,
  }, deleting: true);

  Future<RegionalMapAuthoringSnapshot> deletePoint(
    String root,
    RegionalMapAuthoringSnapshot before,
    String pointId,
  ) => _apply(root, before, 'regionalMap.poi.delete', {
    'poiId': pointId,
  }, deleting: true);

  Future<RegionalMapAuthoringSnapshot> importImage(
    String root,
    RegionalMapAuthoringSnapshot before,
    PresentationStudioPickedMedia picked,
  ) async {
    final extension = p.extension(picked.sourcePath).toLowerCase();
    final mediaType = switch (extension) {
      '.png' => 'image/png',
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => throw const FormatException(
        'Choisissez une image PNG, JPEG, WebP ou GIF.',
      ),
    };
    final staged = await _mutations.stageArtifact(
      root,
      sourcePath: picked.sourcePath,
      declaredMediaType: mediaType,
    );
    try {
      final id = createIdentity('regional-image');
      return await _apply(root, before, 'presentationMedia.import', {
        'artifactHandle': staged.reference.handle,
        'mediaId': id,
        'label': picked.label,
        'kind': 'image',
        'assetId': id,
        'logicalPath': 'assets/presentation/$id$extension',
      });
    } finally {
      await _mutations.releaseArtifact(root, handle: staged.reference.handle);
    }
  }

  Future<RegionalMapAuthoringSnapshot> _apply(
    String root,
    RegionalMapAuthoringSnapshot before,
    String action,
    Map<String, Object?> parameters, {
    bool deleting = false,
  }) async {
    final identity = createIdentity('regional-edit');
    final plan = await _mutations.plan(
      root,
      actionId: action,
      parameters: parameters,
      expectedRevision: before.revision,
      idempotencyKey: identity,
      requestId: identity,
    );
    final confirmation = deleting ? await _mutations.confirm(plan) : null;
    await _mutations.apply(
      plan,
      operationId: '$identity-apply',
      confirmationToken: confirmation,
    );
    return load(root);
  }

  List<Map<String, Object?>> _list(
    EditorAuthoringReadSession session,
    String kind,
  ) {
    final result = <Map<String, Object?>>[];
    String? cursor;
    do {
      final page = session.query(
        AuthoringQueryRequest(
          resourceKind: kind,
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
          pageSize: 200,
          cursor: cursor,
        ),
      );
      result.addAll(
        (page['items']! as List).map(
          (item) => Map<String, Object?>.from(item as Map),
        ),
      );
      cursor = page['nextCursor'] as String?;
    } while (cursor != null);
    return result;
  }
}
