import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('visual library contracts', () {
    const atlas = _worldAtlas;

    test('rejects a source rect outside the real atlas bounds', () {
      expect(
        () => const TilesetActions().validateFrame(
          const TilesetVisualFrame(
            source: TilesetSourceRect(x: 3, y: 0, width: 2),
          ),
          owningTilesetId: 'world',
          atlases: const {'world': atlas},
        ),
        throwsA(
          isA<VisualLibraryException>().having(
            (error) => error.code,
            'code',
            'tileset.source_out_of_bounds',
          ),
        ),
      );
    });

    test('tileset upsert supports progressive legacy atlas migration', () {
      const legacyTilesetId = 'tileset_m00_hanazuki_guesthouse_room';
      final legacy = ProjectManifest(
        name: 'Legacy visual fixture',
        maps: const [],
        tilesets: const [
          ProjectTilesetEntry(
            id: legacyTilesetId,
            name: 'M00 Guesthouse',
            relativePath: 'images/m00.png',
          ),
        ],
        elementCategories: const [
          ProjectElementCategory(id: 'legacy', name: 'Legacy'),
        ],
        elements: const [
          ProjectElementEntry(
            id: 'legacy-bed',
            name: 'Legacy Bed',
            tilesetId: legacyTilesetId,
            categoryId: 'legacy',
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
          ),
        ],
      );
      const m02Atlas = ProjectRegularAtlasTilesetSource(
        assetId: 'm02-atlas',
        pixelWidth: 16,
        pixelHeight: 16,
        tileWidth: 16,
        tileHeight: 16,
      );
      const m02 = ProjectTilesetEntry(
        id: 'm02',
        name: 'M02',
        relativePath: 'images/m02.png',
        source: m02Atlas,
        paletteEntries: [
          TilesetPaletteEntry(
            id: 'm02-tile',
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
          ),
        ],
      );

      final migrated = const TilesetActions().upsert(
        legacy,
        tileset: m02,
      );
      final atlases = readTilesetAtlases(migrated);

      expect(atlases.keys, ['m02']);
      expect(
        () => validateManifestFrames(migrated, atlases),
        throwsA(
          isA<VisualLibraryException>()
              .having(
                (error) => error.code,
                'code',
                'tileset.atlas_missing',
              )
              .having(
                (error) => error.details['tilesetId'],
                'tilesetId',
                legacyTilesetId,
              ),
        ),
      );
      expect(
        () => const TilesetActions().upsert(
          legacy,
          tileset: m02.copyWith(
            source: m02Atlas,
            paletteEntries: const [
              TilesetPaletteEntry(
                id: 'invalid',
                frames: [
                  TilesetVisualFrame(
                    source: TilesetSourceRect(x: 1, y: 0),
                  ),
                ],
              ),
            ],
          ),
        ),
        throwsA(
          isA<VisualLibraryException>().having(
            (error) => error.code,
            'code',
            'tileset.source_out_of_bounds',
          ),
        ),
      );
    });

    test('regrid preview reports every affected visual before apply', () {
      final preview = const TilesetActions().previewRegrid(
        _manifest(),
        tilesetId: 'world',
        tileWidth: 8,
        tileHeight: 8,
      );

      expect(preview.canApply, isTrue);
      expect(preview.impacts.map((impact) => impact.ownerKind), [
        'element',
        'paletteEntry',
      ]);
      expect(preview.before.tileWidth, 16);
      expect(preview.after.tileWidth, 8);
    });

    test('regrid preserves pixel regions for spaced atlases', () {
      const spaced = ProjectRegularAtlasTilesetSource(
        assetId: 'world-atlas',
        pixelWidth: 68,
        pixelHeight: 34,
        tileWidth: 32,
        tileHeight: 32,
        marginX: 1,
        marginY: 1,
        spacingX: 2,
        spacingY: 2,
      );
      final base = _manifest();
      final manifest = base.copyWith(
        tilesets: [
          base.tilesets.single.copyWith(source: spaced),
        ],
      );

      final preview = const TilesetActions().previewRegrid(
        manifest,
        tilesetId: 'world',
        tileWidth: 15,
        tileHeight: 15,
      );

      expect(preview.canApply, isTrue);
      expect(preview.after.columns, 4);
      expect(preview.after.rows, 2);
      expect(preview.impacts[0].after,
          const TilesetSourceRect(x: 2, y: 0, width: 2, height: 2));
      expect(preview.impacts[1].after,
          const TilesetSourceRect(x: 0, y: 0, width: 2, height: 2));
    });

    test('accepts Tiled atlases with unused trailing raster pixels', () {
      const trailingPixels = ProjectRegularAtlasTilesetSource(
        assetId: 'tiled-atlas',
        pixelWidth: 960,
        pixelHeight: 929,
        tileWidth: 32,
        tileHeight: 32,
      );
      final base = _manifest();
      final imported = base.copyWith(
        tilesets: <ProjectTilesetEntry>[
          base.tilesets.single.copyWith(source: trailingPixels),
        ],
      );

      expect(trailingPixels.columns, 30);
      expect(trailingPixels.rows, 29);
      expect(
        () => const TilesetActions().upsert(
          base,
          tileset: imported.tilesets.single,
        ),
        returnsNormally,
      );
      expect(
        () => const TilesetActions().validateFrame(
          TilesetVisualFrame(source: TilesetSourceRect(x: 29, y: 28)),
          owningTilesetId: 'world',
          atlases: const <String, ProjectRegularAtlasTilesetSource>{
            'world': trailingPixels,
          },
        ),
        returnsNormally,
      );
      expect(
        () => const TilesetActions().validateFrame(
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 29)),
          owningTilesetId: 'world',
          atlases: const <String, ProjectRegularAtlasTilesetSource>{
            'world': trailingPixels,
          },
        ),
        throwsA(
          isA<VisualLibraryException>().having(
            (error) => error.code,
            'code',
            'tileset.source_out_of_bounds',
          ),
        ),
      );
    });

    test('element deletion scans every loaded map', () {
      final town = const MapData(
        id: 'town',
        name: 'Town',
        size: GridSize(width: 4, height: 4),
        placedElements: [
          MapPlacedElement(
            id: 'tree-placed',
            layerId: 'objects',
            elementId: 'tree',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );

      expect(
        () => const ElementActions().delete(
          _manifest(),
          maps: [town],
          elementId: 'tree',
        ),
        throwsA(
          isA<VisualLibraryException>()
              .having(
                (error) => error.code,
                'code',
                'element.references_blocking',
              )
              .having(
                (error) => error.details['references'],
                'references',
                contains('map:town:placedElement:tree-placed'),
              ),
        ),
      );
    });

    test('element batch upsert merges the complete batch atomically', () {
      final dynamic actions = const ElementActions();

      final result = actions.upsertMany(
        _manifest(),
        elements: const [
          ProjectElementEntry(
            id: 'tree',
            name: 'Large Tree',
            tilesetId: 'world',
            categoryId: 'nature',
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 1, y: 0),
              ),
            ],
          ),
          ProjectElementEntry(
            id: 'rock',
            name: 'Rock',
            tilesetId: 'world',
            categoryId: 'nature',
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 2, y: 0),
              ),
            ],
          ),
        ],
        atlases: const {'world': _worldAtlas},
      ) as ProjectManifest;

      expect(result.elements.map((element) => element.id), ['rock', 'tree']);
      expect(
        result.elements.singleWhere((element) => element.id == 'tree').name,
        'Large Tree',
      );
    });

    test('element batch upsert rejects an empty batch', () {
      expect(
        () => const ElementActions().upsertMany(
          _manifest(),
          elements: const [],
          atlases: const {'world': _worldAtlas},
        ),
        throwsA(
          isA<VisualLibraryException>().having(
            (error) => error.code,
            'code',
            'element.batch_empty',
          ),
        ),
      );
    });

    test('element batch upsert rejects duplicate element identities', () {
      const rock = ProjectElementEntry(
        id: 'rock',
        name: 'Rock',
        tilesetId: 'world',
        categoryId: 'nature',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 2, y: 0),
          ),
        ],
      );
      expect(
        () => const ElementActions().upsertMany(
          _manifest(),
          elements: const [rock, rock],
          atlases: const {'world': _worldAtlas},
        ),
        throwsA(
          isA<VisualLibraryException>().having(
            (error) => error.code,
            'code',
            'element.batch_duplicate',
          ),
        ),
      );
    });

    test('element batch upsert rejects an oversized batch', () {
      final elements = List.generate(
        513,
        (index) => ProjectElementEntry(
          id: 'element-$index',
          name: 'Element $index',
          tilesetId: 'world',
          categoryId: 'nature',
          frames: const [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0),
            ),
          ],
        ),
      );
      expect(
        () => const ElementActions().upsertMany(
          _manifest(),
          elements: elements,
          atlases: const {'world': _worldAtlas},
        ),
        throwsA(
          isA<VisualLibraryException>().having(
            (error) => error.code,
            'code',
            'element.batch_limit_exceeded',
          ),
        ),
      );
    });

    test('element batch upsert builds one canonical manifest change', () {
      final snapshot = _snapshot(_manifest());
      final draft = const ElementActions().build(
        AuthoringPlanningContext(
          snapshot: snapshot,
          request: AuthoringRequest(
            requestId: 'request-element-batch-upsert',
            actionId: 'element.batch_upsert',
            actionVersion: 1,
            workspaceHandle: 'workspace-visual-library',
            expectedRevision: snapshot.revision,
            idempotencyKey: 'idem-element-batch-upsert',
            parameters: {
              'elements': [
                const ProjectElementEntry(
                  id: 'rock',
                  name: 'Rock',
                  tilesetId: 'world',
                  categoryId: 'nature',
                  frames: [
                    TilesetVisualFrame(
                      source: TilesetSourceRect(x: 2, y: 0),
                    ),
                  ],
                ).toJson(),
              ],
            },
          ),
          planId: 'plan-element-batch-upsert',
          seed: 1,
        ),
      );

      final projected = ProjectManifest.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(
            utf8.decode(draft.changeSet.changes.single.afterBytes!),
          ) as Map,
        ),
      );
      expect(draft.changeSet.changes, hasLength(1));
      expect(projected.elements.map((element) => element.id), ['rock', 'tree']);
    });

    test('dispatcher exposes canonical visual library mutations', () {
      final ids = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll({
          'tileset_folder.upsert',
          'tileset_folder.delete',
          'tileset.upsert',
          'tileset.delete',
          'palette.upsert',
          'palette.delete',
          'element.upsert',
          'element.batch_upsert',
          'element.delete',
          'element_category.upsert',
          'element_category.delete',
          'project.visual_grid.update',
        }),
      );
      expect(ids.where((id) => id.startsWith('preset.')), isEmpty);
    });

    test('visual organization upserts and protects referenced containers', () {
      const actions = VisualOrganizationActions();
      final organized = actions
          .upsertTilesetFolder(
        _manifest(),
        folder: const ProjectTilesetFolder(
          id: 'm02',
          name: 'M02',
          sortOrder: 2,
        ),
      )
          .copyWith(
        tilesets: [
          _manifest().tilesets.single.copyWith(folderId: 'm02'),
        ],
      );

      expect(organized.tilesetFolders.single.id, 'm02');
      expect(
        () => actions.deleteTilesetFolder(
          organized,
          folderId: 'm02',
        ),
        throwsA(
          isA<VisualLibraryException>().having(
            (error) => error.code,
            'code',
            'tileset_folder.references_blocking',
          ),
        ),
      );
      expect(
        () => actions.deleteElementCategory(
          organized,
          categoryId: 'nature',
        ),
        throwsA(
          isA<VisualLibraryException>().having(
            (error) => error.code,
            'code',
            'element_category.references_blocking',
          ),
        ),
      );
    });

    test('visual grid update aligns project cells with atlas cells', () {
      final base = _manifest();
      final manifest = base.copyWith(
        tilesets: [
          base.tilesets.single.copyWith(
            source: const ProjectRegularAtlasTilesetSource(
              assetId: 'world-atlas',
              pixelWidth: 64,
              pixelHeight: 64,
              tileWidth: 32,
              tileHeight: 32,
            ),
          ),
        ],
      );
      final dynamic actions = const VisualOrganizationActions();

      final result = actions.updateProjectVisualGrid(
        manifest,
        tileWidth: 32,
        tileHeight: 32,
        displayScale: 1.0,
      ) as ProjectManifest;

      expect(result.settings.tileWidth, 32);
      expect(result.settings.tileHeight, 32);
      expect(result.settings.displayScale, 1.0);
    });

    test('visual grid update builds one canonical manifest change', () {
      final base = _manifest();
      final manifest = base.copyWith(
        tilesets: [
          base.tilesets.single.copyWith(
            source: const ProjectRegularAtlasTilesetSource(
              assetId: 'world-atlas',
              pixelWidth: 64,
              pixelHeight: 64,
              tileWidth: 32,
              tileHeight: 32,
            ),
          ),
        ],
      );
      final snapshot = _snapshot(manifest);
      final draft = const VisualOrganizationActions().build(
        AuthoringPlanningContext(
          snapshot: snapshot,
          request: AuthoringRequest(
            requestId: 'request-project-visual-grid',
            actionId: 'project.visual_grid.update',
            actionVersion: 1,
            workspaceHandle: 'workspace-visual-library',
            expectedRevision: snapshot.revision,
            idempotencyKey: 'idem-project-visual-grid',
            parameters: const {
              'grid': {
                'tileWidth': 32,
                'tileHeight': 32,
                'displayScale': 1.0,
              },
            },
          ),
          planId: 'plan-project-visual-grid',
          seed: 1,
        ),
      );

      final projected = ProjectManifest.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(
            utf8.decode(draft.changeSet.changes.single.afterBytes!),
          ) as Map,
        ),
      );
      expect(draft.changeSet.changes, hasLength(1));
      expect(projected.settings.tileWidth, 32);
      expect(projected.settings.tileHeight, 32);
      expect(projected.settings.displayScale, 1.0);
    });
  });
}

ProjectManifest _manifest() => ProjectManifest(
      name: 'Visual fixture',
      maps: const [],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'world',
          name: 'World',
          relativePath: 'images/world.png',
          source: _worldAtlas,
          paletteEntries: [
            TilesetPaletteEntry(
              id: 'grass-tile',
              name: 'Grass',
              frames: [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                ),
              ],
            ),
          ],
        ),
      ],
      elementCategories: const [
        ProjectElementCategory(id: 'nature', name: 'Nature'),
      ],
      elements: const [
        ProjectElementEntry(
          id: 'tree',
          name: 'Tree',
          tilesetId: 'world',
          categoryId: 'nature',
          frames: [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 1, y: 0),
            ),
          ],
        ),
      ],
    );

const _worldAtlas = ProjectRegularAtlasTilesetSource(
  assetId: 'world-atlas',
  pixelWidth: 64,
  pixelHeight: 48,
  tileWidth: 16,
  tileHeight: 16,
);

ProjectSnapshot _snapshot(ProjectManifest manifest) {
  final bytes = utf8.encode(jsonEncode(manifest.toJson()));
  final revision = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
      relativePath: 'project.json',
      bytes: bytes,
    ),
  ]);
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('visual-library-project'),
    revision: revision,
    manifest: manifest,
    maps: const [],
    resourceFingerprints: {'project': revision},
    resourceBytes: {'project': bytes},
  );
}
