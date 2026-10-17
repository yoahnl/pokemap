import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';

Future<void> waitForResourcePackTestFile(File file) async {
  final complete = Completer<void>();
  final subscription = file.parent.watch().listen((event) {
    if (file.existsSync() && !complete.isCompleted) complete.complete();
  });
  try {
    if (file.existsSync()) complete.complete();
    await complete.future.timeout(const Duration(seconds: 20));
  } finally {
    await subscription.cancel();
  }
}

final class ResourcePackTestGate {
  ResourcePackTestGate(String root)
      : directory = Directory('$root/.p09-resource-pack-control');
  final Directory directory;

  Future<void> arm(
      String id, String operationId, AuthoringTransactionCheckpoint checkpoint,
      {bool crash = false}) async {
    await directory.create(recursive: true);
    await File('${directory.path}/request.json').writeAsString(jsonEncode({
      'id': id,
      'operationId': operationId,
      'checkpoint': checkpoint.name,
      'crash': crash,
    }));
  }

  Future<void> entered(String id) =>
      waitForResourcePackTestFile(File('${directory.path}/entered-$id'));

  Future<void> release(String id) async {
    await directory.create(recursive: true);
    await File('${directory.path}/release-$id').writeAsString('release');
  }

  Future<void> intercept(AuthoringTransactionCheckpointContext context) async {
    final request = File('${directory.path}/request.json');
    if (!await request.exists()) return;
    final config = jsonDecode(await request.readAsString()) as Map;
    if (config['operationId'] != context.operationId ||
        config['checkpoint'] != context.checkpoint.name) {
      return;
    }
    await request.delete();
    final id = config['id'] as String;
    await File('${directory.path}/entered-$id')
        .writeAsString(context.checkpoint.name);
    await waitForResourcePackTestFile(File('${directory.path}/release-$id'));
    if (config['crash'] == true) {
      throw const AuthoringTransactionSimulatedCrash();
    }
  }
}
