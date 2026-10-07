import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import '../../../features/map_workspace/application/spatial_model_editing_commands.dart';
import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_editing_commands.dart';
import '../../../features/map_workspace/application/map_workspace_controller.dart';
import 'map_character_gesture.dart';
import 'map_canvas_stroke.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';
import '../../shared/widgets/feedback/studio_notice.dart';

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
  });
  final EditableMapDocument document;
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
  final camera = SpatialSceneController()..setView(SpatialEditorView.game);
  final focus = FocusNode();
  SpatialNpcPreview? preview;
  MapData? previewMap;
  MapCharacterGesture? gesture;
  MapCanvasStroke? terrainStroke;
  MapData? terrainSource;
  StudioMapTool? terrainTool;
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
  bool get locked =>
      widget.document.saving ||
      widget.controller.catalogLocks(widget.document.base.mapId);
  @override
  void initState() {
    super.initState();
    widget.view.transform.addListener(syncZoom);
    widget.view.recenter = recenter;
    syncZoom();
    syncCameraView();
  }

  bool get contentGestureValid =>
      !locked &&
      widget.view.tool == StudioMapTool.select &&
      gestureFreeView == widget.view.spatialFreeView &&
      identical(contentSource, widget.document.current) &&
      identical(contentProject, widget.project);

  SpatialSceneContentPreview? get contentPreview {
    if (!contentGestureValid) return null;
    final scene = widget.document.current.spatialScene!;
    if (modelGesture != null && modelEnd != null) {
      final x = modelPosition!.x + modelEnd!.x - modelOrigin!.x;
      final z = modelPosition!.z + modelEnd!.y - modelOrigin!.y;
      return SpatialSceneContentPreview(
        kind: SpatialSceneContentKind.model,
        id: modelGesture!,
        position: Model3dVector3(x: x, y: scene.worldHeightAt(x, z), z: z),
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
    if (old.project != widget.project || old.visuals != widget.visuals) {
      previewMap = null;
    }
    syncCameraView();
    if (contentSource != null && !contentGestureValid) discardGesture();
  }

  void syncCameraView() {
    final next = widget.view.spatialFreeView
        ? SpatialEditorView.orbit
        : SpatialEditorView.game;
    if (camera.view == next) return;
    discardGesture();
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
    final map = widget.document.current;
    if (identical(previewMap, map)) return;
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
          widget.document.error =
              'Aperçu des personnages indisponible : $failure';
        });
        widget.onChanged();
      }
    }
  }

  bool start(int x, int z, [SpatialSceneContentHit? hit]) {
    if (locked ||
        (widget.view.spatialFreeView &&
            (widget.view.tool != StudioMapTool.select || hit == null)) ||
        widget.view.tool == StudioMapTool.pan) {
      return false;
    }
    final armedMove = widget.view.pendingMove;
    discardGesture();
    widget.view.pendingMove = armedMove;
    focus.requestFocus();
    gestureFreeView = widget.view.spatialFreeView;
    final document = widget.document;
    final cell = GridPos(x: x, y: z);
    final commands = SpatialModelEditingCommands(document, widget.project);
    try {
      if (widget.view.tool == StudioMapTool.terrain ||
          widget.view.tool == StudioMapTool.erase ||
          widget.view.tool == StudioMapTool.collisionPaint ||
          widget.view.tool == StudioMapTool.collisionErase) {
        final scene = document.current.spatialScene!;
        final collision =
            widget.view.tool == StudioMapTool.collisionPaint ||
            widget.view.tool == StudioMapTool.collisionErase;
        if (!collision &&
            (scene.heightLevels.any((level) => level != 0) ||
                scene.navigation.ramps.isNotEmpty)) {
          document.error =
              'La peinture du sol est disponible sur les cartes plates pour le moment.';
          widget.onChanged();
          return false;
        }
        terrainStroke = MapCanvasStroke.start(
          map: document.current,
          project: widget.project,
          view: widget.view,
          commands: MapEditingCommands(document, widget.project),
          origin: cell,
        );
        terrainSource = terrainStroke == null ? null : document.current;
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
                      item.position.z.floor() == z,
                )
                .lastOrNull;
      if (instance != null &&
          {
            StudioMapTool.select,
            StudioMapTool.erase,
            StudioMapTool.eraseDecor,
          }.contains(widget.view.tool)) {
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
        document.error =
            'Cet outil ne s’applique pas aux décors et personnages de cette carte 3D.';
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
      document: widget.document,
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
    terrainSource = null;
    terrainTool = null;
    gesture = null;
    modelGesture = null;
    modelEnd = null;
    modelOrigin = null;
    modelPosition = null;
    widget.view.pendingMove = null;
  }

  void cancel() {
    discardGesture();
    widget.onChanged();
  }

  void finish() {
    if (locked ||
        (contentSource != null && !contentGestureValid) ||
        (gestureFreeView != null &&
            gestureFreeView != widget.view.spatialFreeView)) {
      cancel();
      return;
    }
    gestureFreeView = null;
    contentSource = null;
    contentProject = null;
    nudgeKeys.clear();
    final stroke = terrainStroke;
    final source = terrainSource;
    final tool = terrainTool;
    terrainStroke = null;
    terrainSource = null;
    terrainTool = null;
    if (stroke != null) {
      if (!locked &&
          identical(widget.document.current, source) &&
          widget.view.tool == tool) {
        try {
          widget.document.commit(stroke.commit());
        } on Object catch (failure) {
          widget.document.error = failure.toString();
        }
      }
      widget.onChanged();
      return;
    }
    if (modelGesture != null && modelEnd != null) {
      try {
        SpatialModelEditingCommands(widget.document, widget.project).update(
          modelGesture!,
          x: modelPosition!.x + modelEnd!.x - modelOrigin!.x,
          z: modelPosition!.z + modelEnd!.y - modelOrigin!.y,
        );
      } on Object catch (failure) {
        widget.document.error = failure.toString();
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
    if (contentSource != null && !contentGestureValid) {
      cancel();
      return;
    }
    if (terrainStroke != null && !locked) {
      terrainStroke!.paint(GridPos(x: cell.$1, y: cell.$2));
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
      final scene = widget.document.current.spatialScene!;
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
    final key = event.logicalKey;
    if (event is KeyDownEvent &&
        key == LogicalKeyboardKey.escape &&
        (contentSource != null ||
            widget.view.hasSelectionIn(widget.document.current.id) ||
            widget.view.pendingMove != null)) {
      discardGesture();
      widget.view.clearSelection(widget.document);
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
    final delta = switch (key) {
      LogicalKeyboardKey.arrowLeft => (-1, 0),
      LogicalKeyboardKey.arrowRight => (1, 0),
      LogicalKeyboardKey.arrowUp => (0, -1),
      LogicalKeyboardKey.arrowDown => (0, 1),
      _ => null,
    };
    if (delta == null) return KeyEventResult.ignored;
    if (nudgeKeys.isEmpty) {
      final map = widget.document.current;
      final modelId = widget.view.selectedFor(map.id, MapSelectionFamily.decor);
      final model = modelId == null
          ? null
          : SpatialModelEditingCommands(
              widget.document,
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
    previewGeneration++;
    preview?.dispose();
    widget.view.transform.removeListener(syncZoom);
    widget.view.recenter = null;
    focus.dispose();
    camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visuals = widget.visuals;
    if (visuals is! SpatialWorkspaceVisuals) {
      return const StudioNotice(
        'Le rendu 3D est indisponible dans cette session.',
      );
    }
    updatePreview(visuals as SpatialWorkspaceVisuals);
    final freeView = widget.view.spatialFreeView;
    final colors = Theme.of(context).colorScheme;
    final selectedModel = widget.document.current.spatialScene!.instances
        .where(
          (instance) =>
              instance.id ==
              widget.view.selectedFor(
                widget.document.current.id,
                MapSelectionFamily.decor,
              ),
        )
        .firstOrNull;
    final selectedActor = widget.document.current.entities
        .where(
          (entity) =>
              entity.id ==
              widget.view.selectedFor(
                widget.document.current.id,
                MapSelectionFamily.character,
              ),
        )
        .firstOrNull;
    return Focus(
      autofocus: true,
      focusNode: focus,
      onKeyEvent: (_, event) => onKey(event),
      onFocusChange: (focused) {
        if (!focused && nudgeKeys.isNotEmpty) cancel();
      },
      child: SpatialSceneView(
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
              (widget.view.scale * math.exp(-delta * .001)).clamp(.15, 8) /
              widget.view.scale;
          widget.view.transform.value = widget.view.transform.value.clone()
            ..scaleByDouble(factor, factor, 1, 1);
        },
        selectContent:
            widget.view.tool == StudioMapTool.select ||
            (!freeView && widget.view.tool == StudioMapTool.eraseDecor),
        scene: widget.document.current.spatialScene!,
        groundMap: terrainStroke?.preview ?? widget.document.current,
        groundProject: widget.project,
        loadGroundImage: (visuals as SpatialWorkspaceVisuals).readGroundImage,
        models: widget.project.models3d,
        loadModel: (visuals as SpatialWorkspaceVisuals).readModel,
        controller: camera,
        onCell: tap,
        onContextMenu: freeView ? null : widget.onContextMenu,
        onDragStart: start,
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
    );
  }

  List<SpatialCellOverlay> cellOverlays(ColorScheme colors) {
    final map = terrainStroke?.preview ?? widget.document.current;
    final destination = contentGestureValid ? gesture?.destination : null;
    final cells = <SpatialCellOverlay>[];
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
