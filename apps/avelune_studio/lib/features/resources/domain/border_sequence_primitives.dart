import 'package:map_core/map_core_domain.dart';

List<BorderPrimitiveDraft> borderSequenceModelPrimitives({
  String? straightModelId,
  String? capModelId,
  String? cornerModelId,
  String? innerCornerModelId,
  bool directed = false,
}) => [
  for (final (role, modelId, turn, id) in [
    (BorderPrimitiveRole.lineStraight, straightModelId, null, 'lineStraight'),
    (BorderPrimitiveRole.lineCap, capModelId, null, 'lineCap'),
    (
      BorderPrimitiveRole.lineCorner,
      cornerModelId,
      directed ? BorderCornerTurn.right : null,
      'lineCorner',
    ),
    (
      BorderPrimitiveRole.lineCorner,
      innerCornerModelId,
      BorderCornerTurn.left,
      'lineCornerLeft',
    ),
  ])
    if (modelId != null)
      BorderPrimitiveDraft(
        id: id,
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
];

List<BorderPrimitiveDraft> borderSequencePrimitives(
  Iterable<BorderPrimitiveDraft> source,
  int length, {
  int previousLength = 1,
}) {
  final original = source.toList();
  final result = original.where((p) => p.sequenceIndex < length).toList();
  final prototypes = original.where((p) => p.sequenceIndex == 0).toList();
  for (var step = previousLength; step < length; step++) {
    if (result.any((p) => p.sequenceIndex == step)) continue;
    for (final p in prototypes) {
      result.add(
        BorderPrimitiveDraft(
          id: '${p.id}_step_$step',
          sourceModelId: p.sourceModelId,
          role: p.role,
          authoredOrientation: p.authoredOrientation,
          sequenceIndex: step,
          cornerTurn: p.cornerTurn,
          cornerJoinCells: p.cornerJoinCells,
          weight: p.weight,
          anchorWorld: p.anchorWorld,
          transforms: p.transforms,
          animationIndex: p.animationIndex,
          animationLoop: p.animationLoop,
          animationSpeed: p.animationSpeed,
          blocksMovement: p.blocksMovement,
          groundFootprints: p.groundFootprints,
          groundSurfaces: p.groundSurfaces,
        ),
      );
    }
  }
  return result;
}
