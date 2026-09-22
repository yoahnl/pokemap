import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_draft_reference_guard.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';

class TriggerEditingCommands {
  TriggerEditingCommands(this.document, this.project, {this.draftGuard});
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapReferenceGuard? draftGuard;

  MapTrigger? selected(String? id) =>
      document.current.triggers.where((entry) => entry.id == id).firstOrNull;

  List<MapTrigger> at(GridPos position) => document.current.triggers
      .where(
        (trigger) =>
            position.x >= trigger.area.pos.x &&
            position.y >= trigger.area.pos.y &&
            position.x < trigger.area.pos.x + trigger.area.size.width &&
            position.y < trigger.area.pos.y + trigger.area.size.height,
      )
      .toList(growable: false);

  MapTrigger add(MapTrigger trigger) {
    document.commit(addTriggerToMap(document.current, trigger: trigger));
    return trigger;
  }

  void rename(String id, String name) => document.commit(
    updateTriggerOnMap(document.current, triggerId: id, name: name),
  );

  void move(String id, GridPos pos) => document.commit(
    moveTriggerOnMap(document.current, triggerId: id, pos: pos),
  );

  void resize(String id, GridSize size) => document.commit(
    resizeTriggerOnMap(document.current, triggerId: id, size: size),
  );

  String? deletionProblem(String id) {
    final usages =
        buildNarrativeDependencyIndex(
          project: project,
          maps: [document.current],
        ).usagesFor(
          NarrativeDependencyKey.mapSource(
            mapId: document.current.id,
            sourceKind: 'trigger',
            sourceId: id,
          ),
        );
    if (usages.isNotEmpty) {
      return 'Cette zone porte une interaction de l’histoire. Retirez sa '
          'liaison avant de la supprimer.';
    }
    return draftGuard?.call(
      mapId: document.current.id,
      entityId: id,
      kind: MapDraftReferenceKind.trigger,
    );
  }

  void delete(String id) {
    final problem = deletionProblem(id);
    if (problem != null) throw StateError(problem);
    document.commit(removeTriggerFromMap(document.current, triggerId: id));
  }
}
