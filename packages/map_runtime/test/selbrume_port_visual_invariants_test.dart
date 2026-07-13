import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../tool/selbrume_port_visual_capture_test.dart' as visual;

const Set<String> _mutableVisualLayerIds = <String>{
  'l_tile_port_ref_ground',
  'l_tile_port_ref_backdrop',
  'l_tile_port_ref_overhead',
  'l_tile_port_ref_structures',
};

const Set<String> _baselinePlacedElementIds = <String>{
  'env_gen_env_port_ref_clusters_12_0_el_port_ref_forest_cluster',
  'env_gen_env_port_ref_clusters_31_0_el_port_ref_forest_cluster',
  'env_gen_env_port_ref_clusters_34_0_el_port_ref_forest_cluster',
  'env_gen_env_port_ref_clusters_5_0_el_port_ref_forest_cluster',
  'env_gen_env_port_ref_east_trees_40_12_el_port_ref_tree',
  'env_gen_env_port_ref_east_trees_40_16_el_port_ref_tree',
  'env_gen_env_port_ref_east_trees_40_4_el_port_ref_tree',
  'env_gen_env_port_ref_east_trees_40_8_el_port_ref_tree',
  'env_gen_env_port_ref_north_trees_18_0_el_port_ref_tree',
  'env_gen_env_port_ref_north_trees_21_0_el_port_ref_tree',
  'env_gen_env_port_ref_north_trees_40_0_el_port_ref_tree',
  'pe_port_barrel_buoy_center',
  'pe_port_barrel_buoy_east',
  'pe_port_bateau',
  'pe_port_bench_east',
  'pe_port_boat_medium',
  'pe_port_boat_small',
  'pe_port_capitainerie',
  'pe_port_coast_east',
  'pe_port_coast_west',
  'pe_port_fish_basket_east',
  'pe_port_fish_basket_west',
  'pe_port_fish_crates_pier',
  'pe_port_fish_crates_west',
  'pe_port_flower_bed',
  'pe_port_foam_cluster_south',
  'pe_port_foam_quay_center',
  'pe_port_foam_quay_east',
  'pe_port_foam_quay_west',
  'pe_port_foam_wake_large',
  'pe_port_foam_wake_medium',
  'pe_port_foam_wake_small',
  'pe_port_garden_backdrop_captain_east',
  'pe_port_garden_backdrop_captain_west',
  'pe_port_garden_backdrop_east_blue',
  'pe_port_garden_backdrop_east_orange',
  'pe_port_garden_backdrop_west',
  'pe_port_garden_east',
  'pe_port_hangar',
  'pe_port_house_blue',
  'pe_port_house_east',
  'pe_port_house_west',
  'pe_port_lamp_18_12',
  'pe_port_lamp_21_8',
  'pe_port_lamp_26_8',
  'pe_port_lamp_42_9',
  'pe_port_lobster_pots_center',
  'pe_port_lobster_pots_pier',
  'pe_port_market',
  'pe_port_net_rack_east',
  'pe_port_net_rack_west',
  'pe_port_nid_goelise',
  'pe_port_pier_center',
  'pe_port_pier_east',
  'pe_port_pier_west',
  'pe_port_quay_17',
  'pe_port_quay_29',
  'pe_port_quay_5',
  'pe_port_quay_steps',
  'pe_port_rock_pair_south_center',
  'pe_port_rock_small_south_mid',
  'pe_port_rock_small_south_west',
  'pe_port_rock_trio_quay_transition',
  'pe_port_rock_trio_south_east',
  'pe_port_rocks_south_east',
  'pe_port_rope_coil_pier',
  'pe_port_rope_coil_west',
  'pe_port_sign_center',
};

const Set<String> _baselinePortProjectElementIds = <String>{
  'el_port_ref_barrel_buoy_small',
  'el_port_ref_bench',
  'el_port_ref_boat_large',
  'el_port_ref_boat_medium',
  'el_port_ref_boat_small',
  'el_port_ref_chandlery',
  'el_port_ref_coast_east_peninsula',
  'el_port_ref_coast_west_continuous',
  'el_port_ref_fish_basket_small',
  'el_port_ref_fish_crates_small',
  'el_port_ref_fish_market',
  'el_port_ref_flower_bed',
  'el_port_ref_foam_boat_wake',
  'el_port_ref_foam_quay_horizontal',
  'el_port_ref_foam_rock_cluster',
  'el_port_ref_forest_cluster',
  'el_port_ref_harbor_master',
  'el_port_ref_house_blue',
  'el_port_ref_house_orange',
  'el_port_ref_lamp',
  'el_port_ref_lobster_pots_small',
  'el_port_ref_nest',
  'el_port_ref_net_rack_small',
  'el_port_ref_pier_t',
  'el_port_ref_pier_vertical',
  'el_port_ref_quay_horizontal',
  'el_port_ref_quay_steps',
  'el_port_ref_rock_cluster',
  'el_port_ref_rock_pair',
  'el_port_ref_rock_small',
  'el_port_ref_rock_trio',
  'el_port_ref_rope_coil_small',
  'el_port_ref_sign_small',
  'el_port_ref_tree',
  'el_port_ref_walled_garden',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Selbrume Port visual-only invariants', () {
    late visual.PortVisualScene scene;

    setUpAll(() async {
      scene = await visual.loadPortVisualScene();
    });

    test('keeps the four mutable TileLayer visual contracts', () {
      final map = scene.bundle.map;
      expect(map.id, visual.kPortVisualMapId);
      expect(map.size, const GridSize(width: 45, height: 34));
      expect(
        map.layers.every(
          (layer) =>
              layer is TerrainLayer || layer is PathLayer || layer is TileLayer,
        ),
        isTrue,
        reason: 'The QA projection may contain visual layer types only.',
      );

      final tileLayers = <String, TileLayer>{
        for (final layer in map.layers.whereType<TileLayer>()) layer.id: layer,
      };
      expect(tileLayers.keys, containsAll(_mutableVisualLayerIds));
      for (final layerId in _mutableVisualLayerIds) {
        final layer = tileLayers[layerId]!;
        expect(layer.tiles, hasLength(map.size.width * map.size.height));
        expect(layer.tilesetId, 'ts_selbrume_port_reference_v3');
      }
    });

    test('does not introduce MapPlacedElement or ProjectElement IDs', () {
      final placedIds =
          scene.bundle.map.placedElements.map((placed) => placed.id).toSet();
      expect(placedIds.difference(_baselinePlacedElementIds), isEmpty);
      expect(
        placedIds.any((id) => id.startsWith('pe_port_visual_')),
        isFalse,
      );

      final portProjectElementIds = scene.bundle.manifest.elements
          .where((element) => element.id.startsWith('el_port_'))
          .map((element) => element.id)
          .toSet();
      expect(portProjectElementIds, _baselinePortProjectElementIds);
    });

    test('keeps tile modules and placed visual frames within bounds', () {
      final map = scene.bundle.map;
      final tileSize = scene.bundle.manifest.settings.tileWidth;
      final elementById = <String, ProjectElementEntry>{
        for (final element in scene.bundle.manifest.elements)
          element.id: element,
      };

      for (final layer in map.layers.whereType<TileLayer>()) {
        final tilesetId = (layer.tilesetId ?? map.tilesetId).trim();
        if (tilesetId.isEmpty) continue;
        final image = scene.tileImagesByTilesetId[tilesetId];
        expect(image, isNotNull, reason: 'Missing visual tileset $tilesetId');
        final columns = image!.width ~/ tileSize;
        final rows = image.height ~/ tileSize;
        expect(columns, greaterThan(0));
        expect(rows, greaterThan(0));
        final maximumTileId = columns * rows;
        for (final tileId in layer.tiles) {
          expect(tileId, inInclusiveRange(0, maximumTileId));
        }
      }

      for (final placed in map.placedElements) {
        final element = elementById[placed.elementId];
        expect(element, isNotNull,
            reason: 'Unknown visual element ${placed.elementId}');
        final primary = element!.frames.primarySource;
        expect(placed.pos.x, greaterThanOrEqualTo(0));
        expect(placed.pos.y, greaterThanOrEqualTo(0));
        expect(placed.pos.x + primary.width, lessThanOrEqualTo(map.size.width));
        expect(
          placed.pos.y + primary.height,
          lessThanOrEqualTo(map.size.height),
        );

        for (final frame in element.frames) {
          final tilesetId = frame.tilesetId.trim().isEmpty
              ? element.tilesetId.trim()
              : frame.tilesetId.trim();
          final image = scene.tileImagesByTilesetId[tilesetId];
          expect(image, isNotNull, reason: 'Missing frame tileset $tilesetId');
          final source = frame.source;
          expect(
            image!.containsSourceRect(
              ui.Rect.fromLTWH(
                (source.x * tileSize).toDouble(),
                (source.y * tileSize).toDouble(),
                (source.width * tileSize).toDouble(),
                (source.height * tileSize).toDouble(),
              ),
            ),
            isTrue,
            reason: 'Out-of-bounds frame for ${element.id}',
          );
        }
      }
    });

    test('renders a non-black continuous in-bounds map at 32 px per cell',
        () async {
      final image = await visual.renderPortVisualRegion(
        scene,
        visual.kPortVisualOverviewRegion,
      );
      expect((image.width, image.height), (1440, 1088));

      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(pixels, isNotNull);
      var nonBlackPixels = 0;
      for (var offset = 0; offset < pixels!.lengthInBytes; offset += 4) {
        if (pixels.getUint8(offset) != 0 ||
            pixels.getUint8(offset + 1) != 0 ||
            pixels.getUint8(offset + 2) != 0) {
          nonBlackPixels += 1;
        }
      }
      expect(nonBlackPixels, greaterThan(0));

      for (var y = 0; y < scene.bundle.map.size.height; y += 1) {
        for (var x = 0; x < scene.bundle.map.size.width; x += 1) {
          final pixelX = x * visual.kPortVisualCellPixels +
              visual.kPortVisualCellPixels ~/ 2;
          final pixelY = y * visual.kPortVisualCellPixels +
              visual.kPortVisualCellPixels ~/ 2;
          final alphaOffset = (pixelY * image.width + pixelX) * 4 + 3;
          expect(
            pixels.getUint8(alphaOffset),
            greaterThan(0),
            reason: 'Transparent visual gap at cell ($x,$y)',
          );
        }
      }
    });

    test('renders every review crop without transparent capture gaps',
        () async {
      for (final region in visual.kPortVisualReviewRegions) {
        final image = await visual.renderPortVisualRegion(scene, region);
        final pixels =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(pixels, isNotNull, reason: region.id);
        var transparentPixelCount = 0;
        for (var offset = 3; offset < pixels!.lengthInBytes; offset += 4) {
          if (pixels.getUint8(offset) == 0) transparentPixelCount += 1;
        }
        expect(
          transparentPixelCount,
          0,
          reason: '${region.id} must not expose the transparent canvas',
        );
      }
    });
  });
}
