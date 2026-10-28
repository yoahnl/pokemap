import 'dart:convert';

import 'package:map_core/map_core.dart';

import 'game_package_format_exception.dart';
import 'game_package_security_policy.dart';
import 'game_package_spatial_project_validator.dart';
import 'game_package_source_assets.dart';

void validateGamePackageProjectAudio({
  required ProjectManifest project,
  required GamePackageSecurityPolicy policy,
  required Set<String> payloadPaths,
  required GamePackagePayloadReader readPayload,
}) {
  if (!(project.settings.audio?.cues.values.any(
        (binding) => binding.source == ProjectSoundSource.custom,
      ) ??
      false)) {
    return;
  }
  Never fail(String message) => throw GamePackageFormatException(
        code: 'projectAudioInvalid',
        path: 'project/project.json',
        message: message,
      );
  List<int> requiredBytes(String path, int limit) {
    if (!payloadPaths.contains(path)) {
      fail('Missing project audio payload $path.');
    }
    final bytes = readPayload(path);
    if (bytes == null || bytes.length > limit) {
      fail('Missing or oversized project audio payload $path.');
    }
    return bytes;
  }

  final media = ProjectMediaCatalog.fromJson(
      Map<String, Object?>.from(jsonDecode(utf8.decode(requiredBytes(
    'project/assets/.pokemap-media.json',
    policy.maxCatalogBytes < 4 * 1024 * 1024
        ? policy.maxCatalogBytes
        : 4 * 1024 * 1024,
  ))) as Map));
  final receipt = const PresentationMediaPublicationPreflight().inspect(
    catalog: media,
    cinematics: const [],
    audio: project.settings.audio,
  );
  if (!receipt.canPublish) {
    fail(receipt.diagnostics.first.message);
  }
  final assets = readGamePackageSourceAssetCatalog(
      requiredBytes(
        'project/assets/.pokemap-assets.json',
        policy.maxCatalogBytes < 16 * 1024 * 1024
            ? policy.maxCatalogBytes
            : 16 * 1024 * 1024,
      ),
      policy);
  for (final entry in receipt.media) {
    final source = assets[entry.sourceAssetId];
    final metadata = entry.technicalMetadata!;
    if (source == null ||
        source.byteLength != metadata.sizeBytes ||
        source.mediaType != metadata.mediaType) {
      fail('Project audio source metadata does not match its media.');
    }
    final digest = source.digest;
    final blob = requiredBytes(
        'project/assets/.pokemap-store/${digest.substring(7)}.blob',
        policy.maxFileBytes);
    if (blob.length != metadata.sizeBytes ||
        computeNarrativeProjectFingerprint([
              NarrativeProjectFingerprintEntry(
                  relativePath: 'artifact-content', bytes: blob),
            ]) !=
            digest) {
      fail('Project audio source blob does not match its asset catalog.');
    }
  }
}
