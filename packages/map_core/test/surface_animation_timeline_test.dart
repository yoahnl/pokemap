import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceAnimationFrame _frame({
  required String atlasId,
  required int column,
  required int row,
  required int durationMs,
}) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: atlasId,
      column: column,
      row: row,
    ),
    durationMs: durationMs,
  );
}

void main() {
  group('SurfaceAnimationTimeline', () {
    test('minimal timeline with one frame', () {
      final frame = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'water-atlas',
          column: 0,
          row: 0,
        ),
        durationMs: 120,
      );

      final timeline = SurfaceAnimationTimeline(frames: [frame]);

      expect(timeline.frames.length, 1);
      expect(timeline.frameCount, 1);
      expect(timeline.totalDurationMs, 120);
      expect(timeline.frames.first, frame);
    });

    test('rejects empty frames list', () {
      expect(
        () => SurfaceAnimationTimeline(frames: []),
        throwsA(isA<ValidationException>()),
      );
    });

    test('preserves frame order', () {
      final a = _frame(atlasId: 'a', column: 0, row: 0, durationMs: 1);
      final b = _frame(atlasId: 'b', column: 0, row: 0, durationMs: 1);
      final c = _frame(atlasId: 'c', column: 0, row: 0, durationMs: 1);
      final timeline = SurfaceAnimationTimeline(frames: [a, b, c]);
      expect(timeline.frames[0], a);
      expect(timeline.frames[1], b);
      expect(timeline.frames[2], c);
    });

    test('totalDurationMs sums frame durations', () {
      final timeline = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'x', column: 0, row: 0, durationMs: 50),
          _frame(atlasId: 'x', column: 1, row: 0, durationMs: 100),
          _frame(atlasId: 'x', column: 2, row: 0, durationMs: 150),
        ],
      );
      expect(timeline.totalDurationMs, 300);
    });

    test('exposed frames list is unmodifiable', () {
      final f = _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10);
      final timeline = SurfaceAnimationTimeline(frames: [f]);
      expect(
        () => timeline.frames.add(f),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('defensive copy: mutating source after construction does not affect timeline', () {
      final f1 = _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10);
      final source = <SurfaceAnimationFrame>[f1];
      final timeline = SurfaceAnimationTimeline(frames: source);
      final f2 = _frame(atlasId: 'b', column: 0, row: 0, durationMs: 20);
      source.add(f2);
      expect(timeline.frameCount, 1);
      expect(timeline.frames.length, 1);
      expect(timeline.frames.first, f1);
    });

    test('isInside: true when all frames are inside grid', () {
      final geometry = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
      );
      final timeline = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
          _frame(atlasId: 'a', column: 3, row: 2, durationMs: 10),
        ],
      );
      expect(timeline.isInside(geometry), isTrue);
    });

    test('isInside: false when any frame is out of grid', () {
      final geometry = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
      );
      final timeline = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
          _frame(atlasId: 'a', column: 4, row: 0, durationMs: 10),
        ],
      );
      expect(timeline.isInside(geometry), isFalse);
    });

    test('isInside: independent of SurfaceAtlasLayout', () {
      final tile = SurfaceAtlasTileSize(width: 8, height: 8);
      final grid = SurfaceAtlasGridSize(columns: 4, rows: 3);
      final gGrid = SurfaceAtlasGeometry(
        tileSize: tile,
        gridSize: grid,
        layout: SurfaceAtlasLayout.grid,
      );
      final gVertical = SurfaceAtlasGeometry(
        tileSize: tile,
        gridSize: grid,
        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      final timeline = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 1, row: 1, durationMs: 5),
        ],
      );
      expect(timeline.isInside(gGrid), isTrue);
      expect(timeline.isInside(gVertical), isTrue);
    });

    test('value equality: same frames in same order => equal and same hashCode', () {
      final t1 = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
          _frame(atlasId: 'a', column: 1, row: 0, durationMs: 20),
        ],
      );
      final t2 = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
          _frame(atlasId: 'a', column: 1, row: 0, durationMs: 20),
        ],
      );
      expect(t1, t2);
      expect(t1.hashCode, t2.hashCode);
    });

    test('value equality: different order => not equal', () {
      final f0 = _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10);
      final f1 = _frame(atlasId: 'a', column: 1, row: 0, durationMs: 10);
      final t1 = SurfaceAnimationTimeline(frames: [f0, f1]);
      final t2 = SurfaceAnimationTimeline(frames: [f1, f0]);
      expect(t1, isNot(t2));
    });

    test('value equality: different frame content => not equal', () {
      final t1 = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
        ],
      );
      final t2 = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'b', column: 0, row: 0, durationMs: 10),
        ],
      );
      expect(t1, isNot(t2));
    });

    test('value equality: different duration on a frame => not equal', () {
      final t1 = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
        ],
      );
      final t2 = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 99),
        ],
      );
      expect(t1, isNot(t2));
    });

    test('export: type is visible through map_core', () {
      final t = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 1),
        ],
      );
      expect(t, isA<SurfaceAnimationTimeline>());
    });

    test('ProjectManifest toJson: no surface* top-level keys', () {
      const manifest = ProjectManifest(
        name: 'L26',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'Map',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
      );
      final map = manifest.toJson();
      for (final key in <String>[
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(map.containsKey(key), isFalse, reason: key);
      }
    });
  });
}
