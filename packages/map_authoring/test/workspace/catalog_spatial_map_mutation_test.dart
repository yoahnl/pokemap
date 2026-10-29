import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/maps/border_spatial_actions_test.dart'
    show spatialBorderAuthoringFixture;
import '../domains/maps/environment_spatial_actions_test.dart'
    show spatialEnvironmentFixture;
import '../domains/maps/healing_display_fixture.dart';
import '../domains/maps/spatial_field_obstacle_actions_test.dart' show obstacleProject, obstacleMap;

void main() {
  final relinkReads = <List<int>>[];
  for (final unrelated in [0, 90]) {
    test('spatial relink stays targeted on first repeat and undo with $unrelated foreign maps', () async {
      final base = spatialBorderAuthoringFixture(published: true);
      final encoded = encodeBorderBlueprintRecordJson(base.project.borderCatalog.records.single,
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion);
      encoded['id'] = 'replacement';
      final project = base.project.copyWith(borderCatalog: ProjectBorderCatalog(
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
          records: [...base.project.borderCatalog.records,
            decodeBorderBlueprintRecordJson(encoded,
                formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion)]));
      final fixture = await _Fixture.open(unrelated, content: (project: project, map: base.map));
      addTearDown(fixture.close);
      final counts = <int>[];
      for (var repeat = 0; repeat < 2; repeat++) {
        fixture.reader.paths.clear();
        final before = await fixture.mapFile.readAsBytes();
        final timer = Stopwatch()..start();
        final result = await fixture.apply('border_layer.relink_apply', {
          'mapId': 'map', 'layerId': 'border', 'featureId': 'fence',
          'targetBlueprintId': repeat == 0 ? 'replacement' : 'fence',
          'reverseStrokes': true, 'clearVerticalOffset': true,
        }, 'relink-$repeat');
        timer.stop();
        counts.add(fixture.reader.paths.length);
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
        expect(fixture.reader.paths.where((path) => path.startsWith('maps/') && path != 'maps/map.json' || path.endsWith('.glb') || path.endsWith('history.jsonl')), isEmpty);
        expect(counts.last, lessThan(170));
        print('spatial-relink foreign=$unrelated repeat=$repeat reads=${counts.last} elapsedUs=${timer.elapsedMicroseconds}');
        final after = await fixture.mapFile.readAsBytes();
        await fixture.api.undoMutation(fixture.opened.projectHandle,
            entryId: result.receipt.receiptId, idempotencyKey: 'undo-relink-$repeat');
        expect(await fixture.mapFile.readAsBytes(), before);
        if (repeat == 0) {
          await fixture.apply('border_layer.relink_apply', {
            'mapId': 'map', 'layerId': 'border', 'featureId': 'fence',
            'targetBlueprintId': 'replacement', 'reverseStrokes': true,
            'clearVerticalOffset': true,
          }, 'relink-again');
          expect(await fixture.mapFile.readAsBytes(), after);
        }
      }
      relinkReads.add(counts);
      if (relinkReads.length == 2) {
        for (var index = 0; index < counts.length; index++) {
          expect(counts[index] - relinkReads.first[index], inInclusiveRange(0, 16),
              reason: 'Only the bounded catalog index walk may deepen; foreign definitions and maps must remain unread');
        }
      }
      await fixture.reopen();
      final map = MapData.fromJson(jsonDecode(await fixture.mapFile.readAsString()));
      expect((map.layers.single as BorderLayer).content.features.single.blueprintId, 'replacement');
    });
  }
  for (final unrelated in [0, 90]) {
    test('targeted spatial field route first repeat undo reopen ignores $unrelated foreign maps', () async {
      final base = spatialEnvironmentFixture();
      final fixture = await _Fixture.open(unrelated, content: base);
      addTearDown(fixture.close);
      final zone = MapGameplayZone(id: 'cascade', kind: GameplayZoneKind.fieldAction,
        area: const MapRect(pos: GridPos(x: 0, y: 0), size: GridSize(width: 3, height: 1)),
        fieldAction: const FieldActionZonePayload(actionKind: FieldActionZoneKind.waterfall,
          waterfall: WaterfallZonePayload(entry: GridPos(x: 0, y: 0), path: [GridPos(x: 1, y: 0)],
            exit: GridPos(x: 2, y: 0), direction: MapConnectionDirection.east)));
      final counts = <int>[];
      for (var repeat = 0; repeat < 2; repeat++) {
        fixture.reader.paths.clear();
        final action = repeat == 0 ? 'gameplay_zone.create' : 'gameplay_zone.update';
        final parameters = <String, Object?>{'mapId': 'map', 'zone': zone.copyWith(name: 'Route $repeat').toJson(), if (repeat != 0) 'zoneId': zone.id};
        final selected = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle, actionId: action, parameters: parameters);
        expect(selected.manifest.models3d, isEmpty);
        final timer = Stopwatch()..start();
        await fixture.apply(action, parameters, 'route-$repeat', revision: selected.revision);
        timer.stop();
        counts.add(fixture.reader.paths.length);
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
        expect(fixture.reader.paths.where((p) => p.startsWith('maps/') && p != 'maps/map.json' || p.endsWith('.glb') || p.endsWith('history.jsonl')), isEmpty);
        print('field-route foreign=$unrelated repeat=$repeat reads=${counts.last} elapsedUs=${timer.elapsedMicroseconds}');
      }
      expect(counts.every((n) => n < 90), isTrue, reason: '$counts');
      await fixture.reopen();
      for (final operation in <(String, Map<String, Object?>)>[
        ('gameplay_zone.move', {'zoneId': zone.id, 'x': 1, 'y': 1}),
        ('gameplay_zone.resize', {'zoneId': zone.id, 'width': 4, 'height': 1}),
        ('gameplay_zone.set_priority', {'zoneId': zone.id, 'priority': 2}),
        ('gameplay_zone.clone', {'zoneId': zone.id, 'newId': 'copy', 'x': 1, 'y': 2}),
        ('gameplay_zone.delete', {'zoneId': 'copy'}),
      ]) {
        fixture.reader.paths.clear();
        await fixture.apply(operation.$1, {'mapId': 'map', ...operation.$2}, 'route-${operation.$1}-${operation.$2['zoneId']}');
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
        expect(fixture.reader.paths.where((p) => p.startsWith('maps/') && p != 'maps/map.json' || p.endsWith('.glb') || p.endsWith('history.jsonl')), isEmpty);
      }
      final before = await fixture.mapFile.readAsBytes();
      final deleted = await fixture.apply('gameplay_zone.delete', {'mapId': 'map', 'zoneId': zone.id}, 'delete-route');
      await fixture.api.undoMutation(fixture.opened.projectHandle, entryId: deleted.receipt.receiptId, idempotencyKey: 'undo-route');
      expect(await fixture.mapFile.readAsBytes(), before);
    });
  }


  final obstacleCounts = <List<int>>[];
  for (final unrelated in [0, if (Platform.environment['AVELUNE_FIELD_OBSTACLE_LARGE_FIXTURE'] == '1') 2000]) {
    test('targeted 3D field obstacles first repeat undo reopen with $unrelated foreign maps', () async {
      final source = obstacleMap();
      final fixture = await _Fixture.open(unrelated, content: (
        project: obstacleProject().copyWith(maps: const [ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')]),
        map: source.copyWith(id: 'map'),
      ));
      addTearDown(fixture.close);
      final counts = <int>[];
      for (var repeat = 0; repeat < 2; repeat++) {
        fixture.reader.paths.clear();
        final timer = Stopwatch()..start();
        final applied = await fixture.apply('map3d.instance.configure_field_obstacle', {
          'mapId': 'map', 'instanceId': 'oak-1', 'fieldObstacle': {
            'kind': repeat == 0 ? 'cutTree' : 'rockSmashRock', 'resetPolicy': 'persistent',
          },
        }, 'obstacle-$repeat');
        timer.stop();
        counts.add(fixture.reader.paths.length);
        expect(applied.receipt.diff.entries.map((entry) => entry.resource.kind).toSet(), {'catalogHead', 'map'});
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
        expect(fixture.reader.paths.where((p) => p.startsWith('maps/') && p != 'maps/map.json'), isEmpty);
        expect(fixture.reader.paths.where((p) => p.endsWith('.glb') || p.endsWith('history.jsonl')), isEmpty);
        final after = MapData.fromJson(jsonDecode(await fixture.mapFile.readAsString()));
        expect(isValidSpatialFieldObstacle(after, after.entities.single), isTrue);
        expect(after.entities.single.fieldObstacle!.resetPolicy, FieldObstacleResetPolicy.persistent);
        print('field-obstacle foreign=$unrelated repeat=$repeat reads=${counts.last} elapsedUs=${timer.elapsedMicroseconds}');
      }
      obstacleCounts.add(counts);
      expect(counts.every((count) => count <= 90), isTrue, reason: '$counts');
      await fixture.reopen();
      final scope = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle,
        actionId: 'map3d.instance.configure_field_obstacle', parameters: {'mapId': 'map', 'instanceId': 'oak-1', 'fieldObstacle': null});
      expect(scope.manifest.models3d.map((m) => m.id), ['oak']);
      expect(scope.maps.single.entities.single.fieldObstacle!.kind, FieldObstacleKind.rockSmashRock);
      final beforeClear = await fixture.mapFile.readAsBytes();
      final clear = await fixture.apply('map3d.instance.configure_field_obstacle', {'mapId': 'map', 'instanceId': 'oak-1', 'fieldObstacle': null}, 'clear');
      final cleared = MapData.fromJson(jsonDecode(await fixture.mapFile.readAsString()));
      expect(cleared.entities.single.fieldObstacle, isNull);
      expect(cleared.spatialScene!.instances.single.entityId, cleared.entities.single.id);
      await fixture.api.undoMutation(fixture.opened.projectHandle, entryId: clear.receipt.receiptId, idempotencyKey: 'undo-clear');
      expect(await fixture.mapFile.readAsBytes(), beforeClear);
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
  for (final unrelated in [0, 90]) {
    test('targeted spatial Border reorder preserves full feature and instances with $unrelated foreign maps', () async {
      final base = spatialBorderAuthoringFixture(published: true);
      final layer = base.map.layers.single as BorderLayer;
      final original = layer.content.features.single;
      final cells = List.filled(base.map.size.width * base.map.size.height, false);
      cells[0] = cells[1] = cells[2] = true;
      BorderFeature feature(String id) => BorderFeature(id: id, name: id, blueprintId: original.blueprintId, seed: original.seed,
          geometry: original.geometry,
          overrides: [BorderSlotOverride(slotKey: 'retained-slot', variationSalt: BorderSignedInt64.fromInt(3), suppressed: true, locked: false)],
          keepOutRegions: [BorderKeepOutRegion(id: 'opening', region: BorderRegionGeometry(width: base.map.size.width, height: base.map.size.height, cells: cells))]);
      final features = [feature('front'), feature('fence'), feature('back')];
      final beforeMap = base.map.copyWith(layers: [layer.copyWith(content: BorderLayerContent(formatVersion: 4, features: features))],
          spatialScene: base.map.spatialScene!.copyWith(instances: [SpatialModelInstance(id: 'sentinel', modelId: 'tree', position: Model3dVector3(x: 1, y: 0, z: 1))]));
      final fixture = await _Fixture.open(unrelated, content: (project: base.project, map: beforeMap));
      addTearDown(fixture.close);
      fixture.reader.paths.clear();
      await fixture.apply('border_layer.feature_reorder', {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence', 'newIndex': 2}, 'reorder');
      final expected = beforeMap.copyWith(layers: [layer.copyWith(content: BorderLayerContent(formatVersion: 4, features: [features[0], features[2], features[1]]))]);
      final after = MapData.fromJson(jsonDecode(await fixture.mapFile.readAsString()));
      expect(after.toJson(), expected.toJson());
      expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
      expect(fixture.reader.paths.where((p) => p.startsWith('maps/') && p != 'maps/map.json'), isEmpty);
      expect(fixture.reader.paths.length, lessThan(150));
      await fixture.reopen();
      final selected = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle, actionId: 'border_layer.feature_reorder', parameters: {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence', 'newIndex': 1});
      expect(selected.maps.single.toJson(), expected.toJson());
      final persisted = await fixture.mapFile.readAsBytes();
      for (final ids in [('border', 'missing'), ('missing', 'fence')]) {
        await expectLater(fixture.apply('border_layer.feature_reorder', {'mapId': 'map', 'layerId': ids.$1, 'featureId': ids.$2, 'newIndex': 0}, 'bad-${ids.$1}-${ids.$2}'), throwsA(isA<ValidationException>()));
        expect(await fixture.mapFile.readAsBytes(), persisted);
      }
    });
  }


  final geometryReadCounts = <int, List<int>>{};
  for (final unrelated in [0, 90]) {
    test('targeted spatial Border geometry edits stay map-scoped with $unrelated foreign maps', () async {
      final base = spatialBorderAuthoringFixture(published: true);
      final layer = base.map.layers.single as BorderLayer;
      final fence = layer.content.features.single;
      final width = base.map.size.width, height = base.map.size.height;
      final mass = BorderFeature(id: 'mass', name: 'Mass', blueprintId: fence.blueprintId, seed: fence.seed,
          geometry: BorderRegionGeometry(width: width, height: height, cells: List.filled(width * height, false)),
          overrides: const [], keepOutRegions: const []);
      final beforeMap = base.map.copyWith(layers: [layer.copyWith(content: BorderLayerContent(formatVersion: 4, features: [fence, mass]))]);
      final fixture = await _Fixture.open(unrelated, content: (project: base.project, map: beforeMap));
      addTearDown(fixture.close);
      final operations = <(String, Map<String, Object?>)>[
        ('border_layer.stroke_add', {'featureId': 'fence', 'strokeId': 'extra', 'points': [{'x': 1, 'y': 3}, {'x': 2, 'y': 3}, {'x': 3, 'y': 3}]}),
        ('border_layer.stroke_update', {'featureId': 'fence', 'strokeId': 'extra', 'points': [{'x': 1, 'y': 3}, {'x': 2, 'y': 3}]}),
        ('border_layer.stroke_delete', {'featureId': 'fence', 'strokeId': 'extra'}),
        ('border_layer.stroke_erase', {'featureId': 'fence', 'points': [{'x': 1, 'y': 1}]}),
        ('border_layer.region_fill', {'featureId': 'mass', 'x': 1, 'y': 2, 'width': 2, 'height': 1}),
        ('border_layer.region_clear', {'featureId': 'mass', 'x': 1, 'y': 2, 'width': 1, 'height': 1}),
      ];
      final counts = <int>[];
      Future<AuthoringMutationResult> scoped(String action, Map<String, Object?> parameters, String operation) async {
        fixture.reader.paths.clear();
        final timer = Stopwatch()..start();
        final result = await fixture.apply(action, {'mapId': 'map', 'layerId': 'border', ...parameters}, operation);
        timer.stop();
        counts.add(fixture.reader.paths.length);
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty, reason: action);
        expect(fixture.reader.paths.where((p) => p.startsWith('maps/') && p != 'maps/map.json' || p.endsWith('.glb') || p.endsWith('history.jsonl')), isEmpty, reason: action);
        print('border-geometry foreign=$unrelated action=$action reads=${counts.last} elapsedUs=${timer.elapsedMicroseconds}');
        return result;
      }
      for (final (action, parameters) in operations) {
        await scoped(action, parameters, 'first-$action');
      }
      final edited = MapData.fromJson(jsonDecode(await fixture.mapFile.readAsString()));
      final features = (edited.layers.single as BorderLayer).content.features;
      final fenceGeometry = features.firstWhere((f) => f.id == 'fence').geometry as BorderStrokeGeometry;
      expect(fenceGeometry.strokes.map((stroke) => stroke.id), isNot(contains('extra')));
      final massCells = (features.firstWhere((f) => f.id == 'mass').geometry as BorderRegionGeometry).cells;
      expect([for (var i = 0; i < massCells.length; i++) if (massCells[i]) i], [2 * width + 2]);
      await fixture.reopen();
      await scoped('border_layer.region_fill', {'featureId': 'mass', 'x': 3, 'y': 2, 'width': 1, 'height': 1}, 'reopened-fill');
      final beforeRepeat = await fixture.mapFile.readAsBytes();
      final repeated = await scoped('border_layer.region_fill', {'featureId': 'mass', 'x': 4, 'y': 2, 'width': 1, 'height': 1}, 'repeated-fill');
      await fixture.api.undoMutation(fixture.opened.projectHandle, entryId: repeated.receipt.receiptId, idempotencyKey: 'undo-repeated-fill');
      expect(await fixture.mapFile.readAsBytes(), beforeRepeat);
      expect(counts.every((n) => n < 150), isTrue, reason: '$counts');
      geometryReadCounts[unrelated] = counts;
      final baseline = geometryReadCounts[0];
      if (baseline != null && unrelated != 0) {
        for (var index = 0; index < counts.length; index++) {
          expect(counts[index] - baseline[index], inInclusiveRange(0, 16),
              reason: 'Unrelated maps may only deepen the catalog index walk: $baseline -> $counts');
        }
      }
    });
  }

  for (final usage in [SmartTileUsage.path, SmartTileUsage.terrain]) {
    for (final action in ['smart_tile.pattern.paint', 'smart_tile.pattern.paint_batch']) {
      for (final unrelated in [0, 90]) {
        test('targeted pattern ${usage.name} $action with $unrelated foreign maps', () async {
          final fixture = await _Fixture.open(unrelated, content: _patternContent(usage), unreadPatternIds: {'foreign-pattern'});
          addTearDown(fixture.close);
          for (var repeat = 0; repeat < 2; repeat++) {
            final parameters = _patternParameters(action, 'patch', 'stroke-$repeat', repeat + 1);
            fixture.reader.paths.clear();
            final selected = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle, actionId: action, parameters: parameters);
            expect(selected.manifest.smartTileCatalog.patterns.map((p) => p.id), ['patch']);
            await fixture.apply(action, parameters, 'pattern-$repeat');
            expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
            expect(fixture.reader.paths.where((p) => p.startsWith('maps/') && p != 'maps/map.json'), isEmpty);
            expect(fixture.reader.paths.length, lessThan(200));
            final map = MapData.fromJson(jsonDecode(await fixture.mapFile.readAsString()));
            final layer = map.layers.whereType<SmartTileLayer>().single;
            expect(layer.usage, usage);
            expect(layer.patternStrokes, hasLength(repeat + 1));
            expect(layer.patternStrokes.last.cells, [GridPos(x: repeat + 1, y: 1)]);
            expect(layer.patternStrokes.last.phaseX, -repeat - 1);
            expect(layer.patternStrokes.last.phaseY, -1);
            expect(smartTileSemanticCells(layer).every((c) => c == 0), isTrue);
          }
          await fixture.reopen();
          final selected = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle, actionId: action, parameters: _patternParameters(action, 'patch', 'reopen', 1));
          expect(selected.maps.single.layers.whereType<SmartTileLayer>().single.patternStrokes, hasLength(2));
        });
      }
    }
  }
  test('targeted pattern rejects missing and mismatched usage without writes', () async {
    final fixture = await _Fixture.open(0, content: _patternContent(SmartTileUsage.terrain));
    addTearDown(fixture.close);
    final before = await fixture.mapFile.readAsBytes();
    for (final pair in [('missing', 'smart_tile.pattern.unknown'), ('wrong-usage', 'smart_tile.pattern.usage_mismatch')]) {
      await expectLater(fixture.apply('smart_tile.pattern.paint_batch', _patternParameters('smart_tile.pattern.paint_batch', pair.$1, 'rejected', 1), 'rejected-${pair.$1}'), throwsA(isA<MapAuthoringException>().having((e) => e.code, 'domain code', pair.$2)));
      expect(await fixture.mapFile.readAsBytes(), before);
    }
  });

  for (final unrelated in [0, 90]) {
    test('native preset changes preserve geometry and undo with $unrelated foreign maps', () async {
      final base = spatialEnvironmentFixture();
      final raw = _groundCatalog().toJson();
      (raw['presets'] as List).add({...Map<String, dynamic>.from((raw['presets'] as List).single), 'id': 'alternate'});
      final fixture = await _Fixture.open(unrelated, content: (
        project: base.project.copyWith(smartTileCatalog: ProjectSmartTileCatalog.fromJson(raw), tilesets: const [
          ProjectTilesetEntry(id: 'ground-image', name: 'Ground', relativePath: 'assets/ground.png')
        ]), map: base.map
      ));
      addTearDown(fixture.close);
      await fixture.apply('smart_tile.layer.create', {
        'mapId': 'map', 'layerId': 'water', 'name': 'Water', 'presetId': 'ground'
      }, 'create-water');
      await fixture.apply('smart_tile.cell.paint', {
        'mapId': 'map', 'layerId': 'water', 'materialId': 'grass', 'cells': [{'x': 1, 'y': 1}]
      }, 'paint-water');
      final before = await fixture.mapFile.readAsBytes();
      for (var repeat = 0; repeat < 2; repeat++) {
        fixture.reader.paths.clear();
        final applied = await fixture.apply('smart_tile.layer.change_preset', {
          'mapId': 'map', 'layerId': 'water', 'targetPresetId': 'alternate'
        }, 'change-water-$repeat');
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
        expect(fixture.reader.paths.where((p) => p.startsWith('maps/') && p != 'maps/map.json'), isEmpty);
        expect(fixture.reader.paths.length, lessThan(160));
        final after = MapData.fromJson(jsonDecode(await fixture.mapFile.readAsString()));
        final original = MapData.fromJson(jsonDecode(utf8.decode(before)));
        final layer = after.layers.whereType<SmartTileLayer>().single;
        expect(layer.presetId, 'alternate');
        expect(smartTileSemanticCells(layer), smartTileSemanticCells(original.layers.whereType<SmartTileLayer>().single));
        expect(after.spatialScene, original.spatialScene);
        await fixture.reopen();
        final scope = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle,
          actionId: 'smart_tile.layer.change_preset', parameters: {'mapId': 'map', 'layerId': 'water', 'targetPresetId': 'ground'});
        expect(scope.maps.single, after);
        await fixture.api.undoMutation(fixture.opened.projectHandle,
          entryId: applied.receipt.receiptId, idempotencyKey: 'undo-water-$repeat');
        expect(await fixture.mapFile.readAsBytes(), before);
      }
    });
  }
  for (final unrelated in [0, 80]) {
    test(
        'ladder and additive character clips stay local with $unrelated foreign maps',
        () async {
      final base = spatialEnvironmentFixture();
      final hero = ProjectCharacterEntry(
          id: 'hero', name: 'Hero', tilesetId: 'hero-sheet');
      final warp = MapWarp(
          id: 'stairs',
          pos: const GridPos(x: 1, y: 1),
          targetMapId: base.map.id,
          targetPos: const GridPos(x: 2, y: 1));
      final f = await _Fixture.open(unrelated, content: (
        project: base.project.copyWith(characters: [
          hero
        ], tilesets: const [
          ProjectTilesetEntry(
              id: 'hero-sheet', name: 'Hero', relativePath: 'assets/hero.png')
        ]),
        map: base.map.copyWith(warps: [warp])
      ));
      addTearDown(f.close);
      final counts = <int>[], times = <int>[];
      for (var repeat = 0; repeat < 2; repeat++) {
        f.reader.paths.clear();
        final timer = Stopwatch()..start();
        final ladder = MapWarpLadder(
            direction: repeat == 0
                ? MapWarpLadderDirection.up
                : MapWarpLadderDirection.down);
        await f.apply(
            'warp.ladder.configure',
            {
              'mapId': base.map.id,
              'warpId': 'stairs',
              'ladder': ladder.toJson()
            },
            'ladder-$repeat');
        times.add(timer.elapsedMilliseconds);
        expect(
            f.reader.paths
                .where((p) => p.startsWith('maps/') && p != 'maps/map.json'),
            isEmpty);
        expect(f.reader.paths.where(f.unrelatedObjects.contains), isEmpty);
        counts.add(f.reader.paths.length);
      }
      expect(counts.every((count) => count <= 72), isTrue);
      f.reader.paths.clear();
      final clip = CharacterAnimation(
          state: CharacterAnimationState.climb,
          direction: EntityFacing.north,
          frames: const [
            CharacterAnimationFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 16, height: 16),
                durationMs: 100)
          ]);
      final updated = hero.copyWith(animations: [clip]);
      await f.apply('campaign.character.upsert', {'value': updated.toJson()},
          'append-climb',
          workshop: true);
      expect(f.reader.paths.where((p) => p.startsWith('maps/')), isEmpty);
      expect(f.reader.paths.where(f.unrelatedObjects.contains), isEmpty);
      f.reader.paths.clear();
      await f.apply('characterStudio.animationClip.upsert', {'characterId':'hero', 'kind':'system','state':'climb','direction':'north','loop':true,'frames':[
        {'source':{'x':0,'y':0,'width':16,'height':16},'durationMs':133},
        {'source':{'x':16,'y':0,'width':16,'height':16},'durationMs':133},
      ]}, 'animate-climb', workshop:true);
      expect(f.reader.paths.where((p) => p.startsWith('maps/')), isEmpty);
      expect(f.reader.paths.where(f.unrelatedObjects.contains), isEmpty);
      await expectLater(
          f.apply(
              'campaign.character.upsert',
              {'value': updated.copyWith(name: 'Changed').toJson()},
              'reject-identity',
              workshop: true),
          throwsA(isA<AuthoringPlanException>()));
      await expectLater(
          f.apply('campaign.character.upsert', {'value': hero.toJson()},
              'reject-removal',
              workshop: true),
          throwsA(isA<AuthoringPlanException>()));
      await f.reopen();
      final loaded = await f.api.readWorkshopSnapshot(f.opened.projectHandle,
          actionId: 'warp.ladder.configure',
          parameters: {
            'mapId': base.map.id,
            'warpId': 'stairs',
            'ladder': null
          });
      expect(loaded.mapById(base.map.id)!.warps.single.ladder!.direction,
          MapWarpLadderDirection.down);
      print(jsonEncode({
        'ladderUnrelated': unrelated,
        'reads': counts,
        'firstRepeatedMs': times
      }));
    });
  }
  for (final unrelated in [0, 80]) {
    test('battle audio configuration stays scoped with $unrelated unrelated records', () async {
      final fixture = await _Fixture.open(unrelated);
      addTearDown(fixture.close);
      final artifact = await fixture.api.artifacts.put(_storyWav(), declaredMediaType: 'audio/wav');
      await fixture.apply('scene.dialogue.audioMedia.import', {
        'artifactHandle': artifact.reference.handle, 'assetId': 'eye', 'mediaId': 'eye',
        'label': 'Eye', 'logicalPath': 'assets/music/eye.wav', 'mediaKind': 'music',
      }, 'import-eye');
      final reads = <int>[];
      final times = <int>[];
      for (var repeat = 0; repeat < 2; repeat++) {
        fixture.reader.paths.clear();
        final watch = Stopwatch()..start();
        await fixture.apply('project.battle_audio.update', {'encounterMusicPath': repeat == 0 ? 'assets/music/eye.wav' : null}, 'change-eye-$repeat');
        times.add(watch.elapsedMilliseconds);
        final selected = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle,
          actionId: 'project.battle_audio.update', parameters: {'encounterMusicPath': null});
        expect(selected.maps, isEmpty);
        expect(selected.manifest.battleAudio?.encounterMusicPath, repeat == 0 ? 'assets/music/eye.wav' : null);
        expect(fixture.reader.paths.where((p) => p.startsWith('maps/')), isEmpty);
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
        reads.add(fixture.reader.paths.length);
      }
      expect(reads.last, lessThanOrEqualTo(reads.first));
      print(jsonEncode({'battleAudioUnrelated': unrelated, 'reads': reads, 'firstRepeatedMs': times}));
      await fixture.reopen();
      final selected = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle,
        actionId: 'project.battle_audio.update', parameters: {'encounterMusicPath': null});
      expect(selected.manifest.battleAudio, isNull);
    });
  }
  for (final unrelated in [0, 80]) {
    test('story entities and triggers stay local with $unrelated foreign maps',
        () async {
      final base = spatialEnvironmentFixture();
      final fixture = await _Fixture.open(unrelated, content: (
        project: base.project.copyWith(
          characters: const [
            ProjectCharacterEntry(
                id: 'guide', name: 'Guide', tilesetId: 'actor')
          ],
          tilesets: const [
            ProjectTilesetEntry(
                id: 'actor', name: 'Actor', relativePath: 'assets/actor.png')
          ],
        ),
        map: base.map.copyWith(properties: {'keep': 'preserved'}),
      ));
      addTearDown(fixture.close);
      final readCounts = <int>[];
      final timings = <int>[];
      for (var repeat = 0; repeat < 2; repeat++) {
        fixture.reader.paths.clear();
        final timer = Stopwatch()..start();
        await fixture.apply(
            'entity.upsert',
            {
              'mapId': 'map',
              'entity': const MapEntity(
                id: 'story-npc',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 2, y: 2),
                npc: MapEntityNpcData(
                    displayName: 'Guide', characterId: 'guide'),
              ).copyWith(name: 'Guide $repeat').toJson(),
            },
            'story-npc-$repeat');
        await fixture.apply(
            'trigger.create',
            {
              'mapId': 'map',
              'trigger': {
                'id': 'story-trigger-$repeat',
                'name': 'Story trigger $repeat',
                'type': 'event',
                'area': {
                  'pos': {'x': 1 + repeat, 'y': 1},
                  'size': {'width': 1, 'height': 1},
                },
              },
            },
            'story-trigger-$repeat');
        timings.add(timer.elapsedMilliseconds);
        readCounts.add(fixture.reader.paths.length);
        expect(
            fixture.reader.paths
                .where((p) => p.startsWith('maps/') && p != 'maps/map.json'),
            isEmpty);
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains),
            isEmpty);
        expect(fixture.reader.paths.length, lessThan(480));
      }
      final after = MapData.fromJson(
          jsonDecode(await fixture.mapFile.readAsString())
              as Map<String, dynamic>);
      expect(after.entities.single.name, 'Guide 1');
      expect(after.triggers, hasLength(2));
      expect(after.properties, {'keep': 'preserved'});
      expect(await File('${fixture.root.path}/project.json').readAsBytes(),
          fixture.descriptor);
      await fixture.reopen();
      final selected = await fixture.api.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: 'entity.upsert',
          parameters: {
            'mapId': 'map',
            'entity': after.entities.single.toJson()
          });
      expect(selected.maps.single, after);
      expect(selected.manifest.characters.map((value) => value.id), ['guide']);
      print(jsonEncode({
        'storyUnrelated': unrelated,
        'reads': readCounts,
        'elapsedMs': timings
      }));
    });
  }

  test('story map scope preserves failed validation and rejects stale writes',
      () async {
    final fixture = await _Fixture.open(0);
    addTearDown(fixture.close);
    final entity = const MapEntity(
        id: 'npc',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
        npc: MapEntityNpcData(displayName: 'Guide'));
    final parameters = {'mapId': 'map', 'entity': entity.toJson()};
    await fixture.apply('entity.upsert', parameters, 'create');
    final before = await fixture.mapFile.readAsBytes();
    await expectLater(
        fixture.apply(
            'entity.upsert',
            {
              'mapId': 'map',
              'entity': entity
                  .copyWith(kind: MapEntityKind.custom, npc: null)
                  .toJson(),
            },
            'change-kind'),
        throwsA(isA<AuthoringPlanException>()
            .having((e) => e.code, 'code', 'catalog.mutation_scope_required')));
    await expectLater(
        fixture.apply(
            'entity.upsert',
            {
              'mapId': 'map',
              'entity': entity
                  .copyWith(npc: entity.npc!.copyWith(characterId: 'missing'))
                  .toJson(),
            },
            'missing-character'),
        throwsA(isA<Exception>()));
    expect(await fixture.mapFile.readAsBytes(), before);
    final selected = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'entity.upsert',
        parameters: parameters);
    final plan = await fixture.api.planMutation(
        fixture.opened.projectHandle,
        AuthoringRequest(
            requestId: 'stale-story',
            actionId: 'entity.upsert',
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            expectedRevision: selected.revision,
            idempotencyKey: 'stale-story',
            parameters: {
              'mapId': 'map',
              'entity': entity.copyWith(name: 'Changed').toJson()
            }));
    final external = utf8.encode(jsonEncode(selected.maps.single
        .copyWith(properties: {'external': 'keep'}).toJson()));
    await fixture.mapFile.writeAsBytes(external);
    await expectLater(
        fixture.api.applyMutation(fixture.opened.projectHandle,
            planId: plan.planId, operationId: 'stale-story'),
        throwsA(isA<Exception>()));
    expect(await fixture.mapFile.readAsBytes(), external);
  });

  test('the map view reads the targeted catalog map at its scoped revision',
      () async {
    final fixture = await _Fixture.open(3);
    addTearDown(fixture.close);
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [fixture.root.path], fileReader: fixture.reader);
    final read = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy,
            fileReader: fixture.reader,
            handles: fixture.handles),
        snapshotLoader: ProjectSnapshotLoader(handles: fixture.handles));
    final opened = await read.openProject(fixture.root.path);
    final view = await read.readMapView(opened.projectHandle, 'map');
    expect(view.map.id, 'map');
    expect(view.manifest.maps.map((entry) => entry.id), contains('map'));
    final page = await read.queryProject(
        opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'borderFeature',
            operation: AuthoringQueryOperation.list,
            filters: const {'mapId': 'map'}));
    expect(view.revision, page.snapshotRevision);
    await expectLater(
        read.readMapView(opened.projectHandle, 'nowhere'),
        throwsA(isA<AuthoringQueryException>()
            .having((error) => error.code, 'code', 'query.resource_not_found')));
  });

  test('JSONL story trigger creation undo and reopen preserve the original map',
      () async {
    final fixture = await _Fixture.open(0);
    addTearDown(fixture.close);
    final before = await fixture.mapFile.readAsBytes();
    final parameters = <String, Object?>{
      'mapId': 'map',
      'trigger': {
        'id': 'event',
        'name': 'Event',
        'type': 'event',
        'area': {
          'pos': {'x': 1, 'y': 1},
          'size': {'width': 1, 'height': 1}
        },
      }
    };
    final snapshot = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'trigger.create',
        parameters: parameters);
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [fixture.root.path], fileReader: fixture.reader);
    final worker = JsonlWorker(
        api: AuthoringReadApi(
            openService: ProjectOpenService(
                policy: policy,
                fileReader: fixture.reader,
                handles: fixture.handles,
                catalogMetadataFields: {}),
            snapshotLoader: ProjectSnapshotLoader(handles: fixture.handles)),
        mutations: fixture.api);
    Future<AuthoringResult> command(
            String name, Map<String, Object?> args) async =>
        AuthoringResult.fromJson(jsonDecode(await worker.processLine(
            jsonEncode({'id': name, 'command': name, 'args': args}))));
    final planned = await command('plan', {
      'projectHandle': fixture.opened.projectHandle.value,
      'request': AuthoringRequest(
              requestId: 'jsonl-story',
              actionId: 'trigger.create',
              actionVersion: 1,
              workspaceHandle: fixture.opened.workspaceHandle.value,
              expectedRevision: snapshot.revision,
              idempotencyKey: 'jsonl-story',
              parameters: parameters)
          .toJson()
    });
    expect(planned.status, AuthoringResultStatus.success,
        reason: planned.toJson().toString());
    final applied = await command('apply', {
      'projectHandle': fixture.opened.projectHandle.value,
      'planId': planned.data['planId'],
      'operationId': 'jsonl-story'
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: applied.toJson().toString());
    final receipt = applied.data['receipt'] as Map;
    final undone = await command('undo', {
      'projectHandle': fixture.opened.projectHandle.value,
      'entryId': receipt['receiptId'],
      'idempotencyKey': 'jsonl-story-undo'
    });
    expect(undone.status, AuthoringResultStatus.success,
        reason: undone.toJson().toString());
    expect(await fixture.mapFile.readAsBytes(), before);
    await fixture.reopen();
    final reopened = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'trigger.create',
        parameters: parameters);
    expect(reopened.maps.single.triggers, isEmpty);
  });

  for (final unrelated in [0, 80]) {
    test(
        'audio imports use only their media row with $unrelated unrelated records',
        () async {
      final base = spatialEnvironmentFixture();
      final fixture = await _Fixture.open(unrelated, content: (
        project: base.project.copyWith(cinematicMediaAssets: [
          for (var i = 0; i < unrelated; i++)
            CinematicMediaAsset(
                id: 'foreign-media-$i',
                label: 'Foreign $i',
                kind: CinematicMediaAssetKind.music,
                relativePath: 'assets/foreign-$i.wav'),
        ]),
        map: base.map,
      ));
      addTearDown(fixture.close);
      final bytes = _storyWav();
      final artifact = await fixture.api.artifacts
          .put(bytes, declaredMediaType: 'audio/wav');
      final counts = <int>[];
      for (var repeat = 0; repeat < 2; repeat++) {
        fixture.reader.paths.clear();
        final parameters = <String, Object?>{
          'artifactHandle': artifact.reference.handle,
          'assetId': 'music-$repeat',
          'mediaId': 'music-$repeat',
          'label': 'Story music $repeat',
          'logicalPath': 'assets/music/story-$repeat.wav',
          'mediaKind': 'music',
        };
        final imported = await fixture.apply('scene.dialogue.audioMedia.import',
            parameters, 'import-music-$repeat');
        final selected = await fixture.api.readWorkshopSnapshot(
            fixture.opened.projectHandle,
            actionId: 'scene.dialogue.audioMedia.import',
            parameters: parameters);
        expect(selected.maps, isEmpty);
        expect(
            selected.manifest.cinematicMediaAssets.single.id, 'music-$repeat');
        expect(selected.manifest.cinematicMediaAssets.single.loopByDefault,
            isTrue);
        expect(
            await File('${fixture.root.path}/assets/music/story-$repeat.wav')
                .readAsBytes(),
            bytes);
        expect(
            fixture.reader.paths.where((p) => p.startsWith('maps/')), isEmpty);
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains),
            isEmpty);
        expect(fixture.reader.paths.length, lessThan(160));
        counts.add(fixture.reader.paths.length);
        if (repeat == 1) {
          await fixture.api.undoMutation(fixture.opened.projectHandle,
              entryId: imported.receipt.receiptId,
              idempotencyKey: 'undo-second-music');
          expect(
              await File('${fixture.root.path}/assets/music/story-1.wav')
                  .exists(),
              isFalse);
          await fixture.apply('scene.dialogue.audioMedia.import', parameters,
              'reimport-second-music');
        }
      }
      expect(await File('${fixture.root.path}/project.json').readAsBytes(),
          fixture.descriptor);
      await fixture.reopen();
      for (var repeat = 0; repeat < 2; repeat++) {
        final selected = await fixture.api.readWorkshopSnapshot(
            fixture.opened.projectHandle,
            actionId: 'scene.dialogue.audioMedia.import',
            parameters: {'mediaId': 'music-$repeat'});
        expect(selected.manifest.cinematicMediaAssets.single.durationMs, 1000);
      }
      print(jsonEncode(
          {'audioUnrelated': unrelated, 'firstRepeatedReads': counts}));
    });
  }

  test(
      'audio import rejects concurrent asset catalog changes without writing media',
      () async {
    final fixture = await _Fixture.open(0);
    addTearDown(fixture.close);
    final artifact = await fixture.api.artifacts
        .put(_storyWav(), declaredMediaType: 'audio/wav');
    final parameters = <String, Object?>{
      'artifactHandle': artifact.reference.handle,
      'assetId': 'music',
      'mediaId': 'music',
      'label': 'Music',
      'logicalPath': 'assets/music/story.wav',
      'mediaKind': 'music',
    };
    final snapshot = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'scene.dialogue.audioMedia.import',
        parameters: parameters);
    final plan = await fixture.api.planMutation(
        fixture.opened.projectHandle,
        AuthoringRequest(
            requestId: 'audio-concurrent',
            actionId: 'scene.dialogue.audioMedia.import',
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'audio-concurrent',
            parameters: parameters));
    final external = File('${fixture.root.path}/assets/.pokemap-assets.json');
    await external.parent.create(recursive: true);
    await external.writeAsString('concurrent catalog bytes');
    await expectLater(
        fixture.api.applyMutation(fixture.opened.projectHandle,
            planId: plan.planId, operationId: 'audio-concurrent'),
        throwsA(isA<Exception>()));
    expect(await external.readAsString(), 'concurrent catalog bytes');
    expect(await File('${fixture.root.path}/assets/music/story.wav').exists(),
        isFalse);
    expect(await File('${fixture.root.path}/project.json').readAsBytes(),
        fixture.descriptor);
  });

  test(
      'entity upsert resolves new and replacement healing variant element closures',
      () async {
    final base = spatialEnvironmentFixture();
    final healing = healingProject();
    final fixture = await _Fixture.open(80, content: (
      project: healing.copyWith(
          maps: base.project.maps,
          models3d: base.project.models3d,
          elements: [
            ...healing.elements,
            for (final element in healing.elements)
              element.copyWith(id: 'alternate-${element.id}')
          ]),
      map: const MapData(
          id: 'map',
          name: 'Map',
          version: ProjectVersion.v8,
          size: GridSize(width: 6, height: 4)),
    ));
    addTearDown(fixture.close);
    var entity = MapEntity(
        id: 'balls',
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 2, y: 1),
        blocksMovement: false,
        healingDisplay: healingPayload());
    for (var repeat = 0; repeat < 2; repeat++) {
      if (repeat == 1) {
        entity = entity.copyWith(
            healingDisplay: MapEntityHealingDisplayData(variantElementIds: [
          for (final id in healingPayload().variantElementIds) 'alternate-$id'
        ]));
      }
      fixture.reader.paths.clear();
      await fixture.apply('entity.upsert',
          {'mapId': 'map', 'entity': entity.toJson()}, 'healing-$repeat');
      final saved = MapData.fromJson(
          jsonDecode(await fixture.mapFile.readAsString())
              as Map<String, dynamic>);
      expect(saved.entities.single.healingDisplay, entity.healingDisplay);
      expect(
          fixture.reader.paths.where(
              (path) => path.startsWith('maps/') && path != 'maps/map.json'),
          isEmpty);
      expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains),
          isEmpty);
    }
    final before = await fixture.mapFile.readAsBytes();
    await expectLater(
        fixture.apply(
            'entity.upsert',
            {
              'mapId': 'map',
              'entity': entity
                  .copyWith(
                      healingDisplay: MapEntityHealingDisplayData(
                          variantElementIds: [
                        'missing',
                        ...entity.healingDisplay!.variantElementIds.skip(1)
                      ]))
                  .toJson()
            },
            'healing-missing'),
        throwsA(isA<Exception>()));
    expect(await fixture.mapFile.readAsBytes(), before);
  });

  for (final existing in [false, true]) {
    test(
        'event condition closure resolves selected records for existing=$existing presentation',
        () async {
      final base = spatialEnvironmentFixture();
      const selectedId = 'evt_018f0f8c-7b8a-7def-8000-000000000001';
      MapEntity presented(String eventId) => MapEntity(
          id: 'presented',
          kind: MapEntityKind.custom,
          pos: const GridPos(x: 1, y: 1),
          presentation: MapEntityPresentation(variants: [
            MapEntityPresentationVariant(
                id: 'visible',
                condition: NarrativeEventConditionExpression.leaf(
                    NarrativeEventCondition.narrativeEventConsumed(
                        eventId, true)),
                blocksMovement: false),
          ]));
      final fixture = await _Fixture.open(80, content: (
        project: base.project.copyWith(
            eventRegistry: NarrativeEventRegistry(
                schemaVersion: 1,
                mode: EventSystemMode.v2Only,
                legacyClaims: const [],
                records: [
              for (var i = 1; i <= 81; i++)
                NarrativeEventRecord.draft(NarrativeEventDraft(
                    id: 'evt_018f0f8c-7b8a-7def-8000-${i.toString().padLeft(12, '0')}',
                    name: 'Event $i',
                    conditions: const [],
                    priority: 0,
                    order: i)),
            ])),
        map: base.map
            .copyWith(entities: existing ? [presented(selectedId)] : const []),
      ));
      addTearDown(fixture.close);
      fixture.reader.paths.clear();
      final action = existing ? 'trigger.create' : 'entity.upsert';
      final parameters = <String, Object?>{
        'mapId': 'map',
        if (existing)
          'trigger': {
            'id': 'new-event',
            'name': 'Event',
            'type': 'event',
            'area': {
              'pos': {'x': 2, 'y': 2},
              'size': {'width': 1, 'height': 1}
            },
          }
        else
          'entity': presented(selectedId).toJson()
      };
      final selected = await fixture.api.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: action,
          parameters: parameters);
      expect(selected.manifest.eventRegistry, isNotNull);
      expect(
          selected.manifest.eventRegistry!.records.map((record) => record.id),
          [selectedId]);
      await fixture.apply(action, parameters, 'event-condition-$existing',
          revision: selected.revision);
      expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains),
          isEmpty);
      final before = await fixture.mapFile.readAsBytes();
      await expectLater(
          fixture.apply(
              'entity.upsert',
              {
                'mapId': 'map',
                'entity': presented('evt_018f0f8c-7b8a-7def-8000-999999999999')
                    .copyWith(id: 'unknown')
                    .toJson()
              },
              'event-missing'),
          throwsA(isA<Exception>()));
      expect(await fixture.mapFile.readAsBytes(), before);
    });
  }

  test('guided narrative publication retains native Border dependencies and map CAS', () async {
    final source = spatialBorderAuthoringFixture(published: true);
    final fixture = await _Fixture.open(80, content: source);
    addTearDown(fixture.close);
    final before = await fixture.mapFile.readAsBytes();
    final map = MapData.fromJson(jsonDecode(utf8.decode(before)) as Map<String, dynamic>);
    final parameters = <String, Object?>{
      'map': map.copyWith(properties: {'narrative': 'updated'}).toJson(),
      'mapRevision': narrativeEventBytesFingerprint(before),
      'dialogues': [], 'facts': [], 'scenes': [], 'cinematics': [], 'storylines': [], 'events': [],
    };
    fixture.reader.paths.clear();
    final selected = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle,
      actionId: 'narrative.publish_document', parameters: parameters);
    expect(selected.manifest.borderCatalog.records.map((record) => record.id), ['fence']);
    await fixture.apply('narrative.publish_document', parameters, 'guided-border', revision: selected.revision);
    expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
    expect(fixture.reader.paths.where((path) => path.startsWith('maps/') && path != 'maps/map.json'), isEmpty);
    final saved = MapData.fromJson(jsonDecode(await fixture.mapFile.readAsString()) as Map<String, dynamic>);
    expect(saved.layers, map.layers);
    expect(saved.spatialScene, map.spatialScene);
    final next = <String, Object?>{...parameters, 'map': saved.copyWith(properties: {'narrative': 'second'}).toJson(),
      'mapRevision': narrativeEventBytesFingerprint(await fixture.mapFile.readAsBytes())};
    final read = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle,
      actionId: 'narrative.publish_document', parameters: next);
    final plan = await fixture.api.planMutation(fixture.opened.projectHandle, AuthoringRequest(
      requestId: 'guided-stale', actionId: 'narrative.publish_document', actionVersion: 1,
      workspaceHandle: fixture.opened.workspaceHandle.value, expectedRevision: read.revision,
      idempotencyKey: 'guided-stale', parameters: next));
    final external = utf8.encode(jsonEncode(saved.copyWith(properties: {'external': 'preserve'}).toJson()));
    await fixture.mapFile.writeAsBytes(external);
    await expectLater(fixture.api.applyMutation(fixture.opened.projectHandle,
      planId: plan.planId, operationId: 'guided-stale'), throwsA(isA<Exception>()));
    expect(await fixture.mapFile.readAsBytes(), external);
  });

  final navigationReadCounts = <int, List<int>>{};
  for (final unrelated in [0, 80]) {
    test(
        'navigation spawn stays local with $unrelated unrelated maps and preserves CAS',
        () async {
      final fixture = await _Fixture.open(unrelated);
      addTearDown(fixture.close);
      final beforeBytes = await fixture.mapFile.readAsBytes();
      final before = MapData.fromJson(
          jsonDecode(utf8.decode(beforeBytes)) as Map<String, dynamic>);
      final counts = <int>[];
      final totalCounts = <int>[];
      Map<String, Object?> parameters(double x) => {
            'mapId': 'map',
            'navigation': {
              ...before.spatialScene!.navigation.toJson(),
              'spawn': {'x': x, 'z': 1.5}
            }
          };
      for (var repeat = 0; repeat < 2; repeat++) {
        fixture.reader.paths.clear();
        final value = parameters(2.5 + repeat);
        final selected = await fixture.api.readWorkshopSnapshot(
            fixture.opened.projectHandle,
            actionId: 'map3d.navigation.configure',
            parameters: value);
        expect(selected.maps.map((map) => map.id), ['map']);
        expect(selected.manifest.maps.map((map) => map.id), ['map']);
        expect(selected.manifest.models3d.map((model) => model.id), ['tree']);
        await fixture.apply('map3d.navigation.configure', value,
            'navigation-$repeat', revision: selected.revision);
        expect(
            fixture.reader.paths.where(
                (path) => path.startsWith('maps/') && path != 'maps/map.json'),
            isEmpty);
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains),
            isEmpty);
        counts.add(selected.maps.length);
        totalCounts.add(fixture.reader.paths.length);
        expect(totalCounts.last, lessThan(240));
      }
      print(jsonEncode({
        'navigationUnrelatedMaps': unrelated,
        'selectedMapCount': counts,
        'totalScopedReads': totalCounts
      }));
      navigationReadCounts[unrelated] = counts;
      if (unrelated == 80) {
        expect(counts, navigationReadCounts[0]);
      }
      final afterBytes = await fixture.mapFile.readAsBytes();
      final after = MapData.fromJson(
          jsonDecode(utf8.decode(afterBytes)) as Map<String, dynamic>);
      final expected = before.copyWith(
          spatialScene: before.spatialScene!.copyWith(
              navigation: before.spatialScene!.navigation
                  .copyWith(spawn: SpatialSpawn(x: 3.5, z: 1.5))));
      expect(after.toJson(), expected.toJson());
      await expectLater(
          fixture.apply('map3d.navigation.configure', parameters(6.5),
              'invalid-spawn'),
          throwsA(isA<MapAuthoringException>().having(
              (error) => error.code, 'code', 'map3d.parameters_invalid')));
      expect(await fixture.mapFile.readAsBytes(), afterBytes);
      expect(await File('${fixture.root.path}/project.json').readAsBytes(),
          fixture.descriptor);
      await fixture.reopen();
      final reopened = await fixture.api.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: 'map3d.navigation.configure',
          parameters: parameters(4.5));
      expect(reopened.maps.single, after);
      final plan = await fixture.api.planMutation(
          fixture.opened.projectHandle,
          AuthoringRequest(
              requestId: 'stale-navigation',
              actionId: 'map3d.navigation.configure',
              actionVersion: 1,
              workspaceHandle: fixture.opened.workspaceHandle.value,
              expectedRevision: reopened.revision,
              idempotencyKey: 'stale-navigation',
              parameters: parameters(4.5)));
      final externalBytes = utf8.encode(jsonEncode(
          after.copyWith(properties: {'external': 'preserved'}).toJson()));
      await fixture.mapFile.writeAsBytes(externalBytes);
      await expectLater(
          fixture.api.applyMutation(fixture.opened.projectHandle,
              planId: plan.planId, operationId: 'stale-navigation'),
          throwsA(isA<Exception>()));
      expect(await fixture.mapFile.readAsBytes(), externalBytes);
    });
  }

  for (final unrelated in [0, 90]) {
    test(
        'native spatial map actions stay local with $unrelated unrelated maps and models',
        () async {
      final fixture = await _Fixture.open(unrelated);
      addTearDown(fixture.close);
      final operations = <(String, Map<String, Object?>)>[
        ('environment.attach_to_spatial_terrain', {'layerId': 'env'}),
        (
          'environment.area_create',
          {
            'layerId': 'env',
            'areaId': 'forest',
            'name': 'Forest',
            'presetId': 'forest',
            'seed': 1
          }
        ),
        (
          'environment.generated_placement_adopt_batch',
          {
            'layerId': 'env',
            'areaId': 'forest',
            'placementIds': ['old-tree']
          }
        ),
      ];
      for (var i = 0; i < operations.length; i++) {
        final (action, parameters) = operations[i];
        fixture.reader.paths.clear();
        final snapshot = await fixture.api.readWorkshopSnapshot(
            fixture.opened.projectHandle,
            actionId: action,
            parameters: {'mapId': 'map', ...parameters});
        expect(snapshot.maps.map((m) => m.id), ['map']);
        expect(snapshot.manifest.models3d.map((m) => m.id), ['tree']);
        expect(snapshot.manifest.maps.map((m) => m.id), ['map']);
        await fixture.apply(action, {'mapId': 'map', ...parameters}, 'step-$i',
            revision: snapshot.revision);
        expect(
            fixture.reader.paths
                .where((p) => p.startsWith('maps/') && p != 'maps/map.json'),
            isEmpty);
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains),
            isEmpty);
        expect(fixture.reader.paths.length, lessThan(240));
      }
      for (var repeat = 0; repeat < 2; repeat++) {
        final moved = fixture.instance.copyWith(
            position: Model3dVector3(x: 2.25 + repeat, y: 3, z: 2.125));
        await fixture.apply(
            'map3d.instance.upsert_batch',
            {
              'mapId': 'map',
              'instances': [moved.toJson()]
            },
            'move-$repeat');
      }
      final result = MapData.fromJson(
          jsonDecode(await fixture.mapFile.readAsString())
              as Map<String, dynamic>);
      final area =
          (result.layers.single as EnvironmentLayer).content.areas.single;
      expect(area.manualPlacementIds, ['old-tree']);
      expect(result.spatialScene!.instances.single.position.x, 3.25);
      expect(result.properties, {'keep': 'preserved'});
      expect(
          await File('${fixture.root.path}/.pokemap/authoring/history.jsonl')
              .readAsString(),
          'unrelated legacy history\n');
      expect(await File('${fixture.root.path}/project.json').readAsBytes(),
          fixture.descriptor);
      await fixture.reopen();
      final reopened = await fixture.api.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: 'map3d.instance.upsert_batch',
          parameters: {
            'mapId': 'map',
            'instances': [result.spatialScene!.instances.single.toJson()]
          });
      expect(reopened.maps.single, result);
    });
  }

  for (final unrelated in [0, 90]) {
    test('Environment preset changes and manual removals stay map-local with $unrelated foreign maps', () async {
      final base = spatialEnvironmentFixture();
      final originalPreset = base.project.environmentPresets.single;
      final alternative = EnvironmentPreset(id: 'alternative', name: 'Alternative forest', templateId: originalPreset.templateId, palette: originalPreset.palette, defaultParams: originalPreset.defaultParams, sortOrder: 0);
      final first = SpatialModelInstance(id: 'tree-a', modelId: 'tree', position: Model3dVector3(x: 1, y: 1, z: 1));
      final second = SpatialModelInstance(id: 'tree-b', modelId: 'tree', position: Model3dVector3(x: 2, y: 1, z: 1));
      final fixture = await _Fixture.open(unrelated, content: (
        project: base.project.copyWith(environmentPresets: [...base.project.environmentPresets, alternative]),
        map: base.map.copyWith(spatialScene: base.map.spatialScene!.copyWith(instances: [first, second])),
      ));
      addTearDown(fixture.close);
      await fixture.apply('environment.generated_placement_adopt_batch', {'mapId': 'map', 'layerId': 'env', 'areaId': 'forest', 'placementIds': ['tree-a', 'tree-b']}, 'adopt-local-trees');
      for (var repeat = 0; repeat < 2; repeat++) {
        fixture.reader.paths.clear();
        final presetId = repeat == 0 ? 'alternative' : 'forest';
        await fixture.apply('environment.area_set_preset', {'mapId': 'map', 'layerId': 'env', 'areaId': 'forest', 'presetId': presetId}, 'preset-$repeat');
        final changed = MapData.fromJson(jsonDecode(await fixture.mapFile.readAsString()));
        final area = (changed.layers.single as EnvironmentLayer).content.areas.single;
        expect(area.presetId, presetId);
        expect(area.manualPlacementIds, ['tree-a', 'tree-b']);
        expect(changed.spatialScene!.instances, [first, second]);
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
        expect(fixture.reader.paths.where((p) => p.startsWith('maps/') && p != 'maps/map.json'), isEmpty);
        expect(fixture.reader.paths.where((p) => p.endsWith('.glb') || p.endsWith('history.jsonl')), isEmpty);
        expect(fixture.reader.paths.length, lessThan(240));
      }
      final beforeRemoval = await fixture.mapFile.readAsBytes();
      fixture.reader.paths.clear();
      final removed = await fixture.apply('environment.generated_placement_delete', {'mapId': 'map', 'layerId': 'env', 'areaId': 'forest', 'placementId': 'tree-b'}, 'remove-duplicate-tree');
      final changed = MapData.fromJson(jsonDecode(await fixture.mapFile.readAsString()));
      final area = (changed.layers.single as EnvironmentLayer).content.areas.single;
      expect(changed.spatialScene!.instances, [first]);
      expect(area.manualPlacementIds, ['tree-a']);
      expect(area.generatedPlacementIds, ['tree-a']);
      expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
      expect(fixture.reader.paths.where((p) => p.startsWith('maps/') && p != 'maps/map.json'), isEmpty);
      expect(fixture.reader.paths.where((p) => p.endsWith('.glb') || p.endsWith('history.jsonl')), isEmpty);
      expect(fixture.reader.paths.length, lessThan(240));
      await fixture.reopen();
      final selected = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle, actionId: 'environment.generated_placement_delete', parameters: {'mapId': 'map', 'layerId': 'env', 'areaId': 'forest', 'placementId': 'tree-a'});
      expect(selected.maps.single.toJson(), changed.toJson());
      await fixture.api.undoMutation(fixture.opened.projectHandle, entryId: removed.receipt.receiptId, idempotencyKey: 'undo-duplicate-removal');
      expect(await fixture.mapFile.readAsBytes(), beforeRemoval);
      expect(await File('${fixture.root.path}/project.json').readAsBytes(), fixture.descriptor);
    });
  }

  test('targeted spatial publication rejects a concurrent map write', () async {
    final fixture = await _Fixture.open(90);
    addTearDown(fixture.close);
    final parameters = <String, Object?>{'mapId': 'map', 'layerId': 'env'};
    final before = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'environment.attach_to_spatial_terrain',
        parameters: parameters);
    final plan = await fixture.api.planMutation(
        fixture.opened.projectHandle,
        AuthoringRequest(
            requestId: 'stale',
            actionId: 'environment.attach_to_spatial_terrain',
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            expectedRevision: before.revision,
            idempotencyKey: 'stale',
            parameters: parameters));
    final external =
        before.maps.single.copyWith(properties: {'external': 'preserve'});
    final bytes = utf8.encode(jsonEncode(external.toJson()));
    await fixture.mapFile.writeAsBytes(bytes);
    await expectLater(
        fixture.api.applyMutation(fixture.opened.projectHandle,
            planId: plan.planId, operationId: 'stale'),
        throwsA(isA<Exception>()));
    expect(await fixture.mapFile.readAsBytes(), bytes);
  });

  test('JSONL adoption undo and reopen preserve exact existing instances',
      () async {
    final fixture = await _Fixture.open(90);
    addTearDown(fixture.close);
    await fixture.apply('environment.attach_to_spatial_terrain',
        {'mapId': 'map', 'layerId': 'env'}, 'attach');
    await fixture.apply(
        'environment.area_create',
        {
          'mapId': 'map',
          'layerId': 'env',
          'areaId': 'forest',
          'name': 'Forest',
          'presetId': 'forest',
          'seed': 1
        },
        'area');
    final before = await fixture.mapFile.readAsBytes();
    final parameters = <String, Object?>{
      'mapId': 'map',
      'layerId': 'env',
      'areaId': 'forest',
      'placementIds': ['old-tree']
    };
    final snapshot = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'environment.generated_placement_adopt_batch',
        parameters: parameters);
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [fixture.root.path], fileReader: fixture.reader);
    final worker = JsonlWorker(
        api: AuthoringReadApi(
            openService: ProjectOpenService(
                policy: policy,
                fileReader: fixture.reader,
                handles: fixture.handles,
                catalogMetadataFields: {}),
            snapshotLoader: ProjectSnapshotLoader(handles: fixture.handles)),
        mutations: fixture.api);
    Future<AuthoringResult> command(
            String command, Map<String, Object?> args) async =>
        AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode(
            {'id': 'jsonl-$command', 'command': command, 'args': args}))));
    final planned = await command('plan', {
      'projectHandle': fixture.opened.projectHandle.value,
      'request': AuthoringRequest(
              requestId: 'jsonl-adopt',
              actionId: 'environment.generated_placement_adopt_batch',
              actionVersion: 1,
              workspaceHandle: fixture.opened.workspaceHandle.value,
              expectedRevision: snapshot.revision,
              idempotencyKey: 'jsonl-adopt',
              parameters: parameters)
          .toJson()
    });
    expect(planned.status, AuthoringResultStatus.success,
        reason: planned.toJson().toString());
    final applied = await command('apply', {
      'projectHandle': fixture.opened.projectHandle.value,
      'planId': planned.data['planId'],
      'operationId': 'jsonl-adopt'
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: applied.toJson().toString());
    final receipt = applied.data['receipt'] as Map;
    final after = MapData.fromJson(
        jsonDecode(await fixture.mapFile.readAsString())
            as Map<String, dynamic>);
    expect(after.spatialScene!.instances, [fixture.instance]);
    final undone = await command('undo', {
      'projectHandle': fixture.opened.projectHandle.value,
      'entryId': receipt['receiptId'],
      'idempotencyKey': 'jsonl-undo'
    });
    expect(undone.status, AuthoringResultStatus.success,
        reason: undone.toJson().toString());
    expect(await fixture.mapFile.readAsBytes(), before);
    await fixture.reopen();
    final reopened = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'environment.generated_placement_adopt_batch',
        parameters: parameters);
    expect(
        (reopened.maps.single.layers.single as EnvironmentLayer)
            .content
            .areas
            .single
            .manualPlacementIds,
        isEmpty);
    expect(reopened.maps.single.spatialScene!.instances, [fixture.instance]);
  });

  test(
      'terrain changes stay map-local and preserve explicit instance transforms',
      () async {
    final fixture = await _Fixture.open(90);
    addTearDown(fixture.close);
    await fixture.apply(
        'map3d.terrain.configure_appearance',
        {'mapId': 'map', 'cliffFrame': null, 'generateCliffs': false},
        'appearance');
    await fixture.apply(
        'map3d.terrain.surface.upsert_batch',
        {
          'mapId': 'map',
          'reanchorInstances': false,
          'surfaces': [
            {
              'id': 'raised',
              'x': 0,
              'z': 0,
              'height': 2,
              'footprints': [
                [
                  {'x': 0, 'z': 0},
                  {'x': 6, 'z': 0},
                  {'x': 6, 'z': 4},
                  {'x': 0, 'z': 4}
                ]
              ]
            }
          ]
        },
        'surface');
    final after = MapData.fromJson(
        jsonDecode(await fixture.mapFile.readAsString())
            as Map<String, dynamic>);
    expect(after.spatialScene!.generateCliffs, isFalse);
    expect(after.spatialScene!.terrainSurfaces.surfaces.single.height, 2);
    expect(after.spatialScene!.instances, [fixture.instance]);
    expect(
        fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
  });

  final layerOrderReadCounts = <int, List<int>>{};
  for (final unrelated in [0, 90]) {
    test('layer identity reorder stays local with $unrelated unrelated maps', () async {
      final source = spatialBorderAuthoringFixture(published: true);
      final extra = BorderLayer(id: 'rear', name: 'Rear');
      final fixture = await _Fixture.open(unrelated, content: (
        project: source.project,
        map: source.map.copyWith(layers: [...source.map.layers, extra]),
      ));
      addTearDown(fixture.close);
      final before = await fixture.mapFile.readAsBytes();
      final reads = <int>[];
      final receipts = <String>[];
      for (var repeat = 0; repeat < 2; repeat++) {
        fixture.reader.paths.clear();
        final applied = await fixture.apply('map.apply_operations', {
          'mapId': 'map',
          'operations': [{'kind': 'layer.reorder_by_id', 'layerId': 'rear', 'newIndex': repeat == 0 ? 0 : 2}],
        }, 'layer-order-$repeat');
        receipts.add(applied.receipt.receiptId);
        final after = MapData.fromJson(jsonDecode(await fixture.mapFile.readAsString()) as Map<String, dynamic>);
        expect(after.layers.map((layer) => layer.id), repeat == 0 ? ['rear', 'border'] : ['border', 'rear']);
        expect(after.spatialScene, source.map.spatialScene);
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
        expect(fixture.reader.paths.where((path) => path.startsWith('maps/') && path != 'maps/map.json'), isEmpty);
        expect(fixture.reader.paths.length, lessThan(100));
        reads.add(fixture.reader.paths.where((path) => path == 'maps/map.json').length);
      }
      layerOrderReadCounts[unrelated] = reads;
      if (unrelated == 90) expect(reads, layerOrderReadCounts[0]);
      final persisted = await fixture.mapFile.readAsBytes();
      await fixture.reopen();
      final reopened = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle,
        actionId: 'map.apply_operations', parameters: {'mapId': 'map', 'operations': [{'kind': 'layer.reorder_by_id', 'layerId': 'rear', 'newIndex': 0}]});
      expect(reopened.maps.single.toJson(), jsonDecode(utf8.decode(persisted)));
      for (final receipt in receipts.reversed) {
        await fixture.api.undoMutation(fixture.opened.projectHandle, entryId: receipt, idempotencyKey: 'undo-$receipt');
      }
      expect(await fixture.mapFile.readAsBytes(), before);
      expect(await File('${fixture.root.path}/project.json').readAsBytes(), fixture.descriptor);
    });
  }

  final borderDeleteReadCounts = <int, List<int>>{};
  for (final unrelated in [0, 90]) {
    test('materialized Border deletion stays local with $unrelated unrelated maps', () async {
      final source = spatialBorderAuthoringFixture(published: true);
      final fixture = await _Fixture.open(unrelated, content: source);
      addTearDown(fixture.close);
      await fixture.apply('border_layer.materialize_apply',
        {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'}, 'prepare-delete');
      final before = await fixture.mapFile.readAsBytes();
      final original = MapData.fromJson(jsonDecode(utf8.decode(before)) as Map<String, dynamic>);
      expect(original.spatialScene!.instances, isNotEmpty);
      final reads = <int>[];
      for (var repeat = 0; repeat < 2; repeat++) {
        fixture.reader.paths.clear();
        final applied = await fixture.apply('border_layer.feature_delete',
          {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'}, 'delete-$repeat');
        final after = MapData.fromJson(jsonDecode(await fixture.mapFile.readAsString()) as Map<String, dynamic>);
        expect(after.toJson(), removeBorderFeature(original, layerId: 'border', featureId: 'fence').toJson());
        expect(after.layers.whereType<BorderLayer>().single.content.features, isEmpty);
        expect(after.spatialScene!.instances, isEmpty);
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
        expect(fixture.reader.paths.where((path) => path.startsWith('maps/') && path != 'maps/map.json'), isEmpty);
        expect(fixture.reader.paths.length, lessThan(100));
        reads.add(fixture.reader.paths.where((path) => path == 'maps/map.json').length);
        await fixture.reopen();
        final reopened = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle,
          actionId: 'border_layer.feature_delete', parameters: {'mapId': 'map'});
        expect(reopened.maps.single.toJson(), after.toJson());
        await fixture.api.undoMutation(fixture.opened.projectHandle,
          entryId: applied.receipt.receiptId, idempotencyKey: 'undo-delete-$repeat');
        expect(await fixture.mapFile.readAsBytes(), before);
      }
      borderDeleteReadCounts[unrelated] = reads;
      if (unrelated == 90) expect(reads, borderDeleteReadCounts[0]);
      expect(await File('${fixture.root.path}/project.json').readAsBytes(), fixture.descriptor);
    });
  }

  final keepOutReadCounts = <int, List<int>>{};
  for (final unrelated in [0, 90]) {
    test('Border keep-out stays local with $unrelated unrelated maps', () async {
      final source = spatialBorderAuthoringFixture(published: true);
      final fixture = await _Fixture.open(unrelated, content: source);
      addTearDown(fixture.close);
      final before = await fixture.mapFile.readAsBytes();
      final reads = <int>[];
      final receipts = <String>[];
      for (var repeat = 0; repeat < 2; repeat++) {
        final cells = List.filled(source.map.size.width * source.map.size.height, false);
        cells[source.map.size.width + repeat + 1] = true;
        final regions = [BorderKeepOutRegion(id: 'opening', region: BorderRegionGeometry(
          width: source.map.size.width, height: source.map.size.height, cells: cells))];
        fixture.reader.paths.clear();
        final applied = await fixture.apply('border_layer.feature_set_keep_out', {
          'mapId': 'map', 'layerId': 'border', 'featureId': 'fence',
          'regions': [{'id': 'opening', 'region': {
            'width': source.map.size.width, 'height': source.map.size.height,
            'cells': cells,
          }}],
        }, 'keep-out-$repeat');
        receipts.add(applied.receipt.receiptId);
        final after = MapData.fromJson(jsonDecode(await fixture.mapFile.readAsString()) as Map<String, dynamic>);
        final expected = updateBorderFeatureKeepOutRegions(source.map,
          layerId: 'border', featureId: 'fence', keepOutRegions: regions);
        expect(after.toJson(), expected.toJson());
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
        expect(fixture.reader.paths.where((path) => path.startsWith('maps/') && path != 'maps/map.json'), isEmpty);
        expect(fixture.reader.paths.length, lessThan(100));
        reads.add(fixture.reader.paths.where((path) => path == 'maps/map.json').length);
      }
      keepOutReadCounts[unrelated] = reads;
      if (unrelated == 90) expect(reads, keepOutReadCounts[0]);
      final persisted = await fixture.mapFile.readAsBytes();
      await fixture.reopen();
      final reopened = await fixture.api.readWorkshopSnapshot(fixture.opened.projectHandle,
        actionId: 'border_layer.feature_set_keep_out', parameters: {'mapId': 'map'});
      expect(reopened.maps.single.toJson(), jsonDecode(utf8.decode(persisted)));
      for (final receipt in receipts.reversed) {
        await fixture.api.undoMutation(fixture.opened.projectHandle,
          entryId: receipt, idempotencyKey: 'undo-$receipt');
      }
      expect(await fixture.mapFile.readAsBytes(), before);
      expect(await File('${fixture.root.path}/project.json').readAsBytes(), fixture.descriptor);
    });
  }

  test('native Border create and materialization use only their model closure',
      () async {
    final source = spatialBorderAuthoringFixture(published: true);
    final fixture = await _Fixture.open(90, content: (
      project: source.project,
      map: source.map.copyWith(layers: const [])
    ));
    addTearDown(fixture.close);
    await fixture.apply(
        'map.apply_operations',
        {
          'mapId': 'map',
          'operations': [
            {
              'kind': 'layer.add',
              'layerKind': 'border',
              'layerId': 'border',
              'name': 'Native Border'
            }
          ]
        },
        'border-layer');
    await fixture.apply(
        'border_layer.feature_create',
        {
          'mapId': 'map',
          'layerId': 'border',
          'featureId': 'fence',
          'blueprintId': 'fence',
          'name': 'Fence',
          'seed': '17',
          'geometry': {
            'kind': 'stroke',
            'strokes': [
              {
                'id': 'line',
                'closed': false,
                'points': [
                  {'x': 1, 'y': 1},
                  {'x': 2, 'y': 1},
                  {'x': 3, 'y': 1}
                ]
              }
            ]
          }
        },
        'border-feature');
    await fixture.apply(
        'border_layer.materialize_batch_apply',
        {
          'mapId': 'map',
          'features': [
            {'layerId': 'border', 'featureId': 'fence'}
          ],
          'tileWidthPx': 32,
          'tileHeightPx': 32,
          'resolverVersion': borderResolverVersion
        },
        'border-materialize');
    final after = MapData.fromJson(
        jsonDecode(await fixture.mapFile.readAsString())
            as Map<String, dynamic>);
    expect(after.spatialScene!.instances, isNotEmpty);
    final ids = (after.layers.single as BorderLayer)
        .content
        .features
        .single
        .generatedPlacementIds;
    expect(ids.toSet(), after.spatialScene!.instances.map((i) => i.id).toSet());
    expect(
        fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
  });

  for (final unrelated in [0, 90]) {
    test(
        'materialized Border moves stay local and undo exactly with $unrelated unrelated maps',
        () async {
      final source = spatialBorderAuthoringFixture(published: true);
      final fixture = await _Fixture.open(unrelated, content: source);
      addTearDown(fixture.close);
      await fixture.apply(
          'border_layer.materialize_apply',
          {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'},
          'materialize-before-move');
      final beforeBytes = await fixture.mapFile.readAsBytes();
      final before = MapData.fromJson(
          jsonDecode(utf8.decode(beforeBytes)) as Map<String, dynamic>);
      final instances = {
        for (final instance in before.spatialScene!.instances)
          instance.id: instance
      };
      expect(instances, isNotEmpty);
      final parameters = <String, Object?>{
        'mapId': 'map',
        'layerId': 'border',
        'featureId': 'fence',
        'dx': 1,
        'dy': 0
      };
      fixture.reader.paths.clear();
      final selected = await fixture.api.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: 'border_layer.feature_move',
          parameters: parameters);
      expect(selected.maps.map((map) => map.id), ['map']);
      expect(selected.manifest.models3d.map((model) => model.id), ['tree']);
      expect(selected.manifest.borderCatalog.records.map((record) => record.id),
          ['fence']);
      final moved = await fixture.apply(
          'border_layer.feature_move', parameters, 'move-border',
          revision: selected.revision);
      final regenerated = await fixture.apply(
          'border_layer.materialize_apply',
          {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'},
          'regenerate-moved-border');
      final after = MapData.fromJson(
          jsonDecode(await fixture.mapFile.readAsString())
              as Map<String, dynamic>);
      expect(after.spatialScene!.instances.length, instances.length);
      final originalInstances = instances.values.toList()
        ..sort((a, b) => a.position.x.compareTo(b.position.x));
      final movedInstances = after.spatialScene!.instances.toList()
        ..sort((a, b) => a.position.x.compareTo(b.position.x));
      for (var index = 0; index < movedInstances.length; index++) {
        final instance = movedInstances[index];
        final original = originalInstances[index];
        expect(
            {...instance.toJson(), 'id': original.id},
            original
                .copyWith(
                    position: Model3dVector3(
                        x: original.position.x + 1,
                        y: original.position.y,
                        z: original.position.z))
                .toJson());
      }
      final oldFeature =
          (before.layers.single as BorderLayer).content.features.single;
      final feature =
          (after.layers.single as BorderLayer).content.features.single;
      expect(feature.generatedPlacementIds.length,
          oldFeature.generatedPlacementIds.length);
      expect(feature.materialization, isNotNull);
      final stroke = feature.geometry as BorderStrokeGeometry;
      expect(stroke.strokes.single.points, const [
        GridPos(x: 2, y: 1),
        GridPos(x: 3, y: 1),
        GridPos(x: 4, y: 1)
      ]);
      expect(
          fixture.reader.paths.where(
              (path) => path.startsWith('maps/') && path != 'maps/map.json'),
          isEmpty);
      expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains),
          isEmpty);
      expect(fixture.reader.paths.length, lessThan(240));
      expect(await File('${fixture.root.path}/project.json').readAsBytes(),
          fixture.descriptor);
      await fixture.api.undoMutation(fixture.opened.projectHandle,
          entryId: regenerated.receipt.receiptId,
          idempotencyKey: 'undo-regenerate');
      await fixture.api.undoMutation(fixture.opened.projectHandle,
          entryId: moved.receipt.receiptId, idempotencyKey: 'undo-border');
      expect(await fixture.mapFile.readAsBytes(), beforeBytes);
      await fixture.reopen();
      final reopened = await fixture.api.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: 'border_layer.feature_move',
          parameters: parameters);
      expect(reopened.maps.single.toJson(), before.toJson());
      final plan = await fixture.api.planMutation(
          fixture.opened.projectHandle,
          AuthoringRequest(
              requestId: 'stale-move',
              actionId: 'border_layer.feature_move',
              actionVersion: 1,
              workspaceHandle: fixture.opened.workspaceHandle.value,
              expectedRevision: reopened.revision,
              idempotencyKey: 'stale-move',
              parameters: parameters));
      final externalBytes = utf8.encode(jsonEncode(
          before.copyWith(properties: {'external': 'preserved'}).toJson()));
      await fixture.mapFile.writeAsBytes(externalBytes);
      await expectLater(
          fixture.api.applyMutation(fixture.opened.projectHandle,
              planId: plan.planId, operationId: 'stale-move'),
          throwsA(isA<Exception>()));
      expect(await fixture.mapFile.readAsBytes(), externalBytes);
    });
  }

  test('native local selection retains legacy new-game fact dictionary keys',
      () async {
    final base = spatialEnvironmentFixture();
    final fixture = await _Fixture.open(90, content: (
      project: base.project.copyWith(
          newGame: const ProjectNewGameConfig(
              enabled: true,
              startMapId: 'map',
              initialFacts: {'fact-ready': true}),
          facts: [NarrativeFactDefinition(id: 'fact-ready', label: 'Ready')]),
      map: base.map
    ));
    addTearDown(fixture.close);
    fixture.reader.paths.clear();
    final selected = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'map3d.instance.upsert',
        parameters: {'mapId': 'map', 'instance': fixture.instance.toJson()});
    expect(selected.manifest.facts.map((fact) => fact.id), ['fact-ready']);
    expect(selected.manifest.newGame.initialFacts, {'fact-ready': true});
    expect(() => ProjectValidator.validate(selected.manifest), returnsNormally);
    expect(
        fixture.reader.paths.where(
            (path) => path.startsWith('maps/') && path != 'maps/map.json'),
        isEmpty);
    expect(
        fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
  });

  test(
      'native 2D map edits retain targeted persistence and concurrent-write checks',
      () async {
    final base = spatialEnvironmentFixture();
    final fixture = await _Fixture.open(90, content: (
      project: base.project.copyWith(
          version: ProjectVersion.v8,
          settings: base.project.settings
              .copyWith(dimension: ProjectDimension.twoD, spatialCamera: null),
          smartTileCatalog: _groundCatalog(),
          tilesets: const [
            ProjectTilesetEntry(
                id: 'ground-image',
                name: 'Ground',
                relativePath: 'assets/ground.png')
          ]),
      map: const MapData(
          version: ProjectVersion.v8,
          id: 'map',
          name: 'Map',
          size: GridSize(width: 6, height: 4))
    ));
    addTearDown(fixture.close);
    fixture.reader.paths.clear();
    await fixture.apply(
        'map.apply_operations',
        {
          'mapId': 'map',
          'operations': [
            {
              'kind': 'layer.add',
              'layerKind': 'environment',
              'layerId': 'env-2d',
              'name': 'Forest'
            },
            {
              'kind': 'layer.add',
              'layerKind': 'border',
              'layerId': 'border-2d',
              'name': 'Walls'
            }
          ]
        },
        'create-2d-native-layers');
    await fixture.apply(
        'smart_tile.layer.create',
        {
          'mapId': 'map',
          'presetId': 'ground',
          'layerId': 'path',
          'name': 'Path'
        },
        'create-2d-path');
    await fixture.apply(
        'smart_tile.cell.paint',
        {
          'mapId': 'map',
          'layerId': 'path',
          'materialId': 'grass',
          'cells': [
            {'x': 1, 'y': 1}
          ]
        },
        'paint-2d-path');
    final painted = MapData.fromJson(
        jsonDecode(await fixture.mapFile.readAsString())
            as Map<String, dynamic>);
    expect(
        smartTileSemanticCells(
                painted.layers.whereType<SmartTileLayer>().single)
            .where((cell) => cell > 0),
        hasLength(1));
    final parameters = <String, Object?>{'mapId': 'map', 'layerId': 'path'};
    final snapshot = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'smart_tile.layer.delete',
        parameters: parameters);
    final plan = await fixture.api.planMutation(
        fixture.opened.projectHandle,
        AuthoringRequest(
            requestId: 'stale-2d',
            actionId: 'smart_tile.layer.delete',
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'stale-2d',
            parameters: parameters));
    final confirmation = await fixture.api
        .confirmMutation(fixture.opened.projectHandle, planId: plan.planId);
    final external = utf8.encode(jsonEncode(
        painted.copyWith(properties: {'external': 'preserve'}).toJson()));
    await fixture.mapFile.writeAsBytes(external);
    await expectLater(
        fixture.api.applyMutation(fixture.opened.projectHandle,
            planId: plan.planId,
            operationId: 'stale-2d',
            confirmationToken: confirmation.confirmationToken),
        throwsA(isA<Exception>()));
    expect(await fixture.mapFile.readAsBytes(), external);
    await fixture.apply('smart_tile.layer.delete', parameters, 'delete-2d-path',
        confirm: true);
    final deleted = MapData.fromJson(
        jsonDecode(await fixture.mapFile.readAsString())
            as Map<String, dynamic>);
    expect(deleted.layers.whereType<SmartTileLayer>(), isEmpty);
    expect(deleted.layers.whereType<EnvironmentLayer>(), hasLength(1));
    expect(deleted.layers.whereType<BorderLayer>(), hasLength(1));
    expect(deleted.properties, {'external': 'preserve'});
    expect(await File('${fixture.root.path}/project.json').readAsBytes(),
        fixture.descriptor);
    expect(
        fixture.reader.paths.where(
            (path) => path.startsWith('maps/') && path != 'maps/map.json'),
        isEmpty);
    expect(
        fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
    await fixture.reopen();
    final reopened = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'smart_tile.layer.create',
        parameters: {
          'mapId': 'map',
          'presetId': 'ground',
          'layerId': 'next',
          'name': 'Next'
        });
    expect(reopened.maps.single, deleted);
  });

  for (final unrelated in [0, 90]) {
    test('grass encounter configuration stays scoped with $unrelated foreign maps', () async {
      final base = spatialEnvironmentFixture();
      final fixture = await _Fixture.open(unrelated, content: (
        project: base.project.copyWith(smartTileCatalog: _groundCatalog(), tilesets: const [ProjectTilesetEntry(id: 'ground-image', name: 'Ground', relativePath: 'assets/ground.png')], encounterTables: [
          ProjectEncounterTable(id: 'route', name: 'Route', encounterKind: EncounterKind.walk, entries: [
            ProjectEncounterEntry(speciesId: 'pidgey', minLevel: 3, maxLevel: 3)
          ])
        ]), map: base.map
      ));
      addTearDown(fixture.close);
      await fixture.apply('smart_tile.layer.create', {
        'mapId': 'map', 'layerId': 'grass', 'name': 'Grass', 'presetId': 'ground'
      }, 'create-grass');
      await fixture.apply('smart_tile.cell.paint', {
        'mapId': 'map', 'layerId': 'grass', 'materialId': 'grass', 'cells': [{'x': 1, 'y': 1}]
      }, 'paint-grass');
      final before = MapData.fromJson(jsonDecode(await fixture.mapFile.readAsString()));
      final counts = <int>[];
      for (var repeat = 0; repeat < 2; repeat++) {
        fixture.reader.paths.clear();
        await fixture.apply('smart_tile.layer.set_encounter_behavior', {
          'mapId': 'map', 'layerId': 'grass', 'materialId': 'grass',
          'priority': 20 + repeat, 'encounterTableId': 'route', 'encounterKind': 'walk'
        }, 'set-grass-$repeat');
        expect(fixture.reader.paths.where((p) => p.startsWith('maps/') && p != 'maps/map.json'), isEmpty);
        expect(fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
        counts.add(fixture.reader.paths.length);
        final after = MapData.fromJson(jsonDecode(await fixture.mapFile.readAsString()));
        final layer = after.layers.whereType<SmartTileLayer>().single;
        expect(layer.encounterBehavior!.priority, 20 + repeat);
        expect(layer.encounterBehavior!.encounter.encounterTableId, 'route');
        expect(after.copyWith(layers: [for (final value in after.layers) value is SmartTileLayer ? value.copyWith(encounterBehavior: null) : value]), before);
      }
      expect(counts.last, lessThanOrEqualTo(counts.first + 2));
      await fixture.reopen();
      await fixture.apply('smart_tile.layer.clear_encounter_behavior', {'mapId': 'map', 'layerId': 'grass'}, 'clear-grass');
      expect(MapData.fromJson(jsonDecode(await fixture.mapFile.readAsString())), before);
      expect(await File('${fixture.root.path}/project.json').readAsBytes(), fixture.descriptor);
      print(jsonEncode({'grassEncounterForeignMaps': unrelated, 'firstRepeatedReads': counts}));
    });
  }

  test('native Smart Tile map edits do not load unrelated maps or resources',
      () async {
    final base = spatialEnvironmentFixture();
    final catalog = _groundCatalog();
    final fixture = await _Fixture.open(90, content: (
      project: base.project.copyWith(
          smartTileCatalog: catalog,
          maps: [base.project.maps.single.copyWith(groupId: 'child')],
          groups: const [
            ProjectMapGroup(
                id: 'root-group', name: 'Region', type: MapGroupType.route),
            ProjectMapGroup(
                id: 'parent',
                name: 'Routes',
                type: MapGroupType.route,
                parentGroupId: 'root-group'),
            ProjectMapGroup(
                id: 'child',
                name: 'Route',
                type: MapGroupType.route,
                parentGroupId: 'parent'),
          ],
          dialogueFolders: const [
            ProjectDialogueFolder(id: 'root-folder', name: 'Root'),
            ProjectDialogueFolder(
                id: 'parent-folder',
                name: 'Parent',
                parentFolderId: 'root-folder'),
            ProjectDialogueFolder(
                id: 'child-folder',
                name: 'Child',
                parentFolderId: 'parent-folder'),
          ],
          dialogues: const [
            ProjectDialogueEntry(
                id: 'intro',
                name: 'Intro',
                relativePath: 'dialogues/intro.yarn',
                folderId: 'child-folder')
          ],
          characters: const [
            ProjectCharacterEntry(
                id: 'avatar', name: 'Avatar', tilesetId: 'ground-image')
          ],
          facts: [
            NarrativeFactDefinition(id: 'fact-legacy', label: 'Legacy'),
            NarrativeFactDefinition(
                id: 'fact-count',
                label: 'Count',
                initialValue: NarrativeValue.integer(0)),
            NarrativeFactDefinition(id: 'fact-avatar', label: 'Avatar'),
            NarrativeFactDefinition(id: 'fact-party', label: 'Party'),
          ],
          newGame: ProjectNewGameConfig(
              enabled: true,
              startMapId: 'other-0',
              playerAvatarCharacterIds: ['avatar'],
              initialFacts: {'fact-legacy': true},
              initialFactValues: {'fact-count': NarrativeValue.integer(3)},
              initialFactValuesByAvatarCharacterId: {
                'avatar': {'fact-avatar': NarrativeValue.boolean(true)}
              },
              existingPartyFactId: 'fact-party'),
          tilesets: const [
            ProjectTilesetEntry(
                id: 'ground-image',
                name: 'Ground',
                relativePath: 'assets/ground.png')
          ]),
      map: base.map.copyWith(entities: const [
        MapEntity(
            id: 'guide',
            kind: MapEntityKind.sign,
            pos: GridPos(x: 3, y: 2),
            sign: MapEntitySignData(dialogue: DialogueRef(dialogueId: 'intro')))
      ])
    ));
    addTearDown(fixture.close);
    fixture.reader.paths.clear();
    final selected = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'smart_tile.layer.create',
        parameters: {
          'mapId': 'map',
          'presetId': 'ground',
          'layerId': 'path',
          'name': 'Path'
        });
    expect(selected.manifest.groups.map((value) => value.id),
        ['root-group', 'parent', 'child']);
    expect(selected.manifest.dialogueFolders.map((value) => value.id),
        ['root-folder', 'parent-folder', 'child-folder']);
    expect(selected.manifest.dialogues.map((value) => value.id), ['intro']);
    expect(selected.manifest.facts.map((value) => value.id).toSet(),
        {'fact-legacy', 'fact-count', 'fact-avatar', 'fact-party'});
    expect(selected.manifest.maps.map((value) => value.id), ['map', 'other-0']);
    expect(selected.manifest.characters.map((value) => value.id), ['avatar']);
    await fixture.apply(
        'smart_tile.layer.create',
        {
          'mapId': 'map',
          'presetId': 'ground',
          'layerId': 'path',
          'name': 'Path'
        },
        'create-native-path');
    await fixture.apply(
        'smart_tile.cell.paint',
        {
          'mapId': 'map',
          'layerId': 'path',
          'materialId': 'grass',
          'cells': [
            {'x': 1, 'y': 1}
          ]
        },
        'paint-native-path');
    final painted = MapData.fromJson(
        jsonDecode(await fixture.mapFile.readAsString())
            as Map<String, dynamic>);
    expect(
        smartTileSemanticCells(
                painted.layers.whereType<SmartTileLayer>().single)
            .where((v) => v > 0),
        hasLength(1));
    await fixture.apply(
        'smart_tile.cell.erase',
        {
          'mapId': 'map',
          'layerId': 'path',
          'cells': [
            {'x': 1, 'y': 1}
          ]
        },
        'erase-native-path');
    final erased = MapData.fromJson(
        jsonDecode(await fixture.mapFile.readAsString())
            as Map<String, dynamic>);
    expect(
        smartTileSemanticCells(erased.layers.whereType<SmartTileLayer>().single)
            .where((v) => v > 0),
        isEmpty);
    expect(
        fixture.reader.paths.where(
            (path) => path.startsWith('maps/') && path != 'maps/map.json'),
        isEmpty);
    expect(
        fixture.reader.paths.where(fixture.unrelatedObjects.contains), isEmpty);
    expect(await File('${fixture.root.path}/project.json').readAsBytes(),
        fixture.descriptor);
    await fixture.reopen();
    final reopened = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'smart_tile.cell.paint',
        parameters: {
          'mapId': 'map',
          'layerId': 'path',
          'materialId': 'grass',
          'cells': [
            {'x': 1, 'y': 1}
          ]
        });
    expect(reopened.maps.single, erased);
  });
}


Map<String, Object?> _patternParameters(String action, String pattern, String strokeId, int x) {
  final stroke = <String, Object?>{'patternId': pattern, 'strokeId': strokeId, 'selection': {'kind': 'stamp', 'anchor': {'x': x, 'y': 1}}};
  return {'mapId': 'map', 'layerId': 'ground-layer', if (action.endsWith('_batch')) 'strokes': [stroke] else ...stroke};
}

({ProjectManifest project, MapData map}) _patternContent(SmartTileUsage usage) {
  final base = spatialEnvironmentFixture();
  final raw = _groundCatalog().toJson();
  (raw['presets'] as List).single['usage'] = usage.name;
  raw['patterns'] = [
    for (final id in ['patch', 'foreign-pattern', 'wrong-usage']) {
      'id': id, 'name': id, 'usage': id == 'wrong-usage' ? (usage == SmartTileUsage.terrain ? 'path' : 'terrain') : usage.name,
      'width': 1, 'height': 1, 'repeatMode': 'stamp', 'clippingPolicy': 'reject',
      'cells': [{'x': 0, 'y': 0, 'parts': [{'source': {'kind': 'frame', 'frame': {'atlasId': 'ground-atlas', 'column': 0, 'row': 0}}}]}],
    },
  ];
  return (
    project: base.project.copyWith(smartTileCatalog: ProjectSmartTileCatalog.fromJson(raw), tilesets: const [ProjectTilesetEntry(id: 'ground-image', name: 'Ground', relativePath: 'assets/ground.png')]),
    map: base.map.copyWith(layers: [MapLayer.smartTile(id: 'ground-layer', name: 'Ground', presetId: 'ground', usage: usage, materialPalette: const ['', 'grass'], field: SmartTileField.cell(semanticCells: List.filled(base.map.size.width * base.map.size.height, 0)))]),
  );
}

final class _Fixture {
  _Fixture(this.root, this.opened, this.handles, this.api, this.reader,
      this.unrelatedObjects, this.descriptor, this.instance);
  final Directory root;
  OpenedProject opened;
  final WorkspaceHandleStore handles;
  LocalMapAuthoringMutationApi api;
  final _CountingReader reader;
  final Set<String> unrelatedObjects;
  final List<int> descriptor;
  final SpatialModelInstance instance;
  File get mapFile => File('${root.path}/maps/map.json');

  static Future<_Fixture> open(int unrelated,
      {({ProjectManifest project, MapData map})? content, Set<String> unreadPatternIds = const {}}) async {
    final root = Directory(
        '${Platform.environment['AVELUNE_QA_ROOT'] ?? '${Platform.environment['HOME']}/Library/Caches/AveluneQA/targeted-story-authoring'}/dart');
    await root.create(recursive: true);
    final base = content ?? spatialEnvironmentFixture();
    final model = base.project.models3d.single;
    final project = base.project.copyWith(maps: [
      base.project.maps.single,
      for (var i = 0; i < unrelated; i++)
        ProjectMapEntry(
            id: 'other-$i',
            name: 'Other $i',
            relativePath: 'maps/other-$i.json')
    ], models3d: [
      model,
      for (var i = 0; i < unrelated; i++)
        ProjectModel3dEntry.fromJson({
          ...model.toJson(),
          'id': 'unused-$i',
          'name': 'Unused $i',
          'relativePath': 'assets/models3d/unused-$i.glb'
        })
    ]);
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
        store: store, projectId: 'spatial-local', project: project);
    final unrelatedObjects = <String>{};
    for (var i = 0; i < unrelated; i++) {
      final entry = (await working.catalog.snapshot.indexEntry(
          CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'unused-$i')))!;
      final path = 'catalog/objects/${entry.reference.sha256}.json';
      unrelatedObjects.add(path);
      await File('${root.path}/$path')
          .writeAsString('unrelated model must not be read');
      final foreign = File('${root.path}/maps/other-$i.json');
      await foreign.parent.create(recursive: true);
      await foreign.writeAsString('unrelated map must not be decoded');
    }
    for (final id in unreadPatternIds) {
      final entry = (await working.catalog.snapshot.indexEntry(CatalogDefinitionKey(CatalogDefinitionKind.smartTilePattern, id)))!;
      final path = 'catalog/objects/${entry.reference.sha256}.json';
      unrelatedObjects.add(path);
      await File('${root.path}/$path').writeAsString('unrelated pattern must not be decoded');
    }
    for (var i = 0; i < base.project.cinematicMediaAssets.length; i++) {
      final key = CatalogDefinitionKey(CatalogDefinitionKind.catalogMetadata,
          jsonEncode(['projectDefinition', 'cinematicMediaAssets', i]));
      final entry = (await working.catalog.snapshot.indexEntry(key))!;
      final path = 'catalog/objects/${entry.reference.sha256}.json';
      unrelatedObjects.add(path);
      await File('${root.path}/$path')
          .writeAsString('foreign media must remain unread');
    }
    final registry = base.project.eventRegistry;
    if (registry != null) {
      for (final record in registry.records.skip(1)) {
        final key = CatalogDefinitionKey(CatalogDefinitionKind.workspaceState,
            jsonEncode(['narrativeEventDocument', record.id]));
        final entry = (await working.catalog.snapshot.indexEntry(key))!;
        final path = 'catalog/objects/${entry.reference.sha256}.json';
        unrelatedObjects.add(path);
        await File('${root.path}/$path')
            .writeAsString('foreign registry record must remain unread');
      }
      for (var i = 0;; i++) {
        final key = CatalogDefinitionKey(CatalogDefinitionKind.catalogMetadata,
            jsonEncode(['projectAggregateChunk', 'eventRegistry', i]));
        final entry = await working.catalog.snapshot.indexEntry(key);
        if (entry == null) break;
        unrelatedObjects.add('catalog/objects/${entry.reference.sha256}.json');
      }
    }
    final instance = SpatialModelInstance(
        id: 'old-tree',
        modelId: 'tree',
        position: Model3dVector3(x: 1.25, y: 3, z: 2.125),
        rotationDegrees: 25,
        scale: .8,
        blocksMovement: false,
        castsShadows: false);
    final map = content?.map ??
        base.map.copyWith(
            properties: {'keep': 'preserved'},
            layers: const [MapLayer.environment(id: 'env', name: 'Forest')],
            spatialScene:
                base.map.spatialScene!.copyWith(instances: [instance]));
    final file = File('${root.path}/maps/map.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(map.toJson()));
    final reader = _CountingReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {}).openProject(root.path);
    final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
        catalogFileReader: reader);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final history = File('${root.path}/.pokemap/authoring/history.jsonl');
    await history.parent.create(recursive: true);
    await history.writeAsString('unrelated legacy history\n');
    return _Fixture(root, opened, handles, api, reader, unrelatedObjects,
        await File('${root.path}/project.json').readAsBytes(), instance);
  }

  Future<AuthoringMutationResult> apply(
      String action, Map<String, Object?> parameters, String operation,
      {String? revision, bool confirm = false, bool workshop = false}) async {
    final selected = revision ??
        (await api.readWorkshopSnapshot(opened.projectHandle,
                actionId: action, parameters: parameters))
            .revision;
    final plan = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: operation,
            actionId: action,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            extensions: {if (workshop) 'workshopScope': true},
            expectedRevision: selected,
            idempotencyKey: operation,
            parameters: parameters));
    final token = confirm
        ? (await api.confirmMutation(opened.projectHandle, planId: plan.planId))
            .confirmationToken
        : null;
    return api.applyMutation(opened.projectHandle,
        planId: plan.planId, operationId: operation, confirmationToken: token);
  }

  Future<void> reopen() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {}).openProject(root.path);
    api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
        catalogFileReader: reader);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
  }

  Future<void> close() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final List<String> paths = [];
  final LocalProjectFileReader delegate = const LocalProjectFileReader();
  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
  @override
  bool get supportsStreamingResources => true;
  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }
}

ProjectSmartTileCatalog _groundCatalog() =>
    ProjectSmartTileCatalog.fromJson(jsonDecode(jsonEncode({
      'formatVersion': 8,
      'atlases': [
        {
          'id': 'ground-atlas',
          'name': 'Ground',
          'tilesetId': 'ground-image',
          'cellWidth': 32,
          'cellHeight': 32,
          'columns': 1,
          'rows': 1
        }
      ],
      'materials': [
        {'id': 'grass', 'name': 'Grass', 'connectionGroupId': 'grass'}
      ],
      'presets': [
        {
          'id': 'ground',
          'name': 'Ground',
          'usage': 'path',
          'topology': 'uniform',
          'status': 'published',
          'templateHint': 'simple',
          'coveragePolicy': 'sparse',
          'coverageProfile': {'mode': 'template'},
          'transformPolicy': {},
          'defaultMaterialId': 'grass',
          'allowedMaterialIds': ['grass'],
          'rules': [
            {
              'id': 'ground',
              'centerMatch': {'kind': 'material', 'materialId': 'grass'},
              'candidates': [
                {
                  'id': 'native',
                  'parts': [
                    {
                      'source': {
                        'kind': 'frame',
                        'frame': {
                          'atlasId': 'ground-atlas',
                          'column': 0,
                          'row': 0
                        }
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    })) as Map<String, dynamic>);

List<int> _storyWav() {
  final bytes = Uint8List(8044);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, utf8.encode('RIFF'));
  data.setUint32(4, bytes.length - 8, Endian.little);
  bytes.setRange(8, 16, utf8.encode('WAVEfmt '));
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 8000, Endian.little);
  data.setUint32(28, 8000, Endian.little);
  data.setUint16(32, 1, Endian.little);
  data.setUint16(34, 8, Endian.little);
  bytes.setRange(36, 40, utf8.encode('data'));
  data.setUint32(40, 8000, Endian.little);
  bytes.fillRange(44, bytes.length, 128);
  return bytes;
}
