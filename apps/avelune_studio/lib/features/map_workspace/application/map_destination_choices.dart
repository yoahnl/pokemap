import 'package:map_core/map_core_domain.dart';

import '../../resources/domain/studio_search_text.dart';
import 'map_library_tree.dart';

final class MapDestinationChoice {
  const MapDestinationChoice(this.map, this.folderPath);
  final ProjectMapEntry map;
  final String folderPath;
}

List<MapDestinationChoice> mapDestinationChoices(
  ProjectManifest project, {
  String? excludeMapId,
  String query = '',
}) {
  final folders = mapLibraryFolderLabels(project.groups);
  final groupIds = project.groups.map((group) => group.id).toSet();
  return [
    for (final map in project.maps)
      if (map.id != excludeMapId)
        MapDestinationChoice(
          map,
          folders[groupIds.contains(map.groupId) ? map.groupId : ''] ??
              folders['']!,
        ),
  ].where((choice) {
    return studioSearchMatches(
      '${choice.folderPath} ${choice.map.name} ${choice.map.id}',
      query,
    );
  }).toList();
}
