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

    /// **Source de vérité** pour la collision runtime des éléments (décodée en bitmap monde).
    ///
    /// Le gameplay **n’utilise pas** [cells] pour résoudre les collisions : seul
    /// ce masque (ou une migration explicite depuis [cells]) alimente le moteur.
    ElementCollisionPixelMask? pixelMask,

    @Default(WarpTriggerPadding()) WarpTriggerPadding padding,

    /// **Legacy JSON uniquement** : migration / outillage / inspection.
    ///
    /// Ne pas lire cette liste dans [map_gameplay] pour la collision active.
    @Default([]) List<GridPos> cells,
  }) = _ElementCollisionProfile;

  factory ElementCollisionProfile.fromJson(Map<String, dynamic> json) =>
      _$ElementCollisionProfileFromJson(json);
}
