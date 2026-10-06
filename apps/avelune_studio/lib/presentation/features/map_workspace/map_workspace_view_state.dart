import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';

enum MapSelectionFamily { decor, character, marker, warp, zone, trigger }

class MapSelectionTarget {
  const MapSelectionTarget({
    required this.mapId,
    required this.family,
    required this.id,
  });
  final String mapId;
  final MapSelectionFamily family;
  final String id;
}

enum StudioMapTool {
  select,
  place,
  paint,
  terrain,
  character,
  warp,
  spawn,
  sign,
  zone,
  gameplayZone,
  encounterPaint,
  encounterErase,
  collisionPaint,
  collisionErase,
  border,
  environment,
  erase,
  eraseDecor,
  pan,
}

class MapWorkspaceViewState {
  final transform = TransformationController();
  double get scale => transform.value.entry(0, 0).abs();
  StudioMapTool tool = StudioMapTool.select;
  ProjectElementEntry? brush;
  TileLayerPaletteEntry? tile;
  ProjectSmartTilePreset? terrain;
  ProjectCharacterEntry? character;
  ProjectMapEntry? warpDestination;
  String? borderBlueprintId;
  MapBorderDrawingDraft? borderDraft;
  MapEnvironmentSession? environment;
  MapSelectionTarget? _target;
  MapSelectionTarget? get target => _target;

  MapSelectionTarget? _pendingMove;
  String? _moveHint;

  /// Armed by the context menu: the element the next drag must move, whatever
  /// else sits under the pointer.
  MapSelectionTarget? get pendingMove => _pendingMove;
  set pendingMove(MapSelectionTarget? target) {
    _pendingMove = target;
    _moveHint = null;
  }

  String? get moveHint => _pendingMove == null ? null : _moveHint;

  void armMove(MapSelectionTarget target, String hint) {
    _pendingMove = target;
    _moveHint = hint;
  }

  MapPlacedElement? armedDecorIn(MapData map) {
    final armed = _pendingMove;
    if (armed == null ||
        armed.family != MapSelectionFamily.decor ||
        armed.mapId != map.id ||
        tool != StudioMapTool.select) {
      return null;
    }
    return map.placedElements.where((item) => item.id == armed.id).firstOrNull;
  }

  GameplayZoneKind zoneKind = GameplayZoneKind.encounter;
  String characterQuery = '';
  double characterScrollOffset = 0;
  bool grid = false;
  bool navigatorCollapsed = false;
  bool highlightTerrain = true;
  bool dimOtherTerrains = false;
  bool lockDecorProportions = false;
  bool showDecorCollision = false;
  bool paletteTiles = false;
  bool revealPalette = false;
  bool revealInspector = false;
  String paletteTab = 'Décors';
  String decorCategoryId = '';
  String terrainCategoryId = '';
  final paletteScrollOffsets = <String, double>{};
  String? paletteAtlasId;
  final paletteAtlasTransforms = <String, TransformationController>{};
  final fittedPaletteAtlases = <String>{};
  bool positioned = false;
  Size? _viewport;
  Size? _content;
  Matrix4? _fittedTransform;
  int _fitGeneration = 0;
  VoidCallback? recenter;
  void Function(GridPos)? centerOn;
  Offset? Function(GridPos)? globalOfCell;

  void fitViewport(Size viewport, Size content) {
    final widthScale = viewport.width / content.width;
    final heightScale = viewport.height / content.height;
    final scale = math.min(1.0, math.min(widthScale, heightScale));
    transform.value = Matrix4.identity()
      ..translateByDouble(
        (viewport.width - content.width * scale) / 2,
        (viewport.height - content.height * scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
    _fittedTransform = transform.value.clone();
  }

  void attachViewport(
    Size viewport,
    Size content,
    Size tile, {
    required bool Function() mounted,
    GlobalKey? surface,
  }) {
    void fit() => fitViewport(viewport, content);
    centerOn = (cell) => centerCell(cell, viewport, tile);
    recenter = fit;
    globalOfCell = (cell) {
      final box = surface?.currentContext?.findRenderObject();
      return box is RenderBox && box.attached
          ? box.localToGlobal(
              Offset((cell.x + 1) * tile.width, (cell.y + 1) * tile.height),
            )
          : null;
    };
    final changed = _viewport != viewport || _content != content;
    _viewport = viewport;
    _content = content;
    if (!changed) return;
    final fitted = _fittedTransform;
    if (positioned && fitted != null && transform.value != fitted) return;
    positioned = true;
    final generation = ++_fitGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted() &&
          generation == _fitGeneration &&
          (fitted == null || transform.value == fitted)) {
        fit();
      }
    });
  }

  void centerCell(GridPos cell, Size viewport, Size tile) {
    final scale = this.scale;
    transform.value = Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 - (cell.x + .5) * tile.width * scale,
        viewport.height / 2 - (cell.y + .5) * tile.height * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void prepareCharacterPlacement() {
    paletteTab = 'Personnages';
    brush = null;
    tile = null;
    terrain = null;
    tool = character == null ? StudioMapTool.select : StudioMapTool.character;
  }

  void reconcileResources(ProjectManifest project) {
    if (brush != null) {
      brush = project.elements
          .where((item) => item.id == brush!.id)
          .firstOrNull;
      if (brush == null &&
          (tool == StudioMapTool.place || tool == StudioMapTool.paint)) {
        tool = StudioMapTool.select;
      }
    }
    if (terrain != null) {
      terrain = project.smartTileCatalog.presets
          .where((item) => item.id == terrain!.id)
          .firstOrNull;
      if (terrain == null && tool == StudioMapTool.terrain) {
        tool = StudioMapTool.select;
      }
    }
    if (character != null) {
      character = project.characters
          .where((item) => item.id == character!.id)
          .firstOrNull;
      if (character == null && tool == StudioMapTool.character) {
        tool = StudioMapTool.select;
      }
    }
  }

  void prepareWarpPlacement() {
    paletteTab = 'Passages';
    brush = null;
    tile = null;
    terrain = null;
    character = null;
    tool = warpDestination == null ? StudioMapTool.select : StudioMapTool.warp;
  }

  String? selectedFor(String mapId, MapSelectionFamily family) {
    final target = _target;
    return target != null && target.mapId == mapId && target.family == family
        ? target.id
        : null;
  }

  bool hasSelectionIn(String mapId) => _target?.mapId == mapId;

  void select(
    EditableMapDocument document,
    MapSelectionFamily family,
    String id,
  ) {
    _target = MapSelectionTarget(
      mapId: document.current.id,
      family: family,
      id: id,
    );
    document.selectedId = family == MapSelectionFamily.decor ? id : null;
  }

  void clearSelection(EditableMapDocument document) {
    _target = null;
    pendingMove = null;
    document.selectedId = null;
  }

  void dispose() {
    _fitGeneration++;
    transform.dispose();
    for (final controller in paletteAtlasTransforms.values) {
      controller.dispose();
    }
  }
}
