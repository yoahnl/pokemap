import 'package:uuid/uuid.dart';

import '../models/narrative_event_definition.dart';

final class NarrativeEventIdGenerator {
  NarrativeEventIdGenerator({String Function()? rawUuidFactory})
      : _rawUuidFactory = rawUuidFactory ?? _defaultUuidV7;

  static RegExp get eventIdPattern => narrativeEventIdPattern;

  final String Function() _rawUuidFactory;
  final Set<String> _emittedIds = <String>{};

  String generate({required Iterable<NarrativeEventRecord> existingRecords}) {
    final existingIds = {for (final record in existingRecords) record.id};
    for (var attempt = 0; attempt <= 16; attempt++) {
      final rawUuid = _rawUuidFactory();
      final candidate = 'evt_$rawUuid';
      if (!eventIdPattern.hasMatch(candidate)) {
        throw ArgumentError.value(
          rawUuid,
          'rawUuidFactory',
          'must return a canonical lowercase UUIDv7',
        );
      }
      if (!existingIds.contains(candidate) &&
          !_emittedIds.contains(candidate)) {
        _emittedIds.add(candidate);
        return candidate;
      }
    }
    throw StateError(
        'Unable to generate a unique Narrative Event ID after 17 collisions.');
  }

  static String _defaultUuidV7() => const Uuid().v7();
}
