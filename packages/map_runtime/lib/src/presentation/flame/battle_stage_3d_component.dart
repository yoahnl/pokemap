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
    Future<BattleStageRenderer> Function(Size)? stageFactory,
    RuntimeResourceBudget? resourceBudget,
  }) : _stageFactory =
           stageFactory ??
           ((size) =>
               BattleStage3D.create(size, resourceBudget: resourceBudget)),
       super(priority: 6);

  final BattlePerspectiveCamera camera;
  final BattleSceneLayout Function() layout;
  final Map<BattleSlotRef, BattleSceneCombatantComponent> Function() combatants;
  final Map<BattleSlotRef, BattleCombatantSceneGeometry> Function() platforms;
  final bool paintFloor;
  final Future<BattleStageRenderer> Function(Size) _stageFactory;
  BattleStageRenderer? _stage;
  bool _closed = false;
  int _loadGeneration = 0;
  bool _currentFramePresented = false;
  bool _renderFailureReported = false;
  bool sourceHidePlatforms = false;
  bool sourceHideFloor = false;
  int _sourcePaletteLevel = 0;
  Color _sourcePaletteColor = const Color(0xff000000);
  List<Object>? _groundKey;
  List<BattleStageGround> _ground = const [];

  bool get isReady => _stage != null;
  bool get currentFramePresented => _currentFramePresented;

  ColorFilter? get sourcePaletteFilter => _sourcePaletteLevel == 0
      ? null
      : ColorFilter.mode(
          _sourcePaletteColor.withValues(alpha: _sourcePaletteLevel / 16),
          BlendMode.srcATop,
        );

  void setSourcePaletteFade(int level, Color color) {
    _sourcePaletteLevel = level;
    _sourcePaletteColor = color;
  }

  Color _sourceGroundColor(Color color) => Color.lerp(
        color,
        _sourcePaletteColor.withValues(alpha: color.a),
        _sourcePaletteLevel / 16,
      )!;

  @override
  Future<void> onLoad() async {
    final generation = ++_loadGeneration;
    final loadingGame = findGame();
    final loadingParent = parent;
    if (loadingGame?.buildContext == null) return;
    bool isCurrentOwner() =>
        !_closed &&
        generation == _loadGeneration &&
        !isRemoving &&
        !isRemoved &&
        identical(parent, loadingParent) &&
        identical(findGame(), loadingGame);
    try {
      final stage = await _stageFactory(camera.viewport.size);
      if (!isCurrentOwner()) {
        stage.dispose();
        return;
      }
      _stage?.dispose();
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
    final actors = combatants();
    _currentFramePresented = false;
    for (final actor in actors.values) {
      actor.renderedBy3DStage = false;
    }
    final stage = _stage;
    final context = findGame()?.buildContext;
    if (_closed || stage == null || context == null ||
        actors.values.any((actor) =>
            actor.hasBattleScriptPalette || actor.hasBattleScriptMosaic ||
            actor.hasBattleScriptRotation)) {
      return;
    }
    final recorder = PictureRecorder();
    Picture? picture;
    try {
      final geometry = platforms();
      final scene = layout();
      final groundKey = <Object>[
        camera.viewport,
        camera.focal,
        sourceHidePlatforms,
        sourceHideFloor,
        _sourcePaletteLevel,
        _sourcePaletteColor,
        for (final entry in geometry.entries)
          (entry.key, entry.value.footAnchor, entry.value.platformRect),
      ];
      if (!listEquals(groundKey, _groundKey)) {
        _groundKey = groundKey;
        _ground = [
          if (paintFloor && !sourceHideFloor)
            BattleStageGround(
              points: [
                Model3dVector3(x: -150, y: -.04, z: -250),
                Model3dVector3(x: 150, y: -.04, z: -250),
                Model3dVector3(x: 150, y: -.04, z: 150),
                Model3dVector3(x: -150, y: -.04, z: 150),
              ],
              color: _sourceGroundColor(const Color(0xff64875a)),
            ),
          if (!sourceHidePlatforms) for (final entry in geometry.entries) ...[
            _ellipse(entry.value, .0, 1, _sourceGroundColor(const Color(0xff635d3c))),
            _ellipse(entry.value, .015, .94, _sourceGroundColor(const Color(0xff819269))),
          ],
        ];
      }
      final billboards = [
        for (final entry in actors.entries)
          if (entry.value.stageImage != null && geometry.containsKey(entry.key))
            ?_billboard(
              entry.key,
              entry.value,
              geometry[entry.key]!.footAnchor,
            ),
      ];
      final result = stage.render(
        canvas: Canvas(recorder),
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
        billboards: billboards,
      );
      picture = recorder.endRecording();
      if (!result.presented ||
          billboards.length != actors.length ||
          billboards.any(
            (frame) => !result.submittedActorIds.contains(frame.id),
          )) {
        return;
      }
      canvas.drawPicture(picture);
      _currentFramePresented = true;
      _renderFailureReported = false;
      for (final entry in actors.entries) {
        entry.value.renderedBy3DStage = result.submittedActorIds.contains(
          entry.key,
        );
      }
    } catch (error) {
      if (!_renderFailureReported) {
        _renderFailureReported = true;
        debugPrint(
          '[battle][3D] Frame failed; using software presentation: $error',
        );
      }
    } finally {
      if (recorder.isRecording) recorder.endRecording().dispose();
      picture?.dispose();
    }
  }

  BattleStageBillboard? _billboard(
    BattleSlotRef slot,
    BattleSceneCombatantComponent actor,
    Offset foot,
  ) {
    final imageRect = actor.currentCameraNeutralRenderedImageRect;
    final clipY = actor.cameraNeutralBattleGroundClipY;
    final clipFraction = clipY == null || imageRect.height <= 0
        ? 1.0
        : ((clipY - imageRect.top) / imageRect.height).clamp(0.0, 1.0);
    final visibleRect = clipFraction == 0 ? imageRect : Rect.fromLTWH(
      imageRect.left, imageRect.top, imageRect.width, imageRect.height * clipFraction,
    );
    final source = actor.stageSourceRect;
    final visibleSource = clipFraction == 0 ? source : Rect.fromLTWH(
      source.left, source.top, source.width, source.height * clipFraction,
    );
    final world = camera.tryBillboardWorldGeometry(foot, visibleRect);
    if (world == null) return null;
    final shadowRect = actor.currentCameraNeutralShadowRect;
    final maskSize = actor.stageShadowMaskSize;
    final pixels = BattleStageSoftShadow.imageSize(maskSize);
    final shadow = camera.tryBillboardWorldGeometry(
      foot,
      Rect.fromCenter(
        center: shadowRect.center,
        width: pixels.width * shadowRect.width / maskSize.width,
        height: pixels.height * shadowRect.height / maskSize.height,
      ),
    );
    if (shadow == null) return null;
    final trails = <BattleStageTrail>[];
    for (final trail in actor.currentCameraNeutralDashTrails) {
      final geometry = camera.tryBillboardWorldGeometry(foot, trail.rect);
      if (geometry == null) return null;
      trails.add(
        BattleStageTrail(
          position: _point(geometry.position),
          width: geometry.width,
          height: geometry.height,
          tint: trail.tint,
        ),
      );
    }
    return BattleStageBillboard(
      id: slot,
      image: actor.stageImage!,
      source: visibleSource,
      position: _point(world.position),
      width: world.width,
      height: world.height,
      tint: clipFraction == 0 ? actor.stageTint.withValues(alpha: 0) : actor.stageTint,
      shadow: BattleStageSoftShadow(
        maskSize: maskSize,
        position: _point(shadow.position),
        width: shadow.width,
        height: shadow.height,
        tint: actor.stageShadowTint,
      ),
      trails: trails,
    );
  }

  BattleStageGround _ellipse(
    BattleCombatantSceneGeometry geometry,
    double y,
    double scale,
    Color color,
  ) {
    final points = <Model3dVector3>[];
    for (var i = 0; i < 40; i++) {
      final ground = camera.tryGroundAt(
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
      );
      if (ground == null) {
        return BattleStageGround(points: const [], color: color);
      }
      points.add(_point(ground, y: y));
    }
    return BattleStageGround(color: color, points: points);
  }

  static Model3dVector3 _point(BattleCameraPoint point, {double? y}) =>
      Model3dVector3(x: point.x, y: y ?? point.y, z: point.z);

  @override
  void onRemove() {
    _closed = true;
    _loadGeneration++;
    _currentFramePresented = false;
    _stage?.dispose();
    _stage = null;
    _groundKey = null;
    _ground = const [];
    for (final actor in combatants().values) {
      actor.renderedBy3DStage = false;
    }
    super.onRemove();
  }
}
