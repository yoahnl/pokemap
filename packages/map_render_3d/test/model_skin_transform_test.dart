import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:flame_3d/src/parser/gltf/animation_interpolation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/model_playback.dart';

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _CaptureContext extends RenderContext3D {
  _CaptureContext() : super(GraphicsDevice(backend: _UnusedBackend()));
  final snapshots = <Mesh, ({Matrix4 model, List<Matrix4> joints})>{};

  @override
  void drawMesh(Mesh mesh) {
    snapshots[mesh] = (
      model: Matrix4.copy(model),
      joints: [
        for (final joint in jointsInfo.jointTransformsPerSurface[0] ?? [])
          Matrix4.copy(joint),
      ],
    );
  }
}

Mesh triangle({bool skin = false}) {
  final surface = Surface(
    vertices: [
      Vertex(position: Vector3.zero(), texCoord: Vector2.zero()),
      Vertex(position: Vector3(1, 0, 0), texCoord: Vector2.zero()),
      Vertex(position: Vector3(0, 1, 0), texCoord: Vector2.zero()),
    ],
    indices: [0, 1, 2],
    jointMap: skin ? {0: 0} : null,
  );
  return Mesh()..addSurface(surface);
}

({Model model, Mesh skin, Mesh plain, Mesh attachment}) fixture() {
  final skin = triangle(skin: true);
  final plain = triangle();
  final attachment = triangle();
  ModelNode node(
    int id, {
    int? parent,
    double x = 0,
    Mesh? mesh,
    Map<int, ModelJoint> joints = const {},
  }) => ModelNode(
    name: '$id',
    nodeIndex: id,
    parentNodeIndex: parent,
    transform: Matrix4.translationValues(x, 0, 0),
    mesh: mesh,
    joints: joints,
  );
  final animation = ModelAnimation(
    name: 'move',
    nodes: {
      3: NodeAnimation(
        channels: [
          AnimationController<Vector3>(
            animation: TranslationAnimationSpline.from(
              interpolation: AnimationInterpolation.linear,
              times: [0, 1],
              values: [Vector3(1, 0, 0), Vector3(5, 0, 0)],
            ),
          ),
        ],
      ),
    },
  );
  return (
    model: Model(
      nodes: {
        1: node(
          1,
          parent: 0,
          x: 20,
          mesh: skin,
          joints: {
            0: ModelJoint(
              nodeIndex: 3,
              inverseBindMatrix: Matrix4.translationValues(-2, 0, 0),
            ),
          },
        ),
        4: node(4, parent: 0, x: 4, mesh: plain),
        5: node(5, parent: 1, x: 6, mesh: attachment),
        3: node(3, parent: 2, x: 1),
        2: node(2, x: 3),
        0: node(0, x: 10),
      },
      animations: [animation],
    ),
    skin: skin,
    plain: plain,
    attachment: attachment,
  );
}

double skinnedOrigin(({Matrix4 model, List<Matrix4> joints}) snapshot) =>
    snapshot.model
        .multiplied(snapshot.joints.single)
        .transform3(Vector3.zero())
        .x;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final variant in ['flame', 'avelune']) {
    test(
      '$variant ignores mesh parent transforms for skins while animating joints',
      () {
        final f = fixture();
        final component = variant == 'flame'
            ? ModelComponent(model: f.model, position: Vector3(100, 0, 0))
            : AnimatedModelComponent(
                model: f.model,
                position: Vector3(100, 0, 0),
              );
        final context = _CaptureContext();
        component.playAnimationByIndex(0);
        component.draw(context);
        expect(skinnedOrigin(context.snapshots[f.skin]!), closeTo(102, 1e-6));
        expect(
          context.snapshots[f.plain]!.model.getTranslation().x,
          closeTo(114, 1e-6),
        );
        expect(
          context.snapshots[f.attachment]!.model.getTranslation().x,
          closeTo(136, 1e-6),
        );
        component.update(.5);
        component.draw(context);
        expect(skinnedOrigin(context.snapshots[f.skin]!), closeTo(104, 1e-6));
        expect(
          context.snapshots[f.plain]!.model.getTranslation().x,
          closeTo(114, 1e-6),
        );
        expect(
          context.snapshots[f.attachment]!.model.getTranslation().x,
          closeTo(136, 1e-6),
        );
      },
    );
  }
}
