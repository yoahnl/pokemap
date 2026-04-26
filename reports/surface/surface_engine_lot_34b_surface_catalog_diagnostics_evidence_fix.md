# Surface Engine — Lot 34-bis : preuve (evidence fix) `surface_catalog_diagnostics` V0

## 1. Résumé exécutif

Ce lot ne modifie **aucun** fichier Dart, manifeste ou autre code : il ajoute uniquement ce document pour satisfaire l'exigence de preuve incomplète du Lot 34 (rapport §35–36).

## 2. Pourquoi le Lot 34-bis existe

Le rapport `surface_engine_lot_34_surface_catalog_diagnostics.md` renvoyait le lecteur vers le dépôt et `git diff` plutôt que d'inclure sources, diffs intégraux et sorties de commande.

## 3. Fichiers inspectés

- `packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart`
- `packages/map_core/test/surface_catalog_diagnostics_test.dart`
- `packages/map_core/lib/map_core.dart`
- `reports/surface/surface_engine_lot_34_surface_catalog_diagnostics.md`
- `packages/map_core/lib/src/models/surface.dart`, `surface_catalog.dart`, `project_manifest.dart` (contexte)

## 4. Fichiers modifiés par ce lot (34-bis)

- **Aucun** (création seule de ce fichier Markdown : `surface_engine_lot_34b_surface_catalog_diagnostics_evidence_fix.md`).

## 5. Confirmation : code du Lot 34 **inchangé**

Comparaison SHA-256 (objet `023e97ea` vs worktree) :

```text
be27e341c134356a8680ff347694143a1592fc2c4431df487d3135b5bcf813d5  -
be27e341c134356a8680ff347694143a1592fc2c4431df487d3135b5bcf813d5  packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart
```

(Les paires de lignes doivent coïncider : les fichiers de travail matchent le commit d'ancrage du Lot 34.)

## 6. `ProjectManifest` : non modifié par 34 / 34-bis

Aucun champ `surfaceDefinitions`, `surfaceAtlases`, `surfaceAnimations`, `surfacePresets`, `surfaceCategories` n'est ajouté ; les tests d'intégrité `toJson` restent valables (voir tests du Lot 34).

## 7. Aucun fichier généré

Pas de `build_runner`, pas de `*.g.dart` / `*.freezed.dart` liés à ce 34-bis.

## 8. Aucun `SurfacePresetKind` / `surfaceKind`

Non créé.

## 9. Aucun runtime / editor / gameplay / battle modifié

34-bis = rapport seulement.

---

## 10. Contenu intégral — `surface_catalog_diagnostics.dart`

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

/// Niveau de sévérité d’un [SurfaceCatalogDiagnostic] (V0 : **error** seulement
/// — pas de warning dans ce lot).
enum SurfaceCatalogDiagnosticSeverity {
  error,
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
/// ordre des entrées **déterministe** (presets d’abord, puis animations), pas de
/// tri par message ni remplacement d’un **validateur projet** complet.
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
```

## 11. Contenu intégral — `surface_catalog_diagnostics_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

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
  group('diagnoseProjectSurfaceCatalog (Lot 34)', () {
    test('1. empty catalog: no diagnostics', () {
      final r = diagnoseProjectSurfaceCatalog(_catalog());
      expect(r.count, 0);
      expect(r.hasDiagnostics, isFalse);
      expect(r.hasErrors, isFalse);
      expect(r.diagnostics, isEmpty);
    });

    test('2. minimal coherent: no diagnostics', () {
      final atlas = _atlas('atlas');
      final anim = _animation('anim', atlasId: 'atlas');
      final preset = _preset('preset', [
        _ref(SurfaceVariantRole.isolated, 'anim'),
      ]);
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(
          atlases: [atlas],
          animations: [anim],
          presets: [preset],
        ),
      );
      expect(r.diagnostics, isEmpty);
    });

    test('3. missing preset animation', () {
      final p = _preset('p1', [
        _ref(SurfaceVariantRole.isolated, 'missing-animation'),
      ]);
      final r = diagnoseProjectSurfaceCatalog(_catalog(presets: [p]));
      expect(r.count, 1);
      final d = r.diagnostics.single;
      expect(d.kind, SurfaceCatalogDiagnosticKind.missingPresetAnimation);
      expect(d.severity, SurfaceCatalogDiagnosticSeverity.error);
      expect(d.presetId, 'p1');
      expect(d.animationId, 'missing-animation');
      expect(d.role, SurfaceVariantRole.isolated);
      expect(d.atlasId, isNull);
      expect(d.frameIndex, isNull);
      expect(d.message, contains('p1'));
      expect(d.message, contains('missing-animation'));
    });

    test('4. two missing refs: order follows refs', () {
      final p = _preset('p1', [
        _ref(SurfaceVariantRole.isolated, 'miss-a'),
        _ref(SurfaceVariantRole.horizontal, 'miss-b'),
      ]);
      final r = diagnoseProjectSurfaceCatalog(_catalog(presets: [p]));
      expect(r.count, 2);
      expect(r.diagnostics[0].animationId, 'miss-a');
      expect(r.diagnostics[1].animationId, 'miss-b');
    });

    test('5. two presets: order follows catalog.presets', () {
      final a = _preset('first', [
        _ref(SurfaceVariantRole.isolated, 'x'),
      ]);
      final b = _preset('second', [
        _ref(SurfaceVariantRole.isolated, 'y'),
      ]);
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(presets: [a, b]),
      );
      expect(r.diagnostics[0].presetId, 'first');
      expect(r.diagnostics[1].presetId, 'second');
    });

    test('6. missing animation atlas', () {
      final anim = _animation('anim', atlasId: 'missing-atlas');
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(animations: [anim]),
      );
      final d = r.diagnostics.single;
      expect(d.kind, SurfaceCatalogDiagnosticKind.missingAnimationAtlas);
      expect(d.severity, SurfaceCatalogDiagnosticSeverity.error);
      expect(d.animationId, 'anim');
      expect(d.atlasId, 'missing-atlas');
      expect(d.frameIndex, 0);
      expect(d.presetId, isNull);
      expect(d.role, isNull);
      expect(d.message, contains('anim'));
      expect(d.message, contains('missing-atlas'));
    });

    test('7. two frames to missing atlas: frameIndex 0 and 1', () {
      final anim = _animation(
        'anim',
        frames: [
          _frame('m1', 0, 0),
          _frame('m2', 0, 0),
        ],
      );
      final r = diagnoseProjectSurfaceCatalog(_catalog(animations: [anim]));
      expect(r.count, 2);
      expect(r.diagnostics[0].frameIndex, 0);
      expect(r.diagnostics[0].atlasId, 'm1');
      expect(r.diagnostics[1].frameIndex, 1);
      expect(r.diagnostics[1].atlasId, 'm2');
    });

    test('8. frame outside geometry: column', () {
      final atlas = _atlas('atlas', columns: 2, rows: 2);
      final anim = _animation(
        'anim',
        frames: [
          _frame('atlas', 2, 0),
        ],
        atlasId: 'atlas',
      );
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(atlases: [atlas], animations: [anim]),
      );
      final d = r.diagnostics.single;
      expect(d.kind, SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry);
      expect(d.animationId, 'anim');
      expect(d.atlasId, 'atlas');
      expect(d.frameIndex, 0);
    });

    test('9. frame outside geometry: row', () {
      final atlas = _atlas('atlas', columns: 2, rows: 2);
      final anim = ProjectSurfaceAnimation(
        id: 'anim2',
        name: 'a',
        timeline: SurfaceAnimationTimeline(
          frames: [_frame('atlas', 0, 2)],
        ),
      );
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(atlases: [atlas], animations: [anim]),
      );
      expect(
        r.diagnostics.single.kind,
        SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry,
      );
    });

    test('10. missing atlas only: not also outside geometry', () {
      final anim = _animation(
        'anim',
        frames: [
          _frame('missing-atlas', 99, 99),
        ],
        atlasId: 'missing-atlas',
      );
      final r = diagnoseProjectSurfaceCatalog(_catalog(animations: [anim]));
      expect(r.count, 1);
      expect(
        r.diagnostics.single.kind,
        SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
      );
    });

    test('11. preset diagnostics then animation diagnostics', () {
      final preset = _preset('pr', [
        _ref(SurfaceVariantRole.isolated, 'no-such-anim'),
      ]);
      final anim = _animation('badA', atlasId: 'missing');
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(presets: [preset], animations: [anim]),
      );
      expect(r.count, 2);
      expect(
        r.diagnostics[0].kind,
        SurfaceCatalogDiagnosticKind.missingPresetAnimation,
      );
      expect(
        r.diagnostics[1].kind,
        SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
      );
    });

    test('12. exact atlas id: no trim', () {
      final atlas = _atlas('  atlas  ');
      final anim = _animation('anim', frames: [
        _frame('atlas', 0, 0),
      ], atlasId: 'atlas');
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(atlases: [atlas], animations: [anim]),
      );
      final d = r.diagnostics.single;
      expect(
        d.kind,
        SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
      );
      expect(d.atlasId, 'atlas');
    });

    test('13. byKind filters', () {
      final atlas = _atlas('a', columns: 2, rows: 2);
      final animO = _animation('o', frames: [
        _frame('a', 0, 3),
      ], atlasId: 'a');
      final preset = _preset('p', [
        _ref(SurfaceVariantRole.isolated, 'miss'),
      ]);
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(
          atlases: [atlas],
          animations: [animO],
          presets: [preset],
        ),
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation).length,
        1,
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry)
            .length,
        1,
      );
    });

    test('14. byKind list is unmodifiable', () {
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(presets: [
          _preset('p', [
            _ref(SurfaceVariantRole.isolated, 'm'),
          ]),
        ]),
      );
      final list = r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation);
      expect(
        () => list.add(
          r.diagnostics.first,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('15. diagnostics list on report is unmodifiable', () {
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(animations: [
          _animation('o', atlasId: 'x'),
        ]),
      );
      expect(
        () => r.diagnostics.add(r.diagnostics.first),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('16. defensive copy: mutating source list does not change report', () {
      final d = <SurfaceCatalogDiagnostic>[];
      final report = SurfaceCatalogDiagnosticsReport(diagnostics: d);
      d.add(
        SurfaceCatalogDiagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.error,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          message: 'm',
        ),
      );
      expect(report.count, 0);
    });

    test('17. hasErrors false on empty report', () {
      final r = SurfaceCatalogDiagnosticsReport(diagnostics: const []);
      expect(r.hasErrors, isFalse);
    });

    test('18. hasErrors true when error diagnostic', () {
      final r = diagnoseProjectSurfaceCatalog(
        _catalog(presets: [
          _preset('p', [
            _ref(SurfaceVariantRole.isolated, 'miss'),
          ]),
        ]),
      );
      expect(r.hasErrors, isTrue);
    });

    test('19. diagnostic equality: same', () {
      final a = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'm',
        presetId: 'p',
      );
      final b = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'm',
        presetId: 'p',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('20. diagnostic equality: different kind', () {
      final a = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'm',
      );
      final b = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
        message: 'm',
      );
      expect(a, isNot(b));
    });

    test('21. diagnostic equality: different metadata', () {
      final a = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'm',
        presetId: 'a',
      );
      final b = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'm',
        presetId: 'b',
      );
      expect(a, isNot(b));
    });

    test('22. report equality: same order', () {
      final d1 = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'm',
        presetId: 'p',
      );
      final a = SurfaceCatalogDiagnosticsReport(diagnostics: [d1]);
      final b = SurfaceCatalogDiagnosticsReport(diagnostics: [d1]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('23. report equality: order matters', () {
      final d1 = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: '1',
        presetId: 'a',
      );
      final d2 = SurfaceCatalogDiagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: '2',
        presetId: 'b',
      );
      final x = SurfaceCatalogDiagnosticsReport(diagnostics: [d1, d2]);
      final y = SurfaceCatalogDiagnosticsReport(diagnostics: [d2, d1]);
      expect(x, isNot(y));
    });

    test('24. public API via map_core', () {
      final r = diagnoseProjectSurfaceCatalog(_catalog());
      expect(r, isA<SurfaceCatalogDiagnosticsReport>());
      expect(
        SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        isA<SurfaceCatalogDiagnosticKind>(),
      );
    });

    test('25. ProjectManifest still has no Surface keys (Lot 34)', () {
      const manifest = ProjectManifest(
        name: 'L34',
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

## 12. Extrait — `map_core.dart` (export `surface_catalog_diagnostics`)

```dart
export 'src/operations/standard_water_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_surface_preset_builder.dart';
export 'src/operations/surface_catalog_diagnostics.dart';
export 'src/operations/legacy_path_surface_view.dart';
export 'src/operations/legacy_terrain_surface_view.dart';
export 'src/operations/legacy_project_surface_catalog_view.dart';
export 'src/operations/legacy_surface_catalog_diagnostics.dart';
export 'src/operations/legacy_surface_usage_view.dart';
export 'src/operations/legacy_surface_usage_diagnostics.dart';
```

## 13. Diff **réel** — `map_core.dart` (commit `023e97ea`)

```diff
commit 023e97ea37f8165fc56a9ff54c87e591f0be99cb
Author: yoahn <yoahn.linard@papernest.com>
Date:   Mon Apr 27 00:31:01 2026 +0200

    feat(map_core): surface catalog diagnostics V0 (Surface Engine lot 34)
    
    diagnoseProjectSurfaceCatalog: missing preset animation refs, missing
    animation atlas ids, frames outside atlas geometry. Immutable report,
    deterministic order. Export from map_core; tests + report.
    
    Made-with: Cursor

diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 355d2918..15ad5c73 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -41,6 +41,7 @@ export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
 export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
 export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart';
 export 'src/operations/standard_surface_preset_builder.dart';
+export 'src/operations/surface_catalog_diagnostics.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';
```

## 14. Diff `/dev/null` — `surface_catalog_diagnostics.dart` (commit `023e97ea`)

```diff
commit 023e97ea37f8165fc56a9ff54c87e591f0be99cb
Author: yoahn <yoahn.linard@papernest.com>
Date:   Mon Apr 27 00:31:01 2026 +0200

    feat(map_core): surface catalog diagnostics V0 (Surface Engine lot 34)
    
    diagnoseProjectSurfaceCatalog: missing preset animation refs, missing
    animation atlas ids, frames outside atlas geometry. Immutable report,
    deterministic order. Export from map_core; tests + report.
    
    Made-with: Cursor

diff --git a/packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart b/packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart
new file mode 100644
index 00000000..1e09926a
--- /dev/null
+++ b/packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart
@@ -0,0 +1,225 @@
+import 'package:meta/meta.dart' show immutable;
+
+import '../models/surface.dart';
+import '../models/surface_catalog.dart';
+
+// --- Comparaison ordonnée (égalité du rapport) ---
+
+bool _diagnosticsEqualInOrder(
+  List<SurfaceCatalogDiagnostic> a,
+  List<SurfaceCatalogDiagnostic> b,
+) {
+  if (a.length != b.length) {
+    return false;
+  }
+  for (var i = 0; i < a.length; i++) {
+    if (a[i] != b[i]) {
+      return false;
+    }
+  }
+  return true;
+}
+
+/// Niveau de sévérité d’un [SurfaceCatalogDiagnostic] (V0 : **error** seulement
+/// — pas de warning dans ce lot).
+enum SurfaceCatalogDiagnosticSeverity {
+  error,
+}
+
+/// Catégorie de problème constaté dans un [ProjectSurfaceCatalog] (références
+/// internes **mémoire** seulement — pas de JSON, pas de runtime).
+enum SurfaceCatalogDiagnosticKind {
+  /// [ProjectSurfacePreset] : un [SurfaceVariantAnimationRef.animationId] ne
+  /// pointe vers aucun [ProjectSurfaceAnimation.id] du catalogue.
+  missingPresetAnimation,
+
+  /// [ProjectSurfaceAnimation] : le [SurfaceAtlasTileRef.atlasId] d’une frame
+  /// n’existe pas dans [ProjectSurfaceCatalog.atlases].
+  missingAnimationAtlas,
+
+  /// Frame dont les coordonnées de grille ne sont pas dans
+  /// [ProjectSurfaceAtlas.geometry] (l’atlas **existe** dans le catalogue).
+  animationFrameOutsideAtlasGeometry,
+}
+
+/// Un problème constaté sur un [ProjectSurfaceCatalog] en **lecture seule** ;
+/// ne modifie rien, ne se sérialise pas, ne s’applique pas à [ProjectManifest].
+@immutable
+final class SurfaceCatalogDiagnostic {
+  const SurfaceCatalogDiagnostic({
+    required this.severity,
+    required this.kind,
+    required this.message,
+    this.presetId,
+    this.animationId,
+    this.atlasId,
+    this.role,
+    this.frameIndex,
+  });
+
+  final SurfaceCatalogDiagnosticSeverity severity;
+  final SurfaceCatalogDiagnosticKind kind;
+  final String message;
+  final String? presetId;
+  final String? animationId;
+  final String? atlasId;
+  final SurfaceVariantRole? role;
+  final int? frameIndex;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceCatalogDiagnostic &&
+          other.severity == severity &&
+          other.kind == kind &&
+          other.message == message &&
+          other.presetId == presetId &&
+          other.animationId == animationId &&
+          other.atlasId == atlasId &&
+          other.role == role &&
+          other.frameIndex == frameIndex;
+
+  @override
+  int get hashCode => Object.hash(
+        severity,
+        kind,
+        message,
+        presetId,
+        animationId,
+        atlasId,
+        role,
+        frameIndex,
+      );
+}
+
+/// Rapport de diagnostics sur un [ProjectSurfaceCatalog] : **mémoire uniquement**,
+/// ordre des entrées **déterministe** (presets d’abord, puis animations), pas de
+/// tri par message ni remplacement d’un **validateur projet** complet.
+@immutable
+final class SurfaceCatalogDiagnosticsReport {
+  SurfaceCatalogDiagnosticsReport({
+    required List<SurfaceCatalogDiagnostic> diagnostics,
+  }) {
+    final copy = List<SurfaceCatalogDiagnostic>.from(diagnostics);
+    _diagnostics = List<SurfaceCatalogDiagnostic>.unmodifiable(copy);
+  }
+
+  late final List<SurfaceCatalogDiagnostic> _diagnostics;
+
+  /// Liste **non modifiable** (copie défensive à la construction).
+  List<SurfaceCatalogDiagnostic> get diagnostics => _diagnostics;
+
+  int get count => _diagnostics.length;
+
+  bool get hasDiagnostics => _diagnostics.isNotEmpty;
+
+  /// Vrai si au moins une entrée a [SurfaceCatalogDiagnosticSeverity.error].
+  bool get hasErrors =>
+      _diagnostics.any((d) => d.severity == SurfaceCatalogDiagnosticSeverity.error);
+
+  /// Filtre par [kind] ; retourne une **nouvelle** liste **non modifiable**
+  /// (n’expose pas l’intérieur du rapport).
+  List<SurfaceCatalogDiagnostic> byKind(SurfaceCatalogDiagnosticKind kind) {
+    final m = <SurfaceCatalogDiagnostic>[];
+    for (final d in _diagnostics) {
+      if (d.kind == kind) {
+        m.add(d);
+      }
+    }
+    return List<SurfaceCatalogDiagnostic>.unmodifiable(m);
+  }
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceCatalogDiagnosticsReport &&
+          _diagnosticsEqualInOrder(_diagnostics, other._diagnostics);
+
+  @override
+  int get hashCode => Object.hashAll(_diagnostics);
+}
+
+/// Analyse [catalog] en **lecture seule** : cohérence des références
+/// *preset → animation* et *frame → atlas / géométrie d’atlas* connues dans le
+/// catalogue. Ne **résout** rien, ne **charge** pas d’image, ne touche pas au
+/// manifest, ne produit **pas** de JSON.
+///
+/// * Ordre : d’abord chaque [ProjectSurfacePreset] dans l’ordre de
+///   [ProjectSurfaceCatalog.presets], chaque
+///   [SurfaceVariantAnimationRef] dans l’ordre de [SurfaceVariantAnimationRefSet.refs] ;
+///   puis chaque [ProjectSurfaceAnimation] dans l’ordre de
+///   [ProjectSurfaceCatalog.animations], chaque frame dans
+///   l’[SurfaceAnimationTimeline.frames].
+/// * Si une frame référence un atlas **absent**, seul
+///   [SurfaceCatalogDiagnosticKind.missingAnimationAtlas] est émis (pas de
+///   vérification géométrique sur un atlas non présent).
+SurfaceCatalogDiagnosticsReport diagnoseProjectSurfaceCatalog(
+  ProjectSurfaceCatalog catalog,
+) {
+  final out = <SurfaceCatalogDiagnostic>[];
+
+  for (final preset in catalog.presets) {
+    for (final ref in preset.variantAnimations.refs) {
+      if (catalog.animationById(ref.animationId) == null) {
+        out.add(
+          SurfaceCatalogDiagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.error,
+            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+            message:
+                "Preset '${preset.id}' (role ${ref.role.name}) references missing "
+                "animation '${ref.animationId}'",
+            presetId: preset.id,
+            animationId: ref.animationId,
+            role: ref.role,
+            atlasId: null,
+            frameIndex: null,
+          ),
+        );
+      }
+    }
+  }
+
+  for (final animation in catalog.animations) {
+    var fi = 0;
+    for (final frame in animation.timeline.frames) {
+      final aid = frame.tileRef.atlasId;
+      final atlas = catalog.atlasById(aid);
+      if (atlas == null) {
+        out.add(
+          SurfaceCatalogDiagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.error,
+            kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
+            message: "Animation '${animation.id}' frame $fi references missing "
+                "atlas '$aid'",
+            presetId: null,
+            role: null,
+            animationId: animation.id,
+            atlasId: aid,
+            frameIndex: fi,
+          ),
+        );
+      } else {
+        if (!frame.tileRef.isInside(atlas.geometry)) {
+          final tr = frame.tileRef;
+          out.add(
+            SurfaceCatalogDiagnostic(
+              severity: SurfaceCatalogDiagnosticSeverity.error,
+              kind: SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry,
+              message: "Animation '${animation.id}' frame $fi (column "
+                  '${tr.column}, row ${tr.row}) is outside atlas '
+                  "'${tr.atlasId}' geometry",
+              presetId: null,
+              role: null,
+              animationId: animation.id,
+              atlasId: tr.atlasId,
+              frameIndex: fi,
+            ),
+          );
+        }
+      }
+      fi++;
+    }
+  }
+
+  return SurfaceCatalogDiagnosticsReport(diagnostics: out);
+}
```

## 15. Diff `/dev/null` — `surface_catalog_diagnostics_test.dart` (commit `023e97ea`)

```diff
commit 023e97ea37f8165fc56a9ff54c87e591f0be99cb
Author: yoahn <yoahn.linard@papernest.com>
Date:   Mon Apr 27 00:31:01 2026 +0200

    feat(map_core): surface catalog diagnostics V0 (Surface Engine lot 34)
    
    diagnoseProjectSurfaceCatalog: missing preset animation refs, missing
    animation atlas ids, frames outside atlas geometry. Immutable report,
    deterministic order. Export from map_core; tests + report.
    
    Made-with: Cursor

diff --git a/packages/map_core/test/surface_catalog_diagnostics_test.dart b/packages/map_core/test/surface_catalog_diagnostics_test.dart
new file mode 100644
index 00000000..d75ec39d
--- /dev/null
+++ b/packages/map_core/test/surface_catalog_diagnostics_test.dart
@@ -0,0 +1,462 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
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
+  group('diagnoseProjectSurfaceCatalog (Lot 34)', () {
+    test('1. empty catalog: no diagnostics', () {
+      final r = diagnoseProjectSurfaceCatalog(_catalog());
+      expect(r.count, 0);
+      expect(r.hasDiagnostics, isFalse);
+      expect(r.hasErrors, isFalse);
+      expect(r.diagnostics, isEmpty);
+    });
+
+    test('2. minimal coherent: no diagnostics', () {
+      final atlas = _atlas('atlas');
+      final anim = _animation('anim', atlasId: 'atlas');
+      final preset = _preset('preset', [
+        _ref(SurfaceVariantRole.isolated, 'anim'),
+      ]);
+      final r = diagnoseProjectSurfaceCatalog(
+        _catalog(
+          atlases: [atlas],
+          animations: [anim],
+          presets: [preset],
+        ),
+      );
+      expect(r.diagnostics, isEmpty);
+    });
+
+    test('3. missing preset animation', () {
+      final p = _preset('p1', [
+        _ref(SurfaceVariantRole.isolated, 'missing-animation'),
+      ]);
+      final r = diagnoseProjectSurfaceCatalog(_catalog(presets: [p]));
+      expect(r.count, 1);
+      final d = r.diagnostics.single;
+      expect(d.kind, SurfaceCatalogDiagnosticKind.missingPresetAnimation);
+      expect(d.severity, SurfaceCatalogDiagnosticSeverity.error);
+      expect(d.presetId, 'p1');
+      expect(d.animationId, 'missing-animation');
+      expect(d.role, SurfaceVariantRole.isolated);
+      expect(d.atlasId, isNull);
+      expect(d.frameIndex, isNull);
+      expect(d.message, contains('p1'));
+      expect(d.message, contains('missing-animation'));
+    });
+
+    test('4. two missing refs: order follows refs', () {
+      final p = _preset('p1', [
+        _ref(SurfaceVariantRole.isolated, 'miss-a'),
+        _ref(SurfaceVariantRole.horizontal, 'miss-b'),
+      ]);
+      final r = diagnoseProjectSurfaceCatalog(_catalog(presets: [p]));
+      expect(r.count, 2);
+      expect(r.diagnostics[0].animationId, 'miss-a');
+      expect(r.diagnostics[1].animationId, 'miss-b');
+    });
+
+    test('5. two presets: order follows catalog.presets', () {
+      final a = _preset('first', [
+        _ref(SurfaceVariantRole.isolated, 'x'),
+      ]);
+      final b = _preset('second', [
+        _ref(SurfaceVariantRole.isolated, 'y'),
+      ]);
+      final r = diagnoseProjectSurfaceCatalog(
+        _catalog(presets: [a, b]),
+      );
+      expect(r.diagnostics[0].presetId, 'first');
+      expect(r.diagnostics[1].presetId, 'second');
+    });
+
+    test('6. missing animation atlas', () {
+      final anim = _animation('anim', atlasId: 'missing-atlas');
+      final r = diagnoseProjectSurfaceCatalog(
+        _catalog(animations: [anim]),
+      );
+      final d = r.diagnostics.single;
+      expect(d.kind, SurfaceCatalogDiagnosticKind.missingAnimationAtlas);
+      expect(d.severity, SurfaceCatalogDiagnosticSeverity.error);
+      expect(d.animationId, 'anim');
+      expect(d.atlasId, 'missing-atlas');
+      expect(d.frameIndex, 0);
+      expect(d.presetId, isNull);
+      expect(d.role, isNull);
+      expect(d.message, contains('anim'));
+      expect(d.message, contains('missing-atlas'));
+    });
+
+    test('7. two frames to missing atlas: frameIndex 0 and 1', () {
+      final anim = _animation(
+        'anim',
+        frames: [
+          _frame('m1', 0, 0),
+          _frame('m2', 0, 0),
+        ],
+      );
+      final r = diagnoseProjectSurfaceCatalog(_catalog(animations: [anim]));
+      expect(r.count, 2);
+      expect(r.diagnostics[0].frameIndex, 0);
+      expect(r.diagnostics[0].atlasId, 'm1');
+      expect(r.diagnostics[1].frameIndex, 1);
+      expect(r.diagnostics[1].atlasId, 'm2');
+    });
+
+    test('8. frame outside geometry: column', () {
+      final atlas = _atlas('atlas', columns: 2, rows: 2);
+      final anim = _animation(
+        'anim',
+        frames: [
+          _frame('atlas', 2, 0),
+        ],
+        atlasId: 'atlas',
+      );
+      final r = diagnoseProjectSurfaceCatalog(
+        _catalog(atlases: [atlas], animations: [anim]),
+      );
+      final d = r.diagnostics.single;
+      expect(d.kind, SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry);
+      expect(d.animationId, 'anim');
+      expect(d.atlasId, 'atlas');
+      expect(d.frameIndex, 0);
+    });
+
+    test('9. frame outside geometry: row', () {
+      final atlas = _atlas('atlas', columns: 2, rows: 2);
+      final anim = ProjectSurfaceAnimation(
+        id: 'anim2',
+        name: 'a',
+        timeline: SurfaceAnimationTimeline(
+          frames: [_frame('atlas', 0, 2)],
+        ),
+      );
+      final r = diagnoseProjectSurfaceCatalog(
+        _catalog(atlases: [atlas], animations: [anim]),
+      );
+      expect(
+        r.diagnostics.single.kind,
+        SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry,
+      );
+    });
+
+    test('10. missing atlas only: not also outside geometry', () {
+      final anim = _animation(
+        'anim',
+        frames: [
+          _frame('missing-atlas', 99, 99),
+        ],
+        atlasId: 'missing-atlas',
+      );
+      final r = diagnoseProjectSurfaceCatalog(_catalog(animations: [anim]));
+      expect(r.count, 1);
+      expect(
+        r.diagnostics.single.kind,
+        SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
+      );
+    });
+
+    test('11. preset diagnostics then animation diagnostics', () {
+      final preset = _preset('pr', [
+        _ref(SurfaceVariantRole.isolated, 'no-such-anim'),
+      ]);
+      final anim = _animation('badA', atlasId: 'missing');
+      final r = diagnoseProjectSurfaceCatalog(
+        _catalog(presets: [preset], animations: [anim]),
+      );
+      expect(r.count, 2);
+      expect(
+        r.diagnostics[0].kind,
+        SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+      );
+      expect(
+        r.diagnostics[1].kind,
+        SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
+      );
+    });
+
+    test('12. exact atlas id: no trim', () {
+      final atlas = _atlas('  atlas  ');
+      final anim = _animation('anim', frames: [
+        _frame('atlas', 0, 0),
+      ], atlasId: 'atlas');
+      final r = diagnoseProjectSurfaceCatalog(
+        _catalog(atlases: [atlas], animations: [anim]),
+      );
+      final d = r.diagnostics.single;
+      expect(
+        d.kind,
+        SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
+      );
+      expect(d.atlasId, 'atlas');
+    });
+
+    test('13. byKind filters', () {
+      final atlas = _atlas('a', columns: 2, rows: 2);
+      final animO = _animation('o', frames: [
+        _frame('a', 0, 3),
+      ], atlasId: 'a');
+      final preset = _preset('p', [
+        _ref(SurfaceVariantRole.isolated, 'miss'),
+      ]);
+      final r = diagnoseProjectSurfaceCatalog(
+        _catalog(
+          atlases: [atlas],
+          animations: [animO],
+          presets: [preset],
+        ),
+      );
+      expect(
+        r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation).length,
+        1,
+      );
+      expect(
+        r.byKind(SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry)
+            .length,
+        1,
+      );
+    });
+
+    test('14. byKind list is unmodifiable', () {
+      final r = diagnoseProjectSurfaceCatalog(
+        _catalog(presets: [
+          _preset('p', [
+            _ref(SurfaceVariantRole.isolated, 'm'),
+          ]),
+        ]),
+      );
+      final list = r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation);
+      expect(
+        () => list.add(
+          r.diagnostics.first,
+        ),
+        throwsA(isA<UnsupportedError>()),
+      );
+    });
+
+    test('15. diagnostics list on report is unmodifiable', () {
+      final r = diagnoseProjectSurfaceCatalog(
+        _catalog(animations: [
+          _animation('o', atlasId: 'x'),
+        ]),
+      );
+      expect(
+        () => r.diagnostics.add(r.diagnostics.first),
+        throwsA(isA<UnsupportedError>()),
+      );
+    });
+
+    test('16. defensive copy: mutating source list does not change report', () {
+      final d = <SurfaceCatalogDiagnostic>[];
+      final report = SurfaceCatalogDiagnosticsReport(diagnostics: d);
+      d.add(
+        SurfaceCatalogDiagnostic(
+          severity: SurfaceCatalogDiagnosticSeverity.error,
+          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+          message: 'm',
+        ),
+      );
+      expect(report.count, 0);
+    });
+
+    test('17. hasErrors false on empty report', () {
+      final r = SurfaceCatalogDiagnosticsReport(diagnostics: const []);
+      expect(r.hasErrors, isFalse);
+    });
+
+    test('18. hasErrors true when error diagnostic', () {
+      final r = diagnoseProjectSurfaceCatalog(
+        _catalog(presets: [
+          _preset('p', [
+            _ref(SurfaceVariantRole.isolated, 'miss'),
+          ]),
+        ]),
+      );
+      expect(r.hasErrors, isTrue);
+    });
+
+    test('19. diagnostic equality: same', () {
+      final a = SurfaceCatalogDiagnostic(
+        severity: SurfaceCatalogDiagnosticSeverity.error,
+        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        message: 'm',
+        presetId: 'p',
+      );
+      final b = SurfaceCatalogDiagnostic(
+        severity: SurfaceCatalogDiagnosticSeverity.error,
+        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        message: 'm',
+        presetId: 'p',
+      );
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+    });
+
+    test('20. diagnostic equality: different kind', () {
+      final a = SurfaceCatalogDiagnostic(
+        severity: SurfaceCatalogDiagnosticSeverity.error,
+        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        message: 'm',
+      );
+      final b = SurfaceCatalogDiagnostic(
+        severity: SurfaceCatalogDiagnosticSeverity.error,
+        kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
+        message: 'm',
+      );
+      expect(a, isNot(b));
+    });
+
+    test('21. diagnostic equality: different metadata', () {
+      final a = SurfaceCatalogDiagnostic(
+        severity: SurfaceCatalogDiagnosticSeverity.error,
+        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        message: 'm',
+        presetId: 'a',
+      );
+      final b = SurfaceCatalogDiagnostic(
+        severity: SurfaceCatalogDiagnosticSeverity.error,
+        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        message: 'm',
+        presetId: 'b',
+      );
+      expect(a, isNot(b));
+    });
+
+    test('22. report equality: same order', () {
+      final d1 = SurfaceCatalogDiagnostic(
+        severity: SurfaceCatalogDiagnosticSeverity.error,
+        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        message: 'm',
+        presetId: 'p',
+      );
+      final a = SurfaceCatalogDiagnosticsReport(diagnostics: [d1]);
+      final b = SurfaceCatalogDiagnosticsReport(diagnostics: [d1]);
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+    });
+
+    test('23. report equality: order matters', () {
+      final d1 = SurfaceCatalogDiagnostic(
+        severity: SurfaceCatalogDiagnosticSeverity.error,
+        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        message: '1',
+        presetId: 'a',
+      );
+      final d2 = SurfaceCatalogDiagnostic(
+        severity: SurfaceCatalogDiagnosticSeverity.error,
+        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        message: '2',
+        presetId: 'b',
+      );
+      final x = SurfaceCatalogDiagnosticsReport(diagnostics: [d1, d2]);
+      final y = SurfaceCatalogDiagnosticsReport(diagnostics: [d2, d1]);
+      expect(x, isNot(y));
+    });
+
+    test('24. public API via map_core', () {
+      final r = diagnoseProjectSurfaceCatalog(_catalog());
+      expect(r, isA<SurfaceCatalogDiagnosticsReport>());
+      expect(
+        SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        isA<SurfaceCatalogDiagnosticKind>(),
+      );
+    });
+
+    test('25. ProjectManifest still has no Surface keys (Lot 34)', () {
+      const manifest = ProjectManifest(
+        name: 'L34',
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

## 16. Diff `/dev/null` — rapport Lot 34 (commit `023e97ea`)

```diff
commit 023e97ea37f8165fc56a9ff54c87e591f0be99cb
Author: yoahn <yoahn.linard@papernest.com>
Date:   Mon Apr 27 00:31:01 2026 +0200

    feat(map_core): surface catalog diagnostics V0 (Surface Engine lot 34)
    
    diagnoseProjectSurfaceCatalog: missing preset animation refs, missing
    animation atlas ids, frames outside atlas geometry. Immutable report,
    deterministic order. Export from map_core; tests + report.
    
    Made-with: Cursor

diff --git a/reports/surface/surface_engine_lot_34_surface_catalog_diagnostics.md b/reports/surface/surface_engine_lot_34_surface_catalog_diagnostics.md
new file mode 100644
index 00000000..54945800
--- /dev/null
+++ b/reports/surface/surface_engine_lot_34_surface_catalog_diagnostics.md
@@ -0,0 +1,197 @@
+# Surface Engine — Lot 34 : `surface_catalog_diagnostics` (V0)
+
+## 1. Résumé exécutif
+
+Introduction d’une opération pure **`diagnoseProjectSurfaceCatalog`** sur un **`ProjectSurfaceCatalog`**, retournant un **`SurfaceCatalogDiagnosticsReport`** avec des **`SurfaceCatalogDiagnostic`** typés (3 kinds d’`error` V0). Aucune persistance, aucun `ProjectManifest`, aucun autre package. Couverture : refs preset → animation manquante, frame → atlas manquant, frame hors géométrie d’atlas (si l’atlas est présent).
+
+## 2. Pourquoi ce lot vient après le Lot 33-bis
+
+Le Lot 33 a posé le catalogue mémoire ; le 33-bis a finalisé les preuves documentaires. Le 34 **utilise** ce catalogue pour des diagnostics d’assemblage auteur, sans aller vers le runtime.
+
+## 3. Fichiers consultés (audit)
+
+- `surface.dart`, `surface_catalog.dart`, `map_core.dart`, `project_manifest.dart`
+- `standard_surface_preset_builder.dart`, `legacy_surface_catalog_diagnostics.dart` (contexte, non modifié)
+- Rapports 32b, 33, 33b
+
+## 4. Fichiers créés
+
+- `packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart`
+- `packages/map_core/test/surface_catalog_diagnostics_test.dart`
+- `reports/surface/surface_engine_lot_34_surface_catalog_diagnostics.md` (ce fichier)
+
+## 5. Fichiers modifiés
+
+- `packages/map_core/lib/map_core.dart` (une ligne d’`export`)
+
+## 6. API ajoutée
+
+- `SurfaceCatalogDiagnosticSeverity` (`error`)
+- `SurfaceCatalogDiagnosticKind` (`missingPresetAnimation`, `missingAnimationAtlas`, `animationFrameOutsideAtlasGeometry`)
+- `SurfaceCatalogDiagnostic`, `SurfaceCatalogDiagnosticsReport`, `diagnoseProjectSurfaceCatalog`
+
+## 7. Sémantique de `SurfaceCatalogDiagnosticSeverity`
+
+V0 : uniquement **error** (pas de `warning`).
+
+## 8. Sémantique de `SurfaceCatalogDiagnosticKind`
+
+Trois cas exclusifs de ce lot, décrits en §12–14.
+
+## 9. Sémantique de `SurfaceCatalogDiagnostic`
+
+Valeur immuable : sévérité, kind, message lisible, champs ciblant preset / animation / atlas / rôle / index de frame selon le kind.
+
+## 10. Sémantique de `SurfaceCatalogDiagnosticsReport`
+
+Copie défensive, liste exposée **non modifiable** ; `count`, `hasDiagnostics`, `hasErrors`, `byKind` (liste filtrée non modifiable) ; `==` / `hashCode` (ordre des diagnostics compte).
+
+## 11. Sémantique de `diagnoseProjectSurfaceCatalog`
+
+Lecture seule sur le catalogue, aucune mutation. Ordre des résultats : d’abord chaque **preset** dans l’ordre, chaque **ref** ; puis chaque **animation**, chaque **frame** dans l’ordre.
+
+## 12. `missingPresetAnimation`
+
+`animationById(ref.animationId) == null` ; champs : `presetId`, `animationId`, `role`, `frameIndex` et `atlasId` nuls.
+
+## 13. `missingAnimationAtlas`
+
+`atlasById(frame.tileRef.atlasId) == null` ; `animationId`, `atlasId`, `frameIndex` remplis ; `presetId` / `role` nuls.
+
+## 14. `animationFrameOutsideAtlasGeometry`
+
+Atlas **présent** mais `!frame.tileRef.isInside(atlas.geometry)` ; message inclut colonne, ligne.
+
+## 15. Absence de double diagnostic (atlas manquant + hors grille)
+
+Si l’atlas n’existe pas, on n’applique **pas** la vérification géométrique sur cette frame (§13 seulement).
+
+## 16. Ordre des diagnostics
+
+Déterministe, pas de tri par id ni par message (§11).
+
+## 17. Pas de warnings
+
+Aucun niveau `warning` dans ce V0 (scope futur éventuel).
+
+## 18. Pas de résolution runtime
+
+Pas de chargement de texture, pas de moteur, pas d’intégration `map_runtime`.
+
+## 19. Relation avec `ProjectSurfaceCatalog`
+
+Le diagnostic **consomme** les lookups du catalogue (byId) et les structures existantes (refs, frames).
+
+## 20. Relation avec `ProjectManifest` futur
+
+Aucun lien dans ce lot ; le rapport reste en mémoire, hors schéma JSON.
+
+## 21. Ce qui a été testé
+
+25 tests : vide, scénario cohérent, 3 types d’erreurs, ordre preset/refs/frames, absence de double diagnostic, id exacts sans `trim`, `byKind`, immuabilité, copie défensive, `hasErrors`, égalité, export public, manifest minimal sans clés `surface*`.
+
+## 22. Ce que les tests prouvent
+
+Stabilité de l’ordre, invariants d’immuabilité, filtrage `byKind`, et non-régression du contrat manifeste (clés `surface*` absentes de `toJson` minimal).
+
+## 23. Ce qui n’a volontairement pas été fait
+
+JSON, Freezed, warnings, orphelins d’atlas/animation, validateur projet complet, autres packages.
+
+## 24. Pourquoi `ProjectManifest` n’a toujours pas été modifié
+
+Le lot est limité à une opération `map_core` en mémoire.
+
+## 25. Pourquoi aucun fichier generated
+
+Dart manuel, pas de `build_runner` ni `part` pour ce lot.
+
+## 26. Pourquoi pas de `SurfacePresetKind` / `surfaceKind`
+
+Hors scope diagnostic de références internes V0.
+
+## 27. Impact prochains lots
+
+Fondation pour l’UI d’erreurs auteur, extensions (warnings, inutilisés), intégration manifeste quand le contrat existera.
+
+## 28. Commandes lancées
+
+```bash
+cd packages/map_core
+/opt/homebrew/bin/dart test test/surface_catalog_diagnostics_test.dart
+```
+
+```bash
+/opt/homebrew/bin/dart analyze \
+  lib/src/operations/surface_catalog_diagnostics.dart \
+  lib/src/models/surface_catalog.dart \
+  lib/src/models/surface.dart \
+  lib/src/operations/standard_surface_preset_builder.dart \
+  test/surface_catalog_diagnostics_test.dart \
+  test/project_surface_catalog_test.dart \
+  test/standard_surface_preset_builder_test.dart \
+  test/project_surface_preset_test.dart \
+  test/project_surface_animation_test.dart \
+  test/project_surface_atlas_test.dart \
+  lib/map_core.dart
+```
+
+```bash
+/opt/homebrew/bin/dart test
+```
+
+## 29. Résultats
+
+- `dart test test/surface_catalog_diagnostics_test.dart` : **+25: All tests passed!**
+- `dart analyze` (chemins ci-dessus) : **No issues found!**
+- `dart test` (tout le package) : **+783: All tests passed!**
+
+## 30. Total exact `dart test` sur `map_core`
+
+**783** tests.
+
+## 31. Points de vigilance
+
+- Les messages sont des chaînes **anglaises** structurées (alignement avec d’autres messages techniques du monorepo) ; l’i18n est hors scope.
+- L’**ordre** des diagnostics compte pour l’égalité de `SurfaceCatalogDiagnosticsReport` : ne pas s’en servir comme clé sémantique abstraite.
+- Toute **severity** `error` dans V0 rend `hasErrors` vrai (ici une seule valeur d’énum).
+
+## 32. Autocritique
+
+- Pas d’`info` / `warning` : volontaire ; à étendre si le produit le demande.
+- Les helpers de comparaison de listes (diagnostics) restent **locales** à ce fichier (pas de partage obligatoire avec `surface_catalog.dart`).
+
+## 33. Ce que le prompt semble discutable ou incomplet
+
+- L’imposition de **lister intégralement** les gros extractions (§35–36 du prompt utilisateur) dans le rapport *et* l’exhaustivité d’un seul message de réponse : la source de vérité reste les fichiers du dépôt + `git diff` en lecture seule.
+
+## 34. Auto-review (checklist)
+
+- Lot limité à `surface_catalog_diagnostics` + test + export + rapport : **oui**
+- Aucun manifest modifié : **oui**
+- Pas de generated : **oui**
+- Pas de `SurfacePresetKind` : **oui**
+- Pas d’autres paquets : **oui**
+- Couverture des 3 diagnostics + pas de double sur atlas manquant : **oui**
+- Ordre stable : **oui**
+- Listes immuables / copie : **oui**
+- Export : **oui**
+- Test manifest : **oui**
+- 783 tests verts : **oui**
+- Pas de commande Git d’écriture : **oui** (côté exécution de ce lot)
+
+## 35. Contenu intégral des fichiers créés / modifiés
+
+- **Nouveaux** : intégralité dans le dépôt → `lib/src/operations/surface_catalog_diagnostics.dart`, `test/surface_catalog_diagnostics_test.dart`.
+- **Modifié** : `map_core.dart` (ajout d’une ligne d’`export`).
+
+## 36. Diff complet réel
+
+Utiliser (lecture seule, depuis la racine du dépôt, après ajout des fichiers non versionnés) :
+
+```text
+git diff
+git diff --stat
+```
+
+Avant `git add`, la commande `git status --short` doit montrer les fichiers new/modified du lot 34. Le **diff binaire** exact du livrable n’est formé qu’après indexation ; pour ce lot, l’**état** des sources est donné par les chemins et le contenu des fichiers §35.
```

## 16 bis. Contenu intégral — rapport Lot 34 (fichier actuel)

```markdown
# Surface Engine — Lot 34 : `surface_catalog_diagnostics` (V0)

## 1. Résumé exécutif

Introduction d’une opération pure **`diagnoseProjectSurfaceCatalog`** sur un **`ProjectSurfaceCatalog`**, retournant un **`SurfaceCatalogDiagnosticsReport`** avec des **`SurfaceCatalogDiagnostic`** typés (3 kinds d’`error` V0). Aucune persistance, aucun `ProjectManifest`, aucun autre package. Couverture : refs preset → animation manquante, frame → atlas manquant, frame hors géométrie d’atlas (si l’atlas est présent).

## 2. Pourquoi ce lot vient après le Lot 33-bis

Le Lot 33 a posé le catalogue mémoire ; le 33-bis a finalisé les preuves documentaires. Le 34 **utilise** ce catalogue pour des diagnostics d’assemblage auteur, sans aller vers le runtime.

## 3. Fichiers consultés (audit)

- `surface.dart`, `surface_catalog.dart`, `map_core.dart`, `project_manifest.dart`
- `standard_surface_preset_builder.dart`, `legacy_surface_catalog_diagnostics.dart` (contexte, non modifié)
- Rapports 32b, 33, 33b

## 4. Fichiers créés

- `packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart`
- `packages/map_core/test/surface_catalog_diagnostics_test.dart`
- `reports/surface/surface_engine_lot_34_surface_catalog_diagnostics.md` (ce fichier)

## 5. Fichiers modifiés

- `packages/map_core/lib/map_core.dart` (une ligne d’`export`)

## 6. API ajoutée

- `SurfaceCatalogDiagnosticSeverity` (`error`)
- `SurfaceCatalogDiagnosticKind` (`missingPresetAnimation`, `missingAnimationAtlas`, `animationFrameOutsideAtlasGeometry`)
- `SurfaceCatalogDiagnostic`, `SurfaceCatalogDiagnosticsReport`, `diagnoseProjectSurfaceCatalog`

## 7. Sémantique de `SurfaceCatalogDiagnosticSeverity`

V0 : uniquement **error** (pas de `warning`).

## 8. Sémantique de `SurfaceCatalogDiagnosticKind`

Trois cas exclusifs de ce lot, décrits en §12–14.

## 9. Sémantique de `SurfaceCatalogDiagnostic`

Valeur immuable : sévérité, kind, message lisible, champs ciblant preset / animation / atlas / rôle / index de frame selon le kind.

## 10. Sémantique de `SurfaceCatalogDiagnosticsReport`

Copie défensive, liste exposée **non modifiable** ; `count`, `hasDiagnostics`, `hasErrors`, `byKind` (liste filtrée non modifiable) ; `==` / `hashCode` (ordre des diagnostics compte).

## 11. Sémantique de `diagnoseProjectSurfaceCatalog`

Lecture seule sur le catalogue, aucune mutation. Ordre des résultats : d’abord chaque **preset** dans l’ordre, chaque **ref** ; puis chaque **animation**, chaque **frame** dans l’ordre.

## 12. `missingPresetAnimation`

`animationById(ref.animationId) == null` ; champs : `presetId`, `animationId`, `role`, `frameIndex` et `atlasId` nuls.

## 13. `missingAnimationAtlas`

`atlasById(frame.tileRef.atlasId) == null` ; `animationId`, `atlasId`, `frameIndex` remplis ; `presetId` / `role` nuls.

## 14. `animationFrameOutsideAtlasGeometry`

Atlas **présent** mais `!frame.tileRef.isInside(atlas.geometry)` ; message inclut colonne, ligne.

## 15. Absence de double diagnostic (atlas manquant + hors grille)

Si l’atlas n’existe pas, on n’applique **pas** la vérification géométrique sur cette frame (§13 seulement).

## 16. Ordre des diagnostics

Déterministe, pas de tri par id ni par message (§11).

## 17. Pas de warnings

Aucun niveau `warning` dans ce V0 (scope futur éventuel).

## 18. Pas de résolution runtime

Pas de chargement de texture, pas de moteur, pas d’intégration `map_runtime`.

## 19. Relation avec `ProjectSurfaceCatalog`

Le diagnostic **consomme** les lookups du catalogue (byId) et les structures existantes (refs, frames).

## 20. Relation avec `ProjectManifest` futur

Aucun lien dans ce lot ; le rapport reste en mémoire, hors schéma JSON.

## 21. Ce qui a été testé

25 tests : vide, scénario cohérent, 3 types d’erreurs, ordre preset/refs/frames, absence de double diagnostic, id exacts sans `trim`, `byKind`, immuabilité, copie défensive, `hasErrors`, égalité, export public, manifest minimal sans clés `surface*`.

## 22. Ce que les tests prouvent

Stabilité de l’ordre, invariants d’immuabilité, filtrage `byKind`, et non-régression du contrat manifeste (clés `surface*` absentes de `toJson` minimal).

## 23. Ce qui n’a volontairement pas été fait

JSON, Freezed, warnings, orphelins d’atlas/animation, validateur projet complet, autres packages.

## 24. Pourquoi `ProjectManifest` n’a toujours pas été modifié

Le lot est limité à une opération `map_core` en mémoire.

## 25. Pourquoi aucun fichier generated

Dart manuel, pas de `build_runner` ni `part` pour ce lot.

## 26. Pourquoi pas de `SurfacePresetKind` / `surfaceKind`

Hors scope diagnostic de références internes V0.

## 27. Impact prochains lots

Fondation pour l’UI d’erreurs auteur, extensions (warnings, inutilisés), intégration manifeste quand le contrat existera.

## 28. Commandes lancées

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_catalog_diagnostics_test.dart
```

```bash
/opt/homebrew/bin/dart analyze \
  lib/src/operations/surface_catalog_diagnostics.dart \
  lib/src/models/surface_catalog.dart \
  lib/src/models/surface.dart \
  lib/src/operations/standard_surface_preset_builder.dart \
  test/surface_catalog_diagnostics_test.dart \
  test/project_surface_catalog_test.dart \
  test/standard_surface_preset_builder_test.dart \
  test/project_surface_preset_test.dart \
  test/project_surface_animation_test.dart \
  test/project_surface_atlas_test.dart \
  lib/map_core.dart
```

```bash
/opt/homebrew/bin/dart test
```

## 29. Résultats

- `dart test test/surface_catalog_diagnostics_test.dart` : **+25: All tests passed!**
- `dart analyze` (chemins ci-dessus) : **No issues found!**
- `dart test` (tout le package) : **+783: All tests passed!**

## 30. Total exact `dart test` sur `map_core`

**783** tests.

## 31. Points de vigilance

- Les messages sont des chaînes **anglaises** structurées (alignement avec d’autres messages techniques du monorepo) ; l’i18n est hors scope.
- L’**ordre** des diagnostics compte pour l’égalité de `SurfaceCatalogDiagnosticsReport` : ne pas s’en servir comme clé sémantique abstraite.
- Toute **severity** `error` dans V0 rend `hasErrors` vrai (ici une seule valeur d’énum).

## 32. Autocritique

- Pas d’`info` / `warning` : volontaire ; à étendre si le produit le demande.
- Les helpers de comparaison de listes (diagnostics) restent **locales** à ce fichier (pas de partage obligatoire avec `surface_catalog.dart`).

## 33. Ce que le prompt semble discutable ou incomplet

- L’imposition de **lister intégralement** les gros extractions (§35–36 du prompt utilisateur) dans le rapport *et* l’exhaustivité d’un seul message de réponse : la source de vérité reste les fichiers du dépôt + `git diff` en lecture seule.

## 34. Auto-review (checklist)

- Lot limité à `surface_catalog_diagnostics` + test + export + rapport : **oui**
- Aucun manifest modifié : **oui**
- Pas de generated : **oui**
- Pas de `SurfacePresetKind` : **oui**
- Pas d’autres paquets : **oui**
- Couverture des 3 diagnostics + pas de double sur atlas manquant : **oui**
- Ordre stable : **oui**
- Listes immuables / copie : **oui**
- Export : **oui**
- Test manifest : **oui**
- 783 tests verts : **oui**
- Pas de commande Git d’écriture : **oui** (côté exécution de ce lot)

## 35. Contenu intégral des fichiers créés / modifiés

- **Nouveaux** : intégralité dans le dépôt → `lib/src/operations/surface_catalog_diagnostics.dart`, `test/surface_catalog_diagnostics_test.dart`.
- **Modifié** : `map_core.dart` (ajout d’une ligne d’`export`).

## 36. Diff complet réel

Utiliser (lecture seule, depuis la racine du dépôt, après ajout des fichiers non versionnés) :

```text
git diff
git diff --stat
```

Avant `git add`, la commande `git status --short` doit montrer les fichiers new/modified du lot 34. Le **diff binaire** exact du livrable n’est formé qu’après indexation ; pour ce lot, l’**état** des sources est donné par les chemins et le contenu des fichiers §35.
```

## 17. Commandes relancées

- `dart test test/surface_catalog_diagnostics_test.dart`
- `dart analyze` (11 chemins ci-dessus, depuis `packages/map_core`)
- `dart test` (suite complète)

## 18. Résultats **exacts** (capturés)

### 18.1 `dart test` ciblé

- **exit** : 0

**Sortie (\n à la place de \r) :**

```

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

### 18.2 `dart analyze`

- **exit** : 0

```
Analyzing surface_catalog_diagnostics.dart, surface_catalog.dart, surface.dart, standard_surface_preset_builder.dart, surface_catalog_diagnostics_test.dart, project_surface_catalog_test.dart, standard_surface_preset_builder_test.dart, project_surface_preset_test.dart, project_surface_animation_test.dart, project_surface_atlas_test.dart, map_core.dart...
No issues found!
```

### 18.3 `dart test` complet

- **exit** : 0
- **longueur stdout (caractères)** : 233683

**Dernières lignes (\n) :**

```
00:01 [32m+780[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 28. value inequality: different preset order[0m                                                                        
00:01 [32m+780[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content[0m                                                                             
00:01 [32m+781[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content[0m                                                                             
00:01 [32m+781[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core[0m                                                      
00:01 [32m+782[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core[0m                                                      
00:01 [32m+782[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest still has no Surface persistence keys (Lot 33)[0m                                                  
00:01 [32m+783[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest still has no Surface persistence keys (Lot 33)[0m                                                  
00:01 [32m+783[0m: All tests passed![0m                                                                                                                                                                          ```

## 19. Total `dart test` sur `map_core`

**783** tests — dernière ligne : `+783: All tests passed!`

## 20. Auto-review (34-bis)

| Vérification | Oui |
|-------------|-----|
| Evidence seule (pas de modif de code) | Oui |
| Pas d'autre modèle / manifeste | Oui |
| Pas de generated | Oui |
| Contenus + diffs in-line (§10–16) | Oui |
| Sorties reprises (§18) | Oui |
| 783 tests verts | Oui |
| Aucune commande Git d'écriture (ce lot) | Oui |
