import '../exceptions/map_exceptions.dart';
import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/script_conditions.dart';

MapEventDefinition? findMapEventById(
  MapData map,
  String eventId,
) {
  final normalizedEventId = eventId.trim();
  if (normalizedEventId.isEmpty) {
    return null;
  }
  for (final event in map.events) {
    if (event.id == normalizedEventId) {
      return event;
    }
  }
  return null;
}

MapEventDefinition? findMapEventAtPos(
  MapData map,
  int x,
  int y, {
  String? preferredLayerId,
}) {
  final preferred = preferredLayerId?.trim();
  if (preferred != null && preferred.isNotEmpty) {
    for (var i = map.events.length - 1; i >= 0; i--) {
      final event = map.events[i];
      if (event.position.x == x &&
          event.position.y == y &&
          event.position.layerId == preferred) {
        return event;
      }
    }
  }
  for (var i = map.events.length - 1; i >= 0; i--) {
    final event = map.events[i];
    if (event.position.x == x && event.position.y == y) {
      return event;
    }
  }
  return null;
}

MapData addMapEventToMap(
  MapData map, {
  required MapEventDefinition event,
}) {
  final normalizedEvent = _normalizeEvent(event);
  _validateEvent(
    map,
    normalizedEvent,
    duplicateIdLabel: 'Map event ID already exists',
  );
  return map.copyWith(
    events: [...map.events, normalizedEvent],
  );
}

MapData updateMapEventOnMap(
  MapData map, {
  required String eventId,
  String? id,
  String? title,
  EventPosition? position,
  MapEventType? type,
  List<MapEventPage>? pages,
  Map<String, String>? metadata,
}) {
  final index = map.events.indexWhere((event) => event.id == eventId);
  if (index < 0) {
    throw ValidationException('Map event not found: $eventId');
  }
  final current = map.events[index];
  final next = _normalizeEvent(
    current.copyWith(
      id: id?.trim() ?? current.id,
      title: title?.trim() ?? current.title,
      position: position ?? current.position,
      type: type ?? current.type,
      pages: pages ?? current.pages,
      metadata:
          metadata == null ? current.metadata : _normalizeMetadata(metadata),
    ),
  );
  _validateEvent(
    map,
    next,
    excludedEventId: current.id,
    duplicateIdLabel: 'Map event ID already exists',
  );
  final updated = List<MapEventDefinition>.from(map.events, growable: false);
  updated[index] = next;
  return map.copyWith(events: updated);
}

MapData moveMapEventOnMap(
  MapData map, {
  required String eventId,
  required EventPosition position,
}) {
  final event = findMapEventById(map, eventId);
  if (event == null) {
    throw ValidationException('Map event not found: $eventId');
  }
  return updateMapEventOnMap(
    map,
    eventId: eventId,
    position: position,
  );
}

MapData removeMapEventFromMap(
  MapData map, {
  required String eventId,
}) {
  final index = map.events.indexWhere((event) => event.id == eventId);
  if (index < 0) {
    throw ValidationException('Map event not found: $eventId');
  }
  final updated = List<MapEventDefinition>.from(map.events, growable: true)
    ..removeAt(index);
  return map.copyWith(events: updated);
}

MapData addPageToMapEvent(
  MapData map, {
  required String eventId,
  required MapEventPage page,
}) {
  final event = findMapEventById(map, eventId);
  if (event == null) {
    throw ValidationException('Map event not found: $eventId');
  }
  final nextPages = [...event.pages, page];
  return updateMapEventOnMap(
    map,
    eventId: eventId,
    pages: nextPages,
  );
}

MapData updatePageOnMapEvent(
  MapData map, {
  required String eventId,
  required int pageIndex,
  int? pageNumber,
  ScriptCondition? condition,
  bool clearCondition = false,
  ScriptRef? script,
  bool clearScript = false,
  String? spriteId,
  String? message,
  MapEventSceneTarget? sceneTarget,
  bool clearSceneTarget = false,
  bool? isHidden,
  bool? isDisabled,
  Map<String, String>? metadata,
}) {
  final event = findMapEventById(map, eventId);
  if (event == null) {
    throw ValidationException('Map event not found: $eventId');
  }
  if (pageIndex < 0 || pageIndex >= event.pages.length) {
    throw ValidationException(
      'Map event page index out of bounds: event=$eventId pageIndex=$pageIndex',
    );
  }
  final currentPage = event.pages[pageIndex];
  final nextPage = currentPage.copyWith(
    pageNumber: pageNumber ?? currentPage.pageNumber,
    condition: clearCondition ? null : (condition ?? currentPage.condition),
    script: clearScript ? null : (script ?? currentPage.script),
    spriteId: spriteId ?? currentPage.spriteId,
    message: message ?? currentPage.message,
    sceneTarget:
        clearSceneTarget ? null : (sceneTarget ?? currentPage.sceneTarget),
    isHidden: isHidden ?? currentPage.isHidden,
    isDisabled: isDisabled ?? currentPage.isDisabled,
    metadata:
        metadata == null ? currentPage.metadata : _normalizeMetadata(metadata),
  );
  final nextPages = List<MapEventPage>.from(event.pages, growable: false);
  nextPages[pageIndex] = nextPage;
  return updateMapEventOnMap(
    map,
    eventId: eventId,
    pages: nextPages,
  );
}

MapData setMapEventPageSceneTarget(
  MapData map, {
  required String eventId,
  required int pageNumber,
  required String sceneId,
}) {
  final normalizedSceneId = sceneId.trim();
  if (normalizedSceneId.isEmpty) {
    throw const ValidationException('Scene target sceneId cannot be empty');
  }
  final event = findMapEventById(map, eventId);
  if (event == null) {
    throw ValidationException('Map event not found: $eventId');
  }
  final pageIndex = _findPageIndexByNumber(event, pageNumber);
  return updatePageOnMapEvent(
    map,
    eventId: eventId,
    pageIndex: pageIndex,
    sceneTarget: MapEventSceneTarget(sceneId: normalizedSceneId),
  );
}

MapData clearMapEventPageSceneTarget(
  MapData map, {
  required String eventId,
  required int pageNumber,
}) {
  final event = findMapEventById(map, eventId);
  if (event == null) {
    throw ValidationException('Map event not found: $eventId');
  }
  final pageIndex = _findPageIndexByNumber(event, pageNumber);
  return updatePageOnMapEvent(
    map,
    eventId: eventId,
    pageIndex: pageIndex,
    clearSceneTarget: true,
  );
}

MapData removePageFromMapEvent(
  MapData map, {
  required String eventId,
  required int pageIndex,
}) {
  final event = findMapEventById(map, eventId);
  if (event == null) {
    throw ValidationException('Map event not found: $eventId');
  }
  if (pageIndex < 0 || pageIndex >= event.pages.length) {
    throw ValidationException(
      'Map event page index out of bounds: event=$eventId pageIndex=$pageIndex',
    );
  }
  if (event.pages.length <= 1) {
    throw const ValidationException(
      'Map event must keep at least one page',
    );
  }
  final nextPages = List<MapEventPage>.from(event.pages, growable: true)
    ..removeAt(pageIndex);
  return updateMapEventOnMap(
    map,
    eventId: eventId,
    pages: nextPages,
  );
}

MapEventDefinition _normalizeEvent(MapEventDefinition event) {
  final normalizedPages = event.pages
      .map(_normalizePage)
      .toList(growable: false)
    ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
  return event.copyWith(
    id: event.id.trim(),
    title: event.title.trim(),
    position: event.position.copyWith(
      layerId: event.position.layerId.trim(),
    ),
    pages: normalizedPages,
    metadata: _normalizeMetadata(event.metadata),
  );
}

MapEventPage _normalizePage(MapEventPage page) {
  final script = page.script;
  final sceneTarget = page.sceneTarget;
  return page.copyWith(
    spriteId: _trimOptional(page.spriteId),
    message: _trimOptional(page.message),
    script: script == null
        ? null
        : script.copyWith(
            scriptId: script.scriptId.trim(),
            startNode: _trimOptional(script.startNode),
          ),
    sceneTarget: sceneTarget == null
        ? null
        : sceneTarget.copyWith(sceneId: sceneTarget.sceneId.trim()),
    metadata: _normalizeMetadata(page.metadata),
  );
}

Map<String, String> _normalizeMetadata(Map<String, String> metadata) {
  return Map<String, String>.unmodifiable({
    for (final entry in metadata.entries) entry.key.trim(): entry.value.trim(),
  });
}

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

void _validateEvent(
  MapData map,
  MapEventDefinition event, {
  String? excludedEventId,
  required String duplicateIdLabel,
}) {
  final id = event.id.trim();
  if (id.isEmpty) {
    throw const ValidationException('Map event ID cannot be empty');
  }
  if (map.events
      .any((entry) => entry.id == id && entry.id != excludedEventId)) {
    throw ValidationException('$duplicateIdLabel: $id');
  }
  final position = event.position;
  if (position.layerId.trim().isEmpty) {
    throw ValidationException('Map event $id has an empty layerId');
  }
  if (position.x < 0 ||
      position.y < 0 ||
      position.x >= map.size.width ||
      position.y >= map.size.height) {
    throw ValidationException(
      'Map event $id is out of map bounds at (${position.x}, ${position.y})',
    );
  }
  if (event.pages.isEmpty) {
    throw ValidationException('Map event $id must contain at least one page');
  }
  final seenPageNumbers = <int>{};
  for (var i = 0; i < event.pages.length; i++) {
    final page = event.pages[i];
    if (page.pageNumber < 0) {
      throw ValidationException(
        'Map event $id page[$i] has negative pageNumber: ${page.pageNumber}',
      );
    }
    if (!seenPageNumbers.add(page.pageNumber)) {
      throw ValidationException(
        'Map event $id has duplicate pageNumber: ${page.pageNumber}',
      );
    }
    final script = page.script;
    if (script != null && script.scriptId.trim().isEmpty) {
      throw ValidationException(
        'Map event $id page[$i] has a script reference with empty scriptId',
      );
    }
    final sceneTarget = page.sceneTarget;
    if (sceneTarget != null && sceneTarget.sceneId.trim().isEmpty) {
      throw ValidationException(
        'Map event $id page[$i] has a scene target with empty sceneId',
      );
    }
    for (final key in page.metadata.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException(
          'Map event $id page[$i] has an empty metadata key',
        );
      }
    }
  }
  for (final key in event.metadata.keys) {
    if (key.trim().isEmpty) {
      throw ValidationException('Map event $id has an empty metadata key');
    }
  }
}

int _findPageIndexByNumber(MapEventDefinition event, int pageNumber) {
  final index = event.pages.indexWhere((page) => page.pageNumber == pageNumber);
  if (index < 0) {
    throw ValidationException(
      'Map event page not found: event=${event.id} pageNumber=$pageNumber',
    );
  }
  return index;
}
