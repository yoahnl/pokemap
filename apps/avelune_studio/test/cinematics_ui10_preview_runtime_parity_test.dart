import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'support/capture_m3_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/player_component.dart';
import 'support/ui06_scene_fixture.dart';
import 'support/ui10_cinematic_fixture.dart';
import 'support/ui10_parity_fixture.dart';

void main() {
  for (final dimensions in [(16, 16, false), (32, 24, false), (32, 32, true)]) {
    testWidgets(
      'preview matches real Flame actors camera shake fade at ${dimensions.$1}x${dimensions.$2} reset=${dimensions.$3}',
      (tester) async {
        tester.view.physicalSize = const Size(960, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = (await tester.runAsync(
          () => createUi10ParityFixture(
            tileSize: dimensions.$1,
            tileHeight: dimensions.$2,
            cameraReset: dimensions.$3,
          ),
        ))!;
        addTearDown(() => tester.runAsync(fixture.dispose));
        final bytes = (await tester.runAsync(
          () => ui10AuthoringBytes(fixture.directory),
        ))!;
        final bundle = (await tester.runAsync(
          () => loadRuntimeMapBundle(
            projectFilePath: '${fixture.directory.path}/project.json',
            mapId: 'jardin',
          ),
        ))!;
        final game = PlayableMapGame(
          devicePixelRatioProvider: () => 1,
          bundle: bundle,
          projectFilePath: '${fixture.directory.path}/project.json',
        );
        final capture = GlobalKey();
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: capture,
              child: GameWidget(game: game),
            ),
          ),
        );
        for (var i = 0; i < 300; i++) {
          if (game.isLoaded && game.debugIsCinematicPlaying) break;
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await tester.pump();
        }
        expect(game.debugIsCinematicPlaying, isTrue);
        game.pauseEngine();
        final player = game.descendants().whereType<PlayerComponent>().single;
        final initialCamera = game.camera.viewfinder.position.clone();
        final initialPlayer =
            game.debugExpectedPlayerWorldTopLeft + player.size / 2;
        final initialZoom = game.camera.viewfinder.zoom;
        final cinematic = bundle.manifest.cinematics.single;
        final display = buildCinematicActorDisplayPreviewModel(
          cinematic: cinematic,
          project: bundle.manifest,
          stageMap: bundle.manifest.maps.firstWhere((m) => m.id == 'jardin'),
          mapData: bundle.map,
        );
        final plan = buildCinematicPreviewPlaybackPlan(
          cinematic: cinematic,
          actorDisplayPreviewModel: display,
          stageBounds: CinematicPreviewPlaybackStageBounds(
            width: bundle.map.size.width.toDouble(),
            height: bundle.map.size.height.toDouble(),
          ),
          availableMapIds: ['jardin'],
        );
        final total = dimensions.$3 ? 4050 : 3750;
        expect(plan.totalDurationMs, total);
        final projection = CinematicViewportProjection(
          plan: plan,
          initialCamera: CinematicViewportCamera(
            centerX: initialCamera.x,
            centerY: initialCamera.y,
            visibleWidth: 15 * bundle.cellWidth,
            visibleHeight: 11 * bundle.cellHeight,
          ),
          cellWidth: bundle.cellWidth,
          cellHeight: bundle.cellHeight,
        );
        var previous = 0;
        for (final ms in [
          0,
          200,
          400,
          1000,
          1599,
          1600,
          1950,
          2300,
          2450,
          2899,
          2900,
          if (dimensions.$3) 3050,
          3200,
          3500,
          total - 1,
        ]) {
          game.update((ms - previous) / 1000);
          previous = ms;
          await tester.pump();
          final actor = plan
              .frameAt(ms)
              .actorPoses
              .singleWhere((p) => p.actorId == 'hero');
          final visualFocus =
              player.position +
              player.debugActorLocalPosition! +
              player.visualSize / 2;
          expect(
            visualFocus.x,
            closeTo(actor.x! * bundle.cellWidth, .001),
            reason: 'actor x at $ms',
          );
          expect(
            visualFocus.y,
            closeTo(actor.y! * bundle.cellHeight, .001),
            reason: 'actor y at $ms',
          );
          expect(
            player.cinematicFacing.name,
            actor.facing.name,
            reason: 'actor facing at $ms',
          );
          final expected = projection.frameAt(ms);
          expect(
            game.camera.viewfinder.position.x,
            closeTo(expected.camera.centerX + expected.shakeOffsetX, .6),
            reason: 'camera x at $ms',
          );
          expect(
            game.camera.viewfinder.position.y,
            closeTo(expected.camera.centerY, .6),
            reason: 'camera y at $ms',
          );
          final scale = bundle.manifest.settings.displayScale;
          final ideal = math.min(
            960 / expected.camera.visibleWidth,
            640 / expected.camera.visibleHeight,
          );
          final zoom = math.max(1, (scale * ideal).round()) / scale;
          expect(
            game.camera.viewfinder.zoom,
            closeTo(zoom, .0001),
            reason: 'camera zoom at $ms',
          );
          expect(
            game.debugCinematicFadeOpacity,
            expected.fadeOpacity == null
                ? isNull
                : closeTo(expected.fadeOpacity!, .00001),
            reason: 'fade at $ms',
          );
          expect(game.debugIsCinematicPlaying, isTrue);
          if (dimensions == (32, 24, false) &&
              [0, 1000, 1950, 2450, 3200, 3749].contains(ms)) {
            void repaint(RenderObject object) {
              object.markNeedsPaint();
              object.visitChildren(repaint);
            }

            repaint(capture.currentContext!.findRenderObject()!);
            await captureM3Widget(tester, capture, 'parity-runtime-$ms');
          }
        }
        game.update(.001);
        for (
          var i = 0;
          i < 30 && game.debugIsMapActivationDispatchInFlight;
          i++
        ) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await tester.pump();
        }
        expect(game.debugIsCinematicPlaying, isFalse);
        expect(player.focusPoint.x, closeTo(initialPlayer.x, .001));
        expect(player.focusPoint.y, closeTo(initialPlayer.y, .001));
        expect(game.camera.viewfinder.position.x, closeTo(initialPlayer.x, .6));
        expect(game.camera.viewfinder.position.y, closeTo(initialPlayer.y, .6));
        expect(game.camera.viewfinder.zoom, initialZoom);
        expect(game.debugCinematicFadeOpacity, isNull);
        expect(game.debugIsGameplayInputLocked, isFalse);
        expect(
          game
              .gameStateSnapshot
              .narrativeFactRuntimeState
              .overridesByFactId[Ui06SceneFixture.departureFactId],
          isTrue,
        );
        expect(
          await tester.runAsync(() => ui10AuthoringBytes(fixture.directory)),
          bytes,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
