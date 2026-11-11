import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_publication_workflow.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_pack_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog_view.dart';
import 'package:avelune_studio/presentation/features/resources/resource_library_screen.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../application/resource_pack_transfer_controller_test.dart'
    show ExportPackTestPort, ExportTestSink, PendingExportTestSink;
import '../support/map_workspace_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIoUntil;
import 'resource_fixture.dart';

Future<Map<String, List<int>>> _files(Directory root) async => {
  for (final entity in root.listSync(recursive: true))
    if (entity is File) entity.path: await entity.readAsBytes(),
};

Future<_Host> _open(
  WidgetTester tester,
  Size size, {
  PendingExportTestSink? pendingPublication,
  bool marking = true,
  ExportPackTestPort Function(ProjectManifest)? makePackPort,
  String? packPath,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final host = (await tester.runAsync(() async {
    final cache = Directory(
      Platform.environment['AVELUNE_QA_ROOT'] ??
          p.join(
            Platform.isMacOS
                ? p.join(
                    Platform.environment['HOME'] ?? Directory.systemTemp.path,
                    'Library',
                    'Caches',
                  )
                : Directory.systemTemp.path,
            'AveluneQA',
            'resource-pack-retirement',
          ),
    );
    await cache.create(recursive: true);
    final owned = await cache.createTemp('pack-retirement-');
    addTearDown(
      () => tester.runAsync(() async {
        if (await owned.exists()) await owned.delete(recursive: true);
      }),
    );
    final fixture = await ResourceFixture.create(parent: owned);
    addTearDown(() => tester.runAsync(fixture.dispose));
    final imported = await fixture.import();
    for (final id in ['tree', 'rock']) {
      await fixture.resources.saveElement(
        fixture
            .element(imported.createdTilesetId!, id: id)
            .copyWith(name: id == 'tree' ? 'Arbre' : 'Rocher'),
      );
    }
    final workspace = MapWorkspaceController(fixture.session, fixture.maps);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    await workspace.materializeProject();
    final visuals = WorkspaceTestVisuals();
    addTearDown(visuals.dispose);
    final port = makePackPort?.call(workspace.project!) ?? ExportPackTestPort();
    final sink = pendingPublication ?? ExportTestSink();
    var picks = 0;
    final navigation = ResourceNavigation(
      workspace: workspace,
      port: fixture.resources,
      visuals: visuals,
      onUse: (_) {},
      packPort: port,
      packPicker: () async {
        picks++;
        return packPath;
      },
      packExportSink: sink,
    );
    addTearDown(navigation.dispose);
    navigation.library
      ..marking = marking
      ..grid = false;
    return _Host(
      owned,
      fixture,
      workspace,
      visuals,
      navigation,
      port,
      sink,
      () => picks,
    );
  }))!;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: AnimatedBuilder(
          animation: host.navigation,
          builder: (context, _) => ResourceWorkspacePane(
            navigation: host.navigation,
            picker: () async => null,
            onBack: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return host;
}

Future<void> _mark(WidgetTester tester, String id) async {
  final mark = find.byKey(ValueKey('resource-mark-element:$id'));
  await tester.scrollUntilVisible(
    mark,
    160,
    scrollable: find
        .descendant(
          of: find.byType(ResourceCatalogView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.tap(mark);
  await tester.pumpAndSettle();
}

void _expectUnavailable(WidgetTester tester) {
  final library = tester.widget<ResourceLibraryScreen>(
    find.byType(ResourceLibraryScreen),
  );
  expect(library.onImportPack, isNull);
  expect(library.onExportPack, isNull);
  expect(library.onExportMarked, isNull);
  expect(find.byKey(const ValueKey('resource-marked-export')), findsNothing);
  expect(
    find.byKey(const ValueKey('resource-pack-transfer-unavailable')),
    findsOneWidget,
  );
}

void main() {
  for (final size in [const Size(1536, 1024), const Size(760, 620)]) {
    testWidgets(
      'normal catalogue announces pack unavailability without marking at $size',
      (tester) async {
        final host = await _open(tester, size, marking: false);
        final beforeFiles = await tester.runAsync(() => _files(host.owned));
        expect(host.navigation.library.marking, isFalse);
        expect(host.navigation.library.marked, isEmpty);
        expect(find.byKey(const ValueKey('resource-marked-bar')), findsNothing);
        _expectUnavailable(tester);
        expect(
          find.byKey(const ValueKey('resource-pack-reconcile-publication')),
          findsNothing,
        );
        expect(host.transfer.phase, ResourcePackTransferPhase.idle);
        expect(host.transfer.routeActive, isFalse);
        expect(host.transfer.operationActive, isFalse);
        expect(host.port.verbs, isEmpty);
        expect(host.picks(), 0);
        expect(host.sink.entered.isCompleted, isFalse);
        expect(await tester.runAsync(() => _files(host.owned)), beforeFiles);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'retired pack actions retain library selection without starting a transfer at $size',
      (tester) async {
        final host = await _open(tester, size);
        final beforeFiles = await tester.runAsync(() => _files(host.owned));
        final beforeProject = host.workspace.project!.toJson();
        final beforeMap = host.workspace.active!.current;
        await _mark(tester, 'tree');
        await _mark(tester, 'rock');
        final library = host.navigation.library;
        const marked = {'element:tree', 'element:rock'};
        expect(library.marked, marked);
        _expectUnavailable(tester);

        library.query = 'Arbre';
        host.navigation.showLibrary();
        await tester.pumpAndSettle();
        expect(library.marked, marked);
        expect(find.text('dont 1 hors des résultats affichés'), findsOneWidget);
        _expectUnavailable(tester);

        library.query = '';
        library.sort = ResourceSort.nameDescending;
        host.navigation.showLibrary();
        await tester.pumpAndSettle();
        expect(library.marked, marked);
        _expectUnavailable(tester);
        expect(host.transfer.phase, ResourcePackTransferPhase.idle);
        expect(host.transfer.routeActive, isFalse);
        expect(host.transfer.operationActive, isFalse);
        expect(host.transfer.selectedCount, 0);
        expect(host.port.verbs, isEmpty);
        expect(host.port.authorizedPaths, isEmpty);
        expect(host.picks(), 0);
        expect(host.sink.entered.isCompleted, isFalse);

        await tester.tap(find.byKey(const ValueKey('resource-marked-clear')));
        await tester.pumpAndSettle();
        expect(library.marked, isEmpty);
        expect(host.port.verbs, isEmpty);
        expect(host.picks(), 0);
        expect(host.workspace.project!.toJson(), beforeProject);
        expect(host.workspace.active!.current, beforeMap);
        expect(await tester.runAsync(() => _files(host.owned)), beforeFiles);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'catalogue retirement preserves an unknown publication and its real workspace close guard',
    (tester) async {
      final sink = PendingExportTestSink();
      final host = await _open(
        tester,
        const Size(1536, 1024),
        pendingPublication: sink,
      );
      final transfer = host.transfer;
      await tester.runAsync(() async {
        await transfer.beginExport();
        for (final entry in {
          'name': 'Pack',
          'author': 'Publisher',
          'universeId': 'original',
          'provenance': 'Original',
        }.entries) {
          await transfer.setExportField(entry.key, entry.value);
        }
        await transfer.selectFiltered();
        await transfer.prepare();
        transfer.setOrganizationAcknowledgement(true);
        await transfer.export();
      });
      expect(transfer.phase, ResourcePackTransferPhase.publicationRequired);
      expect(transfer.blocksClose, isTrue);
      final beforeVerbs = [...host.port.verbs];
      final beforeReleased = [...host.port.released];
      final beforeFiles = await tester.runAsync(() => _files(host.owned));
      await tester.pumpAndSettle();
      await _mark(tester, 'tree');
      _expectUnavailable(tester);
      host.navigation.showLibrary();
      await tester.pumpAndSettle();
      expect(host.navigation.packTransfer, same(transfer));
      expect(transfer.requiresPublicationReconciliation, isTrue);
      expect(transfer.outputPath, isNull);
      expect(transfer.blocksClose, isTrue);
      expect(host.port.verbs, beforeVerbs);
      expect(host.picks(), 0);

      final workflow = WorkspaceWorkflow(
        controller: host.workspace,
        isActive: () => true,
        changed: () {},
        resources: () => host.navigation,
        narrative: () => null,
        confirmClose: () async => WorkspaceCloseChoice.cancel,
        flushFocus: () {},
        launchMap: (_, _) async {},
      );
      final publication = WorkspacePublicationWorkflow(
        controller: host.workspace,
        workflow: workflow,
        isActive: () => true,
        connectionBusy: () => false,
        exporter: () => null,
        resources: () => host.navigation,
        pokemon: () => null,
      );
      expect(
        await tester.runAsync(
          () => publication.allowClose(leavePokemon: () async => true),
        ),
        isFalse,
      );
      expect(
        await tester.runAsync(
          () => publication.prepareExport(
            confirmPokemonSave: () async => true,
            confirmSave: () async => true,
          ),
        ),
        isFalse,
      );
      expect(host.port.verbs, beforeVerbs);
      expect(host.port.released, beforeReleased);
      expect(
        find.byKey(const ValueKey('resource-pack-publication-pending')),
        findsOneWidget,
      );
      final retry = find.byKey(
        const ValueKey('resource-pack-reconcile-publication'),
      );
      expect(retry, findsOneWidget);
      expect(transfer.operationActive, isFalse);
      await tester.tap(retry);
      await pumpIoUntil(
        tester,
        () => !transfer.operationActive,
        maxFrames: 500,
      );
      expect(
        transfer.operationActive,
        isFalse,
        reason:
            'Publication recheck did not finish: phase=${transfer.phase}, '
            'error=${transfer.error}, requeries=${sink.requeries}',
      );
      await tester.pumpAndSettle();
      expect(transfer.outputPath, '/published.aveluneassets');
      expect(transfer.requiresPublicationReconciliation, isFalse);
      expect(transfer.blocksClose, isFalse);
      expect(retry, findsNothing);
      expect(sink.requeries, 1);
      expect(
        host.port.verbs.where((verb) => verb == 'export').length,
        beforeVerbs.where((verb) => verb == 'export').length,
      );
      expect(host.port.verbs, beforeVerbs);
      expect(host.picks(), 0);
      expect(
        await tester.runAsync(
          () => publication.allowClose(leavePokemon: () async => true),
        ),
        isTrue,
      );
      expect(host.navigation.library.marked, {'element:tree'});
      expect(await tester.runAsync(() => _files(host.owned)), beforeFiles);
      expect(tester.takeException(), isNull);
    },
  );

  for (final phase in [
    ResourcePackTransferPhase.reconciliationRequired,
    ResourcePackTransferPhase.recoveryRequired,
  ]) {
    testWidgets(
      'retained $phase resolves through the UI while the catalogue stays guarded',
      (tester) async {
        final host = await _open(
          tester,
          const Size(1536, 1024),
          makePackPort: (project) => _PackResolutionTestPort(
            project,
            recovery: phase == ResourcePackTransferPhase.recoveryRequired,
          ),
          packPath: '/retained.aveluneassets',
        );
        final port = host.port as _PackResolutionTestPort;
        final transfer = host.transfer;
        await _mark(tester, 'tree');
        await tester.runAsync(() async {
          await transfer.beginImport();
          await transfer.selectFiltered();
          await transfer.prepare();
          expect(transfer.canApply, isTrue);
          await transfer.apply();
        });
        expect(transfer.phase, phase);
        expect(transfer.preparedSummary['createdDefinitionCount'], 10001);
        expect(transfer.preparedSummary['copiedDefinitionCount'], 0);
        expect(port.applies, 1);
        expect(port.appliedOperation, isNotNull);
        final beforeVerbs = [...port.verbs];
        final beforeAuthorized = [...port.authorizedPaths];
        final beforeReleased = [...port.released];
        final beforePicks = host.picks();
        expect(beforePicks, 1);
        final beforeFiles = await tester.runAsync(() => _files(host.owned));
        final beforeProject = host.workspace.project!.toJson();
        final beforeMap = host.workspace.active!.current;
        await tester.pump();
        final reconciliation =
            phase == ResourcePackTransferPhase.reconciliationRequired;
        final action = find.byKey(
          ValueKey(
            reconciliation
                ? 'resource-pack-reconcile-library'
                : 'resource-pack-recover-finalization',
          ),
        );
        final notice = find.byKey(
          ValueKey(
            reconciliation
                ? 'resource-pack-reconciliation-pending'
                : 'resource-pack-recovery-pending',
          ),
        );
        expect(action, findsOneWidget);
        expect(notice, findsOneWidget);
        expect(
          find.ancestor(
            of: action,
            matching: find.byWidgetPredicate(
              (widget) => widget is AbsorbPointer && widget.absorbing,
            ),
          ),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('resource-pack-reconcile-publication')),
          findsNothing,
        );
        expect(transfer.blocksClose, isTrue);
        expect(host.navigation.busy, isTrue);
        expect(transfer.operationActive, isFalse);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        _expectUnavailable(tester);

        final workflow = WorkspaceWorkflow(
          controller: host.workspace,
          isActive: () => true,
          changed: () {},
          resources: () => host.navigation,
          narrative: () => null,
          confirmClose: () async => WorkspaceCloseChoice.cancel,
          flushFocus: () {},
          launchMap: (_, _) async {},
        );
        final publication = WorkspacePublicationWorkflow(
          controller: host.workspace,
          workflow: workflow,
          isActive: () => true,
          connectionBusy: () => false,
          exporter: () => null,
          resources: () => host.navigation,
          pokemon: () => null,
        );
        Future<void> expectBlocked() async {
          expect(
            await tester.runAsync(
              () => publication.allowClose(leavePokemon: () async => true),
            ),
            isFalse,
          );
          expect(
            await tester.runAsync(
              () => publication.prepareExport(
                confirmPokemonSave: () async => true,
                confirmSave: () async => true,
              ),
            ),
            isFalse,
          );
        }

        await expectBlocked();
        await tester.tap(action);
        await pumpIoUntil(
          tester,
          () => !transfer.operationActive,
          maxFrames: 500,
        );
        await tester.pump();
        expect(transfer.operationActive, isFalse);
        expect(transfer.phase, phase);
        expect(transfer.error, 'Relecture indisponible');
        expect(port.reconciliations, 1);
        expect(port.applies, 1);
        expect(port.authorizedPaths, beforeAuthorized);
        expect(host.picks(), beforePicks);
        expect(find.text('Relecture indisponible'), findsOneWidget);
        expect(action, findsOneWidget);
        expect(transfer.blocksClose, isTrue);
        expect(host.navigation.busy, isTrue);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        await expectBlocked();

        await tester.tap(action);
        await pumpIoUntil(
          tester,
          () => !transfer.operationActive,
          maxFrames: 500,
        );
        await tester.pump();
        expect(transfer.operationActive, isFalse);
        expect(transfer.phase, ResourcePackTransferPhase.complete);
        expect(transfer.error, isNull);
        expect(transfer.blocksClose, isFalse);
        expect(host.navigation.busy, isFalse);
        expect(host.navigation.pendingReceipt, isNull);
        expect(action, findsNothing);
        expect(notice, findsNothing);
        await tester.pumpAndSettle();
        expect(
          await tester.runAsync(
            () => publication.allowClose(leavePokemon: () async => true),
          ),
          isTrue,
        );
        expect(port.rereads, reconciliation ? 1 : 2);
        expect(port.reconciliations, 2);
        expect(port.verbs.take(beforeVerbs.length), beforeVerbs);
        expect(
          port.verbs.skip(beforeVerbs.length),
          reconciliation
              ? isEmpty
              : ['recovery_status', 'start_recovery', 'recovery_status'],
        );
        expect(port.applies, 1);
        expect(port.authorizedPaths, beforeAuthorized);
        expect(port.released, beforeReleased);
        expect(host.picks(), beforePicks);
        if (!reconciliation) {
          expect(port.recoveredOperation, port.appliedOperation);
        }
        expect(host.sink.entered.isCompleted, isFalse);
        expect(host.navigation.library.marked, {'element:tree'});
        expect(host.workspace.project!.toJson(), beforeProject);
        expect(host.workspace.active!.current, beforeMap);
        expect(await tester.runAsync(() => _files(host.owned)), beforeFiles);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

final class _PackResolutionTestPort extends ExportPackTestPort {
  _PackResolutionTestPort(this.project, {required bool recovery}) {
    lateFailure = recovery;
  }

  final ProjectManifest project;
  int rereads = 0, reconciliations = 0;

  @override
  ResourceMutationReceipt get receipt => ResourceMutationReceipt(
    before: project,
    manifest: project,
    beforeRevision: 'retained-import',
    revision: 'retained-import',
    changedPaths: const [],
    actionId: 'resource_pack.import',
    operationId: appliedOperation,
  );

  @override
  Future<ResourceMutationReceipt> applyImport({
    required String preparedHandle,
    required String expectedRevision,
    required String operationId,
    required ResourcePackJobMonitor monitor,
  }) async {
    await super.applyImport(
      preparedHandle: preparedHandle,
      expectedRevision: expectedRevision,
      operationId: operationId,
      monitor: monitor,
    );
    throw ResourcePackCommittedFailure(
      operationId,
      const ResourceFailure('Import retenu avant relecture'),
    );
  }

  @override
  Future<ResourceMutationReceipt> rereadApplied() async {
    rereads++;
    return receipt;
  }

  @override
  Future<void> reconcile(ResourceMutationReceipt receipt) async {
    reconciliations++;
    if (reconciliations == 1) {
      throw const ResourceFailure('Relecture indisponible');
    }
  }
}

final class _Host {
  _Host(
    this.owned,
    this.fixture,
    this.workspace,
    this.visuals,
    this.navigation,
    this.port,
    this.sink,
    this.picks,
  );

  final Directory owned;
  final ResourceFixture fixture;
  final MapWorkspaceController workspace;
  final WorkspaceTestVisuals visuals;
  final ResourceNavigation navigation;
  final ExportPackTestPort port;
  final ExportTestSink sink;
  final int Function() picks;
  ResourcePackTransferController get transfer => navigation.packTransfer!;
}
