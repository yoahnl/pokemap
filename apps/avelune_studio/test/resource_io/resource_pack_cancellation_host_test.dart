import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';

import '../support/map_workspace_fixture.dart';

import 'package:avelune_studio/features/resources/application/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_pack_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionCheckpoint, AuthoringTransactionSimulatedCrash;

import '../application/resource_pack_transfer_controller_test.dart'
    show
        PackTestPort,
        ExportPackTestPort,
        ExportTestSink,
        PendingExportTestSink;
import 'resource_pack_import_host_test.dart' show ResourcePackTestHost;

void main() {
  testWidgets(
    'real shell blocks close and switch until unknown publication is reconciled',
    (tester) async {
      final sink = PendingExportTestSink();
      final host = await mountPackShell(
        tester,
        ExportPackTestPort(),
        exportSink: sink,
      );
      final c = host.navigation.packTransfer!;
      await configurePackExport(c);
      await c.selectFiltered();
      await c.prepare();
      c.setOrganizationAcknowledgement(true);
      await c.export();
      expect(c.requiresPublicationReconciliation, isTrue);
      expect(await host.exit(), isFalse);
      expect(await host.home.allowSwitch!(), isFalse);
      await c.retryPublication();
      expect(c.outputPath, '/published.aveluneassets');
      expect(await host.exit(), isTrue);
      expect(await host.home.allowSwitch!(), isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final verb in ['stage_license', 'prepare', 'export']) {
    testWidgets(
      'real shell close and switch wait for export $verb cancellation',
      (tester) async {
        final port = DelayedExportPackPort();
        final host = await mountPackShell(
          tester,
          port,
          exportSink: ExportTestSink(),
        );
        final c = host.navigation.packTransfer!;
        await configurePackExport(c);
        await c.selectFiltered();
        if (verb == 'export') {
          await c.prepare();
          c.setOrganizationAcknowledgement(true);
        }
        port.blockedVerb = verb;
        final operation = verb == 'stage_license'
            ? c.addLicenseDocuments()
            : verb == 'prepare'
            ? c.prepare()
            : c.export();
        await port.entered.future;
        var exited = false, switched = false;
        final exiting = host.exit().then((v) {
          exited = true;
          return v;
        });
        final switching = host.home.allowSwitch!().then((v) {
          switched = true;
          return v;
        });
        await tester.pump();
        await port.cancelled.future;
        expect(exited, isFalse);
        expect(switched, isFalse);
        port.terminal.complete();
        await tester.pump(const Duration(milliseconds: 100));
        await operation;
        expect(await exiting, isTrue);
        expect(await switching, isTrue);
        expect(c.outputPath, isNull);
        expect(port.applies, 0);
        await tester.pumpWidget(const SizedBox());
        host.home.dispose();
        host.workspace.dispose();
      },
    );
  }
  testWidgets(
    'real shell waits during sink writing and refuses close at the publication barrier',
    (tester) async {
      for (final publishing in [false, true]) {
        final port = ExportPackTestPort();
        final sink = BarrierExportTestSink(publishing);
        final host = await mountPackShell(tester, port, exportSink: sink);
        final c = host.navigation.packTransfer!;
        await configurePackExport(c);
        await c.selectFiltered();
        await c.prepare();
        c.setOrganizationAcknowledgement(true);
        final exporting = c.export();
        await sink.entered.future;
        expect(c.operationActive, isTrue);
        if (publishing) {
          expect(c.phase, ResourcePackTransferPhase.publishing);
          expect(await host.exit(), isFalse);
          expect(await host.home.allowSwitch!(), isFalse);
          sink.gate.complete();
          await exporting;
          expect(c.outputPath, '/published.aveluneassets');
          expect(await host.exit(), isTrue);
        } else {
          var done = false;
          final exiting = host.exit().then((v) {
            done = true;
            return v;
          });
          final switching = host.home.allowSwitch!();
          await tester.pump();
          expect(done, isFalse);
          sink.gate.complete();
          await exporting;
          expect(await exiting, isTrue);
          expect(await switching, isTrue);
          expect(c.outputPath, isNull);
        }
        await tester.pumpWidget(const SizedBox());
        host.home.dispose();
        host.workspace.dispose();
      }
    },
  );

  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real shell close and project switch await cancellation before reservation',
    (tester) async {
      final port = DelayedPackPort();
      final host = await mountPackShell(tester, port);
      final controller = host.navigation.packTransfer!;
      final importing = controller.beginImport();
      await port.entered.future;
      var exitDone = false, switchDone = false;
      final exiting = host.exit().then((value) {
        exitDone = true;
        return value;
      });
      final switching = host.home.allowSwitch!().then((value) {
        switchDone = true;
        return value;
      });
      port.start.complete({
        'snapshot': {'jobId': 'staging', 'state': 'running'},
        'phase': 'staging',
        'cancelAllowed': true,
      });
      await tester.pump();
      await port.cancelled.future;
      expect(exitDone, isFalse);
      expect(switchDone, isFalse);
      port.terminal.complete();
      await tester.pump(const Duration(milliseconds: 100));
      expect(await exiting, isTrue);
      expect(await switching, isTrue);
      await importing;
      expect(port.applies, 0);
      await tester.pumpWidget(const SizedBox());
      host.home.dispose();
      host.workspace.dispose();
    },
  );
  testWidgets(
    'real shell blocks close and switch during finalization and receipt reconciliation',
    (tester) async {
      final port = FinalizingPackPort();
      final visuals = GuardVisuals();
      final host = await mountPackShell(tester, port, visuals: visuals);
      final controller = host.navigation.packTransfer!;
      await controller.beginImport();
      await controller.selectFiltered();
      await controller.prepare();
      final applying = controller.apply();
      await tester.pump(const Duration(milliseconds: 100));
      await port.entered.future;
      expect(await host.exit(), isFalse);
      expect(await host.home.allowSwitch!(), isFalse);
      port.terminal.complete();
      await tester.pump();
      await applying;
      expect(controller.requiresReconciliation, isTrue);
      expect(host.navigation.pendingReceipt, isNotNull);
      expect(await host.exit(), isFalse);
      expect(await host.home.allowSwitch!(), isFalse);
      visuals.fail = false;
      expect(await host.navigation.retryReconciliation(), isTrue);
      expect(controller.requiresReconciliation, isFalse);
      expect(await host.exit(), isTrue);
      expect(await host.home.allowSwitch!(), isTrue);
      expect(port.applies, 1);
      await tester.pumpWidget(const SizedBox());
      host.home.dispose();
      host.workspace.dispose();
    },
  );
  test('late native crash keeps the project blocked until original operation recovery', () async {
    var injected = false;
    String? operation;
    final host = await ResourcePackTestHost.create(
      faultInjector: (context) {
        if (!injected &&
            context.checkpoint ==
                AuthoringTransactionCheckpoint.afterResourcePromoted) {
          injected = true;
          operation = context.operationId;
          throw const AuthoringTransactionSimulatedCrash();
        }
      },
    );
    addTearDown(host.dispose);
    await host.prepare();
    await host.transfer.apply();
    expect(injected, isTrue);
    expect(host.transfer.requiresRecovery, isTrue);
    expect(await host.transfer.requestClose(), isFalse);
    await host.transfer.recover();
    expect(host.transfer.error, isNull);
    expect(host.transfer.requiresRecovery, isFalse);
    expect(operation, startsWith('studio_pack_'));
    expect((await host.reopen()).elements, isNotEmpty);
    expect(await host.transfer.requestClose(), isTrue);
  });
  test('close requested before start reply cancels and waits for terminal cancelled', () async {
    final port = DelayedPackPort();
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => '/chosen.aveluneassets',
      accept: (_) async {},
      pollInterval: Duration.zero,
    );
    final importing = controller.beginImport();
    await port.entered.future;
    var closed = false;
    final closing = controller.requestClose().then((value) {
      closed = value;
      return value;
    });
    expect(closed, isFalse);
    port.start.complete({
      'snapshot': {'jobId': 'staging', 'state': 'running'},
      'phase': 'staging',
      'cancelAllowed': true,
    });
    await port.cancelled.future;
    expect(closed, isFalse);
    port.terminal.complete();
    expect(await closing, isTrue);
    await importing;
    expect(port.verbs, isNot(contains('inspect')));
    expect(port.applies, 0);
    controller.dispose();
  });

  test('finalization refuses close and waits for actual receipt', () async {
    final port = FinalizingPackPort();
    final controller = ResourcePackTransferController(
      port: port,
      picker: () async => '/chosen.aveluneassets',
      accept: (_) async {},
      pollInterval: Duration.zero,
    );
    await controller.beginImport();
    await controller.selectFiltered();
    await controller.prepare();
    final applying = controller.apply();
    await port.entered.future;
    expect(await controller.requestClose(), isFalse);
    expect(port.verbs, isNot(contains('cancel')));
    port.terminal.complete();
    await applying;
    expect(controller.error, isNull);
    expect(await controller.requestClose(), isTrue);
    controller.dispose();
  });
}

class DelayedPackPort extends PackTestPort {
  final entered = Completer<void>(),
      cancelled = Completer<void>(),
      terminal = Completer<void>();
  final start = Completer<Map<String, Object?>>();
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    if (verb == 'stage') {
      entered.complete();
      return start.future;
    }
    if (verb == 'cancel') {
      if (!cancelled.isCompleted) cancelled.complete();
      return {'state': 'cancelling', 'bounded': false};
    }
    if (verb == 'get') {
      await terminal.future;
      return {
        'snapshot': {'jobId': 'staging', 'state': 'cancelled'},
        'phase': 'cancelled',
        'cancelAllowed': false,
      };
    }
    return super.transfer(verb, input);
  }
}

class FinalizingPackPort extends PackTestPort {
  final entered = Completer<void>(), terminal = Completer<void>();
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    if (verb == 'get') {
      entered.complete();
      await terminal.future;
      return settled({
        'receipt': {'receiptId': 'applied'},
      });
    }
    return super.transfer(verb, input);
  }

  @override
  Future<ResourceMutationReceipt> applyImport({
    required String preparedHandle,
    required String expectedRevision,
    required String operationId,
    required ResourcePackJobMonitor monitor,
  }) async {
    applies++;
    await monitor({
      'snapshot': {'jobId': 'apply', 'state': 'running'},
      'phase': 'finalizing',
      'cancelAllowed': false,
    });
    return receipt;
  }
}

Future<
  ({
    ResourceNavigation navigation,
    StudioHomeNavigation home,
    MapWorkspaceController workspace,
    Future<bool> Function() exit,
  })
>
mountPackShell(
  WidgetTester tester,
  PackTestPort pack, {
  GuardVisuals? visuals,
  ResourcePackExportSink? exportSink,
}) async {
  final workspace = MapWorkspaceController(
    workspaceSession,
    WorkspaceMemoryPort(),
  );
  final home = StudioHomeNavigation();
  Future<bool> Function()? exit;
  await tester.pumpWidget(
    MaterialApp(
      home: MapWorkspaceScreen(
        controller: workspace,
        loadVisuals: (_, _) async => visuals ?? WorkspaceTestVisuals(),
        runtimeBuilder: (_, _, _) => const SizedBox(),
        onClose: () async {},
        registerExitGuard: (value) => exit = value,
        resourcePort: GuardResourcePort(),
        resourcePackPort: pack,
        resourcePackLicensePicker: () async => ['/LICENSE'],
        resourcePackExportSink: exportSink,
        resourcePackPicker: () async => '/chosen.aveluneassets',
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  home.navigate('resources');
  await tester.pumpAndSettle();
  final navigation = tester
      .widget<ResourceWorkspacePane>(find.byType(ResourceWorkspacePane))
      .navigation;
  expect(exit, isNotNull);
  expect(home.allowSwitch, isNotNull);
  return (
    navigation: navigation,
    home: home,
    workspace: workspace,
    exit: exit!,
  );
}

class GuardResourcePort implements ResourcePort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class GuardVisuals extends WorkspaceTestVisuals
    implements ResourceWorkspaceVisuals {
  bool fail = true;
  @override
  Widget atlasPreview(String tilesetId) => const SizedBox();
  @override
  void setTerrainBrush(ProjectSmartTilePreset? preset) {}
  @override
  Future<void> updateCatalog(
    ProjectManifest manifest, {
    Set<String> changedRelativePaths = const {},
  }) async {
    if (fail) throw StateError('visual refresh unavailable');
  }
}

Future<void> configurePackExport(ResourcePackTransferController c) async {
  await c.beginExport();
  for (final e in {
    'name': 'Pack',
    'author': 'Publisher',
    'universeId': 'original',
    'provenance': 'Original',
  }.entries) {
    await c.setExportField(e.key, e.value);
  }
  expect(c.error, isNull);
}

class DelayedExportPackPort extends ExportPackTestPort {
  String? blockedVerb;
  final entered = Completer<void>(),
      cancelled = Completer<void>(),
      terminal = Completer<void>();
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    if (verb == blockedVerb) {
      entered.complete();
      return {
        'snapshot': {'jobId': 'export-test-job', 'state': 'running'},
        'phase': verb,
        'cancelAllowed': true,
      };
    }
    if (verb == 'cancel' && input['jobId'] == 'export-test-job') {
      if (!cancelled.isCompleted) cancelled.complete();
      return {'state': 'cancelling', 'bounded': false};
    }
    if (verb == 'get' && input['jobId'] == 'export-test-job') {
      await terminal.future;
      return {
        'snapshot': {'jobId': 'export-test-job', 'state': 'cancelled'},
        'phase': 'cancelled',
        'cancelAllowed': false,
      };
    }
    return super.transfer(verb, input);
  }
}

class BarrierExportTestSink implements ResourcePackExportSink {
  @override
  Future<ResourcePackPublication> reconcilePublication(String token) async =>
      throw StateError('No pending publication');
  BarrierExportTestSink(this.publishing);
  final bool publishing;
  final entered = Completer<void>(), gate = Completer<void>();
  @override
  Future<ResourcePackPublication> publish({
    required String suggestedName,
    required int byteLength,
    required String rawSha256,
    required Future<List<int>> Function(int, int) readChunk,
    required bool Function() isCancelled,
    required void Function() enterFinalization,
  }) async {
    if (publishing) enterFinalization();
    entered.complete();
    await gate.future;
    if (isCancelled()) return const ResourcePackPublication.cancelled();
    if (!publishing) enterFinalization();
    return const ResourcePackPublication.published('/published.aveluneassets');
  }
}
