import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';
import 'resource_fixture.dart';

void main() {
  test(
    'Studio replaces a model source and refreshes clips without moving objects',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final input = File('${fixture.root.path}/source.glb');
      await input.writeAsBytes(triangleGlb());
      final imported = await fixture.resources.importModel(
        sourcePath: input.path,
        name: 'Fontaine',
      );
      final id = imported.manifest.models3d.single.id;
      await fixture.resources.mutate('model3d.configure', {
        'modelId': id,
        'scale': 2,
        'pivot': {'x': 1, 'y': 2, 'z': 3},
      });
      final beforeMap = await fixture.mapFile.readAsBytes();
      await input.writeAsBytes(animatedGlb());
      final receipt = await fixture.resources.replaceModelSource(
        modelId: id,
        sourcePath: input.path,
      );
      final model = receipt.manifest.models3d.single;
      expect(model.id, id);
      expect(model.name, 'Fontaine');
      expect(model.scale, 2);
      expect(model.pivot.toJson(), {'x': 1.0, 'y': 2.0, 'z': 3.0});
      expect(model.inspection.animations.single.name, 'Wind');
      expect(await fixture.resources.readModel(id), animatedGlb());
      expect(await fixture.mapFile.readAsBytes(), beforeMap);
      final reopened = await LocalMapWorkspaceAdapter().loadProject(
        fixture.session,
      );
      expect(
        reopened.models3d.single.inspection.animations,
        model.inspection.animations,
      );
    },
  );

  test(
    'Studio imports, configures, reopens and removes a model without changing an open map',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final input = File('${fixture.root.path}/source.glb');
      await input.writeAsBytes(triangleGlb());
      final mapBefore = await fixture.mapFile.readAsBytes();
      final imported = await fixture.resources.importModel(
        sourcePath: input.path,
        name: 'Maison',
      );
      final model = imported.manifest.models3d.single;
      expect(await fixture.resources.readModel(model.id), triangleGlb());
      await fixture.resources.mutate('model3d.configure', {
        'modelId': model.id,
        'name': 'Maison bleue',
        'scale': 2,
      });
      final reopened = await LocalMapWorkspaceAdapter().loadProject(
        fixture.session,
      );
      expect(reopened.models3d.single.name, 'Maison bleue');
      expect(reopened.models3d.single.scale, 2);
      expect(await fixture.mapFile.readAsBytes(), mapBefore);
      final nativePath = Platform.environment['AVELUNE_3D_NATIVE_FIXTURE'];
      if (nativePath != null) {
        final target = Directory(nativePath);
        if (await target.exists()) {
          throw StateError('Native fixture already exists.');
        }
        await target.create(recursive: true);
        await for (final entry in fixture.root.list(
          recursive: true,
          followLinks: false,
        )) {
          final path =
              '$nativePath/${entry.path.substring(fixture.root.path.length + 1)}';
          if (entry is Directory) await Directory(path).create(recursive: true);
          if (entry is File) {
            await File(path).parent.create(recursive: true);
            await entry.copy(path);
          }
        }
      }
      final removed = await fixture.resources.deleteModel(model.id);
      expect(removed.manifest.models3d, isEmpty);
      expect(
        await File('${fixture.root.path}/${model.relativePath}').exists(),
        isFalse,
      );
    },
  );
}
