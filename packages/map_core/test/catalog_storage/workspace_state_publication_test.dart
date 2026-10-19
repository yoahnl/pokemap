import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
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
      final snapshot = await CatalogSnapshot.open(
        root: build.root,
        readObject: (reference) async => build.objects[reference.sha256]!,
      );
      final working = await PortableProjectCatalog.fromSnapshot(snapshot);
      final project = await working.exportProject();
      expect(project.name, 'Working');
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
