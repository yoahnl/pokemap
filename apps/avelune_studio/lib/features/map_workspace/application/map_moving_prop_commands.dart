import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core_domain.dart';

import 'editable_map_document.dart';

class MapMovingPropDraft {
  MapMovingPropDraft.fromPlacement(
    MapData map,
    ProjectManifest project,
    String placementId,
  ) {
    final prop = map.movingProps
        .where((value) => value.placedElementId == placementId)
        .firstOrNull;
    final dx = prop == null
        ? 0
        : prop.openPositionPx.x - prop.closedPositionPx.x;
    final dy = prop == null
        ? 0
        : prop.openPositionPx.y - prop.closedPositionPx.y;
    direction = dx < 0
        ? 'west'
        : dy < 0
        ? 'north'
        : dy > 0
        ? 'south'
        : 'east';
    distance =
        '${prop == null ? project.settings.tileWidth : dx.abs() + dy.abs()}';
    width = '${prop?.collisionRect.widthPx ?? project.settings.tileWidth}';
    height = '${prop?.collisionRect.heightPx ?? project.settings.tileHeight}';
    left = '${prop?.collisionRect.leftPx ?? 0}';
    top = '${prop?.collisionRect.topPx ?? 0}';
    initialState = prop?.initialState.name ?? 'closed';
  }

  late String direction;
  late String distance;
  late String width;
  late String height;
  late String left;
  late String top;
  late String initialState;
}

class MapMovingPropCommands {
  const MapMovingPropCommands(this.document, this.project);
  final EditableMapDocument document;
  final ProjectManifest project;

  MovingPropDefinition? forPlacement(String id) => document.current.movingProps
      .where((value) => value.placedElementId == id)
      .firstOrNull;

  bool canConfigure(MapPlacedElement placement) =>
      document.current.spatialScene == null &&
      project.settings.dimension == ProjectDimension.twoD &&
      isAuthoredMapPlacedElement(placement);

  String? save(String placementId, MapMovingPropDraft draft) {
    try {
      const editing = MovingPropEditing();
      final prop = editing.definition(
        map: document.current,
        project: project,
        placedElementId: placementId,
        direction: EntityFacing.values.byName(draft.direction),
        distancePx: int.parse(draft.distance),
        initialState: MovingPropState.values.byName(draft.initialState),
        collisionRect: PixelRect(
          leftPx: int.parse(draft.left),
          topPx: int.parse(draft.top),
          widthPx: int.parse(draft.width),
          heightPx: int.parse(draft.height),
        ),
      );
      document.commit(
        editing.upsert(map: document.current, project: project, prop: prop),
      );
      return null;
    } on Object {
      return 'Vérifiez les valeurs entières, le rail de 1 à 1024 pixels, l’empreinte dans le décor et les deux positions dans la carte.';
    }
  }

  String? delete(String propId) {
    try {
      document.commit(
        const MovingPropEditing().delete(
          map: document.current,
          project: project,
          propId: propId,
        ),
      );
      return null;
    } on Object {
      return 'Ce déplacement est utilisé par une scène. Retirez sa référence avant de le supprimer.';
    }
  }
}
