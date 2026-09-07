import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const folder = {'id': 'buildings', 'name': 'Buildings'};
const placements = [
  {'tilesetId': 'house', 'targetTilesetId': 'atlas', 'x': 2, 'y': 1},
];
const assignments = [
  {'tilesetId': 'atlas', 'folderId': 'buildings'},
];

ProjectTilesetEntry tileset(String id, int width, int height) =>
    ProjectTilesetEntry(
      id: id,
      name: id,
      relativePath: 'assets/$id.png',
      source: ProjectRegularAtlasTilesetSource(
        assetId: id,
        pixelWidth: width,
        pixelHeight: height,
        tileWidth: 32,
        tileHeight: 32,
      ),
    );

ProjectManifest fixture() => ProjectManifest(
      name: 'Library',
      maps: const [],
      tilesets: [tileset('house', 64, 64), tileset('atlas', 128, 128)],
      elementCategories: const [
        ProjectElementCategory(id: 'props', name: 'Props')
      ],
      elements: const [
        ProjectElementEntry(
          id: 'house',
          name: 'House',
          tilesetId: 'house',
          categoryId: 'props',
          tags: ['preserve'],
          frames: [
            TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0), durationMs: 100),
            TilesetVisualFrame(
                tilesetId: 'house',
                source: TilesetSourceRect(x: 1, y: 1),
                durationMs: 200),
          ],
        )
      ],
    );

ProjectManifest migrate(
  ProjectManifest manifest, {
  List<Map<String, Object?>> moves = placements,
  List<Map<String, Object?>> classification = assignments,
}) =>
    const TilesetLibraryActions().reorganize(
      manifest,
      maps: const [],
      placements: moves,
      folders: const [folder],
      assignments: classification,
    );

void main() {
  test('remaps implicit and explicit frames without changing element metadata',
      () {
    final original = fixture();
    final next = migrate(original);
    expect(next.tilesets.map((t) => t.id), ['atlas']);
    expect(next.tilesets.single.folderId, 'buildings');
    expect(next.elements.single.tilesetId, 'atlas');
    expect(
        next.elements.single.frames
            .map((f) => [f.tilesetId, f.source.x, f.source.y, f.durationMs]),
        [
          ['atlas', 2, 1, 100],
          ['atlas', 3, 2, 200]
        ]);
    final before = original.elements.single.toJson()
      ..remove('frames')
      ..remove('tilesetId');
    final after = next.elements.single.toJson()
      ..remove('frames')
      ..remove('tilesetId');
    expect(after, before);
    expect(original.tilesets.length, 2);
  });

  test('rejects overlapping placements', () {
    final original = fixture()
        .copyWith(tilesets: [...fixture().tilesets, tileset('shed', 32, 32)]);
    expect(
        () => migrate(original, moves: [
              ...placements,
              {'tilesetId': 'shed', 'targetTilesetId': 'atlas', 'x': 2, 'y': 1}
            ]),
        throwsA(isA<VisualLibraryException>()));
  });

  test('rejects incomplete classification', () {
    expect(() => migrate(fixture(), classification: []),
        throwsA(isA<VisualLibraryException>()));
  });

  test('rejects existing consumers of the destination', () {
    final original = fixture();
    expect(
        () => migrate(original.copyWith(elements: [
              ...original.elements,
              original.elements.single
                  .copyWith(id: 'other', tilesetId: 'atlas'),
            ])),
        throwsA(isA<VisualLibraryException>()));
  });

  test('rejects unrelated references and leaves the source intact', () {
    final original =
        fixture().copyWith(globalProperties: const {'tilesetId': 'house'});
    expect(() => migrate(original), throwsA(isA<VisualLibraryException>()));
    expect(original.tilesets.length, 2);
  });

  test('rejects atlas overflow and maximum texture overflow', () {
    expect(
        () => migrate(fixture(), moves: [
              {
                'tilesetId': 'house',
                'targetTilesetId': 'atlas',
                'x': 3,
                'y': 1
              },
            ]),
        throwsA(isA<VisualLibraryException>()));
    expect(
        () => migrate(fixture().copyWith(
            tilesets: [tileset('house', 64, 64), tileset('atlas', 8224, 128)])),
        throwsA(isA<VisualLibraryException>()));
  });

  test('classifies specialized tilesets without altering their sources', () {
    final original = fixture();
    final next = migrate(original, moves: [], classification: [
      ...assignments,
      {'tilesetId': 'house', 'folderId': 'buildings'},
    ]);
    expect(next.tilesets.first.source, original.tilesets.first.source);
    expect(next.elements, original.elements);
  });
}
