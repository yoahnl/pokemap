import '../models/presentation_cinematic_asset.dart';
import '../models/project_media_catalog.dart';

enum PresentationMediaTargetPlatform {
  android,
  ios,
  macos,
  web,
  windows,
  linux,
}

abstract final class PresentationMediaPublicationDiagnosticCodes {
  static const mediaMissing = 'cinematic.presentation.media_missing';
  static const mediaUnsupported = 'cinematic.presentation.media_unsupported';
  static const budgetExceeded = 'cinematic.presentation.budget_exceeded';
  static const provenanceMissing = mediaUnsupported;
  static const licenseMissing = mediaUnsupported;
  static const metadataMissing = mediaUnsupported;
  static const fileBudgetExceeded = budgetExceeded;
  static const presentationBudgetExceeded = budgetExceeded;
  static const sequenceBudgetExceeded = budgetExceeded;
  static const sequencePayloadBudgetExceeded = budgetExceeded;
  static const resolutionBudgetExceeded = budgetExceeded;
  static const concurrentVideoBudgetExceeded = budgetExceeded;
}

abstract final class PresentationMediaPublicationConstraints {
  static const mediaReference = 'mediaReference';
  static const platformCompatibility = 'platformCompatibility';
  static const provenance = 'provenance';
  static const license = 'license';
  static const technicalMetadata = 'technicalMetadata';
  static const fileBytes = 'fileBytes';
  static const presentationPayloadBytes = 'presentationPayloadBytes';
  static const sequenceDurationUs = 'sequenceDurationUs';
  static const sequencePayloadBytes = 'sequencePayloadBytes';
  static const resolution = 'resolution';
  static const concurrentVideoDecoders = 'concurrentVideoDecoders';
}

final class PresentationMediaBudgetPolicy {
  const PresentationMediaBudgetPolicy({
    this.maxFileBytes = 268435456,
    this.maxPresentationPayloadBytes = 230686720,
    this.maxSequenceDurationUs = 900000000,
    this.maxImageDimension = 8192,
    this.maxImagePixels = 67108864,
    this.maxVideoLongEdge = 3840,
    this.maxVideoShortEdge = 2160,
    this.maxConcurrentVideoDecoders = 1,
    this.deviceCacheBytesStatus = 'profiledByBETA-CIN-032',
  });

  final int maxFileBytes;
  final int maxPresentationPayloadBytes;
  final int maxSequenceDurationUs;
  final int maxImageDimension;
  final int maxImagePixels;
  final int maxVideoLongEdge;
  final int maxVideoShortEdge;
  final int maxConcurrentVideoDecoders;
  final String deviceCacheBytesStatus;

  Map<String, Object?> toJson() => {
    'maxFileBytes': maxFileBytes,
    'maxPresentationPayloadBytes': maxPresentationPayloadBytes,
    'maxSequenceDurationUs': maxSequenceDurationUs,
    'maxImageDimension': maxImageDimension,
    'maxImagePixels': maxImagePixels,
    'maxVideoLongEdge': maxVideoLongEdge,
    'maxVideoShortEdge': maxVideoShortEdge,
    'maxConcurrentVideoDecoders': maxConcurrentVideoDecoders,
    'deviceCacheBytes': deviceCacheBytesStatus,
  };
}

final class PresentationMediaPublicationDiagnostic {
  const PresentationMediaPublicationDiagnostic({
    required this.code,
    required this.constraint,
    required this.path,
    required this.message,
    this.mediaId,
    this.cinematicId,
    this.platform,
  });

  final String code;
  final String constraint;
  final String path;
  final String message;
  final String? mediaId;
  final String? cinematicId;
  final PresentationMediaTargetPlatform? platform;

  Map<String, Object?> toJson() => {
    'code': code,
    'constraint': constraint,
    'severity': 'error',
    'path': path,
    'message': message,
    if (mediaId != null) 'mediaId': mediaId,
    if (cinematicId != null) 'cinematicId': cinematicId,
    if (platform != null) 'platform': platform!.name,
  };
}

final class PresentationMediaSequenceBudget {
  PresentationMediaSequenceBudget({
    required this.cinematicId,
    required this.durationUs,
    required this.payloadBytes,
    required this.estimatedDecodedVisualBytes,
    required this.maxConcurrentVideoDecoders,
    required Iterable<String> mediaIds,
  }) : mediaIds = List.unmodifiable(mediaIds.toList()..sort());

  final String cinematicId;
  final int durationUs;
  final int payloadBytes;
  final int estimatedDecodedVisualBytes;
  final int maxConcurrentVideoDecoders;
  final List<String> mediaIds;

  Map<String, Object?> toJson() => {
    'cinematicId': cinematicId,
    'durationUs': durationUs,
    'payloadBytes': payloadBytes,
    'estimatedDecodedVisualBytes': estimatedDecodedVisualBytes,
    'maxConcurrentVideoDecoders': maxConcurrentVideoDecoders,
    'mediaIds': mediaIds,
  };
}

final class PresentationMediaPlatformResolution {
  const PresentationMediaPlatformResolution({
    required this.mediaId,
    required this.resolvedMediaId,
    required this.compatible,
    this.fallbackMediaId,
  });

  final String mediaId;
  final String? resolvedMediaId;
  final String? fallbackMediaId;
  final bool compatible;

  Map<String, Object?> toJson() => {
    'mediaId': mediaId,
    'compatible': compatible,
    if (resolvedMediaId != null) 'resolvedMediaId': resolvedMediaId,
    if (fallbackMediaId != null) 'fallbackMediaId': fallbackMediaId,
  };
}

final class PresentationMediaPlatformReport {
  PresentationMediaPlatformReport({
    required this.platform,
    required this.payloadBytes,
    required this.estimatedDecodedVisualBytes,
    required Iterable<PresentationMediaPlatformResolution> resolutions,
    required Iterable<PresentationMediaPublicationDiagnostic> diagnostics,
  }) : resolutions = List.unmodifiable(
         resolutions.toList()
           ..sort((left, right) => left.mediaId.compareTo(right.mediaId)),
       ),
       diagnostics = List.unmodifiable(diagnostics);

  final PresentationMediaTargetPlatform platform;
  final int payloadBytes;
  final int estimatedDecodedVisualBytes;
  final List<PresentationMediaPlatformResolution> resolutions;
  final List<PresentationMediaPublicationDiagnostic> diagnostics;

  bool get canPublish => diagnostics.isEmpty;

  Map<String, Object?> toJson() => {
    'platform': platform.name,
    'canPublish': canPublish,
    'payloadBytes': payloadBytes,
    'estimatedDecodedVisualBytes': estimatedDecodedVisualBytes,
    'resolutions': resolutions.map((entry) => entry.toJson()).toList(),
    'diagnostics': diagnostics.map((entry) => entry.toJson()).toList(),
  };
}

final class PresentationMediaPublicationReceipt {
  PresentationMediaPublicationReceipt({
    required this.policy,
    required this.totalPayloadBytes,
    required this.estimatedDecodedVisualBytes,
    required Iterable<ProjectMediaAsset> media,
    required Iterable<PresentationMediaSequenceBudget> sequences,
    required Iterable<PresentationMediaPlatformReport> platforms,
    required Iterable<PresentationMediaPublicationDiagnostic> diagnostics,
  }) : media = List.unmodifiable(
         media.toList()..sort((a, b) => a.id.compareTo(b.id)),
       ),
       sequences = List.unmodifiable(
         sequences.toList()
           ..sort((a, b) => a.cinematicId.compareTo(b.cinematicId)),
       ),
       platforms = List.unmodifiable(
         platforms.toList()
           ..sort((a, b) => a.platform.name.compareTo(b.platform.name)),
       ),
       diagnostics = List.unmodifiable(diagnostics);

  final PresentationMediaBudgetPolicy policy;
  final int totalPayloadBytes;
  final int estimatedDecodedVisualBytes;
  final List<ProjectMediaAsset> media;
  final List<PresentationMediaSequenceBudget> sequences;
  final List<PresentationMediaPlatformReport> platforms;
  final List<PresentationMediaPublicationDiagnostic> diagnostics;

  bool get canPublish =>
      diagnostics.isEmpty && platforms.every((platform) => platform.canPublish);

  Map<String, Object?> toJson() => {
    'canPublish': canPublish,
    'totalPayloadBytes': totalPayloadBytes,
    'estimatedDecodedVisualBytes': estimatedDecodedVisualBytes,
    'budgets': policy.toJson(),
    'media': media.map(_publicationMediaJson).toList(),
    'sequences': sequences.map((entry) => entry.toJson()).toList(),
    'platforms': platforms.map((entry) => entry.toJson()).toList(),
    'diagnostics': diagnostics.map((entry) => entry.toJson()).toList(),
  };
}

final class PresentationMediaPublicationPreflight {
  const PresentationMediaPublicationPreflight();

  PresentationMediaPublicationReceipt inspect({
    required ProjectMediaCatalog catalog,
    required Iterable<PresentationCinematicAsset> cinematics,
    PresentationMediaBudgetPolicy policy =
        const PresentationMediaBudgetPolicy(),
    Set<PresentationMediaTargetPlatform> targetPlatforms =
        const <PresentationMediaTargetPlatform>{
          PresentationMediaTargetPlatform.android,
          PresentationMediaTargetPlatform.ios,
          PresentationMediaTargetPlatform.macos,
          PresentationMediaTargetPlatform.web,
          PresentationMediaTargetPlatform.windows,
          PresentationMediaTargetPlatform.linux,
        },
  }) {
    final orderedCinematics = cinematics.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final diagnostics = <PresentationMediaPublicationDiagnostic>[];
    final rootsByCinematic = <String, Set<String>>{};
    final allRoots = <String>{};
    for (final cinematic in orderedCinematics) {
      final roots = _rootMediaIds(cinematic);
      rootsByCinematic[cinematic.id] = roots;
      allRoots.addAll(roots);
      for (final mediaId in roots) {
        if (catalog.find(mediaId) == null) {
          diagnostics.add(
            PresentationMediaPublicationDiagnostic(
              code: PresentationMediaPublicationDiagnosticCodes.mediaMissing,
              constraint:
                  PresentationMediaPublicationConstraints.mediaReference,
              path: 'presentationCinematics[${cinematic.id}].media[$mediaId]',
              message: 'The cinematic references missing Presentation media.',
              mediaId: mediaId,
              cinematicId: cinematic.id,
            ),
          );
        }
      }
    }
    final allMediaIds = _relationshipClosure(catalog, allRoots);
    final media = (allMediaIds.toList()..sort())
        .map(catalog.find)
        .nonNulls
        .toList();
    for (final entry in media) {
      _inspectMedia(entry, policy, diagnostics);
    }
    final totalPayloadBytes = _payloadBytes(media);
    final estimatedDecodedVisualBytes = _estimatedDecodedVisualBytes(media);
    if (totalPayloadBytes > policy.maxPresentationPayloadBytes) {
      diagnostics.add(
        PresentationMediaPublicationDiagnostic(
          code: PresentationMediaPublicationDiagnosticCodes
              .presentationBudgetExceeded,
          constraint:
              PresentationMediaPublicationConstraints.presentationPayloadBytes,
          path: 'presentation.payloadBytes',
          message: 'The Presentation payload exceeds its authored budget.',
        ),
      );
    }
    final sequences = <PresentationMediaSequenceBudget>[];
    for (final cinematic in orderedCinematics) {
      final sequenceIds = _relationshipClosure(
        catalog,
        rootsByCinematic[cinematic.id]!,
      );
      final sequenceMedia = (sequenceIds.toList()..sort())
          .map(catalog.find)
          .nonNulls
          .toList();
      final payloadBytes = _payloadBytes(sequenceMedia);
      final maxConcurrentVideoDecoders = _maxConcurrentVideoDecoders(
        cinematic,
        catalog,
      );
      sequences.add(
        PresentationMediaSequenceBudget(
          cinematicId: cinematic.id,
          durationUs: cinematic.durationUs,
          payloadBytes: payloadBytes,
          estimatedDecodedVisualBytes: _estimatedDecodedVisualBytes(
            sequenceMedia,
          ),
          maxConcurrentVideoDecoders: maxConcurrentVideoDecoders,
          mediaIds: sequenceIds,
        ),
      );
      if (cinematic.durationUs > policy.maxSequenceDurationUs) {
        diagnostics.add(
          PresentationMediaPublicationDiagnostic(
            code: PresentationMediaPublicationDiagnosticCodes
                .sequenceBudgetExceeded,
            constraint:
                PresentationMediaPublicationConstraints.sequenceDurationUs,
            path: 'presentationCinematics[${cinematic.id}].durationUs',
            message: 'The cinematic exceeds the authored duration budget.',
            cinematicId: cinematic.id,
          ),
        );
      }
      if (payloadBytes > policy.maxPresentationPayloadBytes) {
        diagnostics.add(
          PresentationMediaPublicationDiagnostic(
            code: PresentationMediaPublicationDiagnosticCodes
                .sequencePayloadBudgetExceeded,
            constraint:
                PresentationMediaPublicationConstraints.sequencePayloadBytes,
            path: 'presentationCinematics[${cinematic.id}].payloadBytes',
            message: 'The cinematic exceeds the authored payload budget.',
            cinematicId: cinematic.id,
          ),
        );
      }
      if (maxConcurrentVideoDecoders > policy.maxConcurrentVideoDecoders) {
        diagnostics.add(
          PresentationMediaPublicationDiagnostic(
            code: PresentationMediaPublicationDiagnosticCodes
                .concurrentVideoBudgetExceeded,
            constraint:
                PresentationMediaPublicationConstraints.concurrentVideoDecoders,
            path:
                'presentationCinematics[${cinematic.id}].maxConcurrentVideoDecoders',
            message:
                'The cinematic exceeds the authored concurrent-video budget.',
            cinematicId: cinematic.id,
          ),
        );
      }
    }
    final platforms = <PresentationMediaPlatformReport>[];
    final orderedPlatforms = targetPlatforms.toList()
      ..sort((left, right) => left.name.compareTo(right.name));
    for (final platform in orderedPlatforms) {
      final resolutions = <PresentationMediaPlatformResolution>[];
      final platformDiagnostics = <PresentationMediaPublicationDiagnostic>[];
      for (final mediaId in allMediaIds.toList()..sort()) {
        final resolution = resolvePresentationMediaForPlatform(
          catalog,
          mediaId,
          platform,
        );
        resolutions.add(resolution);
        if (!resolution.compatible) {
          platformDiagnostics.add(
            PresentationMediaPublicationDiagnostic(
              code:
                  PresentationMediaPublicationDiagnosticCodes.mediaUnsupported,
              constraint:
                  PresentationMediaPublicationConstraints.platformCompatibility,
              path: 'platforms.${platform.name}.media[$mediaId]',
              message:
                  'The media has no compatible source or fallback for this platform.',
              mediaId: mediaId,
              platform: platform,
            ),
          );
        }
      }
      final resolvedMediaIds = resolutions
          .map((resolution) => resolution.resolvedMediaId)
          .nonNulls
          .toSet();
      final platformMediaIds = _relationshipClosure(catalog, resolvedMediaIds);
      final platformMedia = (platformMediaIds.toList()..sort())
          .map(catalog.find)
          .nonNulls
          .toList();
      platforms.add(
        PresentationMediaPlatformReport(
          platform: platform,
          payloadBytes: _payloadBytes(platformMedia),
          estimatedDecodedVisualBytes: _estimatedDecodedVisualBytes(
            platformMedia,
          ),
          resolutions: resolutions,
          diagnostics: platformDiagnostics,
        ),
      );
    }
    return PresentationMediaPublicationReceipt(
      policy: policy,
      totalPayloadBytes: totalPayloadBytes,
      estimatedDecodedVisualBytes: estimatedDecodedVisualBytes,
      media: media,
      sequences: sequences,
      platforms: platforms,
      diagnostics: <PresentationMediaPublicationDiagnostic>[
        ...diagnostics,
        ...platforms.expand((platform) => platform.diagnostics),
      ],
    );
  }
}

Map<String, Object?> _publicationMediaJson(ProjectMediaAsset media) => {
  'id': media.id,
  'kind': media.kind.id,
  'sourceAssetId': media.sourceAssetId,
  if (media.technicalMetadata != null)
    'technicalMetadata': media.technicalMetadata!.toJson(),
  if (media.provenance != null) 'provenance': media.provenance!.toJson(),
  if (media.license != null) 'license': media.license!.toJson(),
  if (media.posterMediaId != null) 'posterMediaId': media.posterMediaId,
  if (media.fallbackMediaId != null) 'fallbackMediaId': media.fallbackMediaId,
  if (media.captions.isNotEmpty)
    'captions': media.captions.map((entry) => entry.toJson()).toList(),
};

Set<String> _rootMediaIds(PresentationCinematicAsset cinematic) {
  final result = <String>{};
  for (final track in cinematic.tracks) {
    for (final clip in track.clips) {
      switch (clip) {
        case PresentationVisualClip():
          result
            ..add(clip.resourceId)
            ..addAll(<String>[
              if (clip.landscapeResourceId != null) clip.landscapeResourceId!,
              if (clip.portraitResourceId != null) clip.portraitResourceId!,
            ]);
        case PresentationTextClip():
          break;
        case PresentationAudioClip():
          result
            ..add(clip.resourceId)
            ..addAll(<String>[
              if (clip.landscapeResourceId != null) clip.landscapeResourceId!,
              if (clip.portraitResourceId != null) clip.portraitResourceId!,
            ]);
        case PresentationCaptionClip():
          result.add(clip.captionId);
        case PresentationMarkerClip():
          break;
      }
    }
  }
  return result;
}

Set<String> _relationshipClosure(
  ProjectMediaCatalog catalog,
  Iterable<String> roots,
) {
  final result = <String>{};
  final pending = roots.toList();
  while (pending.isNotEmpty) {
    final id = pending.removeLast();
    if (!result.add(id)) continue;
    final media = catalog.find(id);
    if (media == null) continue;
    pending.addAll(<String>[
      if (media.posterMediaId != null) media.posterMediaId!,
      ...media.captionMediaIds,
      ...media.captions.map((caption) => caption.mediaId),
      if (media.fallbackMediaId != null) media.fallbackMediaId!,
    ]);
  }
  return result;
}

void _inspectMedia(
  ProjectMediaAsset media,
  PresentationMediaBudgetPolicy policy,
  List<PresentationMediaPublicationDiagnostic> diagnostics,
) {
  final path = 'media[${media.id}]';
  if (media.provenance == null) {
    diagnostics.add(
      PresentationMediaPublicationDiagnostic(
        code: PresentationMediaPublicationDiagnosticCodes.provenanceMissing,
        constraint: PresentationMediaPublicationConstraints.provenance,
        path: '$path.provenance',
        message: 'Publication requires authored media provenance.',
        mediaId: media.id,
      ),
    );
  }
  if (media.license == null) {
    diagnostics.add(
      PresentationMediaPublicationDiagnostic(
        code: PresentationMediaPublicationDiagnosticCodes.licenseMissing,
        constraint: PresentationMediaPublicationConstraints.license,
        path: '$path.license',
        message: 'Publication requires an authored media license.',
        mediaId: media.id,
      ),
    );
  }
  final metadata = media.technicalMetadata;
  if (metadata == null) {
    diagnostics.add(
      PresentationMediaPublicationDiagnostic(
        code: PresentationMediaPublicationDiagnosticCodes.metadataMissing,
        constraint: PresentationMediaPublicationConstraints.technicalMetadata,
        path: '$path.technicalMetadata',
        message: 'Publication requires probed technical metadata.',
        mediaId: media.id,
      ),
    );
    return;
  }
  if (metadata.sizeBytes > policy.maxFileBytes) {
    diagnostics.add(
      PresentationMediaPublicationDiagnostic(
        code: PresentationMediaPublicationDiagnosticCodes.fileBudgetExceeded,
        constraint: PresentationMediaPublicationConstraints.fileBytes,
        path: '$path.technicalMetadata.sizeBytes',
        message: 'The media exceeds the authored file-size budget.',
        mediaId: media.id,
      ),
    );
  }
  final width = metadata.width;
  final height = metadata.height;
  if (width == null || height == null) return;
  if (media.kind == ProjectMediaKind.image ||
      media.kind == ProjectMediaKind.poster) {
    if (width > policy.maxImageDimension ||
        height > policy.maxImageDimension ||
        width * height > policy.maxImagePixels) {
      diagnostics.add(
        PresentationMediaPublicationDiagnostic(
          code: PresentationMediaPublicationDiagnosticCodes
              .resolutionBudgetExceeded,
          constraint: PresentationMediaPublicationConstraints.resolution,
          path: '$path.technicalMetadata',
          message: 'The image exceeds the authored resolution budget.',
          mediaId: media.id,
        ),
      );
    }
  }
  if (media.kind == ProjectMediaKind.video) {
    final longEdge = width > height ? width : height;
    final shortEdge = width > height ? height : width;
    if (longEdge > policy.maxVideoLongEdge ||
        shortEdge > policy.maxVideoShortEdge) {
      diagnostics.add(
        PresentationMediaPublicationDiagnostic(
          code: PresentationMediaPublicationDiagnosticCodes
              .resolutionBudgetExceeded,
          constraint: PresentationMediaPublicationConstraints.resolution,
          path: '$path.technicalMetadata',
          message: 'The video exceeds the authored resolution budget.',
          mediaId: media.id,
        ),
      );
    }
  }
}

int _payloadBytes(Iterable<ProjectMediaAsset> media) {
  final sizes = <String, int>{};
  for (final entry in media) {
    final size = entry.technicalMetadata?.sizeBytes;
    if (size != null) sizes.putIfAbsent(entry.sourceAssetId, () => size);
  }
  return sizes.values.fold(0, (sum, size) => sum + size);
}

int _estimatedDecodedVisualBytes(Iterable<ProjectMediaAsset> media) {
  final estimates = <String, int>{};
  for (final entry in media) {
    final metadata = entry.technicalMetadata;
    if (metadata == null) continue;
    final estimate = switch (entry.kind.id) {
      'image' || 'poster'
          when metadata.width != null && metadata.height != null =>
        metadata.width! * metadata.height! * 4,
      'video' when metadata.width != null && metadata.height != null =>
        metadata.width! * metadata.height! * 4,
      _ => 0,
    };
    estimates.update(
      entry.sourceAssetId,
      (current) => current > estimate ? current : estimate,
      ifAbsent: () => estimate,
    );
  }
  return estimates.values.fold(0, (sum, value) => sum + value);
}

int _maxConcurrentVideoDecoders(
  PresentationCinematicAsset cinematic,
  ProjectMediaCatalog catalog,
) {
  final events = <(int, int)>[];
  for (final track in cinematic.tracks) {
    for (final clip in track.clips) {
      if (clip is! PresentationVisualClip ||
          catalog.find(clip.resourceId)?.kind != ProjectMediaKind.video) {
        continue;
      }
      events
        ..add((clip.startUs, 1))
        ..add((clip.startUs + clip.durationUs, -1));
    }
  }
  events.sort((left, right) {
    final timeOrder = left.$1.compareTo(right.$1);
    return timeOrder != 0 ? timeOrder : left.$2.compareTo(right.$2);
  });
  var active = 0;
  var maximum = 0;
  for (final event in events) {
    active += event.$2;
    if (active > maximum) maximum = active;
  }
  return maximum;
}

PresentationMediaPlatformResolution resolvePresentationMediaForPlatform(
  ProjectMediaCatalog catalog,
  String mediaId,
  PresentationMediaTargetPlatform platform,
) {
  final visited = <String>{};
  var currentId = mediaId;
  while (visited.add(currentId)) {
    final media = catalog.find(currentId);
    if (media == null) break;
    if (isPresentationMediaCompatible(media, platform)) {
      return PresentationMediaPlatformResolution(
        mediaId: mediaId,
        resolvedMediaId: currentId,
        fallbackMediaId: currentId == mediaId ? null : currentId,
        compatible: true,
      );
    }
    final fallback = nextPresentationMediaFallbackId(media);
    if (fallback == null) break;
    currentId = fallback;
  }
  return PresentationMediaPlatformResolution(
    mediaId: mediaId,
    resolvedMediaId: null,
    compatible: false,
  );
}

bool isPresentationMediaCompatible(
  ProjectMediaAsset media,
  PresentationMediaTargetPlatform platform,
) {
  final metadata = media.technicalMetadata;
  if (metadata == null) return false;
  if (media.kind == ProjectMediaKind.video) {
    if (platform == PresentationMediaTargetPlatform.windows ||
        platform == PresentationMediaTargetPlatform.linux) {
      return false;
    }
    return metadata.mediaType == 'video/mp4' &&
        metadata.container == 'mp4' &&
        metadata.codec == 'h264' &&
        (metadata.audioCodec == null || metadata.audioCodec == 'aac');
  }
  if (media.kind == ProjectMediaKind.image ||
      media.kind == ProjectMediaKind.poster) {
    return metadata.mediaType.startsWith('image/');
  }
  if (media.kind == ProjectMediaKind.audio) {
    return metadata.mediaType.startsWith('audio/');
  }
  if (media.kind == ProjectMediaKind.captions) {
    return metadata.mediaType == 'text/vtt' && metadata.codec == 'webvtt';
  }
  return false;
}

String? nextPresentationMediaFallbackId(ProjectMediaAsset media) =>
    media.fallbackMediaId ?? media.posterMediaId;
