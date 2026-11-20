import 'package:map_core/map_core_domain.dart';

bool supportsBorderWorkshopDraft(BorderBlueprintRecord record) {
  final definition = record.draft.definition;
  return !record.isDeprecated &&
      definition.isSpatial &&
      definition.template == BorderBlueprintTemplate.connectedLine &&
      definition.primitives.every(
        (piece) => const {
          BorderPrimitiveRole.lineCap,
          BorderPrimitiveRole.lineStraight,
          BorderPrimitiveRole.lineCorner,
        }.contains(piece.role),
      );
}

final class BorderWorkshopDraftInput {
  BorderWorkshopDraftInput(this.original) : name = original.definition.name;

  final BorderBlueprintDraft original;
  String name;
  final weights = <String, String>{};
  final collisions = <String, bool>{};

  String weightText(BorderPrimitiveDraft piece) =>
      weights[piece.id] ?? piece.weight.toString();

  int? weight(BorderPrimitiveDraft piece) {
    final value = int.tryParse(weightText(piece).trim());
    return value == null || value < 0 || value > 1000 ? null : value;
  }

  bool collision(BorderPrimitiveDraft piece) =>
      collisions[piece.id] ?? piece.blocksMovement;

  bool get hasChanges =>
      name.trim() != original.definition.name ||
      original.definition.primitives.any(
        (piece) =>
            weight(piece) != piece.weight ||
            collision(piece) != piece.blocksMovement,
      );

  String? get nameError => switch (name.trim().length) {
    0 => 'Donnez un nom au brouillon.',
    > 512 => 'Le nom peut contenir jusqu’à 512 caractères.',
    _ => null,
  };

  BorderBlueprintDraft? get candidate {
    if (!hasChanges || nameError != null) return null;
    final definition = original.definition;
    final pieces = <BorderPrimitiveDraft>[];
    for (final piece in definition.primitives) {
      final value = weight(piece);
      if (value == null) return null;
      final blocks = collision(piece);
      pieces.add(
        value == piece.weight && blocks == piece.blocksMovement
            ? piece
            : BorderPrimitiveDraft(
                id: piece.id,
                sourceModelId: piece.sourceModelId,
                role: piece.role,
                authoredOrientation: piece.authoredOrientation,
                sequenceIndex: piece.sequenceIndex,
                cornerTurn: piece.cornerTurn,
                cornerJoinCells: piece.cornerJoinCells,
                weight: value,
                anchorWorld: piece.anchorWorld,
                animationIndex: piece.animationIndex,
                animationLoop: piece.animationLoop,
                animationSpeed: piece.animationSpeed,
                blocksMovement: blocks,
                transforms: piece.transforms,
                groundFootprints: piece.groundFootprints,
                groundSurfaces: piece.groundSurfaces,
              ),
      );
    }
    return BorderBlueprintDraft(
      baseRevision: original.baseRevision,
      definition: BorderBlueprintDraftDefinition(
        name: name.trim(),
        previewSeed: definition.previewSeed,
        template: definition.template,
        straightOnly: definition.straightOnly,
        sequenceLength: definition.sequenceLength,
        followContourDirection: definition.followContourDirection,
        replacesGround: definition.replacesGround,
        masksGroundCells: definition.masksGroundCells,
        groundBaseOffset: definition.groundBaseOffset,
        primitives: pieces,
        defaults: definition.defaults,
        ground: definition.ground,
        categoryId: definition.categoryId,
        sortOrder: definition.sortOrder,
        jumpBehavior: definition.jumpBehavior,
      ),
    );
  }
}
