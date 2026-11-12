import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/map_effect_editing.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/spatial_visual_editing.dart';

const mapBuilderAmbianceRubrics = {'dayNight', 'weather', 'effects'};

class MapBuilderAmbianceBinding {
  MapBuilderAmbianceBinding({required this.maps, required this.changed});

  final MapWorkspaceController maps;
  final void Function() changed;
  bool shown = false;
  String rubric = 'dayNight';
  MapEffect effect = MapEffect.halos;
  ProjectVisualsController? _visuals;

  bool get spatial => maps.active?.current.spatialScene != null;

  ProjectVisualsController? get visuals => _visuals;

  SpatialVisualPatch get inherited => maps.inheritedVisualProfile;

  SpatialVisualEditing? get editing {
    final owner = _visuals;
    if (owner == null || owner.saved == null) return null;
    return SpatialVisualEditing(
      patch: owner.preview.value,
      inherited: inherited,
      onChanged: owner.edit,
    );
  }

  bool get loading => _visuals != null && _visuals!.saved == null;

  String? get error => _visuals?.error;

  bool get canUndo => _visuals?.canUndo ?? false;

  bool get canRedo => _visuals?.canRedo ?? false;

  void undo() => _visuals?.undo();

  void redo() => _visuals?.redo();

  void beginGesture() => _visuals?.beginGesture();

  void endGesture() => _visuals?.endGesture();

  void openRubric(String id) {
    if (!mapBuilderAmbianceRubrics.contains(id)) return;
    rubric = id;
    changed();
  }

  void openEffect(MapEffect value) {
    effect = value;
    changed();
  }

  void reconcile() {
    final document = maps.active;
    final next = shown && document != null && spatial
        ? maps.weatherDraftFor(document)
        : null;
    if (identical(next, _visuals)) return;
    _visuals?.removeListener(changed);
    _visuals = next;
    _visuals?.addListener(changed);
  }

  void dispose() {
    _visuals?.removeListener(changed);
    _visuals = null;
  }
}
