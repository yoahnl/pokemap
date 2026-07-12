import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

abstract final class SelbrumeMapTestFixture {
  static const String startMapId = 'map_bourg_selbrume';

  static const List<String> canonicalMapIds = <String>[
    startMapId,
    'map_port_brisants',
    'map_bois_chaise_brume',
    'map_marais_salants',
    'map_passage_dames',
    'map_phare_exterieur',
    'map_phare_interieur',
    'map_sommet_phare',
    'map_cabane_gardien',
  ];

  static const List<String> supportMapIds = <String>[
    'map_maison_joueur',
  ];

  static const List<String> allBetaMapIds = <String>[
    ...canonicalMapIds,
    ...supportMapIds,
  ];

  static const Map<String, GridSize> expectedDimensions = <String, GridSize>{
    'map_bourg_selbrume': GridSize(width: 55, height: 55),
    'map_port_brisants': GridSize(width: 45, height: 45),
    'map_bois_chaise_brume': GridSize(width: 45, height: 45),
    'map_marais_salants': GridSize(width: 45, height: 45),
    'map_passage_dames': GridSize(width: 60, height: 24),
    'map_phare_exterieur': GridSize(width: 45, height: 45),
    'map_phare_interieur': GridSize(width: 36, height: 45),
    'map_sommet_phare': GridSize(width: 24, height: 24),
    'map_cabane_gardien': GridSize(width: 20, height: 16),
    'map_maison_joueur': GridSize(width: 20, height: 16),
  };

  static const Set<String> allowedLegacyMapFileNames = <String>{
    'Selbrume.json',
    'route 1.json',
    'house 1.json',
    'house 2.json',
    'house 3.json',
    'house 4.json',
    'house 5.json',
    'lab.json',
    'pokémon center.json',
    'pub.json',
  };

  static const Map<String, List<String>> requiredZoneIdsByMap =
      <String, List<String>>{
    'map_maison_joueur': <String>['zone_player_house_exit'],
    'map_port_brisants': <String>['zone_port_entry', 'zone_port_center'],
    'map_bois_chaise_brume': <String>[
      'zone_bois_herbe_1',
      'zone_bois_herbe_2',
      'zone_bois_herbe_3',
      'zone_bois_herbe_4',
    ],
    'map_marais_salants': <String>['zone_marais_entry'],
    'map_passage_dames': <String>['zone_passage_entry'],
    'map_phare_exterieur': <String>['zone_lighthouse_entry'],
    'map_phare_interieur': <String>[
      'zone_lighthouse_floor_1',
      'zone_lighthouse_top_access',
    ],
    'map_sommet_phare': <String>['zone_lighthouse_top'],
  };

  static const Map<String, List<String>> requiredNarrativePlacedIdsByMap =
      <String, List<String>>{
    'map_port_brisants': <String>['pe_port_nid_goelise'],
    'map_marais_salants': <String>[
      'pe_marais_indice_verre',
      'pe_marais_indice_traces_electriques',
      'pe_marais_indice_repere_lentille',
      'pe_marais_cristal_1',
      'pe_marais_cristal_2',
      'pe_marais_cristal_3',
    ],
    'map_phare_interieur': <String>['pe_phare_note_ancien_gardien'],
    'map_cabane_gardien': <String>[
      'pe_cabane_journal',
      'pe_cabane_cle',
    ],
  };

  // This table is deliberately explicit: legacy landmarks keep their existing
  // element IDs while new beta landmarks use the new element families. A
  // prefix heuristic would silently accept the wrong legacy/new migration.
  static const Map<String, Map<String, Set<String>>>
      allowedElementIdsByLandmarkByMap = <String, Map<String, Set<String>>>{
    'map_bourg_selbrume': <String, Set<String>>{
      'pe_bourg_centre_facade': <String>{'selbrume_centre_pok_mon'},
      'pe_bourg_puits': <String>{'le_puits'},
      'pe_bourg_kiosque': <String>{'kiosque_l_gumes'},
      'pe_bourg_maison_joueur_facade': <String>{'selbrum_maison_1'},
    },
    'map_port_brisants': <String, Set<String>>{
      'pe_port_bateau': <String>{'el_selbrume_port_bateau'},
      'pe_port_hangar': <String>{'el_selbrume_port_hangar'},
      'pe_port_nid_goelise': <String>{
        'el_selbrume_port_nid_vide',
        'el_selbrume_port_nid_brillant',
      },
    },
    'map_bois_chaise_brume': <String, Set<String>>{
      'pe_bois_pin_grand_001': <String>{'el_selbrume_bois_pin_grand'},
      'pe_bois_tronc_tombe_001': <String>{
        'el_selbrume_bois_tronc_tombe',
      },
      'pe_bois_panneau_001': <String>{'el_selbrume_bois_panneau'},
    },
    'map_marais_salants': <String, Set<String>>{
      'pe_marais_cabane_paludier': <String>{
        'el_selbrume_marais_cabane_paludier',
      },
      'pe_marais_ecluse': <String>{
        'el_selbrume_marais_ecluse_fermee',
        'el_selbrume_marais_ecluse_ouverte',
      },
      'pe_marais_indice_verre': <String>{'el_selbrume_indice_verre'},
    },
    'map_passage_dames': <String, Set<String>>{
      'pe_passage_barriere': <String>{
        'el_selbrume_passage_barriere_fermee',
        'el_selbrume_passage_barriere_ouverte',
      },
      'pe_passage_marches': <String>{'el_selbrume_passage_marches'},
    },
    'map_phare_exterieur': <String, Set<String>>{
      'pe_phare_batiment': <String>{'el_selbrume_phare_batiment'},
      'pe_phare_cabane_facade': <String>{'el_selbrume_cabane_facade'},
    },
    'map_phare_interieur': <String, Set<String>>{
      'pe_phare_mecanisme': <String>{'el_selbrume_phare_mecanisme'},
      'pe_phare_note_ancien_gardien': <String>{
        'el_selbrume_phare_bureau_note',
      },
    },
    'map_sommet_phare': <String, Set<String>>{
      'pe_sommet_plateforme': <String>{'el_selbrume_sommet_plateforme'},
      'pe_sommet_lanterne': <String>{'el_selbrume_sommet_lanterne'},
      'pe_sommet_lumiere_eteinte': <String>{
        'el_selbrume_fx_lumiere_eteinte',
      },
    },
    'map_cabane_gardien': <String, Set<String>>{
      'pe_cabane_table': <String>{
        'el_selbrume_cabane_table_carnet_ferme',
        'el_selbrume_cabane_table_carnet_ouvert',
      },
      'pe_cabane_journal': <String>{
        'el_selbrume_cabane_table_carnet_ferme',
        'el_selbrume_cabane_table_carnet_ouvert',
      },
      'pe_cabane_porte_secondaire': <String>{
        'el_selbrume_cabane_porte_secondaire_fermee',
        'el_selbrume_cabane_porte_secondaire_ouverte',
      },
    },
    'map_maison_joueur': <String, Set<String>>{
      'pe_maison_lit': <String>{'el_selbrume_maison_lit'},
      'pe_maison_bureau': <String>{'el_selbrume_maison_bureau'},
      'pe_maison_tapis': <String>{'el_selbrume_maison_tapis'},
    },
  };

  // Only these planned outputs receive the new PNG/RGBA/32-pixel-grid rules.
  // Historical Selbrume JPG/RGB/prefixed sources are intentionally excluded.
  static const Set<String> requiredNewTilesetIds = <String>{
    'ts_selbrume_boat',
    'ts_selbrume_open_sea_loop',
    'ts_selbrume_port_props',
    'ts_selbrume_forest_props',
    'ts_selbrume_marsh_props',
    'ts_selbrume_passage_props',
    'ts_selbrume_lighthouse_exterior',
    'ts_selbrume_lighthouse_interior',
    'ts_selbrume_cabin_interior',
    'ts_selbrume_lighthouse_fx',
  };

  static Directory findRepositoryRoot({Directory? from}) {
    final override = Platform.environment['POKEMAP_REPO_ROOT']?.trim();
    if (override != null && override.isNotEmpty) {
      final root = Directory(p.normalize(p.absolute(override)));
      if (_looksLikeRepositoryRoot(root)) {
        return root;
      }
      throw StateError(
        'POKEMAP_REPO_ROOT does not contain selbrume/project.json: '
        '${root.path}',
      );
    }

    var current = (from ?? Directory.current).absolute;
    while (true) {
      if (_looksLikeRepositoryRoot(current)) {
        return current;
      }
      final parent = current.parent.absolute;
      if (parent.path == current.path) {
        throw StateError(
          'Could not locate repository root from ${Directory.current.path}',
        );
      }
      current = parent;
    }
  }

  static bool _looksLikeRepositoryRoot(Directory directory) {
    return File(p.join(directory.path, 'AGENTS.md')).existsSync() &&
        File(p.join(directory.path, 'selbrume', 'project.json')).existsSync() &&
        File(
          p.join(directory.path, 'packages', 'map_runtime', 'pubspec.yaml'),
        ).existsSync();
  }

  static Directory get repositoryRoot => findRepositoryRoot();

  static Directory get projectRoot =>
      Directory(p.join(repositoryRoot.path, 'selbrume'));

  static String get projectFilePath =>
      p.normalize(p.join(projectRoot.path, 'project.json'));

  static String get mapsDirectoryPath =>
      p.normalize(p.join(projectRoot.path, 'maps'));

  static Future<ProjectManifest> loadManifest() {
    return loadProjectManifestFromFile(projectFilePath);
  }

  static Future<Map<String, RuntimeMapBundle>> loadAllBetaBundles() async {
    final bundles = <String, RuntimeMapBundle>{};
    for (final mapId in allBetaMapIds) {
      bundles[mapId] = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: mapId,
      );
    }
    return bundles;
  }
}
