import 'dart:async';

import '../application/resource_pack_transfer_controller.dart';

Future<void> runResourcePackExport({
  required ResourcePackTransferController controller,
  required Future<void> Function() present,
  String projectName = '',
  List<({String kind, String id})> selection = const [],
}) async {
  if (controller.routeActive || !controller.exportAvailable) return;
  controller.routeActive = true;
  try {
    unawaited(
      controller.beginExport(projectName: projectName, selection: selection),
    );
    await present();
  } finally {
    controller.routeActive = false;
  }
}

Future<void> runResourcePackImport({
  required ResourcePackTransferController controller,
  required Future<void> Function() present,
}) async {
  if (controller.routeActive) return;
  controller.routeActive = true;
  try {
    unawaited(controller.beginImport());
    await present();
  } finally {
    controller.routeActive = false;
  }
}
