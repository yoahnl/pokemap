import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/main.dart' show MapEditorApp;
import 'package:map_editor/src/debug/marionette_project_bootstrap.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_feature_authoring_controller.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_feature_inspection.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_map_editing_providers.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_preview_providers.dart';
import 'package:map_editor/src/features/border_studio/application/border_asset_snapshot_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_project_element_asset_service.dart';
import 'package:map_editor/src/features/border_studio/application/border_smart_tile_ground_snapshot_service.dart';
import 'package:map_editor/src/features/border_studio/state/border_studio_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_selectors.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

Map<String, Object?> openPersonalizationStudioForMarionette({
  required ProviderContainer container,
}) {
  container
      .read(editorNotifierProvider.notifier)
      .selectPersonalizationStudioWorkspace();
  final editor = container.read(editorNotifierProvider);
  return <String, Object?>{
    'opened': editor.workspaceMode == EditorWorkspaceMode.personalizationStudio,
    'workspaceMode': editor.workspaceMode.name,
    'projectRootPath': editor.projectRootPath,
    'projectName': editor.project?.name,
  };
}

/// Debug-only entrypoint for deterministic, observable macOS QA.
void main() {
  // Marionette must be the sole binding initializer in this process.
  MarionetteBinding.ensureInitialized();

  const configuredProjectPath = String.fromEnvironment(
    MarionetteProjectBootstrap.projectPathDefine,
  );
  final bootstrap = MarionetteProjectBootstrap.load(configuredProjectPath);
  final initialState = bootstrap.createInitialState();
  final container = ProviderContainer(
    overrides: <Override>[
      editorNotifierProvider.overrideWith(
        () => _MarionetteSeededEditorNotifier(initialState),
      ),
    ],
  );

  // Force provider creation before runApp, then expose the live provider state
  // so the driver can prove that the rendered shell owns the expected copy.
  container.read(editorNotifierProvider);
  registerMarionetteExtension(
    name: 'pokemap.activeProjectPath',
    description: 'Returns the active and expected PokeMap project roots.',
    callback: (_) async {
      final activePath = container.read(editorNotifierProvider).projectRootPath;
      return MarionetteExtensionResult.success(<String, dynamic>{
        'activeProjectPath': activePath,
        'expectedProjectPath': bootstrap.projectRootPath,
        'matches': activePath == bootstrap.projectRootPath,
      });
    },
  );
  registerMarionetteExtension(
    name: 'pokemap.openPersonalizationStudio',
    description:
        'Opens Personalization Studio through the real editor controller.',
    callback: (_) async {
      return MarionetteExtensionResult.success(
        openPersonalizationStudioForMarionette(container: container),
      );
    },
  );
  developer.registerExtension(
    'ext.flutter.pokemap.marionette.projectContext',
    (_, __) async {
      final editor = container.read(editorNotifierProvider);
      return developer.ServiceExtensionResponse.result(
        jsonEncode(<String, Object?>{
          'ready': editor.project != null,
          'projectRootPath': editor.projectRootPath,
          'projectName': editor.project?.name,
        }),
      );
    },
  );
  developer.registerExtension(
    'ext.flutter.pokemap.marionette.drawPolyline',
    (_, parameters) => _drawPolyline(parameters),
  );
  developer.registerExtension(
    'ext.flutter.pokemap.marionette.openMap',
    (_, parameters) async {
      final relativePath = parameters['relativePath'];
      if (relativePath == null || relativePath.isEmpty) {
        return developer.ServiceExtensionResponse.result(
          jsonEncode(<String, Object?>{
            'opened': false,
            'error': 'relativePath is required.',
          }),
        );
      }
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.selectMapWorkspace();
      await notifier.loadMap(relativePath);
      final activeEditor = container.read(editorNotifierProvider);
      return developer.ServiceExtensionResponse.result(
        jsonEncode(<String, Object?>{
          'opened': activeEditor.activeMap != null,
          'relativePath': relativePath,
          'activeMapId': activeEditor.activeMap?.id,
          'activeMapName': activeEditor.activeMap?.name,
          'errorMessage': activeEditor.errorMessage,
          'statusMessage': activeEditor.statusMessage,
        }),
      );
    },
  );
  developer.registerExtension(
    'ext.flutter.pokemap.marionette.prepareBorderQAPreview',
    (_, parameters) async {
      final relativePath = parameters['relativePath'];
      final blueprintId = parameters['blueprintId'];
      if (relativePath == null ||
          relativePath.isEmpty ||
          blueprintId == null ||
          blueprintId.isEmpty) {
        return developer.ServiceExtensionResponse.result(
          jsonEncode(<String, Object?>{
            'prepared': false,
            'error': 'relativePath and blueprintId are required.',
          }),
        );
      }
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.selectMapWorkspace();
      await notifier.loadMap(relativePath);
      var activeEditor = container.read(editorNotifierProvider);
      final loadedMap = activeEditor.activeMap;
      if (loadedMap == null) {
        return developer.ServiceExtensionResponse.result(
          jsonEncode(<String, Object?>{
            'prepared': false,
            'error': 'The requested map could not be loaded.',
            'errorMessage': activeEditor.errorMessage,
          }),
        );
      }
      final hiddenLayerIds = <String>[];
      for (final layer in loadedMap.layers.whereType<BorderLayer>()) {
        if (!layer.isVisible) continue;
        notifier.setMapLayerVisibility(layer.id, false);
        hiddenLayerIds.add(layer.id);
      }
      notifier.addMapLayer(
        kind: MapLayerKind.border,
        name: parameters['layerName'] ?? 'Bordures QA',
      );
      activeEditor = container.read(editorNotifierProvider);
      final qaMap = activeEditor.activeMap;
      final qaLayer = qaMap?.layers
          .whereType<BorderLayer>()
          .where((layer) => layer.id == activeEditor.activeLayerId)
          .firstOrNull;
      if (qaMap == null || qaLayer == null) {
        return developer.ServiceExtensionResponse.result(
          jsonEncode(<String, Object?>{
            'prepared': false,
            'error': 'The in-memory Border QA layer was not created.',
            'errorMessage': activeEditor.errorMessage,
          }),
        );
      }
      notifier.createBorderFeature(
        layerId: qaLayer.id,
        blueprintId: blueprintId,
        name: parameters['featureName'] ?? 'Bordure QA',
      );
      activeEditor = container.read(editorNotifierProvider);
      final preparedLayer = activeEditor.activeMap?.layers
          .whereType<BorderLayer>()
          .where((layer) => layer.id == qaLayer.id)
          .firstOrNull;
      final feature = preparedLayer?.content.features.lastOrNull;
      return developer.ServiceExtensionResponse.result(
        jsonEncode(<String, Object?>{
          'prepared': feature != null,
          'activeMapId': activeEditor.activeMap?.id,
          'layerId': preparedLayer?.id,
          'featureId': feature?.id,
          'blueprintId': feature?.blueprintId,
          'hiddenLayerIds': hiddenLayerIds,
          'mapDirty': activeEditor.isDirty,
          'errorMessage': activeEditor.errorMessage,
          'statusMessage': activeEditor.statusMessage,
        }),
      );
    },
  );
  developer.registerExtension(
    'ext.flutter.pokemap.marionette.setMapViewport',
    (_, parameters) async {
      final requestedZoom = double.tryParse(parameters['zoom'] ?? '');
      final requestedPanX = double.tryParse(parameters['panX'] ?? '');
      final requestedPanY = double.tryParse(parameters['panY'] ?? '');
      if (requestedZoom == null &&
          requestedPanX == null &&
          requestedPanY == null) {
        return developer.ServiceExtensionResponse.result(
          jsonEncode(<String, Object?>{
            'updated': false,
            'error': 'At least one of zoom, panX, or panY is required.',
          }),
        );
      }
      final notifier = container.read(editorNotifierProvider.notifier);
      var activeEditor = container.read(editorNotifierProvider);
      if (requestedZoom != null) {
        notifier.zoom(requestedZoom - activeEditor.zoom);
        activeEditor = container.read(editorNotifierProvider);
      }
      final targetPan = Offset(
        requestedPanX ?? activeEditor.panOffset.dx,
        requestedPanY ?? activeEditor.panOffset.dy,
      );
      notifier.pan(targetPan - activeEditor.panOffset);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      activeEditor = container.read(editorNotifierProvider);
      return developer.ServiceExtensionResponse.result(
        jsonEncode(<String, Object?>{
          'updated': true,
          'zoom': activeEditor.zoom,
          'panX': activeEditor.panOffset.dx,
          'panY': activeEditor.panOffset.dy,
          'activeMapId': activeEditor.activeMap?.id,
        }),
      );
    },
  );
  developer.registerExtension(
    'ext.flutter.pokemap.marionette.inspectBorderFeature',
    (_, parameters) async {
      final activeEditor = container.read(editorNotifierProvider);
      final preview = container.read(borderPreviewControllerProvider);
      final transaction = preview.transaction;
      return developer.ServiceExtensionResponse.result(
        jsonEncode(
          <String, Object?>{
            ...inspectBorderFeature(
              map: activeEditor.activeMap,
              project: activeEditor.project,
              layerId: parameters['layerId'],
              featureId: parameters['featureId'],
              preview: transaction == null
                  ? null
                  : BorderFeatureInspectionPreview(
                      layerId: transaction.layerId,
                      feature: transaction.proposedFeature,
                      materialization: transaction.result?.materialization,
                    ),
            ),
            'previewPhase': preview.phase.name,
            'previewDiagnostics': transaction?.result == null
                ? const <Object?>[]
                : _borderDiagnosticsJson(
                    transaction!.result!.diagnosticReport,
                  ),
          },
        ),
      );
    },
  );
  developer.registerExtension(
    'ext.flutter.pokemap.marionette.selectEditorTool',
    (_, parameters) async => developer.ServiceExtensionResponse.result(
      jsonEncode(
        selectEditorToolForMarionette(
          container: container,
          parameters: parameters,
        ),
      ),
    ),
  );
  developer.registerExtension(
    'ext.flutter.pokemap.marionette.setBorderPreviewAutoRotation',
    (_, parameters) async => developer.ServiceExtensionResponse.result(
      jsonEncode(
        setBorderPreviewAutoRotationForMarionette(
          container: container,
          parameters: parameters,
        ),
      ),
    ),
  );
  developer.registerExtension(
    'ext.flutter.pokemap.marionette.selectBorderBlueprint',
    (_, parameters) async {
      final blueprintId = parameters['blueprintId'];
      if (blueprintId == null || blueprintId.isEmpty) {
        return developer.ServiceExtensionResponse.result(
          jsonEncode(<String, Object?>{
            'selected': false,
            'error': 'blueprintId is required.',
          }),
        );
      }
      container
          .read(editorNotifierProvider.notifier)
          .selectBorderStudioWorkspace();
      final controller =
          container.read(borderStudioDraftControllerProvider.notifier);
      controller.selectBlueprint(blueprintId);
      final state = container.read(borderStudioDraftControllerProvider);
      return developer.ServiceExtensionResponse.result(
        jsonEncode(<String, Object?>{
          'selected': state.selectedBlueprintId == blueprintId,
          'selectedBlueprintId': state.selectedBlueprintId,
        }),
      );
    },
  );
  developer.registerExtension(
    'ext.flutter.pokemap.marionette.reanalyzeSavePublishBorderBlueprint',
    (_, parameters) => _reanalyzeSavePublishBorderBlueprint(
      container: container,
      parameters: parameters,
    ),
  );
  developer.registerExtension(
    'ext.flutter.pokemap.marionette.applyBorderPreviewAndSave',
    (_, parameters) async {
      final notifier = container.read(editorNotifierProvider.notifier);
      final layerId = parameters['layerId'];
      final featureId = parameters['featureId'];
      final hasTarget = layerId != null && featureId != null;
      if (hasTarget) {
        notifier.selectBorderFeature(
          layerId: layerId,
          featureId: featureId,
        );
      }
      final prepared = hasTarget
          ? notifier.previewBorderFeatureUpdate(
              layerId: layerId,
              featureId: featureId,
            )
          : false;
      final applied = prepared && notifier.applyPendingBorderPreview();
      final saveOutcome = applied ? await notifier.saveActiveMap() : null;
      final editor = container.read(editorNotifierProvider);
      return developer.ServiceExtensionResponse.result(
        jsonEncode(<String, Object?>{
          'prepared': prepared,
          'applied': applied,
          'saveOutcome': saveOutcome?.toString(),
          'activeMapId': editor.activeMap?.id,
          'errorMessage': editor.errorMessage,
          'statusMessage': editor.statusMessage,
        }),
      );
    },
  );
  developer.registerExtension(
    'ext.flutter.pokemap.marionette.relinkBorderFeatureAndSave',
    (_, parameters) async {
      final notifier = container.read(editorNotifierProvider.notifier);
      final activeEditor = container.read(editorNotifierProvider);
      final map = activeEditor.activeMap;
      final project = activeEditor.project;
      final layerId = parameters['layerId'];
      final featureId = parameters['featureId'];
      final targetBlueprintId = parameters['targetBlueprintId'];
      if (map == null || project == null) {
        return developer.ServiceExtensionResponse.result(
          jsonEncode(<String, Object?>{
            'canApply': false,
            'error': 'No active map or project.',
          }),
        );
      }
      final layer = map.layers
          .whereType<BorderLayer>()
          .where((candidate) => candidate.id == layerId)
          .firstOrNull;
      final feature = layer?.content.featureById(featureId ?? '');
      final target = project.borderCatalog.recordById(targetBlueprintId ?? '');
      if (layer == null || feature == null || target == null) {
        return developer.ServiceExtensionResponse.result(
          jsonEncode(<String, Object?>{
            'canApply': false,
            'error': 'Border relink target not found.',
            'layerId': layerId,
            'featureId': featureId,
            'targetBlueprintId': targetBlueprintId,
          }),
        );
      }
      final preview =
          const BorderFeatureAuthoringController().previewBlueprintChange(
        map: map,
        layerId: layer.id,
        featureId: feature.id,
        sourceBlueprint: project.borderCatalog.recordById(feature.blueprintId),
        targetBlueprint: target,
        visualSnapshots: project.borderCatalog.visualSnapshots,
        tileSizePx: GridSize(
          width: project.settings.tileWidth,
          height: project.settings.tileHeight,
        ),
      );
      if (preview.canApply) {
        notifier.changeBorderFeatureBlueprint(preview);
      }
      final saveOutcome =
          preview.canApply ? await notifier.saveActiveMap() : null;
      final updatedEditor = container.read(editorNotifierProvider);
      final updatedFeature = updatedEditor.activeMap?.layers
          .whereType<BorderLayer>()
          .where((candidate) => candidate.id == layer.id)
          .firstOrNull
          ?.content
          .featureById(feature.id);
      return developer.ServiceExtensionResponse.result(
        jsonEncode(<String, Object?>{
          'canApply': preview.canApply,
          'blockedReason': preview.blockedReason,
          'losses': preview.losses.map((loss) => loss.name).toList(),
          'diagnostics':
              preview.relink.proposedResult?.diagnosticReport.diagnostics
                  .map(
                    (diagnostic) => <String, Object?>{
                      'severity': diagnostic.severity.name,
                      'code': diagnostic.code,
                      'parameters': diagnostic.parameters,
                    },
                  )
                  .toList(),
          'blueprintId': updatedFeature?.blueprintId,
          'placementCount': updatedFeature?.materialization?.placements.length,
          'saveOutcome': saveOutcome?.toString(),
          'errorMessage': updatedEditor.errorMessage,
          'statusMessage': updatedEditor.statusMessage,
        }),
      );
    },
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MapEditorApp(),
    ),
  );
}

/// Seeds only the debug container; production continues to use EditorNotifier.
final class _MarionetteSeededEditorNotifier extends EditorNotifier {
  _MarionetteSeededEditorNotifier(this.initialState);

  final EditorState initialState;

  @override
  EditorState build() => initialState;
}

/// Selects the sole editor tool needed by the Border Marionette QA flow.
///
/// This dev-only adapter deliberately delegates to [EditorNotifier.selectTool]
/// and performs no map authoring, history mutation or persistence action.
Map<String, Object?> selectEditorToolForMarionette({
  required ProviderContainer container,
  required Map<String, String> parameters,
}) {
  if (parameters['tool'] != EditorToolType.borderPaint.name) {
    return <String, Object?>{
      'selected': false,
      'error': 'tool must be borderPaint.',
    };
  }
  container
      .read(editorNotifierProvider.notifier)
      .selectTool(EditorToolType.borderPaint);
  final editor = container.read(editorNotifierProvider);
  final activeBorder = container.read(activeBorderFeatureControllerProvider);
  return <String, Object?>{
    'selected': editor.activeTool == EditorToolType.borderPaint,
    'activeTool': editor.activeTool.name,
    'activeLayerId': editor.activeLayerId,
    'activeBorderFeatureId': activeBorder.activeFeatureId,
    'featureId': activeBorder.activeFeatureId,
  };
}

/// Disables decorative filler assets without changing their authored metadata.
///
/// The Border QA publication flow uses this to isolate the two structural
/// cliff rows. Cardinal orientation is intentionally preserved because a
/// missing value decodes as the legacy-axis mode and invalidates rotation-off
/// coverage.
List<BorderPrimitiveDraft> disableFillerPrimitivesForMarionette(
  List<BorderPrimitiveDraft> primitives,
) =>
    <BorderPrimitiveDraft>[
      for (final primitive in primitives)
        BorderPrimitiveDraft(
          id: primitive.id,
          sourceElementId: primitive.sourceElementId,
          role: primitive.role,
          authoredOrientation: primitive.authoredOrientation,
          weight: primitive.role == BorderPrimitiveRole.filler
              ? 0
              : primitive.weight,
          anchorPx: primitive.anchorPx,
          transforms: primitive.transforms,
          currentMetrics: primitive.currentMetrics,
        ),
    ];

/// Refines only the resolved Border preview used by visual QA.
///
/// The editor notifier owns the no-Apply/no-history contract. This dev-only
/// adapter validates a strict boolean wire and returns enough identity and
/// slot evidence for Marionette to reject an accidental target change.
Map<String, Object?> setBorderPreviewAutoRotationForMarionette({
  required ProviderContainer container,
  required Map<String, String> parameters,
}) {
  final layerId = parameters['layerId']?.trim();
  final featureId = parameters['featureId']?.trim();
  final enabledWire = parameters['enabled'];
  if (layerId == null ||
      layerId.isEmpty ||
      featureId == null ||
      featureId.isEmpty ||
      (enabledWire != 'true' && enabledWire != 'false')) {
    return <String, Object?>{
      'updated': false,
      'error': 'layerId, featureId and enabled=true|false are required.',
    };
  }
  final enabled = enabledWire == 'true';
  final notifier = container.read(editorNotifierProvider.notifier);
  final updated = notifier.previewBorderFeatureAutoRotation(
    layerId: layerId,
    featureId: featureId,
    enabled: enabled,
  );
  final editor = container.read(editorNotifierProvider);
  final preview = container.read(borderPreviewControllerProvider);
  final transaction = preview.transaction;
  final placements = transaction?.result?.materialization?.placements ??
      const <BorderResolvedPlacement>[];
  final slotKeys = placements
      .map((placement) => placement.slotKey)
      .toList(growable: false)
    ..sort();
  return <String, Object?>{
    'updated': updated,
    'layerId': transaction?.layerId,
    'featureId': transaction?.featureId,
    'allowAutoRotation':
        transaction?.proposedFeature.paramsOverride?.allowAutoRotation,
    'previewPhase': preview.phase.name,
    'canApply': transaction?.result?.canApply,
    'placementCount': placements.length,
    'slotKeys': slotKeys,
    'errorMessage': editor.errorMessage,
  };
}

Future<developer.ServiceExtensionResponse>
    _reanalyzeSavePublishBorderBlueprint({
  required ProviderContainer container,
  required Map<String, String> parameters,
}) async {
  const assetService = BorderProjectElementAssetService();
  const groundSnapshotService = BorderSmartTileGroundSnapshotService();
  var stage = 'validate-input';
  String? blueprintId;
  final reanalyzedPrimitives = <Map<String, Object?>>[];

  developer.ServiceExtensionResponse response(Map<String, Object?> payload) =>
      developer.ServiceExtensionResponse.result(jsonEncode(payload));

  try {
    final initialState = container.read(borderStudioDraftControllerProvider);
    blueprintId = parameters['blueprintId']?.trim();
    if (blueprintId == null || blueprintId.isEmpty) {
      blueprintId = initialState.selectedBlueprintId;
    }
    if (blueprintId == null || blueprintId.isEmpty) {
      return response(<String, Object?>{
        'ok': false,
        'stage': stage,
        'error': 'blueprintId is required when no blueprint is selected.',
      });
    }

    final manifest = container.read(editorProjectManifestProvider);
    final projectRootPath = container.read(editorProjectRootPathProvider);
    if (manifest == null ||
        projectRootPath == null ||
        projectRootPath.trim().isEmpty) {
      return response(<String, Object?>{
        'ok': false,
        'stage': stage,
        'blueprintId': blueprintId,
        'error': 'No active project.',
      });
    }

    stage = 'select-blueprint';
    container
        .read(editorNotifierProvider.notifier)
        .selectBorderStudioWorkspace();
    final controller =
        container.read(borderStudioDraftControllerProvider.notifier);
    controller.selectBlueprint(blueprintId);
    final selectedState = container.read(borderStudioDraftControllerProvider);
    final working = selectedState.workingDraft;
    if (working == null || working.id != blueprintId) {
      throw StateError('The requested Border blueprint was not selected.');
    }

    final requestedDetailDensity =
        int.tryParse(parameters['detailDensityPermille'] ?? '');
    final requestedIrregularity =
        int.tryParse(parameters['irregularityPermille'] ?? '');
    final requestedMaximumOverlap =
        int.tryParse(parameters['maxOverlapPx'] ?? '');
    final requestedGapTolerance =
        int.tryParse(parameters['gapTolerancePx'] ?? '');
    if (requestedDetailDensity != null ||
        requestedIrregularity != null ||
        requestedMaximumOverlap != null ||
        requestedGapTolerance != null) {
      final defaults = working.blueprint.definition.defaults;
      controller.setGenerationParams(
        BorderGenerationParams(
          irregularityPermille:
              requestedIrregularity ?? defaults.irregularityPermille,
          detailDensityPermille:
              requestedDetailDensity ?? defaults.detailDensityPermille,
          variationPermille: defaults.variationPermille,
          maxOverlapPx: requestedMaximumOverlap ?? defaults.maxOverlapPx,
          gapTolerancePx: requestedGapTolerance ?? defaults.gapTolerancePx,
          depthRows: defaults.depthRows,
          allowAutoRotation: defaults.allowAutoRotation,
        ),
      );
    }
    if (parameters['disableFillerPrimitives'] == 'true') {
      final current = container
          .read(borderStudioDraftControllerProvider)
          .workingDraft!
          .blueprint
          .definition
          .primitives;
      controller.replacePrimitives(
        disableFillerPrimitivesForMarionette(current),
      );
    }

    stage = 'reanalyze-primitives';
    final configuredWorking =
        container.read(borderStudioDraftControllerProvider).workingDraft!;
    final primitives = List<BorderPrimitiveDraft>.of(
      configuredWorking.blueprint.definition.primitives,
    );
    for (final primitive in primitives) {
      final prepared = await assetService.reanalyze(
        manifest: manifest,
        projectRootPath: projectRootPath,
        primitive: primitive,
      );
      controller.replacePrimitiveAfterReanalysis(prepared.primitive);
      reanalyzedPrimitives.add(<String, Object?>{
        'primitiveId': primitive.id,
        'sourceElementId': primitive.sourceElementId,
        'previousFingerprint': primitive.currentMetrics.assetFingerprint,
        'currentFingerprint':
            prepared.primitive.currentMetrics.assetFingerprint,
        'pixelWidth': prepared.primitive.currentMetrics.pixelSize.width,
        'pixelHeight': prepared.primitive.currentMetrics.pixelSize.height,
      });
    }

    stage = 'save-draft';
    final savedDraftManifest = controller.saveDraft();
    final editor = container.read(editorNotifierProvider.notifier);
    editor.applyInMemoryProjectManifest(
      savedDraftManifest,
      statusMessage: 'Brouillon Border réanalysé via Marionette.',
    );
    final draftSaved = await editor.saveProjectManifest();
    if (!draftSaved) {
      throw StateError('The reanalyzed Border draft could not be saved.');
    }

    final savedRecord =
        savedDraftManifest.borderCatalog.recordById(blueprintId);
    if (savedRecord == null) {
      throw StateError('The saved Border blueprint record is missing.');
    }

    stage = 'prepare-publication';
    final prepareCoordinator =
        container.read(borderStudioPublicationCoordinatorProvider);
    if (prepareCoordinator == null) {
      throw StateError('Border publication is unavailable for this project.');
    }
    final ground = savedRecord.draft.definition.ground;
    final groundSnapshots = ground == null
        ? const <BorderGroundVariantRole, BorderAssetSnapshotPreparation>{}
        : await groundSnapshotService.prepareAllRoles(
            manifest: savedDraftManifest,
            projectRootPath: projectRootPath,
            sourceSmartTilePresetId: ground.sourceSmartTilePresetId,
          );
    final preview = await prepareCoordinator.prepare(
      manifest: savedDraftManifest,
      projectRootPath: projectRootPath,
      draftRecord: savedRecord,
      groundSnapshotsByRole: groundSnapshots,
    );
    controller.setDiagnostics(preview.diagnostics);
    if (preview.diagnostics.hasErrors) {
      return response(<String, Object?>{
        'ok': false,
        'stage': stage,
        'blueprintId': blueprintId,
        'reanalyzedPrimitiveCount': reanalyzedPrimitives.length,
        'reanalyzedPrimitives': reanalyzedPrimitives,
        'draftSaved': draftSaved,
        'candidateRevision': preview.candidate.revision,
        'canonicalCaseCount': preview.canonicalGalleryCases.length,
        'diagnostics': _borderDiagnosticsJson(preview.diagnostics),
        'error': 'Publication preview contains blocking diagnostics.',
      });
    }

    stage = 'acknowledge-warnings';
    final warningCodes = preview.warningCodes.toList(growable: false)..sort();
    for (final code in warningCodes) {
      controller.acknowledgeWarningCode(code);
    }
    final acknowledgedWarningCodes = container
        .read(borderStudioDraftControllerProvider)
        .acknowledgedWarningCodes;

    // Read the coordinator again after diagnostics/acknowledgements mutate
    // authoring state. Its manifest transaction deliberately captures the
    // latest editor session and rejects stale in-memory refreshes.
    stage = 'publish';
    final publishCoordinator =
        container.read(borderStudioPublicationCoordinatorProvider);
    if (publishCoordinator == null) {
      throw StateError('Border publication became unavailable.');
    }
    final result = await publishCoordinator.publish(
      preview: preview,
      currentManifest: savedDraftManifest,
      currentDraftRecord: savedRecord,
      acknowledgedWarningCodes: acknowledgedWarningCodes,
    );
    controller.synchronizeFromManifest(
      result.manifest,
      projectIdentity: projectRootPath,
    );
    final publishedRecord = result.manifest.borderCatalog.recordById(
      blueprintId,
    );

    return response(<String, Object?>{
      'ok': true,
      'stage': 'complete',
      'projectRootPath': projectRootPath,
      'blueprintId': blueprintId,
      'reanalyzedPrimitiveCount': reanalyzedPrimitives.length,
      'reanalyzedPrimitives': reanalyzedPrimitives,
      'draftSaved': draftSaved,
      'candidateRevision': preview.candidate.revision,
      'publishedRevision': publishedRecord?.latestPublished?.revision,
      'canonicalCaseCount': preview.canonicalGalleryCases.length,
      'acceptedWarningCodes': warningCodes,
      'diagnostics': _borderDiagnosticsJson(result.diagnostics),
      'createdSnapshotPaths': result.snapshotFinalize.createdRelativePaths,
      'deduplicatedSnapshotPaths':
          result.snapshotFinalize.deduplicatedRelativePaths,
      'stagingCleanupPending': result.stagingCleanupPending,
    });
  } catch (error) {
    return response(<String, Object?>{
      'ok': false,
      'stage': stage,
      if (blueprintId != null) 'blueprintId': blueprintId,
      'reanalyzedPrimitiveCount': reanalyzedPrimitives.length,
      'reanalyzedPrimitives': reanalyzedPrimitives,
      'errorType': error.runtimeType.toString(),
      'error': error.toString(),
    });
  }
}

List<Map<String, Object?>> _borderDiagnosticsJson(
  BorderDiagnosticsReport report,
) =>
    <Map<String, Object?>>[
      for (final diagnostic in report.diagnostics)
        <String, Object?>{
          'severity': diagnostic.severity.name,
          'phase': diagnostic.phase.name,
          'scope': diagnostic.scope.name,
          'code': diagnostic.code,
          'parameters': diagnostic.parameters,
          'suggestedAction': diagnostic.suggestedAction,
        },
    ];

Future<developer.ServiceExtensionResponse> _drawPolyline(
  Map<String, String> parameters,
) async {
  try {
    final scrollDeltaY = double.tryParse(parameters['scrollDeltaY'] ?? '');
    if (scrollDeltaY != null) {
      final position = Offset(
        double.tryParse(parameters['x'] ?? '') ?? 1200,
        double.tryParse(parameters['y'] ?? '') ?? 900,
      );
      GestureBinding.instance.handlePointerEvent(
        PointerScrollEvent(
          position: position,
          scrollDelta: Offset(0, scrollDeltaY),
          kind: PointerDeviceKind.mouse,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return developer.ServiceExtensionResponse.result(
        jsonEncode(<String, Object?>{
          'ok': true,
          'scrollDeltaY': scrollDeltaY,
          'x': position.dx,
          'y': position.dy,
        }),
      );
    }
    final rawPoints = parameters['points'];
    if (rawPoints == null) {
      throw const FormatException('Missing points JSON.');
    }
    final decoded = jsonDecode(rawPoints);
    if (decoded is! List || decoded.length < 2) {
      throw const FormatException('points must contain at least two entries.');
    }
    final points = decoded.map((entry) {
      if (entry is! Map) {
        throw const FormatException('Each point must be an object.');
      }
      final x = entry['x'];
      final y = entry['y'];
      if (x is! num || y is! num) {
        throw const FormatException('Each point needs numeric x and y.');
      }
      return Offset(x.toDouble(), y.toDouble());
    }).toList(growable: false);
    final spacing = math.max(
      1.0,
      double.tryParse(parameters['spacing'] ?? '') ?? 8.0,
    );
    final moveDelayMs = math.max(
      0,
      int.tryParse(parameters['moveDelayMs'] ?? '') ?? 8,
    );
    final buttons = switch (parameters['buttons']) {
      'secondary' => kSecondaryMouseButton,
      'tertiary' => kMiddleMouseButton,
      _ => kPrimaryMouseButton,
    };
    const pointer = 424242;
    const device = 424242;
    var previous = points.first;
    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(
        pointer: pointer,
        device: device,
        position: previous,
        kind: PointerDeviceKind.mouse,
        buttons: buttons,
      ),
    );
    await Future<void>.delayed(Duration(milliseconds: moveDelayMs));
    var emittedMoves = 0;
    for (var index = 1; index < points.length; index += 1) {
      final start = points[index - 1];
      final end = points[index];
      final distance = (end - start).distance;
      final steps = math.max(1, (distance / spacing).ceil());
      for (var step = 1; step <= steps; step += 1) {
        final next = Offset.lerp(start, end, step / steps)!;
        GestureBinding.instance.handlePointerEvent(
          PointerMoveEvent(
            pointer: pointer,
            device: device,
            position: next,
            delta: next - previous,
            kind: PointerDeviceKind.mouse,
            buttons: buttons,
          ),
        );
        previous = next;
        emittedMoves += 1;
        await Future<void>.delayed(Duration(milliseconds: moveDelayMs));
      }
    }
    GestureBinding.instance.handlePointerEvent(
      PointerUpEvent(
        pointer: pointer,
        device: device,
        position: previous,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return developer.ServiceExtensionResponse.result(
      jsonEncode(<String, Object?>{
        'ok': true,
        'pointCount': points.length,
        'emittedMoves': emittedMoves,
      }),
    );
  } on Object catch (error, stackTrace) {
    return developer.ServiceExtensionResponse.result(
      jsonEncode(<String, Object?>{
        'ok': false,
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      }),
    );
  }
}
