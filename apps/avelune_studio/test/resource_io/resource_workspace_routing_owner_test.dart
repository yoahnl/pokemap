import 'package:avelune_studio/features/resources/application/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart'
    show ResourcePage;
import 'package:avelune_studio/features/resources/coordination/resource_workspace_routing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../application/resource_pack_transfer_controller_test.dart'
    show ExportPackTestPort, PackTestPort, PendingExportTestSink;

ResourceWorkspaceView _view(
  ResourcePage page, {
  bool decor = false,
  bool environment = false,
  bool terrain = false,
  bool spatial = false,
  bool visuals = false,
}) => resourceWorkspaceView(
  page,
  hasDecor: decor,
  hasEnvironment: environment,
  hasTerrain: terrain,
  terrainSpatial: spatial,
  hasResourceVisuals: visuals,
);

void main() {
  test('the decor and environment pages show their unavailable workshop only while a draft is held', () {
    expect(
      _view(ResourcePage.decor, decor: true),
      ResourceWorkspaceView.decorUnavailable,
    );
    expect(_view(ResourcePage.decor), ResourceWorkspaceView.library);
    expect(
      _view(ResourcePage.environment, environment: true),
      ResourceWorkspaceView.environmentUnavailable,
    );
    expect(_view(ResourcePage.environment), ResourceWorkspaceView.library);
    expect(
      _view(ResourcePage.library, decor: true, environment: true),
      ResourceWorkspaceView.library,
    );
    expect(
      _view(ResourcePage.characters),
      ResourceWorkspaceView.characters,
    );
  });

  test('the terrain editor needs a terrain model and either a spatial terrain or atlas visuals', () {
    expect(
      _view(ResourcePage.terrain, terrain: true, visuals: true),
      ResourceWorkspaceView.terrainEditor,
    );
    expect(
      _view(ResourcePage.terrain, terrain: true, spatial: true),
      ResourceWorkspaceView.terrainEditor,
    );
    expect(
      _view(ResourcePage.terrain, terrain: true),
      ResourceWorkspaceView.library,
    );
    expect(
      _view(ResourcePage.terrain, visuals: true, spatial: true),
      ResourceWorkspaceView.library,
    );
    expect(
      _view(ResourcePage.library, terrain: true, visuals: true),
      ResourceWorkspaceView.library,
    );
  });

  test('a decor can be created from an import only in a 2D project', () {
    expect(resourceImportCanCreateDecor(ProjectDimension.twoD), isTrue);
    expect(resourceImportCanCreateDecor(ProjectDimension.threeD), isFalse);
  });

  test('no pending pack operation means no resolution', () {
    expect(resourcePackResolution(null), isNull);
    final controller = ResourcePackTransferController(
      port: PackTestPort(),
      picker: () async => null,
      accept: (_) async {},
    );
    addTearDown(controller.dispose);
    expect(resourcePackResolution(controller), isNull);
  });

  test('a reconciliation phase maps to the library re-read, not to a new import', () async {
    final port = PackTestPort();
    var accepts = 0;
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => '/retained.aveluneassets',
      accept: (_) async {
        if (++accepts == 1) {
          throw StateError('Relecture indisponible');
        }
      },
    );
    addTearDown(controller.dispose);
    await controller.beginImport();
    await controller.selectFiltered();
    await controller.prepare();
    await controller.apply();
    expect(controller.phase, ResourcePackTransferPhase.reconciliationRequired);

    final resolution = resourcePackResolution(controller)!;
    expect(resolution.kind, ResourcePackResolutionKind.reconciliation);
    expect(resolution.noticeKey, 'resource-pack-reconciliation-pending');
    expect(resolution.actionKey, 'resource-pack-reconcile-library');
    expect(resolution.label, 'Relire la bibliothèque');
    expect(resolution.message, contains('L’import ne sera pas relancé.'));
    await resolution.resolve();
    expect(controller.phase, ResourcePackTransferPhase.complete);
    expect(accepts, 2);
    expect(port.applies, 1);
    expect(resourcePackResolution(controller), isNull);
  });

  test('a recovery phase maps to the finalization recovery', () async {
    final port = PackTestPort()..lateFailure = true;
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => '/retained.aveluneassets',
      accept: (_) async {},
    );
    addTearDown(controller.dispose);
    await controller.beginImport();
    await controller.selectFiltered();
    await controller.prepare();
    await controller.apply();
    expect(controller.phase, ResourcePackTransferPhase.recoveryRequired);

    final resolution = resourcePackResolution(controller)!;
    expect(resolution.kind, ResourcePackResolutionKind.recovery);
    expect(resolution.noticeKey, 'resource-pack-recovery-pending');
    expect(resolution.actionKey, 'resource-pack-recover-finalization');
    expect(resolution.label, 'Reprendre la finalisation');
    expect(resolution.message, contains('La sélection ne sera pas importée à nouveau.'));
    await resolution.resolve();
    expect(port.recoveredOperation, port.appliedOperation);
    expect(port.applies, 1);
    expect(resourcePackResolution(controller), isNull);
  });

  test('an unknown publication maps to the status re-read, not to a new export', () async {
    final port = ExportPackTestPort();
    final sink = PendingExportTestSink();
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => null,
      exportSink: sink,
      accept: (_) async {},
    );
    addTearDown(controller.dispose);
    await controller.beginExport();
    for (final field in {
      'name': 'Pack',
      'author': 'Publisher',
      'universeId': 'original',
      'provenance': 'Original',
    }.entries) {
      await controller.setExportField(field.key, field.value);
    }
    await controller.selectFiltered();
    await controller.prepare();
    controller.setOrganizationAcknowledgement(true);
    await controller.export();
    expect(controller.requiresPublicationReconciliation, isTrue);

    final resolution = resourcePackResolution(controller)!;
    expect(resolution.kind, ResourcePackResolutionKind.publication);
    expect(resolution.noticeKey, 'resource-pack-publication-pending');
    expect(resolution.actionKey, 'resource-pack-reconcile-publication');
    expect(resolution.label, 'Relire le statut de publication');
    expect(resolution.message, contains('Aucun nouvel export ne sera lancé.'));
    final exports = port.verbs.where((verb) => verb == 'export').length;
    await resolution.resolve();
    expect(sink.requeries, 1);
    expect(port.verbs.where((verb) => verb == 'export'), hasLength(exports));
    expect(controller.outputPath, '/published.aveluneassets');
    expect(resourcePackResolution(controller), isNull);
  });
}
