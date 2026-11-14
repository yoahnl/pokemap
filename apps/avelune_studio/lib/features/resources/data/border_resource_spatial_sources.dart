part of 'border_resource_sources.dart';

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
    cornerJoinCells: primitive.cornerJoinCells,
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
    cornerJoinCells: settings.cornerJoinCells,
    authoredOrientation: primitive.authoredOrientation,
    sequenceIndex: primitive.sequenceIndex,
    weight: primitive.weight,
    anchorWorld: primitive.anchorWorld,
    transforms: primitive.transforms,
    animationIndex: settings.animationIndex,
    animationLoop: settings.animationLoop,
    animationSpeed: settings.animationSpeed,
    blocksMovement: settings.blocksMovement,
    groundFootprints: primitive.groundFootprints,
    groundSurfaces: primitive.groundSurfaces,
  );
}

List<BorderResourcePrimitive> _prepareSpatialBorderResources({
  required ProjectManifest manifest,
  required BorderCreationRequest request,
  required List<(BorderPrimitiveRole, BorderCornerTurn?, String?, String?)>
  chosen,
  required List<BorderPrimitiveDraft> sequencePrimitives,
  required bool directed,
  required String? mapId,
  required String Function(BorderPrimitiveRole role, BorderCornerTurn? turn)
  primitiveId,
  required bool Function(
    BorderPrimitiveDraft primitive,
    BorderPrimitiveRole role,
    BorderCornerTurn? turn,
  )
  matches,
}) {
  final result = <BorderResourcePrimitive>[];
  if (chosen.any((source) => source.$3 != null)) {
    throw const ResourceFailure(
      'Cette bordure 3D doit utiliser uniquement des modèles.',
    );
  }
  for (final primitive in sequencePrimitives) {
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
                  sequenceIndex: primitive.sequenceIndex,
                  cornerJoinCells: primitive.cornerJoinCells,
                  weight: primitive.weight,
                  anchorWorld: primitive.anchorWorld,
                  transforms: primitive.transforms,
                  animationIndex: primitive.animationIndex,
                  animationLoop: primitive.animationLoop,
                  animationSpeed: primitive.animationSpeed,
                  blocksMovement: primitive.blocksMovement,
                  groundFootprints: primitive.groundFootprints,
                  groundSurfaces: primitive.groundSurfaces,
                ),
        ),
        frames: const [],
      ),
    );
  }
  for (final (role, turn, _, modelId) in chosen) {
    if (modelId == null ||
        sequencePrimitives.any((primitive) => matches(primitive, role, turn))) {
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
