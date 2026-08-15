import 'package:file_picker/file_picker.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import 'authoring_mutation_adapter.dart';
import 'authoring_query_adapter.dart';

enum PresentationStudioAddCategory {
  visual,
  text,
  audio,
  video,
  accessibility,
  marker,
}

enum PresentationStudioMediaAvailability {
  ready,
  missing,
  corrupt,
  unsupported,
}

final class PresentationStudioMediaCatalogItem {
  const PresentationStudioMediaCatalogItem({
    required this.id,
    required this.label,
    required this.kind,
    required this.availability,
    required this.metadataLabel,
    this.durationUs,
  });

  final String id;
  final String label;
  final ProjectMediaKind kind;
  final PresentationStudioMediaAvailability availability;
  final String metadataLabel;
  final int? durationUs;
}

final class PresentationStudioPickedMedia {
  const PresentationStudioPickedMedia({
    required this.sourcePath,
    required this.label,
  });

  final String sourcePath;
  final String label;
}

abstract interface class PresentationStudioMediaPicker {
  Future<PresentationStudioPickedMedia?> pick(
    PresentationStudioAddCategory category,
  );
}

final class FilePickerPresentationStudioMediaPicker
    implements PresentationStudioMediaPicker {
  const FilePickerPresentationStudioMediaPicker();

  @override
  Future<PresentationStudioPickedMedia?> pick(
    PresentationStudioAddCategory category,
  ) async {
    final extensions = switch (category) {
      PresentationStudioAddCategory.visual => <String>[
        'png',
        'jpg',
        'jpeg',
        'webp',
      ],
      PresentationStudioAddCategory.audio => <String>[
        'ogg',
        'wav',
        'mp3',
        'm4a',
      ],
      PresentationStudioAddCategory.video => <String>['mp4', 'webm', 'mov'],
      PresentationStudioAddCategory.accessibility => <String>['vtt'],
      PresentationStudioAddCategory.text ||
      PresentationStudioAddCategory.marker => const <String>[],
    };
    if (extensions.isEmpty) return null;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return null;
    return PresentationStudioPickedMedia(
      sourcePath: path,
      label: p.basename(path),
    );
  }
}

final class PresentationStudioMediaImportRequest {
  const PresentationStudioMediaImportRequest({
    required this.category,
    required this.picked,
  });

  final PresentationStudioAddCategory category;
  final PresentationStudioPickedMedia picked;
}

final class PresentationStudioMediaImportResult {
  const PresentationStudioMediaImportResult({
    required this.manifest,
    required this.media,
    required this.receiptId,
  });

  final ProjectManifest manifest;
  final PresentationStudioMediaCatalogItem media;
  final String receiptId;
}

final class PresentationStudioInsertionRequest {
  const PresentationStudioInsertionRequest({
    required this.asset,
    required this.category,
    required this.playheadUs,
    required this.durationUs,
    required this.label,
    this.mediaId,
    this.targetVisualFolderId,
  });

  final PresentationCinematicAsset asset;
  final PresentationStudioAddCategory category;
  final int playheadUs;
  final int durationUs;
  final String label;
  final String? mediaId;
  final String? targetVisualFolderId;
}

final class PresentationStudioInsertionResult {
  const PresentationStudioInsertionResult({
    required this.manifest,
    required this.receiptId,
    required this.trackId,
    required this.clipId,
    this.layerId,
  });

  final ProjectManifest manifest;
  final String receiptId;
  final String trackId;
  final String clipId;
  final String? layerId;
}

final class PresentationStudioImportCancelled implements Exception {
  const PresentationStudioImportCancelled();
}

abstract interface class PresentationStudioAddAuthoringGateway {
  Future<List<PresentationStudioMediaCatalogItem>> loadMedia(
    String projectRootPath,
  );

  Future<PresentationStudioMediaImportResult> importMedia(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required PresentationStudioMediaImportRequest request,
    required bool Function() isCancelled,
  });

  Future<PresentationStudioInsertionResult> insert(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required PresentationStudioInsertionRequest request,
  });
}

typedef PresentationStudioIdentityFactory = String Function(String prefix);

final class CanonicalPresentationStudioAddAuthoringGateway
    implements PresentationStudioAddAuthoringGateway {
  CanonicalPresentationStudioAddAuthoringGateway({
    required AuthoringMutationAdapter mutations,
    required AuthoringQueryAdapter queries,
    PresentationStudioIdentityFactory? identityFactory,
  }) : _mutations = mutations,
       _queries = queries,
       _identityFactory = identityFactory;

  final AuthoringMutationAdapter _mutations;
  final AuthoringQueryAdapter _queries;
  final PresentationStudioIdentityFactory? _identityFactory;
  int _sequence = 0;

  @override
  Future<List<PresentationStudioMediaCatalogItem>> loadMedia(
    String projectRootPath,
  ) async {
    final session = await _queries.open(projectRootPath);
    final media = _queryAll(session, 'presentationMedia');
    final assetIds = _queryAll(
      session,
      'asset',
    ).map((item) => item['id']).whereType<String>().toSet();
    return <PresentationStudioMediaCatalogItem>[
      for (final item in media) _catalogItem(item, assetIds),
    ]..sort((left, right) => left.label.compareTo(right.label));
  }

  @override
  Future<PresentationStudioMediaImportResult> importMedia(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required PresentationStudioMediaImportRequest request,
    required bool Function() isCancelled,
  }) async {
    if (isCancelled()) throw const PresentationStudioImportCancelled();
    final before = await _requireExpectedProject(
      projectRootPath,
      expectedProject,
    );
    final kind = _mediaKind(request.category);
    final staged = await _mutations.stageArtifact(
      projectRootPath,
      sourcePath: request.picked.sourcePath,
      declaredMediaType: _declaredMediaType(request.picked.sourcePath),
    );
    final handle = staged.reference.handle;
    try {
      if (isCancelled()) throw const PresentationStudioImportCancelled();
      final identity = _identity('presentation_media');
      final extension = p.extension(request.picked.sourcePath).toLowerCase();
      final mediaId = '${_slug(request.picked.label)}-$identity';
      final assetId = 'asset-$mediaId';
      final plan = await _mutations.plan(
        projectRootPath,
        actionId: 'presentationMedia.import',
        parameters: <String, Object?>{
          'artifactHandle': handle,
          'mediaId': mediaId,
          'label': request.picked.label,
          'kind': kind.id,
          'assetId': assetId,
          'logicalPath': 'assets/presentation/$mediaId$extension',
        },
        idempotencyKey: identity,
        requestId: '${identity}_request',
        expectedRevision: before.snapshotRevision,
      );
      if (isCancelled()) throw const PresentationStudioImportCancelled();
      final applied = await _mutations.apply(
        plan,
        operationId: '${identity}_apply',
      );
      final after = await _queries.open(projectRootPath);
      final loaded = await loadMedia(projectRootPath);
      final imported = loaded.singleWhere((item) => item.id == mediaId);
      return PresentationStudioMediaImportResult(
        manifest: after.manifest,
        media: imported,
        receiptId: applied.receipt.receiptId,
      );
    } finally {
      await _mutations.releaseArtifact(projectRootPath, handle: handle);
    }
  }

  @override
  Future<PresentationStudioInsertionResult> insert(
    String projectRootPath, {
    required ProjectManifest expectedProject,
    required PresentationStudioInsertionRequest request,
  }) async {
    final before = await _requireExpectedProject(
      projectRootPath,
      expectedProject,
    );
    final cinematic = expectedProject.presentationCinematics.singleWhere(
      (item) => item.id == request.asset.id,
    );
    _validateInsertion(cinematic, request);
    final identity = _identity('presentation_insert');
    final layerId = _requiresLayer(request.category) ? 'layer-$identity' : null;
    final trackId = 'track-$identity';
    final clipId = 'clip-$identity';
    final layer = layerId == null
        ? null
        : PresentationLayer(
            id: layerId,
            label: request.label,
            zIndex:
                cinematic.layers.fold<int>(
                  -1,
                  (maximum, item) =>
                      item.zIndex > maximum ? item.zIndex : maximum,
                ) +
                1,
          );
    final clip = _clip(request, clipId: clipId, layerId: layerId);
    final track = PresentationTrack(
      id: trackId,
      label: request.label,
      kind: clip.trackKind,
      clips: <PresentationClip>[clip],
    );
    final encoded = encodePresentationCinematicAsset(
      PresentationCinematicAsset(
        id: cinematic.id,
        title: cinematic.title,
        description: cinematic.description,
        durationUs: cinematic.durationUs,
        layers: layer == null
            ? const <PresentationLayer>[]
            : <PresentationLayer>[layer],
        tracks: <PresentationTrack>[track],
      ),
    );
    final plan = await _mutations.plan(
      projectRootPath,
      actionId: 'presentationTimeline.insert',
      parameters: <String, Object?>{
        'cinematicId': cinematic.id,
        'targetVisualFolderId': layer == null
            ? null
            : request.targetVisualFolderId,
        'layer': layer == null
            ? null
            : (encoded['layers']! as List<Object?>).single,
        'track': (encoded['tracks']! as List<Object?>).single,
      },
      idempotencyKey: identity,
      requestId: '${identity}_request',
      expectedRevision: before.snapshotRevision,
    );
    final applied = await _mutations.apply(
      plan,
      operationId: '${identity}_apply',
    );
    final after = await _queries.open(projectRootPath);
    return PresentationStudioInsertionResult(
      manifest: after.manifest,
      receiptId: applied.receipt.receiptId,
      trackId: trackId,
      clipId: clipId,
      layerId: layerId,
    );
  }

  Future<EditorAuthoringReadSession> _requireExpectedProject(
    String projectRootPath,
    ProjectManifest expectedProject,
  ) async {
    await _queries.invalidate(projectRootPath);
    final session = await _queries.open(projectRootPath);
    if (session.manifest != expectedProject) {
      throw const EditorConflictException(
        'Le projet a changé. Rechargez la cinématique avant de recommencer.',
      );
    }
    return session;
  }

  String _identity(String prefix) {
    final factory = _identityFactory;
    if (factory != null) return factory(prefix);
    _sequence += 1;
    return '${DateTime.now().toUtc().microsecondsSinceEpoch}-$_sequence';
  }
}

List<Map<String, Object?>> _queryAll(
  EditorAuthoringReadSession session,
  String resourceKind,
) {
  final records = <Map<String, Object?>>[];
  String? cursor;
  do {
    final response = session.query(
      AuthoringQueryRequest(
        resourceKind: resourceKind,
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
        pageSize: 200,
        cursor: cursor,
      ),
    );
    final items = response['items'];
    if (items is List) {
      records.addAll(<Map<String, Object?>>[
        for (final item in items)
          if (item is Map) Map<String, Object?>.from(item),
      ]);
    }
    cursor = response['nextCursor'] as String?;
  } while (cursor != null);
  return records;
}

PresentationStudioMediaCatalogItem _catalogItem(
  Map<String, Object?> item,
  Set<String> assetIds,
) {
  final kind = ProjectMediaKind.fromJson(item['kind']);
  final sourceAssetId = item['sourceAssetId'] as String;
  final metadata = item['technicalMetadata'];
  final technical = metadata is Map
      ? Map<String, Object?>.from(metadata)
      : const <String, Object?>{};
  final durationMilliseconds = technical['durationMilliseconds'] as int?;
  final availability = !assetIds.contains(sourceAssetId)
      ? PresentationStudioMediaAvailability.missing
      : _knownKind(kind)
      ? PresentationStudioMediaAvailability.ready
      : PresentationStudioMediaAvailability.unsupported;
  return PresentationStudioMediaCatalogItem(
    id: item['id']! as String,
    label: (item['label'] ?? item['name'])! as String,
    kind: kind,
    availability: availability,
    metadataLabel: _metadataLabel(kind, technical, availability),
    durationUs: durationMilliseconds == null
        ? null
        : durationMilliseconds * Duration.microsecondsPerMillisecond,
  );
}

String _metadataLabel(
  ProjectMediaKind kind,
  Map<String, Object?> metadata,
  PresentationStudioMediaAvailability availability,
) {
  if (availability == PresentationStudioMediaAvailability.missing) {
    return 'Fichier introuvable';
  }
  if (availability == PresentationStudioMediaAvailability.unsupported) {
    return 'Format non supporté';
  }
  final container = metadata['container']?.toString().toUpperCase();
  final width = metadata['width'];
  final height = metadata['height'];
  final duration = metadata['durationMilliseconds'];
  return <String>[
    container ?? kind.id.toUpperCase(),
    if (width is int && height is int) '$width × $height',
    if (duration is int) '${(duration / 1000).toStringAsFixed(1)} s',
  ].join(' · ');
}

ProjectMediaKind _mediaKind(PresentationStudioAddCategory category) =>
    switch (category) {
      PresentationStudioAddCategory.visual => ProjectMediaKind.image,
      PresentationStudioAddCategory.audio => ProjectMediaKind.audio,
      PresentationStudioAddCategory.video => ProjectMediaKind.video,
      PresentationStudioAddCategory.accessibility => ProjectMediaKind.captions,
      PresentationStudioAddCategory.text ||
      PresentationStudioAddCategory.marker => throw ArgumentError.value(
        category,
        'category',
        'does not import media',
      ),
    };

bool _knownKind(ProjectMediaKind kind) =>
    kind == ProjectMediaKind.image ||
    kind == ProjectMediaKind.poster ||
    kind == ProjectMediaKind.audio ||
    kind == ProjectMediaKind.video ||
    kind == ProjectMediaKind.captions;

bool _requiresLayer(PresentationStudioAddCategory category) =>
    category == PresentationStudioAddCategory.visual ||
    category == PresentationStudioAddCategory.video ||
    category == PresentationStudioAddCategory.text;

void _validateInsertion(
  PresentationCinematicAsset cinematic,
  PresentationStudioInsertionRequest request,
) {
  if (request.playheadUs < 0 || request.playheadUs > cinematic.durationUs) {
    throw ArgumentError.value(request.playheadUs, 'playheadUs');
  }
  final marker = request.category == PresentationStudioAddCategory.marker;
  if ((marker && request.durationUs != 0) ||
      (!marker && request.durationUs <= 0) ||
      request.playheadUs + request.durationUs > cinematic.durationUs) {
    throw ArgumentError.value(request.durationUs, 'durationUs');
  }
  final needsMedia =
      request.category != PresentationStudioAddCategory.text &&
      request.category != PresentationStudioAddCategory.marker;
  if (needsMedia != (request.mediaId != null)) {
    throw ArgumentError.value(request.mediaId, 'mediaId');
  }
}

PresentationClip _clip(
  PresentationStudioInsertionRequest request, {
  required String clipId,
  required String? layerId,
}) => switch (request.category) {
  PresentationStudioAddCategory.visual => PresentationVisualClip(
    id: clipId,
    startUs: request.playheadUs,
    durationUs: request.durationUs,
    layerId: layerId!,
    resourceId: request.mediaId!,
  ),
  PresentationStudioAddCategory.video => PresentationVisualClip(
    id: clipId,
    startUs: request.playheadUs,
    durationUs: request.durationUs,
    layerId: layerId!,
    resourceId: request.mediaId!,
    mediaKind: PresentationVisualMediaKind.video,
  ),
  PresentationStudioAddCategory.text => PresentationTextClip(
    id: clipId,
    startUs: request.playheadUs,
    durationUs: request.durationUs,
    layerId: layerId!,
    text: request.label,
  ),
  PresentationStudioAddCategory.audio => PresentationAudioClip(
    id: clipId,
    startUs: request.playheadUs,
    durationUs: request.durationUs,
    resourceId: request.mediaId!,
    audioKind: PresentationAudioKind.music,
    loop: true,
  ),
  PresentationStudioAddCategory.accessibility => PresentationCaptionClip(
    id: clipId,
    startUs: request.playheadUs,
    durationUs: request.durationUs,
    captionId: request.mediaId!,
  ),
  PresentationStudioAddCategory.marker => PresentationMarkerClip(
    id: clipId,
    startUs: request.playheadUs,
    label: request.label,
  ),
};

String _slug(String value) {
  final slug = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'media' : slug;
}

String? _declaredMediaType(String sourcePath) =>
    switch (p.extension(sourcePath).toLowerCase()) {
      '.png' => 'image/png',
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.webp' => 'image/webp',
      '.ogg' => 'audio/ogg',
      '.wav' => 'audio/wav',
      '.mp3' => 'audio/mpeg',
      '.m4a' => 'audio/mp4',
      '.mp4' => 'video/mp4',
      '.webm' => 'video/webm',
      '.mov' => 'video/quicktime',
      '.vtt' => 'text/vtt',
      _ => null,
    };
