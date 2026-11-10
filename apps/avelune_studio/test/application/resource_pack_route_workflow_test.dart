import 'dart:async';

import 'package:avelune_studio/features/resources/application/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_pack_route_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resource_pack_transfer_controller_test.dart'
    show PackTestPort, ExportPackTestPort, ExportTestSink;

void main() {
  test('one import route owns the picker and refuses a second route', () async {
    final gate = Completer<String?>();
    var picks = 0, duplicateRoutes = 0;
    final controller = ResourcePackTransferController(
      port: PackTestPort(),
      picker: () {
        picks++;
        return gate.future;
      },
      accept: (_) async {},
    );
    addTearDown(controller.dispose);
    bool? active;
    await runResourcePackImport(
      controller: controller,
      present: () async {
        active = controller.routeActive;
        await runResourcePackImport(
          controller: controller,
          present: () async {
            duplicateRoutes++;
          },
        );
        gate.complete(null);
        await controller.requestClose();
      },
    );
    expect(active, isTrue);
    expect(picks, 1);
    expect(duplicateRoutes, 0);
    expect(controller.routeActive, isFalse);
  });

  test('an export route blocks an import route while its own presentation is active', () async {
    final controller = ResourcePackTransferController(
      port: ExportPackTestPort(),
      picker: () async => null,
      exportSink: ExportTestSink(),
      accept: (_) async {},
    );
    addTearDown(controller.dispose);
    var importRoutes = 0;
    bool? active;
    await runResourcePackExport(
      controller: controller,
      projectName: 'Projet',
      present: () async {
        active = controller.routeActive;
        await runResourcePackImport(
          controller: controller,
          present: () async {
            importRoutes++;
          },
        );
        await controller.requestClose();
      },
    );
    expect(active, isTrue);
    expect(importRoutes, 0);
    expect(controller.routeActive, isFalse);
  });

  test('a failed pack presentation releases its route ownership', () async {
    final controller = ResourcePackTransferController(
      port: PackTestPort(),
      picker: () async => null,
      accept: (_) async {},
    );
    addTearDown(controller.dispose);
    await expectLater(
      runResourcePackImport(
        controller: controller,
        present: () async => throw StateError('presentation unavailable'),
      ),
      throwsStateError,
    );
    await controller.requestClose();
    expect(controller.routeActive, isFalse);
  });
}
