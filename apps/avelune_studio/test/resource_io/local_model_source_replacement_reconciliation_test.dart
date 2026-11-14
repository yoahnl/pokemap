import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';
import 'local_model_source_replacement_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('replacement outside the loaded projection does not materialize the catalogue', () async {
    final fixture = await ModelSourceReplacementFixture.create(
      90,
      loadModels: false,
    );
    addTearDown(fixture.dispose);
    final before = await fixture.maps.resourceBaseline(fixture.session);
    expect(before.manifest.models3d, isEmpty);
    expect(before.manifest.models3d, isA<ProjectModel3dEntries>());
    final bytes = volumeGlb(
      edit: (json) {
        json['nodes'][0]['translation'] = [0, 8, 0];
      },
    );
    await fixture.input.writeAsBytes(bytes);
    final receipt = await fixture.resources.replaceModelSource(
      modelId: 'house',
      sourcePath: fixture.input.path,
    );
    expect(receipt.manifest.models3d, isEmpty);
    expect(receipt.changedModels['house']!.inspection.bounds.min.y, 8);
    expect(await fixture.resources.readModel('house'), bytes);
    final reopened = LocalMapWorkspaceAdapter();
    await reopened.loadCatalog(fixture.session);
    final all = await reopened.loadResourceKind(fixture.session, 'model3d');
    expect(
      all.metadata.models3d
          .singleWhere((model) => model.id == 'house')
          .inspection
          .bounds
          .min
          .y,
      8,
    );
  });
  for (final tampered in [false, true]) {
    test(
      'published replacement reconciliation is local and detects tampering=$tampered',
      () async {
        final fixture = await ModelSourceReplacementFixture.create(
          90,
          beforeReconciliation: () async {
            throw StateError('Injected refresh failure');
          },
        );
        addTearDown(fixture.dispose);
        await fixture.input.writeAsBytes(
          volumeGlb(
            edit: (json) {
              json['nodes'][0]['translation'] = [0, 4, 0];
            },
          ),
        );
        ResourceMutationReceipt? receipt;
        try {
          await fixture.resources.replaceModelSource(
            modelId: 'house',
            sourcePath: fixture.input.path,
          );
          fail('Expected partial publication');
        } on ResourceFailure catch (failure) {
          receipt = failure.partialReceipt;
        }
        expect(receipt, isNotNull);
        final headFile = File(
          '${fixture.root.path}/${CatalogStorageStore.headStorageKey}',
        );
        final head = await headFile.readAsBytes();
        if (tampered) {
          await File('${fixture.root.path}/assets/models3d/house.glb')
              .writeAsBytes(volumeGlb());
        }
        final outside = Zone.current;
        final denied = <String>[];
        final reconciliation = IOOverrides.runZoned(
          () => fixture.resources.reconcileReceipt(receipt!),
          createFile: (path) {
            final file = outside.run(() => File(path));
            return fixture.foreignPaths.contains(path)
                ? UnreadableFile(file, denied)
                : file;
          },
        );
        if (tampered) {
          await expectLater(reconciliation, throwsA(anything));
        } else {
          await reconciliation;
          expect(
            (await fixture.maps.resourceBaseline(fixture.session))
                .manifest
                .models3d
                .singleWhere((model) => model.id == 'house')
                .inspection
                .bounds
                .min
                .y,
            4,
          );
        }
        expect(denied, isEmpty);
        expect(await headFile.readAsBytes(), head);
      },
    );
  }
  test('Studio explains incompatible animation replacement and preserves the source', () async {
    final fixture = await ModelSourceReplacementFixture.create(0);
    addTearDown(fixture.dispose);
    final original = await fixture.resources.readModel('house');
    await fixture.input.writeAsBytes(animatedGlb());
    await expectLater(
      fixture.resources.replaceModelSource(
        modelId: 'house',
        sourcePath: fixture.input.path,
      ),
      throwsA(
        isA<ResourceFailure>().having(
          (failure) => failure.message,
          'message',
          contains('animations disponibles'),
        ),
      ),
    );
    expect(await fixture.resources.readModel('house'), original);
  });
  test(
    'scoped context can still materialize a subsequent full resource action',
    () async {
      final fixture = await ModelSourceReplacementFixture.create(0);
      addTearDown(fixture.dispose);
      await fixture.input.writeAsBytes(
        volumeGlb(
          edit: (json) {
            json['nodes'][0]['translation'] = [0, 5, 0];
          },
        ),
      );
      await fixture.resources.replaceModelSource(
        modelId: 'house',
        sourcePath: fixture.input.path,
      );
      final configured = await fixture.resources.mutate('model3d.configure', {
        'modelId': 'house',
        'name': 'Renamed house',
      });
      expect(configured.manifest.models3d.single.name, 'Renamed house');
      expect(configured.manifest.models3d.single.inspection.bounds.min.y, 5);
    },
  );
}
