import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'resource_pack_export_test.dart' as source;
import 'resource_pack_import_fixture.dart';

void main() {
  test('nonblocking model survives native pack projection inspection import and reopen', () async {
    final original = source.mixedFixture();
    final model = original.$1.models3d.single.copyWith(blocksMovementByDefault: false, castsShadowsByDefault: true,
      light: Model3dPointLight(localPosition: Model3dVector3(x: 0, y: 2.25, z: 0)));
    final fixture = await NativeResourcePackImportFixture.create(
      sourceManifest: original.$1.copyWith(models3d: [model]),
      sourceFiles: original.$2,
      roots: [NativeResourcePackRef(kind: ResourcePackKind.model3d, id: model.id)],
    );
    try {
      final catalog = fixture.source.archive.inspection.catalog;
      expect(catalog.models3d.single.blocksMovementByDefault, false);
      expect(catalog.models3d.single.castsShadowsByDefault, true);
      expect(catalog.models3d.single.light, model.light);
      final prepared = await fixture.prepare(selection: await fixture.select(roots: [
        ResourcePackRef(kind: ResourcePackKind.model3d, id: catalog.models3d.single.id),
      ]));
      await fixture.apply(await fixture.plan(prepared));
      await fixture.close();
      await fixture.open();
      final manifest = (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      expect(manifest.models3d.single.blocksMovementByDefault, false);
      expect(manifest.models3d.single.castsShadowsByDefault, true);
      expect(manifest.models3d.single.light, model.light);
      expect(manifest.models3d.single.toJson()['blocksMovementByDefault'], false);
      expect(manifest.models3d.single.inspection, model.inspection);
      expect(manifest.models3d.single.id, isNot(model.id));
    } finally {
      await fixture.dispose();
    }
  });
}
