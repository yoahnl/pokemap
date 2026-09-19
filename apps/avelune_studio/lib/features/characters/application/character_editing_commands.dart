import 'package:map_core/map_core_domain.dart';
import '../../map_workspace/application/editable_map_document.dart';

class CharacterEditingCommands {
  CharacterEditingCommands(this.document, this.project);
  final EditableMapDocument document;
  final ProjectManifest project;
  static int _sequence = 0;

  String _id() {
    String id;
    do {
      id = 'character-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
    } while (document.current.entities.any((entity) => entity.id == id));
    return id;
  }

  MapEntity? selected(String? id) =>
      document.current.entities.where((entity) => entity.id == id).firstOrNull;

  List<MapEntity> at(GridPos position) => document.current.entities.reversed
      .where(
        (entity) =>
            entity.kind == MapEntityKind.npc &&
            position.x >= entity.pos.x &&
            position.y >= entity.pos.y &&
            position.x < entity.pos.x + entity.size.width &&
            position.y < entity.pos.y + entity.size.height,
      )
      .toList(growable: false);

  MapEntity place(ProjectCharacterEntry character, GridPos position) {
    if (!project.characters.any((entry) => entry.id == character.id)) {
      throw StateError('Ce personnage ne fait plus partie du catalogue.');
    }
    final entity = MapEntity(
      id: _id(),
      name: character.name,
      kind: MapEntityKind.npc,
      pos: position,
      npc: MapEntityNpcData(
        characterId: character.id,
        displayName: character.name,
      ),
    );
    document.commit(addEntityToMap(document.current, entity: entity));
    return entity;
  }

  void move(String id, GridPos position) => document.commit(
    moveEntityOnMap(document.current, entityId: id, pos: position),
  );

  MapEntity duplicate(String id) {
    final source = selected(id);
    if (source == null) throw StateError('Ce personnage n’existe plus.');
    final map = document.current;
    final position = source.pos.x + source.size.width < map.size.width
        ? source.pos.copyWith(x: source.pos.x + 1)
        : source.pos;
    final clone = source.copyWith(id: _id(), pos: position);
    document.commit(addEntityToMap(map, entity: clone));
    return clone;
  }

  String? deletionProblem(String id) {
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
    return usages.isEmpty
        ? null
        : 'Ce personnage est utilisé par l’histoire. Retirez ses liaisons avant de le supprimer.';
  }

  void delete(String id) {
    final problem = deletionProblem(id);
    if (problem != null) throw StateError(problem);
    document.commit(removeEntityFromMap(document.current, entityId: id));
  }

  void update(String id, {String? name, EntityFacing? facing, bool? blocks}) {
    final entity = selected(id);
    if (entity?.npc == null) return;
    document.commit(
      updateEntityOnMap(
        document.current,
        entityId: id,
        name: name,
        blocksMovement: blocks,
        npc: entity!.npc!.copyWith(
          displayName: name ?? entity.npc!.displayName,
          facing: facing ?? entity.npc!.facing,
        ),
      ),
    );
  }
}
