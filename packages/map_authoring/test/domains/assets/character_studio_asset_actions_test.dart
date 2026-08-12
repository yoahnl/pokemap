import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Character Studio asset actions', () {
    test('imports one portable inspected PNG asset', () async {
      final store = MemoryArtifactStore(maximumArtifactBytes: 1024);
      final staged = await store.put(
        _png(width: 96, height: 128),
        declaredMediaType: 'image/png',
      );
      final actions = CharacterStudioAssetActions(artifactStore: store);

      final draft = await actions.build(
        _context(
          snapshot: _snapshot(),
          actionId: 'characterStudio.asset.import',
          parameters: <String, Object?>{
            'artifactHandle': staged.reference.handle,
            'assetId': 'elia-neutral',
            'logicalPath': 'assets/characters/elia/neutral.png',
            'mediaKind': 'portrait',
          },
        ),
      );

      expect(draft.preview['width'], 96);
      expect(draft.preview['height'], 128);
      expect(draft.preview['sourceRect'], <String, Object?>{
        'x': 0,
        'y': 0,
        'width': 96,
        'height': 128,
      });
      expect(draft.preview['orphanedBlobDeleted'], isFalse);
      expect(
        draft.changeSet.changes.every(
          (change) =>
              !change.storageKey.startsWith('/') &&
              !change.storageKey.contains('/Users/'),
        ),
        isTrue,
      );
      final catalog = _catalogAfter(draft);
      final record = catalog.require('elia-neutral');
      expect(record.logicalPath, 'assets/characters/elia/neutral.png');
      expect(
        record.tags,
        containsAll(<String>['character-studio', 'character-studio:portrait']),
      );
      expect(
        AuthoringMutationDispatcher.canonical(artifactStore: store)
            .descriptors
            .map((descriptor) => descriptor.id),
        contains('characterStudio.asset.import'),
      );
    });

    test('imports and binds a portrait in one atomic draft', () async {
      final store = MemoryArtifactStore(maximumArtifactBytes: 1024);
      final staged = await store.put(
        _png(width: 96, height: 128),
        declaredMediaType: 'image/png',
      );

      final draft = await CharacterStudioAssetActions(
        artifactStore: store,
      ).build(
        _context(
          snapshot: _snapshot(withCharacterStudio: true),
          actionId: 'characterStudio.asset.import',
          parameters: <String, Object?>{
            'artifactHandle': staged.reference.handle,
            'assetId': 'elia-neutral',
            'logicalPath': 'assets/characters/elia/neutral.png',
            'mediaKind': 'portrait',
            'binding': <String, Object?>{
              'kind': 'portrait',
              'characterId': 'elia',
              'portraitStateId': 'neutral',
              'fitMode': 'cover',
            },
          },
        ),
      );

      expect(
        draft.changeSet.changes.map((change) => change.resource.kind),
        containsAll(<String>['project', 'assetCatalog', 'assetBlob']),
      );
      expect(draft.preview['bindingKind'], 'portrait');
      final project = _projectAfter(draft);
      expect(
          project.characters.single.portraits.single.assetId, 'elia-neutral');
      expect(
        project.characters.single.portraits.single.fitMode,
        CharacterPortraitFitMode.cover,
      );
    });

    test('replaces and binds an animation while closing its old blob',
        () async {
      final oldBytes = _png(width: 64, height: 64, marker: 1);
      final newBytes = _png(width: 96, height: 64, marker: 2);
      final oldArtifact = ContentArtifactRef.fromBytes(
        oldBytes,
        mediaType: 'image/png',
      );
      final store = MemoryArtifactStore(maximumArtifactBytes: 1024);
      final staged = await store.put(newBytes, declaredMediaType: 'image/png');
      final snapshot = _snapshot(
        withCharacterStudio: true,
        animationSourceAssetId: 'elia-idle-north',
        catalog: AssetCatalog(
          records: <AssetRecord>[
            AssetRecord(
              id: 'elia-idle-north',
              logicalPath: 'assets/characters/elia/idle-north.png',
              artifact: oldArtifact,
              tags: const <String>[
                'character-studio',
                'character-studio:spriteSheet',
              ],
            ),
          ],
        ),
        blobs: <ContentArtifactRef, List<int>>{oldArtifact: oldBytes},
      );

      final draft = await CharacterStudioAssetActions(
        artifactStore: store,
      ).build(
        _context(
          snapshot: snapshot,
          actionId: 'characterStudio.asset.replace',
          parameters: <String, Object?>{
            'artifactHandle': staged.reference.handle,
            'assetId': 'elia-idle-north',
            'binding': <String, Object?>{
              'kind': 'animationClip',
              'characterId': 'elia',
              'slotKind': 'system',
              'state': 'idle',
              'direction': 'north',
              'frames': <Object?>[],
              'loop': false,
            },
          },
        ),
      );

      expect(draft.preview['bindingKind'], 'animationClip');
      expect(draft.preview['orphanedBlobDeleted'], isTrue);
      expect(
        draft.changeSet.changes.where((change) => change.afterBytes == null),
        hasLength(1),
      );
      final animation =
          _projectAfter(draft).characters.single.animations.single;
      expect(animation.sourceAssetId, 'elia-idle-north');
      expect(animation.frames, isEmpty);
      expect(animation.loop, isFalse);
    });

    test('rejects a bound replacement when another slot shares the asset',
        () async {
      final oldBytes = _png(width: 64, height: 64, marker: 1);
      final newBytes = _png(width: 96, height: 64, marker: 2);
      final oldArtifact = ContentArtifactRef.fromBytes(
        oldBytes,
        mediaType: 'image/png',
      );
      final store = MemoryArtifactStore(maximumArtifactBytes: 1024);
      final staged = await store.put(newBytes, declaredMediaType: 'image/png');

      await expectLater(
        CharacterStudioAssetActions(artifactStore: store).build(
          _context(
            snapshot: _snapshot(
              withCharacterStudio: true,
              animationSourceAssetId: 'elia-idle-north',
              sharedAnimationSource: true,
              catalog: AssetCatalog(
                records: <AssetRecord>[
                  AssetRecord(
                    id: 'elia-idle-north',
                    logicalPath: 'assets/characters/elia/idle-north.png',
                    artifact: oldArtifact,
                    tags: const <String>[
                      'character-studio',
                      'character-studio:spriteSheet',
                    ],
                  ),
                ],
              ),
              blobs: <ContentArtifactRef, List<int>>{oldArtifact: oldBytes},
            ),
            actionId: 'characterStudio.asset.replace',
            parameters: <String, Object?>{
              'artifactHandle': staged.reference.handle,
              'assetId': 'elia-idle-north',
              'binding': <String, Object?>{
                'kind': 'animationClip',
                'characterId': 'elia',
                'slotKind': 'system',
                'state': 'idle',
                'direction': 'north',
                'frames': <Object?>[],
                'loop': true,
              },
            },
          ),
        ),
        throwsA(
          isA<CharacterStudioAssetException>().having(
            (error) => error.code,
            'code',
            'character_studio.asset.binding_asset_shared',
          ),
        ),
      );
    });

    test('rejects non-PNG bytes and out-of-bounds source rectangles', () async {
      final store = MemoryArtifactStore(maximumArtifactBytes: 1024);
      final text = await store.put(
        utf8.encode('not a png'),
        declaredMediaType: 'text/plain',
      );
      final malformed = await store.put(
        List<int>.filled(24, 0),
        declaredMediaType: 'application/octet-stream',
      );
      final png = await store.put(
        _png(width: 32, height: 48),
        declaredMediaType: 'image/png',
      );
      final actions = CharacterStudioAssetActions(artifactStore: store);

      await expectLater(
        actions.build(
          _context(
            snapshot: _snapshot(),
            actionId: 'characterStudio.asset.import',
            parameters: <String, Object?>{
              'artifactHandle': text.reference.handle,
              'assetId': 'invalid',
              'logicalPath': 'assets/characters/invalid.png',
              'mediaKind': 'portrait',
            },
          ),
        ),
        throwsA(
          isA<CharacterStudioAssetException>().having(
            (error) => error.code,
            'code',
            'character_studio.asset.png_required',
          ),
        ),
      );
      await expectLater(
        actions.build(
          _context(
            snapshot: _snapshot(),
            actionId: 'characterStudio.asset.import',
            parameters: <String, Object?>{
              'artifactHandle': malformed.reference.handle,
              'assetId': 'malformed',
              'logicalPath': 'assets/characters/malformed.png',
              'mediaKind': 'portrait',
            },
          ),
        ),
        throwsA(
          isA<CharacterStudioAssetException>().having(
            (error) => error.code,
            'code',
            'character_studio.asset.png_required',
          ),
        ),
      );
      await expectLater(
        actions.build(
          _context(
            snapshot: _snapshot(),
            actionId: 'characterStudio.asset.import',
            parameters: <String, Object?>{
              'artifactHandle': png.reference.handle,
              'assetId': 'invalid-rect',
              'logicalPath': 'assets/characters/invalid-rect.png',
              'mediaKind': 'spriteSheet',
              'sourceRect': <String, Object?>{
                'x': 16,
                'y': 0,
                'width': 32,
                'height': 48,
              },
            },
          ),
        ),
        throwsA(
          isA<CharacterStudioAssetException>().having(
            (error) => error.code,
            'code',
            'character_studio.asset.source_rect_out_of_bounds',
          ),
        ),
      );
    });

    test('deduplicates imported bytes already owned by another asset',
        () async {
      final bytes = _png(width: 64, height: 64);
      final artifact = ContentArtifactRef.fromBytes(
        bytes,
        mediaType: 'image/png',
      );
      final store = MemoryArtifactStore(maximumArtifactBytes: 1024);
      final staged = await store.put(bytes, declaredMediaType: 'image/png');
      final snapshot = _snapshot(
        catalog: AssetCatalog(
          records: <AssetRecord>[
            AssetRecord(
              id: 'existing',
              logicalPath: 'assets/characters/existing.png',
              artifact: artifact,
            ),
          ],
        ),
        blobs: <ContentArtifactRef, List<int>>{artifact: bytes},
      );

      final draft =
          await CharacterStudioAssetActions(artifactStore: store).build(
        _context(
          snapshot: snapshot,
          actionId: 'characterStudio.asset.import',
          parameters: <String, Object?>{
            'artifactHandle': staged.reference.handle,
            'assetId': 'shared-copy',
            'logicalPath': 'assets/characters/shared-copy.png',
            'mediaKind': 'portrait',
          },
        ),
      );

      expect(draft.preview['deduplicated'], isTrue);
      expect(draft.changeSet.changes, hasLength(1));
    });

    test('replacement deletes an orphaned previous blob transactionally',
        () async {
      final oldBytes = _png(width: 64, height: 64, marker: 1);
      final newBytes = _png(width: 128, height: 96, marker: 2);
      final oldArtifact = ContentArtifactRef.fromBytes(
        oldBytes,
        mediaType: 'image/png',
      );
      final store = MemoryArtifactStore(maximumArtifactBytes: 1024);
      final staged = await store.put(newBytes, declaredMediaType: 'image/png');
      final snapshot = _snapshot(
        catalog: AssetCatalog(
          records: <AssetRecord>[
            AssetRecord(
              id: 'elia-neutral',
              logicalPath: 'assets/characters/elia/neutral.png',
              artifact: oldArtifact,
              tags: const <String>['character-studio'],
            ),
          ],
        ),
        blobs: <ContentArtifactRef, List<int>>{oldArtifact: oldBytes},
      );

      final draft =
          await CharacterStudioAssetActions(artifactStore: store).build(
        _context(
          snapshot: snapshot,
          actionId: 'characterStudio.asset.replace',
          parameters: <String, Object?>{
            'artifactHandle': staged.reference.handle,
            'assetId': 'elia-neutral',
          },
        ),
      );

      expect(draft.preview['width'], 128);
      expect(draft.preview['height'], 96);
      expect(draft.preview['orphanedBlobDeleted'], isTrue);
      expect(draft.changeSet.changes, hasLength(3));
      final deleted = draft.changeSet.changes.singleWhere(
        (change) => change.afterBytes == null,
      );
      expect(deleted.beforeBytes, oldBytes);
    });

    test('replacement preserves a previous blob shared by another asset',
        () async {
      final oldBytes = _png(width: 64, height: 64, marker: 1);
      final newBytes = _png(width: 64, height: 64, marker: 2);
      final oldArtifact = ContentArtifactRef.fromBytes(
        oldBytes,
        mediaType: 'image/png',
      );
      final store = MemoryArtifactStore(maximumArtifactBytes: 1024);
      final staged = await store.put(newBytes, declaredMediaType: 'image/png');
      final snapshot = _snapshot(
        catalog: AssetCatalog(
          records: <AssetRecord>[
            AssetRecord(
              id: 'elia-neutral',
              logicalPath: 'assets/characters/elia/neutral.png',
              artifact: oldArtifact,
            ),
            AssetRecord(
              id: 'nox-neutral',
              logicalPath: 'assets/characters/nox/neutral.png',
              artifact: oldArtifact,
            ),
          ],
        ),
        blobs: <ContentArtifactRef, List<int>>{oldArtifact: oldBytes},
      );

      final draft =
          await CharacterStudioAssetActions(artifactStore: store).build(
        _context(
          snapshot: snapshot,
          actionId: 'characterStudio.asset.replace',
          parameters: <String, Object?>{
            'artifactHandle': staged.reference.handle,
            'assetId': 'elia-neutral',
          },
        ),
      );

      expect(draft.preview['orphanedBlobDeleted'], isFalse);
      expect(draft.changeSet.changes, hasLength(2));
      expect(
          draft.changeSet.changes.every((change) => change.afterBytes != null),
          isTrue);
    });

    test('filesystem staging rejects missing and unauthorized sources',
        () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'character_studio_asset_staging_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final allowed = await Directory('${sandbox.path}/allowed').create();
      final outside = File('${sandbox.path}/outside.png');
      await outside.writeAsBytes(_png(width: 16, height: 16));
      final store = LocalArtifactStore(
        allowedSourceRoots: <String>[allowed.path],
        maximumArtifactBytes: 1024,
      );

      await expectLater(
        store.importFile(outside.path),
        throwsA(
          isA<ArtifactStoreException>().having(
            (error) => error.code,
            'code',
            'artifact.source_outside_allowed_roots',
          ),
        ),
      );
      await expectLater(
        store.importFile('${allowed.path}/missing.png'),
        throwsA(
          isA<ArtifactStoreException>().having(
            (error) => error.code,
            'code',
            'artifact.source_unavailable',
          ),
        ),
      );
    });
  });
}

AuthoringPlanningContext _context({
  required ProjectSnapshot snapshot,
  required String actionId,
  required Map<String, Object?> parameters,
}) {
  return AuthoringPlanningContext(
    snapshot: snapshot,
    request: AuthoringRequest(
      requestId: 'request-character-studio-asset',
      actionId: actionId,
      actionVersion: 1,
      workspaceHandle: 'workspace-character-studio',
      parameters: parameters,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'idem-character-studio-asset',
    ),
    planId: 'plan-character-studio-asset',
    seed: 1,
  );
}

ProjectSnapshot _snapshot({
  AssetCatalog? catalog,
  bool withCharacterStudio = false,
  String? animationSourceAssetId,
  bool sharedAnimationSource = false,
  Map<ContentArtifactRef, List<int>> blobs =
      const <ContentArtifactRef, List<int>>{},
}) {
  final manifest = ProjectManifest(
    name: 'Character asset fixture',
    maps: const <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[
      if (withCharacterStudio)
        const ProjectTilesetEntry(
          id: 'elia',
          name: 'Élia',
          relativePath: 'elia.png',
        ),
    ],
    characterStudioCatalog: ProjectCharacterStudioCatalog(
      portraitStates: <CharacterPortraitStateDefinition>[
        if (withCharacterStudio)
          const CharacterPortraitStateDefinition(
            id: 'neutral',
            displayName: 'Neutre',
          ),
      ],
    ),
    characters: <ProjectCharacterEntry>[
      if (withCharacterStudio)
        ProjectCharacterEntry(
          id: 'elia',
          name: 'Élia',
          tilesetId: 'elia',
          animations: <CharacterAnimation>[
            if (animationSourceAssetId != null)
              CharacterAnimation(
                state: CharacterAnimationState.idle,
                direction: EntityFacing.north,
                sourceAssetId: animationSourceAssetId,
                frames: const <CharacterAnimationFrame>[
                  CharacterAnimationFrame(
                    source: TilesetSourceRect(x: 0, y: 0),
                  ),
                ],
              ),
            if (sharedAnimationSource)
              CharacterAnimation(
                state: CharacterAnimationState.walk,
                direction: EntityFacing.south,
                sourceAssetId: animationSourceAssetId,
              ),
          ],
        ),
    ],
  );
  final projectBytes = utf8.encode(jsonEncode(manifest.toJson()));
  final fingerprints = <String, String>{
    'project': computeAuthoringBytesFingerprint(
      projectBytes,
      logicalName: 'project.json',
    ),
  };
  final resourceBytes = <String, List<int>>{'project': projectBytes};
  final storageKeys = <String, String>{'project': 'project.json'};
  if (catalog != null) {
    final bytes = utf8.encode(
      '${const JsonEncoder.withIndent('  ').convert(catalog.toJson())}\n',
    );
    fingerprints[assetCatalogResourceIdentity] =
        computeAuthoringBytesFingerprint(
      bytes,
      logicalName: assetCatalogStorageKey,
    );
    resourceBytes[assetCatalogResourceIdentity] = bytes;
    storageKeys[assetCatalogResourceIdentity] = assetCatalogStorageKey;
  }
  for (final entry in blobs.entries) {
    final identity = assetBlobResourceIdentity(entry.key.digest);
    final storageKey = assetBlobStorageKey(entry.key);
    fingerprints[identity] = computeAuthoringBytesFingerprint(
      entry.value,
      logicalName: storageKey,
    );
    resourceBytes[identity] = entry.value;
    storageKeys[identity] = storageKey;
  }
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('character_asset_project'),
    revision:
        'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
    manifest: manifest,
    maps: const <MapData>[],
    resourceFingerprints: fingerprints,
    resourceBytes: resourceBytes,
    resourceStorageKeys: storageKeys,
  );
}

ProjectManifest _projectAfter(AuthoringMutationDraft draft) {
  final bytes = draft.changeSet.changes
      .singleWhere((change) => change.resource.kind == 'project')
      .afterBytes!;
  return ProjectManifest.fromJson(
    Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
  );
}

AssetCatalog _catalogAfter(AuthoringMutationDraft draft) {
  final bytes = draft.changeSet.changes
      .singleWhere(
        (change) => change.resource.kind == 'assetCatalog',
      )
      .afterBytes!;
  return AssetCatalog.fromJson(
    Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
  );
}

List<int> _png({
  required int width,
  required int height,
  int marker = 0,
}) {
  List<int> integer(int value) => <int>[
        (value >> 24) & 0xff,
        (value >> 16) & 0xff,
        (value >> 8) & 0xff,
        value & 0xff,
      ];
  return <int>[
    0x89,
    0x50,
    0x4e,
    0x47,
    0x0d,
    0x0a,
    0x1a,
    0x0a,
    0x00,
    0x00,
    0x00,
    0x0d,
    0x49,
    0x48,
    0x44,
    0x52,
    ...integer(width),
    ...integer(height),
    marker,
  ];
}
