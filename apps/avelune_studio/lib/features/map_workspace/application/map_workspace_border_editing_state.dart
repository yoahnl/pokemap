part of 'map_workspace_editing_state.dart';

extension MapWorkspaceBorderEditingState on MapWorkspaceEditingState {
  void failBorderDraft(
    MapBorderDrawingDraft draft,
    EditableMapDocument document,
    Object error,
  ) {
    final message = error.toString();
    document.error = message;
    borderDraftFailure = (draft: draft, message: message);
  }

  void clearBorderDraftFailure(EditableMapDocument document) {
    final failure = borderDraftFailure;
    if (failure != null &&
        identical(failure.draft.sourceMap, document.current) &&
        document.error == failure.message) {
      document.error = null;
    }
    borderDraftFailure = null;
  }

  MapBorderDrawingDraft? retainedBorderDraftFor(String mapId) =>
      _retainedBorderDrafts[mapId];

  void focusBorderDraftOn(String mapId) {
    final draft = borderDraft;
    if (draft != null && draft.mapId != mapId) {
      _retainedBorderDrafts[draft.mapId] = draft;
      borderDraft = null;
      borderMovingAngle = null;
      borderDraftFailure = null;
      borderPreview = null;
    }
    if (borderDraft != null) return;
    final retained = _retainedBorderDrafts.remove(mapId);
    if (retained == null) return;
    borderDraft = retained;
    borderBlueprintId = retained.blueprintId;
  }

  void removeLastBorderAngle(EditableMapDocument document) {
    if (document.current.spatialScene != null) {
      clearBorderDraftFailure(document);
    }
    borderMovingAngle = null;
    borderDraft = borderDraft?.removeLastAngle();
  }

  void selectBorderFeature(({String layerId, String featureId})? value) {
    borderFeature = value;
    borderPreview = null;
  }

  void prepareBorderErase(({String layerId, String featureId}) value) {
    borderEditingMode = BorderStrokeEditingMode.erase;
    selectBorderFeature(value);
    tool = StudioMapTool.border;
  }

  void repairBorderSelection(MapData map) {
    final selected = borderFeature;
    if (selected == null) return;
    final layer = map.layers
        .whereType<BorderLayer>()
        .where((layer) => layer.id == selected.layerId && layer.isVisible)
        .firstOrNull;
    if (layer?.content.featureById(selected.featureId) != null) return;
    borderFeature = null;
    borderPreview = null;
    borderEditingMode = BorderStrokeEditingMode.draw;
  }
}
