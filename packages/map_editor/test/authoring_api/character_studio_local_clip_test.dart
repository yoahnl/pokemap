import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/src/catalog_storage/working_project_catalog.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/character_studio_authoring_gateway.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/features/character_studio/application/character_animation_clip_use_cases.dart';
import 'package:map_editor/src/features/character_studio/application/character_animation_matrix_model.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';

void main() {
  for (final fixtureCase in [(true, 0), (true, 80), (false, 80)]) {
    final (catalog, unrelated) = fixtureCase;
    test(
      'system clip save stays local catalog=$catalog with $unrelated unrelated resources',
      () async {
        final f = await _Fixture.create(unrelated, catalog: catalog);
        addTearDown(f.dispose);
        var project = f.project;
        final counts = <int>[];
        final timings = <int>[];
        for (final mode in ['set', 'preserve', 'clear']) {
          f.reader.paths.clear();
          final watch = Stopwatch()..start();
          project = await f.save(
            project,
            loop: mode != 'preserve',
            reference: mode == 'set' ? 32 : null,
            clear: mode == 'clear',
          );
          timings.add(watch.elapsedMilliseconds);
          counts.add(f.reader.paths.length);
          expect(f.reader.paths.where(f.foreignObjects.contains), isEmpty);
          expect(
            f.reader.paths.where((path) => path.startsWith('maps/')),
            isEmpty,
          );
          expect(f.queries.diagnostics.liveSessions, 0);
          expect(f.queries.diagnostics.closeCount, 0);
          expect(
            project
                .characters
                .first
                .animations
                .single
                .presentationReferenceHeightPx,
            mode == 'clear' ? null : 32,
          );
          final independent = AuthoringQueryAdapter(
            fileReader: const EditorProjectFileReader(),
          );
          try {
            final durable = await independent.open(f.root.path);
            expect(durable.manifest.characters, project.characters);
          } finally {
            await independent.closeAll();
          }
        }
        expect(
          counts.every((count) => count <= 150),
          isTrue,
          reason: '$counts',
        );
        debugPrint(
          'CLIP_LOCAL catalog=$catalog unrelated=$unrelated reads=$counts ms=$timings',
        );
      },
    );
  }

  test(
    'flat local clip resolves only referenced portrait and custom definitions',
    () async {
      final f = await _Fixture.create(
        2,
        catalog: false,
        withStudioDependencies: true,
      );
      addTearDown(f.dispose);
      final file = File('${f.root.path}/project.json');
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final studio = raw['characterStudioCatalog'] as Map<String, dynamic>;
      (studio['portraitStates'] as List).add({
        'id': 'foreign-state',
        'displayName': 42,
        'foreign': true,
      });
      (studio['customAnimationDefinitions'] as List).add({
        'id': 'foreign-custom',
        'mode': 'future-mode',
        'foreign': true,
      });
      (raw['characters'] as List).add({'id': 'foreign-unreadable', 'name': 42});
      await file.writeAsString(jsonEncode(raw));
      final beforeCatalog = jsonEncode(raw['characterStudioCatalog']);
      f.reader.paths.clear();
      final updated = await f.save(f.project, reference: 32);
      final after =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(jsonEncode(after['characterStudioCatalog']), beforeCatalog);
      expect(
        (after['characters'] as List).last,
        (raw['characters'] as List).last,
      );
      final durable = ProjectCharacterEntry.fromJson(
        Map<String, dynamic>.from(
          (after['characters'] as List).singleWhere(
                (row) => row['id'] == 'hero',
              )
              as Map,
        ),
      );
      expect(durable, updated.characters.first);
      expect(durable.portraits, f.project.characters.first.portraits);
      expect(
        durable.customAnimations,
        f.project.characters.first.customAnimations,
      );
      expect(durable.animations.single.presentationReferenceHeightPx, 32);
      expect(f.reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
      expect(f.queries.diagnostics.liveSessions, 0);
    },
  );

  test(
    'stale selected character is rejected before changing catalog HEAD',
    () async {
      final f = await _Fixture.create(2);
      addTearDown(f.dispose);
      final updated = await f.save(f.project, reference: 32);
      final head = await File('${f.root.path}/catalog/HEAD.json').readAsBytes();
      await expectLater(
        f.save(f.project, reference: 24),
        throwsA(isA<EditorConflictException>()),
      );
      expect(
        await File('${f.root.path}/catalog/HEAD.json').readAsBytes(),
        head,
      );
      expect(
        updated
            .characters
            .first
            .animations
            .single
            .presentationReferenceHeightPx,
        32,
      );
    },
  );

  test(
    'unrelated stale draft does not block or overwrite a local clip save',
    () async {
      final f = await _Fixture.create(2);
      addTearDown(f.dispose);
      final stale = f.project.copyWith(name: 'Stale editor name');
      final updated = await f.save(stale, reference: 32);
      expect(updated.name, 'Stale editor name');
      final independent = AuthoringQueryAdapter(
        fileReader: const EditorProjectFileReader(),
      );
      try {
        final durable = await independent.open(f.root.path);
        expect(durable.manifest.name, f.project.name);
        expect(durable.manifest.characters, updated.characters);
      } finally {
        await independent.closeAll();
      }
    },
  );
}

final class _Fixture {
  _Fixture(
    this.root,
    this.project,
    this.reader,
    this.queries,
    this.mutations,
    this.gateway,
    this.foreignObjects,
  );
  final Directory root;
  final ProjectManifest project;
  final _Reader reader;
  final AuthoringQueryAdapter queries;
  final AuthoringMutationAdapter mutations;
  final CanonicalCharacterStudioAuthoringGateway gateway;
  final Set<String> foreignObjects;

  static Future<_Fixture> create(
    int unrelated, {
    bool catalog = true,
    bool withStudioDependencies = false,
  }) async {
    final root = await Directory.systemTemp.createTemp('c702_local_clip_');
    var project = ProjectManifest(
      name: 'Local clip',
      maps: [
        for (var i = 0; i < unrelated; i++)
          ProjectMapEntry(
            id: 'foreign-$i',
            name: 'Foreign $i',
            relativePath: 'maps/foreign-$i.json',
          ),
      ],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'characters',
          name: 'Characters',
          relativePath: 'assets/characters.png',
        ),
      ],
      characters: [
        const ProjectCharacterEntry(
          id: 'hero',
          name: 'Hero',
          tilesetId: 'characters',
        ),
        for (var i = 0; i < unrelated; i++)
          ProjectCharacterEntry(
            id: 'foreign-$i',
            name: 'Foreign $i',
            tilesetId: 'characters',
          ),
      ],
    );
    if (withStudioDependencies) {
      project = project.copyWith(
        characterStudioCatalog: const ProjectCharacterStudioCatalog(
          portraitStates: [
            CharacterPortraitStateDefinition(
              id: 'neutral',
              displayName: 'Neutral',
            ),
          ],
          customAnimationDefinitions: [
            CharacterCustomAnimationDefinition(
              id: 'jump',
              displayName: 'Jump',
              mode: CharacterCustomAnimationMode.single,
            ),
          ],
        ),
        characters: [
          project.characters.first.copyWith(
            portraits: const [
              CharacterPortraitVariant(
                portraitStateId: 'neutral',
                assetId: 'hero-portrait',
              ),
            ],
            customAnimations: const [
              CharacterCustomAnimationClip(
                definitionId: 'jump',
                sourceAssetId: 'jump-source',
                frames: [
                  CharacterAnimationFrame(
                    source: TilesetSourceRect(
                      x: 0,
                      y: 0,
                      width: 16,
                      height: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ...project.characters.skip(1),
        ],
      );
    }
    final store = catalog
        ? await CatalogStorageStore.open(projectRoot: root.path)
        : null;
    if (store != null) {
      await WorkingProjectCatalog.create(
        store: store,
        projectId: 'local-clip',
        project: project,
      );
    } else {
      await File(
        '${root.path}/project.json',
      ).writeAsString(jsonEncode(project.toJson()));
    }
    final foreignObjects = <String>{};
    for (var i = 0; i < unrelated; i++) {
      final map = File('${root.path}/maps/foreign-$i.json');
      await map.parent.create(recursive: true);
      await map.writeAsString(
        jsonEncode(
          MapData(
            id: 'foreign-$i',
            name: 'Foreign $i',
            size: const GridSize(width: 4, height: 4),
          ).toJson(),
        ),
      );
    }
    final reader = _Reader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: reader,
    );
    final gateway = CanonicalCharacterStudioAuthoringGateway(
      mutations: mutations,
      queries: queries,
    );
    if (store != null && unrelated > 0) {
      for (var i = 0; i < 12; i++) {
        project = await gateway.apply(
          projectRootPath: root.path,
          expectedProject: project,
          actionId: 'characterStudio.animationClip.upsert',
          operationLabel: 'foreign_history_$i',
          parameters: {
            'characterId': 'foreign-0',
            'kind': 'system',
            'state': 'idle',
            'direction': 'south',
            'sourceAssetId': 'foreign-source',
            'frames': [
              {
                'source': {'x': 0, 'y': 0, 'width': 16, 'height': 32},
                'durationMs': 100 + i,
              },
            ],
          },
        );
      }
      final published = await store.openRoot((await store.readHead())!);
      for (var i = 0; i < unrelated; i++) {
        final entry = (await published.snapshot.indexEntry(
          CatalogDefinitionKey(CatalogDefinitionKind.character, 'foreign-$i'),
        ))!;
        foreignObjects.add('catalog/objects/${entry.reference.sha256}.json');
      }
    }
    return _Fixture(
      root,
      project,
      reader,
      queries,
      mutations,
      gateway,
      foreignObjects,
    );
  }

  Future<ProjectManifest> save(
    ProjectManifest draft, {
    int? reference,
    bool clear = false,
    bool loop = true,
  }) => SaveCharacterAnimationClipUseCase(gateway).execute(
    ProjectFileSystem(root.path),
    draft,
    characterId: 'hero',
    slotKey: const CharacterAnimationSlotKey.system(
      state: CharacterAnimationState.surfIdle,
      direction: EntityFacing.south,
    ),
    sourceAssetId: 'surf-source',
    frames: const [
      CharacterAnimationFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 56),
      ),
    ],
    loop: loop,
    presentationReferenceHeightPx: reference,
    clearPresentationReferenceHeight: clear,
  );

  Future<void> dispose() async {
    await mutations.closeAll();
    await queries.closeAll();
    await root.delete(recursive: true);
  }
}

final class _Reader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectSnapshotCacheIdentityReader,
        ProjectDirectoryReader,
        ProjectResourceProbeReader,
        EditorProjectRootLocator {
  static const delegate = EditorProjectFileReader();
  final paths = <String>[];
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  bool get supportsStreamingResources => true;
  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.openRead(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<ProjectResourceIdentity?> readIdentity({
    required String projectRoot,
    required String relativePath,
  }) => delegate.readIdentity(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );
  @override
  Future<List<String>> listFiles({
    required String projectRoot,
    required String relativeDirectory,
  }) => delegate.listFiles(
    projectRoot: projectRoot,
    relativeDirectory: relativeDirectory,
  );
  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) => delegate.probeResource(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );
  @override
  Future<String> locateForResource(String resourcePath) =>
      delegate.locateForResource(resourcePath);
}
