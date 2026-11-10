import 'package:map_core/map_core.dart';

import 'editable_map_document.dart';
import 'map_workspace_editing_state.dart';
import 'spatial_ramp_editing_commands.dart';

class SpatialRampEditingSession {
  SpatialRampEditingSession(this.document, this.view, {this.project}) {
    load(document.current);
  }

  final EditableMapDocument document;
  final MapWorkspaceEditingState view;
  ProjectManifest? project;
  bool _disposed = false;
  MapData? source;
  SpatialRamp? ramp;
  SpatialRampEditingPreview? _ownPreview;
  String x = '', y = '', width = '', depth = '';
  String lowLevel = '0', highLevel = '1';
  SpatialRampDirection direction = SpatialRampDirection.north;
  String? surfaceInstanceId;
  String? error;
  String? notice;

  bool get enabled => !_disposed && !document.saving && ramp != null;

  List<SpatialModelInstance> get surfaceChoices {
    final map = document.current;
    final owned = <String>{};
    for (final layer in map.layers) {
      if (layer is EnvironmentLayer) {
        for (final area in layer.content.areas) {
          owned.addAll(area.generatedPlacementIds);
        }
      } else if (layer is BorderLayer) {
        for (final feature in layer.content.features) {
          owned.addAll(feature.generatedPlacementIds);
        }
      }
    }
    return (map.spatialScene?.instances ?? const <SpatialModelInstance>[])
        .where(
          (instance) =>
              !instance.blocksMovement &&
              !instance.id.startsWith('smt_') &&
              !owned.contains(instance.id),
        )
        .toList();
  }

  void synchronize() {
    if (_disposed || identical(source, document.current)) return;
    clearPreview(view);
    load(document.current);
    notice = 'La carte a changé. Les valeurs affichées ont été actualisées.';
  }

  void clearPreview(MapWorkspaceEditingState view) {
    if (identical(view.rampPreview, _ownPreview)) view.rampPreview = null;
    _ownPreview = null;
  }

  void load(MapData map, {String? rampId}) {
    if (_disposed) return;
    final sameMap = source?.id == map.id;
    final selectedId = rampId ?? (sameMap ? this.ramp?.id : null);
    final ramps = map.spatialScene?.navigation.ramps ?? const <SpatialRamp>[];
    source = map;
    this.ramp =
        ramps.where((ramp) => ramp.id == selectedId).firstOrNull ??
        ramps.firstOrNull;
    final ramp = this.ramp;
    if (ramp != null) {
      x = '${ramp.x}';
      y = '${ramp.z}';
      width = '${ramp.width}';
      depth = '${ramp.depth}';
      lowLevel = '${ramp.lowLevel}';
      highLevel = '${ramp.highLevel}';
      direction = ramp.direction;
      surfaceInstanceId = ramp.surfaceInstanceId;
    }
    error = null;
    notice = null;
  }

  void edit(void Function() change) {
    if (_disposed) return;
    clearPreview(view);
    error = null;
    notice = null;
    change();
  }

  double _number(String value, String label) {
    final number = double.tryParse(value.trim().replaceAll(',', '.'));
    if (number == null || !number.isFinite) {
      throw StateError('$label doit être un nombre fini, par exemple 1,25.');
    }
    return number;
  }

  void preview() {
    if (_disposed) return;
    clearPreview(view);
    try {
      if (!identical(source, document.current)) {
        throw StateError('La carte a changé. Choisissez à nouveau la pente.');
      }
      final ramp = this.ramp!;
      final preview = SpatialRampEditingCommands(document, project: project)
          .preview(
            ramp.copyWith(
              x: _number(x, 'X'),
              z: _number(y, 'Y'),
              width: _number(width, 'La largeur'),
              depth: _number(depth, 'La profondeur'),
              lowLevel: _number(lowLevel, 'Le niveau bas'),
              highLevel: _number(highLevel, 'Le niveau haut'),
              direction: direction,
              surfaceInstanceId: surfaceInstanceId,
            ),
          );
      _ownPreview = preview;
      view.rampPreview = preview;
      error = null;
      notice = null;
    } on Object catch (failure) {
      error = spatialRampEditingFailureMessage(failure);
    }
  }

  void apply() {
    if (_disposed) return;
    final preview = _ownPreview;
    if (preview == null) return;
    if (!identical(view.rampPreview, preview)) {
      error = 'L’aperçu a changé. Préparez un nouvel aperçu de la pente.';
      return;
    }
    try {
      SpatialRampEditingCommands(document, project: project).apply(preview);
      clearPreview(view);
      load(document.current);
      notice = 'Pente appliquée. Une seule annulation restaure la carte.';
    } on Object catch (failure) {
      clearPreview(view);
      error = spatialRampEditingFailureMessage(failure);
    }
  }

  void updateProject(ProjectManifest? value) {
    if (_disposed || identical(project, value)) return;
    project = value;
    clearPreview(view);
  }

  void dispose() {
    _disposed = true;
    clearPreview(view);
  }
}
