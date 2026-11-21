part of 'border_resource_sources.dart';

Future<BorderResourcePrimitive> _prepareElementSpriteSource({
  required ProjectManifest manifest,
  required String root,
  required BorderPrimitiveRole role,
  required String elementId,
  required bool isFacade,
}) async {
  if (manifest.settings.dimension != ProjectDimension.twoD) {
    throw const ResourceFailure(
      'Cette bordure 3D doit utiliser uniquement des modèles.',
    );
  }
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
      throw ResourceFailure('Chemin source non sûr pour « ${element.name} ».');
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
  final first = frames.first.rect!;
  final anchor = BorderPixelPos(x: first.width ~/ 2, y: first.height ~/ 2);
  final preparation = const CanonicalBorderSnapshotCompiler().prepare(
    sourceElementId: element.id,
    frames: sources,
    anchorPx: anchor,
  );
  return BorderResourcePrimitive(
    draft: BorderPrimitiveDraft(
      id: role.name,
      sourceElementId: element.id,
      role: role,
      authoredOrientation: isFacade
          ? BorderPrimitiveOrientation.east
          : BorderPrimitiveOrientation.legacyAxis,
      weight: 1000,
      anchorPx: anchor,
      transforms: BorderTransformPolicy(
        allowFlipX: !isFacade,
        allowedQuarterTurns: isFacade ? const [0] : const [0, 1, 2, 3],
      ),
      currentMetrics: preparation.metrics,
    ),
    frames: frames,
  );
}

Future<List<BorderResourcePrimitive>> prepareExistingBorderSpriteSources(
  ProjectManifest manifest,
  String root,
  Iterable<BorderPrimitiveDraft> primitives,
) async {
  final result = <BorderResourcePrimitive>[];
  final sourceBytes = <String, Future<Uint8List>>{};
  final sourceFrames =
      <
        (String, BorderPixelPos, BorderPrimitiveAssetMetrics),
        List<BorderResourceFrame>
      >{};
  for (final primitive in primitives) {
    final element = manifest.elements
        .where((element) => element.id == primitive.sourceElementId)
        .firstOrNull;
    if (element == null || element.frames.isEmpty) {
      throw const ResourceFailure(
        'Un décor source du rebord est indisponible.',
      );
    }
    final key = (element.id, primitive.anchorPx, primitive.currentMetrics);
    if (sourceFrames[key] case final frames?) {
      result.add(BorderResourcePrimitive(draft: primitive, frames: frames));
      continue;
    }
    final frames = <BorderResourceFrame>[];
    final sources = <CanonicalBorderSourceFrame>[];
    for (final frame in element.frames) {
      final tilesetId = frame.tilesetId.isEmpty
          ? element.tilesetId
          : frame.tilesetId;
      final tileset = manifest.tilesets
          .where((tileset) => tileset.id == tilesetId)
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
          'Image source manquante pour « ${element.name} ».',
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
          encodedImageBytes: await sourceBytes.putIfAbsent(
            resolved,
            file.readAsBytes,
          ),
          sourceRectPx: rect,
          durationMs: frame.durationMs,
          transparentColorArgb: transparent,
        ),
      );
    }
    const compiler = CanonicalBorderSnapshotCompiler();
    final preparation = compiler.prepare(
      sourceElementId: element.id,
      frames: sources,
      anchorPx: primitive.anchorPx,
    );
    var acceptedFrames = frames;
    if (preparation.metrics != primitive.currentMetrics) {
      final changedSource = ResourceFailure(
        'Le dessin source de « ${element.name} » a changé. Réimportez ce rebord avant de publier.',
      );
      if (preparation.metrics.pixelSize != primitive.currentMetrics.pixelSize ||
          frames.any((frame) => frame.rect!.x != 0 || frame.rect!.y != 0)) {
        throw changedSource;
      }
      final wholeImage = compiler.prepare(
        sourceElementId: element.id,
        anchorPx: primitive.anchorPx,
        frames: [
          for (final source in sources)
            CanonicalBorderSourceFrame(
              sourceProjectRelativePath: source.sourceProjectRelativePath,
              encodedImageBytes: source.encodedImageBytes,
              durationMs: source.durationMs,
              transparentColorArgb: source.transparentColorArgb,
              decodedFrameIndex: source.decodedFrameIndex,
            ),
        ],
      );
      if (wholeImage.metrics != primitive.currentMetrics ||
          wholeImage.snapshot != preparation.snapshot) {
        throw changedSource;
      }
      acceptedFrames = [
        for (final frame in frames)
          BorderResourceFrame(
            absolutePath: frame.absolutePath,
            relativePath: frame.relativePath,
            rect: null,
            durationMs: frame.durationMs,
            transparentColorArgb: frame.transparentColorArgb,
          ),
      ];
    }
    sourceFrames[key] = acceptedFrames;
    result.add(
      BorderResourcePrimitive(draft: primitive, frames: acceptedFrames),
    );
  }
  return result;
}
