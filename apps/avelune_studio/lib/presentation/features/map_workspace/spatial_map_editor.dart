import '../../../features/project_visuals/application/project_visuals_controller.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../features/map_workspace/application/map_atmosphere_controller.dart';
import '../../../features/map_workspace/application/map_exterior_decoration_controller.dart';

import 'dart:math' as math;

import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../../features/map_workspace/application/spatial_model_editing_commands.dart';
import '../../../features/map_workspace/application/map_border_editing_commands.dart';
import '../../../features/map_workspace/application/map_border_drawing_draft.dart';
import '../../../features/map_workspace/application/spatial_terrain_stroke.dart';
import '../../../features/map_workspace/application/spatial_terrain_surface_editing_commands.dart';
import '../../../features/map_workspace/application/environment_editing_commands.dart';
import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_editing_commands.dart';
import '../../../features/map_workspace/application/map_workspace_controller.dart';
import 'map_character_gesture.dart';
import 'map_canvas_stroke.dart';
import 'map_encounter_cell_stroke.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
part 'spatial_map_editor_guidance.dart';
part 'spatial_environment_gesture.dart';
part 'spatial_border_gesture.dart';

class SpatialMapEditor extends StatefulWidget {
  const SpatialMapEditor({
    super.key,
    required this.document,
    required this.controller,
    required this.project,
    required this.visuals,
    required this.view,
    required this.onChanged,
    this.onContextMenu,
    this.neighbors = const [],
    this.neighborDecorations = const [],
    this.exteriorContextReady = true,
  });
  final EditableMapDocument document;
  final List<SpatialSceneNeighbor> neighbors;
  final List<SpatialSceneDecoration> neighborDecorations;
  final bool exteriorContextReady;
  final MapWorkspaceController controller;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final void Function(GridPos, Offset)? onContextMenu;
  @override
  State<SpatialMapEditor> createState() => _SpatialMapEditorState();
}

class _SpatialMapEditorState extends State<SpatialMapEditor> {
  MapExteriorDecorationController? get exterior =>
      widget.document.exteriorDecoration;
  bool get editingExterior => exterior?.editingExterior == true;
  EditableMapDocument get editingDocument => editingExterior
      ? exterior?.editingDocument ?? widget.document
      : widget.document;
  ChangeNotifier? _exteriorNotifier;

  void _bindExterior() {
    final next = exterior;
    if (identical(next, _exteriorNotifier)) return;
    _exteriorNotifier?.removeListener(_exteriorChanged);
    _exteriorNotifier = next;
    _exteriorNotifier?.addListener(_exteriorChanged);
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

  SpatialSceneAuthoringTarget? get authoringTarget {
    final controller = exterior;
    final child = controller?.editingDocument;
    if (!editingExterior || child == null) return null;
    return SpatialSceneAuthoringTarget(
      map: child.current,
      offset: Offset(
        controller!.originX.toDouble(),
        controller.originZ.toDouble(),
      ),
      decorationKey:
          'exterior:${widget.document.current.id}:${controller.selectedSectorId}',
    );
  }

  EnvironmentArea? _exteriorEnvironmentTemplate;
  void _bindExteriorEnvironment({required bool create}) {
    if (!editingExterior || widget.view.tool != StudioMapTool.environment) {
      return;
    }
    final commands = EnvironmentEditingCommands(
      editingDocument,
      widget.project,
    );
    final session = widget.view.environment;
    final armedPresetId = widget.view.exteriorEnvironmentPresetId;
    final current = session == null ? null : commands.area(session);
    if (current == null &&
        armedPresetId != null &&
        _exteriorEnvironmentTemplate?.presetId != armedPresetId) {
      _exteriorEnvironmentTemplate = null;
      if (!create) return;
      final preset = widget.project.environmentPresets
          .where((preset) => preset.id == armedPresetId)
          .firstOrNull;
      if (preset == null) return;
      final created = commands.create(preset);
      widget.view.environment = created;
      _exteriorEnvironmentTemplate = commands.area(created);
      return;
    }
    if (current != null) {
      _exteriorEnvironmentTemplate = current;
      return;
    }
    final area = _exteriorEnvironmentTemplate;
    if (area == null) return;
    final existing = commands.areas
        .where(
          (entry) =>
              entry.area.presetId == area.presetId &&
              entry.area.seed == area.seed &&
              entry.area.paramsOverride == area.paramsOverride,
        )
        .firstOrNull;
    if (existing == null && !create) return;
    final next = existing == null
        ? commands.create(
            widget.project.environmentPresets.firstWhere(
              (preset) => preset.id == area.presetId,
            ),
          )
        : MapEnvironmentSession(
            layerId: existing.layer.id,
            areaId: existing.area.id,
          );
    if (existing == null) {
      editingDocument.commit(
        const EnvironmentEditing().updateArea(
          editingDocument.current,
          manifest: widget.project,
          layerId: next.layerId,
          areaId: next.areaId,
          seed: area.seed,
          paramsOverride: area.paramsOverride,
        ),
      );
    }
    next.tool = session?.tool ?? EnvironmentPaintTool.brush;
    widget.view.environment = next;
  }

  bool _exteriorGestureActive = false;
  GridPos? _exteriorLastCell;

  Iterable<ExteriorDecorationRect> get _neighborBounds => [
    for (final neighbor in widget.neighbors)
      ExteriorDecorationRect(
        x: neighbor.offset.dx.round(),
        z: neighbor.offset.dy.round(),
        width: neighbor.map.size.width,
        depth: neighbor.map.size.height,
      ),
  ];

  bool get _continuousExteriorStroke =>
      terrainStroke != null ||
      reliefStroke != null ||
      environmentGesture != null &&
          environmentGesture!.tool != EnvironmentPaintTool.rectangle;

  void _continueExteriorStroke(int x, int z) {
    final controller = exterior!;
    final definition = controller.current!;
    final last = _exteriorLastCell;
    if (last == null || last.x == x && last.y == z) return;
    final bounds = definition.outerBounds;
    final path = MapEncounterCellStroke(
      GridSize(width: bounds.width, height: bounds.depth),
      false,
      GridPos(x: last.x - bounds.x, y: last.y - bounds.z),
    )..paint(GridPos(x: x - bounds.x, y: z - bounds.z));
    for (final point in path.cells.skip(1)) {
      final logical = GridPos(x: point.x + bounds.x, y: point.y + bounds.z);
      final current = authoringTarget;
      if (current == null) return;
      var localX = logical.x - controller.originX,
          localZ = logical.y - controller.originZ;
      if (localX < 0 ||
          localZ < 0 ||
          localX >= current.map.size.width ||
          localZ >= current.map.size.height) {
        if (definition.isExcluded(
          logical.x,
          logical.y,
          neighborBounds: _neighborBounds,
        )) {
          return;
        }
        final session = widget.view.environment;
        final area = session == null
            ? null
            : EnvironmentEditingCommands(
                editingDocument,
                widget.project,
              ).area(session);
        finishSegment();
        if (!_exteriorGestureActive ||
            !controller.selectAt(
              logical.x,
              logical.y,
              neighborBounds: _neighborBounds,
            )) {
          return;
        }
        if (area != null) _exteriorEnvironmentTemplate = area;
        _bindExteriorEnvironment(create: true);
        localX = logical.x - controller.originX;
        localZ = logical.y - controller.originZ;
        if (!_startSegment(localX, localZ)) return;
      } else {
        updateDrag((localX, localZ));
      }
      _exteriorLastCell = logical;
    }
  }

  SpatialSceneAuthoringTarget? resolveAuthoringTarget(int x, int z) {
    final controller = exterior;
    if (!editingExterior || controller == null || !widget.exteriorContextReady) {
      return null;
    }
    final activeGesture =
        terrainStroke != null ||
        reliefStroke != null ||
        environmentGesture != null ||
        (borderEraseDraft != null || exteriorBorderEraseActive) ||
        gesture != null ||
        modelGesture != null ||
        widget.view.borderDraft != null;
    final target = authoringTarget;
    final environment = widget.view.environment;
    if (environment != null) {
      final area = EnvironmentEditingCommands(
        editingDocument,
        widget.project,
      ).area(environment);
      if (area != null) _exteriorEnvironmentTemplate = area;
    }
    if (_exteriorGestureActive && _continuousExteriorStroke) {
      _continueExteriorStroke(x, z);
      final selected = authoringTarget;
      return selected != null &&
              selected.map.spatialScene != null &&
              x >= controller.originX &&
              z >= controller.originZ &&
              x < controller.originX + selected.map.size.width &&
              z < controller.originZ + selected.map.size.height
          ? selected
          : null;
    }
    if (activeGesture &&
        target != null &&
        !(widget.view.tool == StudioMapTool.border)) {
      final localX = x - controller.originX, localZ = z - controller.originZ;
      return localX >= 0 &&
              localZ >= 0 &&
              localX < target.map.size.width &&
              localZ < target.map.size.height
          ? target
          : null;
    }
    if (!controller.selectAt(x, z, neighborBounds: _neighborBounds)) {
      return null;
    }
    _bindExteriorEnvironment(create: false);
    return authoringTarget;
  }

  List<SpatialSceneDecoration> decorationVisuals(
    SpatialWorkspaceVisuals visuals,
    MapData? preview,
  ) {
    final controller = exterior;
    var decoration = controller?.current;
    if (decoration == null) return widget.neighborDecorations;
    if (editingExterior &&
        preview != null &&
        controller?.selectedSectorId != null) {
      decoration = MapExteriorDecoration(
        mapId: decoration.mapId,
        playableWidth: decoration.playableWidth,
        playableDepth: decoration.playableDepth,
        west: decoration.west,
        east: decoration.east,
        north: decoration.north,
        south: decoration.south,
        borders: decoration.borders,
        sectors: [
          for (final sector in decoration.sectors)
            if (sector.id == controller!.selectedSectorId)
              ExteriorDecorationSector(
                id: sector.id,
                originX: sector.originX,
                originZ: sector.originZ,
                scene: preview.spatialScene!,
                layers: preview.layers,
              )
            else
              sector,
        ],
      );
    }
    decoration = withExteriorBorderPreview(decoration);
    return [
      ...widget.neighborDecorations,
      SpatialSceneDecoration(
        ownerMapId: widget.document.current.id,
        decoration: decoration,
        offset: Offset.zero,
        project: widget.project,
        loadGroundImage: visuals.readGroundImage,
        loadModel: visuals.readModel,
      ),
    ];
  }

  final camera = SpatialSceneController()..setView(SpatialEditorView.game);
  final focus = FocusNode();
  MapAtmosphereController? _atmosphere;
  void _syncAtmosphere() {
    camera.visualProfile = widget.document.visualProfile;
    final settings = _atmosphere?.current;
    if (settings != null) camera.applyAtmosphereSettings(settings);
  }

  void _bindAtmosphere() {
    final next = widget.document.atmosphere;
    if (identical(next, _atmosphere)) {
      _syncAtmosphere();
      return;
    }
    _atmosphere?.removeListener(_syncAtmosphere);
    _atmosphere = next;
    _atmosphere?.addListener(_syncAtmosphere);
    _syncAtmosphere();
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
  MapData? terrainSource;
  ProjectManifest? terrainProject;
  StudioMapTool? terrainTool;
  (bool, String, String, SpatialRampDirection, bool)? terrainSurfaceOptions;
  int previewGeneration = 0;
  Object? error;
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
  bool get showsHover =>
      !locked &&
      {
        StudioMapTool.place,
        StudioMapTool.terrain,
        StudioMapTool.erase,
        StudioMapTool.collisionPaint,
        StudioMapTool.collisionErase,
        StudioMapTool.environment,
        StudioMapTool.border,
      }.contains(widget.view.tool);

  Model3dVector3 positionFor(SpatialSurfaceHit hit) {
    final scene = editingDocument.current.spatialScene!;
    final x = precision
        ? hit.position.x.clamp(0.0, scene.width - .000001)
        : hit.cell.$1 + .5;
    final z = precision
        ? hit.position.z.clamp(0.0, scene.depth - .000001)
        : hit.cell.$2 + .5;
    return Model3dVector3(x: x, y: scene.worldHeightAt(x, z), z: z);
  }

  SpatialModelPlacementPreview? get placementPreview {
    final model = widget.view.model3d;
    if (!showsHover ||
        hover == null ||
        widget.view.tool != StudioMapTool.place ||
        model == null ||
        !widget.project.models3d.any((item) => item.id == model.id)) {
      return null;
    }
    return SpatialModelPlacementPreview(
      modelId: model.id,
      position: positionFor(hover!),
    );
  }

  bool get textEditing =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>() !=
      null;

  void updateHover(SpatialSurfaceHit? hit) {
    if (!mounted) return;
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

  void surfaceTap(SpatialSurfaceHit hit) {
    if (locked) return;
    if (selectingTerrainSurface) {
      selectTerrainSurfaceAt(hit.position.x, hit.position.z);
      return;
    }
    if (widget.view.tool != StudioMapTool.place ||
        widget.view.model3d == null) {
      tap(hit.cell.$1, hit.cell.$2);
      return;
    }
    focus.requestFocus();
    try {
      final item = SpatialModelEditingCommands(
        editingDocument,
        widget.project,
      ).placeAt(widget.view.model3d!, positionFor(hit));
      widget.view.select(editingDocument, MapSelectionFamily.decor, item.id);
    } on Object catch (failure) {
      editingDocument.error = failure.toString();
    }
    hover = null;
    widget.onChanged();
  }

  bool get locked =>
      editingExterior && !widget.exteriorContextReady ||
      exterior?.saving == true ||
      editingDocument.saving ||
      widget.controller.catalogLocks(editingDocument.base.mapId);
  bool get selectingTerrainSurface =>
      widget.view.tool == StudioMapTool.terrain &&
      widget.view.spatialTerrainMode == SpatialTerrainMode.relief &&
      widget.view.spatialContinuousTerrain &&
      widget.view.spatialSurfaceSelect;

  void selectTerrainSurfaceAt(double x, double z) {
    SpatialTerrainSurface? selected;
    for (final surface
        in editingDocument.current.spatialScene!.terrainSurfaces.surfaces) {
      if (surface.contains(x, z) &&
          (selected == null ||
              surface.heightAt(x, z) >= selected.heightAt(x, z))) {
        selected = surface;
      }
    }
    widget.view.spatialSurfaceId = selected?.id;
    widget.view.terrainSurfacePreview = null;
    widget.onChanged();
  }

  @override
  void initState() {
    super.initState();
    widget.view.spatialSceneController = camera;
    _bindAtmosphere();
    _bindExterior();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(widget.view.spatialSceneController, camera)) {
        widget.onChanged();
      }
    });
    widget.view.transform.addListener(syncZoom);
    widget.view.recenter = recenter;
    syncZoom();
    syncCameraView();
  }

  bool get contentGestureValid =>
      !locked &&
      (modelGesture == null ||
          !editingDocument.isElementUnavailable('model', modelGesture!)) &&
      gesture?.isLocked != true &&
      widget.view.tool == StudioMapTool.select &&
      gestureFreeView == widget.view.spatialFreeView &&
      identical(contentSource, editingDocument.current) &&
      identical(contentProject, widget.project);

  bool get terrainGestureValid =>
      !locked &&
      terrainTool == widget.view.tool &&
      gestureFreeView == widget.view.spatialFreeView &&
      identical(terrainSource, editingDocument.current) &&
      identical(terrainProject, widget.project) &&
      (!widget.view.spatialSurfaceSelect ||
          reliefStroke?.surfaceBrush == null) &&
      (terrainSurfaceOptions == null ||
          terrainSurfaceOptions == widget.view.terrainSurfaceOptions) &&
      (terrainStroke == null || terrainStroke!.matches(widget.view)) &&
      (reliefStroke == null ||
          reliefStroke!.mode == widget.view.spatialTerrainMode &&
              reliefStroke!.level == widget.view.spatialTerrainLevel);

  SpatialSceneContentPreview? get contentPreview {
    if (!contentGestureValid) return null;
    final scene = editingDocument.current.spatialScene!;
    if (modelGesture != null && modelEnd != null) {
      final x = modelPosition!.x + modelEnd!.x - modelOrigin!.x;
      final z = modelPosition!.z + modelEnd!.y - modelOrigin!.y;
      return SpatialSceneContentPreview(
        kind: SpatialSceneContentKind.model,
        id: modelGesture!,
        position: Model3dVector3(
          x: x,
          y:
              scene.worldHeightAt(x, z) +
              modelPosition!.y -
              scene.worldHeightAt(modelPosition!.x, modelPosition!.z),
          z: z,
        ),
      );
    }
    final entity = gesture?.entity;
    final destination = gesture?.destination;
    if (entity == null ||
        entity.kind != MapEntityKind.npc ||
        destination == null) {
      return null;
    }
    final x = destination.x + .5, z = destination.y + .5;
    return SpatialSceneContentPreview(
      kind: SpatialSceneContentKind.actor,
      id: 'npc:${entity.id}',
      position: Model3dVector3(x: x, y: scene.worldHeightAt(x, z), z: z),
    );
  }

  @override
  void didUpdateWidget(SpatialMapEditor old) {
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

  void syncCameraView({bool preserveGesture = false}) {
    final next = widget.view.spatialFreeView
        ? SpatialEditorView.orbit
        : SpatialEditorView.game;
    if (camera.view == next) return;
    if (preserveGesture) {
      if (gestureFreeView != null) {
        gestureFreeView = widget.view.spatialFreeView;
      }
    } else {
      discardGesture();
      discardBorder();
    }
    if (next == SpatialEditorView.orbit) {
      final profile = widget.document.current.spatialScene!.camera;
      camera.yaw = profile.yawDegrees * math.pi / 180;
      camera.pitch = profile.pitchDegrees * math.pi / 180;
    }
    camera.setView(next);
  }

  void syncZoom() =>
      camera.dolly(math.log(1 / widget.view.scale / camera.zoom) * 1000);
  void recenter() {
    discardGesture();
    widget.view.spatialFreeView = false;
    widget.view.transform.value = Matrix4.identity();
    camera.reset();
    camera.setView(SpatialEditorView.game);
    widget.onChanged();
  }

  Future<void> updatePreview(SpatialWorkspaceVisuals visuals) async {
    final map = editingExterior
        ? widget.document.current
        : editingDocument.current;
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
      return;
    }
    try {
      final loaded = await visuals.spatialPreview(map);
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
    } on Object catch (failure) {
      if (mounted && generation == previewGeneration) {
        setState(() {
          error = failure;
          editingDocument.error =
              'Aperçu des personnages indisponible : $failure';
        });
        widget.onChanged();
      }
    }
  }

  bool canSelectContent(SpatialSceneContentKind kind, String id) {
    return !editingDocument.isElementUnavailable(
      switch (kind) {
        SpatialSceneContentKind.model => 'model',
        SpatialSceneContentKind.actor ||
        SpatialSceneContentKind.marker => 'entity',
        SpatialSceneContentKind.warp => 'warp',
      },
      kind == SpatialSceneContentKind.actor && id.startsWith('npc:')
          ? id.substring(4)
          : id,
    );
  }

  SpatialSceneVisibility get sceneVisibility => _visibilityFor(editingDocument);

  SpatialSceneVisibility _visibilityFor(EditableMapDocument document) {
    final state = document.editorState;
    final content = <(SpatialSceneContentKind, String)>{};
    final layers = <String>{};
    final kinds = <SpatialSceneContentKind>{};
    for (final family in state.hiddenFamilies) {
      switch (family) {
        case 'model':
          kinds.add(SpatialSceneContentKind.model);
        case 'entity':
          kinds.addAll([
            SpatialSceneContentKind.actor,
            SpatialSceneContentKind.marker,
          ]);
        case 'warp':
          kinds.add(SpatialSceneContentKind.warp);
      }
    }
    for (final key in state.hiddenElements) {
      final separator = key.indexOf(':');
      final kind = key.substring(0, separator);
      final id = key.substring(separator + 1);
      switch (kind) {
        case 'model':
          content.add((SpatialSceneContentKind.model, id));
        case 'entity':
          content.add((SpatialSceneContentKind.actor, 'npc:$id'));
          content.add((SpatialSceneContentKind.marker, id));
        case 'warp':
          content.add((SpatialSceneContentKind.warp, id));
        case 'layer':
          layers.add(id);
      }
    }
    final allLayers = state.hiddenFamilies.contains('layer');
    for (final layerId
        in allLayers
            ? document.current.layers.map((layer) => layer.id)
            : layers) {
      for (final id in document.elementIdsInLayer('model', layerId)) {
        content.add((SpatialSceneContentKind.model, id));
      }
    }
    return SpatialSceneVisibility(
      hiddenContent: content,
      hiddenKinds: kinds,
      hiddenLayers: layers,
      allLayersHidden: allLayers,
    );
  }

  bool start(int x, int z, [SpatialSceneContentHit? hit]) {
    if (editingExterior &&
        {
          StudioMapTool.character,
          StudioMapTool.warp,
          StudioMapTool.connection,
          StudioMapTool.spawn,
          StudioMapTool.sign,
          StudioMapTool.fieldObstacle,
          StudioMapTool.zone,
          StudioMapTool.gameplayZone,
          StudioMapTool.encounterPaint,
          StudioMapTool.encounterErase,
          StudioMapTool.collisionPaint,
          StudioMapTool.collisionErase,
        }.contains(widget.view.tool)) {
      widget.document.error =
          'Le décor extérieur accepte uniquement les outils visuels.';
      widget.onChanged();
      return false;
    }
    if (editingExterior && !_exteriorGestureActive) {
      exterior!.beginGesture();
      _exteriorGestureActive = true;
      _exteriorLastCell = GridPos(
        x: x + exterior!.originX,
        y: z + exterior!.originZ,
      );
    }
    final started = _startSegment(x, z, hit);
    if (!started && _exteriorGestureActive) {
      exterior!.endGesture();
      _exteriorGestureActive = false;
      _exteriorLastCell = null;
    }
    return started;
  }

  bool _startSegment(int x, int z, [SpatialSceneContentHit? hit]) {
    if (_exteriorGestureActive) _bindExteriorEnvironment(create: true);
    widget.view.reconcileLocks(editingDocument);
    if (hit != null && !canSelectContent(hit.kind, hit.id)) {
      discardGesture();
      widget.onChanged();
      return false;
    }
    if (locked ||
        (widget.view.spatialFreeView &&
            widget.view.tool == StudioMapTool.select &&
            hit == null) ||
        widget.view.tool == StudioMapTool.pan) {
      return false;
    }
    widget.view.rampPreview = null;
    widget.view.terrainSurfacePreview = null;
    if (selectingTerrainSurface) {
      selectTerrainSurfaceAt(x + .5, z + .5);
      return false;
    }
    if (widget.view.tool == StudioMapTool.border) {
      if (widget.view.borderEditingMode == BorderStrokeEditingMode.erase) {
        return startBorderErase(GridPos(x: x, y: z));
      }
      addBorderAngle(GridPos(x: x, y: z));
      return false;
    }
    final armedMove = widget.view.pendingMove;
    if ((hit?.kind == SpatialSceneContentKind.model &&
                hit!.id.startsWith('smt_') ||
            armedMove?.id.startsWith('smt_') == true) &&
        {
          StudioMapTool.select,
          StudioMapTool.eraseDecor,
        }.contains(widget.view.tool)) {
      discardGesture();
      editingDocument.error = SpatialModelEditingCommands.paintedTerrainMessage;
      widget.onChanged();
      return false;
    }
    discardGesture();
    widget.view.pendingMove = armedMove;
    focus.requestFocus();
    gestureFreeView = widget.view.spatialFreeView;
    final document = editingDocument;
    final cell = GridPos(x: x, y: z);
    final commands = SpatialModelEditingCommands(document, widget.project);
    try {
      if (widget.view.tool == StudioMapTool.environment) {
        return startEnvironment(cell);
      }
      if (widget.view.tool == StudioMapTool.terrain ||
          widget.view.tool == StudioMapTool.erase ||
          widget.view.tool == StudioMapTool.collisionPaint ||
          widget.view.tool == StudioMapTool.collisionErase) {
        final collision =
            widget.view.tool == StudioMapTool.collisionPaint ||
            widget.view.tool == StudioMapTool.collisionErase;
        if (!collision &&
            widget.view.spatialTerrainMode != SpatialTerrainMode.ground) {
          reliefStroke = SpatialTerrainStroke(
            source: document.current,
            models: widget.project.models3d,
            mode: widget.view.spatialTerrainMode,
            level: widget.view.spatialTerrainLevel,
            erase: widget.view.tool == StudioMapTool.erase,
            origin: cell,
            reanchorInstances: widget.view.spatialSurfaceReanchorInstances,
            surfaceBrush:
                widget.view.spatialTerrainMode == SpatialTerrainMode.relief &&
                    widget.view.spatialContinuousTerrain
                ? widget.view.tool == StudioMapTool.erase
                      ? const SpatialTerrainSurfaceBrush(
                          lowLevel: 0,
                          highLevel: 0,
                          direction: SpatialRampDirection.north,
                        )
                      : SpatialTerrainSurfaceBrush.parse(
                          lowLevel: widget.view.spatialSurfaceLowLevel,
                          highLevel: widget.view.spatialSurfaceHighLevel,
                          direction: widget.view.spatialSurfaceDirection,
                        )
                : null,
          );
          terrainSurfaceOptions = widget.view.terrainSurfaceOptions;
          terrainSource = document.current;
          terrainProject = widget.project;
          terrainTool = widget.view.tool;
          document.error = reliefStroke!.error;
          widget.onChanged();
          return true;
        }
        terrainStroke = MapCanvasStroke.start(
          map: document.current,
          project: widget.project,
          view: widget.view,
          commands: MapEditingCommands(document, widget.project),
          origin: cell,
        );
        terrainSource = terrainStroke == null ? null : document.current;
        terrainProject = terrainStroke == null ? null : widget.project;
        terrainTool = terrainStroke == null ? null : widget.view.tool;
        widget.onChanged();
        return terrainStroke != null;
      }
      if (widget.view.tool == StudioMapTool.place &&
          widget.view.model3d != null) {
        final item = commands.place(widget.view.model3d!, cell);
        widget.view.select(document, MapSelectionFamily.decor, item.id);
        widget.onChanged();
        return true;
      }
      final armed = widget.view.pendingMove;
      final instance = armed != null
          ? (armed.family == MapSelectionFamily.decor
                ? commands.selected(armed.id)
                : null)
          : hit?.kind == SpatialSceneContentKind.model
          ? commands.selected(hit!.id)
          : hit != null
          ? null
          : document.current.spatialScene!.instances
                .where(
                  (item) =>
                      item.position.x.floor() == x &&
                      item.position.z.floor() == z &&
                      !document.isElementUnavailable('model', item.id),
                )
                .lastOrNull;
      if (instance != null &&
          !document.isElementUnavailable('model', instance.id) &&
          {
            StudioMapTool.select,
            StudioMapTool.erase,
            StudioMapTool.eraseDecor,
          }.contains(widget.view.tool)) {
        final borderOwner = commands.borderOwner(instance.id);
        if (borderOwner != null) {
          widget.view.borderFeature = borderOwner;
          document.error = SpatialModelEditingCommands.generatedBorderMessage;
          widget.onChanged();
          return false;
        }
        if (widget.view.tool != StudioMapTool.select) {
          commands.delete(instance.id);
        } else {
          widget.view.select(document, MapSelectionFamily.decor, instance.id);
          document.stackPosition = cell;
          modelGesture = instance.id;
          modelEnd = null;
          modelOrigin = cell;
          modelPosition = instance.position;
          contentSource = document.current;
          contentProject = widget.project;
        }
        widget.onChanged();
        return true;
      }
      if (!{
        StudioMapTool.select,
        StudioMapTool.character,
        StudioMapTool.spawn,
        StudioMapTool.warp,
        StudioMapTool.eraseDecor,
      }.contains(widget.view.tool)) {
        document.error = 'Cet outil ne s’applique pas aux décors et personnages de cette carte 3D.';
        widget.onChanged();
        return false;
      }
    } on Object catch (failure) {
      document.error = failure.toString();
      widget.onChanged();
      return false;
    }
    if (widget.view.pendingMove == null &&
        hit?.kind == SpatialSceneContentKind.actor &&
        hit!.id.startsWith('npc:') &&
        widget.view.tool == StudioMapTool.select) {
      final entity = document.current.entities
          .where((entity) => entity.id == hit.id.substring(4))
          .firstOrNull;
      if (entity == null || entity.pos.x != x || entity.pos.y != z) {
        return false;
      }
      widget.view.select(document, MapSelectionFamily.character, entity.id);
    }
    if (widget.view.pendingMove == null &&
        hit != null &&
        widget.view.tool == StudioMapTool.select &&
        (hit.kind == SpatialSceneContentKind.marker ||
            hit.kind == SpatialSceneContentKind.warp)) {
      final family = hit.kind == SpatialSceneContentKind.marker
          ? MapSelectionFamily.marker
          : MapSelectionFamily.warp;
      widget.view.select(document, family, hit.id);
      widget.view.pendingMove = MapSelectionTarget(
        mapId: document.current.id,
        family: family,
        id: hit.id,
      );
    }
    gesture = MapCharacterGesture.start(
      document: editingDocument,
      project: widget.project,
      view: widget.view,
      origin: GridPos(x: x, y: z),
    );
    if ((gesture?.entity != null || gesture?.warp != null) &&
        widget.view.tool == StudioMapTool.select) {
      contentSource = document.current;
      contentProject = widget.project;
    }
    widget.onChanged();
    return gesture != null;
  }

  void discardGesture() {
    contentSource = null;
    contentProject = null;
    nudgeKeys.clear();
    gestureFreeView = null;
    terrainStroke = null;
    environmentGesture = null;
    reliefStroke = null;
    terrainSource = null;
    terrainProject = null;
    terrainTool = null;
    terrainSurfaceOptions = null;
    gesture = null;
    modelGesture = null;
    modelEnd = null;
    modelOrigin = null;
    modelPosition = null;
    widget.view.pendingMove = null;
  }

  void cancel() {
    if (_exteriorGestureActive) exterior?.cancelGesture();
    _exteriorGestureActive = false;
    _exteriorLastCell = null;
    discardGesture();
    if (widget.view.tool == StudioMapTool.border) discardBorder();
    widget.onChanged();
  }

  void finish() {
    finishSegment();
    if (_exteriorGestureActive) exterior?.endGesture();
    _exteriorGestureActive = false;
    _exteriorLastCell = null;
  }

  void finishSegment() {
    if (borderEraseDraft != null || exteriorBorderEraseActive) {
      finishBorderErase();
      return;
    }
    if (locked ||
        (contentSource != null && !contentGestureValid) ||
        (terrainSource != null && !terrainGestureValid) ||
        (environmentGesture != null && !environmentGestureValid) ||
        (gestureFreeView != null &&
            gestureFreeView != widget.view.spatialFreeView)) {
      cancel();
      return;
    }
    if (environmentGesture != null) {
      finishEnvironment();
      return;
    }
    gestureFreeView = null;
    contentSource = null;
    contentProject = null;
    nudgeKeys.clear();
    final stroke = terrainStroke;
    final relief = reliefStroke;
    final source = terrainSource;
    final tool = terrainTool;
    terrainStroke = null;
    reliefStroke = null;
    terrainSource = null;
    terrainProject = null;
    terrainTool = null;
    terrainSurfaceOptions = null;
    if (stroke != null || relief != null) {
      if (!locked &&
          identical(editingDocument.current, source) &&
          widget.view.tool == tool &&
          (relief == null ||
              relief.mode == widget.view.spatialTerrainMode &&
                  relief.level == widget.view.spatialTerrainLevel)) {
        try {
          editingDocument.commit(relief?.commit() ?? stroke!.commit());
          if (relief?.surfaceId != null) {
            widget.view.spatialSurfaceId = relief!.surfaceId;
          }
        } on Object catch (failure) {
          editingDocument.error = failure.toString();
        }
      }
      widget.onChanged();
      return;
    }
    if (modelGesture != null && modelEnd != null) {
      try {
        SpatialModelEditingCommands(editingDocument, widget.project).update(
          modelGesture!,
          x: modelPosition!.x + modelEnd!.x - modelOrigin!.x,
          z: modelPosition!.z + modelEnd!.y - modelOrigin!.y,
        );
      } on Object catch (failure) {
        editingDocument.error = failure.toString();
      }
      widget.view.pendingMove = null;
    }
    modelGesture = null;
    modelEnd = null;
    modelOrigin = null;
    modelPosition = null;
    gesture?.commit();
    gesture = null;
    widget.onChanged();
  }

  void tap(int x, int z) {
    start(x, z);
    finish();
  }

  void updateDrag((int, int) cell) {
    if (borderEraseDraft != null || exteriorBorderEraseActive) {
      sampleBorderErase(GridPos(x: cell.$1, y: cell.$2));
      widget.onChanged();
      return;
    }
    if (environmentGesture != null) {
      if (!environmentGestureValid) {
        cancel();
        return;
      }
      environmentGesture!.paint(GridPos(x: cell.$1, y: cell.$2));
      widget.onChanged();
      return;
    }
    if (contentSource != null && !contentGestureValid) {
      cancel();
      return;
    }
    if (terrainSource != null && !terrainGestureValid) {
      cancel();
      return;
    }
    if (terrainStroke != null && !locked) {
      try {
        terrainStroke!.paint(GridPos(x: cell.$1, y: cell.$2));
      } on Object catch (error) {
        editingDocument.error = error.toString();
        cancel();
        return;
      }
      widget.onChanged();
    }
    if (reliefStroke != null && !locked) {
      reliefStroke!.paint(GridPos(x: cell.$1, y: cell.$2));
      editingDocument.error = reliefStroke!.error;
      widget.onChanged();
    }
    gesture?.end = GridPos(x: cell.$1, y: cell.$2);
    final moving = gesture;
    final sourcePosition = moving?.entity?.pos ?? moving?.warp?.pos;
    final destination = moving?.destination;
    if (moving != null && sourcePosition != null && destination != null) {
      moving.end = GridPos(
        x: moving.origin.x + destination.x - sourcePosition.x,
        y: moving.origin.y + destination.y - sourcePosition.y,
      );
    }
    if (modelGesture != null) {
      final scene = editingDocument.current.spatialScene!;
      final x = modelPosition!.x.floor(), z = modelPosition!.z.floor();
      modelEnd = GridPos(
        x:
            modelOrigin!.x +
            (x + cell.$1 - modelOrigin!.x).clamp(0, scene.width - 1) -
            x,
        y:
            modelOrigin!.y +
            (z + cell.$2 - modelOrigin!.y).clamp(0, scene.depth - 1) -
            z,
      );
    }
    if (contentSource != null) widget.onChanged();
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
    final delta = switch (key) {
      LogicalKeyboardKey.arrowLeft => (-1, 0),
      LogicalKeyboardKey.arrowRight => (1, 0),
      LogicalKeyboardKey.arrowUp => (0, -1),
      LogicalKeyboardKey.arrowDown => (0, 1),
      _ => null,
    };
    if (event is KeyUpEvent && cameraKeys.remove(key)) {
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent && cameraKeys.contains(key) && !precision) {
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent &&
        !cameraKeys.contains(key) &&
        !nudgeKeys.contains(key)) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent && widget.view.tool == StudioMapTool.border) {
      if (key == LogicalKeyboardKey.escape) {
        discardBorder();
        widget.onChanged();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        finishBorder();
        return KeyEventResult.handled;
      }
    }
    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.delete ||
            key == LogicalKeyboardKey.backspace) &&
        !precision &&
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed &&
        !HardwareKeyboard.instance.isAltPressed) {
      final id = widget.view.selectedFor(
        editingDocument.current.id,
        MapSelectionFamily.decor,
      );
      final commands = SpatialModelEditingCommands(
        editingDocument,
        widget.project,
      );
      if (id != null &&
          commands.selected(id) != null &&
          !editingDocument.isElementUnavailable('model', id)) {
        if (!locked) {
          discardGesture();
          try {
            commands.delete(id);
            widget.view.clearSelection(editingDocument);
          } on Object catch (failure) {
            editingDocument.error = failure.toString();
          }
          widget.onChanged();
        }
        return KeyEventResult.handled;
      }
    }
    if (event is! KeyUpEvent &&
        delta != null &&
        !locked &&
        HardwareKeyboard.instance.isShiftPressed &&
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed &&
        !HardwareKeyboard.instance.isAltPressed) {
      if (nudgeKeys.isNotEmpty) finish();
      cameraKeys.add(key);
      widget.view.spatialFreeView = true;
      syncCameraView(preserveGesture: true);
      camera.orbit(delta.$1 * 12, delta.$2 * 12);
      widget.onChanged();
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        key == LogicalKeyboardKey.escape &&
        (contentSource != null ||
            reliefStroke != null ||
            terrainStroke != null ||
            environmentGesture != null ||
            widget.view.rampPreview != null ||
            widget.view.terrainSurfacePreview != null ||
            (selectingTerrainSurface && widget.view.spatialSurfaceId != null) ||
            widget.view.hasSelectionIn(editingDocument.current.id) ||
            widget.view.pendingMove != null ||
            widget.view.tool == StudioMapTool.place)) {
      discardGesture();
      widget.view.rampPreview = null;
      widget.view.terrainSurfacePreview = null;
      widget.view.spatialSurfaceId = null;
      hover = null;
      if (widget.view.tool == StudioMapTool.place) {
        widget.view.tool = StudioMapTool.select;
      }
      widget.view.clearSelection(editingDocument);
      widget.onChanged();
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent && nudgeKeys.remove(key)) {
      if (nudgeKeys.isEmpty) finish();
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent ||
        locked ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed ||
        widget.view.tool != StudioMapTool.select ||
        (contentSource != null && nudgeKeys.isEmpty)) {
      return KeyEventResult.ignored;
    }
    if (delta == null) return KeyEventResult.ignored;
    if (nudgeKeys.isEmpty) {
      final map = editingDocument.current;
      final modelId = widget.view.selectedFor(map.id, MapSelectionFamily.decor);
      final model = modelId == null
          ? null
          : SpatialModelEditingCommands(
              editingDocument,
              widget.project,
            ).selected(modelId);
      final npc = map.entities
          .where(
            (entity) =>
                entity.id ==
                widget.view.selectedFor(map.id, MapSelectionFamily.character),
          )
          .firstOrNull;
      final marker = map.entities
          .where(
            (entity) =>
                entity.id ==
                widget.view.selectedFor(map.id, MapSelectionFamily.marker),
          )
          .firstOrNull;
      final warp = map.warps
          .where(
            (warp) =>
                warp.id ==
                widget.view.selectedFor(map.id, MapSelectionFamily.warp),
          )
          .firstOrNull;
      final hit = marker != null
          ? SpatialSceneContentHit(
              kind: SpatialSceneContentKind.marker,
              id: marker.id,
              cell: (marker.pos.x, marker.pos.y),
            )
          : warp != null
          ? SpatialSceneContentHit(
              kind: SpatialSceneContentKind.warp,
              id: warp.id,
              cell: (warp.pos.x, warp.pos.y),
            )
          : model != null
          ? SpatialSceneContentHit(
              kind: SpatialSceneContentKind.model,
              id: model.id,
              cell: (model.position.x.floor(), model.position.z.floor()),
            )
          : npc != null
          ? SpatialSceneContentHit(
              kind: SpatialSceneContentKind.actor,
              id: 'npc:${npc.id}',
              cell: (npc.pos.x, npc.pos.y),
            )
          : null;
      if (hit == null || !start(hit.cell.$1, hit.cell.$2, hit)) {
        return KeyEventResult.ignored;
      }
    }
    nudgeKeys.add(key);
    final position = modelEnd ?? modelOrigin ?? gesture!.end;
    updateDrag((position.x + delta.$1, position.y + delta.$2));
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _atmosphere?.removeListener(_syncAtmosphere);
    _exteriorNotifier?.removeListener(_exteriorChanged);
    previewGeneration++;
    preview?.dispose();
    widget.view.transform.removeListener(syncZoom);
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
      return const StudioNotice(
        'Le rendu 3D est indisponible dans cette session.',
      );
    }
    updatePreview(visuals as SpatialWorkspaceVisuals);
    final freeView = widget.view.spatialFreeView;
    final borderMap = spatialBorderPreview;
    final rampMap =
        widget.view.tool == StudioMapTool.terrain &&
            widget.view.spatialTerrainMode == SpatialTerrainMode.ramp &&
            widget.view.rampPreview?.validFor(editingDocument.current) == true
        ? widget.view.rampPreview!.result
        : null;
    final terrainSurfaceMap =
        widget.view.tool == StudioMapTool.terrain &&
            widget.view.spatialTerrainMode == SpatialTerrainMode.relief &&
            widget.view.spatialContinuousTerrain &&
            widget.view.terrainSurfacePreview?.validFor(
                  editingDocument.current,
                ) ==
                true
        ? widget.view.terrainSurfacePreview!.result
        : null;
    final colors = Theme.of(context).colorScheme;
    final selectedModel = editingDocument.current.spatialScene!.instances
        .where(
          (instance) =>
              instance.id ==
              widget.view.selectedFor(
                editingDocument.current.id,
                MapSelectionFamily.decor,
              ),
        )
        .firstOrNull;
    final selectedActor = editingDocument.current.entities
        .where(
          (entity) =>
              entity.id ==
              widget.view.selectedFor(
                editingDocument.current.id,
                MapSelectionFamily.character,
              ),
        )
        .firstOrNull;
    return Focus(
      autofocus: true,
      focusNode: focus,
      onKeyEvent: (_, event) => onKey(event),
      onFocusChange: (focused) {
        if (!focused) cameraKeys.clear();
        setState(() {});
        if (!focused && nudgeKeys.isNotEmpty) cancel();
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: SpatialSceneView(
              neighbors: widget.neighbors,
              visibility: editingExterior
                  ? _visibilityFor(widget.document)
                  : sceneVisibility,
              decorations: decorationVisuals(
                visuals as SpatialWorkspaceVisuals,
                borderMap ??
                    rampMap ??
                    terrainSurfaceMap ??
                    environmentPreview ??
                    reliefStroke?.preview ??
                    terrainStroke?.preview,
              ),
              authoringTarget: authoringTarget,
              resolveAuthoringTarget: editingExterior
                  ? resolveAuthoringTarget
                  : null,
              canSelectContent: canSelectContent,
              canSelectLayer: (id) =>
                  !editingDocument.isElementUnavailable('layer', id),
              animationPreview: widget.view.spatialAnimations,
              onHover: showsHover ? updateHover : null,
              onSurfaceTap: surfaceTap,
              placementPreview: placementPreview,
              cellOverlays: cellOverlays(colors),
              contentPreview: contentPreview,
              selectedContent: selectedModel != null
                  ? SpatialSceneContentHit(
                      kind: SpatialSceneContentKind.model,
                      id: selectedModel.id,
                      cell: (
                        selectedModel.position.x.floor(),
                        selectedModel.position.z.floor(),
                      ),
                    )
                  : selectedActor != null
                  ? SpatialSceneContentHit(
                      kind: SpatialSceneContentKind.actor,
                      id: 'npc:${selectedActor.id}',
                      cell: (selectedActor.pos.x, selectedActor.pos.y),
                    )
                  : null,
              selectionColor: colors.primary,
              onZoom: (delta) {
                final factor =
                    (widget.view.scale * math.exp(-delta * .001)).clamp(
                      .15,
                      8,
                    ) /
                    widget.view.scale;
                widget.view.transform.value =
                    widget.view.transform.value.clone()
                      ..scaleByDouble(factor, factor, 1, 1);
              },
              selectContent:
                  widget.view.tool == StudioMapTool.select ||
                  (!freeView && widget.view.tool == StudioMapTool.eraseDecor),
              scene: editingExterior
                  ? widget.document.current.spatialScene!
                  : borderMap?.spatialScene ??
                        rampMap?.spatialScene ??
                        terrainSurfaceMap?.spatialScene ??
                        environmentPreview?.spatialScene ??
                        reliefStroke?.preview.spatialScene ??
                        editingDocument.current.spatialScene!,
              groundMap: editingExterior
                  ? widget.document.current
                  : borderMap ??
                        rampMap ??
                        terrainSurfaceMap ??
                        environmentPreview ??
                        reliefStroke?.preview ??
                        terrainStroke?.preview ??
                        editingDocument.current,
              groundProject: widget.project,
              loadGroundImage:
                  (visuals as SpatialWorkspaceVisuals).readGroundImage,
              models: widget.project.models3d,
              loadModel: (visuals as SpatialWorkspaceVisuals).readModel,
              controller: camera,
              onCell: tap,
              onContextMenu: freeView || editingExterior
                  ? null
                  : widget.onContextMenu,
              onDragStart: (x, z, hit) =>
                  widget.view.tool == StudioMapTool.place ||
                      (widget.view.tool == StudioMapTool.border &&
                          widget.view.borderEditingMode ==
                              BorderStrokeEditingMode.draw)
                  ? false
                  : start(x, z, hit),
              onDragUpdate: updateDrag,
              onDragEnd: finish,
              onDragCancel: cancel,
              onContent: (hit) {
                start(hit.cell.$1, hit.cell.$2, hit);
                finish();
              },
              actorFrames: (_) => preview?.frames ?? const {},
              background: colors.surfaceContainerLowest,
              ground: colors.primaryContainer,
              edge: colors.outlineVariant,
              errorBuilder: (_, failure) => Center(
                child: StudioNotice(
                  'Le rendu de cette carte est indisponible : ${error ?? failure}',
                ),
              ),
            ),
          ),
          if (guidance != null)
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: IgnorePointer(
                child: StudioNotice(
                  guidance!,
                  isError:
                      reliefStroke?.error != null ||
                      borderPreviewError != null ||
                      widget.view.borderDraftErrorFor(
                            editingDocument.current,
                            widget.project,
                          ) !=
                          null,
                  maxLines: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<SpatialCellOverlay> cellOverlays(ColorScheme colors) {
    final map =
        environmentPreview ??
        reliefStroke?.preview ??
        terrainStroke?.preview ??
        editingDocument.current;
    final destination = contentGestureValid ? gesture?.destination : null;
    final cells = <SpatialCellOverlay>[];
    cells.addAll(previewOverlays(colors));
    cells.addAll(environmentOverlays(colors));
    cells.addAll(borderOverlays(colors));
    cells.addAll(terrainSurfaceSelectionOverlays(colors));
    for (final layer in map.layers.whereType<CollisionLayer>()) {
      for (var index = 0; index < layer.collisions.length; index++) {
        if (layer.collisions[index]) {
          cells.add(
            SpatialCellOverlay(
              id: '${layer.id}:$index',
              cell: (index % map.size.width, index ~/ map.size.width),
              kind: SpatialCellOverlayKind.collision,
              color: colors.error,
            ),
          );
        }
      }
    }
    for (final entity in map.entities.where(
      (entity) => entity.kind == MapEntityKind.spawn,
    )) {
      final position = gesture?.entity?.id == entity.id
          ? destination ?? entity.pos
          : entity.pos;
      cells.add(
        SpatialCellOverlay(
          id: entity.id,
          cell: (position.x, position.y),
          kind: SpatialCellOverlayKind.spawn,
          color:
              widget.view.selectedFor(map.id, MapSelectionFamily.marker) ==
                  entity.id
              ? colors.primary
              : colors.secondary,
        ),
      );
    }
    for (final warp in map.warps) {
      final origin = gesture?.warp?.id == warp.id
          ? destination ?? warp.pos
          : warp.pos;
      cells.add(
        SpatialCellOverlay(
          id: warp.id,
          cell: (origin.x, origin.y),
          kind: SpatialCellOverlayKind.warp,
          color:
              widget.view.selectedFor(map.id, MapSelectionFamily.warp) ==
                  warp.id
              ? colors.primary
              : colors.tertiary,
        ),
      );
    }
    return cells;
  }
}

bool _previewOrderOnlyChange(MapData before, MapData after) {
  if (!mapSharesNonVisualOrderStorage(before, after) ||
      before.layers.length != after.layers.length ||
      before.placedElements.length != after.placedElements.length) {
    return false;
  }
  final layers = {for (final layer in before.layers) layer.id: layer};
  for (final layer in after.layers) {
    if (layers[layer.id] != layer) return false;
  }
  for (var index = 0; index < before.placedElements.length; index++) {
    final previous = before.placedElements[index],
        next = after.placedElements[index];
    if (!identical(previous, next) &&
        previous.copyWith(visualOrder: next.visualOrder) != next) {
      return false;
    }
  }
  return true;
}
