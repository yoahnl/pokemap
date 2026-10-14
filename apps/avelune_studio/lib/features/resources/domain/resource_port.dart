import 'dart:typed_data';

import 'package:map_core/map_core_domain.dart';

final class ResourceImageImport {
  const ResourceImageImport({
    required this.sourcePath,
    required this.name,
    required this.tileWidth,
    required this.tileHeight,
  });

  final String sourcePath;
  final String name;
  final int tileWidth;
  final int tileHeight;
}

final class BorderModelSettings {
  const BorderModelSettings({
    this.animationIndex,
    this.animationLoop = true,
    this.animationSpeed = 1,
    this.blocksMovement = true,
  });

  final int? animationIndex;
  final bool animationLoop;
  final double animationSpeed;
  final bool blocksMovement;

  @override
  bool operator ==(Object other) =>
      other is BorderModelSettings &&
      other.animationIndex == animationIndex &&
      other.animationLoop == animationLoop &&
      other.animationSpeed == animationSpeed &&
      other.blocksMovement == blocksMovement;

  @override
  int get hashCode => Object.hash(
    animationIndex,
    animationLoop,
    animationSpeed,
    blocksMovement,
  );
}

final class BorderCreationRequest {
  const BorderCreationRequest({
    required this.name,
    this.capElementId,
    this.straightElementId,
    this.cornerElementId,
    this.capModelId,
    this.straightModelId,
    this.cornerModelId,
    this.innerCornerModelId,
    this.primitiveModelIds = const {},
    this.primitiveModelSettings = const {},
    this.straightOnly,
    this.followContourDirection,
    this.replacesGround,
    this.masksGroundCells,
    this.groundBaseOffset,
    this.jumpSide,
    this.expectedRecord,
    this.blueprintId,
    this.publish = true,
    this.acceptedWarningCodes = const [],
  });

  final String name;
  final String? capElementId;
  final String? straightElementId;
  final String? cornerElementId;
  final String? capModelId, straightModelId, cornerModelId;
  final String? innerCornerModelId;
  final Map<String, String> primitiveModelIds;
  final Map<String, BorderModelSettings> primitiveModelSettings;
  final bool? straightOnly;
  final bool? followContourDirection;
  final bool? replacesGround;
  final bool? masksGroundCells;
  final double? groundBaseOffset;
  final BorderLineSide? jumpSide;
  final BorderBlueprintRecord? expectedRecord;
  final String? blueprintId;
  final bool publish;
  final List<String> acceptedWarningCodes;
}

final class CharacterPortraitImport {
  const CharacterPortraitImport({
    required this.sourcePath,
    required this.characterId,
    required this.portraitStateId,
  });

  final String sourcePath;
  final String characterId;
  final String portraitStateId;
}

final class CharacterAnimationImport {
  const CharacterAnimationImport({
    required this.sourcePath,
    required this.characterId,
    required this.state,
    required this.direction,
    required this.poseWidth,
    required this.poseHeight,
  });

  final String sourcePath;
  final String characterId;
  final CharacterAnimationState state;
  final EntityFacing direction;
  final int poseWidth;
  final int poseHeight;
}

final class ResourceMutationReceipt {
  const ResourceMutationReceipt({
    required this.before,
    required this.manifest,
    required this.beforeRevision,
    required this.revision,
    required this.changedPaths,
    this.createdTilesetId,
    this.operationId,
    this.actionId,
    this.snapshotBeforeRevision,
    this.resourceRevisions = const {},
    this.pathRevisions = const {},
    this.changedMaps = const {},
    this.mapRevisions = const {},
  });

  final ProjectManifest before;
  final ProjectManifest manifest;
  final String beforeRevision;
  final String revision;
  final List<String> changedPaths;
  final String? createdTilesetId;
  final String? operationId;
  final String? actionId;
  final String? snapshotBeforeRevision;
  final Map<String, String?> resourceRevisions;
  final Map<String, String?> pathRevisions;
  final Map<String, MapData> changedMaps;
  final Map<String, String> mapRevisions;
  bool get noChange => changedPaths.isEmpty;
}

abstract interface class ResourcePort {
  Future<ResourceMutationReceipt> importImage(ResourceImageImport request);

  Future<ResourceMutationReceipt> createBorder(BorderCreationRequest request);

  Future<ResourceMutationReceipt> importCharacterPortrait(
    CharacterPortraitImport request,
  );

  Future<ResourceMutationReceipt> importCharacterAnimation(
    CharacterAnimationImport request,
  );

  Future<Uint8List?> readCharacterPortrait(
    String characterId,
    String portraitStateId,
  );

  Future<ResourceMutationReceipt> mutate(
    String actionId,
    Map<String, Object?> parameters,
  );

  Future<ResourceMutationReceipt> saveElement(ProjectElementEntry element);

  Future<void> dispose();
}

final class ResourceFailure implements Exception {
  const ResourceFailure(
    this.message, {
    this.partialReceipt,
    this.borderId,
    this.warningCodes = const [],
  });

  final String message;
  final ResourceMutationReceipt? partialReceipt;
  final String? borderId;
  final List<String> warningCodes;

  @override
  String toString() => message;
}
