import 'package:map_core/map_core_domain.dart';

import '../../map_workspace/application/editable_map_document.dart';

class NarrativeSourceLocation {
  const NarrativeSourceLocation({
    required this.document,
    required this.position,
    this.entityId,
    this.triggerId,
    this.instanceId,
  });
  final EditableMapDocument document;
  final GridPos position;
  final String? entityId;
  final String? triggerId;
  final String? instanceId;

  static NarrativeSourceLocation? fromSource(
    EditableMapDocument document,
    NarrativeEventSourceRef source,
  ) {
    final fields = source.toJson();
    if (fields['mapId'] != document.current.id) return null;
    if (source.kind == NarrativeEventSourceKind.modelInteract) {
      final instance = document.current.spatialScene?.instances
          .where((instance) => instance.id == fields['instanceId']).firstOrNull;
      if (instance == null) return null;
      return NarrativeSourceLocation(
        document: document,
        position: GridPos(x: instance.position.x.floor(), y: instance.position.z.floor()),
        instanceId: instance.id,
      );
    }
    final entity = document.current.entities
        .where((entity) => entity.id == fields['entityId'])
        .firstOrNull;
    if (entity != null) {
      return NarrativeSourceLocation(
        document: document,
        position: entity.pos,
        entityId: entity.id,
      );
    }
    final trigger = document.current.triggers
        .where((trigger) => trigger.id == fields['triggerId'])
        .firstOrNull;
    if (trigger == null) return null;
    return NarrativeSourceLocation(
      document: document,
      position: GridPos(
        x: trigger.area.pos.x + (trigger.area.size.width - 1) ~/ 2,
        y: trigger.area.pos.y + (trigger.area.size.height - 1) ~/ 2,
      ),
      triggerId: trigger.id,
    );
  }
}
