import 'dart:io';

import 'package:map_authoring/map_authoring.dart'
    show JournaledAuthoringTransactionException;

import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';

import 'resource_fixture.dart';

void main() {
  test(
    'contact-only updates preserve unrelated asset bytes and skip snapshots',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final imported = await fixture.import();
      final created = await fixture.resources.mutate(
        'characterStudio.character.create',
        {'name': 'Contact actor', 'tilesetId': imported.createdTilesetId},
      );
      final character = created.manifest.characters.single;
      final image = File(
        '${fixture.root.path}/${created.manifest.tilesets.single.relativePath}',
      );
      await image.writeAsBytes([1, 2, 3]);
      final mapBefore = await fixture.mapFile.readAsBytes();
      for (final enabled in [true, false, null]) {
        final receipt = await fixture.resources.mutate(
          'characterStudio.character.update',
          {'characterId': character.id, 'contactShadow': enabled},
        );
        expect(receipt.manifest.characters.single.contactShadow, enabled);
        expect(receipt.changedPaths, ['project.json']);
        expect(receipt.actionId, 'characterStudio.contactShadow.set');
        expect(await image.readAsBytes(), [1, 2, 3]);
        expect(await fixture.mapFile.readAsBytes(), mapBefore);
      }
      await expectLater(
        fixture.resources.mutate('characterStudio.character.update', {
          'characterId': character.id,
          'contactShadow': true,
          'name': 'Other edit',
        }),
        throwsA(isA<ResourceFailure>()),
      );
      final reopened = await LocalMapWorkspaceAdapter().loadProject(
        fixture.session,
      );
      expect(reopened.characters.single.contactShadow, isNull);
    },
  );

  test(
    'targeted contact update keeps before-transaction and reconciliation hooks',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final imported = await fixture.import();
      final created = await fixture.resources.mutate(
        'characterStudio.character.create',
        {'name': 'Hook actor', 'tilesetId': imported.createdTilesetId},
      );
      var beforeCount = 0;
      var afterCount = 0;
      final adapter = LocalResourceAdapter(
        session: fixture.session,
        mapAdapter: fixture.maps,
        beforeTransactionPrecondition: () async {
          beforeCount++;
        },
        beforeReconciliation: () async {
          afterCount++;
        },
      );
      addTearDown(adapter.dispose);
      await adapter.mutate('characterStudio.character.update', {
        'characterId': created.manifest.characters.single.id,
        'contactShadow': true,
      });
      expect(beforeCount, 1);
      expect(afterCount, 1);
    },
  );
  test(
    'targeted contact precondition failure leaves the manifest unchanged',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final imported = await fixture.import();
      final created = await fixture.resources.mutate(
        'characterStudio.character.create',
        {'name': 'Protected actor', 'tilesetId': imported.createdTilesetId},
      );
      final before = await fixture.manifestFile.readAsBytes();
      var attempts = 0;
      final adapter = LocalResourceAdapter(
        session: fixture.session,
        mapAdapter: fixture.maps,
        beforeTransactionPrecondition: () async {
          attempts++;
          throw const JournaledAuthoringTransactionException(
            'transaction.recovery_required',
            'Operation refused',
          );
        },
      );
      addTearDown(adapter.dispose);
      await expectLater(
        adapter.mutate('characterStudio.character.update', {
          'characterId': created.manifest.characters.single.id,
          'contactShadow': true,
        }),
        throwsA(isA<ResourceFailure>()),
      );
      expect(await fixture.manifestFile.readAsBytes(), before);
      expect(attempts, 1);
    },
  );
}
