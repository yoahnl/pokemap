import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:path/path.dart' as p;

import 'package:avelune_studio/presentation/features/map_workspace/workspace_resource_diagnostic.dart';

final class StudioResourceFailure implements Exception {
  const StudioResourceFailure(this.cause, this.detail);
  final WorkspaceResourceCause cause;
  final String detail;
}

typedef StudioImageDecoder =
    Future<RuntimeTilesetImage> Function(
      Uint8List bytes, {
      TilesetTransparentColor? transparentColor,
    });

final class StudioResourceDecoder {
  StudioResourceDecoder({
    required this.projectRoot,
    required this.maximumDecodeBytes,
    required this.reserve,
    this.decode = decodeRuntimeTilesetImage,
  });

  final String projectRoot;
  final int maximumDecodeBytes;
  final void Function(int) reserve;
  final StudioImageDecoder decode;
  int reads = 0;
  int decodes = 0;
  int peakTransientBytes = 0;

  Future<RuntimeTilesetImage> load(
    String path, {
    TilesetTransparentColor? transparentColor,
  }) async {
    const reader = LocalProjectFileReader();
    final relativePath = p.relative(path, from: projectRoot);
    if (relativePath != relativePath.trim()) {
      throw const StudioResourceFailure(
        WorkspaceResourceCause.unsupported,
        'Chemin non préservé',
      );
    }
    final probe = await reader.probeResource(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    final cause = switch (probe.status) {
      ProjectResourceProbeStatus.exists => null,
      ProjectResourceProbeStatus.missing => WorkspaceResourceCause.missing,
      ProjectResourceProbeStatus.accessDenied =>
        WorkspaceResourceCause.accessDenied,
      ProjectResourceProbeStatus.unsafePath =>
        WorkspaceResourceCause.unsupported,
      ProjectResourceProbeStatus.inventoryUnavailable =>
        WorkspaceResourceCause.readFailure,
    };
    if (cause != null) throw StudioResourceFailure(cause, relativePath);
    if (probe.identity!.byteLength > maximumDecodeBytes) {
      throw const StudioResourceFailure(
        WorkspaceResourceCause.memoryPressure,
        'Fichier encodé trop volumineux',
      );
    }
    late Uint8List bytes;
    try {
      reads++;
      bytes = Uint8List.fromList(
        await reader.readBytes(
          projectRoot: projectRoot,
          relativePath: relativePath,
        ),
      );
    } on Object catch (error) {
      throw StudioResourceFailure(
        error is FileSystemException &&
                (error.osError?.errorCode == 13 ||
                    error.osError?.errorCode == 1)
            ? WorkspaceResourceCause.accessDenied
            : WorkspaceResourceCause.readFailure,
        error.toString(),
      );
    }
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      late int imageBytes;
      try {
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        imageBytes = descriptor.width * descriptor.height * 4;
        descriptor.dispose();
      } finally {
        buffer.dispose();
      }
      if (imageBytes > maximumDecodeBytes) {
        throw const StudioResourceFailure(
          WorkspaceResourceCause.memoryPressure,
          'Image décodée trop volumineuse',
        );
      }
      reserve(imageBytes);
      final transientBytes = bytes.length * 2 + imageBytes * 3;
      if (transientBytes > peakTransientBytes) {
        peakTransientBytes = transientBytes;
      }
      decodes++;
      return await decode(bytes, transparentColor: transparentColor);
    } on StudioResourceFailure {
      rethrow;
    } on Object catch (error) {
      throw StudioResourceFailure(
        WorkspaceResourceCause.decodeFailure,
        error.toString(),
      );
    }
  }
}
