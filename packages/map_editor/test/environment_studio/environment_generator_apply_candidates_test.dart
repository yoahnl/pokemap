import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/environment_generator_apply_use_cases.dart';
import 'package:map_editor/src/application/use_cases/environment_generator_use_cases.dart';

void main() {
  group('EnvironmentApplyResult / modèles', () {
    test(
        'EnvironmentApplyResult copie défensivement et expose des listes immuables',
        () {
      final m = _minimalMap();
      final rawApplied = <EnvironmentAppliedGeneratedPlacement>[
        const EnvironmentAppliedGeneratedPlacement(
          candidateId: 'c1',
          placedElementId: 'c1',
          elementId: 'e1',
          layerId: 'tiles',
          pos: GridPos(x: 0, y: 0),
        ),
      ];
      final rawIssues = <EnvironmentApplyIssue>[
        const EnvironmentApplyIssue(
          severity: EnvironmentApplyIssueSeverity.error,
          kind: EnvironmentApplyIssueKind.emptyCandidates,
          message: 'x',
        ),
      ];
      final r = EnvironmentApplyResult(
        map: m,
        appliedPlacements: rawApplied,
        issues: rawIssues,
      );
      rawApplied.clear();
      rawIssues.clear();
      expect(r.appliedPlacementCount, 1);
      expect(r.errorCount, 1);
      expect(() => r.appliedPlacements.clear(), throwsUnsupportedError);
      expect(() => r.issues.clear(), throwsUnsupportedError);
      expect(
          r.issuesForKind(EnvironmentApplyIssueKind.emptyCandidates).length, 1);
    });

    test(
        'EnvironmentAppliedGeneratedPlacement et EnvironmentApplyIssue égalité',
        () {
      const a = EnvironmentAppliedGeneratedPlacement(
        candidateId: 'c',
        placedElementId: 'p',
        elementId: 'e',
        layerId: 'l',
        pos: GridPos(x: 1, y: 2),
      );
      const b = EnvironmentAppliedGeneratedPlacement(
        candidateId: 'c',
        placedElementId: 'p',
        elementId: 'e',
        layerId: 'l',
        pos: GridPos(x: 1, y: 2),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);

      const i1 = EnvironmentApplyIssue(
        severity: EnvironmentApplyIssueSeverity.error,
        kind: EnvironmentApplyIssueKind.areaNotFound,
        message: 'm',
        candidateId: 'c',
      );
      const i2 = EnvironmentApplyIssue(
        severity: EnvironmentApplyIssueSeverity.error,
        kind: EnvironmentApplyIssueKind.areaNotFound,
        message: 'm',
        candidateId: 'c',
      );
      expect(i1, i2);
    });
  });

  group('ApplyEnvironmentGeneratedPlacementsUseCase', () {
    test('chemin heureux : placements, generatedPlacementIds, layers préservés',
        () {
      final ctx = _happyContext();
      final c1 = _cand(
        id: 'env_gen_area1_0_0_e1',
        env: 'env',
        area: 'area1',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 0,
        y: 0,
      );
      final c2 = _cand(
        id: 'env_gen_area1_1_0_e1',
        env: 'env',
        area: 'area1',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 1,
        y: 0,
      );
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [c1, c2],
      );
      expect(r.hasErrors, isFalse);
      expect(r.appliedPlacementCount, 2);
      final env = r.map.layers.first as EnvironmentLayer;
      expect(env.content.targetTileLayerId, 'tiles');
      expect(env.content.areas.single.generatedPlacementIds,
          ['env_gen_area1_0_0_e1', 'env_gen_area1_1_0_e1']);
      final tile = r.map.layers[1] as TileLayer;
      expect(tile.tiles, ctx.tilesSnapshot);
      expect(r.map.placedElements.length, 2);
      expect(r.map.placedElements.map((e) => e.id).toList(),
          ['env_gen_area1_0_0_e1', 'env_gen_area1_1_0_e1']);
    });

    test('ordre des candidats = ordre placedElements et generatedPlacementIds',
        () {
      final ctx = _happyContext(mapW: 3, mapH: 1);
      final a = _cand(
        id: 'A',
        env: 'env',
        area: 'area1',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 0,
        y: 0,
      );
      final b = _cand(
        id: 'B',
        env: 'env',
        area: 'area1',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 1,
        y: 0,
      );
      final c = _cand(
        id: 'C',
        env: 'env',
        area: 'area1',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 2,
        y: 0,
      );
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [a, b, c],
      );
      expect(r.map.placedElements.map((e) => e.id).toList(), ['A', 'B', 'C']);
      final area =
          (r.map.layers.first as EnvironmentLayer).content.areas.single;
      expect(area.generatedPlacementIds, ['A', 'B', 'C']);
    });

    test('collisionMode forceEnabled / forceDisabled / useElementDefault', () {
      final modes = [
        EnvironmentCollisionMode.forceEnabled,
        EnvironmentCollisionMode.forceDisabled,
        EnvironmentCollisionMode.useElementDefault,
      ];
      final expected = [true, false, true];
      for (var i = 0; i < modes.length; i++) {
        final ctxI = _happyContext(mapW: 3, mapH: 1, areaIdSuffix: '_$i');
        final cand = _cand(
          id: 'id_$i',
          env: 'env',
          area: 'area1_$i',
          preset: 'preset1',
          target: 'tiles',
          el: 'e1',
          x: i,
          y: 0,
          mode: modes[i],
        );
        final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
        final r = uc.execute(
          ctxI.map,
          manifest: ctxI.manifest,
          environmentLayerId: 'env',
          areaId: 'area1_$i',
          candidates: [cand],
        );
        expect(r.hasErrors, isFalse, reason: 'mode $i');
        expect(r.map.placedElements.single.applyCollision, expected[i]);
      }
    });

    test('tags candidat ne sont pas copiés vers MapPlacedElement.properties',
        () {
      final ctx = _happyContext();
      final cand = EnvironmentGeneratedPlacementCandidate(
        id: 't1',
        environmentLayerId: 'env',
        areaId: 'area1',
        presetId: 'preset1',
        targetLayerId: 'tiles',
        elementId: 'e1',
        pos: const GridPos(x: 0, y: 0),
        collisionMode: EnvironmentCollisionMode.useElementDefault,
        tags: {'canopy'},
      );
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [cand],
      );
      expect(r.map.placedElements.single.properties, isEmpty);
    });

    test('erreurs layer / target / area', () {
      final ctx = _happyContext();
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final cand = _singleCandidate(ctx);
      final r1 = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'missing',
        areaId: 'area1',
        candidates: [cand],
      );
      expect(
        r1.issuesForKind(EnvironmentApplyIssueKind.environmentLayerNotFound),
        isNotEmpty,
      );
      expect(identical(r1.map, ctx.map), isTrue);

      const tileMap = MapData(
        id: 'm',
        name: 'M',
        size: GridSize(width: 2, height: 1),
        layers: [
          MapLayer.tile(id: 'env', name: 'E', tiles: [0, 0]),
          TileLayer(id: 'tiles', name: 'T', tiles: [0, 0]),
        ],
      );
      final r2 = uc.execute(
        tileMap,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [cand],
      );
      expect(
        r2.issuesForKind(EnvironmentApplyIssueKind.layerIsNotEnvironmentLayer),
        isNotEmpty,
      );

      final noTarget = _mapMissingTarget();
      final r3 = uc.execute(
        noTarget.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [cand],
      );
      expect(
        r3.issuesForKind(EnvironmentApplyIssueKind.targetTileLayerMissing),
        isNotEmpty,
      );

      final badTarget = _mapTargetObjectLayer();
      final r4 = uc.execute(
        badTarget.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [cand],
      );
      expect(
        r4.issuesForKind(EnvironmentApplyIssueKind.targetTileLayerInvalid),
        isNotEmpty,
      );

      final r5 = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'ghost',
        candidates: [cand],
      );
      expect(
          r5.issuesForKind(EnvironmentApplyIssueKind.areaNotFound), isNotEmpty);
    });

    test('emptyCandidates et areaAlreadyHasGeneratedPlacements', () {
      final ctx = _happyContext();
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final r1 = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: const [],
      );
      expect(r1.issuesForKind(EnvironmentApplyIssueKind.emptyCandidates),
          isNotEmpty);

      final withIds = _happyContext(
        preGeneratedIds: const ['old'],
      );
      final r2 = uc.execute(
        withIds.map,
        manifest: withIds.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [_singleCandidate(withIds)],
      );
      expect(
        r2.issuesForKind(
            EnvironmentApplyIssueKind.areaAlreadyHasGeneratedPlacements),
        isNotEmpty,
      );
    });

    test(
        'erreurs candidates : wrong layer, area, preset, target, element, bounds',
        () {
      final ctx = _happyContext();
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final base = _singleCandidate(ctx);

      EnvironmentGeneratedPlacementCandidate copy({
        String? env,
        String? area,
        String? preset,
        String? target,
        String? el,
        int? x,
        int? y,
      }) {
        return EnvironmentGeneratedPlacementCandidate(
          id: base.id,
          environmentLayerId: env ?? base.environmentLayerId,
          areaId: area ?? base.areaId,
          presetId: preset ?? base.presetId,
          targetLayerId: target ?? base.targetLayerId,
          elementId: el ?? base.elementId,
          pos: GridPos(x: x ?? base.pos.x, y: y ?? base.pos.y),
          collisionMode: base.collisionMode,
          tags: base.tags,
        );
      }

      expect(
        uc.execute(
          ctx.map,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [copy(env: 'other')],
        ).issuesForKind(
            EnvironmentApplyIssueKind.candidateWrongEnvironmentLayer),
        isNotEmpty,
      );
      expect(
        uc.execute(
          ctx.map,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [copy(area: 'other')],
        ).issuesForKind(EnvironmentApplyIssueKind.candidateWrongArea),
        isNotEmpty,
      );
      expect(
        uc.execute(
          ctx.map,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [copy(preset: 'wrong')],
        ).issuesForKind(EnvironmentApplyIssueKind.candidateWrongPreset),
        isNotEmpty,
      );
      expect(
        uc.execute(
          ctx.map,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [copy(target: 'wrong')],
        ).issuesForKind(EnvironmentApplyIssueKind.candidateWrongTargetLayer),
        isNotEmpty,
      );
      expect(
        uc.execute(
          ctx.map,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [copy(el: 'missing')],
        ).issuesForKind(EnvironmentApplyIssueKind.candidateElementMissing),
        isNotEmpty,
      );
      expect(
        uc.execute(
          ctx.map,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [copy(x: 99)],
        ).issuesForKind(EnvironmentApplyIssueKind.candidateOutOfBounds),
        isNotEmpty,
      );
    });

    test(
        'candidateDuplicateId, placedElementIdConflict, candidatePositionDuplicate',
        () {
      final ctx = _happyContext();
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final a = _singleCandidate(ctx);
      final b = EnvironmentGeneratedPlacementCandidate(
        id: a.id,
        environmentLayerId: a.environmentLayerId,
        areaId: a.areaId,
        presetId: a.presetId,
        targetLayerId: a.targetLayerId,
        elementId: a.elementId,
        pos: const GridPos(x: 1, y: 0),
        collisionMode: a.collisionMode,
        tags: a.tags,
      );
      expect(
        uc.execute(
          ctx.map,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [a, b],
        ).issuesForKind(EnvironmentApplyIssueKind.candidateDuplicateId),
        isNotEmpty,
      );

      const placed = MapPlacedElement(
        id: 'env_gen_area1_0_0_e1',
        layerId: 'tiles',
        elementId: 'e1',
        pos: GridPos(x: 0, y: 0),
      );
      final mapWith = ctx.map.copyWith(placedElements: [placed]);
      expect(
        uc.execute(
          mapWith,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [_singleCandidate(ctx)],
        ).issuesForKind(EnvironmentApplyIssueKind.placedElementIdConflict),
        isNotEmpty,
      );

      final c1 = _cand(
        id: 'p1',
        env: 'env',
        area: 'area1',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 0,
        y: 0,
      );
      final c2 = _cand(
        id: 'p2',
        env: 'env',
        area: 'area1',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 0,
        y: 0,
      );
      expect(
        uc.execute(
          ctx.map,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [c1, c2],
        ).issuesForKind(EnvironmentApplyIssueKind.candidatePositionDuplicate),
        isNotEmpty,
      );
    });

    test('transactionnalité : deuxième candidate invalide → aucune mutation',
        () {
      final ctx = _happyContext(mapW: 3, mapH: 1);
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final good = _cand(
        id: 'g1',
        env: 'env',
        area: 'area1',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 0,
        y: 0,
      );
      final bad = _cand(
        id: 'g2',
        env: 'env',
        area: 'wrong_area',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 1,
        y: 0,
      );
      final before = ctx.map;
      final r = uc.execute(
        before,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [good, bad],
      );
      expect(r.hasErrors, isTrue);
      expect(identical(r.map, before), isTrue);
      expect(r.map.placedElements, isEmpty);
      final area =
          (r.map.layers.first as EnvironmentLayer).content.areas.single;
      expect(area.generatedPlacementIds, isEmpty);
    });

    test('ProjectManifest et TileLayer.tiles inchangés après succès', () {
      final ctx = _happyContext();
      final manifestBefore = ctx.manifest;
      final tilesBefore = (ctx.map.layers[1] as TileLayer).tiles;
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [_singleCandidate(ctx)],
      );
      expect(r.hasErrors, isFalse);
      expect(identical(r.map, ctx.map), isFalse);
      expect(
          manifestBefore.environmentPresets, ctx.manifest.environmentPresets);
      final tilesAfter = (r.map.layers[1] as TileLayer).tiles;
      expect(tilesAfter, tilesBefore);
    });

    test('intégration Lot 23 → Lot 24', () {
      final ctx = _happyContext(mapW: 2, mapH: 2);
      final gen = GenerateEnvironmentAreaPlacementsUseCase();
      final genResult = gen.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(genResult.hasErrors, isFalse);
      expect(genResult.placementCount, greaterThan(0));
      final apply = ApplyEnvironmentGeneratedPlacementsUseCase();
      final applyResult = apply.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: genResult.placements,
      );
      expect(applyResult.hasErrors, isFalse);
      expect(
        applyResult.appliedPlacementCount,
        genResult.placementCount,
      );
      final ids = genResult.placements.map((c) => c.id).toList();
      final area = (applyResult.map.layers.first as EnvironmentLayer)
          .content
          .areas
          .single;
      expect(area.generatedPlacementIds, ids);
    });

    test('candidateTargetLayerTilesetMismatch : layer vs element incompatible',
        () {
      final ctx = _happyContext(layerTilesetId: 'tsA');
      final manifestBad = ProjectManifest(
        name: 'p',
        maps: const [],
        tilesets: const [],
        elements: [
          const ProjectElementEntry(
            id: 'e1',
            name: 'E',
            tilesetId: 'tsB',
            categoryId: 'c',
            frames: [
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
            ],
          ),
        ],
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        environmentPresets: [
          EnvironmentPreset(
            id: 'preset1',
            name: 'P',
            templateId: 't',
            palette: [
              EnvironmentPaletteItem(elementId: 'e1', weight: 1),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
        ],
      );
      final cand = _singleCandidate(ctx);
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: manifestBad,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [cand],
      );
      expect(
        r.issuesForKind(
          EnvironmentApplyIssueKind.candidateTargetLayerTilesetMismatch,
        ),
        isNotEmpty,
      );
      expect(identical(r.map, ctx.map), isTrue);
    });
  });
}

EnvironmentGeneratedPlacementCandidate _singleCandidate(_HappyContext ctx) {
  return _cand(
    id: 'env_gen_area1_0_0_e1',
    env: 'env',
    area: 'area1',
    preset: 'preset1',
    target: 'tiles',
    el: 'e1',
    x: 0,
    y: 0,
  );
}

EnvironmentGeneratedPlacementCandidate _cand({
  required String id,
  required String env,
  required String area,
  required String preset,
  required String target,
  required String el,
  required int x,
  required int y,
  EnvironmentCollisionMode mode = EnvironmentCollisionMode.useElementDefault,
}) {
  return EnvironmentGeneratedPlacementCandidate(
    id: id,
    environmentLayerId: env,
    areaId: area,
    presetId: preset,
    targetLayerId: target,
    elementId: el,
    pos: GridPos(x: x, y: y),
    collisionMode: mode,
    tags: const {},
  );
}

class _HappyContext {
  _HappyContext({
    required this.map,
    required this.manifest,
    required this.tilesSnapshot,
  });

  final MapData map;
  final ProjectManifest manifest;
  final List<int> tilesSnapshot;
}

_HappyContext _happyContext({
  int mapW = 2,
  int mapH = 2,
  List<String>? preGeneratedIds,
  String areaIdSuffix = '',
  String? layerTilesetId,
}) {
  final n = mapW * mapH;
  final cells = List<bool>.filled(n, true);
  final mask = EnvironmentAreaMask(width: mapW, height: mapH, cells: cells);
  final areaId = 'area1$areaIdSuffix';
  final area = EnvironmentArea(
    id: areaId,
    name: 'Z',
    presetId: 'preset1',
    mask: mask,
    seed: 1,
    generatedPlacementIds: preGeneratedIds,
  );
  final env = MapLayer.environment(
    id: 'env',
    name: 'E',
    content: EnvironmentLayerContent(
      targetTileLayerId: 'tiles',
      areas: [area],
    ),
  );
  final tiles = List<int>.filled(n, 7);
  final tile = MapLayer.tile(
    id: 'tiles',
    name: 'T',
    tilesetId: layerTilesetId,
    tiles: tiles,
  );
  final map = MapData(
    id: 'map1',
    name: 'Map',
    size: GridSize(width: mapW, height: mapH),
    tilesetId: layerTilesetId ?? 'tsA',
    layers: [env, tile],
  );
  final manifest = ProjectManifest(
    name: 'proj',
    maps: const [],
    tilesets: const [],
    elements: [
      ProjectElementEntry(
        id: 'e1',
        name: 'El',
        tilesetId: layerTilesetId ?? 'tsA',
        categoryId: 'cat',
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    environmentPresets: [
      EnvironmentPreset(
        id: 'preset1',
        name: 'P',
        templateId: 't',
        palette: [
          EnvironmentPaletteItem(elementId: 'e1', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams(
          density: 1,
          edgeDensity: 1,
          variation: 0,
          minSpacingCells: 0,
        ),
        sortOrder: 0,
      ),
    ],
  );
  return _HappyContext(map: map, manifest: manifest, tilesSnapshot: tiles);
}

MapData _minimalMap() {
  return const MapData(
    id: 'm',
    name: 'M',
    size: GridSize(width: 1, height: 1),
    layers: [
      TileLayer(id: 't', name: 'T', tiles: [0]),
    ],
  );
}

({MapData map}) _mapMissingTarget() {
  final mask = EnvironmentAreaMask(
    width: 2,
    height: 1,
    cells: const [true, true],
  );
  final area = EnvironmentArea(
    id: 'area1',
    name: 'Z',
    presetId: 'preset1',
    mask: mask,
    seed: 0,
  );
  final env = MapLayer.environment(
    id: 'env',
    name: 'E',
    content: EnvironmentLayerContent(
      targetTileLayerId: null,
      areas: [area],
    ),
  );
  final map = MapData(
    id: 'm',
    name: 'M',
    size: const GridSize(width: 2, height: 1),
    layers: [
      env,
      const TileLayer(id: 'tiles', name: 'T', tiles: [0, 0]),
    ],
  );
  return (map: map);
}

({MapData map}) _mapTargetObjectLayer() {
  final mask = EnvironmentAreaMask(
    width: 2,
    height: 1,
    cells: const [true, true],
  );
  final area = EnvironmentArea(
    id: 'area1',
    name: 'Z',
    presetId: 'preset1',
    mask: mask,
    seed: 0,
  );
  final env = MapLayer.environment(
    id: 'env',
    name: 'E',
    content: EnvironmentLayerContent(
      targetTileLayerId: 'obj',
      areas: [area],
    ),
  );
  final map = MapData(
    id: 'm',
    name: 'M',
    size: const GridSize(width: 2, height: 1),
    layers: [
      env,
      const MapLayer.object(id: 'obj', name: 'O'),
    ],
  );
  return (map: map);
}
