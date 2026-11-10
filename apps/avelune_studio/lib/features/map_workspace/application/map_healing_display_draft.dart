import 'package:map_core/map_core_domain.dart';

class MapHealingDisplayDraft {
  MapHealingDisplayDraft(this.map, this.project, this.entity)
    : variants =
          entity.healingDisplay?.variantElementIds.cast<String?>().toList() ??
          List<String?>.filled(6, null);
  MapData map;
  ProjectManifest project;
  final MapEntity entity;
  final List<String?> variants;

  void updateContext(MapData map, ProjectManifest project) {
    this.map = map;
    this.project = project;
  }

  bool get canConfigure =>
      entity.kind == MapEntityKind.custom &&
      !entity.blocksMovement &&
      entity.size.width == 1 &&
      entity.size.height == 1 &&
      entity.npc == null &&
      entity.sign == null &&
      entity.item == null &&
      entity.spawn == null &&
      entity.fieldObstacle == null &&
      entity.editorVisual == null &&
      !healingDisplayHasCollisionOverride(entity) &&
      map.spatialScene == null &&
      map.version != ProjectVersion.v9 &&
      project.settings.dimension == ProjectDimension.twoD;
  (int, int)? geometry(ProjectElementEntry element) {
    if (element.frames.isEmpty ||
        element.collisionProfile != null ||
        project.elements.where((e) => e.id == element.id).length != 1) {
      return null;
    }
    (int, int)? size;
    for (final frame in element.frames) {
      final id = frame.tilesetId.isEmpty ? element.tilesetId : frame.tilesetId;
      final sources = project.tilesets.where((t) => t.id == id).toList();
      if (sources.length != 1 ||
          sources.single.source is! ProjectRegularAtlasTilesetSource ||
          (frame.durationMs != null && frame.durationMs! <= 0)) {
        return null;
      }
      final source = sources.single.source! as ProjectRegularAtlasTilesetSource;
      try {
        final bounds = const ProjectTilesetVisualResolver()
            .resolve(
              source: source,
              selection: ProjectTilesetVisualSelection.regularAtlas(
                source: frame.source,
              ),
              cellWidth: source.tileWidth,
              cellHeight: source.tileHeight,
            )
            .animationBounds;
        final next = (bounds.width, bounds.height);
        if (bounds.width > 512 ||
            bounds.height > 512 ||
            (size != null && size != next)) {
          return null;
        }
        size = next;
      } on ProjectTilesetVisualResolutionException {
        return null;
      }
    }
    return size;
  }

  Map<String, ProjectElementEntry> get candidates {
    final candidates = <String, ProjectElementEntry>{};
    final sizes = <(int, int), int>{};
    for (final element in project.elements) {
      final size = geometry(element);
      if (size == null) continue;
      candidates[element.id] = element;
      sizes[size] = (sizes[size] ?? 0) + 1;
    }
    candidates.removeWhere(
      (id, element) => (sizes[geometry(element)] ?? 0) < 6,
    );
    return candidates;
  }

  (int, int)? get selectedSize {
    final available = candidates;
    final selected = variants
        .whereType<String>()
        .map((id) => available[id])
        .whereType<ProjectElementEntry>()
        .firstOrNull;
    return selected == null ? null : geometry(selected);
  }

  bool get valid {
    final available = candidates;
    final size = selectedSize;
    return variants.every(
          (id) =>
              id != null &&
              available.containsKey(id) &&
              (size == null || geometry(available[id]!) == size),
        ) &&
        variants.toSet().length == 6;
  }

  MapEntityHealingDisplayData? get value => valid
      ? MapEntityHealingDisplayData(variantElementIds: variants.cast<String>())
      : null;
}
