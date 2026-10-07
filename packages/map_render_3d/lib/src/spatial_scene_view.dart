import 'dart:math' as math;
import 'dart:typed_data';

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
import 'spatial_picking.dart';
import 'adaptive_camera.dart';
import 'spatial_actor_visual.dart';
import 'spatial_game_surface.dart';
import 'spatial_pixel_material.dart';
import 'spatial_ground.dart';
import 'spatial_selection.dart';

Future<void> initializeSpatialRenderer() => GpuBackend.initialize();

enum SpatialEditorView { orbit, top, game }

enum SpatialSceneContentKind { actor, model }

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
  });
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
  final MapSpatialScene scene;
  final List<ProjectModel3dEntry> models;
  final Future<Uint8List> Function(String id) loadModel;
  final SpatialSceneController controller;
  final void Function(int x, int z) onCell;
  final Color background, ground, edge;
  final (int, int)? selectedCell;
  final SpatialSceneContentHit? selectedContent;
  final SpatialSceneContentPreview? contentPreview;
  final Color? selectionColor;
  final Widget Function(BuildContext, Object) errorBuilder;
  @override
  State<SpatialSceneView> createState() => _SpatialSceneViewState();
}

class _SpatialSceneViewState extends State<SpatialSceneView> {
  _SpatialGame? game;
  Object? failure;
  bool draggingContent = false;
  SpatialContentDrag? contentDrag;
  double? contentDragHeight;
  double trackpadScale = 1;
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
    initialize();
  }

  Future<void> initialize() async {
    try {
      await initializeSpatialRenderer();
      if (!mounted) return;
      final initialized = _SpatialGame(widget);
      setState(() => game = initialized);
    } on Object catch (error) {
      if (mounted) setState(() => failure = error);
    }
  }

  Future<void> refresh() async {
    try {
      await game?.refresh();
      if (mounted) setState(() => failure = null);
    } on Object catch (error) {
      if (mounted) setState(() => failure = error);
    }
  }

  @override
  void didUpdateWidget(SpatialSceneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final game = this.game;
    if (game == null) return;
    if (oldWidget.controller != widget.controller && game.sceneReady) {
      oldWidget.controller.removeListener(game.syncCamera);
      widget.controller.addListener(game.syncCamera);
    }
    game.configuration = widget;
    game.syncContentPreview();
    if (!identical(oldWidget.groundProject, widget.groundProject)) {
      game.groundTextureCache.clear();
    }
    if (!identical(oldWidget.scene, widget.scene) ||
        !identical(oldWidget.groundMap, widget.groundMap) ||
        !identical(oldWidget.groundProject, widget.groundProject) ||
        !identical(oldWidget.models, widget.models) ||
        oldWidget.selectedCell != widget.selectedCell ||
        oldWidget.selectedContent?.id != widget.selectedContent?.id ||
        oldWidget.selectedContent?.kind != widget.selectedContent?.kind ||
        oldWidget.selectionColor != widget.selectionColor) {
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = this.game;
    return Listener(
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
        zoom(-event.panDelta.dy - math.log(event.scale / trackpadScale) * 1000);
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
                final actorId = game.pickActor(event.localPosition);
                final actor = actorId == null
                    ? null
                    : game.actors[actorId]?.mesh;
                final cell = actor == null
                    ? game.pickContentCell(event.localPosition)
                    : (actor.position.x.floor(), actor.position.z.floor());
                if (cell != null)
                  widget.onContextMenu?.call(
                    GridPos(x: cell.$1, y: cell.$2),
                    event.globalPosition,
                  );
              },
              onPanStart: (event) {
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
                    (widget.onDragStart?.call(cell.$1, cell.$2, hit) ?? false);
                contentDrag = draggingContent
                    ? SpatialContentDrag(anchor: cell!, pointerOrigin: ground!)
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
                final cell = game.pickCell(event.localPosition);
                if (cell != null) widget.onCell(cell.$1, cell.$2);
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SpatialGameSurface<_SpatialGame>(
                      game: game,
                      loadingBuilder: (_) =>
                          const Center(child: Text('Chargement de la scène…')),
                      errorBuilder: widget.errorBuilder,
                    ),
                  ),
                  if (failure != null)
                    Positioned.fill(
                      child: widget.errorBuilder(context, failure!),
                    ),
                ],
              ),
            ),
    );
  }
}

class _SpatialGame extends FlameGame3D<World3D, CameraComponent3D> {
  _SpatialGame(this.configuration)
    : super(world: World3D(), camera: AdaptiveCamera3D(fovY: 40));
  SpatialSceneView configuration;
  final Map<String, Future<Model>> cache = {};
  Map<
    String,
    ({_SceneModelComponent component, Vector3 position, Model3dVector3 anchor})
  >
  modelComponents = {};
  bool sceneReady = false, closed = false;
  final actorSelections = <String, List<MeshComponent>>{};
  int generation = 0;
  final actors =
      <String, ({MeshComponent mesh, SpatialPixelMaterial material})>{};
  SpatialActorVisual? actorVisual;
  double billboardPitch = 0, billboardYaw = 0;
  final groundTextureCache = <String, Future<Texture>>{};
  Map<String, Texture> groundTextures = {};
  SpatialGroundPlan? groundPlan;
  List<SpatialGroundVisual> groundVisuals = [];
  List<MeshComponent> groundComponents = [];
  double groundElapsed = 0;
  @override
  Color backgroundColor() => configuration.background;
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (closed) return;
    sceneReady = true;
    configuration.controller.addListener(syncCamera);
    await refresh();
    if (!closed) configuration.onReady?.call();
  }

  Future<void> refresh() async {
    if (!sceneReady || closed) return;
    final ticket = ++generation;
    final scene = configuration.scene;
    final definitions = {
      for (final model in configuration.models) model.id: model,
    };
    final components = <Object3D>[];
    final nextModelComponents =
        <
          String,
          ({
            _SceneModelComponent component,
            Vector3 position,
            Model3dVector3 anchor,
          })
        >{};
    final map = configuration.groundMap;
    final project = configuration.groundProject;
    final loader = configuration.loadGroundImage;
    SpatialGroundPlan? nextGroundPlan;
    final nextTextures = <String, Texture>{};
    if (map != null && map.layers.isNotEmpty) {
      if (project == null || loader == null) {
        throw StateError('Les ressources du sol 3D sont indisponibles.');
      }
      nextGroundPlan = SpatialGroundPlan(map, project);
      for (final id in nextGroundPlan.imageIds) {
        try {
          nextTextures[id] = await groundTextureCache.putIfAbsent(
            id,
            () async => loadSpatialGroundTexture(
              await loader(id),
              transparentColor: project.tilesets
                  .where((tileset) => tileset.id == id)
                  .firstOrNull
                  ?.transparentColor,
            ),
          );
        } on Object {
          groundTextureCache.remove(id);
          rethrow;
        }
        if (ticket != generation || closed) return;
      }
    }
    for (final mesh in terrainMeshes(
      scene,
      configuration.ground,
      configuration.edge,
      selectedCell: configuration.selectedCell,
    )) {
      components.add(MeshComponent(mesh: mesh));
    }
    for (final instance in scene.instances) {
      final definition = definitions[instance.modelId];
      if (definition == null) {
        throw StateError('Modèle absent : ${instance.modelId}');
      }
      final model = await cache.putIfAbsent(
        definition.sourceAssetId,
        () async =>
            ModelByteLoader.load(await configuration.loadModel(definition.id)),
      );
      if (ticket != generation || closed) return;
      final scale = definition.scale * instance.scale;
      final rotation = Quaternion.axisAngle(
        Vector3(0, 1, 0),
        instance.rotationDegrees * math.pi / 180,
      );
      final pivot =
          Vector3(definition.pivot.x, definition.pivot.y, definition.pivot.z) *
          scale;
      rotation.rotate(pivot);
      final component = _SceneModelComponent(
        model: model,
        position:
            Vector3(
              instance.position.x,
              instance.position.y,
              instance.position.z,
            ) -
            pivot,
        rotation: rotation,
        scale: Vector3.all(scale),
        children:
            configuration.selectedContent?.kind ==
                    SpatialSceneContentKind.model &&
                configuration.selectedContent?.id == instance.id
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
                configuration.selectionColor ?? configuration.edge,
              )
            : const [],
      );
      if (instance.animationIndex case final index?) {
        component.playAnimationByIndex(index);
      }
      components.add(component);
      nextModelComponents[instance.id] = (
        component: component,
        position: component.position.clone(),
        anchor: instance.position,
      );
    }
    if (ticket != generation || closed) return;
    groundPlan = nextGroundPlan;
    groundTextures = nextTextures;
    groundVisuals = groundPlan?.resolve((groundElapsed * 1000).round()) ?? [];
    groundComponents = [
      for (final mesh in spatialGroundMeshes(groundVisuals, groundTextures))
        MeshComponent(mesh: mesh),
    ];
    components.addAll(groundComponents);
    for (final entry in actorSelections.entries) {
      actors[entry.key]?.mesh.removeAll(entry.value);
    }
    actorSelections.clear();
    world.removeAll(world.children.toList());
    await world.add(LightComponent.ambient(intensity: 0.85));
    await world.addAll(components);
    await world.addAll(actors.values.map((actor) => actor.mesh));
    modelComponents = nextModelComponents;
    syncContentPreview();
    syncCamera();
  }

  void syncContentPreview() {
    final preview = configuration.contentPreview;
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

  void syncCamera() {
    final scene = configuration.scene;
    final control = configuration.controller;
    final visual = actorVisual;
    final center = visual == null
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
      distance = scene.camera.distance * control.zoom;
      camera.fovY = scene.camera.fieldOfViewDegrees;
    }
    center.x += control.pan.dx;
    center.z += control.pan.dy;
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
    if (!sceneReady || closed) return;
    if (groundPlan?.animated ?? false) {
      if (dt.isFinite && dt > 0) groundElapsed += dt;
      final next = groundPlan!.resolve((groundElapsed * 1000).round());
      var changed = next.length != groundVisuals.length;
      for (var index = 0; !changed && index < next.length; index++) {
        final before = groundVisuals[index].visual, after = next[index].visual;
        changed =
            before.sourceRect != after.sourceRect ||
            before.tilesetId != after.tilesetId ||
            before.transform != after.transform ||
            before.geometry.visualBounds != after.geometry.visualBounds;
      }
      if (changed) {
        world.removeAll(groundComponents);
        groundVisuals = next;
        groundComponents = [
          for (final mesh in spatialGroundMeshes(next, groundTextures))
            MeshComponent(mesh: mesh),
        ];
        world.addAll(groundComponents);
      }
    }
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
        position?.x ?? frame.x,
        (position?.y ?? frame.y) + .02,
        position?.z ?? frame.z,
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
      actor.mesh.scale.x *= frame.frame.width / frame.frame.height;
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
    final actorId = pickActor(offset);
    if (actorId != null) {
      final actor = actors[actorId]!.mesh;
      return SpatialSceneContentHit(
        kind: SpatialSceneContentKind.actor,
        id: actorId,
        cell: (actor.position.x.floor(), actor.position.z.floor()),
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
                dx * math.cos(angle) +
                dz * math.sin(angle);
            final worldZ =
                instance.position.z -
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

  (int, int)? pickCell(Offset offset) {
    final ray = pointerRay(offset);
    return ray == null
        ? null
        : pickSpatialCell(configuration.scene, ray.$1, ray.$2);
  }

  (Vector3, Vector3)? pointerRay(Offset offset) {
    if (!sceneReady || size.x <= 0 || size.y <= 0) return null;
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
    return (start, direction);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (sceneReady) syncCamera();
  }

  @override
  void onRemove() {
    closed = true;
    generation++;
    configuration.controller.removeListener(syncCamera);
    cache.clear();
    modelComponents.clear();
    groundTextureCache.clear();
    groundTextures.clear();
    groundComponents.clear();
    groundVisuals = [];
    groundPlan = null;
    actorSelections.clear();
    super.onRemove();
  }
}

class _SceneModelComponent extends ModelComponent {
  _SceneModelComponent({
    required super.model,
    super.position,
    super.rotation,
    super.scale,
    super.children,
  });
  @override
  bool isVisible(CameraComponent3D camera) => true;
}

Iterable<Mesh> terrainMeshes(
  MapSpatialScene scene,
  Color ground,
  Color edge, {
  (int, int)? selectedCell,
}) sync* {
  final groups = <Color, ({List<Vertex> vertices, List<int> indices})>{};
  var vertexCount = 0;
  void quad(List<Vector3> positions, Color color) {
    final group = groups.putIfAbsent(
      color,
      () => (vertices: <Vertex>[], indices: <int>[]),
    );
    final vertices = group.vertices;
    final indices = group.indices;
    final base = vertices.length;
    vertices.addAll(
      positions.map(
        (p) => Vertex(position: p, texCoord: Vector2.zero(), color: color),
      ),
    );
    indices.addAll([base, base + 1, base + 2, base, base + 2, base + 3]);
    vertexCount += 4;
  }

  Mesh flush() {
    final mesh = Mesh();
    for (final entry in groups.entries) {
      mesh.addSurface(
        Surface(
          vertices: entry.value.vertices,
          indices: entry.value.indices,
          material: UnlitMaterial(albedoColor: entry.key),
        ),
      );
    }
    groups.clear();
    vertexCount = 0;
    return mesh;
  }

  for (var z = 0; z < scene.depth; z++) {
    for (var x = 0; x < scene.width; x++) {
      final a = x.toDouble(), b = z.toDouble(), h = scene.heightAt(x, z);
      final color = selectedCell == (x, z)
          ? Color.lerp(ground, edge, .8)!
          : (x + z).isEven
          ? ground
          : Color.lerp(ground, edge, 0.15)!;
      quad([
        Vector3(a, h, b),
        Vector3(a, h, b + 1),
        Vector3(a + 1, h, b + 1),
        Vector3(a + 1, h, b),
      ], color);
      final left = x == 0 ? -0.15 : scene.heightAt(x - 1, z);
      final right = x == scene.width - 1 ? -0.15 : scene.heightAt(x + 1, z);
      final back = z == 0 ? -0.15 : scene.heightAt(x, z - 1);
      final front = z == scene.depth - 1 ? -0.15 : scene.heightAt(x, z + 1);
      if (h > left)
        quad([
          Vector3(a, left, b),
          Vector3(a, left, b + 1),
          Vector3(a, h, b + 1),
          Vector3(a, h, b),
        ], edge);
      if (h > right)
        quad([
          Vector3(a + 1, right, b + 1),
          Vector3(a + 1, right, b),
          Vector3(a + 1, h, b),
          Vector3(a + 1, h, b + 1),
        ], edge);
      if (h > back)
        quad([
          Vector3(a + 1, back, b),
          Vector3(a, back, b),
          Vector3(a, h, b),
          Vector3(a + 1, h, b),
        ], edge);
      if (h > front)
        quad([
          Vector3(a, front, b + 1),
          Vector3(a + 1, front, b + 1),
          Vector3(a + 1, h, b + 1),
          Vector3(a, h, b + 1),
        ], edge);
      if (vertexCount > 60000) yield flush();
    }
  }
  if (vertexCount > 0) yield flush();
}
