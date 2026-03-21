import '../models/project_manifest.dart';
import '../models/map_data.dart';
import '../exceptions/map_exceptions.dart';

class ProjectValidator {
  static void validate(ProjectManifest manifest) {
    _validateUniqueness(manifest);
    _validateHierarchy(manifest);
  }

  static void _validateUniqueness(ProjectManifest manifest) {
    final mapIds = <String>{};
    for (final map in manifest.maps) {
      if (!mapIds.add(map.id)) throw ValidationException('Duplicate map ID: ${map.id}');
    }

    final groupIds = <String>{};
    for (final group in manifest.groups) {
      if (!groupIds.add(group.id)) throw ValidationException('Duplicate group ID: ${group.id}');
    }
  }

  static void _validateHierarchy(ProjectManifest manifest) {
    final groupIds = manifest.groups.map((g) => g.id).toSet();
    
    // Check parent references
    for (final group in manifest.groups) {
      if (group.parentGroupId != null && !groupIds.contains(group.parentGroupId)) {
        throw ValidationException('Group ${group.id} references non-existent parent: ${group.parentGroupId}');
      }
      if (group.parentGroupId == group.id) {
        throw ValidationException('Group ${group.id} cannot be its own parent');
      }
      
      // Basic cycle detection
      var current = group;
      final visited = {group.id};
      while (current.parentGroupId != null) {
        if (!groupIds.contains(current.parentGroupId)) break;
        if (!visited.add(current.parentGroupId!)) {
          throw ValidationException('Cycle detected in group hierarchy at ${group.id}');
        }
        current = manifest.groups.firstWhere((g) => g.id == current.parentGroupId);
      }
    }

    // Check map group references
    for (final map in manifest.maps) {
      if (map.groupId != null && !groupIds.contains(map.groupId)) {
        throw ValidationException('Map ${map.id} references non-existent group: ${map.groupId}');
      }
    }
  }
}

class MapValidator {
  static void validate(MapData map) {
    if (map.id.isEmpty) throw const ValidationException('Map ID cannot be empty');
    if (map.size.width <= 0 || map.size.height <= 0) {
      throw const ValidationException('Map size must be positive');
    }
  }
}
