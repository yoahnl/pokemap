import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const plain = MapWarp(
    id: 'ladder',
    pos: GridPos(x: 2, y: 3),
    targetMapId: 'upper',
    targetPos: GridPos(x: 4, y: 5),
  );
  test('legacy warp bytes do not acquire a ladder field', () {
    final json = plain.toJson();
    expect(json.containsKey('ladder'), isFalse);
    expect(MapWarp.fromJson(json).ladder, isNull);
    expect(jsonEncode(MapWarp.fromJson(json).toJson()), jsonEncode(json));
  });
  test('ladder direction, facing and motion survive warp serialization', () {
    final ladder = MapWarpLadder(
      direction: MapWarpLadderDirection.down,
      facing: EntityFacing.south,
      heightCells: 1.5,
      durationSeconds: .6,
    );
    final warp = plain.copyWith(ladder: ladder);
    expect(MapWarp.fromJson(warp.toJson()).ladder, ladder);
    expect(warp.copyWith(ladder: null), plain);
  });
  test('ladder rejects malformed and unknown traversal values', () {
    final valid = MapWarpLadder().toJson();
    for (final patch in [
      {'heightCells': 0},
      {'heightCells': -1},
      {'durationSeconds': 0},
      {'durationSeconds': 11},
      {'direction': 'sideways'},
      {'facing': 'unknown'},
      {'other': true},
      {'heightCells': '2'},
    ]) {
      expect(
        () => MapWarpLadder.fromJson({...valid, ...patch}),
        throwsFormatException,
        reason: '$patch',
      );
    }
    expect(() => MapWarpLadder(heightCells: double.nan), throwsFormatException);
  });
}
