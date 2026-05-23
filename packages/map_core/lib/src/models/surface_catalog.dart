import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'surface.dart';

/// Comparaison **ordonnée** de deux listes d’[ProjectSurfaceAtlas] pour
/// [ProjectSurfaceCatalog.operator ==].
bool _projectSurfaceAtlasesEqualInOrder(
  List<ProjectSurfaceAtlas> a,
  List<ProjectSurfaceAtlas> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Idem pour [ProjectSurfaceAnimation].
bool _projectSurfaceAnimationsEqualInOrder(
  List<ProjectSurfaceAnimation> a,
  List<ProjectSurfaceAnimation> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Idem pour [ProjectSurfacePreset].
bool _projectSurfacePresetsEqualInOrder(
  List<ProjectSurfacePreset> a,
  List<ProjectSurfacePreset> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

void _rejectDuplicateIds<T>(
  List<T> items,
  String Function(T) idOf,
  String message,
) {
  final seen = <String>{};
  for (final item in items) {
    if (!seen.add(idOf(item))) {
      throw ValidationException(message);
    }
  }
}

/// Catalogue auteur **Surface** en **mémoire uniquement** : regroupe des
/// [ProjectSurfaceAtlas], [ProjectSurfaceAnimation] et [ProjectSurfacePreset]
/// pour des lookups et de futurs diagnostics — **sans** persistance JSON,
/// **sans** [ProjectManifest], **sans** résolution de références.
///
/// * Les listes sont **copiées** puis exposées en **non modifiables** : une
///   mutation de la source après construction ne change **pas** le catalogue.
/// * Unicité des `id` **au sein de chaque liste** ; les **namespaces** atlas /
///   animation / preset sont **indépendants** en V0 (même chaîne `water` dans
///   les trois collections autorisée — pas de contrainte globale prématurée).
/// * Ne **revalide** pas les modèles embarqués ; ne **résout** pas les
///   `animationId` des presets vers des animations du catalogue.
@immutable
final class ProjectSurfaceCatalog {
  ProjectSurfaceCatalog({
    List<ProjectSurfaceAtlas> atlases = const [],
    List<ProjectSurfaceAnimation> animations = const [],
    List<ProjectSurfacePreset> presets = const [],
  })  : _atlases = List<ProjectSurfaceAtlas>.unmodifiable(atlases),
        _animations = List<ProjectSurfaceAnimation>.unmodifiable(animations),
        _presets = List<ProjectSurfacePreset>.unmodifiable(presets) {
    _rejectDuplicateIds<ProjectSurfaceAtlas>(
      _atlases,
      (a) => a.id,
      'ProjectSurfaceCatalog.atlases must not contain duplicate ProjectSurfaceAtlas.id',
    );
    _rejectDuplicateIds<ProjectSurfaceAnimation>(
      _animations,
      (a) => a.id,
      'ProjectSurfaceCatalog.animations must not contain duplicate ProjectSurfaceAnimation.id',
    );
    _rejectDuplicateIds<ProjectSurfacePreset>(
      _presets,
      (a) => a.id,
      'ProjectSurfaceCatalog.presets must not contain duplicate ProjectSurfacePreset.id',
    );
  }

  const ProjectSurfaceCatalog.empty()
      : _atlases = const [],
        _animations = const [],
        _presets = const [];

  final List<ProjectSurfaceAtlas> _atlases;
  final List<ProjectSurfaceAnimation> _animations;
  final List<ProjectSurfacePreset> _presets;

  /// Atlasses (ordre d’insertion, liste **non modifiable**).
  List<ProjectSurfaceAtlas> get atlases => _atlases;

  /// Animations (ordre d’insertion, liste **non modifiable**).
  List<ProjectSurfaceAnimation> get animations => _animations;

  /// Presets (ordre d’insertion, liste **non modifiable**).
  List<ProjectSurfacePreset> get presets => _presets;

  int get atlasCount => _atlases.length;

  int get animationCount => _animations.length;

  int get presetCount => _presets.length;

  /// Vrai si **les trois** listes sont vides (modèle valide hors manifest).
  bool get isEmpty =>
      _atlases.isEmpty && _animations.isEmpty && _presets.isEmpty;

  /// Inverse de [isEmpty].
  bool get isNotEmpty => !isEmpty;

  /// [ProjectSurfaceAtlas] dont [ProjectSurfaceAtlas.id] est **égale** à [id]
  /// (comparaison de chaînes, **pas** de [trim]).
  ProjectSurfaceAtlas? atlasById(String id) {
    for (final a in _atlases) {
      if (a.id == id) {
        return a;
      }
    }
    return null;
  }

  /// Idem [atlasById] pour [ProjectSurfaceAnimation.id].
  ProjectSurfaceAnimation? animationById(String id) {
    for (final a in _animations) {
      if (a.id == id) {
        return a;
      }
    }
    return null;
  }

  /// Idem [atlasById] pour [ProjectSurfacePreset.id].
  ProjectSurfacePreset? presetById(String id) {
    for (final p in _presets) {
      if (p.id == id) {
        return p;
      }
    }
    return null;
  }

  /// Délègue : [atlasById] `!= null`.
  bool containsAtlas(String id) => atlasById(id) != null;

  /// Délègue : [animationById] `!= null`.
  bool containsAnimation(String id) => animationById(id) != null;

  /// Délègue : [presetById] `!= null`.
  bool containsPreset(String id) => presetById(id) != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectSurfaceCatalog &&
          _projectSurfaceAtlasesEqualInOrder(_atlases, other._atlases) &&
          _projectSurfaceAnimationsEqualInOrder(_animations, other._animations) &&
          _projectSurfacePresetsEqualInOrder(_presets, other._presets);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(_atlases),
        Object.hashAll(_animations),
        Object.hashAll(_presets),
      );
}
