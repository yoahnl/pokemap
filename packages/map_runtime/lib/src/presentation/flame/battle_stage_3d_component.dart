import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import 'battle_perspective_camera.dart';
import 'battle_scene_combatant_component.dart';
import 'battle_scene_layout.dart';

final class BattleStage3DComponent extends Component {
  BattleStage3DComponent({
    required this.camera,
    required this.layout,
    required this.combatants,
    required this.platforms,
    required this.paintFloor,
  }) : super(priority: 6);

  final BattlePerspectiveCamera camera;
  final BattleSceneLayout Function() layout;
  final Map<BattleSlotRef, BattleSceneCombatantComponent> Function() combatants;
  final Map<BattleSlotRef, BattleCombatantSceneGeometry> Function() platforms;
  final bool paintFloor;
  BattleStage3D? _stage;
  bool _closed = false;
  BattleSceneLayout? _groundLayout;
  int _groundCount = 0;
  List<BattleStageGround> _ground = const [];

  bool get isReady => _stage != null;

  @override
  Future<void> onLoad() async {
    final loadingGame = findGame();
    final loadingParent = parent;
    if (loadingGame?.buildContext == null) return;
    bool isCurrentOwner() =>
        !_closed &&
        !isRemoving &&
        !isRemoved &&
        identical(parent, loadingParent) &&
        identical(findGame(), loadingGame);
    try {
      final stage = await BattleStage3D.create(camera.viewport.size);
      if (!isCurrentOwner()) {
        stage.dispose();
        return;
      }
      _stage = stage;
    } catch (error) {
      if (!isCurrentOwner()) return;
      final message = error.toString();
      if (!message.contains(
            'Flutter GPU requires the Impeller rendering backend',
          ) &&
          !message.contains(
            'Flutter GPU must be enabled via the Flutter GPU manifest setting',
          )) {
        rethrow;
      }
      debugPrint(
        '[battle][3D] GPU unavailable; using the software battle presentation: $error',
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final stage = _stage;
    final context = findGame()?.buildContext;
    if (_closed || stage == null || context == null) return;
    final actors = combatants();
    final geometry = platforms();
    final scene = layout();
    if (!identical(scene, _groundLayout) || geometry.length != _groundCount) {
      _groundLayout = scene;
      _groundCount = geometry.length;
      _ground = [
        if (paintFloor)
          BattleStageGround(
            points: [
              Model3dVector3(x: -150, y: -.04, z: -250),
              Model3dVector3(x: 150, y: -.04, z: -250),
              Model3dVector3(x: 150, y: -.04, z: 150),
              Model3dVector3(x: -150, y: -.04, z: 150),
            ],
            color: const Color(0xff64875a),
          ),
        for (final entry in geometry.entries) ...[
          _ellipse(entry.value, .0, 1, const Color(0xff635d3c)),
          _ellipse(entry.value, .015, .94, const Color(0xff819269)),
        ],
      ];
    }
    final visible = stage.render(
      canvas: canvas,
      context: context,
      viewport: scene.arenaRect,
      clip: scene.arenaRect,
      eye: _point(camera.eye),
      aim: _point(camera.aim),
      focal: camera.focal,
      projectionCenter: Offset(
        camera.viewport.center.dx,
        camera.viewport.top + camera.viewport.height * .55,
      ),
      ground: _ground,
      billboards: [
        for (final entry in actors.entries)
          if (entry.value.stageImage != null)
            _billboard(entry.key, entry.value, geometry[entry.key]!.footAnchor),
      ],
    );
    for (final entry in actors.entries) {
      entry.value.renderedBy3DStage = visible.contains(entry.key);
    }
  }

  BattleStageBillboard _billboard(
    BattleSlotRef slot,
    BattleSceneCombatantComponent actor,
    Offset foot,
  ) {
    final world = camera.billboardWorldGeometry(
      foot,
      actor.currentCameraNeutralRenderedSpriteRect,
    );
    return BattleStageBillboard(
      id: slot,
      image: actor.stageImage!,
      source: actor.stageSourceRect,
      position: _point(world.position),
      width: world.width,
      height: world.height,
      tint: actor.stageTint,
    );
  }

  BattleStageGround _ellipse(
    BattleCombatantSceneGeometry geometry,
    double y,
    double scale,
    Color color,
  ) => BattleStageGround(
    color: color,
    points: [
      for (var i = 0; i < 40; i++)
        _point(
          camera.groundAt(
            geometry.footAnchor +
                Offset(
                  math.cos(i * math.pi / 20) *
                      geometry.platformRect.width *
                      scale /
                      2,
                  math.sin(i * math.pi / 20) *
                      geometry.platformRect.height *
                      scale /
                      2,
                ),
          ),
          y: y,
        ),
    ],
  );

  static Model3dVector3 _point(BattleCameraPoint point, {double? y}) =>
      Model3dVector3(x: point.x, y: y ?? point.y, z: point.z);

  @override
  void onRemove() {
    _closed = true;
    _stage?.dispose();
    _stage = null;
    for (final actor in combatants().values) {
      actor.renderedBy3DStage = false;
    }
    super.onRemove();
  }
}
