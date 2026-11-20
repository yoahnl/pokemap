import '../models/border_blueprint.dart';

BorderBlueprintPublishedDefinition spatialBorderPublicationDefinition(
  BorderBlueprintDraftDefinition draft,
) => BorderBlueprintPublishedDefinition(
  name: draft.name,
  previewSeed: draft.previewSeed,
  template: draft.template,
  straightOnly: draft.straightOnly,
  sequenceLength: draft.sequenceLength,
  followContourDirection: draft.followContourDirection,
  replacesGround: draft.replacesGround,
  masksGroundCells: draft.masksGroundCells,
  groundBaseOffset: draft.groundBaseOffset,
  primitives: [
    for (final primitive in draft.primitives)
      if (primitive.weight > 0)
        BorderPublishedPrimitive(
          id: primitive.id,
          sourceModelId: primitive.sourceModelId,
          role: primitive.role,
          cornerTurn: primitive.cornerTurn,
          cornerJoinCells: primitive.cornerJoinCells,
          authoredOrientation: primitive.authoredOrientation,
          sequenceIndex: primitive.sequenceIndex,
          weight: primitive.weight,
          transforms: primitive.transforms,
          anchorWorld: primitive.anchorWorld,
          animationIndex: primitive.animationIndex,
          animationLoop: primitive.animationLoop,
          animationSpeed: primitive.animationSpeed,
          blocksMovement: primitive.blocksMovement,
          groundFootprints: primitive.groundFootprints,
          groundSurfaces: primitive.groundSurfaces,
        ),
  ],
  defaults: draft.defaults,
  sortOrder: draft.sortOrder,
  jumpBehavior: draft.jumpBehavior,
  categoryId: draft.categoryId,
);
