import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/models/editor_workspace_mode.dart';
import '../../application/models/narrative_document_route.dart';
import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../features/narrative/state/scene_consequence_catalog_providers.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';
import 'cinematics/cinematic_library_dialogs.dart';
import 'narrative_studio/narrative_studio_route_presentation.dart';
import 'narrative_studio/narrative_studio_workspace_page.dart';
import 'scenes/scene_action_builder.dart';
import 'scenes/scene_cinematic_picker.dart';
import 'scenes/scene_graph_editor.dart';
import 'scenes/scene_graph_read_only_view.dart';
import 'scenes/scene_library_panel.dart';
import 'scenes/scene_node_read_only_inspector.dart';
import 'scenes/scene_presentation_cinematic_picker.dart';

typedef SceneDraftCreator = Future<String?> Function({
  required String name,
  String? description,
});

typedef SceneNodeDraftCreator = Future<String?> Function({
  required String sceneId,
  required SceneNodeKind kind,
});

typedef SceneLinkedAssetNodeDraftCreator = Future<String?> Function({
  required String sceneId,
  required SceneNodePayload payload,
  String? title,
});

typedef SceneConsequenceActionNodeDraftCreator = Future<String?> Function({
  required String sceneId,
  required SceneConsequence consequence,
  String? title,
});

typedef _SelectedLinkedAssetNodeDraftCreator = Future<void> Function({
  required SceneNodePayload payload,
  String? title,
});

typedef _SelectedConsequenceActionNodeDraftCreator = Future<void> Function({
  required SceneConsequence consequence,
  String? title,
});

typedef SceneEdgeDraftCreator = Future<String?> Function({
  required String sceneId,
  required String fromNodeId,
  required String fromPortId,
  required String toNodeId,
});

typedef SceneEdgeDraftRemover = Future<bool> Function({
  required String sceneId,
  required String edgeId,
});

typedef SceneNodeDraftRemover = Future<bool> Function({
  required String sceneId,
  required String nodeId,
});

typedef SceneNodeDraftDuplicator = Future<String?> Function({
  required String sceneId,
  required String nodeId,
});

typedef SceneNodeLayoutUpdater = Future<void> Function({
  required String sceneId,
  required String nodeId,
  required double x,
  required double y,
});

typedef SceneConditionSourceUpdater = Future<bool> Function({
  required String sceneId,
  required String nodeId,
  required SceneConditionSource source,
});

typedef SceneEndPayloadUpdater = Future<bool> Function({
  required String sceneId,
  required String nodeId,
  String? sceneOutcomeId,
  required SceneOutcomePolicy? outcomePolicy,
});

typedef SceneYarnDialoguePayloadUpdater = Future<bool> Function({
  required String sceneId,
  required String nodeId,
  required String dialogueId,
  String? yarnNodeName,
  required List<String> expectedOutcomes,
});

typedef SceneBattlePayloadUpdater = Future<bool> Function({
  required String sceneId,
  required String nodeId,
  required String trainerId,
  required String battleKind,
  String? battleTemplateId,
});

typedef SceneCinematicPayloadUpdater = Future<bool> Function({
  required String sceneId,
  required String nodeId,
  required String cinematicId,
});

typedef SceneActionConsequenceUpdater = Future<bool> Function({
  required String sceneId,
  required String nodeId,
  required SceneConsequence consequence,
});

typedef SceneLinkedAssetOpener = void Function({
  required String sceneId,
  required String nodeId,
  required String assetId,
});

final class ScenePresentationCreateAndLinkOutcome {
  const ScenePresentationCreateAndLinkOutcome({
    required this.cinematicId,
    required this.nodeId,
  });

  final String cinematicId;
  final String nodeId;
}
typedef ScenePresentationCreateAndLinkCreator =
    Future<ScenePresentationCreateAndLinkOutcome?> Function({
  required String sceneId,
  required String targetNodeId,
  required String title,
  required String templateId,
  required int templateVersion,
  required String? folderId,
});

typedef ScenePresentationCreateAndLinkOpener = void Function({
  required String sceneId,
  required String returnNodeId,
  required String cinematicId,
  required SceneGraphViewport viewport,
  required NarrativeSceneInspector inspector,
});

typedef SceneLibraryEditor = Future<SceneLibraryMutationResult?> Function({
  required String sceneId,
  required String name,
  required SceneLibraryLocation location,
  required List<String> tags,
  required List<SceneOutcome> declaredOutcomes,
});

typedef SceneLibraryDuplicator = Future<SceneLibraryMutationResult?> Function({
  required String sceneId,
});

typedef SceneLibraryArchiveToggler = Future<SceneLibraryMutationResult?>
    Function({
  required String sceneId,
  required bool archived,
});

typedef SceneLibraryDeleter = Future<SceneLibraryMutationResult?> Function({
  required String sceneId,
  String? replacementSceneId,
});

const _scenesInlineInspectorMinWidth = 1240.0;

class ScenesWorkspace extends StatefulWidget {
  const ScenesWorkspace({
    super.key,
    required this.scenes,
    this.linkedAssetContracts,
    this.cinematicsLibrary,
    this.presentationCinematics = const [],
    this.presentationFolders = const [],
    this.conditionSourceOptions = const [],
    this.consequenceFactOptions = const [],
    this.consequenceEventOptions = const [],
    this.consequenceCatalogs = const SceneConsequenceCatalogs.unavailable(),
    this.actionPickerOptions = const {},
    this.requestedSceneId,
    this.requestedNodeId,
    this.requestedSceneFocusNonce,
    this.strictRequestedSceneFocus = false,
    this.requestedFocusAnchorId,
    this.requestedViewportX,
    this.requestedViewportY,
    this.requestedZoom,
    this.requestedInspector,
    this.requestedRestorationRevision,
    this.onRestorationApplied,
    required this.onCreateSceneDraft,
    required this.onAddNodeDraft,
    required this.onAddLinkedAssetNodeDraft,
    required this.onAddConsequenceActionNodeDraft,
    required this.onAddEdgeDraft,
    required this.onRemoveEdgeDraft,
    required this.onRemoveNodeDraft,
    this.onDuplicateNodeDraft,
    required this.onUpdateNodeLayout,
    required this.onUpdateConditionSource,
    this.onUpdateEndPayload,
    required this.onUpdateYarnDialoguePayload,
    required this.onUpdateBattlePayload,
    required this.onUpdateCinematicPayload,
    required this.onUpdateActionConsequence,
    this.onOpenDialogue,
    this.onOpenCinematic,
    this.onCreateAndLinkPresentation,
    this.onOpenCreatedPresentation,
    this.sceneConsumerPaths = const <String, List<String>>{},
    this.onEditScene,
    this.onDuplicateScene,
    this.onToggleArchiveScene,
    this.onDeleteScene,
  });

  final List<NarrativeSceneSummary> scenes;
  final LinkedAssetContractsSnapshot? linkedAssetContracts;
  final CinematicsLibraryReadModel? cinematicsLibrary;
  final List<PresentationCinematicAsset> presentationCinematics;
  final List<CinematicLibraryFolder> presentationFolders;
  final List<SceneConditionSourcePickerOption> conditionSourceOptions;
  final List<SceneConsequenceFactPickerOption> consequenceFactOptions;
  final List<SceneConsequenceEventPickerOption> consequenceEventOptions;
  final SceneConsequenceCatalogs consequenceCatalogs;
  final Map<NarrativeCommandParameterKind, List<SceneActionPickerOption>>
      actionPickerOptions;
  final String? requestedSceneId;
  final String? requestedNodeId;
  final int? requestedSceneFocusNonce;
  final bool strictRequestedSceneFocus;
  final String? requestedFocusAnchorId;
  final double? requestedViewportX;
  final double? requestedViewportY;
  final double? requestedZoom;
  final NarrativeSceneInspector? requestedInspector;
  final int? requestedRestorationRevision;
  final ValueChanged<int>? onRestorationApplied;
  final SceneDraftCreator onCreateSceneDraft;
  final SceneNodeDraftCreator onAddNodeDraft;
  final SceneLinkedAssetNodeDraftCreator onAddLinkedAssetNodeDraft;
  final SceneConsequenceActionNodeDraftCreator onAddConsequenceActionNodeDraft;
  final SceneEdgeDraftCreator onAddEdgeDraft;
  final SceneEdgeDraftRemover onRemoveEdgeDraft;
  final SceneNodeDraftRemover onRemoveNodeDraft;
  final SceneNodeDraftDuplicator? onDuplicateNodeDraft;
  final SceneNodeLayoutUpdater onUpdateNodeLayout;
  final SceneConditionSourceUpdater onUpdateConditionSource;
  final SceneEndPayloadUpdater? onUpdateEndPayload;
  final SceneYarnDialoguePayloadUpdater onUpdateYarnDialoguePayload;
  final SceneBattlePayloadUpdater onUpdateBattlePayload;
  final SceneCinematicPayloadUpdater onUpdateCinematicPayload;
  final SceneActionConsequenceUpdater onUpdateActionConsequence;
  final SceneLinkedAssetOpener? onOpenDialogue;
  final SceneLinkedAssetOpener? onOpenCinematic;
  final ScenePresentationCreateAndLinkCreator? onCreateAndLinkPresentation;
  final ScenePresentationCreateAndLinkOpener? onOpenCreatedPresentation;
  final Map<String, List<String>> sceneConsumerPaths;
  final SceneLibraryEditor? onEditScene;
  final SceneLibraryDuplicator? onDuplicateScene;
  final SceneLibraryArchiveToggler? onToggleArchiveScene;
  final SceneLibraryDeleter? onDeleteScene;

  @override
  State<ScenesWorkspace> createState() => _ScenesWorkspaceState();
}

class _ScenesWorkspaceState extends State<ScenesWorkspace> {
  final FocusNode _inspectorLauncherFocusNode = FocusNode(
    debugLabel: 'Scenes inspector launcher',
  );
  final ValueNotifier<int> _inspectorRevision = ValueNotifier<int>(0);
  final Map<String, FocusNode> _graphNodeFocusNodes = <String, FocusNode>{};
  bool _inspectorSheetOpen = false;
  bool _inspectorRefreshScheduled = false;
  String? _selectedSceneId;
  String? _selectedNodeId;
  String? _selectedEdgeId;
  _PendingSceneConnection? _pendingConnection;
  String? _requestedRouteFailure;
  int? _restorationRevisionInFlight;
  SceneGraphViewport _graphViewport = const SceneGraphViewport();
  NarrativeSceneInspector _sceneInspector = NarrativeSceneInspector.node;

  @override
  void initState() {
    super.initState();
    _syncSelection();
    _applyRequestedSceneFocus();
    _applyRequestedViewport();
  }

  @override
  void didUpdateWidget(covariant ScenesWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelection();
    if (_requestedSceneFocusChanged(oldWidget)) {
      _applyRequestedSceneFocus();
    } else {
      _revalidateRequestedSceneFocus();
    }
    if (_requestedViewportChanged(oldWidget)) {
      _applyRequestedViewport();
    }
  }

  @override
  void dispose() {
    _inspectorLauncherFocusNode.dispose();
    _inspectorRevision.dispose();
    for (final focusNode in _graphNodeFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String? get requestedSceneId => widget.requestedSceneId;

  int? get requestedSceneFocusNonce => widget.requestedSceneFocusNonce;

  bool _requestedSceneFocusChanged(ScenesWorkspace oldWidget) =>
      oldWidget.requestedSceneId != widget.requestedSceneId ||
      oldWidget.requestedNodeId != widget.requestedNodeId ||
      oldWidget.requestedSceneFocusNonce != widget.requestedSceneFocusNonce ||
      oldWidget.strictRequestedSceneFocus != widget.strictRequestedSceneFocus;

  bool _requestedViewportChanged(ScenesWorkspace oldWidget) =>
      oldWidget.requestedViewportX != widget.requestedViewportX ||
      oldWidget.requestedViewportY != widget.requestedViewportY ||
      oldWidget.requestedZoom != widget.requestedZoom ||
      oldWidget.requestedInspector != widget.requestedInspector ||
      oldWidget.requestedRestorationRevision !=
          widget.requestedRestorationRevision;

  void _applyRequestedViewport() {
    final x = widget.requestedViewportX;
    final y = widget.requestedViewportY;
    final zoom = widget.requestedZoom;
    if (x != null && y != null && zoom != null) {
      _graphViewport = SceneGraphViewport(
        pan: Offset(x, y),
        zoom: zoom,
      );
    }
    _sceneInspector = widget.requestedInspector ?? NarrativeSceneInspector.node;
  }

  void _revalidateRequestedSceneFocus() {
    final requested = requestedSceneId;
    if (requested == null) {
      _requestedRouteFailure = null;
      return;
    }
    final scene = _sceneById(requested);
    if (scene == null) {
      if (!widget.strictRequestedSceneFocus) {
        _requestedRouteFailure = null;
        return;
      }
      _selectedSceneId = null;
      _selectedNodeId = null;
      _selectedEdgeId = null;
      _pendingConnection = null;
      _requestedRouteFailure =
          'La scène demandée « $requested » n’existe plus dans le projet.';
      return;
    }
    final requestedNodeId = widget.requestedNodeId;
    if (requestedNodeId != null &&
        !scene.graph.nodes.any((node) => node.id == requestedNodeId)) {
      if (!widget.strictRequestedSceneFocus) {
        _requestedRouteFailure = null;
        return;
      }
      _selectedSceneId = null;
      _selectedNodeId = null;
      _selectedEdgeId = null;
      _pendingConnection = null;
      _requestedRouteFailure = 'Le nœud demandé « $requestedNodeId » '
          'n’existe plus dans la scène « $requested ».';
      return;
    }
    if (_requestedRouteFailure != null) {
      _applyRequestedSceneFocus();
    }
  }

  void _applyRequestedSceneFocus() {
    final requested = requestedSceneId;
    if (requested == null) {
      _requestedRouteFailure = null;
      return;
    }
    final scene = _sceneById(requested);
    if (scene == null) {
      if (!widget.strictRequestedSceneFocus) {
        _requestedRouteFailure = null;
        return;
      }
      _selectedSceneId = null;
      _selectedNodeId = null;
      _selectedEdgeId = null;
      _pendingConnection = null;
      _requestedRouteFailure =
          'La scène demandée « $requested » n’existe plus dans le projet.';
      return;
    }
    _selectedSceneId = requested;
    final requestedNodeId = widget.requestedNodeId;
    if (requestedNodeId != null &&
        !scene.graph.nodes.any((node) => node.id == requestedNodeId)) {
      if (!widget.strictRequestedSceneFocus) {
        _requestedRouteFailure = null;
        return;
      }
      _selectedNodeId = null;
      _selectedEdgeId = null;
      _pendingConnection = null;
      _requestedRouteFailure = 'Le nœud demandé « $requestedNodeId » '
          'n’existe plus dans la scène « $requested ».';
      return;
    }
    _selectedNodeId = requestedNodeId ?? _preferredNodeId(scene);
    _selectedEdgeId = null;
    _pendingConnection = null;
    _requestedRouteFailure = null;
  }

  String _graphNodeFocusKey(String sceneId, String nodeId) =>
      '$sceneId\u001f$nodeId';

  FocusNode _graphNodeFocusNodeFor(String sceneId, String nodeId) {
    final key = _graphNodeFocusKey(sceneId, nodeId);
    return _graphNodeFocusNodes.putIfAbsent(
      key,
      () => FocusNode(debugLabel: 'Scene graph node $sceneId / $nodeId'),
    );
  }

  void _scheduleRequestedRestoration() {
    final revision = widget.requestedRestorationRevision;
    final onApplied = widget.onRestorationApplied;
    if (revision == null ||
        onApplied == null ||
        _requestedRouteFailure != null ||
        _selectedSceneId != widget.requestedSceneId ||
        _selectedNodeId != widget.requestedNodeId ||
        _restorationRevisionInFlight == revision) {
      return;
    }
    _restorationRevisionInFlight = revision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreRequestedScene(revision, attempt: 0);
    });
  }

  void _restoreRequestedScene(int revision, {required int attempt}) {
    if (!mounted || widget.requestedRestorationRevision != revision) {
      if (_restorationRevisionInFlight == revision) {
        _restorationRevisionInFlight = null;
      }
      return;
    }
    final sceneId = widget.requestedSceneId;
    final nodeId = widget.requestedNodeId;
    if (_requestedRouteFailure != null ||
        sceneId == null ||
        nodeId == null ||
        _selectedSceneId != sceneId ||
        _selectedNodeId != nodeId) {
      _failRequestedRestoration(
        revision,
        'La scène et le nœud exacts ne peuvent pas être restaurés.',
      );
      return;
    }

    final focusAnchor = widget.requestedFocusAnchorId;
    if (focusAnchor != null) {
      if (focusAnchor != nodeId) {
        _failRequestedRestoration(
          revision,
          'Le point de focus « $focusAnchor » ne correspond pas au nœud '
          'demandé « $nodeId ».',
        );
        return;
      }
      final focusNode =
          _graphNodeFocusNodes[_graphNodeFocusKey(sceneId, nodeId)];
      if (focusNode?.context == null) {
        _retryRequestedRestoration(revision, attempt: attempt);
        return;
      }
      if (!focusNode!.hasFocus) {
        focusNode.requestFocus();
        _retryRequestedRestoration(revision, attempt: attempt);
        return;
      }
    }

    _restorationRevisionInFlight = null;
    widget.onRestorationApplied!(revision);
  }

  void _retryRequestedRestoration(int revision, {required int attempt}) {
    if (attempt >= 12) {
      _failRequestedRestoration(
        revision,
        'Le nœud demandé n’a pas pu être rematérialisé pour restaurer le '
        'focus.',
      );
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreRequestedScene(revision, attempt: attempt + 1);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void _failRequestedRestoration(int revision, String message) {
    if (_restorationRevisionInFlight == revision) {
      _restorationRevisionInFlight = null;
    }
    if (!mounted || _requestedRouteFailure == message) return;
    setState(() => _requestedRouteFailure = message);
  }

  void _syncSelection() {
    if (widget.scenes.isEmpty) {
      _selectedSceneId = null;
      _selectedNodeId = null;
      _selectedEdgeId = null;
      _pendingConnection = null;
      return;
    }
    final selectedStillExists =
        widget.scenes.any((scene) => scene.id == _selectedSceneId);
    if (!selectedStillExists) {
      _selectedSceneId = widget.scenes.first.id;
      _selectedNodeId = _preferredNodeId(widget.scenes.first);
      _selectedEdgeId = null;
      _pendingConnection = null;
      return;
    }
    final selected = _selectedScene;
    if (selected == null || selected.graph.nodes.isEmpty) {
      _selectedNodeId = null;
      _selectedEdgeId = null;
      _pendingConnection = null;
      return;
    }
    final nodeStillExists =
        selected.graph.nodes.any((node) => node.id == _selectedNodeId);
    if (!nodeStillExists) {
      _selectedNodeId = _preferredNodeId(selected);
    }
    final edgeStillExists =
        selected.graph.edges.any((edge) => edge.id == _selectedEdgeId);
    if (!edgeStillExists) {
      _selectedEdgeId = null;
    }
    final pending = _pendingConnection;
    if (pending != null &&
        !selected.graph.nodes.any((node) => node.id == pending.fromNodeId)) {
      _pendingConnection = null;
    }
  }

  Future<void> _editSelectedScene() async {
    final scene = _selectedScene;
    final callback = widget.onEditScene;
    if (scene == null || callback == null) return;
    final request = await showPokeMapDesktopSideSheet<_SceneLibraryEditRequest>(
      context: context,
      title: 'Renommer et classer la scène',
      semanticLabel: 'Édition de la bibliothèque de scènes',
      builder: (sheetContext) => _SceneLibraryEditSheet(
        scene: scene,
        scenes: widget.scenes,
        onSubmit: (request) => Navigator.of(sheetContext).pop(request),
      ),
    );
    if (request == null || !mounted) return;
    final result = await callback(
      sceneId: scene.id,
      name: request.name,
      location: SceneLibraryLocation(
        folder: request.folder,
        storylineId: request.storylineId,
        chapterId: request.chapterId,
      ),
      tags: request.tags,
      declaredOutcomes: request.declaredOutcomes,
    );
    if (mounted) await _showSceneLibraryFailure(result);
  }

  Future<void> _duplicateSelectedScene() async {
    final scene = _selectedScene;
    final callback = widget.onDuplicateScene;
    if (scene == null || callback == null) return;
    final result = await callback(sceneId: scene.id);
    if (!mounted) return;
    if (result?.isApplied == true && result?.scene != null) {
      setState(() {
        _selectedSceneId = result!.scene!.id;
        _selectedNodeId = result.scene!.graph.startNodeId;
        _selectedEdgeId = null;
      });
    }
    await _showSceneLibraryFailure(result);
  }

  Future<void> _toggleSelectedSceneArchive() async {
    final scene = _selectedScene;
    final callback = widget.onToggleArchiveScene;
    if (scene == null || callback == null) return;
    final result = await callback(
      sceneId: scene.id,
      archived: !scene.isArchived,
    );
    if (mounted) await _showSceneLibraryFailure(result);
  }

  Future<void> _deleteSelectedScene() async {
    final scene = _selectedScene;
    final callback = widget.onDeleteScene;
    if (scene == null || callback == null) return;
    final consumerPaths = widget.sceneConsumerPaths[scene.id] ?? const [];
    final request =
        await showPokeMapDesktopSideSheet<_SceneLibraryDeleteRequest>(
      context: context,
      title: consumerPaths.isEmpty
          ? 'Supprimer la scène'
          : 'Remplacer puis supprimer la scène',
      semanticLabel: 'Suppression protégée de la scène',
      builder: (sheetContext) => _SceneLibraryDeleteSheet(
        scene: scene,
        consumerPaths: consumerPaths,
        replacementScenes: [
          for (final candidate in widget.scenes)
            if (candidate.id != scene.id) candidate,
        ],
        onSubmit: (request) => Navigator.of(sheetContext).pop(request),
      ),
    );
    if (request == null || !mounted) return;
    final result = await callback(
      sceneId: scene.id,
      replacementSceneId: request.replacementSceneId,
    );
    if (!mounted) return;
    if (result?.isApplied == true) {
      setState(() {
        _selectedSceneId = widget.scenes
            .where((candidate) => candidate.id != scene.id)
            .firstOrNull
            ?.id;
        _selectedNodeId = null;
        _selectedEdgeId = null;
      });
    }
    await _showSceneLibraryFailure(result);
  }

  Future<void> _showSceneLibraryFailure(
    SceneLibraryMutationResult? result,
  ) async {
    if (result == null ||
        result.disposition != SceneLibraryMutationDisposition.rejected) {
      return;
    }
    await showPokeMapConfirmationDialog<void>(
      context: context,
      title: 'Modification impossible',
      message: result.message ??
          'La bibliothèque de scènes a refusé cette opération.',
      actions: const [
        PokeMapDialogAction(label: 'Compris', value: null),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedScene = _selectedScene;
    _scheduleInspectorSheetRefresh();
    _scheduleRequestedRestoration();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < _scenesInlineInspectorMinWidth;
        final treeWidth = compact ? 220.0 : 244.0;
        return NarrativeStudioWorkspacePage(
          presentation: narrativeStudioRoutePresentationFor(
            EditorWorkspaceMode.scenes,
          )!,
          actions: [
            if (compact)
              PokeMapButton(
                key: const ValueKey('scenes-open-inspector-action'),
                focusNode: _inspectorLauncherFocusNode,
                onPressed: _openInspectorSheet,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.compact,
                leading: const Icon(CupertinoIcons.slider_horizontal_3),
                child: const Text('Inspecteur'),
              ),
            PokeMapButton(
              key: const ValueKey('scenes-create-scene-action'),
              onPressed: _createSceneDraft,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.compact,
              leading: const Icon(CupertinoIcons.plus),
              child: const Text('Nouvelle scène'),
            ),
          ],
          body: PokeMapPageSurface(
            key: const ValueKey('scenes-workspace-shell'),
            padding: const EdgeInsets.all(8),
            child: _requestedRouteFailure == null
                ? _buildWorkspaceRow(
                    compact: compact,
                    treeWidth: treeWidth,
                    selectedScene: selectedScene,
                  )
                : Column(
                    children: [
                      PokeMapDiagnosticCallout(
                        key: const ValueKey('scenes-route-restoration-failure'),
                        severity: PokeMapDiagnosticSeverity.error,
                        title: 'Retour vers la Scene impossible',
                        message: _requestedRouteFailure!,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildWorkspaceRow(
                          compact: compact,
                          treeWidth: treeWidth,
                          selectedScene: selectedScene,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildWorkspaceRow({
    required bool compact,
    required double treeWidth,
    required NarrativeSceneSummary? selectedScene,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: const ValueKey('scenes-tree-column'),
          width: treeWidth,
          child: SceneLibraryPanel(
            scenes: widget.scenes,
            selectedSceneId: selectedScene?.id,
            consumerCountBySceneId: {
              for (final entry in widget.sceneConsumerPaths.entries)
                entry.key: entry.value.length,
            },
            onEditScene: widget.onEditScene == null ? null : _editSelectedScene,
            onDuplicateScene: widget.onDuplicateScene == null
                ? null
                : _duplicateSelectedScene,
            onToggleArchiveScene: widget.onToggleArchiveScene == null
                ? null
                : _toggleSelectedSceneArchive,
            onDeleteScene:
                widget.onDeleteScene == null ? null : _deleteSelectedScene,
            onSelectScene: (sceneId) {
              setState(() {
                _selectedSceneId = sceneId;
                _selectedNodeId = _preferredNodeId(_sceneById(sceneId));
                _selectedEdgeId = null;
                _pendingConnection = null;
                _requestedRouteFailure = null;
                _graphViewport = const SceneGraphViewport();
                _sceneInspector = NarrativeSceneInspector.node;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox.expand(
            key: const ValueKey('scenes-graph-column'),
            child: _SceneReadOnlySummary(
              scene: selectedScene,
              selectedNodeId: _selectedNodeId,
              selectedEdgeId: _selectedEdgeId,
              pendingConnection: _pendingConnection,
              focusNodeForNodeId: selectedScene == null
                  ? null
                  : (nodeId) => _graphNodeFocusNodeFor(
                        selectedScene.id,
                        nodeId,
                      ),
              onSelectNode: _handleGraphNodeTap,
              onSelectEdge: _handleGraphEdgeTap,
              onAddNodeDraft: _addNodeDraft,
              onAddLinkedAssetNodeDraft: _addLinkedAssetNodeDraft,
              onAddConsequenceActionNodeDraft: _addConsequenceActionNodeDraft,
              linkedAssetContracts: widget.linkedAssetContracts,
              cinematicsLibrary: widget.cinematicsLibrary,
              presentationCinematics: widget.presentationCinematics,
              presentationFolders: widget.presentationFolders,
              viewport: _graphViewport,
              inspector: _sceneInspector,
              onViewportChanged: (viewport) {
                if (_graphViewport == viewport) return;
                setState(() => _graphViewport = viewport);
              },
              onCreateAndLinkPresentation: widget.onCreateAndLinkPresentation,
              onOpenCreatedPresentation: widget.onOpenCreatedPresentation,
              consequenceFactOptions: widget.consequenceFactOptions,
              consequenceEventOptions: widget.consequenceEventOptions,
              consequenceCatalogs: widget.consequenceCatalogs,
              actionPickerOptions: widget.actionPickerOptions,
              onAddEdgeDraft: _addEdgeDraft,
              onStartConnection: _startConnection,
              onCancelConnection: _cancelConnection,
              onUpdateNodeLayout: _updateNodeLayout,
              onDuplicateNode: widget.onDuplicateNodeDraft == null
                  ? null
                  : (nodeId) => _duplicateNodeDraft(nodeId),
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          SizedBox(
            key: const ValueKey('scenes-inspector-column'),
            width: 320,
            child: _buildInspectorPane(selectedScene),
          ),
        ],
      ],
    );
  }

  Widget _buildInspectorPane(NarrativeSceneSummary? selectedScene) {
    return LayoutBuilder(
      builder: (context, inspectorConstraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: inspectorConstraints.maxHeight,
            ),
            child: selectedScene == null
                ? const _SceneInspectorEmptyPanel()
                : SceneNodeReadOnlyInspector(
                    scene: selectedScene,
                    selectedNodeId: _selectedNodeId,
                    selectedEdgeId: _selectedEdgeId,
                    onRemoveEdgeDraft: _removeSelectedEdgeDraft,
                    onRemoveNodeDraft: _removeSelectedNodeDraft,
                    conditionSourceOptions: widget.conditionSourceOptions,
                    onUpdateConditionSource: _updateConditionSource,
                    onUpdateEndPayload: _updateEndPayload,
                    linkedAssetContracts: widget.linkedAssetContracts,
                    cinematicsLibrary: widget.cinematicsLibrary,
                    onUpdateYarnDialoguePayload: _updateYarnDialoguePayload,
                    onOpenDialogue: (dialogueId) {
                      final sceneId = selectedScene.id;
                      final nodeId = _selectedNodeId;
                      if (nodeId == null) return;
                      widget.onOpenDialogue?.call(
                        sceneId: sceneId,
                        nodeId: nodeId,
                        assetId: dialogueId,
                      );
                    },
                    onUpdateBattlePayload: _updateBattlePayload,
                    onUpdateCinematicPayload: _updateCinematicPayload,
                    onOpenCinematic: (cinematicId) {
                      final sceneId = selectedScene.id;
                      final nodeId = _selectedNodeId;
                      if (nodeId == null) return;
                      widget.onOpenCinematic?.call(
                        sceneId: sceneId,
                        nodeId: nodeId,
                        assetId: cinematicId,
                      );
                    },
                    consequenceFactOptions: widget.consequenceFactOptions,
                    consequenceEventOptions: widget.consequenceEventOptions,
                    consequenceCatalogs: widget.consequenceCatalogs,
                    onUpdateActionConsequence: _updateActionConsequence,
                  ),
          ),
        );
      },
    );
  }

  void _scheduleInspectorSheetRefresh() {
    if (!_inspectorSheetOpen || _inspectorRefreshScheduled) {
      return;
    }
    _inspectorRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inspectorRefreshScheduled = false;
      if (mounted && _inspectorSheetOpen) {
        _inspectorRevision.value += 1;
      }
    });
  }

  Future<void> _openInspectorSheet() async {
    _inspectorSheetOpen = true;
    try {
      await showPokeMapDesktopSideSheet<void>(
        context: context,
        title: 'Inspecteur de scène',
        semanticLabel: 'Inspecteur de la scène sélectionnée',
        barrierLabel: 'Fermer l’inspecteur de scène',
        width: 380,
        builder: (context) => ValueListenableBuilder<int>(
          valueListenable: _inspectorRevision,
          builder: (context, revision, child) => SizedBox.expand(
            key: const ValueKey('scenes-inspector-sheet-content'),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _buildInspectorPane(_selectedScene),
            ),
          ),
        ),
      );
    } finally {
      _inspectorSheetOpen = false;
    }
  }

  Future<void> _createSceneDraft() async {
    final draft = await showCupertinoDialog<_SceneDraftDialogResult>(
      context: context,
      builder: (context) => const _CreateSceneDraftDialog(),
    );
    if (draft == null) {
      return;
    }

    final createdSceneId = await widget.onCreateSceneDraft(
      name: draft.name,
      description: draft.description,
    );
    if (!mounted || createdSceneId == null) {
      return;
    }
    setState(() {
      _selectedSceneId = createdSceneId;
      _selectedNodeId = 'node_start';
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
  }

  Future<void> _addNodeDraft(SceneNodeKind kind) async {
    final selected = _selectedScene;
    if (selected == null) {
      return;
    }
    final createdNodeId = await widget.onAddNodeDraft(
      sceneId: selected.id,
      kind: kind,
    );
    if (!mounted || createdNodeId == null) {
      return;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = createdNodeId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
  }

  Future<void> _addLinkedAssetNodeDraft({
    required SceneNodePayload payload,
    String? title,
  }) async {
    final selected = _selectedScene;
    if (selected == null) {
      return;
    }
    final createdNodeId = await widget.onAddLinkedAssetNodeDraft(
      sceneId: selected.id,
      payload: payload,
      title: title,
    );
    if (!mounted || createdNodeId == null) {
      return;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = createdNodeId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
  }

  Future<void> _addConsequenceActionNodeDraft({
    required SceneConsequence consequence,
    String? title,
  }) async {
    final selected = _selectedScene;
    if (selected == null) {
      return;
    }
    final createdNodeId = await widget.onAddConsequenceActionNodeDraft(
      sceneId: selected.id,
      consequence: consequence,
      title: title,
    );
    if (!mounted || createdNodeId == null) {
      return;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = createdNodeId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
  }

  void _startConnection(SceneAuthorableOutputPort port) {
    final nodeId = _selectedNodeId;
    if (nodeId == null) {
      return;
    }
    setState(() {
      _pendingConnection = _PendingSceneConnection(
        fromNodeId: nodeId,
        fromPortId: port.id,
      );
      _selectedEdgeId = null;
    });
  }

  void _cancelConnection() {
    setState(() => _pendingConnection = null);
  }

  Future<void> _handleGraphNodeTap(String nodeId) async {
    final pending = _pendingConnection;
    if (pending == null) {
      setState(() {
        _selectedNodeId = nodeId;
        _selectedEdgeId = null;
      });
      return;
    }
    if (nodeId == pending.fromNodeId) {
      return;
    }
    await _addEdgeDraft(
      fromNodeId: pending.fromNodeId,
      fromPortId: pending.fromPortId,
      toNodeId: nodeId,
    );
  }

  Future<void> _addEdgeDraft({
    required String fromNodeId,
    required String fromPortId,
    required String toNodeId,
  }) async {
    final selected = _selectedScene;
    if (selected == null) {
      return;
    }
    final createdEdgeId = await widget.onAddEdgeDraft(
      sceneId: selected.id,
      fromNodeId: fromNodeId,
      fromPortId: fromPortId,
      toNodeId: toNodeId,
    );
    if (!mounted || createdEdgeId == null) {
      return;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = fromNodeId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
  }

  void _handleGraphEdgeTap(String edgeId) {
    setState(() {
      _selectedEdgeId = edgeId;
      _selectedNodeId = null;
      _pendingConnection = null;
    });
  }

  Future<void> _removeSelectedEdgeDraft(String edgeId) async {
    final selected = _selectedScene;
    if (selected == null) {
      return;
    }
    final removed = await widget.onRemoveEdgeDraft(
      sceneId: selected.id,
      edgeId: edgeId,
    );
    if (!mounted || !removed) {
      return;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedEdgeId = null;
      _selectedNodeId = _preferredNodeId(selected);
      _pendingConnection = null;
    });
  }

  Future<void> _removeSelectedNodeDraft(String nodeId) async {
    final selected = _selectedScene;
    if (selected == null) {
      return;
    }
    final removed = await widget.onRemoveNodeDraft(
      sceneId: selected.id,
      nodeId: nodeId,
    );
    if (!mounted || !removed) {
      return;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedEdgeId = null;
      _selectedNodeId = _preferredNodeIdAfterRemoving(selected, nodeId);
      _pendingConnection = null;
    });
  }

  Future<String?> _duplicateNodeDraft(String nodeId) async {
    final selected = _selectedScene;
    final duplicate = widget.onDuplicateNodeDraft;
    if (selected == null || duplicate == null) return null;
    final createdId = await duplicate(sceneId: selected.id, nodeId: nodeId);
    if (!mounted || createdId == null) return createdId;
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = createdId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
    return createdId;
  }

  Future<void> _updateNodeLayout({
    required String sceneId,
    required String nodeId,
    required double x,
    required double y,
  }) async {
    final scene = _sceneById(sceneId);
    if (scene == null) {
      return;
    }
    await widget.onUpdateNodeLayout(
      sceneId: scene.id,
      nodeId: nodeId,
      x: x,
      y: y,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedSceneId = scene.id;
      _selectedNodeId = nodeId;
      _selectedEdgeId = null;
    });
  }

  Future<bool> _updateConditionSource({
    required String nodeId,
    required SceneConditionSource source,
  }) async {
    final selected = _selectedScene;
    if (selected == null) {
      return false;
    }
    final updated = await widget.onUpdateConditionSource(
      sceneId: selected.id,
      nodeId: nodeId,
      source: source,
    );
    if (!mounted || !updated) {
      return false;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = nodeId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
    return true;
  }

  Future<bool> _updateYarnDialoguePayload({
    required String nodeId,
    required String dialogueId,
    String? yarnNodeName,
    required List<String> expectedOutcomes,
  }) async {
    final selected = _selectedScene;
    if (selected == null) {
      return false;
    }
    final updated = await widget.onUpdateYarnDialoguePayload(
      sceneId: selected.id,
      nodeId: nodeId,
      dialogueId: dialogueId,
      yarnNodeName: yarnNodeName,
      expectedOutcomes: expectedOutcomes,
    );
    if (!mounted || !updated) {
      return false;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = nodeId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
    return true;
  }

  Future<bool> _updateEndPayload({
    required String nodeId,
    String? sceneOutcomeId,
    required SceneOutcomePolicy? outcomePolicy,
  }) async {
    final selected = _selectedScene;
    final updater = widget.onUpdateEndPayload;
    if (selected == null || updater == null) return false;
    final updated = await updater(
      sceneId: selected.id,
      nodeId: nodeId,
      sceneOutcomeId: sceneOutcomeId,
      outcomePolicy: outcomePolicy,
    );
    if (!mounted || !updated) return false;
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = nodeId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
    return true;
  }

  Future<bool> _updateBattlePayload({
    required String nodeId,
    required String trainerId,
    required String battleKind,
    String? battleTemplateId,
  }) async {
    final selected = _selectedScene;
    if (selected == null) {
      return false;
    }
    final updated = await widget.onUpdateBattlePayload(
      sceneId: selected.id,
      nodeId: nodeId,
      trainerId: trainerId,
      battleKind: battleKind,
      battleTemplateId: battleTemplateId,
    );
    if (!mounted || !updated) {
      return false;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = nodeId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
    return true;
  }

  Future<bool> _updateCinematicPayload({
    required String nodeId,
    required String cinematicId,
  }) async {
    final selected = _selectedScene;
    if (selected == null) {
      return false;
    }
    final updated = await widget.onUpdateCinematicPayload(
      sceneId: selected.id,
      nodeId: nodeId,
      cinematicId: cinematicId,
    );
    if (!mounted || !updated) {
      return false;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = nodeId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
    return true;
  }

  Future<bool> _updateActionConsequence({
    required String nodeId,
    required SceneConsequence consequence,
  }) async {
    final selected = _selectedScene;
    if (selected == null) {
      return false;
    }
    final updated = await widget.onUpdateActionConsequence(
      sceneId: selected.id,
      nodeId: nodeId,
      consequence: consequence,
    );
    if (!mounted || !updated) {
      return false;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = nodeId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
    return true;
  }

  NarrativeSceneSummary? get _selectedScene {
    for (final scene in widget.scenes) {
      if (scene.id == _selectedSceneId) {
        return scene;
      }
    }
    return widget.scenes.isEmpty ? null : widget.scenes.first;
  }

  NarrativeSceneSummary? _sceneById(String sceneId) {
    for (final scene in widget.scenes) {
      if (scene.id == sceneId) {
        return scene;
      }
    }
    return null;
  }

  String? _preferredNodeId(NarrativeSceneSummary? scene) {
    if (scene == null || scene.graph.nodes.isEmpty) {
      return null;
    }
    final startNodeExists =
        scene.graph.nodes.any((node) => node.id == scene.graph.startNodeId);
    return startNodeExists
        ? scene.graph.startNodeId
        : scene.graph.nodes.first.id;
  }

  String? _preferredNodeIdAfterRemoving(
    NarrativeSceneSummary scene,
    String removedNodeId,
  ) {
    if (scene.graph.startNodeId != removedNodeId &&
        scene.graph.nodes.any((node) => node.id == scene.graph.startNodeId)) {
      return scene.graph.startNodeId;
    }
    for (final node in scene.graph.nodes) {
      if (node.id != removedNodeId) {
        return node.id;
      }
    }
    return null;
  }
}

class _PendingSceneConnection {
  const _PendingSceneConnection({
    required this.fromNodeId,
    required this.fromPortId,
  });

  final String fromNodeId;
  final String fromPortId;
}

class _SceneDraftDialogResult {
  const _SceneDraftDialogResult({
    required this.name,
    this.description,
  });

  final String name;
  final String? description;
}

class _CreateSceneDraftDialog extends StatefulWidget {
  const _CreateSceneDraftDialog();

  @override
  State<_CreateSceneDraftDialog> createState() =>
      _CreateSceneDraftDialogState();
}

class _CreateSceneDraftDialogState extends State<_CreateSceneDraftDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _showNameError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return CupertinoAlertDialog(
      key: const ValueKey('scenes-create-scene-dialog'),
      title: const Text('Créer une scène'),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            CupertinoTextField(
              key: const ValueKey('scenes-create-scene-name-field'),
              controller: _nameController,
              placeholder: 'Nom de la scène',
              onChanged: (_) {
                if (_showNameError) {
                  setState(() => _showNameError = false);
                }
              },
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              key: const ValueKey('scenes-create-scene-description-field'),
              controller: _descriptionController,
              placeholder: 'Description optionnelle',
              minLines: 2,
              maxLines: 3,
            ),
            if (_showNameError) ...[
              const SizedBox(height: 8),
              Text(
                'Nom requis.',
                key: const ValueKey('scenes-create-scene-name-error'),
                style: TextStyle(
                  color: colors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          key: const ValueKey('scenes-create-scene-cancel'),
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        CupertinoDialogAction(
          key: const ValueKey('scenes-create-scene-submit'),
          isDefaultAction: true,
          child: const Text('Créer la scène'),
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              setState(() => _showNameError = true);
              return;
            }
            Navigator.of(context).pop(
              _SceneDraftDialogResult(
                name: name,
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
              ),
            );
          },
        ),
      ],
    );
  }
}

final class _SceneLibraryEditRequest {
  const _SceneLibraryEditRequest({
    required this.name,
    required this.folder,
    required this.storylineId,
    required this.chapterId,
    required this.tags,
    required this.declaredOutcomes,
  });

  final String name;
  final String? folder;
  final String? storylineId;
  final String? chapterId;
  final List<String> tags;
  final List<SceneOutcome> declaredOutcomes;
}

final class _SceneLibraryEditSheet extends StatefulWidget {
  const _SceneLibraryEditSheet({
    required this.scene,
    required this.scenes,
    required this.onSubmit,
  });

  final NarrativeSceneSummary scene;
  final List<NarrativeSceneSummary> scenes;
  final ValueChanged<_SceneLibraryEditRequest> onSubmit;

  @override
  State<_SceneLibraryEditSheet> createState() => _SceneLibraryEditSheetState();
}

final class _SceneLibraryEditSheetState extends State<_SceneLibraryEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _folderController;
  late final TextEditingController _tagsController;
  late final TextEditingController _outcomesController;
  late String _storylineId;
  late String _chapterId;
  bool _showNameError = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.scene.name);
    _folderController = TextEditingController(text: widget.scene.libraryFolder);
    _tagsController = TextEditingController(text: widget.scene.tags.join(', '));
    _outcomesController = TextEditingController(
      text: widget.scene.outcomeDefinitions
          .map((outcome) => outcome.id)
          .join(', '),
    );
    _storylineId = widget.scene.storylineId ?? '';
    _chapterId = widget.scene.chapterId ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _folderController.dispose();
    _tagsController.dispose();
    _outcomesController.dispose();
    super.dispose();
  }

  List<String> get _storylineIds => {
        '',
        for (final scene in widget.scenes)
          if (scene.storylineId != null) scene.storylineId!,
      }.toList(growable: false);

  List<String> get _chapterIds => {
        '',
        for (final scene in widget.scenes)
          if (scene.storylineId == _storylineId && scene.chapterId != null)
            scene.chapterId!,
      }.toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('scenes-library-edit-sheet'),
      padding: const EdgeInsets.all(16),
      children: [
        PokeMapTextField(
          key: const ValueKey('scenes-library-edit-name'),
          label: 'Nom lisible',
          controller: _nameController,
          autofocus: true,
          errorText: _showNameError ? 'Le nom est obligatoire.' : null,
          onChanged: (_) {
            if (_showNameError) setState(() => _showNameError = false);
          },
        ),
        const SizedBox(height: 12),
        PokeMapTextField(
          key: const ValueKey('scenes-library-edit-folder'),
          label: 'Dossier de bibliothèque',
          controller: _folderController,
          hintText: 'Ex. Quête principale',
        ),
        const SizedBox(height: 12),
        PokeMapDropdownField<String>(
          key: const ValueKey('scenes-library-edit-storyline'),
          label: 'Storyline',
          value: _storylineId,
          items: [
            for (final id in _storylineIds)
              PokeMapDropdownItem(
                value: id,
                label: id.isEmpty ? 'Sans storyline' : id,
              ),
          ],
          onChanged: (value) => setState(() {
            _storylineId = value;
            if (!_chapterIds.contains(_chapterId)) _chapterId = '';
          }),
        ),
        const SizedBox(height: 12),
        PokeMapDropdownField<String>(
          key: const ValueKey('scenes-library-edit-chapter'),
          label: 'Chapitre',
          value: _chapterId,
          enabled: _storylineId.isNotEmpty,
          items: [
            for (final id in _chapterIds)
              PokeMapDropdownItem(
                value: id,
                label: id.isEmpty ? 'Sans chapitre' : id,
              ),
          ],
          onChanged: (value) => setState(() => _chapterId = value),
        ),
        const SizedBox(height: 12),
        PokeMapTextField(
          key: const ValueKey('scenes-library-edit-tags'),
          label: 'Tags séparés par des virgules',
          controller: _tagsController,
          hintText: 'port, rival, acte-1',
        ),
        const SizedBox(height: 12),
        PokeMapTextField(
          key: const ValueKey('scenes-library-edit-outcomes'),
          label: 'Résultats déclarés séparés par des virgules',
          controller: _outcomesController,
          hintText: 'victory, defeat',
        ),
        const SizedBox(height: 18),
        PokeMapButton(
          key: const ValueKey('scenes-library-edit-submit'),
          onPressed: _submit,
          leading: const Icon(CupertinoIcons.check_mark),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    final tags = _commaSeparatedValues(_tagsController.text);
    final outcomeIds = _commaSeparatedValues(_outcomesController.text);
    final existingById = {
      for (final outcome in widget.scene.outcomeDefinitions)
        outcome.id: outcome,
    };
    widget.onSubmit(
      _SceneLibraryEditRequest(
        name: name,
        folder: _emptyToNull(_folderController.text),
        storylineId: _emptyToNull(_storylineId),
        chapterId: _emptyToNull(_chapterId),
        tags: tags,
        declaredOutcomes: [
          for (final id in outcomeIds)
            existingById[id] ?? SceneOutcome(id: id, label: id),
        ],
      ),
    );
  }
}

final class _SceneLibraryDeleteRequest {
  const _SceneLibraryDeleteRequest({this.replacementSceneId});

  final String? replacementSceneId;
}

final class _SceneLibraryDeleteSheet extends StatefulWidget {
  const _SceneLibraryDeleteSheet({
    required this.scene,
    required this.consumerPaths,
    required this.replacementScenes,
    required this.onSubmit,
  });

  final NarrativeSceneSummary scene;
  final List<String> consumerPaths;
  final List<NarrativeSceneSummary> replacementScenes;
  final ValueChanged<_SceneLibraryDeleteRequest> onSubmit;

  @override
  State<_SceneLibraryDeleteSheet> createState() =>
      _SceneLibraryDeleteSheetState();
}

final class _SceneLibraryDeleteSheetState
    extends State<_SceneLibraryDeleteSheet> {
  String _replacementSceneId = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final requiresReplacement = widget.consumerPaths.isNotEmpty;
    return ListView(
      key: const ValueKey('scenes-library-delete-sheet'),
      padding: const EdgeInsets.all(16),
      children: [
        PokeMapDiagnosticCallout(
          severity: requiresReplacement
              ? PokeMapDiagnosticSeverity.warning
              : PokeMapDiagnosticSeverity.info,
          title: requiresReplacement
              ? '${widget.consumerPaths.length} dépendances détectées'
              : 'Scène sans dépendance',
          message: requiresReplacement
              ? 'Choisissez une scène de remplacement compatible avant la suppression.'
              : 'La suppression retire définitivement cette scène du projet.',
        ),
        if (requiresReplacement) ...[
          const SizedBox(height: 12),
          PokeMapDropdownField<String>(
            key: const ValueKey('scenes-library-delete-replacement'),
            label: 'Scène de remplacement',
            value: _replacementSceneId,
            items: [
              const PokeMapDropdownItem(value: '', label: 'Choisir…'),
              for (final scene in widget.replacementScenes)
                PokeMapDropdownItem(value: scene.id, label: scene.name),
            ],
            onChanged: (value) => setState(() => _replacementSceneId = value),
          ),
          const SizedBox(height: 12),
          Text(
            'Consommateurs',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          for (final path in widget.consumerPaths)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $path',
                style: TextStyle(color: colors.textSecondary, fontSize: 11),
              ),
            ),
        ],
        const SizedBox(height: 18),
        PokeMapButton(
          key: const ValueKey('scenes-library-delete-submit'),
          onPressed: !requiresReplacement || _replacementSceneId.isNotEmpty
              ? () => widget.onSubmit(
                    _SceneLibraryDeleteRequest(
                      replacementSceneId: _emptyToNull(_replacementSceneId),
                    ),
                  )
              : null,
          variant: PokeMapButtonVariant.danger,
          leading: const Icon(CupertinoIcons.delete),
          child: Text(
              requiresReplacement ? 'Remplacer et supprimer' : 'Supprimer'),
        ),
      ],
    );
  }
}

List<String> _commaSeparatedValues(String raw) {
  final seen = <String>{};
  return [
    for (final value in raw.split(','))
      if (value.trim().isNotEmpty && seen.add(value.trim())) value.trim(),
  ];
}

String? _emptyToNull(String raw) {
  final value = raw.trim();
  return value.isEmpty ? null : value;
}

class _SceneReadOnlySummary extends StatelessWidget {
  const _SceneReadOnlySummary({
    required this.scene,
    required this.selectedNodeId,
    required this.selectedEdgeId,
    required this.pendingConnection,
    required this.focusNodeForNodeId,
    required this.onSelectNode,
    required this.onSelectEdge,
    required this.onAddNodeDraft,
    required this.onAddLinkedAssetNodeDraft,
    required this.onAddConsequenceActionNodeDraft,
    required this.linkedAssetContracts,
    required this.cinematicsLibrary,
    required this.presentationCinematics,
    required this.presentationFolders,
    required this.viewport,
    required this.inspector,
    required this.onViewportChanged,
    required this.onCreateAndLinkPresentation,
    required this.onOpenCreatedPresentation,
    required this.consequenceFactOptions,
    required this.consequenceEventOptions,
    required this.consequenceCatalogs,
    required this.actionPickerOptions,
    required this.onAddEdgeDraft,
    required this.onStartConnection,
    required this.onCancelConnection,
    required this.onUpdateNodeLayout,
    this.onDuplicateNode,
  });

  final NarrativeSceneSummary? scene;
  final String? selectedNodeId;
  final String? selectedEdgeId;
  final _PendingSceneConnection? pendingConnection;
  final FocusNode Function(String nodeId)? focusNodeForNodeId;
  final ValueChanged<String> onSelectNode;
  final ValueChanged<String> onSelectEdge;
  final ValueChanged<SceneNodeKind> onAddNodeDraft;
  final _SelectedLinkedAssetNodeDraftCreator onAddLinkedAssetNodeDraft;
  final _SelectedConsequenceActionNodeDraftCreator
      onAddConsequenceActionNodeDraft;
  final LinkedAssetContractsSnapshot? linkedAssetContracts;
  final CinematicsLibraryReadModel? cinematicsLibrary;
  final List<PresentationCinematicAsset> presentationCinematics;
  final List<CinematicLibraryFolder> presentationFolders;
  final SceneGraphViewport viewport;
  final NarrativeSceneInspector inspector;
  final ValueChanged<SceneGraphViewport> onViewportChanged;
  final ScenePresentationCreateAndLinkCreator? onCreateAndLinkPresentation;
  final ScenePresentationCreateAndLinkOpener? onOpenCreatedPresentation;
  final List<SceneConsequenceFactPickerOption> consequenceFactOptions;
  final List<SceneConsequenceEventPickerOption> consequenceEventOptions;
  final SceneConsequenceCatalogs consequenceCatalogs;
  final Map<NarrativeCommandParameterKind, List<SceneActionPickerOption>>
      actionPickerOptions;
  final SceneVisualEdgeDraftCreator onAddEdgeDraft;
  final ValueChanged<SceneAuthorableOutputPort> onStartConnection;
  final VoidCallback onCancelConnection;
  final SceneNodeLayoutUpdater onUpdateNodeLayout;
  final SceneGraphNodeDuplicator? onDuplicateNode;

  @override
  Widget build(BuildContext context) {
    final current = scene;
    return PokeMapPanel(
      expandChild: true,
      padding: EdgeInsets.zero,
      child: current == null
          ? const _SceneSummaryEmptyState()
          : _SelectedSceneSummary(
              scene: current,
              selectedNodeId: selectedNodeId,
              selectedEdgeId: selectedEdgeId,
              pendingConnection: pendingConnection,
              focusNodeForNodeId: focusNodeForNodeId,
              onSelectNode: onSelectNode,
              onSelectEdge: onSelectEdge,
              onAddNodeDraft: onAddNodeDraft,
              onAddLinkedAssetNodeDraft: onAddLinkedAssetNodeDraft,
              onAddConsequenceActionNodeDraft: onAddConsequenceActionNodeDraft,
              linkedAssetContracts: linkedAssetContracts,
              cinematicsLibrary: cinematicsLibrary,
              presentationCinematics: presentationCinematics,
              presentationFolders: presentationFolders,
              viewport: viewport,
              inspector: inspector,
              onViewportChanged: onViewportChanged,
              onCreateAndLinkPresentation: onCreateAndLinkPresentation,
              onOpenCreatedPresentation: onOpenCreatedPresentation,
              consequenceFactOptions: consequenceFactOptions,
              consequenceEventOptions: consequenceEventOptions,
              consequenceCatalogs: consequenceCatalogs,
              actionPickerOptions: actionPickerOptions,
              onAddEdgeDraft: onAddEdgeDraft,
              onStartConnection: onStartConnection,
              onCancelConnection: onCancelConnection,
              onUpdateNodeLayout: onUpdateNodeLayout,
              onDuplicateNode: onDuplicateNode,
            ),
    );
  }
}

class _SceneSummaryEmptyState extends StatelessWidget {
  const _SceneSummaryEmptyState();

  @override
  Widget build(BuildContext context) {
    return const PokeMapEmptyState(
      key: ValueKey('scenes-summary-empty-state'),
      icon: Icon(CupertinoIcons.flowchart),
      title: 'Aucune scène créée',
      description: 'Créez bientôt vos scènes sous forme de graph '
          'd’orchestration : dialogue, condition, combat, cinématique, action.',
    );
  }
}

class _SelectedSceneSummary extends StatelessWidget {
  const _SelectedSceneSummary({
    required this.scene,
    required this.selectedNodeId,
    required this.selectedEdgeId,
    required this.pendingConnection,
    required this.focusNodeForNodeId,
    required this.onSelectNode,
    required this.onSelectEdge,
    required this.onAddNodeDraft,
    required this.onAddLinkedAssetNodeDraft,
    required this.onAddConsequenceActionNodeDraft,
    required this.linkedAssetContracts,
    required this.cinematicsLibrary,
    required this.presentationCinematics,
    required this.presentationFolders,
    required this.viewport,
    required this.inspector,
    required this.onViewportChanged,
    required this.onCreateAndLinkPresentation,
    required this.onOpenCreatedPresentation,
    required this.consequenceFactOptions,
    required this.consequenceEventOptions,
    required this.consequenceCatalogs,
    required this.actionPickerOptions,
    required this.onAddEdgeDraft,
    required this.onStartConnection,
    required this.onCancelConnection,
    required this.onUpdateNodeLayout,
    this.onDuplicateNode,
  });

  final NarrativeSceneSummary scene;
  final String? selectedNodeId;
  final String? selectedEdgeId;
  final _PendingSceneConnection? pendingConnection;
  final FocusNode Function(String nodeId)? focusNodeForNodeId;
  final ValueChanged<String> onSelectNode;
  final ValueChanged<String> onSelectEdge;
  final ValueChanged<SceneNodeKind> onAddNodeDraft;
  final _SelectedLinkedAssetNodeDraftCreator onAddLinkedAssetNodeDraft;
  final _SelectedConsequenceActionNodeDraftCreator
      onAddConsequenceActionNodeDraft;
  final LinkedAssetContractsSnapshot? linkedAssetContracts;
  final CinematicsLibraryReadModel? cinematicsLibrary;
  final List<PresentationCinematicAsset> presentationCinematics;
  final List<CinematicLibraryFolder> presentationFolders;
  final SceneGraphViewport viewport;
  final NarrativeSceneInspector inspector;
  final ValueChanged<SceneGraphViewport> onViewportChanged;
  final ScenePresentationCreateAndLinkCreator? onCreateAndLinkPresentation;
  final ScenePresentationCreateAndLinkOpener? onOpenCreatedPresentation;
  final List<SceneConsequenceFactPickerOption> consequenceFactOptions;
  final List<SceneConsequenceEventPickerOption> consequenceEventOptions;
  final SceneConsequenceCatalogs consequenceCatalogs;
  final Map<NarrativeCommandParameterKind, List<SceneActionPickerOption>>
      actionPickerOptions;
  final SceneVisualEdgeDraftCreator onAddEdgeDraft;
  final ValueChanged<SceneAuthorableOutputPort> onStartConnection;
  final VoidCallback onCancelConnection;
  final SceneNodeLayoutUpdater onUpdateNodeLayout;
  final SceneGraphNodeDuplicator? onDuplicateNode;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      key: ValueKey('scenes-selected-summary-${scene.id}'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            scene.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            scene.description ?? 'Aucune description.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _SceneNodeDraftPalette(
            scene: scene,
            linkedAssetContracts: linkedAssetContracts,
            cinematicsLibrary: cinematicsLibrary,
            presentationCinematics: presentationCinematics,
            presentationFolders: presentationFolders,
            viewport: viewport,
            inspector: inspector,
            selectedNodeId: selectedNodeId,
            onCreateAndLinkPresentation: onCreateAndLinkPresentation,
            onOpenCreatedPresentation: onOpenCreatedPresentation,
            consequenceFactOptions: consequenceFactOptions,
            consequenceEventOptions: consequenceEventOptions,
            consequenceCatalogs: consequenceCatalogs,
            actionPickerOptions: actionPickerOptions,
            onAddNodeDraft: onAddNodeDraft,
            onAddLinkedAssetNodeDraft: onAddLinkedAssetNodeDraft,
            onAddConsequenceActionNodeDraft: onAddConsequenceActionNodeDraft,
          ),
          const SizedBox(height: 8),
          _SceneEdgeDraftToolbar(
            scene: scene,
            selectedNodeId: selectedNodeId,
            pendingConnection: pendingConnection,
            onStartConnection: onStartConnection,
            onCancelConnection: onCancelConnection,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SceneGraphEditor(
              scene: scene,
              selectedNodeId: selectedNodeId,
              selectedEdgeId: selectedEdgeId,
              focusNodeForNodeId: focusNodeForNodeId,
              viewport: viewport,
              onViewportChanged: onViewportChanged,
              onSelectNode: onSelectNode,
              onSelectEdge: onSelectEdge,
              canDragNodes: pendingConnection == null,
              onCreateEdgeDraft: ({
                required fromNodeId,
                required fromPortId,
                required toNodeId,
              }) =>
                  onAddEdgeDraft(
                fromNodeId: fromNodeId,
                fromPortId: fromPortId,
                toNodeId: toNodeId,
              ),
              onUpdateNodeLayout: ({
                required nodeId,
                required x,
                required y,
              }) =>
                  onUpdateNodeLayout(
                sceneId: scene.id,
                nodeId: nodeId,
                x: x,
                y: y,
              ),
              onDuplicateNode: onDuplicateNode,
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneNodeDraftPalette extends StatelessWidget {
  const _SceneNodeDraftPalette({
    required this.scene,
    required this.linkedAssetContracts,
    required this.cinematicsLibrary,
    required this.presentationCinematics,
    required this.presentationFolders,
    required this.viewport,
    required this.inspector,
    required this.selectedNodeId,
    required this.onCreateAndLinkPresentation,
    required this.onOpenCreatedPresentation,
    required this.consequenceFactOptions,
    required this.consequenceEventOptions,
    required this.consequenceCatalogs,
    required this.actionPickerOptions,
    required this.onAddNodeDraft,
    required this.onAddLinkedAssetNodeDraft,
    required this.onAddConsequenceActionNodeDraft,
  });

  final NarrativeSceneSummary scene;
  final LinkedAssetContractsSnapshot? linkedAssetContracts;
  final CinematicsLibraryReadModel? cinematicsLibrary;
  final List<PresentationCinematicAsset> presentationCinematics;
  final List<CinematicLibraryFolder> presentationFolders;
  final SceneGraphViewport viewport;
  final NarrativeSceneInspector inspector;
  final String? selectedNodeId;
  final ScenePresentationCreateAndLinkCreator? onCreateAndLinkPresentation;
  final ScenePresentationCreateAndLinkOpener? onOpenCreatedPresentation;
  final List<SceneConsequenceFactPickerOption> consequenceFactOptions;
  final List<SceneConsequenceEventPickerOption> consequenceEventOptions;
  final SceneConsequenceCatalogs consequenceCatalogs;
  final Map<NarrativeCommandParameterKind, List<SceneActionPickerOption>>
      actionPickerOptions;
  final ValueChanged<SceneNodeKind> onAddNodeDraft;
  final _SelectedLinkedAssetNodeDraftCreator onAddLinkedAssetNodeDraft;
  final _SelectedConsequenceActionNodeDraftCreator
      onAddConsequenceActionNodeDraft;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final contracts = linkedAssetContracts;
    final library = cinematicsLibrary;
    final isPreSession =
        scene.executionProfile == SceneExecutionProfile.preSession;
    final hasDialogues = contracts?.dialogues.isNotEmpty ?? false;
    final hasBattles = contracts?.battles.isNotEmpty ?? false;
    final canonicalCinematics = library?.canonicalEntries ?? const [];
    final hasCanonicalCinematics = canonicalCinematics.isNotEmpty;
    final compatiblePresentations = presentationCinematics.toList()
      ..sort((left, right) => left.title.compareTo(right.title));
    final branchSources = scene.graph.nodes
        .where(
          (node) =>
              node.kind == SceneNodeKind.yarnDialogue ||
              node.kind == SceneNodeKind.battle ||
              node.kind == SceneNodeKind.condition ||
              (isPreSession &&
                  node.payload is SceneActionPayload &&
                  (node.payload as SceneActionPayload)
                          .preSessionInteraction !=
                      null),
        )
        .toList(growable: false);
    final cinematicReason = hasCanonicalCinematics
        ? null
        : 'Créez d’abord une cinématique dans la Cinematics Library.';
    const worldOnlyReason = 'réservé aux scènes in-game';
    return SizedBox(
      key: const ValueKey('scenes-add-node-palette'),
      height: 34,
      child: Row(
        children: [
          Text(
            'Ajouter un nœud',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _NodeDraftButton(
                    buttonKey: isPreSession
                        ? const ValueKey(
                            'scenes-add-node-condition-disabled-profile',
                          )
                        : const ValueKey('scenes-add-node-condition'),
                    label: 'Condition',
                    icon: CupertinoIcons.check_mark_circled,
                    disabledReason: isPreSession ? worldOnlyReason : null,
                    onPressed: isPreSession
                        ? null
                        : () => onAddNodeDraft(SceneNodeKind.condition),
                  ),
                  _NodeDraftButton(
                    buttonKey: const ValueKey('scenes-add-node-merge'),
                    label: 'Merge',
                    icon: CupertinoIcons.arrow_merge,
                    onPressed: () => onAddNodeDraft(SceneNodeKind.merge),
                  ),
                  _NodeDraftButton(
                    buttonKey: const ValueKey('scenes-add-node-end'),
                    label: 'Fin',
                    icon: CupertinoIcons.flag,
                    onPressed: () => onAddNodeDraft(SceneNodeKind.end),
                  ),
                  _NodeDraftButton(
                    buttonKey: isPreSession
                        ? const ValueKey(
                            'scenes-add-node-yarn-disabled-profile',
                          )
                        : hasDialogues
                            ? const ValueKey('scenes-add-node-yarn')
                            : const ValueKey(
                                'scenes-add-node-yarn-disabled',
                              ),
                    label: 'Dialogue',
                    icon: CupertinoIcons.text_bubble,
                    disabledReason: isPreSession
                        ? worldOnlyReason
                        : hasDialogues
                            ? null
                            : 'contrat absent',
                    onPressed: !isPreSession && hasDialogues
                        ? () => _pickDialogueAndAddNode(
                              context,
                              contracts!.dialogues,
                            )
                        : null,
                  ),
                  _NodeDraftButton(
                    buttonKey: isPreSession
                        ? const ValueKey(
                            'scenes-add-node-battle-disabled-profile',
                          )
                        : hasBattles
                            ? const ValueKey('scenes-add-node-battle')
                            : const ValueKey(
                                'scenes-add-node-battle-disabled',
                              ),
                    label: 'Combat',
                    icon: CupertinoIcons.asterisk_circle,
                    disabledReason: isPreSession
                        ? worldOnlyReason
                        : hasBattles
                            ? null
                            : 'contrat absent',
                    onPressed: !isPreSession && hasBattles
                        ? () => _pickBattleAndAddNode(
                              context,
                              contracts!.battles,
                            )
                        : null,
                  ),
                  const _NodeDraftButton(
                    buttonKey: ValueKey('scenes-add-node-start-disabled'),
                    label: 'Début',
                    icon: CupertinoIcons.play_circle,
                    disabledReason: 'déjà unique',
                  ),
                  _NodeDraftButton(
                    buttonKey: isPreSession
                        ? const ValueKey(
                            'scenes-add-node-action-disabled-profile',
                          )
                        : const ValueKey(
                            'scenes-add-node-action-consequence',
                          ),
                    label: 'Action',
                    icon: CupertinoIcons.bolt,
                    disabledReason: isPreSession ? worldOnlyReason : null,
                    onPressed: isPreSession
                        ? null
                        : () => _pickConsequenceAndAddNode(context),
                  ),
                  _NodeDraftButton(
                    buttonKey: isPreSession
                        ? const ValueKey(
                            'scenes-add-node-cinematic-disabled-profile',
                          )
                        : hasCanonicalCinematics
                            ? const ValueKey('scenes-add-node-cinematic')
                            : const ValueKey(
                                'scenes-add-node-cinematic-disabled',
                              ),
                    label: 'Cinématique',
                    icon: CupertinoIcons.film,
                    disabledReason:
                        isPreSession ? worldOnlyReason : cinematicReason,
                    onPressed: !isPreSession && hasCanonicalCinematics
                        ? () => _pickCinematicAndAddNode(context, library!)
                        : null,
                  ),
                  if (isPreSession)
                    _NodeDraftButton(
                      buttonKey: const ValueKey(
                        'scenes-add-node-presentation-cinematic',
                      ),
                      label: 'Présentation',
                      icon: CupertinoIcons.play_rectangle,
                      onPressed: () => _pickPresentationAndAddNode(
                        context,
                        compatiblePresentations,
                      ),
                    ),
                  _NodeDraftButton(
                    buttonKey: branchSources.isEmpty
                        ? const ValueKey('scenes-add-node-branch-disabled')
                        : const ValueKey('scenes-add-node-branch'),
                    label: 'Branche',
                    icon: CupertinoIcons.arrow_branch,
                    disabledReason:
                        branchSources.isEmpty ? 'aucun résultat source' : null,
                    onPressed: branchSources.isEmpty
                        ? null
                        : () => _pickBranchAndAddNode(
                              context,
                              branchSources,
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDialogueAndAddNode(
    BuildContext context,
    List<DialoguePublicContract> dialogues,
  ) async {
    final contract = await showCupertinoDialog<DialoguePublicContract>(
      context: context,
      builder: (context) => _DialoguePayloadPickerDialog(dialogues: dialogues),
    );
    if (contract == null) {
      return;
    }
    await onAddLinkedAssetNodeDraft(
      payload: SceneYarnDialoguePayload(
        dialogueId: contract.id,
        yarnNodeName: contract.defaultStartNode,
        expectedOutcomes: [
          for (final outcome in contract.declaredOutcomes) outcome.id,
        ],
      ),
      title: contract.label,
    );
  }

  Future<void> _pickBattleAndAddNode(
    BuildContext context,
    List<BattlePublicContract> battles,
  ) async {
    final contract = await showCupertinoDialog<BattlePublicContract>(
      context: context,
      builder: (context) => _BattlePayloadPickerDialog(battles: battles),
    );
    if (contract == null) {
      return;
    }
    await onAddLinkedAssetNodeDraft(
      payload: SceneBattlePayload(
        battleKind: switch (contract.battleKind) {
          BattlePublicContractKind.trainer => 'trainer',
          BattlePublicContractKind.staticEncounter => 'static',
        },
        trainerId: contract.trainerId,
        battleTemplateId:
            contract.battleKind == BattlePublicContractKind.staticEncounter
                ? contract.battleTemplateId
                : null,
        declaredOutcomes: [
          for (final outcome in contract.possibleOutcomes) outcome.id,
        ],
      ),
      title: contract.label,
    );
  }

  Future<void> _pickCinematicAndAddNode(
    BuildContext context,
    CinematicsLibraryReadModel library,
  ) async {
    final entry = await showCupertinoDialog<CinematicsLibraryEntry>(
      context: context,
      builder: (context) => SceneCinematicPickerDialog(library: library),
    );
    if (entry == null) {
      return;
    }
    await onAddLinkedAssetNodeDraft(
      payload: SceneCinematicPayload(cinematicId: entry.id),
      title: entry.title,
    );
  }

  Future<void> _pickPresentationAndAddNode(
    BuildContext context,
    List<PresentationCinematicAsset> cinematics,
  ) async {
    final choice =
        await showPokeMapDesktopSideSheet<ScenePresentationPickerResult>(
      context: context,
      title: 'Cinématique de présentation',
      semanticLabel:
          'Choisir une cinématique de présentation compatible avec la scène',
      barrierLabel: 'Fermer le sélecteur de cinématique de présentation',
      width: 520,
      builder: (context) => ScenePresentationCinematicPicker(
        cinematics: cinematics,
      ),
    );
    switch (choice) {
      case ScenePresentationPickerExisting(:final cinematic):
        await onAddLinkedAssetNodeDraft(
          payload: ScenePresentationCinematicPayload(
            presentationCinematicId: cinematic.id,
          ),
          title: cinematic.title,
        );
      case ScenePresentationPickerCreate():
        if (!context.mounted) return;
        await _createAndLinkPresentation(context);
      case null:
        return;
    }
  }

  Future<void> _createAndLinkPresentation(BuildContext context) async {
    final create = onCreateAndLinkPresentation;
    final targetNodeId = _presentationInsertionTarget();
    if (create == null || targetNodeId == null) return;
    ScenePresentationCreateAndLinkOutcome? outcome;
    final createdId = await showCinematicLibraryCreateDialog(
      context: context,
      family: CinematicLibraryFamily.presentation,
      initialFolderId: null,
      folders: presentationFolders,
      onCreate: (request) async {
        final created = await create(
          sceneId: scene.id,
          targetNodeId: targetNodeId,
          title: request.title,
          templateId: request.presentationTemplateId!,
          templateVersion: request.presentationTemplateVersion!,
          folderId: request.folderId,
        );
        outcome = created;
        return created?.cinematicId;
      },
    );
    final created = outcome;
    if (createdId == null || created == null || !context.mounted) return;
    onOpenCreatedPresentation?.call(
      sceneId: scene.id,
      returnNodeId: selectedNodeId ?? targetNodeId,
      cinematicId: created.cinematicId,
      viewport: viewport,
      inspector: inspector,
    );
  }

  String? _presentationInsertionTarget() {
    final selectedId = selectedNodeId;
    if (selectedId != null && selectedId != scene.graph.startNodeId) {
      final incoming = scene.graph.edges
          .where((edge) => edge.toNodeId == selectedId)
          .length;
      if (incoming == 1) return selectedId;
    }
    for (final node in scene.graph.nodes) {
      if (node.kind != SceneNodeKind.end) continue;
      final incoming = scene.graph.edges
          .where((edge) => edge.toNodeId == node.id)
          .length;
      if (incoming == 1) return node.id;
    }
    return null;
  }

  Future<void> _pickConsequenceAndAddNode(BuildContext context) async {
    final consequence = await showPokeMapDesktopSideSheet<SceneConsequence>(
      context: context,
      title: 'Ajouter une conséquence',
      semanticLabel: 'Créer une conséquence de gameplay pour la scène',
      width: 480,
      builder: (sheetContext) => _SceneConsequencePickerDialog(
        facts: consequenceFactOptions,
        events: consequenceEventOptions,
        catalogs: consequenceCatalogs,
        onOpenCommandCatalog: actionPickerOptions.isEmpty
            ? null
            : () => _openCommandCatalog(sheetContext),
      ),
    );
    if (consequence == null) {
      return;
    }
    await onAddConsequenceActionNodeDraft(consequence: consequence);
  }

  Future<void> _openCommandCatalog(BuildContext consequenceSheetContext) async {
    final payload = await showPokeMapDesktopSideSheet<SceneNodePayload>(
      context: consequenceSheetContext,
      title: 'Catalogue de commandes',
      semanticLabel: 'Créer une action guidée depuis le catalogue canonique',
      width: 440,
      builder: (catalogContext) => SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: SceneActionBuilder(
          pickerOptions: actionPickerOptions,
          onSubmit: (payload) => Navigator.of(catalogContext).pop(payload),
        ),
      ),
    );
    if (payload == null || !consequenceSheetContext.mounted) return;
    Navigator.of(consequenceSheetContext).pop();
    if (payload case SceneActionPayload(:final consequence?)) {
      await onAddConsequenceActionNodeDraft(consequence: consequence);
      return;
    }
    await onAddLinkedAssetNodeDraft(payload: payload);
  }

  Future<void> _pickBranchAndAddNode(
    BuildContext context,
    List<SceneNode> sources,
  ) async {
    final source = await showCupertinoDialog<SceneNode>(
      context: context,
      builder: (context) => _BranchSourcePickerDialog(sources: sources),
    );
    if (source == null || !context.mounted) return;
    final policy = await showCupertinoDialog<SceneBranchOutcomeFallbackPolicy>(
      context: context,
      builder: (context) => const _BranchFallbackPickerDialog(),
    );
    if (policy == null) return;
    await onAddLinkedAssetNodeDraft(
      payload: SceneBranchByOutcomePayload(
        sourceNodeId: source.id,
        sourceOutcomeSetRef: switch (source.payload) {
          SceneYarnDialoguePayload(:final dialogueId) => dialogueId,
          SceneBattlePayload(:final trainerId) => trainerId ?? source.id,
          _ => source.id,
        },
        fallbackPolicy: policy,
      ),
      title: 'Branche · ${source.title ?? source.id}',
    );
  }
}

enum _SceneConsequencePickerMode {
  setFact,
  markEventConsumed,
  completeStoryStep,
  giveItem,
  takeItem,
  giveMoney,
  givePokemon,
  giveConfiguredStarter,
}

class _SceneConsequencePickerDialog extends StatefulWidget {
  const _SceneConsequencePickerDialog({
    required this.facts,
    required this.events,
    required this.catalogs,
    this.onOpenCommandCatalog,
  });

  final List<SceneConsequenceFactPickerOption> facts;
  final List<SceneConsequenceEventPickerOption> events;
  final SceneConsequenceCatalogs catalogs;
  final VoidCallback? onOpenCommandCatalog;

  @override
  State<_SceneConsequencePickerDialog> createState() =>
      _SceneConsequencePickerDialogState();
}

class _SceneConsequencePickerDialogState
    extends State<_SceneConsequencePickerDialog> {
  late _SceneConsequencePickerMode _mode;
  SceneConsequenceFactPickerOption? _selectedFact;
  SceneConsequenceEventPickerOption? _selectedEvent;
  SceneConsequenceCatalogOption? _selectedStoryStep;
  SceneConsequenceCatalogOption? _selectedItem;
  SceneConsequenceCatalogOption? _selectedSpecies;
  String? _selectedPokemonFormId;
  SceneConsequenceCatalogOption? _selectedConfiguredStarter;
  bool _setFactValue = true;
  final TextEditingController _setFactValueController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final TextEditingController _moneyAmountController =
      TextEditingController(text: '100');
  final TextEditingController _pokemonLevelController =
      TextEditingController(text: '5');
  final TextEditingController _pokemonCurrentHpController =
      TextEditingController(text: '20');
  final TextEditingController _pokemonNicknameController =
      TextEditingController();
  final TextEditingController _pokemonFriendshipController =
      TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _mode = widget.facts.isNotEmpty
        ? _SceneConsequencePickerMode.setFact
        : _SceneConsequencePickerMode.markEventConsumed;
    _selectedFact = widget.facts.firstOrNull;
    final initialFact = _selectedFact;
    if (initialFact != null) {
      _setFactValue = initialFact.valueKind == NarrativeValueKind.boolean
          ? initialFact.initialValue.boolValue
          : false;
      _setFactValueController.text = switch (initialFact.valueKind) {
        NarrativeValueKind.boolean => '',
        NarrativeValueKind.integer => '${initialFact.initialValue.intValue}',
        NarrativeValueKind.string => initialFact.initialValue.stringValue,
      };
    }
    _selectedEvent = widget.events.firstOrNull;
    _selectedStoryStep = widget.catalogs.storySteps.options.firstOrNull;
    _selectedItem = widget.catalogs.items.options.firstOrNull;
    _selectedSpecies = widget.catalogs.species.options.firstOrNull;
    _selectedPokemonFormId = _selectedSpecies?.formIds.firstOrNull;
    _selectedConfiguredStarter =
        widget.catalogs.configuredStarters.options.firstOrNull;
  }

  @override
  void dispose() {
    _setFactValueController.dispose();
    _quantityController.dispose();
    _moneyAmountController.dispose();
    _pokemonLevelController.dispose();
    _pokemonCurrentHpController.dispose();
    _pokemonNicknameController.dispose();
    _pokemonFriendshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consequence = _buildConsequence();
    return Padding(
      key: const ValueKey('scene-consequence-picker-sheet'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.onOpenCommandCatalog != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: PokeMapButton(
                key: const ValueKey('scene-open-command-catalog'),
                onPressed: widget.onOpenCommandCatalog,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.square_grid_2x2),
                child: const Text('Toutes les commandes'),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _kindButton(
                key: const ValueKey('scene-consequence-kind-setFact'),
                label: 'Définir un fait',
                mode: _SceneConsequencePickerMode.setFact,
                enabled: widget.facts.isNotEmpty,
              ),
              _kindButton(
                key: const ValueKey(
                  'scene-consequence-kind-markEventConsumed',
                ),
                label: 'Marquer joué',
                mode: _SceneConsequencePickerMode.markEventConsumed,
                enabled: widget.events.isNotEmpty,
              ),
              _kindButton(
                key: const ValueKey(
                  'scene-consequence-kind-completeStoryStep',
                ),
                label: 'Terminer une étape',
                mode: _SceneConsequencePickerMode.completeStoryStep,
                enabled: widget.catalogs.storySteps.isReady,
              ),
              _kindButton(
                key: const ValueKey('scene-consequence-kind-giveItem'),
                label: 'Donner un objet',
                mode: _SceneConsequencePickerMode.giveItem,
                enabled: widget.catalogs.items.isReady,
              ),
              _kindButton(
                key: const ValueKey('scene-consequence-kind-takeItem'),
                label: 'Retirer un objet',
                mode: _SceneConsequencePickerMode.takeItem,
                enabled: widget.catalogs.items.isReady,
              ),
              _kindButton(
                key: const ValueKey('scene-consequence-kind-giveMoney'),
                label: 'Donner de l’argent',
                mode: _SceneConsequencePickerMode.giveMoney,
                // Money has no catalog reference, so it remains authorable
                // while item/species catalogs are loading or unavailable.
                enabled: true,
              ),
              _kindButton(
                key: const ValueKey('scene-consequence-kind-givePokemon'),
                label: 'Donner un Pokémon',
                mode: _SceneConsequencePickerMode.givePokemon,
                enabled: widget.catalogs.species.isReady,
              ),
              _kindButton(
                key: const ValueKey(
                  'scene-consequence-kind-giveConfiguredStarter',
                ),
                label: 'Donner un starter',
                mode: _SceneConsequencePickerMode.giveConfiguredStarter,
                enabled: widget.catalogs.configuredStarters.isReady,
              ),
            ],
          ),
          if (!widget.catalogs.items.isReady) ...[
            const SizedBox(height: 10),
            PokeMapDiagnosticCallout(
              key: const ValueKey(
                'scene-consequence-items-catalog-diagnostic',
              ),
              severity: widget.catalogs.items.status ==
                      SceneConsequenceCatalogStatus.failed
                  ? PokeMapDiagnosticSeverity.error
                  : PokeMapDiagnosticSeverity.warning,
              title: 'Objets indisponibles',
              message: widget.catalogs.items.message,
            ),
          ],
          if (!widget.catalogs.species.isReady) ...[
            const SizedBox(height: 10),
            PokeMapDiagnosticCallout(
              key: const ValueKey(
                'scene-consequence-species-catalog-diagnostic',
              ),
              severity: widget.catalogs.species.status ==
                      SceneConsequenceCatalogStatus.failed
                  ? PokeMapDiagnosticSeverity.error
                  : PokeMapDiagnosticSeverity.warning,
              title: 'Pokémon indisponibles',
              message: widget.catalogs.species.message,
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: switch (_mode) {
                  _SceneConsequencePickerMode.setFact => _setFactControls(),
                  _SceneConsequencePickerMode.markEventConsumed =>
                    _markEventControls(),
                  _SceneConsequencePickerMode.completeStoryStep =>
                    _completeStoryStepControls(),
                  _SceneConsequencePickerMode.giveItem => _giveItemControls(),
                  _SceneConsequencePickerMode.takeItem => _giveItemControls(),
                  _SceneConsequencePickerMode.giveMoney => _giveMoneyControls(),
                  _SceneConsequencePickerMode.givePokemon =>
                    _givePokemonControls(),
                  _SceneConsequencePickerMode.giveConfiguredStarter =>
                    _giveConfiguredStarterControls(),
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PokeMapButton(
                key: const ValueKey('scene-consequence-cancel-action'),
                onPressed: () => Navigator.of(context).pop(),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              PokeMapButton(
                key: const ValueKey('scene-consequence-create-action'),
                onPressed: consequence == null
                    ? null
                    : () => Navigator.of(context).pop(consequence),
                variant: PokeMapButtonVariant.primary,
                size: PokeMapButtonSize.small,
                child: const Text('Créer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kindButton({
    required Key key,
    required String label,
    required _SceneConsequencePickerMode mode,
    required bool enabled,
  }) {
    return PokeMapButton(
      key: key,
      onPressed: enabled ? () => setState(() => _mode = mode) : null,
      variant: _mode == mode
          ? PokeMapButtonVariant.primary
          : PokeMapButtonVariant.secondary,
      size: PokeMapButtonSize.small,
      child: Text(label),
    );
  }

  List<Widget> _setFactControls() {
    return [
      for (final fact in widget.facts)
        _ConsequencePickerCard(
          key: ValueKey(
            'scene-consequence-fact-option-${_pickerKeyPart(fact.factId)}',
          ),
          selected: _selectedFact?.factId == fact.factId,
          title: fact.label,
          subtitle: fact.factId,
          details: [
            [fact.category, fact.description]
                .where((value) => value.isNotEmpty)
                .join(' · '),
            if (fact.debugTechnicalLabel.isNotEmpty) fact.debugTechnicalLabel,
          ],
          onTap: () => setState(() {
            _selectedFact = fact;
            _setFactValue = fact.valueKind == NarrativeValueKind.boolean
                ? fact.initialValue.boolValue
                : false;
            _setFactValueController.text = switch (fact.valueKind) {
              NarrativeValueKind.boolean => '',
              NarrativeValueKind.integer => '${fact.initialValue.intValue}',
              NarrativeValueKind.string => fact.initialValue.stringValue,
            };
          }),
        ),
      const SizedBox(height: 6),
      if (_selectedFact?.valueKind == NarrativeValueKind.boolean)
        Row(
          children: [
            Expanded(
              child: PokeMapButton(
                key: const ValueKey('scene-consequence-setfact-value-true'),
                onPressed: () => setState(() => _setFactValue = true),
                variant: _setFactValue
                    ? PokeMapButtonVariant.primary
                    : PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                child: const Text('true'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PokeMapButton(
                key: const ValueKey('scene-consequence-setfact-value-false'),
                onPressed: () => setState(() => _setFactValue = false),
                variant: !_setFactValue
                    ? PokeMapButtonVariant.primary
                    : PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                child: const Text('false'),
              ),
            ),
          ],
        )
      else if (_selectedFact != null)
        PokeMapTextField(
          key: const ValueKey('scene-consequence-setfact-typed-value'),
          label: _selectedFact!.valueKind == NarrativeValueKind.integer
              ? 'Valeur entière'
              : 'Texte',
          controller: _setFactValueController,
          onChanged: (_) => setState(() {}),
          errorText: _selectedFact!.valueKind == NarrativeValueKind.integer &&
                  int.tryParse(_setFactValueController.text.trim()) == null
              ? 'Saisissez un nombre entier valide.'
              : null,
        ),
    ];
  }

  List<Widget> _markEventControls() {
    return [
      for (final event in widget.events)
        _ConsequencePickerCard(
          key: ValueKey(
            'scene-consequence-event-option-'
            '${_pickerKeyPart(event.mapId)}-${_pickerKeyPart(event.eventId)}',
          ),
          selected: _selectedEvent?.mapId == event.mapId &&
              _selectedEvent?.eventId == event.eventId,
          title: event.eventLabel,
          subtitle: event.eventId,
          details: [
            '${event.mapLabel} · ${event.eventLabel}',
            if (event.debugTechnicalLabel.isNotEmpty) event.debugTechnicalLabel,
          ],
          onTap: () => setState(() => _selectedEvent = event),
        ),
    ];
  }

  List<Widget> _completeStoryStepControls() {
    return <Widget>[
      for (final step in widget.catalogs.storySteps.options)
        _ConsequencePickerCard(
          key: ValueKey(
            'scene-consequence-story-step-option-${_pickerKeyPart(step.id)}',
          ),
          selected: _selectedStoryStep?.id == step.id,
          title: step.label,
          subtitle: 'Étape narrative du projet',
          details: step.details,
          onTap: () => setState(() => _selectedStoryStep = step),
        ),
    ];
  }

  List<Widget> _giveItemControls() {
    final quantity = int.tryParse(_quantityController.text.trim());
    final quantityError = quantity == null || quantity <= 0
        ? 'Saisissez une quantité supérieure à zéro.'
        : null;
    return [
      for (final item in widget.catalogs.items.options)
        _ConsequencePickerCard(
          key: ValueKey(
            'scene-consequence-item-option-${_pickerKeyPart(item.id)}',
          ),
          selected: _selectedItem?.id == item.id,
          title: item.label,
          subtitle: 'Objet du catalogue local',
          details: item.details,
          onTap: () => setState(() => _selectedItem = item),
        ),
      const SizedBox(height: 4),
      PokeMapTextField(
        key: const ValueKey('scene-consequence-item-quantity-field'),
        label: 'Quantité',
        controller: _quantityController,
        keyboardType: TextInputType.number,
        errorText: quantityError,
        onChanged: (_) => setState(() {}),
      ),
    ];
  }

  List<Widget> _giveMoneyControls() {
    final amount = int.tryParse(_moneyAmountController.text.trim());
    return [
      PokeMapTextField(
        key: const ValueKey('scene-consequence-money-amount-field'),
        label: 'Montant',
        controller: _moneyAmountController,
        keyboardType: TextInputType.number,
        errorText: amount == null || amount <= 0
            ? 'Saisissez un montant supérieur à zéro.'
            : null,
        onChanged: (_) => setState(() {}),
      ),
    ];
  }

  List<Widget> _givePokemonControls() {
    final level = int.tryParse(_pokemonLevelController.text.trim());
    final currentHp = int.tryParse(_pokemonCurrentHpController.text.trim());
    final friendship = int.tryParse(_pokemonFriendshipController.text.trim());
    final formIds = _selectedSpecies?.formIds ?? const <String>[];
    return [
      for (final species in widget.catalogs.species.options)
        _ConsequencePickerCard(
          key: ValueKey(
            'scene-consequence-species-option-${_pickerKeyPart(species.id)}',
          ),
          selected: _selectedSpecies?.id == species.id,
          title: species.label,
          subtitle: 'Espèce locale activée',
          details: species.details,
          onTap: () => setState(() {
            _selectedSpecies = species;
            _selectedPokemonFormId = species.formIds.firstOrNull;
          }),
        ),
      const SizedBox(height: 4),
      if (formIds.isEmpty)
        const PokeMapDiagnosticCallout(
          key: ValueKey('scene-consequence-pokemon-form-diagnostic'),
          severity: PokeMapDiagnosticSeverity.error,
          title: 'Formes indisponibles',
          message: 'Cette espèce ne déclare aucune forme sélectionnable.',
        )
      else
        PokeMapDropdownField<String>(
          key: const ValueKey('scene-consequence-pokemon-form-picker'),
          label: 'Forme',
          value: _selectedPokemonFormId ?? formIds.first,
          items: [
            for (final formId in formIds)
              PokeMapDropdownItem(
                value: formId,
                label: scenePokemonFormLabel(formId),
              ),
          ],
          onChanged: (value) =>
              setState(() => _selectedPokemonFormId = value),
        ),
      const SizedBox(height: 12),
      PokeMapTextField(
        key: const ValueKey('scene-consequence-pokemon-level-field'),
        label: 'Niveau',
        controller: _pokemonLevelController,
        keyboardType: TextInputType.number,
        errorText: level == null || level < 1 || level > 100
            ? 'Choisissez un niveau entre 1 et 100.'
            : null,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      PokeMapTextField(
        key: const ValueKey('scene-consequence-pokemon-current-hp-field'),
        label: 'PV courants',
        controller: _pokemonCurrentHpController,
        keyboardType: TextInputType.number,
        errorText: currentHp == null || currentHp <= 0
            ? 'Saisissez des PV courants supérieurs à zéro.'
            : null,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      PokeMapTextField(
        key: const ValueKey('scene-consequence-pokemon-nickname-field'),
        label: 'Surnom (facultatif)',
        controller: _pokemonNicknameController,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      PokeMapTextField(
        key: const ValueKey('scene-consequence-pokemon-friendship-field'),
        label: 'Amitié initiale',
        controller: _pokemonFriendshipController,
        keyboardType: TextInputType.number,
        errorText: friendship == null || friendship < 0 || friendship > 255
            ? 'Choisissez une amitié entre 0 et 255.'
            : null,
        onChanged: (_) => setState(() {}),
      ),
    ];
  }

  List<Widget> _giveConfiguredStarterControls() {
    return <Widget>[
      for (final starter in widget.catalogs.configuredStarters.options)
        _ConsequencePickerCard(
          key: ValueKey(
            'scene-consequence-configured-starter-option-'
            '${_pickerKeyPart(starter.id)}',
          ),
          selected: _selectedConfiguredStarter?.id == starter.id,
          title: starter.label,
          subtitle: 'Starter configuré dans Nouveau Jeu',
          details: starter.details,
          onTap: () => setState(() => _selectedConfiguredStarter = starter),
        ),
    ];
  }

  SceneConsequence? _buildConsequence() {
    return switch (_mode) {
      _SceneConsequencePickerMode.setFact => _selectedFact == null
          ? null
          : _setFactNarrativeValue() == null
              ? null
              : SceneConsequence.setFactValue(
                  factId: _selectedFact!.factId,
                  value: _setFactNarrativeValue()!,
                ),
      _SceneConsequencePickerMode.markEventConsumed => _selectedEvent == null
          ? null
          : SceneConsequence.markEventConsumed(
              mapId: _selectedEvent!.mapId,
              eventId: _selectedEvent!.eventId,
            ),
      _SceneConsequencePickerMode.completeStoryStep =>
        _selectedStoryStep == null
            ? null
            : SceneConsequence.completeStoryStep(
                stepId: _selectedStoryStep!.id,
              ),
      _SceneConsequencePickerMode.giveItem => _selectedItem == null ||
              (int.tryParse(_quantityController.text.trim()) ?? 0) <= 0
          ? null
          : SceneConsequence.giveItem(
              itemId: _selectedItem!.id,
              quantity: int.parse(_quantityController.text.trim()),
            ),
      _SceneConsequencePickerMode.takeItem => _selectedItem == null ||
              (int.tryParse(_quantityController.text.trim()) ?? 0) <= 0
          ? null
          : SceneConsequence.takeItem(
              itemId: _selectedItem!.id,
              quantity: int.parse(_quantityController.text.trim()),
            ),
      _SceneConsequencePickerMode.giveMoney =>
        (int.tryParse(_moneyAmountController.text.trim()) ?? 0) <= 0
            ? null
            : SceneConsequence.giveMoney(
                amount: int.parse(_moneyAmountController.text.trim()),
              ),
      _SceneConsequencePickerMode.givePokemon => _selectedSpecies == null ||
              _selectedPokemonFormId == null ||
              (int.tryParse(_pokemonLevelController.text.trim()) ?? 0) < 1 ||
              (int.tryParse(_pokemonLevelController.text.trim()) ?? 101) >
                  100 ||
              (int.tryParse(_pokemonCurrentHpController.text.trim()) ?? 0) <=
                  0 ||
              (int.tryParse(_pokemonFriendshipController.text.trim()) ?? -1) <
                  0 ||
              (int.tryParse(_pokemonFriendshipController.text.trim()) ?? 256) >
                  255
          ? null
          : SceneConsequence.givePokemon(
              speciesId: _selectedSpecies!.id,
              formId: _selectedPokemonFormId!,
              level: int.parse(_pokemonLevelController.text.trim()),
              currentHp: int.parse(_pokemonCurrentHpController.text.trim()),
              nickname: _pokemonNicknameController.text,
              friendship: int.parse(_pokemonFriendshipController.text.trim()),
            ),
      _SceneConsequencePickerMode.giveConfiguredStarter =>
        _selectedConfiguredStarter == null
            ? null
            : SceneConsequence.giveConfiguredStarter(
                starterOptionId: _selectedConfiguredStarter!.id,
              ),
    };
  }

  NarrativeValue? _setFactNarrativeValue() {
    final fact = _selectedFact;
    if (fact == null) return null;
    return switch (fact.valueKind) {
      NarrativeValueKind.boolean => NarrativeValue.boolean(_setFactValue),
      NarrativeValueKind.integer => switch (
            int.tryParse(_setFactValueController.text.trim())) {
          final value? => NarrativeValue.integer(value),
          null => null,
        },
      NarrativeValueKind.string =>
        NarrativeValue.string(_setFactValueController.text),
    };
  }
}

class _ConsequencePickerCard extends StatelessWidget {
  const _ConsequencePickerCard({
    super.key,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final List<String> details;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PokeMapCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        selected: selected,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            for (final detail in details.where((value) => value.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BranchSourcePickerDialog extends StatelessWidget {
  const _BranchSourcePickerDialog({required this.sources});

  final List<SceneNode> sources;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      key: const ValueKey('scene-branch-source-picker-dialog'),
      title: const Text('Résultat à observer'),
      content: _PayloadPickerContent(
        children: [
          for (final source in sources)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PokeMapCard(
                key: ValueKey('scene-branch-source-${source.id}'),
                onTap: () => Navigator.of(context).pop(source),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(source.title ?? source.id),
                ),
              ),
            ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

class _BranchFallbackPickerDialog extends StatelessWidget {
  const _BranchFallbackPickerDialog();

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      key: const ValueKey('scene-branch-fallback-picker-dialog'),
      title: const Text('Si le résultat n’est pas relié'),
      content: const Text(
        'Exact bloque la scène. Par défaut suit une sortie commune. '
        'Erreur suit une sortie d’erreur explicite.',
      ),
      actions: [
        CupertinoDialogAction(
          key: const ValueKey('scene-branch-fallback-exact'),
          onPressed: () =>
              Navigator.of(context).pop(SceneBranchOutcomeFallbackPolicy.exact),
          child: const Text('Exact'),
        ),
        CupertinoDialogAction(
          key: const ValueKey('scene-branch-fallback-default'),
          onPressed: () => Navigator.of(context)
              .pop(SceneBranchOutcomeFallbackPolicy.defaultRoute),
          child: const Text('Par défaut'),
        ),
        CupertinoDialogAction(
          key: const ValueKey('scene-branch-fallback-error'),
          onPressed: () => Navigator.of(context)
              .pop(SceneBranchOutcomeFallbackPolicy.errorRoute),
          child: const Text('Erreur'),
        ),
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

class _DialoguePayloadPickerDialog extends StatelessWidget {
  const _DialoguePayloadPickerDialog({required this.dialogues});

  final List<DialoguePublicContract> dialogues;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      key: const ValueKey('scene-dialogue-picker-dialog'),
      title: const Text('Choisir un dialogue'),
      content: _PayloadPickerContent(
        children: [
          for (final dialogue in dialogues)
            _PayloadPickerOptionButton(
              key: ValueKey('scene-dialogue-picker-option-${dialogue.id}'),
              title: dialogue.label,
              subtitle: dialogue.id,
              details: [
                dialogue.sourceRef,
                if (dialogue.defaultStartNode != null)
                  'Start: ${dialogue.defaultStartNode}',
              ],
              diagnostics: dialogue.diagnostics,
              onPressed: () => Navigator.of(context).pop(dialogue),
            ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _BattlePayloadPickerDialog extends StatelessWidget {
  const _BattlePayloadPickerDialog({required this.battles});

  final List<BattlePublicContract> battles;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      key: const ValueKey('scene-battle-picker-dialog'),
      title: const Text('Choisir un combat'),
      content: _PayloadPickerContent(
        children: [
          for (final battle in battles)
            _PayloadPickerOptionButton(
              key: ValueKey(
                'scene-battle-picker-option-${_pickerKeyPart(battle.id)}',
              ),
              title: battle.label,
              subtitle: battle.trainerId,
              details: [
                battle.battleKind.name,
                battle.trainerLabel,
                battle.possibleOutcomes
                    .map((outcome) => outcome.id)
                    .join(' / '),
              ],
              diagnostics: battle.diagnostics,
              onPressed: () => Navigator.of(context).pop(battle),
            ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _PayloadPickerContent extends StatelessWidget {
  const _PayloadPickerContent({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PayloadPickerOptionButton extends StatelessWidget {
  const _PayloadPickerOptionButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.diagnostics,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final List<String> details;
  final List<LinkedAssetContractDiagnostic> diagnostics;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PokeMapCard(
        onTap: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            for (final detail in details.where((value) => value.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            for (final diagnostic in diagnostics)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  diagnostic.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _diagnosticColor(context, diagnostic.severity),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Color _diagnosticColor(
  BuildContext context,
  LinkedAssetContractDiagnosticSeverity severity,
) {
  final colors = context.pokeMapColors;
  return switch (severity) {
    LinkedAssetContractDiagnosticSeverity.error => colors.error,
    LinkedAssetContractDiagnosticSeverity.warning => colors.warning,
    LinkedAssetContractDiagnosticSeverity.info => colors.textMuted,
  };
}

String _pickerKeyPart(String value) {
  final buffer = StringBuffer();
  var wroteSeparator = false;
  for (final codeUnit in value.trim().toLowerCase().codeUnits) {
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    final isAsciiLetter = codeUnit >= 97 && codeUnit <= 122;
    if (isDigit || isAsciiLetter) {
      buffer.writeCharCode(codeUnit);
      wroteSeparator = false;
    } else if (!wroteSeparator && buffer.isNotEmpty) {
      buffer.write('_');
      wroteSeparator = true;
    }
  }
  final slug = buffer.toString();
  return slug.endsWith('_') ? slug.substring(0, slug.length - 1) : slug;
}

class _SceneEdgeDraftToolbar extends StatelessWidget {
  const _SceneEdgeDraftToolbar({
    required this.scene,
    required this.selectedNodeId,
    required this.pendingConnection,
    required this.onStartConnection,
    required this.onCancelConnection,
  });

  final NarrativeSceneSummary scene;
  final String? selectedNodeId;
  final _PendingSceneConnection? pendingConnection;
  final ValueChanged<SceneAuthorableOutputPort> onStartConnection;
  final VoidCallback onCancelConnection;

  @override
  Widget build(BuildContext context) {
    final pending = pendingConnection;
    if (pending != null) {
      return _PendingConnectionBar(
        pending: pending,
        onCancelConnection: onCancelConnection,
      );
    }

    final node = _selectedNode;
    if (node == null) {
      return const SizedBox(
        key: ValueKey('scenes-edge-no-outputs'),
        height: 34,
      );
    }
    final ports = authorableSceneOutputPortsForNodeInGraph(node, scene.graph);
    if (ports.isEmpty) {
      return const _NoOutputPortsBar();
    }

    final usedPorts = {
      for (final edge in scene.graph.edges)
        if (edge.fromNodeId == node.id) edge.fromPortId,
    };
    final colors = context.pokeMapColors;
    return SizedBox(
      key: const ValueKey('scenes-edge-authoring-toolbar'),
      height: 34,
      child: Row(
        children: [
          Text(
            'Connexions',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final port in ports)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: PokeMapButton(
                        key: ValueKey('scenes-connect-port-${port.id}'),
                        onPressed: usedPorts.contains(port.id)
                            ? null
                            : () => onStartConnection(port),
                        variant: usedPorts.contains(port.id)
                            ? PokeMapButtonVariant.ghost
                            : PokeMapButtonVariant.secondary,
                        size: PokeMapButtonSize.small,
                        leading: const Icon(CupertinoIcons.link),
                        child: Text(
                          usedPorts.contains(port.id)
                              ? '${port.label} · connecté'
                              : 'Connecter ${port.label}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SceneNode? get _selectedNode {
    final id = selectedNodeId;
    if (id == null) {
      return null;
    }
    for (final node in scene.graph.nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }
}

class _PendingConnectionBar extends StatelessWidget {
  const _PendingConnectionBar({
    required this.pending,
    required this.onCancelConnection,
  });

  final _PendingSceneConnection pending;
  final VoidCallback onCancelConnection;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return SizedBox(
      key: const ValueKey('scenes-edge-connection-pending'),
      height: 34,
      child: Row(
        children: [
          const Icon(CupertinoIcons.link, size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Connexion en cours depuis '
              '${pending.fromNodeId} / ${pending.fromPortId}. '
              'Cliquez un nœud cible.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PokeMapButton(
            key: const ValueKey('scenes-edge-connection-cancel'),
            onPressed: onCancelConnection,
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}

class _NoOutputPortsBar extends StatelessWidget {
  const _NoOutputPortsBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return SizedBox(
      key: const ValueKey('scenes-edge-no-outputs'),
      height: 34,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Aucune sortie connectable V0.',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _NodeDraftButton extends StatelessWidget {
  const _NodeDraftButton({
    required this.buttonKey,
    required this.label,
    required this.icon,
    this.onPressed,
    this.disabledReason,
  });

  final Key buttonKey;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final reason = disabledReason;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: PokeMapButton(
        key: buttonKey,
        onPressed: onPressed,
        variant: onPressed == null
            ? PokeMapButtonVariant.ghost
            : PokeMapButtonVariant.secondary,
        size: PokeMapButtonSize.small,
        leading: Icon(icon),
        child: Text(reason == null ? label : '$label · $reason'),
      ),
    );
  }
}

class _SceneInspectorEmptyPanel extends StatelessWidget {
  const _SceneInspectorEmptyPanel();

  @override
  Widget build(BuildContext context) {
    return const PokeMapInspectorPanel(
      padding: EdgeInsets.all(12),
      header: Padding(
        padding: EdgeInsets.fromLTRB(12, 11, 12, 9),
        child: Row(
          children: [
            PokeMapIconTile(
              icon: CupertinoIcons.sidebar_right,
              tone: PokeMapTone.narrative,
              size: 30,
              iconSize: 15,
            ),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Détails du nœud',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      child: PokeMapEmptyState(
        icon: Icon(CupertinoIcons.sidebar_right),
        title: 'Aucun nœud',
        description: 'Sélectionnez une scène pour inspecter son graph.',
      ),
    );
  }
}
