import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../domain/resource_port.dart';

final class BorderResourceFrame {
  const BorderResourceFrame({
    required this.absolutePath,
    required this.relativePath,
    required this.rect,
    this.durationMs,
    this.transparentColorArgb,
  });

  final String absolutePath;
  final String relativePath;
  final BorderPixelRect rect;
  final int? durationMs;
  final int? transparentColorArgb;
}

final class BorderResourcePrimitive {
  const BorderResourcePrimitive({required this.draft, required this.frames});

  final BorderPrimitiveDraft draft;
  final List<BorderResourceFrame> frames;
}

Future<List<BorderResourcePrimitive>> prepareBorderResources({
  required ProjectManifest manifest,
  required String projectRoot,
  required BorderCreationRequest request,
}) async {
  final root = await Directory(projectRoot).resolveSymbolicLinks();
  final chosen = <(BorderPrimitiveRole, String?)>[
    (BorderPrimitiveRole.lineCap, request.capElementId),
    (BorderPrimitiveRole.lineStraight, request.straightElementId),
    (BorderPrimitiveRole.lineCorner, request.cornerElementId),
  ];
  final result = <BorderResourcePrimitive>[];
  for (final (role, elementId) in chosen) {
    if (elementId == null) continue;
    final element = manifest.elements
        .where((candidate) => candidate.id == elementId)
        .firstOrNull;
    if (element == null || element.frames.isEmpty) {
      throw ResourceFailure('Choisissez un décor existant pour ${role.name}.');
    }
    final frames = <BorderResourceFrame>[];
    final sources = <CanonicalBorderSourceFrame>[];
    for (final frame in element.frames) {
      final tilesetId = frame.tilesetId.isEmpty
          ? element.tilesetId
          : frame.tilesetId;
      final tileset = manifest.tilesets
          .where((candidate) => candidate.id == tilesetId)
          .firstOrNull;
      if (tileset == null) {
        throw ResourceFailure(
          'Image source introuvable pour « ${element.name} ».',
        );
      }
      final relative = tileset.relativePath;
      if (relative.isEmpty ||
          p.isAbsolute(relative) ||
          relative.split('/').any((part) => part == '..')) {
        throw ResourceFailure(
          'Chemin source non sûr pour « ${element.name} ».',
        );
      }
      final file = File(p.join(root, relative));
      if (!await file.exists()) {
        throw ResourceFailure(
          'Image source manquante pour « ${element.name} ». Réimportez-la avant de publier.',
        );
      }
      final resolved = await file.resolveSymbolicLinks();
      if (!p.isWithin(root, resolved)) {
        throw ResourceFailure(
          'Image source hors du projet pour « ${element.name} ».',
        );
      }
      final rect = BorderPixelRect(
        x: frame.source.x * manifest.settings.tileWidth,
        y: frame.source.y * manifest.settings.tileHeight,
        width: frame.source.width * manifest.settings.tileWidth,
        height: frame.source.height * manifest.settings.tileHeight,
      );
      final color = tileset.transparentColor;
      final transparent = color == null
          ? null
          : 0xff000000 | (color.red << 16) | (color.green << 8) | color.blue;
      final bytes = await file.readAsBytes();
      frames.add(
        BorderResourceFrame(
          absolutePath: resolved,
          relativePath: relative,
          rect: rect,
          durationMs: frame.durationMs,
          transparentColorArgb: transparent,
        ),
      );
      sources.add(
        CanonicalBorderSourceFrame(
          sourceProjectRelativePath: relative,
          encodedImageBytes: bytes,
          sourceRectPx: rect,
          durationMs: frame.durationMs,
          transparentColorArgb: transparent,
        ),
      );
    }
    final first = frames.first.rect;
    final anchor = BorderPixelPos(x: first.width ~/ 2, y: first.height ~/ 2);
    final preparation = const CanonicalBorderSnapshotCompiler().prepare(
      sourceElementId: element.id,
      frames: sources,
      anchorPx: anchor,
    );
    result.add(
      BorderResourcePrimitive(
        draft: BorderPrimitiveDraft(
          id: role.name,
          sourceElementId: element.id,
          role: role,
          authoredOrientation: BorderPrimitiveOrientation.east,
          weight: 1000,
          anchorPx: anchor,
          transforms: BorderTransformPolicy(
            allowFlipX: true,
            allowedQuarterTurns: const [0, 1, 2, 3],
          ),
          currentMetrics: preparation.metrics,
        ),
        frames: frames,
      ),
    );
  }
  return result;
}
