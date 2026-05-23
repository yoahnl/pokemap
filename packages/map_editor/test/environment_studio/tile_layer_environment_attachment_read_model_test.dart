import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/tile_layer_environment_attachment_read_model.dart';
import 'package:map_editor/src/application/services/tile_layer_environment_attachment_read_model_builder.dart';

void main() {
  group('TileLayerEnvironmentAttachmentReadModel', () {
    test('retourne un empty state quand le projet est null', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: null,
        map: _map(),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: null,
      );

      expect(model.state, TileLayerEnvironmentAttachmentState.noProject);
      expect(model.emptyStateTitle, 'Aucun projet chargé');
      expect(model.canEnableEnvironment, isFalse);
      expect(model.canPaintMask, isFalse);
      expect(model.canGenerate, isFalse);
    });

    test('retourne un état neutre quand la map est null', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: null,
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: null,
      );

      expect(model.state, TileLayerEnvironmentAttachmentState.noMap);
      expect(model.emptyStateTitle, 'Aucune carte active');
      expect(model.canEnableEnvironment, isFalse);
      expect(model.canPaintMask, isFalse);
      expect(model.canGenerate, isFalse);
    });

    test('retourne un état neutre quand aucun layer est sélectionné', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(),
        selectedLayerId: null,
        selectedEnvironmentAreaId: null,
      );

      expect(model.state, TileLayerEnvironmentAttachmentState.noLayerSelected);
      expect(
          model.selectedLayerKind, TileLayerEnvironmentSelectedLayerKind.none);
      expect(model.emptyStateTitle, 'Aucun layer sélectionné');
      expect(model.canEnableEnvironment, isFalse);
    });

    test('détecte un TileLayer sans environnement attaché', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: null,
      );

      expect(model.state, TileLayerEnvironmentAttachmentState.noAttachment);
      expect(
          model.selectedLayerKind, TileLayerEnvironmentSelectedLayerKind.tile);
      expect(model.activeTileLayerId, 'tiles');
      expect(model.hasAttachment, isFalse);
      expect(model.canEnableEnvironment, isTrue);
      expect(model.primaryActionLabel, 'Activer l’environnement');
    });

    test('détecte un TileLayer avec EnvironmentLayer attaché', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(areas: [_area(activeCells: 1)]),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area1',
      );

      expect(model.state, TileLayerEnvironmentAttachmentState.ready);
      expect(model.hasAttachment, isTrue);
      expect(model.hasValidTargetTileLayer, isTrue);
      expect(model.attachedEnvironmentLayerId, 'env');
      expect(model.activeTileLayerId, 'tiles');
      expect(model.canPaintMask, isTrue);
      expect(model.canGenerate, isTrue);
      expect(model.canClearGeneratedPlacements, isFalse);
      expect(model.canRegenerate, isFalse);
      expect(model.canShuffle, isFalse);
    });

    test('détecte plusieurs EnvironmentLayers attachés au même TileLayer', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(
          areas: [_area(activeCells: 1)],
          extraLayers: [
            MapLayer.environment(
              id: 'env_b',
              name: 'Environment B',
              content: EnvironmentLayerContent(
                targetTileLayerId: 'tiles',
                areas: [_area(id: 'area_b', activeCells: 1)],
              ),
            ),
          ],
        ),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area1',
      );

      expect(model.hasMultipleAttachments, isTrue);
      expect(model.attachedEnvironmentLayerId, 'env');
      expect(
          model.warnings,
          contains(
              'Plusieurs environnements ciblent ce layer. Le premier sera utilisé pour l’instant.'));
    });

    test('détecte un EnvironmentLayer sélectionné directement en mode legacy',
        () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(areas: [_area(activeCells: 1)]),
        selectedLayerId: 'env',
        selectedEnvironmentAreaId: 'area1',
      );

      expect(model.isLegacyEnvironmentLayerSelection, isTrue);
      expect(model.selectedLayerKind,
          TileLayerEnvironmentSelectedLayerKind.environment);
      expect(model.activeTileLayerId, 'tiles');
      expect(
          model.warnings,
          contains(
              'Cet environnement est attaché à un TileLayer. La prochaine UX le pilotera depuis le layer cible.'));
    });

    test('détecte targetTileLayerId manquant', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(
          environmentTargetLayerId: null,
          areas: [_area(activeCells: 1)],
        ),
        selectedLayerId: 'env',
        selectedEnvironmentAreaId: 'area1',
      );

      expect(model.state,
          TileLayerEnvironmentAttachmentState.missingTargetTileLayer);
      expect(model.hasValidTargetTileLayer, isFalse);
      expect(model.errors,
          contains('Cet environnement n’a pas encore de layer cible.'));
      expect(model.canPaintMask, isFalse);
      expect(model.canGenerate, isFalse);
    });

    test('détecte target layer inexistant', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(
          environmentTargetLayerId: 'missing',
          areas: [_area(activeCells: 1)],
        ),
        selectedLayerId: 'env',
        selectedEnvironmentAreaId: 'area1',
      );

      expect(model.state,
          TileLayerEnvironmentAttachmentState.targetTileLayerMissing);
      expect(model.errors,
          contains('Le layer cible de cet environnement est introuvable.'));
      expect(model.canGenerate, isFalse);
    });

    test('détecte target layer non TileLayer', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(
          environmentTargetLayerId: 'objects',
          areas: [_area(activeCells: 1)],
          extraLayers: const [
            MapLayer.object(id: 'objects', name: 'Objects'),
          ],
        ),
        selectedLayerId: 'env',
        selectedEnvironmentAreaId: 'area1',
      );

      expect(model.state,
          TileLayerEnvironmentAttachmentState.targetLayerIsNotTileLayer);
      expect(
          model.errors,
          contains(
              'Le layer cible de cet environnement n’est pas un TileLayer.'));
      expect(model.canPaintMask, isFalse);
    });

    test('détecte absence d’area', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(areas: const []),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: null,
      );

      expect(model.state, TileLayerEnvironmentAttachmentState.noArea);
      expect(model.emptyStateTitle, 'Aucune zone d’environnement');
      expect(model.primaryActionLabel, 'Ajouter une zone');
      expect(model.canPaintMask, isFalse);
      expect(model.areaSummaries, isEmpty);
    });

    test('détecte area sélectionnée valide', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(
            areas: [_area(id: 'area1'), _area(id: 'area2', activeCells: 1)]),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area2',
      );

      expect(model.selectedEnvironmentAreaId, 'area2');
      expect(model.selectedEnvironmentAreaName, 'Zone area2');
      expect(model.maskActiveCellCount, 1);
      expect(model.areaSummaries.map((summary) => summary.id), [
        'area1',
        'area2',
      ]);
      expect(
          model.areaSummaries
              .singleWhere((summary) => summary.id == 'area2')
              .isSelected,
          isTrue);
    });

    test('détecte area sélectionnée absente', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(areas: [_area(id: 'area1', activeCells: 1)]),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'missing',
      );

      expect(
          model.state, TileLayerEnvironmentAttachmentState.selectedAreaMissing);
      expect(model.errors,
          contains('La zone d’environnement sélectionnée est introuvable.'));
      expect(model.canGenerate, isFalse);
      expect(model.areaSummaries, hasLength(1));
      expect(model.areaSummaries.single.isSelected, isFalse);
    });

    test('utilise la seule area existante quand aucune sélection est fournie',
        () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(areas: [_area(id: 'area1', activeCells: 1)]),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: null,
      );

      expect(model.state, TileLayerEnvironmentAttachmentState.ready);
      expect(model.selectedEnvironmentAreaId, 'area1');
      expect(model.canGenerate, isTrue);
      expect(model.areaSummaries, hasLength(1));
      expect(model.areaSummaries.single.isSelected, isTrue);
    });

    test('demande une sélection quand plusieurs areas existent sans sélection',
        () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(areas: [_area(id: 'area1'), _area(id: 'area2')]),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: null,
      );

      expect(model.state,
          TileLayerEnvironmentAttachmentState.areaSelectionRequired);
      expect(model.emptyStateTitle, 'Sélectionnez une zone d’environnement');
      expect(model.canGenerate, isFalse);
      expect(model.areaSummaries.map((summary) => summary.id), [
        'area1',
        'area2',
      ]);
      expect(
        model.areaSummaries.where((summary) => summary.isSelected),
        isEmpty,
      );
    });

    test('expose les summaries de zones dans l’ordre avec compteurs', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(
          areas: [
            _area(
              id: 'area1',
              activeCells: 2,
              generatedPlacementIds: const ['g1', 'missing'],
            ),
            _area(id: 'area2', activeCells: 1),
          ],
          placedElements: const [
            MapPlacedElement(
              id: 'g1',
              layerId: 'tiles',
              elementId: 'tree',
              pos: GridPos(x: 0, y: 0),
            ),
          ],
        ),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area1',
      );

      expect(model.areaSummaries, hasLength(2));
      final first = model.areaSummaries[0];
      expect(first.id, 'area1');
      expect(first.name, 'Zone area1');
      expect(first.presetId, 'forest');
      expect(first.presetName, 'Forêt');
      expect(first.isSelected, isTrue);
      expect(first.maskActiveCellCount, 2);
      expect(first.generatedPlacementCount, 2);
      expect(first.missingGeneratedPlacementCount, 1);
      expect(first.hasMissingPreset, isFalse);
      expect(model.areaSummaries[1].id, 'area2');
    });

    test('summary signale un preset manquant', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(environmentPresets: const []),
        map: _map(areas: [_area(presetId: 'missing_preset')]),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area1',
      );

      final summary = model.areaSummaries.single;
      expect(summary.presetId, 'missing_preset');
      expect(summary.presetName, isNull);
      expect(summary.hasMissingPreset, isTrue);
    });

    test('détecte preset valide', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(areas: [_area(activeCells: 1)]),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area1',
      );

      expect(model.selectedPresetId, 'forest');
      expect(model.selectedPresetName, 'Forêt');
      expect(model.errors, isEmpty);
    });

    test('expose les paramètres effectifs depuis le preset sans override', () {
      final defaultParams = _params(
        density: 0.45,
        variation: 0.15,
        edgeDensity: 0.85,
        minSpacingCells: 2,
      );

      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(defaultParams: defaultParams),
        map: _map(areas: [_area(activeCells: 1, seed: 123)]),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area1',
      );

      expect(model.selectedAreaDefaultParams, defaultParams);
      expect(model.selectedAreaEffectiveParams, defaultParams);
      expect(model.selectedAreaParamsOverride, isNull);
      expect(model.selectedAreaHasParamsOverride, isFalse);
      expect(model.selectedAreaSeed, 123);
      expect(model.canEditSelectedAreaGenerationParams, isTrue);
    });

    test('expose les paramètres effectifs depuis paramsOverride', () {
      final defaultParams = _params(
        density: 0.45,
        variation: 0.15,
        edgeDensity: 0.85,
        minSpacingCells: 2,
      );
      final override = _params(
        density: 0.8,
        variation: 0.25,
        edgeDensity: 0.6,
        minSpacingCells: 4,
      );

      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(defaultParams: defaultParams),
        map: _map(
          areas: [
            _area(
              activeCells: 1,
              seed: 77,
              paramsOverride: override,
            ),
          ],
        ),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area1',
      );

      expect(model.selectedAreaDefaultParams, defaultParams);
      expect(model.selectedAreaEffectiveParams, override);
      expect(model.selectedAreaParamsOverride, override);
      expect(model.selectedAreaHasParamsOverride, isTrue);
      expect(model.selectedAreaSeed, 77);
      expect(model.canEditSelectedAreaGenerationParams, isTrue);
    });

    test('désactive les paramètres si le preset est manquant', () {
      final override = _params(
        density: 0.7,
        variation: 0.2,
        edgeDensity: 0.9,
        minSpacingCells: 1,
      );

      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(environmentPresets: const []),
        map: _map(
          areas: [
            _area(
              activeCells: 1,
              paramsOverride: override,
              seed: 9,
            ),
          ],
        ),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area1',
      );

      expect(model.selectedAreaDefaultParams, isNull);
      expect(model.selectedAreaEffectiveParams, isNull);
      expect(model.selectedAreaParamsOverride, override);
      expect(model.selectedAreaHasParamsOverride, isTrue);
      expect(model.selectedAreaSeed, 9);
      expect(model.canEditSelectedAreaGenerationParams, isFalse);
    });

    test('désactive les paramètres si aucune area effective est sélectionnée',
        () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(areas: [_area(id: 'area1'), _area(id: 'area2')]),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: null,
      );

      expect(model.state,
          TileLayerEnvironmentAttachmentState.areaSelectionRequired);
      expect(model.selectedAreaDefaultParams, isNull);
      expect(model.selectedAreaEffectiveParams, isNull);
      expect(model.selectedAreaParamsOverride, isNull);
      expect(model.selectedAreaHasParamsOverride, isFalse);
      expect(model.selectedAreaSeed, isNull);
      expect(model.canEditSelectedAreaGenerationParams, isFalse);
    });

    test('détecte preset manquant', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(environmentPresets: const []),
        map: _map(areas: [_area(activeCells: 1)]),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area1',
      );

      expect(model.state, TileLayerEnvironmentAttachmentState.missingPreset);
      expect(
          model.errors,
          contains(
              'Le preset d’environnement utilisé par cette zone est introuvable.'));
      expect(model.canPaintMask, isTrue);
      expect(model.canGenerate, isFalse);
      expect(model.canRegenerate, isFalse);
      expect(model.canShuffle, isFalse);
    });

    test('détecte masque vide', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(areas: [_area(activeCells: 0)]),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area1',
      );

      expect(model.state, TileLayerEnvironmentAttachmentState.emptyMask);
      expect(model.hasMask, isFalse);
      expect(model.maskActiveCellCount, 0);
      expect(model.canPaintMask, isTrue);
      expect(model.canGenerate, isFalse);
      expect(model.canRegenerate, isFalse);
      expect(model.canShuffle, isFalse);
    });

    test('détecte masque non vide', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(areas: [_area(activeCells: 2)]),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area1',
      );

      expect(model.hasMask, isTrue);
      expect(model.maskActiveCellCount, 2);
    });

    test('compte generatedPlacementIds et placements manquants', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(
          areas: [
            _area(
              activeCells: 1,
              generatedPlacementIds: const ['g1', 'g2', 'g3'],
            ),
          ],
          placedElements: const [
            MapPlacedElement(
              id: 'g1',
              layerId: 'tiles',
              elementId: 'tree',
              pos: GridPos(x: 0, y: 0),
            ),
          ],
        ),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area1',
      );

      expect(model.generatedPlacementCount, 3);
      expect(model.existingGeneratedPlacementCount, 1);
      expect(model.missingGeneratedPlacementCount, 2);
      expect(model.hasGeneratedPlacements, isTrue);
      expect(model.canClearGeneratedPlacements, isTrue);
      expect(model.canGenerate, isFalse);
      expect(model.canRegenerate, isTrue);
      expect(model.canShuffle, isTrue);
      expect(model.warnings,
          contains('2 placements générés référencés sont introuvables.'));
    });

    test(
        'expose la palette du preset avec la sélection et les éléments manquants',
        () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(
          environmentPresets: [
            EnvironmentPreset(
              id: 'forest',
              name: 'Forêt',
              templateId: 'forest',
              palette: [
                EnvironmentPaletteItem(elementId: 'tree', weight: 2),
                EnvironmentPaletteItem(elementId: 'missing_bush', weight: 3),
              ],
              defaultParams: EnvironmentGenerationParams(
                density: 1,
                variation: 0,
                edgeDensity: 1,
                minSpacingCells: 0,
              ),
              sortOrder: 0,
            ),
          ],
        ),
        map: _map(
          areas: [
            _area(
              activeCells: 1,
              generatedPlacementIds: const ['g1'],
            ),
          ],
        ),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area1',
        selectedGeneratedPlacementElementId: 'tree',
      );

      expect(model.selectedAreaPaletteItems, hasLength(2));
      expect(model.selectedAreaPaletteItems[0].elementId, 'tree');
      expect(model.selectedAreaPaletteItems[0].elementName, 'Tree');
      expect(model.selectedAreaPaletteItems[0].weight, 2);
      expect(model.selectedAreaPaletteItems[0].hasMissingElement, isFalse);
      expect(model.selectedAreaPaletteItems[0].isSelected, isTrue);
      expect(model.selectedAreaPaletteItems[1].elementId, 'missing_bush');
      expect(model.selectedAreaPaletteItems[1].elementName, isNull);
      expect(model.selectedAreaPaletteItems[1].hasMissingElement, isTrue);
      expect(model.canAddGeneratedPlacement, isTrue);
    });

    test('désactive l’ajout individuel si tous les éléments sont manquants',
        () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(
          environmentPresets: [
            EnvironmentPreset(
              id: 'forest',
              name: 'Forêt',
              templateId: 'forest',
              palette: [
                EnvironmentPaletteItem(elementId: 'missing_tree', weight: 1),
              ],
              defaultParams: EnvironmentGenerationParams(
                density: 1,
                variation: 0,
                edgeDensity: 1,
                minSpacingCells: 0,
              ),
              sortOrder: 0,
            ),
          ],
        ),
        map: _map(
          areas: [
            _area(
              activeCells: 1,
              generatedPlacementIds: const ['g1'],
            ),
          ],
        ),
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area1',
      );

      expect(model.selectedAreaPaletteItems, hasLength(1));
      expect(model.selectedAreaPaletteItems.single.hasMissingElement, isTrue);
      expect(model.canAddGeneratedPlacement, isFalse);
    });

    test('retourne un état neutre pour un layer non TileLayer', () {
      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: _manifest(),
        map: _map(
          extraLayers: const [
            MapLayer.collision(id: 'collision', name: 'Collision'),
          ],
        ),
        selectedLayerId: 'collision',
        selectedEnvironmentAreaId: null,
      );

      expect(model.state, TileLayerEnvironmentAttachmentState.unsupportedLayer);
      expect(
          model.selectedLayerKind, TileLayerEnvironmentSelectedLayerKind.other);
      expect(model.emptyStateMessage,
          'Sélectionnez un TileLayer pour utiliser une brush d’environnement.');
      expect(model.canEnableEnvironment, isFalse);
    });
  });
}

ProjectManifest _manifest({
  List<EnvironmentPreset>? environmentPresets,
  EnvironmentGenerationParams? defaultParams,
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: const [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'nature',
        categoryId: 'trees',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    environmentPresets: environmentPresets ??
        [
          EnvironmentPreset(
            id: 'forest',
            name: 'Forêt',
            templateId: 'forest',
            palette: [
              EnvironmentPaletteItem(elementId: 'tree', weight: 1),
            ],
            defaultParams: defaultParams ??
                EnvironmentGenerationParams(
                  density: 1,
                  variation: 0,
                  edgeDensity: 1,
                  minSpacingCells: 0,
                ),
            sortOrder: 0,
          ),
        ],
  );
}

MapData _map({
  List<EnvironmentArea>? areas,
  String? environmentTargetLayerId = 'tiles',
  List<MapLayer> extraLayers = const [],
  List<MapPlacedElement> placedElements = const [],
}) {
  final layers = <MapLayer>[
    const TileLayer(
      id: 'tiles',
      name: 'Ground',
      tilesetId: 'nature',
      tiles: [0, 0, 0, 0],
    ),
  ];
  if (areas != null || environmentTargetLayerId != 'tiles') {
    layers.add(
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: environmentTargetLayerId,
          areas: areas ?? const [],
        ),
      ),
    );
  }
  layers.addAll(extraLayers);
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 2, height: 2),
    layers: layers,
    placedElements: placedElements,
  );
}

EnvironmentArea _area({
  String id = 'area1',
  String presetId = 'forest',
  int activeCells = 0,
  int seed = 1,
  EnvironmentGenerationParams? paramsOverride,
  List<String> generatedPlacementIds = const [],
}) {
  final cells = List<bool>.filled(4, false);
  for (var i = 0; i < activeCells && i < cells.length; i++) {
    cells[i] = true;
  }
  return EnvironmentArea(
    id: id,
    name: 'Zone $id',
    presetId: presetId,
    mask: EnvironmentAreaMask(width: 2, height: 2, cells: cells),
    seed: seed,
    paramsOverride: paramsOverride,
    generatedPlacementIds: generatedPlacementIds,
  );
}

EnvironmentGenerationParams _params({
  required double density,
  required double variation,
  required double edgeDensity,
  required int minSpacingCells,
}) {
  return EnvironmentGenerationParams(
    density: density,
    variation: variation,
    edgeDensity: edgeDensity,
    minSpacingCells: minSpacingCells,
  );
}
