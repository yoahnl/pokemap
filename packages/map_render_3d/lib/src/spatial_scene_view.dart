import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flame/game.dart' show GameWidget;
import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter/gestures.dart' hide Matrix4;
import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:map_core/map_core.dart';

import 'model_byte_loader.dart';
import 'model_preview.dart';
import 'spatial_picking.dart';
import 'adaptive_camera.dart';

enum SpatialEditorView { orbit, top, game }

class SpatialSceneController extends ModelPreviewController {
  SpatialEditorView view = SpatialEditorView.orbit;
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
  });
  final MapSpatialScene scene;
  final List<ProjectModel3dEntry> models;
  final Future<Uint8List> Function(String id) loadModel;
  final SpatialSceneController controller;
  final void Function(int x, int z) onCell;
  final Color background, ground, edge;
  final (int, int)? selectedCell;
  final Widget Function(BuildContext, Object) errorBuilder;
  @override
  State<SpatialSceneView> createState() => _SpatialSceneViewState();
}

class _SpatialSceneViewState extends State<SpatialSceneView> {
  late final game = _SpatialGame(widget);
  Object? failure;
  Future<void> refresh() async {
    try {
      await game.refresh();
      if (mounted) setState(() => failure = null);
    } on Object catch (error) {
      if (mounted) setState(() => failure = error);
    }
  }

  @override
  void didUpdateWidget(SpatialSceneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller && game.sceneReady) {
      oldWidget.controller.removeListener(game.syncCamera);
      widget.controller.addListener(game.syncCamera);
    }
    game.configuration = widget;
    if (!identical(oldWidget.scene, widget.scene) ||
        !identical(oldWidget.models, widget.models) ||
        oldWidget.selectedCell != widget.selectedCell) {
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: (event) {
      if (event is PointerScrollEvent &&
          widget.controller.view != SpatialEditorView.game) {
        GestureBinding.instance.pointerSignalResolver.register(
          event,
          (_) => widget.controller.dolly(event.scrollDelta.dy),
        );
      }
    },
    child: GestureDetector(
      onPanUpdate: (event) {
        if (widget.controller.view == SpatialEditorView.orbit) {
          widget.controller.orbit(event.delta.dx, event.delta.dy);
        }
      },
      onTapUp: (event) {
        final cell = game.pickCell(event.localPosition);
        if (cell != null) widget.onCell(cell.$1, cell.$2);
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: GameWidget<_SpatialGame>(
              game: game,
              loadingBuilder: (_) =>
                  const Center(child: Text('Chargement de la scène…')),
              errorBuilder: widget.errorBuilder,
            ),
          ),
          if (failure != null)
            Positioned.fill(child: widget.errorBuilder(context, failure!)),
        ],
      ),
    ),
  );
}

class _SpatialGame extends FlameGame3D<World3D, CameraComponent3D> {
  _SpatialGame(this.configuration)
    : super(world: World3D(), camera: AdaptiveCamera3D(fovY: 40));
  SpatialSceneView configuration;
  final Map<String, Future<Model>> cache = {};
  bool sceneReady = false, closed = false;
  int generation = 0;
  @override
  Color backgroundColor() => configuration.background;
  @override
  Future<void> onLoad() async {
    await GpuBackend.initialize();
    await super.onLoad();
    if (closed) return;
    sceneReady = true;
    configuration.controller.addListener(syncCamera);
    await refresh();
  }

  Future<void> refresh() async {
    if (!sceneReady || closed) return;
    final ticket = ++generation;
    final scene = configuration.scene;
    final definitions = {
      for (final model in configuration.models) model.id: model,
    };
    final components = <Object3D>[];
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
      );
      if (instance.animationIndex case final index?) {
        component.playAnimationByIndex(index);
      }
      components.add(component);
    }
    if (ticket != generation || closed) return;
    world.removeAll(world.children.toList());
    await world.add(LightComponent.ambient(intensity: 0.85));
    await world.addAll(components);
    syncCamera();
  }

  void syncCamera() {
    final scene = configuration.scene;
    final control = configuration.controller;
    final center = Vector3(
      scene.width / 2,
      scene.heightAt(scene.width ~/ 2, scene.depth ~/ 2),
      scene.depth / 2,
    );
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
      distance = scene.camera.distance;
      camera.fovY = scene.camera.fieldOfViewDegrees;
    }
    (camera as AdaptiveCamera3D).frame(
      center,
      pitch: pitch,
      yaw: yaw,
      distance: distance,
    );
  }

  (int, int)? pickCell(Offset offset) {
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
    return pickSpatialCell(configuration.scene, start, direction);
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
    super.onRemove();
  }
}

class _SceneModelComponent extends ModelComponent {
  _SceneModelComponent({
    required super.model,
    super.position,
    super.rotation,
    super.scale,
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
