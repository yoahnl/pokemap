import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart';
import 'package:path/path.dart' as p;

import 'support/selbrume_map_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('port render paints registered placements and planned landmarks',
      () async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_port_brisants',
    );
    expect(bundle.map.placedElements, isNotEmpty);
    final placedById = <String, MapPlacedElement>{
      for (final placed in bundle.map.placedElements) placed.id: placed,
    };
    expect(placedById['pe_port_bateau']?.pos, const GridPos(x: 0, y: 21));
    expect(placedById['pe_port_hangar']?.pos, const GridPos(x: 31, y: 11));
    expect(placedById['pe_port_nid_goelise']?.pos, const GridPos(x: 7, y: 9));
    expect(
      bundle.map.placedElements.map((placed) => placed.elementId),
      containsAll(<String>[
        'el_port_ref_boat_large',
        'el_port_ref_boat_medium',
        'el_port_ref_harbor_master',
        'el_port_ref_fish_crates_small',
        'el_port_ref_nest',
      ]),
    );

    final tileImages = await _loadTilesetsForRender(bundle);
    expect(
      tileImages.keys,
      containsAll(<String>[
        'ts_selbrume_port_reference_v3',
        'ts_selbrume_port_ground_v3',
        'ts_selbrume_port_water_v3',
      ]),
    );
    final image = await _renderOverview(
      MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth: (bundle.map.size.width * bundle.cellWidth).round(),
      worldHeight: (bundle.map.size.height * bundle.cellHeight).round(),
    );
    expect((image.width, image.height), (320, 240));
    expect(await _containsNonBlackPixel(image), isTrue);
  });

  test('bourg render paints the four canonical landmarks and seed atlases',
      () async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_bourg_selbrume',
    );
    final placedById = <String, MapPlacedElement>{
      for (final placed in bundle.map.placedElements) placed.id: placed,
    };
    expect(
      placedById['pe_bourg_maison_joueur_facade']?.elementId,
      'selbrum_maison_1',
    );
    expect(
      placedById['pe_bourg_centre_facade']?.elementId,
      'selbrume_centre_pok_mon',
    );
    expect(placedById['pe_bourg_puits']?.elementId, 'le_puits');
    expect(placedById['pe_bourg_kiosque']?.elementId, 'kiosque_l_gumes');
    expect(
      placedById['pe_bourg_maison_joueur_facade']?.pos,
      const GridPos(x: 10, y: 18),
    );
    expect(
      placedById['pe_bourg_centre_facade']?.pos,
      const GridPos(x: 29, y: 22),
    );
    expect(
      placedById['pe_bourg_puits']?.pos,
      const GridPos(x: 23, y: 27),
    );
    expect(
      placedById['pe_bourg_kiosque']?.pos,
      const GridPos(x: 36, y: 35),
    );

    final tileImages = await _loadTilesetsForRender(bundle);
    expect(
      tileImages.keys,
      containsAll(<String>[
        'arbre_pixellab',
        'selbrume_all_sprite',
      ]),
    );
    final image = await _renderOverview(
      MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth: (bundle.map.size.width * bundle.cellWidth).round(),
      worldHeight: (bundle.map.size.height * bundle.cellHeight).round(),
    );
    expect((image.width, image.height), (320, 240));
    expect(await _containsNonBlackPixel(image), isTrue);
  });

  test('maison_joueur render paints the interior atlas and landmarks',
      () async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_maison_joueur',
    );
    final placedById = <String, MapPlacedElement>{
      for (final placed in bundle.map.placedElements) placed.id: placed,
    };
    expect(placedById['pe_maison_lit']?.elementId, 'el_selbrume_maison_lit');
    expect(
      placedById['pe_maison_bureau']?.elementId,
      'el_selbrume_maison_bureau',
    );
    expect(
      placedById['pe_maison_tapis']?.elementId,
      'el_selbrume_maison_tapis',
    );
    expect(
      placedById['pe_maison_etagere']?.elementId,
      'el_selbrume_cabane_etagere',
    );
    expect(
      placedById['pe_maison_porte']?.elementId,
      'el_selbrume_cabane_porte_principale',
    );
    expect(
      bundle.map.placedElements.map((placed) => placed.elementId),
      containsAll(<String>[
        'el_selbrume_cabane_sol_bois',
        'el_selbrume_cabane_mur_n',
        'el_selbrume_cabane_mur_cote',
      ]),
    );
    expect(
      bundle.map.placedElements.map((placed) => placed.layerId).toSet(),
      <String>{
        'l_tile_floor',
        'l_tile_walls',
        'l_tile_furniture',
        'l_tile_overhead',
      },
      reason: 'The opt-in bottom-to-top order keeps semantic layers visible.',
    );

    final tileImages = await _loadTilesetsForRender(bundle);
    expect(tileImages.keys, contains('ts_selbrume_cabin_interior'));
    final image = await _renderOverview(
      MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth: (bundle.map.size.width * bundle.cellWidth).round(),
      worldHeight: (bundle.map.size.height * bundle.cellHeight).round(),
    );
    expect((image.width, image.height), (320, 240));
    expect(await _containsNonBlackPixel(image), isTrue);
  });

  test('cabane_gardien renders the closed state and hides journal reserve',
      () async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_cabane_gardien',
    );
    final placedById = <String, MapPlacedElement>{
      for (final placed in bundle.map.placedElements) placed.id: placed,
    };
    expect(
      placedById['pe_cabane_table']?.elementId,
      'el_selbrume_cabane_table_carnet_ferme',
    );
    expect(placedById['pe_cabane_table']?.opacity, 1);
    expect(
      placedById['pe_cabane_journal']?.elementId,
      'el_selbrume_cabane_table_carnet_ouvert',
    );
    expect(placedById['pe_cabane_journal']?.opacity, 0);
    expect(
      placedById['pe_cabane_porte_secondaire']?.elementId,
      'el_selbrume_cabane_porte_secondaire_fermee',
    );
    expect(
      bundle.map.placedElements.map((placed) => placed.elementId),
      containsAll(<String>[
        'el_selbrume_cabane_sol_bois',
        'el_selbrume_cabane_mur_n',
        'el_selbrume_cabane_mur_cote',
        'el_selbrume_cabane_lit',
        'el_selbrume_cabane_poele',
        'el_selbrume_cabane_etagere',
        'el_selbrume_cabane_coffre',
        'el_selbrume_cabane_carte',
        'el_selbrume_cabane_cle',
        'el_selbrume_cabane_outils',
        'el_selbrume_cabane_lanterne',
        'el_selbrume_cabane_chaise',
        'el_selbrume_cabane_porte_principale',
      ]),
    );

    final tileImages = await _loadTilesetsForRender(bundle);
    expect(tileImages.keys, contains('ts_selbrume_cabin_interior'));
    expect(
      resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      ),
      isEmpty,
    );
    final image = await _renderOverview(
      MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth: (bundle.map.size.width * bundle.cellWidth).round(),
      worldHeight: (bundle.map.size.height * bundle.cellHeight).round(),
    );
    expect((image.width, image.height), (320, 240));
    expect(await _containsNonBlackPixel(image), isTrue);

    final withoutJournal = RuntimeMapBundle(
      manifest: bundle.manifest,
      map: bundle.map.copyWith(
        placedElements: <MapPlacedElement>[
          for (final placed in bundle.map.placedElements)
            if (placed.id != 'pe_cabane_journal') placed,
        ],
      ),
      projectRootDirectory: bundle.projectRootDirectory,
      tilesetAbsolutePathsById: bundle.tilesetAbsolutePathsById,
    );
    final withoutJournalImage = await _renderOverview(
      MapLayersComponent(
        bundle: withoutJournal,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth:
          (withoutJournal.map.size.width * withoutJournal.cellWidth).round(),
      worldHeight:
          (withoutJournal.map.size.height * withoutJournal.cellHeight).round(),
    );
    expect(
      await _imagesDiffer(image, withoutJournalImage),
      isFalse,
      reason: 'The reserved open-journal state must not paint any pixels.',
    );

    final withoutPlacements = RuntimeMapBundle(
      manifest: bundle.manifest,
      map: bundle.map.copyWith(placedElements: const <MapPlacedElement>[]),
      projectRootDirectory: bundle.projectRootDirectory,
      tilesetAbsolutePathsById: bundle.tilesetAbsolutePathsById,
    );
    final baseline = await _renderOverview(
      MapLayersComponent(
        bundle: withoutPlacements,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth:
          (withoutPlacements.map.size.width * withoutPlacements.cellWidth)
              .round(),
      worldHeight:
          (withoutPlacements.map.size.height * withoutPlacements.cellHeight)
              .round(),
    );
    expect(
      await _imagesDiffer(image, baseline),
      isTrue,
      reason: 'Keeper-cabin placements must change the rendered map pixels.',
    );
  });

  test('bois render paints forest atlas landmarks and fog composition',
      () async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_bois_chaise_brume',
    );
    expect(bundle.map.mapMetadata.weather, MapWeather.fog);
    final placedById = <String, MapPlacedElement>{
      for (final placed in bundle.map.placedElements) placed.id: placed,
    };
    expect(
      placedById['pe_bois_pin_grand_001']?.elementId,
      'el_selbrume_bois_pin_grand',
    );
    expect(
      placedById['pe_bois_tronc_tombe_001']?.elementId,
      'el_selbrume_bois_tronc_tombe',
    );
    expect(
      placedById['pe_bois_panneau_001']?.elementId,
      'el_selbrume_bois_panneau',
    );
    expect(
      bundle.map.placedElements.map((placed) => placed.elementId),
      containsAll(<String>[
        'el_selbrume_bois_pin_grand',
        'el_selbrume_bois_pin_moyen',
        'el_selbrume_bois_pin_petit',
        'el_selbrume_bois_buisson_1',
        'el_selbrume_bois_buisson_2',
        'el_selbrume_bois_fougere',
        'el_selbrume_bois_souche',
        'el_selbrume_bois_tronc_tombe',
        'el_selbrume_bois_ronces',
        'el_selbrume_bois_aiguilles_sol',
        'el_selbrume_bois_banc',
        'el_selbrume_bois_panneau',
      ]),
    );

    final tileImages = await _loadTilesetsForRender(bundle);
    expect(tileImages.keys, contains('ts_selbrume_forest_props'));
    final occlusionInstructions =
        resolveStaticPlacedElementOcclusionPatchInstructions(
      bundle: bundle,
      originCellX: 0,
      originCellY: 0,
    );
    expect(
      occlusionInstructions.map((instruction) => instruction.placedElementId),
      unorderedEquals(<String>[
        'pe_bois_pin_grand_001',
        'pe_bois_pin_moyen_001',
        'pe_bois_pin_petit_001',
      ]),
    );
    final image = await _renderOverview(
      MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth: (bundle.map.size.width * bundle.cellWidth).round(),
      worldHeight: (bundle.map.size.height * bundle.cellHeight).round(),
    );
    expect((image.width, image.height), (320, 240));
    expect(await _containsNonBlackPixel(image), isTrue);
    final withoutPlacements = RuntimeMapBundle(
      manifest: bundle.manifest,
      map: bundle.map.copyWith(placedElements: const <MapPlacedElement>[]),
      projectRootDirectory: bundle.projectRootDirectory,
      tilesetAbsolutePathsById: bundle.tilesetAbsolutePathsById,
    );
    final baseline = await _renderOverview(
      MapLayersComponent(
        bundle: withoutPlacements,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth:
          (withoutPlacements.map.size.width * withoutPlacements.cellWidth)
              .round(),
      worldHeight:
          (withoutPlacements.map.size.height * withoutPlacements.cellHeight)
              .round(),
    );
    expect(
      await _imagesDiffer(image, baseline),
      isTrue,
      reason: 'Forest placements must change the rendered map pixels.',
    );
  });

  test('marais render paints landmarks and cabin occlusion', () async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_marais_salants',
    );
    final placedById = <String, MapPlacedElement>{
      for (final placed in bundle.map.placedElements) placed.id: placed,
    };
    expect(
      placedById['pe_marais_cabane_paludier']?.elementId,
      'el_selbrume_marais_cabane_paludier',
    );
    expect(
      placedById['pe_marais_ecluse']?.elementId,
      'el_selbrume_marais_ecluse_fermee',
    );
    expect(
      placedById['pe_marais_indice_verre']?.elementId,
      'el_selbrume_indice_verre',
    );
    expect(
      bundle.map.placedElements.map((placed) => placed.elementId),
      containsAll(<String>[
        'el_selbrume_marais_passerelle_h',
        'el_selbrume_marais_passerelle_v',
        'el_selbrume_marais_passerelle_angle',
        'el_selbrume_marais_passerelle_t',
        'el_selbrume_marais_roseaux_1',
        'el_selbrume_marais_sel_grand',
        'el_selbrume_marais_rateau',
        'el_selbrume_cristal_3',
      ]),
    );

    final tileImages = await _loadTilesetsForRender(bundle);
    expect(tileImages.keys, contains('ts_selbrume_marsh_props'));
    final occlusionInstructions =
        resolveStaticPlacedElementOcclusionPatchInstructions(
      bundle: bundle,
      originCellX: 0,
      originCellY: 0,
    );
    expect(
      occlusionInstructions.map((instruction) => instruction.placedElementId),
      <String>['pe_marais_cabane_paludier'],
    );
    final image = await _renderOverview(
      MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth: (bundle.map.size.width * bundle.cellWidth).round(),
      worldHeight: (bundle.map.size.height * bundle.cellHeight).round(),
    );
    expect((image.width, image.height), (320, 240));
    expect(await _containsNonBlackPixel(image), isTrue);

    final withoutPlacements = RuntimeMapBundle(
      manifest: bundle.manifest,
      map: bundle.map.copyWith(placedElements: const <MapPlacedElement>[]),
      projectRootDirectory: bundle.projectRootDirectory,
      tilesetAbsolutePathsById: bundle.tilesetAbsolutePathsById,
    );
    final baseline = await _renderOverview(
      MapLayersComponent(
        bundle: withoutPlacements,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth:
          (withoutPlacements.map.size.width * withoutPlacements.cellWidth)
              .round(),
      worldHeight:
          (withoutPlacements.map.size.height * withoutPlacements.cellHeight)
              .round(),
    );
    expect(
      await _imagesDiffer(image, baseline),
      isTrue,
      reason: 'Marsh placements must change the rendered map pixels.',
    );
  });

  test('passage render paints causeway props without false occlusion',
      () async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_passage_dames',
    );
    final placedById = <String, MapPlacedElement>{
      for (final placed in bundle.map.placedElements) placed.id: placed,
    };
    expect(
      placedById['pe_passage_barriere']?.elementId,
      'el_selbrume_passage_barriere_fermee',
    );
    expect(
      placedById['pe_passage_marches']?.elementId,
      'el_selbrume_passage_marches',
    );
    expect(
      placedById['pe_passage_banc_brume']?.elementId,
      'el_selbrume_passage_banc_brume',
    );
    expect(
      bundle.map.placedElements.map((placed) => placed.elementId),
      containsAll(<String>[
        'el_selbrume_passage_chaussee_humide',
        'el_selbrume_passage_chaussee_seche',
        'el_selbrume_passage_ecume_h',
        'el_selbrume_passage_ecume_v',
        'el_selbrume_passage_flaques',
        'el_selbrume_passage_algues',
        'el_selbrume_passage_balanes',
        'el_selbrume_passage_bois_flotte',
      ]),
    );

    final tileImages = await _loadTilesetsForRender(bundle);
    expect(tileImages.keys, contains('ts_selbrume_passage_props'));
    expect(
      resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      ),
      isEmpty,
    );
    final image = await _renderOverview(
      MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth: (bundle.map.size.width * bundle.cellWidth).round(),
      worldHeight: (bundle.map.size.height * bundle.cellHeight).round(),
    );
    expect((image.width, image.height), (320, 240));
    expect(await _containsNonBlackPixel(image), isTrue);
    final withoutPlacements = RuntimeMapBundle(
      manifest: bundle.manifest,
      map: bundle.map.copyWith(placedElements: const <MapPlacedElement>[]),
      projectRootDirectory: bundle.projectRootDirectory,
      tilesetAbsolutePathsById: bundle.tilesetAbsolutePathsById,
    );
    final baseline = await _renderOverview(
      MapLayersComponent(
        bundle: withoutPlacements,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth:
          (withoutPlacements.map.size.width * withoutPlacements.cellWidth)
              .round(),
      worldHeight:
          (withoutPlacements.map.size.height * withoutPlacements.cellHeight)
              .round(),
    );
    expect(
      await _imagesDiffer(image, baseline),
      isTrue,
      reason: 'Passage placements must change the rendered map pixels.',
    );
  });

  test('phare_exterieur render paints both landmarks and occlusion', () async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_phare_exterieur',
    );
    final placedById = <String, MapPlacedElement>{
      for (final placed in bundle.map.placedElements) placed.id: placed,
    };
    expect(
      placedById['pe_phare_batiment']?.elementId,
      'el_selbrume_phare_batiment',
    );
    expect(
      placedById['pe_phare_cabane_facade']?.elementId,
      'el_selbrume_cabane_facade',
    );
    expect(
      placedById['pe_phare_porte_ouverte']?.elementId,
      'el_selbrume_phare_porte_ouverte',
    );
    expect(
      placedById['pe_phare_cabane_porte_ouverte']?.elementId,
      'el_selbrume_cabane_porte_ouverte',
    );

    final tileImages = await _loadTilesetsForRender(bundle);
    expect(tileImages.keys, contains('ts_selbrume_lighthouse_exterior'));
    final occlusionInstructions =
        resolveStaticPlacedElementOcclusionPatchInstructions(
      bundle: bundle,
      originCellX: 0,
      originCellY: 0,
    );
    expect(
      occlusionInstructions.map((instruction) => instruction.placedElementId),
      unorderedEquals(<String>[
        'pe_phare_batiment',
        'pe_phare_cabane_facade',
      ]),
    );
    final image = await _renderOverview(
      MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth: (bundle.map.size.width * bundle.cellWidth).round(),
      worldHeight: (bundle.map.size.height * bundle.cellHeight).round(),
    );
    expect((image.width, image.height), (320, 240));
    expect(await _containsNonBlackPixel(image), isTrue);

    final withoutPlacements = RuntimeMapBundle(
      manifest: bundle.manifest,
      map: bundle.map.copyWith(placedElements: const <MapPlacedElement>[]),
      projectRootDirectory: bundle.projectRootDirectory,
      tilesetAbsolutePathsById: bundle.tilesetAbsolutePathsById,
    );
    final baseline = await _renderOverview(
      MapLayersComponent(
        bundle: withoutPlacements,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth:
          (withoutPlacements.map.size.width * withoutPlacements.cellWidth)
              .round(),
      worldHeight:
          (withoutPlacements.map.size.height * withoutPlacements.cellHeight)
              .round(),
    );
    expect(
      await _imagesDiffer(image, baseline),
      isTrue,
      reason: 'Lighthouse placements must change the rendered map pixels.',
    );
  });

  test('phare_interieur render paints the dungeon without false occlusion',
      () async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_phare_interieur',
    );
    final placedById = <String, MapPlacedElement>{
      for (final placed in bundle.map.placedElements) placed.id: placed,
    };
    expect(
      placedById['pe_phare_note_ancien_gardien']?.elementId,
      'el_selbrume_phare_bureau_note',
    );
    expect(
      placedById['pe_phare_mecanisme']?.elementId,
      'el_selbrume_phare_mecanisme',
    );
    expect(
      placedById['pe_phare_escalier_haut']?.elementId,
      'el_selbrume_phare_escalier_haut',
    );
    expect(
      placedById['pe_phare_escalier_bas']?.elementId,
      'el_selbrume_phare_escalier_bas',
    );

    final tileImages = await _loadTilesetsForRender(bundle);
    expect(tileImages.keys, contains('ts_selbrume_lighthouse_interior'));
    expect(
      resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      ),
      isEmpty,
    );
    final image = await _renderOverview(
      MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth: (bundle.map.size.width * bundle.cellWidth).round(),
      worldHeight: (bundle.map.size.height * bundle.cellHeight).round(),
    );
    expect((image.width, image.height), (320, 240));
    expect(await _containsNonBlackPixel(image), isTrue);

    final withoutPlacements = RuntimeMapBundle(
      manifest: bundle.manifest,
      map: bundle.map.copyWith(placedElements: const <MapPlacedElement>[]),
      projectRootDirectory: bundle.projectRootDirectory,
      tilesetAbsolutePathsById: bundle.tilesetAbsolutePathsById,
    );
    final baseline = await _renderOverview(
      MapLayersComponent(
        bundle: withoutPlacements,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth:
          (withoutPlacements.map.size.width * withoutPlacements.cellWidth)
              .round(),
      worldHeight:
          (withoutPlacements.map.size.height * withoutPlacements.cellHeight)
              .round(),
    );
    expect(
      await _imagesDiffer(image, baseline),
      isTrue,
      reason: 'Lighthouse dungeon placements must change rendered pixels.',
    );
  });

  test('sommet render separates the passable off FX from structural art',
      () async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_sommet_phare',
    );
    final placedById = <String, MapPlacedElement>{
      for (final placed in bundle.map.placedElements) placed.id: placed,
    };
    expect(
      placedById['pe_sommet_plateforme']?.elementId,
      'el_selbrume_sommet_plateforme',
    );
    expect(
      placedById['pe_sommet_lanterne']?.elementId,
      'el_selbrume_sommet_lanterne',
    );
    expect(
      placedById['pe_sommet_lumiere_eteinte']?.elementId,
      'el_selbrume_fx_lumiere_eteinte',
    );
    expect(
      placedById['pe_sommet_lumiere_eteinte']?.layerId,
      'l_tile_fx',
    );
    expect(
      placedById['pe_sommet_lumiere_eteinte']?.applyCollision,
      isFalse,
    );

    final tileImages = await _loadTilesetsForRender(bundle);
    expect(
      tileImages.keys,
      containsAll(<String>[
        'ts_selbrume_lighthouse_interior',
        'ts_selbrume_lighthouse_fx',
      ]),
    );
    expect(
      resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      ),
      isEmpty,
    );
    final image = await _renderOverview(
      MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth: (bundle.map.size.width * bundle.cellWidth).round(),
      worldHeight: (bundle.map.size.height * bundle.cellHeight).round(),
    );
    expect((image.width, image.height), (320, 240));
    expect(await _containsNonBlackPixel(image), isTrue);

    final fxOnlyBundle = RuntimeMapBundle(
      manifest: bundle.manifest,
      map: bundle.map.copyWith(
        placedElements: <MapPlacedElement>[
          for (final placed in bundle.map.placedElements)
            if (placed.elementId.startsWith('el_selbrume_fx_')) placed,
        ],
      ),
      projectRootDirectory: bundle.projectRootDirectory,
      tilesetAbsolutePathsById: bundle.tilesetAbsolutePathsById,
    );
    final fxOnly = await _renderOverview(
      MapLayersComponent(
        bundle: fxOnlyBundle,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth:
          (fxOnlyBundle.map.size.width * fxOnlyBundle.cellWidth).round(),
      worldHeight:
          (fxOnlyBundle.map.size.height * fxOnlyBundle.cellHeight).round(),
    );

    final withoutPlacements = RuntimeMapBundle(
      manifest: bundle.manifest,
      map: bundle.map.copyWith(placedElements: const <MapPlacedElement>[]),
      projectRootDirectory: bundle.projectRootDirectory,
      tilesetAbsolutePathsById: bundle.tilesetAbsolutePathsById,
    );
    final baseline = await _renderOverview(
      MapLayersComponent(
        bundle: withoutPlacements,
        tileImagesByTilesetId: tileImages,
      ),
      worldWidth:
          (withoutPlacements.map.size.width * withoutPlacements.cellWidth)
              .round(),
      worldHeight:
          (withoutPlacements.map.size.height * withoutPlacements.cellHeight)
              .round(),
    );
    expect(
      await _imagesDiffer(image, baseline),
      isTrue,
      reason: 'Summit structural placements must change rendered pixels.',
    );
    expect(
      await _imagesDiffer(fxOnly, baseline),
      isTrue,
      reason: 'The passable initial off-state FX must render independently.',
    );
  });

  test(
    'renders every Selbrume beta map overview at 320x240 through MapLayersComponent',
    () async {
      for (final mapId in SelbrumeMapTestFixture.allBetaMapIds) {
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: SelbrumeMapTestFixture.projectFilePath,
          mapId: mapId,
        );
        final tileImages = await _loadTilesetsForRender(bundle);
        final layer = MapLayersComponent(
          bundle: bundle,
          tileImagesByTilesetId: tileImages,
        );
        final image = await _renderOverview(
          layer,
          worldWidth: (bundle.map.size.width * bundle.cellWidth).round(),
          worldHeight: (bundle.map.size.height * bundle.cellHeight).round(),
        );

        expect(image.width, 320, reason: '$mapId overview width drifted.');
        expect(image.height, 240, reason: '$mapId overview height drifted.');
        expect(
          await _containsNonBlackPixel(image),
          isTrue,
          reason: '$mapId rendered only the opaque black overview backdrop.',
        );
      }
    },
  );

  test(
    'fails before render when a referenced Selbrume tileset cannot be decoded',
    () async {
      final temp = Directory.systemTemp.createTempSync(
        'selbrume_render_decode_failure_',
      );
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });

      const manifest = ProjectManifest(
        name: 'Selbrume render decode failure',
        maps: <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map_temp_selbrume',
            name: 'Temporary Selbrume map',
            relativePath: 'maps/map_temp_selbrume.json',
          ),
        ],
        tilesets: <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'ts_selbrume_invalid_temp',
            name: 'Invalid temporary tileset',
            relativePath: 'assets/ts_selbrume_invalid_temp.png',
          ),
        ],
        settings: ProjectSettings(displayScale: 1),
      );
      const map = MapData(
        id: 'map_temp_selbrume',
        name: 'Temporary Selbrume map',
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          MapLayer.tile(
            id: 'ground',
            name: 'Ground',
            tilesetId: 'ts_selbrume_invalid_temp',
            tiles: <int>[0],
          ),
        ],
      );
      final projectFile = File(p.join(temp.path, 'project.json'));
      final mapFile = File(
        p.join(temp.path, 'maps', 'map_temp_selbrume.json'),
      );
      final invalidPng = File(
        p.join(temp.path, 'assets', 'ts_selbrume_invalid_temp.png'),
      );
      await mapFile.parent.create(recursive: true);
      await invalidPng.parent.create(recursive: true);
      await projectFile.writeAsString(jsonEncode(manifest.toJson()));
      await mapFile.writeAsString(jsonEncode(map.toJson()));
      await invalidPng.writeAsBytes(<int>[0x89, 0x50, 0x4e, 0x47, 0x00]);

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFile.path,
        mapId: map.id,
      );
      var renderHelperInvoked = false;

      await expectLater(
        () async {
          final tileImages = await _loadTilesetsForRender(bundle);
          renderHelperInvoked = true;
          await _renderOverview(
            MapLayersComponent(
              bundle: bundle,
              tileImagesByTilesetId: tileImages,
            ),
            worldWidth: bundle.cellWidth.round(),
            worldHeight: bundle.cellHeight.round(),
          );
        },
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(
              contains('ts_selbrume_invalid_temp'),
              contains('decode'),
            ),
          ),
        ),
      );
      expect(
        renderHelperInvoked,
        isFalse,
        reason: 'The overview renderer must not run after image decode fails.',
      );
    },
  );
}

Future<Map<String, RuntimeTilesetImage>> _loadTilesetsForRender(
  RuntimeMapBundle bundle,
) async {
  final transparentColors = <String, TilesetTransparentColor>{
    for (final tileset in bundle.manifest.tilesets)
      if (tileset.transparentColor != null)
        tileset.id: tileset.transparentColor!,
  };
  final loaded = <String, RuntimeTilesetImage>{};
  for (final entry in bundle.tilesetAbsolutePathsById.entries) {
    try {
      loaded.addAll(
        await loadTilesetImagesById(
          <String, String>{entry.key: entry.value},
          transparentColorByTilesetId: transparentColors,
        ),
      );
    } on Object catch (error) {
      throw StateError(
        'Failed to decode referenced Selbrume tileset ${entry.key} at '
        '${entry.value}: $error',
      );
    }
  }
  return loaded;
}

Future<ui.Image> _renderOverview(
  MapLayersComponent layer, {
  required int worldWidth,
  required int worldHeight,
  int viewportWidth = 320,
  int viewportHeight = 240,
}) {
  if (worldWidth <= 0 || worldHeight <= 0) {
    throw ArgumentError('Overview world dimensions must be positive.');
  }
  if (viewportWidth <= 0 || viewportHeight <= 0) {
    throw ArgumentError('Overview viewport dimensions must be positive.');
  }

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  // The opaque black baseline makes the smoke assertion independent of alpha
  // while still proving that the real layer paints at least one RGB pixel.
  canvas.drawRect(
    ui.Rect.fromLTWH(
      0,
      0,
      viewportWidth.toDouble(),
      viewportHeight.toDouble(),
    ),
    ui.Paint()..color = const ui.Color(0xff000000),
  );

  final scale = math.min(
    viewportWidth / worldWidth,
    viewportHeight / worldHeight,
  );
  final scaledWidth = worldWidth * scale;
  final scaledHeight = worldHeight * scale;
  final offsetX = (viewportWidth - scaledWidth) / 2;
  final offsetY = (viewportHeight - scaledHeight) / 2;

  // A single uniform scale preserves map aspect ratio; offsets letterbox and
  // center the full authored world instead of stretching it to the viewport.
  layer.update(0);
  canvas.save();
  canvas.translate(offsetX, offsetY);
  canvas.scale(scale, scale);
  layer.render(canvas);
  canvas.restore();

  return recorder.endRecording().toImage(viewportWidth, viewportHeight);
}

Future<bool> _containsNonBlackPixel(ui.Image image) async {
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (pixels == null) {
    throw StateError('Could not read overview pixels as raw RGBA.');
  }
  for (var offset = 0; offset < pixels.lengthInBytes; offset += 4) {
    if (pixels.getUint8(offset) != 0 ||
        pixels.getUint8(offset + 1) != 0 ||
        pixels.getUint8(offset + 2) != 0) {
      return true;
    }
  }
  return false;
}

Future<bool> _imagesDiffer(ui.Image left, ui.Image right) async {
  if (left.width != right.width || left.height != right.height) return true;
  final leftPixels = await left.toByteData(format: ui.ImageByteFormat.rawRgba);
  final rightPixels =
      await right.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (leftPixels == null || rightPixels == null) {
    throw StateError('Could not compare overview pixels as raw RGBA.');
  }
  if (leftPixels.lengthInBytes != rightPixels.lengthInBytes) return true;
  for (var offset = 0; offset < leftPixels.lengthInBytes; offset++) {
    if (leftPixels.getUint8(offset) != rightPixels.getUint8(offset)) {
      return true;
    }
  }
  return false;
}
