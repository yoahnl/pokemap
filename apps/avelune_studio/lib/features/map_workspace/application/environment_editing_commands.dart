import 'dart:math' as math;
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core_domain.dart';
import 'editable_map_document.dart';
import 'map_editing_commands.dart';

enum EnvironmentPaintTool { brush, rectangle, erase }

String environmentEditingMessage(Object failure) {
  if (failure is StateError) return failure.message;
  if ('$failure'.contains('environment.region_too_large')) {
    return 'Cette zone est trop grande pour un aperçu unique. Réduisez-la : la limite inclut la marge de raccordement.';
  }
  return 'La zone ne peut pas être modifiée : $failure';
}

class MapEnvironmentSession {
  MapEnvironmentSession({required this.layerId, required this.areaId});
  final String layerId, areaId;
  EnvironmentPaintTool tool = EnvironmentPaintTool.brush;
  EnvironmentGenerationPreview? generation;
  MapData? previewSource, previewResult;
  ProjectManifest? previewProject;

  void clearPreview() {
    generation = null;
    previewSource = null;
    previewResult = null;
    previewProject = null;
  }
}

class EnvironmentEditingCommands {
  EnvironmentEditingCommands(this.document, this.project);
  final EditableMapDocument document;
  final ProjectManifest project;
  static int _identity = 0;
  static const _actions = EnvironmentEditing();

  List<({EnvironmentLayer layer, EnvironmentArea area})> get areas => [
    for (final layer in document.current.layers.whereType<EnvironmentLayer>())
      for (final area in layer.content.areas) (layer: layer, area: area),
  ];

  EnvironmentArea? area(MapEnvironmentSession session) => areas
      .where(
        (entry) =>
            entry.layer.id == session.layerId &&
            entry.area.id == session.areaId,
      )
      .firstOrNull
      ?.area;

  MapEnvironmentSession create(EnvironmentPreset preset) {
    var map = document.current;
    final support = MapEditingCommands(document, project).supportLayer(map);
    if (!map.layers.any((layer) => layer.id == support.id)) {
      map = map.copyWith(layers: [...map.layers, support]);
    }
    var layer = map.layers
        .whereType<EnvironmentLayer>()
        .where((layer) => layer.content.targetTileLayerId == support.id)
        .firstOrNull;
    if (layer == null) {
      final id =
          'environment-layer-${DateTime.now().microsecondsSinceEpoch}-${_identity++}';
      map = addMapLayer(
        map,
        kind: MapLayerKind.environment,
        id: id,
        name: 'Environnements',
      );
      map = _actions.attachToTileLayer(
        map,
        layerId: id,
        targetTileLayerId: support.id,
      );
      layer = map.layers.whereType<EnvironmentLayer>().firstWhere(
        (layer) => layer.id == id,
      );
    }
    final id =
        'environment-area-${DateTime.now().microsecondsSinceEpoch}-${_identity++}';
    map = _actions.createArea(
      map,
      manifest: project,
      layerId: layer.id,
      areaId: id,
      name: preset.name,
      presetId: preset.id,
      seed: _identity,
    );
    document.commit(map);
    return MapEnvironmentSession(layerId: layer.id, areaId: id);
  }

  void paint(
    MapEnvironmentSession session,
    Iterable<GridPos> cells, {
    required bool erase,
  }) {
    document.commit(
      _actions.paintCells(
        document.current,
        layerId: session.layerId,
        areaId: session.areaId,
        cells: cells.toSet(),
        value: !erase,
      ),
    );
    session.clearPreview();
  }

  void paintRectangle(
    MapEnvironmentSession session,
    GridPos start,
    GridPos end,
  ) {
    final size = document.current.size;
    final x = math.min(start.x, end.x).clamp(0, size.width - 1);
    final y = math.min(start.y, end.y).clamp(0, size.height - 1);
    final right = math.max(start.x, end.x).clamp(0, size.width - 1);
    final bottom = math.max(start.y, end.y).clamp(0, size.height - 1);
    document.commit(
      _actions.paintRegion(
        document.current,
        layerId: session.layerId,
        areaId: session.areaId,
        region: EnvironmentGenerationRegion(
          x: x,
          y: y,
          width: right - x + 1,
          height: bottom - y + 1,
        ),
        value: true,
      ),
    );
    session.clearPreview();
  }

  void changeSeed(MapEnvironmentSession session) {
    final current = area(session);
    if (current == null) throw StateError('Cette zone n’existe plus.');
    document.commit(
      _actions.setSeed(
        document.current,
        layerId: session.layerId,
        areaId: session.areaId,
        seed: current.seed + 1,
      ),
    );
    session.clearPreview();
  }

  void delete(MapEnvironmentSession session) {
    document.commit(
      _actions.deleteArea(
        document.current,
        layerId: session.layerId,
        areaId: session.areaId,
      ),
    );
    session.clearPreview();
  }

  String _revision(MapData map) =>
      '${document.base.revision}:${identityHashCode(map)}:${identityHashCode(project)}';

  void preview(MapEnvironmentSession session) {
    final map = document.current;
    final current = area(session);
    if (current == null) throw StateError('Cette zone n’existe plus.');
    final cells = <GridPos>[
      for (var y = 0; y < current.mask.height; y++)
        for (var x = 0; x < current.mask.width; x++)
          if (current.mask.isActiveAt(x, y)) GridPos(x: x, y: y),
      for (final placement in map.placedElements)
        if (current.generatedPlacementIds.contains(placement.id)) placement.pos,
    ];
    if (cells.isEmpty) {
      throw StateError('Dessinez une zone avant de préparer l’aperçu.');
    }
    final x = cells.map((cell) => cell.x).reduce(math.min);
    final y = cells.map((cell) => cell.y).reduce(math.min);
    final right = cells.map((cell) => cell.x).reduce(math.max);
    final bottom = cells.map((cell) => cell.y).reduce(math.max);
    final revision = _revision(map);
    final generation = _actions.previewGeneration(
      manifest: project,
      map: map,
      layerId: session.layerId,
      areaId: session.areaId,
      projectRevision: revision,
      region: EnvironmentGenerationRegion(
        x: x,
        y: y,
        width: right - x + 1,
        height: bottom - y + 1,
      ),
    );
    final result = _actions.applyGeneration(
      manifest: project,
      map: map,
      preview: generation,
      currentRevision: revision,
    );
    session.previewSource = map;
    session.previewProject = project;
    session.generation = generation;
    session.previewResult = result;
  }

  void apply(MapEnvironmentSession session) {
    final generation = session.generation;
    if (generation == null ||
        !identical(session.previewSource, document.current) ||
        !identical(session.previewProject, project)) {
      session.clearPreview();
      throw StateError(
        'L’aperçu a changé. Préparez-le à nouveau avant d’appliquer.',
      );
    }
    document.commit(
      _actions.applyGeneration(
        manifest: project,
        map: document.current,
        preview: generation,
        currentRevision: _revision(document.current),
      ),
    );
    session.clearPreview();
  }
}
