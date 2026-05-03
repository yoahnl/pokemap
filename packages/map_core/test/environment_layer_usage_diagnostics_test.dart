import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

EnvironmentPreset _manifestPreset({required String id}) {
  return EnvironmentPreset(
    id: id,
    name: 'n',
    templateId: 'tpl',
    palette: [EnvironmentPaletteItem(elementId: 'elm', weight: 1)],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: 0,
  );
}

ProjectManifest _manifest({List<EnvironmentPreset> presets = const []}) {
  return ProjectManifest(
    name: 'test',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: ProjectSurfaceCatalog(),
    environmentPresets: presets,
  );
}

EnvironmentAreaMask _mask(int w, int h, {bool allActive = true}) {
  return EnvironmentAreaMask(
    width: w,
    height: h,
    cells: List<bool>.filled(w * h, allActive),
  );
}

EnvironmentArea _area({
  required String id,
  required String presetId,
  EnvironmentAreaMask? mask,
  List<String>? generatedPlacementIds,
}) {
  return EnvironmentArea(
    id: id,
    name: 'area_$id',
    presetId: presetId,
    mask: mask ?? _mask(4, 3),
    seed: 0,
    generatedPlacementIds: generatedPlacementIds,
  );
}

MapData _map({
  List<MapLayer> layers = const [],
  List<MapPlacedElement> placedElements = const [],
}) {
  return MapData(
    id: 'map_1',
    name: 'Map 1',
    size: const GridSize(width: 4, height: 3),
    tilesetId: 'tileset',
    layers: layers,
    placedElements: placedElements,
  );
}

TileLayer _decorLayer() {
  return MapLayer.tile(
    id: 'decor',
    name: 'Decor',
    tiles: List<int>.filled(4 * 3, 0),
  ) as TileLayer;
}

EnvironmentLayer _envLayer({
  required String id,
  EnvironmentLayerContent? content,
}) {
  return MapLayer.environment(
    id: id,
    name: 'Environment',
    content: content ?? EnvironmentLayerContent.empty(),
  ) as EnvironmentLayer;
}

void main() {
  group('EnvironmentLayerUsageDiagnosticsReport', () {
    test('vide', () {
      final r = EnvironmentLayerUsageDiagnosticsReport(diagnostics: []);
      expect(r.hasDiagnostics, isFalse);
      expect(r.errorCount, 0);
      expect(r.warningCount, 0);
    });

    test('copie défensive et liste immuable', () {
      final raw = <EnvironmentLayerUsageDiagnostic>[
        EnvironmentLayerUsageDiagnostic(
          severity: EnvironmentLayerUsageDiagnosticSeverity.error,
          kind: EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer,
          mapId: 'm',
          layerId: 'l',
          targetTileLayerId: 't',
          message: 'msg',
        ),
      ];
      final r = EnvironmentLayerUsageDiagnosticsReport(diagnostics: raw);
      expect(() => r.diagnostics.add(raw.first), throwsUnsupportedError);
      raw.clear();
      expect(r.diagnosticCount, 1);
    });

    test('counts et diagnosticsForLayer / Area / Kind', () {
      final d1 = EnvironmentLayerUsageDiagnostic(
        severity: EnvironmentLayerUsageDiagnosticSeverity.error,
        kind: EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
        mapId: 'm',
        layerId: 'L',
        areaId: 'A',
        presetId: 'P',
        message: 'm1',
      );
      final d2 = EnvironmentLayerUsageDiagnostic(
        severity: EnvironmentLayerUsageDiagnosticSeverity.warning,
        kind: EnvironmentLayerUsageDiagnosticKind.emptyAreaMask,
        mapId: 'm',
        layerId: 'L',
        areaId: 'B',
        message: 'm2',
      );
      final r = EnvironmentLayerUsageDiagnosticsReport(diagnostics: [d1, d2]);
      expect(r.errorCount, 1);
      expect(r.warningCount, 1);
      expect(r.diagnosticsForLayer('  L  ').length, 2);
      expect(r.diagnosticsForLayer(''), isEmpty);
      expect(r.diagnosticsForArea('A').length, 1);
      expect(r.diagnosticsForArea(''), isEmpty);
      final k = r.diagnosticsForKind(
        EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
      );
      expect(k.length, 1);
      expect(() => k.add(d1), throwsUnsupportedError);
    });

    test('égalité', () {
      final d = EnvironmentLayerUsageDiagnostic(
        severity: EnvironmentLayerUsageDiagnosticSeverity.warning,
        kind: EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId,
        mapId: 'm',
        layerId: 'l',
        message: 'x',
      );
      final r1 = EnvironmentLayerUsageDiagnosticsReport(diagnostics: [d]);
      final r2 = EnvironmentLayerUsageDiagnosticsReport(diagnostics: [d]);
      expect(r1, equals(r2));
    });
  });

  group('missingAreaPreset', () {
    test('preset présent => rien', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: [_area(id: 'a1', presetId: 'pre')],
            ),
          ),
          _decorLayer(),
        ],
      );
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
          EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
        ),
        isEmpty,
      );
    });

    test('preset absent => error', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env_layer',
            content: EnvironmentLayerContent(
              areas: [
                _area(id: 'forest_north', presetId: 'selbrume_dense_forest'),
              ],
            ),
          ),
        ],
      );
      final d = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnosticsForKind(
            EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
          )
          .single;
      expect(d.areaId, 'forest_north');
      expect(d.presetId, 'selbrume_dense_forest');
      expect(
        d.message,
        'Environment area "forest_north" on layer "env_layer" references missing preset "selbrume_dense_forest".',
      );
    });

    test('deux areas même preset absent => deux diagnostics', () {
      final m = _manifest();
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              areas: [
                _area(id: 'a1', presetId: 'gone'),
                _area(id: 'a2', presetId: 'gone'),
              ],
            ),
          ),
        ],
      );
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map)
            .diagnosticsForKind(
              EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
            )
            .length,
        2,
      );
    });
  });

  group('missingTargetTileLayerId', () {
    test('sans area => pas de warning', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent.empty(),
          ),
        ],
      );
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
          EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId,
        ),
        isEmpty,
      );
    });

    test('avec area sans target => warning', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env_layer',
            content: EnvironmentLayerContent(
              areas: [_area(id: 'a', presetId: 'pre')],
            ),
          ),
        ],
      );
      final r = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnosticsForKind(
            EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId,
          )
          .single;
      expect(
        r.message,
        'Environment layer "env_layer" has areas but no target tile layer.',
      );
    });
  });

  group('unknownTargetTileLayer', () {
    test('TileLayer existant => rien', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: [_area(id: 'a', presetId: 'pre')],
            ),
          ),
          _decorLayer(),
        ],
      );
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
          EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer,
        ),
        isEmpty,
      );
    });

    test('cible inexistante => error', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env_layer',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: [_area(id: 'a', presetId: 'pre')],
            ),
          ),
        ],
      );
      final d = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnosticsForKind(
            EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer,
          )
          .single;
      expect(d.targetTileLayerId, 'decor');
      expect(
        d.message,
        'Environment layer "env_layer" targets missing tile layer "decor".',
      );
    });
  });

  group('targetLayerIsNotTileLayer', () {
    test('ObjectLayer => error', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env_layer',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'objects',
              areas: [_area(id: 'a', presetId: 'pre')],
            ),
          ),
          MapLayer.object(id: 'objects', name: 'O'),
        ],
      );
      final d = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnosticsForKind(
            EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer,
          )
          .single;
      expect(d.targetTileLayerId, 'objects');
      expect(
        d.message,
        'Environment layer "env_layer" targets layer "objects", but it is not a TileLayer.',
      );
    });

    test('self EnvironmentLayer => error', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final env = _envLayer(
        id: 'env_self',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'env_self',
          areas: [_area(id: 'a', presetId: 'pre')],
        ),
      );
      final map = _map(layers: [env]);
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map)
            .diagnosticsForKind(
              EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer,
            )
            .length,
        1,
      );
    });
  });

  group('areaMaskSizeMismatch', () {
    test('taille ok => rien', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              areas: [_area(id: 'a', presetId: 'pre')],
            ),
          ),
        ],
      );
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
          EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch,
        ),
        isEmpty,
      );
    });

    test('width différent', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              areas: [
                _area(
                  id: 'forest_north',
                  presetId: 'pre',
                  mask: EnvironmentAreaMask(
                    width: 8,
                    height: 3,
                    cells: List<bool>.filled(8 * 3, true),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
      final d = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnosticsForKind(
            EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch,
          )
          .single;
      expect(
        d.message,
        'Environment area "forest_north" mask size 8x3 does not match map size 4x3.',
      );
    });

    test('height différent', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              areas: [
                _area(
                  id: 'a',
                  presetId: 'pre',
                  mask: EnvironmentAreaMask(
                    width: 4,
                    height: 2,
                    cells: List<bool>.filled(8, true),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map)
            .diagnosticsForKind(
              EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch,
            )
            .length,
        1,
      );
    });
  });

  group('emptyAreaMask', () {
    test('au moins une cellule active => rien', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              areas: [_area(id: 'a', presetId: 'pre')],
            ),
          ),
        ],
      );
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
          EnvironmentLayerUsageDiagnosticKind.emptyAreaMask,
        ),
        isEmpty,
      );
    });

    test('masque tout false => warning', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              areas: [
                _area(
                  id: 'forest_north',
                  presetId: 'pre',
                  mask: _mask(4, 3, allActive: false),
                ),
              ],
            ),
          ),
        ],
      );
      final d = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnosticsForKind(
            EnvironmentLayerUsageDiagnosticKind.emptyAreaMask,
          )
          .single;
      expect(
        d.message,
        'Environment area "forest_north" has an empty mask.',
      );
    });
  });

  group('missingGeneratedPlacement', () {
    test('ids présents => rien', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              areas: [
                _area(
                  id: 'forest_north',
                  presetId: 'pre',
                  generatedPlacementIds: ['tree_42'],
                ),
              ],
            ),
          ),
        ],
        placedElements: [
          MapPlacedElement(
            id: 'tree_42',
            layerId: 'decor',
            elementId: 'oak',
            pos: const GridPos(x: 0, y: 0),
          ),
        ],
      );
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
          EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement,
        ),
        isEmpty,
      );
    });

    test('id absent => warning avec message stable', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env_layer',
            content: EnvironmentLayerContent(
              areas: [
                _area(
                  id: 'forest_north',
                  presetId: 'pre',
                  generatedPlacementIds: ['tree_42'],
                ),
              ],
            ),
          ),
        ],
      );
      final d = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnosticsForKind(
            EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement,
          )
          .single;
      expect(d.generatedPlacementId, 'tree_42');
      expect(
        d.message,
        'Environment area "forest_north" references generated placement "tree_42", but it is not present in map.placedElements.',
      );
    });

    test('plusieurs ids absents => ordre des generatedPlacementIds', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              areas: [
                _area(
                  id: 'a',
                  presetId: 'pre',
                  generatedPlacementIds: ['second', 'first'],
                ),
              ],
            ),
          ),
        ],
      );
      final ids = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnosticsForKind(
            EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement,
          )
          .map((e) => e.generatedPlacementId)
          .toList();
      expect(ids, ['second', 'first']);
    });
  });

  group('ordre stable', () {
    test('targets puis areaMismatch, empty, preset, placements', () {
      final m = _manifest(
        presets: [
          _manifestPreset(id: 'good_pre'),
        ],
      );

      final areaBadMask = EnvironmentAreaMask(
        width: 8,
        height: 8,
        cells: List<bool>.filled(64, false),
      );
      final areaEmptyOkSize = _mask(4, 3, allActive: false);

      final map = _map(
        layers: [
          MapLayer.object(id: 'objects', name: 'O'),
          _envLayer(
            id: 'env_layer',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'objects',
              areas: [
                _area(
                  id: 'r1',
                  presetId: 'good_pre',
                  mask: areaBadMask,
                ),
                EnvironmentArea(
                  id: 'r2',
                  name: 'R2',
                  presetId: 'missing_pre',
                  mask: areaEmptyOkSize,
                  seed: 0,
                ),
                _area(
                  id: 'r3',
                  presetId: 'good_pre',
                  generatedPlacementIds: ['z', 'y'],
                ),
              ],
            ),
          ),
        ],
      );

      final kinds = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnostics
          .map((e) => e.kind)
          .toList();

      expect(
        kinds.indexOf(
            EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer),
        lessThan(
          kinds.indexOf(
              EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch),
        ),
      );

      final idxMismatch = kinds.indexOf(
        EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch,
      );
      final idxEmpty =
          kinds.indexOf(EnvironmentLayerUsageDiagnosticKind.emptyAreaMask);
      final idxPreset = kinds.indexOf(
        EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
      );

      expect(idxMismatch, lessThan(idxEmpty));
      expect(idxEmpty, lessThan(idxPreset));

      expect(
        kinds.lastIndexWhere(
          (k) =>
              k ==
              EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement,
        ),
        greaterThan(idxPreset),
      );

      final report = diagnoseMapEnvironmentLayerUsage(m, map);
      final placementKinds = [
        for (final d in report.diagnostics)
          if (d.kind ==
              EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement)
            d.generatedPlacementId,
      ];
      expect(placementKinds, ['z', 'y']);
    });
  });
}
