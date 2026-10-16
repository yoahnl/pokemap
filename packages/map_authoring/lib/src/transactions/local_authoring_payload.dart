import 'dart:io';

import 'authoring_payload.dart';

Future<AuthoringPayload> captureAuthoringPayload({
  required String storageKey,
  required Stream<List<int>> chunks,
  required int byteLength,
  String? resourceRevision,
}) async {
  final directory =
      await Directory.systemTemp.createTemp('pokemap-authoring-payload-');
  final file = File('${directory.path}${Platform.pathSeparator}payload');
  try {
    final writer = await file.open(mode: FileMode.write);
    var written = 0;
    try {
      await for (final chunk in chunks) {
        written += chunk.length;
        if (written > byteLength) {
          throw const AuthoringPayloadException('payload.length_mismatch',
              'The payload length changed during capture.');
        }
        await writer.writeFrom(chunk);
      }
      await writer.flush();
    } finally {
      await writer.close();
    }
    final observed = await inspectAuthoringPayload(file.openRead(),
        storageKey: storageKey, byteLength: byteLength);
    if (resourceRevision != null &&
        observed.resourceRevision != resourceRevision) {
      throw const AuthoringPayloadException('payload.source_mismatch',
          'The captured payload differs from its expected resource revision.');
    }
    return await AuthoringPayload.verifiedSource(
        storageKey: storageKey,
        byteLength: byteLength,
        rawSha256: observed.rawSha256,
        resourceRevision: observed.resourceRevision,
        openRead: file.openRead,
        release: () async {
          if (await directory.exists()) await directory.delete(recursive: true);
        });
  } on Object {
    if (await directory.exists()) await directory.delete(recursive: true);
    rethrow;
  }
}

Future<AuthoringPayload> reframeAuthoringPayload(
        AuthoringPayload payload, String storageKey) =>
    storageKey == payload.storageKey
        ? Future.value(payload)
        : captureAuthoringPayload(
            storageKey: storageKey,
            chunks: payload.openRead(),
            byteLength: payload.byteLength);
