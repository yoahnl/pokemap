import 'package:meta/meta.dart' show immutable;

import '../models/surface.dart';
import '../models/surface_catalog.dart';

// --- Comparaison ordonnée (égalité du rapport) ---

bool _diagnosticsEqualInOrder(
  List<SurfaceCatalogDiagnostic> a,
  List<SurfaceCatalogDiagnostic> b,
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

/// Niveau de sévérité d’un [SurfaceCatalogDiagnostic] :
/// * [error] : références invalides (Lot 34, [diagnoseProjectSurfaceCatalog]) ;
/// * [warning] : ressources non référencées (Lot 35,
///   [diagnoseProjectSurfaceCatalogUnusedResources]).
enum SurfaceCatalogDiagnosticSeverity {
  error,
  warning,
}

/// Catégorie de problème constaté dans un [ProjectSurfaceCatalog] (références
/// internes **mémoire** seulement — pas de JSON, pas de runtime).
enum SurfaceCatalogDiagnosticKind {
  /// [ProjectSurfacePreset] : un [SurfaceVariantAnimationRef.animationId] ne
  /// pointe vers aucun [ProjectSurfaceAnimation.id] du catalogue.
  missingPresetAnimation,

  /// [ProjectSurfaceAnimation] : le [SurfaceAtlasTileRef.atlasId] d’une frame
  /// n’existe pas dans [ProjectSurfaceCatalog.atlases].
  missingAnimationAtlas,

  /// Frame dont les coordonnées de grille ne sont pas dans
  /// [ProjectSurfaceAtlas.geometry] (l’atlas **existe** dans le catalogue).
  animationFrameOutsideAtlasGeometry,

  /// Aucune frame d’[ProjectSurfaceAnimation] ne référence cet
  /// [ProjectSurfaceAtlas.id] (comparaison de chaînes **exacte**).
  /// Lot 35 — [diagnoseProjectSurfaceCatalogUnusedResources] seulement.
  unusedAtlas,

  /// Aucun [ProjectSurfacePreset] ne référence cet [ProjectSurfaceAnimation.id]
  /// dans une [SurfaceVariantAnimationRef] (exact).
  /// Lot 35 — [diagnoseProjectSurfaceCatalogUnusedResources] seulement.
  /// Le kind `unusedPreset` n’existe **pas** : aucun autre type du projet ne
  /// référence encore un preset par id (pas de consommateur fiable).
  unusedAnimation,
}

/// Un problème constaté sur un [ProjectSurfaceCatalog] en **lecture seule** ;
/// ne modifie rien, ne se sérialise pas, ne s’applique pas à [ProjectManifest].
@immutable
final class SurfaceCatalogDiagnostic {
  const SurfaceCatalogDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
    this.presetId,
    this.animationId,
    this.atlasId,
    this.role,
    this.frameIndex,
  });

  final SurfaceCatalogDiagnosticSeverity severity;
  final SurfaceCatalogDiagnosticKind kind;
  final String message;
  final String? presetId;
  final String? animationId;
  final String? atlasId;
  final SurfaceVariantRole? role;
  final int? frameIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceCatalogDiagnostic &&
          other.severity == severity &&
          other.kind == kind &&
          other.message == message &&
          other.presetId == presetId &&
          other.animationId == animationId &&
          other.atlasId == atlasId &&
          other.role == role &&
          other.frameIndex == frameIndex;

  @override
  int get hashCode => Object.hash(
        severity,
        kind,
        message,
        presetId,
        animationId,
        atlasId,
        role,
        frameIndex,
      );
}

/// Rapport de diagnostics sur un [ProjectSurfaceCatalog] : **mémoire uniquement**,
/// ordre des entrées **déterministe** selon la fonction appelée
/// ([diagnoseProjectSurfaceCatalog] : presets puis animations+frames ;
/// [diagnoseProjectSurfaceCatalogUnusedResources] : atlases inutilisés puis
/// animations inutilisées) ; pas de tri par message ; ne remplace pas un
/// **validateur projet** complet.
@immutable
final class SurfaceCatalogDiagnosticsReport {
  SurfaceCatalogDiagnosticsReport({
    required List<SurfaceCatalogDiagnostic> diagnostics,
  }) {
    final copy = List<SurfaceCatalogDiagnostic>.from(diagnostics);
    _diagnostics = List<SurfaceCatalogDiagnostic>.unmodifiable(copy);
  }

  late final List<SurfaceCatalogDiagnostic> _diagnostics;

  /// Liste **non modifiable** (copie défensive à la construction).
  List<SurfaceCatalogDiagnostic> get diagnostics => _diagnostics;

  int get count => _diagnostics.length;

  bool get hasDiagnostics => _diagnostics.isNotEmpty;

  /// Vrai si au moins une entrée a [SurfaceCatalogDiagnosticSeverity.error].
  bool get hasErrors =>
      _diagnostics.any((d) => d.severity == SurfaceCatalogDiagnosticSeverity.error);

  /// Filtre par [kind] ; retourne une **nouvelle** liste **non modifiable**
  /// (n’expose pas l’intérieur du rapport).
  List<SurfaceCatalogDiagnostic> byKind(SurfaceCatalogDiagnosticKind kind) {
    final m = <SurfaceCatalogDiagnostic>[];
    for (final d in _diagnostics) {
      if (d.kind == kind) {
        m.add(d);
      }
    }
    return List<SurfaceCatalogDiagnostic>.unmodifiable(m);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceCatalogDiagnosticsReport &&
          _diagnosticsEqualInOrder(_diagnostics, other._diagnostics);

  @override
  int get hashCode => Object.hashAll(_diagnostics);
}

/// Analyse [catalog] en **lecture seule** : cohérence des références
/// *preset → animation* et *frame → atlas / géométrie d’atlas* connues dans le
/// catalogue. Ne **résout** rien, ne **charge** pas d’image, ne touche pas au
/// manifest, ne produit **pas** de JSON.
///
/// * Ordre : d’abord chaque [ProjectSurfacePreset] dans l’ordre de
///   [ProjectSurfaceCatalog.presets], chaque
///   [SurfaceVariantAnimationRef] dans l’ordre de [SurfaceVariantAnimationRefSet.refs] ;
///   puis chaque [ProjectSurfaceAnimation] dans l’ordre de
///   [ProjectSurfaceCatalog.animations], chaque frame dans
///   l’[SurfaceAnimationTimeline.frames].
/// * Si une frame référence un atlas **absent**, seul
///   [SurfaceCatalogDiagnosticKind.missingAnimationAtlas] est émis (pas de
///   vérification géométrique sur un atlas non présent).
SurfaceCatalogDiagnosticsReport diagnoseProjectSurfaceCatalog(
  ProjectSurfaceCatalog catalog,
) {
  final out = <SurfaceCatalogDiagnostic>[];

  for (final preset in catalog.presets) {
    for (final ref in preset.variantAnimations.refs) {
      if (catalog.animationById(ref.animationId) == null) {
        out.add(
          SurfaceCatalogDiagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
            message:
                "Preset '${preset.id}' (role ${ref.role.name}) references missing "
                "animation '${ref.animationId}'",
            presetId: preset.id,
            animationId: ref.animationId,
            role: ref.role,
            atlasId: null,
            frameIndex: null,
          ),
        );
      }
    }
  }

  for (final animation in catalog.animations) {
    var fi = 0;
    for (final frame in animation.timeline.frames) {
      final aid = frame.tileRef.atlasId;
      final atlas = catalog.atlasById(aid);
      if (atlas == null) {
        out.add(
          SurfaceCatalogDiagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
            message: "Animation '${animation.id}' frame $fi references missing "
                "atlas '$aid'",
            presetId: null,
            role: null,
            animationId: animation.id,
            atlasId: aid,
            frameIndex: fi,
          ),
        );
      } else {
        if (!frame.tileRef.isInside(atlas.geometry)) {
          final tr = frame.tileRef;
          out.add(
            SurfaceCatalogDiagnostic(
              severity: SurfaceCatalogDiagnosticSeverity.error,
              kind: SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry,
              message: "Animation '${animation.id}' frame $fi (column "
                  '${tr.column}, row ${tr.row}) is outside atlas '
                  "'${tr.atlasId}' geometry",
              presetId: null,
              role: null,
              animationId: animation.id,
              atlasId: tr.atlasId,
              frameIndex: fi,
            ),
          );
        }
      }
      fi++;
    }
  }

  return SurfaceCatalogDiagnosticsReport(diagnostics: out);
}

/// Détecte les ressources **non référencées** dans [catalog] (avertissements
/// seulement), **séparé** de [diagnoseProjectSurfaceCatalog] (erreurs Lot 34).
/// Ne valide **pas** les frames, la géométrie ni l’existence d’atlas côté erreur
/// — seulement : atlas cité par au moins une frame ? animation citée par au moins
/// un preset ? Comparaison d’[String] **stricte** (pas de [trim]).
/// Ne remplace **pas** un validateur projet complet ; le kind `unusedPreset` n’est
/// pas proposé tant qu’il n’y a pas de consommateur de presets Surface ailleurs.
///
/// * Ordre : d’abord chaque [SurfaceCatalogDiagnosticKind.unusedAtlas] pour
///   chaque [ProjectSurfaceCatalog.atlases] ; puis chaque
///   [SurfaceCatalogDiagnosticKind.unusedAnimation] pour chaque
///   [ProjectSurfaceCatalog.animations].
SurfaceCatalogDiagnosticsReport diagnoseProjectSurfaceCatalogUnusedResources(
  ProjectSurfaceCatalog catalog,
) {
  final out = <SurfaceCatalogDiagnostic>[];

  final atlasIdsUsedByAnyFrame = <String>{};
  for (final animation in catalog.animations) {
    for (final frame in animation.timeline.frames) {
      atlasIdsUsedByAnyFrame.add(frame.tileRef.atlasId);
    }
  }

  for (final atlas in catalog.atlases) {
    if (!atlasIdsUsedByAnyFrame.contains(atlas.id)) {
      out.add(
        SurfaceCatalogDiagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.warning,
          kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
          message: "Atlas '${atlas.id}' is not referenced by any animation frame",
          presetId: null,
          animationId: null,
          atlasId: atlas.id,
          role: null,
          frameIndex: null,
        ),
      );
    }
  }

  final animationIdsUsedByAnyPreset = <String>{};
  for (final preset in catalog.presets) {
    for (final ref in preset.variantAnimations.refs) {
      animationIdsUsedByAnyPreset.add(ref.animationId);
    }
  }

  for (final animation in catalog.animations) {
    if (!animationIdsUsedByAnyPreset.contains(animation.id)) {
      out.add(
        SurfaceCatalogDiagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.warning,
          kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
          message: "Animation '${animation.id}' is not referenced by any preset",
          presetId: null,
          animationId: animation.id,
          atlasId: null,
          role: null,
          frameIndex: null,
        ),
      );
    }
  }

  return SurfaceCatalogDiagnosticsReport(diagnostics: out);
}
