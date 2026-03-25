import '../models/project_manifest.dart';

/// Branche de la bibliothèque tilesets (dossier + contenu trié).
class TilesetLibraryBranch {
  const TilesetLibraryBranch({
    required this.folder,
    required this.childFolders,
    required this.tilesets,
  });

  final ProjectTilesetFolder folder;
  final List<TilesetLibraryBranch> childFolders;
  final List<ProjectTilesetEntry> tilesets;
}

/// Vue hiérarchique : dossiers racine + tilesets sans dossier (`folderId == null`).
class TilesetLibraryTreeSnapshot {
  const TilesetLibraryTreeSnapshot({
    required this.rootFolders,
    required this.rootTilesets,
  });

  final List<TilesetLibraryBranch> rootFolders;
  final List<ProjectTilesetEntry> rootTilesets;
}

int _compareFolders(ProjectTilesetFolder a, ProjectTilesetFolder b) {
  final o = a.sortOrder.compareTo(b.sortOrder);
  if (o != 0) return o;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

int _compareTilesetsForLibrary(ProjectTilesetEntry a, ProjectTilesetEntry b) {
  if (a.isWorldTileset != b.isWorldTileset) {
    return a.isWorldTileset ? -1 : 1;
  }
  final o = a.sortOrder.compareTo(b.sortOrder);
  if (o != 0) return o;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

TilesetLibraryBranch _buildBranch({
  required ProjectTilesetFolder folder,
  required List<ProjectTilesetFolder> allFolders,
  required List<ProjectTilesetEntry> allTilesets,
}) {
  final children = allFolders
      .where((f) => f.parentFolderId == folder.id)
      .toList()
    ..sort(_compareFolders);
  final directTilesets = allTilesets
      .where((t) => t.folderId == folder.id)
      .toList()
    ..sort(_compareTilesetsForLibrary);

  return TilesetLibraryBranch(
    folder: folder,
    childFolders: children
        .map(
          (f) => _buildBranch(
            folder: f,
            allFolders: allFolders,
            allTilesets: allTilesets,
          ),
        )
        .toList(growable: false),
    tilesets: directTilesets,
  );
}

/// Construit l’arbre de bibliothèque à partir du manifeste (tri stable).
TilesetLibraryTreeSnapshot buildTilesetLibraryTree(ProjectManifest manifest) {
  final folders = manifest.tilesetFolders.toList()..sort(_compareFolders);
  final roots = folders.where((f) => f.parentFolderId == null).toList();
  final rootBranches = roots
      .map(
        (f) => _buildBranch(
          folder: f,
          allFolders: folders,
          allTilesets: manifest.tilesets,
        ),
      )
      .toList(growable: false);

  final rootTilesets = manifest.tilesets
      .where((t) => t.folderId == null || t.folderId!.trim().isEmpty)
      .toList()
    ..sort(_compareTilesetsForLibrary);

  return TilesetLibraryTreeSnapshot(
    rootFolders: rootBranches,
    rootTilesets: rootTilesets,
  );
}

/// Ligne pour un sélecteur de dossier (libellé avec chemin lisible).
class TilesetLibraryFolderPickerRow {
  const TilesetLibraryFolderPickerRow({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

/// Liste plate des dossiers, triée comme l’arbre (profondeur d’abord).
List<TilesetLibraryFolderPickerRow> flattenTilesetFoldersForPicker(
  ProjectManifest manifest,
) {
  final folders = manifest.tilesetFolders.toList()..sort(_compareFolders);
  final out = <TilesetLibraryFolderPickerRow>[];

  void walk(String? parentId, String prefix) {
    final children = folders.where((f) => f.parentFolderId == parentId).toList()
      ..sort(_compareFolders);
    for (final f in children) {
      final label = prefix.isEmpty ? f.name : '$prefix / ${f.name}';
      out.add(TilesetLibraryFolderPickerRow(id: f.id, label: label));
      walk(f.id, label);
    }
  }

  walk(null, '');
  return out;
}

/// Identifiants du dossier [rootId] et de tous ses sous-dossiers (incl. [rootId]).
Set<String> tilesetFolderSubtreeIds(ProjectManifest manifest, String rootId) {
  final byParent = <String?, List<ProjectTilesetFolder>>{};
  for (final f in manifest.tilesetFolders) {
    byParent.putIfAbsent(f.parentFolderId, () => []).add(f);
  }
  final out = <String>{};
  void walk(String id) {
    out.add(id);
    for (final c in byParent[id] ?? const <ProjectTilesetFolder>[]) {
      walk(c.id);
    }
  }

  walk(rootId);
  return out;
}
