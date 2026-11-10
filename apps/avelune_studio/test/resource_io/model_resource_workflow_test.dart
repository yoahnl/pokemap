import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/resources/coordination/model_resource_workflow.dart';
import 'package:avelune_studio/features/resources/domain/model_source_picker.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';
import '../support/resource_replacement_fixture.dart';

Future<(ResourceReplacementFixture, File)> _open({
  Future<void> Function()? beforeReconciliation,
}) async {
  final host = await ResourceReplacementFixture.create(
    beforeReconciliation: beforeReconciliation,
  );
  final file = File('${host.fixture.root.path}/source.glb');
  await file.writeAsBytes(triangleGlb());
  return (host, file);
}

void _place(ResourceReplacementFixture host, String modelId) {
  host.workspace.documents['scene'] = EditableMapDocument(
    MapWorkspaceDocument(
      mapId: 'scene',
      revision: 'r0',
      map: MapData(
        id: 'scene',
        name: 'Carte ouverte',
        version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4),
        spatialScene: MapSpatialScene(
          width: 4,
          depth: 4,
          instances: [
            SpatialModelInstance(
              id: 'placed',
              modelId: modelId,
              position: Model3dVector3(x: 1, y: 0, z: 1),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('model import replacement and removal use canonical receipts without changing the map', () async {
    final (host, source) = await _open();
    final map = await host.fixture.mapFile.readAsBytes();
    await importStudioModel(
      host.navigation,
      picker: () async => PickedModelSource(source.path, 'Fontaine'),
    );
    final model = host.workspace.project!.models3d.single;
    expect(model.name, 'Fontaine');
    await source.writeAsBytes(animatedGlb());
    final receipt = await replaceStudioModelSource(
      host.navigation,
      model.id,
      picker: () async => PickedModelSource(source.path, 'Source remplacée'),
    );
    expect(receipt, isNotNull);
    expect(host.workspace.project!.models3d.single.id, model.id);
    expect(
      host.workspace.project!.models3d.single.inspection.animations.single.name,
      'Wind',
    );
    final workflow = ModelDefinitionWorkflow(
      navigation: host.navigation,
      isActive: () => true,
    );
    expect(await workflow.remove(model, confirm: () async => true), isTrue);
    expect((await host.reopen()).models3d, isEmpty);
    expect(await host.fixture.mapFile.readAsBytes(), map);
  });

  test('a cancelled model picker does not change project resources', () async {
    final (host, _) = await _open();
    final before = await host.fixture.manifestFile.readAsBytes();
    await importStudioModel(host.navigation, picker: () async => null);
    expect(await host.fixture.manifestFile.readAsBytes(), before);
    expect(host.navigation.busy, isFalse);
  });

  test('a late model picker cannot import into a closed navigation', () async {
    final (host, source) = await _open();
    final picked = Completer<PickedModelSource?>();
    final before = await host.fixture.manifestFile.readAsBytes();
    final importing = importStudioModel(
      host.navigation,
      picker: () => picked.future,
    );
    host.navigation.dispose();
    picked.complete(PickedModelSource(source.path, 'Fontaine'));
    await importing;
    expect(await host.fixture.manifestFile.readAsBytes(), before);
  });

  test('model deletion revalidates live occurrences after consent', () async {
    final (host, source) = await _open();
    await importStudioModel(
      host.navigation,
      picker: () async => PickedModelSource(source.path, 'Fontaine'),
    );
    final model = host.workspace.project!.models3d.single;
    final before = await host.fixture.manifestFile.readAsBytes();
    final workflow = ModelDefinitionWorkflow(
      navigation: host.navigation,
      isActive: () => true,
    );
    ResourceFailure? failure;
    try {
      await workflow.remove(
        model,
        confirm: () async {
          _place(host, model.id);
          return true;
        },
      );
    } on ResourceFailure catch (error) {
      failure = error;
    }
    expect(failure?.message, contains('encore utilisé'));
    expect(await host.fixture.manifestFile.readAsBytes(), before);
    expect(
      host
          .workspace
          .documents['scene']!
          .current
          .spatialScene!
          .instances
          .single
          .modelId,
      model.id,
    );
  });

  test('shared model configuration requires scope consent once and preserves occurrences', () async {
    final (host, source) = await _open();
    await importStudioModel(
      host.navigation,
      picker: () async => PickedModelSource(source.path, 'Fontaine'),
    );
    final model = host.workspace.project!.models3d.single;
    _place(host, model.id);
    final scene = host.workspace.documents['scene']!.current;
    final workflow = ModelDefinitionWorkflow(
      navigation: host.navigation,
      isActive: () => true,
    );
    final scopes = <Map<String, int>>[];
    Future<bool> confirm(Map<String, int> scope) async {
      scopes.add(scope);
      return true;
    }

    await workflow.configure(model, {
      'name': 'Fontaine partagée',
    }, confirmShared: confirm);
    await workflow.configure(model, {'scale': 2}, confirmShared: confirm);
    expect(scopes, [
      {'Carte ouverte': 1},
    ]);
    expect(host.workspace.project!.models3d.single.name, 'Fontaine partagée');
    expect(host.workspace.project!.models3d.single.scale, 2);
    expect(host.workspace.documents['scene']!.current, same(scene));
  });

  test('a pending imported model receipt blocks a repeated import before picking again', () async {
    var reconciliations = 0;
    final (host, source) = await _open(
      beforeReconciliation: () async {
        reconciliations++;
        throw StateError('reconciliation unavailable');
      },
    );
    var picks = 0;
    Future<PickedModelSource?> picker() async {
      picks++;
      return PickedModelSource(source.path, 'Fontaine');
    }

    await importStudioModel(host.navigation, picker: picker);
    final partial = host.navigation.pendingReceipt;
    expect(partial, isNotNull);
    final before = await host.fixture.manifestFile.readAsBytes();
    await importStudioModel(host.navigation, picker: picker);
    expect(picks, 1);
    expect(reconciliations, 1);
    expect(host.navigation.pendingReceipt, same(partial));
    expect(await host.fixture.manifestFile.readAsBytes(), before);
  });
}
