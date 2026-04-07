import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'geometry.dart';
import 'map_data.dart';

part 'element_collision_profile.freezed.dart';
part 'element_collision_profile.g.dart';

/// Masque collision pixel-level sérialisé.
///
/// Ce modèle est la nouvelle source de vérité métier pour la collision décor :
/// - dimensions en pixels du masque;
/// - encodage compact (`packed_bits_v1`);
/// - payload base64.
///
/// Le masque reste local à l'élément (repère frame source).
@freezed
class ElementCollisionPixelMask with _$ElementCollisionPixelMask {
  @JsonSerializable(explicitToJson: true)
  const factory ElementCollisionPixelMask({
    required int widthPx,
    required int heightPx,
    @Default(ElementCollisionMaskEncoding.packedBitsV1)
    ElementCollisionMaskEncoding encoding,
    @Default('') String dataBase64,
  }) = _ElementCollisionPixelMask;

  factory ElementCollisionPixelMask.fromJson(Map<String, dynamic> json) =>
      _$ElementCollisionPixelMaskFromJson(json);
}

@freezed
class ElementCollisionProfile with _$ElementCollisionProfile {
  @JsonSerializable(explicitToJson: true)
  const factory ElementCollisionProfile({
    @Default(ElementCollisionProfileSource.generated)
    ElementCollisionProfileSource source,

    /// Optionnel: masque pixel-level (nouvelle source de vérité).
    ///
    /// Stratégie de compatibilité:
    /// - si présent, le runtime peut en dériver les cellules cache;
    /// - sinon, on utilise la liste `cells` legacy.
    ElementCollisionPixelMask? pixelMask,

    @Default(WarpTriggerPadding()) WarpTriggerPadding padding,

    /// Format legacy basé sur cellules.
    ///
    /// Conservé pour compatibilité JSON/projets existants et pour debug.
    @Default([]) List<GridPos> cells,
  }) = _ElementCollisionProfile;

  factory ElementCollisionProfile.fromJson(Map<String, dynamic> json) =>
      _$ElementCollisionProfileFromJson(json);
}
