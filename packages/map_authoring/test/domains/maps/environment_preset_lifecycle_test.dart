import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_information_actions_test.dart'
    show informationFixture;
import '../assets/resource_information_fixture.dart';
import 'map_catalog_fixture.dart';

void main() {
  test('direct API deletes a free preset with an unchanged locked dependency',
      () async {
    final fixture = await ResourceInformationFixture.create(_manifest());
    addTearDown(fixture.dispose);
    final handle = ProjectHandle(fixture.project);
    final snapshot = await fixture.snapshots.load(handle);
    final planned = await fixture.mutations.planMutation(
        handle,
        AuthoringRequest(
            requestId: 'environment-direct',
            actionId: 'environment.preset.delete',
            actionVersion: 1,
            workspaceHandle: fixture.workspace,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'environment-direct',
            parameters: const {'presetId': 'forest'}));
    final confirmed =
        await fixture.mutations.confirmMutation(handle, planId: planned.planId);
    var checked = false;
    final result = await fixture.mutations.applyMutation(handle,
        planId: planned.planId,
        operationId: 'environment-direct-apply',
        confirmationToken: confirmed.confirmationToken, precondition: () async {
      checked = true;
    });
    expect(checked, isTrue);
    expect(result.receipt.status, AuthoringReceiptStatus.applied);
    final reread = await fixture.snapshots.load(handle);
    expect(reread.manifest.environmentPresets, isEmpty);
    expect(reread.manifest.elements, snapshot.manifest.elements);
  });

  test('JSONL deletion confirms, applies and rereads the persisted receipt',
      () async {
    final fixture = await ResourceInformationFixture.create(_manifest());
    addTearDown(fixture.dispose);
    final manifestFile = File('${fixture.root.path}/project.json');
    final before = await manifestFile.readAsBytes();
    final planned =
        await fixture.plan('environment.preset.delete', {'presetId': 'forest'});
    expect(planned.status, AuthoringResultStatus.success,
        reason: jsonEncode(planned.toJson()));
    expect(await manifestFile.readAsBytes(), before);
    final refused = await fixture.apply(planned);
    expect(refused.status, AuthoringResultStatus.failure);
    expect(await manifestFile.readAsBytes(), before);
    final confirmation = await fixture.command('confirm', {
      'projectHandle': fixture.project,
      'planId': planned.data['planId'],
    });
    final applied = await fixture.command('apply', {
      'projectHandle': fixture.project,
      'planId': planned.data['planId'],
      'operationId': 'environment-jsonl-delete',
      'confirmationToken': confirmation.data['confirmationToken'],
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: jsonEncode(applied.toJson()));
    expect((applied.data['receipt'] as Map)['status'], 'applied');
    expect((await fixture.read()).environmentPresets, isEmpty);
    expect((await fixture.read()).elements, _manifest().elements);
  });

  test('unused preset deletion preserves its palette and other resources', () {
    final manifest = _manifest();
    final snapshot = catalogSnapshot(const [], project: manifest);
    final dispatcher = MapMutationDispatcher.canonical();
    final descriptor = dispatcher.descriptors
        .singleWhere((entry) => entry.id == 'environment.preset.delete');
    expect(descriptor.riskLevel, AuthoringRiskLevel.high);
    expect(
        (descriptor.extensions['inputSchema'] as Map)['additionalProperties'],
        isFalse);
    final draft = const EnvironmentPresetActions().build(catalogContext(
        snapshot, 'environment.preset.delete', {'presetId': 'forest'}));
    final after = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!)));
    expect(after.environmentPresets, isEmpty);
    expect(after.elements, manifest.elements);
    expect(after.tilesets, manifest.tilesets);
  });

  test('deletion refuses closed map reference and incomplete map inventory',
      () {
    final map = _withArea(catalogMap('closed'));
    final manifest = _manifest().copyWith(maps: const [
      ProjectMapEntry(
          id: 'closed', name: 'Fermée', relativePath: 'closed.json'),
    ]);
    for (final snapshot in [
      catalogSnapshot([map], project: manifest),
      catalogSnapshot(const [], project: manifest),
      catalogSnapshot([catalogMap('closed')],
          project: manifest,
          diagnostics: [
            ProjectSnapshotLoadDiagnostic(
                code: 'project.map_invalid',
                resourceKind: 'map',
                resourceId: 'closed')
          ]),
    ]) {
      expect(
          () => const EnvironmentPresetActions().build(catalogContext(
              snapshot, 'environment.preset.delete', {'presetId': 'forest'})),
          throwsA(isA<VisualLibraryException>().having(
              (error) => error.code,
              'code',
              anyOf('environment.preset_in_use',
                  'environment.inventory_incomplete'))));
    }
  });

  test('closed map dependency added after initial check refuses under lock',
      () async {
    final manifest = _manifest().copyWith(maps: const [
      ProjectMapEntry(
          id: 'closed', name: 'Fermée', relativePath: 'closed.json'),
    ]);
    final fixture = await ResourceInformationFixture.create(
        manifest.copyWith(maps: const []));
    addTearDown(fixture.dispose);
    final map = catalogMap('closed');
    final mapFile = File('${fixture.root.path}/closed.json');
    await mapFile.writeAsString(jsonEncode(map.toJson()));
    final manifestFile = File('${fixture.root.path}/project.json');
    await manifestFile.writeAsString(jsonEncode(manifest.toJson()));
    final planned =
        await fixture.plan('environment.preset.delete', {'presetId': 'forest'});
    expect(planned.status, AuthoringResultStatus.success,
        reason: jsonEncode(planned.toJson()));
    final confirmation = await fixture.command('confirm', {
      'projectHandle': fixture.project,
      'planId': planned.data['planId'],
    });
    final before = await manifestFile.readAsBytes();
    var initialCheckPassed = false;
    await expectLater(
      fixture.mutations.applyMutation(ProjectHandle(fixture.project),
          planId: planned.data['planId'] as String,
          operationId: 'environment-locked-reference',
          confirmationToken: confirmation.data['confirmationToken'] as String,
          precondition: () async {
        initialCheckPassed = true;
        await mapFile.writeAsString(jsonEncode(_withArea(map).toJson()));
      }),
      throwsA(isA<AuthoringPlanException>()
          .having((error) => error.code, 'code', 'plan.stale')),
    );
    expect(initialCheckPassed, isTrue);
    expect(await manifestFile.readAsBytes(), before);
    expect((await fixture.read()).environmentPresets.single.id, 'forest');
    final persisted =
        MapData.fromJson(jsonDecode(await mapFile.readAsString()));
    expect(
        persisted.layers
            .whereType<EnvironmentLayer>()
            .single
            .content
            .areas
            .single
            .presetId,
        'forest');
  });
}

ProjectManifest _manifest() =>
    informationFixture().copyWith(environmentPresets: [
      EnvironmentPreset(
          id: 'forest',
          name: 'Forêt',
          templateId: 'forest',
          palette: [EnvironmentPaletteItem(elementId: 'decor', weight: 1)],
          defaultParams: EnvironmentGenerationParams.standard(),
          sortOrder: 0)
    ]);

MapData _withArea(MapData map) => map.copyWith(layers: [
      ...map.layers,
      MapLayer.environment(
          id: 'environment',
          name: 'Forêt',
          content: EnvironmentLayerContent(targetTileLayerId: 'base', areas: [
            EnvironmentArea(
                id: 'area',
                name: 'Zone',
                presetId: 'forest',
                seed: 37,
                mask: EnvironmentAreaMask(
                    width: map.size.width,
                    height: map.size.height,
                    cells: List.filled(map.size.width * map.size.height, true)))
          ]))
    ]);
