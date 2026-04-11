// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_entity_editor_visual.freezed.dart';
part 'map_entity_editor_visual.g.dart';

@freezed
class MapEntityEditorVisual with _$MapEntityEditorVisual {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntityEditorVisual({
    required String elementId,

    /// Force le rendu de cette entité "élément projet" au-dessus du décor
    /// avant-plan.
    ///
    /// Cas visé :
    /// - petits props décoratifs représentés comme entités (ex. Poké Ball
    ///   posée sur une table) ;
    /// - besoin de garder un objet volontairement visible au-dessus d'un
    ///   overlay de tiles qui masquerait sinon l'entité.
    ///
    /// Non-objectif :
    /// - ce n'est pas un système générique de z-index ;
    /// - ce flag n'a pas vocation à remplacer le tri "par les pieds" des
    ///   vrais acteurs gameplay ;
    /// - il sert seulement à faire passer l'entité dans la passe foreground
    ///   quand elle est rendue comme ProjectElementEntry.
    @Default(false) bool renderInForeground,
  }) = _MapEntityEditorVisual;

  factory MapEntityEditorVisual.fromJson(Map<String, dynamic> json) =>
      _$MapEntityEditorVisualFromJson(json);
}
