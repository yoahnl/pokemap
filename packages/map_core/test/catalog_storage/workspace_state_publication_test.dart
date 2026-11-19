import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'export reads definitions in bounded groups and preserves order',
    () async {
      final units = List.generate(
        40,
        (index) => CatalogDefinitionUnit(
          key: CatalogDefinitionKey(
            CatalogDefinitionKind.tileset,
            'tileset-${index.toString().padLeft(2, '0')}',
          ),
          payload: {'position': index},
        ),
      );
      final build = CatalogStorageBuilder().build(units);
      var activeReads = 0;
      var peakReads = 0;
      final snapshot = await CatalogSnapshot.open(
        root: build.root,
        readObject: (reference) async {
          activeReads++;
          if (activeReads > peakReads) peakReads = activeReads;
          await Future<void>.delayed(Duration.zero);
          activeReads--;
          return build.objects[reference.sha256]!;
        },
      );

      final exported = await snapshot.readAllUnits(
        includeWorkspaceState: false,
      );

      expect(peakReads, inInclusiveRange(2, 16));
      expect(exported.map((unit) => unit.key), units.map((unit) => unit.key));
    },
  );

  test(
    'working state is excluded from exports and forbidden in portable input',
    () async {
      final publication = PortableCatalogPublication.encodeProject(
        ProjectManifest(name: 'Working', maps: const [], tilesets: const []),
      );
      final read = PortableCatalogPublication.readSync(
        publication.descriptor,
        readObject: (reference) =>
            publication.storage.objects[reference.sha256]!,
      );
      final build = CatalogStorageBuilder().build([
        ...read.units,
        CatalogDefinitionUnit(
          key: CatalogDefinitionKey(
            CatalogDefinitionKind.workspaceState,
            'workspace',
          ),
          payload: {'id': 'workspace', 'fingerprint': 'sha256:${'a' * 64}'},
        ),
      ]);
      final reads = <String>[];
      final snapshot = await CatalogSnapshot.open(
        root: build.root,
        readObject: (reference) async {
          reads.add(reference.sha256);
          return build.objects[reference.sha256]!;
        },
      );
      final workspace = await snapshot.page(
        kind: CatalogDefinitionKind.workspaceState,
        limit: 1,
      );
      final workspaceObject = workspace.items.single.reference.sha256;
      final working = await PortableProjectCatalog.fromSnapshot(snapshot);
      reads.clear();
      final project = await working.exportProject();
      expect(project.name, 'Working');
      expect(reads, isNot(contains(workspaceObject)));
      await snapshot.validate();
      expect(reads, contains(workspaceObject));
      final exported = PortableCatalogPublication.encodeProject(project);
      expect(exported.storage.definitionCount, read.units.length);
      expect(
        () => PortableCatalogPublication.readSync({
          ...publication.descriptor,
          'root': build.root.toJson(),
        }, readObject: (reference) => build.objects[reference.sha256]!),
        throwsFormatException,
      );
      await expectLater(
        PortableProjectCatalog.open({
          ...publication.descriptor,
          'root': build.root.toJson(),
        }, readObject: (reference) async => build.objects[reference.sha256]!),
        throwsFormatException,
      );
    },
  );
}
