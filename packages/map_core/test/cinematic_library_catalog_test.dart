import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('round-trips recursive folders and placements for both families', () {
    final catalog = CinematicLibraryCatalog(
      folders: [
        CinematicLibraryFolder(
          id: 'world-story',
          family: CinematicLibraryFamily.world,
          name: 'Histoire',
          sortOrder: 0,
        ),
        CinematicLibraryFolder(
          id: 'world-story-chapter-1',
          family: CinematicLibraryFamily.world,
          name: 'Chapitre 1',
          parentFolderId: 'world-story',
          sortOrder: 0,
        ),
        CinematicLibraryFolder(
          id: 'presentation-openings',
          family: CinematicLibraryFamily.presentation,
          name: 'Ouvertures',
          sortOrder: 0,
        ),
      ],
      entries: [
        CinematicLibraryEntry(
          family: CinematicLibraryFamily.world,
          cinematicId: 'world-intro',
          folderId: 'world-story-chapter-1',
          sortOrder: 0,
        ),
        CinematicLibraryEntry(
          family: CinematicLibraryFamily.presentation,
          cinematicId: 'presentation-intro',
          folderId: 'presentation-openings',
          sortOrder: 0,
          isArchived: true,
        ),
      ],
    );
    final manifest = ProjectManifest(
      name: 'Cinematics',
      version: ProjectVersion.v7,
      maps: const [],
      tilesets: const [],
      cinematicLibraryCatalog: catalog,
    );

    final wire =
        jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>;
    final decoded = ProjectManifest.fromJson(wire);

    expect(wire['cinematicLibraryCatalog'], catalog.toJson());
    expect(decoded.cinematicLibraryCatalog, catalog);
    expect(decoded.toJson(), manifest.toJson());
  });

  test('moves a folder without changing its stable identity', () {
    final source = CinematicLibraryCatalog(
      folders: [
        CinematicLibraryFolder(
          id: 'source',
          family: CinematicLibraryFamily.world,
          name: 'Source',
          sortOrder: 0,
        ),
        CinematicLibraryFolder(
          id: 'target',
          family: CinematicLibraryFamily.world,
          name: 'Target',
          sortOrder: 1,
        ),
        CinematicLibraryFolder(
          id: 'child',
          family: CinematicLibraryFamily.world,
          name: 'Child',
          parentFolderId: 'source',
          sortOrder: 0,
        ),
      ],
    );

    final moved = const CinematicLibraryCatalogOperations().moveFolder(
      source,
      folderId: 'child',
      targetParentFolderId: 'target',
      targetIndex: 0,
    );

    expect(moved.requireFolder('child').id, 'child');
    expect(moved.requireFolder('child').parentFolderId, 'target');
    expect(moved.requireFolder('child').sortOrder, 0);
  });

  test('rejects a folder move that would create a cycle', () {
    final source = CinematicLibraryCatalog(
      folders: [
        CinematicLibraryFolder(
          id: 'root',
          family: CinematicLibraryFamily.presentation,
          name: 'Root',
          sortOrder: 0,
        ),
        CinematicLibraryFolder(
          id: 'child',
          family: CinematicLibraryFamily.presentation,
          name: 'Child',
          parentFolderId: 'root',
          sortOrder: 0,
        ),
      ],
    );

    expect(
      () => const CinematicLibraryCatalogOperations().moveFolder(
        source,
        folderId: 'root',
        targetParentFolderId: 'child',
        targetIndex: 0,
      ),
      throwsA(
        isA<CinematicLibraryCatalogMutationException>().having(
          (error) => error.code,
          'code',
          'cinematic_library.cycle',
        ),
      ),
    );
  });

  test('creates and renames folders while rejecting sibling collisions', () {
    const operations = CinematicLibraryCatalogOperations();
    final created = operations.createFolder(
      const CinematicLibraryCatalog.empty(),
      folderId: 'opening',
      family: CinematicLibraryFamily.presentation,
      name: 'Ouvertures',
      parentFolderId: null,
      targetIndex: 0,
    );
    final renamed = operations.renameFolder(
      created,
      folderId: 'opening',
      name: 'Introductions',
    );

    expect(renamed.requireFolder('opening').name, 'Introductions');
    expect(
      () => operations.createFolder(
        renamed,
        folderId: 'duplicate',
        family: CinematicLibraryFamily.presentation,
        name: 'introductions',
        parentFolderId: null,
        targetIndex: 1,
      ),
      throwsA(
        isA<CinematicLibraryCatalogMutationException>().having(
          (error) => error.code,
          'code',
          'cinematic_library.name_collision',
        ),
      ),
    );
  });

  test('archives by identity and refuses to delete a non-empty folder', () {
    const operations = CinematicLibraryCatalogOperations();
    final source = CinematicLibraryCatalog(
      folders: [
        CinematicLibraryFolder(
          id: 'openings',
          family: CinematicLibraryFamily.presentation,
          name: 'Ouvertures',
          sortOrder: 0,
        ),
      ],
      entries: [
        CinematicLibraryEntry(
          family: CinematicLibraryFamily.presentation,
          cinematicId: 'presentation-intro',
          folderId: 'openings',
          sortOrder: 0,
        ),
      ],
    );

    final archived = operations.setFolderArchived(
      source,
      folderId: 'openings',
      isArchived: true,
    );

    expect(archived.requireFolder('openings').isArchived, isTrue);
    expect(archived.entries.single.folderId, 'openings');
    expect(
      () => operations.deleteFolder(archived, folderId: 'openings'),
      throwsA(
        isA<CinematicLibraryCatalogMutationException>().having(
          (error) => error.code,
          'code',
          'cinematic_library.folder_not_empty',
        ),
      ),
    );
  });

  test('places, reorders, archives and removes cinematics independently', () {
    const operations = CinematicLibraryCatalogOperations();
    final source = CinematicLibraryCatalog(
      folders: [
        CinematicLibraryFolder(
          id: 'world-folder',
          family: CinematicLibraryFamily.world,
          name: 'Monde',
          sortOrder: 0,
        ),
      ],
    );
    final first = operations.placeCinematic(
      source,
      family: CinematicLibraryFamily.world,
      cinematicId: 'world-a',
      targetFolderId: 'world-folder',
      targetIndex: 0,
    );
    final second = operations.placeCinematic(
      first,
      family: CinematicLibraryFamily.world,
      cinematicId: 'world-b',
      targetFolderId: 'world-folder',
      targetIndex: 0,
    );
    final archived = operations.setCinematicArchived(
      second,
      family: CinematicLibraryFamily.world,
      cinematicId: 'world-a',
      isArchived: true,
    );
    final removed = operations.removeCinematic(
      archived,
      family: CinematicLibraryFamily.world,
      cinematicId: 'world-b',
    );

    expect(second.entries.map((entry) => entry.cinematicId), [
      'world-b',
      'world-a',
    ]);
    expect(
      archived.entryFor(CinematicLibraryFamily.world, 'world-a')!.isArchived,
      isTrue,
    );
    expect(removed.entries.single.cinematicId, 'world-a');
    expect(removed.entries.single.sortOrder, 0);
  });

  test('rejects a move that collides with a target sibling name', () {
    final source = CinematicLibraryCatalog(
      folders: [
        CinematicLibraryFolder(
          id: 'source',
          family: CinematicLibraryFamily.world,
          name: 'Source',
          sortOrder: 0,
        ),
        CinematicLibraryFolder(
          id: 'target',
          family: CinematicLibraryFamily.world,
          name: 'Target',
          sortOrder: 1,
        ),
        CinematicLibraryFolder(
          id: 'moving',
          family: CinematicLibraryFamily.world,
          name: 'Chapter',
          parentFolderId: 'source',
          sortOrder: 0,
        ),
        CinematicLibraryFolder(
          id: 'existing',
          family: CinematicLibraryFamily.world,
          name: 'chapter',
          parentFolderId: 'target',
          sortOrder: 0,
        ),
      ],
    );

    expect(
      () => const CinematicLibraryCatalogOperations().moveFolder(
        source,
        folderId: 'moving',
        targetParentFolderId: 'target',
        targetIndex: 1,
      ),
      throwsA(
        isA<CinematicLibraryCatalogMutationException>().having(
          (error) => error.code,
          'code',
          'cinematic_library.name_collision',
        ),
      ),
    );
  });

  test('fails closed on future schemas, cycles and cross-family folders', () {
    expect(
      () => CinematicLibraryCatalog.fromJson({
        'schemaVersion': 2,
        'folders': <Object?>[],
        'entries': <Object?>[],
      }),
      throwsFormatException,
    );
    expect(
      () => CinematicLibraryCatalog(
        folders: [
          CinematicLibraryFolder(
            id: 'a',
            family: CinematicLibraryFamily.world,
            name: 'A',
            parentFolderId: 'b',
            sortOrder: 0,
          ),
          CinematicLibraryFolder(
            id: 'b',
            family: CinematicLibraryFamily.world,
            name: 'B',
            parentFolderId: 'a',
            sortOrder: 0,
          ),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => CinematicLibraryCatalog(
        folders: [
          CinematicLibraryFolder(
            id: 'world',
            family: CinematicLibraryFamily.world,
            name: 'World',
            sortOrder: 0,
          ),
        ],
        entries: [
          CinematicLibraryEntry(
            family: CinematicLibraryFamily.presentation,
            cinematicId: 'intro',
            folderId: 'world',
            sortOrder: 0,
          ),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('rejects ambiguous or gapped sibling ordering', () {
    expect(
      () => CinematicLibraryCatalog(
        folders: [
          CinematicLibraryFolder(
            id: 'a',
            family: CinematicLibraryFamily.world,
            name: 'A',
            sortOrder: 0,
          ),
          CinematicLibraryFolder(
            id: 'b',
            family: CinematicLibraryFamily.world,
            name: 'B',
            sortOrder: 0,
          ),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => CinematicLibraryCatalog(
        entries: [
          CinematicLibraryEntry(
            family: CinematicLibraryFamily.presentation,
            cinematicId: 'a',
            sortOrder: 1,
          ),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('gates persisted catalogs to v7 and validates asset references', () {
    expect(
      ProjectManifest(
        name: 'V6',
        version: ProjectVersion.v6,
        maps: const [],
        tilesets: const [],
      ).toJson(),
      isNot(contains('cinematicLibraryCatalog')),
    );
    expect(
      () => ProjectManifest.fromJson({
        'name': 'V6',
        'version': 'v6',
        'maps': <Object?>[],
        'tilesets': <Object?>[],
        'cinematicLibraryCatalog': const CinematicLibraryCatalog.empty()
            .toJson(),
      }),
      throwsFormatException,
    );
    final invalid = ProjectManifest(
      name: 'V7',
      version: ProjectVersion.v7,
      maps: const [],
      tilesets: const [],
      cinematicLibraryCatalog: CinematicLibraryCatalog(
        entries: [
          CinematicLibraryEntry(
            family: CinematicLibraryFamily.world,
            cinematicId: 'missing',
            sortOrder: 0,
          ),
        ],
      ),
    );

    expect(
      () => ProjectValidator.validate(invalid),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.code,
          'code',
          'cinematic_library.asset_unknown',
        ),
      ),
    );
  });
}
