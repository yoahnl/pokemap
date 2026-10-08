import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter/gestures.dart' hide Matrix4;
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter/widgets.dart' hide Matrix4, Texture;
import 'package:map_core/map_core.dart';

import 'model_byte_loader.dart';
import 'model_preview.dart';
import 'model_playback.dart';
import 'spatial_picking.dart';
import 'adaptive_camera.dart';
import 'flutter_frame_graphics_device.dart';
import 'spatial_actor_visual.dart';
import 'spatial_game_surface.dart';
import 'spatial_pixel_material.dart';
import 'spatial_ground.dart';
import 'spatial_terrain_geometry.dart';
import 'spatial_selection.dart';
import 'spatial_cell_overlay.dart';
import 'spatial_scene_neighbor.dart';
import 'spatial_scene_components.dart';
import 'spatial_model_placement_preview.dart';

Future<void> initializeSpatialRenderer() => GpuBackend.initialize();

enum SpatialEditorView { orbit, top, game }

enum SpatialSceneContentKind { actor, model, marker, warp }

final class SpatialSceneContentHit {
  const SpatialSceneContentHit({
    required this.kind,
    required this.id,
    required this.cell,
  });
  final SpatialSceneContentKind kind;
  final String id;
  final (int, int) cell;
}

final class SpatialSceneContentPreview {
  const SpatialSceneContentPreview({
    required this.kind,
    required this.id,
    required this.position,
  });
  final SpatialSceneContentKind kind;
  final String id;
  final Model3dVector3 position;
}

class SpatialSceneController extends ModelPreviewController {
  @override
  void dolly(double delta) {
    zoom = (zoom * math.exp(delta * .001)).clamp(.125, 1 / .15);
    notifyListeners();
  }

  SpatialEditorView view = SpatialEditorView.orbit;
  Offset pan = Offset.zero;
  void panBy(double x, double z) {
    pan += Offset(x, z);
    notifyListeners();
  }

  @override
  void reset() {
    pan = Offset.zero;
    super.reset();
  }

  void setView(SpatialEditorView value) {
    view = value;
    notifyListeners();
  }
}

class SpatialSceneView extends StatefulWidget {
  const SpatialSceneView({
    super.key,
    required this.scene,
    required this.models,
    required this.loadModel,
    required this.controller,
    required this.onCell,
    required this.background,
    required this.ground,
    required this.edge,
    required this.errorBuilder,
    this.selectedCell,
    this.selectedContent,
    this.contentPreview,
    this.placementPreview,
    this.onHover,
    this.onSurfaceTap,
    this.cellOverlays = const [],
    this.selectionColor,
    this.actorFrames,
    this.onReady,
    this.onContent,
    this.selectContent = true,
    this.onZoom,
    this.onContextMenu,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onDragCancel,
    this.groundMap,
    this.groundProject,
    this.loadGroundImage,
    this.neighbors = const [],
    this.sceneOffset = Offset.zero,
    this.animationPreview,
    this.modelRuntimeState,
    this.presentationPaused,
    this.cameraPose,
  });
  final SpatialModelRuntimeState? Function(String mapId, String instanceId)?
  modelRuntimeState;
  final bool Function()? presentationPaused;
  final ({double x, double y, double z, double zoom})? Function()? cameraPose;
  final Map<String, SpatialActorVisual> Function(double dt)? actorFrames;
  final VoidCallback? onReady;
  final ValueChanged<SpatialSceneContentHit>? onContent;
  final bool selectContent;
  final ValueChanged<double>? onZoom;
  final void Function(GridPos, Offset)? onContextMenu;
  final bool Function(int, int, SpatialSceneContentHit?)? onDragStart;
  final ValueChanged<(int, int)>? onDragUpdate;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDragCancel;
  final MapData? groundMap;
  final ProjectManifest? groundProject;
  final Future<Uint8List> Function(String id)? loadGroundImage;
  final List<SpatialSceneNeighbor> neighbors;
  final Offset sceneOffset;
  final SpatialAnimationPreviewController? animationPreview;
  final MapSpatialScene scene;
  final List<ProjectModel3dEntry> models;
  final Future<Uint8List> Function(String id) loadModel;
  final SpatialSceneController controller;
  final void Function(int x, int z) onCell;
  final Color background, ground, edge;
  final (int, int)? selectedCell;
  final SpatialSceneContentHit? selectedContent;
  final SpatialSceneContentPreview? contentPreview;
  final SpatialModelPlacementPreview? placementPreview;
  final ValueChanged<SpatialSurfaceHit?>? onHover;
  final ValueChanged<SpatialSurfaceHit>? onSurfaceTap;
  final List<SpatialCellOverlay> cellOverlays;
  final Color? selectionColor;
  final Widget Function(BuildContext, Object) errorBuilder;

  bool modelSourcesMatch(SpatialSceneView other) =>
      identical(groundProject, other.groundProject) &&
      loadModel == other.loadModel &&
      listEquals(models, other.models);

  @override
  State<SpatialSceneView> createState() => _SpatialSceneViewState();
}

class _SpatialSceneViewState extends State<SpatialSceneView> {
  _SpatialGame? game;
  Object? failure;
  Object? previewFailure;
  bool draggingContent = false;
  SpatialContentDrag? contentDrag;
  double? contentDragHeight;
  double trackpadScale = 1;
  Offset? hoverPosition;
  bool hoverRefreshPending = false;
  bool get zoomEnabled =>
      widget.onZoom != null ||
      widget.controller.view != SpatialEditorView.game ||
      widget.onDragStart != null;

  void zoom(double delta) {
    if (!zoomEnabled) return;
    final onZoom = widget.onZoom;
    if (onZoom != null) {
      onZoom(delta);
    } else {
      widget.controller.dolly(delta);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(scheduleHoverRefresh);
    initialize();
  }

  void scheduleHoverRefresh() {
    if (!mounted ||
        hoverPosition == null ||
        widget.onHover == null ||
        hoverRefreshPending) {
      return;
    }
    hoverRefreshPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hoverRefreshPending = false;
      if (mounted) refreshHover();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void refreshHover() {
    final position = hoverPosition;
    if (position == null || widget.onHover == null) return;
    game?.syncCamera();
    widget.onHover!(game?.pickSurface(position));
  }

  void hoverAt(Offset position) {
    if (widget.onHover == null) return;
    hoverPosition = position;
    enterHover();
    final game = this.game;
    widget.onHover!(game?.pickSurface(position));
  }

  void enterHover() {
    final game = this.game;
    if (game != null && game.placementPreviewHidden) {
      game.placementPreviewHidden = false;
      game.syncPlacementPreview();
    }
  }

  void handlePreviewStatus(Object? error) {
    if (mounted && !identical(previewFailure, error)) {
      setState(() => previewFailure = error);
    }
  }

  void exitHover() {
    hoverPosition = null;
    final game = this.game;
    if (game != null) {
      game.placementPreviewHidden = true;
      game.placementRenderer.clear();
    }
    widget.onHover?.call(null);
  }

  Future<void> initialize() async {
    try {
      await initializeSpatialRenderer();
      if (!mounted) return;
      final initialized = _SpatialGame(
        widget,
        onPreviewStatus: handlePreviewStatus,
        onSurfaceChanged: scheduleHoverRefresh,
      );
      setState(() => game = initialized);
    } on Object catch (error) {
      if (mounted) setState(() => failure = error);
    }
  }

  Future<void> refresh() async {
    try {
      final refreshed = await game?.refresh();
      if (mounted && refreshed == true) setState(() => failure = null);
    } on Object catch (error) {
      if (mounted) setState(() => failure = error);
    }
  }

  @override
  void didUpdateWidget(SpatialSceneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(scheduleHoverRefresh);
      widget.controller.addListener(scheduleHoverRefresh);
    }
    if (widget.onHover == null) hoverPosition = null;
    final game = this.game;
    if (game == null) return;
    if (oldWidget.controller != widget.controller && game.sceneReady) {
      oldWidget.controller.removeListener(game.syncCamera);
      widget.controller.addListener(game.syncCamera);
    }
    if (oldWidget.animationPreview != widget.animationPreview &&
        game.sceneReady) {
      oldWidget.animationPreview?.removeListener(game.syncAnimations);
      widget.animationPreview?.addListener(game.syncAnimations);
    }
    game.configuration = widget;
    final modelSourcesChanged = !widget.modelSourcesMatch(oldWidget);
    if (!identical(oldWidget.groundProject, widget.groundProject)) {
      game.groundTextureCache.clear();
      game.placementRenderer.clear();
    }
    if (modelSourcesChanged) {
      game.cache.clear();
      game.placementRenderer.clear();
    }
    if (widget.placementPreview == null) game.placementRenderer.clear();
    if (!identical(oldWidget.scene, widget.scene) ||
        !identical(oldWidget.groundMap, widget.groundMap) ||
        !identical(oldWidget.groundProject, widget.groundProject) ||
        modelSourcesChanged ||
        !_sameNeighbors(oldWidget.neighbors, widget.neighbors) ||
        oldWidget.sceneOffset != widget.sceneOffset ||
        oldWidget.selectedCell != widget.selectedCell ||
        oldWidget.selectedContent?.id != widget.selectedContent?.id ||
        oldWidget.selectedContent?.kind != widget.selectedContent?.kind ||
        oldWidget.selectionColor != widget.selectionColor) {
      refresh();
    } else if (!game.refreshing) {
      game.renderedConfiguration = widget;
      game.syncContentPreview();
      game.syncPlacementPreview();
      if (!listEquals(oldWidget.cellOverlays, widget.cellOverlays)) {
        game.syncCellOverlays();
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(scheduleHoverRefresh);
    game?.placementRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = this.game;
    return MouseRegion(
      onEnter: widget.placementPreview == null ? null : (_) => enterHover(),
      onHover: widget.onHover == null
          ? null
          : (event) => hoverAt(event.localPosition),
      onExit: widget.onHover == null && widget.placementPreview == null
          ? null
          : (_) => exitHover(),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: (event) {
          if (event is PointerScrollEvent && zoomEnabled) {
            GestureBinding.instance.pointerSignalResolver.register(
              event,
              (_) => zoom(event.scrollDelta.dy),
            );
          }
        },
        onPointerPanZoomStart: (_) => trackpadScale = 1,
        onPointerPanZoomUpdate: (event) {
          zoom(
            -event.panDelta.dy - math.log(event.scale / trackpadScale) * 1000,
          );
          trackpadScale = event.scale;
        },
        child: game == null
            ? failure == null
                  ? const Center(child: Text('Chargement de la scène…'))
                  : widget.errorBuilder(context, failure!)
            : GestureDetector(
                supportedDevices: zoomEnabled
                    ? (PointerDeviceKind.values.toSet()
                        ..remove(PointerDeviceKind.trackpad))
                    : null,
                onSecondaryTapUp: (event) {
                  final cell = game.pickContentCell(event.localPosition);
                  if (cell != null)
                    widget.onContextMenu?.call(
                      GridPos(x: cell.$1, y: cell.$2),
                      event.globalPosition,
                    );
                },
                onPanStart: (event) {
                  hoverAt(event.localPosition);
                  final orbit =
                      widget.controller.view == SpatialEditorView.orbit &&
                      HardwareKeyboard.instance.isAltPressed;
                  final hit = widget.selectContent && !orbit
                      ? game.pickContent(event.localPosition)
                      : null;
                  contentDragHeight = hit == null
                      ? null
                      : game.contentHeight(hit, event.localPosition);
                  final ground = contentDragHeight == null
                      ? game.pickCell(event.localPosition)
                      : game.pickPlaneCell(
                          event.localPosition,
                          contentDragHeight!,
                        );
                  final cell = hit?.cell ?? ground;
                  draggingContent =
                      cell != null &&
                      ground != null &&
                      !orbit &&
                      (widget.onDragStart?.call(cell.$1, cell.$2, hit) ??
                          false);
                  contentDrag = draggingContent
                      ? SpatialContentDrag(
                          anchor: cell!,
                          pointerOrigin: ground!,
                        )
                      : null;
                  if (!draggingContent) contentDragHeight = null;
                },
                onPanEnd: (_) {
                  if (draggingContent) widget.onDragEnd?.call();
                  draggingContent = false;
                  contentDrag = null;
                  contentDragHeight = null;
                },
                onPanCancel: () {
                  if (draggingContent) widget.onDragCancel?.call();
                  draggingContent = false;
                  contentDrag = null;
                  contentDragHeight = null;
                },
                onPanUpdate: (event) {
                  hoverAt(event.localPosition);
                  if (draggingContent) {
                    final cell = contentDragHeight == null
                        ? game.pickCell(event.localPosition)
                        : game.pickPlaneCell(
                            event.localPosition,
                            contentDragHeight!,
                          );
                    if (cell != null)
                      widget.onDragUpdate?.call(contentDrag!.cellAt(cell));
                    return;
                  }
                  if (widget.onDragStart != null &&
                      widget.controller.view == SpatialEditorView.game) {
                    widget.controller.panBy(
                      -event.delta.dx /
                          game.size.x *
                          widget.scene.width *
                          widget.controller.zoom,
                      -event.delta.dy /
                          game.size.y *
                          widget.scene.depth *
                          widget.controller.zoom,
                    );
                  }
                  if (widget.controller.view == SpatialEditorView.orbit) {
                    widget.controller.orbit(event.delta.dx, event.delta.dy);
                  }
                },
                onTapUp: (event) {
                  final hit = widget.selectContent
                      ? game.pickContent(event.localPosition)
                      : null;
                  if (hit != null && widget.onContent != null) {
                    widget.onContent!(hit);
                    return;
                  }
                  final surface = game.pickSurface(event.localPosition);
                  if (surface != null && widget.onSurfaceTap != null) {
                    widget.onSurfaceTap!(surface);
                    return;
                  }
                  final cell = surface?.cell;
                  if (cell != null) widget.onCell(cell.$1, cell.$2);
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SpatialGameSurface<_SpatialGame>(
                        game: game,
                        loadingBuilder: (_) => const Center(
                          child: Text('Chargement de la scène…'),
                        ),
                        errorBuilder: widget.errorBuilder,
                      ),
                    ),
                    if (failure != null || previewFailure != null)
                      Positioned.fill(
                        child: widget.errorBuilder(
                          context,
                          failure ?? previewFailure!,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SpatialGame extends FlameGame3D<World3D, CameraComponent3D> {
  @override
  late final GraphicsDevice device = FlutterFrameGraphicsDevice();

  _SpatialGame(
    this.configuration, {
    required this.onPreviewStatus,
    required this.onSurfaceChanged,
  }) : super(world: World3D(), camera: AdaptiveCamera3D(fovY: 40));
  SpatialSceneView configuration;
  final ValueChanged<Object?> onPreviewStatus;
  final VoidCallback onSurfaceChanged;
  SpatialSceneView? renderedConfiguration;
  SpatialSceneView get visibleConfiguration =>
      renderedConfiguration ?? configuration;
  bool refreshing = false;
  final Map<String, Future<Model>> cache = {};
  Map<
    String,
    ({_SceneModelComponent component, Vector3 position, Model3dVector3 anchor})
  >
  modelComponents = {};
  Map<(String, String), _SceneModelComponent> animationModels = {};
  bool sceneReady = false, closed = false;
  final actorSelections = <String, List<MeshComponent>>{};
  int generation = 0;
  final actors =
      <String, ({MeshComponent mesh, SpatialPixelMaterial material})>{};
  SpatialActorVisual? actorVisual;
  double billboardPitch = 0, billboardYaw = 0;
  final groundTextureCache = <(String, String), Future<Texture>>{};
  List<_SceneGround> grounds = [];
  late final sceneComponents = SpatialSceneComponents(world);
  late final placementRenderer = SpatialPlacementPreviewRenderer(
    world,
    onStatus: onPreviewStatus,
    loadModel: (definition) => ModelByteLoader.loadCached(
      cache,
      definition.sourceAssetId,
      () => configuration.loadModel(definition.id),
    ),
  );
  bool placementPreviewHidden = false;
  List<MeshComponent> cellOverlayComponents = [];
  double groundElapsed = 0;
  @override
  Color backgroundColor() => visibleConfiguration.background;
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (closed) return;
    sceneReady = true;
    configuration.controller.addListener(syncCamera);
    configuration.animationPreview?.addListener(syncAnimations);
    world.add(LightComponent.ambient(intensity: 0.85));
    await refresh();
    if (!closed) {
      configuration.onReady?.call();
      if (configuration.onHover != null) onSurfaceChanged();
    }
  }

  Future<bool> refresh() async {
    if (!sceneReady || closed) return false;
    final ticket = ++generation;
    refreshing = true;
    placementRenderer.clear();
    sceneComponents.cancelPending();
    final snapshot = configuration;
    final neighbors = List<SpatialSceneNeighbor>.of(snapshot.neighbors);
    final definitions = {for (final model in snapshot.models) model.id: model};
    final components = <Object3D>[];
    final nextGrounds = <_SceneGround>[];
    final nextAnimationModels = <(String, String), _SceneModelComponent>{};
    final nextModelComponents =
        <
          String,
          ({
            _SceneModelComponent component,
            Vector3 position,
            Model3dVector3 anchor,
          })
        >{};
    final placements = [
      (
        scene: snapshot.scene,
        map: snapshot.groundMap,
        offset: snapshot.sceneOffset,
        loader: snapshot.loadGroundImage,
        active: true,
      ),
      for (final neighbor in neighbors)
        if (neighbor.map.spatialScene case final scene?)
          (
            scene: scene,
            map: neighbor.map,
            offset: snapshot.sceneOffset + neighbor.offset,
            loader: neighbor.loadGroundImage,
            active: false,
          ),
    ];
    try {
      for (final placement in placements) {
        final map = placement.map;
        final project = snapshot.groundProject;
        final loader = placement.loader;
        SpatialGroundPlan? groundPlan;
        final textures = <String, Texture>{};
        if (map != null &&
            (map.layers.isNotEmpty || map.spatialScene?.cliffFrame != null)) {
          if (project == null || loader == null) {
            throw StateError('Les ressources du sol 3D sont indisponibles.');
          }
          final plan = SpatialGroundPlan(map, project);
          groundPlan = plan;
          for (final id in plan.imageIds) {
            final key = (map.id, id);
            final pending = groundTextureCache.putIfAbsent(
              key,
              () async => loadSpatialGroundTexture(
                await loader(id),
                transparentColor: project.tilesets
                    .where((tileset) => tileset.id == id)
                    .firstOrNull
                    ?.transparentColor,
              ),
            );
            try {
              textures[id] = await pending;
            } on Object {
              if (identical(groundTextureCache[key], pending)) {
                groundTextureCache.remove(key);
              }
              rethrow;
            }
            if (ticket != generation || closed) return false;
          }
          final ground = _SceneGround(plan, textures, placement.offset);
          ground.resolve((groundElapsed * 1000).round());
          nextGrounds.add(ground);
          components.addAll(ground.components);
        }
        for (final mesh in terrainMeshes(
          placement.scene,
          snapshot.ground,
          snapshot.edge,
          selectedCell: placement.active ? snapshot.selectedCell : null,
          cliffTexture: groundPlan?.cliff == null
              ? null
              : (
                  texture: textures[groundPlan!.cliff!.tilesetId]!,
                  sourceRect: groundPlan.cliff!.sourceRect,
                ),
        )) {
          components.add(
            MeshComponent(
              mesh: mesh,
              position: Vector3(placement.offset.dx, 0, placement.offset.dy),
            ),
          );
        }
        for (final instance in placement.scene.instances) {
          final definition = definitions[instance.modelId];
          if (definition == null) {
            throw StateError('Modèle absent : ${instance.modelId}');
          }
          final model = await ModelByteLoader.loadCached(
            cache,
            definition.sourceAssetId,
            () => snapshot.loadModel(definition.id),
          );
          if (ticket != generation || closed) return false;
          final scale = definition.scale * instance.scale;
          final rotation = Quaternion.axisAngle(
            Vector3(0, 1, 0),
            instance.rotationDegrees * math.pi / 180,
          );
          final pivot =
              Vector3(
                definition.pivot.x,
                definition.pivot.y,
                definition.pivot.z,
              ) *
              scale;
          rotation.rotate(pivot);
          final animationKey = (placement.map?.id ?? '__scene__', instance.id);
          final previous = animationModels[animationKey];
          final component = _SceneModelComponent(
            model: model,
            playback: identical(previous?.model, model)
                ? ModelPlaybackState.from(previous!.playback)
                : null,
            runtimePoseBefore: identical(previous?.model, model)
                ? previous?.runtimePoseBefore
                : null,
            position:
                Vector3(
                  instance.position.x + placement.offset.dx,
                  instance.position.y,
                  instance.position.z + placement.offset.dy,
                ) -
                pivot,
            rotation: rotation,
            scale: Vector3.all(scale),
            children:
                placement.active &&
                    snapshot.selectedContent?.kind ==
                        SpatialSceneContentKind.model &&
                    snapshot.selectedContent?.id == instance.id
                ? spatialSelectionFrame(
                    Vector3(
                      definition.inspection.bounds.min.x,
                      definition.inspection.bounds.min.y,
                      definition.inspection.bounds.min.z,
                    ),
                    Vector3(
                      definition.inspection.bounds.max.x,
                      definition.inspection.bounds.max.y,
                      definition.inspection.bounds.max.z,
                    ),
                    .04 / scale,
                    snapshot.selectionColor ?? snapshot.edge,
                  )
                : const [],
          );
          component.bindAnimation(
            instance.animationIndex,
            loop: instance.animationLoop,
            speed: instance.animationSpeed,
          );
          nextAnimationModels[animationKey] = component;
          components.add(component);
          if (placement.active) {
            nextModelComponents[instance.id] = (
              component: component,
              position: component.position.clone(),
              anchor: instance.position,
            );
          }
        }
      }
      if (ticket != generation || closed) return false;
      final nextCellOverlays = buildCellOverlays(snapshot);
      components.addAll(nextCellOverlays);
      return await sceneComponents.replace(
        components,
        isCurrent: () => ticket == generation && !closed,
        onCommit: () {
          for (final entry in actorSelections.entries) {
            actors[entry.key]?.mesh.removeAll(entry.value);
          }
          actorSelections.clear();
          grounds = nextGrounds;
          for (final entry in nextAnimationModels.entries) {
            final previous = animationModels[entry.key];
            if (previous != null) {
              entry.value.playback.synchronizeClock(previous.playback);
            }
          }
          modelComponents = nextModelComponents;
          animationModels = nextAnimationModels;
          renderedConfiguration = configuration;
          actorVisual = null;
          cellOverlayComponents = nextCellOverlays;
          refreshing = false;
          syncAnimations();
          syncContentPreview();
          syncPlacementPreview();
          syncCamera();
          syncActors(0);
          if (!listEquals(snapshot.cellOverlays, configuration.cellOverlays)) {
            syncCellOverlays();
          }
          if (configuration.onHover != null) onSurfaceChanged();
        },
      );
    } on Object {
      if (ticket != generation || closed) return false;
      rethrow;
    } finally {
      if (ticket == generation) refreshing = false;
    }
  }

  Future<void> syncPlacementPreview() async {
    if (!sceneReady || closed || refreshing) return;
    await placementRenderer.sync(
      preview: placementPreviewHidden ? null : configuration.placementPreview,
      models: configuration.models,
      color: configuration.selectionColor ?? configuration.edge,
      offset: configuration.sceneOffset,
    );
  }

  void syncContentPreview() {
    if (refreshing) return;
    final preview = visibleConfiguration.contentPreview;
    for (final entry in modelComponents.entries) {
      final model = entry.value;
      final position =
          preview?.kind == SpatialSceneContentKind.model &&
              preview?.id == entry.key
          ? preview!.position
          : model.anchor;
      model.component.position.setValues(
        model.position.x + position.x - model.anchor.x,
        model.position.y + position.y - model.anchor.y,
        model.position.z + position.z - model.anchor.z,
      );
    }
  }

  List<MeshComponent> buildCellOverlays(SpatialSceneView configuration) => [
    for (final mesh in spatialCellOverlayMeshes(
      configuration.scene,
      configuration.cellOverlays,
    ))
      MeshComponent(
        mesh: mesh,
        position: Vector3(
          configuration.sceneOffset.dx,
          0,
          configuration.sceneOffset.dy,
        ),
      ),
  ];

  void syncCellOverlays() {
    if (!sceneReady || closed || refreshing) return;
    final next = buildCellOverlays(visibleConfiguration);
    sceneComponents.replaceSubset(cellOverlayComponents, next);
    cellOverlayComponents = next;
  }

  final animationRestartVersions = <String, int>{};

  void syncAnimations() {
    if (refreshing) return;
    final preview = configuration.animationPreview;
    for (final entry in modelComponents.entries) {
      final version = preview?.restartVersion(entry.key) ?? 0;
      if (version != (animationRestartVersions[entry.key] ?? 0)) {
        entry.value.component.playback.restart();
      }
      entry.value.component.playback.paused =
          preview?.isPaused(entry.key) ?? false;
      animationRestartVersions[entry.key] = version;
    }
  }

  void syncCamera() {
    if (refreshing) return;
    final configuration = visibleConfiguration;
    final scene = configuration.scene;
    final control = configuration.controller;
    final visual = actorVisual;
    final cameraPose = configuration.cameraPose?.call();
    final center = cameraPose != null
        ? Vector3(cameraPose.x, cameraPose.y, cameraPose.z)
        : visual == null
        ? Vector3(
            scene.width / 2,
            scene.heightAt(scene.width ~/ 2, scene.depth ~/ 2),
            scene.depth / 2,
          )
        : Vector3(visual.x, visual.y, visual.z);
    final maximumHeight =
        scene.heightLevels.reduce(math.max) * scene.levelHeight;
    (camera as AdaptiveCamera3D).sceneRadius = math.max(
      math.max(scene.width, scene.depth).toDouble(),
      32 * scene.levelHeight,
    );
    for (final neighbor in configuration.neighbors) {
      final neighborScene = neighbor.map.spatialScene;
      if (neighborScene == null) continue;
      final radius = math.max(
        neighbor.offset.dx.abs() + neighborScene.width,
        neighbor.offset.dy.abs() + neighborScene.depth,
      );
      (camera as AdaptiveCamera3D).sceneRadius = math.max(
        (camera as AdaptiveCamera3D).sceneRadius,
        radius,
      );
    }
    var pitch = control.pitch;
    var yaw = control.yaw;
    camera.fovY = 40;
    final aspect = size.y > 0 ? size.x / size.y : 1.0;
    var distance =
        math.max(math.max(scene.width, scene.depth), maximumHeight) /
        (2 * math.tan(math.pi / 9) * math.min(1.0, aspect)) *
        1.35 *
        control.zoom;
    if (control.view == SpatialEditorView.top) {
      pitch = math.pi / 2 - 0.0001;
      yaw = 0;
    } else if (control.view == SpatialEditorView.game) {
      pitch = scene.camera.pitchDegrees * math.pi / 180;
      yaw = scene.camera.yawDegrees * math.pi / 180;
      distance = scene.camera.distance * control.zoom * (cameraPose?.zoom ?? 1);
      camera.fovY = scene.camera.fieldOfViewDegrees;
    }
    center.x += control.pan.dx + configuration.sceneOffset.dx;
    center.z += control.pan.dy + configuration.sceneOffset.dy;
    billboardPitch = pitch;
    billboardYaw = yaw;
    (camera as AdaptiveCamera3D).frame(
      center,
      pitch: pitch,
      yaw: yaw,
      distance: distance,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!sceneReady || closed || refreshing) return;
    if (grounds.any((ground) => ground.plan.animated)) {
      if (dt.isFinite && dt > 0) groundElapsed += dt;
      for (final ground in grounds.where((ground) => ground.plan.animated)) {
        final previous = ground.components;
        if (ground.resolve((groundElapsed * 1000).round())) {
          sceneComponents.replaceSubset(previous, ground.components);
        }
      }
    }
    syncActors(dt);
    syncRuntimeModels();
  }

  void syncRuntimeModels() {
    final provider = visibleConfiguration.modelRuntimeState;
    if (provider == null) return;
    for (final entry in animationModels.entries) {
      final state = provider(entry.key.$1, entry.key.$2);
      final component = entry.value;
      final map = entry.key.$1 == visibleConfiguration.groundMap?.id
          ? visibleConfiguration.groundMap
          : visibleConfiguration.neighbors
                .where((neighbor) => neighbor.map.id == entry.key.$1)
                .firstOrNull
                ?.map;
      final instance = (map?.spatialScene ?? visibleConfiguration.scene)
          .instances
          .where((value) => value.id == entry.key.$2)
          .firstOrNull;
      if (instance == null) continue;
      component.bindRuntimeState(
        state,
        authoredAnimationIndex: instance.animationIndex,
        authoredLoop: instance.animationLoop,
        authoredSpeed: instance.animationSpeed,
        paused:
            (visibleConfiguration.presentationPaused?.call() ?? false) ||
            (visibleConfiguration.animationPreview?.isPaused(instance.id) ??
                false),
      );
    }
  }

  void syncActors(double dt) {
    final configuration = visibleConfiguration;
    final frames =
        configuration.actorFrames?.call(dt) ??
        const <String, SpatialActorVisual>{};
    actorVisual = frames['hero'];
    for (final id
        in actors.keys.where((id) => !frames.containsKey(id)).toList()) {
      actors.remove(id)!.mesh.removeFromParent();
      actorSelections.remove(id);
    }
    for (final entry in frames.entries) {
      final frame = entry.value;
      var actor = actors[entry.key];
      if (actor == null) {
        final actorMaterial = SpatialPixelMaterial(frame.texture.texture);
        const width = 1.92;
        final mesh = Mesh()
          ..addSurface(
            Surface(
              vertices: [
                Vertex(
                  position: Vector3(-width / 2, 0, 0),
                  texCoord: Vector2(0, 1),
                ),
                Vertex(
                  position: Vector3(width / 2, 0, 0),
                  texCoord: Vector2(1, 1),
                ),
                Vertex(
                  position: Vector3(width / 2, 1.92, 0),
                  texCoord: Vector2(1, 0),
                ),
                Vertex(
                  position: Vector3(-width / 2, 1.92, 0),
                  texCoord: Vector2(0, 0),
                ),
              ],
              indices: [0, 1, 2, 2, 3, 0],
              material: actorMaterial,
            ),
          );
        actor = (mesh: MeshComponent(mesh: mesh), material: actorMaterial);
        actors[entry.key] = actor;
        world.add(actor.mesh);
      }
      final preview = configuration.contentPreview;
      final position =
          preview?.kind == SpatialSceneContentKind.actor &&
              preview?.id == entry.key
          ? preview!.position
          : null;
      actor.mesh.position.setValues(
        (position?.x ?? frame.x) + configuration.sceneOffset.dx,
        (position?.y ?? frame.y) + .02,
        (position?.z ?? frame.z) + configuration.sceneOffset.dy,
      );
      final transform = spatialActorTransform(
        SpatialCameraProfile(
          pitchDegrees: billboardPitch * 180 / math.pi,
          yawDegrees: billboardYaw * 180 / math.pi,
        ),
      );
      actor.mesh.rotation.setFrom(transform.rotation);
      actor.mesh.scale.setFrom(transform.scale);
      if (configuration.controller.view == SpatialEditorView.top) {
        actor.mesh.rotation.setFrom(
          Quaternion.axisAngle(Vector3(1, 0, 0), -math.pi / 2),
        );
        actor.mesh.scale.setValues(1, 1, 1);
      }
      actor.mesh.scale.x *= frame.resolvedWidth / 1.92;
      actor.mesh.scale.y *= frame.height / 1.92;
      final selected =
          configuration.selectedContent?.kind ==
              SpatialSceneContentKind.actor &&
          configuration.selectedContent?.id == entry.key;
      if (selected && !actorSelections.containsKey(entry.key)) {
        final selection = spatialSelectionFrame(
          Vector3(-.96, 0, 0),
          Vector3(.96, 1.92, 0),
          .04,
          configuration.selectionColor ?? configuration.edge,
        );
        actorSelections[entry.key] = selection;
        actor.mesh.addAll(selection);
      } else if (!selected && actorSelections.containsKey(entry.key)) {
        actor.mesh.removeAll(actorSelections.remove(entry.key)!);
      }
      final texture = frame.texture.texture;
      actor.material
        ..albedoTexture = texture
        ..uvRect.setValues(
          frame.frame.left / texture.width,
          frame.frame.top / texture.height,
          frame.frame.width / texture.width,
          frame.frame.height / texture.height,
        );
    }
    syncCamera();
  }

  String? pickActor(Offset offset) {
    if (refreshing) return null;
    String? result;
    var nearest = double.infinity;
    for (final entry in actors.entries) {
      final actor = entry.value.mesh;
      final matrix = Matrix4.compose(
        actor.position,
        actor.rotation,
        actor.scale,
      );
      final projected = <Offset>[];
      var depth = 0.0;
      for (final corner in [
        Vector3(-.96, 0, 0),
        Vector3(.96, 0, 0),
        Vector3(.96, 1.92, 0),
        Vector3(-.96, 1.92, 0),
      ]) {
        final world = matrix.transform3(corner);
        final clip = camera.viewProjectionMatrix.transform(
          Vector4(world.x, world.y, world.z, 1),
        );
        if (clip.w <= 0) {
          projected.clear();
          break;
        }
        projected.add(
          Offset(
            (clip.x / clip.w + 1) * size.x / 2,
            (1 - clip.y / clip.w) * size.y / 2,
          ),
        );
        depth += clip.z / clip.w;
      }
      if (projected.isEmpty) continue;
      final bounds = Rect.fromLTRB(
        projected.map((p) => p.dx).reduce(math.min),
        projected.map((p) => p.dy).reduce(math.min),
        projected.map((p) => p.dx).reduce(math.max),
        projected.map((p) => p.dy).reduce(math.max),
      );
      if (bounds.contains(offset) && depth < nearest) {
        result = entry.key;
        nearest = depth;
      }
    }
    return result;
  }

  SpatialSceneContentHit? pickContent(Offset offset) {
    if (refreshing) return null;
    final configuration = visibleConfiguration;
    final cell = pickCell(offset);
    for (final overlay in configuration.cellOverlays.reversed) {
      if (overlay.cell == cell &&
          (overlay.kind == SpatialCellOverlayKind.spawn ||
              overlay.kind == SpatialCellOverlayKind.warp)) {
        return SpatialSceneContentHit(
          kind: overlay.kind == SpatialCellOverlayKind.spawn
              ? SpatialSceneContentKind.marker
              : SpatialSceneContentKind.warp,
          id: overlay.id,
          cell: overlay.cell,
        );
      }
    }
    final actorId = pickActor(offset);
    if (actorId != null) {
      final actor = actors[actorId]!.mesh;
      return SpatialSceneContentHit(
        kind: SpatialSceneContentKind.actor,
        id: actorId,
        cell: (
          (actor.position.x - configuration.sceneOffset.dx).floor(),
          (actor.position.z - configuration.sceneOffset.dy).floor(),
        ),
      );
    }
    final model = pickModel(offset);
    return model == null
        ? null
        : SpatialSceneContentHit(
            kind: SpatialSceneContentKind.model,
            id: model.id,
            cell: (model.position.x.floor(), model.position.z.floor()),
          );
  }

  (int, int)? pickContentCell(Offset offset) =>
      pickContent(offset)?.cell ?? pickCell(offset);
  SpatialModelInstance? pickModel(Offset offset) {
    if (refreshing) return null;
    final configuration = visibleConfiguration;
    SpatialModelInstance? selected;
    var nearest = double.infinity;
    for (final instance in configuration.scene.instances) {
      final definition = configuration.models
          .where((model) => model.id == instance.modelId)
          .firstOrNull;
      if (definition == null) continue;
      final bounds = definition.inspection.bounds;
      final angle = instance.rotationDegrees * math.pi / 180;
      final scale = instance.scale * definition.scale;
      final projected = <Offset>[];
      var depth = 0.0;
      for (final x in [bounds.min.x, bounds.max.x]) {
        for (final y in [bounds.min.y, bounds.max.y]) {
          for (final z in [bounds.min.z, bounds.max.z]) {
            final dx = (x - definition.pivot.x) * scale;
            final dz = (z - definition.pivot.z) * scale;
            final worldX =
                instance.position.x +
                configuration.sceneOffset.dx +
                dx * math.cos(angle) +
                dz * math.sin(angle);
            final worldZ =
                instance.position.z +
                configuration.sceneOffset.dy -
                dx * math.sin(angle) +
                dz * math.cos(angle);
            final clip = camera.viewProjectionMatrix.transform(
              Vector4(
                worldX,
                instance.position.y + (y - definition.pivot.y) * scale,
                worldZ,
                1,
              ),
            );
            if (clip.w <= 0) continue;
            projected.add(
              Offset(
                (clip.x / clip.w + 1) * size.x / 2,
                (1 - clip.y / clip.w) * size.y / 2,
              ),
            );
            depth += clip.z / clip.w;
          }
        }
      }
      if (projected.length != 8) continue;
      final rect = Rect.fromLTRB(
        projected.map((point) => point.dx).reduce(math.min),
        projected.map((point) => point.dy).reduce(math.min),
        projected.map((point) => point.dx).reduce(math.max),
        projected.map((point) => point.dy).reduce(math.max),
      );
      if (rect.contains(offset) && depth < nearest) {
        selected = instance;
        nearest = depth;
      }
    }
    return selected;
  }

  double? contentHeight(SpatialSceneContentHit hit, Offset offset) {
    final ray = pointerRay(offset);
    return ray == null
        ? null
        : spatialContentDragHeight(ray.$1, ray.$2, hit.cell);
  }

  (int, int)? pickPlaneCell(Offset offset, double height) {
    final ray = pointerRay(offset);
    return ray == null ? null : pickSpatialPlaneCell(ray.$1, ray.$2, height);
  }

  (int, int)? pickCell(Offset offset) => pickSurface(offset)?.cell;

  SpatialSurfaceHit? pickSurface(Offset offset) {
    final ray = pointerRay(offset);
    return ray == null
        ? null
        : pickSpatialSurface(visibleConfiguration.scene, ray.$1, ray.$2);
  }

  (Vector3, Vector3)? pointerRay(Offset offset) {
    if (!sceneReady || refreshing || size.x <= 0 || size.y <= 0) return null;
    final inverse = Matrix4.copy(camera.viewProjectionMatrix);
    if (inverse.invert() == 0) return null;
    final x = offset.dx / size.x * 2 - 1;
    final y = 1 - offset.dy / size.y * 2;
    Vector3 unproject(double z) {
      final point = inverse.transform(Vector4(x, y, z, 1));
      return Vector3(point.x / point.w, point.y / point.w, point.z / point.w);
    }

    final start = unproject(-1);
    final direction = unproject(1) - start;
    final sceneOffset = visibleConfiguration.sceneOffset;
    start.x -= sceneOffset.dx;
    start.z -= sceneOffset.dy;
    return (start, direction);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (sceneReady) {
      syncCamera();
      if (configuration.onHover != null) onSurfaceChanged();
    }
  }

  @override
  void onRemove() {
    closed = true;
    generation++;
    sceneComponents.dispose();
    placementRenderer.dispose();
    configuration.controller.removeListener(syncCamera);
    configuration.animationPreview?.removeListener(syncAnimations);
    cache.clear();
    modelComponents.clear();
    animationModels.clear();
    groundTextureCache.clear();
    grounds.clear();
    actorSelections.clear();
    super.onRemove();
  }
}

bool _sameNeighbors(
  List<SpatialSceneNeighbor> before,
  List<SpatialSceneNeighbor> after,
) {
  if (before.length != after.length) return false;
  for (var index = 0; index < before.length; index++) {
    if (!identical(before[index].map, after[index].map) ||
        before[index].offset != after[index].offset) {
      return false;
    }
  }
  return true;
}

final class _SceneGround {
  _SceneGround(this.plan, this.textures, this.offset);

  final SpatialGroundPlan plan;
  final Map<String, Texture> textures;
  final Offset offset;
  List<SpatialGroundVisual> visuals = [];
  List<MeshComponent> components = [];

  bool resolve(int elapsedMs) {
    final next = plan.resolve(elapsedMs);
    var changed = components.isEmpty || next.length != visuals.length;
    for (var index = 0; !changed && index < next.length; index++) {
      final before = visuals[index].visual, after = next[index].visual;
      changed =
          before.sourceRect != after.sourceRect ||
          before.tilesetId != after.tilesetId ||
          before.transform != after.transform ||
          before.geometry.visualBounds != after.geometry.visualBounds;
    }
    if (!changed) return false;
    visuals = next;
    components = [
      for (final mesh in spatialGroundMeshes(
        visuals,
        textures,
        scene: plan.scene,
      ))
        MeshComponent(mesh: mesh, position: Vector3(offset.dx, 0, offset.dy)),
    ];
    return true;
  }
}

class _SceneModelComponent extends AnimatedModelComponent {
  _SceneModelComponent({
    required super.model,
    super.position,
    super.rotation,
    super.scale,
    super.children,
    super.playback,
    super.runtimePoseBefore,
  });
  @override
  bool isVisible(CameraComponent3D camera) => true;
}

Iterable<Mesh> terrainMeshes(
  MapSpatialScene scene,
  Color ground,
  Color edge, {
  (int, int)? selectedCell,
  ({Texture texture, SmartTileSourceRect sourceRect})? cliffTexture,
}) sync* {
  final groups =
      <(Color, bool), ({List<Vertex> vertices, List<int> indices})>{};
  var vertexCount = 0;
  if (cliffTexture != null) {
    final rect = cliffTexture.sourceRect, texture = cliffTexture.texture;
    if (rect.x < 0 ||
        rect.y < 0 ||
        rect.width <= 0 ||
        rect.height <= 0 ||
        rect.x + rect.width > texture.width ||
        rect.y + rect.height > texture.height) {
      throw StateError('Frame de falaise hors de son atlas.');
    }
  }
  Mesh flush() {
    final mesh = Mesh();
    for (final entry in groups.entries) {
      final cliff = cliffTexture;
      final material = entry.key.$2 && cliff != null
          ? (SpatialPixelMaterial(cliff.texture)
              ..uvRect.setValues(
                cliff.sourceRect.x / cliff.texture.width,
                cliff.sourceRect.y / cliff.texture.height,
                cliff.sourceRect.width / cliff.texture.width,
                cliff.sourceRect.height / cliff.texture.height,
              ))
          : UnlitMaterial(albedoColor: entry.key.$1);
      mesh.addSurface(
        Surface(
          vertices: entry.value.vertices,
          indices: entry.value.indices,
          material: material,
        ),
      );
    }
    groups.clear();
    vertexCount = 0;
    return mesh;
  }

  for (final face in spatialTerrainFaces(scene)) {
    if (vertexCount + face.positions.length > 60000) yield flush();
    final (x, z) = face.cell;
    final color = !face.isTop
        ? edge
        : selectedCell == face.cell
        ? Color.lerp(ground, edge, .8)!
        : (x + z).isEven
        ? ground
        : Color.lerp(ground, edge, .15)!;
    final textured = !face.isTop && cliffTexture != null;
    final group = groups.putIfAbsent((
      color,
      textured,
    ), () => (vertices: <Vertex>[], indices: <int>[]));
    final base = group.vertices.length;
    for (var index = 0; index < face.positions.length; index++) {
      group.vertices.add(
        Vertex(
          position: face.positions[index],
          texCoord: face.uvs[index],
          color: textured ? const Color(0xffffffff) : color,
        ),
      );
    }
    for (var index = 1; index < face.positions.length - 1; index++) {
      group.indices.addAll([base, base + index, base + index + 1]);
    }
    vertexCount += face.positions.length;
  }
  if (vertexCount > 0) yield flush();
}
