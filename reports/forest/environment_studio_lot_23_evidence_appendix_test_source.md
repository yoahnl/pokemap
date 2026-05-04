# Annexe — `packages/map_editor/test/environment_studio/environment_generator_deterministic_core_test.dart` (contenu intégral)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/environment_generator_use_cases.dart';

void main() {
  group('EnvironmentGenerationResult / DTO immuabilité', () {
    test(
        'EnvironmentGeneratedPlacementCandidate copie les tags et expose un Set immuable',
        () {
      final mutable = <String>{'a', 'b'};
      final c = EnvironmentGeneratedPlacementCandidate(
        id: 'i',
        environmentLayerId: 'e',
        areaId: 'a',
        presetId: 'p',
        targetLayerId: 't',
        elementId: 'el',
        pos: const GridPos(x: 0, y: 0),
        collisionMode: EnvironmentCollisionMode.useElementDefault,
        tags: mutable,
      );
      mutable.add('c');
      expect(c.tags, containsAll(<String>['a', 'b']));
      expect(c.tags.contains('c'), isFalse);
      expect(() => c.tags.add('x'), throwsUnsupportedError);
    });

    test(
        'EnvironmentGenerationResult copie placements et issues ; issuesForKind',
        () {
      final p = EnvironmentGeneratedPlacementCandidate(
        id: '1',
        environmentLayerId: 'e',
        areaId: 'a',
        presetId: 'p',
        targetLayerId: 't',
        elementId: 'el',
        pos: const GridPos(x: 0, y: 0),
        collisionMode: EnvironmentCollisionMode.useElementDefault,
        tags: const {},
      );
      final i1 = EnvironmentGenerationIssue(
        severity: EnvironmentGenerationIssueSeverity.warning,
        kind: EnvironmentGenerationIssueKind.emptyAreaMask,
        message: 'm1',
      );
      final i2 = EnvironmentGenerationIssue(
        severity: EnvironmentGenerationIssueSeverity.error,
        kind: EnvironmentGenerationIssueKind.presetMissing,
        message: 'm2',
      );
      final rawPlacements = <EnvironmentGeneratedPlacementCandidate>[p];
      final rawIssues = <EnvironmentGenerationIssue>[i1, i2];
      final r = EnvironmentGenerationResult(
        placements: rawPlacements,
        issues: rawIssues,
      );
      rawPlacements.clear();
      rawIssues.clear();
      expect(r.placementCount, 1);
      expect(r.errorCount, 1);
      expect(r.warningCount, 1);
      expect(r.hasErrors, isTrue);
      expect(r.hasWarnings, isTrue);
      expect(() => r.placements.clear(), throwsUnsupportedError);
      expect(() => r.issues.clear(), throwsUnsupportedError);
      expect(
        r.issuesForKind(EnvironmentGenerationIssueKind.emptyAreaMask).length,
        1,
      );
    });
  });

  group('GenerateEnvironmentAreaPlacementsUseCase', () {
    test('déterminisme : deux exécutions identiques', () {
      final ctx = _fullScenario(
        mapW: 3,
        mapH: 3,
        activeAll: true,
        params: _params(density: 0.5, edgeDensity: 0.5, variation: 0.25),
      );
      final uc = GenerateEnvironmentAreaPlacementsUseCase();
      final a = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      final b = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(a, b);
      expect(a.placements.map((e) => e.id).toList(),
          b.placements.map((e) => e.id).toList());
    });

    test(
        'mask : seulement deux cellules actives reçoivent des placements possibles',
        () {
      final cells = List<bool>.filled(9, false);
      cells[0] = true;
      cells[8] = true;
      final ctx = _fullScenario(
        mapW: 3,
        mapH: 3,
        cells: cells,
        params: _params(
          density: 1,
          edgeDensity: 1,
          variation: 0,
          minSpacing: 0,
        ),
      );
      final uc = GenerateEnvironmentAreaPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(r.hasErrors, isFalse);
      final xs = r.placements.map((e) => e.pos).toSet();
      expect(xs.length, r.placements.length);
      for (final p in r.placements) {
        expect(
          p.pos == const GridPos(x: 0, y: 0) ||
              p.pos == const GridPos(x: 2, y: 2),
          isTrue,
          reason: 'hors masque : ${p.pos}',
        );
      }
    });

    test(
        'density 0 et edgeDensity 0 : aucun placement, warning noPlacementCandidates',
        () {
      final ctx = _fullScenario(
        mapW: 2,
        mapH: 2,
        activeAll: true,
        params: _params(
          density: 0,
          edgeDensity: 0,
          variation: 0,
          minSpacing: 0,
        ),
      );
      final uc = GenerateEnvironmentAreaPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(r.hasErrors, isFalse);
      expect(r.placements, isEmpty);
      expect(
        r.issuesForKind(EnvironmentGenerationIssueKind.noPlacementCandidates),
        isNotEmpty,
      );
    });

    test(
        'density 1, edgeDensity 1, variation 0, spacing 0 : toutes les cellules actives',
        () {
      final ctx = _fullScenario(
        mapW: 2,
        mapH: 2,
        activeAll: true,
        params: _params(
          density: 1,
          edgeDensity: 1,
          variation: 0,
          minSpacing: 0,
        ),
      );
      final uc = GenerateEnvironmentAreaPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(r.hasErrors, isFalse);
      expect(r.placementCount, 4);
    });

    test('edgeDensity seul sur bloc 3x3 : le centre ne reçoit pas de placement',
        () {
      final ctx = _fullScenario(
        mapW: 3,
        mapH: 3,
        activeAll: true,
        params: _params(
          density: 0,
          edgeDensity: 1,
          variation: 0,
          minSpacing: 0,
        ),
      );
      final uc = GenerateEnvironmentAreaPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(r.hasErrors, isFalse);
      expect(
        r.placements.any((e) => e.pos == const GridPos(x: 1, y: 1)),
        isFalse,
      );
      expect(r.placementCount, 8);
    });

    test('variation non nulle : stable entre deux appels', () {
      final ctx = _fullScenario(
        mapW: 4,
        mapH: 4,
        activeAll: true,
        params: _params(
          density: 0.7,
          edgeDensity: 0.7,
          variation: 0.8,
          minSpacing: 0,
        ),
      );
      final uc = GenerateEnvironmentAreaPlacementsUseCase();
      final r1 = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      final r2 = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(r1, r2);
    });

    test('minSpacingCells 1 sur 3x3 : aucune paire Chebyshev <= 1', () {
      final ctx = _fullScenario(
        mapW: 3,
        mapH: 3,
        activeAll: true,
        params: _params(
          density: 1,
          edgeDensity: 1,
          variation: 0,
          minSpacing: 1,
        ),
      );
      final uc = GenerateEnvironmentAreaPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(r.hasErrors, isFalse);
      expect(r.placementCount < 9, isTrue);
      final pos = r.placements.map((e) => e.pos).toList();
      for (var i = 0; i < pos.length; i++) {
        for (var j = i + 1; j < pos.length; j++) {
          final dx = (pos[i].x - pos[j].x).abs();
          final dy = (pos[i].y - pos[j].y).abs();
          expect(
            dx > 1 || dy > 1,
            isTrue,
            reason: 'trop proche : ${pos[i]} et ${pos[j]}',
          );
        }
      }
    });

    test('palette à un seul item : tous les elementId identiques', () {
      final ctx = _fullScenario(
        mapW: 2,
        mapH: 2,
        activeAll: true,
        elementId: 'tree',
        params:
            _params(density: 1, edgeDensity: 1, variation: 0, minSpacing: 0),
      );
      final uc = GenerateEnvironmentAreaPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(r.placements.every((e) => e.elementId == 'tree'), isTrue);
    });

    test('palette deux items : résultat déterministe et pondération (snapshot)',
        () {
      final palette = [
        EnvironmentPaletteItem(elementId: 'A', weight: 7),
        EnvironmentPaletteItem(elementId: 'B', weight: 3),
      ];
      final preset = EnvironmentPreset(
        id: 'preset1',
        name: 'P',
        templateId: 't',
        palette: palette,
        defaultParams: _params(
          density: 1,
          edgeDensity: 1,
          variation: 0,
          minSpacing: 0,
        ),
        sortOrder: 0,
      );
      final manifest = _manifest(
        presets: [preset],
        elements: [
          _element(id: 'A'),
          _element(id: 'B'),
        ],
      );
      final mask = EnvironmentAreaMask(
        width: 2,
        height: 1,
        cells: const <bool>[true, true],
      );
      final area = EnvironmentArea(
        id: 'area1',
        name: 'Z',
        presetId: 'preset1',
        mask: mask,
        seed: 4242,
      );
      final map = _mapWithEnv(
        width: 2,
        height: 1,
        area: area,
        targetTileLayerId: 'tiles',
      );
      final uc = GenerateEnvironmentAreaPlacementsUseCase();
      final r = uc.execute(
        map,
        manifest: manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(r.hasErrors, isFalse);
      expect(r.placementCount, 2);
      expect(r.placements.map((e) => e.elementId).toList(), ['B', 'B']);
    });

    test(
        'erreurs : environmentLayerNotFound, layerIsNotEnvironmentLayer, cible',
        () {
      final ctx = _fullScenario(mapW: 1, mapH: 1, activeAll: true);
      final uc = GenerateEnvironmentAreaPlacementsUseCase();
      final r1 = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'nope',
        areaId: 'area1',
      );
      expect(
        r1.issuesForKind(
            EnvironmentGenerationIssueKind.environmentLayerNotFound),
        isNotEmpty,
      );
      expect(r1.placements, isEmpty);

      final tileOnly = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 1, height: 1),
        layers: [
          TileLayer(id: 'env', name: 'T', tiles: const [0]),
        ],
      );
      final r2 = uc.execute(
        tileOnly,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(
        r2.issuesForKind(
            EnvironmentGenerationIssueKind.layerIsNotEnvironmentLayer),
        isNotEmpty,
      );

      final tile = TileLayer(id: 't', name: 'T', tiles: const [0]);
      final area = EnvironmentArea(
        id: 'a',
        name: 'Z',
        presetId: 'preset1',
        mask: EnvironmentAreaMask(
          width: 1,
          height: 1,
          cells: const [true],
        ),
        seed: 0,
      );
      final envWithArea = MapLayer.environment(
        id: 'env2',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: null,
          areas: [area],
        ),
      );
      final map3 = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 1, height: 1),
        layers: [envWithArea, tile],
      );
      final r3 = uc.execute(
        map3,
        manifest: ctx.manifest,
        environmentLayerId: 'env2',
        areaId: 'a',
      );
      expect(
        r3.issuesForKind(EnvironmentGenerationIssueKind.targetTileLayerMissing),
        isNotEmpty,
      );

      final obj = MapLayer.object(id: 'obj', name: 'O');
      final envBadTarget = MapLayer.environment(
        id: 'env3',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'obj',
          areas: [
            EnvironmentArea(
              id: 'a',
              name: 'Z',
              presetId: 'preset1',
              mask: EnvironmentAreaMask(
                width: 1,
                height: 1,
                cells: const [true],
              ),
              seed: 0,
            ),
          ],
        ),
      );
      final map4 = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 1, height: 1),
        layers: [envBadTarget, obj],
      );
      final r4 = uc.execute(
        map4,
        manifest: ctx.manifest,
        environmentLayerId: 'env3',
        areaId: 'a',
      );
      expect(
        r4.issuesForKind(EnvironmentGenerationIssueKind.targetTileLayerInvalid),
        isNotEmpty,
      );
    });

    test('erreurs : areaNotFound, presetMissing, paletteElementMissing', () {
      final ctx = _fullScenario(mapW: 1, mapH: 1, activeAll: true);
      final uc = GenerateEnvironmentAreaPlacementsUseCase();
      final r1 = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'unknown',
      );
      expect(r1.issuesForKind(EnvironmentGenerationIssueKind.areaNotFound),
          isNotEmpty);

      final areaWrongPreset = EnvironmentArea(
        id: 'area1',
        name: 'Z',
        presetId: 'ghost',
        mask: EnvironmentAreaMask(
          width: 1,
          height: 1,
          cells: const [true],
        ),
        seed: 0,
      );
      final map2 = _mapWithEnv(
        width: 1,
        height: 1,
        area: areaWrongPreset,
        targetTileLayerId: 'tiles',
      );
      final r2 = uc.execute(
        map2,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(r2.issuesForKind(EnvironmentGenerationIssueKind.presetMissing),
          isNotEmpty);

      final badPalettePreset = EnvironmentPreset(
        id: 'preset1',
        name: 'P',
        templateId: 't',
        palette: [
          EnvironmentPaletteItem(elementId: 'missing', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 0,
      );
      final manifest2 = _manifest(
        presets: [badPalettePreset],
        elements: [_element(id: 'other')],
      );
      final r3 = uc.execute(
        ctx.map,
        manifest: manifest2,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(
        r3.issuesForKind(EnvironmentGenerationIssueKind.paletteElementMissing),
        isNotEmpty,
      );
    });

    test('erreur : invalidMaskSize', () {
      final ctx = _fullScenario(
        mapW: 3,
        mapH: 3,
        maskW: 2,
        maskH: 2,
        activeAll: true,
      );
      final uc = GenerateEnvironmentAreaPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(r.issuesForKind(EnvironmentGenerationIssueKind.invalidMaskSize),
          isNotEmpty);
      expect(r.placements, isEmpty);
    });

    test('warnings : mask vide et aucune erreur', () {
      final cells = List<bool>.filled(4, false);
      final ctx = _fullScenario(
        mapW: 2,
        mapH: 2,
        cells: cells,
        activeAll: false,
      );
      final uc = GenerateEnvironmentAreaPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(r.hasErrors, isFalse);
      expect(r.placements, isEmpty);
      expect(r.issuesForKind(EnvironmentGenerationIssueKind.emptyAreaMask),
          isNotEmpty);
    });

    test('paramsOverride remplace defaultParams du preset', () {
      final preset = EnvironmentPreset(
        id: 'preset1',
        name: 'P',
        templateId: 't',
        palette: [
          EnvironmentPaletteItem(elementId: 'e1', weight: 1),
        ],
        defaultParams: _params(
          density: 0,
          edgeDensity: 0,
          variation: 0,
          minSpacing: 0,
        ),
        sortOrder: 0,
      );
      final manifest = _manifest(
        presets: [preset],
        elements: [_element(id: 'e1')],
      );
      final mask = EnvironmentAreaMask(
        width: 1,
        height: 1,
        cells: const [true],
      );
      final area = EnvironmentArea(
        id: 'area1',
        name: 'Z',
        presetId: 'preset1',
        mask: mask,
        seed: 1,
        paramsOverride: _params(
          density: 1,
          edgeDensity: 1,
          variation: 0,
          minSpacing: 0,
        ),
      );
      final map = _mapWithEnv(
        width: 1,
        height: 1,
        area: area,
        targetTileLayerId: 'tiles',
      );
      final uc = GenerateEnvironmentAreaPlacementsUseCase();
      final r = uc.execute(
        map,
        manifest: manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(r.hasErrors, isFalse);
      expect(r.placementCount, 1);
    });

    test('aucune mutation : MapData, manifest, areas, tiles, placedElements',
        () {
      final ctx = _fullScenario(mapW: 2, mapH: 2, activeAll: true);
      final mapBefore = ctx.map;
      final manifestBefore = ctx.manifest;
      final envLayer = mapBefore.layers.first as EnvironmentLayer;
      final areaBefore = envLayer.content.areas.single;
      final tileLayer = mapBefore.layers[1] as TileLayer;
      final tilesBefore = List<int>.from(tileLayer.tiles);
      final genIdsBefore = List<String>.from(areaBefore.generatedPlacementIds);
      final placedBefore =
          List<MapPlacedElement>.from(mapBefore.placedElements);
      final presetsBefore =
          List<EnvironmentPreset>.from(manifestBefore.environmentPresets);

      final uc = GenerateEnvironmentAreaPlacementsUseCase();
      uc.execute(
        mapBefore,
        manifest: manifestBefore,
        environmentLayerId: 'env',
        areaId: 'area1',
      );

      expect(mapBefore, ctx.map);
      expect(manifestBefore.environmentPresets, presetsBefore);
      final envAfter = mapBefore.layers.first as EnvironmentLayer;
      final areaAfter = envAfter.content.areas.single;
      expect(areaAfter.generatedPlacementIds, genIdsBefore);
      final tileAfter = mapBefore.layers[1] as TileLayer;
      expect(tileAfter.tiles, tilesBefore);
      expect(mapBefore.placedElements, placedBefore);
    });
  });
}

EnvironmentGenerationParams _params({
  double density = 1,
  double edgeDensity = 1,
  double variation = 0,
  int minSpacing = 0,
}) {
  return EnvironmentGenerationParams(
    density: density,
    variation: variation,
    edgeDensity: edgeDensity,
    minSpacingCells: minSpacing,
  );
}

class _Scenario {
  _Scenario({required this.map, required this.manifest});

  final MapData map;
  final ProjectManifest manifest;
}

_Scenario _fullScenario({
  required int mapW,
  required int mapH,
  bool activeAll = false,
  List<bool>? cells,
  EnvironmentGenerationParams? params,
  String elementId = 'e1',
  int maskW = 0,
  int maskH = 0,
}) {
  final mw = maskW == 0 ? mapW : maskW;
  final mh = maskH == 0 ? mapH : maskH;
  final cellList = cells ??
      List<bool>.filled(
        mw * mh,
        activeAll,
      );
  final mask = EnvironmentAreaMask(
    width: mw,
    height: mh,
    cells: cellList,
  );
  final preset = EnvironmentPreset(
    id: 'preset1',
    name: 'P',
    templateId: 'tpl',
    palette: [
      EnvironmentPaletteItem(elementId: elementId, weight: 1),
    ],
    defaultParams: params ?? EnvironmentGenerationParams.standard(),
    sortOrder: 0,
  );
  final manifest = _manifest(
    presets: [preset],
    elements: [_element(id: elementId)],
  );
  final area = EnvironmentArea(
    id: 'area1',
    name: 'Zone',
    presetId: 'preset1',
    mask: mask,
    seed: 99,
  );
  final map = _mapWithEnv(
    width: mapW,
    height: mapH,
    area: area,
    targetTileLayerId: 'tiles',
  );
  return _Scenario(map: map, manifest: manifest);
}

ProjectManifest _manifest({
  List<EnvironmentPreset> presets = const [],
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 't-gen',
    maps: const [],
    tilesets: const [],
    environmentPresets: presets,
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectElementEntry _element({required String id}) {
  return ProjectElementEntry(
    id: id,
    name: 'El $id',
    tilesetId: 'ts',
    categoryId: 'cat',
    frames: const [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
  );
}

MapData _mapWithEnv({
  required int width,
  required int height,
  required EnvironmentArea area,
  required String targetTileLayerId,
}) {
  final n = width * height;
  final env = MapLayer.environment(
    id: 'env',
    name: 'E',
    content: EnvironmentLayerContent(
      targetTileLayerId: targetTileLayerId,
      areas: [area],
    ),
  );
  final tile = TileLayer(
    id: 'tiles',
    name: 'T',
    tiles: List<int>.filled(n, 0),
  );
  return MapData(
    id: 'map1',
    name: 'Map',
    size: GridSize(width: width, height: height),
    layers: [env, tile],
  );
}

```
