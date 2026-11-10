import 'package:map_core/map_core.dart';

import 'editable_map_document.dart';

class SpatialLiftEditingSession {
  SpatialLiftEditingSession(this.document, this.instance) {
    load();
  }

  final EditableMapDocument document;
  SpatialModelInstance instance;
  bool _disposed = false;
  final values = <String, String>{};
  SpatialLiftDefinition? lift;
  MapData? source;
  String? error;

  void load() {
    if (_disposed) return;
    source = document.current;
    lift = source!.spatialScene!.lifts
        .where((v) => v.instanceId == instance.id)
        .firstOrNull;
    final point = instance.position;
    final ground = source!.spatialScene!.worldHeightAt(point.x, point.z);
    values.addAll({
      'name': lift?.name ?? 'Ascenseur',
      'x': '${lift?.x ?? point.x.floor()}',
      'z': '${lift?.z ?? point.z.floor()}',
      'width': '${lift?.width ?? 1}',
      'depth': '${lift?.depth ?? 1}',
      'lower': '${lift?.lowerHeight ?? ground}',
      'upper': '${lift?.upperHeight ?? ground + 1}',
      'duration': '${lift?.durationMs ?? 1000}',
    });
    error = null;
  }

  String nextId() {
    var index = 1;
    while (source!.spatialScene!.lifts.any(
      (v) => v.id == 'vertical-platform-$index',
    )) {
      index++;
    }
    return 'vertical-platform-$index';
  }

  bool apply() {
    if (_disposed) return false;
    try {
      if (document.saving ||
          !identical(source, document.current) ||
          document.isElementLocked('model', instance.id)) {
        throw StateError('La carte a changé ou cet élément est verrouillé.');
      }
      final definition = SpatialLiftDefinition(
        id: lift?.id ?? nextId(),
        name: values['name']!.trim(),
        instanceId: instance.id,
        x: int.parse(values['x']!),
        z: int.parse(values['z']!),
        width: int.parse(values['width']!),
        depth: int.parse(values['depth']!),
        lowerHeight: double.parse(values['lower']!.replaceAll(',', '.')),
        upperHeight: double.parse(values['upper']!.replaceAll(',', '.')),
        durationMs: int.parse(values['duration']!),
      );
      document.commit(
        const SpatialMapOperations().upsertLifts(document.current, [
          definition,
        ]),
      );
      load();
      return true;
    } catch (e) {
      error = e is StateError ? e.message.toString() : 'Vérifiez la zone, les deux hauteurs et une durée entre 100 et 30000 ms.';
      return false;
    }
  }

  bool delete() {
    if (_disposed ||
        document.saving ||
        document.isElementLocked('model', instance.id) ||
        lift == null) {
      return false;
    }
    if (!identical(source, document.current)) {
      error = 'La carte a changé ou cet élément est verrouillé.';
      return false;
    }
    document.commit(
      const SpatialMapOperations().deleteLifts(document.current, [lift!.id]),
    );
    load();
    return true;
  }

  void dispose() {
    _disposed = true;
  }
}
