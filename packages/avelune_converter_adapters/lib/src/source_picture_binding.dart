import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'native_project_writer.dart';

final class SourcePictureBindingUnavailable implements Exception {
  const SourcePictureBindingUnavailable(this.reason);
  final String reason;
}

final class SourcePictureBinding {
  SourcePictureBinding._(
      {required this.name,
      required this.mediaId,
      required this.imageFile,
      required this.sourceSnapshotHash,
      required this.normalizationHash,
      required this.profileHash,
      required this.artifact,
      required this.mutation});
  final String name, mediaId;
  final SourceFileEntry imageFile;
  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash;
  final NativeArtifact artifact;
  final NativeMutation mutation;

  bool isBoundTo(NormalizedSourceProject source) =>
      source.snapshot.canonicalHash == sourceSnapshotHash &&
      source.canonicalHash == normalizationHash &&
      SourceEventProfile.forProject(source).canonicalHash == profileHash &&
      source.snapshot.entries
              .where((entry) =>
                  entry.fileId == imageFile.fileId &&
                  entry.relativePath == imageFile.relativePath &&
                  entry.sha256 == imageFile.sha256 &&
                  entry.byteLength == imageFile.byteLength &&
                  entry.kind == SourceNodeKind.file)
              .length ==
          1 &&
      artifact.rawSha256 == imageFile.sha256;

  Map<String, Object?> get evidence => {
        'kind': 'exactSourcePictureBinding',
        'name': name,
        'mediaId': mediaId,
        'sourceImage': imageFile.toJson(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'nativeScopeAdaptation': 'mapPresentationResetOnTransfer',
        'sourcePixelsResampled': false,
        'fullSourceParity': false,
      };
}

final class SourcePictureBindingResolver {
  const SourcePictureBindingResolver();

  Future<SourcePictureBinding> read({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    required String name,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    limits.validate();
    final profile = SourceEventProfile.forProject(source);
    if (!profile.isQualified ||
        source.snapshot.state != SourceScanState.complete) {
      throw const SourcePictureBindingUnavailable('profile_unqualified');
    }
    if (name.isEmpty ||
        name.length > 512 ||
        name.trim() != name ||
        name == '.' ||
        name == '..' ||
        RegExp(r'[\\/:<>\x00-\x1f]').hasMatch(name)) {
      throw const SourcePictureBindingUnavailable('name_unqualified');
    }
    final base = 'Graphics/Pictures/$name';
    final key = sourcePathCollisionKey(base);
    final matches = source.snapshot.entries.where((entry) {
      final path = sourcePathCollisionKey(entry.relativePath);
      return path == key ||
          path.startsWith('$key.') &&
              !path.substring(key.length + 1).contains('/');
    }).toList();
    if (matches.length != 1) {
      throw SourcePictureBindingUnavailable(
          matches.isEmpty ? 'picture_missing' : 'picture_ambiguous');
    }
    final image = matches.single;
    if (image.relativePath != '$base.png' ||
        image.kind != SourceNodeKind.file ||
        image.sha256 == null) {
      throw const SourcePictureBindingUnavailable('picture_unsupported');
    }
    if (image.byteLength > limits.maxArtifactBytes ||
        image.byteLength > limits.maxTotalArtifactBytes) {
      throw const SourcePictureBindingUnavailable('picture_quota');
    }
    final bytes = await files.read(image.fileId);
    cancellation?.check();
    if (bytes.length != image.byteLength ||
        crypto.sha256.convert(bytes).toString() != image.sha256!.value) {
      throw const SourcePictureBindingUnavailable('picture_changed');
    }
    final NativeArtifact artifact;
    try {
      artifact = NativeArtifact(
          bytes: bytes,
          mediaType: 'image/png',
          expectedSha256: image.sha256,
          limits: limits);
    } on NativeWriteException {
      throw const SourcePictureBindingUnavailable('picture_unsupported');
    }
    final hash = canonicalHashOf({
      'namespace': source.snapshot.logicalProjectNamespace.value,
      'fileId': image.fileId.value,
      'sha256': image.sha256!.value,
    }).value;
    final assetId = 'source_picture_$hash';
    final mediaId = 'source_picture_media_$hash';
    return SourcePictureBinding._(
        name: name,
        mediaId: mediaId,
        imageFile: image,
        sourceSnapshotHash: source.snapshot.canonicalHash,
        normalizationHash: source.canonicalHash,
        profileHash: profile.canonicalHash,
        artifact: artifact,
        mutation: NativeMutation(
            operationId: ConverterId('source_picture_import_$hash'),
            actionId: 'presentationMedia.import',
            sourceEntityIds: [image.fileId],
            targetEntityIds: [ConverterId(assetId), ConverterId(mediaId)],
            parameters: {
              'artifactHandle': artifact.handle,
              'assetId': assetId,
              'mediaId': mediaId,
              'label': name,
              'logicalPath': 'assets/presentation/$assetId.png',
              'kind': 'image',
            },
            limits: limits));
  }
}
