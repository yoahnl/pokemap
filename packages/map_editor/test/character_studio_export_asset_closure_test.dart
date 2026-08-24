import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/character_studio/application/character_studio_media_resolver.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'export closes portable Character Studio assets and drops orphan blobs',
    () async {
      final source = await Directory.systemTemp.createTemp(
        'chs-export-source-',
      );
      final moved = await Directory.systemTemp.createTemp('chs-export-moved-');
      addTearDown(() async {
        if (await source.exists()) await source.delete(recursive: true);
        if (await moved.exists()) await moved.delete(recursive: true);
      });

      final sharedBytes = utf8.encode('shared-png-bytes');
      final walkBytes = utf8.encode('walk-png-bytes');
      final orphanBytes = utf8.encode('orphan-png-bytes');
      final shared = ContentArtifactRef.fromBytes(
        sharedBytes,
        mediaType: 'image/png',
      );
      final walk = ContentArtifactRef.fromBytes(
        walkBytes,
        mediaType: 'image/png',
      );
      final orphan = ContentArtifactRef.fromBytes(
        orphanBytes,
        mediaType: 'image/png',
      );
      final catalog = AssetCatalog(
        records: [
          AssetRecord(
            id: 'elia-surprise',
            logicalPath: 'assets/characters/elia/surprise.png',
            artifact: shared,
          ),
          AssetRecord(
            id: 'elia-walk',
            logicalPath: 'assets/characters/elia/walk.png',
            artifact: walk,
          ),
          AssetRecord(
            id: 'elia-saluer',
            logicalPath: 'assets/characters/elia/saluer.png',
            artifact: shared,
          ),
        ],
      );
      final manifest = ProjectManifest(
        name: 'Character Studio export',
        version: ProjectVersion.v6,
        maps: const [],
        tilesets: const [],
        characterStudioCatalog: const ProjectCharacterStudioCatalog(
          portraitStates: [
            CharacterPortraitStateDefinition(
              id: 'surprise',
              displayName: 'Surprise',
            ),
          ],
          customAnimationDefinitions: [
            CharacterCustomAnimationDefinition(
              id: 'saluer',
              displayName: 'Saluer',
              mode: CharacterCustomAnimationMode.directional,
            ),
          ],
        ),
        characters: const [
          ProjectCharacterEntry(
            id: 'elia',
            name: 'Élia',
            tilesetId: 'elia-base',
            portraits: [
              CharacterPortraitVariant(
                portraitStateId: 'surprise',
                assetId: 'elia-surprise',
              ),
            ],
            animations: [
              CharacterAnimation(
                state: CharacterAnimationState.walk,
                direction: EntityFacing.south,
                sourceAssetId: 'elia-walk',
              ),
            ],
            customAnimations: [
              CharacterCustomAnimationClip(
                definitionId: 'saluer',
                direction: EntityFacing.south,
                sourceAssetId: 'elia-saluer',
              ),
            ],
          ),
        ],
      );

      await _writeJson(
        File(p.join(source.path, 'project.json')),
        manifest.toJson(),
      );
      await _writeJson(
        File(p.join(source.path, assetCatalogStorageKey)),
        catalog.toJson(),
      );
      await _writeBlob(source, shared, sharedBytes);
      await _writeBlob(source, walk, walkBytes);
      await _writeBlob(source, orphan, orphanBytes);

      final projection = await const RuntimeProjectProjectionBuilder().build(
        projectRoot: source,
        profile: GamePackageExportProfile(
          gameId: 'games.pokemap.characterstudioexport',
          gameVersion: '1.0.0',
          title: 'Character Studio export',
          authorName: 'PokeMap',
          defaultLocale: 'fr',
          supportedLocales: const ['fr'],
        ),
      );

      expect(
        projection.payloadFiles,
        contains('project/$assetCatalogStorageKey'),
      );
      expect(
        projection.payloadFiles,
        contains('project/${assetBlobStorageKey(shared)}'),
      );
      expect(
        projection.payloadFiles,
        contains('project/${assetBlobStorageKey(walk)}'),
      );
      expect(
        projection.payloadFiles,
        isNot(contains('project/${assetBlobStorageKey(orphan)}')),
      );
      expect(
        projection.payloadFiles.keys
            .where((path) => path.endsWith('.blob'))
            .length,
        2,
      );

      for (final entry in projection.payloadFiles.entries) {
        if (!entry.key.startsWith('project/')) continue;
        final target = File(
          p.join(moved.path, entry.key.substring('project/'.length)),
        );
        await target.parent.create(recursive: true);
        await target.writeAsBytes(entry.value, flush: true);
      }
      final resolver = CharacterStudioMediaResolver(
        source: const FileCharacterStudioMediaSource(),
      );
      for (final entry in const {
        'elia-surprise': 'shared-png-bytes',
        'elia-walk': 'walk-png-bytes',
        'elia-saluer': 'shared-png-bytes',
      }.entries) {
        expect(
          utf8.decode(
            await resolver.resolve(
              CharacterStudioMediaRequest(
                projectRootPath: moved.path,
                assetId: entry.key,
                projectRevision: 'exported-v1',
              ),
            ),
          ),
          entry.value,
        );
      }
      expect(
        utf8.decode(projection.payloadFiles['project/project.json']!),
        isNot(contains(source.path)),
      );
    },
  );

  test(
    'export identifies the missing portable asset by logical path',
    () async {
      final source = await Directory.systemTemp.createTemp(
        'chs-export-missing-',
      );
      addTearDown(() async {
        if (await source.exists()) await source.delete(recursive: true);
      });

      final missing = ContentArtifactRef.fromBytes(
        utf8.encode('missing-png-bytes'),
        mediaType: 'image/png',
      );
      await _writeJson(
        File(p.join(source.path, 'project.json')),
        ProjectManifest(
          name: 'Character Studio missing asset',
          version: ProjectVersion.v6,
          maps: const [],
          tilesets: const [],
        ).toJson(),
      );
      await _writeJson(
        File(p.join(source.path, assetCatalogStorageKey)),
        AssetCatalog(
          records: [
            AssetRecord(
              id: 'elia-surprise',
              logicalPath: 'assets/characters/elia/surprise.png',
              artifact: missing,
            ),
          ],
        ).toJson(),
      );

      expect(
        () => const RuntimeProjectProjectionBuilder().build(
          projectRoot: source,
          profile: GamePackageExportProfile(
            gameId: 'games.pokemap.characterstudioexportmissing',
            gameVersion: '1.0.0',
            title: 'Character Studio missing asset',
            authorName: 'PokeMap',
            defaultLocale: 'fr',
            supportedLocales: const ['fr'],
          ),
        ),
        throwsA(
          isA<GamePackageExportException>()
              .having((error) => error.code, 'code', 'missingProjectFile')
              .having(
                (error) => error.path,
                'path',
                'assets/characters/elia/surprise.png',
              ),
        ),
      );
    },
  );
}

Future<void> _writeJson(File file, Object value) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(value), flush: true);
}

Future<void> _writeBlob(
  Directory root,
  ContentArtifactRef artifact,
  List<int> bytes,
) async {
  final file = File(p.join(root.path, assetBlobStorageKey(artifact)));
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
}
