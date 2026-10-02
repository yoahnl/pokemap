import 'dart:io';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resource_fixture.dart';

void main() {
  test(
    'character inspection never applies and deletion preserves source',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final imported = await fixture.import();
      final created = await fixture.resources.mutate(
        'characterStudio.character.create',
        {'name': 'Libre', 'tilesetId': imported.createdTilesetId!},
      );
      final id = created.manifest.characters.single.id;
      final before = await fixture.manifestFile.readAsBytes();
      final image = await fixture.source.readAsBytes();
      final inspect = await fixture.resources.prepareOperation(
        'characterStudio.character.deletePlan',
        {'characterId': id},
      );
      expect(inspect.impact['dependencies'], isEmpty);
      expect(await fixture.manifestFile.readAsBytes(), before);
      await expectLater(
        fixture.resources.applyPrepared(inspect, confirmDestructive: true),
        throwsA(isA<ResourceFailure>()),
      );
      expect(await fixture.manifestFile.readAsBytes(), before);
      await fixture.resources.releasePreparation(inspect);
      final plan = await fixture.resources.prepareOperation(
        'characterStudio.character.delete',
        {'characterId': id},
      );
      await expectLater(
        fixture.resources.applyPrepared(plan),
        throwsA(isA<ResourceFailure>()),
      );
      final receipt = await fixture.resources.applyPrepared(
        plan,
        confirmDestructive: true,
      );
      expect(receipt.manifest.characters, isEmpty);
      expect(receipt.manifest.tilesets, created.manifest.tilesets);
      expect(await fixture.source.readAsBytes(), image);
      final independent = await LocalMapWorkspaceAdapter().loadProject(
        fixture.session,
      );
      expect(independent.characters, isEmpty);
      expect(
        await File(
          '${fixture.root.path}/${imported.manifest.tilesets.single.relativePath}',
        ).exists(),
        isTrue,
      );
    },
  );
}
