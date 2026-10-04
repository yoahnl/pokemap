import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'map_catalog_fixture.dart';

void main() {
  for (final change in ['dispose', 'sourceDraft', 'narrativeDraft', 'none']) {
    test(
      'transaction rechecks $change after acquiring the writer lock',
      () async {
        final reached = Completer<void>();
        final release = Completer<void>();
        final fixture = await MapCatalogFixture.create(
          beforeTransactionPrecondition: () async {
            reached.complete();
            await release.future;
          },
        );
        addTearDown(fixture.dispose);
        final source = fixture.controller.active!;
        final manifestBefore = fixture.controller.project;
        final sourceFile = File(
          p.join(
            fixture.root.path,
            fixture.controller.project!.maps.first.relativePath,
          ),
        );
        final bytes = await sourceFile.readAsBytes();
        var narrativeDirty = false;
        var preliminaryChecks = 0;
        fixture.controller.catalogDependencyFailure = (_, _) {
          preliminaryChecks++;
          return narrativeDirty
              ? 'La nouvelle saisie Histoire doit être résolue.'
              : null;
        };
        final action = change == 'narrativeDraft'
            ? 'map.delete_apply'
            : 'map.duplicate';
        final targetId = change == 'narrativeDraft'
            ? fixture.controller.project!.maps.last.id
            : source.base.mapId;
        final targetPath = p.join(
          fixture.root.path,
          fixture.controller.project!.maps.last.relativePath,
        );
        final preparation = await fixture.controller.prepareCatalog(action, {
          if (change == 'narrativeDraft')
            'mapId': targetId
          else ...{
            'sourceMapId': targetId,
            'targetMapId': 'locked-copy',
            'name': 'Copie protégée',
          },
        });
        expect(preparation.canApply, isTrue);
        final pending = fixture.controller.applyPreparedCatalog(
          preparation,
          confirmDestructive: change == 'narrativeDraft',
        );
        await reached.future;
        expect(fixture.controller.catalogBusy, isTrue);
        if (change == 'narrativeDraft') {
          expect(preliminaryChecks, greaterThanOrEqualTo(3));
        }
        switch (change) {
          case 'dispose':
            fixture.controller.dispose();
          case 'sourceDraft':
            source.commit(
              source.current.copyWith(properties: {'concurrentDraft': true}),
            );
          case 'narrativeDraft':
            narrativeDirty = true;
        }
        release.complete();
        final result = await pending;
        if (change == 'none') {
          expect(result.published, isTrue, reason: result.error);
          expect(result.integrated, isTrue);
          expect(
            await File(
              p.join(fixture.root.path, 'maps/locked-copy.json'),
            ).exists(),
            isTrue,
          );
        } else {
          expect(result.published, isFalse, reason: result.error);
          expect(result.integrated, isFalse);
          expect(fixture.controller.project, same(manifestBefore));
          expect(
            await File(
              p.join(fixture.root.path, 'maps/locked-copy.json'),
            ).exists(),
            isFalse,
          );
          expect(await File(targetPath).exists(), isTrue);
          expect(fixture.controller.pendingCatalogReceipt, isNull);
        }
        expect(await sourceFile.readAsBytes(), bytes);
        if (change == 'sourceDraft') {
          expect(source.dirty, isTrue);
          expect(source.current.properties['concurrentDraft'], isTrue);
        }
      },
    );
  }
}
