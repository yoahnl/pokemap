import 'package:meta/meta.dart' show immutable;

import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/project_manifest.dart';

enum CinematicStageMapSourceCatalogStatus {
  missingStageMap,
  mapDataUnavailable,
  mapIdMismatch,
  available,
}

enum CinematicStageMapSourceDiagnosticCode {
  stageMapMissing,
  stageMapDataUnavailable,
  stageMapDataIdMismatch,
  stageMapHasNoEntities,
  stageMapHasNoEvents,
  entityMissingLabelFallbackToId,
  eventMissingTitleFallbackToId,
}

@immutable
final class CinematicStageMapSourceDiagnostic {
  const CinematicStageMapSourceDiagnostic({
    required this.code,
    required this.message,
    this.sourceId,
  });

  final CinematicStageMapSourceDiagnosticCode code;
  final String message;
  final String? sourceId;
}

@immutable
final class CinematicStageMapSourceCatalog {
  CinematicStageMapSourceCatalog({
    required this.status,
    required this.stageMapId,
    required this.stageMapLabel,
    required this.stageMapRelativePath,
    required this.mapDataId,
    required List<CinematicStageMapEntitySource> entities,
    required List<CinematicStageMapEventSource> events,
    required List<CinematicStageMapSourceDiagnostic> diagnostics,
  })  : entities = List<CinematicStageMapEntitySource>.unmodifiable(entities),
        events = List<CinematicStageMapEventSource>.unmodifiable(events),
        diagnostics =
            List<CinematicStageMapSourceDiagnostic>.unmodifiable(diagnostics);

  final CinematicStageMapSourceCatalogStatus status;
  final String? stageMapId;
  final String? stageMapLabel;
  final String? stageMapRelativePath;
  final String? mapDataId;
  final List<CinematicStageMapEntitySource> entities;
  final List<CinematicStageMapEventSource> events;
  final List<CinematicStageMapSourceDiagnostic> diagnostics;

  bool get isAvailable =>
      status == CinematicStageMapSourceCatalogStatus.available;

  CinematicStageMapEntitySource? entityById(String entityId) {
    final normalizedId = entityId.trim();
    for (final entity in entities) {
      if (entity.id == normalizedId) {
        return entity;
      }
    }
    return null;
  }

  CinematicStageMapEventSource? eventById(String eventId) {
    final normalizedId = eventId.trim();
    for (final event in events) {
      if (event.id == normalizedId) {
        return event;
      }
    }
    return null;
  }
}

@immutable
final class CinematicStageMapEntitySource {
  CinematicStageMapEntitySource({
    required this.id,
    required this.label,
    required this.secondaryLabel,
    required this.kindLabel,
    required this.canBindActor,
    required this.canBeMovementTarget,
    required this.positionSummary,
    required List<CinematicStageMapSourceDiagnostic> diagnostics,
  }) : diagnostics =
            List<CinematicStageMapSourceDiagnostic>.unmodifiable(diagnostics);

  final String id;
  final String label;
  final String secondaryLabel;
  final String kindLabel;
  final bool canBindActor;
  final bool canBeMovementTarget;
  final String positionSummary;
  final List<CinematicStageMapSourceDiagnostic> diagnostics;
}

@immutable
final class CinematicStageMapEventSource {
  CinematicStageMapEventSource({
    required this.id,
    required this.label,
    required this.secondaryLabel,
    required this.kindLabel,
    required this.canBeMovementTarget,
    required this.positionSummary,
    required List<CinematicStageMapSourceDiagnostic> diagnostics,
  }) : diagnostics =
            List<CinematicStageMapSourceDiagnostic>.unmodifiable(diagnostics);

  final String id;
  final String label;
  final String secondaryLabel;
  final String kindLabel;
  bool get canBindActor => false;
  final bool canBeMovementTarget;
  final String positionSummary;
  final List<CinematicStageMapSourceDiagnostic> diagnostics;
}

CinematicStageMapSourceCatalog buildCinematicStageMapSourceCatalog({
  required ProjectMapEntry? stageMap,
  required MapData? mapData,
}) {
  if (stageMap == null) {
    return CinematicStageMapSourceCatalog(
      status: CinematicStageMapSourceCatalogStatus.missingStageMap,
      stageMapId: null,
      stageMapLabel: null,
      stageMapRelativePath: null,
      mapDataId: mapData?._normalizedId,
      entities: const [],
      events: const [],
      diagnostics: const [
        CinematicStageMapSourceDiagnostic(
          code: CinematicStageMapSourceDiagnosticCode.stageMapMissing,
          message: 'Aucune map de scene selectionnee.',
        ),
      ],
    );
  }

  final stageMapId = stageMap._normalizedId;
  final stageMapLabel = _labelOrId(stageMap.name, stageMapId);
  final stageMapRelativePath = stageMap.relativePath.trim();

  if (mapData == null) {
    return CinematicStageMapSourceCatalog(
      status: CinematicStageMapSourceCatalogStatus.mapDataUnavailable,
      stageMapId: stageMapId,
      stageMapLabel: stageMapLabel,
      stageMapRelativePath: stageMapRelativePath,
      mapDataId: null,
      entities: const [],
      events: const [],
      diagnostics: const [
        CinematicStageMapSourceDiagnostic(
          code: CinematicStageMapSourceDiagnosticCode.stageMapDataUnavailable,
          message: 'La MapData de la map de scene est indisponible.',
        ),
      ],
    );
  }

  final mapDataId = mapData._normalizedId;
  if (mapDataId != stageMapId) {
    return CinematicStageMapSourceCatalog(
      status: CinematicStageMapSourceCatalogStatus.mapIdMismatch,
      stageMapId: stageMapId,
      stageMapLabel: stageMapLabel,
      stageMapRelativePath: stageMapRelativePath,
      mapDataId: mapDataId,
      entities: const [],
      events: const [],
      diagnostics: [
        CinematicStageMapSourceDiagnostic(
          code: CinematicStageMapSourceDiagnosticCode.stageMapDataIdMismatch,
          message:
              'La MapData "$mapDataId" ne correspond pas a la map "$stageMapId".',
        ),
      ],
    );
  }

  final diagnostics = <CinematicStageMapSourceDiagnostic>[];
  final entities = <CinematicStageMapEntitySource>[];
  final events = <CinematicStageMapEventSource>[];

  if (mapData.entities.isEmpty) {
    diagnostics.add(
      const CinematicStageMapSourceDiagnostic(
        code: CinematicStageMapSourceDiagnosticCode.stageMapHasNoEntities,
        message: 'La map de scene ne contient aucune entite.',
      ),
    );
  } else {
    for (final entity in mapData.entities) {
      final source = _buildEntitySource(
        mapId: stageMapId,
        entity: entity,
      );
      entities.add(source);
      diagnostics.addAll(source.diagnostics);
    }
  }

  if (mapData.events.isEmpty) {
    diagnostics.add(
      const CinematicStageMapSourceDiagnostic(
        code: CinematicStageMapSourceDiagnosticCode.stageMapHasNoEvents,
        message: 'La map de scene ne contient aucun event.',
      ),
    );
  } else {
    for (final event in mapData.events) {
      final source = _buildEventSource(
        mapId: stageMapId,
        event: event,
      );
      events.add(source);
      diagnostics.addAll(source.diagnostics);
    }
  }

  return CinematicStageMapSourceCatalog(
    status: CinematicStageMapSourceCatalogStatus.available,
    stageMapId: stageMapId,
    stageMapLabel: stageMapLabel,
    stageMapRelativePath: stageMapRelativePath,
    mapDataId: mapDataId,
    entities: entities,
    events: events,
    diagnostics: diagnostics,
  );
}

CinematicStageMapEntitySource _buildEntitySource({
  required String mapId,
  required MapEntity entity,
}) {
  final entityId = entity._normalizedId;
  final label = _entityLabel(entity);
  final diagnostics = <CinematicStageMapSourceDiagnostic>[];
  if (label == entityId) {
    diagnostics.add(
      CinematicStageMapSourceDiagnostic(
        code: CinematicStageMapSourceDiagnosticCode
            .entityMissingLabelFallbackToId,
        message: 'L entite "$entityId" utilise son id comme libelle.',
        sourceId: entityId,
      ),
    );
  }

  return CinematicStageMapEntitySource(
    id: entityId,
    label: label,
    secondaryLabel: '$mapId:$entityId',
    kindLabel: _entityKindLabel(entity.kind),
    canBindActor: entity.kind == MapEntityKind.npc || entity.npc != null,
    canBeMovementTarget: true,
    positionSummary: _gridPositionSummary(entity.pos.x, entity.pos.y),
    diagnostics: diagnostics,
  );
}

CinematicStageMapEventSource _buildEventSource({
  required String mapId,
  required MapEventDefinition event,
}) {
  final eventId = event._normalizedId;
  final label = _labelOrId(event.title, eventId);
  final diagnostics = <CinematicStageMapSourceDiagnostic>[];
  if (label == eventId) {
    diagnostics.add(
      CinematicStageMapSourceDiagnostic(
        code:
            CinematicStageMapSourceDiagnosticCode.eventMissingTitleFallbackToId,
        message: 'L event "$eventId" utilise son id comme libelle.',
        sourceId: eventId,
      ),
    );
  }

  return CinematicStageMapEventSource(
    id: eventId,
    label: label,
    secondaryLabel: '$mapId:$eventId',
    kindLabel: _eventKindLabel(event.type),
    canBeMovementTarget: true,
    positionSummary: _gridPositionSummary(event.position.x, event.position.y),
    diagnostics: diagnostics,
  );
}

String _entityLabel(MapEntity entity) {
  switch (entity.kind) {
    case MapEntityKind.npc:
      final displayName = entity.npc?.displayName.trim();
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }
    case MapEntityKind.sign:
      final title = entity.sign?.title.trim();
      if (title != null && title.isNotEmpty) {
        return title;
      }
    case MapEntityKind.item:
      final gameItemId = entity.item?.gameItemId.trim();
      if (gameItemId != null && gameItemId.isNotEmpty) {
        return gameItemId;
      }
    case MapEntityKind.spawn:
      final spawnKey = entity.spawn?.spawnKey.trim();
      if (spawnKey != null && spawnKey.isNotEmpty) {
        return spawnKey;
      }
    case MapEntityKind.custom:
      break;
  }

  return _labelOrId(entity.name, entity._normalizedId);
}

String _entityKindLabel(MapEntityKind kind) {
  return switch (kind) {
    MapEntityKind.npc => 'PNJ',
    MapEntityKind.sign => 'Panneau',
    MapEntityKind.item => 'Objet',
    MapEntityKind.spawn => 'Spawn',
    MapEntityKind.custom => 'Custom',
  };
}

String _eventKindLabel(MapEventType type) {
  return switch (type) {
    MapEventType.actor => 'Acteur event',
    MapEventType.object => 'Objet event',
    MapEventType.triggerZone => 'Zone trigger',
    MapEventType.effect => 'Effet',
  };
}

String _gridPositionSummary(int x, int y) => 'Tuile $x, $y';

String _labelOrId(String label, String id) {
  final trimmedLabel = label.trim();
  return trimmedLabel.isEmpty ? id : trimmedLabel;
}

extension on ProjectMapEntry {
  String get _normalizedId => id.trim();
}

extension on MapData {
  String get _normalizedId => id.trim();
}

extension on MapEntity {
  String get _normalizedId => id.trim();
}

extension on MapEventDefinition {
  String get _normalizedId => id.trim();
}
