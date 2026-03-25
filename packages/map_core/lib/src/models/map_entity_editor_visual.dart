import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_entity_editor_visual.freezed.dart';
part 'map_entity_editor_visual.g.dart';

@freezed
class MapEntityEditorVisual with _$MapEntityEditorVisual {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntityEditorVisual({
    required String elementId,
  }) = _MapEntityEditorVisual;

  factory MapEntityEditorVisual.fromJson(Map<String, dynamic> json) =>
      _$MapEntityEditorVisualFromJson(json);
}
