import 'package:map_core/map_core_domain.dart';

import 'editable_map_document.dart';
import 'map_editing_commands.dart';
import 'spatial_model_editing_commands.dart';

final class MapDecorGroupSummary {
  const MapDecorGroupSummary({
    required this.ids,
    required this.editableIds,
    required this.lockedIds,
    required this.x,
    required this.y,
  });

  final List<String> ids, editableIds, lockedIds;
  final num? x, y;

  bool get mixedX => x == null && ids.isNotEmpty;
  bool get mixedY => y == null && ids.isNotEmpty;
}

final class MapDecorGroupEditing {
  const MapDecorGroupEditing(this.document, this.project);

  final EditableMapDocument document;
  final ProjectManifest project;

  bool get _spatial => document.current.spatialScene != null;

  String get _kind => _spatial ? 'model' : 'decor';

  Map<String, (num, num)> _positions(Iterable<String> ids) {
    final wanted = ids.toSet();
    if (_spatial) {
      return {
        for (final instance in document.current.spatialScene!.instances)
          if (wanted.contains(instance.id))
            instance.id: (instance.position.x, instance.position.z),
      };
    }
    return {
      for (final element in document.current.placedElements)
        if (wanted.contains(element.id))
          element.id: (element.pos.x, element.pos.y),
    };
  }

  MapDecorGroupSummary summarize(Iterable<String> ids) {
    final positions = _positions(ids);
    final present = [
      for (final id in ids)
        if (positions.containsKey(id)) id,
    ];
    final locked = [
      for (final id in present)
        if (document.isElementLocked(_kind, id) ||
            document.isElementUnavailable(_kind, id))
          id,
    ];
    num? shared(num Function((num, num) position) axis) {
      final values = {for (final id in present) axis(positions[id]!)};
      return values.length == 1 ? values.single : null;
    }

    return MapDecorGroupSummary(
      ids: present,
      editableIds: [
        for (final id in present)
          if (!locked.contains(id)) id,
      ],
      lockedIds: locked,
      x: shared((position) => position.$1),
      y: shared((position) => position.$2),
    );
  }

  bool move(Iterable<String> ids, {num? x, num? y}) {
    if (x == null && y == null) return false;
    final summary = summarize(ids);
    if (summary.editableIds.isEmpty) return false;
    final positions = _positions(summary.editableIds);
    return _grouped(() {
      for (final id in summary.editableIds) {
        final (currentX, currentY) = positions[id]!;
        if (_spatial) {
          SpatialModelEditingCommands(document, project).update(
            id,
            x: (x ?? currentX).toDouble(),
            z: (y ?? currentY).toDouble(),
          );
        } else {
          MapEditingCommands(document, project).move(
            id,
            GridPos(x: (x ?? currentX).round(), y: (y ?? currentY).round()),
          );
        }
        if (document.error != null) return false;
      }
      return true;
    });
  }

  bool remove(Iterable<String> ids) {
    final summary = summarize(ids);
    if (summary.editableIds.isEmpty) return false;
    return _grouped(() {
      for (final id in summary.editableIds) {
        if (_spatial) {
          SpatialModelEditingCommands(document, project).delete(id);
        } else {
          if (document.current.movingProps.any(
            (prop) => prop.placedElementId == id,
          )) {
            document.error = 'Retirez le déplacement du décor avant de supprimer son visuel.';
            return false;
          }
          document.commit(
            removeMapPlacedElement(document.current, instanceId: id),
          );
        }
        if (document.error != null) return false;
      }
      return true;
    });
  }

  bool _grouped(bool Function() apply) {
    final restore = document.preserveDraft();
    document.error = null;
    bool applied;
    try {
      applied = apply();
    } on StateError catch (error) {
      document.error = error.message;
      applied = false;
    }
    final result = document.current;
    final error = document.error;
    restore();
    if (!applied) {
      document.error = error;
      return false;
    }
    if (result == document.current) return false;
    document.commit(result);
    return true;
  }
}
