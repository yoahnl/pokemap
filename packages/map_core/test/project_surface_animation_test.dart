import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceAtlasTileRef _ref(int column, int row, {String atlasId = 'water-atlas'}) {
  return SurfaceAtlasTileRef(
    atlasId: atlasId,
    column: column,
    row: row,
  );
}

SurfaceAnimationFrame _frame(
  int column,
  int row,
  int durationMs, {
  String atlasId = 'water-atlas',
}) {
  return SurfaceAnimationFrame(
    tileRef: _ref(column, row, atlasId: atlasId),
    durationMs: durationMs,
  );
}

SurfaceAnimationTimeline _singleFrameTimeline({int durationMs = 120}) {
  return SurfaceAnimationTimeline(
    frames: [
      _frame(0, 0, durationMs),
    ],
  );
}

SurfaceAtlasGeometry _geometry([SurfaceAtlasLayout? layout]) {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
    layout: layout ?? SurfaceAtlasLayout.grid,
  );
}

void main() {
  group('ProjectSurfaceAnimation', () {
    test('minimal animation: fields and delegation', () {
      final timeline = SurfaceAnimationTimeline(
        frames: [
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(
              atlasId: 'water-atlas',
              column: 0,
              row: 0,
            ),
            durationMs: 120,
          ),
        ],
      );

      final animation = ProjectSurfaceAnimation(
        id: 'water-loop',
        name: 'Water Loop',
        timeline: timeline,
      );

      expect(animation.id, 'water-loop');
      expect(animation.name, 'Water Loop');
      expect(animation.timeline, timeline);
      expect(animation.syncGroupId, isNull);
      expect(animation.categoryId, isNull);
      expect(animation.sortOrder, 0);
      expect(animation.frameCount, 1);
      expect(animation.totalDurationMs, 120);
    });

    test('preserves the exact same timeline instance', () {
      final timeline = _singleFrameTimeline();
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: timeline,
      );
      expect(identical(animation.timeline, timeline), isTrue);
    });

    test('preserves syncGroupId, categoryId, sortOrder', () {
      final timeline = _singleFrameTimeline();
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: timeline,
        syncGroupId: 'water-global',
        categoryId: 'animated-surfaces',
        sortOrder: 42,
      );
      expect(animation.syncGroupId, 'water-global');
      expect(animation.categoryId, 'animated-surfaces');
      expect(animation.sortOrder, 42);
    });

    test('stores id, name, syncGroupId strings exactly without auto-trim', () {
      const id = '  water-loop  ';
      const name = '  Water Loop  ';
      const sync = '  water-sync  ';
      final animation = ProjectSurfaceAnimation(
        id: id,
        name: name,
        timeline: _singleFrameTimeline(),
        syncGroupId: sync,
      );
      expect(animation.id, id);
      expect(animation.name, name);
      expect(animation.syncGroupId, sync);
    });

    test('rejects empty id: empty string', () {
      expect(
        () => ProjectSurfaceAnimation(
          id: '',
          name: 'N',
          timeline: _singleFrameTimeline(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty id: whitespace only', () {
      expect(
        () => ProjectSurfaceAnimation(
          id: '   ',
          name: 'N',
          timeline: _singleFrameTimeline(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty name: empty string', () {
      expect(
        () => ProjectSurfaceAnimation(
          id: 'a',
          name: '',
          timeline: _singleFrameTimeline(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty name: whitespace only', () {
      expect(
        () => ProjectSurfaceAnimation(
          id: 'a',
          name: '   ',
          timeline: _singleFrameTimeline(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-null syncGroupId that is only whitespace: empty', () {
      expect(
        () => ProjectSurfaceAnimation(
          id: 'a',
          name: 'A',
          timeline: _singleFrameTimeline(),
          syncGroupId: '',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-null syncGroupId that is only whitespace: spaces', () {
      expect(
        () => ProjectSurfaceAnimation(
          id: 'a',
          name: 'A',
          timeline: _singleFrameTimeline(),
          syncGroupId: '   ',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('allows syncGroupId == null', () {
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: _singleFrameTimeline(),
      );
      expect(animation.syncGroupId, isNull);
    });

    test('categoryId: accepts empty and whitespace (ProjectSurfaceAtlas policy)', () {
      final a1 = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: _singleFrameTimeline(),
        categoryId: '',
      );
      expect(a1.categoryId, '');

      const rawWhitespace = '   ';
      final a2 = ProjectSurfaceAnimation(
        id: 'b',
        name: 'B',
        timeline: _singleFrameTimeline(),
        categoryId: rawWhitespace,
      );
      expect(a2.categoryId, rawWhitespace);
    });

    test('sortOrder: preserves negative value', () {
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: _singleFrameTimeline(),
        sortOrder: -10,
      );
      expect(animation.sortOrder, -10);
    });

    test('frameCount delegates to timeline (3 frames)', () {
      final timeline = SurfaceAnimationTimeline(
        frames: [
          _frame(0, 0, 1),
          _frame(0, 0, 1),
          _frame(0, 0, 1),
        ],
      );
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: timeline,
      );
      expect(animation.frameCount, 3);
    });

    test('totalDurationMs delegates: 50 + 100 + 150 = 300', () {
      final timeline = SurfaceAnimationTimeline(
        frames: [
          _frame(0, 0, 50),
          _frame(1, 0, 100),
          _frame(2, 0, 150),
        ],
      );
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: timeline,
      );
      expect(animation.totalDurationMs, 300);
    });

    test('isInside: true when all tiles inside grid', () {
      final g = _geometry();
      final timeline = SurfaceAnimationTimeline(
        frames: [
          _frame(0, 0, 10),
          _frame(3, 2, 10),
        ],
      );
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: timeline,
      );
      expect(animation.isInside(g), isTrue);
    });

    test('isInside: false when one frame out of grid', () {
      final g = _geometry();
      final timeline = SurfaceAnimationTimeline(
        frames: [
          _frame(0, 0, 10),
          _frame(4, 0, 10),
        ],
      );
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: timeline,
      );
      expect(animation.isInside(g), isFalse);
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
          _frame(1, 1, 5),
        ],
      );
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: timeline,
      );
      expect(animation.isInside(gGrid), isTrue);
      expect(animation.isInside(gVertical), isTrue);
    });

    test('value equality: same values => equal and same hash', () {
      final t1 = _singleFrameTimeline();
      final a = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: t1,
        syncGroupId: 'g',
        categoryId: 'c',
        sortOrder: 1,
      );
      final t2 = SurfaceAnimationTimeline(
        frames: [
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(
              atlasId: 'water-atlas',
              column: 0,
              row: 0,
            ),
            durationMs: 120,
          ),
        ],
      );
      final b = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: t2,
        syncGroupId: 'g',
        categoryId: 'c',
        sortOrder: 1,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('value equality: id differs', () {
      final t = _singleFrameTimeline();
      final a = ProjectSurfaceAnimation(id: 'a', name: 'N', timeline: t);
      final b = ProjectSurfaceAnimation(id: 'b', name: 'N', timeline: t);
      expect(a, isNot(b));
    });

    test('value equality: name differs', () {
      final t = _singleFrameTimeline();
      final a = ProjectSurfaceAnimation(id: 'a', name: 'A', timeline: t);
      final b = ProjectSurfaceAnimation(id: 'a', name: 'B', timeline: t);
      expect(a, isNot(b));
    });

    test('value equality: timeline differs (duration)', () {
      final t1 = _singleFrameTimeline(durationMs: 10);
      final t2 = _singleFrameTimeline(durationMs: 20);
      final a = ProjectSurfaceAnimation(id: 'a', name: 'A', timeline: t1);
      final b = ProjectSurfaceAnimation(id: 'a', name: 'A', timeline: t2);
      expect(a, isNot(b));
    });

    test('value equality: syncGroupId differs', () {
      final t = _singleFrameTimeline();
      final a = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: t,
        syncGroupId: 'g1',
      );
      final b = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: t,
        syncGroupId: 'g2',
      );
      expect(a, isNot(b));
    });

    test('value equality: categoryId differs', () {
      final t = _singleFrameTimeline();
      final a = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: t,
        categoryId: 'c1',
      );
      final b = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: t,
        categoryId: 'c2',
      );
      expect(a, isNot(b));
    });

    test('value equality: sortOrder differs', () {
      final t = _singleFrameTimeline();
      final a = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: t,
        sortOrder: 0,
      );
      final b = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: t,
        sortOrder: 1,
      );
      expect(a, isNot(b));
    });

    test('value equality: timeline order differs (same frames, different order)', () {
      final f1 = _frame(0, 0, 10);
      final f2 = _frame(1, 0, 10);
      final t1 = SurfaceAnimationTimeline(frames: [f1, f2]);
      final t2 = SurfaceAnimationTimeline(frames: [f2, f1]);
      final a = ProjectSurfaceAnimation(id: 'a', name: 'A', timeline: t1);
      final b = ProjectSurfaceAnimation(id: 'a', name: 'A', timeline: t2);
      expect(a, isNot(b));
    });

    test('export: type is visible through map_core', () {
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: _singleFrameTimeline(),
      );
      expect(animation, isA<ProjectSurfaceAnimation>());
    });

    test('ProjectManifest toJson: no surface* top-level keys', () {
      final manifest = ProjectManifest(
        name: 'L27',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'Map',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
        surfaceCatalog: ProjectSurfaceCatalog(),);
      final map = manifest.toJson();
      expect(map.containsKey('surfaceCatalog'), isTrue);
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
