import 'resource_catalog.dart';

enum ResourceItemActionKind {
  terrainEdit,
  terrainRename,
  tilesetInformation,
  move,
  usages,
  replaceSource,
  duplicateTerrain,
  removeTerrain,
  duplicateDefinition,
  remove,
}

extension ResourceItemActionKindPresentation on ResourceItemActionKind {
  bool get destructive => switch (this) {
    ResourceItemActionKind.removeTerrain || ResourceItemActionKind.remove =>
      true,
    _ => false,
  };
}

typedef ResourceItemActionEntry = ({ResourceItemActionKind kind, String label});

List<ResourceItemActionEntry> resourceItemActionMatrix(
  ResourceItem item, {
  bool onInformation = false,
  bool onMove = false,
  bool onUsages = false,
  bool onReplace = false,
  bool onRemove = false,
  bool onDuplicate = false,
  bool onTerrainEdit = false,
}) {
  final movable =
      item.tileset != null || item.element != null || item.terrain != null;
  return [
    if (item.terrain != null && onTerrainEdit)
      (
        kind: ResourceItemActionKind.terrainEdit,
        label: 'Modifier les raccords',
      ),
    if (item.terrain != null && onInformation)
      (
        kind: ResourceItemActionKind.terrainRename,
        label: 'Renommer le terrain…',
      ),
    if (item.tileset != null && onInformation)
      (
        kind: ResourceItemActionKind.tilesetInformation,
        label: 'Modifier les informations',
      ),
    if (onMove && movable)
      (kind: ResourceItemActionKind.move, label: 'Déplacer vers…'),
    if (onUsages && movable)
      (
        kind: ResourceItemActionKind.usages,
        label: 'Voir les usages dans le projet',
      ),
    if (item.tileset != null && onReplace)
      (
        kind: ResourceItemActionKind.replaceSource,
        label: 'Remplacer l’image source…',
      ),
    if (item.terrain != null && onDuplicate)
      (
        kind: ResourceItemActionKind.duplicateTerrain,
        label: 'Dupliquer le terrain…',
      ),
    if (item.terrain != null && onRemove)
      (
        kind: ResourceItemActionKind.removeTerrain,
        label: 'Supprimer le terrain…',
      ),
    if (item.element != null && onDuplicate)
      (
        kind: ResourceItemActionKind.duplicateDefinition,
        label: 'Dupliquer la définition…',
      ),
    if (onRemove && (item.tileset != null || item.element != null))
      (
        kind: ResourceItemActionKind.remove,
        label: item.element == null
            ? 'Supprimer la planche…'
            : 'Supprimer la définition…',
      ),
  ];
}
