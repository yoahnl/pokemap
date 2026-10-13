import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../tool/source_semantics_study.dart' as study;
import 'support/native_writer_fixture.dart';

void main() {
  late Directory root;
  late NativeWriterFixture fixture;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ac15-study-map-proof-');
    fixture = await NativeWriterFixture.create(root.path);
  });
  tearDown(() async => root.delete(recursive: true));

  NativeMutation save(MapData map, String operationId) => NativeMutation(
        operationId: ConverterId(operationId),
        actionId: 'map.save',
        sourceEntityIds: [fixture.source.mapIdentity(1)],
        targetEntityIds: [ConverterId(map.id)],
        parameters: {'map': map.toJson()},
      );

  NativeMutation connect(String from, String to, {int offset = 0}) =>
      NativeMutation(
        operationId: ConverterId('study_pair'),
        actionId: 'connection.create_bidirectional_apply',
        sourceEntityIds: [fixture.source.mapIdentity(1)],
        targetEntityIds: [ConverterId(from), ConverterId(to)],
        parameters: {
          'mapId': from,
          'direction': 'east',
          'targetMapId': to,
          'offset': offset,
        },
      );

  NativeMutation change(
          String action, String mapId, String key, Object value) =>
      NativeMutation(
        operationId: ConverterId('study_${action.replaceAll('.', '_')}'),
        actionId: action,
        sourceEntityIds: [fixture.source.mapIdentity(1)],
        targetEntityIds: [ConverterId(mapId)],
        parameters: {'mapId': mapId, key: jsonDecode(jsonEncode(value))},
      );

  test('study reopening compares every saved map', () {
    final map = fixture.expectedMap;
    final result = study.expectedStudyMaps([save(map, 'study_save')]);
    expect(result.keys, [map.id]);
    expect(result[map.id]!.toJson(), map.toJson());
  });

  test('study reopening includes music assigned after map save', () {
    final map = fixture.expectedMap;
    final result = study.expectedStudyMaps([
      save(map, 'study_save'),
      NativeMutation(
        operationId: ConverterId('study_music'),
        actionId: 'map.audio.update',
        sourceEntityIds: [fixture.source.mapIdentity(1)],
        targetEntityIds: [ConverterId(map.id)],
        parameters: {
          'mapId': map.id,
          'musicPath': 'assets/audio/original.ogg',
          'musicVolume': 0.64,
        },
      ),
    ]);
    expect(result[map.id]!.mapMetadata.musicPath, 'assets/audio/original.ogg');
    expect(result[map.id]!.mapMetadata.musicVolume, 0.64);
    expect(map.mapMetadata.musicPath, isNot('assets/audio/original.ogg'));
  });

  test('study reopening includes both ends and signed reciprocal offset', () {
    final from = fixture.expectedMap;
    final to = from.copyWith(id: 'study_target_map', name: 'Target');
    final result = study.expectedStudyMaps([
      save(from, 'study_save_from'),
      save(to, 'study_save_to'),
      connect(from.id, to.id, offset: 1),
    ]);
    expect(result[from.id]!.connections.single.direction,
        MapConnectionDirection.east);
    expect(result[from.id]!.connections.single.targetMapId, to.id);
    expect(result[from.id]!.connections.single.offset, 1);
    expect(result[to.id]!.connections.single.direction,
        MapConnectionDirection.west);
    expect(result[to.id]!.connections.single.targetMapId, from.id);
    expect(result[to.id]!.connections.single.offset, -1);
    expect(from.connections, isEmpty);
    expect(to.connections, isEmpty);
  });

  test('study proof refuses a connection before both map saves', () {
    final from = fixture.expectedMap;
    expect(
        () => study.expectedStudyMaps([
              save(from, 'study_save'),
              connect(from.id, 'missing_map'),
            ]),
        throwsStateError);
  });

  test('study proof refuses replacing an occupied connection', () {
    final from = fixture.expectedMap;
    final to = from.copyWith(id: 'study_target_map', name: 'Target');
    expect(
        () => study.expectedStudyMaps([
              save(from, 'study_save_from'),
              save(to, 'study_save_to'),
              connect(from.id, to.id),
              connect(from.id, to.id),
            ]),
        throwsStateError);
  });

  test('study proof refuses duplicate saves that could erase later changes',
      () {
    final map = fixture.expectedMap;
    expect(
        () => study.expectedStudyMaps([
              save(map, 'study_save'),
              save(map, 'study_save_again'),
            ]),
        throwsStateError);
  });

  test('study reopening includes a projected event entity', () {
    final map = fixture.expectedMap;
    const entity = MapEntity(
        id: 'study_event',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 1, y: 1));
    final result = study.expectedStudyMaps([
      save(map, 'study_save'),
      change('entity.upsert', map.id, 'entity', entity.toJson()),
    ]);
    expect(result[map.id]!.entities, [...map.entities, entity]);
    expect(map.entities, isNot(contains(entity)));
  });

  test('study entity replacement preserves its list position', () {
    const entity = MapEntity(
        id: 'study_event',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 1, y: 1));
    final map = fixture.expectedMap.copyWith(entities: [entity]);
    final replacement =
        entity.copyWith(name: 'Updated event', blocksMovement: false);
    final result = study.expectedStudyMaps([
      save(map, 'study_save'),
      change('entity.upsert', map.id, 'entity', replacement.toJson()),
    ]);
    expect(result[map.id]!.entities, [replacement]);
  });

  test('study reopening includes a projected event trigger', () {
    final map = fixture.expectedMap;
    const trigger = MapTrigger(
        id: 'study_trigger',
        type: TriggerType.event,
        area: MapRect(
            pos: GridPos(x: 1, y: 1), size: GridSize(width: 1, height: 1)));
    final result = study.expectedStudyMaps([
      save(map, 'study_save'),
      change('trigger.create', map.id, 'trigger', trigger.toJson()),
    ]);
    expect(result[map.id]!.triggers, [...map.triggers, trigger]);
  });

  test('study reopening includes a projected arrival warp', () {
    final map = fixture.expectedMap;
    final warp = MapWarp(
        id: 'study_arrival',
        pos: const GridPos(x: 1, y: 1),
        targetMapId: map.id,
        targetPos: const GridPos(x: 1, y: 1),
        triggerMode: MapWarpTriggerMode.onBump);
    final result = study.expectedStudyMaps([
      save(map, 'study_save'),
      change('warp.create', map.id, 'warp', warp.toJson()),
    ]);
    expect(result[map.id]!.warps, [...map.warps, warp]);
  });

  test('study proof refuses unhandled map-domain actions', () {
    final map = fixture.expectedMap;
    for (final action in [
      'entity.delete',
      'trigger.delete',
      'warp.delete',
      'connection.delete'
    ]) {
      expect(
          () => study.expectedStudyMaps([
                save(map, 'study_save'),
                change(action, map.id, 'entityId', 'study_event'),
              ]),
          throwsStateError,
          reason: action);
    }
  });

  test('study proof refuses an event entity before its map save', () {
    final map = fixture.expectedMap;
    const entity = MapEntity(
        id: 'study_event',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 1, y: 1));
    expect(
        () => study.expectedStudyMaps([
              change('entity.upsert', map.id, 'entity', entity.toJson()),
            ]),
        throwsStateError);
  });
}
