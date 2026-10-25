import 'package:avelune_studio/presentation/features/resources/resource_library_screen.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:avelune_studio/features/resources/application/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/presentation/features/resources/resource_pack_transfer_dialog.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';

import '../application/resource_pack_transfer_controller_test.dart'
    show
        PackTestPort,
        ExportPackTestPort,
        ExportTestSink,
        PendingExportTestSink;

import '../support/map_workspace_fixture.dart';
import '../resource_io/resource_pack_import_host_test.dart'
    show ResourcePackTestHost;

void main() {
  testWidgets('oversized derived draft notice remains visible before import', (
    tester,
  ) async {
    final c = ResourcePackTransferController(
      port: PackTestPort(),
      picker: () async => null,
      accept: (_) async {},
    );
    addTearDown(c.dispose);
    c.phase = ResourcePackTransferPhase.preview;
    c.preview = [
      {
        'kind': 'authoringDraftNotice',
        'label': 'Eau animée',
        'message': 'Le terrain publié reste disponible pour peindre. Son brouillon dépasse les limites du catalogue.',
      },
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(body: ResourcePackTransferDialog(controller: c)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'Eau animée : Le terrain publié reste disponible pour peindre.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Nécessaire pour « null »'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'unknown publication shows a status-only retry without premature success',
    (tester) async {
      final port = ExportPackTestPort();
      final sink = PendingExportTestSink();
      final c = ResourcePackTransferController(
        port: port,
        picker: () async => null,
        exportSink: sink,
        accept: (_) async {},
      );
      addTearDown(c.dispose);
      await c.beginExport();
      for (final e in {
        'name': 'Pack',
        'author': 'Publisher',
        'universeId': 'original',
        'provenance': 'Original',
      }.entries) {
        await c.setExportField(e.key, e.value);
      }
      await c.selectFiltered();
      await c.prepare();
      c.setOrganizationAcknowledgement(true);
      await c.export();
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(body: ResourcePackTransferDialog(controller: c)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Relire le statut de publication'), findsOneWidget);
      expect(find.textContaining('Pack exporté :'), findsNothing);
      expect(c.outputPath, isNull);
      await tester.tap(find.text('Relire le statut de publication'));
      await tester.pumpAndSettle();
      expect(c.outputPath, '/published.aveluneassets');
      expect(find.textContaining('Pack exporté :'), findsOneWidget);
      expect(sink.requeries, 1);
    },
  );

  testWidgets(
    'export route keeps its footer and Escape accessible at 700x500 and text 1.8',
    (tester) async {
      tester.view.physicalSize = const Size(700, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final port = ExportPackTestPort();
      final c = ResourcePackTransferController(
        port: port,
        picker: () async => null,
        exportSink: ExportTestSink(),
        accept: (_) async {},
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    showResourcePackExport(context, c, projectName: 'Project'),
                child: const Text('Open export'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open export'));
      await tester.pumpAndSettle();
      expect(find.text('Exporter un pack de ressources'), findsOneWidget);
      for (final e in {
        'name': 'Pack',
        'author': 'Publisher',
        'universeId': 'original',
        'provenance': 'Original',
      }.entries) {
        await c.setExportField(e.key, e.value);
      }
      await c.selectFiltered();
      await c.prepare();
      await tester.pumpAndSettle();
      expect(c.error, isNull);
      final ack = find.byKey(const ValueKey('resource-pack-organization-ack'));
      await tester.ensureVisible(ack);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: ack, matching: find.byType(Switch)));
      await tester.pumpAndSettle();
      final confirm = find.byKey(const ValueKey('confirm-reviewed-plan'));
      expect(tester.getBottomRight(confirm).dy, lessThanOrEqualTo(500));
      expect(c.canExport, isTrue);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ResourcePackTransferDialog), findsNothing);
      expect(
        port.released.where((h) => h == 'native-prepared-1'),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'completed import retains the explicit before-import and planned-write summary',
    (tester) async {
      final controller = ResourcePackTransferController(
        port: PackTestPort(),
        picker: () async => '/chosen.aveluneassets',
        accept: (_) async {},
      );
      addTearDown(controller.dispose);
      await controller.beginImport();
      await controller.selectFiltered();
      await controller.prepare();
      final preparedSummary = controller.preparedSummary;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: ResourcePackTransferDialog(controller: controller),
          ),
        ),
      );
      await controller.apply();
      await tester.pumpAndSettle();
      expect(controller.phase, ResourcePackTransferPhase.complete);
      expect(controller.preparedSummary, same(preparedSummary));
      expect(
        find.textContaining('0 présentes avant cet import'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Écritures prévues pour cette installation :'),
        findsOneWidget,
      );
      expect(find.textContaining('total à écrire :'), findsNothing);
      expect(find.textContaining('0 présentes dans le projet'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'native conflict names the resource and copy produces an applicable preview',
    (tester) async {
      final host = (await tester.runAsync(ResourcePackTestHost.create))!;
      late String localElementId;
      try {
        await tester.runAsync(() async {
          await host.transfer.beginImport();
          await host.transfer.setFilter(kind: 'element');
          await host.transfer.selectFiltered();
          await host.transfer.prepare();
          await host.transfer.apply();
          final element = host.workspace.project!.elements.first;
          localElementId = element.id;
          await host.navigation.accept(
            await host.resources.saveElement(
              element.copyWith(name: 'Mon décor local'),
            ),
          );
          await host.transfer.beginImport();
          await host.transfer.setFilter(kind: 'environmentPreset');
          await host.transfer.selectFiltered();
          await host.transfer.prepare();
        });
        expect(host.transfer.error, isNull);
        expect(host.transfer.conflictCount, greaterThan(0));
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        ResourcePackTransferDialog(controller: host.transfer),
                  ),
                  child: const Text('Review'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Review'));
        await tester.pumpAndSettle();
        final named = host.transfer.preview
            .where((row) => row['conflict'] != null)
            .first;
        expect(named['label'], contains('Original'));
        expect(named['message'], contains('modifiée'));
        expect(
          find.textContaining('${named['label']} : ${named['message']}'),
          findsOneWidget,
        );
        expect(
          find.textContaining('dependency_modified_or_missing:'),
          findsNothing,
        );
        final copy = find.text('Importer une copie');
        await tester.ensureVisible(copy);
        await tester.runAsync(() => tester.tap(copy));
        await tester.runAsync(() async {
          final until = DateTime.now().add(const Duration(seconds: 20));
          while (host.transfer.operationActive &&
              DateTime.now().isBefore(until)) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });
        await tester.pumpAndSettle();
        expect(host.transfer.error, isNull);
        expect(host.transfer.canApply, isTrue);
        expect(
          host.transfer.preparedSummary['copiedDefinitionCount'],
          greaterThan(0),
        );
        expect(find.text('Importer la sélection'), findsOneWidget);
        expect(
          host.workspace.project!.elements
              .singleWhere((element) => element.id == localElementId)
              .name,
          'Mon décor local',
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(host.dispose);
      }
    },
  );
  testWidgets(
    'cancelling the native picker closes the real route without error',
    (tester) async {
      final controller = ResourcePackTransferController(
        port: PackTestPort(),
        picker: () async => null,
        accept: (_) async {
          fail('No mutation');
        },
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showResourcePackImport(context, controller),
                child: const Text('Open pack'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open pack'));
      await tester.pumpAndSettle();
      expect(find.byType(ResourcePackTransferDialog), findsNothing);
      expect(controller.phase, ResourcePackTransferPhase.closed);
      expect(controller.error, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'small dialog supports enlarged text, server selection and keyboard close',
    (tester) async {
      tester.view.physicalSize = const Size(700, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = ResourcePackTransferController(
        port: PackTestPort(),
        picker: () async => '/chosen.aveluneassets',
        accept: (_) async {},
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showResourcePackImport(context, controller),
                child: const Text('Open pack'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open pack'));
      await tester.pumpAndSettle();
      final select = find.byKey(
        const ValueKey('resource-pack-select-filtered'),
      );
      await tester.ensureVisible(select);
      await tester.tap(select);
      await tester.pumpAndSettle();
      expect(controller.selectedCount, 10000);
      expect(find.text('10000 sélectionnées au total'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ResourcePackTransferDialog), findsNothing);
      expect(controller.phase, ResourcePackTransferPhase.closed);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('pack import is shared by full and compact library actions', (
    tester,
  ) async {
    var imports = 0;
    for (final size in [const Size(1536, 1024), const Size(700, 500)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResourceLibraryScreen(
              project: workspaceProject,
              visuals: WorkspaceTestVisuals(),
              state: ResourceLibraryState(),
              onUse: (_) {},
              onEdit: (_) {},
              onTerrain: (_) {},
              onCreateBorder: () {},
              onResumeBorder: (_) {},
              onImport: () {},
              onImportPack: () => imports++,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (size.height < 650) {
        await tester.tap(find.text('Actions'));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(
        find.byKey(const ValueKey('resource-import-pack')),
      );
      await tester.tap(find.byKey(const ValueKey('resource-import-pack')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(imports, 2);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
