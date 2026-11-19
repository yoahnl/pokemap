part of 'spatial_map_editing_viewport.dart';

class _SpatialMapEditingViewportState extends State<SpatialMapEditingViewport> {
  MapExteriorDecorationController? get exterior =>
      widget.document.exteriorDecoration;
  bool get editingExterior => exterior?.editingExterior == true;
  EditableMapDocument get editingDocument => editingExterior
      ? exterior?.editingDocument ?? widget.document
      : widget.document;
  MapExteriorDecorationController? _exteriorNotifier;
  SpatialMapAssetSource? _sceneAssets;

  SpatialMapAssetSource assetsFor(SpatialWorkspaceVisuals visuals) {
    final current = _sceneAssets;
    if (current != null &&
        identical(current.project, widget.project) &&
        identical(current.visuals, visuals)) {
      return current;
    }
    return _sceneAssets = SpatialMapAssetSource(widget.project, visuals);
  }

  void _exteriorChanged() {
    if (_exteriorGestureActive && !editingExterior) {
      _exteriorGestureActive = false;
      _exteriorLastCell = null;
      discardGesture();
      exterior?.cancelGesture();
    }
    if (mounted) setState(() {});
  }

  EnvironmentArea? _exteriorEnvironmentTemplate;

  bool _exteriorGestureActive = false;
  GridPos? _exteriorLastCell;

  final camera = SpatialSceneController(presentationEffectsEnabled: false)
    ..setView(SpatialEditorView.game);
  final focus = FocusNode();
  MapAtmosphereController? _atmosphere;
  ProjectVisualsController? _weatherVisuals;
  void _syncAtmosphere() {
    camera
      ..visualProfile = widget.document.visualProfile
      ..ambiencePreview = widget.view.ambiencePreview;
    final settings = _atmosphere?.current;
    if (settings != null) camera.applyAtmosphereSettings(settings);
  }

  SpatialNpcPreview? preview;
  MapData? previewMap;
  MapCharacterGesture? gesture;
  MapCanvasStroke? terrainStroke;
  _SpatialEnvironmentGesture? environmentGesture;
  MapBorderEraseDraft? borderEraseDraft;
  MapData? borderErasePreview;
  ({double yaw, double pitch, double zoom, Offset pan, SpatialEditorView view})?
  borderEraseCamera;
  bool? borderFreeView;
  Object? borderSession;
  MapBorderDrawingDraft? borderPreviewDraft;
  MapData? borderPreviewMap;
  String? borderPreviewError;
  SpatialTerrainStroke? reliefStroke;
  MapReliefStroke? reliefPaint;
  MapData? terrainSource;
  ProjectManifest? terrainProject;
  StudioMapTool? terrainTool;
  (bool, String, String, SpatialRampDirection, bool)? terrainSurfaceOptions;
  int previewGeneration = 0;
  Object? error;
  (EditableMapDocument, String)? previewProblem;
  SpatialGizmoAxis? gizmoAxis;
  double gizmoStep = 0;
  String? modelGesture;
  GridPos? modelEnd;
  GridPos? modelOrigin;
  Model3dVector3? modelPosition;
  bool? gestureFreeView;
  MapData? contentSource;
  ProjectManifest? contentProject;
  final nudgeKeys = <LogicalKeyboardKey>{};
  final cameraKeys = <LogicalKeyboardKey>{};
  bool get precision => HardwareKeyboard.instance.isShiftPressed;
  SpatialSurfaceHit? hover;
  MapData? hoverMap;
  ProjectManifest? hoverProject;
  StudioMapTool? hoverTool;
  String? hoverModelId;
  SpatialTerrainMode? hoverMode;

  void updateHover(SpatialSurfaceHit? hit) {
    if (!mounted) return;
    recordPointer(hit);
    if (hit != null && !textEditing) focus.requestFocus();
    if (hover?.cell == hit?.cell && hover?.position == hit?.position) return;
    setState(() {
      hover = showsHover ? hit : null;
      hoverMap = editingDocument.current;
      hoverProject = widget.project;
      hoverTool = widget.view.tool;
      hoverModelId = widget.view.model3d?.id;
      hoverMode = widget.view.spatialTerrainMode;
      if (widget.view.tool == StudioMapTool.border && borderContextValid) {
        widget.view.borderDraft = widget.view.borderDraft?.pointAt(
          hit == null
              ? null
              : borderPointForCell(GridPos(x: hit.cell.$1, y: hit.cell.$2)),
        );
      }
    });
    if (widget.view.tool == StudioMapTool.border) widget.onChanged();
  }

  MapCanvasReadiness? _readiness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _readiness = MapCanvasReadinessScope.maybeOf(context)?..claim();
  }

  @override
  void initState() {
    super.initState();
    widget.view.spatialSceneController = camera;
    _bindAtmosphere();
    _bindExterior();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(claimOpeningFocus);
      if (mounted && identical(widget.view.spatialSceneController, camera)) {
        widget.onChanged();
      }
    });
    widget.view.transform.addListener(syncZoom);
    widget.view.recenter = recenter;
    widget.view.centerOn = centerOnCell;
    syncZoom();
    syncCameraView();
  }

  @override
  void didUpdateWidget(SpatialMapEditingViewport old) {
    super.didUpdateWidget(old);
    _bindAtmosphere();
    _bindExterior();
    if (!identical(old.view, widget.view)) {
      if (identical(old.view.spatialSceneController, camera)) {
        old.view.spatialSceneController = null;
      }
      widget.view.spatialSceneController = camera;
    }
    if (old.document.base.mapId != widget.document.base.mapId) {
      widget.view.spatialAnimations.clear();
    }
    if (old.project != widget.project || old.visuals != widget.visuals) {
      previewMap = null;
    }
    if (hoverMap != editingDocument.current ||
        hoverProject != widget.project ||
        hoverTool != widget.view.tool ||
        hoverModelId != widget.view.model3d?.id ||
        hoverMode != widget.view.spatialTerrainMode ||
        !showsHover) {
      hover = null;
    }
    syncCameraView();
    if (contentSource != null && !contentGestureValid) discardGesture();
    if (terrainSource != null && !terrainGestureValid) discardGesture();
    if (environmentGesture != null && !environmentGestureValid) {
      discardGesture();
    }
    widget.view.focusBorderDraftOn(editingDocument.current.id);
    if (widget.view.borderDraft != null && !borderContextValid) {
      discardBorder();
    }
    if ((borderEraseDraft != null || exteriorBorderEraseActive) &&
        !borderEraseContextValid) {
      discardBorder();
    }
    if (widget.view.borderPreview?.validFor(
          editingDocument.current,
          widget.project,
        ) ==
        false) {
      widget.view.borderPreview = null;
    }
    if (widget.view.rampPreview?.validFor(editingDocument.current) == false) {
      widget.view.rampPreview = null;
    }
    if (widget.view.terrainSurfacePreview?.validFor(editingDocument.current) ==
        false) {
      widget.view.terrainSurfacePreview = null;
    }
  }

  void syncZoom() =>
      camera.dolly(math.log(1 / widget.view.scale / camera.zoom) * 1000);
  void centerOnCell(GridPos cell) {
    final scene = widget.document.current.spatialScene;
    if (scene == null) return;
    camera.panBy(
      cell.x + .5 - scene.width / 2 - camera.pan.dx,
      cell.y + .5 - scene.depth / 2 - camera.pan.dy,
    );
  }

  Future<void> updatePreview(SpatialWorkspaceVisuals visuals) async {
    final map = editingExterior
        ? widget.document.current
        : editingDocument.spatialPreviewMap;
    if (identical(previewMap, map)) return;
    final previous = previewMap;
    if (previous != null && _previewOrderOnlyChange(previous, map)) {
      previewMap = map;
      return;
    }
    previewMap = map;
    final generation = ++previewGeneration;
    if (map.entities.isEmpty) {
      preview?.dispose();
      preview = null;
      clearPreviewProblem();
      return;
    }
    try {
      final loaded = await visuals.spatialPreview(map, widget.project);
      if (!mounted || generation != previewGeneration) {
        loaded.dispose();
        return;
      }
      final previous = preview;
      setState(() {
        preview = loaded;
        error = null;
      });
      previous?.dispose();
      clearPreviewProblem();
    } on Object catch (failure) {
      if (mounted && generation == previewGeneration) {
        setState(() => error = failure);
        reportPreviewProblem(failure);
      }
    }
  }

  KeyEventResult onKey(KeyEvent event) {
    if (editingExterior && exterior?.editingDocument == null) {
      return KeyEventResult.ignored;
    }
    if (textEditing) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      setState(() {});
      return KeyEventResult.ignored;
    }
    return handleKey(event, key);
  }

  @override
  void dispose() {
    _weatherVisuals?.removeListener(_syncAtmosphere);
    _atmosphere?.removeListener(_syncAtmosphere);
    _exteriorNotifier?.removeListener(_exteriorChanged);
    previewGeneration++;
    preview?.dispose();
    widget.view.transform.removeListener(syncZoom);
    if (widget.view.centerOn == centerOnCell) widget.view.centerOn = null;
    widget.view.recenter = null;
    focus.dispose();
    camera.dispose();
    if (identical(widget.view.spatialSceneController, camera)) {
      widget.view.spatialSceneController = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.view.reconcileLocks(editingDocument);
    if (contentSource != null && !contentGestureValid) discardGesture();
    final visuals = widget.visuals;
    if (visuals is! SpatialWorkspaceVisuals) {
      return const Center(child: Text('3D viewport unavailable'));
    }
    updatePreview(visuals as SpatialWorkspaceVisuals);
    return Focus(
      focusNode: focus,
      onKeyEvent: (_, event) => onKey(event),
      onFocusChange: (focused) {
        if (!focused) cameraKeys.clear();
        setState(() {});
        if (!focused && nudgeKeys.isNotEmpty) cancel();
      },
      child: Stack(
        children: [
          Positioned.fill(child: sceneView(visuals)),
          if (gizmoOverlay(context) case final gizmo?)
            Positioned.fill(child: gizmo),
        ],
      ),
    );
  }
}
