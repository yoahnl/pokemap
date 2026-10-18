import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'resource_pack_export_test.dart' as source;
import 'resource_pack_import_fixture.dart';

void main() {
  ProjectManifest dynamicProject() {
    final mixed = source.mixedFixture();
    return PortableCatalogPublication.withProjectDynamicDependencies(mixed.$1, [
      CatalogDynamicDependency(
          owner: CatalogDefinitionKey(CatalogDefinitionKind.element, 'decor'),
          targets: [
            CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'model')
          ]),
    ]);
  }

  test('native selection follows an explicitly declared model dependency',
      () async {
    final manifest = dynamicProject();
    final files = source.mixedFixture().$2;
    final selected = await ResourcePackProjectionBuilder().selectedFileIds(
        manifest: manifest,
        roots: [
          NativeResourcePackRef(kind: ResourcePackKind.element, id: 'decor')
        ],
        files: files);
    expect(selected, contains(manifest.models3d.single.sourceAssetId));
    final projection = await ResourcePackProjectionBuilder().project(
        manifest: manifest,
        roots: [
          NativeResourcePackRef(kind: ResourcePackKind.element, id: 'decor')
        ],
        files: files,
        author: 'Original',
        sourceRevision: 'revision',
        localLicenses: [fixtureLicense('Original licence')]);
    expect(projection.catalog.models3d, hasLength(1));
    final declaration = projection.catalog.dynamicDependencies.single;
    expect(declaration.owner.id, projection.catalog.elements.single.id);
    expect(
        declaration.targets.single.id, projection.catalog.models3d.single.id);
  });

  test('native import remaps declarations and preserves them on reexport',
      () async {
    final fixture = await NativeResourcePackImportFixture.create(
        sourceManifest: dynamicProject(),
        sourceFiles: source.mixedFixture().$2,
        roots: [
          NativeResourcePackRef(kind: ResourcePackKind.element, id: 'decor')
        ]);
    try {
      final element = fixture.source.archive.inspection.catalog.elements.single;
      final selected = await fixture.select(roots: [
        ResourcePackRef(kind: ResourcePackKind.element, id: element.id)
      ]);
      await fixture.apply(
          await fixture.plan(await fixture.prepare(selection: selected)));
      final snapshot = await fixture.loader.load(fixture.opened.projectHandle);
      final installed = snapshot.manifest;
      expect(installed.models3d, hasLength(1));
      final declaration =
          PortableCatalogPublication.projectDynamicDependencies(installed)
              .single;
      expect(declaration.owner.id, installed.elements.single.id);
      expect(declaration.targets.single.id, installed.models3d.single.id);
      final installation = installed.resourcePackInstallations.entries.single;
      final files = <NativeResourcePackFile>[
        for (final asset in installation.assets)
          NativeResourcePackFile(
              id: asset.assetId,
              logicalPath: asset.targetPath,
              byteLength: asset.byteLength,
              rawSha256: asset.rawSha256,
              mediaType: asset.mediaType,
              openRead: () =>
                  File('${fixture.root.path}/${asset.targetPath}').openRead()),
        for (final license in installation.licenses)
          NativeResourcePackFile(
              id: 'license_${license.rawSha256}',
              logicalPath: license.targetPath,
              byteLength: license.byteLength,
              rawSha256: license.rawSha256,
              mediaType: 'text/plain',
              openRead: () => File('${fixture.root.path}/${license.targetPath}')
                  .openRead()),
      ];
      final projected = await ResourcePackProjectionBuilder().project(
          manifest: installed,
          roots: [
            NativeResourcePackRef(
                kind: ResourcePackKind.element,
                id: installed.elements.single.id)
          ],
          files: files,
          author: 'Original',
          sourceRevision: snapshot.revision);
      expect(projected.catalog.dynamicDependencies, hasLength(1));
      expect(projected.catalog.models3d, hasLength(1));
      expect(
          projected.catalog.files.map((file) => file.rawSha256).toSet(),
          fixture.source.archive.inspection.catalog.files
              .map((file) => file.rawSha256)
              .toSet());
    } finally {
      await fixture.dispose();
    }
  });

  test(
      'dynamic Border snapshot identities survive native export import reexport',
      () async {
    final sourceFixture = await source.spriteFixture();
    final originalSnapshot =
        sourceFixture.$1.borderCatalog.visualSnapshots.first;
    final originalSnapshotKey = CatalogDefinitionKey(
        CatalogDefinitionKind.borderVisualSnapshot, originalSnapshot.id);
    final manifest = PortableCatalogPublication.withProjectDynamicDependencies(
        sourceFixture.$1, [
      CatalogDynamicDependency(
          owner: CatalogDefinitionKey(CatalogDefinitionKind.element, 'decor'),
          targets: [originalSnapshotKey]),
      CatalogDynamicDependency(owner: originalSnapshotKey, targets: [
        CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'atlas'),
      ]),
    ]);
    final fixture = await NativeResourcePackImportFixture.create(
        sourceManifest: manifest,
        sourceFiles: sourceFixture.$2,
        roots: [
          NativeResourcePackRef(kind: ResourcePackKind.element, id: 'decor')
        ]);
    try {
      final catalog = fixture.source.archive.inspection.catalog;
      final portableSnapshotKey = CatalogDefinitionKey(
          CatalogDefinitionKind.borderVisualSnapshot,
          resourcePackBorderSnapshotAlias(originalSnapshot.contentFingerprint));
      expect(catalog.dynamicDependencies.first.targets,
          contains(portableSnapshotKey));
      expect(catalog.dynamicDependencies.last.owner, portableSnapshotKey);
      final selection = await fixture.select(roots: [
        ResourcePackRef(
            kind: ResourcePackKind.element, id: catalog.elements.single.id),
      ]);
      await fixture.apply(
          await fixture.plan(await fixture.prepare(selection: selection)));
      final installed =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      final snapshot = installed.borderCatalog.visualSnapshots.single;
      expect(snapshot.id, originalSnapshot.id);
      final declarations =
          PortableCatalogPublication.projectDynamicDependencies(installed);
      expect(
          declarations.map((declaration) => declaration.owner),
          contains(CatalogDefinitionKey(
              CatalogDefinitionKind.borderVisualSnapshot, snapshot.id)));
      PortableCatalogPublication.encodeProject(installed);
      final installation = installed.resourcePackInstallations.entries.single;
      final files = [
        for (final asset in installation.assets)
          NativeResourcePackFile(
              id: asset.assetId,
              logicalPath: asset.targetPath,
              byteLength: asset.byteLength,
              rawSha256: asset.rawSha256,
              mediaType: asset.mediaType,
              openRead: () =>
                  File('${fixture.root.path}/${asset.targetPath}').openRead()),
        for (final license in installation.licenses)
          NativeResourcePackFile(
              id: 'license_${license.rawSha256}',
              logicalPath: license.targetPath,
              byteLength: license.byteLength,
              rawSha256: license.rawSha256,
              mediaType: 'text/plain',
              openRead: () => File('${fixture.root.path}/${license.targetPath}')
                  .openRead()),
      ];
      final exported = await ResourcePackProjectionBuilder().project(
          manifest: installed,
          roots: [
            NativeResourcePackRef(
                kind: ResourcePackKind.element,
                id: installed.elements.single.id)
          ],
          files: files,
          author: 'Original',
          sourceRevision: 'revision');
      expect(exported.catalog.dynamicDependencies, hasLength(2));
      expect(
          exported.catalog.dynamicDependencies
              .map((declaration) => declaration.owner),
          contains(portableSnapshotKey));
      expect(
          exported
              .catalog.borderCatalog.visualSnapshots.single.contentFingerprint,
          originalSnapshot.contentFingerprint);
      PortableCatalogPublication.encodeCatalog(exported.catalog);
    } finally {
      await fixture.dispose();
    }
  });

  test('two packs union dynamic targets owned by one immutable snapshot',
      () async {
    final original = await source.spriteFixture();
    final snapshotKey = CatalogDefinitionKey(
        CatalogDefinitionKind.borderVisualSnapshot,
        original.$1.borderCatalog.visualSnapshots.first.id);
    final manifest =
        PortableCatalogPublication.withProjectDynamicDependencies(original.$1, [
      CatalogDynamicDependency(
          owner: CatalogDefinitionKey(CatalogDefinitionKind.element, 'decor'),
          targets: [snapshotKey]),
      CatalogDynamicDependency(owner: snapshotKey, targets: [
        CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'atlas'),
      ]),
    ]);
    final fixture = await NativeResourcePackImportFixture.create(
        sourceManifest: manifest,
        sourceFiles: original.$2,
        roots: [
          NativeResourcePackRef(kind: ResourcePackKind.element, id: 'decor')
        ]);
    final second = await ResourcePackImportFixture.create(
        sourceManifest: manifest,
        sourceFiles: original.$2,
        roots: [
          NativeResourcePackRef(kind: ResourcePackKind.element, id: 'decor')
        ],
        metadata: ResourcePackMetadata.fromJson({
          ...source.metadata().toJson(),
          'id': 'original.second',
        }));
    try {
      final firstSelection = await fixture.select(roots: [
        ResourcePackRef(
            kind: ResourcePackKind.element,
            id: fixture.source.archive.inspection.catalog.elements.single.id)
      ]);
      await fixture.apply(
          await fixture.plan(await fixture.prepare(selection: firstSelection)));
      final store = fixture.mutations
          .resourcePackPayloadStore(fixture.opened.projectHandle);
      final staged = await second.archive.withSource((input) => store.stage(
          scope: fixture.preparer.scope,
          byteLength: input.length,
          chunks: sourceChunks(input)));
      final secondSelection = await fixture.preparer
          .select(archiveHandle: staged.payload.handle, roots: [
        ResourcePackRef(
            kind: ResourcePackKind.element,
            id: second.archive.inspection.catalog.elements.single.id)
      ]);
      await fixture.apply(await fixture
          .plan(await fixture.prepare(selection: secondSelection)));
      final installed =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      final declarations =
          PortableCatalogPublication.projectDynamicDependencies(installed);
      expect(
          declarations.where((declaration) => declaration.owner == snapshotKey),
          hasLength(1));
      expect(
          declarations
              .singleWhere((declaration) => declaration.owner == snapshotKey)
              .targets
              .toSet(),
          installed.tilesets
              .map((tileset) => CatalogDefinitionKey(
                  CatalogDefinitionKind.tileset, tileset.id))
              .toSet());
      PortableCatalogPublication.encodeProject(installed);
      final byPath = <String, NativeResourcePackFile>{};
      for (final installation in installed.resourcePackInstallations.entries) {
        for (final asset in installation.assets) {
          byPath.putIfAbsent(
              asset.targetPath,
              () => NativeResourcePackFile(
                  id: asset.assetId,
                  logicalPath: asset.targetPath,
                  byteLength: asset.byteLength,
                  rawSha256: asset.rawSha256,
                  mediaType: asset.mediaType,
                  openRead: () =>
                      File('${fixture.root.path}/${asset.targetPath}')
                          .openRead()));
        }
        for (final license in installation.licenses) {
          byPath.putIfAbsent(
              license.targetPath,
              () => NativeResourcePackFile(
                  id:
                      'license_${license.rawSha256}_${installation.installationId}',
                  logicalPath: license.targetPath,
                  byteLength: license.byteLength,
                  rawSha256: license.rawSha256,
                  mediaType: 'text/plain',
                  openRead: () =>
                      File('${fixture.root.path}/${license.targetPath}')
                          .openRead()));
        }
      }
      final exported = await ResourcePackProjectionBuilder().project(
          manifest: installed,
          roots: [
            NativeResourcePackRef(
                kind: ResourcePackKind.element, id: installed.elements.first.id)
          ],
          files: byPath.values,
          author: 'Original',
          sourceRevision: 'revision');
      expect(exported.catalog.tilesets, hasLength(2));
      expect(
          exported.catalog.dynamicDependencies
              .singleWhere((declaration) =>
                  declaration.owner.kind ==
                  CatalogDefinitionKind.borderVisualSnapshot)
              .targets,
          hasLength(2));
      PortableCatalogPublication.encodeCatalog(exported.catalog);
      for (final selection in [firstSelection, secondSelection]) {
        expect((await fixture.prepare(selection: selection)).status,
            ResourcePackPreparedImportStatus.alreadyInstalled);
      }
    } finally {
      await second.dispose();
      await fixture.dispose();
    }
  });

  test('missing and cyclic declared references fail during native selection',
      () async {
    final manifest = dynamicProject();
    for (final declarations in [
      [
        CatalogDynamicDependency(
            owner: CatalogDefinitionKey(CatalogDefinitionKind.element, 'decor'),
            targets: [
              CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'missing')
            ])
      ],
      [
        ...PortableCatalogPublication.projectDynamicDependencies(manifest),
        CatalogDynamicDependency(
            owner: CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'model'),
            targets: [
              CatalogDefinitionKey(CatalogDefinitionKind.element, 'decor')
            ])
      ],
    ]) {
      await expectLater(
          ResourcePackProjectionBuilder().selectedFileIds(
              manifest:
                  PortableCatalogPublication.withProjectDynamicDependencies(
                      manifest, declarations),
              roots: [
                NativeResourcePackRef(
                    kind: ResourcePackKind.element, id: 'decor')
              ],
              files: source.mixedFixture().$2),
          throwsA(isA<FormatException>()));
    }
  });

  test('two individually valid packs cannot compose a shared snapshot cycle',
      () async {
    final original = await source.spriteFixture(margins: true);
    expect(original.$1.borderCatalog.visualSnapshots.length,
        greaterThanOrEqualTo(2));
    final snapshots = original.$1.borderCatalog.visualSnapshots;
    final a = CatalogDefinitionKey(
        CatalogDefinitionKind.borderVisualSnapshot, snapshots[0].id);
    final b = CatalogDefinitionKey(
        CatalogDefinitionKind.borderVisualSnapshot, snapshots[1].id);
    ProjectManifest project(
            CatalogDefinitionKey owner, CatalogDefinitionKey target) =>
        PortableCatalogPublication.withProjectDynamicDependencies(original.$1, [
          CatalogDynamicDependency(
              owner:
                  CatalogDefinitionKey(CatalogDefinitionKind.element, 'decor'),
              targets: [owner]),
          CatalogDynamicDependency(owner: owner, targets: [target]),
        ]);
    final fixture = await NativeResourcePackImportFixture.create(
        sourceManifest: project(a, b),
        sourceFiles: original.$2,
        roots: [
          NativeResourcePackRef(kind: ResourcePackKind.element, id: 'decor'),
        ]);
    final second = await ResourcePackImportFixture.create(
        sourceManifest: project(b, a),
        sourceFiles: original.$2,
        roots: [
          NativeResourcePackRef(kind: ResourcePackKind.element, id: 'decor'),
        ],
        metadata: ResourcePackMetadata.fromJson({
          ...source.metadata().toJson(),
          'id': 'original.cycle',
        }));
    try {
      final first = await fixture.select(roots: [
        ResourcePackRef(
            kind: ResourcePackKind.element,
            id: fixture.source.archive.inspection.catalog.elements.single.id),
      ]);
      await fixture
          .apply(await fixture.plan(await fixture.prepare(selection: first)));
      final before = await fixture.loader.load(fixture.opened.projectHandle);
      final store = fixture.mutations
          .resourcePackPayloadStore(fixture.opened.projectHandle);
      final staged = await second.archive.withSource((input) => store.stage(
          scope: fixture.preparer.scope,
          byteLength: input.length,
          chunks: sourceChunks(input)));
      final selection = await fixture.preparer
          .select(archiveHandle: staged.payload.handle, roots: [
        ResourcePackRef(
            kind: ResourcePackKind.element,
            id: second.archive.inspection.catalog.elements.single.id),
      ]);
      Object result;
      try {
        result = (await fixture.prepare(selection: selection)).status;
      } on FormatException catch (error) {
        result = error;
      } on ResourcePackDependencyException catch (error) {
        result = error;
      }
      expect(result, isNot(ResourcePackPreparedImportStatus.ready));
      expect((await fixture.loader.load(fixture.opened.projectHandle)).revision,
          before.revision);
    } finally {
      await second.dispose();
      await fixture.dispose();
    }
  });

  test(
      'two native packs keep independent dynamic namespaces and local metadata',
      () async {
    final fixture = await NativeResourcePackImportFixture.create(
      sourceManifest: dynamicProject(),
      sourceFiles: source.mixedFixture().$2,
      roots: [
        NativeResourcePackRef(kind: ResourcePackKind.element, id: 'decor'),
      ],
      target: ProjectManifest(
        name: 'Two packs',
        maps: [],
        tilesets: [],
        settings: ProjectSettings(tileWidth: 2, tileHeight: 2),
        globalProperties: {
          'localFeature': {
            'enabled': true,
            'labels': ['keep', 'local']
          },
        },
      ),
    );
    final second = await ResourcePackImportFixture.create(
      sourceManifest: dynamicProject(),
      sourceFiles: source.mixedFixture().$2,
      roots: [
        NativeResourcePackRef(kind: ResourcePackKind.element, id: 'decor'),
      ],
      metadata: ResourcePackMetadata.fromJson({
        ...source.metadata().toJson(),
        'id': 'original.second',
      }),
    );
    try {
      final firstCatalog = fixture.source.archive.inspection.catalog;
      final secondCatalog = second.archive.inspection.catalog;
      expect(secondCatalog.elements.single.id, firstCatalog.elements.single.id);
      expect(secondCatalog.models3d.single.id, firstCatalog.models3d.single.id);
      expect(secondCatalog.files.map((file) => file.rawSha256).toSet(),
          firstCatalog.files.map((file) => file.rawSha256).toSet());
      final firstSelection = await fixture.select(roots: [
        ResourcePackRef(
            kind: ResourcePackKind.element,
            id: firstCatalog.elements.single.id),
      ]);
      await fixture.apply(
          await fixture.plan(await fixture.prepare(selection: firstSelection)));
      final store = fixture.mutations
          .resourcePackPayloadStore(fixture.opened.projectHandle);
      final staged = await second.archive.withSource((input) => store.stage(
            scope: fixture.preparer.scope,
            byteLength: input.length,
            chunks: sourceChunks(input),
          ));
      final secondSelection = await fixture.preparer.select(
        archiveHandle: staged.payload.handle,
        roots: [
          ResourcePackRef(
              kind: ResourcePackKind.element,
              id: secondCatalog.elements.single.id),
        ],
      );
      await fixture.apply(await fixture
          .plan(await fixture.prepare(selection: secondSelection)));
      final snapshot = await fixture.loader.load(fixture.opened.projectHandle);
      final installed = snapshot.manifest;
      expect(installed.elements, hasLength(2));
      expect(installed.models3d, hasLength(2));
      expect(installed.elements.map((element) => element.id).toSet(),
          hasLength(2));
      expect(installed.models3d.map((model) => model.id).toSet(), hasLength(2));
      expect(installed.resourcePackInstallations.entries, hasLength(2));
      expect(installed.globalProperties['localFeature'], {
        'enabled': true,
        'labels': ['keep', 'local']
      });
      final declarations =
          PortableCatalogPublication.projectDynamicDependencies(installed);
      expect(declarations, hasLength(2));
      for (final installation in installed.resourcePackInstallations.entries) {
        final elementId = installation.resources
            .singleWhere(
                (mapping) => mapping.source.kind == ResourcePackKind.element)
            .targetId;
        final modelId = installation.resources
            .singleWhere(
                (mapping) => mapping.source.kind == ResourcePackKind.model3d)
            .targetId;
        final declaration = declarations
            .singleWhere((declaration) => declaration.owner.id == elementId);
        expect(declaration.targets, [
          CatalogDefinitionKey(CatalogDefinitionKind.model3d, modelId),
        ]);
        final model =
            installed.models3d.singleWhere((model) => model.id == modelId);
        final media = installation.assets
            .singleWhere((asset) => asset.assetId == model.sourceAssetId);
        expect(model.relativePath, media.targetPath);
        expect(await File('${fixture.root.path}/${media.targetPath}').exists(),
            isTrue);
      }
      for (final selection in [firstSelection, secondSelection]) {
        final repeated = await fixture.prepare(selection: selection);
        expect(
            repeated.status, ResourcePackPreparedImportStatus.alreadyInstalled);
        expect(repeated.preparedImportHandle, isNull);
      }
      final repeated = await fixture.loader.load(fixture.opened.projectHandle);
      expect(repeated.revision, snapshot.revision);
      expect(repeated.manifest.toJson(), installed.toJson());
    } finally {
      await second.dispose();
      await fixture.dispose();
    }
  });
}
