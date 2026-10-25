import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_draft_reference_guard.dart';

const studioEntityKinds = [MapEntityKind.spawn, MapEntityKind.sign];

typedef MapReferenceGuard = String? Function({
  required String mapId,
  required String entityId,
  MapDraftReferenceKind kind,
});

class MapEntityEditingCommands {
  MapEntityEditingCommands(this.document, this.project, {this.draftGuard});
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapReferenceGuard? draftGuard;
  static int _sequence = 0;

  String _id(MapEntityKind kind) {
    String id;
    do {
      id =
          '${kind.name}-${DateTime.now().microsecondsSinceEpoch}-'
          '${_sequence++}';
    } while (document.current.entities.any((entity) => entity.id == id));
    return id;
  }

  MapEntity? selected(String? id) => document.current.entities
      .where((entity) => entity.id == id && entity.kind != MapEntityKind.npc)
      .firstOrNull;

  List<MapEntity> at(GridPos position) => document.current.entities.reversed
      .where(
        (entity) =>
            entity.kind != MapEntityKind.npc &&
            position.x >= entity.pos.x &&
            position.y >= entity.pos.y &&
            position.x < entity.pos.x + entity.size.width &&
            position.y < entity.pos.y + entity.size.height,
      )
      .toList(growable: false);

  MapEntity? playerStart() => document.current.entities
      .where(
        (entity) =>
            entity.kind == MapEntityKind.spawn &&
            entity.spawn?.role == EntitySpawnRole.playerStart,
      )
      .firstOrNull;

  MapEntity place(MapEntityKind kind, GridPos position) {
    final entity = switch (kind) {
      MapEntityKind.spawn => MapEntity(
        id: _id(kind),
        name: 'Point de départ',
        kind: kind,
        pos: position,
        blocksMovement: false,
        spawn: const MapEntitySpawnData(role: EntitySpawnRole.playerStart),
      ),
      MapEntityKind.sign => MapEntity(
        id: _id(kind),
        name: 'Panneau',
        kind: kind,
        pos: position,
        sign: const MapEntitySignData(title: 'Panneau'),
      ),
      _ => throw StateError('Cette famille ne se pose pas depuis la carte.'),
    };
    document.commit(addEntityToMap(document.current, entity: entity));
    return entity;
  }

  MapEntity placeFieldObstacle({
    required GridPos position,
    required String elementId,
    required FieldObstacleKind kind,
  }) {
    final entity = MapEntity(
      id: _id(MapEntityKind.custom),
      name: switch (kind) {
        FieldObstacleKind.cutTree => 'Arbre à couper',
        FieldObstacleKind.strengthBoulder => 'Rocher à pousser',
        FieldObstacleKind.rockSmashRock => 'Rocher à briser',
        FieldObstacleKind.iceBlock => 'Bloc de glace',
      },
      kind: MapEntityKind.custom,
      pos: position,
      blocksMovement: true,
      editorVisual: MapEntityEditorVisual(elementId: elementId),
    );
    const actions = EntityActions();
    final placed = actions.create(document.current, entity);
    final configured = actions.setFieldObstacle(
      placed,
      project: project,
      entityId: entity.id,
      fieldObstacle: MapEntityFieldObstacleData(kind: kind),
    );
    document.commit(configured);
    return configured.entities.singleWhere((item) => item.id == entity.id);
  }

  void move(String id, GridPos position) {
    if (document.isElementUnavailable('entity', id)) return;
    document.commit(
      moveEntityOnMap(document.current, entityId: id, pos: position),
    );
  }

  String? deletionProblem(String id) {
    if (document.isElementUnavailable('entity', id)) {
      return 'Cet élément est verrouillé ou masqué. Déverrouillez-le ou affichez-le dans Éléments.';
    }
    if (selected(id) == null) {
      return 'Cet élément n’appartient plus à cette carte.';
    }
    final usages =
        buildNarrativeDependencyIndex(
          project: project,
          maps: [document.current],
        ).usagesFor(
          NarrativeDependencyKey.mapSource(
            mapId: document.current.id,
            sourceKind: 'entity',
            sourceId: id,
          ),
        );
    if (usages.isNotEmpty) {
      return 'Cet élément est utilisé par l’histoire. Retirez ses liaisons '
          'avant de le supprimer.';
    }
    return draftGuard?.call(mapId: document.current.id, entityId: id);
  }

  void delete(String id) {
    final problem = deletionProblem(id);
    if (problem != null) throw StateError(problem);
    document.commit(removeEntityFromMap(document.current, entityId: id));
  }

  void rename(String id, String name) => document.commit(
    updateEntityOnMap(document.current, entityId: id, name: name),
  );

  void updateSpawn(String id, {EntitySpawnRole? role, EntityFacing? facing}) {
    final entity = selected(id);
    final spawn = entity?.spawn;
    if (spawn == null) return;
    document.commit(
      updateEntityOnMap(
        document.current,
        entityId: id,
        spawn: spawn.copyWith(
          role: role ?? spawn.role,
          facing: facing ?? spawn.facing,
        ),
      ),
    );
  }

  void updateSign(String id, {String? title, String? plainText}) {
    final entity = selected(id);
    final sign = entity?.sign;
    if (sign == null) return;
    document.commit(
      updateEntityOnMap(
        document.current,
        entityId: id,
        name: title ?? entity!.name,
        sign: sign.copyWith(
          title: title ?? sign.title,
          plainText: plainText ?? sign.plainText,
        ),
      ),
    );
  }

  void setFieldObstacle(String id, MapEntityFieldObstacleData? fieldObstacle) =>
      document.commit(
        const EntityActions().setFieldObstacle(
          document.current,
          project: project,
          entityId: id,
          fieldObstacle: fieldObstacle,
        ),
      );

  void setInteractiveEncounter(
    String id,
    MapEntityInteractiveEncounterData? payload,
  ) => document.commit(
    const EntityActions().setInteractiveEncounter(
      document.current,
      project: project,
      entityId: id,
      interactiveEncounter: payload,
    ),
  );

  void setHealingDisplay(String id, MapEntityHealingDisplayData? display) =>
      document.commit(
        const EntityActions().setHealingDisplay(
          document.current,
          project: project,
          entityId: id,
          healingDisplay: display,
        ),
      );

  void setPresentation(String id, MapEntityPresentation? presentation) =>
      document.commit(
        const EntityActions().setPresentation(
          document.current,
          project: project,
          entityId: id,
          presentation: presentation,
        ),
      );

  void setBlocking(String id, {required bool blocks}) => document.commit(
    updateEntityOnMap(document.current, entityId: id, blocksMovement: blocks),
  );
}
