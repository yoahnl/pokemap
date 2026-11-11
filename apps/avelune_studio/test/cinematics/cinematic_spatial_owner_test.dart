@Timeout(Duration(minutes: 3))
library;

import 'dart:ui';

import 'package:avelune_studio/features/cinematics/application/cinematic_map_model.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_spatial_picking.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_viewport_camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/cinematic_workspace_owner_fixture.dart';
import '../support/ui10_cinematic_fixture.dart';

void main() {
  for (final tileSize in [16, 32]) {
    group('$tileSize px tiles', () {
      late CinematicWorkspaceOwnerFixture owner;
      setUp(() async {
        owner = await CinematicWorkspaceOwnerFixture.create(tileSize: tileSize);
      });
      tearDown(() => owner.dispose());

      test(
        'destination uses $tileSize pixel cells after actual zoom pan and publication',
        () async {
          final before = await owner.open();
          final map = await owner.loadMap(before.mapId!);
          final mapBefore = await owner.mapBytes();
          final controller = owner.controller;

          expect(
            controller.setDestination(
              'walk',
              12,
              10,
              width: map.size.width,
              height: map.size.height,
            ),
            isTrue,
            reason: controller.error,
          );
          final changed = controller.active!.asset;
          final target = changed.timeline.steps
              .singleWhere((s) => s.id == 'walk')
              .targetId;
          expect(target, isNot('destination'));
          final binding = changed.stageContext!.movementTargetBindings
              .singleWhere((b) => b.targetId == target);
          final point = changed.stageContext!.stagePoints.singleWhere(
            (p) => p.id == binding.sourceId,
          );
          expect((point.x, point.y), (12, 10));
          expect(
            changed.stageContext!.stagePoints
                .singleWhere((p) => p.id == 'arrival')
                .x,
            13,
          );
          expect(
            changed.stageContext!.movementTargetBindings
                .singleWhere((b) => b.targetId == 'destination')
                .sourceId,
            'arrival',
          );
          expect(controller.active!.dirty, isTrue);
          controller.undo();
          expect(controller.active!.asset.toJson(), before.toJson());
          controller.redo();
          expect(controller.active!.asset.toJson(), changed.toJson());

          expect(await controller.save(), isTrue, reason: controller.error);
          expect(controller.active!.dirty, isFalse);
          expect((await owner.reread()).toJson(), changed.toJson());
          expect(await owner.mapBytes(), mapBefore);
        },
      );

      test(
        'a destination outside the map is refused without mutation',
        () async {
          final before = await owner.open();
          final map = await owner.loadMap(before.mapId!);
          expect(
            owner.controller.setDestination(
              'walk',
              map.size.width.toDouble(),
              0,
              width: map.size.width,
              height: map.size.height,
            ),
            isFalse,
          );
          expect(owner.controller.error, contains('dans la carte'));
          expect(owner.controller.active!.asset, same(before));
        },
      );
    });
  }

  group('real garden project', () {
    late CinematicWorkspaceOwnerFixture owner;
    late CinematicAsset asset;
    late MapData map;
    late CinematicMapModel model;
    setUp(() async {
      owner = await CinematicWorkspaceOwnerFixture.create();
      asset = await owner.open();
      map = await owner.loadMap(asset.mapId!);
      model = CinematicMapModel(asset, owner.controller.project, map);
    });
    tearDown(() => owner.dispose());

    CinematicPreviewPlaybackPlan plan(CinematicMapModel model) =>
        buildCinematicPreviewPlaybackPlan(
          cinematic: model.asset,
          actorDisplayPreviewModel: model.actors,
          resolvedMovementTargets: model.targets,
          stageBounds: model.bounds,
          availableMapIds: [model.map.id],
        );

    test('preview camera zoom shake fade uses playback transform and Stop restores author view', () {
      final camera = cinematicInitialViewportCamera(
        model,
        cellWidth: 32,
        cellHeight: 32,
      );
      expect(camera.centerX, 8 * 32);
      expect(camera.centerY, 9 * 32);
      expect(camera.visibleWidth, 15 * 32);
      expect(camera.visibleHeight, 11 * 32);

      final projection = cinematicPlaybackProjection(
        plan(model),
        model,
        cellWidth: 32,
        cellHeight: 32,
      );
      final start = projection.frameAt(0).camera;
      expect(start.centerX, camera.centerX);
      expect(start.visibleWidth, camera.visibleWidth);
      final framed = projection.frameAt(2450).camera;
      expect((
        framed.centerX,
        framed.visibleWidth,
      ), isNot((start.centerX, start.visibleWidth)));
    });

    test('a small map clamps the initial playback window to its cells', () {
      final small = CinematicMapModel(
        asset,
        owner.controller.project,
        map.copyWith(size: const GridSize(width: 10, height: 8)),
      );
      final camera = cinematicInitialViewportCamera(
        small,
        cellWidth: 16,
        cellHeight: 16,
      );
      expect(camera.visibleWidth, 10 * 16);
      expect(camera.visibleHeight, 8 * 16);

      final spatial = cinematicInitialViewportCamera(small, clampToMap: false);
      expect(spatial.visibleWidth, cinematicInitialVisibleColumns);
      expect(spatial.visibleHeight, cinematicInitialVisibleRows);
      expect(cinematicSpatialPreviewZoom(2, 15), 2);
      expect(cinematicSpatialPreviewZoom(2, 7.5), 4);
    });

    test('without a player actor the initial camera centres the map', () {
      final unbound = asset.copyWith(
        stageContext: CinematicStageContext(
          backdropMode: asset.stageContext!.backdropMode,
          actorBindings: [
            for (final binding in asset.stageContext!.actorBindings)
              if (binding.kind != CinematicActorBindingKind.player) binding,
          ],
          initialPlacements: asset.stageContext!.initialPlacements,
          movementTargetBindings: asset.stageContext!.movementTargetBindings,
          stagePoints: asset.stageContext!.stagePoints,
        ),
      );
      final camera = cinematicInitialViewportCamera(
        CinematicMapModel(unbound, owner.controller.project, map),
        cellWidth: 32,
        cellHeight: 32,
      );
      expect(camera.centerX, map.size.width / 2 * 32);
      expect(camera.centerY, map.size.height / 2 * 32);
    });

    test('3D cinematic keeps existing point commands, preview and Escape cancellation', () async {
      final hero = model.actors.actors.singleWhere((a) => a.actorId == 'hero');
      final chief = model.actors.actors.singleWhere(
        (a) => a.actorId == 'chief',
      );
      expect(cinematicActorContentId(hero), cinematicPlayerContentId);
      expect(cinematicActorContentId(chief), 'cinematic:chief');
      expect(cinematicActorIdForContent(model, 'hero'), 'hero');
      expect(cinematicActorIdForContent(model, 'cinematic:chief'), 'chief');
      expect(cinematicActorIdForContent(model, 'decor:arbre'), isNull);
      expect(cinematicCellCentre(10, 9), const Offset(10.5, 9.5));

      final start = cinematicStagePointAtCell(asset, 8, 9)!;
      expect(start.id, 'start');
      expect(cinematicStagePointAtCell(asset, 7, 9), isNull);
      final destination = cinematicSpatialDragDestination(
        start,
        origin: const Offset(8, 9),
        cell: (9, 9),
      );
      expect(destination, const Offset(9, 9));
      final fractional = CinematicStagePoint(
        id: 'half',
        label: 'Demi',
        x: 8.5,
        y: 9.5,
      );
      expect(
        cinematicSpatialDragDestination(
          fractional,
          origin: const Offset(8, 9),
          cell: (9, 9),
        ),
        const Offset(9.5, 9.5),
      );
      expect(
        cinematicCommittedDragDestination(start, const Offset(8, 9)),
        isNull,
      );
      expect(cinematicCommittedDragDestination(null, destination), isNull);
      expect(
        cinematicCommittedDragDestination(start, destination),
        destination,
      );

      final before = owner.controller.active!.asset;
      expect(
        await owner.controller.moveStagePointTo(
          start.id,
          destination.dx,
          destination.dy,
          model: model,
          confirmShared: (_) async => true,
        ),
        isTrue,
        reason: owner.controller.error,
      );
      final moved = owner.controller.active!.asset.stageContext!.stagePoints
          .singleWhere((p) => p.id == 'start');
      expect((moved.x, moved.y), (9, 9));
      owner.controller.undo();
      expect(owner.controller.active!.asset, before);
    });

    for (final tileSize in [16, 32]) {
      test(
        'map clicks and point drag respect pan zoom resize at $tileSize px',
        () async {
          final cell = Size(tileSize.toDouble(), tileSize.toDouble());
          final start = cinematicStagePointAtCell(asset, 8, 9)!;
          final destination = cinematicGridDragDestination(
            start,
            delta: Offset(tileSize * 2 + 3, tileSize * .4),
            cell: cell,
          );
          expect(destination, const Offset(10, 9));
          expect(
            cinematicGridDragDestination(
              CinematicStagePoint(id: 'half', label: 'Demi', x: 8.5, y: 9),
              delta: Offset.zero,
              cell: cell,
            ),
            const Offset(9, 9),
          );
          final mapBefore = await owner.mapBytes();
          expect(
            await owner.controller.moveStagePointTo(
              start.id,
              destination.dx,
              destination.dy,
              model: model,
              confirmShared: (_) async => true,
            ),
            isTrue,
            reason: owner.controller.error,
          );
          final moved = owner.controller.active!.asset.stageContext!.stagePoints
              .singleWhere((p) => p.id == 'start');
          expect((moved.x, moved.y), (10, 9));
          expect(await owner.mapBytes(), mapBefore);
        },
      );
    }

    test('a stage point cannot be dragged out of the map', () async {
      final before = owner.controller.active!.asset;
      expect(
        await owner.controller.moveStagePointTo(
          'start',
          map.size.width.toDouble(),
          9,
          model: model,
          confirmShared: (_) async => true,
        ),
        isFalse,
      );
      expect(owner.controller.active!.asset, same(before));
      expect(ui10CinematicId, before.id);
    });
  });
}
