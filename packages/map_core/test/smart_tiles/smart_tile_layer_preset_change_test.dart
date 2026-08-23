import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('planSmartTileLayerPresetChange', () {
    test('reprojects a cell field while preserving layer identity', () {
      const stroke = SmartTilePatternStroke(
        id: 'stroke',
        patternId: 'pattern',
        cells: <GridPos>[GridPos(x: 1, y: 0)],
        phaseX: 2,
        phaseY: 3,
      );
      const layer = SmartTileLayer(
        id: 'path',
        name: 'Main path',
        isVisible: false,
        opacity: 0.75,
        presetId: 'dark-path',
        usage: SmartTileUsage.path,
        materialPalette: <String>['', 'dark', 'shared', 'unused'],
        field: SmartTileField.cell(semanticCells: <int>[1, 2]),
        patternStrokes: <SmartTilePatternStroke>[stroke],
        layerSeed: 42,
        candidateWeights: <String, int>{'dark-a': 2, 'dark-b': 0},
        properties: <String, String>{'author': 'Yoahn'},
      );
      final source = _preset(
        id: 'dark-path',
        allowedMaterialIds: const <String>['dark', 'shared', 'unused'],
      );
      final target = _preset(
        id: 'rural-path',
        allowedMaterialIds: const <String>['shared', 'rural', 'extra'],
        defaultMaterialId: 'rural',
      );

      final result = planSmartTileLayerPresetChange(
        map: _mapWith(layer),
        layer: layer,
        sourcePreset: source,
        targetPreset: target,
        catalog: _catalog(source, target),
        materialMappings: const <String, String>{'dark': 'rural'},
      );

      final success = result as SmartTileLayerPresetChangeSuccess;
      expect(success.layer.id, layer.id);
      expect(success.layer.name, layer.name);
      expect(success.layer.isVisible, layer.isVisible);
      expect(success.layer.opacity, layer.opacity);
      expect(success.layer.presetId, target.id);
      expect(success.layer.usage, layer.usage);
      expect(success.layer.materialPalette, const <String>[
        '',
        'shared',
        'rural',
        'extra',
      ]);
      expect(
        success.layer.field,
        const SmartTileField.cell(semanticCells: <int>[2, 1]),
      );
      expect(success.layer.patternStrokes, layer.patternStrokes);
      expect(success.layer.layerSeed, layer.layerSeed);
      expect(success.layer.properties, layer.properties);
      expect(success.layer.candidateWeights, isEmpty);
      expect(success.remappedEntryCount, 2);
      expect(success.clearedCandidateWeightCount, 2);
      expect(success.materialMappings, const <String, String>{
        'dark': 'rural',
        'shared': 'shared',
      });
      expect(layer.presetId, source.id);
      expect(
        layer.field,
        const SmartTileField.cell(semanticCells: <int>[1, 2]),
      );
    });

    test('reprojects every active Wang lattice', () {
      for (final fixture
          in <({SmartTileTopology topology, SmartTileField field})>[
            (
              topology: SmartTileTopology.wangEdge4,
              field: const SmartTileField.edge(
                semanticCells: <int>[1],
                horizontalEdges: <int>[1, 2],
                verticalEdges: <int>[2, 1],
              ),
            ),
            (
              topology: SmartTileTopology.wangCorner4,
              field: const SmartTileField.corner(
                semanticCells: <int>[1],
                corners: <int>[1, 2, 2, 1],
              ),
            ),
            (
              topology: SmartTileTopology.wang8,
              field: const SmartTileField.mixed(
                semanticCells: <int>[1],
                horizontalEdges: <int>[1, 2],
                verticalEdges: <int>[2, 1],
                corners: <int>[1, 2, 2, 1],
              ),
            ),
          ]) {
        final source = _preset(
          id: 'source-${fixture.topology.name}',
          topology: fixture.topology,
          allowedMaterialIds: const <String>['dark', 'shared'],
        );
        final target = _preset(
          id: 'target-${fixture.topology.name}',
          topology: fixture.topology,
          allowedMaterialIds: const <String>['shared', 'rural'],
          defaultMaterialId: 'rural',
        );
        final layer = SmartTileLayer(
          id: 'path',
          name: 'Path',
          presetId: source.id,
          usage: SmartTileUsage.path,
          materialPalette: const <String>['', 'dark', 'shared'],
          field: fixture.field,
        );

        final result = planSmartTileLayerPresetChange(
          map: _mapWith(layer, size: const GridSize(width: 1, height: 1)),
          layer: layer,
          sourcePreset: source,
          targetPreset: target,
          catalog: _catalog(source, target),
          materialMappings: const <String, String>{'dark': 'rural'},
        );

        final success = result as SmartTileLayerPresetChangeSuccess;
        expect(smartTileSemanticCells(success.layer), const <int>[
          2,
        ], reason: fixture.topology.name);
        expect(
          smartTileHorizontalEdges(success.layer),
          smartTileHorizontalEdges(
            layer,
          ).map((value) => value == 1 ? 2 : 1).toList(),
          reason: fixture.topology.name,
        );
        expect(
          smartTileVerticalEdges(success.layer),
          smartTileVerticalEdges(
            layer,
          ).map((value) => value == 1 ? 2 : 1).toList(),
          reason: fixture.topology.name,
        );
        expect(
          smartTileCorners(success.layer),
          smartTileCorners(layer).map((value) => value == 1 ? 2 : 1).toList(),
          reason: fixture.topology.name,
        );
      }
    });

    test('does not require mappings for unused palette entries', () {
      const layer = SmartTileLayer(
        id: 'path',
        name: 'Path',
        presetId: 'dark-path',
        usage: SmartTileUsage.path,
        materialPalette: <String>['', 'dark', 'unused'],
        field: SmartTileField.cell(semanticCells: <int>[1]),
      );
      final source = _preset(
        id: 'dark-path',
        allowedMaterialIds: const <String>['dark', 'unused'],
      );
      final target = _preset(
        id: 'rural-path',
        allowedMaterialIds: const <String>['rural'],
        defaultMaterialId: 'rural',
      );

      final result = planSmartTileLayerPresetChange(
        map: _mapWith(layer, size: const GridSize(width: 1, height: 1)),
        layer: layer,
        sourcePreset: source,
        targetPreset: target,
        catalog: _catalog(source, target),
        materialMappings: const <String, String>{'dark': 'rural'},
      );

      expect(result, isA<SmartTileLayerPresetChangeSuccess>());
    });

    test('rejects a no-op preset change', () {
      const layer = SmartTileLayer(
        id: 'path',
        name: 'Path',
        presetId: 'path',
        usage: SmartTileUsage.path,
        materialPalette: <String>['', 'dark'],
        field: SmartTileField.cell(semanticCells: <int>[1]),
      );
      final preset = _preset(id: 'path');

      final result = planSmartTileLayerPresetChange(
        map: _mapWith(layer, size: const GridSize(width: 1, height: 1)),
        layer: layer,
        sourcePreset: preset,
        targetPreset: preset,
        catalog: _catalog(preset),
      );

      expect(
        (result as SmartTileLayerPresetChangeFailure).code,
        'smart_tile.layer_preset_no_change',
      );
    });

    test('rejects a draft target preset', () {
      const layer = SmartTileLayer(
        id: 'path',
        name: 'Path',
        presetId: 'source',
        usage: SmartTileUsage.path,
        materialPalette: <String>['', 'dark'],
        field: SmartTileField.cell(semanticCells: <int>[1]),
      );
      final source = _preset(id: 'source');
      final target = _preset(id: 'target', status: SmartTilePresetStatus.draft);

      final result = planSmartTileLayerPresetChange(
        map: _mapWith(layer, size: const GridSize(width: 1, height: 1)),
        layer: layer,
        sourcePreset: source,
        targetPreset: target,
        catalog: _catalog(source, target),
      );

      expect(
        (result as SmartTileLayerPresetChangeFailure).code,
        'smart_tile.layer_preset_not_published',
      );
    });

    test('rejects a target with another usage', () {
      const layer = SmartTileLayer(
        id: 'path',
        name: 'Path',
        presetId: 'source',
        usage: SmartTileUsage.path,
        materialPalette: <String>['', 'dark'],
        field: SmartTileField.cell(semanticCells: <int>[1]),
      );
      final source = _preset(id: 'source');
      final target = _preset(id: 'target', usage: SmartTileUsage.terrain);

      final result = planSmartTileLayerPresetChange(
        map: _mapWith(layer, size: const GridSize(width: 1, height: 1)),
        layer: layer,
        sourcePreset: source,
        targetPreset: target,
        catalog: _catalog(source, target),
      );

      expect(
        (result as SmartTileLayerPresetChangeFailure).code,
        'smart_tile.layer_preset_usage_incompatible',
      );
    });

    test('rejects a target with an incompatible topology family', () {
      const layer = SmartTileLayer(
        id: 'path',
        name: 'Path',
        presetId: 'source',
        usage: SmartTileUsage.path,
        materialPalette: <String>['', 'dark'],
        field: SmartTileField.cell(semanticCells: <int>[1]),
      );
      final source = _preset(id: 'source');
      final target = _preset(
        id: 'target',
        topology: SmartTileTopology.wangEdge4,
      );

      final result = planSmartTileLayerPresetChange(
        map: _mapWith(layer, size: const GridSize(width: 1, height: 1)),
        layer: layer,
        sourcePreset: source,
        targetPreset: target,
        catalog: _catalog(source, target),
      );

      expect(
        (result as SmartTileLayerPresetChangeFailure).code,
        'smart_tile.layer_preset_topology_incompatible',
      );
    });

    test('reports every used material that needs an explicit mapping', () {
      const layer = SmartTileLayer(
        id: 'path',
        name: 'Path',
        presetId: 'source',
        usage: SmartTileUsage.path,
        materialPalette: <String>['', 'dark', 'shared', 'mud'],
        field: SmartTileField.cell(semanticCells: <int>[1, 2, 3]),
      );
      final source = _preset(
        id: 'source',
        allowedMaterialIds: const <String>['dark', 'shared', 'mud'],
      );
      final target = _preset(
        id: 'target',
        allowedMaterialIds: const <String>['shared', 'rural'],
        defaultMaterialId: 'rural',
      );

      final result = planSmartTileLayerPresetChange(
        map: _mapWith(layer, size: const GridSize(width: 3, height: 1)),
        layer: layer,
        sourcePreset: source,
        targetPreset: target,
        catalog: _catalog(source, target),
      );

      final failure = result as SmartTileLayerPresetChangeFailure;
      expect(failure.code, 'smart_tile.layer_preset_material_mapping_required');
      expect(failure.requiredMaterialIds, const <String>['dark', 'mud']);
    });

    test('rejects a mapping to a material unavailable to the target', () {
      const layer = SmartTileLayer(
        id: 'path',
        name: 'Path',
        presetId: 'source',
        usage: SmartTileUsage.path,
        materialPalette: <String>['', 'dark'],
        field: SmartTileField.cell(semanticCells: <int>[1]),
      );
      final source = _preset(id: 'source');
      final target = _preset(
        id: 'target',
        allowedMaterialIds: const <String>['rural'],
        defaultMaterialId: 'rural',
      );

      final result = planSmartTileLayerPresetChange(
        map: _mapWith(layer, size: const GridSize(width: 1, height: 1)),
        layer: layer,
        sourcePreset: source,
        targetPreset: target,
        catalog: _catalog(source, target),
        materialMappings: const <String, String>{'dark': 'extra'},
      );

      expect(
        (result as SmartTileLayerPresetChangeFailure).code,
        'smart_tile.layer_preset_material_mapping_invalid',
      );
    });

    test('rejects a field whose dimensions do not match the map', () {
      const layer = SmartTileLayer(
        id: 'path',
        name: 'Path',
        presetId: 'source',
        usage: SmartTileUsage.path,
        materialPalette: <String>['', 'dark'],
        field: SmartTileField.cell(semanticCells: <int>[1]),
      );
      final source = _preset(id: 'source');
      final target = _preset(id: 'target');

      final result = planSmartTileLayerPresetChange(
        map: _mapWith(layer),
        layer: layer,
        sourcePreset: source,
        targetPreset: target,
        catalog: _catalog(source, target),
      );

      expect(
        (result as SmartTileLayerPresetChangeFailure).code,
        'smart_tile.layer_preset_field_invalid',
      );
    });

    test('rejects a projection unresolved by the target preset', () {
      const layer = SmartTileLayer(
        id: 'path',
        name: 'Path',
        presetId: 'source',
        usage: SmartTileUsage.path,
        materialPalette: <String>['', 'dark'],
        field: SmartTileField.cell(semanticCells: <int>[1]),
      );
      final source = _preset(id: 'source');
      final target = _preset(id: 'target', rules: const <SmartTileRule>[]);

      final result = planSmartTileLayerPresetChange(
        map: _mapWith(layer, size: const GridSize(width: 1, height: 1)),
        layer: layer,
        sourcePreset: source,
        targetPreset: target,
        catalog: _catalog(source, target),
      );

      expect(
        (result as SmartTileLayerPresetChangeFailure).code,
        'smart_tile.layer_preset_unresolved',
      );
    });

    test(
      'remaps the encounter behavior material even when no cell uses it',
      () {
        const layer = SmartTileLayer(
          id: 'path',
          name: 'Path',
          presetId: 'source',
          usage: SmartTileUsage.path,
          materialPalette: <String>['', 'dark', 'unused'],
          field: SmartTileField.cell(semanticCells: <int>[1]),
          encounterBehavior: SmartTileEncounterBehavior(
            materialId: 'unused',
            encounter: EncounterZonePayload(
              encounterTableId: 'grass',
              encounterKind: EncounterKind.walk,
            ),
          ),
        );
        final source = _preset(
          id: 'source',
          allowedMaterialIds: const <String>['dark', 'unused'],
        );
        final target = _preset(
          id: 'target',
          allowedMaterialIds: const <String>['rural', 'extra'],
          defaultMaterialId: 'rural',
        );

        final result = planSmartTileLayerPresetChange(
          map: _mapWith(layer, size: const GridSize(width: 1, height: 1)),
          layer: layer,
          sourcePreset: source,
          targetPreset: target,
          catalog: _catalog(source, target),
          materialMappings: const <String, String>{
            'dark': 'rural',
            'unused': 'extra',
          },
        );

        final success = result as SmartTileLayerPresetChangeSuccess;
        expect(success.layer.encounterBehavior?.materialId, 'extra');
        expect(success.materialMappings['unused'], 'extra');
      },
    );
  });
}

const List<ProjectSmartTileMaterial> _materials = <ProjectSmartTileMaterial>[
  ProjectSmartTileMaterial(
    id: 'dark',
    name: 'Dark dirt',
    connectionGroupId: 'dirt',
  ),
  ProjectSmartTileMaterial(
    id: 'shared',
    name: 'Shared dirt',
    connectionGroupId: 'dirt',
  ),
  ProjectSmartTileMaterial(
    id: 'unused',
    name: 'Unused dirt',
    connectionGroupId: 'dirt',
  ),
  ProjectSmartTileMaterial(id: 'mud', name: 'Mud', connectionGroupId: 'dirt'),
  ProjectSmartTileMaterial(
    id: 'rural',
    name: 'Rural dirt',
    connectionGroupId: 'dirt',
  ),
  ProjectSmartTileMaterial(
    id: 'extra',
    name: 'Extra dirt',
    connectionGroupId: 'dirt',
  ),
];

MapData _mapWith(
  SmartTileLayer layer, {
  GridSize size = const GridSize(width: 2, height: 1),
}) => MapData(id: 'map', name: 'Map', size: size, layers: <MapLayer>[layer]);

ProjectSmartTileCatalog _catalog(
  ProjectSmartTilePreset first, [
  ProjectSmartTilePreset? second,
]) => ProjectSmartTileCatalog(
  materials: _materials,
  presets: <ProjectSmartTilePreset>[first, if (second != null) second],
);

ProjectSmartTilePreset _preset({
  required String id,
  SmartTileUsage usage = SmartTileUsage.path,
  SmartTileTopology topology = SmartTileTopology.uniform,
  SmartTilePresetStatus status = SmartTilePresetStatus.published,
  List<String> allowedMaterialIds = const <String>['dark'],
  String defaultMaterialId = 'dark',
  List<SmartTileRule>? rules,
}) => ProjectSmartTilePreset(
  id: id,
  name: id,
  usage: usage,
  topology: topology,
  status: status,
  coveragePolicy: SmartTileCoveragePolicy.sparse,
  coverageProfile: const SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.explicit,
  ),
  transformPolicy: const SmartTileTransformPolicy(),
  defaultMaterialId: defaultMaterialId,
  allowedMaterialIds: allowedMaterialIds,
  rules:
      rules ??
      <SmartTileRule>[
        SmartTileRule(
          id: '$id-rule',
          centerMatch: const SmartTileSlotMatch.any(),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(id: '$id-candidate'),
          ],
        ),
      ],
);
