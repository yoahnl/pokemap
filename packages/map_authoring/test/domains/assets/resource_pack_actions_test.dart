import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/src/ports/file_backed_payload_store.dart';
import 'dart:io';
import 'resource_pack_import_fixture.dart';
import 'resource_pack_export_test.dart' as source;

void main() {
  test('preparation freezes all seven kinds and creates no native mutation',
      () async {
    final fixture = await ResourcePackImportFixture.create();
    try {
      final prepared = await fixture.prepare();
      expect(prepared.status.name, 'ready');
      expect(prepared.installation!.toJson()['internalMappings'], isNotEmpty);
      expect(ResourcePackInstallation.fromJson(prepared.installation!.toJson()),
          prepared.installation);
      expect(prepared.installation!.resources.map((r) => r.source.kind).toSet(),
          ResourcePackKind.values.toSet());
      expect(
          prepared.installation!.resources.every((r) =>
              RegExp(r'^rp_[a-f0-9]{16}_[a-f0-9]{24}$').hasMatch(r.targetId)),
          isTrue);
      expect(
          fixture.snapshot.manifest.resourcePackInstallations.isEmpty, isTrue);
      expect(fixture.directory.listSync().map((e) => e.path),
          everyElement(endsWith('/cache')));
    } finally {
      await fixture.dispose();
    }
  });
  test(
      'selection and target revisions, foreign handles and dimensions are refused',
      () async {
    final fixture = await ResourcePackImportFixture.create();
    try {
      final selected = await fixture.select();
      await expectLater(
          fixture.preparer.prepare(
              selectionHandle: selected.handle,
              selectionRevision: 'stale',
              expectedRevision: fixture.snapshot.revision),
          throwsA(isA<ResourcePackImportException>()
              .having((e) => e.code, 'code', 'resource_pack.selection_stale')));
      await expectLater(
          fixture.preparer.prepare(
              selectionHandle: selected.handle,
              selectionRevision: selected.revision,
              expectedRevision: 'stale'),
          throwsA(isA<ResourcePackImportException>()
              .having((e) => e.code, 'code', 'resource_pack.project_stale')));
      await expectLater(
          fixture.preparer.prepare(
              selectionHandle: 'foreign',
              selectionRevision: selected.revision,
              expectedRevision: fixture.snapshot.revision),
          throwsA(isA<ResourcePackImportException>().having(
              (e) => e.code, 'code', 'resource_pack.selection_unknown')));
      fixture.snapshot = makeSnapshot(fixture.snapshot.manifest
          .copyWith(settings: ProjectSettings(tileWidth: 16, tileHeight: 16)));
      await expectLater(
          fixture.prepare(selection: selected),
          throwsA(isA<ResourcePackImportException>().having(
              (e) => e.code, 'code', 'resource_pack.dimensions_incompatible')));
    } finally {
      await fixture.dispose();
    }
  });

  test(
      'physical files outside the catalog conflict and unavailable inventory is never absence',
      () async {
    for (final unavailable in [false, true]) {
      final fixture = await ResourcePackImportFixture.create(
          probe: (_) async => unavailable
              ? const ProjectResourceProbe.inventoryUnavailable()
              : const ProjectResourceProbe.exists(ProjectResourceIdentity(
                  scope: 'project',
                  relativePath: 'occupied',
                  byteLength: 1,
                  modifiedAtMicros: 0)));
      try {
        if (unavailable) {
          await expectLater(
              fixture.prepare(),
              throwsA(isA<ResourcePackImportException>().having((e) => e.code,
                  'code', 'resource_pack.inventory_unavailable')));
        } else {
          final prepared = await fixture.prepare();
          expect(prepared.status.name, 'conflict');
          expect(prepared.preparedImportHandle, isNull);
          expect(prepared.conflicts, contains(startsWith('path_occupied:')));
        }
        expect(fixture.preparer.preparedCount, 0);
      } finally {
        await fixture.dispose();
      }
    }
  });

  test(
      'two plans own independent payload wrappers after prepared selection and archive release',
      () async {
    final fixture = await ResourcePackImportFixture.create();
    final plans = AuthoringPlanStore();
    try {
      final selection = await fixture.select();
      final prepared = await fixture.prepare(selection: selection);
      final planner = AuthoringActionPlanner(store: plans);
      final dispatcher = MapMutationDispatcher.canonical(
          preparedResourcePackImportResolver: fixture.preparer.buildDraft);
      final first = await planner.plan(
          request:
              fixture.request(prepared.preparedImportHandle!, key: 'first'),
          snapshot: fixture.snapshot,
          build: dispatcher.build);
      final second = await planner.plan(
          request:
              fixture.request(prepared.preparedImportHandle!, key: 'second'),
          snapshot: fixture.snapshot,
          build: dispatcher.build);
      final a = first.changeSet.changes
          .firstWhere((c) => c.resource.kind == 'asset')
          .afterPayload!;
      final b = second.changeSet.changes
          .firstWhere((c) => c.resource.kind == 'asset')
          .afterPayload!;
      expect(identical(a, b), isFalse);
      expect(a.isInline, isFalse);
      await fixture.preparer.discardPrepared(prepared.preparedImportHandle!);
      await fixture.preparer.discardSelection(selection.handle);
      await fixture.archive.dispose();
      final before = await b.readBytes();
      await plans.discard(first.planId);
      expect(fixture.preparer.planInventoryCount, 1);
      expect(await b.readBytes(), before);
      await plans.discard(second.planId);
      expect(fixture.preparer.planInventoryCount, 0);
    } finally {
      await plans.dispose();
      await fixture.dispose();
    }
  });

  test(
      'expired preparation releases its leases while a frozen plan remains readable',
      () async {
    var now = DateTime.utc(2026, 10, 17);
    final fixture = await ResourcePackImportFixture.create(clock: () => now);
    final plans =
        AuthoringPlanStore(clock: () => now, ttl: const Duration(days: 2));
    try {
      final prepared = await fixture.prepare();
      final planner = AuthoringActionPlanner(store: plans);
      final dispatcher = MapMutationDispatcher.canonical(
          preparedResourcePackImportResolver: fixture.preparer.buildDraft);
      final plan = await planner.plan(
          request: fixture.request(prepared.preparedImportHandle!),
          snapshot: fixture.snapshot,
          build: dispatcher.build);
      await fixture.archive.dispose();
      now = now.add(const Duration(hours: 1));
      await fixture.preparer.collectExpired();
      expect(fixture.preparer.preparedCount, 0);
      final output = plan.changeSet.changes
          .firstWhere((c) => c.resource.kind == 'asset')
          .afterPayload!;
      expect(await output.readBytes(), isNotEmpty);
      await expectLater(
          planner.plan(
              request: fixture.request(prepared.preparedImportHandle!),
              snapshot: fixture.snapshot,
              build: dispatcher.build),
          throwsA(isA<ResourcePackImportException>()));
      await plans.dispose();
      now = now.add(const Duration(days: 2));
      await fixture.store.collectExpired();
      expect(fixture.store.cachedBytes, 0);
      expect(fixture.preparer.planInventoryCount, 0);
    } finally {
      await plans.dispose();
      await fixture.dispose();
    }
  });

  test('a corrupted owned archive is rejected before preparation', () async {
    final fixture = await ResourcePackImportFixture.create();
    try {
      final selected = await fixture.select();
      final stage = fixture.directory
          .listSync(recursive: true)
          .whereType<File>()
          .singleWhere((f) => f.path.endsWith(fixture.archive.payload.handle));
      final bytes = await stage.readAsBytes();
      bytes[0] ^= 1;
      await stage.writeAsBytes(bytes);
      await expectLater(
          fixture.prepare(selection: selected),
          throwsA(isA<FileBackedPayloadException>()
              .having((e) => e.code, 'code', 'resource_pack.stage_corrupt')));
      expect(fixture.preparer.preparedCount, 0);
    } finally {
      await fixture.dispose();
    }
  });

  test(
      'describe parity includes pack API CLI and MCP evidence while editor remains partial',
      () {
    final parity = AuthoringFullParityCatalog.canonical()
        .requireMutationAction('resource_pack.import');
    expect(parity.contractTestPath,
        'test/domains/assets/resource_pack_actions_test.dart');
    expect(parity.endToEndEvidence.keys, {AuthoringTransport.directApi, AuthoringTransport.cli, AuthoringTransport.mcp});
    expect(parity.endToEndVerifiedTransports, {AuthoringTransport.directApi, AuthoringTransport.cli, AuthoringTransport.mcp});
    expect(parity.endToEndEvidence.containsKey(AuthoringTransport.editor), false);
  });

  test(
      '2D Border imports keep content-addressed snapshots and reconstruct target source metrics',
      () async {
    final native = await source.spriteFixture(margins: true);
    final fixture = await NativeResourcePackImportFixture.create(
        sourceManifest: native.$1,
        sourceFiles: native.$2,
        roots: [
          NativeResourcePackRef(
              kind: ResourcePackKind.borderBlueprint, id: 'sprite')
        ]);
    try {
      final catalog = fixture.source.archive.inspection.catalog;
      final selection = await fixture.select(roots: [
        ResourcePackRef(
            kind: ResourcePackKind.borderBlueprint,
            id: catalog.borderCatalog.records.single.id)
      ]);
      final prepared = await fixture.prepare(selection: selection);
      expect(prepared.status.name, 'ready');
      await fixture.apply(await fixture.plan(prepared));
      final actual =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      expect(actual.borderCatalog.visualSnapshots.map((s) => s.id).toSet(),
          catalog.borderCatalog.visualSnapshots.map((s) => s.id).toSet());
      for (final snapshot in actual.borderCatalog.visualSnapshots) {
        for (final frame in snapshot.frames) {
          expect(
              frame.relativeAssetPath,
              startsWith(
                  'assets/borders/snapshots/${snapshot.contentFingerprint}/frame_'));
        }
      }
      final primitive = actual.borderCatalog.records.single.latestPublished!
          .definition.primitives.single;
      expect(primitive.sourceElementId, actual.elements.single.id);
      expect(
          primitive.publishedMetrics.assetFingerprint,
          isNot(catalog.borderCatalog.records.single.latestPublished!.definition
              .primitives.single.publishedMetrics.assetFingerprint));
      expect(
          actual.borderCatalog.records.single.draft.definition.primitives.single
              .currentMetrics,
          primitive.publishedMetrics);
      final copy = await fixture.prepare(
          selection: selection, policy: ResourcePackConflictPolicy.importCopy);
      expect(copy.status.name, 'ready');
      await fixture.apply(await fixture.plan(copy));
      final copied =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      expect(copied.borderCatalog.records, hasLength(2));
      expect(copied.borderCatalog.visualSnapshots.length,
          actual.borderCatalog.visualSnapshots.length);
    } finally {
      await fixture.dispose();
    }
  });

  test(
      'image collection page references and asset properties remap while numeric IDs remain local',
      () async {
    final base = source.originalManifest();
    final property = ProjectTilesetProperty(
        name: 'portrait',
        type: ProjectTilesetPropertyType.assetReference,
        value: 'portrait');
    final imageCollection = ProjectTilesetSource.imageCollection(pages: [
      ProjectImageCollectionPage(
          id: 'page', assetId: 'image', pixelWidth: 2, pixelHeight: 2)
    ], properties: [
      property
    ], tileDefinitions: [
      ProjectImageCollectionTileDefinition(
          tileId: 9,
          pageId: 'page',
          sourceRect: ProjectTilesetPixelRect(x: 0, y: 0, width: 2, height: 2),
          animation: [
            ProjectImageCollectionAnimationFrame(tileId: 9, durationMs: 80)
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
    final fixture = await NativeResourcePackImportFixture.create(
        sourceManifest: base.copyWith(
            tilesets: [base.tilesets.single.copyWith(source: imageCollection)]),
        sourceFiles: [
          source.nativeImage(),
          source.nativeImage(id: 'portrait', path: 'assets/portrait.png')
        ],
        roots: [
          NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas')
        ]);
    try {
      final selection = await fixture.select(roots: [
        ResourcePackRef(
            kind: ResourcePackKind.tileset,
            id: fixture.source.archive.inspection.catalog.tilesets.single.id)
      ]);
      final prepared = await fixture.prepare(selection: selection);
      await fixture.apply(await fixture.plan(prepared));
      final actual = (await fixture.loader.load(fixture.opened.projectHandle))
          .manifest
          .tilesets
          .single
          .source as ProjectImageCollectionTilesetSource;
      expect(actual.tileDefinitions.single.pageId, actual.pages.single.id);
      expect(actual.pages.single.id, startsWith('rp_'));
      expect(actual.pages.single.assetId, startsWith('rp_'));
      expect(actual.properties.single.value, startsWith('rp_'));
      expect(actual.tileDefinitions.single.tileId, 9);
      expect(actual.tileDefinitions.single.animation.single.tileId, 9);
      expect(actual.tileDefinitions.single.collisionObjects.single.id, 2);
      expect(
          actual.tileDefinitions.single.collisionObjects.single.properties.last
              .value,
          2);
    } finally {
      await fixture.dispose();
    }
  });

  test(
      'planning preserves the target world tileset and never allocates IDs from a plan seed',
      () async {
    final world = ProjectTilesetEntry(
        id: 'target-world',
        name: 'World',
        relativePath: 'assets/world.png',
        isWorldTileset: true);
    final fixture = await ResourcePackImportFixture.create(
        target: ProjectManifest(
            name: 'Target',
            maps: [],
            tilesets: [world],
            settings: ProjectSettings(tileWidth: 2, tileHeight: 2)));
    final plans = AuthoringPlanStore();
    try {
      final prepared = await fixture.prepare();
      final first = await fixture.preparer.buildDraft(
          AuthoringPlanningContext(
              snapshot: fixture.snapshot,
              request: fixture.request(prepared.preparedImportHandle!),
              planId: 'plan-one',
              seed: 1),
          prepared.preparedImportHandle!);
      final second = await fixture.preparer.buildDraft(
          AuthoringPlanningContext(
              snapshot: fixture.snapshot,
              request: fixture.request(prepared.preparedImportHandle!),
              planId: 'plan-two',
              seed: 999),
          prepared.preparedImportHandle!);
      expect(
          first.projectedProject!.tilesets.singleWhere((e) => e.id == world.id),
          world);
      expect(
          first.projectedProject!.tilesets
              .where((e) => e.id != world.id)
              .every((e) => !e.isWorldTileset),
          isTrue);
      expect(first.projectedProject, second.projectedProject);
      await first.changeSet.releasePayloads();
      await second.changeSet.releasePayloads();
    } finally {
      await plans.dispose();
      await fixture.dispose();
    }
  });

  test('canonical registry exposes the prepared additive import contract', () {
    final descriptor = MapMutationDispatcher.canonical()
        .descriptors
        .where((value) => value.id == 'resource_pack.import')
        .firstOrNull;
    expect(descriptor, isNotNull);
    expect(descriptor!.version, 1);
    expect(descriptor.guarantees, isNot(contains(AuthoringGuarantee.atomic)));
    expect(descriptor.extensions['multiFileGuarantee'], 'recoverable');
    expect(
        descriptor.requiredPermissions,
        containsAll(
            [AuthoringPermission.importRun, AuthoringPermission.assetWrite]));
    expect(descriptor.guarantees,
        containsAll([AuthoringGuarantee.dryRun, AuthoringGuarantee.undoable]));
  });
}
