import 'dart:math' as math;

import 'package:map_core/map_core_domain.dart';

import 'editable_map_document.dart';
import 'map_selection_target.dart';
import 'spatial_model_editing_commands.dart';

sealed class MapElementCopy {
  const MapElementCopy();
  GridPos get anchor;
}

final class SpatialModelCopyItem extends MapElementCopy {
  const SpatialModelCopyItem(this.instance, this.elevation);
  final SpatialModelInstance instance;
  final double elevation;
  @override
  GridPos get anchor =>
      GridPos(x: instance.position.x.floor(), y: instance.position.z.floor());
}

final class PlacedDecorCopyItem extends MapElementCopy {
  const PlacedDecorCopyItem(this.element);
  final MapPlacedElement element;
  @override
  GridPos get anchor => element.pos;
}

final class EntityCopyItem extends MapElementCopy {
  const EntityCopyItem(this.entity, this.family);
  final MapEntity entity;
  final MapSelectionFamily family;
  @override
  GridPos get anchor => entity.pos;
}

final class WarpCopyItem extends MapElementCopy {
  const WarpCopyItem(this.warp);
  final MapWarp warp;
  @override
  GridPos get anchor => warp.pos;
}

final class ZoneCopyItem extends MapElementCopy {
  const ZoneCopyItem(this.zone);
  final MapGameplayZone zone;
  @override
  GridPos get anchor => zone.area.pos;
}

final class TriggerCopyItem extends MapElementCopy {
  const TriggerCopyItem(this.trigger);
  final MapTrigger trigger;
  @override
  GridPos get anchor => trigger.area.pos;
}

class MapElementClipboard {
  MapElementClipboard({
    required this.sourceMapId,
    required this.items,
    this.cut = false,
  }) : assert(items.isNotEmpty);
  final String sourceMapId;
  final List<MapElementCopy> items;
  final bool cut;

  GridPos get origin => GridPos(
    x: items.map((item) => item.anchor.x).reduce(math.min),
    y: items.map((item) => item.anchor.y).reduce(math.min),
  );
}

const mapCopyNameSuffix = ' (copie)';

String copiedName(String name) =>
    name.trim().isEmpty ? name : '$name$mapCopyNameSuffix';

MapElementClipboard copyMapElements(
  EditableMapDocument document,
  ProjectManifest project,
  List<MapSelectionTarget> targets,
) {
  final map = document.current;
  final spatial = SpatialModelEditingCommands(document, project);
  final items = <MapElementCopy>[];
  for (final target in targets) {
    if (target.mapId != map.id) continue;
    items.add(switch (target.family) {
      MapSelectionFamily.decor => _decorCopy(document, spatial, target.id),
      MapSelectionFamily.character ||
      MapSelectionFamily.marker => _entityCopy(map, target),
      MapSelectionFamily.warp => WarpCopyItem(
        map.warps.where((item) => item.id == target.id).firstOrNull ??
            (throw _missing()),
      ),
      MapSelectionFamily.zone => ZoneCopyItem(
        map.gameplayZones.where((item) => item.id == target.id).firstOrNull ??
            (throw _missing()),
      ),
      MapSelectionFamily.trigger => TriggerCopyItem(
        map.triggers.where((item) => item.id == target.id).firstOrNull ??
            (throw _missing()),
      ),
    });
  }
  if (items.isEmpty) {
    throw StateError('Sélectionnez au moins un élément à copier.');
  }
  return MapElementClipboard(sourceMapId: map.id, items: items);
}

StateError _missing() => StateError('Cet élément n’existe plus sur la carte.');

MapElementCopy _decorCopy(
  EditableMapDocument document,
  SpatialModelEditingCommands spatial,
  String id,
) {
  if (id.startsWith('smt_')) {
    throw StateError(SpatialModelEditingCommands.paintedTerrainMessage);
  }
  if (spatial.borderOwner(id) != null) {
    throw StateError(SpatialModelEditingCommands.generatedBorderMessage);
  }
  final instance = spatial.selected(id);
  if (instance != null) {
    return SpatialModelCopyItem(
      instance.copyWith(clearEntityBinding: true),
      spatial.elevationOf(instance),
    );
  }
  final element = document.current.placedElements
      .where((item) => item.id == id)
      .firstOrNull;
  if (element == null) throw _missing();
  return PlacedDecorCopyItem(element);
}

MapElementCopy _entityCopy(MapData map, MapSelectionTarget target) {
  final entity = map.entities.where((item) => item.id == target.id).firstOrNull;
  if (entity == null) throw _missing();
  if (entity.kind == MapEntityKind.spawn) {
    throw StateError(
      'Un point d’apparition ne se copie pas : placez-en un nouveau.',
    );
  }
  return EntityCopyItem(entity, target.family);
}
