import 'dart:typed_data';

import 'resource_mutation_preparation.dart';

final class ResourceReplacementRequest {
  ResourceReplacementRequest({
    required this.tilesetId,
    required this.sourcePath,
    required Uint8List bytes,
  }) : bytes = Uint8List.fromList(bytes).asUnmodifiableView();

  final String tilesetId;
  final String sourcePath;
  final Uint8List bytes;
}

final class ResourceReplacementPreview {
  ResourceReplacementPreview({
    required this.preparation,
    required Uint8List beforeBytes,
    required Uint8List candidateBytes,
    required this.width,
    required this.height,
    required this.impact,
  }) : beforeBytes = Uint8List.fromList(beforeBytes).asUnmodifiableView(),
       candidateBytes = Uint8List.fromList(candidateBytes).asUnmodifiableView();

  final ResourceMutationPreparation preparation;
  final Uint8List beforeBytes;
  final Uint8List candidateBytes;
  final int width;
  final int height;
  final Map<String, Object?> impact;
}

abstract interface class ResourceLifecyclePreparationPort {
  Future<ResourceReplacementPreview> prepareReplacement(
    ResourceReplacementRequest request,
  );
  Future<void> releasePreparation(ResourceMutationPreparation preparation);
}
