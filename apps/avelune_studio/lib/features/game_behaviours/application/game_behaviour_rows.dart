import 'package:map_core/map_core_domain.dart';

import '../../events/domain/event_record_view.dart';
import '../../game_memory/domain/narrative_index_port.dart';
import '../../map_workspace/application/map_story_elements.dart';
import 'game_behaviour_source.dart';

enum GameBehaviourFilter { withoutMap, toRepair, disabled, outsideTrame }

enum GameBehaviourPresence { known, notLoaded, deletedElsewhere }

final class GameBehaviourRow {
  const GameBehaviourRow({
    required this.id,
    required this.name,
    this.record,
    this.presence = GameBehaviourPresence.known,
    this.mapId,
    this.mapName,
    this.target,
    this.elementId,
    this.elementName,
    this.unsaved = false,
  });

  final String id;
  final String name;
  final NarrativeEventRecord? record;
  final GameBehaviourPresence presence;
  final String? mapId;
  final String? mapName;
  final MapStoryElementTarget? target;
  final String? elementId;
  final String? elementName;
  final bool unsaved;

  bool get withoutMap =>
      presence == GameBehaviourPresence.known && mapId == null;

  bool get mapMissing => mapId != null && mapName == null;

  bool get disabled => record?.enabledOrNull == false;

  bool get toRepair =>
      mapMissing ||
      (record != null &&
          record!.enabledOrNull == null &&
          (record!.source == null || record!.sceneId == null));

  bool matches(GameBehaviourFilter filter) => switch (filter) {
    GameBehaviourFilter.withoutMap => withoutMap,
    GameBehaviourFilter.toRepair => toRepair,
    GameBehaviourFilter.disabled => disabled,
    GameBehaviourFilter.outsideTrame => false,
  };
}

List<GameBehaviourRow> gameBehaviourRows({
  required List<NarrativeTitle> saved,
  required GameBehaviourSource source,
}) {
  final records = {
    for (final record
        in source.registry?.records ?? const <NarrativeEventRecord>[])
      record.id: record,
  };
  final maps = {for (final entry in source.maps) entry.id: entry.name};
  final titles = {for (final title in saved) title.id: title};
  GameBehaviourRow row(String id, NarrativeEventRecord? record) {
    final at = record == null ? null : mapStoryLocation(record);
    final presence = record == null
        ? GameBehaviourPresence.notLoaded
        : titles.containsKey(id) || source.touched(id)
        ? GameBehaviourPresence.known
        : GameBehaviourPresence.deletedElsewhere;
    final name = record?.name.trim();
    return GameBehaviourRow(
      id: id,
      name: name != null && name.isNotEmpty ? name : titles[id]?.title ?? '',
      record: record,
      presence: presence,
      mapId: at?.$1,
      mapName: at == null ? null : maps[at.$1],
      target: at?.$2,
      elementId: at?.$3,
      elementName: at == null ? null : source.elementName(at.$1, at.$2, at.$3),
      unsaved: source.touched(id),
    );
  }

  return [
    for (final title in saved) row(title.id, records[title.id]),
    for (final record in records.values)
      if (!titles.containsKey(record.id)) row(record.id, record),
  ];
}

List<GameBehaviourRow> filterGameBehaviours(
  List<GameBehaviourRow> rows, {
  String query = '',
  Set<GameBehaviourFilter> filters = const {},
  String Function(GameBehaviourRow row)? elementLabel,
  bool Function(GameBehaviourRow row)? outside,
}) {
  final needle = query.trim().toLowerCase();
  bool keeps(GameBehaviourRow row, GameBehaviourFilter filter) =>
      filter == GameBehaviourFilter.outsideTrame
      ? outside?.call(row) ?? false
      : row.matches(filter);
  bool found(String? value) =>
      value != null && value.toLowerCase().contains(needle);
  return [
    for (final row in rows)
      if (filters.every((filter) => keeps(row, filter)) &&
          (needle.isEmpty ||
              found(row.name) ||
              found(row.mapName) ||
              found(elementLabel?.call(row))))
        row,
  ];
}
