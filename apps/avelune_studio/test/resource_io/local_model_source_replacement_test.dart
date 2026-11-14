import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_workshop.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'local_model_source_replacement_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final unrelated in [0, 90]) {
    test(
      'Studio replaces only the selected source cold and repeated with $unrelated unrelated models',
      () async {
        final fixture = await ModelSourceReplacementFixture.create(unrelated);
        addTearDown(fixture.dispose);
        var baseline = await fixture.maps.resourceBaseline(fixture.session);
        expect(baseline.manifest.models3d, isA<ProjectModel3dEntries>());
        await fixture.maps.loadMapSelection(
          fixture.session,
          baseline.manifest.maps.first,
        );
        baseline = await fixture.maps.resourceBaseline(fixture.session);
        expect(baseline.manifest.models3d, isA<ProjectModel3dEntries>());
        await fixture.maps.loadWorkshop(
          fixture.session,
          MapWorkspaceWorkshop.dialogue,
        );
        baseline = await fixture.maps.resourceBaseline(fixture.session);
        expect(baseline.manifest.models3d, isA<ProjectModel3dEntries>());
        final lightModel = (baseline.manifest.models3d as ProjectModel3dEntries)
            .lookup('house')!;
        await fixture.maps.acceptModelLight(
          fixture.session,
          lightModel,
          baseline.revision,
          baseline.revision,
        );
        baseline = await fixture.maps.resourceBaseline(fixture.session);
        expect(baseline.manifest.models3d, isA<ProjectModel3dEntries>());
        final mapBefore = await fixture.mapFile.readAsBytes();
        final descriptorBefore = await File('${fixture.root.path}/project.json')
            .readAsBytes();
        for (var operation = 0; operation < 2; operation++) {
          final replacement = volumeGlb(
            edit: (json) {
              json['nodes'][0]['translation'] = [0, operation + 2, 0];
            },
          );
          await fixture.input.writeAsBytes(replacement);
          final denied = <String>[];
          final outside = Zone.current;
          final receipt = await IOOverrides.runZoned(
            () => fixture.resources.replaceModelSource(
              modelId: 'house',
              sourcePath: fixture.input.path,
            ),
            createFile: (path) {
              final file = outside.run(() => File(path));
              return fixture.foreignPaths.contains(path)
                  ? UnreadableFile(file, denied)
                  : file;
            },
          );
          expect(denied, isEmpty);
          final model = receipt.manifest.models3d.singleWhere(
            (model) => model.id == 'house',
          );
          expect(model.sourceAssetId, 'house-source');
          expect(model.scale, 1.25);
          expect(model.pivot.toJson(), {'x': 0.25, 'y': 0.0, 'z': 0.0});
          expect(model.inspection.bounds.min.y, operation + 2);
          expect(receipt.changedModels.keys, ['house']);
          expect(receipt.modelSourceRevisions.keys, ['house-source']);
          expect(await fixture.resources.readModel('house'), replacement);
          expect(await fixture.mapFile.readAsBytes(), mapBefore);
          expect(
            await File('${fixture.root.path}/project.json').readAsBytes(),
            descriptorBefore,
          );
        }
        await fixture.maps.loadMapSelection(
          fixture.session,
          baseline.manifest.maps.first,
        );
        final revisited = await fixture.maps.resourceBaseline(fixture.session);
        expect(
          revisited.manifest.models3d
              .singleWhere((model) => model.id == 'house')
              .inspection
              .bounds
              .min
              .y,
          3,
        );
        final reopened = LocalMapWorkspaceAdapter();
        await reopened.loadCatalog(fixture.session);
        final selected = await reopened.loadResourceKind(
          fixture.session,
          'model3d',
        );
        expect(
          selected.metadata.models3d
              .singleWhere((model) => model.id == 'house')
              .inspection
              .bounds
              .min
              .y,
          3,
        );
      },
    );
  }
  test(
    'source acceptance publishes only the model delta without resource reads',
    () async {
      final fixture = await ModelSourceReplacementFixture.create(90);
      addTearDown(fixture.dispose);
      final baseline = await fixture.maps.resourceBaseline(fixture.session);
      final workspace = MapWorkspaceController(fixture.session, fixture.maps)
        ..project = baseline.manifest;
      addTearDown(workspace.dispose);
      final visuals = await StudioMapResources.load(
        fixture.session,
        baseline.manifest,
      );
      addTearDown(visuals.dispose);
      final navigation = ResourceNavigation(
        workspace: workspace,
        port: fixture.resources,
        visuals: visuals,
        onUse: (_) {},
      );
      addTearDown(navigation.dispose);
      await fixture.input.writeAsBytes(
        volumeGlb(
          edit: (json) {
            json['materials'] = [
              {
                'pbrMetallicRoughness': {
                  'baseColorFactor': [0, 1, 0, 1],
                },
              },
            ];
            json['meshes'][0]['primitives'][0]['material'] = 0;
          },
        ),
      );
      final receipt = await fixture.resources.replaceModelSource(
        modelId: 'house',
        sourcePath: fixture.input.path,
      );
      var notifications = 0;
      visuals.modelSourceUpdates.addListener(() => notifications++);
      final attempted = <String>[];
      final outside = Zone.current;
      await IOOverrides.runZoned(
        () => navigation.accept(receipt),
        createFile: (path) =>
            UnreadableFile(outside.run(() => File(path)), attempted),
      );
      expect(attempted, isEmpty);
      expect(workspace.project, receipt.manifest);
      expect(visuals.manifest, same(workspace.project));
      expect(
        visuals.modelSourceUpdates.definition('house'),
        receipt.changedModels['house'],
      );
      expect(
        visuals.modelSourceUpdates.revision('house-source'),
        receipt.modelSourceRevisions['house-source'],
      );
      expect(notifications, 1);
      expect(visuals.store.decoder.reads, 0);
      expect(visuals.store.decoder.decodes, 0);
      expect(navigation.pendingReceipt, isNull);
      final current = workspace.project;
      final lookups = workspace.modelSourceProjectionLookups;
      final unchanged = await fixture.resources.replaceModelSource(
        modelId: 'house',
        sourcePath: fixture.input.path,
      );
      expect(unchanged.noChange, true);
      await navigation.accept(unchanged);
      expect(workspace.project, same(current));
      expect(workspace.modelSourceProjectionLookups, lookups);
      expect(notifications, 1);
    },
  );
}
