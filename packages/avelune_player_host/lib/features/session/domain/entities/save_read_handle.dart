import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

/// Stable opaque selector for the exact save revision chosen by the title.
String hubSaveReadHandle(SaveEnvelope envelope) {
  final scopedRevision = <String>[
    envelope.gameId,
    envelope.profileId,
    envelope.slotId,
    envelope.saveId,
    envelope.updatedAt.toUtc().toIso8601String(),
    envelope.checksum.algorithm,
    envelope.checksum.value,
  ].join('\u0000');
  return 'save-v1-${sha256.convert(utf8.encode(scopedRevision))}';
}
