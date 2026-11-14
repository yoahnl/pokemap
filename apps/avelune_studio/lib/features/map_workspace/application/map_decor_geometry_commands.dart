part of 'map_editing_commands.dart';

extension MapDecorGeometryCommands on MapEditingCommands {
  bool setGeometryText(
    String id,
    String field,
    String text, {
    required bool lockProportions,
  }) {
    final number = int.tryParse(text.trim());
    if (number == null) {
      document.error = 'Saisissez un nombre entier de pixels.';
      return false;
    }
    final instance = document.selected;
    if (instance == null || instance.id != id) return false;
    final element = project.elements
        .where((entry) => entry.id == instance.elementId)
        .firstOrNull;
    if (element == null) return false;
    final rect = resolveMapPlacedElementGeometry(
      instance: instance,
      element: element,
      tileSize: PixelSize(
        width: project.settings.tileWidth,
        height: project.settings.tileHeight,
      ),
    ).logicalRect;
    var width = rect.widthPx, height = rect.heightPx;
    if (field == 'width') {
      width = number;
      if (lockProportions) {
        height = math.max(1, (width * rect.heightPx / rect.widthPx).round());
      }
    }
    if (field == 'height') {
      height = number;
      if (lockProportions) {
        width = math.max(1, (height * rect.widthPx / rect.heightPx).round());
      }
    }
    return setGeometry(
      id,
      x: field == 'x' ? number : rect.leftPx,
      y: field == 'y' ? number : rect.topPx,
      size: field == 'x' || field == 'y'
          ? instance.pixelSize
          : PixelSize(width: width, height: height),
    );
  }

  bool snapGeometryToGrid(String id) {
    final instance = document.selected;
    if (instance == null || instance.id != id) return false;
    final element = project.elements
        .where((entry) => entry.id == instance.elementId)
        .firstOrNull;
    if (element == null) return false;
    final tile = PixelSize(
      width: project.settings.tileWidth,
      height: project.settings.tileHeight,
    );
    final rect = resolveMapPlacedElementGeometry(
      instance: instance,
      element: element,
      tileSize: tile,
    ).logicalRect;
    return setGeometry(
      id,
      x: (rect.leftPx / tile.width).round() * tile.width,
      y: (rect.topPx / tile.height).round() * tile.height,
      size: instance.pixelSize,
    );
  }

  bool setGeometry(
    String id, {
    required int x,
    required int y,
    required PixelSize? size,
  }) {
    if (document.isElementUnavailable('decor', id)) return false;
    try {
      document.commit(
        const MovingPropEditing().reconcilePlacementChanges(
          before: document.current,
          project: project,
          after: setMapPlacedElementGeometry(
            document.current,
            manifest: project,
            instanceId: id,
            pixelX: x,
            pixelY: y,
            pixelSize: size,
          ),
        ),
      );
      document.stackPosition = document.selected?.pos;
      document.stackPixelPosition = PixelPosition(leftPx: x, topPx: y);
      return true;
    } on FormatException {
      document.error =
          'Le décor mobile ou son rail dépasse les limites de la carte.';
      return false;
    } on ValidationException {
      document.error =
          'Ce décor dépasse les limites de la carte ou sa taille autorisée.';
      return false;
    }
  }
}
