import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../operations/map_events.dart';
import 'event_builder_authoring_operations.dart';
import 'event_builder_contract.dart';

/// Résultat atomique de création d'un draft Event Builder sur une map.
///
/// Le lot NS-EVENT-06 doit rester côté `map_core` et retourner à la fois la
/// map immuable mise à jour, l'événement normalisé par les opérations de map,
/// et la vue de contrat Event Builder que l'UI pourra consommer sans relire les
/// metadata brutes.
final class EventBuilderDraftCreationResult {
  const EventBuilderDraftCreationResult({
    required this.updatedMap,
    required this.createdEvent,
    required this.createdContract,
  });

  final MapData updatedMap;
  final MapEventDefinition createdEvent;
  final EventBuilderContractView createdContract;
}

/// Crée un événement de map minimal, valide et lisible comme draft Event Builder.
///
/// Cette opération ne choisit jamais une position par défaut : l'appelant doit
/// fournir une [EventPosition] explicite pour éviter un faux draft placé en
/// `(0, 0)`. La validation des bornes, de l'id et des pages reste déléguée à
/// [addMapEventToMap] afin de ne pas créer un second validateur parallèle.
EventBuilderDraftCreationResult createEventBuilderDraftEventOnMap(
  MapData map, {
  required String title,
  required EventPosition position,
  MapEventType type = MapEventType.actor,
  EventBuilderReusePolicy reusePolicy = EventBuilderReusePolicy.oneShot,
}) {
  final normalizedTitle = _normalizeDraftTitle(title);
  final draftId = _uniqueDraftEventId(
    normalizedTitle,
    map.events.map((event) => event.id),
  );
  final draftEvent = MapEventDefinition(
    id: draftId,
    title: normalizedTitle,
    position: position,
    type: type,
    pages: [
      MapEventPage(
        pageNumber: 0,
        metadata: _eventBuilderDraftMetadata(reusePolicy),
      ),
    ],
  );

  final updatedMap = addMapEventToMap(map, event: draftEvent);
  final createdEvent = findMapEventById(updatedMap, draftId);
  if (createdEvent == null) {
    throw StateError('Created Event Builder draft cannot be found: $draftId');
  }

  return EventBuilderDraftCreationResult(
    updatedMap: updatedMap,
    createdEvent: createdEvent,
    createdContract: readEventBuilderContractFromMapEvent(createdEvent),
  );
}

String _normalizeDraftTitle(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) {
    return 'Nouvel événement';
  }
  return trimmed;
}

Map<String, String> _eventBuilderDraftMetadata(
  EventBuilderReusePolicy reusePolicy,
) {
  return Map<String, String>.unmodifiable({
    EventBuilderMetadataKeys.schemaVersion:
        EventBuilderMetadataKeys.currentSchemaVersion,
    EventBuilderMetadataKeys.reusePolicy: reusePolicy.name,
  });
}

String _uniqueDraftEventId(String title, Iterable<String> existingIds) {
  final slug = _slugifyDraftEventTitle(title);
  final base = 'evt_${slug.isEmpty ? 'nouvel_evenement' : slug}';
  final existing = existingIds.toSet();
  if (!existing.contains(base)) {
    return base;
  }

  var suffix = 2;
  while (existing.contains('${base}_$suffix')) {
    suffix++;
  }
  return '${base}_$suffix';
}

String _slugifyDraftEventTitle(String value) {
  final lower = value.trim().toLowerCase();
  final buffer = StringBuffer();
  var wroteSeparator = false;

  for (final rune in lower.runes) {
    final normalized = _latinAsciiOverride(rune);
    for (final codeUnit in normalized.codeUnits) {
      final isDigit = codeUnit >= 48 && codeUnit <= 57;
      final isAsciiLetter = codeUnit >= 97 && codeUnit <= 122;
      if (isDigit || isAsciiLetter) {
        buffer.writeCharCode(codeUnit);
        wroteSeparator = false;
      } else if (!wroteSeparator && buffer.isNotEmpty) {
        buffer.write('_');
        wroteSeparator = true;
      }
    }
  }

  final slug = buffer.toString();
  return slug.endsWith('_') ? slug.substring(0, slug.length - 1) : slug;
}

String _latinAsciiOverride(int rune) {
  return switch (rune) {
    0x00E0 || 0x00E1 || 0x00E2 || 0x00E3 || 0x00E4 || 0x00E5 => 'a',
    0x00E6 => 'ae',
    0x00E7 => 'c',
    0x00E8 || 0x00E9 || 0x00EA || 0x00EB => 'e',
    0x00EC || 0x00ED || 0x00EE || 0x00EF => 'i',
    0x00F1 => 'n',
    0x00F2 || 0x00F3 || 0x00F4 || 0x00F5 || 0x00F6 || 0x00F8 => 'o',
    0x0153 => 'oe',
    0x00F9 || 0x00FA || 0x00FB || 0x00FC => 'u',
    0x00FD || 0x00FF => 'y',
    _ => String.fromCharCode(rune),
  };
}
