// Read models **Surface Studio** (Lot 51) : vue pure, immuable, sans UI Flutter.
//
// * Prépare l’affichage futur (compteurs, listes, diagnostics auteur) **sans**
//   persistance disque, **sans** widget, **sans** Riverpod.
// * N’impose **aucun** tri, **aucun** filtre : l’ordre de parcours est celui
//   des listes sur [`ProjectSurfaceCatalog`] (y compris si [`sortOrder`] varie
//   entre entités) — l’auteur voit l’**ordre source** tel qu’enregistré.
// * Les **diagnostics** proviennent exclusivement de l’agrégateur auteur existant
//   : [`diagnoseProjectSurfaceCatalogForAuthoring`] puis
//   [`buildSurfaceCatalogDiagnosticsPresentation`]. Les références orphelines
//   restent des **rapports d’analyse**, jamais des erreurs de **construction**
//   du read model.
// * Passe [`ProjectManifest`] via [`getProjectManifestSurfaceCatalog`] côté
//   constructeur `buildSurfaceStudioReadModel` — un seul champ `surfaceCatalog`
//   sur le manifest, pas de recomposition JSON ici.

import 'package:meta/meta.dart' show immutable;

import '../models/project_manifest.dart';
import '../models/surface.dart';
import '../models/surface_catalog.dart';
import 'project_manifest_surface_catalog_operations.dart';
import 'surface_catalog_authoring_diagnostics.dart';
import 'surface_catalog_diagnostics_presentation.dart';

// --- Comparaison de listes (ordre strict) — égalité des read models ---

bool _strListEqual(List<String> a, List<String> b) {
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

bool _roleListEqual(List<SurfaceVariantRole> a, List<SurfaceVariantRole> b) {
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

List<String> _referencedAtlasFirstAppearance(ProjectSurfaceAnimation animation) {
  final seen = <String>{};
  final out = <String>[];
  for (final frame in animation.timeline.frames) {
    final id = frame.tileRef.atlasId;
    if (seen.add(id)) {
      out.add(id);
    }
  }
  return out;
}

List<String> _usedByAnimationIdsForAtlas(
  ProjectSurfaceCatalog catalog,
  ProjectSurfaceAtlas atlas,
) {
  final out = <String>[];
  for (final anim in catalog.animations) {
    var uses = false;
    for (final frame in anim.timeline.frames) {
      if (frame.tileRef.atlasId == atlas.id) {
        uses = true;
        break;
      }
    }
    if (uses) {
      out.add(anim.id);
    }
  }
  return out;
}

List<String> _referencedAnimationIdsDeduped(SurfaceVariantAnimationRefSet refs) {
  final seen = <String>{};
  final out = <String>[];
  for (final r in refs.refs) {
    if (seen.add(r.animationId)) {
      out.add(r.animationId);
    }
  }
  return out;
}

/// Résumé numérique pour l’en-tête Surface Studio (compteurs seuls).
@immutable
final class SurfaceStudioCatalogSummaryReadModel {
  SurfaceStudioCatalogSummaryReadModel({
    required this.atlasCount,
    required this.animationCount,
    required this.presetCount,
  });

  final int atlasCount;
  final int animationCount;
  final int presetCount;

  bool get isEmpty =>
      atlasCount == 0 && animationCount == 0 && presetCount == 0;

  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioCatalogSummaryReadModel &&
          other.atlasCount == atlasCount &&
          other.animationCount == animationCount &&
          other.presetCount == presetCount;

  @override
  int get hashCode => Object.hash(atlasCount, animationCount, presetCount);
}

/// Une ligne **atlas** : instance source + animations qui s’y référencent
/// (ordre des ids = ordre des animations dans le catalogue, sans doublon).
@immutable
final class SurfaceStudioAtlasReadModel {
  SurfaceStudioAtlasReadModel({
    required this.atlas,
    required List<String> usedByAnimationIds,
  }) : usedByAnimationIds = List<String>.unmodifiable(usedByAnimationIds);

  final ProjectSurfaceAtlas atlas;
  final List<String> usedByAnimationIds;

  String get id => atlas.id;
  String get name => atlas.name;
  String get tilesetId => atlas.tilesetId;
  String? get categoryId => atlas.categoryId;
  int get sortOrder => atlas.sortOrder;
  SurfaceAtlasGeometry get geometry => atlas.geometry;
  SurfaceAtlasLayout get layout => atlas.geometry.layout;
  int get tileWidth => atlas.geometry.tileSize.width;
  int get tileHeight => atlas.geometry.tileSize.height;
  int get columns => atlas.geometry.gridSize.columns;
  int get rows => atlas.geometry.gridSize.rows;
  int get tileCount => atlas.geometry.tileCount;
  bool get isUsedByAnimation => usedByAnimationIds.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioAtlasReadModel &&
          other.atlas == atlas &&
          _strListEqual(other.usedByAnimationIds, usedByAnimationIds);

  @override
  int get hashCode => Object.hash(atlas, Object.hashAll(usedByAnimationIds));
}

/// Une ligne **animation** : instance source + atlasId des frames
/// (première apparition, sans doublon).
@immutable
final class SurfaceStudioAnimationReadModel {
  SurfaceStudioAnimationReadModel({
    required this.animation,
    required List<String> referencedAtlasIds,
  }) : referencedAtlasIds = List<String>.unmodifiable(referencedAtlasIds);

  final ProjectSurfaceAnimation animation;
  final List<String> referencedAtlasIds;

  String get id => animation.id;
  String get name => animation.name;
  String? get syncGroupId => animation.syncGroupId;
  String? get categoryId => animation.categoryId;
  int get sortOrder => animation.sortOrder;
  int get frameCount => animation.frameCount;
  int get totalDurationMs => animation.totalDurationMs;
  bool get hasFrames => animation.frameCount > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioAnimationReadModel &&
          other.animation == animation &&
          _strListEqual(other.referencedAtlasIds, referencedAtlasIds);

  @override
  int get hashCode => Object.hash(animation, Object.hashAll(referencedAtlasIds));
}

/// Une ligne **preset** : instance source, rôles (ordre des refs) et
/// `animationId` uniques (ordre de première apparition).
@immutable
final class SurfaceStudioPresetReadModel {
  SurfaceStudioPresetReadModel({
    required this.preset,
    required List<SurfaceVariantRole> roles,
    required List<String> referencedAnimationIds,
  })  : roles = List<SurfaceVariantRole>.unmodifiable(roles),
        referencedAnimationIds = List<String>.unmodifiable(
          referencedAnimationIds,
        );

  final ProjectSurfacePreset preset;
  final List<SurfaceVariantRole> roles;
  final List<String> referencedAnimationIds;

  String get id => preset.id;
  String get name => preset.name;
  String? get categoryId => preset.categoryId;
  int get sortOrder => preset.sortOrder;
  int get variantCount => preset.variantCount;
  bool get coversStandardRoles =>
      preset.coversAllRoles(standardSurfaceVariantRoleOrder);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioPresetReadModel &&
          other.preset == preset &&
          _roleListEqual(other.roles, roles) &&
          _strListEqual(other.referencedAnimationIds, referencedAnimationIds);

  @override
  int get hashCode => Object.hash(
        preset,
        Object.hashAll(roles),
        Object.hashAll(referencedAnimationIds),
      );
}

/// Vue read-only complète d’un [ProjectSurfaceCatalog] + diagnostics auteur.
@immutable
final class SurfaceStudioReadModel {
  SurfaceStudioReadModel({
    required this.catalog,
    required this.summary,
    required List<SurfaceStudioAtlasReadModel> atlases,
    required List<SurfaceStudioAnimationReadModel> animations,
    required List<SurfaceStudioPresetReadModel> presets,
    required this.diagnostics,
  })  : atlases = List<SurfaceStudioAtlasReadModel>.unmodifiable(atlases),
        animations =
            List<SurfaceStudioAnimationReadModel>.unmodifiable(animations),
        presets = List<SurfaceStudioPresetReadModel>.unmodifiable(presets);

  final ProjectSurfaceCatalog catalog;
  final SurfaceStudioCatalogSummaryReadModel summary;
  final List<SurfaceStudioAtlasReadModel> atlases;
  final List<SurfaceStudioAnimationReadModel> animations;
  final List<SurfaceStudioPresetReadModel> presets;
  final SurfaceCatalogDiagnosticsPresentation diagnostics;

  bool get isEmpty => summary.isEmpty;
  bool get isNotEmpty => summary.isNotEmpty;
  bool get hasDiagnostics => diagnostics.hasDiagnostics;
  bool get hasErrors => diagnostics.hasErrors;
  bool get hasWarnings => diagnostics.hasWarnings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioReadModel &&
          other.catalog == catalog &&
          other.summary == summary &&
          _atlasReadListEqual(other.atlases, atlases) &&
          _animReadListEqual(other.animations, animations) &&
          _presetReadListEqual(other.presets, presets) &&
          other.diagnostics == diagnostics;

  @override
  int get hashCode => Object.hash(
        catalog,
        summary,
        Object.hashAll(atlases),
        Object.hashAll(animations),
        Object.hashAll(presets),
        diagnostics,
      );
}

bool _atlasReadListEqual(
  List<SurfaceStudioAtlasReadModel> a,
  List<SurfaceStudioAtlasReadModel> b,
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

bool _animReadListEqual(
  List<SurfaceStudioAnimationReadModel> a,
  List<SurfaceStudioAnimationReadModel> b,
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

bool _presetReadListEqual(
  List<SurfaceStudioPresetReadModel> a,
  List<SurfaceStudioPresetReadModel> b,
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

/// Construit un [SurfaceStudioReadModel] via [`getProjectManifestSurfaceCatalog`]
/// (aucune mutation du [manifest]).
SurfaceStudioReadModel buildSurfaceStudioReadModel(ProjectManifest manifest) =>
    buildSurfaceStudioReadModelFromCatalog(
      getProjectManifestSurfaceCatalog(manifest),
    );

/// Construit un [SurfaceStudioReadModel] : même instance de [catalog],
/// même ordre source que les listes du catalogue, diagnostics auteur
/// (Lots 36 + 38) **sans** filtrage ni tri.
SurfaceStudioReadModel buildSurfaceStudioReadModelFromCatalog(
  ProjectSurfaceCatalog catalog,
) {
  final summary = SurfaceStudioCatalogSummaryReadModel(
    atlasCount: catalog.atlasCount,
    animationCount: catalog.animationCount,
    presetCount: catalog.presetCount,
  );
  final report = diagnoseProjectSurfaceCatalogForAuthoring(catalog);
  final diagnostics = buildSurfaceCatalogDiagnosticsPresentation(report);

  final atlasRows = <SurfaceStudioAtlasReadModel>[];
  for (final a in catalog.atlases) {
    atlasRows.add(
      SurfaceStudioAtlasReadModel(
        atlas: a,
        usedByAnimationIds: _usedByAnimationIdsForAtlas(catalog, a),
      ),
    );
  }

  final animRows = <SurfaceStudioAnimationReadModel>[];
  for (final anim in catalog.animations) {
    animRows.add(
      SurfaceStudioAnimationReadModel(
        animation: anim,
        referencedAtlasIds: _referencedAtlasFirstAppearance(anim),
      ),
    );
  }

  final presetRows = <SurfaceStudioPresetReadModel>[];
  for (final p in catalog.presets) {
    final roleList = p.variantAnimations.refs.map((r) => r.role).toList();
    presetRows.add(
      SurfaceStudioPresetReadModel(
        preset: p,
        roles: roleList,
        referencedAnimationIds: _referencedAnimationIdsDeduped(
          p.variantAnimations,
        ),
      ),
    );
  }

  return SurfaceStudioReadModel(
    catalog: catalog,
    summary: summary,
    atlases: atlasRows,
    animations: animRows,
    presets: presetRows,
    diagnostics: diagnostics,
  );
}
