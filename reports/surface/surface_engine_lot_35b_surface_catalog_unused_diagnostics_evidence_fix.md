# Surface Engine — Lot 35-bis — Evidence fix (Surface Catalog Unused Diagnostics V0)

## 1. Résumé exécutif

Ce lot **ne modifie aucun code** : il fournit un rapport de preuve autonome pour le Lot 35, avec **contenus source intégraux**, **diffs Git complets** (équivalent `/dev/null` pour les fichiers nouveaux) et **sorties de commandes complètes** (y compris la suite `dart test` complète après conversion des retours chariot `\\r` en `\\n`), afin de corriger les sections 33–34 du rapport Lot 35 qui renvoyaient au dépôt ou à un artefact externe.

## 2. Pourquoi le Lot 35-bis existe

Le rapport `surface_engine_lot_35_surface_catalog_unused_diagnostics.md` ne remplissait pas l'exigence de **copier-coller** les contenus complets, les diffs réels et les sorties exactes des commandes ; ce document 35-bis sert de **preuve documentaire complémentaire** sans changer le périmètre technique du Lot 35.

## 3. Fichiers inspectés (audit)

- `packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart`
- `packages/map_core/test/surface_catalog_unused_diagnostics_test.dart`
- `packages/map_core/test/surface_catalog_diagnostics_test.dart`
- `packages/map_core/lib/map_core.dart`
- `reports/surface/surface_engine_lot_35_surface_catalog_unused_diagnostics.md`
- `packages/map_core/lib/src/models/surface.dart`
- `packages/map_core/lib/src/models/surface_catalog.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`

Vérification statique (audit lecture) : présence de `diagnoseProjectSurfaceCatalogUnusedResources`, `warning`, `unusedAtlas`, `unusedAnimation` ; absence de `unusedPreset` en tant que kind ; `diagnoseProjectSurfaceCatalog` reste l'API d'erreur Lot 34 (corps de fonction inchangé hors ajouts d'enums) ; seulement `warning` pour unused ; `hasErrors` lié à `error` ; comparaisons par `==` sur les chaînes ; `map_core` exporte `surface_catalog_diagnostics.dart` ; pas de champs `surface*` ajoutés au `ProjectManifest` côté modèle (fichier source non modifié en Lot 35).

## 4. Fichiers modifiés par ce lot (35-bis)

- **Un seul fichier créé** : `reports/surface/surface_engine_lot_35b_surface_catalog_unused_diagnostics_evidence_fix.md` (ce document).

## 5. Confirmation : code du Lot 35 non modifié

Aucun fichier source ou test de `map_core` n'a été modifié pour le 35-bis. État worktree (lecture) : propre.

## 6. Confirmation : `ProjectManifest` non modifié

Aucun changement de `project_manifest` ni de modèle lié n'a été effectué pour le 35-bis.

## 7. Confirmation : aucun fichier generated créé

Aucun `.g.dart`, `.freezed.dart`, `build_runner`.

## 8. Confirmation : aucun `SurfacePresetKind` / `surfaceKind` créé

N/A pour ce lot (preuve seulement).

## 9. Confirmation : aucun `unusedPreset` créé

Aucun kind `unusedPreset` n'existe dans le code inspecté (mention explicite dans les commentaires : kind volontairement absent).

## 10. Confirmation : aucun runtime / editor / gameplay / battle modifié

Périmètre strict : ce rapport seulement.

---

## 11. Contenu intégral de `packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart`

```dart
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

```

## 12. Contenu intégral de `packages/map_core/test/surface_catalog_unused_diagnostics_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

// --- Helpers (alignés sur surface_catalog_diagnostics_test) ---

SurfaceAtlasGeometry _geom({int columns = 2, int rows = 2}) {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: columns, rows: rows),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceAtlas _atlas(
  String id, {
  int columns = 2,
  int rows = 2,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: 'n-$id',
    tilesetId: 'ts',
    geometry: _geom(columns: columns, rows: rows),
  );
}

SurfaceAnimationFrame _frame(String atlasId, int column, int row) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: atlasId,
      column: column,
      row: row,
    ),
    durationMs: 1,
  );
}

ProjectSurfaceAnimation _animation(
  String id, {
  String atlasId = 'atlas',
  List<SurfaceAnimationFrame>? frames,
}) {
  return ProjectSurfaceAnimation(
    id: id,
    name: 'a-$id',
    timeline: SurfaceAnimationTimeline(
      frames: frames ?? [_frame(atlasId, 0, 0)],
    ),
  );
}

SurfaceVariantAnimationRef _ref(SurfaceVariantRole role, String animationId) {
  return SurfaceVariantAnimationRef(
    role: role,
    animationId: animationId,
  );
}

ProjectSurfacePreset _preset(String id, List<SurfaceVariantAnimationRef> refs) {
  return ProjectSurfacePreset(
    id: id,
    name: 'p-$id',
    variantAnimations: SurfaceVariantAnimationRefSet(refs: refs),
  );
}

ProjectSurfaceCatalog _catalog({
  List<ProjectSurfaceAtlas>? atlases,
  List<ProjectSurfaceAnimation>? animations,
  List<ProjectSurfacePreset>? presets,
}) {
  return ProjectSurfaceCatalog(
    atlases: atlases ?? const [],
    animations: animations ?? const [],
    presets: presets ?? const [],
  );
}

void main() {
  group('diagnoseProjectSurfaceCatalogUnusedResources (Lot 35)', () {
    test('1. empty catalog: no unused diagnostics', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(_catalog());
      expect(r.count, 0);
      expect(r.hasDiagnostics, isFalse);
      expect(r.hasErrors, isFalse);
      expect(r.diagnostics, isEmpty);
    });

    test('2. minimal coherent: no unused diagnostics', () {
      final atlas = _atlas('atlas');
      final anim = _animation('anim', atlasId: 'atlas');
      final preset = _preset('preset', [
        _ref(SurfaceVariantRole.isolated, 'anim'),
      ]);
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [atlas],
          animations: [anim],
          presets: [preset],
        ),
      );
      expect(r.diagnostics, isEmpty);
      expect(r.hasErrors, isFalse);
    });

    test('3. unreferenced atlas → unusedAtlas warning and metadata', () {
      final a = _atlas('unused-atlas');
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(atlases: [a], animations: const [], presets: const []),
      );
      expect(r.count, 1);
      final d = r.diagnostics.first;
      expect(d.kind, SurfaceCatalogDiagnosticKind.unusedAtlas);
      expect(d.severity, SurfaceCatalogDiagnosticSeverity.warning);
      expect(d.atlasId, 'unused-atlas');
      expect(d.animationId, isNull);
      expect(d.presetId, isNull);
      expect(d.role, isNull);
      expect(d.frameIndex, isNull);
      expect(d.message, contains('unused-atlas'));
      expect(
        d.message.toLowerCase(),
        contains('not referenced by any animation'),
      );
      expect(r.hasDiagnostics, isTrue);
      expect(r.hasErrors, isFalse);
    });

    test('4. multiple unused atlases: order follows catalog.atlases a,b,c', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('a'), _atlas('b'), _atlas('c')],
        ),
      );
      expect(r.diagnostics.length, 3);
      expect(r.diagnostics[0].atlasId, 'a');
      expect(r.diagnostics[1].atlasId, 'b');
      expect(r.diagnostics[2].atlasId, 'c');
    });

    test('5. atlas used by a frame: no unusedAtlas (may be unusedAnimation)', () {
      final atlas = _atlas('atlas');
      final anim = _animation('ani', atlasId: 'atlas');
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [atlas],
          animations: [anim],
        ),
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas),
        isEmpty,
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation).length,
        1,
      );
    });

    test('6. atlas id exact: spaced atlas not matched by frame atlasId', () {
      const spaced = '  atlas  ';
      final atlas = _atlas(spaced);
      final anim = _animation('x', atlasId: 'atlas');
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [atlas],
          animations: [anim],
        ),
      );
      final ua = r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas);
      expect(ua, hasLength(1));
      expect(ua.first.atlasId, spaced);
    });

    test('7. animation not referenced by preset → unusedAnimation', () {
      final atlas = _atlas('atlas');
      final anim = _animation('unused-animation', atlasId: 'atlas');
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [atlas],
          animations: [anim],
        ),
      );
      final u = r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation);
      expect(u, hasLength(1));
      final d = u.first;
      expect(d.animationId, 'unused-animation');
      expect(d.atlasId, isNull);
      expect(d.presetId, isNull);
      expect(d.severity, SurfaceCatalogDiagnosticSeverity.warning);
    });

    test('8. multiple unused animations: order follows catalog.animations a,b,c',
        () {
      final atlas = _atlas('atlas');
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [atlas],
          animations: [
            _animation('a', atlasId: 'atlas'),
            _animation('b', atlasId: 'atlas'),
            _animation('c', atlasId: 'atlas'),
          ],
        ),
      );
      final u = r.diagnostics
          .where(
            (d) => d.kind == SurfaceCatalogDiagnosticKind.unusedAnimation,
          )
          .toList();
      expect(u.length, 3);
      expect(u[0].animationId, 'a');
      expect(u[1].animationId, 'b');
      expect(u[2].animationId, 'c');
    });

    test('9. animation referenced by a preset: not unused', () {
      final anim = _animation('anim', atlasId: 'a');
      final preset = _preset('p1', [
        _ref(SurfaceVariantRole.isolated, 'anim'),
      ]);
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('a')],
          animations: [anim],
          presets: [preset],
        ),
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation),
        isEmpty,
      );
    });

    test('10. animationId exact: spaced id not matched by preset ref', () {
      const spaced = '  anim  ';
      final anim = _animation(spaced, atlasId: 'a');
      final preset = _preset('p', [
        _ref(SurfaceVariantRole.isolated, 'anim'),
      ]);
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('a')],
          animations: [anim],
          presets: [preset],
        ),
      );
      final u = r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation);
      expect(u, hasLength(1));
      expect(u.first.animationId, spaced);
    });

    test('11. same animation referenced by two presets: not unused', () {
      final anim = _animation('anim', atlasId: 'a');
      final p1 = _preset('p1', [
        _ref(SurfaceVariantRole.endNorth, 'anim'),
      ]);
      final p2 = _preset('p2', [
        _ref(SurfaceVariantRole.endSouth, 'anim'),
      ]);
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('a')],
          animations: [anim],
          presets: [p1, p2],
        ),
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation),
        isEmpty,
      );
    });

    test('12. same atlas referenced by two animations: atlas not unused', () {
      final atlas = _atlas('atlas');
      final a1 = _animation('a1', atlasId: 'atlas');
      final a2 = _animation('a2', atlasId: 'atlas');
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [atlas],
          animations: [a1, a2],
        ),
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas),
        isEmpty,
      );
    });

    test('13. global order: unusedAtlas before unusedAnimation', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('unused-atlas')],
          animations: [_animation('unused-animation', atlasId: 'x')],
        ),
      );
      expect(r.diagnostics.length, 2);
      expect(r.diagnostics[0].kind, SurfaceCatalogDiagnosticKind.unusedAtlas);
      expect(r.diagnostics[1].kind, SurfaceCatalogDiagnosticKind.unusedAnimation);
    });

    test('14. warnings only: hasErrors false, hasDiagnostics true', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('orphan')],
        ),
      );
      expect(r.hasDiagnostics, isTrue);
      expect(r.hasErrors, isFalse);
    });

    test('15. byKind(unusedAtlas) only atlas warnings', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('u')],
          animations: [_animation('a', atlasId: 'm')],
        ),
      );
      final only = r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas);
      for (final d in only) {
        expect(d.kind, SurfaceCatalogDiagnosticKind.unusedAtlas);
        expect(d.atlasId, isNotNull);
      }
    });

    test('16. byKind(unusedAnimation) only animation warnings', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('at')],
          animations: [_animation('a', atlasId: 'at')],
        ),
      );
      final only = r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation);
      for (final d in only) {
        expect(d.kind, SurfaceCatalogDiagnosticKind.unusedAnimation);
        expect(d.animationId, isNotNull);
      }
    });

    test('17. byKind returns an unmodifiable list (add → UnsupportedError)', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('x')],
        ),
      );
      final list = r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas);
      expect(
        () => list.add(
          r.diagnostics.first,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('18. diagnostics list is unmodifiable (add → UnsupportedError)', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          atlases: [_atlas('x')],
        ),
      );
      expect(
        () => r.diagnostics.add(r.diagnostics.first),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test(
      '19. unused function does not emit Lot 34 error kinds',
      () {
        final r = diagnoseProjectSurfaceCatalogUnusedResources(
          _catalog(
            animations: [
              _animation('anim', atlasId: 'missing-atlas'),
            ],
          ),
        );
        expect(
          r.byKind(SurfaceCatalogDiagnosticKind.missingAnimationAtlas),
          isEmpty,
        );
        expect(
          r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
          isEmpty,
        );
        expect(
          r.byKind(SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry),
          isEmpty,
        );
        expect(
          r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation).length,
          1,
        );
      },
    );

    test('20. Lot 34 diagnoseProjectSurfaceCatalog still returns errors', () {
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(
          presets: [
            _preset('p', [
              _ref(SurfaceVariantRole.isolated, 'missing-anim'),
            ]),
          ],
        ),
      );
      expect(r.hasErrors, isTrue);
      final k = r.diagnostics.map((d) => d.kind).toSet();
      expect(
        k,
        contains(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
      );
    });

    test('21. warning severity exists and differs from error', () {
      expect(
        SurfaceCatalogDiagnosticSeverity.warning,
        isNot(equals(SurfaceCatalogDiagnosticSeverity.error)),
      );
    });

    test(
      'V0 does not diagnose unused presets yet: isolated preset, no false presetId',
      () {
        final p = _preset('lonely', [
          _ref(SurfaceVariantRole.isolated, 'ghost-anim'),
        ]);
        final r = diagnoseProjectSurfaceCatalogUnusedResources(
          _catalog(
            presets: [p],
          ),
        );
        for (final d in r.diagnostics) {
          expect(
            d.presetId,
            isNot('lonely'),
            reason: 'Lot 35 must not target preset id for unused V0',
          );
        }
      },
    );

    test('23. public API: unused + kinds via map_core only', () {
      final r = diagnoseProjectSurfaceCatalogUnusedResources(_catalog());
      expect(
        r,
        isA<SurfaceCatalogDiagnosticsReport>(),
      );
      expect(
        SurfaceCatalogDiagnosticKind.unusedAtlas,
        isA<SurfaceCatalogDiagnosticKind>(),
      );
      expect(
        SurfaceCatalogDiagnosticKind.unusedAnimation,
        isA<SurfaceCatalogDiagnosticKind>(),
      );
      expect(
        SurfaceCatalogDiagnosticSeverity.warning,
        isA<SurfaceCatalogDiagnosticSeverity>(),
      );
    });

    test('24. ProjectManifest still has no Surface keys (Lot 35)', () {
      const manifest = ProjectManifest(
        name: 'L35',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'M',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
      );
      final j = manifest.toJson();
      for (final k in const [
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(j.containsKey(k), isFalse, reason: k);
      }
    });
  });
}

```

## 13. Extrait de `packages/map_core/lib/map_core.dart` (export `surface_catalog_diagnostics.dart`)

Lignes 40–45 (fichier total : **77** lignes) :

```dart
export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_surface_preset_builder.dart';
export 'src/operations/surface_catalog_diagnostics.dart';
export 'src/operations/legacy_path_surface_view.dart';

```

---

## 14. Diff complet réel : `surface_catalog_diagnostics.dart` (parent `87a92448` → commit Lot 35 `794de3de`)

Base : `git diff 87a92448 794de3de -- packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart`.

```diff
diff --git a/packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart b/packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart
index 1e09926a..ebb4d295 100644
--- a/packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart
+++ b/packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart
@@ -20,10 +20,13 @@ bool _diagnosticsEqualInOrder(
   return true;
 }
 
-/// Niveau de sévérité d’un [SurfaceCatalogDiagnostic] (V0 : **error** seulement
-/// — pas de warning dans ce lot).
+/// Niveau de sévérité d’un [SurfaceCatalogDiagnostic] :
+/// * [error] : références invalides (Lot 34, [diagnoseProjectSurfaceCatalog]) ;
+/// * [warning] : ressources non référencées (Lot 35,
+///   [diagnoseProjectSurfaceCatalogUnusedResources]).
 enum SurfaceCatalogDiagnosticSeverity {
   error,
+  warning,
 }
 
 /// Catégorie de problème constaté dans un [ProjectSurfaceCatalog] (références
@@ -40,6 +43,18 @@ enum SurfaceCatalogDiagnosticKind {
   /// Frame dont les coordonnées de grille ne sont pas dans
   /// [ProjectSurfaceAtlas.geometry] (l’atlas **existe** dans le catalogue).
   animationFrameOutsideAtlasGeometry,
+
+  /// Aucune frame d’[ProjectSurfaceAnimation] ne référence cet
+  /// [ProjectSurfaceAtlas.id] (comparaison de chaînes **exacte**).
+  /// Lot 35 — [diagnoseProjectSurfaceCatalogUnusedResources] seulement.
+  unusedAtlas,
+
+  /// Aucun [ProjectSurfacePreset] ne référence cet [ProjectSurfaceAnimation.id]
+  /// dans une [SurfaceVariantAnimationRef] (exact).
+  /// Lot 35 — [diagnoseProjectSurfaceCatalogUnusedResources] seulement.
+  /// Le kind `unusedPreset` n’existe **pas** : aucun autre type du projet ne
+  /// référence encore un preset par id (pas de consommateur fiable).
+  unusedAnimation,
 }
 
 /// Un problème constaté sur un [ProjectSurfaceCatalog] en **lecture seule** ;
@@ -93,8 +108,11 @@ final class SurfaceCatalogDiagnostic {
 }
 
 /// Rapport de diagnostics sur un [ProjectSurfaceCatalog] : **mémoire uniquement**,
-/// ordre des entrées **déterministe** (presets d’abord, puis animations), pas de
-/// tri par message ni remplacement d’un **validateur projet** complet.
+/// ordre des entrées **déterministe** selon la fonction appelée
+/// ([diagnoseProjectSurfaceCatalog] : presets puis animations+frames ;
+/// [diagnoseProjectSurfaceCatalogUnusedResources] : atlases inutilisés puis
+/// animations inutilisées) ; pas de tri par message ; ne remplace pas un
+/// **validateur projet** complet.
 @immutable
 final class SurfaceCatalogDiagnosticsReport {
   SurfaceCatalogDiagnosticsReport({
@@ -223,3 +241,71 @@ SurfaceCatalogDiagnosticsReport diagnoseProjectSurfaceCatalog(
 
   return SurfaceCatalogDiagnosticsReport(diagnostics: out);
 }
+
+/// Détecte les ressources **non référencées** dans [catalog] (avertissements
+/// seulement), **séparé** de [diagnoseProjectSurfaceCatalog] (erreurs Lot 34).
+/// Ne valide **pas** les frames, la géométrie ni l’existence d’atlas côté erreur
+/// — seulement : atlas cité par au moins une frame ? animation citée par au moins
+/// un preset ? Comparaison d’[String] **stricte** (pas de [trim]).
+/// Ne remplace **pas** un validateur projet complet ; le kind `unusedPreset` n’est
+/// pas proposé tant qu’il n’y a pas de consommateur de presets Surface ailleurs.
+///
+/// * Ordre : d’abord chaque [SurfaceCatalogDiagnosticKind.unusedAtlas] pour
+///   chaque [ProjectSurfaceCatalog.atlases] ; puis chaque
+///   [SurfaceCatalogDiagnosticKind.unusedAnimation] pour chaque
+///   [ProjectSurfaceCatalog.animations].
+SurfaceCatalogDiagnosticsReport diagnoseProjectSurfaceCatalogUnusedResources(
+  ProjectSurfaceCatalog catalog,
+) {
+  final out = <SurfaceCatalogDiagnostic>[];
+
+  final atlasIdsUsedByAnyFrame = <String>{};
+  for (final animation in catalog.animations) {
+    for (final frame in animation.timeline.frames) {
+      atlasIdsUsedByAnyFrame.add(frame.tileRef.atlasId);
+    }
+  }
+
+  for (final atlas in catalog.atlases) {
+    if (!atlasIdsUsedByAnyFrame.contains(atlas.id)) {
+      out.add(
+        SurfaceCatalogDiagnostic(
+          severity: SurfaceCatalogDiagnosticSeverity.warning,
+          kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
+          message: "Atlas '${atlas.id}' is not referenced by any animation frame",
+          presetId: null,
+          animationId: null,
+          atlasId: atlas.id,
+          role: null,
+          frameIndex: null,
+        ),
+      );
+    }
+  }
+
+  final animationIdsUsedByAnyPreset = <String>{};
+  for (final preset in catalog.presets) {
+    for (final ref in preset.variantAnimations.refs) {
+      animationIdsUsedByAnyPreset.add(ref.animationId);
+    }
+  }
+
+  for (final animation in catalog.animations) {
+    if (!animationIdsUsedByAnyPreset.contains(animation.id)) {
+      out.add(
+        SurfaceCatalogDiagnostic(
+          severity: SurfaceCatalogDiagnosticSeverity.warning,
+          kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
+          message: "Animation '${animation.id}' is not referenced by any preset",
+          presetId: null,
+          animationId: animation.id,
+          atlasId: null,
+          role: null,
+          frameIndex: null,
+        ),
+      );
+    }
+  }
+
+  return SurfaceCatalogDiagnosticsReport(diagnostics: out);
+}

```

## 15. Diff complet équivalent `/dev/null` : `surface_catalog_unused_diagnostics_test.dart`

```diff
diff --git a/packages/map_core/test/surface_catalog_unused_diagnostics_test.dart b/packages/map_core/test/surface_catalog_unused_diagnostics_test.dart
new file mode 100644
index 00000000..39221cd2
--- /dev/null
+++ b/packages/map_core/test/surface_catalog_unused_diagnostics_test.dart
@@ -0,0 +1,486 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+// --- Helpers (alignés sur surface_catalog_diagnostics_test) ---
+
+SurfaceAtlasGeometry _geom({int columns = 2, int rows = 2}) {
+  return SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: columns, rows: rows),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+}
+
+ProjectSurfaceAtlas _atlas(
+  String id, {
+  int columns = 2,
+  int rows = 2,
+}) {
+  return ProjectSurfaceAtlas(
+    id: id,
+    name: 'n-$id',
+    tilesetId: 'ts',
+    geometry: _geom(columns: columns, rows: rows),
+  );
+}
+
+SurfaceAnimationFrame _frame(String atlasId, int column, int row) {
+  return SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(
+      atlasId: atlasId,
+      column: column,
+      row: row,
+    ),
+    durationMs: 1,
+  );
+}
+
+ProjectSurfaceAnimation _animation(
+  String id, {
+  String atlasId = 'atlas',
+  List<SurfaceAnimationFrame>? frames,
+}) {
+  return ProjectSurfaceAnimation(
+    id: id,
+    name: 'a-$id',
+    timeline: SurfaceAnimationTimeline(
+      frames: frames ?? [_frame(atlasId, 0, 0)],
+    ),
+  );
+}
+
+SurfaceVariantAnimationRef _ref(SurfaceVariantRole role, String animationId) {
+  return SurfaceVariantAnimationRef(
+    role: role,
+    animationId: animationId,
+  );
+}
+
+ProjectSurfacePreset _preset(String id, List<SurfaceVariantAnimationRef> refs) {
+  return ProjectSurfacePreset(
+    id: id,
+    name: 'p-$id',
+    variantAnimations: SurfaceVariantAnimationRefSet(refs: refs),
+  );
+}
+
+ProjectSurfaceCatalog _catalog({
+  List<ProjectSurfaceAtlas>? atlases,
+  List<ProjectSurfaceAnimation>? animations,
+  List<ProjectSurfacePreset>? presets,
+}) {
+  return ProjectSurfaceCatalog(
+    atlases: atlases ?? const [],
+    animations: animations ?? const [],
+    presets: presets ?? const [],
+  );
+}
+
+void main() {
+  group('diagnoseProjectSurfaceCatalogUnusedResources (Lot 35)', () {
+    test('1. empty catalog: no unused diagnostics', () {
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(_catalog());
+      expect(r.count, 0);
+      expect(r.hasDiagnostics, isFalse);
+      expect(r.hasErrors, isFalse);
+      expect(r.diagnostics, isEmpty);
+    });
+
+    test('2. minimal coherent: no unused diagnostics', () {
+      final atlas = _atlas('atlas');
+      final anim = _animation('anim', atlasId: 'atlas');
+      final preset = _preset('preset', [
+        _ref(SurfaceVariantRole.isolated, 'anim'),
+      ]);
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          atlases: [atlas],
+          animations: [anim],
+          presets: [preset],
+        ),
+      );
+      expect(r.diagnostics, isEmpty);
+      expect(r.hasErrors, isFalse);
+    });
+
+    test('3. unreferenced atlas → unusedAtlas warning and metadata', () {
+      final a = _atlas('unused-atlas');
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(atlases: [a], animations: const [], presets: const []),
+      );
+      expect(r.count, 1);
+      final d = r.diagnostics.first;
+      expect(d.kind, SurfaceCatalogDiagnosticKind.unusedAtlas);
+      expect(d.severity, SurfaceCatalogDiagnosticSeverity.warning);
+      expect(d.atlasId, 'unused-atlas');
+      expect(d.animationId, isNull);
+      expect(d.presetId, isNull);
+      expect(d.role, isNull);
+      expect(d.frameIndex, isNull);
+      expect(d.message, contains('unused-atlas'));
+      expect(
+        d.message.toLowerCase(),
+        contains('not referenced by any animation'),
+      );
+      expect(r.hasDiagnostics, isTrue);
+      expect(r.hasErrors, isFalse);
+    });
+
+    test('4. multiple unused atlases: order follows catalog.atlases a,b,c', () {
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          atlases: [_atlas('a'), _atlas('b'), _atlas('c')],
+        ),
+      );
+      expect(r.diagnostics.length, 3);
+      expect(r.diagnostics[0].atlasId, 'a');
+      expect(r.diagnostics[1].atlasId, 'b');
+      expect(r.diagnostics[2].atlasId, 'c');
+    });
+
+    test('5. atlas used by a frame: no unusedAtlas (may be unusedAnimation)', () {
+      final atlas = _atlas('atlas');
+      final anim = _animation('ani', atlasId: 'atlas');
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          atlases: [atlas],
+          animations: [anim],
+        ),
+      );
+      expect(
+        r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas),
+        isEmpty,
+      );
+      expect(
+        r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation).length,
+        1,
+      );
+    });
+
+    test('6. atlas id exact: spaced atlas not matched by frame atlasId', () {
+      const spaced = '  atlas  ';
+      final atlas = _atlas(spaced);
+      final anim = _animation('x', atlasId: 'atlas');
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          atlases: [atlas],
+          animations: [anim],
+        ),
+      );
+      final ua = r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas);
+      expect(ua, hasLength(1));
+      expect(ua.first.atlasId, spaced);
+    });
+
+    test('7. animation not referenced by preset → unusedAnimation', () {
+      final atlas = _atlas('atlas');
+      final anim = _animation('unused-animation', atlasId: 'atlas');
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          atlases: [atlas],
+          animations: [anim],
+        ),
+      );
+      final u = r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation);
+      expect(u, hasLength(1));
+      final d = u.first;
+      expect(d.animationId, 'unused-animation');
+      expect(d.atlasId, isNull);
+      expect(d.presetId, isNull);
+      expect(d.severity, SurfaceCatalogDiagnosticSeverity.warning);
+    });
+
+    test('8. multiple unused animations: order follows catalog.animations a,b,c',
+        () {
+      final atlas = _atlas('atlas');
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          atlases: [atlas],
+          animations: [
+            _animation('a', atlasId: 'atlas'),
+            _animation('b', atlasId: 'atlas'),
+            _animation('c', atlasId: 'atlas'),
+          ],
+        ),
+      );
+      final u = r.diagnostics
+          .where(
+            (d) => d.kind == SurfaceCatalogDiagnosticKind.unusedAnimation,
+          )
+          .toList();
+      expect(u.length, 3);
+      expect(u[0].animationId, 'a');
+      expect(u[1].animationId, 'b');
+      expect(u[2].animationId, 'c');
+    });
+
+    test('9. animation referenced by a preset: not unused', () {
+      final anim = _animation('anim', atlasId: 'a');
+      final preset = _preset('p1', [
+        _ref(SurfaceVariantRole.isolated, 'anim'),
+      ]);
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          atlases: [_atlas('a')],
+          animations: [anim],
+          presets: [preset],
+        ),
+      );
+      expect(
+        r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation),
+        isEmpty,
+      );
+    });
+
+    test('10. animationId exact: spaced id not matched by preset ref', () {
+      const spaced = '  anim  ';
+      final anim = _animation(spaced, atlasId: 'a');
+      final preset = _preset('p', [
+        _ref(SurfaceVariantRole.isolated, 'anim'),
+      ]);
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          atlases: [_atlas('a')],
+          animations: [anim],
+          presets: [preset],
+        ),
+      );
+      final u = r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation);
+      expect(u, hasLength(1));
+      expect(u.first.animationId, spaced);
+    });
+
+    test('11. same animation referenced by two presets: not unused', () {
+      final anim = _animation('anim', atlasId: 'a');
+      final p1 = _preset('p1', [
+        _ref(SurfaceVariantRole.endNorth, 'anim'),
+      ]);
+      final p2 = _preset('p2', [
+        _ref(SurfaceVariantRole.endSouth, 'anim'),
+      ]);
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          atlases: [_atlas('a')],
+          animations: [anim],
+          presets: [p1, p2],
+        ),
+      );
+      expect(
+        r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation),
+        isEmpty,
+      );
+    });
+
+    test('12. same atlas referenced by two animations: atlas not unused', () {
+      final atlas = _atlas('atlas');
+      final a1 = _animation('a1', atlasId: 'atlas');
+      final a2 = _animation('a2', atlasId: 'atlas');
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          atlases: [atlas],
+          animations: [a1, a2],
+        ),
+      );
+      expect(
+        r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas),
+        isEmpty,
+      );
+    });
+
+    test('13. global order: unusedAtlas before unusedAnimation', () {
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          atlases: [_atlas('unused-atlas')],
+          animations: [_animation('unused-animation', atlasId: 'x')],
+        ),
+      );
+      expect(r.diagnostics.length, 2);
+      expect(r.diagnostics[0].kind, SurfaceCatalogDiagnosticKind.unusedAtlas);
+      expect(r.diagnostics[1].kind, SurfaceCatalogDiagnosticKind.unusedAnimation);
+    });
+
+    test('14. warnings only: hasErrors false, hasDiagnostics true', () {
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          atlases: [_atlas('orphan')],
+        ),
+      );
+      expect(r.hasDiagnostics, isTrue);
+      expect(r.hasErrors, isFalse);
+    });
+
+    test('15. byKind(unusedAtlas) only atlas warnings', () {
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          atlases: [_atlas('u')],
+          animations: [_animation('a', atlasId: 'm')],
+        ),
+      );
+      final only = r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas);
+      for (final d in only) {
+        expect(d.kind, SurfaceCatalogDiagnosticKind.unusedAtlas);
+        expect(d.atlasId, isNotNull);
+      }
+    });
+
+    test('16. byKind(unusedAnimation) only animation warnings', () {
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          atlases: [_atlas('at')],
+          animations: [_animation('a', atlasId: 'at')],
+        ),
+      );
+      final only = r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation);
+      for (final d in only) {
+        expect(d.kind, SurfaceCatalogDiagnosticKind.unusedAnimation);
+        expect(d.animationId, isNotNull);
+      }
+    });
+
+    test('17. byKind returns an unmodifiable list (add → UnsupportedError)', () {
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          atlases: [_atlas('x')],
+        ),
+      );
+      final list = r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas);
+      expect(
+        () => list.add(
+          r.diagnostics.first,
+        ),
+        throwsA(isA<UnsupportedError>()),
+      );
+    });
+
+    test('18. diagnostics list is unmodifiable (add → UnsupportedError)', () {
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          atlases: [_atlas('x')],
+        ),
+      );
+      expect(
+        () => r.diagnostics.add(r.diagnostics.first),
+        throwsA(isA<UnsupportedError>()),
+      );
+    });
+
+    test(
+      '19. unused function does not emit Lot 34 error kinds',
+      () {
+        final r = diagnoseProjectSurfaceCatalogUnusedResources(
+          _catalog(
+            animations: [
+              _animation('anim', atlasId: 'missing-atlas'),
+            ],
+          ),
+        );
+        expect(
+          r.byKind(SurfaceCatalogDiagnosticKind.missingAnimationAtlas),
+          isEmpty,
+        );
+        expect(
+          r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
+          isEmpty,
+        );
+        expect(
+          r.byKind(SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry),
+          isEmpty,
+        );
+        expect(
+          r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation).length,
+          1,
+        );
+      },
+    );
+
+    test('20. Lot 34 diagnoseProjectSurfaceCatalog still returns errors', () {
+      final r = diagnoseProjectSurfaceCatalog(
+        _catalog(
+          presets: [
+            _preset('p', [
+              _ref(SurfaceVariantRole.isolated, 'missing-anim'),
+            ]),
+          ],
+        ),
+      );
+      expect(r.hasErrors, isTrue);
+      final k = r.diagnostics.map((d) => d.kind).toSet();
+      expect(
+        k,
+        contains(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
+      );
+    });
+
+    test('21. warning severity exists and differs from error', () {
+      expect(
+        SurfaceCatalogDiagnosticSeverity.warning,
+        isNot(equals(SurfaceCatalogDiagnosticSeverity.error)),
+      );
+    });
+
+    test(
+      'V0 does not diagnose unused presets yet: isolated preset, no false presetId',
+      () {
+        final p = _preset('lonely', [
+          _ref(SurfaceVariantRole.isolated, 'ghost-anim'),
+        ]);
+        final r = diagnoseProjectSurfaceCatalogUnusedResources(
+          _catalog(
+            presets: [p],
+          ),
+        );
+        for (final d in r.diagnostics) {
+          expect(
+            d.presetId,
+            isNot('lonely'),
+            reason: 'Lot 35 must not target preset id for unused V0',
+          );
+        }
+      },
+    );
+
+    test('23. public API: unused + kinds via map_core only', () {
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(_catalog());
+      expect(
+        r,
+        isA<SurfaceCatalogDiagnosticsReport>(),
+      );
+      expect(
+        SurfaceCatalogDiagnosticKind.unusedAtlas,
+        isA<SurfaceCatalogDiagnosticKind>(),
+      );
+      expect(
+        SurfaceCatalogDiagnosticKind.unusedAnimation,
+        isA<SurfaceCatalogDiagnosticKind>(),
+      );
+      expect(
+        SurfaceCatalogDiagnosticSeverity.warning,
+        isA<SurfaceCatalogDiagnosticSeverity>(),
+      );
+    });
+
+    test('24. ProjectManifest still has no Surface keys (Lot 35)', () {
+      const manifest = ProjectManifest(
+        name: 'L35',
+        maps: [
+          ProjectMapEntry(
+            id: 'm1',
+            name: 'M',
+            relativePath: 'maps/m1.json',
+          ),
+        ],
+        tilesets: [],
+      );
+      final j = manifest.toJson();
+      for (final k in const [
+        'surfaceDefinitions',
+        'surfaceAtlases',
+        'surfaceAnimations',
+        'surfacePresets',
+        'surfaceCategories',
+      ]) {
+        expect(j.containsKey(k), isFalse, reason: k);
+      }
+    });
+  });
+}

```

## 16. Diff complet équivalent `/dev/null` : rapport Lot 35

```diff
diff --git a/reports/surface/surface_engine_lot_35_surface_catalog_unused_diagnostics.md b/reports/surface/surface_engine_lot_35_surface_catalog_unused_diagnostics.md
new file mode 100644
index 00000000..ec2d6aa5
--- /dev/null
+++ b/reports/surface/surface_engine_lot_35_surface_catalog_unused_diagnostics.md
@@ -0,0 +1,198 @@
+# Surface Engine — Lot 35 — Surface Catalog Unused Diagnostics V0
+
+## 1. Résumé exécutif
+
+Le lot ajoute, dans `map_core`, une seconde fonction de diagnostic **pure** sur un `ProjectSurfaceCatalog` : `diagnoseProjectSurfaceCatalogUnusedResources`, qui ne produit que des **avertissements** (`SurfaceCatalogDiagnosticSeverity.warning`) pour des atlas / animations considérés comme **non référencés** (selon des égalités de chaînes **strictes**). L’ancienne fonction `diagnoseProjectSurfaceCatalog` (Lot 34) reste **la seule** source de diagnostics d’**erreur** `missing*`. Aucun changement de persistance, manifest, JSON, Freezed, runtime, éditeur ou gameplay.
+
+## 2. Pourquoi ce lot vient après le Lot 34-bis
+
+Le Lot 34 a posé le diagnostic d’**erreur** (références invalides) ; le 34-bis a corrigé des preuves documentaires. Le 35 enchaîne sur le **même module** de diagnostics, en ajoutant un axe **séparé** (ressources inutilisées) sans modifier le contrat d’erreur du 34.
+
+## 3. Fichiers consultés (audit)
+
+- `packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart` (existant, Lot 34)
+- `packages/map_core/test/surface_catalog_diagnostics_test.dart` (regression Lot 34)
+- `packages/map_core/lib/src/models/surface_catalog.dart`, `surface.dart`
+- `packages/map_core/test/project_surface_*_test.dart` (fumée Surface)
+- `packages/map_core/lib/map_core.dart` (export déjà présent pour `surface_catalog_diagnostics.dart`)
+- Rapports 34 / 34b et spécifications Surface (périmètre)
+
+## 4. Fichiers créés
+
+- `packages/map_core/test/surface_catalog_unused_diagnostics_test.dart` (24 tests)
+- `reports/surface/surface_engine_lot_35_surface_catalog_unused_diagnostics.md` (ce rapport)
+
+## 5. Fichiers modifiés
+
+- `packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart` uniquement
+
+`map_core.dart` : **non modifié** (export Lot 34 suffisant).
+
+## 6. API ajoutée
+
+- `SurfaceCatalogDiagnosticsReport diagnoseProjectSurfaceCatalogUnusedResources(ProjectSurfaceCatalog catalog)`
+- `SurfaceCatalogDiagnosticSeverity.warning`
+- `SurfaceCatalogDiagnosticKind.unusedAtlas`, `unusedAnimation`
+
+## 7. `SurfaceCatalogDiagnosticSeverity`
+
+- Avant : `error` seul.
+- Après : `error` | `warning`.
+- Sémantique de `hasErrors` : inchangée — `true` **uniquement** s’il existe au moins un diagnostic en `error`.
+
+## 8. `SurfaceCatalogDiagnosticKind`
+
+Ajouts : `unusedAtlas`, `unusedAnimation`. Pas de `unusedPreset`.
+
+## 9. Sémantique de `diagnoseProjectSurfaceCatalogUnusedResources`
+
+Lecture seule, aucune mutation, n’appelle **pas** `diagnoseProjectSurfaceCatalog`, n’émet **aucune** `severity: error` ; détection basée sur des références en mémoire et égalité `String` exacte (pas de `trim`).
+
+## 10. `unusedAtlas`
+
+Un `ProjectSurfaceAtlas` est **utilisé** si `frame.tileRef.atlasId == atlas.id` pour au moins une frame. Sinon, un warning `unusedAtlas` (métadonnées : `atlasId` renseigné, autres cibles nulles).
+
+## 11. `unusedAnimation`
+
+Un `ProjectSurfaceAnimation` est **utilisé** si `ref.animationId == animation.id` pour au moins une `SurfaceVariantAnimationRef` d’un `ProjectSurfacePreset`. Sinon `unusedAnimation` (`animationId` renseigné).
+
+## 12. Décision : pas de `unusedPreset`
+
+Aucun autre nœud du modèle (manifest, calques, etc.) ne référence encore un preset par id ; signaler des presets inutilisés serait bruyant / trompeur.
+
+## 13. Décision : fonction séparée
+
+Les erreurs de cohérence (Lot 34) et les avertissements d’inutilisation (Lot 35) ne sont **pas** fusionnés automatiquement : l’appelant choisit quoi exécuter.
+
+## 14. Décision : ordre des diagnostics
+
+1. Tous les `unusedAtlas` dans l’ordre de `catalog.atlases`
+2. Puis tous les `unusedAnimation` dans l’ordre de `catalog.animations`  
+Aucun tri par id, message ou kind dynamique.
+
+## 15. Décision : warnings seuls dans cette fonction
+
+Garantit `hasErrors == false` pour un rapport issu **uniquement** de `diagnoseProjectSurfaceCatalogUnusedResources` (dès qu’il y a seulement des warnings, `hasDiagnostics` peut être vrai et `hasErrors` faux).
+
+## 16. Décision : comparaison exacte (sans `trim`)
+
+Aligné sur le reste des diagnostics Surface : les ids sont comparés tels quels.
+
+## 17. Relation avec `ProjectSurfaceCatalog`
+
+Source unique en mémoire : atlases, animations, presets, timelines et frames.
+
+## 18. Relation avec un futur `ProjectManifest` Surface
+
+Ce lot n’ajoute **aucun** champ Surface au manifest ; l’intégration future restera explicite et hors scope 35.
+
+## 19. Ce qui a été testé
+
+Fichier `surface_catalog_unused_diagnostics_test.dart` : cas vides, cohérent minimal, cas exacts / ordre, trim, `byKind`, immuabilité, absence d’erreurs Lot 34 dans la fonction unused, régression sur `diagnoseProjectSurfaceCatalog`, severities, V0 pas de diagnostic « preset inutilisé », manifest sans clés `surface*`, API publique.
+
+## 20. Ce que les tests prouvent
+
+- Comportement demandé des warnings et de l’ordre stable
+- Aucun effet de bord sur le diagnostic d’erreur Lot 34
+- Le manifest JSON minimal n’expose toujours pas de clés `surface*`
+
+## 21. Ce qui n’a volontairement pas été fait
+
+JSON Surface, `toJson` des diagnostics, merge auto error+warning, éditeur, runtime, gameplay, bataille, `build_runner`, validateur projet complet, images réelles, durées, rôles manquants par preset, `SurfacePresetKind` / `surfaceKind`.
+
+## 22. Pourquoi `ProjectManifest` n’a toujours pas été modifié
+
+Le périmètre Surface persistant n’est **pas** ce lot.
+
+## 23. Pourquoi aucun fichier généré
+
+Aucun modèle Freezed/JSON n’a changé.
+
+## 24. Pourquoi pas `SurfacePresetKind` / `surfaceKind`
+
+Hors cahier des charges et roadmap Surface existante (non requis pour inutilisé V0).
+
+## 25. Impact prochains lots
+
+- UI : peut combiner manuellement les deux rapports
+- Quand un consommateur de presets (carte, manifest, etc.) existera, un futur `unusedPreset` deviendra pertinent
+
+## 26. Commandes lancées
+
+```bash
+cd packages/map_core
+/opt/homebrew/bin/dart test test/surface_catalog_unused_diagnostics_test.dart
+/opt/homebrew/bin/dart test test/surface_catalog_diagnostics_test.dart
+/opt/homebrew/bin/dart test test/project_surface_catalog_test.dart
+/opt/homebrew/bin/dart test test/standard_surface_preset_builder_test.dart
+/opt/homebrew/bin/dart test test/project_surface_preset_test.dart
+/opt/homebrew/bin/dart test test/project_surface_animation_test.dart
+/opt/homebrew/bin/dart test test/project_surface_atlas_test.dart
+/opt/homebrew/bin/dart analyze lib/src/operations/surface_catalog_diagnostics.dart \
+  lib/src/models/surface_catalog.dart lib/src/models/surface.dart \
+  lib/src/operations/standard_surface_preset_builder.dart \
+  test/surface_catalog_unused_diagnostics_test.dart test/surface_catalog_diagnostics_test.dart \
+  test/project_surface_catalog_test.dart test/standard_surface_preset_builder_test.dart \
+  test/project_surface_preset_test.dart test/project_surface_animation_test.dart \
+  test/project_surface_atlas_test.dart lib/map_core.dart
+/opt/homebrew/bin/dart test
+```
+
+## 27. Résultats exacts (extraits)
+
+- Toutes les cibles de test listées : **All tests passed!**
+- `dart analyze` (chemins ciblés) : **No issues found!**
+
+## 28. `dart test` complet (map_core) — total exact
+
+- **807** tests, **All tests passed!** (sortie avec `tr '\r' '\n' | tail` : ligne finale `+807: All tests passed!`)
+
+## 29. Points de vigilance
+
+- Combiner les deux rapports côté appelant : pas de double appel implicite fourni
+- « Inutilisé » est une heuristique (références catalogue uniquement)
+
+## 30. Autocritique
+
+- Documenter côté produit, plus tard, comment présenter error vs warning
+- i18n des messages d’`unused*` : anglais pour rester cohérent avec les messages d’erreur existants
+
+## 31. Ce que le prompt semble discutable ou incomplet
+
+- Exiger « contenu intégral + diff + sorties de commande » dans un seul canevas Markdown peut dupliquer le dépôt ; ce rapport se concentre sur la preuve de comportement, les sommes de tests, et le référentiel sert de vérité unique pour les fichiers binaires longs
+- Aucun autre sujet bloquant
+
+## 32. Auto-review indépendante (checklist explicite)
+
+| Question | Oui / Non |
+|----------|-----------|
+| Lot limité aux diagnostics unused du catalogue Surface | Oui |
+| Aucun `ProjectManifest` modifié | Oui |
+| Aucun champ Surface persistant ajouté au manifest | Oui |
+| Aucun `SurfacePresetKind` / `surfaceKind` créé | Oui |
+| Aucun `unusedPreset` créé | Oui |
+| Aucun modèle Freezed/JSON généré | Oui |
+| Aucun `.g.dart` / `.freezed.dart` | Oui |
+| Aucun runtime/editor/gameplay/battle modifié | Oui |
+| `diagnoseProjectSurfaceCatalog` reste l’API d’erreur Lot 34 | Oui (non modifié) |
+| `diagnoseProjectSurfaceCatalogUnusedResources` n’émet que des warnings | Oui |
+| `unusedAtlas` : égalité exacte | Oui |
+| `unusedAnimation` : égalité exacte | Oui |
+| Warnings n’affectent pas `hasErrors` | Oui |
+| Listes exposées immuables | Oui (inchangé) |
+| Export public | Oui (`map_core` existant) |
+| Test manifest sans clés Surface | Oui (test 24) |
+| `map_core` complet vert, total 807 | Oui |
+| Contenus / diffs : voir section 33–34 et dépôt | Oui |
+| Pas de commande Git d’écriture utilisée ici | Oui (read-only) |
+
+## 33. Contenu des fichiers créés / modifiés (référence)
+
+Voir les fichiers finaux dans le dépôt :
+
+- `packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart` (fichier complet, 312 lignes)
+- `packages/map_core/test/surface_catalog_unused_diagnostics_test.dart` (fichier complet, 487 lignes)
+
+## 34. Diff complet réel (fichier modifié suivi)
+
+Le diff de `git diff packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart` est reproduit dans l’artefact de livraison / journal de tâche (hors de ce fichier pour limiter la taille du rapport versionné) ; le fichier de test est **untracked** jusqu’à `git add` (équivalent diff : contenu intégral du fichier de test).

```

## 17. Commandes relancées (reproduction exacte)

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_catalog_unused_diagnostics_test.dart
```
```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_catalog_diagnostics_test.dart
```
```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze \
  lib/src/operations/surface_catalog_diagnostics.dart \
  lib/src/models/surface_catalog.dart \
  lib/src/models/surface.dart \
  lib/src/operations/standard_surface_preset_builder.dart \
  test/surface_catalog_unused_diagnostics_test.dart \
  test/surface_catalog_diagnostics_test.dart \
  test/project_surface_catalog_test.dart \
  test/standard_surface_preset_builder_test.dart \
  test/project_surface_preset_test.dart \
  test/project_surface_animation_test.dart \
  test/project_surface_atlas_test.dart \
  lib/map_core.dart
```
```bash
cd packages/map_core
/opt/homebrew/bin/dart test
```
(Pour la dernière, sortie transformée : `2>&1 | tr '\r' '\n'` afin d’avoir **une ligne par mise à jour** de progression ; sortie intégrale en section 18.4.)

## 18. Résultats exacts des commandes (sorties intégrales)

### 18.1 `dart test test/surface_catalog_unused_diagnostics_test.dart`

```text

00:00 [32m+0[0m: [1m[90mloading test/surface_catalog_unused_diagnostics_test.dart[0m[0m                                                                                                                                    
00:00 [32m+0[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                                                                                
00:00 [32m+1[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                                                                                
00:00 [32m+1[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 2. minimal coherent: no unused diagnostics[0m                                                                                             
00:00 [32m+2[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 2. minimal coherent: no unused diagnostics[0m                                                                                             
00:00 [32m+2[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 3. unreferenced atlas → unusedAtlas warning and metadata[0m                                                                               
00:00 [32m+3[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 3. unreferenced atlas → unusedAtlas warning and metadata[0m                                                                               
00:00 [32m+3[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 4. multiple unused atlases: order follows catalog.atlases a,b,c[0m                                                                        
00:00 [32m+4[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 4. multiple unused atlases: order follows catalog.atlases a,b,c[0m                                                                        
00:00 [32m+4[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 5. atlas used by a frame: no unusedAtlas (may be unusedAnimation)[0m                                                                      
00:00 [32m+5[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 5. atlas used by a frame: no unusedAtlas (may be unusedAnimation)[0m                                                                      
00:00 [32m+5[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 6. atlas id exact: spaced atlas not matched by frame atlasId[0m                                                                           
00:00 [32m+6[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 6. atlas id exact: spaced atlas not matched by frame atlasId[0m                                                                           
00:00 [32m+6[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 7. animation not referenced by preset → unusedAnimation[0m                                                                                
00:00 [32m+7[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 7. animation not referenced by preset → unusedAnimation[0m                                                                                
00:00 [32m+7[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 8. multiple unused animations: order follows catalog.animations a,b,c[0m                                                                  
00:00 [32m+8[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 8. multiple unused animations: order follows catalog.animations a,b,c[0m                                                                  
00:00 [32m+8[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 9. animation referenced by a preset: not unused[0m                                                                                        
00:00 [32m+9[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 9. animation referenced by a preset: not unused[0m                                                                                        
00:00 [32m+9[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 10. animationId exact: spaced id not matched by preset ref[0m                                                                             
00:00 [32m+10[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 10. animationId exact: spaced id not matched by preset ref[0m                                                                            
00:00 [32m+10[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 11. same animation referenced by two presets: not unused[0m                                                                              
00:00 [32m+11[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 11. same animation referenced by two presets: not unused[0m                                                                              
00:00 [32m+11[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 12. same atlas referenced by two animations: atlas not unused[0m                                                                         
00:00 [32m+12[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 12. same atlas referenced by two animations: atlas not unused[0m                                                                         
00:00 [32m+12[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 13. global order: unusedAtlas before unusedAnimation[0m                                                                                  
00:00 [32m+13[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 13. global order: unusedAtlas before unusedAnimation[0m                                                                                  
00:00 [32m+13[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 14. warnings only: hasErrors false, hasDiagnostics true[0m                                                                               
00:00 [32m+14[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 14. warnings only: hasErrors false, hasDiagnostics true[0m                                                                               
00:00 [32m+14[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 15. byKind(unusedAtlas) only atlas warnings[0m                                                                                           
00:00 [32m+15[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 15. byKind(unusedAtlas) only atlas warnings[0m                                                                                           
00:00 [32m+15[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 16. byKind(unusedAnimation) only animation warnings[0m                                                                                   
00:00 [32m+16[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 16. byKind(unusedAnimation) only animation warnings[0m                                                                                   
00:00 [32m+16[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 17. byKind returns an unmodifiable list (add → UnsupportedError)[0m                                                                      
00:00 [32m+17[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 17. byKind returns an unmodifiable list (add → UnsupportedError)[0m                                                                      
00:00 [32m+17[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 18. diagnostics list is unmodifiable (add → UnsupportedError)[0m                                                                         
00:00 [32m+18[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 18. diagnostics list is unmodifiable (add → UnsupportedError)[0m                                                                         
00:00 [32m+18[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 19. unused function does not emit Lot 34 error kinds[0m                                                                                  
00:00 [32m+19[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 19. unused function does not emit Lot 34 error kinds[0m                                                                                  
00:00 [32m+19[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 20. Lot 34 diagnoseProjectSurfaceCatalog still returns errors[0m                                                                         
00:00 [32m+20[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 20. Lot 34 diagnoseProjectSurfaceCatalog still returns errors[0m                                                                         
00:00 [32m+20[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 21. warning severity exists and differs from error[0m                                                                                    
00:00 [32m+21[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 21. warning severity exists and differs from error[0m                                                                                    
00:00 [32m+21[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) V0 does not diagnose unused presets yet: isolated preset, no false presetId[0m                                                           
00:00 [32m+22[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) V0 does not diagnose unused presets yet: isolated preset, no false presetId[0m                                                           
00:00 [32m+22[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 23. public API: unused + kinds via map_core only[0m                                                                                      
00:00 [32m+23[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 23. public API: unused + kinds via map_core only[0m                                                                                      
00:00 [32m+23[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 24. ProjectManifest still has no Surface keys (Lot 35)[0m                                                                                
00:00 [32m+24[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 24. ProjectManifest still has no Surface keys (Lot 35)[0m                                                                                
00:00 [32m+24[0m: All tests passed![0m                                                                                                                                                                           

```

### 18.2 `dart test test/surface_catalog_diagnostics_test.dart`

```text

00:00 [32m+0[0m: [1m[90mloading test/surface_catalog_diagnostics_test.dart[0m[0m                                                                                                                                           
00:00 [32m+0[0m: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics[0m                                                                                                                      
00:00 [32m+1[0m: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics[0m                                                                                                                      
00:00 [32m+1[0m: diagnoseProjectSurfaceCatalog (Lot 34) 2. minimal coherent: no diagnostics[0m                                                                                                                   
00:00 [32m+2[0m: diagnoseProjectSurfaceCatalog (Lot 34) 2. minimal coherent: no diagnostics[0m                                                                                                                   
00:00 [32m+2[0m: diagnoseProjectSurfaceCatalog (Lot 34) 3. missing preset animation[0m                                                                                                                           
00:00 [32m+3[0m: diagnoseProjectSurfaceCatalog (Lot 34) 3. missing preset animation[0m                                                                                                                           
00:00 [32m+3[0m: diagnoseProjectSurfaceCatalog (Lot 34) 4. two missing refs: order follows refs[0m                                                                                                               
00:00 [32m+4[0m: diagnoseProjectSurfaceCatalog (Lot 34) 4. two missing refs: order follows refs[0m                                                                                                               
00:00 [32m+4[0m: diagnoseProjectSurfaceCatalog (Lot 34) 5. two presets: order follows catalog.presets[0m                                                                                                         
00:00 [32m+5[0m: diagnoseProjectSurfaceCatalog (Lot 34) 5. two presets: order follows catalog.presets[0m                                                                                                         
00:00 [32m+5[0m: diagnoseProjectSurfaceCatalog (Lot 34) 6. missing animation atlas[0m                                                                                                                            
00:00 [32m+6[0m: diagnoseProjectSurfaceCatalog (Lot 34) 6. missing animation atlas[0m                                                                                                                            
00:00 [32m+6[0m: diagnoseProjectSurfaceCatalog (Lot 34) 7. two frames to missing atlas: frameIndex 0 and 1[0m                                                                                                    
00:00 [32m+7[0m: diagnoseProjectSurfaceCatalog (Lot 34) 7. two frames to missing atlas: frameIndex 0 and 1[0m                                                                                                    
00:00 [32m+7[0m: diagnoseProjectSurfaceCatalog (Lot 34) 8. frame outside geometry: column[0m                                                                                                                     
00:00 [32m+8[0m: diagnoseProjectSurfaceCatalog (Lot 34) 8. frame outside geometry: column[0m                                                                                                                     
00:00 [32m+8[0m: diagnoseProjectSurfaceCatalog (Lot 34) 9. frame outside geometry: row[0m                                                                                                                        
00:00 [32m+9[0m: diagnoseProjectSurfaceCatalog (Lot 34) 9. frame outside geometry: row[0m                                                                                                                        
00:00 [32m+9[0m: diagnoseProjectSurfaceCatalog (Lot 34) 10. missing atlas only: not also outside geometry[0m                                                                                                     
00:00 [32m+10[0m: diagnoseProjectSurfaceCatalog (Lot 34) 10. missing atlas only: not also outside geometry[0m                                                                                                    
00:00 [32m+10[0m: diagnoseProjectSurfaceCatalog (Lot 34) 11. preset diagnostics then animation diagnostics[0m                                                                                                    
00:00 [32m+11[0m: diagnoseProjectSurfaceCatalog (Lot 34) 11. preset diagnostics then animation diagnostics[0m                                                                                                    
00:00 [32m+11[0m: diagnoseProjectSurfaceCatalog (Lot 34) 12. exact atlas id: no trim[0m                                                                                                                          
00:00 [32m+12[0m: diagnoseProjectSurfaceCatalog (Lot 34) 12. exact atlas id: no trim[0m                                                                                                                          
00:00 [32m+12[0m: diagnoseProjectSurfaceCatalog (Lot 34) 13. byKind filters[0m                                                                                                                                   
00:00 [32m+13[0m: diagnoseProjectSurfaceCatalog (Lot 34) 13. byKind filters[0m                                                                                                                                   
00:00 [32m+13[0m: diagnoseProjectSurfaceCatalog (Lot 34) 14. byKind list is unmodifiable[0m                                                                                                                      
00:00 [32m+14[0m: diagnoseProjectSurfaceCatalog (Lot 34) 14. byKind list is unmodifiable[0m                                                                                                                      
00:00 [32m+14[0m: diagnoseProjectSurfaceCatalog (Lot 34) 15. diagnostics list on report is unmodifiable[0m                                                                                                       
00:00 [32m+15[0m: diagnoseProjectSurfaceCatalog (Lot 34) 15. diagnostics list on report is unmodifiable[0m                                                                                                       
00:00 [32m+15[0m: diagnoseProjectSurfaceCatalog (Lot 34) 16. defensive copy: mutating source list does not change report[0m                                                                                      
00:00 [32m+16[0m: diagnoseProjectSurfaceCatalog (Lot 34) 16. defensive copy: mutating source list does not change report[0m                                                                                      
00:00 [32m+16[0m: diagnoseProjectSurfaceCatalog (Lot 34) 17. hasErrors false on empty report[0m                                                                                                                  
00:00 [32m+17[0m: diagnoseProjectSurfaceCatalog (Lot 34) 17. hasErrors false on empty report[0m                                                                                                                  
00:00 [32m+17[0m: diagnoseProjectSurfaceCatalog (Lot 34) 18. hasErrors true when error diagnostic[0m                                                                                                             
00:00 [32m+18[0m: diagnoseProjectSurfaceCatalog (Lot 34) 18. hasErrors true when error diagnostic[0m                                                                                                             
00:00 [32m+18[0m: diagnoseProjectSurfaceCatalog (Lot 34) 19. diagnostic equality: same[0m                                                                                                                        
00:00 [32m+19[0m: diagnoseProjectSurfaceCatalog (Lot 34) 19. diagnostic equality: same[0m                                                                                                                        
00:00 [32m+19[0m: diagnoseProjectSurfaceCatalog (Lot 34) 20. diagnostic equality: different kind[0m                                                                                                              
00:00 [32m+20[0m: diagnoseProjectSurfaceCatalog (Lot 34) 20. diagnostic equality: different kind[0m                                                                                                              
00:00 [32m+20[0m: diagnoseProjectSurfaceCatalog (Lot 34) 21. diagnostic equality: different metadata[0m                                                                                                          
00:00 [32m+21[0m: diagnoseProjectSurfaceCatalog (Lot 34) 21. diagnostic equality: different metadata[0m                                                                                                          
00:00 [32m+21[0m: diagnoseProjectSurfaceCatalog (Lot 34) 22. report equality: same order[0m                                                                                                                      
00:00 [32m+22[0m: diagnoseProjectSurfaceCatalog (Lot 34) 22. report equality: same order[0m                                                                                                                      
00:00 [32m+22[0m: diagnoseProjectSurfaceCatalog (Lot 34) 23. report equality: order matters[0m                                                                                                                   
00:00 [32m+23[0m: diagnoseProjectSurfaceCatalog (Lot 34) 23. report equality: order matters[0m                                                                                                                   
00:00 [32m+23[0m: diagnoseProjectSurfaceCatalog (Lot 34) 24. public API via map_core[0m                                                                                                                          
00:00 [32m+24[0m: diagnoseProjectSurfaceCatalog (Lot 34) 24. public API via map_core[0m                                                                                                                          
00:00 [32m+24[0m: diagnoseProjectSurfaceCatalog (Lot 34) 25. ProjectManifest still has no Surface keys (Lot 34)[0m                                                                                               
00:00 [32m+25[0m: diagnoseProjectSurfaceCatalog (Lot 34) 25. ProjectManifest still has no Surface keys (Lot 34)[0m                                                                                               
00:00 [32m+25[0m: All tests passed![0m                                                                                                                                                                           

```

### 18.3 `dart analyze` (chemins ciblés)

```text
Analyzing surface_catalog_diagnostics.dart, surface_catalog.dart, surface.dart, standard_surface_preset_builder.dart, surface_catalog_unused_diagnostics_test.dart, surface_catalog_diagnostics_test.dart, project_surface_catalog_test.dart, standard_surface_preset_builder_test.dart, project_surface_preset_test.dart, project_surface_animation_test.dart, project_surface_atlas_test.dart, map_core.dart...
No issues found!

```

### 18.4 `dart test` (suite complète `map_core`, sortie intégrale, `tr \\r \\n`)

Nombre de lignes de sortie : **1133** (voir intégralité ci-dessous).

```text

00:00 [32m+0[0m: [1m[90mloading test/placed_element_animation_test.dart[0m[0m                                                                                                                                              
00:00 [32m+0[0m: test/placed_element_animation_test.dart: MapPlacedElementAnimation serialization serializes and deserializes on placed element[0m                                                               
00:00 [32m+1[0m: test/game_state_persistence_test.dart: gameStateFromSaveData migrates legacy save fields to GameState[0m                                                                                        
00:00 [32m+2[0m: test/game_state_persistence_test.dart: gameStateFromSaveData migrates legacy save fields to GameState[0m                                                                                        
00:00 [32m+3[0m: test/game_state_persistence_test.dart: gameStateFromSaveData migrates legacy save fields to GameState[0m                                                                                        
00:00 [32m+4[0m: test/game_state_persistence_test.dart: gameStateFromSaveData migrates legacy save fields to GameState[0m                                                                                        
00:00 [32m+5[0m: test/game_state_persistence_test.dart: gameStateFromSaveData migrates legacy save fields to GameState[0m                                                                                        
00:00 [32m+6[0m: test/save_data_test.dart: PokemonStatSpread serialization round-trip[0m                                                                                                                         
00:00 [32m+7[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                            
00:00 [32m+8[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                            
00:00 [32m+9[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                            
00:00 [32m+10[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+11[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+12[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+13[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+14[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+15[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+16[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+17[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+18[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+19[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+20[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+21[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+22[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+23[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+24[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+25[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+26[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+27[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+28[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+29[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                           
00:00 [32m+30[0m: test/standard_lava_path_preset_vertical_atlas_builder_test.dart: createStandardLavaPathPresetFromVerticalAtlas preset generation preserves categoryId and sortOrder[0m                         
00:00 [32m+31[0m: test/save_data_test.dart: TrainerProfile normalized rejects empty names[0m                                                                                                                     
00:00 [32m+32[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a move with a secondary status effect[0m                                                                                          
00:00 [32m+33[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a move with a secondary status effect[0m                                                                                          
00:00 [32m+34[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a move with a secondary status effect[0m                                                                                          
00:00 [32m+35[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a move with a secondary status effect[0m                                                                                          
00:00 [32m+36[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a move with a secondary status effect[0m                                                                                          
00:00 [32m+37[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a move with a secondary status effect[0m                                                                                          
00:00 [32m+38[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a move with a secondary status effect[0m                                                                                          
00:00 [32m+39[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a move with a secondary status effect[0m                                                                                          
00:00 [32m+40[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a move with a secondary status effect[0m                                                                                          
00:00 [32m+41[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a move with a secondary status effect[0m                                                                                          
00:00 [32m+42[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a move with a secondary status effect[0m                                                                                          
00:00 [32m+43[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a move with a secondary status effect[0m                                                                                          
00:00 [32m+44[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a move with a secondary status effect[0m                                                                                          
00:00 [32m+45[0m: test/save_data_test.dart: SaveData serialization round-trip[0m                                                                                                                                 
00:00 [32m+46[0m: test/save_data_test.dart: SaveData serialization round-trip[0m                                                                                                                                 
00:00 [32m+47[0m: test/save_data_test.dart: SaveData serialization round-trip[0m                                                                                                                                 
00:00 [32m+48[0m: test/save_data_test.dart: SaveData serialization round-trip[0m                                                                                                                                 
00:00 [32m+49[0m: test/save_data_test.dart: SaveData serialization round-trip[0m                                                                                                                                 
00:00 [32m+50[0m: test/standard_lava_path_preset_vertical_atlas_builder_test.dart: createStandardLavaPathPresetFromVerticalAtlas compatibility is compatible with LegacyProjectSurfaceCatalogView[0m             
00:00 [32m+51[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON keeps engine support metadata[0m                                                                                                      
00:00 [32m+52[0m: test/save_data_test.dart: SaveData defaults are coherent[0m                                                                                                                                    
00:00 [32m+53[0m: test/standard_lava_path_preset_vertical_atlas_builder_test.dart: createStandardLavaPathPresetFromVerticalAtlas compatibility is compatible with resolveTileVisualFrameTimeline[0m              
00:00 [32m+54[0m: test/standard_lava_path_preset_vertical_atlas_builder_test.dart: createStandardLavaPathPresetFromVerticalAtlas compatibility is compatible with resolveTileVisualFrameTimeline[0m              
00:00 [32m+55[0m: test/standard_lava_path_preset_vertical_atlas_builder_test.dart: createStandardLavaPathPresetFromVerticalAtlas compatibility is compatible with resolveTileVisualFrameTimeline[0m              
00:00 [32m+56[0m: test/pokemon_move_test.dart: PokemonMove fromJson enforces normalization for blank ids[0m                                                                                                      
00:00 [32m+57[0m: test/pokemon_move_test.dart: PokemonMove fromJson enforces normalization for blank ids[0m                                                                                                      
00:00 [32m+58[0m: test/standard_lava_path_preset_vertical_atlas_builder_test.dart: createStandardLavaPathPresetFromVerticalAtlas validation delegation delegates validation for empty id[0m                      
00:00 [32m+59[0m: test/pokemon_move_test.dart: PokemonMove can represent a move with stat changes and recoil[0m                                                                                                  
00:00 [32m+60[0m: test/pokemon_move_test.dart: PokemonMove can represent a move with stat changes and recoil[0m                                                                                                  
00:00 [32m+61[0m: test/pokemon_move_test.dart: PokemonMove can represent a move with stat changes and recoil[0m                                                                                                  
00:00 [32m+62[0m: test/standard_lava_path_preset_vertical_atlas_builder_test.dart: createStandardLavaPathPresetFromVerticalAtlas validation delegation delegates validation for negative firstColumn[0m          
00:00 [32m+63[0m: test/pokemon_move_test.dart: PokemonMove normalized trims ids and dedupes flags and unsupported reasons[0m                                                                                     
00:00 [32m+64[0m: test/pokemon_move_test.dart: PokemonMove normalized trims ids and dedupes flags and unsupported reasons[0m                                                                                     
00:00 [32m+65[0m: test/standard_lava_path_preset_vertical_atlas_builder_test.dart: createStandardLavaPathPresetFromVerticalAtlas validation delegation delegates validation for empty variants[0m                
00:00 [32m+66[0m: test/pokemon_move_test.dart: PokemonMove normalized rejects blank id[0m                                                                                                                        
00:00 [32m+67[0m: test/standard_lava_path_preset_vertical_atlas_builder_test.dart: createStandardLavaPathPresetFromVerticalAtlas validation delegation delegates validation for duplicate variants[0m            
00:00 [32m+68[0m: test/pokemon_move_test.dart: PokemonMove normalized rejects blank name[0m                                                                                                                      
00:00 [32m+69[0m: test/standard_lava_path_preset_vertical_atlas_builder_test.dart: createStandardLavaPathPresetFromVerticalAtlas validation delegation delegates validation for invalid frameCount[0m            
00:00 [32m+70[0m: test/pokemon_move_test.dart: PokemonMoveAccuracy serializes percent accuracy[0m                                                                                                                
00:00 [32m+71[0m: test/standard_lava_path_preset_vertical_atlas_builder_test.dart: createStandardLavaPathPresetFromVerticalAtlas validation delegation delegates validation for invalid source dimensions[0m     
00:00 [32m+72[0m: test/pokemon_move_test.dart: PokemonMoveAccuracy serializes always hits accuracy[0m                                                                                                            
00:00 [32m+73[0m: test/standard_lava_path_preset_vertical_atlas_builder_test.dart: createStandardLavaPathPresetFromVerticalAtlas validation delegation delegates validation for invalid defaultDurationMs[0m     
00:00 [32m+74[0m: test/pokemon_move_test.dart: PokemonMoveAccuracy normalized rejects out-of-range percent accuracy[0m                                                                                           
00:00 [32m+75[0m: test/standard_lava_path_preset_vertical_atlas_builder_test.dart: ... validation delegation delegates validation for frameDurationsMs length mismatch[0m                                        
00:00 [32m+76[0m: test/pokemon_move_test.dart: PokemonMoveAccuracy fromJson rejects out-of-range percent accuracy[0m                                                                                             
00:00 [32m+77[0m: test/standard_lava_path_preset_vertical_atlas_builder_test.dart: createStandardLavaPathPresetFromVerticalAtlas validation delegation delegates validation for non-positive frame durations[0m  
00:00 [32m+78[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for fixed damage[0m                                                                                                             
00:00 [32m+79[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for fixed damage[0m                                                                                                             
00:00 [32m+79[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for setWeather[0m                                                                                                               
00:00 [32m+80[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for setWeather[0m                                                                                                               
00:00 [32m+80[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for setTerrain[0m                                                                                                               
00:00 [32m+81[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for setTerrain[0m                                                                                                               
00:00 [32m+81[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for setPseudoWeather[0m                                                                                                         
00:00 [32m+82[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for setPseudoWeather[0m                                                                                                         
00:00 [32m+82[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for setSideCondition[0m                                                                                                         
00:00 [32m+83[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for setSideCondition[0m                                                                                                         
00:00 [32m+83[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for setSlotCondition[0m                                                                                                         
00:00 [32m+84[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for setSlotCondition[0m                                                                                                         
00:00 [32m+84[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for forceSwitch[0m                                                                                                              
00:00 [32m+85[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for forceSwitch[0m                                                                                                              
00:00 [32m+85[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for requireRecharge[0m                                                                                                          
00:00 [32m+86[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for requireRecharge[0m                                                                                                          
00:00 [32m+86[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for chargeThenStrike[0m                                                                                                         
00:00 [32m+87[0m: test/pokemon_move_test.dart: PokemonMoveEffect round-trip JSON for chargeThenStrike[0m                                                                                                         
00:00 [32m+87[0m: test/pokemon_move_test.dart: PokemonMoveEffect normalized rejects invalid multiHit range[0m                                                                                                    
00:00 [32m+88[0m: test/pokemon_move_test.dart: PokemonMoveEffect normalized rejects invalid multiHit range[0m                                                                                                    
00:00 [32m+88[0m: test/pokemon_move_test.dart: PokemonMoveEffect fromJson rejects invalid multiHit range[0m                                                                                                      
00:00 [32m+89[0m: test/pokemon_move_test.dart: PokemonMoveEffect fromJson rejects invalid multiHit range[0m                                                                                                      
00:00 [32m+89[0m: [1m[90mloading test/surface_atlas_geometry_test.dart[0m[0m                                                                                                                                               
00:00 [32m+89[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                          
00:00 [32m+90[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                          
00:00 [32m+90[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize rejects non-positive width: 0[0m                                                                                                   
00:00 [32m+91[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize rejects non-positive width: 0[0m                                                                                                   
00:00 [32m+91[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize rejects non-positive width: -1[0m                                                                                                  
00:00 [32m+92[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize rejects non-positive width: -1[0m                                                                                                  
00:00 [32m+92[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize rejects non-positive height: 0[0m                                                                                                  
00:00 [32m+93[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize rejects non-positive height: 0[0m                                                                                                  
00:00 [32m+93[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize rejects non-positive height: -1[0m                                                                                                 
00:00 [32m+94[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                                
00:00 [32m+95[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                                
00:00 [32m+96[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                                
00:00 [32m+97[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                                
00:00 [32m+98[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                                
00:00 [32m+99[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                                
00:00 [32m+100[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                               
00:00 [32m+101[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                               
00:00 [32m+102[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                               
00:00 [32m+103[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                               
00:00 [32m+104[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                               
00:00 [32m+105[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                               
00:00 [32m+106[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                               
00:00 [32m+107[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                               
00:00 [32m+108[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                               
00:00 [32m+109[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                               
00:00 [32m+110[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns no diagnostics for healthy declared and used surfaces[0m                                               
00:00 [32m+110[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics warns when a used TerrainType has no declared terrain surface[0m                                               
00:00 [32m+111[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics warns when a used TerrainType has no declared terrain surface[0m                                               
00:00 [32m+111[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics warns when a used TerrainType has multiple declared candidates[0m                                              
00:00 [32m+112[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics warns when a used TerrainType has multiple declared candidates[0m                                              
00:00 [32m+112[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics reports declared terrain surfaces without matching usage as info[0m                                            
00:00 [32m+113[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics reports declared terrain surfaces without matching usage as info[0m                                            
00:00 [32m+113[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics warns when a used terrain candidate has no variants[0m                                                         
00:00 [32m+114[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics warns when a used terrain candidate has no variants[0m                                                         
00:00 [32m+114[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics warns for non-empty missing path preset usage[0m                                                               
00:00 [32m+115[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics warns for non-empty missing path preset usage[0m                                                               
00:00 [32m+115[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics warns for active path usage with an empty preset id[0m                                                         
00:00 [32m+116[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics warns for active path usage with an empty preset id[0m                                                         
00:00 [32m+116[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics reports declared path surfaces without usage as info[0m                                                        
00:00 [32m+117[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics reports declared path surfaces without usage as info[0m                                                        
00:00 [32m+117[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics warns when a used path id has multiple declared candidates[0m                                                  
00:00 [32m+118[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics warns when a used path id has multiple declared candidates[0m                                                  
00:00 [32m+118[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics warns when a used path surface has no variants[0m                                                              
00:00 [32m+119[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics warns when a used path surface has no variants[0m                                                              
00:00 [32m+119[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics keeps global diagnostic order deterministic[0m                                                                 
00:00 [32m+120[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics keeps global diagnostic order deterministic[0m                                                                 
00:00 [32m+120[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns an unmodifiable diagnostics list[0m                                                                    
00:00 [32m+121[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics returns an unmodifiable diagnostics list[0m                                                                    
00:00 [32m+121[0m: test/legacy_surface_usage_diagnostics_test.dart: LegacySurfaceUsageDiagnostics does not mutate catalog or usage inputs[0m                                                                     
00:00 [32m+122[0m: test/scenario_assets_test.dart: ScenarioAsset serialization round-trips scenario with bindings and condition payload[0m                                                                       
00:00 [32m+123[0m: test/scenario_assets_test.dart: ScenarioAsset serialization round-trips scenario with bindings and condition payload[0m                                                                       
00:00 [32m+124[0m: test/scenario_assets_test.dart: ScenarioAsset serialization round-trips scenario with bindings and condition payload[0m                                                                       
00:00 [32m+125[0m: test/dialogue_library_tree_test.dart: buildDialogueLibraryTree nests folders and assigns dialogues to correct parents[0m                                                                      
00:00 [32m+126[0m: test/scenario_assets_test.dart: ScenarioAsset validation accepts valid scenario inside project manifest[0m                                                                                    
00:00 [32m+127[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+128[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+129[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+130[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+131[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+132[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+133[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+134[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+134[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy behavior list without ids receives stable non-empty ids[0m                                                
00:00 [32m+135[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy behavior list without ids receives stable non-empty ids[0m                                                
00:00 [32m+135[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration parses onExit and onNear triggers from json[0m                                                                   
00:00 [32m+136[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration parses onExit and onNear triggers from json[0m                                                                   
00:00 [32m+136[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration serializes and deserializes optional cooldownMs[0m                                                               
00:00 [32m+137[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration serializes and deserializes optional cooldownMs[0m                                                               
00:00 [32m+137[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy behavior json without cooldownMs/triggerScope keeps defaults[0m                                           
00:00 [32m+138[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy behavior json without cooldownMs/triggerScope keeps defaults[0m                                           
00:00 [32m+138[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects behavior with empty id[0m                                                                               
00:00 [32m+139[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects behavior with empty id[0m                                                                               
00:00 [32m+139[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects showMessage without text[0m                                                                             
00:00 [32m+140[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects showMessage without text[0m                                                                             
00:00 [32m+140[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects openDialogue without dialogue ref[0m                                                                    
00:00 [32m+141[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects openDialogue without dialogue ref[0m                                                                    
00:00 [32m+141[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects setAnimationEnabled without value[0m                                                                    
00:00 [32m+142[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects setAnimationEnabled without value[0m                                                                    
00:00 [32m+142[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects duplicate behavior ids in same instance[0m                                                              
00:00 [32m+143[0m: test/project_trainer_validation_test.dart: ProjectTrainerEntry validation rejects battleDifficulty values outside the authored 1..10 range[0m                                                 
00:00 [32m+144[0m: test/project_trainer_validation_test.dart: ProjectTrainerEntry validation rejects battleDifficulty values outside the authored 1..10 range[0m                                                 
00:00 [32m+145[0m: test/project_trainer_validation_test.dart: ProjectTrainerEntry validation rejects battleDifficulty values outside the authored 1..10 range[0m                                                 
00:00 [32m+146[0m: test/project_trainer_validation_test.dart: ProjectTrainerEntry validation rejects battleDifficulty values outside the authored 1..10 range[0m                                                 
00:00 [32m+147[0m: test/project_trainer_validation_test.dart: ProjectTrainerEntry validation rejects battleDifficulty values outside the authored 1..10 range[0m                                                 
00:00 [32m+148[0m: test/project_trainer_validation_test.dart: ProjectTrainerEntry validation rejects battleDifficulty values outside the authored 1..10 range[0m                                                 
00:00 [32m+149[0m: test/surface_model_entrypoint_test.dart: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) SurfaceAtlasLayout.values exposes exactly the expected cases in order[0m                      
00:00 [32m+150[0m: test/surface_model_entrypoint_test.dart: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) SurfaceAtlasLayout.values exposes exactly the expected cases in order[0m                      
00:00 [32m+151[0m: test/surface_model_entrypoint_test.dart: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) SurfaceAtlasLayout.values exposes exactly the expected cases in order[0m                      
00:00 [32m+151[0m: test/surface_model_entrypoint_test.dart: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectManifest JSON has no surface engine manifest keys yet[0m                               
00:00 [32m+152[0m: test/surface_model_entrypoint_test.dart: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectManifest JSON has no surface engine manifest keys yet[0m                               
00:00 [32m+152[0m: test/surface_model_entrypoint_test.dart: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectPathPreset construction remains available unchanged[0m                                 
00:00 [32m+153[0m: test/surface_model_entrypoint_test.dart: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectPathPreset construction remains available unchanged[0m                                 
00:00 [32m+153[0m: [1m[90mloading test/element_collision_mask_codec_test.dart[0m[0m                                                                                                                                        
00:00 [32m+153[0m: test/element_collision_mask_codec_test.dart: ElementCollisionMaskCodec packed bits roundtrip preserves mask[0m                                                                                
00:00 [32m+154[0m: test/project_element_frames_test.dart: ProjectElementEntry frames serializes and deserializes multi-frame element[0m                                                                          
00:00 [32m+155[0m: test/project_element_frames_test.dart: ProjectElementEntry frames serializes and deserializes multi-frame element[0m                                                                          
00:00 [32m+156[0m: test/project_element_frames_test.dart: ProjectElementEntry frames serializes and deserializes multi-frame element[0m                                                                          
00:00 [32m+156[0m: test/project_element_frames_test.dart: ProjectElementEntry frames validator rejects non-positive frame duration[0m                                                                            
00:00 [32m+157[0m: test/project_element_frames_test.dart: ProjectElementEntry frames validator rejects non-positive frame duration[0m                                                                            
00:00 [32m+157[0m: [1m[90mloading test/map_entity_editor_visual_test.dart[0m[0m                                                                                                                                            
00:00 [32m+157[0m: test/map_entity_editor_visual_test.dart: MapEntityEditorVisual defaults to background entity rendering[0m                                                                                     
00:00 [32m+158[0m: test/map_entity_editor_visual_test.dart: MapEntityEditorVisual defaults to background entity rendering[0m                                                                                     
00:00 [32m+158[0m: test/map_entity_editor_visual_test.dart: MapEntityEditorVisual serializes and exposes the foreground render flag[0m                                                                           
00:00 [32m+159[0m: test/map_entity_editor_visual_test.dart: MapEntityEditorVisual serializes and exposes the foreground render flag[0m                                                                           
00:00 [32m+159[0m: [1m[90mloading test/project_surface_animation_test.dart[0m[0m                                                                                                                                           
00:00 [32m+159[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation minimal animation: fields and delegation[0m                                                                                 
00:00 [32m+160[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation minimal animation: fields and delegation[0m                                                                                 
00:00 [32m+160[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation preserves the exact same timeline instance[0m                                                                               
00:00 [32m+161[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation preserves the exact same timeline instance[0m                                                                               
00:00 [32m+161[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation preserves syncGroupId, categoryId, sortOrder[0m                                                                             
00:00 [32m+162[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation preserves syncGroupId, categoryId, sortOrder[0m                                                                             
00:00 [32m+162[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation stores id, name, syncGroupId strings exactly without auto-trim[0m                                                           
00:00 [32m+163[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation stores id, name, syncGroupId strings exactly without auto-trim[0m                                                           
00:00 [32m+163[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation rejects empty id: empty string[0m                                                                                           
00:00 [32m+164[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+165[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+166[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+167[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+168[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+169[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+170[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+171[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+172[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+173[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+174[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+175[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+176[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+177[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+178[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+179[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+180[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+181[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when no maps are provided[0m                                                          
00:00 [32m+182[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation value equality: syncGroupId differs[0m                                                                                      
00:00 [32m+183[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation value equality: syncGroupId differs[0m                                                                                      
00:00 [32m+183[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation value equality: categoryId differs[0m                                                                                       
00:00 [32m+184[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when maps have no surface layers[0m                                                   
00:00 [32m+185[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when maps have no surface layers[0m                                                   
00:00 [32m+186[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when maps have no surface layers[0m                                                   
00:00 [32m+187[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView empty inputs returns empty view when maps have no surface layers[0m                                                   
00:00 [32m+188[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation ProjectManifest toJson: no surface* top-level keys[0m                                                                       
00:00 [32m+189[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation ProjectManifest toJson: no surface* top-level keys[0m                                                                       
00:00 [32m+190[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation ProjectManifest toJson: no surface* top-level keys[0m                                                                       
00:00 [32m+191[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation ProjectManifest toJson: no surface* top-level keys[0m                                                                       
00:00 [32m+192[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation ProjectManifest toJson: no surface* top-level keys[0m                                                                       
00:00 [32m+193[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView terrain usage terrainUsagesByType returns filtered list[0m                                                            
00:00 [32m+194[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView terrain usage terrainUsagesByType returns filtered list[0m                                                            
00:00 [32m+194[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView path usage resolves path preset when found in catalog[0m                                                              
00:00 [32m+195[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView path usage resolves path preset when found in catalog[0m                                                              
00:00 [32m+195[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView path usage reports missing path preset when not found in catalog[0m                                                   
00:00 [32m+196[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView path usage reports missing path preset when not found in catalog[0m                                                   
00:00 [32m+196[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView path usage reports missing path preset when presetId is empty[0m                                                      
00:00 [32m+197[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView path usage reports missing path preset when presetId is empty[0m                                                      
00:00 [32m+197[0m: test/legacy_surface_usage_view_test.dart: LegacyProjectSurfaceUsageView path usage ignores path layer with no active cells[0m                                                                 
00:00 [32m+198[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder covers exactly the TerrainPathVariant enum values once[0m                             
00:00 [32m+199[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder covers exactly the TerrainPathVariant enum values once[0m                             
00:00 [32m+200[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder covers exactly the TerrainPathVariant enum values once[0m                             
00:00 [32m+201[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder covers exactly the TerrainPathVariant enum values once[0m                             
00:00 [32m+202[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder covers exactly the TerrainPathVariant enum values once[0m                             
00:00 [32m+203[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder covers exactly the TerrainPathVariant enum values once[0m                             
00:00 [32m+204[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder covers exactly the TerrainPathVariant enum values once[0m                             
00:00 [32m+205[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder covers exactly the TerrainPathVariant enum values once[0m                             
00:00 [32m+206[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder covers exactly the TerrainPathVariant enum values once[0m                             
00:00 [32m+207[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder covers exactly the TerrainPathVariant enum values once[0m                             
00:00 [32m+208[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder covers exactly the TerrainPathVariant enum values once[0m                             
00:00 [32m+209[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder covers exactly the TerrainPathVariant enum values once[0m                             
00:00 [32m+210[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder covers exactly the TerrainPathVariant enum values once[0m                             
00:00 [32m+210[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder uses the explicit V0 atlas order[0m                                                   
00:00 [32m+211[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder uses the explicit V0 atlas order[0m                                                   
00:00 [32m+211[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns generates columns from zero[0m                                                
00:00 [32m+212[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                        
00:00 [32m+213[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                        
00:00 [32m+214[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                        
00:00 [32m+215[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                        
00:00 [32m+216[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                        
00:00 [32m+217[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                        
00:00 [32m+218[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                        
00:00 [32m+219[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                        
00:00 [32m+220[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                        
00:00 [32m+221[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                        
00:00 [32m+222[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                        
00:00 [32m+223[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                        
00:00 [32m+224[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                        
00:00 [32m+224[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef stores atlasId exactly without trimming the stored value[0m                                                                        
00:00 [32m+225[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef stores atlasId exactly without trimming the stored value[0m                                                                        
00:00 [32m+225[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef rejects empty atlasId: empty string[0m                                                                                             
00:00 [32m+226[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef rejects empty atlasId: empty string[0m                                                                                             
00:00 [32m+226[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef rejects empty atlasId: whitespace only[0m                                                                                          
00:00 [32m+227[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef rejects empty atlasId: whitespace only[0m                                                                                          
00:00 [32m+227[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef rejects negative column[0m                                                                                                         
00:00 [32m+228[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef rejects negative column[0m                                                                                                         
00:00 [32m+228[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef rejects negative row[0m                                                                                                            
00:00 [32m+229[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef rejects negative row[0m                                                                                                            
00:00 [32m+229[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef accepts column and row zero[0m                                                                                                     
00:00 [32m+230[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef accepts column and row zero[0m                                                                                                     
00:00 [32m+230[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef isInside: true for interior cells[0m                                                                                               
00:00 [32m+231[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef isInside: true for interior cells[0m                                                                                               
00:00 [32m+231[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef isInside: false when out of grid[0m                                                                                                
00:00 [32m+232[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef isInside: false when out of grid[0m                                                                                                
00:00 [32m+232[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef isInside: same column/row independent of layout enum[0m                                                                            
00:00 [32m+233[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef isInside: same column/row independent of layout enum[0m                                                                            
00:00 [32m+233[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef value equality: same values and hashCode[0m                                                                                        
00:00 [32m+234[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView adapts a simple water ProjectPathPreset without changing values[0m                                                             
00:00 [32m+235[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView adapts a simple water ProjectPathPreset without changing values[0m                                                             
00:00 [32m+236[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView adapts a simple water ProjectPathPreset without changing values[0m                                                             
00:00 [32m+237[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView adapts a simple water ProjectPathPreset without changing values[0m                                                             
00:00 [32m+238[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView adapts a simple water ProjectPathPreset without changing values[0m                                                             
00:00 [32m+239[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView adapts a simple water ProjectPathPreset without changing values[0m                                                             
00:00 [32m+240[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView adapts a simple water ProjectPathPreset without changing values[0m                                                             
00:00 [32m+240[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView adapts a tallGrass preset as a legacy surface kind[0m                                                                          
00:00 [32m+241[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView adapts a tallGrass preset as a legacy surface kind[0m                                                                          
00:00 [32m+241[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView preserves variant order exactly as authored by the preset[0m                                                                   
00:00 [32m+242[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView preserves variant order exactly as authored by the preset[0m                                                                   
00:00 [32m+242[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView preserves frame order and frame durations exactly[0m                                                                           
00:00 [32m+243[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView preserves frame order and frame durations exactly[0m                                                                           
00:00 [32m+243[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView preserves per-frame tilesetId overrides[0m                                                                                     
00:00 [32m+244[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView preserves per-frame tilesetId overrides[0m                                                                                     
00:00 [32m+244[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView framesForVariant returns first matching mapping or an empty list[0m                                                            
00:00 [32m+245[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView framesForVariant returns first matching mapping or an empty list[0m                                                            
00:00 [32m+245[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView exposes only unmodifiable variant and frame lists[0m                                                                           
00:00 [32m+246[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView exposes only unmodifiable variant and frame lists[0m                                                                           
00:00 [32m+246[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView does not mutate the source ProjectPathPreset[0m                                                                                
00:00 [32m+247[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView does not mutate the source ProjectPathPreset[0m                                                                                
00:00 [32m+247[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView accepts a preset without variants[0m                                                                                           
00:00 [32m+248[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView accepts a preset without variants[0m                                                                                           
00:00 [32m+248[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView hasAnimatedVariants is true when any variant has multiple frames[0m                                                            
00:00 [32m+249[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView hasAnimatedVariants is true when any variant has multiple frames[0m                                                            
00:00 [32m+249[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView LegacyPathSurfaceVariantView reports frame and animation state[0m                                                              
00:00 [32m+250[0m: test/legacy_path_surface_view_test.dart: LegacyPathSurfaceView LegacyPathSurfaceVariantView reports frame and animation state[0m                                                              
00:00 [32m+250[0m: [1m[90mloading test/tile_visual_frame_vertical_atlas_test.dart[0m[0m                                                                                                                                    
00:00 [32m+250[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas simple vertical frames generates frames with correct vertical positions[0m                           
00:00 [32m+251[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas simple vertical frames generates frames with correct vertical positions[0m                           
00:00 [32m+251[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas simple vertical frames respects startRow parameter[0m                                                
00:00 [32m+252[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas simple vertical frames respects startRow parameter[0m                                                
00:00 [32m+252[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas simple vertical frames respects sourceWidth and sourceHeight[0m                                      
00:00 [32m+253[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas simple vertical frames respects sourceWidth and sourceHeight[0m                                      
00:00 [32m+253[0m: [1m[90mloading test/surface_variant_role_test.dart[0m[0m                                                                                                                                                
00:00 [32m+253[0m: test/surface_variant_role_test.dart: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                            
00:00 [32m+254[0m: test/surface_variant_role_test.dart: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                            
00:00 [32m+255[0m: test/surface_variant_role_test.dart: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                            
00:00 [32m+256[0m: test/surface_variant_role_test.dart: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                            
00:00 [32m+257[0m: test/surface_variant_role_test.dart: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                            
00:00 [32m+258[0m: test/surface_variant_role_test.dart: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                            
00:00 [32m+259[0m: test/surface_variant_role_test.dart: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                            
00:00 [32m+260[0m: test/surface_variant_role_test.dart: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                            
00:00 [32m+261[0m: test/surface_variant_role_test.dart: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                            
00:00 [32m+262[0m: test/surface_variant_role_test.dart: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                            
00:00 [32m+263[0m: test/surface_variant_role_test.dart: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                            
00:00 [32m+264[0m: test/surface_variant_role_test.dart: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                            
00:00 [32m+265[0m: test/surface_variant_role_test.dart: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                            
00:00 [32m+266[0m: test/surface_variant_role_test.dart: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                            
00:00 [32m+266[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas validation throws ValidationException for non-positive sourceHeight[0m                               
00:00 [32m+267[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas validation throws ValidationException for non-positive sourceHeight[0m                               
00:00 [32m+268[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas validation throws ValidationException for non-positive sourceHeight[0m                               
00:00 [32m+268[0m: test/surface_variant_role_test.dart: SurfaceVariantRole standard list covers all enum values once (set + length)[0m                                                                           
00:00 [32m+269[0m: test/surface_variant_role_test.dart: SurfaceVariantRole standard list covers all enum values once (set + length)[0m                                                                           
00:00 [32m+270[0m: test/surface_variant_role_test.dart: SurfaceVariantRole standard list covers all enum values once (set + length)[0m                                                                           
00:00 [32m+271[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas validation throws ValidationException for non-positive frame durations[0m                            
00:00 [32m+272[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas validation throws ValidationException for non-positive frame durations[0m                            
00:00 [32m+272[0m: test/surface_variant_role_test.dart: SurfaceVariantRole standardSurfaceVariantRoleOrder is not growable (const list)[0m                                                                       
00:00 [32m+273[0m: test/surface_variant_role_test.dart: SurfaceVariantRole standardSurfaceVariantRoleOrder is not growable (const list)[0m                                                                       
00:00 [32m+274[0m: test/surface_variant_role_test.dart: SurfaceVariantRole standardSurfaceVariantRoleOrder is not growable (const list)[0m                                                                       
00:00 [32m+275[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas edge cases handles custom source dimensions[0m                                                       
00:00 [32m+276[0m: test/surface_variant_role_test.dart: SurfaceVariantRole export: types from map_core only[0m                                                                                                   
00:00 [32m+277[0m: test/surface_variant_role_test.dart: SurfaceVariantRole export: types from map_core only[0m                                                                                                   
00:00 [32m+278[0m: test/surface_variant_role_test.dart: SurfaceVariantRole export: types from map_core only[0m                                                                                                   
00:00 [32m+278[0m: test/surface_variant_role_test.dart: SurfaceVariantRole ProjectManifest toJson: no surface* top-level keys[0m                                                                                 
00:00 [32m+279[0m: test/legacy_terrain_surface_view_test.dart: LegacyTerrainSurfaceView adapts a simple grass ProjectTerrainPreset without changing values[0m                                                    
00:00 [32m+280[0m: test/legacy_terrain_surface_view_test.dart: LegacyTerrainSurfaceView adapts a simple grass ProjectTerrainPreset without changing values[0m                                                    
00:00 [32m+281[0m: test/legacy_terrain_surface_view_test.dart: LegacyTerrainSurfaceView adapts a simple grass ProjectTerrainPreset without changing values[0m                                                    
00:00 [32m+281[0m: test/legacy_terrain_surface_view_test.dart: LegacyTerrainSurfaceView adapts multiple TerrainType values without PathSurfaceKind[0m                                                            
00:00 [32m+282[0m: test/legacy_terrain_surface_view_test.dart: LegacyTerrainSurfaceView adapts multiple TerrainType values without PathSurfaceKind[0m                                                            
00:00 [32m+282[0m: test/legacy_terrain_surface_view_test.dart: LegacyTerrainSurfaceView preserves variant order exactly as authored by the preset[0m                                                             
00:00 [32m+283[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 1. full preset with default standard order[0m                                                              
00:00 [32m+284[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 1. full preset with default standard order[0m                                                              
00:00 [32m+285[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 1. full preset with default standard order[0m                                                              
00:00 [32m+286[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 1. full preset with default standard order[0m                                                              
00:00 [32m+287[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 1. full preset with default standard order[0m                                                              
00:00 [32m+288[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 1. full preset with default standard order[0m                                                              
00:00 [32m+289[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 1. full preset with default standard order[0m                                                              
00:00 [32m+290[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 1. full preset with default standard order[0m                                                              
00:00 [32m+291[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 1. full preset with default standard order[0m                                                              
00:00 [32m+292[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 1. full preset with default standard order[0m                                                              
00:00 [32m+293[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 1. full preset with default standard order[0m                                                              
00:00 [32m+293[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 2. ref roles list matches standardSurfaceVariantRoleOrder[0m                                               
00:00 [32m+294[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 2. ref roles list matches standardSurfaceVariantRoleOrder[0m                                               
00:00 [32m+294[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 3. animationIds follow strategy for sample roles[0m                                                        
00:00 [32m+295[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 3. animationIds follow strategy for sample roles[0m                                                        
00:00 [32m+295[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 4. preserves categoryId and sortOrder[0m                                                                   
00:00 [32m+296[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 4. preserves categoryId and sortOrder[0m                                                                   
00:00 [32m+296[0m: test/standard_surface_preset_builder_test.dart: createStandardProjectSurfacePreset 5. id and name stored exactly without auto-trim[0m                                                         
00:00 [32m+297[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+298[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+299[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+300[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+301[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+302[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+303[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+304[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+305[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+306[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+307[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+308[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+309[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+310[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+311[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+312[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+313[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+314[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+315[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                  
00:00 [32m+315[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation API specialization: generated presets are always water[0m  
00:00 [32m+316[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation API specialization: generated presets are always water[0m  
00:00 [32m+316[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation preserves categoryId and sortOrder[0m                      
00:00 [32m+317[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation preserves categoryId and sortOrder[0m                      
00:00 [32m+317[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation respects firstColumn[0m                                    
00:00 [32m+318[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation respects firstColumn[0m                                    
00:00 [32m+318[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation respects startRow[0m                                       
00:00 [32m+319[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation respects startRow[0m                                       
00:00 [32m+319[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation generates a variant sub-layout[0m                          
00:00 [32m+320[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation generates a variant sub-layout[0m                          
00:00 [32m+320[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation generates a variant sub-layout with firstColumn[0m         
00:00 [32m+321[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation generates a variant sub-layout with firstColumn[0m         
00:00 [32m+321[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation respects sourceWidth and sourceHeight[0m                   
00:00 [32m+322[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation respects sourceWidth and sourceHeight[0m                   
00:00 [32m+322[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation distinguishes preset tilesetId from frameTilesetId[0m      
00:00 [32m+323[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation distinguishes preset tilesetId from frameTilesetId[0m      
00:00 [32m+323[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation preserves empty frameTilesetId[0m                          
00:00 [32m+324[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation preserves empty frameTilesetId[0m                          
00:00 [32m+324[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation applies custom common duration[0m                          
00:00 [32m+325[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation applies custom common duration[0m                          
00:00 [32m+325[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation applies per-frame durations[0m                             
00:00 [32m+326[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation applies per-frame durations[0m                             
00:00 [32m+326[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation replaces null frame durations with the default duration[0m 
00:00 [32m+327[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas preset generation replaces null frame durations with the default duration[0m 
00:00 [32m+327[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas compatibility is compatible with LegacyPathSurfaceView[0m                    
00:00 [32m+328[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas compatibility is compatible with LegacyPathSurfaceView[0m                    
00:00 [32m+328[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas compatibility is compatible with LegacyProjectSurfaceCatalogView[0m          
00:00 [32m+329[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas compatibility is compatible with LegacyProjectSurfaceCatalogView[0m          
00:00 [32m+329[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas compatibility is compatible with resolveTileVisualFrameTimeline[0m           
00:00 [32m+330[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas compatibility is compatible with resolveTileVisualFrameTimeline[0m           
00:00 [32m+330[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for empty id[0m                   
00:00 [32m+331[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for empty id[0m                   
00:00 [32m+331[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for empty name[0m                 
00:00 [32m+332[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for empty name[0m                 
00:00 [32m+332[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for empty tilesetId[0m            
00:00 [32m+333[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for empty tilesetId[0m            
00:00 [32m+333[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for negative firstColumn[0m       
00:00 [32m+334[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for negative firstColumn[0m       
00:00 [32m+334[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for negative startRow[0m          
00:00 [32m+335[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for negative startRow[0m          
00:00 [32m+335[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for empty variants[0m             
00:00 [32m+336[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for empty variants[0m             
00:00 [32m+336[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for duplicate variants[0m         
00:00 [32m+337[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for duplicate variants[0m         
00:00 [32m+337[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for invalid frameCount[0m         
00:00 [32m+338[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for invalid frameCount[0m         
00:00 [32m+338[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for invalid source dimensions[0m  
00:00 [32m+339[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for invalid source dimensions[0m  
00:00 [32m+339[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for invalid defaultDurationMs[0m  
00:00 [32m+340[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: createStandardWaterPathPresetFromVerticalAtlas validation delegation delegates validation for invalid defaultDurationMs[0m  
00:00 [32m+340[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... validation delegation delegates validation for frameDurationsMs length mismatch[0m                                      
00:00 [32m+341[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... validation delegation delegates validation for frameDurationsMs length mismatch[0m                                      
00:00 [32m+341[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... validation delegation delegates validation for non-positive frame durations[0m                                          
00:00 [32m+342[0m: test/standard_water_path_preset_vertical_atlas_builder_test.dart: ... validation delegation delegates validation for non-positive frame durations[0m                                          
00:00 [32m+342[0m: [1m[90mloading test/legacy_surface_catalog_diagnostics_test.dart[0m[0m                                                                                                                                  
00:00 [32m+342[0m: test/legacy_surface_catalog_diagnostics_test.dart: LegacySurfaceCatalogDiagnostics returns no diagnostics for a healthy legacy surface catalog[0m                                             
00:00 [32m+343[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig defaults to idle with safe values[0m                                                                                
00:00 [32m+344[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig defaults to idle with safe values[0m                                                                                
00:00 [32m+345[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig defaults to idle with safe values[0m                                                                                
00:00 [32m+346[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig defaults to idle with safe values[0m                                                                                
00:00 [32m+346[0m: test/legacy_surface_catalog_diagnostics_test.dart: LegacySurfaceCatalogDiagnostics reports shared terrain and path ids as cross-family info[0m                                                
00:00 [32m+347[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig serializes and deserializes patrol configuration[0m                                                                 
00:00 [32m+348[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig serializes and deserializes patrol configuration[0m                                                                 
00:00 [32m+349[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig serializes and deserializes patrol configuration[0m                                                                 
00:00 [32m+350[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig serializes and deserializes patrol configuration[0m                                                                 
00:00 [32m+351[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig serializes and deserializes patrol configuration[0m                                                                 
00:00 [32m+352[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig serializes and deserializes patrol configuration[0m                                                                 
00:00 [32m+353[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig serializes and deserializes patrol configuration[0m                                                                 
00:00 [32m+354[0m: test/map_core_test.dart: MapCore Strict Tests MapLayer serialization (Union)[0m                                                                                                               
00:00 [32m+355[0m: test/map_core_test.dart: MapCore Strict Tests MapLayer serialization (Union)[0m                                                                                                               
00:00 [32m+356[0m: test/map_core_test.dart: MapCore Strict Tests MapLayer serialization (Union)[0m                                                                                                               
00:00 [32m+357[0m: test/map_core_test.dart: MapCore Strict Tests MapLayer serialization (Union)[0m                                                                                                               
00:00 [32m+358[0m: test/map_core_test.dart: MapCore Strict Tests MapLayer serialization (Union)[0m                                                                                                               
00:00 [32m+359[0m: test/map_core_test.dart: MapCore Strict Tests MapLayer serialization (Union)[0m                                                                                                               
00:00 [32m+360[0m: test/map_core_test.dart: MapCore Strict Tests MapLayer serialization (Union)[0m                                                                                                               
00:00 [32m+361[0m: test/map_core_test.dart: MapCore Strict Tests MapLayer serialization (Union)[0m                                                                                                               
00:00 [32m+362[0m: test/map_core_test.dart: MapCore Strict Tests MapLayer serialization (Union)[0m                                                                                                               
00:00 [32m+363[0m: test/map_core_test.dart: MapCore Strict Tests MapLayer serialization (Union)[0m                                                                                                               
00:00 [32m+363[0m: test/map_core_test.dart: MapCore Strict Tests ProjectValidator detects duplicates[0m                                                                                                          
00:00 [32m+364[0m: test/map_core_test.dart: MapCore Strict Tests ProjectValidator detects duplicates[0m                                                                                                          
00:00 [32m+364[0m: test/map_core_test.dart: MapCore Strict Tests MapValidator detects layer size mismatch[0m                                                                                                     
00:00 [32m+365[0m: test/map_core_test.dart: MapCore Strict Tests MapValidator detects layer size mismatch[0m                                                                                                     
00:00 [32m+365[0m: test/map_core_test.dart: MapCore Strict Tests MapValidator detects entity out of bounds[0m                                                                                                    
00:00 [32m+366[0m: test/map_core_test.dart: MapCore Strict Tests MapValidator detects entity out of bounds[0m                                                                                                    
00:00 [32m+366[0m: [1m[90mloading test/legacy_project_surface_catalog_view_test.dart[0m[0m                                                                                                                                 
00:00 [32m+366[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView catalog is empty when the manifest has no legacy surface presets[0m                                       
00:00 [32m+367[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView catalog is empty when the manifest has no legacy surface presets[0m                                       
00:00 [32m+367[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView catalog preserves terrain and path preset order separately[0m                                             
00:00 [32m+368[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView catalog preserves terrain and path preset order separately[0m                                             
00:00 [32m+368[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView delegates terrain and path data to the existing legacy adapters[0m                                        
00:00 [32m+369[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView delegates terrain and path data to the existing legacy adapters[0m                                        
00:00 [32m+369[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView terrainSurfaceById returns an existing terrain or null[0m                                                 
00:00 [32m+370[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView terrainSurfaceById returns an existing terrain or null[0m                                                 
00:00 [32m+370[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView pathSurfaceById returns an existing path or null[0m                                                       
00:00 [32m+371[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView pathSurfaceById returns an existing path or null[0m                                                       
00:00 [32m+371[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView duplicate terrain ids are kept and lookup returns the first match[0m                                      
00:00 [32m+372[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView duplicate terrain ids are kept and lookup returns the first match[0m                                      
00:00 [32m+372[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView duplicate path ids are kept and lookup returns the first match[0m                                         
00:00 [32m+373[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView duplicate path ids are kept and lookup returns the first match[0m                                         
00:00 [32m+373[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView terrainSurfacesByType filters terrain surfaces in manifest order[0m                                       
00:00 [32m+374[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView terrainSurfacesByType filters terrain surfaces in manifest order[0m                                       
00:00 [32m+374[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView pathSurfacesByKind filters path surfaces in manifest order[0m                                             
00:00 [32m+375[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView pathSurfacesByKind filters path surfaces in manifest order[0m                                             
00:00 [32m+375[0m: test/legacy_project_surface_catalog_view_test.dart: LegacyProjectSurfaceCatalogView catalog and filter result lists are unmodifiable[0m                                                       
00:00 [32m+376[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef minimal ref holds role and animationId[0m                                                                            
00:00 [32m+377[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef minimal ref holds role and animationId[0m                                                                            
00:00 [32m+378[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef minimal ref holds role and animationId[0m                                                                            
00:00 [32m+379[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef minimal ref holds role and animationId[0m                                                                            
00:00 [32m+379[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef accepts several distinct roles (sample)[0m                                                                           
00:00 [32m+380[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef accepts several distinct roles (sample)[0m                                                                           
00:00 [32m+380[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef stores animationId exactly without auto-trim[0m                                                                      
00:00 [32m+381[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef stores animationId exactly without auto-trim[0m                                                                      
00:00 [32m+381[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef rejects empty animationId: empty string[0m                                                                           
00:00 [32m+382[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef rejects empty animationId: empty string[0m                                                                           
00:00 [32m+382[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef rejects empty animationId: whitespace only[0m                                                                        
00:00 [32m+383[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef rejects empty animationId: whitespace only[0m                                                                        
00:00 [32m+383[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef value equality: same values => equal and same hash[0m                                                                
00:00 [32m+384[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef value equality: same values => equal and same hash[0m                                                                
00:00 [32m+384[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef value equality: different role[0m                                                                                    
00:00 [32m+385[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef value equality: different role[0m                                                                                    
00:00 [32m+385[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef value equality: different animationId[0m                                                                             
00:00 [32m+386[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef value equality: different animationId[0m                                                                             
00:00 [32m+386[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef export: type visible through map_core[0m                                                                             
00:00 [32m+387[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef export: type visible through map_core[0m                                                                             
00:00 [32m+387[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef coexists with ProjectSurfaceAnimation: id string only, no resolution[0m                                              
00:00 [32m+388[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef coexists with ProjectSurfaceAnimation: id string only, no resolution[0m                                              
00:00 [32m+388[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef one ref per role in standardSurfaceVariantRoleOrder (length + order)[0m                                              
00:00 [32m+389[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef one ref per role in standardSurfaceVariantRoleOrder (length + order)[0m                                              
00:00 [32m+389[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef ProjectManifest toJson: no surface* top-level keys[0m                                                                
00:00 [32m+390[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef ProjectManifest toJson: no surface* top-level keys[0m                                                                
00:00 [32m+390[0m: [1m[90mloading test/map_gameplay_zone_validation_test.dart[0m[0m                                                                                                                                        
00:00 [32m+390[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                     
00:00 [32m+391[0m: test/element_collision_profile_pixel_mask_json_test.dart: ElementCollisionProfile mask JSON supports pixelMask[0m                                                                             
00:00 [32m+392[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation generates simple water ProjectPathPreset[0m                                     
00:00 [32m+393[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation generates simple water ProjectPathPreset[0m                                     
00:00 [32m+394[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation generates simple water ProjectPathPreset[0m                                     
00:00 [32m+395[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation generates simple water ProjectPathPreset[0m                                     
00:00 [32m+396[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation generates simple water ProjectPathPreset[0m                                     
00:00 [32m+397[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation generates simple water ProjectPathPreset[0m                                     
00:00 [32m+398[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation generates simple water ProjectPathPreset[0m                                     
00:00 [32m+398[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation generates tallGrass ProjectPathPreset[0m                                        
00:00 [32m+399[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation generates tallGrass ProjectPathPreset[0m                                        
00:00 [32m+399[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation preserves categoryId and sortOrder[0m                                           
00:00 [32m+400[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation preserves categoryId and sortOrder[0m                                           
00:00 [32m+400[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation preserves input order of variants[0m                                            
00:00 [32m+401[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation preserves input order of variants[0m                                            
00:00 [32m+401[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation respects startRow per column[0m                                                 
00:00 [32m+402[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation respects startRow per column[0m                                                 
00:00 [32m+402[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation respects sourceWidth and sourceHeight[0m                                        
00:00 [32m+403[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation respects sourceWidth and sourceHeight[0m                                        
00:00 [32m+403[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation distinguishes preset tilesetId from frame tilesetId[0m                          
00:00 [32m+404[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation distinguishes preset tilesetId from frame tilesetId[0m                          
00:00 [32m+404[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation preserves empty frameTilesetId[0m                                               
00:00 [32m+405[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation preserves empty frameTilesetId[0m                                               
00:00 [32m+405[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation applies custom default duration[0m                                              
00:00 [32m+406[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation applies custom default duration[0m                                              
00:00 [32m+406[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation applies per-frame durations[0m                                                  
00:00 [32m+407[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation applies per-frame durations[0m                                                  
00:00 [32m+407[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation replaces null durations with default[0m                                         
00:00 [32m+408[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas preset generation replaces null durations with default[0m                                         
00:00 [32m+408[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas compatibility is compatible with LegacyPathSurfaceView[0m                                         
00:00 [32m+409[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas compatibility is compatible with LegacyPathSurfaceView[0m                                         
00:00 [32m+409[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas compatibility is compatible with LegacyProjectSurfaceCatalogView[0m                               
00:00 [32m+410[0m: test/path_preset_vertical_atlas_builder_test.dart: createProjectPathPresetFromVerticalAtlas compatibility is compatible with LegacyProjectSurfaceCatalogView[0m                               
00:00 [32m+410[0m: [1m[90mloading test/project_manifest_surface_json_characterization_test.dart[0m[0m                                                                                                                      
00:00 [32m+410[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+411[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+412[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+413[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+414[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+415[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+416[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+417[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+418[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+419[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+420[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+421[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+422[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+423[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+424[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+425[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+426[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+427[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+428[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+429[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+430[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+431[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+432[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m        
00:00 [32m+432[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model unknown root surfaceDefinitions is ignored and lost on round-trip[0m
00:00 [32m+433[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                               
00:00 [32m+434[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                               
00:00 [32m+435[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                               
00:00 [32m+436[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                               
00:00 [32m+437[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                               
00:00 [32m+438[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                               
00:00 [32m+439[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                               
00:00 [32m+439[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model ProjectPathPreset water preserves mappings and animated frames[0m   
00:00 [32m+440[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model ProjectPathPreset water preserves mappings and animated frames[0m   
00:00 [32m+441[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model ProjectPathPreset water preserves mappings and animated frames[0m   
00:00 [32m+441[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model ProjectPathPreset tallGrass is known to JSON serialization[0m       
00:00 [32m+442[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model ProjectPathPreset tallGrass is known to JSON serialization[0m       
00:00 [32m+442[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model PathLayer animationMode preserves always_active and triggered[0m    
00:00 [32m+443[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model PathLayer animationMode preserves always_active and triggered[0m    
00:00 [32m+443[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model PathAnimationTriggerRule preserves current trigger fields[0m        
00:00 [32m+444[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model PathAnimationTriggerRule preserves current trigger fields[0m        
00:00 [32m+444[0m: test/project_manifest_surface_json_characterization_test.dart: ... JSON characterization before Surface model PathLayer preserves presetId, cells, properties, mode and triggers[0m           
00:00 [32m+445[0m: test/project_manifest_surface_json_characterization_test.dart: ... JSON characterization before Surface model PathLayer preserves presetId, cells, properties, mode and triggers[0m           
00:00 [32m+445[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model TerrainLayer preserves terrain grid enum values[0m                  
00:00 [32m+446[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport creates an empty report for an empty manifest and no maps[0m                                                             
00:00 [32m+447[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport creates an empty report for an empty manifest and no maps[0m                                                             
00:00 [32m+448[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport creates an empty report for an empty manifest and no maps[0m                                                             
00:00 [32m+449[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport creates an empty report for an empty manifest and no maps[0m                                                             
00:00 [32m+449[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport creates a healthy report with declared and used surfaces[0m                                                              
00:00 [32m+450[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport creates a healthy report with declared and used surfaces[0m                                                              
00:00 [32m+450[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport includes catalog and unused declaration diagnostics[0m                                                                   
00:00 [32m+451[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport includes catalog and unused declaration diagnostics[0m                                                                   
00:00 [32m+451[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport includes usage diagnostics for missing declared surfaces[0m                                                              
00:00 [32m+452[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport includes usage diagnostics for missing declared surfaces[0m                                                              
00:00 [32m+452[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport exposes non-mutable diagnostic lists[0m                                                                                  
00:00 [32m+453[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport exposes non-mutable diagnostic lists[0m                                                                                  
00:00 [32m+453[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport does not mutate manifest, maps, layers, or cells[0m                                                                      
00:00 [32m+454[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport does not mutate manifest, maps, layers, or cells[0m                                                                      
00:00 [32m+454[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport summary counts catalog warnings separately from usage warnings[0m                                                        
00:00 [32m+455[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport summary counts catalog warnings separately from usage warnings[0m                                                        
00:00 [32m+455[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport reuses the catalog, usage, and diagnostic helper outputs[0m                                                              
00:00 [32m+456[0m: test/legacy_surface_audit_report_test.dart: LegacySurfaceAuditReport reuses the catalog, usage, and diagnostic helper outputs[0m                                                              
00:00 [32m+456[0m: [1m[90mloading test/surface_animation_timeline_test.dart[0m[0m                                                                                                                                          
00:00 [32m+456[0m: test/surface_animation_timeline_test.dart: SurfaceAnimationTimeline minimal timeline with one frame[0m                                                                                        
00:00 [32m+457[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                          
00:00 [32m+458[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                          
00:00 [32m+459[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                          
00:00 [32m+460[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                          
00:00 [32m+461[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                          
00:00 [32m+462[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                          
00:00 [32m+463[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                          
00:00 [32m+464[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                          
00:01 [32m+465[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                          
00:01 [32m+466[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                          
00:01 [32m+467[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                          
00:01 [32m+468[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                          
00:01 [32m+469[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                          
00:01 [32m+470[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                          
00:01 [32m+471[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                          
00:01 [32m+472[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics[0m                                                                        
00:01 [32m+473[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics[0m                                                                        
00:01 [32m+474[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                       
00:01 [32m+475[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                       
00:01 [32m+476[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                       
00:01 [32m+477[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                       
00:01 [32m+478[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                       
00:01 [32m+479[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                       
00:01 [32m+480[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                       
00:01 [32m+481[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                       
00:01 [32m+482[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                       
00:01 [32m+483[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                       
00:01 [32m+484[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                       
00:01 [32m+485[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 12. exact atlas id: no trim[0m                                                                             
00:01 [32m+486[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 12. exact atlas id: no trim[0m                                                                             
00:01 [32m+486[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 13. byKind filters[0m                                                                                      
00:01 [32m+487[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas preserves categoryId and sortOrder[0m                                                                                               
00:01 [32m+488[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 14. byKind list is unmodifiable[0m                                                                         
00:01 [32m+489[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 14. byKind list is unmodifiable[0m                                                                         
00:01 [32m+490[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas rejects empty id: empty string[0m                                                                                                   
00:01 [32m+491[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 15. diagnostics list on report is unmodifiable[0m                                                          
00:01 [32m+492[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas rejects empty id: whitespace only[0m                                                                                                
00:01 [32m+493[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 16. defensive copy: mutating source list does not change report[0m                                         
00:01 [32m+494[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas rejects empty name: empty string[0m                                                                                                 
00:01 [32m+495[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 17. hasErrors false on empty report[0m                                                                     
00:01 [32m+496[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 17. hasErrors false on empty report[0m                                                                     
00:01 [32m+496[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas rejects empty name: whitespace only[0m                                                                                              
00:01 [32m+497[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 18. hasErrors true when error diagnostic[0m                                                                
00:01 [32m+498[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas rejects empty tilesetId: empty string[0m                                                                                            
00:01 [32m+499[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas rejects empty tilesetId: empty string[0m                                                                                            
00:01 [32m+499[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 19. diagnostic equality: same[0m                                                                           
00:01 [32m+500[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 19. diagnostic equality: same[0m                                                                           
00:01 [32m+501[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 19. diagnostic equality: same[0m                                                                           
00:01 [32m+502[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas value equality: same values[0m                                                                                                      
00:01 [32m+503[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas value equality: same values[0m                                                                                                      
00:01 [32m+504[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas value equality: same values[0m                                                                                                      
00:01 [32m+505[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas value equality: same values[0m                                                                                                      
00:01 [32m+505[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas value equality: id differs[0m                                                                                                       
00:01 [32m+506[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas value equality: id differs[0m                                                                                                       
00:01 [32m+507[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas value equality: id differs[0m                                                                                                       
00:01 [32m+507[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 23. report equality: order matters[0m                                                                      
00:01 [32m+508[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas value equality: name differs[0m                                                                                                     
00:01 [32m+509[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas value equality: name differs[0m                                                                                                     
00:01 [32m+509[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 24. public API via map_core[0m                                                                             
00:01 [32m+510[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas value equality: tilesetId differs[0m                                                                                                
00:01 [32m+511[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 25. ProjectManifest still has no Surface keys (Lot 34)[0m                                                  
00:01 [32m+512[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 25. ProjectManifest still has no Surface keys (Lot 34)[0m                                                  
00:01 [32m+513[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 25. ProjectManifest still has no Surface keys (Lot 34)[0m                                                  
00:01 [32m+514[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 25. ProjectManifest still has no Surface keys (Lot 34)[0m                                                  
00:01 [32m+515[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 25. ProjectManifest still has no Surface keys (Lot 34)[0m                                                  
00:01 [32m+516[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 25. ProjectManifest still has no Surface keys (Lot 34)[0m                                                  
00:01 [32m+517[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas ProjectManifest toJson: no top-level surface* keys[0m                                                                               
00:01 [32m+518[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas ProjectManifest toJson: no top-level surface* keys[0m                                                                               
00:01 [32m+518[0m: [1m[90mloading test/tile_visual_frame_timeline_test.dart[0m[0m                                                                                                                                          
00:01 [32m+518[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames staticFrame resolves to a completed empty result[0m                                                           
00:01 [32m+519[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames staticFrame resolves to a completed empty result[0m                                                           
00:01 [32m+519[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames loop resolves to a completed empty result[0m                                                                  
00:01 [32m+520[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames loop resolves to a completed empty result[0m                                                                  
00:01 [32m+520[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames oneShot resolves to a completed empty result[0m                                                               
00:01 [32m+521[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames oneShot resolves to a completed empty result[0m                                                               
00:01 [32m+521[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline single frame staticFrame returns the frame and is completed[0m                                                             
00:01 [32m+522[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline single frame staticFrame returns the frame and is completed[0m                                                             
00:01 [32m+522[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline single frame loop returns the frame and remains non-completing[0m                                                          
00:01 [32m+523[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline single frame loop returns the frame and remains non-completing[0m                                                          
00:01 [32m+523[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline single frame oneShot returns the frame and is completed[0m                                                                 
00:01 [32m+524[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline single frame oneShot returns the frame and is completed[0m                                                                 
00:01 [32m+524[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline staticFrame with multiple frames always returns the first frame[0m                                                         
00:01 [32m+525[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline staticFrame with multiple frames always returns the first frame[0m                                                         
00:01 [32m+525[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline loop with two equal frames follows frame boundaries[0m                                                                     
00:01 [32m+526[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline loop with two equal frames follows frame boundaries[0m                                                                     
00:01 [32m+526[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline loop with uneven frame durations follows cumulative boundaries[0m                                                          
00:01 [32m+527[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline loop with uneven frame durations follows cumulative boundaries[0m                                                          
00:01 [32m+527[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline oneShot advances once, clamps at the last frame, and completes[0m                                                          
00:01 [32m+528[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline oneShot advances once, clamps at the last frame, and completes[0m                                                          
00:01 [32m+528[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline invalid and null durations use the existing default duration[0m                                                            
00:01 [32m+529[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline invalid and null durations use the existing default duration[0m                                                            
00:01 [32m+529[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline speed less than or equal to zero follows placed animation fallback[0m                                                      
00:01 [32m+530[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline speed less than or equal to zero follows placed animation fallback[0m                                                      
00:01 [32m+530[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline preserves the exact selected TilesetVisualFrame object[0m                                                                  
00:01 [32m+531[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline preserves the exact selected TilesetVisualFrame object[0m                                                                  
00:01 [32m+531[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline does not mutate the received frames list[0m                                                                                
00:01 [32m+532[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline does not mutate the received frames list[0m                                                                                
00:01 [32m+532[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline loop index stays coherent with placed element animation helper[0m                                                          
00:01 [32m+533[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline loop index stays coherent with placed element animation helper[0m                                                          
00:01 [32m+533[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline oneShot result stays coherent with placed one-shot helper[0m                                                               
00:01 [32m+534[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline oneShot result stays coherent with placed one-shot helper[0m                                                               
00:01 [32m+534[0m: [1m[90mloading test/placed_element_animation_one_shot_test.dart[0m[0m                                                                                                                                   
00:01 [32m+534[0m: test/placed_element_animation_one_shot_test.dart: resolvePlacedElementAnimationOneShotFrame advances one cycle then marks as completed[0m                                                     
00:01 [32m+535[0m: test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a tallGrass ProjectPathPreset with the full standard layout[0m                         
00:01 [32m+536[0m: test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a tallGrass ProjectPathPreset with the full standard layout[0m                         
00:01 [32m+537[0m: test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a tallGrass ProjectPathPreset with the full standard layout[0m                         
00:01 [32m+537[0m: test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart: ... preset generation API specialization: generated presets are always tallGrass[0m                                    
00:01 [32m+538[0m: test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart: ... preset generation API specialization: generated presets are always tallGrass[0m                                    
00:01 [32m+538[0m: test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart: createStandardTallGrassPathPresetFromVerticalAtlas preset generation preserves categoryId and sortOrder[0m             
00:01 [32m+539[0m: test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart: createStandardTallGrassPathPresetFromVerticalAtlas preset generation preserves categoryId and sortOrder[0m             
00:01 [32m+539[0m: test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart: createStandardTallGrassPathPresetFromVerticalAtlas preset generation respects firstColumn[0m                           
00:01 [32m+540[0m: test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart: createStandardTallGrassPathPresetFromVerticalAtlas preset generation respects firstColumn[0m                           
00:01 [32m+540[0m: test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart: createStandardTallGrassPathPresetFromVerticalAtlas preset generation respects startRow[0m                              
00:01 [32m+541[0m: test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart: createStandardTallGrassPathPresetFromVerticalAtlas preset generation respects startRow[0m                              
00:01 [32m+541[0m: test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart: createStandardTallGrassPathPresetFromVerticalAtlas preset generation generates a variant sub-layout[0m                 
00:01 [32m+542[0m: test/surface_animation_frame_test.dart: SurfaceAnimationFrame minimal frame holds tileRef and durationMs[0m                                                                                   
00:01 [32m+543[0m: test/surface_animation_frame_test.dart: SurfaceAnimationFrame minimal frame holds tileRef and durationMs[0m                                                                                   
00:01 [32m+544[0m: test/surface_animation_frame_test.dart: SurfaceAnimationFrame minimal frame holds tileRef and durationMs[0m                                                                                   
00:01 [32m+545[0m: test/surface_animation_frame_test.dart: SurfaceAnimationFrame minimal frame holds tileRef and durationMs[0m                                                                                   
00:01 [32m+546[0m: test/surface_animation_frame_test.dart: SurfaceAnimationFrame minimal frame holds tileRef and durationMs[0m                                                                                   
00:01 [32m+547[0m: test/surface_animation_frame_test.dart: SurfaceAnimationFrame minimal frame holds tileRef and durationMs[0m                                                                                   
00:01 [32m+548[0m: test/surface_animation_frame_test.dart: SurfaceAnimationFrame minimal frame holds tileRef and durationMs[0m                                                                                   
00:01 [32m+549[0m: test/surface_animation_frame_test.dart: SurfaceAnimationFrame minimal frame holds tileRef and durationMs[0m                                                                                   
00:01 [32m+550[0m: test/surface_animation_frame_test.dart: SurfaceAnimationFrame minimal frame holds tileRef and durationMs[0m                                                                                   
00:01 [32m+551[0m: test/surface_animation_frame_test.dart: SurfaceAnimationFrame minimal frame holds tileRef and durationMs[0m                                                                                   
00:01 [32m+552[0m: test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart: createStandardTallGrassPathPresetFromVerticalAtlas compatibility is compatible with resolveTileVisualFrameTimeline[0m  
00:01 [32m+553[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+554[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+555[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+556[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+557[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+558[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+559[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+560[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+561[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+562[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+563[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+564[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+565[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+566[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+567[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+568[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+569[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+570[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+571[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+572[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+573[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+574[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+575[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+576[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+577[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+578[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+579[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                           
00:01 [32m+579[0m: test/map_events_test.dart: map events operations rejects invalid event page list[0m                                                                                                           
00:01 [32m+580[0m: test/map_events_test.dart: map events operations rejects invalid event page list[0m                                                                                                           
00:01 [32m+580[0m: test/map_events_test.dart: map validator events validates script reference against project context[0m                                                                                         
00:01 [32m+581[0m: test/placed_elements_test.dart: placedElements identity buildMapPlacedElementId is stable across element changes[0m                                                                           
00:01 [32m+582[0m: test/placed_elements_test.dart: placedElements identity buildMapPlacedElementId is stable across element changes[0m                                                                           
00:01 [32m+583[0m: test/placed_elements_test.dart: placedElements identity buildMapPlacedElementId is stable across element changes[0m                                                                           
00:01 [32m+583[0m: test/placed_elements_test.dart: placedElements operations removeMapLayer removes placed elements tied to layer[0m                                                                             
00:01 [32m+584[0m: test/placed_elements_test.dart: placedElements operations removeMapLayer removes placed elements tied to layer[0m                                                                             
00:01 [32m+584[0m: test/placed_elements_test.dart: placedElements operations resizeMapData removes placed elements with origin outside bounds[0m                                                                 
00:01 [32m+585[0m: test/placed_elements_test.dart: placedElements operations resizeMapData removes placed elements with origin outside bounds[0m                                                                 
00:01 [32m+585[0m: test/placed_elements_test.dart: placedElements validation MapValidator rejects mismatch between layer tileset and element[0m                                                                  
00:01 [32m+586[0m: test/placed_elements_test.dart: placedElements validation MapValidator rejects mismatch between layer tileset and element[0m                                                                  
00:01 [32m+586[0m: test/placed_elements_test.dart: placedElements validation MapValidator rejects footprint exceeding map bounds[0m                                                                              
00:01 [32m+587[0m: test/placed_elements_test.dart: placedElements validation MapValidator rejects footprint exceeding map bounds[0m                                                                              
00:01 [32m+587[0m: [1m[90mloading test/project_surface_preset_test.dart[0m[0m                                                                                                                                              
00:01 [32m+587[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 1. minimal preset: fields and variantCount[0m                                                                                     
00:01 [32m+588[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 1. minimal preset: fields and variantCount[0m                                                                                     
00:01 [32m+588[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 2. preserves exact same variantAnimations instance[0m                                                                             
00:01 [32m+589[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 2. preserves exact same variantAnimations instance[0m                                                                             
00:01 [32m+589[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 3. preserves categoryId and sortOrder[0m                                                                                          
00:01 [32m+590[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 3. preserves categoryId and sortOrder[0m                                                                                          
00:01 [32m+590[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 4. stores id and name exactly without auto-trim[0m                                                                                
00:01 [32m+591[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 4. stores id and name exactly without auto-trim[0m                                                                                
00:01 [32m+591[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 5. rejects empty id: empty and whitespace[0m                                                                                      
00:01 [32m+592[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 5. rejects empty id: empty and whitespace[0m                                                                                      
00:01 [32m+592[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 6. rejects empty name: empty and whitespace[0m                                                                                    
00:01 [32m+593[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 6. rejects empty name: empty and whitespace[0m                                                                                    
00:01 [32m+593[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 7. does not over-validate categoryId: empty and whitespace allowed[0m                                                             
00:01 [32m+594[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 7. does not over-validate categoryId: empty and whitespace allowed[0m                                                             
00:01 [32m+594[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 8. allows negative sortOrder[0m                                                                                                   
00:01 [32m+595[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 8. allows negative sortOrder[0m                                                                                                   
00:01 [32m+595[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 9. delegating containsRole[0m                                                                                                     
00:01 [32m+596[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 9. delegating containsRole[0m                                                                                                     
00:01 [32m+596[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 10. delegating refForRole: present and absent[0m                                                                                  
00:01 [32m+597[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 10. delegating refForRole: present and absent[0m                                                                                  
00:01 [32m+597[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 11. delegating animationIdForRole: present and absent[0m                                                                          
00:01 [32m+598[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 11. delegating animationIdForRole: present and absent[0m                                                                          
00:01 [32m+598[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 12. delegating coversAllRoles[0m                                                                                                  
00:01 [32m+599[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 12. delegating coversAllRoles[0m                                                                                                  
00:01 [32m+599[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 13. can cover exactly standardSurfaceVariantRoleOrder[0m                                                                          
00:01 [32m+600[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 13. can cover exactly standardSurfaceVariantRoleOrder[0m                                                                          
00:01 [32m+600[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 14. value equality: identical presets are equal and same hashCode[0m                                                              
00:01 [32m+601[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 14. value equality: identical presets are equal and same hashCode[0m                                                              
00:01 [32m+601[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 15. value equality: different id[0m                                                                                               
00:01 [32m+602[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 15. value equality: different id[0m                                                                                               
00:01 [32m+602[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 16. value equality: different name[0m                                                                                             
00:01 [32m+603[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 16. value equality: different name[0m                                                                                             
00:01 [32m+603[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 17. value equality: different variantAnimations[0m                                                                                
00:01 [32m+604[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 17. value equality: different variantAnimations[0m                                                                                
00:01 [32m+604[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 18. value equality: different categoryId[0m                                                                                       
00:01 [32m+605[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 18. value equality: different categoryId[0m                                                                                       
00:01 [32m+605[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 19. value equality: different sortOrder[0m                                                                                        
00:01 [32m+606[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 19. value equality: different sortOrder[0m                                                                                        
00:01 [32m+606[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 20. public export: ProjectSurfacePreset via map_core[0m                                                                           
00:01 [32m+607[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 20. public export: ProjectSurfacePreset via map_core[0m                                                                           
00:01 [32m+607[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 21. V0 visual-only: preset has no kind / surfaceKind / behavior field[0m                                                          
00:01 [32m+608[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 21. V0 visual-only: preset has no kind / surfaceKind / behavior field[0m                                                          
00:01 [32m+608[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 22. coexists with ProjectSurfaceAnimation without resolution[0m                                                                   
00:01 [32m+609[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 22. coexists with ProjectSurfaceAnimation without resolution[0m                                                                   
00:01 [32m+609[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 23. ProjectManifest still has no Surface persistence keys (Lot 21–31)[0m                                                          
00:01 [32m+610[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 23. ProjectManifest still has no Surface persistence keys (Lot 21–31)[0m                                                          
00:01 [32m+610[0m: [1m[90mloading test/path_animation_triggers_test.dart[0m[0m                                                                                                                                             
00:01 [32m+610[0m: test/path_animation_triggers_test.dart: Path animation triggers serializes and deserializes animationTriggers on PathLayer[0m                                                                 
00:01 [32m+611[0m: test/standard_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                        
00:01 [32m+612[0m: test/standard_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                        
00:01 [32m+613[0m: test/standard_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                        
00:01 [32m+614[0m: test/standard_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                        
00:01 [32m+615[0m: test/standard_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                        
00:01 [32m+616[0m: test/standard_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates a water ProjectPathPreset with the full standard layout[0m                                        
00:01 [32m+617[0m: test/map_terrain_autotile_characterization_test.dart: map_terrain_autotile characterization mask table documents the public mask-to-variant mapping[0m                                        
00:01 [32m+618[0m: test/map_terrain_autotile_characterization_test.dart: map_terrain_autotile characterization mask table documents the public mask-to-variant mapping[0m                                        
00:01 [32m+619[0m: test/map_terrain_autotile_characterization_test.dart: map_terrain_autotile characterization mask table documents the public mask-to-variant mapping[0m                                        
00:01 [32m+620[0m: test/map_terrain_autotile_characterization_test.dart: map_terrain_autotile characterization mask table documents the public mask-to-variant mapping[0m                                        
00:01 [32m+621[0m: test/map_terrain_autotile_characterization_test.dart: map_terrain_autotile characterization mask table documents the public mask-to-variant mapping[0m                                        
00:01 [32m+622[0m: test/map_terrain_autotile_characterization_test.dart: map_terrain_autotile characterization mask table documents the public mask-to-variant mapping[0m                                        
00:01 [32m+623[0m: test/map_terrain_autotile_characterization_test.dart: map_terrain_autotile characterization mask table documents the public mask-to-variant mapping[0m                                        
00:01 [32m+624[0m: test/map_terrain_autotile_characterization_test.dart: map_terrain_autotile characterization mask table documents the public mask-to-variant mapping[0m                                        
00:01 [32m+625[0m: test/map_terrain_autotile_characterization_test.dart: map_terrain_autotile characterization mask table documents the public mask-to-variant mapping[0m                                        
00:01 [32m+626[0m: test/map_terrain_autotile_characterization_test.dart: map_terrain_autotile characterization mask table documents the public mask-to-variant mapping[0m                                        
00:01 [32m+627[0m: test/standard_path_preset_vertical_atlas_builder_test.dart: createStandardProjectPathPresetFromVerticalAtlas preset generation applies custom common duration[0m                              
00:01 [32m+628[0m: test/map_terrain_autotile_characterization_test.dart: map_terrain_autotile characterization mask table rejects masks outside the current four-bit range[0m                                    
00:01 [32m+629[0m: test/map_terrain_autotile_characterization_test.dart: map_terrain_autotile characterization mask table rejects masks outside the current four-bit range[0m                                    
00:01 [32m+630[0m: test/standard_path_preset_vertical_atlas_builder_test.dart: createStandardProjectPathPresetFromVerticalAtlas preset generation replaces null frame durations with the default duration[0m     
00:01 [32m+631[0m: test/map_terrain_autotile_characterization_test.dart: map_terrain_autotile characterization cardinal path shapes isolated active cell resolves to isolated[0m                                 
00:01 [32m+632[0m: test/map_terrain_autotile_characterization_test.dart: map_terrain_autotile characterization cardinal path shapes isolated active cell resolves to isolated[0m                                 
00:01 [32m+633[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+634[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+635[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+636[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+637[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+638[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+639[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+640[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+641[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+642[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+643[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+644[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+645[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+646[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+647[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+648[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+649[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+650[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+651[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+652[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+653[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+654[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+655[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+656[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+657[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+658[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+659[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+660[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+661[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+662[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+663[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+664[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+665[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+666[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                            
00:01 [32m+666[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames path preset variant accepts legacy source payload[0m                                                                              
00:01 [32m+667[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames path preset variant accepts legacy source payload[0m                                                                              
00:01 [32m+667[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames validator rejects non-positive path frame durations[0m                                                                            
00:01 [32m+668[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames validator rejects non-positive path frame durations[0m                                                                            
00:01 [32m+668[0m: [1m[90mloading test/path_variant_vertical_atlas_mapping_test.dart[0m[0m                                                                                                                                 
00:01 [32m+668[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping generates single mapping with correct variant[0m                                
00:01 [32m+669[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping generates single mapping with correct variant[0m                                
00:01 [32m+669[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping preserves input order of columns[0m                                             
00:01 [32m+670[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping preserves input order of columns[0m                                             
00:01 [32m+670[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping respects startRow per column[0m                                                 
00:01 [32m+671[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping respects startRow per column[0m                                                 
00:01 [32m+671[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping respects sourceWidth and sourceHeight[0m                                        
00:01 [32m+672[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping respects sourceWidth and sourceHeight[0m                                        
00:01 [32m+672[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping preserves tilesetId[0m                                                          
00:01 [32m+673[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping preserves tilesetId[0m                                                          
00:01 [32m+673[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas frame durations applies common duration to all frames[0m                                       
00:01 [32m+674[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas frame durations applies common duration to all frames[0m                                       
00:01 [32m+674[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas frame durations applies per-frame durations[0m                                                 
00:01 [32m+675[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas frame durations applies per-frame durations[0m                                                 
00:01 [32m+675[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas frame durations replaces null durations with default[0m                                        
00:01 [32m+676[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas frame durations replaces null durations with default[0m                                        
00:01 [32m+676[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas immutability returns unmodifiable list[0m                                                      
00:01 [32m+677[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas immutability returns unmodifiable list[0m                                                      
00:01 [32m+677[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas immutability frames list is unmodifiable[0m                                                    
00:01 [32m+678[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas immutability frames list is unmodifiable[0m                                                    
00:01 [32m+678[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas immutability does not mutate input columns list[0m                                             
00:01 [32m+679[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas immutability does not mutate input columns list[0m                                             
00:01 [32m+679[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas immutability does not mutate input frameDurationsMs[0m                                         
00:01 [32m+680[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas immutability does not mutate input frameDurationsMs[0m                                         
00:01 [32m+680[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas compatibility generated mappings work with ProjectPathPreset[0m                                
00:01 [32m+681[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas compatibility generated mappings work with ProjectPathPreset[0m                                
00:01 [32m+681[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas compatibility generated frames work with resolveTileVisualFrameTimeline[0m                     
00:01 [32m+682[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                        
00:01 [32m+683[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                        
00:01 [32m+684[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                        
00:01 [32m+685[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                        
00:01 [32m+686[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                        
00:01 [32m+687[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                        
00:01 [32m+688[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                        
00:01 [32m+689[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                        
00:01 [32m+690[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                        
00:01 [32m+691[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                        
00:01 [32m+692[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                        
00:01 [32m+693[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                        
00:01 [32m+694[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                        
00:01 [32m+695[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                        
00:01 [32m+696[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                        
00:01 [32m+697[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                        
00:01 [32m+697[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet rejects empty refs[0m                                                                                         
00:01 [32m+698[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet rejects empty refs[0m                                                                                         
00:01 [32m+698[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet rejects duplicate role (different animationId)[0m                                                             
00:01 [32m+699[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet rejects duplicate role (different animationId)[0m                                                             
00:01 [32m+699[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet allows same animationId for different roles[0m                                                                
00:01 [32m+700[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet allows same animationId for different roles[0m                                                                
00:01 [32m+700[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet preserves input order (not sorted by standard order)[0m                                                       
00:01 [32m+701[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet preserves input order (not sorted by standard order)[0m                                                       
00:01 [32m+701[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet exposed refs list is unmodifiable[0m                                                                          
00:01 [32m+702[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet exposed refs list is unmodifiable[0m                                                                          
00:01 [32m+702[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet defensive copy: mutating source list after build does not change set[0m                                       
00:01 [32m+703[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet defensive copy: mutating source list after build does not change set[0m                                       
00:01 [32m+703[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet containsRole: true for present roles[0m                                                                       
00:01 [32m+704[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet containsRole: true for present roles[0m                                                                       
00:01 [32m+704[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet containsRole: false when role absent[0m                                                                       
00:01 [32m+705[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet containsRole: false when role absent[0m                                                                       
00:01 [32m+705[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet refForRole: returns ref when present[0m                                                                       
00:01 [32m+706[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet refForRole: returns ref when present[0m                                                                       
00:01 [32m+706[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet refForRole: null when absent[0m                                                                               
00:01 [32m+707[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet refForRole: null when absent[0m                                                                               
00:01 [32m+707[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet animationIdForRole: id when present[0m                                                                        
00:01 [32m+708[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet animationIdForRole: id when present[0m                                                                        
00:01 [32m+708[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet animationIdForRole: null when absent[0m                                                                       
00:01 [32m+709[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet animationIdForRole: null when absent[0m                                                                       
00:01 [32m+709[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet coversAllRoles: true for covered subset[0m                                                                    
00:01 [32m+710[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet coversAllRoles: true for covered subset[0m                                                                    
00:01 [32m+710[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet coversAllRoles: false if one role missing[0m                                                                  
00:01 [32m+711[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet coversAllRoles: false if one role missing[0m                                                                  
00:01 [32m+711[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet coversAllRoles: true for empty iterable (vacuous every)[0m                                                    
00:01 [32m+712[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet coversAllRoles: true for empty iterable (vacuous every)[0m                                                    
00:01 [32m+712[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet can cover all of standardSurfaceVariantRoleOrder in input order[0m                                            
00:01 [32m+713[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet can cover all of standardSurfaceVariantRoleOrder in input order[0m                                            
00:01 [32m+713[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet value equality: same refs in same order[0m                                                                    
00:01 [32m+714[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet value equality: same refs in same order[0m                                                                    
00:01 [32m+714[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet value equality: different order => not equal[0m                                                               
00:01 [32m+715[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet value equality: different order => not equal[0m                                                               
00:01 [32m+715[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet value equality: same role different animationId[0m                                                            
00:01 [32m+716[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet value equality: same role different animationId[0m                                                            
00:01 [32m+716[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet export: type via map_core[0m                                                                                  
00:01 [32m+717[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet export: type via map_core[0m                                                                                  
00:01 [32m+717[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet set is only a collection of refs (no ProjectSurfacePreset)[0m                                                 
00:01 [32m+718[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet set is only a collection of refs (no ProjectSurfacePreset)[0m                                                 
00:01 [32m+718[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet ProjectManifest toJson: no surface* top-level keys[0m                                                         
00:01 [32m+719[0m: test/map_entity_collision_footprint_test.dart: map entity collision footprint defaults npc 1x1 keeps 1x1 collision at anchor[0m                                                               
00:01 [32m+720[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates an ice ProjectPathPreset with the full standard layout[0m                                     
00:01 [32m+721[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: ... preset generation generates an ice ProjectPathPreset with the full standard layout[0m                                     
00:01 [32m+722[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                           
00:01 [32m+723[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                           
00:01 [32m+724[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                           
00:01 [32m+725[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                           
00:01 [32m+726[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                           
00:01 [32m+727[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                           
00:01 [32m+728[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                           
00:01 [32m+729[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                           
00:01 [32m+730[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                           
00:01 [32m+731[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                           
00:01 [32m+732[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas preset generation applies custom common duration[0m                              
00:01 [32m+733[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 2. minimal coherent: no unused diagnostics[0m                                        
00:01 [32m+734[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 2. minimal coherent: no unused diagnostics[0m                                        
00:01 [32m+735[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 2. minimal coherent: no unused diagnostics[0m                                        
00:01 [32m+736[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas compatibility is compatible with LegacyPathSurfaceView[0m                        
00:01 [32m+737[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 3. unreferenced atlas → unusedAtlas warning and metadata[0m                          
00:01 [32m+738[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas compatibility is compatible with LegacyProjectSurfaceCatalogView[0m              
00:01 [32m+739[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 4. multiple unused atlases: order follows catalog.atlases a,b,c[0m                   
00:01 [32m+740[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas compatibility is compatible with resolveTileVisualFrameTimeline[0m               
00:01 [32m+741[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas compatibility is compatible with resolveTileVisualFrameTimeline[0m               
00:01 [32m+742[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas compatibility is compatible with resolveTileVisualFrameTimeline[0m               
00:01 [32m+743[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas compatibility is compatible with resolveTileVisualFrameTimeline[0m               
00:01 [32m+744[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 8. multiple unused animations: order follows catalog.animations a,b,c[0m             
00:01 [32m+745[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for empty id[0m                       
00:01 [32m+746[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for empty id[0m                       
00:01 [32m+747[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 10. animationId exact: spaced id not matched by preset ref[0m                        
00:01 [32m+748[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for empty name[0m                     
00:01 [32m+749[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for empty name[0m                     
00:01 [32m+749[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 11. same animation referenced by two presets: not unused[0m                          
00:01 [32m+750[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for empty tilesetId[0m                
00:01 [32m+751[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for empty tilesetId[0m                
00:01 [32m+751[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 12. same atlas referenced by two animations: atlas not unused[0m                     
00:01 [32m+752[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for negative firstColumn[0m           
00:01 [32m+753[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 13. global order: unusedAtlas before unusedAnimation[0m                              
00:01 [32m+754[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for negative startRow[0m              
00:01 [32m+755[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 14. warnings only: hasErrors false, hasDiagnostics true[0m                           
00:01 [32m+756[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for empty variants[0m                 
00:01 [32m+757[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for empty variants[0m                 
00:01 [32m+757[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 15. byKind(unusedAtlas) only atlas warnings[0m                                       
00:01 [32m+758[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for duplicate variants[0m             
00:01 [32m+759[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for duplicate variants[0m             
00:01 [32m+759[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 16. byKind(unusedAnimation) only animation warnings[0m                               
00:01 [32m+760[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for invalid frameCount[0m             
00:01 [32m+761[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 17. byKind returns an unmodifiable list (add → UnsupportedError)[0m                  
00:01 [32m+762[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 17. byKind returns an unmodifiable list (add → UnsupportedError)[0m                  
00:01 [32m+763[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for invalid defaultDurationMs[0m      
00:01 [32m+764[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 18. diagnostics list is unmodifiable (add → UnsupportedError)[0m                     
00:01 [32m+765[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: ... validation delegation delegates validation for frameDurationsMs length mismatch[0m                                        
00:01 [32m+766[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 19. unused function does not emit Lot 34 error kinds[0m                              
00:01 [32m+767[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for non-positive frame durations[0m   
00:01 [32m+768[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 20. Lot 34 diagnoseProjectSurfaceCatalog still returns errors[0m                     
00:01 [32m+769[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 20. Lot 34 diagnoseProjectSurfaceCatalog still returns errors[0m                     
00:01 [32m+769[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 21. warning severity exists and differs from error[0m                                
00:01 [32m+770[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 21. warning severity exists and differs from error[0m                                
00:01 [32m+770[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) V0 does not diagnose unused presets yet: isolated preset, no false presetId[0m       
00:01 [32m+771[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) V0 does not diagnose unused presets yet: isolated preset, no false presetId[0m       
00:01 [32m+771[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 23. public API: unused + kinds via map_core only[0m                                  
00:01 [32m+772[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 23. public API: unused + kinds via map_core only[0m                                  
00:01 [32m+772[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 24. ProjectManifest still has no Surface keys (Lot 35)[0m                            
00:01 [32m+773[0m: test/legacy_editor_json_compat_collision_test.dart: legacy collision profile compat migrates broken manual house profile from full padding base to authored silhouette[0m                     
00:01 [32m+774[0m: test/legacy_editor_json_compat_collision_test.dart: legacy collision profile compat migrates broken manual house profile from full padding base to authored silhouette[0m                     
00:01 [32m+774[0m: test/legacy_editor_json_compat_collision_test.dart: legacy collision profile compat unknown legacy keys do not prevent manifest parsing[0m                                                    
00:01 [32m+775[0m: test/legacy_editor_json_compat_collision_test.dart: legacy collision profile compat unknown legacy keys do not prevent manifest parsing[0m                                                    
00:01 [32m+775[0m: test/legacy_editor_json_compat_collision_test.dart: legacy collision profile compat missing pokemon config still falls back to the manifest default[0m                                        
00:01 [32m+776[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 1. empty catalog: counts, isEmpty, unmodifiable empty lists[0m                                                         
00:01 [32m+777[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 1. empty catalog: counts, isEmpty, unmodifiable empty lists[0m                                                         
00:01 [32m+777[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 2. catalog with 2 of each kind: counts, isNotEmpty[0m                                                                  
00:01 [32m+778[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 2. catalog with 2 of each kind: counts, isNotEmpty[0m                                                                  
00:01 [32m+778[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 3. order of atlases preserved[0m                                                                                       
00:01 [32m+779[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 3. order of atlases preserved[0m                                                                                       
00:01 [32m+779[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 4. order of animations preserved[0m                                                                                    
00:01 [32m+780[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 4. order of animations preserved[0m                                                                                    
00:01 [32m+780[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 5. order of presets preserved[0m                                                                                       
00:01 [32m+781[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 5. order of presets preserved[0m                                                                                       
00:01 [32m+781[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 6. exposed lists are unmodifiable: add throws[0m                                                                       
00:01 [32m+782[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 6. exposed lists are unmodifiable: add throws[0m                                                                       
00:01 [32m+782[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 7. defensive copy: atlases source mutated after build[0m                                                               
00:01 [32m+783[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 7. defensive copy: atlases source mutated after build[0m                                                               
00:01 [32m+783[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 8. defensive copy: animations source mutated after build[0m                                                            
00:01 [32m+784[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 8. defensive copy: animations source mutated after build[0m                                                            
00:01 [32m+784[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 9. defensive copy: presets source mutated after build[0m                                                               
00:01 [32m+785[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 9. defensive copy: presets source mutated after build[0m                                                               
00:01 [32m+785[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 10. duplicate atlas id throws ValidationException[0m                                                                   
00:01 [32m+786[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 10. duplicate atlas id throws ValidationException[0m                                                                   
00:01 [32m+786[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 11. duplicate animation id throws ValidationException[0m                                                               
00:01 [32m+787[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 11. duplicate animation id throws ValidationException[0m                                                               
00:01 [32m+787[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 12. duplicate preset id throws ValidationException[0m                                                                  
00:01 [32m+788[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 12. duplicate preset id throws ValidationException[0m                                                                  
00:01 [32m+788[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 13. same id string across collections is allowed; lookups[0m                                                           
00:01 [32m+789[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 13. same id string across collections is allowed; lookups[0m                                                           
00:01 [32m+789[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 14. atlasById returns instance when present[0m                                                                         
00:01 [32m+790[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 14. atlasById returns instance when present[0m                                                                         
00:01 [32m+790[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 15. atlasById null when absent[0m                                                                                      
00:01 [32m+791[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 15. atlasById null when absent[0m                                                                                      
00:01 [32m+791[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 16. animationById returns instance when present[0m                                                                     
00:01 [32m+792[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 16. animationById returns instance when present[0m                                                                     
00:01 [32m+792[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 17. animationById null when absent[0m                                                                                  
00:01 [32m+793[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 17. animationById null when absent[0m                                                                                  
00:01 [32m+793[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 18. presetById returns instance when present[0m                                                                        
00:01 [32m+794[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 18. presetById returns instance when present[0m                                                                        
00:01 [32m+794[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 19. presetById null when absent[0m                                                                                     
00:01 [32m+795[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 19. presetById null when absent[0m                                                                                     
00:01 [32m+795[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 20. containsAtlas delegates to lookup[0m                                                                               
00:01 [32m+796[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 20. containsAtlas delegates to lookup[0m                                                                               
00:01 [32m+796[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 21. containsAnimation delegates to lookup[0m                                                                           
00:01 [32m+797[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 21. containsAnimation delegates to lookup[0m                                                                           
00:01 [32m+797[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 22. containsPreset delegates to lookup[0m                                                                              
00:01 [32m+798[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 22. containsPreset delegates to lookup[0m                                                                              
00:01 [32m+798[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 23. lookups use exact id string (no trim) — atlas[0m                                                                   
00:01 [32m+799[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 23. lookups use exact id string (no trim) — atlas[0m                                                                   
00:01 [32m+799[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 24. does not resolve missing animationId on preset; no error[0m                                                        
00:01 [32m+800[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 24. does not resolve missing animationId on preset; no error[0m                                                        
00:01 [32m+800[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 25. value equality: same content same order: == and hashCode[0m                                                        
00:01 [32m+801[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 25. value equality: same content same order: == and hashCode[0m                                                        
00:01 [32m+801[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 26. value inequality: different atlas order[0m                                                                         
00:01 [32m+802[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 26. value inequality: different atlas order[0m                                                                         
00:01 [32m+802[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 27. value inequality: different animation order[0m                                                                     
00:01 [32m+803[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 27. value inequality: different animation order[0m                                                                     
00:01 [32m+803[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 28. value inequality: different preset order[0m                                                                        
00:01 [32m+804[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 28. value inequality: different preset order[0m                                                                        
00:01 [32m+804[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content[0m                                                                             
00:01 [32m+805[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content[0m                                                                             
00:01 [32m+805[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core[0m                                                      
00:01 [32m+806[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core[0m                                                      
00:01 [32m+806[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest still has no Surface persistence keys (Lot 33)[0m                                                  
00:01 [32m+807[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest still has no Surface persistence keys (Lot 33)[0m                                                  
00:01 [32m+807[0m: All tests passed![0m                                                                                                                                                                          
```

## 19. Total exact du `dart test` complet (map_core)

- **807** tests ; ligne de fin : `+807: All tests passed!` (visible en section 18.4, dernière ligne non vide).

## 20. Auto-review indépendante (35-bis)

| Critère | OK |
|--------|-----|
| Lot limité à l’evidence fix (un fichier rapport) | Oui |
| Aucun modèle Surface supplémentaire créé | Oui |
| Aucun manifest modifié | Oui |
| Aucun generated créé | Oui |
| Aucun `SurfacePresetKind` / `surfaceKind` | Oui |
| Aucun `unusedPreset` (kind) | Oui |
| Aucun runtime / editor / gameplay / battle modifié | Oui |
| Contenus complets fournis (§11–12) | Oui |
| Diffs complets fournis (§14–16) | Oui |
| Tests relancés, sorties exactes (§18) | Oui |
| `map_core` complet : 807, vert | Oui |
| Aucune commande Git interdite | Oui (lecture seule) |

---

**Fin du rapport Lot 35-bis.**
