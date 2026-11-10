import 'package:map_core/map_core.dart';

import 'editable_map_document.dart';

class SpatialPlatformEditingSession {
  SpatialPlatformEditingSession(this.document, this.instance) {
    load();
  }

  final EditableMapDocument document;
  SpatialModelInstance instance;
  bool _disposed = false;
  MapData? source;
  SpatialPlatformDefinition? platform;
  final values = <String, String>{};
  final routes = <SpatialPlatformRouteDraft>[];
  String? error;
  bool get enabled =>
      !_disposed &&
      !document.saving &&
      !document.isElementLocked('model', instance.id);

  void load() {
    if (_disposed) return;
    source = document.current;
    platform = source!.spatialScene!.platforms
        .where((value) => value.instanceId == instance.id)
        .firstOrNull;
    final position = instance.position;
    values.addAll({
      'name': platform?.name ?? 'Plateforme',
      'x': '${platform?.x ?? position.x.floor()}',
      'z': '${platform?.z ?? position.z.floor()}',
      'width': '${platform?.width ?? 1}',
      'depth': '${platform?.depth ?? 1}',
      'height':
          '${platform?.height ?? source!.spatialScene!.worldHeightAt(position.x, position.z)}',
      'duration': '${platform?.durationMs ?? 1500}',
    });
    routes.clear();
    routes.addAll(
      platform?.routes.map(SpatialPlatformRouteDraft.fromRoute) ??
          [SpatialPlatformRouteDraft('route-1')],
    );
    error = null;
  }

  double number(String value) => double.parse(value.replaceAll(',', '.'));
  bool apply() {
    if (_disposed) return false;
    try {
      if (!enabled || !identical(source, document.current)) {
        throw StateError('La carte a changé ou cet élément est verrouillé.');
      }
      var serial = 1;
      while (source!.spatialScene!.platforms.any(
            (value) => value.id == 'route-platform-$serial',
          ) ||
          source!.spatialScene!.lifts.any(
            (value) => value.id == 'route-platform-$serial',
          )) {
        serial++;
      }
      final value = SpatialPlatformDefinition(
        id: platform?.id ?? 'route-platform-$serial',
        name: values['name']!.trim(),
        instanceId: instance.id,
        x: number(values['x']!),
        z: number(values['z']!),
        width: number(values['width']!),
        depth: number(values['depth']!),
        height: number(values['height']!),
        durationMs: int.parse(values['duration']!),
        routes: [
          for (final route in routes)
            SpatialPlatformRoute(
              id: route.id,
              waypoints: [
                for (final point in route.points)
                  SpatialPlatformStop(x: number(point[0]), z: number(point[1])),
              ],
              conditions: [
                for (final condition in route.conditions)
                  SpatialPlatformCondition(
                    factId: condition.$1,
                    value: condition.$2,
                  ),
              ],
            ),
        ],
      );
      document.commit(
        const SpatialMapOperations().upsertPlatform(document.current, value),
      );
      load();
      return true;
    } catch (exception) {
      error = exception is StateError ? exception.message.toString() : 'Vérifiez la zone, les quais, les conditions et la durée (100 à 30000 ms). Gardez exactement un trajet sans condition.';
      return false;
    }
  }

  void addRoute() {
    if (_disposed) return;
    var serial = 1;
    while (routes.any((value) => value.id == 'route-$serial')) {
      serial++;
    }
    routes.add(SpatialPlatformRouteDraft('route-$serial'));
  }

  void dispose() {
    _disposed = true;
  }
}

final class SpatialPlatformRouteDraft {
  SpatialPlatformRouteDraft(this.id)
    : points = [
        ['0', '0'],
        ['1', '0'],
      ],
      conditions = [];
  SpatialPlatformRouteDraft.fromRoute(SpatialPlatformRoute route)
    : id = route.id,
      points = [
        for (final point in route.waypoints) ['${point.x}', '${point.z}'],
      ],
      conditions = [
        for (final condition in route.conditions)
          (condition.factId, condition.value),
      ];
  final String id;
  final List<List<String>> points;
  final List<(String, bool)> conditions;
}
