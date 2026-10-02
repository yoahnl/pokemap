import 'dart:async';

import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resource_fixture.dart';

void main() {
  for (final scenario in ['dirty owner', 'disposed session']) {
    test(
      'transaction refuses $scenario after planning at real writer precondition',
      () async {
        final fixture = await ResourceFixture.create();
        addTearDown(fixture.dispose);
        final imported = await fixture.import();
        final entered = Completer<void>();
        final release = Completer<void>();
        var dirty = false;
        final adapter = LocalResourceAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
          beforeTransactionPrecondition: () async {
            entered.complete();
            await release.future;
          },
        );
        addTearDown(adapter.dispose);
        final prepared = await adapter
            .prepareOperation('tileset.metadata.update', {
              'tilesetId': imported.createdTilesetId,
              'name': 'Jamais publié',
              'folderId': null,
            });
        final before = await fixture.manifestFile.readAsBytes();
        final mapBefore = await fixture.mapFile.readAsBytes();
        final pending = adapter.applyPrepared(
          prepared,
          validateBeforeApply: () =>
              dirty ? 'Ce propriétaire a un brouillon.' : null,
        );
        final failure = expectLater(
          pending,
          throwsA(
            isA<ResourceFailure>().having(
              (error) => error.partialReceipt,
              'publication',
              isNull,
            ),
          ),
        );
        await entered.future;
        if (scenario == 'dirty owner') {
          dirty = true;
        } else {
          await adapter.dispose();
        }
        release.complete();
        await failure;
        expect(await fixture.manifestFile.readAsBytes(), before);
        expect(await fixture.mapFile.readAsBytes(), mapBefore);
        expect(
          (await fixture.maps.loadProject(
            fixture.session,
          )).tilesets.single.name,
          'Arbres',
        );
      },
    );
  }

  test(
    'double click refuses second pending apply and first publishes once',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final entered = Completer<void>();
      final release = Completer<void>();
      final adapter = LocalResourceAdapter(
        session: fixture.session,
        mapAdapter: fixture.maps,
        beforeTransactionPrecondition: () async {
          entered.complete();
          await release.future;
        },
      );
      addTearDown(adapter.dispose);
      final prepared = await adapter.prepareOperation('tileset_folder.upsert', {
        'folder': {'id': 'one', 'name': 'Un seul dossier'},
      });
      final pending = adapter.applyPrepared(prepared);
      await entered.future;
      await expectLater(
        adapter.applyPrepared(prepared),
        throwsA(isA<ResourceFailure>()),
      );
      release.complete();
      final receipt = await pending;
      expect(receipt.manifest.tilesetFolders, hasLength(1));
      expect(
        (await fixture.maps.loadProject(fixture.session)).tilesetFolders,
        hasLength(1),
      );
    },
  );
}
