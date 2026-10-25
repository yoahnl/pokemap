import 'package:map_core/map_core.dart';

final class SpatialRuntimeModelIndex {
  SpatialRuntimeModelIndex(Map<String, Iterable<SpatialModelInstance>> scenes)
    : _instances = {
        for (final scene in scenes.entries)
          for (final instance in scene.value)
            (scene.key, instance.id): instance,
      };

  final Map<(String, String), SpatialModelInstance> _instances;

  void replaceInstance(String mapId, SpatialModelInstance instance) {
    final key = (mapId, instance.id);
    if (!_instances.containsKey(key)) throw StateError('Cannot replace an unknown spatial model instance.');
    _instances[key] = instance;
  }

  SpatialModelInstance? instance(String mapId, String instanceId) =>
      _instances[(mapId, instanceId)];
}
