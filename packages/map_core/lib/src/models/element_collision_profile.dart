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

    /// Masque **visuel** : pixels où le sprite est matière affichée (alpha au-dessus du seuil).
    ///
    /// Sert à l’éditeur (aperçu, légende) et à l’auto-génération ; **ne bloque pas**
    /// le déplacement par lui-même. Peut être absent : l’éditeur peut retomber sur
    /// la lecture directe du PNG.
    ElementCollisionPixelMask? visualMask,

    /// **Collision gameplay** : pixels qui **bloquent** joueur / PNJ (bitmap monde).
    ///
    /// Clé JSON historique : `pixelMask` (compatibilité). Ne doit **pas** être une
    /// simple copie du visuel : ombres / décoration haute peuvent être exclues par
    /// l’auto-génération ou l’édition manuelle.
    @JsonKey(name: 'pixelMask') ElementCollisionPixelMask? collisionMask,

    /// **Occlusion / couverture** : pixels du sprite qui peuvent **recouvrir** un
    /// personnage lorsqu’il passe « derrière » (toit, feuillage, etc.).
    ///
    /// Le runtime l’utilise pour le **rendu** (profondeur), pas pour le blocage.
    /// Indépendant de [collisionMask].
    ElementCollisionPixelMask? occlusionMask,

    @Default(WarpTriggerPadding()) WarpTriggerPadding padding,

    /// **Legacy JSON uniquement** : migration / outillage / inspection.
    ///
    /// Ne pas lire cette liste dans [map_gameplay] pour la collision active.
    @Default([]) List<GridPos> cells,
  }) = _ElementCollisionProfile;

  factory ElementCollisionProfile.fromJson(Map<String, dynamic> json) =>
      _$ElementCollisionProfileFromJson(json);
}
