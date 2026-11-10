import 'package:map_core/map_core_domain.dart';

Map<String, String> newMapSheetOptions(ProjectManifest project) {
  final characterSheets = {
    for (final character in project.characters) character.tilesetId,
  };
  final folders = mapLibrarySheetFolderLabels(project.tilesetFolders);
  String label(ProjectTilesetEntry entry) {
    final usage = characterSheets.contains(entry.id) ? 'Personnage' : 'Décor';
    final folder = folders[entry.folderId];
    return folder == null
        ? '$usage · ${entry.name}'
        : '$usage · $folder / ${entry.name}';
  }

  final sorted = project.tilesets.toList()
    ..sort((left, right) {
      final usage = characterSheets
          .contains(left.id)
          .toString()
          .compareTo(characterSheets.contains(right.id).toString());
      if (usage != 0) return usage;
      final order = left.sortOrder.compareTo(right.sortOrder);
      return order != 0 ? order : left.name.compareTo(right.name);
    });
  return {
    '': 'Choix automatique du projet',
    for (final entry in sorted) entry.id: label(entry),
  };
}

Map<String, String> mapLibrarySheetFolderLabels(
  List<ProjectTilesetFolder> folders,
) {
  final byId = {for (final folder in folders) folder.id: folder};
  String path(ProjectTilesetFolder folder, Set<String> visited) {
    final parent = byId[folder.parentFolderId];
    if (parent == null || !visited.add(folder.id)) return folder.name;
    return '${path(parent, visited)} / ${folder.name}';
  }

  return {for (final folder in folders) folder.id: path(folder, {})};
}

String mapRoleLabel(MapRole role) => switch (role) {
  MapRole.exterior => 'Extérieur',
  MapRole.interior => 'Intérieur',
  MapRole.basement => 'Sous-sol',
  MapRole.upper_floor => 'Étage',
  MapRole.connector => 'Liaison',
  MapRole.gate => 'Entrée',
  MapRole.room => 'Pièce',
  MapRole.section => 'Section',
  MapRole.sub_area => 'Sous-zone',
};
