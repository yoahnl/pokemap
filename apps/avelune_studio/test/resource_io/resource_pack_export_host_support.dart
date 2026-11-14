import 'dart:io';

import 'package:avelune_studio/features/resources/coordination/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_pack_port.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> configureExport(ResourcePackTransferController c) async {
  await c.beginExport(projectName: 'Studio pack');
  for (final e in {
    'version': '1.0.0',
    'author': 'Studio Publisher',
    'universeId': 'original',
    'provenance': 'Original Studio edition',
  }.entries) {
    await c.setExportField(e.key, e.value);
  }
  expect(c.error, isNull);
}

class FileExportTestSink implements ResourcePackExportSink {
  @override
  Future<ResourcePackPublication> reconcilePublication(String token) async =>
      throw StateError('No pending publication');
  FileExportTestSink(this.destination);
  final File destination;
  String mode = 'publish';
  @override
  Future<ResourcePackPublication> publish({
    required String suggestedName,
    required int byteLength,
    required String rawSha256,
    required Future<List<int>> Function(int, int) readChunk,
    required bool Function() isCancelled,
    required void Function() enterFinalization,
  }) async {
    final temporary = File('${destination.path}.part');
    final stream = temporary.openWrite();
    var written = 0;
    var renamed = false;
    try {
      while (written < byteLength) {
        final count = (byteLength - written).clamp(1, 128 * 1024);
        final bytes = await readChunk(written, count);
        if (bytes.isEmpty || bytes.length > count) {
          throw StateError('invalid payload chunk');
        }
        stream.add(bytes);
        written += bytes.length;
        if (mode == 'error') throw StateError('sink failure');
      }
      await stream.flush();
      await stream.close();
      if (mode == 'cancel' || isCancelled()) {
        return const ResourcePackPublication.cancelled();
      }
      enterFinalization();
      await temporary.rename(destination.path);
      renamed = true;
      return ResourcePackPublication.published(
        destination.path,
        warning: mode == 'warning' ? 'cleanup warning' : null,
      );
    } finally {
      await stream.close();
      if (!renamed && await temporary.exists()) await temporary.delete();
    }
  }
}
