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

BorderPrimitiveDraft _withModelSettings(
  ProjectManifest manifest,
  BorderCreationRequest request,
  BorderPrimitiveDraft primitive,
) {
  final original = BorderModelSettings(
    animationIndex: primitive.animationIndex,
    animationLoop: primitive.animationLoop,
    animationSpeed: primitive.animationSpeed,
    blocksMovement: primitive.blocksMovement,
  );
  final settings = request.primitiveModelSettings[primitive.id] ?? original;
  final model = manifest.models3d.firstWhere(
    (model) => model.id == primitive.sourceModelId,
  );
  if (!settings.animationSpeed.isFinite ||
      settings.animationSpeed <= 0 ||
      settings.animationSpeed > 16) {
    throw const ResourceFailure(
      'La vitesse doit être supérieure à 0 et au maximum égale à 16.',
    );
  }
  if (settings.animationIndex != null &&
      !model.inspection.animations.any(
        (clip) => clip.index == settings.animationIndex,
      )) {
    throw const ResourceFailure(
      'Le modèle ne contient pas l’animation sélectionnée. Choisissez une animation disponible ou « Aucune ».',
    );
  }
  if (settings == original) return primitive;
  return BorderPrimitiveDraft(
    id: primitive.id,
    sourceModelId: primitive.sourceModelId,
    role: primitive.role,
    cornerTurn: primitive.cornerTurn,
    authoredOrientation: primitive.authoredOrientation,
    weight: primitive.weight,
    anchorWorld: primitive.anchorWorld,
    transforms: primitive.transforms,
    animationIndex: settings.animationIndex,
    animationLoop: settings.animationLoop,
    animationSpeed: settings.animationSpeed,
    blocksMovement: settings.blocksMovement,
  );
}

Future<List<BorderResourcePrimitive>> prepareBorderResources({
  required ProjectManifest manifest,
  required String projectRoot,
  required BorderCreationRequest request,
}) async {
  final root = await Directory(projectRoot).resolveSymbolicLinks();
  final record = manifest.borderCatalog.recordById(request.blueprintId ?? '');
  if (record?.draft.definition.template == BorderBlueprintTemplate.ledgeLine &&
      record?.draft.definition.isSpatial == false) {
    if (request.capElementId != null ||
        request.straightElementId != null ||
        request.cornerElementId != null ||
        request.capModelId != null ||
        request.straightModelId != null ||
        request.cornerModelId != null ||
        request.primitiveModelIds.isNotEmpty ||
        request.primitiveModelSettings.isNotEmpty ||
        (request.straightOnly != null &&
            request.straightOnly != record!.draft.definition.straightOnly)) {
      throw const ResourceFailure(
        'Les variantes natives de ce rebord doivent être conservées.',
      );
    }
    return _prepareExistingSpriteSources(
      manifest,
      root,
      record!.draft.definition.primitives,
    );
  }
  final existing = manifest.borderCatalog
      .recordById(request.blueprintId ?? '')
      ?.draft
      .definition;
  final directed =
      request.followContourDirection ??
      existing?.followContourDirection ??
      false;
  if (directed && manifest.settings.dimension != ProjectDimension.threeD ||
      !directed && request.innerCornerModelId != null) {
    throw const ResourceFailure(
      'Les angles rentrants nécessitent une bordure 3D orientée.',
    );
  }
  String primitiveId(BorderPrimitiveRole role, BorderCornerTurn? turn) =>
      turn == BorderCornerTurn.left ? 'lineCornerLeft' : role.name;
  bool matches(
    BorderPrimitiveDraft primitive,
    BorderPrimitiveRole role,
    BorderCornerTurn? turn,
  ) =>
      primitive.role == role &&
      (!directed ||
          role != BorderPrimitiveRole.lineCorner ||
          (primitive.cornerTurn ?? BorderCornerTurn.right) == turn);
  final chosen = <(BorderPrimitiveRole, BorderCornerTurn?, String?, String?)>[
    (
      BorderPrimitiveRole.lineCap,
      null,
      request.capElementId,
      request.capModelId,
    ),
    (
      BorderPrimitiveRole.lineStraight,
      null,
      request.straightElementId,
      request.straightModelId,
    ),
    (
      BorderPrimitiveRole.lineCorner,
      directed ? BorderCornerTurn.right : null,
      request.cornerElementId,
      request.cornerModelId,
    ),
    if (directed)
      (
        BorderPrimitiveRole.lineCorner,
        BorderCornerTurn.left,
        null,
        request.innerCornerModelId,
      ),
  ];
  final result = <BorderResourcePrimitive>[];
  final mapId = request.blueprintId == null
      ? null
      : manifest.resourceLibraryCatalog
            .entryFor('borderBlueprint', request.blueprintId!)
            ?.mapId;
  final settingsIds = {
    if (existing?.isSpatial == true)
      ...existing!.primitives.map((primitive) => primitive.id),
    for (final source in chosen)
      if (source.$4 != null &&
          existing?.primitives.any(
                (primitive) => matches(primitive, source.$1, source.$2),
              ) !=
              true)
        primitiveId(source.$1, source.$2),
  };
  if (request.primitiveModelSettings.isNotEmpty &&
      (manifest.settings.dimension != ProjectDimension.threeD ||
          request.primitiveModelSettings.keys.any(
            (id) => !settingsIds.contains(id),
          ))) {
    throw const ResourceFailure(
      'Choisissez une pièce 3D existante pour ses réglages.',
    );
  }
  if (request.primitiveModelIds.isNotEmpty &&
      (existing?.isSpatial != true ||
          request.primitiveModelIds.keys.any(
            (id) =>
                !existing!.primitives.any((primitive) => primitive.id == id),
          ))) {
    throw const ResourceFailure(
      'Choisissez une variante existante de cette bordure 3D.',
    );
  }
  if (existing?.isSpatial == true) {
    if (chosen.any((source) => source.$3 != null)) {
      throw const ResourceFailure(
        'Cette bordure 3D doit utiliser uniquement des modèles.',
      );
    }
    for (final primitive in existing!.primitives) {
      final roleModelId = switch (primitive.role) {
        BorderPrimitiveRole.lineCap => request.capModelId,
        BorderPrimitiveRole.lineStraight => request.straightModelId,
        BorderPrimitiveRole.lineCorner =>
          primitive.cornerTurn == BorderCornerTurn.left
              ? request.innerCornerModelId
              : request.cornerModelId,
        _ => null,
      };
      final modelId =
          request.primitiveModelIds[primitive.id] ??
          roleModelId ??
          primitive.sourceModelId!;
      if (manifest.settings.dimension != ProjectDimension.threeD ||
          !manifest.models3d.any((model) => model.id == modelId) ||
          !manifest.resourceLibraryCatalog.availableForMap(
            'model3d',
            modelId,
            mapId ?? '',
          )) {
        throw const ResourceFailure(
          'Choisissez un modèle 3D disponible pour cette variante.',
        );
      }
      result.add(
        BorderResourcePrimitive(
          draft: _withModelSettings(
            manifest,
            request,
            modelId == primitive.sourceModelId &&
                    (!directed ||
                        primitive.role != BorderPrimitiveRole.lineCorner ||
                        primitive.cornerTurn != null)
                ? primitive
                : BorderPrimitiveDraft(
                    id: primitive.id,
                    sourceModelId: modelId,
                    role: primitive.role,
                    cornerTurn:
                        primitive.cornerTurn ??
                        (directed &&
                                primitive.role == BorderPrimitiveRole.lineCorner
                            ? BorderCornerTurn.right
                            : null),
                    authoredOrientation: primitive.authoredOrientation,
                    weight: primitive.weight,
                    anchorWorld: primitive.anchorWorld,
                    transforms: primitive.transforms,
                    animationIndex: primitive.animationIndex,
                    animationLoop: primitive.animationLoop,
                    animationSpeed: primitive.animationSpeed,
                    blocksMovement: primitive.blocksMovement,
                  ),
          ),
          frames: const [],
        ),
      );
    }
    for (final (role, turn, _, modelId) in chosen) {
      if (modelId == null ||
          existing.primitives.any(
            (primitive) => matches(primitive, role, turn),
          )) {
        continue;
      }
      if (!manifest.models3d.any((model) => model.id == modelId) ||
          !manifest.resourceLibraryCatalog.availableForMap(
            'model3d',
            modelId,
            mapId ?? '',
          )) {
        throw const ResourceFailure(
          'Choisissez un modèle 3D disponible pour cette bordure.',
        );
      }
      result.add(
        BorderResourcePrimitive(
          draft: _withModelSettings(
            manifest,
            request,
            BorderPrimitiveDraft(
              id: primitiveId(role, turn),
              sourceModelId: modelId,
              role: role,
              cornerTurn: turn,
              authoredOrientation: BorderPrimitiveOrientation.east,
              weight: 1000,
              transforms: BorderTransformPolicy(
                allowFlipX: false,
                allowedQuarterTurns: const [0, 1, 2, 3],
              ),
            ),
          ),
          frames: const [],
        ),
      );
    }
    return result;
  }
  final preservedRoles = <(BorderPrimitiveRole, BorderCornerTurn?)>{};
  if (existing != null && !existing.isSpatial) {
    for (final (role, turn, elementId, modelId) in chosen) {
      final first = existing.primitives
          .where((primitive) => matches(primitive, role, turn))
          .firstOrNull;
      if (modelId == null &&
          elementId != null &&
          first?.sourceElementId == elementId) {
        preservedRoles.add((role, turn));
      }
    }
    result.addAll(
      await _prepareExistingSpriteSources(
        manifest,
        root,
        existing.primitives.where(
          (primitive) => preservedRoles.any(
            (source) => matches(primitive, source.$1, source.$2),
          ),
        ),
      ),
    );
  }
  for (final (role, turn, elementId, modelId) in chosen) {
    if (preservedRoles.contains((role, turn))) continue;
    if (modelId != null) {
      if (elementId != null ||
          manifest.settings.dimension != ProjectDimension.threeD ||
          !manifest.models3d.any((model) => model.id == modelId) ||
          !manifest.resourceLibraryCatalog.availableForMap(
            'model3d',
            modelId,
            mapId ?? '',
          )) {
        throw const ResourceFailure(
          'Choisissez un modèle 3D disponible pour cette bordure.',
        );
      }
      final original = manifest.borderCatalog
          .recordById(request.blueprintId ?? '')
          ?.draft
          .definition
          .primitives
          .where(
            (primitive) =>
                matches(primitive, role, turn) &&
                primitive.sourceModelId == modelId,
          )
          .firstOrNull;
      result.add(
        BorderResourcePrimitive(
          draft: _withModelSettings(
            manifest,
            request,
            original ??
                BorderPrimitiveDraft(
                  id: primitiveId(role, turn),
                  sourceModelId: modelId,
                  role: role,
                  cornerTurn: turn,
                  authoredOrientation: BorderPrimitiveOrientation.east,
                  weight: 1000,
                  transforms: BorderTransformPolicy(
                    allowFlipX: false,
                    allowedQuarterTurns: const [0, 1, 2, 3],
                  ),
                ),
          ),
          frames: const [],
        ),
      );
      continue;
    }
    if (elementId == null) continue;
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

Future<List<BorderResourcePrimitive>> _prepareExistingSpriteSources(
  ProjectManifest manifest,
  String root,
  Iterable<BorderPrimitiveDraft> primitives,
) async {
  final result = <BorderResourcePrimitive>[];
  for (final primitive in primitives) {
    final element = manifest.elements
        .where((element) => element.id == primitive.sourceElementId)
        .firstOrNull;
    if (element == null || element.frames.isEmpty) {
      throw const ResourceFailure(
        'Un décor source du rebord est indisponible.',
      );
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
          encodedImageBytes: await file.readAsBytes(),
          sourceRectPx: rect,
          durationMs: frame.durationMs,
          transparentColorArgb: transparent,
        ),
      );
    }
    final preparation = const CanonicalBorderSnapshotCompiler().prepare(
      sourceElementId: element.id,
      frames: sources,
      anchorPx: primitive.anchorPx,
    );
    if (preparation.metrics != primitive.currentMetrics) {
      throw ResourceFailure(
        'Le dessin source de « ${element.name} » a changé. Réimportez ce rebord avant de publier.',
      );
    }
    result.add(BorderResourcePrimitive(draft: primitive, frames: frames));
  }
  return result;
}
