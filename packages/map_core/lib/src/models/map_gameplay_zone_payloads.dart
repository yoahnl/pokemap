import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'map_gameplay_zone_payloads.freezed.dart';
part 'map_gameplay_zone_payloads.g.dart';

// ---------------------------------------------------------------------------
// Payloads typés par kind de zone gameplay
// ---------------------------------------------------------------------------

/// Payload d'une zone [GameplayZoneKind.encounter].
/// Lie la zone à une [ProjectEncounterTable] et précise le type de rencontre.
@freezed
class EncounterZonePayload with _$EncounterZonePayload {
  @JsonSerializable(explicitToJson: true)
  const factory EncounterZonePayload({
    /// ID de la [ProjectEncounterTable] du projet (optionnel — zone sans table = inerte).
    String? encounterTableId,

    /// Type de rencontre déclenchée dans cette zone.
    @Default(EncounterKind.walk) EncounterKind encounterKind,

    /// Image de fond de combat authorée explicitement pour cette zone.
    ///
    /// Le chemin reste project-local et optionnel :
    /// - aucune bibliothèque média globale n'est introduite ici ;
    /// - le runtime pourra l'utiliser comme override visuel du fond contextuel ;
    /// - l'absence de valeur garde le comportement contextuel existant.
    String? battleBackgroundRelativePath,
  }) = _EncounterZonePayload;

  factory EncounterZonePayload.fromJson(Map<String, dynamic> json) =>
      _$EncounterZonePayloadFromJson(json);
}

/// Payload d'une zone [GameplayZoneKind.movement].
/// Contrainte ou mode de déplacement requis/appliqué dans la zone.
///
/// Les effets de surface comme la glissade ou le coût de déplacement restent
/// séparés dans [MovementEffectZonePayload] pour éviter de transformer ce
/// payload de gate en fourre-tout.
@freezed
class MovementZonePayload with _$MovementZonePayload {
  @JsonSerializable(explicitToJson: true)
  const factory MovementZonePayload({
    /// Mode de déplacement requis pour traverser la zone.
    @Default(MovementMode.walk) MovementMode requiredMode,

    /// Modes supplémentaires autorisés en plus de [requiredMode].
    @Default([]) List<MovementMode> allowedModes,
  }) = _MovementZonePayload;

  factory MovementZonePayload.fromJson(Map<String, dynamic> json) =>
      _$MovementZonePayloadFromJson(json);
}

/// Payload d'une zone [GameplayZoneKind.movementEffect].
///
/// Le payload décrit une source persistante typée. `map_gameplay` décidera
/// plus tard comment la transformer en `GameplayMovementEffect`.
@freezed
class MovementEffectZonePayload with _$MovementEffectZonePayload {
  @JsonSerializable(explicitToJson: true)
  const factory MovementEffectZonePayload({
    @Default(MovementEffectZoneKind.slide) MovementEffectZoneKind effectKind,

    /// Coût entier positif pour [MovementEffectZoneKind.movementCost].
    ///
    /// Pour [MovementEffectZoneKind.slide], la valeur est conservée par défaut
    /// pour garder un JSON stable, mais elle n'est pas consommée.
    @Default(1) int movementCost,
  }) = _MovementEffectZonePayload;

  factory MovementEffectZonePayload.fromJson(Map<String, dynamic> json) =>
      _$MovementEffectZonePayloadFromJson(json);
}

/// Payload d'une zone [GameplayZoneKind.hazard].
/// Définit le type de danger et son effet sur le personnage.
@freezed
class HazardZonePayload with _$HazardZonePayload {
  @JsonSerializable(explicitToJson: true)
  const factory HazardZonePayload({
    @Default(HazardKind.other) HazardKind hazardKind,

    /// Dommages infligés à chaque pas dans la zone (0 = aucun dommage direct).
    @Default(0) int damagePerStep,
  }) = _HazardZonePayload;

  factory HazardZonePayload.fromJson(Map<String, dynamic> json) =>
      _$HazardZonePayloadFromJson(json);
}

/// Payload d'une zone [GameplayZoneKind.special] (et `custom`).
/// Données libres pour les comportements scriptés ou les extensions.
@freezed
class SpecialZonePayload with _$SpecialZonePayload {
  @JsonSerializable(explicitToJson: true)
  const factory SpecialZonePayload({
    /// Clé de script rattachée à cette zone (ex. identifiant Yarn / EventGraph).
    String? scriptKey,

    /// Propriétés libres (clé → valeur).
    @Default({}) Map<String, String> properties,
  }) = _SpecialZonePayload;

  factory SpecialZonePayload.fromJson(Map<String, dynamic> json) =>
      _$SpecialZonePayloadFromJson(json);
}

// ---------------------------------------------------------------------------
// Migration JSON legacy → format typé
// ---------------------------------------------------------------------------

/// Migre un objet JSON [MapGameplayZone] depuis l'ancien format à plat
/// vers le nouveau format à payloads typés.
///
/// Transformations appliquées :
/// - `kind == 'transition'` → `'special'`
/// - champ plat `encounterTableId` → `encounter.encounterTableId`
/// - champ plat `movementMode`    → `movement.requiredMode`
/// - champ plat `properties`      → `special.properties`
Map<String, dynamic> migrateMapGameplayZoneJson(Map<String, dynamic> json) {
  final out = Map<String, dynamic>.from(json);

  // transition n'existe plus → special
  if (out['kind'] == 'transition') {
    out['kind'] = 'special';
  }

  // encounterTableId plat → encounter payload
  final rawEncounterTableId = out.remove('encounterTableId');
  if (rawEncounterTableId is String && rawEncounterTableId.trim().isNotEmpty) {
    if (out['encounter'] == null) {
      out['encounter'] = <String, dynamic>{
        'encounterTableId': rawEncounterTableId,
        'encounterKind': 'walk',
      };
    }
  }

  // movementMode plat → movement payload
  final rawMovementMode = out.remove('movementMode');
  if (rawMovementMode is String && rawMovementMode.trim().isNotEmpty) {
    if (out['movement'] == null) {
      out['movement'] = <String, dynamic>{
        'requiredMode': rawMovementMode,
      };
    }
  }

  // properties plat → special.properties
  final rawProperties = out.remove('properties');
  if (rawProperties is Map && rawProperties.isNotEmpty) {
    final existing = out['special'] as Map<String, dynamic>?;
    if (existing == null) {
      out['special'] = <String, dynamic>{
        'properties': rawProperties,
      };
    } else {
      out['special'] = <String, dynamic>{
        ...existing,
        'properties': rawProperties,
      };
    }
  }

  return out;
}
