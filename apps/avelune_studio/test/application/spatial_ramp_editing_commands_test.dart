import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/spatial_ramp_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_ramp_fixture.dart';

void main() {
  test('fractional preview preserves unrelated geometry and applies once with undo redo and reopen', () {
    final map = precisionRampMap();
    final document = rampDocument(map);
    final commands = SpatialRampEditingCommands(document);
    final original = map.spatialScene!.navigation.ramps.first;
    final updated = original.copyWith(x: 2.1875, width: 3.5625);
    final preview = commands.preview(updated);
    expect(preview.validFor(map), isTrue);
    expect(preview.updatedRamp, updated);
    expect(preview.rampId, original.id);
    expect(document.current, same(map));
    expect(document.undoCount, 0);
    expect(preview.result.spatialScene!.instances, map.spatialScene!.instances);
    expect(preview.result.layers, map.layers);
    expect(preview.result.warps, map.warps);
    expect(
      preview.result.spatialScene!.navigation.ramps.last,
      same(map.spatialScene!.navigation.ramps.last),
    );
    expect(
      preview.result.spatialScene!.navigation.spawn,
      map.spatialScene!.navigation.spawn,
    );
    expect(
      preview.result.spatialScene!.navigation.blockedAreas,
      map.spatialScene!.navigation.blockedAreas,
    );
    expect(
      preview.result.spatialScene!.navigation.allowDiagonalMovement,
      isTrue,
    );
    expect(
      preview.result.spatialScene!.heightLevels,
      map.spatialScene!.heightLevels,
    );
    expect(preview.result.spatialScene!.camera, map.spatialScene!.camera);
    expect(preview.result.spatialScene!.generateCliffs, isFalse);
    commands.apply(preview);
    expect(document.current, same(preview.result));
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, map);
    document.restore(redo: true);
    expect(document.current, preview.result);
    final saved = jsonEncode(document.current.toJson());
    document.acceptSave(document.current, 'r2');
    expect(document.dirty, isFalse);
    final reopened = rampDocument(MapData.fromJson(jsonDecode(saved)));
    expect(reopened.current, preview.result);
    expect(reopened.current.spatialScene!.navigation.ramps.first.width, 3.5625);
  });

  test('changed support reanchors only Y and keeps relative offsets ownership and animation', () {
    final map = precisionRampMap();
    final document = rampDocument(map);
    final commands = SpatialRampEditingCommands(document);
    final preview = commands.preview(
      map.spatialScene!.navigation.ramps.first.copyWith(depth: 2.75),
    );
    final before = map.spatialScene!.instances.first;
    final after = preview.result.spatialScene!.instances.first;
    final delta =
        preview.result.spatialScene!.worldHeightAt(
          before.position.x,
          before.position.z,
        ) -
        map.spatialScene!.worldHeightAt(before.position.x, before.position.z);
    expect(delta, isNot(0));
    expect(
      after,
      before.copyWith(
        position: Model3dVector3(
          x: before.position.x,
          y: before.position.y + delta,
          z: before.position.z,
        ),
      ),
    );
    expect(
      after.position.y -
          preview.result.spatialScene!.worldHeightAt(
            after.position.x,
            after.position.z,
          ),
      closeTo(-.375, 1e-12),
    );
    for (var index = 1; index < map.spatialScene!.instances.length; index++) {
      expect(
        jsonEncode(preview.result.spatialScene!.instances[index].toJson()),
        jsonEncode(map.spatialScene!.instances[index].toJson()),
      );
    }
    expect(
      jsonEncode(preview.result.layers.map((layer) => layer.toJson()).toList()),
      jsonEncode(map.layers.map((layer) => layer.toJson()).toList()),
    );
    expect(preview.result.warps, map.warps);
    commands.apply(preview);
    document.restore(redo: false);
    expect(document.current, map);
  });

  test('overlap invalid contacts missing ramp saving and stale previews leave document untouched', () {
    final map = precisionRampMap();
    final document = rampDocument(map);
    final commands = SpatialRampEditingCommands(document);
    final ramp = map.spatialScene!.navigation.ramps.first;
    for (final invalid in [
      ramp.copyWith(width: 8),
      ramp.copyWith(lowLevel: 0),
      ramp.copyWith(width: 20),
      ramp.copyWith(direction: SpatialRampDirection.south),
      SpatialRamp(
        id: 'missing',
        x: 2,
        z: 3,
        width: 1,
        depth: 3,
        lowLevel: 4,
        highLevel: 8,
        direction: SpatialRampDirection.north,
      ),
    ]) {
      expect(
        () => commands.preview(invalid),
        throwsA(anyOf(isA<FormatException>(), isA<StateError>())),
      );
      expect(document.current, same(map));
      expect(document.undoCount, 0);
    }
    final preview = commands.preview(ramp.copyWith(depth: 2.75));
    document.saving = true;
    expect(() => commands.preview(ramp), throwsStateError);
    expect(() => commands.apply(preview), throwsStateError);
    expect(document.current, same(map));
    document.saving = false;
    document.commit(map.copyWith(name: 'Carte modifiée'));
    final changed = document.current;
    expect(() => commands.apply(preview), throwsStateError);
    expect(preview.validFor(changed), isFalse);
    expect(document.current, same(changed));
    expect(document.undoCount, 1);
    final planar = map.copyWith(version: ProjectVersion.v8, spatialScene: null);
    expect(
      () => SpatialRampEditingCommands(rampDocument(planar)).preview(ramp),
      throwsStateError,
    );
  });

  final sourceRamps = [
    SpatialRamp(
      id: 'pav-high',
      x: 11.6875,
      z: 13,
      width: 3.625,
      depth: 2,
      lowLevel: 28,
      highLevel: 36,
      direction: SpatialRampDirection.north,
    ),
    SpatialRamp(
      id: 'pav-mid',
      x: 11.6875,
      z: 17,
      width: 3.625,
      depth: 2,
      lowLevel: 20,
      highLevel: 28,
      direction: SpatialRampDirection.north,
    ),
    SpatialRamp(
      id: 'pav-east',
      x: 18,
      z: 20.6875,
      width: 4,
      depth: 1.625,
      lowLevel: 4,
      highLevel: 20,
      direction: SpatialRampDirection.west,
    ),
    SpatialRamp(
      id: 'route-stair',
      x: 54.998046875,
      z: 13.125,
      width: 5.001953125,
      depth: 1.75,
      lowLevel: 3,
      highLevel: 23,
      direction: SpatialRampDirection.east,
    ),
  ];
  for (final ramp in sourceRamps) {
    test(
      'exact footprint ${ramp.id} survives preview application and serialization',
      () {
        final map = sourceRampFootprint(ramp);
        final document = rampDocument(map);
        final commands = SpatialRampEditingCommands(document);
        final preview = commands.preview(SpatialRamp.fromJson(ramp.toJson()));
        expect(preview.hasChanges, isFalse);
        expect(preview.result, map);
        expect(preview.updatedRamp.toJson(), ramp.toJson());
        commands.apply(preview);
        expect(document.undoCount, 0);
        expect(MapData.fromJson(document.current.toJson()), map);
      },
    );
  }

  test('contact and overlap errors have clear French recovery messages', () {
    expect(
      spatialRampEditingFailureMessage(
        const FormatException(
          'A ramp must contact its low and high terrain levels.',
        ),
      ),
      contains('extrémités'),
    );
    expect(
      spatialRampEditingFailureMessage(
        const FormatException('Navigation rectangles must not overlap.'),
      ),
      contains('chevaucher'),
    );
  });
}
