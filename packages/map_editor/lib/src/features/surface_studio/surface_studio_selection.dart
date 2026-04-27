// État de sélection **UI local** Surface Studio (Lot 58).
//
// Aucun Flutter, aucun map_core, aucun JSON, aucune persistance : value object
// pur pour le panneau. Ne décrit pas le catalogue — ne le mutera jamais.

/// Rôle d’une entrée sélectionnée dans le browser Surface Studio.
enum SurfaceStudioSelectionKind {
  atlas,
  animation,
  preset,
}

/// Sélection auteur côté éditeur (inspection / futur inspector), jamais persistée.
class SurfaceStudioSelection {
  const SurfaceStudioSelection._(this._kind, this._id);

  final SurfaceStudioSelectionKind? _kind;
  final String? _id;

  /// Aucun atlas / animation / preset mis en surbrillance.
  const SurfaceStudioSelection.none()
      : _kind = null,
        _id = null;

  /// [id] rejeté si vide ou uniquement des espaces (après trim).
  factory SurfaceStudioSelection.atlas(String id) {
    final t = id.trim();
    if (t.isEmpty) {
      throw ArgumentError.value(id, 'id', 'atlas id must be non-empty');
    }
    return SurfaceStudioSelection._(SurfaceStudioSelectionKind.atlas, t);
  }

  factory SurfaceStudioSelection.animation(String id) {
    final t = id.trim();
    if (t.isEmpty) {
      throw ArgumentError.value(id, 'id', 'animation id must be non-empty');
    }
    return SurfaceStudioSelection._(SurfaceStudioSelectionKind.animation, t);
  }

  factory SurfaceStudioSelection.preset(String id) {
    final t = id.trim();
    if (t.isEmpty) {
      throw ArgumentError.value(id, 'id', 'preset id must be non-empty');
    }
    return SurfaceStudioSelection._(SurfaceStudioSelectionKind.preset, t);
  }

  SurfaceStudioSelectionKind? get kind => _kind;

  String? get id => _id;

  bool get isNone => _kind == null;

  bool get isAtlas => _kind == SurfaceStudioSelectionKind.atlas;

  bool get isAnimation => _kind == SurfaceStudioSelectionKind.animation;

  bool get isPreset => _kind == SurfaceStudioSelectionKind.preset;

  bool matchesAtlas(String id) => isAtlas && _id == id.trim();

  bool matchesAnimation(String id) => isAnimation && _id == id.trim();

  bool matchesPreset(String id) => isPreset && _id == id.trim();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioSelection &&
          _kind == other._kind &&
          _id == other._id;

  @override
  int get hashCode => Object.hash(_kind, _id);
}
