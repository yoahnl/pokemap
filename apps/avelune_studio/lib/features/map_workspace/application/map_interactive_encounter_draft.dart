import 'package:map_core/map_core_domain.dart';

class MapInteractiveEncounterDraft {
  const MapInteractiveEncounterDraft(this.entity, this.project);
  final MapEntity entity;
  final ProjectManifest project;
  MapEntityInteractiveEncounterData? get payload => entity.interactiveEncounter;
  InteractiveEncounterTrigger get trigger =>
      entity.fieldObstacle?.kind == FieldObstacleKind.rockSmashRock
      ? InteractiveEncounterTrigger.afterRockSmash
      : InteractiveEncounterTrigger.headbutt;
  EncounterKind get kind => trigger == InteractiveEncounterTrigger.headbutt
      ? EncounterKind.headbutt
      : EncounterKind.special;
  List<ProjectEncounterTable> get tables => project.encounterTables
      .where((table) => table.encounterKind == kind)
      .toList();

  MapEntityInteractiveEncounterData change({
    String? tableId,
    InteractiveEncounterReusePolicy? reuse,
    List<ScriptCondition>? conditions,
  }) {
    final id = tableId ?? payload?.encounterTableId ?? tables.first.id;
    return MapEntityInteractiveEncounterData(
      trigger: trigger,
      encounterTableId: id,
      reusePolicy:
          reuse ??
          payload?.reusePolicy ??
          InteractiveEncounterReusePolicy.repeatable,
      conditions: conditions ?? payload?.conditions ?? const [],
      presentation: payload?.presentation.copyWith(encounterTableId: id),
    );
  }
}
