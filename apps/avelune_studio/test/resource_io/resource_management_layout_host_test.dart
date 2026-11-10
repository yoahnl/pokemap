import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_containers.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_usage_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/authoring_resource_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'resource folder publication persists and usage analysis stays current',
    () async {
      final fixture = await AuthoringResourceFixture.create();
      addTearDown(fixture.dispose);
      final navigation = fixture.navigation;
      final maps = await fixture.mapFiles();
      final source = fixture.workspace.project!.tilesets.single;
      const folder = ResourceContainer(
        'vegetation',
        'Dossier accessible',
        null,
        0,
      );
      expect(
        await publishResourceManagementChange(
          navigation,
          await navigation.captureResourceRevision(),
          containerAction(ResourceKind.images, 'upsert'),
          containerParameters(ResourceKind.images, folder),
        ),
        isNull,
      );
      final reopened = await fixture.reopen();
      expect(reopened.tilesetFolders.single.id, folder.id);
      expect(reopened.tilesetFolders.single.name, folder.name);
      expect(reopened.tilesets.single, source);
      expect(await fixture.mapFiles(), maps);
      final report = await navigation.usages.analyze(
        ResourceUsageTarget(family: 'images', id: source.id),
      );
      expect(report.complete, isTrue);
      expect(report.target.id, source.id);
      expect(await navigation.usages.isCurrent(report), isTrue);
      expect(await fixture.mapFiles(), maps);
    },
  );
}
