part of 'map_editing_commands.dart';

extension MapDecorOrderCommands on MapEditingCommands {
  void reorder({required bool forward}) {
    final id = document.selectedId;
    if (id != null && document.isElementUnavailable('decor', id)) return;
    document.commit(_reordered(forward: forward));
  }

  bool canReorder({required bool forward}) =>
      _reordered(forward: forward) != document.current;

  bool canReorderAt({
    required String instanceId,
    required GridPos at,
    required bool forward,
  }) =>
      _reorderedAt(instanceId: instanceId, at: at, forward: forward) !=
      document.current;

  String? reorderProblemAt({
    required String instanceId,
    required GridPos at,
    required bool forward,
  }) {
    if (canReorderAt(instanceId: instanceId, at: at, forward: forward)) {
      return null;
    }
    final source = document.current.placedElements
        .where((element) => element.id == instanceId)
        .firstOrNull;
    if (source == null) return 'Ce décor n’est plus sur la carte.';
    final pixel = document.stackPosition == at
        ? document.stackPixelPosition
        : null;
    final peers = pixel != null
        ? mapPlacedElementsAtPixel(
            document.current,
            project,
            pixel,
            layerId: source.layerId,
          )
        : mapPlacedElementsAt(
            document.current,
            project,
            at,
            layerId: source.layerId,
          );
    if (!peers.any((element) => element.id == instanceId)) {
      return 'Ce décor n’occupe plus cet emplacement.';
    }
    if (peers.length == 1) {
      return 'Aucun autre décor réordonnable à cet emplacement.';
    }
    if (!canReorderAt(instanceId: instanceId, at: at, forward: !forward)) {
      return 'Aucun autre décor réordonnable à cet emplacement.';
    }
    return forward
        ? 'Ce décor est déjà devant les autres décors réordonnables ici.'
        : 'Ce décor est déjà derrière les autres décors réordonnables ici.';
  }

  void reorderAt({
    required String instanceId,
    required GridPos at,
    required bool forward,
  }) => document.commit(
    _reorderedAt(instanceId: instanceId, at: at, forward: forward),
  );

  MapData _reorderedAt({
    required String instanceId,
    required GridPos at,
    required bool forward,
  }) {
    if (document.isElementUnavailable('decor', instanceId)) {
      return document.current;
    }
    try {
      return moveMapPlacedElementVisualOrder(
        document.current,
        manifest: project,
        instanceId: instanceId,
        forward: forward,
        at: document.stackPosition == at && document.stackPixelPosition != null
            ? null
            : at,
        atPixel: document.stackPosition == at
            ? document.stackPixelPosition
            : null,
      );
    } on ValidationException {
      return document.current;
    }
  }

  MapData _reordered({required bool forward}) {
    final id = document.selectedId;
    if (id == null) return document.current;
    if (document.isElementUnavailable('decor', id)) return document.current;
    try {
      return moveMapPlacedElementVisualOrder(
        document.current,
        manifest: project,
        instanceId: id,
        forward: forward,
        at: document.stackPixelPosition == null ? document.stackPosition : null,
        atPixel: document.stackPixelPosition,
      );
    } on ValidationException {
      return document.current;
    }
  }

  List<MapPlacedElement> stack(GridPos position) =>
      mapPlacedElementsAt(document.current, project, position).reversed
          .where((item) => !document.isElementUnavailable('decor', item.id))
          .toList();

  List<MapPlacedElement> stackAtPixel(PixelPosition position) =>
      mapPlacedElementsAtPixel(document.current, project, position).reversed
          .where((item) => !document.isElementUnavailable('decor', item.id))
          .toList();

  List<MapPlacedElement> contextStack(GridPos position) =>
      document.stackPosition == position && document.stackPixelPosition != null
      ? stackAtPixel(document.stackPixelPosition!)
      : stack(position);

  MapDecorOrderContext? decorOrderContext({String? instanceId, GridPos? at}) {
    final id = instanceId ?? document.selectedId;
    if (id == null) return null;
    final target = document.current.placedElements
        .where((element) => element.id == id)
        .firstOrNull;
    final position = at ?? document.stackPosition ?? target?.pos;
    if (position == null) return null;
    final entries = contextStack(position);
    return MapDecorOrderContext(
      instanceId: id,
      target: target,
      position: position,
      pixelPosition: document.stackPosition == position
          ? document.stackPixelPosition
          : null,
      stack: entries,
      reorderable: entries
          .where((element) => element.layerId == target?.layerId)
          .toList(),
      other: entries
          .where((element) => element.layerId != target?.layerId)
          .toList(),
      forwardProblem: reorderProblemAt(
        instanceId: id,
        at: position,
        forward: true,
      ),
      backwardProblem: reorderProblemAt(
        instanceId: id,
        at: position,
        forward: false,
      ),
    );
  }
}
