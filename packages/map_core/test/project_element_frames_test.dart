import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectElementEntry frames', () {
    test('serializes and deserializes multi-frame element', () {
      final element = ProjectElementEntry(
        id: 'pokemon_center',
        name: 'Pokemon Center',
        tilesetId: 'main',
        categoryId: 'buildings',
        frames: const [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 6, height: 7),
            durationMs: 120,
          ),
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 6, y: 0, width: 6, height: 7),
            durationMs: 180,
          ),
        ],
      );
      final json = element.toJson();
      final decoded = ProjectElementEntry.fromJson(json);
      expect(decoded.frames.length, 2);
      expect(decoded.frames.first.source.x, 0);
      expect(decoded.frames.last.source.x, 6);
      expect(decoded.frames.first.durationMs, 120);
      expect(decoded.frames.last.durationMs, 180);
    });

    test('validator rejects non-positive frame duration', () {
      final manifest = ProjectManifest(
        name: 'project',
        maps: const [],
        tilesets: const [
          ProjectTilesetEntry(
              id: 'main', name: 'Main', relativePath: 'main.png'),
        ],
        elementCategories: const [
          ProjectElementCategory(id: 'buildings', name: 'Buildings'),
        ],
        elements: const [
          ProjectElementEntry(
            id: 'pokemon_center',
            name: 'Pokemon Center',
            tilesetId: 'main',
            categoryId: 'buildings',
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 6, height: 7),
                durationMs: 0,
              ),
            ],
          ),
        ],
      );
      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
