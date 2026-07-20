import 'package:flutter/foundation.dart' show immutable;
import 'package:map_core/map_core.dart';

const String borderStudioSourceReanalysisRequiredDiagnosticCode =
    'border.studio.source_asset_reanalysis_required';
const String borderStudioSourceRepublishRequiredDiagnosticCode =
    'border.studio.source_asset_republish_required';

@immutable
final class BorderStudioDraft {
  const BorderStudioDraft({
    required this.id,
    required this.blueprint,
  });

  final String id;
  final BorderBlueprintDraft blueprint;
}

@immutable
final class BorderStudioPublicationAvailability {
  const BorderStudioPublicationAvailability.allowed()
      : isAllowed = true,
        disabledReason = null;

  const BorderStudioPublicationAvailability.disabled(String reason)
      : isAllowed = false,
        disabledReason = reason;

  final bool isAllowed;
  final String? disabledReason;
}

@immutable
final class BorderStudioDraftState {
  BorderStudioDraftState({
    List<BorderBlueprintRecord> catalogRecords =
        const <BorderBlueprintRecord>[],
    this.selectedBlueprintId,
    this.workingDraft,
    this.isDirty = false,
    this.selectedHasPublishedRevision = false,
    this.diagnostics = const BorderDiagnosticsReport.empty(),
    this.diagnosticsAreCurrent = false,
    Set<String> acknowledgedWarningCodes = const <String>{},
    Map<String, String> loadedAssetFingerprints = const <String, String>{},
    Set<String> sourceDivergedPrimitiveIds = const <String>{},
    Set<String> reanalyzedDivergedPrimitiveIds = const <String>{},
  })  : catalogRecords = List<BorderBlueprintRecord>.unmodifiable(
          catalogRecords,
        ),
        acknowledgedWarningCodes = Set<String>.unmodifiable(
          acknowledgedWarningCodes,
        ),
        loadedAssetFingerprints = Map<String, String>.unmodifiable(
          loadedAssetFingerprints,
        ),
        sourceDivergedPrimitiveIds = Set<String>.unmodifiable(
          sourceDivergedPrimitiveIds,
        ),
        reanalyzedDivergedPrimitiveIds = Set<String>.unmodifiable(
          reanalyzedDivergedPrimitiveIds,
        );

  final List<BorderBlueprintRecord> catalogRecords;
  final String? selectedBlueprintId;
  final BorderStudioDraft? workingDraft;
  final bool isDirty;
  final bool selectedHasPublishedRevision;
  final BorderDiagnosticsReport diagnostics;
  final bool diagnosticsAreCurrent;
  final Set<String> acknowledgedWarningCodes;
  final Map<String, String> loadedAssetFingerprints;
  final Set<String> sourceDivergedPrimitiveIds;
  final Set<String> reanalyzedDivergedPrimitiveIds;

  BorderSignedInt64? get previewSeed =>
      workingDraft?.blueprint.definition.previewSeed;

  Set<BorderPrimitiveRole> get allowedPrimitiveRoles {
    final draft = workingDraft;
    if (draft == null) {
      return const <BorderPrimitiveRole>{};
    }
    return borderAllowedPrimitiveRolesForTemplate(
      draft.blueprint.definition.template,
    );
  }

  Set<String> get warningCodes {
    final codes = <String>{
      for (final diagnostic in diagnostics.diagnostics)
        if (diagnostic.severity == BorderDiagnosticSeverity.warning)
          diagnostic.code,
    }.toList(growable: false)
      ..sort();
    return Set<String>.unmodifiable(codes);
  }

  Set<String> get unacknowledgedWarningCodes {
    final codes = warningCodes
        .where((code) => !acknowledgedWarningCodes.contains(code))
        .toList(growable: false)
      ..sort();
    return Set<String>.unmodifiable(codes);
  }

  bool get requiresSourceReanalysis => sourceDivergedPrimitiveIds.any(
        (id) => !reanalyzedDivergedPrimitiveIds.contains(id),
      );

  bool get requiresRepublish => sourceDivergedPrimitiveIds.isNotEmpty;

  bool get canDeleteSelectedDraft =>
      workingDraft != null && !selectedHasPublishedRevision;

  BorderStudioPublicationAvailability get publicationAvailability {
    final draft = workingDraft;
    if (draft == null) {
      return const BorderStudioPublicationAvailability.disabled(
        'Sélectionnez ou créez un blueprint avant de publier.',
      );
    }
    return _currentPreviewPublicationAvailability;
  }

  BorderStudioPublicationAvailability
      get _currentPreviewPublicationAvailability {
    if (!diagnosticsAreCurrent) {
      return const BorderStudioPublicationAvailability.disabled(
        'Regénérez l’aperçu canonique avant de publier.',
      );
    }
    if (diagnostics.hasErrors) {
      return const BorderStudioPublicationAvailability.disabled(
        'Corrigez les erreurs du blueprint avant de publier.',
      );
    }
    if (unacknowledgedWarningCodes.isNotEmpty) {
      return const BorderStudioPublicationAvailability.disabled(
        'Acceptez explicitement chaque avertissement avant de publier.',
      );
    }
    return const BorderStudioPublicationAvailability.allowed();
  }

  bool get canPublish => publicationAvailability.isAllowed;

  BorderStudioDraftState copyWith({
    List<BorderBlueprintRecord>? catalogRecords,
    Object? selectedBlueprintId = _unset,
    Object? workingDraft = _unset,
    bool? isDirty,
    bool? selectedHasPublishedRevision,
    BorderDiagnosticsReport? diagnostics,
    bool? diagnosticsAreCurrent,
    Set<String>? acknowledgedWarningCodes,
    Map<String, String>? loadedAssetFingerprints,
    Set<String>? sourceDivergedPrimitiveIds,
    Set<String>? reanalyzedDivergedPrimitiveIds,
  }) {
    return BorderStudioDraftState(
      catalogRecords: catalogRecords ?? this.catalogRecords,
      selectedBlueprintId: identical(selectedBlueprintId, _unset)
          ? this.selectedBlueprintId
          : selectedBlueprintId as String?,
      workingDraft: identical(workingDraft, _unset)
          ? this.workingDraft
          : workingDraft as BorderStudioDraft?,
      isDirty: isDirty ?? this.isDirty,
      selectedHasPublishedRevision:
          selectedHasPublishedRevision ?? this.selectedHasPublishedRevision,
      diagnostics: diagnostics ?? this.diagnostics,
      diagnosticsAreCurrent:
          diagnosticsAreCurrent ?? this.diagnosticsAreCurrent,
      acknowledgedWarningCodes:
          acknowledgedWarningCodes ?? this.acknowledgedWarningCodes,
      loadedAssetFingerprints:
          loadedAssetFingerprints ?? this.loadedAssetFingerprints,
      sourceDivergedPrimitiveIds:
          sourceDivergedPrimitiveIds ?? this.sourceDivergedPrimitiveIds,
      reanalyzedDivergedPrimitiveIds:
          reanalyzedDivergedPrimitiveIds ?? this.reanalyzedDivergedPrimitiveIds,
    );
  }
}

const Object _unset = Object();
