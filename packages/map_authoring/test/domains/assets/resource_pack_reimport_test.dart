import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'resource_pack_import_fixture.dart';
import 'resource_pack_export_test.dart' as source;

void main() {
  test(
      'covered roots return alreadyInstalled before checking locally edited or deleted definitions',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    try {
      final root = ResourcePackRef(
          kind: ResourcePackKind.element,
          id: fixture.source.archive.inspection.catalog.elements.first.id);
      final selection = await fixture.select(roots: [root]);
      final prepared = await fixture.prepare(selection: selection);
      await fixture.apply(await fixture.plan(prepared));
      final file = File('${fixture.root.path}/project.json');
      final installed =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      await file.writeAsString(jsonEncode(installed.copyWith(elements: [
        installed.elements.single.copyWith(name: 'Locally edited')
      ]).toJson()));
      final history =
          await File('${fixture.root.path}/.pokemap/authoring/history.jsonl')
              .readAsString();
      final edited = await fixture.prepare(selection: selection);
      expect(edited.status.name, 'alreadyInstalled');
      expect(edited.preparedImportHandle, isNull);
      expect(
          (await fixture.loader.load(fixture.opened.projectHandle))
              .manifest
              .elements
              .single
              .name,
          'Locally edited');
      final current =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      await file.writeAsString(jsonEncode(current.copyWith(
          elements: [],
          resourceLibraryCatalog: ResourceLibraryCatalog(
              families: current.resourceLibraryCatalog.families,
              entries: current.resourceLibraryCatalog.entries
                  .where((e) => e.resourceKind != 'element'))).toJson()));
      final deleted = await fixture.prepare(selection: selection);
      expect(deleted.status.name, 'alreadyInstalled');
      expect(
          (await fixture.loader.load(fixture.opened.projectHandle))
              .manifest
              .elements,
          isEmpty);
      expect(
          await File('${fixture.root.path}/.pokemap/authoring/history.jsonl')
              .readAsString(),
          history);
      final extension = await fixture.select(roots: [
        ResourcePackRef(
            kind: ResourcePackKind.environmentPreset,
            id: fixture
                .source.archive.inspection.catalog.environmentPresets.single.id)
      ]);
      final refused = await fixture.prepare(selection: extension);
      expect(refused.status.name, 'conflict');
      expect(refused.preparedImportHandle, isNull);
      expect(refused.conflicts,
          contains(startsWith('dependency_modified_or_missing:')));
      final copied = await fixture.prepare(
          selection: extension, policy: ResourcePackConflictPolicy.importCopy);
      expect(copied.status.name, 'ready');
      expect(copied.installation!.copyOrdinal, 1);
      await fixture.apply(await fixture.plan(copied));
      final after =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      expect(after.resourcePackInstallations.entries, hasLength(2));
      expect(after.elements.any((e) => e.id == installed.elements.single.id),
          isFalse);
    } finally {
      await fixture.dispose();
    }
  });

  test(
      'a root previously covered as a dependency is already installed without a trace-only commit',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    try {
      final catalog = fixture.source.archive.inspection.catalog;
      final selected = await fixture.select(roots: [
        ResourcePackRef(
            kind: ResourcePackKind.element, id: catalog.elements.first.id)
      ]);
      await fixture.apply(
          await fixture.plan(await fixture.prepare(selection: selected)));
      final dependency = await fixture.select(roots: [
        ResourcePackRef(
            kind: ResourcePackKind.tileset, id: catalog.tilesets.single.id)
      ]);
      final result = await fixture.prepare(selection: dependency);
      expect(result.status.name, 'alreadyInstalled');
      expect(result.preparedImportHandle, isNull);
      expect(
          (await fixture.mutations
                  .listMutationHistory(fixture.opened.projectHandle, limit: 10))
              .entries,
          hasLength(1));
      final current =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      await File('${fixture.root.path}/project.json').writeAsString(jsonEncode(
          current.copyWith(
              tilesets: [],
              elements: [],
              resourceLibraryCatalog: ResourceLibraryCatalog(
                  families:
                      current.resourceLibraryCatalog.families)).toJson()));
      final removed = await fixture.prepare(selection: dependency);
      expect(removed.status.name, 'alreadyInstalled');
      expect(removed.preparedImportHandle, isNull);
    } finally {
      await fixture.dispose();
    }
  });

  test(
      'extension compares only required historical dependencies and reuses certified mappings',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    try {
      final catalog = fixture.source.archive.inspection.catalog;
      final firstRoot = ResourcePackRef(
          kind: ResourcePackKind.element, id: catalog.elements.first.id);
      final selection = await fixture.select(roots: [firstRoot]);
      final first = await fixture.prepare(selection: selection);
      await fixture.apply(await fixture.plan(first));
      final current =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      final originalTilesetId = current.tilesets.single.id;
      await File('${fixture.root.path}/project.json').writeAsString(jsonEncode(
          current.copyWith(
              elements: [
            current.elements.single.copyWith(name: 'Unrelated edit')
          ],
              resourceLibraryCatalog: ResourceLibraryCatalog(
                  families: current.resourceLibraryCatalog.families,
                  entries: [
                    for (final entry in current.resourceLibraryCatalog.entries)
                      if (entry.resourceKind == 'element')
                        ResourceLibraryEntry.fromJson(
                            {...entry.toJson(), 'placementContext': 'interior'})
                      else
                        entry
                  ])).toJson()));
      final extension = await fixture.select(roots: [
        ResourcePackRef(
            kind: ResourcePackKind.character, id: catalog.characters.single.id)
      ]);
      final second = await fixture.prepare(selection: extension);
      expect(second.status.name, 'ready');
      expect(second.installation!.copyOrdinal, 0);
      expect(
          second.installation!.resources
              .singleWhere((e) => e.source.kind == ResourcePackKind.tileset)
              .targetId,
          originalTilesetId);
      await fixture.apply(await fixture.plan(second));
      final after =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      expect(after.tilesets, hasLength(1));
      expect(after.elements.single.name, 'Unrelated edit');
      expect(
          after.resourceLibraryCatalog.entries
              .singleWhere((entry) => entry.resourceKind == 'element')
              .placementContext,
          ResourcePlacementContext.interior);
      expect(after.characters, hasLength(1));
      expect(after.resourcePackInstallations.entries, hasLength(1));
      final repeat = await fixture.prepare(selection: extension);
      expect(repeat.status.name, 'alreadyInstalled');
    } finally {
      await fixture.dispose();
    }
  });

  for (final classifiedAtSource in [false, true]) {
    test(
        'extension rejects changed classification presence on a required dependency from classified=$classifiedAtSource',
        () async {
      final mixed = source.mixedFixture();
      final fixture = await NativeResourcePackImportFixture.create(
          sourceManifest: mixed.$1.copyWith(
              resourceLibraryCatalog: ResourceLibraryCatalog(
                  families: mixed.$1.resourceLibraryCatalog.families,
                  entries: mixed.$1.resourceLibraryCatalog.entries.where(
                      (entry) =>
                          classifiedAtSource ||
                          entry.resourceKind != 'tileset'))),
          sourceFiles: mixed.$2);
      try {
        final catalog = fixture.source.archive.inspection.catalog;
        final initial = await fixture.select(roots: [
          ResourcePackRef(
              kind: ResourcePackKind.element, id: catalog.elements.first.id)
        ]);
        await fixture.apply(
            await fixture.plan(await fixture.prepare(selection: initial)));
        final installed =
            (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
        final dependencyId = installed.tilesets.single.id;
        final localEntries = [
          for (final entry in installed.resourceLibraryCatalog.entries)
            if (entry.resourceKind != 'tileset') entry,
          if (!classifiedAtSource)
            ResourceLibraryEntry(
                resourceKind: 'tileset',
                resourceId: dependencyId,
                placementContext: ResourcePlacementContext.interior)
        ];
        final file = File('${fixture.root.path}/project.json');
        await file.writeAsString(jsonEncode(installed
            .copyWith(
                resourceLibraryCatalog: ResourceLibraryCatalog(
                    families: installed.resourceLibraryCatalog.families,
                    entries: localEntries))
            .toJson()));
        final before = await file.readAsString();
        final extension = await fixture.select(roots: [
          ResourcePackRef(
              kind: ResourcePackKind.character,
              id: catalog.characters.single.id)
        ]);
        final result = await fixture.prepare(selection: extension);
        expect(result.status.name, 'conflict');
        expect(result.preparedImportHandle, isNull);
        expect(result.conflicts,
            ['classification_modified_or_missing:$dependencyId']);
        expect(await file.readAsString(), before);
        expect(
            (await fixture.mutations.listMutationHistory(
                    fixture.opened.projectHandle,
                    limit: 10))
                .entries,
            hasLength(1));
        final copy = await fixture.prepare(
            selection: extension,
            policy: ResourcePackConflictPolicy.importCopy);
        expect(copy.status.name, 'ready');
        await fixture.apply(await fixture.plan(copy));
        final copied =
            (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
        expect(
            copied.resourceLibraryCatalog.entries
                .where((entry) =>
                    entry.resourceKind == 'tileset' &&
                    entry.resourceId == dependencyId)
                .map((entry) => entry.toJson()),
            localEntries
                .where((entry) => entry.resourceKind == 'tileset')
                .map((entry) => entry.toJson()));
      } finally {
        await fixture.dispose();
      }
    });
  }

  test(
      'a modified required support refuses preserveProject while importCopy isolates the closure',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    try {
      final catalog = fixture.source.archive.inspection.catalog;
      final selection = await fixture.select(roots: [
        ResourcePackRef(
            kind: ResourcePackKind.element, id: catalog.elements.first.id)
      ]);
      await fixture.apply(
          await fixture.plan(await fixture.prepare(selection: selection)));
      final before =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      final category = before.elementCategories.first;
      final edited = before.copyWith(elementCategories: [
        for (final c in before.elementCategories)
          c.id == category.id ? c.copyWith(name: 'Local support') : c
      ]);
      await File('${fixture.root.path}/project.json')
          .writeAsString(jsonEncode(edited.toJson()));
      final extension = await fixture.select(roots: [
        ResourcePackRef(
            kind: ResourcePackKind.environmentPreset,
            id: catalog.environmentPresets.single.id)
      ]);
      final conflict = await fixture.prepare(selection: extension);
      expect(conflict.status.name, 'conflict');
      expect(conflict.conflicts,
          contains(startsWith('dependency_modified_or_missing:')));
      final copy = await fixture.prepare(
          selection: extension, policy: ResourcePackConflictPolicy.importCopy);
      expect(copy.status.name, 'ready');
      await fixture.apply(await fixture.plan(copy));
      final after =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      expect(
          after.elementCategories.singleWhere((c) => c.id == category.id).name,
          'Local support');
      expect(
          after.elements.singleWhere((e) => e.id == before.elements.single.id),
          before.elements.single);
    } finally {
      await fixture.dispose();
    }
  });

  test(
      'same pack identity with another archive is refused without replacing installed data',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    final mixed = source.mixedFixture();
    final alternate = await ResourcePackImportFixture.create(
        sourceManifest: mixed.$1.copyWith(name: 'Changed archive', elements: [
          for (final e in mixed.$1.elements) e.copyWith(name: 'Different')
        ]),
        sourceFiles: mixed.$2);
    try {
      await fixture.apply(await fixture.plan(await fixture.prepare()));
      final before =
          await File('${fixture.root.path}/project.json').readAsString();
      final store = fixture.mutations
          .resourcePackPayloadStore(fixture.opened.projectHandle);
      final stage = await alternate.archive.withSource((s) => store.stage(
          scope: fixture.preparer.scope,
          byteLength: s.length,
          chunks: sourceChunks(s)));
      final selection = await fixture.preparer
          .select(archiveHandle: stage.payload.handle, roots: [
        ResourcePackRef(
            kind: ResourcePackKind.element,
            id: alternate.archive.inspection.catalog.elements.first.id)
      ]);
      await expectLater(
          fixture.prepare(selection: selection),
          throwsA(isA<ResourcePackImportException>()
              .having((e) => e.code, 'code', 'pack.identity_conflict')));
      expect(await File('${fixture.root.path}/project.json').readAsString(),
          before);
    } finally {
      await alternate.dispose();
      await fixture.dispose();
    }
  });

  test(
      'a new immutable version installs alongside the old version with new identities',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    final alternate = await ResourcePackImportFixture.create(
        metadata: ResourcePackMetadata(
            id: 'original.pack',
            version: '2.0.0',
            name: 'Original',
            description: '',
            universeId: 'original',
            authors: ['Original'],
            provenance: 'Second version'));
    try {
      await fixture.apply(await fixture.plan(await fixture.prepare()));
      final before =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      final store = fixture.mutations
          .resourcePackPayloadStore(fixture.opened.projectHandle);
      final staged = await alternate.archive.withSource((s) => store.stage(
          scope: fixture.preparer.scope,
          byteLength: s.length,
          chunks: sourceChunks(s)));
      final selected = await fixture.preparer
          .select(archiveHandle: staged.payload.handle, roots: [
        ResourcePackRef(
            kind: ResourcePackKind.character,
            id: alternate.archive.inspection.catalog.characters.single.id)
      ]);
      final prepared = await fixture.prepare(selection: selected);
      expect(prepared.status.name, 'ready');
      await fixture.apply(await fixture.plan(prepared));
      final after =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      expect(
          after.resourcePackInstallations.entries
              .map((e) => e.packVersion)
              .toSet(),
          {'1.0.0', '2.0.0'});
      expect(after.characters, hasLength(2));
      expect(
          after.characters
              .singleWhere((e) => e.id == before.characters.single.id),
          before.characters.single);
    } finally {
      await alternate.dispose();
      await fixture.dispose();
    }
  });

  test(
      'explicit copies allow identical visible names and preserve the original installation',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    try {
      final selection = await fixture.select();
      final first = await fixture.prepare(selection: selection);
      await fixture.apply(await fixture.plan(first));
      final before =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      final copy = await fixture.prepare(
          selection: selection, policy: ResourcePackConflictPolicy.importCopy);
      expect(copy.status.name, 'ready');
      await fixture.apply(await fixture.plan(copy));
      final after =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      expect(
          after.characters
              .where((c) => c.name == before.characters.single.name),
          hasLength(2));
      expect(
          after.characters
              .singleWhere((c) => c.id == before.characters.single.id),
          before.characters.single);
      expect(
          after.resourcePackInstallations.entries
              .map((e) => e.copyOrdinal)
              .toSet(),
          {0, 1});
    } finally {
      await fixture.dispose();
    }
  });
}
