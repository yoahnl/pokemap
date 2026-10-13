import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/border_jump_fixture.dart';

List<BorderDirectedJumpBinding> _bind(
  BorderJumpFixture fixture, {
  MapData? map,
  ProjectManifest? project,
}) =>
    bindMaterializedBorderJumpFaces(
      map: map ?? fixture.map,
      project: project ?? fixture.project,
      tileSize: const PixelSize(width: 32, height: 32),
    );

BorderFeature _feature(
  BorderFeature source, {
  String? id,
  BorderSignedInt64? seed,
  BorderMaterialization? materialization,
  List<BorderSlotOverride>? overrides,
}) =>
    BorderFeature(
      id: id ?? source.id,
      name: source.name,
      blueprintId: source.blueprintId,
      seed: seed ?? source.seed,
      geometry: source.geometry,
      lineSide: source.lineSide,
      paramsOverride: source.paramsOverride,
      overrides: overrides ?? source.overrides,
      keepOutRegions: source.keepOutRegions,
      materialization: materialization ?? source.materialization,
    );

MapData _withFeatures(
        BorderJumpFixture fixture, List<BorderFeature> features) =>
    fixture.map.copyWith(layers: [
      MapLayer.border(
        id: 'original-borders',
        name: 'Borders',
        content: BorderLayerContent(formatVersion: 4, features: features),
      ),
      fixture.map.layers.last,
    ]);

void main() {
  for (final direction in Direction.values) {
    test(
        'canonical ${direction.name} Border binds its actual whole-cell module',
        () {
      final fixture = BorderJumpFixture(direction: direction);
      final binding = _bind(fixture).single;
      final edge = fixture.evidence.edges.single;
      expect(binding.carrierCell, edge.expectedCarrierCell);
      expect(binding.owner.layerId, 'original-borders');
      expect(binding.owner.featureId, fixture.feature.id);
      expect(binding.owner.placementId, edge.finalPlacement.id);
      expect(binding.allowedDirection, direction);
      expect(binding.physicalNormal.name, direction.name);
      expect(binding.carrierArea.leftPx, fixture.carrier.x * 32);
      expect(binding.carrierArea.topPx, fixture.carrier.y * 32);
      expect(binding.carrierArea.widthPx, 32);
      expect(binding.carrierArea.heightPx, 32);
      expect(binding.durationMs, 420);
      expect(binding.peakHeightPx, 19);
      expect(binding.inputFingerprint,
          fixture.feature.materialization!.receipt.inputFingerprint);
      expect(binding.outputFingerprint,
          fixture.feature.materialization!.receipt.outputFingerprint);
      expect(
          stepGameplayWorld(
              fixture.world(direction: direction), MoveIntent(direction)),
          isA<Jumped>());
    });
  }

  for (final direction in Direction.values) {
    for (final side in BorderLineSide.values) {
      test('long ${direction.name} line keeps every ${side.name} face binding',
          () {
        final points = switch (direction) {
          Direction.south => List.generate(11, (i) => GridPos(x: i + 1, y: 5)),
          Direction.north => List.generate(11, (i) => GridPos(x: 11 - i, y: 5)),
          Direction.east => List.generate(11, (i) => GridPos(x: 5, y: 11 - i)),
          Direction.west => List.generate(11, (i) => GridPos(x: 5, y: i + 1)),
        };
        final opposite = switch (direction) {
          Direction.north => Direction.south,
          Direction.south => Direction.north,
          Direction.east => Direction.west,
          Direction.west => Direction.east,
        };
        final allowed = side == BorderLineSide.inverted ? opposite : direction;
        final denied = side == BorderLineSide.inverted ? direction : opposite;
        final fixture = BorderJumpFixture(
          direction: direction,
          jumpSide: side,
          points: points,
        );
        final bindings = _bind(fixture);
        expect(bindings, hasLength(10));
        expect(bindings.map((value) => value.faceKey).toSet(), hasLength(10));
        expect(bindings.map((value) => value.owner).toSet(), hasLength(10));
        expect(
            bindings.map((value) => value.carrierCell).toList(),
            fixture.evidence.edges
                .map((edge) => edge.expectedCarrierCell)
                .toList());
        for (var i = 0; i < bindings.length; i++) {
          final binding = bindings[i];
          final edge = fixture.evidence.edges[i];
          expect(binding.owner.placementId, edge.finalPlacement.id);
          expect(binding.physicalNormal.name, direction.name);
          expect(binding.allowedDirection, allowed);
          final world = fixture.world(
            direction: allowed,
            playerPos: GridPos(
              x: binding.carrierCell.x - allowed.dx,
              y: binding.carrierCell.y - allowed.dy,
            ),
          );
          final step = stepGameplayWorld(world, MoveIntent(allowed));
          expect(step, isA<Jumped>());
          expect((step as Jumped).plan.binding.owner, binding.owner);
          final reverse = fixture.world(
            direction: denied,
            playerPos: GridPos(
              x: binding.carrierCell.x - denied.dx,
              y: binding.carrierCell.y - denied.dy,
            ),
          );
          expect(stepGameplayWorld(reverse, MoveIntent(denied)),
              isNot(isA<Jumped>()));
        }
      });
    }
  }

  test('side inversion changes permission without changing any drawn placement',
      () {
    final primary = BorderJumpFixture();
    final inverted = BorderJumpFixture(jumpSide: BorderLineSide.inverted);
    expect(primary.feature.materialization!.placements,
        inverted.feature.materialization!.placements);
    expect(_bind(primary).single.physicalNormal,
        _bind(inverted).single.physicalNormal);
    expect(_bind(inverted).single.allowedDirection, Direction.north);
    expect(
        _bind(primary).single.carrierCell, _bind(inverted).single.carrierCell);
  });

  test('physical line side changes the actual carrier and module orientation',
      () {
    final primary = BorderJumpFixture();
    final inverted = BorderJumpFixture(lineSide: BorderLineSide.inverted);
    expect(_bind(inverted).single.allowedDirection, Direction.north);
    expect(_bind(inverted).single.carrierCell,
        GridPos(x: primary.carrier.x, y: primary.carrier.y - 1));
    expect(
        _bind(inverted).single.physicalNormal, BorderCardinalDirection.north);
  });

  test('bindings are immutable and shared only by copies of the same context',
      () {
    final fixture = BorderJumpFixture();
    final world = fixture.world(direction: Direction.south);
    expect(() => world.borderJumpBindings.clear(), throwsUnsupportedError);
    expect(world.withPlayer(world.player).borderJumpBindings,
        same(world.borderJumpBindings));
    expect(
        world
            .withNpcMapPresencePredicate((mapId, entity) => false)
            .borderJumpBindings,
        same(world.borderJumpBindings));
    expect(
        world
            .withMapEntityPresencePredicate((mapId, entity) => false)
            .borderJumpBindings,
        same(world.borderJumpBindings));
    final rebuilt = fixture.world(direction: Direction.south);
    expect(rebuilt.borderJumpBindings, isNot(same(world.borderJumpBindings)));
  });

  test(
      'stale seed is refused even when the old output still has valid geometry',
      () {
    final fixture = BorderJumpFixture();
    final altered =
        _feature(fixture.feature, seed: BorderSignedInt64.fromInt(99));
    expect(() => _bind(fixture, map: _withFeatures(fixture, [altered])),
        throwsA(isA<ValidationException>()));
  });

  test(
      'canonical replay refuses an alternative variant with a recomputed receipt',
      () {
    final fixture = BorderJumpFixture(extraVariant: true);
    final output = fixture.feature.materialization!;
    final chosen = output.placements.single;
    final alternative = fixture.revision.definition.primitives.firstWhere(
      (value) =>
          value.authoredOrientation == BorderPrimitiveOrientation.south &&
          value.id != chosen.primitiveId,
    );
    final placement = BorderResolvedPlacement(
      id: chosen.id,
      slotKey: chosen.slotKey,
      primitiveId: alternative.id,
      visualSnapshotId: alternative.visualSnapshotId,
      anchorCell: chosen.anchorCell,
      topLeftWorldPx: chosen.topLeftWorldPx,
      opaqueWorldBoundsPx: chosen.opaqueWorldBoundsPx,
      transform: chosen.transform,
      drawBand: chosen.drawBand,
      stableOrderKey: chosen.stableOrderKey,
    );
    final forged = BorderMaterialization(
      ground: output.ground,
      placements: [placement],
      receipt: BorderResolutionReceipt(
        resolverVersion: output.receipt.resolverVersion,
        blueprintRevision: output.receipt.blueprintRevision,
        components: output.receipt.components,
        inputFingerprint: output.receipt.inputFingerprint,
        outputFingerprint: computeBorderOutputFingerprint(
          ground: output.ground,
          placements: [placement],
        ),
      ),
    );
    final map = _withFeatures(
        fixture, [_feature(fixture.feature, materialization: forged)]);
    expect(
        resolveMaterializedBorderCollisions(
          map: map,
          project: fixture.project,
          tileSize: const PixelSize(width: 32, height: 32),
        ).toList(),
        hasLength(1));
    expect(() => _bind(fixture, map: map), throwsA(isA<ValidationException>()));
  });

  test('missing collision profile is refused without inventing a carrier', () {
    final fixture = BorderJumpFixture();
    final project = fixture.project.copyWith(elements: [
      for (final element in fixture.project.elements)
        element.copyWith(collisionProfile: null),
    ]);
    expect(() => _bind(fixture, project: project),
        throwsA(isA<ValidationException>()));
  });

  test('a collision mask with a single pixel hole is not a whole-cell carrier',
      () {
    final pixels = List.filled(1024, true)..[15 * 32 + 15] = false;
    final fixture = BorderJumpFixture(
        collisionProfile: ElementCollisionProfile(
      collisionMask: ElementCollisionPixelMask(
        widthPx: 32,
        heightPx: 32,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: 32,
          heightPx: 32,
          solidPixels: pixels,
        ),
      ),
    ));
    expect(() => _bind(fixture), throwsA(isA<ValidationException>()));
  });

  test('an exact full-cell pixel mask is a valid carrier', () {
    final fixture = BorderJumpFixture(
        collisionProfile: ElementCollisionProfile(
      collisionMask: ElementCollisionPixelMask(
        widthPx: 32,
        heightPx: 32,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: 32,
          heightPx: 32,
          solidPixels: List.filled(1024, true),
        ),
      ),
    ));
    expect(_bind(fixture), hasLength(1));
  });

  test(
      'suppressed placements remove bindings instead of leaving topology ghosts',
      () {
    const points = [
      GridPos(x: 3, y: 3),
      GridPos(x: 4, y: 3),
      GridPos(x: 5, y: 3)
    ];
    final initial = BorderJumpFixture(points: points);
    final suppressed = BorderJumpFixture(points: points, overrides: [
      BorderSlotOverride(
        slotKey: initial.feature.materialization!.placements.first.slotKey,
        variationSalt: BorderSignedInt64.zero,
        suppressed: true,
        locked: false,
      ),
    ]);
    final bindings = _bind(suppressed);
    expect(bindings, hasLength(1));
    expect(bindings.single.owner.placementId,
        suppressed.feature.materialization!.placements.single.id);
    expect(bindings.single.carrierCell,
        initial.evidence.edges.last.expectedCarrierCell);
  });

  test(
      'keep-out removes the exact placement before binding the remaining faces',
      () {
    const points = [
      GridPos(x: 3, y: 3),
      GridPos(x: 4, y: 3),
      GridPos(x: 5, y: 3)
    ];
    final initial = BorderJumpFixture(points: points);
    final removed = initial.evidence.edges.first.expectedCarrierCell;
    final fixture = BorderJumpFixture(points: points, keepOut: [
      BorderKeepOutRegion(
          id: 'explicit-keep-out',
          region: BorderRegionGeometry(
            width: 12,
            height: 12,
            cells: List.generate(144, (i) => i == removed.y * 12 + removed.x),
          )),
    ]);
    final bindings = _bind(fixture);
    expect(bindings, hasLength(1));
    expect(bindings.single.carrierCell,
        initial.evidence.edges.last.expectedCarrierCell);
  });

  test(
      'changed offset override cannot use the previously admitted materialization',
      () {
    final fixture = BorderJumpFixture();
    final changed = _feature(fixture.feature, overrides: [
      BorderSlotOverride(
        slotKey: fixture.feature.materialization!.placements.single.slotKey,
        variationSalt: BorderSignedInt64.zero,
        suppressed: false,
        locked: false,
        offsetDeltaPx: const BorderPixelOffset(x: 1, y: 0),
      ),
    ]);
    expect(() => _bind(fixture, map: _withFeatures(fixture, [changed])),
        throwsA(isA<ValidationException>()));
  });

  test('two canonical owners on the same carrier are ambiguous', () {
    final fixture = BorderJumpFixture();
    final secondBase = _feature(fixture.feature, id: 'second-feature');
    final resolved = resolveLedgeLineBorderWithEvidence(BorderResolutionRequest(
      mapSize: fixture.map.size,
      tileSizePx: const GridSize(width: 32, height: 32),
      blueprintId: fixture.feature.blueprintId,
      blueprintRevision: fixture.revision,
      feature: secondBase,
      visualSnapshots: fixture.project.borderCatalog.visualSnapshots,
      resolverVersion: borderResolverVersion,
    ));
    final second =
        _feature(secondBase, materialization: resolved.result.materialization);
    expect(
        () => _bind(fixture,
            map: _withFeatures(fixture, [fixture.feature, second])),
        throwsA(isA<ValidationException>()));
  });

  test(
      'unknown placed-element reference at C is refused before cache admission',
      () {
    final fixture = BorderJumpFixture();
    final map = fixture.map.copyWith(placedElements: [
      MapPlacedElement(
        id: 'missing-object',
        layerId: 'objects',
        elementId: 'unknown-element',
        pos: GridPos(x: fixture.carrier.x, y: fixture.carrier.y + 1),
      ),
    ]);
    expect(() => fixture.world(direction: Direction.south, mapOverride: map),
        throwsA(isA<ValidationException>()));
  });

  test('unknown tileset on a blocking element at C is refused before admission',
      () {
    final fixture = BorderJumpFixture();
    final element = fixture.project.elements.first.copyWith(
      id: 'landing-solid',
      tilesetId: 'unknown-tileset',
    );
    final project = fixture.project
        .copyWith(elements: [...fixture.project.elements, element]);
    final map = fixture.map.copyWith(placedElements: [
      MapPlacedElement(
        id: 'landing-object',
        layerId: 'objects',
        elementId: element.id,
        pos: GridPos(x: fixture.carrier.x, y: fixture.carrier.y + 1),
      ),
    ]);
    expect(
        () => fixture.world(
            direction: Direction.south,
            mapOverride: map,
            projectOverride: project),
        throwsA(isA<ValidationException>()));
  });

  test('missing published context cannot silently enable ordinary walking', () {
    final fixture = BorderJumpFixture();
    expect(
        () => GameplayWorldState.initial(
              map: fixture.map,
              playerPos: const GridPos(x: 3, y: 2),
              tileWidth: 32,
              tileHeight: 32,
            ),
        throwsA(isA<ValidationException>()));
  });

  test('tile dimensions must match the immutable project context', () {
    final fixture = BorderJumpFixture();
    expect(
        () => bindMaterializedBorderJumpFaces(
              map: fixture.map,
              project: fixture.project,
              tileSize: const PixelSize(width: 16, height: 16),
            ),
        throwsA(isA<ValidationException>()));
  });

  test(
      'factory captures mutable map collections before keeping static bindings',
      () {
    final fixture = BorderJumpFixture();
    final layers = List<MapLayer>.from(fixture.map.layers);
    final placed = <MapPlacedElement>[];
    final map = fixture.map.copyWith(layers: layers, placedElements: placed);
    final world = fixture.world(direction: Direction.south, mapOverride: map);
    layers.clear();
    placed.add(const MapPlacedElement(
        id: 'foreign-mutation',
        layerId: 'objects',
        elementId: 'unknown',
        pos: GridPos(x: 3, y: 4)));
    expect(world.map.layers, hasLength(2));
    expect(world.map.placedElements, isEmpty);
    expect(stepGameplayWorld(world, const MoveIntent(Direction.south)),
        isA<Jumped>());
  });
}
