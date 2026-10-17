import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/infrastructure/local_resource_pack_store.dart';
import 'package:map_authoring/src/ports/file_backed_payload_store.dart';
import 'package:map_distribution/map_distribution.dart';
import 'resource_pack_export_test.dart' as source;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'resource_pack_import_fixture.dart';

void main() {
  test('local terrain identities survive copies while shared connection groups stay installation scoped', () async {
    final base = source.originalManifest();
    final smart = base.smartTileCatalog;
    final first = smart.presets.single;
    final second = first.copyWith(
      id: 'second',
      name: 'Second',
      defaultMaterialId: 'm2',
      allowedMaterialIds: ['m2'],
      coverageProfile: first.coverageProfile.copyWith(
        requiredScenarios: [
          SmartTileCoverageScenario(id: 'scenario', centerMaterialId: 'm2'),
        ],
      ),
    );
    final fixture = await NativeResourcePackImportFixture.create(
      sourceManifest: base.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          atlases: smart.atlases,
          materials: [
            smart.materials.single,
            smart.materials.single.copyWith(id: 'm2'),
          ],
          presets: [first, second],
        ),
      ),
      sourceFiles: [source.nativeImage()],
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
    try {
      final roots = [
        for (final preset
            in fixture
                .source
                .archive
                .inspection
                .catalog
                .smartTileCatalog
                .presets)
          ResourcePackRef(
            kind: ResourcePackKind.smartTilePreset,
            id: preset.id,
          ),
      ];
      final prepared = await fixture.prepare(
        selection: await fixture.select(roots: roots),
      );
      await fixture.apply(await fixture.plan(prepared));
      final copy = await fixture.prepare(
        selection: await fixture.select(roots: roots),
        policy: ResourcePackConflictPolicy.importCopy,
      );
      await fixture.apply(await fixture.plan(copy));
      await fixture.close();
      await fixture.open();
      final manifest = (await fixture.loader.load(fixture.opened.projectHandle))
          .manifest;
      expect(manifest.smartTileCatalog.presets, hasLength(4));
      expect(manifest.smartTileCatalog.materials, hasLength(4));
      final groups = <String>{};
      for (final installation in manifest.resourcePackInstallations.entries) {
        final group = installation.supports
            .singleWhere(
              (s) => s.kind == ResourcePackSupportKind.smartTileConnectionGroup,
            )
            .targetId;
        groups.add(group);
        final materialIds = installation.supports
            .where((s) => s.kind == ResourcePackSupportKind.smartTileMaterial)
            .map((s) => s.targetId)
            .toSet();
        final materials = manifest.smartTileCatalog.materials.where(
          (m) => materialIds.contains(m.id),
        );
        expect(materials, hasLength(2));
        expect(materials.map((m) => m.connectionGroupId).toSet(), {group});
      }
      expect(groups, hasLength(2));
      for (final preset in manifest.smartTileCatalog.presets) {
        expect(preset.rules.single.id, 'all');
        expect(preset.rules.single.candidates.single.id, 'one');
        expect(preset.fallbackRuleId, 'all');
      }
    } finally {
      await fixture.dispose();
    }
  });
  test(
      'global publisher credits and documents survive native import close and selective official reexport',
      () async {
    final base = source.mixedFixture();
    final dir = await Directory.systemTemp.createTemp('p11-global-roundtrip-');
    final aStore = LocalResourcePackStore(
        cacheDirectory: '${dir.path}/a-cache', allowedSourceRoots: []);
    const scope = FileBackedPayloadScope(sessionId: 'global-a', projectId: 'a');
    OwnedResourcePackExport? archive, c;
    NativeResourcePackImportFixture? fixture;
    LocalResourcePackStore? cStore;
    var sourceDisposed = false;
    try {
      final projection = await const ResourcePackProjectionBuilder().project(
          manifest: base.$1,
          files: base.$2,
          roots: [
            NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas'),
            NativeResourcePackRef(
                kind: ResourcePackKind.character, id: 'person'),
            NativeResourcePackRef(kind: ResourcePackKind.model3d, id: 'model')
          ],
          author: 'GLOBAL Publisher',
          sourceUrl: 'https://example.test/global',
          sourceRevision: 'a',
          attribution: originalAttribution(base.$2),
          localLicenses: [fixtureLicense('GLOBAL original licence')]);
      archive =
          await CanonicalResourcePackExportService(store: aStore, scope: scope)
              .export(
                  projection: projection,
                  metadata: source.metadata(),
                  expectedRevision: 'a',
                  readCurrentRevision: () async => 'a',
                  acknowledgeOrganizationRemoval: true);
      final global = archive.inspection.catalog.provenance
          .singleWhere((o) => o.author == 'GLOBAL Publisher');
      expect(global.resources, isEmpty);
      expect(
          archive.inspection.catalog.files
              .any((f) => f.provenanceId == global.id),
          isFalse);
      fixture = await NativeResourcePackImportFixture.create(
          nativeRoot: Directory('${dir.path}/b'));
      final nativeStore = fixture.mutations
          .resourcePackPayloadStore(fixture.opened.projectHandle);
      final staged = await archive.withSource((source) => nativeStore.stage(
          scope: fixture!.preparer.scope,
          byteLength: source.length,
          chunks: sourceChunks(source)));
      final chosen = await fixture.preparer
          .select(archiveHandle: staged.payload.handle, roots: [
        ResourcePackRef(
            kind: ResourcePackKind.tileset,
            id: archive.inspection.catalog.tilesets.single.id)
      ]);
      final prepared = await fixture.prepare(selection: chosen);
      final selectedLicensePaths = {
        for (final origin in archive.inspection.catalog.provenance)
          if (origin.author == 'Alice' || origin.author == 'GLOBAL Publisher')
            ...origin.licenseIds
      };
      final expectedLicenseBytes = archive.inspection.manifest.content.files
          .where((file) => selectedLicensePaths.contains(file.path))
          .fold<int>(0, (total, file) => total + file.byteLength);
      expect(prepared.review.summary['licenseBytes'], expectedLicenseBytes);
      expect(
          expectedLicenseBytes,
          utf8.encode('Alice original licence').length +
              utf8.encode('GLOBAL original licence').length);
      await fixture.apply(await fixture.plan(prepared));
      await fixture.close();
      await archive.dispose();
      archive = null;
      await aStore.close();
      await fixture.source.dispose();
      sourceDisposed = true;
      await fixture.open();
      final snapshot = await fixture.loader.load(fixture.opened.projectHandle);
      final installation =
          snapshot.manifest.resourcePackInstallations.entries.single;
      expect(installation.origins.map((o) => o.author).toSet(),
          {'Alice', 'GLOBAL Publisher'});
      expect(installation.licenses, hasLength(2));
      expect(
          installation.origins
              .singleWhere((o) => o.author == 'GLOBAL Publisher')
              .resources,
          isEmpty);
      final files = await nativeFiles(snapshot, fixture.root);
      final roots = [
        NativeResourcePackRef(
            kind: ResourcePackKind.tileset,
            id: snapshot.manifest.tilesets.single.id)
      ];
      final selected = await const ResourcePackProjectionBuilder()
          .selectedFileIds(
              manifest: snapshot.manifest, roots: roots, files: files);
      final inputs = files.where((f) => selected.contains(f.id)).toList();
      cStore = LocalResourcePackStore(
          cacheDirectory: '${dir.path}/c-cache', allowedSourceRoots: []);
      const cScope =
          FileBackedPayloadScope(sessionId: 'global-c', projectId: 'c');
      final leases = <FileBackedPayloadLease>[];
      for (final file in inputs) {
        leases.add(await cStore.stage(
            scope: cScope,
            chunks: file.openRead(),
            byteLength: file.byteLength,
            expectedRawSha256: file.rawSha256));
      }
      c = await CanonicalResourcePackExportService(store: cStore, scope: cScope)
          .exportNative(
              manifest: snapshot.manifest,
              roots: roots,
              smartTilePatternIds: [],
              files: [
                for (var i = 0; i < inputs.length; i++)
                  (
                    inputs[i].id,
                    inputs[i].logicalPath,
                    leases[i].payload,
                    inputs[i].mediaType
                  )
              ],
              metadata: source.metadata(),
              author: 'Next edition',
              expectedRevision: snapshot.revision,
              readCurrentRevision: () async =>
                  (await fixture!.loader.load(fixture.opened.projectHandle))
                      .revision,
              acknowledgeOrganizationRemoval: true);
      expect(c.inspection.catalog.provenance.map((o) => o.author).toSet(),
          {'Alice', 'GLOBAL Publisher'});
      expect(
          c.inspection.manifest.content.files
              .where((f) => f.mediaType == 'text/plain'),
          hasLength(2));
      final preserved = c.inspection.catalog.provenance
          .singleWhere((o) => o.author == 'GLOBAL Publisher');
      expect(preserved.resources, isEmpty);
      expect(preserved.sourceUrl, 'https://example.test/global');
      expect(
          c.inspection.catalog.files.any((f) => f.provenanceId == preserved.id),
          isFalse);
      for (final lease in leases) {
        await cStore.release(scope: cScope, leaseId: lease.leaseId);
      }
    } finally {
      await c?.dispose();
      await archive?.dispose();
      await aStore.close();
      await cStore?.close();
      if (fixture != null) {
        await fixture.close();
        if (!sourceDisposed) await fixture.source.dispose();
      }
      await dir.delete(recursive: true);
    }
  });
  test(
      'import review includes selected media origin documents beyond file licence bindings',
      () async {
    final base = source.mixedFixture();
    final original = originalAttribution(base.$2);
    final extra = fixtureLicense('Bob origin-only additional licence');
    final attribution = NativeResourcePackAttribution(
        provenance: [
          for (final origin in original.provenance)
            ResourcePackProvenance(
                id: origin.id,
                author: origin.author,
                sourceUrl: origin.sourceUrl,
                resources: origin.resources,
                licenseIds: [
                  ...origin.licenseIds,
                  if (origin.author == 'Bob') extra.path
                ])
        ],
        files: original.files,
        licenses: [...original.licenses, extra]);
    final fixture = await ResourcePackImportFixture.create(
        sourceManifest: base.$1,
        sourceFiles: base.$2,
        attribution: attribution);
    try {
      final prepared = await fixture.prepare();
      final expected = attribution.licenses
          .fold<int>(0, (total, document) => total + document.byteLength);
      expect(prepared.review.summary['licenseBytes'], expected);
      expect(
          prepared.installation!.licenses
              .map((document) => document.sourcePath)
              .toSet(),
          attribution.licenses.map((document) => document.path).toSet());
    } finally {
      await fixture.dispose();
    }
  });
  test(
      'native global attribution is scoped to touched installations and includes zero-licence pattern owners',
      () async {
    final base = installationPair();
    final first = base.$1.resourcePackInstallations.entries
        .firstWhere((i) => i.installationId == 'installation-Alice');
    final second = base.$1.resourcePackInstallations.entries
        .firstWhere((i) => i.installationId == 'installation-Bob');
    final document = fixtureLicense('GLOBAL document');
    final path = 'assets/resource_packs/global/${document.path}';
    final json = first.toJson();
    json['origins'] = [
      for (final o in first.origins) o.toJson(),
      ResourcePackProvenance(
          id: 'global',
          author: 'GLOBAL Publisher',
          licenseIds: [document.path]).toJson(),
      ResourcePackProvenance(id: 'zero', author: 'Zero licence', licenseIds: [])
          .toJson(),
      ResourcePackProvenance(
          id: 'mediaonly',
          author: 'MEDIAONLY',
          licenseIds: [document.path]).toJson()
    ];
    json['assets'] = [
      for (final a in first.assets) a.toJson(),
      ResourcePackAssetMapping(
          fileId: 'unselected',
          assetId: 'unselected-media',
          targetPath: 'assets/unselected.png',
          rawSha256: base.$2.first.rawSha256,
          byteLength: base.$2.first.byteLength,
          mediaType: 'image/png',
          provenanceId: 'mediaonly',
          licenseIds: [document.path]).toJson()
    ];
    json['licenses'] = [
      for (final d in first.licenses) d.toJson(),
      ResourcePackLicenseMapping(
              sourcePath: document.path,
              targetPath: path,
              rawSha256: document.rawSha256,
              byteLength: document.byteLength)
          .toJson()
    ];
    json['supports'] = [
      ResourcePackSupportMapping(
              kind: ResourcePackSupportKind.smartTilePattern,
              sourceId: 'portable-pattern',
              targetId: 'standalone')
          .toJson()
    ];
    json['selectedSmartTilePatternIds'] = ['portable-pattern'];
    final neighbourJson = second.toJson();
    neighbourJson['origins'] = [
      for (final o in second.origins) o.toJson(),
      ResourcePackProvenance(
          id: 'neighbour-global',
          author: 'Unreached neighbour',
          licenseIds: second.licenses.map((d) => d.sourcePath)).toJson()
    ];
    final neighbour = ResourcePackInstallation.fromJson(neighbourJson);
    final installed = ResourcePackInstallation.fromJson(json);
    final pattern = ProjectSmartTilePattern(
        id: 'standalone',
        name: 'Erase stamp',
        usage: SmartTileUsage.terrain,
        width: 1,
        height: 1,
        cells: [SmartTilePatternCell(x: 0, y: 0, eraseMaterial: true)]);
    final manifest = base.$1.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog.fromJson({
          ...base.$1.smartTileCatalog.toJson(),
          'patterns': [pattern.toJson()]
        }),
        resourcePackInstallations:
            ResourcePackInstallationCatalog(entries: [installed, neighbour]));
    final files = [
      ...base.$2.where((f) => f.id != 'license-Bob'),
      NativeResourcePackFile(
          id: 'global-document',
          logicalPath: path,
          byteLength: document.byteLength,
          rawSha256: document.rawSha256,
          mediaType: 'text/plain',
          openRead: document.openRead)
    ];
    Future<ResourcePackExportProjection> project(
            {bool patternOnly = false,
            Iterable<NativeResourcePackFile>? sources}) =>
        const ResourcePackProjectionBuilder().project(
            manifest: manifest,
            roots: patternOnly
                ? []
                : [
                    NativeResourcePackRef(
                        kind: ResourcePackKind.tileset, id: 'atlas')
                  ],
            smartTilePatternIds: patternOnly ? ['standalone'] : [],
            files: sources ?? files,
            author: 'Next edition',
            sourceRevision: 'b');
    final selected = await project();
    expect(selected.catalog.provenance.map((o) => o.author).toSet(),
        {'Alice', 'GLOBAL Publisher', 'Zero licence'});
    expect(
        selected.catalog.provenance
            .singleWhere((o) => o.author == 'Zero licence')
            .licenseIds,
        isEmpty);
    expect(selected.sources.where((s) => s.mediaType == 'text/plain'),
        hasLength(2));
    final supportOnly = await project(patternOnly: true);
    expect(supportOnly.catalog.provenance.map((o) => o.author).toSet(),
        {'GLOBAL Publisher', 'Zero licence'});
    expect(supportOnly.catalog.files, isEmpty);
    expect(supportOnly.catalog.smartTilePatternIds, hasLength(1));
    await expectLater(
        project(sources: files.where((f) => f.id != 'global-document')),
        throwsA(isA<FormatException>().having(
            (e) => e.message,
            'reached global document required',
            contains('license_document_missing'))));
  });

  test(
      'projects two original attributions with separate documents and deduplicated image bytes',
      () async {
    final fixture = source.mixedFixture();
    final attribution = originalAttribution(fixture.$2);
    final projection = await const ResourcePackProjectionBuilder().project(
      manifest: fixture.$1,
      files: fixture.$2,
      roots: [
        NativeResourcePackRef(kind: ResourcePackKind.character, id: 'person')
      ],
      author: 'Publisher',
      sourceRevision: 'source-a',
      attribution: attribution,
    );
    expect(projection.catalog.provenance.map((origin) => origin.author).toSet(),
        {'Alice', 'Bob'});
    expect(projection.catalog.files, hasLength(3));
    expect(projection.sources.where((entry) => entry.path.startsWith('blobs/')),
        hasLength(1));
    expect(
        projection.sources.where((entry) => entry.path.startsWith('licenses/')),
        hasLength(2));
    assertOriginalAssociations(projection.catalog);
    final review = projection.review.rows;
    expect(
        review
            .where((row) => row['kind'] == 'source')
            .map((row) => row['label'])
            .toSet(),
        {'Alice', 'Bob'});
    expect(
        review
            .where((row) => row['kind'] == 'license')
            .map((row) => row['path'])
            .toSet(),
        projection.sources
            .where((entry) => entry.mediaType == 'text/plain')
            .map((entry) => entry.path)
            .toSet());
    expect(
        review
            .where((row) => row['kind'] == 'sourceFile')
            .map((row) => '${row['fileId']}:${row['sourceId']}')
            .toSet(),
        projection.catalog.files
            .map((file) => '${file.id}:${file.provenanceId}')
            .toSet());
    expect(
        review
            .where((row) => row['kind'] == 'sourceResource')
            .map((row) =>
                '${row['resourceKind']}:${row['id']}:${row['sourceId']}')
            .toSet(),
        {
          for (final origin in projection.catalog.provenance)
            for (final ref in origin.resources)
              '${ref.kind.name}:${ref.id}:${origin.id}'
        });
  });

  test(
      'A to native B to C preserves exact origins after archives and stages are removed',
      () async {
    final a = source.mixedFixture();
    final directory =
        await Directory.systemTemp.createTemp('p11-attribution-native-');
    final sourceRoot = await Directory('${directory.path}/a').create();
    final projectFile = File('${sourceRoot.path}/project.json');
    await projectFile.writeAsString(jsonEncode(a.$1.toJson()));
    final sourceFiles = <NativeResourcePackFile>[];
    for (final descriptor in a.$2) {
      final file = File('${sourceRoot.path}/${descriptor.logicalPath}');
      await file.parent.create(recursive: true);
      final sink = file.openWrite();
      await sink.addStream(descriptor.openRead());
      await sink.close();
      sourceFiles.add(NativeResourcePackFile(
          id: descriptor.id,
          logicalPath: descriptor.logicalPath,
          byteLength: descriptor.byteLength,
          rawSha256: descriptor.rawSha256,
          mediaType: descriptor.mediaType,
          openRead: file.openRead));
    }
    final before = await sourceFingerprints(a.$1, sourceFiles);
    final projectHash =
        (await sha256.bind(projectFile.openRead()).first).toString();
    final fixture = await NativeResourcePackImportFixture.create(
        sourceManifest: a.$1,
        sourceFiles: sourceFiles,
        attribution: originalAttribution(sourceFiles),
        nativeRoot: Directory('${directory.path}/b'));
    var sourceDisposed = false;
    OwnedResourcePackExport? c;
    LocalResourcePackStore? store;
    try {
      assertOriginalAssociations(fixture.source.archive.inspection.catalog);
      final selected = await fixture.select();
      final prepared = await fixture.prepare(selection: selected);
      expect(prepared.status, ResourcePackPreparedImportStatus.ready);
      await fixture.apply(await fixture.plan(prepared));
      final expectedOriginAssociations = fixture
          .source.archive.inspection.catalog.provenance
          .map((origin) =>
              (origin.author, origin.sourceUrl, jsonEncode(origin.licenseIds)))
          .toSet();
      await fixture.close();
      await fixture.source.dispose();
      sourceDisposed = true;
      expect(await fixture.source.directory.exists(), isFalse);
      await fixture.open();
      final reopened = await fixture.loader.load(fixture.opened.projectHandle);
      final installation =
          reopened.manifest.resourcePackInstallations.entries.single;
      expect(
          installation.origins
              .map((origin) => (
                    origin.author,
                    origin.sourceUrl,
                    jsonEncode(origin.licenseIds)
                  ))
              .toSet(),
          expectedOriginAssociations);
      expect(reopened.manifest.elements, hasLength(2));
      expect(installation.resources, hasLength(8));
      expect(
          installation.resources.map((mapping) => mapping.source.kind).toSet(),
          ResourcePackKind.values.toSet());
      expect(installation.licenses, hasLength(2));
      expect(installation.assets, hasLength(4));
      final candidates = await nativeFiles(reopened, fixture.root);
      final nativeRoots = [
        NativeResourcePackRef(
            kind: ResourcePackKind.character,
            id: reopened.manifest.characters.single.id)
      ];
      final selectedIds = await const ResourcePackProjectionBuilder()
          .selectedFileIds(
              manifest: reopened.manifest,
              roots: nativeRoots,
              files: candidates);
      expect(
          selectedIds,
          candidates
              .where((file) => file.mediaType != 'model/gltf-binary')
              .map((file) => file.id)
              .toSet());
      final selectedCandidates =
          candidates.where((file) => selectedIds.contains(file.id)).toList();
      expect(candidates.where((file) => file.mediaType == 'text/plain'),
          hasLength(2));
      store = LocalResourcePackStore(
          cacheDirectory: '${directory.path}/c-cache', allowedSourceRoots: []);
      const scope = FileBackedPayloadScope(
          sessionId: 'p11-export', projectId: 'native-b');
      final leases = <FileBackedPayloadLease>[];
      for (final file in selectedCandidates) {
        leases.add(await store.stage(
            scope: scope,
            chunks: file.openRead(),
            byteLength: file.byteLength,
            expectedRawSha256: file.rawSha256));
      }
      c = await CanonicalResourcePackExportService(store: store, scope: scope)
          .exportNative(
              manifest: reopened.manifest,
              roots: nativeRoots,
              smartTilePatternIds: [],
              files: [
                for (var i = 0; i < selectedCandidates.length; i++)
                  (
                    selectedCandidates[i].id,
                    selectedCandidates[i].logicalPath,
                    leases[i].payload,
                    selectedCandidates[i].mediaType
                  )
              ],
              metadata: ResourcePackMetadata(
                  id: 'avelune.reexport',
                  version: '1.0.0',
                  name: 'Reexport C',
                  description: '',
                  universeId: 'avelune.test',
                  authors: ['Publisher C'],
                  provenance: 'Selective native reexport'),
              author: 'Publisher C',
              expectedRevision: reopened.revision,
              readCurrentRevision: () async =>
                  (await fixture.loader.load(fixture.opened.projectHandle))
                      .revision,
              acknowledgeOrganizationRemoval: true);
      assertOriginalAssociations(c.inspection.catalog);
      expect(c.inspection.manifest.pack.authors, ['Publisher C']);
      expect(
          c.inspection.manifest.content.files
              .where((file) => file.path.startsWith('blobs/')),
          hasLength(1));
      expect(
          c.inspection.manifest.content.files
              .where((file) => file.path.startsWith('licenses/'))
              .map((file) => (file.path, file.rawSha256, file.byteLength))
              .toSet(),
          installation.licenses
              .map((file) => (file.sourcePath, file.rawSha256, file.byteLength))
              .toSet());
      expect(c.inspection.catalog.elements, isEmpty);
      expect(c.inspection.catalog.models3d, isEmpty);
      expect(await sourceFingerprints(a.$1, sourceFiles), before);
      expect((await sha256.bind(projectFile.openRead()).first).toString(),
          projectHash);
      final license =
          candidates.firstWhere((file) => file.mediaType == 'text/plain');
      await expectLater(
          const ResourcePackProjectionBuilder().selectedFileIds(
              manifest: reopened.manifest,
              roots: nativeRoots,
              files: candidates.where((file) => file.id != license.id)),
          throwsA(isA<FormatException>().having(
              (error) => error.message,
              'missing native document',
              contains('license_document_missing'))));
      final nativeDocument =
          File('${fixture.root.path}/${license.logicalPath}');
      await nativeDocument.writeAsBytes(List.filled(license.byteLength, 120));
      final altered = await const ResourcePackProjectionBuilder().project(
        manifest: reopened.manifest,
        roots: nativeRoots,
        files: candidates,
        author: 'Publisher C',
        sourceRevision: reopened.revision,
      );
      await expectLater(
          altered.sources
              .firstWhere((source) =>
                  source.path == 'licenses/${license.rawSha256}.txt')
              .openRead()
              .drain<void>(),
          throwsA(isA<FormatException>().having(
              (error) => error.message,
              'raw document bytes checked',
              contains('license_document_changed'))));
      for (final lease in leases) {
        await store.release(scope: scope, leaseId: lease.leaseId);
      }
    } finally {
      await c?.dispose();
      await store?.close();
      await fixture.close();
      if (!sourceDisposed) await fixture.source.dispose();
      await directory.delete(recursive: true);
    }
  });

  test(
      'rejects missing and altered original licence documents without inventing replacements',
      () async {
    final a = source.mixedFixture();
    final valid = originalAttribution(a.$2);
    for (final mode in ['missing', 'altered', 'invalid-utf8']) {
      final documents = valid.licenses.toList();
      if (mode == 'missing') documents.removeLast();
      if (mode == 'altered') {
        final original = documents.last;
        documents[documents.length - 1] = ResourcePackBuildSource(
            path: original.path,
            byteLength: original.byteLength,
            rawSha256: original.rawSha256,
            mediaType: original.mediaType,
            openRead: () =>
                Stream.value(List.filled(original.byteLength, 120)));
      }
      var attribution = NativeResourcePackAttribution(
          provenance: valid.provenance,
          files: valid.files,
          licenses: documents);
      if (mode == 'invalid-utf8') {
        final bytes = [255];
        final hash = sha256.convert(bytes).toString();
        final path = 'licenses/$hash.txt';
        attribution = NativeResourcePackAttribution(provenance: [
          ResourcePackProvenance(
              id: 'original', author: 'Alice', licenseIds: [path])
        ], files: [
          for (final file in valid.files)
            ResourcePackFileBinding(
                id: file.id,
                logicalPath: file.logicalPath,
                archivePath: file.archivePath,
                byteLength: file.byteLength,
                mediaType: file.mediaType,
                rawSha256: file.rawSha256,
                provenanceId: 'original',
                licenseIds: [path])
        ], licenses: [
          ResourcePackBuildSource(
              path: path,
              byteLength: 1,
              rawSha256: hash,
              mediaType: 'text/plain',
              openRead: () => Stream.value(bytes))
        ]);
      }
      await expectLater(() async {
        final projection = await const ResourcePackProjectionBuilder().project(
          manifest: a.$1,
          roots: [
            NativeResourcePackRef(
                kind: ResourcePackKind.character, id: 'person')
          ],
          files: a.$2,
          author: 'Publisher',
          sourceRevision: 'a',
          attribution: attribution,
        );
        for (final document in projection.sources
            .where((source) => source.mediaType == 'text/plain')) {
          await document.openRead().drain<void>();
        }
      }, throwsFormatException, reason: mode);
    }
  });

  test(
      'origin IDs are scoped by installation while equal CAS bytes remain reusable',
      () async {
    final fixture = installationPair();
    final builder = const ResourcePackProjectionBuilder();
    final both = await builder.project(
      manifest: fixture.$1,
      roots: [
        NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas'),
        NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas-b')
      ],
      files: fixture.$2,
      author: 'Publisher',
      sourceRevision: 'b',
    );
    expect(both.catalog.provenance.map((origin) => origin.author).toSet(),
        {'Alice', 'Bob'});
    expect(both.catalog.provenance.map((origin) => origin.id).toSet(),
        hasLength(2));
    expect(both.catalog.files, hasLength(2));
    expect(both.sources.where((source) => source.path.startsWith('blobs/')),
        hasLength(1));
    expect(both.sources.where((source) => source.path.startsWith('licenses/')),
        hasLength(2));
    final onlyA = await builder.project(
      manifest: fixture.$1,
      roots: [
        NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas')
      ],
      files: fixture.$2,
      author: 'Publisher',
      sourceRevision: 'b',
    );
    expect(onlyA.catalog.provenance.map((origin) => origin.author), ['Alice']);
    expect(onlyA.sources.where((source) => source.path.startsWith('licenses/')),
        hasLength(1));
    expect(onlyA.catalog.files, hasLength(1));
    final conflict = installationPair(sharedAlias: true);
    await expectLater(
        builder.project(
          manifest: conflict.$1,
          roots: [
            NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas'),
            NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas-b')
          ],
          files: conflict.$2,
          author: 'Publisher',
          sourceRevision: 'b',
        ),
        throwsA(isA<FormatException>().having((error) => error.message,
            'explicit ambiguity', contains('attribution_ambiguous'))));
  });

  test('local global credits remain distinct from preserved original bindings',
      () async {
    final fixture = installationPair();
    final projection = await const ResourcePackProjectionBuilder().project(
      manifest: fixture.$1,
      roots: [
        NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas')
      ],
      files: fixture.$2,
      author: 'Local publisher',
      sourceUrl: 'https://example.test/publisher',
      localLicenses: [fixtureLicense('Local added credit')],
      sourceRevision: 'b',
    );
    final local = projection.catalog.provenance
        .singleWhere((origin) => origin.author == 'Local publisher');
    final original = projection.catalog.provenance
        .singleWhere((origin) => origin.author == 'Alice');
    expect(local.resources, isEmpty);
    expect(
        projection.review.rows.singleWhere((row) =>
            row['kind'] == 'source' &&
            row['id'] == local.id)['attributionScope'],
        'globalCredits');
    expect(
        projection.review.rows.singleWhere((row) =>
            row['kind'] == 'source' &&
            row['id'] == original.id)['attributionScope'],
        'resourceOrFileAttribution');
    expect(local.licenseIds, isNot(original.licenseIds));
    expect(projection.catalog.files.single.provenanceId, original.id);
    expect(projection.catalog.files.single.licenseIds, original.licenseIds);
    expect(
        projection.sources
            .where((source) => source.path.startsWith('licenses/')),
        hasLength(2));
  });

  test(
      'deduplicates identical licence text without coalescing original authors',
      () async {
    final base = source.mixedFixture();
    final original = originalAttribution(base.$2);
    final document = original.licenses.first;
    final attribution = NativeResourcePackAttribution(provenance: [
      for (final origin in original.provenance)
        ResourcePackProvenance(
            id: origin.id,
            author: origin.author,
            sourceUrl: origin.sourceUrl,
            licenseIds: [document.path],
            resources: origin.resources)
    ], files: [
      for (final file in original.files)
        ResourcePackFileBinding(
            id: file.id,
            logicalPath: file.logicalPath,
            archivePath: file.archivePath,
            byteLength: file.byteLength,
            mediaType: file.mediaType,
            rawSha256: file.rawSha256,
            provenanceId: file.provenanceId,
            licenseIds: [document.path])
    ], licenses: [
      document
    ]);
    final projection = await const ResourcePackProjectionBuilder().project(
      manifest: base.$1,
      roots: [
        NativeResourcePackRef(kind: ResourcePackKind.character, id: 'person')
      ],
      files: base.$2,
      attribution: attribution,
      author: 'Publisher',
      sourceRevision: 'a',
    );
    expect(projection.catalog.provenance.map((origin) => origin.author).toSet(),
        {'Alice', 'Bob'});
    expect(
        projection.sources
            .where((source) => source.path.startsWith('licenses/')),
        hasLength(1));
    expect(
        projection.catalog.files
            .every((file) => file.licenseIds.single == document.path),
        isTrue);
  });

  test(
      'importCopy retains equivalent Border snapshot attributions without merging resource origins',
      () async {
    final original = await source.spriteFixture();
    final fixture = await NativeResourcePackImportFixture.create(
        sourceManifest: original.$1,
        sourceFiles: original.$2,
        roots: [
          NativeResourcePackRef(
              kind: ResourcePackKind.borderBlueprint, id: 'sprite')
        ]);
    try {
      final portable = ResourcePackRef(
          kind: ResourcePackKind.borderBlueprint,
          id: fixture.source.archive.inspection.catalog.borderCatalog.records
              .single.id);
      final prepared = await fixture.prepare(
          selection: await fixture.select(roots: [portable]));
      expect(prepared.status, ResourcePackPreparedImportStatus.ready);
      await fixture.apply(await fixture.plan(prepared));
      final baseline = await fixture.loader.load(fixture.opened.projectHandle);
      final nativeId = baseline.manifest.borderCatalog.records.single.id;
      final roots = [
        NativeResourcePackRef(
            kind: ResourcePackKind.borderBlueprint, id: nativeId)
      ];
      final before = await const ResourcePackProjectionBuilder().project(
        manifest: baseline.manifest,
        roots: roots,
        files: await nativeFiles(baseline, fixture.root),
        author: 'Publisher',
        sourceRevision: baseline.revision,
      );
      expect(before.catalog.borderCatalog.records, hasLength(1));
      final copy = await fixture.prepare(
          selection: await fixture.select(roots: [portable]),
          policy: ResourcePackConflictPolicy.importCopy);
      expect(copy.status, ResourcePackPreparedImportStatus.ready);
      await fixture.apply(await fixture.plan(copy));
      final after = await fixture.loader.load(fixture.opened.projectHandle);
      final installs = after.manifest.resourcePackInstallations.entries;
      expect(installs, hasLength(2));
      expect(
          installs
              .map((installation) => jsonEncode(installation.origins
                  .map((origin) => {
                        'id': origin.id,
                        'author': origin.author,
                        'sourceUrl': origin.sourceUrl,
                        'licenseIds': origin.licenseIds
                      })
                  .toList()))
              .toSet(),
          hasLength(1));
      final sharedAssets = installs.first.assets
          .map((mapping) => mapping.assetId)
          .toSet()
          .intersection(
              installs.last.assets.map((mapping) => mapping.assetId).toSet());
      expect(sharedAssets, hasLength(1));
      final files = await nativeFiles(after, fixture.root);
      Future<ResourcePackExportProjection> project(
              List<NativeResourcePackRef> roots,
              {ProjectManifest? manifest}) =>
          const ResourcePackProjectionBuilder().project(
            manifest: manifest ?? after.manifest,
            roots: roots,
            files: files,
            author: 'Publisher',
            sourceRevision: after.revision,
          );
      final reexport = await project(roots);
      expect(reexport.catalog.borderCatalog.records, hasLength(1));
      expect(reexport.catalog.provenance, hasLength(1));
      expect(reexport.catalog.provenance.single.author, 'Original');
      expect(
          reexport.sources
              .where((source) => source.path.startsWith('licenses/')),
          hasLength(1));
      final required = await const ResourcePackProjectionBuilder()
          .selectedFileIds(
              manifest: after.manifest, roots: roots, files: files);
      expect(
          required.intersection(files
              .where((file) => file.mediaType == 'text/plain')
              .map((file) => file.id)
              .toSet()),
          hasLength(1));
      final installedCopy =
          installs.singleWhere((installation) => installation.copyOrdinal == 1);
      for (final conflict in [
        'sourceUrl',
        'originLicenses',
        'bindingLicenses'
      ]) {
        final changed = Map<String, Object?>.from(
            jsonDecode(jsonEncode(installedCopy.toJson())) as Map);
        if (conflict == 'bindingLicenses') {
          for (final asset in changed['assets'] as List) {
            if (sharedAssets.contains((asset as Map)['assetId'])) {
              asset['licenseIds'] = <String>[];
            }
          }
        } else {
          for (final origin in changed['origins'] as List) {
            if (conflict == 'sourceUrl') {
              (origin as Map)['sourceUrl'] =
                  'https://example.test/different-source';
            }
            if (conflict == 'originLicenses') {
              (origin as Map)['licenseIds'] = <String>[];
            }
          }
        }
        final contradictory = after.manifest.copyWith(
            resourcePackInstallations:
                ResourcePackInstallationCatalog(entries: [
          for (final installation in installs)
            installation.installationId == installedCopy.installationId
                ? ResourcePackInstallation.fromJson(changed)
                : installation
        ]));
        await expectLater(
            project(roots, manifest: contradictory),
            throwsA(isA<FormatException>().having(
                (error) => error.message,
                'complete declaration remains strict',
                contains('attribution_ambiguous'))),
            reason: conflict);
      }
      final bothRoots = [
        for (final record in after.manifest.borderCatalog.records)
          NativeResourcePackRef(
              kind: ResourcePackKind.borderBlueprint, id: record.id)
      ];
      final both = await project(bothRoots);
      expect(both.catalog.provenance, hasLength(2));
      expect(both.catalog.provenance.map((origin) => origin.id).toSet(),
          hasLength(2));
      expect(
          both.catalog.provenance.every((origin) => origin.resources
              .any((ref) => ref.kind == ResourcePackKind.borderBlueprint)),
          isTrue);
      final reverse = await project(bothRoots.reversed.toList(),
          manifest: after.manifest.copyWith(
              resourcePackInstallations:
                  ResourcePackInstallationCatalog(entries: installs.reversed)));
      expect(reverse.catalog, both.catalog);
      final resourcesByOrigin = {
        for (final origin in both.catalog.provenance)
          origin.id: origin.resources.map((ref) => ref.identity).toSet()
      };
      expect(
          resourcesByOrigin.values
              .toList()[0]
              .intersection(resourcesByOrigin.values.toList()[1]),
          isEmpty);
    } finally {
      await fixture.dispose();
    }
  });

  test(
      'native import retains declared provenance and licence descriptors after reopen',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    try {
      final prepared = await fixture.prepare();
      await fixture.apply(await fixture.plan(prepared));
      await fixture.close();
      await fixture.open();
      final native =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      final json = native.resourcePackInstallations.entries.single.toJson();
      expect(json['origins'], isNotEmpty);
      expect(json['licenses'], isNotEmpty);
      expect(
          (json['assets'] as List)
              .every((value) => (value as Map)['provenanceId'] != null),
          isTrue);
      expect(ProjectManifest.fromJson(native.toJson()), native);
    } finally {
      await fixture.dispose();
    }
  });
}

NativeResourcePackAttribution originalAttribution(
    List<NativeResourcePackFile> files) {
  final documents =
      ['Alice original licence', 'Bob original licence'].map((text) {
    final bytes = utf8.encode(text);
    final hash = sha256.convert(bytes).toString();
    return ResourcePackBuildSource(
        path: 'licenses/$hash.txt',
        byteLength: bytes.length,
        rawSha256: hash,
        mediaType: 'text/plain',
        openRead: () => Stream.value(bytes));
  }).toList();
  return NativeResourcePackAttribution(provenance: [
    ResourcePackProvenance(
        id: 'alice',
        author: 'Alice',
        sourceUrl: 'https://example.test/alice',
        licenseIds: [
          documents[0].path
        ],
        resources: [
          ResourcePackRef(kind: ResourcePackKind.character, id: 'person'),
          ResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas'),
          ResourcePackRef(kind: ResourcePackKind.element, id: 'decor'),
          ResourcePackRef(kind: ResourcePackKind.element, id: 'second'),
          ResourcePackRef(kind: ResourcePackKind.model3d, id: 'model'),
          ResourcePackRef(kind: ResourcePackKind.smartTilePreset, id: 'sol'),
          ResourcePackRef(kind: ResourcePackKind.borderBlueprint, id: 'border'),
          ResourcePackRef(
              kind: ResourcePackKind.environmentPreset, id: 'environment')
        ]),
    ResourcePackProvenance(
        id: 'bob',
        author: 'Bob',
        sourceUrl: 'https://example.test/bob',
        licenseIds: [documents[1].path],
        resources: []),
  ], files: [
    for (final file in files)
      ResourcePackFileBinding(
          id: file.id,
          logicalPath: file.logicalPath,
          archivePath:
              'blobs/${file.rawSha256}.${file.mediaType == 'image/png' ? 'png' : 'glb'}',
          byteLength: file.byteLength,
          mediaType: file.mediaType,
          rawSha256: file.rawSha256,
          provenanceId: file.id == 'portrait' || file.id == 'animation' ? 'bob' : 'alice',
          licenseIds: [
            documents[file.id == 'portrait' || file.id == 'animation' ? 1 : 0]
                .path
          ])
  ], licenses: documents);
}

void assertOriginalAssociations(ResourcePackCatalog catalog) {
  final origins = {for (final origin in catalog.provenance) origin.id: origin};
  expect(
      origins.values.map((origin) => origin.author).toSet(), {'Alice', 'Bob'});
  expect(
      origins.values
          .singleWhere((origin) => origin.author == 'Alice')
          .resources
          .toSet(),
      {
        for (final resource in catalog.characters)
          ResourcePackRef(kind: ResourcePackKind.character, id: resource.id),
        for (final resource in catalog.tilesets)
          ResourcePackRef(kind: ResourcePackKind.tileset, id: resource.id),
        for (final resource in catalog.elements)
          ResourcePackRef(kind: ResourcePackKind.element, id: resource.id),
        for (final resource in catalog.models3d)
          ResourcePackRef(kind: ResourcePackKind.model3d, id: resource.id),
        for (final resource in catalog.smartTileCatalog.presets)
          ResourcePackRef(
              kind: ResourcePackKind.smartTilePreset, id: resource.id),
        for (final resource in catalog.borderCatalog.records)
          ResourcePackRef(
              kind: ResourcePackKind.borderBlueprint, id: resource.id),
        for (final resource in catalog.environmentPresets)
          ResourcePackRef(
              kind: ResourcePackKind.environmentPreset, id: resource.id),
      });
  expect(
      origins.values.singleWhere((origin) => origin.author == 'Bob').resources,
      isEmpty);
  final bobIds = {
    for (final character in catalog.characters) ...[
      for (final portrait in character.portraits) portrait.assetId,
      for (final animation in character.customAnimations)
        animation.sourceAssetId
    ]
  };
  for (final file in catalog.files) {
    final expected = bobIds.contains(file.id) ? 'Bob' : 'Alice';
    final origin = origins[file.provenanceId]!;
    expect(origin.author, expected);
    expect(origin.sourceUrl, 'https://example.test/${expected.toLowerCase()}');
    expect(file.licenseIds, origin.licenseIds);
    final expectedHash =
        sha256.convert(utf8.encode('$expected original licence')).toString();
    expect(file.licenseIds, ['licenses/$expectedHash.txt']);
  }
}

Future<Map<String, String>> sourceFingerprints(
        ProjectManifest manifest, List<NativeResourcePackFile> files) async =>
    {
      'manifest':
          sha256.convert(utf8.encode(jsonEncode(manifest.toJson()))).toString(),
      for (final file in files)
        file.logicalPath: (await sha256.bind(file.openRead()).first).toString(),
    };

Future<List<NativeResourcePackFile>> nativeFiles(
    ProjectSnapshot snapshot, Directory root) async {
  final catalog = AssetCatalog.fromJson(Map<String, dynamic>.from(jsonDecode(
      utf8.decode(
          snapshot.findResourceBytes(assetCatalogResourceIdentity)!)) as Map));
  return [
    for (final record in catalog.records)
      NativeResourcePackFile(
          id: record.id,
          logicalPath: record.logicalPath,
          byteLength: record.artifact.byteLength,
          rawSha256: (await sha256
                  .bind(File('${root.path}/${record.logicalPath}').openRead())
                  .first)
              .toString(),
          mediaType: record.artifact.mediaType,
          openRead: File('${root.path}/${record.logicalPath}').openRead)
  ];
}

(ProjectManifest, List<NativeResourcePackFile>) installationPair(
    {bool sharedAlias = false}) {
  final base = source.mixedFixture();
  final image = base.$2.singleWhere((file) => file.id == 'image');
  final imageB = sharedAlias
      ? image
      : NativeResourcePackFile(
          id: 'image-b',
          logicalPath: 'assets/second.png',
          byteLength: image.byteLength,
          rawSha256: image.rawSha256,
          mediaType: image.mediaType,
          openRead: image.openRead);
  final declarations = originalAttribution(base.$2);
  final nativeDocuments = <NativeResourcePackFile>[];
  ResourcePackInstallation installation(String author, String target,
      NativeResourcePackFile media, ResourcePackBuildSource document) {
    final origin = ResourcePackProvenance(
        id: 'declared',
        author: author,
        sourceUrl: 'https://example.test/${author.toLowerCase()}',
        licenseIds: [
          document.path
        ],
        resources: [
          ResourcePackRef(kind: ResourcePackKind.tileset, id: 'portable')
        ]);
    final path =
        'assets/resource_packs/${author.toLowerCase()}/${document.path}';
    nativeDocuments.add(NativeResourcePackFile(
        id: 'license-$author',
        logicalPath: path,
        byteLength: document.byteLength,
        rawSha256: document.rawSha256,
        mediaType: 'text/plain',
        openRead: document.openRead));
    return ResourcePackInstallation(
        installationId: 'installation-$author',
        packId: 'avelune.${author.toLowerCase()}',
        packVersion: '1.0.0',
        universeId: 'avelune.test',
        archiveRawSha256: 'a' * 64,
        catalogRawSha256: 'b' * 64,
        copyOrdinal: 0,
        selectedRoots: origin.resources,
        resources: [
          ResourcePackResourceMapping(
              source: origin.resources.single,
              targetId: target,
              definitionRawSha256: 'c' * 64)
        ],
        supports: [],
        assets: [
          ResourcePackAssetMapping(
              fileId: 'media',
              assetId: media.id,
              targetPath: media.logicalPath,
              rawSha256: media.rawSha256,
              byteLength: media.byteLength,
              mediaType: media.mediaType,
              provenanceId: origin.id,
              licenseIds: origin.licenseIds)
        ],
        origins: [origin],
        licenses: [
          ResourcePackLicenseMapping(
              sourcePath: document.path,
              targetPath: path,
              rawSha256: document.rawSha256,
              byteLength: document.byteLength)
        ],
        installedAtUtc: '2026-10-17T00:00:00.000Z',
        provenanceStatus: ResourcePackProvenanceStatus.declared);
  }

  final first = installation('Alice', 'atlas', image, declarations.licenses[0]);
  final second =
      installation('Bob', 'atlas-b', imageB, declarations.licenses[1]);
  return (
    base.$1.copyWith(
        tilesets: [
          base.$1.tilesets.single,
          base.$1.tilesets.single.copyWith(
              id: 'atlas-b',
              relativePath: imageB.logicalPath,
              source: ProjectTilesetSource.regularAtlas(
                  assetId: imageB.id,
                  pixelWidth: 4,
                  pixelHeight: 4,
                  tileWidth: 2,
                  tileHeight: 2))
        ],
        resourcePackInstallations:
            ResourcePackInstallationCatalog(entries: [first, second])),
    [image, if (!sharedAlias) imageB, ...nativeDocuments]
  );
}
