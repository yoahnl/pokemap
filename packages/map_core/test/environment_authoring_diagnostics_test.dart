import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

ProjectManifest _manifest({
  List<EnvironmentPreset> environmentPresets = const [],
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'authoring_diag',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: ProjectSurfaceCatalog(),
    environmentPresets: environmentPresets,
    elements: elements,
  );
}

EnvironmentPreset _preset({
  required String id,
  String templateId = 'tpl',
  List<EnvironmentPaletteItem>? palette,
}) {
  return EnvironmentPreset(
    id: id,
    name: 'n_$id',
    templateId: templateId,
    palette: palette ??
        [
          EnvironmentPaletteItem(elementId: 'elm_ok', weight: 1),
        ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: 0,
  );
}

ProjectElementEntry _element({
  required String id,
  ElementCollisionProfile? collisionProfile,
}) {
  return ProjectElementEntry(
    id: id,
    name: 'name_$id',
    tilesetId: 'ts',
    categoryId: 'cat',
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
    collisionProfile: collisionProfile,
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

MapData _map({
  required String id,
  List<MapLayer> layers = const [],
  List<MapPlacedElement> placedElements = const [],
}) {
  return MapData(
    id: id,
    name: 'Map $id',
    size: const GridSize(width: 4, height: 3),
    tilesetId: 'tileset',
    layers: layers,
    placedElements: placedElements,
  );
}

void main() {
  group('EnvironmentAuthoringDiagnosticsReport', () {
    test('vide : hasDiagnostics / erreurs / warnings', () {
      final r = EnvironmentAuthoringDiagnosticsReport(diagnostics: []);
      expect(r.hasDiagnostics, isFalse);
      expect(r.hasErrors, isFalse);
      expect(r.hasWarnings, isFalse);
      expect(r.diagnosticCount, 0);
      expect(r.summary.totalCount, 0);
    });

    test('copie défensive et liste immuable', () {
      final raw = <EnvironmentAuthoringDiagnostic>[
        EnvironmentAuthoringDiagnostic(
          source: EnvironmentAuthoringDiagnosticSource.layerUsage,
          severity: EnvironmentAuthoringDiagnosticSeverity.error,
          kind: EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
          message: 'm',
          mapId: 'x',
          layerId: 'l',
        ),
      ];
      final r = EnvironmentAuthoringDiagnosticsReport(diagnostics: raw);
      expect(() => r.diagnostics.add(raw.first), throwsUnsupportedError);
      raw.clear();
      expect(r.diagnosticCount, 1);
    });

    test('diagnosticCount / errorCount / warningCount', () {
      final r = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
            message: 'e',
            presetId: 'p',
          ),
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.warning,
            kind: EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
            message: 'w',
            mapId: 'm',
            layerId: 'l',
            areaId: 'a',
          ),
        ],
      );
      expect(r.diagnosticCount, 2);
      expect(r.errorCount, 1);
      expect(r.warningCount, 1);
    });

    test('diagnosticsForSource', () {
      final r = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
            message: 'a',
            presetId: 'p1',
          ),
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
            message: 'b',
            mapId: 'm',
            layerId: 'l',
            presetId: 'p2',
          ),
        ],
      );
      expect(
          r
              .diagnosticsForSource(
                  EnvironmentAuthoringDiagnosticSource.presetManifest)
              .length,
          1);
      expect(
          r
              .diagnosticsForSource(
                  EnvironmentAuthoringDiagnosticSource.layerUsage)
              .length,
          1);
      expect(
        () => r
            .diagnosticsForSource(
                EnvironmentAuthoringDiagnosticSource.presetManifest)
            .add(
              r.diagnostics.first,
            ),
        throwsUnsupportedError,
      );
    });

    test('diagnosticsForKind retourne liste immuable', () {
      final r = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
            message: 'x',
            presetId: 'dup',
          ),
        ],
      );
      final list = r.diagnosticsForKind(
          EnvironmentAuthoringDiagnosticKind.duplicatePresetId);
      expect(list.length, 1);
      expect(() => list.add(r.diagnostics.first), throwsUnsupportedError);
    });

    test('diagnosticsForMap trim et inconnu', () {
      final r = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.unknownTargetTileLayer,
            message: 'msg',
            mapId: 'map_a',
            layerId: 'env',
            targetTileLayerId: 'x',
          ),
        ],
      );
      expect(r.diagnosticsForMap('  map_a  ').length, 1);
      expect(r.diagnosticsForMap(''), isEmpty);
      expect(r.diagnosticsForMap('   '), isEmpty);
      expect(r.diagnosticsForMap('missing'), isEmpty);
      expect(() => r.diagnosticsForMap('map_a').add(r.diagnostics.first),
          throwsUnsupportedError);
    });

    test('diagnosticsForLayer trim et inconnu', () {
      final r = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.warning,
            kind: EnvironmentAuthoringDiagnosticKind.missingTargetTileLayerId,
            message: 'm',
            mapId: 'm1',
            layerId: 'env_layer',
          ),
        ],
      );
      expect(r.diagnosticsForLayer(' env_layer ').length, 1);
      expect(r.diagnosticsForLayer(''), isEmpty);
      expect(r.diagnosticsForLayer('nope'), isEmpty);
    });

    test('diagnosticsForArea trim et inconnu', () {
      final r = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.warning,
            kind: EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
            message: 'e',
            mapId: 'm',
            layerId: 'l',
            areaId: 'forest',
          ),
        ],
      );
      expect(r.diagnosticsForArea(' forest ').length, 1);
      expect(r.diagnosticsForArea(''), isEmpty);
      expect(r.diagnosticsForArea('other'), isEmpty);
    });

    test('diagnosticsForPreset trim et inconnu', () {
      final r = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
            message: 'msg',
            presetId: 'preset_x',
          ),
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
            message: 'usage',
            mapId: 'm',
            layerId: 'l',
            areaId: 'a',
            presetId: 'preset_x',
          ),
        ],
      );
      expect(r.diagnosticsForPreset(' preset_x ').length, 2);
      expect(r.diagnosticsForPreset(''), isEmpty);
      expect(r.diagnosticsForPreset('absent'), isEmpty);
    });

    test('égalité de valeur du rapport', () {
      final a = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
            message: 'm',
            presetId: 'p',
          ),
        ],
      );
      final b = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
            message: 'm',
            presetId: 'p',
          ),
        ],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('EnvironmentAuthoringDiagnosticsSummary', () {
    test('vide : compteurs à 0', () {
      const s = EnvironmentAuthoringDiagnosticsSummary(
        totalCount: 0,
        errorCount: 0,
        warningCount: 0,
        presetManifestCount: 0,
        layerUsageCount: 0,
        mapsWithDiagnosticsCount: 0,
        presetsWithDiagnosticsCount: 0,
      );
      expect(s.hasDiagnostics, isFalse);
      expect(s.hasErrors, isFalse);
      expect(s.hasWarnings, isFalse);
    });

    test('hasDiagnostics / hasErrors / hasWarnings', () {
      const s = EnvironmentAuthoringDiagnosticsSummary(
        totalCount: 2,
        errorCount: 1,
        warningCount: 1,
        presetManifestCount: 1,
        layerUsageCount: 1,
        mapsWithDiagnosticsCount: 1,
        presetsWithDiagnosticsCount: 1,
      );
      expect(s.hasDiagnostics, isTrue);
      expect(s.hasErrors, isTrue);
      expect(s.hasWarnings, isTrue);
    });

    test('compteurs agrégés depuis le rapport', () {
      final r = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
            message: 'm1',
            presetId: 'same_preset',
            elementId: 'missing_elm',
          ),
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
            message: 'm2',
            mapId: 'map_1',
            layerId: 'env',
            areaId: 'a1',
            presetId: 'same_preset',
          ),
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
            message: 'm3',
            mapId: 'map_1',
            layerId: 'env',
            areaId: 'a2',
            presetId: 'same_preset',
          ),
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.warning,
            kind: EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
            message: 'm4',
            mapId: 'map_2',
            layerId: 'env',
            areaId: 'a3',
          ),
        ],
      );
      final s = r.summary;
      expect(s.totalCount, 4);
      expect(s.errorCount, 3);
      expect(s.warningCount, 1);
      expect(s.presetManifestCount, 1);
      expect(s.layerUsageCount, 3);
      expect(s.mapsWithDiagnosticsCount, 2);
      expect(s.presetsWithDiagnosticsCount, 1);
    });
  });

  group('mapping preset diagnostic', () {
    test('missingPaletteElement conservé', () {
      final m = _manifest(
        environmentPresets: [
          _preset(
            id: 'p1',
            palette: [
              EnvironmentPaletteItem(elementId: 'ghost_elm', weight: 1),
            ],
          ),
        ],
        elements: const [],
      );
      final r = diagnoseProjectEnvironmentAuthoring(m, maps: const []);
      expect(r.diagnosticCount, 1);
      final d = r.diagnostics.single;
      expect(d.source, EnvironmentAuthoringDiagnosticSource.presetManifest);
      expect(d.severity, EnvironmentAuthoringDiagnosticSeverity.error);
      expect(d.kind, EnvironmentAuthoringDiagnosticKind.missingPaletteElement);
      expect(d.presetId, 'p1');
      expect(d.elementId, 'ghost_elm');
      expect(d.message, contains('p1'));
      expect(d.mapId, isNull);
      expect(d.layerId, isNull);
    });
  });

  group('mapping usage diagnostic', () {
    test('missingAreaPreset conservé', () {
      final m = _manifest(
        environmentPresets: [
          _preset(id: 'ok_preset'),
        ],
      );
      final map = _map(
        id: 'terrain_map',
        layers: [
          _decorLayer(),
          _envLayer(
            id: 'env1',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: [
                _area(id: 'zone_a', presetId: 'nope'),
              ],
            ),
          ),
        ],
      );
      final r = diagnoseProjectEnvironmentAuthoring(m, maps: [map]);
      final d = r
          .diagnosticsForKind(
              EnvironmentAuthoringDiagnosticKind.missingAreaPreset)
          .single;
      expect(d.source, EnvironmentAuthoringDiagnosticSource.layerUsage);
      expect(d.severity, EnvironmentAuthoringDiagnosticSeverity.error);
      expect(d.mapId, 'terrain_map');
      expect(d.layerId, 'env1');
      expect(d.areaId, 'zone_a');
      expect(d.presetId, 'nope');
      expect(d.message, contains('zone_a'));
    });
  });

  group('ordre stable', () {
    test('preset puis maps dans l’ordre fourni, ordre interne usage inchangé',
        () {
      final m = _manifest(
        environmentPresets: [
          _preset(id: 'dup'),
          _preset(id: 'dup'),
        ],
        elements: [_element(id: 'elm_ok')],
      );

      final mapA = _map(
        id: 'first_map',
        layers: [
          _decorLayer(),
          _envLayer(
            id: 'e',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: [
                _area(id: 'a1', presetId: 'dup', mask: _mask(2, 2)),
              ],
            ),
          ),
        ],
      );

      final mapB = _map(
        id: 'second_map',
        layers: [
          _decorLayer(),
          _envLayer(
            id: 'e2',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'missing_decor',
              areas: [
                _area(id: 'b1', presetId: 'dup'),
              ],
            ),
          ),
        ],
      );

      final aggregated =
          diagnoseProjectEnvironmentAuthoring(m, maps: [mapA, mapB]);
      final presetOnly = diagnoseProjectEnvironmentPresets(m);
      final usageA = diagnoseMapEnvironmentLayerUsage(m, mapA);
      final usageB = diagnoseMapEnvironmentLayerUsage(m, mapB);

      final kinds = aggregated.diagnostics.map((d) => d.kind).toList();
      final expectedKinds = <EnvironmentAuthoringDiagnosticKind>[
        ...presetOnly.diagnostics.map((d) => switch (d.kind) {
              EnvironmentPresetDiagnosticKind.duplicatePresetId =>
                EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
              EnvironmentPresetDiagnosticKind.missingPaletteElement =>
                EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
              EnvironmentPresetDiagnosticKind.unknownTemplateId =>
                EnvironmentAuthoringDiagnosticKind.unknownTemplateId,
              EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile =>
                EnvironmentAuthoringDiagnosticKind
                    .forcedCollisionWithoutProfile,
            }),
        ...usageA.diagnostics.map((d) => switch (d.kind) {
              EnvironmentLayerUsageDiagnosticKind.missingAreaPreset =>
                EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
              EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId =>
                EnvironmentAuthoringDiagnosticKind.missingTargetTileLayerId,
              EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer =>
                EnvironmentAuthoringDiagnosticKind.unknownTargetTileLayer,
              EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer =>
                EnvironmentAuthoringDiagnosticKind.targetLayerIsNotTileLayer,
              EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch =>
                EnvironmentAuthoringDiagnosticKind.areaMaskSizeMismatch,
              EnvironmentLayerUsageDiagnosticKind.emptyAreaMask =>
                EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
              EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement =>
                EnvironmentAuthoringDiagnosticKind.missingGeneratedPlacement,
            }),
        ...usageB.diagnostics.map((d) => switch (d.kind) {
              EnvironmentLayerUsageDiagnosticKind.missingAreaPreset =>
                EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
              EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId =>
                EnvironmentAuthoringDiagnosticKind.missingTargetTileLayerId,
              EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer =>
                EnvironmentAuthoringDiagnosticKind.unknownTargetTileLayer,
              EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer =>
                EnvironmentAuthoringDiagnosticKind.targetLayerIsNotTileLayer,
              EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch =>
                EnvironmentAuthoringDiagnosticKind.areaMaskSizeMismatch,
              EnvironmentLayerUsageDiagnosticKind.emptyAreaMask =>
                EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
              EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement =>
                EnvironmentAuthoringDiagnosticKind.missingGeneratedPlacement,
            }),
      ];
      expect(kinds, expectedKinds);
    });
  });

  group('diagnoseProjectEnvironmentAuthoring', () {
    test('maps vide : seulement diagnostics preset', () {
      final m = _manifest(
        environmentPresets: [
          _preset(
            id: 'p',
            palette: [
              EnvironmentPaletteItem(elementId: 'missing', weight: 1),
            ],
          ),
        ],
      );
      final r = diagnoseProjectEnvironmentAuthoring(m, maps: const []);
      expect(
          r.diagnostics.every((d) =>
              d.source == EnvironmentAuthoringDiagnosticSource.presetManifest),
          isTrue);
      expect(r.summary.layerUsageCount, 0);
      expect(r.summary.mapsWithDiagnosticsCount, 0);
    });

    test('manifest et maps sans problème : rapport vide', () {
      final m = _manifest(
        environmentPresets: [_preset(id: 'forest')],
        elements: [_element(id: 'elm_ok')],
      );
      final map = _map(
        id: 'clean',
        layers: [
          _decorLayer(),
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: [
                _area(id: 'a', presetId: 'forest'),
              ],
            ),
          ),
        ],
      );
      final r = diagnoseProjectEnvironmentAuthoring(m, maps: [map]);
      expect(r.hasDiagnostics, isFalse);
    });

    test('agrège preset + usage', () {
      final m = _manifest(
        environmentPresets: [
          _preset(
            id: 'p1',
            palette: [
              EnvironmentPaletteItem(elementId: 'bad', weight: 1),
            ],
          ),
        ],
      );
      final map = _map(
        id: 'agg',
        layers: [
          _decorLayer(),
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: [
                _area(id: 'ar', presetId: 'unknown_preset'),
              ],
            ),
          ),
        ],
      );
      final r = diagnoseProjectEnvironmentAuthoring(m, maps: [map]);
      expect(r.diagnosticCount, 2);
      expect(
          r
              .diagnosticsForSource(
                  EnvironmentAuthoringDiagnosticSource.presetManifest)
              .length,
          1);
      expect(
          r
              .diagnosticsForSource(
                  EnvironmentAuthoringDiagnosticSource.layerUsage)
              .length,
          1);
    });

    test('knownTemplateIds transmis à diagnoseProjectEnvironmentPresets', () {
      final m = _manifest(
        environmentPresets: [_preset(id: 'p', templateId: 'my_tpl')],
        elements: [_element(id: 'elm_ok')],
      );
      final withoutKnown =
          diagnoseProjectEnvironmentAuthoring(m, maps: const []);
      expect(
        withoutKnown.diagnosticsForKind(
            EnvironmentAuthoringDiagnosticKind.unknownTemplateId),
        isEmpty,
      );

      final withKnown = diagnoseProjectEnvironmentAuthoring(
        m,
        maps: const [],
        knownTemplateIds: {'other'},
      );
      expect(
        withKnown
            .diagnosticsForKind(
                EnvironmentAuthoringDiagnosticKind.unknownTemplateId)
            .length,
        1,
      );
      final d = withKnown.diagnostics.single;
      expect(d.templateId, 'my_tpl');
      expect(d.severity, EnvironmentAuthoringDiagnosticSeverity.warning);
    });
  });
}
