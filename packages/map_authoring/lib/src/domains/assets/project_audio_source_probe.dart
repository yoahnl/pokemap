import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import '../../contracts/artifact_ref.dart';

final class ProjectAudioSourceException implements Exception {
  const ProjectAudioSourceException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'ProjectAudioSourceException($code): $message';
}

PresentationMediaProbeResult probeProjectAudioSourceBytes(
  List<int> bytes, {
  required ContentArtifactRef artifact,
  required ProjectMediaAsset media,
  PresentationMediaProbePort probe = const PresentationMediaHeaderProbe(),
}) {
  final metadata = media.technicalMetadata;
  if (media.kind != ProjectMediaKind.audio ||
      metadata == null ||
      !projectAudioSourceMimeMatches(artifact.mediaType, metadata.mediaType)) {
    throw const ProjectAudioSourceException(
        'project_audio.source_metadata_invalid',
        'The selected sound has contradictory audio source metadata.');
  }
  if (bytes.length != artifact.byteLength ||
      bytes.length != metadata.sizeBytes) {
    throw const ProjectAudioSourceException(
        'project_audio.source_size_mismatch',
        'The selected sound bytes differ from their imported size.');
  }
  final actual =
      ContentArtifactRef.fromBytes(bytes, mediaType: artifact.mediaType);
  if (actual.digest != artifact.digest) {
    throw const ProjectAudioSourceException(
        'project_audio.source_digest_mismatch',
        'The selected sound bytes differ from their imported content identity.');
  }
  final PresentationMediaProbeResult inspected;
  try {
    inspected = probe.inspect(bytes, declaredMediaType: metadata.mediaType);
  } on PresentationMediaProbeException catch (error) {
    throw ProjectAudioSourceException(error.code, error.message);
  }
  if (!inspected.mediaType.startsWith('audio/') ||
      inspected.mediaType != metadata.mediaType ||
      inspected.sizeBytes != bytes.length) {
    throw const ProjectAudioSourceException(
        'project_audio.source_content_invalid',
        'The selected sound does not contain the declared audio format.');
  }
  return inspected;
}
