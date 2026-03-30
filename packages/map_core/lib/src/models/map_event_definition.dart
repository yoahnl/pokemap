import 'package:freezed_annotation/freezed_annotation.dart';

import 'script_conditions.dart';

part 'map_event_definition.freezed.dart';
part 'map_event_definition.g.dart';

/// Définition d'un événement de map à pages conditionnelles.
///
/// Inspiré du système RPG classique mais adapté à notre architecture.
///
/// Un événement peut avoir plusieurs pages.
/// La page active est déterminée par les conditions et l'état de partie.
///
/// Cas d'usage :
/// - PNJ qui change de dialogue selon la progression
/// - Objet ramassable qui disparaît après collecte
/// - Acteur qui devient visible/invisible selon un flag
/// - Porte qui s'ouvre après un événement
@freezed
class MapEventDefinition with _$MapEventDefinition {
  @JsonSerializable(explicitToJson: true)
  const factory MapEventDefinition({
    /// Identifiant unique de l'événement.
    required String id,

    /// Titre optionnel (pour l'éditeur / debug).
    @Default('') String title,

    /// Pages de l'événement.
    /// La première page valide (dans l'ordre) est active.
    required List<MapEventPage> pages,

    /// Position de l'événement sur la map.
    required EventPosition position,

    /// Type d'événement (détermine le rendu / comportement).
    @Default(MapEventType.actor) MapEventType type,

    /// Métadonnées.
    @Default({}) Map<String, String> metadata,
  }) = _MapEventDefinition;

  factory MapEventDefinition.fromJson(Map<String, dynamic> json) =>
      _$MapEventDefinitionFromJson(json);
}

/// Position d'un événement sur la map.
@freezed
class EventPosition with _$EventPosition {
  const factory EventPosition({
    /// Layer ID où placer l'événement.
    required String layerId,

    /// Coordonnée X.
    required int x,

    /// Coordonnée Y.
    required int y,
  }) = _EventPosition;

  factory EventPosition.fromJson(Map<String, dynamic> json) =>
      _$EventPositionFromJson(json);
}

/// Types d'événements.
enum MapEventType {
  /// Acteur / PNJ (sprite + interactions).
  @JsonValue('actor')
  actor,

  /// Objet interactif (item, panneau, etc.).
  @JsonValue('object')
  object,

  /// Zone déclencheuse (tapis, porte, etc.).
  @JsonValue('triggerZone')
  triggerZone,

  /// Effet visuel / sonore.
  @JsonValue('effect')
  effect,
}

/// Page d'un événement.
///
/// Une page contient :
/// - des conditions (si toutes true, la page est candidate)
/// - une référence à un script à exécuter
/// - des propriétés visuelles (optionnel)
///
/// Les pages sont évaluées dans l'ordre.
/// La première page valide est active.
@freezed
class MapEventPage with _$MapEventPage {
  @JsonSerializable(explicitToJson: true)
  const factory MapEventPage({
    /// Numéro de page (0-based, pour référence).
    required int pageNumber,

    /// Conditions pour que cette page soit active.
    /// Si null ou vide, la page est toujours active (fallback).
    ScriptCondition? condition,

    /// Référence au script à exécuter lors de l'interaction.
    ScriptRef? script,

    /// ID du sprite / visuel.
    String? spriteId,

    /// Message à afficher (alternative simple au script).
    String? message,

    /// Si true, l'événement est invisible mais toujours interactif.
    @Default(false) bool isHidden,

    /// Si true, l'événement est désactivé (pas d'interaction).
    @Default(false) bool isDisabled,

    /// Métadonnées.
    @Default({}) Map<String, String> metadata,
  }) = _MapEventPage;

  factory MapEventPage.fromJson(Map<String, dynamic> json) =>
      _$MapEventPageFromJson(json);
}

/// Référence à un script.
@freezed
class ScriptRef with _$ScriptRef {
  @JsonSerializable(explicitToJson: true)
  const factory ScriptRef({
    /// ID du script asset.
    required String scriptId,

    /// Noeud de démarrage.
    /// Si null, utilise le defaultStartNode du script.
    String? startNode,
  }) = _ScriptRef;

  factory ScriptRef.fromJson(Map<String, dynamic> json) =>
      _$ScriptRefFromJson(json);
}

/// Résultat de la résolution de page active.
@freezed
class ActiveEventPage with _$ActiveEventPage {
  const factory ActiveEventPage({
    /// ID de l'événement.
    required String eventId,

    /// Page active.
    required MapEventPage page,

    /// Index de la page dans la liste.
    required int pageIndex,
  }) = _ActiveEventPage;

  factory ActiveEventPage.fromJson(Map<String, dynamic> json) =>
      _$ActiveEventPageFromJson(json);
}
