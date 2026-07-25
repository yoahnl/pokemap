import 'package:map_core/map_core.dart';

/// Stable opaque selector for the exact save revision chosen by the title.
String hubSaveReadHandle(SaveEnvelope envelope) {
  return '${envelope.gameId}:${envelope.profileId}:${envelope.slotId}:'
      '${envelope.saveId}';
}
