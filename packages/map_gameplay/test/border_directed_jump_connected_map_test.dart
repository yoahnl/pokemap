import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/border_jump_fixture.dart';

void main() {
  late BorderJumpFixture fixture;
  late ProjectManifest project;
  late List<MapData> maps;

  setUp(() {
    fixture = BorderJumpFixture();
    final owner = fixture.map.copyWith(connections: const [
      MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: 'east-a',
          offset: 0),
      MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: 'east-b',
          offset: 6),
    ]);
    MapData neighbor(String id, int offset) => MapData(
          id: id,
          name: id,
          size: const GridSize(width: 12, height: 6),
          layers: [
            MapLayer.tile(
                id: 'ground', name: 'Ground', cells: List.filled(72, 0))
          ],
          connections: [
            MapConnection(
                direction: MapConnectionDirection.west,
                targetMapId: owner.id,
                offset: offset)
          ],
        );
    maps = [owner, neighbor('east-a', 0), neighbor('east-b', -6)];
    project = fixture.project.copyWith(maps: [
      for (final map in maps)
        ProjectMapEntry(
            id: map.id, name: map.name, relativePath: 'maps/${map.id}.json'),
    ]);
  });

  test('complete disjoint connection graph with canonical Border is valid', () {
    ProjectValidator.validate(project, maps: maps);
    for (final map in maps) {
      MapValidator.validate(map, projectDialogueContext: project);
    }
  });

  test('local Border binding preserves both same-edge connections', () {
    final bindings = bindMaterializedBorderJumpFaces(
      map: maps.first,
      project: project,
      tileSize: const PixelSize(width: 32, height: 32),
    );
    expect(bindings.single.carrierCell, fixture.carrier);
    expect(bindings.single.allowedDirection, Direction.south);
    expect(
        maps.first.connections.map((connection) => connection.offset), [0, 6]);
    expect(maps.skip(1).map((map) => map.connections.single.offset), [0, -6]);
  });

  test('connected jump world initializes and keeps directed movement', () {
    final world = fixture.world(
        direction: Direction.south,
        mapOverride: maps.first,
        projectOverride: project);
    expect(world.map.connections, maps.first.connections);
    expect(stepGameplayWorld(world, const MoveIntent(Direction.south)),
        isA<Jumped>());
    final reverse = fixture.world(
        direction: Direction.north,
        mapOverride: maps.first,
        projectOverride: project);
    expect(
        stepGameplayWorld(
            reverse, const MoveIntent(Direction.north, pixelsPerStep: 32)),
        isA<Blocked>());
  });

  test('global graph validation still rejects overlapping target spans', () {
    final overlapping = maps.first.copyWith(connections: [
      maps.first.connections.first,
      const MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: 'east-b',
          offset: 5),
    ]);
    expect(
        () => ProjectValidator.validate(project,
            maps: [overlapping, ...maps.skip(1)]),
        throwsA(isA<ValidationException>()));
  });

  test('global graph validation still requires every target dimension', () {
    expect(() => ProjectValidator.validate(project, maps: maps.take(2)),
        throwsA(isA<ValidationException>()));
  });

  test('local binding still rejects duplicate map connections', () {
    final duplicate = maps.first.copyWith(connections: [
      maps.first.connections.first,
      maps.first.connections.first,
    ]);
    expect(
        () => bindMaterializedBorderJumpFaces(
            map: duplicate,
            project: project,
            tileSize: const PixelSize(width: 32, height: 32)),
        throwsA(isA<ValidationException>()));
  });

  test('local binding still rejects wrong map cell dimensions', () {
    final invalid =
        maps.first.copyWith(size: const GridSize(width: 1, height: 1));
    expect(
        () => bindMaterializedBorderJumpFaces(
            map: invalid,
            project: project,
            tileSize: const PixelSize(width: 32, height: 32)),
        throwsA(isA<ValidationException>()));
  });

  test('local connected Border binding still refuses a forged fingerprint', () {
    final original = fixture.feature;
    final output = original.materialization!;
    final altered = BorderFeature(
        id: original.id,
        name: original.name,
        blueprintId: original.blueprintId,
        seed: original.seed,
        geometry: original.geometry,
        lineSide: original.lineSide,
        paramsOverride: original.paramsOverride,
        overrides: original.overrides,
        keepOutRegions: original.keepOutRegions,
        materialization: BorderMaterialization(
            ground: output.ground,
            placements: output.placements,
            receipt: BorderResolutionReceipt(
                resolverVersion: output.receipt.resolverVersion,
                blueprintRevision: output.receipt.blueprintRevision,
                components: output.receipt.components,
                inputFingerprint: 'sha256:${List.filled(64, '0').join()}',
                outputFingerprint: output.receipt.outputFingerprint)));
    final forged = maps.first.copyWith(layers: [
      for (final layer in maps.first.layers)
        if (layer is BorderLayer)
          MapLayer.border(
              id: layer.id,
              name: layer.name,
              content:
                  BorderLayerContent(formatVersion: 4, features: [altered]))
        else
          layer,
    ]);
    expect(
        () => bindMaterializedBorderJumpFaces(
            map: forged,
            project: project,
            tileSize: const PixelSize(width: 32, height: 32)),
        throwsA(isA<ValidationException>()));
  });
}
