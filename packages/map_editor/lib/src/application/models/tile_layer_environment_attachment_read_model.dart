enum TileLayerEnvironmentSelectedLayerKind {
  none,
  missing,
  tile,
  environment,
  other,
}

enum TileLayerEnvironmentAttachmentState {
  noProject,
  noMap,
  noLayerSelected,
  selectedLayerMissing,
  unsupportedLayer,
  noAttachment,
  missingTargetTileLayer,
  targetTileLayerMissing,
  targetLayerIsNotTileLayer,
  noArea,
  selectedAreaMissing,
  areaSelectionRequired,
  missingPreset,
  emptyMask,
  ready,
  generated,
}

enum TileLayerEnvironmentAttachmentIssueSeverity {
  warning,
  error,
}

final class TileLayerEnvironmentAttachmentIssue {
  const TileLayerEnvironmentAttachmentIssue({
    required this.severity,
    required this.message,
  });

  final TileLayerEnvironmentAttachmentIssueSeverity severity;
  final String message;
}

final class TileLayerEnvironmentAttachmentReadModel {
  const TileLayerEnvironmentAttachmentReadModel({
    required this.state,
    this.selectedLayerId,
    this.selectedLayerKind = TileLayerEnvironmentSelectedLayerKind.none,
    this.activeTileLayerId,
    this.activeTileLayerName,
    this.attachedEnvironmentLayerId,
    this.attachedEnvironmentLayerName,
    this.isLegacyEnvironmentLayerSelection = false,
    this.hasAttachment = false,
    this.hasValidTargetTileLayer = false,
    this.hasMultipleAttachments = false,
    this.attachmentCount = 0,
    this.selectedEnvironmentAreaId,
    this.selectedEnvironmentAreaName,
    this.selectedPresetId,
    this.selectedPresetName,
    this.maskActiveCellCount = 0,
    this.hasMask = false,
    this.hasGeneratedPlacements = false,
    this.generatedPlacementCount = 0,
    this.existingGeneratedPlacementCount = 0,
    this.missingGeneratedPlacementCount = 0,
    this.canEnableEnvironment = false,
    this.canPaintMask = false,
    this.canGenerate = false,
    this.canClearGeneratedPlacements = false,
    this.canRegenerate = false,
    this.canShuffle = false,
    this.emptyStateTitle = '',
    this.emptyStateMessage = '',
    this.primaryActionLabel,
    this.issues = const [],
  });

  final TileLayerEnvironmentAttachmentState state;
  final String? selectedLayerId;
  final TileLayerEnvironmentSelectedLayerKind selectedLayerKind;
  final String? activeTileLayerId;
  final String? activeTileLayerName;
  final String? attachedEnvironmentLayerId;
  final String? attachedEnvironmentLayerName;
  final bool isLegacyEnvironmentLayerSelection;
  final bool hasAttachment;
  final bool hasValidTargetTileLayer;
  final bool hasMultipleAttachments;
  final int attachmentCount;
  final String? selectedEnvironmentAreaId;
  final String? selectedEnvironmentAreaName;
  final String? selectedPresetId;
  final String? selectedPresetName;
  final int maskActiveCellCount;
  final bool hasMask;
  final bool hasGeneratedPlacements;
  final int generatedPlacementCount;
  final int existingGeneratedPlacementCount;
  final int missingGeneratedPlacementCount;
  final bool canEnableEnvironment;
  final bool canPaintMask;
  final bool canGenerate;
  final bool canClearGeneratedPlacements;
  final bool canRegenerate;
  final bool canShuffle;
  final String emptyStateTitle;
  final String emptyStateMessage;
  final String? primaryActionLabel;
  final List<TileLayerEnvironmentAttachmentIssue> issues;

  List<String> get warnings {
    return [
      for (final issue in issues)
        if (issue.severity ==
            TileLayerEnvironmentAttachmentIssueSeverity.warning)
          issue.message,
    ];
  }

  List<String> get errors {
    return [
      for (final issue in issues)
        if (issue.severity == TileLayerEnvironmentAttachmentIssueSeverity.error)
          issue.message,
    ];
  }

  bool get hasWarnings => warnings.isNotEmpty;

  bool get hasErrors => errors.isNotEmpty;
}
