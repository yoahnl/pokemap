import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/src/infrastructure/local_resource_pack_store.dart';
import 'package:map_authoring/src/ports/file_backed_payload_store.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';
import '../../support/glb_fixture.dart';

void main() {
  test('portable terrain keeps preset-local rule candidate and fallback identities', () async {
    final base = originalManifest();
    final first = base.smartTileCatalog.presets.single;
    final second = first.copyWith(id: 'second', name: 'Second');
    final manifest = base.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        atlases: base.smartTileCatalog.atlases,
        materials: base.smartTileCatalog.materials,
        presets: [first, second],
      ),
    );
    final projection = await projectFixture(
      manifest,
      [nativeImage()],
      roots: [
        NativeResourcePackRef(
          kind: ResourcePackKind.smartTilePreset,
          id: first.id,
        ),
        NativeResourcePackRef(
          kind: ResourcePackKind.smartTilePreset,
          id: second.id,
        ),
      ],
    );
    final presets = projection.catalog.smartTileCatalog.presets;
    expect(presets.map((p) => p.id).toSet(), hasLength(2));
    for (final preset in presets) {
      expect(preset.rules.single.id, 'all');
      expect(preset.rules.single.candidates.single.id, 'one');
      expect(preset.fallbackRuleId, 'all');
      expect(
        preset.rules.single.candidates.single.parts.single.source,
        SmartTileVisualSource.frame(
          frame: SmartTileFrameRef(
            atlasId: projection.catalog.smartTileCatalog.atlases.single.id,
            column: 0,
            row: 0,
          ),
        ),
      );
    }
    expect(
      projection.catalog.smartTileCatalog.materials.single.connectionGroupId,
      isNot('g'),
    );
    expect(base.smartTileCatalog.presets.single, first);
  });
  test(
      'native preparation pins snapshots without copying bytes and builds after owner release and expiry',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('p11-prepared-export-');
    var now = DateTime.utc(2026, 10, 17);
    final store = LocalResourcePackStore(
        cacheDirectory: '${directory.path}/cache',
        allowedSourceRoots: [],
        clock: () => now);
    const scope =
        FileBackedPayloadScope(sessionId: 'native', projectId: 'project');
    final image = nativeImage();
    final media = await store.stage(
        scope: scope,
        chunks: image.openRead(),
        byteLength: image.byteLength,
        expectedRawSha256: image.rawSha256);
    final docs = <FileBackedPayloadLease>[];
    for (final text in ['First licence', 'Second licence']) {
      final bytes = utf8.encode(text);
      docs.add(await store.stage(
          scope: scope, chunks: Stream.value(bytes), byteLength: bytes.length));
    }
    final cachedBefore = store.cachedBytes;
    final service =
        CanonicalResourcePackExportService(store: store, scope: scope);
    NativeResourcePackPreparedExport? prepared;
    OwnedResourcePackExport? artifact;
    try {
      final roots = [
        NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas')
      ];
      final patterns = <String>[];
      final files = [
        (image.id, image.logicalPath, media.payload, image.mediaType)
      ];
      final documents = docs.map((lease) => lease.payload).toList();
      final preparation = service.prepareNative(
        manifest: originalManifest(),
        roots: roots,
        smartTilePatternIds: patterns,
        files: files,
        licenseDocuments: documents,
        metadata: metadata(),
        author: 'Original',
        expectedRevision: 'revision',
        readCurrentRevision: () async => 'revision',
      );
      roots.clear();
      patterns.add('changed-after-preparation');
      files.clear();
      documents.clear();
      prepared = await preparation;
      expect(prepared.catalog.tilesets, hasLength(1));
      expect(store.cachedBytes, cachedBefore);
      final fingerprint = prepared.projectionFingerprint;
      expect(() => prepared!.sourceInventory.clear(), throwsUnsupportedError);
      expect(() => prepared!.nativeMappings.clear(), throwsUnsupportedError);
      expect(() => prepared!.nativeSourceIds.clear(), throwsUnsupportedError);
      for (final lease in [media, ...docs]) {
        await store.release(scope: scope, leaseId: lease.leaseId);
      }
      now = now.add(const Duration(days: 2));
      await store.collectExpired();
      expect(store.cachedBytes, cachedBefore);
      artifact = await service.exportPrepared(
          prepared: prepared, readCurrentRevision: () async => 'revision');
      expect(artifact.inspection.catalog, prepared.catalog);
      expect(artifact.inspection.manifest.pack, prepared.metadata);
      expect(prepared.projectionFingerprint, fingerprint);
      expect(
          artifact.inspection.manifest.content.files
              .where((file) => file.mediaType == 'text/plain'),
          hasLength(2));
      await prepared.dispose();
      now = now.add(const Duration(days: 2));
      await store.collectExpired();
      expect(store.cachedBytes, artifact.payload.byteLength);
    } finally {
      await artifact?.dispose();
      await prepared?.dispose();
      await store.close();
      await directory.delete(recursive: true);
    }
  });

  test(
      'native preparation rolls back earlier pins if a later source is unknown',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('p11-pin-rollback-');
    var now = DateTime.utc(2026, 10, 17);
    final store = LocalResourcePackStore(
        cacheDirectory: '${directory.path}/cache',
        allowedSourceRoots: [],
        clock: () => now);
    const scope =
        FileBackedPayloadScope(sessionId: 'native', projectId: 'project');
    final image = nativeImage();
    final media = await store.stage(
        scope: scope, chunks: image.openRead(), byteLength: image.byteLength);
    try {
      await expectLater(
          CanonicalResourcePackExportService(store: store, scope: scope)
              .prepareNative(
                  manifest: originalManifest(),
                  roots: [
                    NativeResourcePackRef(
                        kind: ResourcePackKind.tileset, id: 'atlas')
                  ],
                  smartTilePatternIds: [],
                  files: [
                    (
                      image.id,
                      image.logicalPath,
                      media.payload,
                      image.mediaType
                    )
                  ],
                  licenseDocuments: [
                    StoredFilePayload(
                        handle: 'unknown', byteLength: 0, rawSha256: '0' * 64)
                  ],
                  metadata: metadata(),
                  author: 'Original',
                  expectedRevision: 'revision',
                  readCurrentRevision: () async => 'revision'),
          throwsA(isA<FileBackedPayloadException>()));
      await store.release(scope: scope, leaseId: media.leaseId);
      now = now.add(const Duration(days: 2));
      await store.collectExpired();
      expect(store.cachedBytes, 0);
    } finally {
      await store.close();
      await directory.delete(recursive: true);
    }
  });

  test(
      'refuses a deduplicated native alias mutated after projection with a stable revision',
      () async {
    final fixture = mixedFixture();
    var mutated = false;
    var aliasReads = 0;
    final files = fixture.$2
        .map((file) => file.id != 'animation'
            ? file
            : NativeResourcePackFile(
                id: file.id,
                logicalPath: file.logicalPath,
                byteLength: file.byteLength,
                rawSha256: file.rawSha256,
                mediaType: file.mediaType,
                openRead: () async* {
                  aliasReads++;
                  await for (final chunk in file.openRead()) {
                    final bytes = List<int>.from(chunk);
                    if (mutated) bytes[0] ^= 1;
                    yield bytes;
                  }
                }))
        .toList();
    final projection = await projectFixture(fixture.$1, files, roots: [
      NativeResourcePackRef(kind: ResourcePackKind.character, id: 'person')
    ]);
    expect(projection.catalog.files, hasLength(3));
    expect(projection.sources, hasLength(1));
    mutated = true;
    await withAliasExportService((service, store) async {
      OwnedResourcePackExport? result;
      try {
        await expectLater(() async {
          result = await service.export(
              acknowledgeOrganizationRemoval: true,
              projection: projection,
              metadata: metadata(),
              expectedRevision: 'revision',
              readCurrentRevision: () async => 'revision');
        },
            throwsA(anyOf(
                isA<FormatException>(), isA<GamePackageFormatException>())));
        expect(aliasReads, greaterThan(0));
        expect(result, isNull);
        expect(store.cachedBytes, 0);
      } finally {
        await result?.dispose();
      }
    });
  });

  test('observes every selected native alias twice while writing one ZIP blob',
      () async {
    final fixture = mixedFixture();
    final reads = <String, int>{};
    const policy = ResourcePackSecurityPolicy(maxChunkBytes: 7);
    final files = fixture.$2
        .map((file) => NativeResourcePackFile(
            id: file.id,
            logicalPath: file.logicalPath,
            byteLength: file.byteLength,
            rawSha256: file.rawSha256,
            mediaType: file.mediaType,
            openRead: () async* {
              reads.update(file.id, (count) => count + 1, ifAbsent: () => 1);
              await for (final chunk in file.openRead()) {
                for (var offset = 0; offset < chunk.length; offset += 7) {
                  yield chunk.sublist(offset,
                      offset + 7 < chunk.length ? offset + 7 : chunk.length);
                }
              }
            }))
        .toList();
    final projection = await ResourcePackProjectionBuilder(policy: policy)
        .project(
            manifest: fixture.$1,
            files: files,
            author: 'Original',
            sourceRevision: 'revision',
            roots: [
          NativeResourcePackRef(kind: ResourcePackKind.character, id: 'person')
        ]);
    await withAliasExportService((service, store) async {
      final result = await service.export(
          acknowledgeOrganizationRemoval: true,
          projection: projection,
          metadata: metadata(),
          expectedRevision: 'revision',
          readCurrentRevision: () async => 'revision');
      try {
        expect(reads, {'animation': 2, 'image': 2, 'portrait': 2});
        expect(result.inspection.catalog.files, hasLength(3));
        expect(
            result.inspection.manifest.content.files
                .where((file) => file.path.startsWith('blobs/')),
            hasLength(1));
        expect(projection.sources, hasLength(1));
      } finally {
        await result.dispose();
      }
    }, policy: policy);
  });

  test('refuses an alias mutated between the builder observations', () async {
    final fixture = mixedFixture();
    final reads = <String, int>{};
    final files = fixture.$2
        .map((file) => NativeResourcePackFile(
            id: file.id,
            logicalPath: file.logicalPath,
            byteLength: file.byteLength,
            rawSha256: file.rawSha256,
            mediaType: file.mediaType,
            openRead: () async* {
              final count = reads.update(file.id, (count) => count + 1,
                  ifAbsent: () => 1);
              await for (final chunk in file.openRead()) {
                final bytes = List<int>.from(chunk);
                if (file.id == 'image' && count == 2) bytes[0] ^= 1;
                yield bytes;
              }
            }))
        .toList();
    final projection = await projectFixture(fixture.$1, files, roots: [
      NativeResourcePackRef(kind: ResourcePackKind.character, id: 'person')
    ]);
    await withAliasExportService((service, store) async {
      OwnedResourcePackExport? result;
      try {
        await expectLater(() async {
          result = await service.export(
              acknowledgeOrganizationRemoval: true,
              projection: projection,
              metadata: metadata(),
              expectedRevision: 'revision',
              readCurrentRevision: () async => 'revision');
        },
            throwsA(anyOf(
                isA<FormatException>(), isA<GamePackageFormatException>())));
        expect(reads['image'], 2);
        expect(reads['animation'], greaterThanOrEqualTo(1));
        expect(reads['portrait'], greaterThanOrEqualTo(1));
        expect(reads.containsKey('glb'), isFalse);
        expect(result, isNull);
        expect(store.cachedBytes, 0);
      } finally {
        await result?.dispose();
      }
    });
  });

  for (final defect in [
    'oversized_chunk',
    'invalid_byte',
    'truncated',
    'excess'
  ]) {
    test('refuses deduplicated aliases with $defect using bounded streams',
        () async {
      final fixture = mixedFixture();
      final files = fixture.$2
          .map((file) => NativeResourcePackFile(
              id: file.id,
              logicalPath: file.logicalPath,
              byteLength: file.byteLength,
              rawSha256: file.rawSha256,
              mediaType: file.mediaType,
              openRead: () async* {
                await for (final chunk in file.openRead()) {
                  final bytes = List<int>.from(chunk);
                  if (file.id == 'image') {
                    if (defect == 'oversized_chunk') {
                      yield bytes;
                      continue;
                    }
                    if (defect == 'invalid_byte') bytes[0] = 256;
                    if (defect == 'truncated') bytes.removeLast();
                    if (defect == 'excess') bytes.add(0);
                  }
                  for (var offset = 0; offset < bytes.length; offset += 7) {
                    yield bytes.sublist(offset,
                        offset + 7 < bytes.length ? offset + 7 : bytes.length);
                  }
                }
              }))
          .toList();
      final policy = ResourcePackSecurityPolicy(maxChunkBytes: 7);
      final projection = await ResourcePackProjectionBuilder(policy: policy)
          .project(
              manifest: fixture.$1,
              files: files,
              author: 'Original',
              sourceRevision: 'revision',
              roots: [
            NativeResourcePackRef(
                kind: ResourcePackKind.character, id: 'person')
          ]);
      await withAliasExportService((service, store) async {
        OwnedResourcePackExport? result;
        try {
          await expectLater(() async {
            result = await service.export(
                acknowledgeOrganizationRemoval: true,
                projection: projection,
                metadata: metadata(),
                expectedRevision: 'revision',
                readCurrentRevision: () async => 'revision');
          },
              throwsA(anyOf(
                  isA<FormatException>(), isA<GamePackageFormatException>())));
          expect(result, isNull);
          expect(store.cachedBytes, 0);
        } finally {
          await result?.dispose();
        }
      }, policy: policy);
    });
  }

  test(
      'recalculates the exact canonical source fingerprint with margins and duration',
      () async {
    final fixture = await spriteFixture(margins: true);
    final projection = await projectFixture(fixture.$1, fixture.$2, roots: [
      NativeResourcePackRef(
          kind: ResourcePackKind.borderBlueprint, id: 'sprite')
    ]);
    final tile = projection.catalog.tilesets.single;
    final element = projection.catalog.elements.single;
    final bytes = await fixture.$2.first.openRead().first;
    final expected = CanonicalBorderSnapshotCompiler()
        .prepare(sourceElementId: element.id, frames: [
      CanonicalBorderSourceFrame(
          sourceProjectRelativePath: tile.relativePath,
          encodedImageBytes: bytes,
          sourceRectPx: BorderPixelRect(x: 1, y: 1, width: 2, height: 2),
          durationMs: 135)
    ]);
    expect(
        projection.catalog.borderCatalog.records.single.latestPublished!
            .definition.primitives.single.publishedMetrics.assetFingerprint,
        expected.metrics.assetFingerprint);
    expect(expected.snapshot.frames.single.durationMs, 135);
  });

  test('remaps image collection pages and each supported property scope',
      () async {
    final base = originalManifest();
    final property = ProjectTilesetProperty(
        name: 'texture',
        type: ProjectTilesetPropertyType.assetReference,
        value: 'portrait');
    final source = ProjectTilesetSource.imageCollection(pages: [
      ProjectImageCollectionPage(
          id: 'page été', assetId: 'image', pixelWidth: 2, pixelHeight: 2)
    ], properties: [
      property
    ], tileDefinitions: [
      ProjectImageCollectionTileDefinition(
          tileId: 9,
          pageId: 'page été',
          sourceRect: ProjectTilesetPixelRect(x: 0, y: 0, width: 2, height: 2),
          animation: [
            ProjectImageCollectionAnimationFrame(tileId: 9, durationMs: 80)
          ],
          properties: [
            property
          ],
          collisionObjects: [
            ProjectTilesetCollisionObject(
                id: 2,
                x: 0,
                y: 0,
                width: 2,
                height: 2,
                properties: [
                  property,
                  ProjectTilesetProperty(
                      name: 'self',
                      type: ProjectTilesetPropertyType.objectReference,
                      value: 2)
                ])
          ])
    ]);
    final manifest = base
        .copyWith(tilesets: [base.tilesets.single.copyWith(source: source)]);
    final files = [
      nativeImage(),
      nativeImage(id: 'portrait', path: 'assets/portrait.png')
    ];
    final projection = await projectFixture(manifest, files, roots: [
      NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas')
    ]);
    final portable = projection.catalog.tilesets.single.source
        as ProjectImageCollectionTilesetSource;
    expect(portable.pages.single.id, matches(RegExp(r'^rp_[a-f0-9]+$')));
    expect(portable.tileDefinitions.single.pageId, portable.pages.single.id);
    final bindingId = projection.catalog.files
        .singleWhere((f) => f.id != portable.pages.single.assetId)
        .id;
    expect(portable.properties.single.value, bindingId);
    expect(portable.tileDefinitions.single.properties.single.value, bindingId);
    expect(
        portable.tileDefinitions.single.collisionObjects.single.properties.first
            .value,
        bindingId);
    expect(
        portable.tileDefinitions.single.collisionObjects.single.properties.last
            .value,
        2);
    expect(portable.tileDefinitions.single.animation.single.tileId, 9);
    for (final defect in [
      ProjectTilesetProperty(
          name: 'unknown',
          type: ProjectTilesetPropertyType.structured,
          value: {'resource': 'secret'}),
      ProjectTilesetProperty(
          name: 'missing-object',
          type: ProjectTilesetPropertyType.objectReference,
          value: 99)
    ]) {
      await expectLater(
          projectFixture(
              base.copyWith(tilesets: [
                base.tilesets.single.copyWith(
                    source: ProjectTilesetSource.imageCollection(
                        pages: (source as ProjectImageCollectionTilesetSource)
                            .pages,
                        tileDefinitions: (source).tileDefinitions,
                        properties: [defect]))
              ]),
              files,
              roots: [
                NativeResourcePackRef(
                    kind: ResourcePackKind.tileset, id: 'atlas')
              ]),
          throwsFormatException);
    }
  });

  test('transforms asymmetric pixels exactly', () async {
    final image = img.Image(width: 2, height: 2, numChannels: 4);
    image.setPixelRgba(0, 0, 10, 0, 0, 255);
    image.setPixelRgba(1, 0, 20, 0, 0, 255);
    image.setPixelRgba(0, 1, 30, 0, 0, 255);
    image.setPixelRgba(1, 1, 40, 0, 0, 255);
    final base = originalManifest();
    final preset = base.smartTileCatalog.presets.single.copyWith(rules: [
      SmartTileRule(
          id: 'all',
          centerMatch: SmartTileSlotMatch.any(),
          candidates: [
            SmartTileCandidate(id: 'one', parts: [
              SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                      frame:
                          SmartTileFrameRef(atlasId: 'a', column: 0, row: 0)),
                  transform:
                      SmartTileSpriteTransform(flipX: true, quarterTurns: 1))
            ])
          ])
    ]);
    final manifest = base.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
            atlases: base.smartTileCatalog.atlases,
            materials: base.smartTileCatalog.materials,
            presets: [preset]));
    final result = await CanonicalBorderGroundComposer().composeAllRoles(
        manifest: manifest,
        sourceSmartTilePresetId: 'sol',
        readPng: (_, __) async => img.encodePng(image));
    final actual = img.decodePng(result.values.first.single.encodedImageBytes)!;
    expect([
      for (var y = 0; y < 2; y++)
        for (var x = 0; x < 2; x++) actual.getPixel(x, y).r
    ], [
      40,
      20,
      30,
      10
    ]);
  });

  test(
      'proves Border source pixels on both sides and rebuilds editable identities',
      () async {
    final fixture = await spriteFixture();
    final before = fixture.$1.borderCatalog.records.single;
    final projection = await projectFixture(fixture.$1, fixture.$2, roots: [
      NativeResourcePackRef(
          kind: ResourcePackKind.borderBlueprint, id: 'sprite')
    ]);
    final border = projection.catalog.borderCatalog.records.single;
    final originalSnapshot = fixture.$1.borderCatalog.visualSnapshots.single;
    expect(projection.catalog.borderCatalog.visualSnapshots.single.id,
        originalSnapshot.id);
    expect(
        border.latestPublished!.definition.primitives.single.publishedMetrics
            .assetFingerprint,
        isNot(before.latestPublished!.definition.primitives.single
            .publishedMetrics.assetFingerprint));
    expect(border.draft.definition.primitives.single.sourceElementId,
        projection.catalog.elements.single.id);
    expect(border.latestPublished!.definition.ground!.sourceSmartTilePresetId,
        projection.catalog.smartTileCatalog.presets.single.id);
    validatePortable(projection.catalog);
    final expectedMetrics = CanonicalBorderSnapshotCompiler().prepare(
        sourceElementId: projection.catalog.elements.single.id,
        frames: [
          CanonicalBorderSourceFrame(
              sourceProjectRelativePath:
                  projection.catalog.tilesets.single.relativePath,
              encodedImageBytes: originalPng(),
              sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
              durationMs: 100)
        ]).metrics;
    expect(
        border.latestPublished!.definition.primitives.single.publishedMetrics
            .assetFingerprint,
        expectedMetrics.assetFingerprint);
    final root = await Directory.systemTemp.createTemp('p07-sprite-');
    final store = LocalResourcePackStore(
        cacheDirectory: root.path, allowedSourceRoots: []);
    try {
      final result = await CanonicalResourcePackExportService(
              store: store,
              scope: FileBackedPayloadScope(
                  sessionId: 'sprite', projectId: 'sprite'))
          .export(
              acknowledgeOrganizationRemoval: true,
              projection: projection,
              metadata: metadata(),
              expectedRevision: 'revision',
              readCurrentRevision: () async => 'revision');
      expect(result.inspection.catalog.borderCatalog.records, hasLength(1));
      await result.dispose();
    } finally {
      await store.close();
      await root.delete(recursive: true);
    }
  });

  test('snapshot bytes cannot serve as evidence for changed original sources',
      () async {
    final fixture = await spriteFixture();
    final changed = img.Image(width: 2, height: 2, numChannels: 4);
    img.fill(changed, color: img.ColorRgba8(200, 10, 10, 255));
    final bytes = Uint8List.fromList(img.encodePng(changed));
    final files = [
      fileOf('image', 'assets/original.png', bytes),
      fixture.$2.last
    ];
    await expectLater(
        projectFixture(fixture.$1, files, roots: [
          NativeResourcePackRef(
              kind: ResourcePackKind.borderBlueprint, id: 'sprite')
        ]),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            contains('border.source_publication_mismatch'))));
  });

  test(
      'refuses a weighted Smart Tile whose remapped seed changes published pixels',
      () async {
    var refused = false;
    for (var seed = 0; seed < 32 && !refused; seed++) {
      final fixture = await spriteFixture(weighted: true, seed: seed);
      try {
        await projectFixture(fixture.$1, fixture.$2, roots: [
          NativeResourcePackRef(
              kind: ResourcePackKind.borderBlueprint, id: 'sprite')
        ]);
      } on FormatException catch (error) {
        if (!error.message.contains('border_remap_changes_pixels')) rethrow;
        refused = true;
      }
    }
    expect(refused, isTrue);
  });

  test(
      'refuses headless 3D ground explicitly while GLB resources stay exportable',
      () async {
    final fixture = mixedFixture();
    final preset = fixture.$1.smartTileCatalog.presets.single.copyWith(rules: [
      SmartTileRule(
          id: 'all',
          centerMatch: SmartTileSlotMatch.any(),
          candidates: [
            SmartTileCandidate(id: 'model', parts: [
              SmartTileVisualPart(
                  source: SmartTileVisualSource.model3d(modelId: 'model'))
            ])
          ])
    ]);
    final manifest = fixture.$1.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
            materials: fixture.$1.smartTileCatalog.materials,
            presets: [preset]));
    final projection = await projectFixture(manifest, fixture.$2, roots: [
      NativeResourcePackRef(kind: ResourcePackKind.smartTilePreset, id: 'sol')
    ]);
    expect(projection.catalog.models3d, hasLength(1));
    await expectLater(
        CanonicalBorderGroundComposer().composeAllRoles(
            manifest: manifest,
            sourceSmartTilePresetId: 'sol',
            readPng: (_, __) async => originalPng()),
        throwsA(isA<BorderSmartTileGroundSnapshotException>().having(
            (e) => e.code,
            'code',
            BorderSmartTileGroundSnapshotErrorCode.unsupportedModel3dGround)));
  });

  test(
      'composes margins and gutters per cell with transforms and a pingpong timeline',
      () async {
    final image = img.Image(width: 7, height: 4, numChannels: 4);
    img.fill(image, color: img.ColorRgba8(255, 0, 255, 255));
    for (var y = 1; y < 3; y++) {
      for (var x = 1; x < 3; x++) {
        image.setPixelRgba(x, y, 10, 0, 0, 255);
      }
      for (var x = 4; x < 6; x++) {
        image.setPixelRgba(x, y, 20, 0, 0, 255);
      }
    }
    final base = originalManifest();
    final animation = ProjectSmartTileAnimation(
        id: 'water',
        name: 'Water',
        loop: SmartTileAnimationLoop.pingPong,
        frames: [
          for (final (column, duration) in [(0, 50), (1, 80), (0, 120)])
            ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(atlasId: 'a', column: column, row: 0),
                durationMs: duration)
        ]);
    final preset = base.smartTileCatalog.presets.single.copyWith(rules: [
      SmartTileRule(
          id: 'all',
          centerMatch: SmartTileSlotMatch.any(),
          candidates: [
            SmartTileCandidate(id: 'one', parts: [
              SmartTileVisualPart(
                  source: SmartTileVisualSource.animation(animationId: 'water'),
                  transform:
                      SmartTileSpriteTransform(flipX: true, quarterTurns: 2))
            ])
          ])
    ]);
    final manifest = base.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
            materials: base.smartTileCatalog.materials,
            presets: [
          preset
        ],
            animations: [
          animation
        ],
            atlases: [
          base.smartTileCatalog.atlases.single
              .copyWith(columns: 2, marginX: 1, marginY: 1, spacingX: 1)
        ]));
    final result = await CanonicalBorderGroundComposer().composeAllRoles(
        manifest: manifest,
        sourceSmartTilePresetId: 'sol',
        readPng: (_, __) async => img.encodePng(image));
    final frames = result.values.first;
    expect(frames.map((f) => f.durationMs), [50, 80, 120, 80]);
    expect(
        frames.map((f) => img.decodePng(f.encodedImageBytes)!.getPixel(0, 0).r),
        [10, 20, 10, 20]);
  });

  test('roundtrips seven kinds and editable supports with shared blobs',
      () async {
    final fixture = mixedFixture();
    final before = fixture.$1.toJson();
    final projection = await projectFixture(fixture.$1, fixture.$2, roots: [
      for (final entry in fixture.$1.resourceLibraryCatalog.entries)
        NativeResourcePackRef(
            kind: ResourcePackKind.values.byName(entry.resourceKind),
            id: entry.resourceId)
    ], patterns: [
      'motif'
    ]);
    final catalog = ResourcePackCatalog.fromJson(projection.catalog.toJson());
    final closure =
        ResourcePackDependencyGraph.fromCatalog(catalog).validateAll();
    expect(closure.resources.map((r) => r.kind).toSet(),
        ResourcePackKind.values.toSet());
    expect(catalog.elements, hasLength(2));
    expect(catalog.elements.map((e) => e.tilesetId).toSet(), hasLength(1));
    expect(catalog.files, hasLength(4));
    expect(projection.sources, hasLength(2));
    expect(catalog.files.map((f) => f.archivePath).toSet(), hasLength(2));
    expect(
        catalog.characters.single.portraits.single.assetId,
        catalog.files
            .singleWhere((f) =>
                f.id == catalog.characters.single.portraits.single.assetId)
            .id);
    expect(catalog.characterStudioCatalog.customAnimationDefinitions.single.id,
        catalog.characters.single.customAnimations.single.definitionId);
    expect(catalog.characters.single.animations.first.sourceAssetId, isNull);
    expect(catalog.smartTileCatalog.patterns.single.id,
        catalog.smartTilePatternIds.single);
    expect(
        catalog.resourceLibraryCatalog.entries
            .map((e) => e.placementContext)
            .toSet(),
        containsAll(ResourcePlacementContext.values));
    expect(
        catalog.elements.first.collisionProfile!.cells, [GridPos(x: 0, y: 0)]);
    expect(catalog.tilesets.single.elementGroups, hasLength(2));
    expect(catalog.resourceLibraryCatalog.families, hasLength(2));
    expect(catalog.elementCategories, hasLength(2));
    expect(catalog.tilesetFolders, hasLength(2));
    expect(
        catalog.borderCatalog.records.single.draft.definition.primitives.single
            .sourceModelId,
        catalog.models3d.single.id);
    expect(catalog.models3d.single.relativePath,
        'assets/models3d/${catalog.models3d.single.id}.glb');
    expect(catalog.models3d.single.scale, 2);
    expect(catalog.models3d.single.inspection.animations, hasLength(1));
    expect(catalog.models3d.single.inspection.materials, isNotEmpty);
    expect(catalog.models3d.single.pivot, Model3dVector3(x: 1, y: 2, z: 3));
    final reconstructed = reconstructResourcePackSmartTileDraft(
        preset: catalog.smartTileCatalog.presets.single,
        catalog: catalog.smartTileCatalog);
    expect(reconstructed.rules.single.id, reconstructed.fallbackRuleId);
    expect(fixture.$1.toJson(), before);
    validatePortable(projection.catalog);
    final root = await Directory.systemTemp.createTemp('p07-mixed-');
    final store = LocalResourcePackStore(
        cacheDirectory: root.path, allowedSourceRoots: []);
    try {
      final exported = await CanonicalResourcePackExportService(
              store: store,
              scope: FileBackedPayloadScope(
                  sessionId: 'mixed', projectId: 'mixed'))
          .export(
              acknowledgeOrganizationRemoval: true,
              projection: projection,
              metadata: metadata(),
              expectedRevision: 'revision',
              readCurrentRevision: () async => 'revision');
      expect(exported.inspection.modelInspections.values.single, isNotNull);
      expect(exported.inspection.resourceCount, 8);
      await exported.dispose();
    } finally {
      await store.close();
      await root.delete(recursive: true);
    }
  });

  test('leaves standalone patterns out unless selected explicitly', () async {
    final fixture = mixedFixture();
    final projection = await projectFixture(fixture.$1, fixture.$2, roots: [
      NativeResourcePackRef(kind: ResourcePackKind.smartTilePreset, id: 'sol')
    ]);
    expect(projection.catalog.smartTileCatalog.patterns, isEmpty);
    expect(projection.catalog.smartTilePatternIds, isEmpty);
    expect(projection.catalog.models3d, isEmpty);
  });

  test('unpublished unrelated Borders cannot block a valid root', () async {
    final fixture = mixedFixture();
    final private = BorderBlueprintRecord(
        id: 'private', draft: fixture.$1.borderCatalog.records.single.draft);
    final manifest = fixture.$1
        .copyWith(borderCatalog: ProjectBorderCatalog(records: [private]));
    final projection = await projectFixture(manifest, fixture.$2, roots: [
      NativeResourcePackRef(kind: ResourcePackKind.element, id: 'decor')
    ]);
    expect(projection.catalog.elements, hasLength(1));
    expect(projection.catalog.borderCatalog.records, isEmpty);
    await expectLater(
        projectFixture(manifest, fixture.$2, roots: [
          NativeResourcePackRef(
              kind: ResourcePackKind.borderBlueprint, id: 'private')
        ]),
        throwsA(isA<FormatException>().having(
            (e) => e.message, 'message', contains('border_unpublished'))));
  });

  test(
      'normalization is described before acknowledgement and never changes native data',
      () async {
    final fixture = mixedFixture();
    final manifest = fixture.$1.copyWith(tilesets: [
      fixture.$1.tilesets.single
          .copyWith(groupId: 'map-tree', isWorldTileset: true, paletteEntries: [
        TilesetPaletteEntry(id: 'p', recommendedLayerId: 'layer', frames: [
          TilesetVisualFrame(
              tilesetId: 'atlas', source: TilesetSourceRect(x: 0, y: 0))
        ])
      ])
    ]);
    final described = await ResourcePackProjectionBuilder().project(
        manifest: manifest,
        roots: [
          NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas')
        ],
        files: fixture.$2,
        author: 'Original',
        sourceRevision: 'revision');
    expect(described.review.requiresOrganizationAcknowledgement, isTrue);
    final result = await projectFixture(manifest, fixture.$2, roots: [
      NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas')
    ]);
    expect(result.catalog.tilesets.single.isWorldTileset, isFalse);
    expect(result.catalog.tilesets.single.groupId, isNull);
    expect(
        result.catalog.tilesets.single.paletteEntries.single.recommendedLayerId,
        isNull);
    expect(
        result.catalog.tilesets.single.paletteEntries.single.frames.single
            .tilesetId,
        result.catalog.tilesets.single.id);
    expect(manifest.tilesets.single.isWorldTileset, isTrue);
  });

  test(
      'rejects missing dependencies, invalid cycles and unknown property references',
      () async {
    final base = originalManifest();
    final element = ProjectElementEntry(
        id: 'missing',
        name: 'Missing',
        tilesetId: 'absent',
        categoryId: '',
        frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))]);
    await expectLater(
        projectFixture(base.copyWith(elements: [element]), [
          nativeImage()
        ], roots: [
          NativeResourcePackRef(kind: ResourcePackKind.element, id: 'missing')
        ]),
        throwsFormatException);
    final fixture = mixedFixture();
    final cycles = fixture.$1.copyWith(elementCategories: [
      ProjectElementCategory(
          id: 'category', name: 'A', parentCategoryId: 'parent'),
      ProjectElementCategory(
          id: 'parent', name: 'B', parentCategoryId: 'category')
    ]);
    await expectLater(
        projectFixture(cycles, fixture.$2, roots: [
          NativeResourcePackRef(kind: ResourcePackKind.element, id: 'decor')
        ]),
        throwsFormatException);
  });

  test(
      'exports to an owned opaque stage, reinspects and rejects stale revision',
      () async {
    final root = await Directory.systemTemp.createTemp('p07-test-');
    var now = DateTime.utc(2026);
    final store = LocalResourcePackStore(
        cacheDirectory: root.path, allowedSourceRoots: [], clock: () => now);
    final scope =
        FileBackedPayloadScope(sessionId: 'session', projectId: 'project');
    final projection = await ResourcePackProjectionBuilder().project(
        manifest: originalManifest(),
        roots: [
          NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas')
        ],
        files: [nativeImage()],
        author: 'Original',
        sourceRevision: 'revision');
    final service =
        CanonicalResourcePackExportService(store: store, scope: scope);
    final metadata = ResourcePackMetadata(
        id: 'original.pack',
        version: '1.0.0',
        name: 'Original',
        description: '',
        universeId: 'original',
        authors: ['Original'],
        provenance: 'Original fixture');
    try {
      final first = await service.export(
          acknowledgeOrganizationRemoval: true,
          projection: projection,
          metadata: metadata,
          expectedRevision: 'revision',
          readCurrentRevision: () async => 'revision');
      final second = await service.export(
          acknowledgeOrganizationRemoval: true,
          projection: projection,
          metadata: metadata,
          expectedRevision: 'revision',
          readCurrentRevision: () async => 'revision');
      expect(first.inspection.archiveRawSha256,
          second.inspection.archiveRawSha256);
      expect(first.inspection.resourceCount, 1);
      await first.dispose();
      await second.dispose();
      var checks = 0;
      await expectLater(
          service.export(
              acknowledgeOrganizationRemoval: true,
              projection: projection,
              metadata: metadata,
              expectedRevision: 'revision',
              readCurrentRevision: () async =>
                  ++checks == 1 ? 'revision' : 'changed'),
          throwsFormatException);
      now = now.add(Duration(days: 2));
      await store.collectExpired();
      expect(store.cachedBytes, 0);
    } finally {
      await store.close();
      await root.delete(recursive: true);
    }
  });

  test('closes native Unicode roots before validating portable definitions',
      () async {
    final manifest = originalManifest().copyWith(
        elements: [
          ProjectElementEntry(
              id: 'décor été',
              name: 'Tree',
              tilesetId: 'atlas',
              categoryId: '',
              frames: [
                TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))
              ])
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
          ResourceLibraryEntry(
              resourceKind: 'element',
              resourceId: 'décor été',
              mapId: 'private-map',
              placementContext: ResourcePlacementContext.exterior)
        ]));
    final before = manifest.toJson();
    final result = await ResourcePackProjectionBuilder().project(
      manifest: manifest,
      roots: [
        NativeResourcePackRef(kind: ResourcePackKind.element, id: 'décor été')
      ],
      files: [nativeImage()],
      author: 'Original',
      sourceRevision: 'revision',
    );
    expect(result.catalog.elements, hasLength(1));
    expect(result.catalog.smartTileCatalog.presets, isEmpty);
    expect(result.catalog.elements.single.id, matches(RegExp(r'^[a-z0-9_]+$')));
    expect(result.catalog.resourceLibraryCatalog.entries.single.mapId, isNull);
    expect(
        result.catalog.resourceLibraryCatalog.entries.single.placementContext,
        ResourcePlacementContext.exterior);
    expect(manifest.toJson(), before);
    expect(result.catalog.tilesets.single.id,
        result.catalog.elements.single.tilesetId);
  });

  test('headless composer resolves all roles without filesystem access',
      () async {
    final result = await CanonicalBorderGroundComposer().composeAllRoles(
        manifest: originalManifest(),
        sourceSmartTilePresetId: 'sol',
        readPng: (_, __) async => originalPng());
    expect(result.keys, standardBorderGroundVariantRoleOrder);
    for (final frames in result.values) {
      expect(frames, hasLength(1));
      expect(
          img.decodePng(frames.single.encodedImageBytes)!.getPixel(0, 0).r, 17);
    }
  });
}

Uint8List originalPng() {
  final image = img.Image(width: 2, height: 2, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(17, 31, 59, 255));
  return Uint8List.fromList(img.encodePng(image));
}

ProjectManifest originalManifest() => ProjectManifest(
    name: 'Original',
    maps: [],
    settings: ProjectSettings(tileWidth: 2, tileHeight: 2),
    elementCategories: [
      ProjectElementCategory(id: 'category', name: 'Original')
    ],
    tilesets: [
      ProjectTilesetEntry(
          id: 'atlas',
          name: 'Atlas',
          relativePath: 'assets/original.png',
          source: ProjectTilesetSource.regularAtlas(
              assetId: 'image',
              pixelWidth: 2,
              pixelHeight: 2,
              tileWidth: 2,
              tileHeight: 2))
    ],
    smartTileCatalog: ProjectSmartTileCatalog(atlases: [
      ProjectSmartTileAtlas(
          id: 'a',
          name: 'Atlas',
          tilesetId: 'atlas',
          cellWidth: 2,
          cellHeight: 2,
          columns: 1,
          rows: 1)
    ], materials: [
      ProjectSmartTileMaterial(id: 'm', name: 'Ground', connectionGroupId: 'g')
    ], presets: [
      ProjectSmartTilePreset(
          id: 'sol',
          name: 'Ground',
          usage: SmartTileUsage.terrain,
          topology: SmartTileTopology.uniform,
          status: SmartTilePresetStatus.published,
          coveragePolicy: SmartTileCoveragePolicy.sparse,
          coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.explicit,
              allowFallback: true,
              requiredScenarios: [
                SmartTileCoverageScenario(id: 'scenario', centerMaterialId: 'm')
              ]),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'm',
          allowedMaterialIds: ['m'],
          fallbackRuleId: 'all',
          rules: [
            SmartTileRule(
                id: 'all',
                centerMatch: SmartTileSlotMatch.any(),
                candidates: [
                  SmartTileCandidate(id: 'one', parts: [
                    SmartTileVisualPart(
                        source: SmartTileVisualSource.frame(
                            frame: SmartTileFrameRef(
                                atlasId: 'a', column: 0, row: 0)))
                  ])
                ])
          ])
    ]));

NativeResourcePackFile nativeImage(
    {String id = 'image', String path = 'assets/original.png'}) {
  final bytes = originalPng();
  return NativeResourcePackFile(
      id: id,
      logicalPath: path,
      byteLength: bytes.length,
      rawSha256: sha256.convert(bytes).toString(),
      mediaType: 'image/png',
      openRead: () => Stream.value(bytes));
}

Future<ResourcePackExportProjection> projectFixture(
        ProjectManifest manifest, List<NativeResourcePackFile> files,
        {required List<NativeResourcePackRef> roots,
        List<String> patterns = const []}) =>
    ResourcePackProjectionBuilder().project(
      manifest: manifest,
      files: files,
      roots: roots,
      smartTilePatternIds: patterns,
      author: 'Original',
      sourceRevision: 'revision',
    );

ResourcePackMetadata metadata() => ResourcePackMetadata(
    id: 'original.pack',
    version: '1.0.0',
    name: 'Original',
    description: '',
    universeId: 'original',
    authors: ['Original'],
    provenance: 'Original test fixture');

(ProjectManifest, List<NativeResourcePackFile>) mixedFixture() {
  final base = originalManifest();
  final glb = originalModelGlb();
  final model = ProjectModel3dEntry(
      id: 'model',
      name: 'Original model',
      sourceAssetId: 'glb',
      relativePath: 'assets/models3d/model.glb',
      inspection: GlbModel3dInspector().inspect(glb),
      scale: 2,
      pivot: Model3dVector3(x: 1, y: 2, z: 3));
  final element = ProjectElementEntry(
      id: 'decor',
      name: 'Original decor',
      tilesetId: 'atlas',
      categoryId: 'category',
      tilesetGroupId: 'group',
      collisionProfile: ElementCollisionProfile(cells: [GridPos(x: 0, y: 0)]),
      frames: [
        TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0), durationMs: 80),
        TilesetVisualFrame(
            tilesetId: 'atlas',
            source: TilesetSourceRect(x: 0, y: 0),
            durationMs: 120)
      ]);
  final definition = BorderBlueprintPublishedDefinition(
      name: 'Original border',
      previewSeed: BorderSignedInt64.fromInt(1),
      template: BorderBlueprintTemplate.connectedLine,
      primitives: [
        BorderPublishedPrimitive(
            id: 'primitive',
            sourceModelId: 'model',
            role: BorderPrimitiveRole.lineStraight,
            weight: 1,
            anchorWorld: Model3dVector3.zero,
            transforms: BorderTransformPolicy(
                allowFlipX: false, allowedQuarterTurns: [0]))
      ],
      defaults: BorderGenerationParams(
          irregularityPermille: 0,
          detailDensityPermille: 0,
          variationPermille: 0,
          maxOverlapPx: 0,
          gapTolerancePx: 0,
          depthRows: 1),
      sortOrder: 0);
  final border = BorderBlueprintRecord(
      id: 'border',
      latestPublished:
          BorderBlueprintRevision(revision: 1, definition: definition),
      draft: BorderBlueprintDraft(
          baseRevision: 1,
          definition: BorderBlueprintDraftDefinition(
              name: 'Unrelated private draft',
              previewSeed: definition.previewSeed,
              template: definition.template,
              primitives: [],
              defaults: definition.defaults,
              sortOrder: 0)));
  final parts =
      base.smartTileCatalog.presets.single.rules.single.candidates.single.parts;
  final manifest = base.copyWith(
      elements: [element, element.copyWith(id: 'second', name: 'Second')],
      models3d: [model],
      tilesets: [
        base.tilesets.single.copyWith(
            source: ProjectTilesetSource.regularAtlas(
                assetId: 'image',
                pixelWidth: 4,
                pixelHeight: 4,
                tileWidth: 2,
                tileHeight: 2),
            folderId: 'folder',
            elementGroups: [
              TilesetElementGroup(id: 'parent-group', name: 'Parent'),
              TilesetElementGroup(
                  id: 'group', name: 'Group', parentGroupId: 'parent-group')
            ])
      ],
      elementCategories: [
        ProjectElementCategory(id: 'parent', name: 'Parent'),
        ProjectElementCategory(
            id: 'category', name: 'Category', parentCategoryId: 'parent')
      ],
      tilesetFolders: [
        ProjectTilesetFolder(id: 'parent-folder', name: 'Parent'),
        ProjectTilesetFolder(
            id: 'folder', name: 'Folder', parentFolderId: 'parent-folder')
      ],
      characters: [
        ProjectCharacterEntry(
            id: 'person',
            name: 'Original',
            tilesetId: 'atlas',
            frameWidth: 1,
            frameHeight: 1,
            portraits: [
              CharacterPortraitVariant(
                  portraitStateId: 'custom-face', assetId: 'portrait')
            ],
            animations: [
              CharacterAnimation(
                  state: CharacterAnimationState.idle,
                  direction: EntityFacing.south,
                  frames: [
                    CharacterAnimationFrame(
                        source: TilesetSourceRect(x: 0, y: 0))
                  ])
            ],
            customAnimations: [
              CharacterCustomAnimationClip(
                  definitionId: 'custom-action',
                  sourceAssetId: 'animation',
                  frames: [
                    CharacterAnimationFrame(
                        source: TilesetSourceRect(x: 0, y: 0))
                  ])
            ])
      ],
      characterStudioCatalog: ProjectCharacterStudioCatalog(portraitStates: [
        CharacterPortraitStateDefinition(
            id: 'custom-face', displayName: 'Original face')
      ], customAnimationDefinitions: [
        CharacterCustomAnimationDefinition(
            id: 'custom-action',
            displayName: 'Original action',
            mode: CharacterCustomAnimationMode.single)
      ]),
      environmentPresets: [
        EnvironmentPreset(
            id: 'environment',
            name: 'Original environment',
            templateId: 'original',
            categoryId: 'category',
            palette: [
              EnvironmentPaletteItem(elementId: 'decor', weight: 2),
              EnvironmentPaletteItem(elementId: 'second', weight: 3)
            ],
            defaultParams: EnvironmentGenerationParams(
                density: .5,
                variation: .5,
                edgeDensity: .5,
                minSpacingCells: 0),
            sortOrder: 0)
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
          atlases: base.smartTileCatalog.atlases,
          materials: base.smartTileCatalog.materials,
          presets: base.smartTileCatalog.presets,
          patterns: [
            ProjectSmartTilePattern(
                id: 'motif',
                name: 'Independent',
                usage: SmartTileUsage.terrain,
                width: 1,
                height: 1,
                cells: [SmartTilePatternCell(x: 0, y: 0, parts: parts)])
          ]),
      borderCatalog: ProjectBorderCatalog(
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
          records: [border]),
      resourceLibraryCatalog: ResourceLibraryCatalog(families: [
        ResourceFamily(id: 'family-parent', name: 'Parent'),
        ResourceFamily(id: 'family', name: 'Family', parentId: 'family-parent')
      ], entries: [
        for (final (index, kind, id) in [
          (0, 'element', 'decor'),
          (1, 'element', 'second'),
          (2, 'tileset', 'atlas'),
          (3, 'character', 'person'),
          (4, 'model3d', 'model'),
          (5, 'smartTilePreset', 'sol'),
          (6, 'environmentPreset', 'environment'),
          (7, 'borderBlueprint', 'border')
        ])
          ResourceLibraryEntry(
              resourceKind: kind,
              resourceId: id,
              familyId: 'family',
              placementContext: ResourcePlacementContext.values[index % 3])
      ]));
  final sprite = img.Image(width: 4, height: 4, numChannels: 4);
  img.fill(sprite, color: img.ColorRgba8(17, 31, 59, 255));
  final spriteBytes = Uint8List.fromList(img.encodePng(sprite));
  return (
    manifest,
    [
      fileOf('image', 'assets/original.png', spriteBytes),
      fileOf('portrait', 'assets/portrait.png', spriteBytes),
      fileOf('animation', 'assets/animation.png', spriteBytes),
      NativeResourcePackFile(
          id: 'glb',
          logicalPath: model.relativePath,
          byteLength: glb.length,
          rawSha256: sha256.convert(glb).toString(),
          mediaType: 'model/gltf-binary',
          openRead: () => Stream.value(glb))
    ]
  );
}

NativeResourcePackFile fileOf(String id, String path, Uint8List bytes) =>
    NativeResourcePackFile(
        id: id,
        logicalPath: path,
        byteLength: bytes.length,
        rawSha256: sha256.convert(bytes).toString(),
        mediaType: 'image/png',
        openRead: () => Stream.value(bytes));

Future<(ProjectManifest, List<NativeResourcePackFile>)> spriteFixture(
    {bool weighted = false, bool margins = false, int seed = 0}) async {
  var base = originalManifest();
  var image = originalPng();
  if (margins) {
    final pixels = img.Image(width: 4, height: 4, numChannels: 4);
    img.fill(pixels, color: img.ColorRgba8(255, 0, 255, 255));
    for (var y = 1; y < 3; y++) {
      for (var x = 1; x < 3; x++) {
        pixels.setPixelRgba(x, y, 17, 31, 59, 255);
      }
    }
    image = Uint8List.fromList(img.encodePng(pixels));
    base = base.copyWith(
        tilesets: [
          base.tilesets.single.copyWith(
              source: ProjectTilesetSource.regularAtlas(
                  assetId: 'image',
                  pixelWidth: 4,
                  pixelHeight: 4,
                  tileWidth: 2,
                  tileHeight: 2,
                  marginX: 1,
                  marginY: 1))
        ],
        smartTileCatalog: ProjectSmartTileCatalog(
            materials: base.smartTileCatalog.materials,
            presets: base.smartTileCatalog.presets,
            atlases: [
              base.smartTileCatalog.atlases.single
                  .copyWith(marginX: 1, marginY: 1)
            ]));
  }
  if (weighted) {
    final pixels = img.Image(width: 4, height: 2, numChannels: 4);
    img.fill(pixels, color: img.ColorRgba8(17, 31, 59, 255));
    for (var y = 0; y < 2; y++) {
      for (var x = 2; x < 4; x++) {
        pixels.setPixelRgba(x, y, 220, 1, 2, 255);
      }
    }
    image = Uint8List.fromList(img.encodePng(pixels));
    final original = base.smartTileCatalog.presets.single;
    final rule = original.rules.single;
    base = base.copyWith(
        tilesets: [
          base.tilesets.single.copyWith(
              source: ProjectTilesetSource.regularAtlas(
                  assetId: 'image',
                  pixelWidth: 4,
                  pixelHeight: 2,
                  tileWidth: 2,
                  tileHeight: 2))
        ],
        smartTileCatalog: ProjectSmartTileCatalog(
            materials: base.smartTileCatalog.materials,
            atlases: [
              base.smartTileCatalog.atlases.single.copyWith(columns: 2)
            ],
            presets: [
              original.copyWith(seedSalt: seed, rules: [
                rule.copyWith(candidates: [
                  ...rule.candidates,
                  SmartTileCandidate(id: 'two', weight: 2, parts: [
                    SmartTileVisualPart(
                        source: SmartTileVisualSource.frame(
                            frame: SmartTileFrameRef(
                                atlasId: 'a', column: 1, row: 0)))
                  ])
                ])
              ])
            ]));
  }
  final compositions = await CanonicalBorderGroundComposer().composeAllRoles(
      manifest: base,
      sourceSmartTilePresetId: 'sol',
      readPng: (_, __) async => image);
  final first = compositions.values.first.single;
  final content = first.contentFrame;
  final fingerprint =
      computeBorderSnapshotContentFingerprint(frames: [content]);
  final snapshot = BorderVisualSnapshot(
      id: 'border-snapshot-sha256:$fingerprint',
      contentFingerprint: fingerprint,
      frames: [
        BorderVisualFrameSnapshot(
            relativeAssetPath: 'assets/borders/snapshots/snapshot.png',
            sourceRectPx: content.sourceRectPx,
            durationMs: content.durationMs)
      ]);
  final snapshots = <BorderVisualSnapshot>[snapshot];
  final files = <NativeResourcePackFile>[
    fileOf('image', 'assets/original.png', image),
    fileOf('snapshot', 'assets/borders/snapshots/snapshot.png',
        first.encodedImageBytes)
  ];
  final byRole = <BorderGroundVariantRole, String>{};
  for (final entry in compositions.entries) {
    final value = entry.value.single;
    final hash =
        computeBorderSnapshotContentFingerprint(frames: [value.contentFrame]);
    final id = 'border-snapshot-sha256:$hash';
    byRole[entry.key] = id;
    if (!snapshots.any((snapshot) => snapshot.id == id)) {
      final path = 'assets/borders/snapshots/snapshot-$hash.png';
      snapshots
          .add(BorderVisualSnapshot(id: id, contentFingerprint: hash, frames: [
        BorderVisualFrameSnapshot(
            relativeAssetPath: path,
            sourceRectPx: value.contentFrame.sourceRectPx,
            durationMs: value.contentFrame.durationMs)
      ]));
      files.add(fileOf('snapshot-$hash', path, value.encodedImageBytes));
    }
  }
  final primitiveContent = BorderSnapshotContentFrame(
      sourceRectPx: content.sourceRectPx,
      durationMs: margins ? 135 : 100,
      rgbaBytes:
          img.decodePng(originalPng())!.getBytes(order: img.ChannelOrder.rgba));
  final primitiveHash =
      computeBorderSnapshotContentFingerprint(frames: [primitiveContent]);
  final primitiveSnapshotId = 'border-snapshot-sha256:$primitiveHash';
  if (!snapshots.any((s) => s.id == primitiveSnapshotId)) {
    snapshots.add(BorderVisualSnapshot(
        id: primitiveSnapshotId,
        contentFingerprint: primitiveHash,
        frames: [
          BorderVisualFrameSnapshot(
              relativeAssetPath: 'assets/borders/snapshots/primitive.png',
              sourceRectPx: content.sourceRectPx,
              durationMs: margins ? 135 : 100)
        ]));
    files.add(fileOf(
        'primitive', 'assets/borders/snapshots/primitive.png', originalPng()));
  }
  final defaults = BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 0,
      maxOverlapPx: 0,
      gapTolerancePx: 0,
      depthRows: 1);
  final definition = BorderBlueprintPublishedDefinition(
      name: 'Original sprite border',
      previewSeed: BorderSignedInt64.fromInt(1),
      template: BorderBlueprintTemplate.connectedLine,
      primitives: [
        BorderPublishedPrimitive(
            id: 'p',
            sourceElementId: 'decor',
            visualSnapshotId: primitiveSnapshotId,
            role: BorderPrimitiveRole.lineStraight,
            weight: 1,
            anchorPx: BorderPixelPos(x: 0, y: 0),
            transforms: BorderTransformPolicy(
                allowFlipX: false, allowedQuarterTurns: [0]),
            publishedMetrics: BorderPrimitiveAssetMetrics(
                assetFingerprint: 'original-source',
                pixelSize: GridSize(width: 2, height: 2),
                opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
                defaultAnchorPx: BorderPixelPos(x: 0, y: 0),
                occupancyMaskRle: 'border-rle-v1:4:1:4'))
      ],
      ground: BorderPublishedGround(
          sourceSmartTilePresetId: 'sol',
          edgeBandCells: 1,
          visualSnapshotIdsByRole: byRole),
      defaults: defaults,
      sortOrder: 0);
  final published =
      BorderBlueprintRevision(revision: 1, definition: definition);
  final record = BorderBlueprintRecord(
      id: 'sprite',
      latestPublished: published,
      draft: reconstructResourcePackBorderDraft(published));
  return (
    base.copyWith(
        elements: [
          ProjectElementEntry(
              id: 'decor',
              name: 'Original',
              tilesetId: 'atlas',
              categoryId: 'category',
              frames: [
                TilesetVisualFrame(
                    source: TilesetSourceRect(x: 0, y: 0),
                    durationMs: margins ? 135 : null)
              ])
        ],
        borderCatalog: ProjectBorderCatalog(
            formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
            records: [record],
            visualSnapshots: snapshots)),
    files
  );
}

void validatePortable(ResourcePackCatalog catalog) =>
    ProjectValidator.validate(ProjectManifest(
        name: 'Portable',
        version: ProjectVersion.v9,
        maps: [],
        tilesets: catalog.tilesets,
        elements: catalog.elements,
        models3d: catalog.models3d,
        characters: catalog.characters,
        smartTileCatalog: catalog.smartTileCatalog,
        borderCatalog: catalog.borderCatalog,
        environmentPresets: catalog.environmentPresets,
        resourceLibraryCatalog: catalog.resourceLibraryCatalog,
        elementCategories: catalog.elementCategories,
        tilesetFolders: catalog.tilesetFolders,
        characterStudioCatalog: catalog.characterStudioCatalog,
        settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile(),
            tileWidth: 2,
            tileHeight: 2)));

Uint8List originalModelGlb() {
  final source = Uint8List.fromList(texturedGlb());
  final jsonLength = ByteData.sublistView(source).getUint32(12, Endian.little);
  final document = jsonDecode(utf8.decode(source.sublist(20, 20 + jsonLength)))
      as Map<String, dynamic>;
  final length = document['buffers'][0]['byteLength'] as int;
  final offset = (length + 3) ~/ 4 * 4;
  final binary = Uint8List(offset + 32);
  binary.setRange(
      0, length, source.sublist(28 + jsonLength, 28 + jsonLength + length));
  final values = ByteData.sublistView(binary);
  values.setFloat32(offset + 4, 1, Endian.little);
  values.setFloat32(offset + 20, 1, Endian.little);
  final view = (document['bufferViews'] as List).length;
  document['bufferViews'].addAll([
    {'buffer': 0, 'byteOffset': offset, 'byteLength': 8},
    {'buffer': 0, 'byteOffset': offset + 8, 'byteLength': 24}
  ]);
  final accessor = (document['accessors'] as List).length;
  document['accessors'].addAll([
    {
      'bufferView': view,
      'componentType': 5126,
      'count': 2,
      'type': 'SCALAR',
      'min': [0],
      'max': [1]
    },
    {'bufferView': view + 1, 'componentType': 5126, 'count': 2, 'type': 'VEC3'}
  ]);
  document['animations'] = [
    {
      'name': 'Original motion',
      'samplers': [
        {'input': accessor, 'output': accessor + 1}
      ],
      'channels': [
        {
          'sampler': 0,
          'target': {'node': 0, 'path': 'translation'}
        }
      ]
    }
  ];
  document['buffers'][0]['byteLength'] = binary.length;
  return Uint8List.fromList(encodeGlb(document, binary));
}

Future<void> withAliasExportService(
    Future<void> Function(CanonicalResourcePackExportService service,
            LocalResourcePackStore store)
        run,
    {ResourcePackSecurityPolicy policy =
        const ResourcePackSecurityPolicy()}) async {
  final directory = await Directory.systemTemp.createTemp('p07-alias-test-');
  final store = LocalResourcePackStore(
      cacheDirectory: directory.path, allowedSourceRoots: [], policy: policy);
  try {
    await run(
        CanonicalResourcePackExportService(
            store: store,
            scope:
                FileBackedPayloadScope(sessionId: 'alias', projectId: 'alias'),
            policy: policy),
        store);
  } finally {
    await store.close();
    await directory.delete(recursive: true);
  }
}
