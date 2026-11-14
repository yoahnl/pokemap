import '../../events/domain/event_record_view.dart';
import '../../game_memory/domain/narrative_index_port.dart';
import 'game_behaviour_rows.dart';

enum GameBehaviourGrouping { map, fact }

enum GameBehaviourGroupKind {
  map,
  missingMap,
  withoutMap,
  notLoaded,
  fact,
  withoutFact,
}

final class GameBehaviourGroup {
  GameBehaviourGroup(this.kind, List<GameBehaviourRow> rows, {this.label})
    : rows = List.unmodifiable(rows);

  final GameBehaviourGroupKind kind;
  final String? label;
  final List<GameBehaviourRow> rows;
}

List<GameBehaviourGroup> groupGameBehavioursByMap(
  List<GameBehaviourRow> rows,
  List<String> mapOrder,
) {
  final byMap = <String, List<GameBehaviourRow>>{};
  final withoutMap = <GameBehaviourRow>[];
  final notLoaded = <GameBehaviourRow>[];
  for (final row in rows) {
    if (row.record == null) {
      notLoaded.add(row);
    } else if (row.mapId case final mapId?) {
      byMap.putIfAbsent(mapId, () => []).add(row);
    } else {
      withoutMap.add(row);
    }
  }
  return [
    for (final mapId in mapOrder)
      if (byMap.remove(mapId) case final rows?)
        GameBehaviourGroup(
          GameBehaviourGroupKind.map,
          rows,
          label: rows.first.mapName,
        ),
    for (final rows in byMap.values)
      GameBehaviourGroup(GameBehaviourGroupKind.missingMap, rows),
    if (withoutMap.isNotEmpty)
      GameBehaviourGroup(GameBehaviourGroupKind.withoutMap, withoutMap),
    if (notLoaded.isNotEmpty)
      GameBehaviourGroup(GameBehaviourGroupKind.notLoaded, notLoaded),
  ];
}

List<GameBehaviourGroup> groupGameBehavioursByFact(
  List<GameBehaviourRow> rows, {
  required List<NarrativeTitle> facts,
  required Map<String, NarrativeUsages> usages,
}) {
  final placed = <String>{};
  final groups = <GameBehaviourGroup>[];
  for (final fact in facts) {
    final owners = usages[fact.id]?.owners ?? const <NarrativeOwner>[];
    final events = {
      for (final owner in owners)
        if (owner.kind == NarrativeOwnerKind.event) owner.id,
    };
    final scenes = {
      for (final owner in owners)
        if (owner.kind == NarrativeOwnerKind.scene) owner.id,
    };
    final members = [
      for (final row in rows)
        if (events.contains(row.id) || scenes.contains(row.record?.sceneId))
          row,
    ];
    if (members.isEmpty) continue;
    placed.addAll(members.map((row) => row.id));
    groups.add(
      GameBehaviourGroup(
        GameBehaviourGroupKind.fact,
        members,
        label: fact.title.trim().isEmpty ? null : fact.title,
      ),
    );
  }
  final rest = [
    for (final row in rows)
      if (!placed.contains(row.id)) row,
  ];
  return [
    ...groups,
    if (rest.isNotEmpty)
      GameBehaviourGroup(GameBehaviourGroupKind.withoutFact, rest),
  ];
}
