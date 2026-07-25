import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/game_export.dart';
import 'package:path/path.dart' as p;

void main() {
  test('publishes immutable package bytes before a canonical request',
      () async {
    final inbox = await Directory.systemTemp.createTemp('pokemap_hub_inbox_');
    addTearDown(() => inbox.delete(recursive: true));
    final publisher = HubInstallRequestPublisher(
      inbox: inbox,
      requestIdGenerator: () => 'export-20260725-0001',
      now: () => DateTime.utc(2026, 7, 25, 8, 30),
    );
    final bytes = <int>[1, 2, 3, 4, 5];

    final request = await publisher.publish(bytes);

    expect(
      await File(p.join(inbox.path, request.packageFileName)).readAsBytes(),
      bytes,
    );
    expect(request.packageSha256, sha256.convert(bytes).toString());
    final requestFile = File(
      p.join(inbox.path, '${request.requestId}.request.json'),
    );
    expect(
      const GamePackageInstallRequestCodec().decodeUtf8(
        await requestFile.readAsBytes(),
      ),
      request,
    );
    expect(
      await inbox
          .list()
          .where((entity) => entity.path.endsWith('.tmp'))
          .isEmpty,
      isTrue,
    );
  });
}
