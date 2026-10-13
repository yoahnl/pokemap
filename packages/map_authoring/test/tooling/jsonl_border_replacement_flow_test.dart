import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../support/border_replacement_fixture.dart';
import 'jsonl_border_catalog_flow_test.dart' show BorderCatalogHarness;

Future<AuthoringResult> invoke(BorderCatalogHarness h, String command,
        Map<String, Object?> args) async =>
    AuthoringResult.fromJson(jsonDecode(await h.worker.processLine(
            jsonEncode({'id': command, 'command': command, 'args': args})))
        as Map<String, dynamic>);

void main() {
  test(
      'direct and JSONL replacement mutate exactly one native slot and refuse invalid parameters',
      () async {
    final targets = <MapData>[];
    for (final jsonl in [false, true]) {
      final h = await BorderCatalogHarness.create(
          'replacement-${jsonl ? 'jsonl' : 'direct'}');
      try {
        await writeBorderReplacementFixture(h.root);
        final opened = jsonl
            ? (await invoke(h, 'open', {'projectRoot': h.root.path})).data
            : await h.readApi.open(h.root.path);
        final handle = ProjectHandle(opened['projectHandle'] as String);
        final workspace = WorkspaceHandle(opened['workspaceHandle'] as String);
        if (!jsonl) {
          await h.mutations.attachProject(
              projectRootPath: h.root.path,
              workspaceHandle: workspace,
              projectHandle: handle);
        }
        final initial = await h.snapshots.load(handle);
        final original = initial.maps.single;
        final fixture = BorderReplacementFixture(extraVariant: true);
        final slot = fixture.evidence.edges.single.finalPlacement.slotKey;
        final request = AuthoringRequest(
            requestId: 'replace',
            actionId: 'border_layer.feature_set_replacement',
            actionVersion: 1,
            workspaceHandle: workspace.value,
            expectedRevision: initial.revision,
            idempotencyKey: 'replace',
            parameters: {
              'mapId': original.id,
              'layerId': 'original-borders',
              'featureId': 'ledge-feature',
              'slotKey': slot,
              'primitiveId': 'south-alternate'
            });
        final before =
            await File('${h.root.path}/maps/original-map.pokemap.json')
                .readAsBytes();
        final plan = jsonl
            ? (await invoke(h, 'plan', {
                'projectHandle': handle.value,
                'request': request.toJson()
              }))
                .data
            : await h.mutations.plan(handle, request);
        expect(
            await File('${h.root.path}/maps/original-map.pokemap.json')
                .readAsBytes(),
            before);
        final applied = jsonl
            ? (await invoke(h, 'apply', {
                'projectHandle': handle.value,
                'planId': plan['planId'],
                'operationId': 'replace'
              }))
                .data
            : await h.mutations.apply(handle,
                planId: plan['planId'] as String, operationId: 'replace');
        expect((applied['receipt'] as Map)['status'], 'applied');
        final current = await h.snapshots
            .load(handle, policy: ProjectSnapshotLoadPolicy.strict);
        final updated = current.maps.single;
        expect(
            (updated.layers.first as BorderLayer)
                .content
                .features
                .single
                .overrides
                .single
                .replacementPrimitiveId,
            'south-alternate');
        expect(updated.layers.last, original.layers.last);
        targets.add(updated);
        final invalid = AuthoringRequest(
            requestId: 'invalid',
            actionId: request.actionId,
            actionVersion: 1,
            workspaceHandle: workspace.value,
            expectedRevision: current.revision,
            idempotencyKey: 'invalid',
            parameters: {...request.parameters, 'primitiveId': 'missing'});
        if (jsonl) {
          final rejected = await invoke(h, 'plan',
              {'projectHandle': handle.value, 'request': invalid.toJson()});
          expect(rejected.status, AuthoringResultStatus.failure);
          expect(rejected.error!.details['domainCode'],
              'border.primitive_missing');
        } else {
          await expectLater(
              h.mutations.plan(handle, invalid),
              throwsA(isA<MapAuthoringException>()
                  .having((e) => e.code, 'code', 'border.primitive_missing')));
        }
        expect((await h.snapshots.load(handle)).maps.single, updated);
        if (jsonl) {
          await invoke(h, 'close', {'workspaceHandle': workspace.value});
        } else {
          await h.readApi.close(workspace);
        }
      } finally {
        await h.root.delete(recursive: true);
      }
    }
    expect(targets[0], targets[1]);
  });
}
