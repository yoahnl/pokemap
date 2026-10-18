import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'resource_pack_export_test.dart' as source;
import 'resource_pack_import_fixture.dart';

void main() {
  test(
      'partitioned pack passes native import and reexport without losing media or variants',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    OwnedResourcePackExport? reexport;
    try {
      final original = fixture.source.archive.inspection;
      expect(original.manifest.toJson()['formatVersion'], 2);
      await fixture.source.archive.withSource((input) async {
        final zip = ZipDecoder().decodeBytes(input.readAtSync(0, input.length));
        final descriptor =
            jsonDecode(utf8.decode(zip.findFile('catalog.json')!.content))
                as Map;
        expect(descriptor['version'], 2);
        expect(descriptor['root'], isA<Map>());
        expect(descriptor.containsKey('smartTileCatalog'), isFalse);
        expect(
            zip.files.where((file) => file.name.startsWith('catalog/objects/')),
            isNotEmpty);
      });
      await fixture.apply(await fixture.plan(await fixture.prepare()));
      final snapshot = await fixture.loader.load(fixture.opened.projectHandle);
      final installed = snapshot.manifest;
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
      final projection = await ResourcePackProjectionBuilder().project(
          manifest: installed,
          files: files,
          roots: [
            for (final mapping in installation.resources)
              NativeResourcePackRef(
                  kind: mapping.source.kind, id: mapping.targetId)
          ],
          author: 'L4 proof',
          sourceRevision: snapshot.revision);
      reexport = await CanonicalResourcePackExportService(
              store: fixture.source.store,
              scope: ResourcePackImportFixture.scope)
          .export(
              projection: projection,
              metadata: source.metadata(),
              expectedRevision: snapshot.revision,
              readCurrentRevision: () async => snapshot.revision);
      final again = reexport.inspection;
      expect(again.manifest.toJson()['formatVersion'], 2);
      expect(again.resourceCount, original.resourceCount);
      expect(again.supportCount, original.supportCount);
      expect(again.catalog.files.map((file) => file.rawSha256).toSet(),
          original.catalog.files.map((file) => file.rawSha256).toSet());
      expect(
          again.catalog.smartTileCatalog.patterns.map((p) => p.name).toSet(),
          original.catalog.smartTileCatalog.patterns
              .map((p) => p.name)
              .toSet());
      expect(again.catalog.models3d.map((model) => model.name).toSet(),
          original.catalog.models3d.map((model) => model.name).toSet());
      expect(
          again.catalog.resourceLibraryCatalog.entries
              .map((entry) => entry.placementContext)
              .toSet(),
          original.catalog.resourceLibraryCatalog.entries
              .map((entry) => entry.placementContext)
              .toSet());
      final repeated = await fixture.prepare();
      expect(
          repeated.status, ResourcePackPreparedImportStatus.alreadyInstalled);
      expect((await fixture.loader.load(fixture.opened.projectHandle)).revision,
          snapshot.revision);
    } finally {
      await reexport?.dispose();
      await fixture.dispose();
    }
  });
}
