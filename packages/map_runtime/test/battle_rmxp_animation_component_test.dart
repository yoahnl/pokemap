import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_rmxp_animation_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_rmxp_hue_filter.dart';
import 'package:map_runtime/src/presentation/flame/battle_sdk_rmxp_animation_catalog.dart';

void main() {
  group('BattleRmxpAnimationComponent', () {
    test('advances RMXP frames at Pokemon SDK timing', () async {
      final component = BattleRmxpAnimationComponent(
        image: await _image(960, 384),
        animation: _animation(
          frames: <RmxpAnimationFrameSpec>[
            const RmxpAnimationFrameSpec(
              cellMax: 1,
              cells: <RmxpAnimationCellSpec>[
                RmxpAnimationCellSpec(
                  index: 0,
                  pattern: 0,
                  x: 0,
                  y: 0,
                  zoom: 100,
                  angle: 0,
                  mirror: false,
                  opacity: 255,
                  blendType: 0,
                ),
              ],
            ),
            const RmxpAnimationFrameSpec(
              cellMax: 1,
              cells: <RmxpAnimationCellSpec>[
                RmxpAnimationCellSpec(
                  index: 0,
                  pattern: 1,
                  x: 0,
                  y: 0,
                  zoom: 100,
                  angle: 0,
                  mirror: false,
                  opacity: 255,
                  blendType: 0,
                ),
              ],
            ),
          ],
        ),
        sourceAnchorPosition: Vector2(100, 100),
        sceneSize: Vector2(320, 240),
        reverse: false,
      );

      expect(component.currentFrameIndex, equals(0));
      component.update(0.049);
      expect(component.currentFrameIndex, equals(0));
      component.update(0.001);
      expect(component.currentFrameIndex, equals(1));
      expect(component.isAnimationComplete, isFalse);
      component.update(0.05);
      expect(component.isAnimationComplete, isTrue);
    });

    test('computes source rects with 192px RMXP cells and 5 columns', () async {
      final component = BattleRmxpAnimationComponent(
        image: await _image(960, 384),
        animation: _animation(
          frames: <RmxpAnimationFrameSpec>[
            const RmxpAnimationFrameSpec(
              cellMax: 1,
              cells: <RmxpAnimationCellSpec>[
                RmxpAnimationCellSpec(
                  index: 0,
                  pattern: 6,
                  x: 0,
                  y: 0,
                  zoom: 100,
                  angle: 0,
                  mirror: false,
                  opacity: 255,
                  blendType: 0,
                ),
              ],
            ),
          ],
        ),
        sourceAnchorPosition: Vector2(100, 100),
        sceneSize: Vector2(320, 240),
        reverse: false,
      );

      final cells = component.visibleCellsForTesting;
      expect(cells, hasLength(1));
      expect(cells.single.sourceRect.left, equals(192));
      expect(cells.single.sourceRect.top, equals(192));
      expect(cells.single.sourceRect.right, lessThanOrEqualTo(960));
      expect(cells.single.sourceRect.bottom, lessThanOrEqualTo(384));
    });

    test('exposes RMXP cell style metadata for renderer fidelity', () async {
      final component = BattleRmxpAnimationComponent(
        image: await _image(960, 384),
        animation: _animation(
          animationHue: 120,
          option: RmxpAnimationOption.rotateOnReverse,
          forceNoReverse: false,
          frames: <RmxpAnimationFrameSpec>[
            const RmxpAnimationFrameSpec(
              cellMax: 1,
              cells: <RmxpAnimationCellSpec>[
                RmxpAnimationCellSpec(
                  index: 0,
                  pattern: 2,
                  x: 40,
                  y: -20,
                  zoom: 160,
                  angle: 45,
                  mirror: true,
                  opacity: 128,
                  blendType: 1,
                ),
              ],
            ),
          ],
        ),
        sourceAnchorPosition: Vector2(100, 100),
        sceneSize: Vector2(320, 240),
        reverse: true,
      );

      final cell = component.visibleCellsForTesting.single;
      expect(component.animation.animationHue, equals(120));
      expect(cell.colorFilter, isNotNull);
      expect(cell.opacity, closeTo(128 / 255, 0.001));
      expect(cell.angleRadians, closeTo(225 * 3.141592653589793 / 180, 0.001));
      expect(cell.mirror, isTrue);
      expect(cell.blendType, equals(1));
      expect(cell.destinationRect.width, closeTo(153.6, 0.001));
      expect(cell.destinationRect.center.dx, closeTo(80, 0.001));
      expect(cell.destinationRect.center.dy, closeTo(110, 0.001));
    });

    test('mirrors screen-position animations on both SDK axes when reversed',
        () async {
      final component = BattleRmxpAnimationComponent(
        image: await _image(960, 384),
        animation: _animation(
          position: 3,
          option: RmxpAnimationOption.rotateOnReverse,
          forceNoReverse: false,
          frames: <RmxpAnimationFrameSpec>[
            const RmxpAnimationFrameSpec(
              cellMax: 1,
              cells: <RmxpAnimationCellSpec>[
                RmxpAnimationCellSpec(
                  index: 0,
                  pattern: 0,
                  x: -40,
                  y: 24,
                  zoom: 100,
                  angle: 0,
                  mirror: false,
                  opacity: 255,
                  blendType: 0,
                ),
              ],
            ),
          ],
        ),
        sourceAnchorPosition: Vector2(100, 100),
        placementSpec: const RmxpPlacementSpec(
          policy: RmxpPlacementPolicy.sdkStage,
          anchor: BattleVisualAnchor.stageCenter,
        ),
        sceneSize: Vector2(320, 240),
        stageRect: const ui.Rect.fromLTWH(0, 0, 320, 240),
        reverse: true,
      );

      final cell = component.visibleCellsForTesting.single;
      expect(cell.destinationRect.center.dx, closeTo(180, 0.001));
      expect(cell.destinationRect.center.dy, closeTo(24, 0.001));
      expect(cell.angleRadians, closeTo(3.141592653589793, 0.001));
    });

    test('water gun exact RMXP animation travels down-left when reversed',
        () async {
      final component = BattleRmxpAnimationComponent(
        image: await _image(960, 576),
        animation: BattleSdkRmxpAnimationCatalog.require(55),
        sourceAnchorPosition: Vector2(100, 100),
        placementSpec: const RmxpPlacementSpec(
          policy: RmxpPlacementPolicy.projectileLine,
          sourceAnchor: BattleVisualAnchor.attackerMouth,
          targetAnchor: BattleVisualAnchor.defenderImpact,
          rotateToLine: true,
        ),
        projectileSourceAnchorPosition: Vector2(260, 80),
        projectileTargetAnchorPosition: Vector2(90, 190),
        sceneSize: Vector2(320, 240),
        reverse: true,
      );

      component.update(RmxpAnimationSpec.frameDurationSeconds);
      final firstCell = component.visibleCellsForTesting.first;

      component.update(RmxpAnimationSpec.frameDurationSeconds * 23);
      final lateCell = component.visibleCellsForTesting.last;

      expect(firstCell.destinationRect.center.dx, greaterThan(160));
      expect(lateCell.destinationRect.center.dx,
          lessThan(firstCell.destinationRect.center.dx));
      expect(lateCell.destinationRect.center.dy,
          greaterThan(firstCell.destinationRect.center.dy));
    });

    test('mega punch target impact stays centered on defender, not stage line',
        () async {
      final defenderImpact = Vector2(510, 210);
      final component = BattleRmxpAnimationComponent(
        image: await _image(960, 384),
        animation: BattleSdkRmxpAnimationCatalog.require(5),
        sourceAnchorPosition: defenderImpact,
        placementSpec: const RmxpPlacementSpec(
          policy: RmxpPlacementPolicy.targetImpact,
          anchor: BattleVisualAnchor.defenderImpact,
        ),
        placementAnchorPosition: defenderImpact,
        sceneSize: Vector2(760, 520),
        stageRect: const ui.Rect.fromLTWH(0, 0, 760, 420),
        reverse: false,
      );

      component.update(RmxpAnimationSpec.frameDurationSeconds * 2);

      final cell = component.visibleCellsForTesting.single;
      expect(
        (cell.destinationRect.center -
                ui.Offset(defenderImpact.x, defenderImpact.y))
            .distance,
        lessThan(120),
      );
      expect(cell.destinationRect.center.dy, lessThan(420));
    });

    test('swift projectile line starts at attacker and reaches defender',
        () async {
      final source = Vector2(120, 320);
      final target = Vector2(520, 170);
      final component = BattleRmxpAnimationComponent(
        image: await _image(960, 576),
        animation: BattleSdkRmxpAnimationCatalog.require(129),
        sourceAnchorPosition: source,
        placementSpec: const RmxpPlacementSpec(
          policy: RmxpPlacementPolicy.projectileLine,
          sourceAnchor: BattleVisualAnchor.attackerHand,
          targetAnchor: BattleVisualAnchor.defenderImpact,
        ),
        projectileSourceAnchorPosition: source,
        projectileTargetAnchorPosition: target,
        sceneSize: Vector2(760, 520),
        stageRect: const ui.Rect.fromLTWH(0, 0, 760, 420),
        reverse: false,
      );

      component.update(RmxpAnimationSpec.frameDurationSeconds);
      final firstCell = component.visibleCellsForTesting.first;
      component.update(RmxpAnimationSpec.frameDurationSeconds * 16);
      final lateCell = component.visibleCellsForTesting.last;

      expect(
        (firstCell.destinationRect.center - ui.Offset(source.x, source.y))
            .distance,
        lessThan(80),
      );
      expect(lateCell.destinationRect.center.dx,
          greaterThan(firstCell.destinationRect.center.dx));
      expect(
        (lateCell.destinationRect.center - ui.Offset(target.x, target.y))
            .distance,
        lessThan(
          (lateCell.destinationRect.center - ui.Offset(source.x, source.y))
              .distance,
        ),
      );
    });

    test('projectile RMXP moves progress from source toward target', () async {
      final samples = <({int animationId, String name})>[
        (animationId: 55, name: 'water gun'),
        (animationId: 81, name: 'string shot'),
        (animationId: 225, name: 'dragon breath'),
      ];

      for (final sample in samples) {
        final source = Vector2(130, 330);
        final target = Vector2(520, 180);
        final component = BattleRmxpAnimationComponent(
          image: await _image(960, 576),
          animation: BattleSdkRmxpAnimationCatalog.require(sample.animationId),
          sourceAnchorPosition: source,
          placementSpec: const RmxpPlacementSpec(
            policy: RmxpPlacementPolicy.projectileLine,
            sourceAnchor: BattleVisualAnchor.attackerMouth,
            targetAnchor: BattleVisualAnchor.defenderImpact,
            rotateToLine: true,
          ),
          projectileSourceAnchorPosition: source,
          projectileTargetAnchorPosition: target,
          sceneSize: Vector2(760, 520),
          stageRect: const ui.Rect.fromLTWH(0, 0, 760, 420),
          reverse: false,
        );

        component.update(RmxpAnimationSpec.frameDurationSeconds);
        final firstCell = component.visibleCellsForTesting.first;
        component.update(RmxpAnimationSpec.frameDurationSeconds * 8);
        final lateCell = component.visibleCellsForTesting.last;

        expect(
          (firstCell.destinationRect.center - ui.Offset(source.x, source.y))
              .distance,
          lessThan(130),
          reason: sample.name,
        );
        expect(lateCell.destinationRect.center.dx,
            greaterThan(firstCell.destinationRect.center.dx),
            reason: sample.name);
        expect(
          (lateCell.destinationRect.center - ui.Offset(target.x, target.y))
              .distance,
          lessThan(
            (firstCell.destinationRect.center - ui.Offset(target.x, target.y))
                .distance,
          ),
          reason: sample.name,
        );
      }
    });

    test('keeps RMXP subtract blend alpha-safe for transparent sheets',
        () async {
      final component = BattleRmxpAnimationComponent(
        image: await _image(960, 384),
        animation: _animation(
          frames: <RmxpAnimationFrameSpec>[
            const RmxpAnimationFrameSpec(
              cellMax: 1,
              cells: <RmxpAnimationCellSpec>[
                RmxpAnimationCellSpec(
                  index: 0,
                  pattern: 4,
                  x: 48,
                  y: -56,
                  zoom: 100,
                  angle: 0,
                  mirror: false,
                  opacity: 255,
                  blendType: 2,
                ),
              ],
            ),
          ],
        ),
        sourceAnchorPosition: Vector2(100, 100),
        sceneSize: Vector2(320, 240),
        reverse: false,
      );

      final cell = component.visibleCellsForTesting.single;
      expect(cell.blendType, equals(2));
      expect(cell.blendMode, equals(ui.BlendMode.srcOver));
    });

    test('builds an active RGSS-like hue matrix for non-zero hues', () {
      expect(
        RmxpHueFilter.matrixForHue(0),
        equals(RmxpHueFilter.identityMatrix),
      );

      final matrix = RmxpHueFilter.matrixForHue(120);

      expect(matrix, hasLength(20));
      expect(matrix, isNot(equals(RmxpHueFilter.identityMatrix)));
      expect(matrix.sublist(15, 20), equals(<double>[0, 0, 0, 1, 0]));
      expect(matrix[4], equals(0));
      expect(matrix[9], equals(0));
      expect(matrix[14], equals(0));
      expect(matrix[19], equals(0));
      expect(RmxpHueFilter.colorFilterForHue(120), isNotNull);
      expect(RmxpHueFilter.colorFilterForHue(0), isNull);
    });

    test('processes RMXP flash timings and restores visibility', () async {
      final pokemonFlashTimings = <RmxpAnimationTimingSpec>[];
      final sceneFlashTimings = <RmxpAnimationTimingSpec>[];
      final visibility = <bool>[];
      final component = BattleRmxpAnimationComponent(
        image: await _image(960, 384),
        animation: _animation(
          frames: <RmxpAnimationFrameSpec>[
            for (var i = 0; i < 3; i++)
              const RmxpAnimationFrameSpec(
                cellMax: 0,
                cells: <RmxpAnimationCellSpec>[],
              ),
          ],
          timings: const <RmxpAnimationTimingSpec>[
            RmxpAnimationTimingSpec(
              frame: 0,
              condition: 0,
              flashScope: 1,
              flashDuration: 1,
              flashRed: 255,
              flashGreen: 32,
              flashBlue: 16,
              flashAlpha: 192,
              seName: null,
              seVolume: 0,
              sePitch: 100,
            ),
            RmxpAnimationTimingSpec(
              frame: 1,
              condition: 0,
              flashScope: 2,
              flashDuration: 1,
              flashRed: 32,
              flashGreen: 64,
              flashBlue: 255,
              flashAlpha: 160,
              seName: null,
              seVolume: 0,
              sePitch: 100,
            ),
            RmxpAnimationTimingSpec(
              frame: 1,
              condition: 0,
              flashScope: 3,
              flashDuration: 1,
              flashRed: 0,
              flashGreen: 0,
              flashBlue: 0,
              flashAlpha: 0,
              seName: null,
              seVolume: 0,
              sePitch: 100,
            ),
          ],
        ),
        sourceAnchorPosition: Vector2(100, 100),
        sceneSize: Vector2(320, 240),
        reverse: false,
        onPokemonFlash: pokemonFlashTimings.add,
        onSceneFlash: sceneFlashTimings.add,
        onVisibilityChanged: visibility.add,
      );

      component.update(0);
      expect(pokemonFlashTimings, hasLength(1));
      expect(sceneFlashTimings, isEmpty);
      expect(visibility, isEmpty);

      component.update(0.05);
      expect(sceneFlashTimings, hasLength(1));
      expect(visibility, equals(<bool>[true]));

      component.update(0.05);
      expect(visibility, equals(<bool>[true, false]));
    });

    test('reports and clears cell 15 combatant transforms', () async {
      RmxpCombatantTransform? latestTransform;
      var didClear = false;
      final component = BattleRmxpAnimationComponent(
        image: await _image(960, 384),
        animation: _animation(
          frames: <RmxpAnimationFrameSpec>[
            const RmxpAnimationFrameSpec(
              cellMax: 16,
              cells: <RmxpAnimationCellSpec>[
                RmxpAnimationCellSpec(
                  index: 15,
                  pattern: 0,
                  x: 40,
                  y: -20,
                  zoom: 120,
                  angle: 0,
                  mirror: false,
                  opacity: 255,
                  blendType: 0,
                ),
              ],
            ),
          ],
        ),
        sourceAnchorPosition: Vector2(100, 100),
        sceneSize: Vector2(320, 240),
        reverse: false,
        onCombatantTransform: (transform) => latestTransform = transform,
        onCombatantTransformCleared: () => didClear = true,
      );

      component.update(0);
      expect(latestTransform?.offset.dx, equals(20));
      expect(latestTransform?.offset.dy, equals(-10));
      expect(latestTransform?.scale, equals(1.2));

      component.update(0.05);
      expect(component.isAnimationComplete, isTrue);
      component.removeFromParent();
      component.onRemove();
      expect(didClear, isTrue);
    });
  });
}

RmxpAnimationSpec _animation({
  required List<RmxpAnimationFrameSpec> frames,
  int animationHue = 0,
  RmxpAnimationOption option = RmxpAnimationOption.normal,
  bool forceNoReverse = true,
  int position = 1,
  List<RmxpAnimationTimingSpec> timings = const <RmxpAnimationTimingSpec>[],
}) {
  return RmxpAnimationSpec(
    id: 999,
    name: 'N/TEST',
    animationName: 'ANIM001',
    assetId: 'anim001',
    animationHue: animationHue,
    position: position,
    frameMax: frames.length,
    option: option,
    forceNoReverse: forceNoReverse,
    frames: frames,
    timings: timings,
  );
}

Future<ui.Image> _image(int width, int height) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Offset.zero & ui.Size(width.toDouble(), height.toDouble()),
    ui.Paint(),
  );
  return recorder.endRecording().toImage(width, height);
}
