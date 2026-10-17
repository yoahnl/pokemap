import 'package:map_core/map_core.dart';

final class SpatialRuntimeModelIndex {
  SpatialRuntimeModelIndex(Map<String, Iterable<SpatialModelInstance>> scenes)
    : _instances = {
        for (final scene in scenes.entries)
          for (final instance in scene.value)
            (scene.key, instance.id): instance,
      };

  final Map<(String, String), SpatialModelInstance> _instances;

  SpatialModelInstance? instance(String mapId, String instanceId) =>
      _instances[(mapId, instanceId)];
}
