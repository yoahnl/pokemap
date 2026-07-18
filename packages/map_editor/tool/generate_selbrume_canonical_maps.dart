import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

const int selbrumeGeneratorDivergenceExitCode = 2;
const int _usageExitCode = 64;
const String _defaultThrough = 'task4';
const String _task0BourgSemanticFingerprint =
    'cb2625eae6e98c3f58523502cd0309004172eb3b4897f5e24ef91bd22f49f0df';
const String _task0BourgNavigationFingerprint =
    '4c7c8255997e9ff04f8802c0cc8fa167900cce538e2a3437a8f67f3b9f935418';
// Task 0 records the two hashes above from pretty `jq -S` output. The
// generator hashes the same projections with map_core's canonical JSON codec,
// so these equivalent canonical digests are pinned separately.
const String _task0BourgSemanticCanonicalSha256 =
    '0a6949ecd4f49c37fa5f704961473b48650b246a3150a2ddf1c1cff7c1ddd3c4';
const String _task0BourgNavigationCanonicalSha256 =
    'b67f1b9d81347e468278d3560e0241113917d2e22ef3598d93c92565ae223c04';
const Set<String> _supportedThrough = <String>{
  'task4',
  'task5',
  'task6',
  'task7',
  'task8',
  'task9',
  'task10',
  'task11',
  'task12',
  'task13',
  'task14',
  'task15',
  'task16',
};

const List<String> canonicalSelbrumeMapIds = <String>[
  'map_bourg_selbrume',
  'map_port_brisants',
  'map_bois_chaise_brume',
  'map_marais_salants',
  'map_passage_dames',
  'map_phare_exterieur',
  'map_phare_interieur',
  'map_sommet_phare',
  'map_cabane_gardien',
  'map_maison_joueur',
];

const Map<String, GridSize> _authoredMapSizes = <String, GridSize>{
  'map_bourg_selbrume': GridSize(width: 55, height: 55),
  'map_port_brisants': GridSize(width: 45, height: 34),
  'map_bois_chaise_brume': GridSize(width: 45, height: 45),
  'map_marais_salants': GridSize(width: 45, height: 45),
  'map_passage_dames': GridSize(width: 60, height: 24),
  'map_phare_exterieur': GridSize(width: 45, height: 45),
  'map_phare_interieur': GridSize(width: 36, height: 45),
  'map_sommet_phare': GridSize(width: 24, height: 24),
  'map_cabane_gardien': GridSize(width: 20, height: 16),
  'map_maison_joueur': GridSize(width: 20, height: 16),
};

const Map<String, List<(MapConnectionDirection, String, int)>>
    _authoredConnections =
    <String, List<(MapConnectionDirection, String, int)>>{
  'map_bourg_selbrume': <(MapConnectionDirection, String, int)>[
    (MapConnectionDirection.south, 'map_port_brisants', 0),
    (MapConnectionDirection.east, 'map_bois_chaise_brume', 0),
  ],
  'map_port_brisants': <(MapConnectionDirection, String, int)>[
    (MapConnectionDirection.north, 'map_bourg_selbrume', 0),
  ],
  'map_bois_chaise_brume': <(MapConnectionDirection, String, int)>[
    (MapConnectionDirection.west, 'map_bourg_selbrume', 0),
    (MapConnectionDirection.east, 'map_marais_salants', 0),
  ],
  'map_marais_salants': <(MapConnectionDirection, String, int)>[
    (MapConnectionDirection.west, 'map_bois_chaise_brume', 0),
    (MapConnectionDirection.south, 'map_passage_dames', 0),
  ],
  'map_passage_dames': <(MapConnectionDirection, String, int)>[
    (MapConnectionDirection.north, 'map_marais_salants', 0),
    (MapConnectionDirection.east, 'map_phare_exterieur', 0),
  ],
  'map_phare_exterieur': <(MapConnectionDirection, String, int)>[
    (MapConnectionDirection.west, 'map_passage_dames', 0),
  ],
};

const Map<String, List<(String, GridPos, String, GridPos)>> _authoredWarps =
    <String, List<(String, GridPos, String, GridPos)>>{
  'map_bourg_selbrume': <(String, GridPos, String, GridPos)>[
    (
      'warp_bourg_to_maison',
      GridPos(x: 13, y: 23),
      'map_maison_joueur',
      GridPos(x: 10, y: 13),
    ),
  ],
  'map_phare_exterieur': <(String, GridPos, String, GridPos)>[
    (
      'warp_phare_ext_to_interieur',
      GridPos(x: 23, y: 18),
      'map_phare_interieur',
      GridPos(x: 18, y: 42),
    ),
    (
      'warp_phare_ext_to_cabane',
      GridPos(x: 8, y: 33),
      'map_cabane_gardien',
      GridPos(x: 10, y: 13),
    ),
  ],
  'map_phare_interieur': <(String, GridPos, String, GridPos)>[
    (
      'warp_phare_interieur_to_exterieur',
      GridPos(x: 18, y: 44),
      'map_phare_exterieur',
      GridPos(x: 23, y: 19),
    ),
    (
      'warp_phare_interieur_to_sommet',
      GridPos(x: 18, y: 1),
      'map_sommet_phare',
      GridPos(x: 12, y: 22),
    ),
  ],
  'map_sommet_phare': <(String, GridPos, String, GridPos)>[
    (
      'warp_sommet_to_phare_interieur',
      GridPos(x: 12, y: 23),
      'map_phare_interieur',
      GridPos(x: 18, y: 2),
    ),
  ],
  'map_cabane_gardien': <(String, GridPos, String, GridPos)>[
    (
      'warp_cabane_to_phare_exterieur',
      GridPos(x: 10, y: 15),
      'map_phare_exterieur',
      GridPos(x: 8, y: 34),
    ),
    (
      'warp_cabane_to_passage',
      GridPos(x: 19, y: 8),
      'map_passage_dames',
      GridPos(x: 50, y: 10),
    ),
  ],
  'map_maison_joueur': <(String, GridPos, String, GridPos)>[
    (
      'warp_maison_to_bourg',
      GridPos(x: 10, y: 15),
      'map_bourg_selbrume',
      GridPos(x: 13, y: 24),
    ),
  ],
};

const Map<String, List<(String, String, String, GridPos, bool)>>
    _authoredLandmarks =
    <String, List<(String, String, String, GridPos, bool)>>{
  'map_bourg_selbrume': <(String, String, String, GridPos, bool)>[
    (
      'pe_bourg_maison_joueur_facade',
      'selbrum_maison_1',
      'l_tile_maison',
      GridPos(x: 10, y: 18),
      true,
    ),
    (
      'pe_bourg_centre_facade',
      'selbrume_centre_pok_mon',
      'l_tile_maison',
      GridPos(x: 29, y: 22),
      true,
    ),
    (
      'pe_bourg_puits',
      'le_puits',
      'l_tile_maison',
      GridPos(x: 23, y: 27),
      true,
    ),
    (
      'pe_bourg_kiosque',
      'kiosque_l_gumes',
      'l_tile_maison',
      GridPos(x: 36, y: 35),
      true,
    ),
  ],
  'map_port_brisants': <(String, String, String, GridPos, bool)>[
    (
      'pe_port_bateau',
      'el_port_ref_boat_large',
      'l_tile_port_ref_structures',
      GridPos(x: 0, y: 21),
      true,
    ),
    (
      'pe_port_nid_goelise',
      'el_port_ref_nest',
      'l_tile_port_ref_ground',
      GridPos(x: 7, y: 9),
      false,
    ),
    (
      'pe_port_hangar',
      'el_port_ref_chandlery',
      'l_tile_port_ref_structures',
      GridPos(x: 31, y: 11),
      true,
    ),
  ],
  'map_bois_chaise_brume': <(String, String, String, GridPos, bool)>[
    (
      'pe_bois_panneau_001',
      'el_selbrume_bois_panneau',
      'l_tile_structures',
      GridPos(x: 3, y: 21),
      true,
    ),
    (
      'pe_bois_tronc_tombe_001',
      'el_selbrume_bois_tronc_tombe',
      'l_tile_structures',
      GridPos(x: 18, y: 36),
      true,
    ),
  ],
  'map_marais_salants': <(String, String, String, GridPos, bool)>[
    (
      'pe_marais_cabane_paludier',
      'el_selbrume_marais_cabane_paludier',
      'l_tile_structures',
      GridPos(x: 4, y: 14),
      true,
    ),
    (
      'pe_marais_ecluse',
      'el_selbrume_marais_ecluse_fermee',
      'l_tile_structures',
      GridPos(x: 27, y: 18),
      true,
    ),
    (
      'pe_marais_indice_verre',
      'el_selbrume_indice_verre',
      'l_tile_ground',
      GridPos(x: 8, y: 32),
      false,
    ),
    (
      'pe_marais_indice_traces_electriques',
      'el_selbrume_indice_traces_electriques',
      'l_tile_fx',
      GridPos(x: 32, y: 10),
      false,
    ),
    (
      'pe_marais_indice_repere_lentille',
      'el_selbrume_indice_repere_lentille',
      'l_tile_ground',
      GridPos(x: 34, y: 34),
      false,
    ),
  ],
  'map_passage_dames': <(String, String, String, GridPos, bool)>[
    (
      'pe_passage_barriere',
      'el_selbrume_passage_barriere_fermee',
      'l_tile_structures',
      GridPos(x: 32, y: 3),
      true,
    ),
    (
      'pe_passage_marches',
      'el_selbrume_passage_marches',
      'l_tile_ground',
      GridPos(x: 56, y: 13),
      false,
    ),
    (
      'pe_passage_banc_brume',
      'el_selbrume_passage_banc_brume',
      'l_tile_fx',
      GridPos(x: 42, y: 10),
      false,
    ),
  ],
  'map_phare_exterieur': <(String, String, String, GridPos, bool)>[
    (
      'pe_phare_batiment',
      'el_selbrume_phare_batiment',
      'l_tile_structures',
      GridPos(x: 19, y: 8),
      true,
    ),
    (
      'pe_phare_cabane_facade',
      'el_selbrume_cabane_facade',
      'l_tile_structures',
      GridPos(x: 6, y: 28),
      true,
    ),
    (
      'pe_phare_porte_ouverte',
      'el_selbrume_phare_porte_ouverte',
      'l_tile_structures',
      GridPos(x: 22, y: 16),
      false,
    ),
    (
      'pe_phare_cabane_porte_ouverte',
      'el_selbrume_cabane_porte_ouverte',
      'l_tile_structures',
      GridPos(x: 7, y: 32),
      false,
    ),
  ],
  'map_phare_interieur': <(String, String, String, GridPos, bool)>[
    (
      'pe_phare_escalier_haut',
      'el_selbrume_phare_escalier_haut',
      'l_tile_floor',
      GridPos(x: 17, y: 0),
      false,
    ),
    (
      'pe_phare_escalier_bas',
      'el_selbrume_phare_escalier_bas',
      'l_tile_floor',
      GridPos(x: 17, y: 42),
      false,
    ),
    (
      'pe_phare_note_ancien_gardien',
      'el_selbrume_phare_bureau_note',
      'l_tile_furniture',
      GridPos(x: 10, y: 24),
      true,
    ),
    (
      'pe_phare_mecanisme',
      'el_selbrume_phare_mecanisme',
      'l_tile_furniture',
      GridPos(x: 25, y: 23),
      true,
    ),
  ],
  'map_sommet_phare': <(String, String, String, GridPos, bool)>[
    (
      'pe_sommet_plateforme',
      'el_selbrume_sommet_plateforme',
      'l_tile_floor',
      GridPos(x: 9, y: 7),
      false,
    ),
    (
      'pe_sommet_lanterne',
      'el_selbrume_sommet_lanterne',
      'l_tile_furniture',
      GridPos(x: 10, y: 0),
      true,
    ),
    (
      'pe_sommet_lumiere_eteinte',
      'el_selbrume_fx_lumiere_eteinte',
      'l_tile_fx',
      GridPos(x: 10, y: 0),
      false,
    ),
  ],
  'map_cabane_gardien': <(String, String, String, GridPos, bool)>[
    (
      'pe_cabane_table',
      'el_selbrume_cabane_table_carnet_ferme',
      'l_tile_furniture',
      GridPos(x: 6, y: 5),
      true,
    ),
    (
      'pe_cabane_journal',
      'el_selbrume_cabane_table_carnet_ouvert',
      'l_tile_furniture',
      GridPos(x: 6, y: 5),
      false,
    ),
    (
      'pe_cabane_cle',
      'el_selbrume_cabane_cle',
      'l_tile_floor',
      GridPos(x: 14, y: 9),
      false,
    ),
    (
      'pe_cabane_porte_principale',
      'el_selbrume_cabane_porte_principale',
      'l_tile_walls',
      GridPos(x: 9, y: 13),
      false,
    ),
    (
      'pe_cabane_porte_secondaire',
      'el_selbrume_cabane_porte_secondaire_fermee',
      'l_tile_walls',
      GridPos(x: 18, y: 6),
      false,
    ),
  ],
  'map_maison_joueur': <(String, String, String, GridPos, bool)>[
    (
      'pe_maison_lit',
      'el_selbrume_maison_lit',
      'l_tile_furniture',
      GridPos(x: 2, y: 3),
      true,
    ),
    (
      'pe_maison_bureau',
      'el_selbrume_maison_bureau',
      'l_tile_furniture',
      GridPos(x: 14, y: 4),
      true,
    ),
    (
      'pe_maison_tapis',
      'el_selbrume_maison_tapis',
      'l_tile_floor',
      GridPos(x: 8, y: 8),
      false,
    ),
    (
      'pe_maison_etagere',
      'el_selbrume_cabane_etagere',
      'l_tile_furniture',
      GridPos(x: 16, y: 3),
      true,
    ),
    (
      'pe_maison_porte',
      'el_selbrume_cabane_porte_principale',
      'l_tile_walls',
      GridPos(x: 9, y: 13),
      false,
    ),
  ],
};

const List<String> canonicalSelbrumeGroupIds = <String>[
  'group_selbrume_bourg',
  'group_selbrume_port',
  'group_selbrume_bois',
  'group_selbrume_marais',
  'group_selbrume_phare',
  'group_selbrume_interiors',
];

const Set<String> _authoredExteriorMapIds = <String>{
  'map_bourg_selbrume',
  'map_port_brisants',
  'map_bois_chaise_brume',
  'map_marais_salants',
  'map_passage_dames',
  'map_phare_exterieur',
};

const Set<String> _authoredExteriorLayerIds = <String>{
  'l_terrain',
  'l_path_primary',
  'l_path_secondary',
  'l_tile_ground',
  'l_tile_structures',
  'l_tile_overhead',
  'l_tile_fx',
  'l_collisions',
};

// Le Bourg conserve la composition authored issue de l'éditeur (forêt et
// maisons sur leurs calques dédiés) tout en utilisant l'ID terrain canonique.
// Les autres extérieurs restent soumis au contrat de production à huit
// calques, collisions statiques comprises.
const Set<String> _authoredBourgLayerIds = <String>{
  'l_tile_for_t',
  'l_environment_for_t',
  'l_path_path',
  'l_terrain',
  'l_path_ocean',
  'l_tile_maison',
};

const Set<String> _authoredPortLayerIds = <String>{
  'l_terrain',
  'l_path_primary',
  'l_path_secondary',
  'l_tile_port_ref_base',
  'l_tile_port_ref_ground',
  'l_tile_port_ref_backdrop',
  'l_environment_port_ref_north',
  'l_tile_port_ref_overhead',
  'l_environment_port_ref_east',
  'l_tile_port_ref_structures',
  'l_collisions',
};

const Set<String> _authoredRoomLayerIds = <String>{
  'l_terrain',
  'l_tile_floor',
  'l_tile_walls',
  'l_tile_furniture',
  'l_tile_overhead',
  'l_tile_fx',
  'l_collisions',
};

const Map<String, Set<String>> _authoredRequiredEntities =
    <String, Set<String>>{
  'map_bourg_selbrume': <String>{'spawn', 'p6_03_intro_sign', 'npc'},
  'map_port_brisants': <String>{
    'anchor_port_lysa',
    'anchor_port_soline',
    'anchor_port_pecheurs',
  },
  'map_marais_salants': <String>{'grant', 'anchor_marais_mado'},
  'map_maison_joueur': <String>{'spawn_maison_joueur'},
};

const Map<String, Set<String>> _authoredRequiredTriggers =
    <String, Set<String>>{
  'map_port_brisants': <String>{
    'zone_port_entry',
    'zone_port_center',
    'tr_port_rival_scene',
    'tr_port_nest',
  },
  'map_marais_salants': <String>{
    'zone_marais_entry',
    'tr_marais_indice_verre',
    'tr_marais_indice_traces_electriques',
    'tr_marais_indice_repere_lentille',
    'tr_marais_cristal_1',
    'tr_marais_cristal_2',
    'tr_marais_cristal_3',
  },
  'map_passage_dames': <String>{'zone_passage_entry'},
  'map_phare_exterieur': <String>{'zone_lighthouse_entry'},
  'map_phare_interieur': <String>{'tr_phare_note'},
  'map_sommet_phare': <String>{
    'tr_sommet_confrontation',
    'tr_lighthouse_top',
  },
  // The narrative seed moves the key outside the cabin and owns its exterior
  // Event V2 trigger; only the journal remains a cabin trigger contract.
  'map_cabane_gardien': <String>{'tr_cabane_journal'},
  'map_maison_joueur': <String>{'zone_player_house_exit'},
};

const Map<String, Set<String>> _authoredRequiredZones = <String, Set<String>>{
  'map_port_brisants': <String>{'zone_port_entry', 'zone_port_center'},
  'map_bois_chaise_brume': <String>{
    'zone_bois_herbe_1',
    'zone_bois_herbe_2',
    'zone_bois_herbe_3',
    'zone_bois_herbe_4',
  },
  'map_marais_salants': <String>{
    'zone',
    'zone_1',
    'zone_2',
    'zone_3',
    'zone_4',
    'zone_marais_entry',
  },
  'map_passage_dames': <String>{'zone_passage_entry'},
  'map_phare_exterieur': <String>{'zone_lighthouse_entry'},
  'map_phare_interieur': <String>{
    'zone_lighthouse_floor_1',
    'zone_lighthouse_top_access',
  },
  'map_sommet_phare': <String>{'zone_lighthouse_top'},
  'map_maison_joueur': <String>{'zone_player_house_exit'},
};

const JsonEncoder _prettyJson = JsonEncoder.withIndent('  ');

final class SelbrumeGeneratorOptions {
  SelbrumeGeneratorOptions({
    required Directory projectRoot,
    this.write = false,
    this.through = _defaultThrough,
    this.validateAuthored = false,
  }) : projectRoot = Directory(p.normalize(p.absolute(projectRoot.path)));

  final Directory projectRoot;
  final bool write;
  final String through;
  final bool validateAuthored;
}

final class SelbrumeGeneratorResult {
  const SelbrumeGeneratorResult({
    required this.exitCode,
    required this.divergentRelativePaths,
  });

  final int exitCode;
  final List<String> divergentRelativePaths;
}

SelbrumeGeneratorOptions parseSelbrumeGeneratorOptions(List<String> arguments) {
  Directory? projectRoot;
  var write = false;
  var through = _defaultThrough;
  var validateAuthored = false;

  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    switch (argument) {
      case '--project-root':
        if (++index >= arguments.length || arguments[index].trim().isEmpty) {
          throw const FormatException('--project-root requires a path.');
        }
        projectRoot = Directory(arguments[index]);
        break;
      case '--through':
        if (++index >= arguments.length || arguments[index].trim().isEmpty) {
          throw const FormatException('--through requires a task boundary.');
        }
        through = arguments[index].trim();
        break;
      case '--write-historical':
        write = true;
        break;
      case '--write':
        throw const FormatException(
          '--write is disabled for authored maps; use --write-historical '
          'only for an explicit legacy recovery/migration run.',
        );
      case '--check':
        write = false;
        break;
      case '--validate-authored':
        validateAuthored = true;
        break;
      case '--help':
      case '-h':
        throw const FormatException(_usage);
      default:
        throw FormatException('Unknown argument: $argument\n$_usage');
    }
  }

  if (projectRoot == null) {
    throw const FormatException('--project-root is required.\n$_usage');
  }
  if (!_supportedThrough.contains(through)) {
    throw FormatException(
      'Unsupported --through value "$through"; expected task4, task5, '
      'task6, task7, task8, task9, task10, task11, task12, task13, or '
      'task14, task15, or task16.',
    );
  }
  if (validateAuthored && write) {
    throw const FormatException(
      '--validate-authored is read-only and cannot be combined with '
      '--write-historical.',
    );
  }
  return SelbrumeGeneratorOptions(
    projectRoot: projectRoot,
    write: write,
    through: through,
    validateAuthored: validateAuthored,
  );
}

Future<SelbrumeGeneratorResult> generateSelbrumeCanonicalMaps(
  SelbrumeGeneratorOptions options,
) async {
  if (options.validateAuthored) {
    if (options.write) {
      throw ArgumentError(
        'Authored-map validation is read-only and cannot write files.',
      );
    }
    return _validateAuthoredSelbrumeProject(options.projectRoot);
  }
  if (!_supportedThrough.contains(options.through)) {
    throw ArgumentError.value(
      options.through,
      'through',
      'Only task4, task5, task6, task7, task8, task9, task10, task11, task12, '
          'task13, task14, task15, and task16 are supported.',
    );
  }

  final projectRoot = await _validatedProjectRoot(options.projectRoot);
  final projectFile = File(p.join(projectRoot.path, 'project.json'));
  final mapsDirectory = await _validatedMapsDirectory(projectRoot);
  final projectSource = await projectFile.readAsString();
  final projectJson = _decodeJsonObject(projectSource, projectFile.path);
  _rejectBoundaryDowngrade(
    projectJson,
    mapsDirectory: mapsDirectory,
    requested: options.through,
  );
  final boundaryRank = _boundaryRank(options.through);
  final task5Assets =
      boundaryRank < 5 ? null : await _loadTask5Assets(projectRoot);
  final task6PortAtlas =
      boundaryRank < 6 ? null : await _loadTask6PortAtlas(projectRoot);
  final task8CabinAtlas =
      boundaryRank < 8 ? null : await _loadTask8CabinAtlas(projectRoot);
  final task9ForestAtlas =
      boundaryRank < 9 ? null : await _loadTask9ForestAtlas(projectRoot);
  final task10MarshAtlas =
      boundaryRank < 10 ? null : await _loadTask10MarshAtlas(projectRoot);
  final task11PassageAtlas =
      boundaryRank < 11 ? null : await _loadTask11PassageAtlas(projectRoot);
  final task12LighthouseExteriorAtlas = boundaryRank < 12
      ? null
      : await _loadTask12LighthouseExteriorAtlas(projectRoot);
  final task13LighthouseInteriorAtlas = boundaryRank < 13
      ? null
      : await _loadTask13LighthouseInteriorAtlas(projectRoot);
  final task14LighthouseFxAtlas = boundaryRank < 14
      ? null
      : await _loadTask14LighthouseFxAtlas(projectRoot);

  final sourceBourgFile = File(p.join(mapsDirectory.path, 'Selbrume.json'));
  final sourceMaraisFile = File(p.join(mapsDirectory.path, 'route 1.json'));
  final sourceBourg = _decodeJsonObject(
    await sourceBourgFile.readAsString(),
    sourceBourgFile.path,
  );
  final sourceMarais = _decodeJsonObject(
    await sourceMaraisFile.readAsString(),
    sourceMaraisFile.path,
  );
  if (boundaryRank >= 7) {
    _validateTask7BourgSeed(sourceBourg);
  }

  final desiredMaps = <String, Map<String, dynamic>>{
    'map_bourg_selbrume': boundaryRank >= 7
        ? _buildBourgPilot(sourceBourg).toJson()
        : _migrateSeedMap(
            sourceBourg,
            id: 'map_bourg_selbrume',
            name: 'Bourg de Selbrume',
            metadata: const MapMetadata(
              displayName: 'Bourg de Selbrume',
              mapType: MapType.city,
              isIndoor: false,
              allowEscapeRope: false,
              defaultSpawnId: 'spawn',
              tags: <String>['selbrume', 'beta', 'map-production'],
            ),
            connections: const <MapConnection>[
              MapConnection(
                direction: MapConnectionDirection.south,
                targetMapId: 'map_port_brisants',
              ),
              MapConnection(
                direction: MapConnectionDirection.east,
                targetMapId: 'map_bois_chaise_brume',
              ),
            ],
            warps: const <MapWarp>[
              MapWarp(
                id: 'warp_bourg_to_maison',
                pos: GridPos(x: 13, y: 23),
                targetMapId: 'map_maison_joueur',
                targetPos: GridPos(x: 10, y: 13),
              ),
            ],
          ),
    'map_port_brisants':
        (task6PortAtlas == null ? _buildPort() : _buildPortPilot()).toJson(),
    'map_bois_chaise_brume':
        (task9ForestAtlas == null ? _buildForest() : _buildForestPilot())
            .toJson(),
    'map_marais_salants': task10MarshAtlas == null
        ? _migrateSeedMap(
            sourceMarais,
            id: 'map_marais_salants',
            name: 'Marais Salants',
            metadata: const MapMetadata(
              displayName: 'Marais Salants',
              mapType: MapType.route,
              isIndoor: false,
              allowEscapeRope: false,
              tags: <String>['selbrume', 'beta', 'map-production'],
            ),
            connections: const <MapConnection>[
              MapConnection(
                direction: MapConnectionDirection.west,
                targetMapId: 'map_bois_chaise_brume',
              ),
              MapConnection(
                direction: MapConnectionDirection.south,
                targetMapId: 'map_passage_dames',
              ),
            ],
            warps: const <MapWarp>[],
          )
        : _buildMarshPilot(sourceMarais).toJson(),
    'map_passage_dames':
        (task11PassageAtlas == null ? _buildPassage() : _buildPassagePilot())
            .toJson(),
    'map_phare_exterieur': (task12LighthouseExteriorAtlas == null
            ? _buildLighthouseExterior()
            : _buildLighthouseExteriorPilot())
        .toJson(),
    'map_phare_interieur': (task13LighthouseInteriorAtlas == null
            ? _buildLighthouseInterior()
            : _buildLighthouseInteriorPilot())
        .toJson(),
    'map_sommet_phare': (task14LighthouseFxAtlas == null
            ? _buildLighthouseTop()
            : _buildLighthouseTopPilot())
        .toJson(),
    'map_cabane_gardien':
        (boundaryRank >= 15 ? _buildKeeperCabinPilot() : _buildKeeperCabin())
            .toJson(),
    'map_maison_joueur':
        (boundaryRank >= 8 ? _buildPlayerHousePilot() : _buildPlayerHouse())
            .toJson(),
  };
  if (boundaryRank >= 5) {
    if (boundaryRank < 10) {
      desiredMaps['map_marais_salants'] = _withoutFullMapReferenceLayer(
        desiredMaps['map_marais_salants']!,
        mapId: 'map_marais_salants',
      );
    }
    if (boundaryRank < 7) {
      desiredMaps['map_bourg_selbrume'] = _withoutFullMapReferenceLayer(
        desiredMaps['map_bourg_selbrume']!,
        mapId: 'map_bourg_selbrume',
      );
    }
  }
  if (boundaryRank == 6) {
    desiredMaps['map_bourg_selbrume'] = _withBourgPortCauseway(
      desiredMaps['map_bourg_selbrume']!,
    );
  }
  for (final id in desiredMaps.keys.toList(growable: false)) {
    // Some generated geometry codecs expose nested value objects from toJson.
    // A JSON round-trip materializes those objects into the exact wire shape
    // that MapData.fromJson and the on-disk files consume.
    desiredMaps[id] = _decodeJsonObject(
      jsonEncode(desiredMaps[id]),
      '<generated:$id>',
    );
  }

  final desiredMapEntries = _canonicalMapEntries()
      .map((entry) => entry.toJson())
      .toList(growable: false);
  final desiredGroups = _canonicalGroups(through: options.through)
      .map((group) => group.toJson())
      .toList(growable: false);
  final canonicalCutover = boundaryRank >= 16;
  final updatedMaps = canonicalCutover
      ? desiredMapEntries
      : _upsertObjectsById(
          _jsonObjectList(projectJson['maps'], context: 'project maps'),
          desiredMapEntries,
          context: 'project maps',
        );
  final updatedGroups = canonicalCutover
      ? desiredGroups
      : _upsertObjectsById(
          _jsonObjectList(projectJson['groups'], context: 'project groups'),
          desiredGroups,
          context: 'project groups',
        );
  final updatedScenarios = canonicalCutover
      ? _migrateTask16MapBindings(
          _jsonObjectList(
            projectJson['scenarios'],
            context: 'project scenarios',
          ),
          context: 'project scenarios',
        )
      : null;
  final updatedCinematics = canonicalCutover
      ? _migrateTask16MapBindings(
          _jsonObjectList(
            projectJson['cinematics'],
            context: 'project cinematics',
          ),
          context: 'project cinematics',
        )
      : null;

  List<Map<String, dynamic>>? updatedTilesets;
  List<Map<String, dynamic>>? updatedElements;
  List<Map<String, dynamic>>? updatedPathPatterns;
  List<Map<String, dynamic>>? updatedTilesetFolders;
  List<Map<String, dynamic>>? updatedElementCategories;
  if (task5Assets != null) {
    final task6 = task6PortAtlas != null;
    final task8 = task8CabinAtlas != null;
    final task9 = task9ForestAtlas != null;
    final task10 = task10MarshAtlas != null;
    final task11 = task11PassageAtlas != null;
    final task12 = task12LighthouseExteriorAtlas != null;
    final task13 = task13LighthouseInteriorAtlas != null;
    final task14 = task14LighthouseFxAtlas != null;
    updatedTilesets = _upsertObjectsById(
      _jsonObjectList(projectJson['tilesets'], context: 'project tilesets'),
      <Map<String, dynamic>>[
        for (final entry in _task5Tilesets(
          folderId: task6 ? 'tsf_selbrume_beta_port' : null,
        ))
          entry.toJson(),
        if (task6) _task6PortTileset().toJson(),
        if (task8) _task8CabinTileset().toJson(),
        if (task9) _task9ForestTileset().toJson(),
        if (task10) _task10MarshTileset().toJson(),
        if (task11) _task11PassageTileset().toJson(),
        if (task12) _task12LighthouseExteriorTileset().toJson(),
        if (task13) _task13LighthouseInteriorTileset().toJson(),
        if (task14) _task14LighthouseFxTileset().toJson(),
      ],
      context: 'project tilesets',
    );
    updatedElements = _upsertObjectsById(
      _jsonObjectList(projectJson['elements'], context: 'project elements'),
      <Map<String, dynamic>>[
        _task5BoatElement(task5Assets.boat).toJson(),
        if (task6)
          for (final element in _task6PortElements(task6PortAtlas))
            element.toJson(),
        if (task8)
          for (final element in _task8CabinElements(task8CabinAtlas))
            element.toJson(),
        if (task9)
          for (final element in _task9ForestElements(task9ForestAtlas))
            element.toJson(),
        if (task10)
          for (final element in _task10MarshElements(task10MarshAtlas))
            element.toJson(),
        if (task11)
          for (final element in _task11PassageElements(task11PassageAtlas))
            element.toJson(),
        if (task12)
          for (final element in _task12LighthouseExteriorElements(
            task12LighthouseExteriorAtlas,
          ))
            element.toJson(),
        if (task13)
          for (final element in _task13LighthouseInteriorElements(
            task13LighthouseInteriorAtlas,
          ))
            element.toJson(),
        if (task14)
          for (final element in _task14LighthouseFxElements(
            task14LighthouseFxAtlas,
          ))
            element.toJson(),
      ],
      context: 'project elements',
    );
    if (canonicalCutover) {
      updatedElements = _migrateTask16GroupBindings(
        updatedElements,
        context: 'project elements',
      );
    }
    updatedPathPatterns = _replaceNouveauCheminPatterns(
      _jsonObjectList(
        projectJson['pathPatternPresets'],
        context: 'project pathPatternPresets',
      ),
      encodeProjectPathPatternPreset(_task5OpenSeaPattern()),
    );
    if (task6) {
      updatedTilesetFolders = _upsertObjectsById(
        _jsonObjectList(
          projectJson['tilesetFolders'],
          context: 'project tilesetFolders',
        ),
        <ProjectTilesetFolder>[
          ..._task6TilesetFolders(),
          if (task8) _task8CabinTilesetFolder(),
          if (task9) _task9ForestTilesetFolder(),
          if (task10) _task10MarshTilesetFolder(),
          if (task11) _task11PassageTilesetFolder(),
          if (task12) _task12LighthouseExteriorTilesetFolder(),
          if (task14) _task14LighthouseFxTilesetFolder(),
        ].map((entry) => entry.toJson()).toList(growable: false),
        context: 'project tilesetFolders',
      );
      updatedElementCategories = _upsertObjectsById(
        _jsonObjectList(
          projectJson['elementCategories'],
          context: 'project elementCategories',
        ),
        <Map<String, dynamic>>[
          _task6PortCategory().toJson(),
          if (task8) _task8CabinCategory().toJson(),
          if (task9) _task9ForestCategory().toJson(),
          if (task10) _task10MarshCategory().toJson(),
          if (task11) _task11PassageCategory().toJson(),
          if (task12) _task12LighthouseExteriorCategory().toJson(),
          if (task14) _task14LighthouseFxCategory().toJson(),
        ],
        context: 'project elementCategories',
      );
    }
  }

  var desiredProjectSource = _replaceTopLevelArray(
    projectSource,
    key: 'groups',
    value: updatedGroups,
  );
  desiredProjectSource = _replaceTopLevelArray(
    desiredProjectSource,
    key: 'maps',
    value: updatedMaps,
  );
  if (canonicalCutover) {
    desiredProjectSource = _replaceTopLevelArray(
      desiredProjectSource,
      key: 'scenarios',
      value: updatedScenarios!,
    );
    desiredProjectSource = _replaceTopLevelArray(
      desiredProjectSource,
      key: 'cinematics',
      value: updatedCinematics!,
    );
  }
  if (task5Assets != null) {
    desiredProjectSource = _replaceTopLevelArray(
      desiredProjectSource,
      key: 'tilesets',
      value: updatedTilesets!,
    );
    desiredProjectSource = _replaceTopLevelArray(
      desiredProjectSource,
      key: 'elements',
      value: updatedElements!,
    );
    desiredProjectSource = _replaceTopLevelArray(
      desiredProjectSource,
      key: 'pathPatternPresets',
      value: updatedPathPatterns!,
    );
    if (task6PortAtlas != null) {
      desiredProjectSource = _replaceTopLevelArray(
        desiredProjectSource,
        key: 'tilesetFolders',
        value: updatedTilesetFolders!,
      );
      desiredProjectSource = _replaceTopLevelArray(
        desiredProjectSource,
        key: 'elementCategories',
        value: updatedElementCategories!,
      );
    }
  }
  final desiredProjectJson = _decodeJsonObject(
    desiredProjectSource,
    projectFile.path,
  );
  final desiredManifest = ProjectManifest.fromJson(desiredProjectJson);

  _validateGeneratedOutput(
    maps: desiredMaps,
    manifest: desiredManifest,
    through: options.through,
  );

  final desiredFiles = <File, String>{
    for (final id in canonicalSelbrumeMapIds)
      File(p.join(mapsDirectory.path, '$id.json')):
          '${_prettyJson.convert(desiredMaps[id])}\n',
    projectFile: desiredProjectSource,
  };
  final divergent = <String>[];
  final divergentFiles = <File, String>{};
  for (final entry in desiredFiles.entries) {
    final same =
        entry.key.existsSync() && await entry.key.readAsString() == entry.value;
    if (!same) {
      divergent.add(p.relative(entry.key.path, from: projectRoot.path));
      divergentFiles[entry.key] = entry.value;
    }
  }

  if (!options.write) {
    return SelbrumeGeneratorResult(
      exitCode: divergent.isEmpty ? 0 : selbrumeGeneratorDivergenceExitCode,
      divergentRelativePaths: List<String>.unmodifiable(divergent),
    );
  }

  if (divergent.isNotEmpty) {
    await _writeAtomicallyWithManifestLast(
      desiredFiles: divergentFiles,
      manifestFile: projectFile,
    );
  }
  return const SelbrumeGeneratorResult(
    exitCode: 0,
    divergentRelativePaths: <String>[],
  );
}

Future<SelbrumeGeneratorResult> _validateAuthoredSelbrumeProject(
  Directory requestedRoot,
) async {
  final projectRoot = await _validatedAuthoredProjectRoot(requestedRoot);
  final projectFile = File(p.join(projectRoot.path, 'project.json'));
  final projectJson = _decodeJsonObject(
    await projectFile.readAsString(),
    projectFile.path,
  );
  final manifest = ProjectManifest.fromJson(projectJson);
  ProjectValidator.validate(manifest);

  final activeMapIds = manifest.maps.map((entry) => entry.id).toList();
  if (activeMapIds.length != canonicalSelbrumeMapIds.length ||
      activeMapIds.toSet().length != canonicalSelbrumeMapIds.length ||
      !activeMapIds.toSet().containsAll(canonicalSelbrumeMapIds)) {
    throw StateError(
      'Authored Selbrume map catalog must contain exactly the ten canonical '
      'map IDs.',
    );
  }

  final tilesetById = <String, ProjectTilesetEntry>{
    for (final tileset in manifest.tilesets) tileset.id: tileset,
  };
  for (final tileset in manifest.tilesets) {
    await _validateAuthoredReferencedFile(
      projectRoot: projectRoot,
      relativePath: tileset.relativePath,
      label: 'Tileset ${tileset.id}',
    );
  }
  for (final atlas in manifest.surfaceCatalog.atlases) {
    if (!tilesetById.containsKey(atlas.tilesetId)) {
      throw StateError(
        'Surface atlas ${atlas.id} references unknown tileset '
        '${atlas.tilesetId}.',
      );
    }
  }

  final elementIds = manifest.elements.map((element) => element.id).toSet();
  final environmentPresetById = <String, EnvironmentPreset>{
    for (final preset in manifest.environmentPresets) preset.id: preset,
  };
  for (final preset in manifest.environmentPresets) {
    for (final paletteItem in preset.palette) {
      if (!elementIds.contains(paletteItem.elementId)) {
        throw StateError(
          'Environment preset ${preset.id} references unknown element '
          '${paletteItem.elementId}.',
        );
      }
    }
  }

  final mapById = <String, MapData>{};
  for (final mapId in canonicalSelbrumeMapIds) {
    final entries = manifest.maps.where((entry) => entry.id == mapId);
    if (entries.length != 1) {
      throw StateError('Canonical map $mapId must be registered exactly once.');
    }
    final entry = entries.single;
    final expectedPath = p.posix.join('maps', '$mapId.json');
    if (p.posix.normalize(entry.relativePath.replaceAll(r'\', '/')) !=
        expectedPath) {
      throw StateError(
        'Canonical map $mapId must reference $expectedPath, got '
        '${entry.relativePath}.',
      );
    }
    final mapFile = await _validateAuthoredReferencedFile(
      projectRoot: projectRoot,
      relativePath: entry.relativePath,
      label: 'Map $mapId',
    );
    final raw = _decodeJsonObject(await mapFile.readAsString(), mapFile.path);
    final map = MapData.fromJson(raw);
    if (map.id != mapId) {
      throw StateError(
        'Map file ${entry.relativePath} contains id ${map.id}, expected '
        '$mapId.',
      );
    }
    MapValidator.validate(map, projectDialogueContext: manifest);
    _validateAuthoredMapContract(
      map,
      manifest: manifest,
      tilesetById: tilesetById,
      environmentPresetById: environmentPresetById,
    );
    mapById[mapId] = map;
  }
  _validateAuthoredTopology(mapById);

  return const SelbrumeGeneratorResult(
    exitCode: 0,
    divergentRelativePaths: <String>[],
  );
}

void _validateAuthoredMapContract(
  MapData map, {
  required ProjectManifest manifest,
  required Map<String, ProjectTilesetEntry> tilesetById,
  required Map<String, EnvironmentPreset> environmentPresetById,
}) {
  final expectedSize = _authoredMapSizes[map.id];
  if (expectedSize == null || map.size != expectedSize) {
    throw StateError(
      '${map.id} authored dimensions must be '
      '${expectedSize?.width}x${expectedSize?.height}; got '
      '${map.size.width}x${map.size.height}.',
    );
  }

  final layerById = <String, MapLayer>{
    for (final layer in map.layers) layer.id: layer,
  };
  final requiredLayerIds = _authoredRequiredLayerIds(map.id);
  for (final layerId in requiredLayerIds) {
    final layer = layerById[layerId];
    if (layer == null || !_isAuthoredLayerTypeValid(layerId, layer)) {
      throw StateError(
        '${map.id} is missing required layer $layerId with its canonical type.',
      );
    }
  }
  final collisionLayers = map.layers.whereType<CollisionLayer>();
  final usesPlacementOnlyCollisions = map.id == 'map_bourg_selbrume';
  if ((!usesPlacementOnlyCollisions && collisionLayers.length != 1) ||
      (collisionLayers.isNotEmpty &&
          (collisionLayers.length != 1 ||
              collisionLayers.single.id != 'l_collisions'))) {
    throw StateError(
      '${map.id} must expose exactly one canonical l_collisions layer.',
    );
  }

  final mapTilesetId = map.tilesetId.trim();
  if (mapTilesetId.isNotEmpty && !tilesetById.containsKey(mapTilesetId)) {
    throw StateError('${map.id} references unknown tileset $mapTilesetId.');
  }
  final pathPresetById = <String, ProjectPathPreset>{
    for (final preset in manifest.pathPresets) preset.id: preset,
  };
  for (final layer in map.layers) {
    if (layer case TileLayer(:final tilesetId)) {
      final id = (tilesetId ?? map.tilesetId).trim();
      if (id.isNotEmpty && !tilesetById.containsKey(id)) {
        throw StateError(
          '${map.id}/${layer.id} references unknown tileset $id.',
        );
      }
    } else if (layer case PathLayer(:final presetId, :final cells)) {
      final id = presetId.trim();
      if (id.isEmpty) {
        if (cells.contains(true)) {
          throw StateError(
              '${map.id}/${layer.id} has cells but no path preset.');
        }
        continue;
      }
      final preset = pathPresetById[id];
      if (preset == null) {
        throw StateError(
          '${map.id}/${layer.id} references unknown path preset $id.',
        );
      }
    } else if (layer case SurfaceLayer(:final placements)) {
      for (final placement in placements) {
        if (!manifest.surfaceCatalog.containsPreset(
          placement.surfacePresetId,
        )) {
          throw StateError(
            '${map.id}/${layer.id} references unknown surface preset '
            '${placement.surfacePresetId}.',
          );
        }
      }
    } else if (layer case EnvironmentLayer(:final content)) {
      final placementIds =
          map.placedElements.map((placed) => placed.id).toSet();
      for (final area in content.areas) {
        if (!environmentPresetById.containsKey(area.presetId)) {
          throw StateError(
            '${map.id}/${layer.id}/${area.id} references unknown environment '
            'preset ${area.presetId}.',
          );
        }
        for (final generatedId in area.generatedPlacementIds) {
          if (!placementIds.contains(generatedId)) {
            throw StateError(
              '${map.id}/${layer.id}/${area.id} references missing generated '
              'placement $generatedId.',
            );
          }
        }
      }
    }
  }

  final placedById = <String, MapPlacedElement>{
    for (final placed in map.placedElements) placed.id: placed,
  };
  for (final contract in _authoredLandmarks[map.id] ??
      const <(String, String, String, GridPos, bool)>[]) {
    final placed = placedById[contract.$1];
    if (map.id == 'map_port_brisants' &&
        contract.$1 == 'pe_port_nid_goelise') {
      // The promoted project must never retain both visual owners: the static
      // placement cannot react to World Rules, whereas the entity proxy can.
      if (placed != null || !_matchesPromotedNarrativeLandmark(map, contract)) {
        throw StateError(
          '${map.id} required landmark ${contract.$1} is missing or changed.',
        );
      }
      continue;
    }
    if (placed == null ||
        placed.elementId != contract.$2 ||
        placed.layerId != contract.$3 ||
        placed.pos != contract.$4 ||
        placed.applyCollision != contract.$5) {
      throw StateError(
        '${map.id} required landmark ${contract.$1} is missing or changed.',
      );
    }
  }
  _requireAuthoredIds(
    map.id,
    'entity',
    map.entities.map((entity) => entity.id).toSet(),
    _authoredRequiredEntities[map.id] ?? const <String>{},
  );
  _requireAuthoredIds(
    map.id,
    'trigger',
    map.triggers.map((trigger) => trigger.id).toSet(),
    _authoredRequiredTriggers[map.id] ?? const <String>{},
  );
  _requireAuthoredIds(
    map.id,
    'gameplay zone',
    map.gameplayZones.map((zone) => zone.id).toSet(),
    _authoredRequiredZones[map.id] ?? const <String>{},
  );
}

bool _matchesPromotedNarrativeLandmark(
  MapData map,
  (String, String, String, GridPos, bool) contract,
) {
  if (map.id != 'map_port_brisants' ||
      contract.$1 != 'pe_port_nid_goelise' ||
      contract.$2 != 'el_port_ref_nest' ||
      contract.$4 != const GridPos(x: 7, y: 9) ||
      contract.$5) {
    return false;
  }
  final proxies = map.entities.where(
    (entity) => entity.id == 'goelise_nest_proxy',
  );
  if (proxies.length != 1) return false;
  final proxy = proxies.single;
  return proxy.kind == MapEntityKind.custom &&
      proxy.pos == contract.$4 &&
      proxy.size == const GridSize(width: 1, height: 1) &&
      !proxy.blocksMovement &&
      proxy.editorVisual?.elementId == contract.$2 &&
      proxy.properties['contractRole'] == 'selbrume_world_state_visual';
}

void _validateAuthoredTopology(Map<String, MapData> maps) {
  for (final map in maps.values) {
    final expectedConnections = _authoredConnections[map.id] ??
        const <(MapConnectionDirection, String, int)>[];
    if (map.connections.length != expectedConnections.length ||
        expectedConnections.any(
          (expected) => !map.connections.any(
            (connection) =>
                connection.direction == expected.$1 &&
                connection.targetMapId == expected.$2 &&
                connection.offset == expected.$3,
          ),
        )) {
      throw StateError('${map.id} required connection topology changed.');
    }
    for (final connection in map.connections) {
      final target = maps[connection.targetMapId];
      if (target == null) {
        throw StateError(
          '${map.id} connection targets unknown map '
          '${connection.targetMapId}.',
        );
      }
      final reciprocal = target.connections.where(
        (candidate) =>
            candidate.targetMapId == map.id &&
            candidate.direction == connection.direction.opposite &&
            candidate.offset == -connection.offset,
      );
      if (reciprocal.length != 1) {
        throw StateError(
          '${map.id} ${connection.direction.name} connection has no exact '
          'reciprocal on ${target.id}.',
        );
      }
      if (!_hasWalkableAuthoredConnectionEdge(map, connection.direction)) {
        throw StateError(
          '${map.id} ${connection.direction.name} connection edge is fully '
          'blocked.',
        );
      }
    }

    final expectedWarps =
        _authoredWarps[map.id] ?? const <(String, GridPos, String, GridPos)>[];
    if (map.warps.length != expectedWarps.length ||
        expectedWarps.any(
          (expected) => !map.warps.any(
            (warp) =>
                warp.id == expected.$1 &&
                warp.pos == expected.$2 &&
                warp.targetMapId == expected.$3 &&
                warp.targetPos == expected.$4,
          ),
        )) {
      throw StateError('${map.id} required warp topology changed.');
    }
    for (final warp in map.warps) {
      final target = maps[warp.targetMapId];
      if (target == null) {
        throw StateError('${map.id}/${warp.id} targets an unknown map.');
      }
      if (warp.targetPos.x < 0 ||
          warp.targetPos.y < 0 ||
          warp.targetPos.x >= target.size.width ||
          warp.targetPos.y >= target.size.height) {
        throw StateError('${map.id}/${warp.id} target is out of bounds.');
      }
      if (_isStaticallyBlocked(target, warp.targetPos)) {
        throw StateError('${map.id}/${warp.id} target is statically blocked.');
      }
    }
  }
}

Set<String> _authoredRequiredLayerIds(String mapId) {
  if (mapId == 'map_bourg_selbrume') {
    return _authoredBourgLayerIds;
  }
  if (mapId == 'map_port_brisants') {
    return _authoredPortLayerIds;
  }
  if (_authoredExteriorMapIds.contains(mapId)) {
    return _authoredExteriorLayerIds;
  }
  if (mapId == 'map_cabane_gardien' ||
      mapId == 'map_maison_joueur' ||
      mapId == 'map_phare_interieur' ||
      mapId == 'map_sommet_phare') {
    return _authoredRoomLayerIds;
  }
  throw StateError('No authored layer contract for $mapId.');
}

bool _isAuthoredLayerTypeValid(String id, MapLayer layer) {
  if (id == 'l_terrain') return layer is TerrainLayer;
  if (id == 'l_collisions') return layer is CollisionLayer;
  if (id.startsWith('l_path_')) return layer is PathLayer;
  if (id.startsWith('l_environment_')) return layer is EnvironmentLayer;
  return layer is TileLayer;
}

void _requireAuthoredIds(
  String mapId,
  String label,
  Set<String> actual,
  Set<String> required,
) {
  final missing = required.difference(actual).toList()..sort();
  if (missing.isNotEmpty) {
    throw StateError(
        '$mapId is missing required $label IDs: ${missing.join(', ')}.');
  }
}

bool _hasWalkableAuthoredConnectionEdge(
  MapData map,
  MapConnectionDirection direction,
) {
  final collisions = map.layers
      .whereType<CollisionLayer>()
      .where((layer) => layer.id == 'l_collisions')
      .toList(growable: false);
  if (collisions.isEmpty) {
    return true;
  }
  final collision = collisions.single;
  final positions = switch (direction) {
    MapConnectionDirection.north => <GridPos>[
        for (var x = 0; x < map.size.width; x++) GridPos(x: x, y: 0),
      ],
    MapConnectionDirection.south => <GridPos>[
        for (var x = 0; x < map.size.width; x++)
          GridPos(x: x, y: map.size.height - 1),
      ],
    MapConnectionDirection.west => <GridPos>[
        for (var y = 0; y < map.size.height; y++) GridPos(x: 0, y: y),
      ],
    MapConnectionDirection.east => <GridPos>[
        for (var y = 0; y < map.size.height; y++)
          GridPos(x: map.size.width - 1, y: y),
      ],
  };
  return positions.any(
    (pos) => !collision.collisions[pos.y * map.size.width + pos.x],
  );
}

Future<Directory> _validatedAuthoredProjectRoot(Directory requested) async {
  if (!await requested.exists()) {
    throw FileSystemException('Project root does not exist.', requested.path);
  }
  final resolved = Directory(await requested.resolveSymbolicLinks());
  final projectFile = File(p.join(resolved.path, 'project.json'));
  if (!await projectFile.exists()) {
    throw FileSystemException('Missing project.json.', projectFile.path);
  }
  final resolvedProjectFile = await projectFile.resolveSymbolicLinks();
  if (!p.isWithin(resolved.path, resolvedProjectFile)) {
    throw FileSystemException(
      'project.json escapes the project root.',
      projectFile.path,
    );
  }
  await _validatedMapsDirectory(resolved);
  return resolved;
}

Future<File> _validateAuthoredReferencedFile({
  required Directory projectRoot,
  required String relativePath,
  required String label,
}) async {
  final file = File(p.join(projectRoot.path, relativePath));
  if (!await file.exists()) {
    throw FileSystemException('$label file is missing.', file.path);
  }
  final resolvedPath = await file.resolveSymbolicLinks();
  if (!p.isWithin(projectRoot.path, resolvedPath)) {
    throw FileSystemException('$label escapes the project root.', file.path);
  }
  return File(resolvedPath);
}

Future<void> main(List<String> arguments) async {
  try {
    final options = parseSelbrumeGeneratorOptions(arguments);
    final result = await generateSelbrumeCanonicalMaps(options);
    if (result.divergentRelativePaths.isNotEmpty) {
      stderr.writeln('Selbrume ${options.through} divergence:');
      for (final path in result.divergentRelativePaths) {
        stderr.writeln('  $path');
      }
      stderr.writeln(
        'Run again with --write-historical to materialize these legacy files.',
      );
    } else {
      stdout.writeln(
        options.validateAuthored
            ? 'Selbrume authored maps are valid.'
            : options.write
                ? 'Selbrume ${options.through} output is materialized and valid.'
                : 'Selbrume ${options.through} output is up to date.',
      );
    }
    exitCode = result.exitCode;
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = _usageExitCode;
  } catch (error) {
    stderr.writeln('Selbrume generation failed: $error');
    exitCode = 1;
  }
}

Future<_Task5Assets> _loadTask5Assets(Directory projectRoot) async {
  final tilesetsDirectory = p.join(projectRoot.path, 'assets', 'tilesets');
  final boat = await _decodeRequiredRgbaPng(
    projectRoot: projectRoot,
    file: File(p.join(tilesetsDirectory, 'selbrume_boat.png')),
    expectedWidth: 160,
    expectedHeight: 224,
    contractLabel: 'Task 5',
  );
  await _decodeRequiredRgbaPng(
    projectRoot: projectRoot,
    file: File(p.join(tilesetsDirectory, 'selbrume_open_sea_loop.png')),
    expectedWidth: 2048,
    expectedHeight: 64,
    contractLabel: 'Task 5',
  );
  return _Task5Assets(boat: boat);
}

Future<img.Image> _loadTask6PortAtlas(Directory projectRoot) async {
  return _decodeRequiredRgbaPng(
    projectRoot: projectRoot,
    file: File(
      p.join(
        projectRoot.path,
        'assets',
        'tilesets',
        'selbrume_port_props.png',
      ),
    ),
    expectedWidth: 512,
    expectedHeight: 512,
    contractLabel: 'Task 6',
  );
}

Future<img.Image> _loadTask8CabinAtlas(Directory projectRoot) async {
  return _decodeRequiredRgbaPng(
    projectRoot: projectRoot,
    file: File(
      p.join(
        projectRoot.path,
        'assets',
        'tilesets',
        'selbrume_cabin_interior.png',
      ),
    ),
    expectedWidth: 512,
    expectedHeight: 512,
    contractLabel: 'Task 8',
  );
}

Future<img.Image> _loadTask9ForestAtlas(Directory projectRoot) async {
  return _decodeRequiredRgbaPng(
    projectRoot: projectRoot,
    file: File(
      p.join(
        projectRoot.path,
        'assets',
        'tilesets',
        'selbrume_forest_props.png',
      ),
    ),
    expectedWidth: 512,
    expectedHeight: 512,
    contractLabel: 'Task 9',
  );
}

Future<img.Image> _loadTask10MarshAtlas(Directory projectRoot) async {
  return _decodeRequiredRgbaPng(
    projectRoot: projectRoot,
    file: File(
      p.join(
        projectRoot.path,
        'assets',
        'tilesets',
        'selbrume_marsh_props.png',
      ),
    ),
    expectedWidth: 512,
    expectedHeight: 512,
    contractLabel: 'Task 10',
  );
}

Future<img.Image> _loadTask11PassageAtlas(Directory projectRoot) async {
  return _decodeRequiredRgbaPng(
    projectRoot: projectRoot,
    file: File(
      p.join(
        projectRoot.path,
        'assets',
        'tilesets',
        'selbrume_passage_props.png',
      ),
    ),
    expectedWidth: 512,
    expectedHeight: 512,
    contractLabel: 'Task 11',
  );
}

Future<img.Image> _loadTask12LighthouseExteriorAtlas(
  Directory projectRoot,
) async {
  return _decodeRequiredRgbaPng(
    projectRoot: projectRoot,
    file: File(
      p.join(
        projectRoot.path,
        'assets',
        'tilesets',
        'selbrume_lighthouse_exterior.png',
      ),
    ),
    expectedWidth: 512,
    expectedHeight: 512,
    contractLabel: 'Task 12',
  );
}

Future<img.Image> _loadTask13LighthouseInteriorAtlas(
  Directory projectRoot,
) async {
  return _decodeRequiredRgbaPng(
    projectRoot: projectRoot,
    file: File(
      p.join(
        projectRoot.path,
        'assets',
        'tilesets',
        'selbrume_lighthouse_interior.png',
      ),
    ),
    expectedWidth: 1024,
    expectedHeight: 1024,
    contractLabel: 'Task 13',
  );
}

Future<img.Image> _loadTask14LighthouseFxAtlas(
  Directory projectRoot,
) async {
  return _decodeRequiredRgbaPng(
    projectRoot: projectRoot,
    file: File(
      p.join(
        projectRoot.path,
        'assets',
        'tilesets',
        'selbrume_lighthouse_fx.png',
      ),
    ),
    expectedWidth: 512,
    expectedHeight: 512,
    contractLabel: 'Task 14',
  );
}

Future<img.Image> _decodeRequiredRgbaPng({
  required Directory projectRoot,
  required File file,
  required int expectedWidth,
  required int expectedHeight,
  required String contractLabel,
}) async {
  if (!await file.exists()) {
    throw FileSystemException(
        'Missing required $contractLabel PNG.', file.path);
  }
  final resolvedPath = await file.resolveSymbolicLinks();
  if (!p.isWithin(projectRoot.path, resolvedPath)) {
    throw FileSystemException(
      '$contractLabel PNG escapes the project root.',
      file.path,
    );
  }
  final bytes = await File(resolvedPath).readAsBytes();
  const pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 26 ||
      !_startsWith(bytes, pngSignature) ||
      String.fromCharCodes(bytes.sublist(12, 16)) != 'IHDR') {
    throw FormatException('${file.path} is not a valid PNG with an IHDR.');
  }
  final bitDepth = bytes[24];
  final colorType = bytes[25];
  if (bitDepth != 8 || colorType != 6) {
    throw FormatException(
      '${file.path} must be an 8-bit RGBA PNG (IHDR color type 6).',
    );
  }
  final decoded = img.decodePng(bytes);
  if (decoded == null) {
    throw FormatException('${file.path} cannot be decoded as PNG.');
  }
  if (decoded.width != expectedWidth || decoded.height != expectedHeight) {
    throw StateError(
      '${file.path} must decode to ${expectedWidth}x$expectedHeight; '
      'got ${decoded.width}x${decoded.height}.',
    );
  }
  if (decoded.numChannels != 4 || !decoded.hasAlpha) {
    throw FormatException('${file.path} must decode as RGBA.');
  }
  return decoded;
}

bool _startsWith(List<int> bytes, List<int> prefix) {
  if (bytes.length < prefix.length) return false;
  for (var index = 0; index < prefix.length; index += 1) {
    if (bytes[index] != prefix[index]) return false;
  }
  return true;
}

List<ProjectTilesetEntry> _task5Tilesets({String? folderId}) =>
    <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'ts_selbrume_boat',
        name: 'Bateau de Selbrume',
        relativePath: 'assets/tilesets/selbrume_boat.png',
        folderId: folderId,
      ),
      ProjectTilesetEntry(
        id: 'ts_selbrume_open_sea_loop',
        name: 'Boucle marine de Selbrume',
        relativePath: 'assets/tilesets/selbrume_open_sea_loop.png',
        folderId: folderId,
      ),
    ];

ProjectElementEntry _task5BoatElement(img.Image boat) {
  final visualPixels = List<bool>.filled(boat.width * boat.height, false);
  final collisionPixels = List<bool>.filled(boat.width * boat.height, false);
  final occlusionPixels = List<bool>.filled(boat.width * boat.height, false);
  for (var y = 0; y < boat.height; y += 1) {
    for (var x = 0; x < boat.width; x += 1) {
      final index = y * boat.width + x;
      final visible = boat.getPixel(x, y).a.toInt() > 24;
      visualPixels[index] = visible;
      collisionPixels[index] = visible && y >= 160;
      occlusionPixels[index] = visible && y < 160;
    }
  }

  ElementCollisionPixelMask mask(List<bool> pixels) =>
      ElementCollisionPixelMask(
        widthPx: boat.width,
        heightPx: boat.height,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: boat.width,
          heightPx: boat.height,
          solidPixels: pixels,
        ),
      );

  final visualMask = mask(visualPixels);
  final collisionMask = mask(collisionPixels);
  final occlusionMask = mask(occlusionPixels);
  final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
    mask: collisionMask,
    tileWidth: 32,
    tileHeight: 32,
    sourceWidthInTiles: 5,
    sourceHeightInTiles: 7,
  );
  if (cells.isEmpty || cells.any((cell) => cell.y < 5)) {
    throw StateError(
      'selbrume_boat.png has no valid opaque hull-base collision cells.',
    );
  }

  return ProjectElementEntry(
    id: 'el_selbrume_port_bateau',
    name: 'Bateau du Port des Brisants',
    tilesetId: 'ts_selbrume_boat',
    categoryId: 'batiments',
    frames: const <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: 5, height: 7),
      ),
    ],
    collisionProfile: ElementCollisionProfile(
      source: ElementCollisionProfileSource.manual,
      visualMask: visualMask,
      collisionMask: collisionMask,
      occlusionMask: occlusionMask,
      shapeCells: cells,
      cells: cells,
    ),
    recommendedLayerId: 'l_tile_structures',
    tags: const <String>['selbrume', 'port', 'beta'],
  );
}

List<ProjectTilesetFolder> _task6TilesetFolders() =>
    const <ProjectTilesetFolder>[
      ProjectTilesetFolder(
        id: 'tsf_selbrume_beta',
        name: 'Selbrume Beta',
        sortOrder: 100,
      ),
      ProjectTilesetFolder(
        id: 'tsf_selbrume_beta_port',
        name: 'Port des Brisants',
        parentFolderId: 'tsf_selbrume_beta',
        sortOrder: 0,
      ),
    ];

ProjectElementCategory _task6PortCategory() => const ProjectElementCategory(
      id: 'cat_selbrume_port_props',
      name: 'Selbrume - Port',
      parentCategoryId: 'props',
      sortOrder: 100,
    );

ProjectTilesetEntry _task6PortTileset() => const ProjectTilesetEntry(
      id: 'ts_selbrume_port_props',
      name: 'Port des Brisants - Modules',
      relativePath: 'assets/tilesets/selbrume_port_props.png',
      folderId: 'tsf_selbrume_beta_port',
    );

ProjectTilesetFolder _task8CabinTilesetFolder() => const ProjectTilesetFolder(
      id: 'tsf_selbrume_beta_interiors',
      name: 'Interieurs de Selbrume',
      parentFolderId: 'tsf_selbrume_beta',
      sortOrder: 10,
    );

ProjectElementCategory _task8CabinCategory() => const ProjectElementCategory(
      id: 'cat_selbrume_interiors',
      name: 'Selbrume - Interieurs',
      parentCategoryId: 'props',
      sortOrder: 110,
    );

ProjectTilesetEntry _task8CabinTileset() => const ProjectTilesetEntry(
      id: 'ts_selbrume_cabin_interior',
      name: 'Interieurs des cabanes de Selbrume',
      relativePath: 'assets/tilesets/selbrume_cabin_interior.png',
      folderId: 'tsf_selbrume_beta_interiors',
    );

ProjectTilesetFolder _task9ForestTilesetFolder() => const ProjectTilesetFolder(
      id: 'tsf_selbrume_beta_forest',
      name: 'Bois de la Chaise-Brume',
      parentFolderId: 'tsf_selbrume_beta',
      sortOrder: 20,
    );

ProjectElementCategory _task9ForestCategory() => const ProjectElementCategory(
      id: 'cat_selbrume_forest',
      name: 'Selbrume - Foret',
      parentCategoryId: 'environnement',
      sortOrder: 120,
    );

ProjectTilesetEntry _task9ForestTileset() => const ProjectTilesetEntry(
      id: 'ts_selbrume_forest_props',
      name: 'Bois de la Chaise-Brume - Modules',
      relativePath: 'assets/tilesets/selbrume_forest_props.png',
      folderId: 'tsf_selbrume_beta_forest',
    );

ProjectTilesetFolder _task10MarshTilesetFolder() => const ProjectTilesetFolder(
      id: 'tsf_selbrume_beta_marsh',
      name: 'Marais Salants',
      parentFolderId: 'tsf_selbrume_beta',
      sortOrder: 30,
    );

ProjectElementCategory _task10MarshCategory() => const ProjectElementCategory(
      id: 'cat_selbrume_marsh',
      name: 'Selbrume - Marais',
      parentCategoryId: 'environnement',
      sortOrder: 130,
    );

ProjectTilesetEntry _task10MarshTileset() => const ProjectTilesetEntry(
      id: 'ts_selbrume_marsh_props',
      name: 'Marais Salants - Modules',
      relativePath: 'assets/tilesets/selbrume_marsh_props.png',
      folderId: 'tsf_selbrume_beta_marsh',
    );

ProjectTilesetFolder _task11PassageTilesetFolder() =>
    const ProjectTilesetFolder(
      id: 'tsf_selbrume_beta_passage',
      name: 'Passage des Dames',
      parentFolderId: 'tsf_selbrume_beta',
      sortOrder: 40,
    );

ProjectElementCategory _task11PassageCategory() => const ProjectElementCategory(
      id: 'cat_selbrume_passage',
      name: 'Selbrume - Passage',
      parentCategoryId: 'environnement',
      sortOrder: 140,
    );

ProjectTilesetEntry _task11PassageTileset() => const ProjectTilesetEntry(
      id: 'ts_selbrume_passage_props',
      name: 'Passage des Dames - Modules',
      relativePath: 'assets/tilesets/selbrume_passage_props.png',
      folderId: 'tsf_selbrume_beta_passage',
    );

ProjectTilesetFolder _task12LighthouseExteriorTilesetFolder() =>
    const ProjectTilesetFolder(
      id: 'tsf_selbrume_beta_lighthouse',
      name: "Vieux Phare d'Ecume",
      parentFolderId: 'tsf_selbrume_beta',
      sortOrder: 50,
    );

ProjectElementCategory _task12LighthouseExteriorCategory() =>
    const ProjectElementCategory(
      id: 'cat_selbrume_lighthouse',
      name: 'Selbrume - Phare',
      parentCategoryId: 'batiments',
      sortOrder: 150,
    );

ProjectTilesetEntry _task12LighthouseExteriorTileset() =>
    const ProjectTilesetEntry(
      id: 'ts_selbrume_lighthouse_exterior',
      name: "Vieux Phare d'Ecume - Exterieur",
      relativePath: 'assets/tilesets/selbrume_lighthouse_exterior.png',
      folderId: 'tsf_selbrume_beta_lighthouse',
    );

List<ProjectElementEntry> _task12LighthouseExteriorElements(img.Image atlas) {
  for (final spec in _lighthouseExteriorElementSpecs) {
    _requireVisibleLighthouseExteriorSource(atlas, spec);
  }
  return <ProjectElementEntry>[
    for (var index = 0;
        index < _lighthouseExteriorElementSpecs.length;
        index += 1)
      _lighthouseExteriorElementEntry(
        _lighthouseExteriorElementSpecs[index],
        atlas,
        sortOrder: index,
      ),
  ];
}

void _requireVisibleLighthouseExteriorSource(
  img.Image atlas,
  _LighthouseExteriorElementSpec spec,
) {
  const tileSize = 32;
  final left = spec.source.x * tileSize;
  final top = spec.source.y * tileSize;
  final right = left + spec.source.width * tileSize;
  final bottom = top + spec.source.height * tileSize;
  for (var y = top; y < bottom; y += 1) {
    for (var x = left; x < right; x += 1) {
      if (atlas.getPixel(x, y).a.toInt() > 24) return;
    }
  }
  throw StateError('${spec.id} has no visible pixels in its source rect.');
}

ProjectElementEntry _lighthouseExteriorElementEntry(
  _LighthouseExteriorElementSpec spec,
  img.Image atlas, {
  required int sortOrder,
}) {
  return ProjectElementEntry(
    id: spec.id,
    name: spec.name,
    tilesetId: 'ts_selbrume_lighthouse_exterior',
    categoryId: 'cat_selbrume_lighthouse',
    frames: <TilesetVisualFrame>[
      TilesetVisualFrame(source: spec.source),
    ],
    collisionProfile: spec.collisionCells.isEmpty && spec.occlusionCells.isEmpty
        ? null
        : _lighthouseExteriorCollisionProfile(atlas, spec),
    recommendedLayerId: spec.layerId,
    tags: <String>[
      'selbrume',
      'lighthouse',
      'map_phare_exterieur',
      'beta',
      spec.isStateVariant ? 'state_variant' : 'static',
    ],
    sortOrder: sortOrder,
  );
}

ElementCollisionProfile _lighthouseExteriorCollisionProfile(
  img.Image atlas,
  _LighthouseExteriorElementSpec spec,
) {
  const tileSize = 32;
  final widthPx = spec.source.width * tileSize;
  final heightPx = spec.source.height * tileSize;
  final originX = spec.source.x * tileSize;
  final originY = spec.source.y * tileSize;
  final collisionCells = spec.collisionCells.toSet();
  final occlusionCells = spec.occlusionCells.toSet();
  final visualPixels = List<bool>.filled(widthPx * heightPx, false);
  final collisionPixels = List<bool>.filled(widthPx * heightPx, false);
  final occlusionPixels = List<bool>.filled(widthPx * heightPx, false);
  final visibleCollisionPixels = <GridPos, int>{
    for (final cell in spec.collisionCells) cell: 0,
  };
  var visibleCount = 0;
  var occlusionCount = 0;
  for (var y = 0; y < heightPx; y += 1) {
    for (var x = 0; x < widthPx; x += 1) {
      final index = y * widthPx + x;
      final visible = atlas.getPixel(originX + x, originY + y).a.toInt() > 24;
      final cell = GridPos(x: x ~/ tileSize, y: y ~/ tileSize);
      final collision = visible && collisionCells.contains(cell);
      final occlusion = visible && occlusionCells.contains(cell);
      visualPixels[index] = visible;
      collisionPixels[index] = collision;
      occlusionPixels[index] = occlusion;
      if (visible) visibleCount += 1;
      if (collision) {
        visibleCollisionPixels[cell] = visibleCollisionPixels[cell]! + 1;
      }
      if (occlusion) occlusionCount += 1;
    }
  }
  if (visibleCount == 0) {
    throw StateError('${spec.id} has no visible pixels in its source rect.');
  }
  const minimumCollisionPixelsPerCell = 11;
  for (final entry in visibleCollisionPixels.entries) {
    if (entry.value < minimumCollisionPixelsPerCell) {
      throw StateError(
        '${spec.id} collision cell (${entry.key.x}, ${entry.key.y}) has '
        '${entry.value} visible pixels; expected at least '
        '$minimumCollisionPixelsPerCell.',
      );
    }
  }
  if (occlusionCells.isNotEmpty && occlusionCount == 0) {
    throw StateError('${spec.id} has no visible occlusion pixels.');
  }

  ElementCollisionPixelMask mask(List<bool> pixels) =>
      ElementCollisionPixelMask(
        widthPx: widthPx,
        heightPx: heightPx,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: widthPx,
          heightPx: heightPx,
          solidPixels: pixels,
        ),
      );

  final collisionMask = collisionCells.isEmpty ? null : mask(collisionPixels);
  if (collisionMask != null) {
    final derivedCollisionCells = ElementCollisionMaskCodec.cellsFromPixelMask(
      mask: collisionMask,
      tileWidth: tileSize,
      tileHeight: tileSize,
      sourceWidthInTiles: spec.source.width,
      sourceHeightInTiles: spec.source.height,
    );
    if (!_sameGridPositions(derivedCollisionCells, spec.collisionCells)) {
      throw StateError('${spec.id} pixel/coarse collision cells diverge.');
    }
  }
  return ElementCollisionProfile(
    source: ElementCollisionProfileSource.manual,
    visualMask: mask(visualPixels),
    collisionMask: collisionMask,
    occlusionMask: occlusionCells.isEmpty ? null : mask(occlusionPixels),
    shapeCells: spec.collisionCells,
    cells: spec.collisionCells,
  );
}

ProjectTilesetEntry _task13LighthouseInteriorTileset() =>
    const ProjectTilesetEntry(
      id: 'ts_selbrume_lighthouse_interior',
      name: "Vieux Phare d'Ecume - Kit interieur",
      relativePath: 'assets/tilesets/selbrume_lighthouse_interior.png',
      folderId: 'tsf_selbrume_beta_lighthouse',
    );

List<ProjectElementEntry> _task13LighthouseInteriorElements(img.Image atlas) {
  for (final spec in _lighthouseInteriorElementSpecs) {
    _requireVisibleLighthouseInteriorSource(atlas, spec);
  }
  return <ProjectElementEntry>[
    for (var index = 0; index < _lighthouseInteriorElementSpecs.length; index++)
      _lighthouseInteriorElementEntry(
        _lighthouseInteriorElementSpecs[index],
        atlas,
        sortOrder: index,
      ),
  ];
}

void _requireVisibleLighthouseInteriorSource(
  img.Image atlas,
  _LighthouseInteriorElementSpec spec,
) {
  const tileSize = 32;
  final left = spec.source.x * tileSize;
  final top = spec.source.y * tileSize;
  final right = left + spec.source.width * tileSize;
  final bottom = top + spec.source.height * tileSize;
  for (var y = top; y < bottom; y++) {
    for (var x = left; x < right; x++) {
      if (atlas.getPixel(x, y).a.toInt() > 24) return;
    }
  }
  throw StateError('${spec.id} has no visible pixels in its source rect.');
}

ProjectElementEntry _lighthouseInteriorElementEntry(
  _LighthouseInteriorElementSpec spec,
  img.Image atlas, {
  required int sortOrder,
}) {
  return ProjectElementEntry(
    id: spec.id,
    name: spec.name,
    tilesetId: 'ts_selbrume_lighthouse_interior',
    categoryId: 'cat_selbrume_lighthouse',
    frames: <TilesetVisualFrame>[
      TilesetVisualFrame(source: spec.source),
    ],
    collisionProfile: spec.collisionCells.isEmpty
        ? null
        : _lighthouseInteriorCollisionProfile(atlas, spec),
    recommendedLayerId: spec.layerId,
    tags: <String>[
      'selbrume',
      'lighthouse',
      'interior',
      spec.mapTag,
      'beta',
      'static',
    ],
    sortOrder: sortOrder,
  );
}

ProjectTilesetFolder _task14LighthouseFxTilesetFolder() =>
    const ProjectTilesetFolder(
      id: 'tsf_selbrume_beta_fx',
      name: 'Effets de Selbrume',
      parentFolderId: 'tsf_selbrume_beta',
      sortOrder: 60,
    );

ProjectElementCategory _task14LighthouseFxCategory() =>
    const ProjectElementCategory(
      id: 'cat_selbrume_fx',
      name: 'Selbrume - Effets',
      parentCategoryId: 'environnement',
      sortOrder: 160,
    );

ProjectTilesetEntry _task14LighthouseFxTileset() => const ProjectTilesetEntry(
      id: 'ts_selbrume_lighthouse_fx',
      name: "Vieux Phare d'Ecume - Effets",
      relativePath: 'assets/tilesets/selbrume_lighthouse_fx.png',
      folderId: 'tsf_selbrume_beta_fx',
    );

List<ProjectElementEntry> _task14LighthouseFxElements(img.Image atlas) {
  for (final spec in _lighthouseFxElementSpecs) {
    for (var frameIndex = 0; frameIndex < spec.frames.length; frameIndex++) {
      _requireVisibleLighthouseFxFrame(
        atlas,
        spec,
        frameIndex: frameIndex,
      );
    }
  }
  return <ProjectElementEntry>[
    for (var index = 0; index < _lighthouseFxElementSpecs.length; index++)
      ProjectElementEntry(
        id: _lighthouseFxElementSpecs[index].id,
        name: _lighthouseFxElementSpecs[index].name,
        tilesetId: 'ts_selbrume_lighthouse_fx',
        categoryId: 'cat_selbrume_fx',
        frames: _lighthouseFxElementSpecs[index].frames,
        recommendedLayerId: 'l_tile_fx',
        tags: <String>[
          'selbrume',
          'environment',
          'lighthouse',
          'fx',
          'map_passage_dames',
          'map_phare_exterieur',
          'map_phare_interieur',
          'map_sommet_phare',
          'beta',
          if (_lighthouseFxElementSpecs[index].stateVariant) 'state_variant',
          if (_lighthouseFxElementSpecs[index].animated)
            'animated'
          else if (!_lighthouseFxElementSpecs[index].stateVariant)
            'static',
        ],
        sortOrder: index,
      ),
  ];
}

void _requireVisibleLighthouseFxFrame(
  img.Image atlas,
  _LighthouseFxElementSpec spec, {
  required int frameIndex,
}) {
  const tileSize = 32;
  final source = spec.frames[frameIndex].source;
  final left = source.x * tileSize;
  final top = source.y * tileSize;
  final right = left + source.width * tileSize;
  final bottom = top + source.height * tileSize;
  for (var y = top; y < bottom; y++) {
    for (var x = left; x < right; x++) {
      if (atlas.getPixel(x, y).a.toInt() > 24) return;
    }
  }
  throw StateError(
    '${spec.id} frame ${frameIndex + 1} has no visible pixels in its '
    'source rect.',
  );
}

ElementCollisionProfile _lighthouseInteriorCollisionProfile(
  img.Image atlas,
  _LighthouseInteriorElementSpec spec,
) {
  const tileSize = 32;
  final widthPx = spec.source.width * tileSize;
  final heightPx = spec.source.height * tileSize;
  final originX = spec.source.x * tileSize;
  final originY = spec.source.y * tileSize;
  final collisionCells = spec.collisionCells.toSet();
  final visualPixels = List<bool>.filled(widthPx * heightPx, false);
  final collisionPixels = List<bool>.filled(widthPx * heightPx, false);
  final visibleCollisionPixels = <GridPos, int>{
    for (final cell in spec.collisionCells) cell: 0,
  };
  var visibleCount = 0;
  for (var y = 0; y < heightPx; y++) {
    for (var x = 0; x < widthPx; x++) {
      final index = y * widthPx + x;
      final visible = atlas.getPixel(originX + x, originY + y).a.toInt() > 24;
      final cell = GridPos(x: x ~/ tileSize, y: y ~/ tileSize);
      final collision = visible && collisionCells.contains(cell);
      visualPixels[index] = visible;
      collisionPixels[index] = collision;
      if (visible) visibleCount++;
      if (collision) {
        visibleCollisionPixels[cell] = visibleCollisionPixels[cell]! + 1;
      }
    }
  }
  if (visibleCount == 0) {
    throw StateError('${spec.id} has no visible pixels in its source rect.');
  }
  const minimumCollisionPixelsPerCell = 11;
  for (final entry in visibleCollisionPixels.entries) {
    if (entry.value < minimumCollisionPixelsPerCell) {
      throw StateError(
        '${spec.id} collision cell (${entry.key.x}, ${entry.key.y}) has '
        '${entry.value} visible pixels; expected at least '
        '$minimumCollisionPixelsPerCell.',
      );
    }
  }

  ElementCollisionPixelMask mask(List<bool> pixels) =>
      ElementCollisionPixelMask(
        widthPx: widthPx,
        heightPx: heightPx,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: widthPx,
          heightPx: heightPx,
          solidPixels: pixels,
        ),
      );
  final collisionMask = mask(collisionPixels);
  final derivedCells = ElementCollisionMaskCodec.cellsFromPixelMask(
    mask: collisionMask,
    tileWidth: tileSize,
    tileHeight: tileSize,
    sourceWidthInTiles: spec.source.width,
    sourceHeightInTiles: spec.source.height,
  );
  if (!_sameGridPositions(derivedCells, spec.collisionCells)) {
    throw StateError('${spec.id} pixel/coarse collision cells diverge.');
  }
  return ElementCollisionProfile(
    source: ElementCollisionProfileSource.manual,
    visualMask: mask(visualPixels),
    collisionMask: collisionMask,
    shapeCells: spec.collisionCells,
    cells: spec.collisionCells,
  );
}

List<ProjectElementEntry> _task11PassageElements(img.Image atlas) {
  for (final spec in _passageElementSpecs) {
    _requireVisiblePassageSource(atlas, spec);
  }
  return <ProjectElementEntry>[
    for (var index = 0; index < _passageElementSpecs.length; index += 1)
      _passageElementEntry(
        _passageElementSpecs[index],
        atlas,
        sortOrder: index,
      ),
  ];
}

void _requireVisiblePassageSource(img.Image atlas, _PassageElementSpec spec) {
  const tileSize = 32;
  final left = spec.source.x * tileSize;
  final top = spec.source.y * tileSize;
  final right = left + spec.source.width * tileSize;
  final bottom = top + spec.source.height * tileSize;
  for (var y = top; y < bottom; y += 1) {
    for (var x = left; x < right; x += 1) {
      if (atlas.getPixel(x, y).a.toInt() > 24) return;
    }
  }
  throw StateError('${spec.id} has no visible pixels in its source rect.');
}

ProjectElementEntry _passageElementEntry(
  _PassageElementSpec spec,
  img.Image atlas, {
  required int sortOrder,
}) {
  return ProjectElementEntry(
    id: spec.id,
    name: spec.name,
    tilesetId: 'ts_selbrume_passage_props',
    categoryId: 'cat_selbrume_passage',
    frames: <TilesetVisualFrame>[
      TilesetVisualFrame(source: spec.source),
    ],
    collisionProfile: spec.collisionCells.isEmpty
        ? null
        : _passageCollisionProfile(atlas, spec),
    recommendedLayerId: spec.layerId,
    tags: <String>[
      'selbrume',
      'environment',
      'passage',
      'map_passage_dames',
      'beta',
      spec.isStateVariant ? 'state_variant' : 'static',
    ],
    sortOrder: sortOrder,
  );
}

ElementCollisionProfile _passageCollisionProfile(
  img.Image atlas,
  _PassageElementSpec spec,
) {
  const tileSize = 32;
  final widthPx = spec.source.width * tileSize;
  final heightPx = spec.source.height * tileSize;
  final originX = spec.source.x * tileSize;
  final originY = spec.source.y * tileSize;
  final collisionCells = spec.collisionCells.toSet();
  final visualPixels = List<bool>.filled(widthPx * heightPx, false);
  final collisionPixels = List<bool>.filled(widthPx * heightPx, false);
  final visibleCollisionPixels = <GridPos, int>{
    for (final cell in spec.collisionCells) cell: 0,
  };
  var visibleCount = 0;
  for (var y = 0; y < heightPx; y += 1) {
    for (var x = 0; x < widthPx; x += 1) {
      final index = y * widthPx + x;
      final visible = atlas.getPixel(originX + x, originY + y).a.toInt() > 24;
      final cell = GridPos(x: x ~/ tileSize, y: y ~/ tileSize);
      final collision = visible && collisionCells.contains(cell);
      visualPixels[index] = visible;
      collisionPixels[index] = collision;
      if (visible) visibleCount += 1;
      if (collision) {
        visibleCollisionPixels[cell] = visibleCollisionPixels[cell]! + 1;
      }
    }
  }
  if (visibleCount == 0) {
    throw StateError('${spec.id} has no visible pixels in its source rect.');
  }
  const minimumCollisionPixelsPerCell = 11;
  for (final entry in visibleCollisionPixels.entries) {
    if (entry.value < minimumCollisionPixelsPerCell) {
      throw StateError(
        '${spec.id} collision cell (${entry.key.x}, ${entry.key.y}) has '
        '${entry.value} visible pixels; expected at least '
        '$minimumCollisionPixelsPerCell.',
      );
    }
  }

  ElementCollisionPixelMask mask(List<bool> pixels) =>
      ElementCollisionPixelMask(
        widthPx: widthPx,
        heightPx: heightPx,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: widthPx,
          heightPx: heightPx,
          solidPixels: pixels,
        ),
      );

  final collisionMask = mask(collisionPixels);
  final derivedCollisionCells = ElementCollisionMaskCodec.cellsFromPixelMask(
    mask: collisionMask,
    tileWidth: tileSize,
    tileHeight: tileSize,
    sourceWidthInTiles: spec.source.width,
    sourceHeightInTiles: spec.source.height,
  );
  if (!_sameGridPositions(derivedCollisionCells, spec.collisionCells)) {
    throw StateError('${spec.id} pixel/coarse collision cells diverge.');
  }
  return ElementCollisionProfile(
    source: ElementCollisionProfileSource.manual,
    visualMask: mask(visualPixels),
    collisionMask: collisionMask,
    shapeCells: spec.collisionCells,
    cells: spec.collisionCells,
  );
}

List<ProjectElementEntry> _task10MarshElements(img.Image atlas) {
  for (final spec in _marshElementSpecs) {
    _requireVisibleMarshSource(atlas, spec);
  }
  return <ProjectElementEntry>[
    for (var index = 0; index < _marshElementSpecs.length; index += 1)
      _marshElementEntry(_marshElementSpecs[index], atlas, sortOrder: index),
  ];
}

void _requireVisibleMarshSource(img.Image atlas, _MarshElementSpec spec) {
  const tileSize = 32;
  final left = spec.source.x * tileSize;
  final top = spec.source.y * tileSize;
  final right = left + spec.source.width * tileSize;
  final bottom = top + spec.source.height * tileSize;
  for (var y = top; y < bottom; y += 1) {
    for (var x = left; x < right; x += 1) {
      if (atlas.getPixel(x, y).a.toInt() > 24) return;
    }
  }
  throw StateError('${spec.id} has no visible pixels in its source rect.');
}

ProjectElementEntry _marshElementEntry(
  _MarshElementSpec spec,
  img.Image atlas, {
  required int sortOrder,
}) {
  return ProjectElementEntry(
    id: spec.id,
    name: spec.name,
    tilesetId: 'ts_selbrume_marsh_props',
    categoryId: 'cat_selbrume_marsh',
    frames: <TilesetVisualFrame>[
      TilesetVisualFrame(source: spec.source),
    ],
    collisionProfile: spec.collisionCells.isEmpty
        ? null
        : _marshCollisionProfile(atlas, spec),
    recommendedLayerId: spec.layerId,
    tags: <String>[
      'selbrume',
      'environment',
      'marsh',
      'map_marais_salants',
      'beta',
      spec.isStateVariant ? 'state_variant' : 'static',
    ],
    sortOrder: sortOrder,
  );
}

ElementCollisionProfile _marshCollisionProfile(
  img.Image atlas,
  _MarshElementSpec spec,
) {
  const tileSize = 32;
  final widthPx = spec.source.width * tileSize;
  final heightPx = spec.source.height * tileSize;
  final originX = spec.source.x * tileSize;
  final originY = spec.source.y * tileSize;
  final collisionCells = spec.collisionCells.toSet();
  final occlusionCells = spec.occlusionCells.toSet();
  final visualPixels = List<bool>.filled(widthPx * heightPx, false);
  final collisionPixels = List<bool>.filled(widthPx * heightPx, false);
  final occlusionPixels = List<bool>.filled(widthPx * heightPx, false);
  final visibleCollisionPixels = <GridPos, int>{
    for (final cell in spec.collisionCells) cell: 0,
  };
  var visibleCount = 0;
  var occlusionCount = 0;
  for (var y = 0; y < heightPx; y += 1) {
    for (var x = 0; x < widthPx; x += 1) {
      final index = y * widthPx + x;
      final visible = atlas.getPixel(originX + x, originY + y).a.toInt() > 24;
      final cell = GridPos(x: x ~/ tileSize, y: y ~/ tileSize);
      final collision = visible && collisionCells.contains(cell);
      final occlusion = visible && occlusionCells.contains(cell);
      visualPixels[index] = visible;
      collisionPixels[index] = collision;
      occlusionPixels[index] = occlusion;
      if (visible) visibleCount += 1;
      if (collision) {
        visibleCollisionPixels[cell] = visibleCollisionPixels[cell]! + 1;
      }
      if (occlusion) occlusionCount += 1;
    }
  }
  if (visibleCount == 0) {
    throw StateError('${spec.id} has no visible pixels in its source rect.');
  }
  const minimumCollisionPixelsPerCell = 11;
  for (final entry in visibleCollisionPixels.entries) {
    if (entry.value < minimumCollisionPixelsPerCell) {
      throw StateError(
        '${spec.id} collision cell (${entry.key.x}, ${entry.key.y}) has '
        '${entry.value} visible pixels; expected at least '
        '$minimumCollisionPixelsPerCell.',
      );
    }
  }
  if (occlusionCells.isNotEmpty && occlusionCount == 0) {
    throw StateError('${spec.id} has no visible occlusion pixels.');
  }

  ElementCollisionPixelMask mask(List<bool> pixels) =>
      ElementCollisionPixelMask(
        widthPx: widthPx,
        heightPx: heightPx,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: widthPx,
          heightPx: heightPx,
          solidPixels: pixels,
        ),
      );

  final collisionMask = mask(collisionPixels);
  final derivedCollisionCells = ElementCollisionMaskCodec.cellsFromPixelMask(
    mask: collisionMask,
    tileWidth: tileSize,
    tileHeight: tileSize,
    sourceWidthInTiles: spec.source.width,
    sourceHeightInTiles: spec.source.height,
  );
  if (!_sameGridPositions(derivedCollisionCells, spec.collisionCells)) {
    throw StateError('${spec.id} pixel/coarse collision cells diverge.');
  }
  return ElementCollisionProfile(
    source: ElementCollisionProfileSource.manual,
    visualMask: mask(visualPixels),
    collisionMask: collisionMask,
    occlusionMask: occlusionCells.isEmpty ? null : mask(occlusionPixels),
    shapeCells: spec.collisionCells,
    cells: spec.collisionCells,
  );
}

List<ProjectElementEntry> _task9ForestElements(img.Image atlas) {
  for (final spec in _forestElementSpecs) {
    _requireVisibleForestSource(atlas, spec);
  }
  return <ProjectElementEntry>[
    for (var index = 0; index < _forestElementSpecs.length; index += 1)
      _forestElementEntry(_forestElementSpecs[index], atlas, sortOrder: index),
  ];
}

void _requireVisibleForestSource(img.Image atlas, _ForestElementSpec spec) {
  const tileSize = 32;
  final left = spec.source.x * tileSize;
  final top = spec.source.y * tileSize;
  final right = left + spec.source.width * tileSize;
  final bottom = top + spec.source.height * tileSize;
  for (var y = top; y < bottom; y += 1) {
    for (var x = left; x < right; x += 1) {
      if (atlas.getPixel(x, y).a.toInt() > 24) return;
    }
  }
  throw StateError('${spec.id} has no visible pixels in its source rect.');
}

ProjectElementEntry _forestElementEntry(
  _ForestElementSpec spec,
  img.Image atlas, {
  required int sortOrder,
}) {
  return ProjectElementEntry(
    id: spec.id,
    name: spec.name,
    tilesetId: 'ts_selbrume_forest_props',
    categoryId: 'cat_selbrume_forest',
    frames: <TilesetVisualFrame>[
      TilesetVisualFrame(source: spec.source),
    ],
    collisionProfile: spec.collisionCells.isEmpty
        ? null
        : _forestCollisionProfile(atlas, spec),
    recommendedLayerId: spec.layerId,
    tags: const <String>[
      'selbrume',
      'environment',
      'forest',
      'map_bois_chaise_brume',
      'beta',
      'static',
    ],
    sortOrder: sortOrder,
  );
}

ElementCollisionProfile _forestCollisionProfile(
  img.Image atlas,
  _ForestElementSpec spec,
) {
  const tileSize = 32;
  final widthPx = spec.source.width * tileSize;
  final heightPx = spec.source.height * tileSize;
  final originX = spec.source.x * tileSize;
  final originY = spec.source.y * tileSize;
  final collisionCells = spec.collisionCells.toSet();
  final visualPixels = List<bool>.filled(widthPx * heightPx, false);
  final collisionPixels = List<bool>.filled(widthPx * heightPx, false);
  final occlusionPixels = List<bool>.filled(widthPx * heightPx, false);
  final collisionPixelsByCell = <GridPos, int>{
    for (final cell in spec.collisionCells) cell: 0,
  };
  var visibleCount = 0;
  var occlusionCount = 0;
  for (var y = 0; y < heightPx; y += 1) {
    for (var x = 0; x < widthPx; x += 1) {
      final index = y * widthPx + x;
      final visible = atlas.getPixel(originX + x, originY + y).a.toInt() > 24;
      final cell = GridPos(x: x ~/ tileSize, y: y ~/ tileSize);
      final collision = visible && collisionCells.contains(cell);
      final occlusion = visible && spec.hasCanopy && !collision;
      visualPixels[index] = visible;
      collisionPixels[index] = collision;
      occlusionPixels[index] = occlusion;
      if (visible) visibleCount += 1;
      if (collision) {
        collisionPixelsByCell[cell] = collisionPixelsByCell[cell]! + 1;
      }
      if (occlusion) occlusionCount += 1;
    }
  }
  if (visibleCount == 0) {
    throw StateError('${spec.id} has no visible pixels in its source rect.');
  }
  const minimumCollisionPixelsPerCell = 11;
  for (final entry in collisionPixelsByCell.entries) {
    if (entry.value < minimumCollisionPixelsPerCell) {
      throw StateError(
        '${spec.id} collision cell (${entry.key.x}, ${entry.key.y}) has '
        '${entry.value} visible pixels; expected at least '
        '$minimumCollisionPixelsPerCell.',
      );
    }
  }
  if (spec.hasCanopy && occlusionCount == 0) {
    throw StateError('${spec.id} canopy has no visible occlusion pixels.');
  }

  ElementCollisionPixelMask mask(List<bool> pixels) =>
      ElementCollisionPixelMask(
        widthPx: widthPx,
        heightPx: heightPx,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: widthPx,
          heightPx: heightPx,
          solidPixels: pixels,
        ),
      );

  final collisionMask = mask(collisionPixels);
  final derivedCollisionCells = ElementCollisionMaskCodec.cellsFromPixelMask(
    mask: collisionMask,
    tileWidth: tileSize,
    tileHeight: tileSize,
    sourceWidthInTiles: spec.source.width,
    sourceHeightInTiles: spec.source.height,
  );
  if (!_sameGridPositions(derivedCollisionCells, spec.collisionCells)) {
    throw StateError('${spec.id} pixel/coarse collision cells diverge.');
  }
  return ElementCollisionProfile(
    source: ElementCollisionProfileSource.manual,
    visualMask: mask(visualPixels),
    collisionMask: collisionMask,
    occlusionMask: spec.hasCanopy ? mask(occlusionPixels) : null,
    shapeCells: spec.collisionCells,
    cells: spec.collisionCells,
  );
}

List<ProjectElementEntry> _task8CabinElements(img.Image atlas) {
  for (final spec in _cabinElementSpecs) {
    _requireVisibleCabinSource(atlas, spec);
  }
  return <ProjectElementEntry>[
    for (var index = 0; index < _cabinElementSpecs.length; index += 1)
      _cabinElementEntry(_cabinElementSpecs[index], atlas, sortOrder: index),
  ];
}

void _requireVisibleCabinSource(img.Image atlas, _CabinElementSpec spec) {
  const tileSize = 32;
  final left = spec.source.x * tileSize;
  final top = spec.source.y * tileSize;
  final right = left + spec.source.width * tileSize;
  final bottom = top + spec.source.height * tileSize;
  for (var y = top; y < bottom; y += 1) {
    for (var x = left; x < right; x += 1) {
      if (atlas.getPixel(x, y).a.toInt() > 24) return;
    }
  }
  throw StateError('${spec.id} has no visible pixels in its source rect.');
}

ProjectElementEntry _cabinElementEntry(
  _CabinElementSpec spec,
  img.Image atlas, {
  required int sortOrder,
}) {
  return ProjectElementEntry(
    id: spec.id,
    name: spec.name,
    tilesetId: 'ts_selbrume_cabin_interior',
    categoryId: 'cat_selbrume_interiors',
    frames: <TilesetVisualFrame>[
      TilesetVisualFrame(source: spec.source),
    ],
    collisionProfile: spec.collisionCells.isEmpty
        ? null
        : _cabinCollisionProfile(atlas, spec),
    recommendedLayerId: spec.layerId,
    tags: <String>[
      'selbrume',
      'environment',
      'interior',
      'map_cabane_gardien',
      'map_maison_joueur',
      'beta',
      spec.isStateVariant ? 'state_variant' : 'static',
    ],
    sortOrder: sortOrder,
  );
}

ElementCollisionProfile _cabinCollisionProfile(
  img.Image atlas,
  _CabinElementSpec spec,
) {
  const tileSize = 32;
  final widthPx = spec.source.width * tileSize;
  final heightPx = spec.source.height * tileSize;
  final originX = spec.source.x * tileSize;
  final originY = spec.source.y * tileSize;
  final collisionCells = spec.collisionCells.toSet();
  final visualPixels = List<bool>.filled(widthPx * heightPx, false);
  final collisionPixels = List<bool>.filled(widthPx * heightPx, false);
  final visibleCollisionPixels = <GridPos, int>{
    for (final cell in spec.collisionCells) cell: 0,
  };
  var visibleCount = 0;
  for (var y = 0; y < heightPx; y += 1) {
    for (var x = 0; x < widthPx; x += 1) {
      final index = y * widthPx + x;
      final visible = atlas.getPixel(originX + x, originY + y).a.toInt() > 24;
      final cell = GridPos(x: x ~/ tileSize, y: y ~/ tileSize);
      final collision = visible && collisionCells.contains(cell);
      visualPixels[index] = visible;
      collisionPixels[index] = collision;
      if (visible) visibleCount += 1;
      if (collision) {
        visibleCollisionPixels[cell] = visibleCollisionPixels[cell]! + 1;
      }
    }
  }
  if (visibleCount == 0) {
    throw StateError('${spec.id} has no visible pixels in its source rect.');
  }
  const minimumCollisionPixelsPerCell = 11;
  for (final entry in visibleCollisionPixels.entries) {
    if (entry.value < minimumCollisionPixelsPerCell) {
      throw StateError(
        '${spec.id} collision cell (${entry.key.x}, ${entry.key.y}) has '
        '${entry.value} visible pixels; expected at least '
        '$minimumCollisionPixelsPerCell.',
      );
    }
  }

  ElementCollisionPixelMask mask(List<bool> pixels) =>
      ElementCollisionPixelMask(
        widthPx: widthPx,
        heightPx: heightPx,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: widthPx,
          heightPx: heightPx,
          solidPixels: pixels,
        ),
      );

  final collisionMask = mask(collisionPixels);
  final derivedCollisionCells = ElementCollisionMaskCodec.cellsFromPixelMask(
    mask: collisionMask,
    tileWidth: tileSize,
    tileHeight: tileSize,
    sourceWidthInTiles: spec.source.width,
    sourceHeightInTiles: spec.source.height,
  );
  if (!_sameGridPositions(derivedCollisionCells, spec.collisionCells)) {
    throw StateError('${spec.id} pixel/coarse collision cells diverge.');
  }
  return ElementCollisionProfile(
    source: ElementCollisionProfileSource.manual,
    visualMask: mask(visualPixels),
    collisionMask: collisionMask,
    shapeCells: spec.collisionCells,
    cells: spec.collisionCells,
  );
}

List<ProjectElementEntry> _task6PortElements(img.Image atlas) {
  for (final spec in _portElementSpecs) {
    _requireVisiblePortSource(atlas, spec);
  }
  return <ProjectElementEntry>[
    for (var index = 0; index < _portElementSpecs.length; index += 1)
      _portElementEntry(_portElementSpecs[index], atlas, sortOrder: index),
  ];
}

void _requireVisiblePortSource(img.Image atlas, _PortElementSpec spec) {
  const tileSize = 32;
  final left = spec.source.x * tileSize;
  final top = spec.source.y * tileSize;
  final right = left + spec.source.width * tileSize;
  final bottom = top + spec.source.height * tileSize;
  for (var y = top; y < bottom; y += 1) {
    for (var x = left; x < right; x += 1) {
      if (atlas.getPixel(x, y).a.toInt() > 24) return;
    }
  }
  throw StateError('${spec.id} has no visible pixels in its source rect.');
}

ProjectElementEntry _portElementEntry(
  _PortElementSpec spec,
  img.Image atlas, {
  required int sortOrder,
}) {
  return ProjectElementEntry(
    id: spec.id,
    name: spec.name,
    tilesetId: 'ts_selbrume_port_props',
    categoryId: 'cat_selbrume_port_props',
    frames: <TilesetVisualFrame>[
      TilesetVisualFrame(source: spec.source),
    ],
    collisionProfile:
        spec.collisionCells.isEmpty ? null : _portCollisionProfile(atlas, spec),
    recommendedLayerId: spec.layerId,
    tags: <String>[
      'selbrume',
      'environment',
      'port',
      'map_port_brisants',
      'beta',
      spec.isStateVariant ? 'state_variant' : 'static',
    ],
    sortOrder: sortOrder,
  );
}

ElementCollisionProfile _portCollisionProfile(
  img.Image atlas,
  _PortElementSpec spec,
) {
  const tileSize = 32;
  final widthPx = spec.source.width * tileSize;
  final heightPx = spec.source.height * tileSize;
  final originX = spec.source.x * tileSize;
  final originY = spec.source.y * tileSize;
  final collisionCells = spec.collisionCells.toSet();
  final occlusionCells = spec.occlusionCells.toSet();
  final visualPixels = List<bool>.filled(widthPx * heightPx, false);
  final collisionPixels = List<bool>.filled(widthPx * heightPx, false);
  final occlusionPixels = List<bool>.filled(widthPx * heightPx, false);
  final collisionPixelsByCell = <GridPos, int>{
    for (final cell in spec.collisionCells) cell: 0,
  };
  final occlusionPixelsByCell = <GridPos, int>{
    for (final cell in spec.occlusionCells) cell: 0,
  };
  var visibleCount = 0;
  for (var y = 0; y < heightPx; y += 1) {
    for (var x = 0; x < widthPx; x += 1) {
      final index = y * widthPx + x;
      final visible = atlas.getPixel(originX + x, originY + y).a.toInt() > 24;
      final cell = GridPos(x: x ~/ tileSize, y: y ~/ tileSize);
      final collision = visible && collisionCells.contains(cell);
      final occlusion = visible && occlusionCells.contains(cell);
      visualPixels[index] = visible;
      collisionPixels[index] = collision;
      occlusionPixels[index] = occlusion;
      if (visible) visibleCount += 1;
      if (collision) {
        collisionPixelsByCell[cell] = collisionPixelsByCell[cell]! + 1;
      }
      if (occlusion) {
        occlusionPixelsByCell[cell] = occlusionPixelsByCell[cell]! + 1;
      }
    }
  }
  if (visibleCount == 0) {
    throw StateError('${spec.id} has no visible pixels in its source rect.');
  }
  const minimumCollisionPixelsPerCell = 11;
  for (final entry in collisionPixelsByCell.entries) {
    if (entry.value < minimumCollisionPixelsPerCell) {
      throw StateError(
        '${spec.id} collision cell (${entry.key.x}, ${entry.key.y}) has '
        '${entry.value} visible pixels; expected at least '
        '$minimumCollisionPixelsPerCell.',
      );
    }
  }
  for (final entry in occlusionPixelsByCell.entries) {
    if (entry.value == 0) {
      throw StateError(
        '${spec.id} occlusion cell (${entry.key.x}, ${entry.key.y}) has no '
        'visible pixels.',
      );
    }
  }

  ElementCollisionPixelMask mask(List<bool> pixels) =>
      ElementCollisionPixelMask(
        widthPx: widthPx,
        heightPx: heightPx,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: widthPx,
          heightPx: heightPx,
          solidPixels: pixels,
        ),
      );

  final collisionMask = mask(collisionPixels);
  final derivedCollisionCells = ElementCollisionMaskCodec.cellsFromPixelMask(
    mask: collisionMask,
    tileWidth: tileSize,
    tileHeight: tileSize,
    sourceWidthInTiles: spec.source.width,
    sourceHeightInTiles: spec.source.height,
  );
  if (!_sameGridPositions(derivedCollisionCells, spec.collisionCells)) {
    throw StateError('${spec.id} pixel/coarse collision cells diverge.');
  }
  return ElementCollisionProfile(
    source: ElementCollisionProfileSource.manual,
    visualMask: mask(visualPixels),
    collisionMask: collisionMask,
    occlusionMask: spec.occlusionCells.isEmpty ? null : mask(occlusionPixels),
    shapeCells: spec.collisionCells,
    cells: spec.collisionCells,
  );
}

final List<_PortElementSpec> _portElementSpecs = <_PortElementSpec>[
  const _PortElementSpec(
    id: 'el_selbrume_port_quai_droit',
    name: 'Quai droit',
    source: TilesetSourceRect(x: 0, y: 0, width: 4, height: 2),
    layerId: 'l_tile_ground',
  ),
  const _PortElementSpec(
    id: 'el_selbrume_port_quai_angle',
    name: 'Angle de quai',
    source: TilesetSourceRect(x: 4, y: 0, width: 3, height: 3),
    layerId: 'l_tile_ground',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 0, y: 1),
      GridPos(x: 0, y: 2),
      GridPos(x: 1, y: 2),
      GridPos(x: 2, y: 2),
    ],
  ),
  const _PortElementSpec(
    id: 'el_selbrume_port_quai_t',
    name: 'Jonction de quai en T',
    source: TilesetSourceRect(x: 7, y: 0, width: 4, height: 3),
    layerId: 'l_tile_ground',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 2),
      GridPos(x: 1, y: 2),
      GridPos(x: 2, y: 2),
      GridPos(x: 3, y: 2),
    ],
  ),
  const _PortElementSpec(
    id: 'el_selbrume_port_quai_fin',
    name: 'Extremite de quai',
    source: TilesetSourceRect(x: 11, y: 0, width: 3, height: 3),
    layerId: 'l_tile_ground',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 1, y: 0),
      GridPos(x: 2, y: 0),
      GridPos(x: 2, y: 1),
      GridPos(x: 0, y: 2),
      GridPos(x: 1, y: 2),
      GridPos(x: 2, y: 2),
    ],
  ),
  const _PortElementSpec(
    id: 'el_selbrume_port_escalier_quai',
    name: 'Escalier de quai',
    source: TilesetSourceRect(x: 0, y: 3, width: 3, height: 2),
    layerId: 'l_tile_ground',
  ),
  _PortElementSpec(
    id: 'el_selbrume_port_brise_lames',
    name: 'Brise-lames',
    source: const TilesetSourceRect(x: 3, y: 3, width: 6, height: 3),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[
      for (var y = 1; y < 3; y += 1)
        for (var x = 0; x < 6; x += 1) GridPos(x: x, y: y),
    ],
  ),
  _PortElementSpec(
    id: 'el_selbrume_port_hangar',
    name: 'Hangar portuaire',
    source: const TilesetSourceRect(x: 9, y: 3, width: 6, height: 5),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[
      for (var x = 1; x < 5; x += 1) GridPos(x: x, y: 0),
      for (var y = 1; y < 5; y += 1)
        for (var x = 0; x < 6; x += 1) GridPos(x: x, y: y),
    ],
    occlusionCells: <GridPos>[
      for (var x = 1; x < 5; x += 1) GridPos(x: x, y: 0),
      for (var y = 1; y < 4; y += 1)
        for (var x = 0; x < 6; x += 1) GridPos(x: x, y: y),
    ],
  ),
  const _PortElementSpec(
    id: 'el_selbrume_port_bollard',
    name: 'Bollard d amarrage',
    source: TilesetSourceRect(x: 0, y: 6, width: 1, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1)],
  ),
  const _PortElementSpec(
    id: 'el_selbrume_port_corde',
    name: 'Cordage',
    source: TilesetSourceRect(x: 1, y: 6, width: 2, height: 1),
    layerId: 'l_tile_ground',
  ),
  const _PortElementSpec(
    id: 'el_selbrume_port_filets',
    name: 'Filets de peche',
    source: TilesetSourceRect(x: 3, y: 6, width: 3, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ],
    occlusionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 1, y: 0),
      GridPos(x: 2, y: 0),
    ],
  ),
  const _PortElementSpec(
    id: 'el_selbrume_port_caisses',
    name: 'Caisses du port',
    source: TilesetSourceRect(x: 6, y: 6, width: 3, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
    ],
    occlusionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 1, y: 0),
      GridPos(x: 2, y: 0),
    ],
  ),
  const _PortElementSpec(
    id: 'el_selbrume_port_tonneaux',
    name: 'Tonneaux du port',
    source: TilesetSourceRect(x: 0, y: 8, width: 2, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ],
    occlusionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 1, y: 0),
    ],
  ),
  const _PortElementSpec(
    id: 'el_selbrume_port_bouees',
    name: 'Bouees du port',
    source: TilesetSourceRect(x: 2, y: 8, width: 2, height: 2),
    layerId: 'l_tile_ground',
  ),
  const _PortElementSpec(
    id: 'el_selbrume_port_nid_vide',
    name: 'Nid de Goelise vide',
    source: TilesetSourceRect(x: 4, y: 8, width: 2, height: 2),
    layerId: 'l_tile_ground',
    isStateVariant: true,
  ),
  const _PortElementSpec(
    id: 'el_selbrume_port_nid_brillant',
    name: 'Nid de Goelise brillant',
    source: TilesetSourceRect(x: 6, y: 8, width: 2, height: 2),
    layerId: 'l_tile_fx',
    isStateVariant: true,
  ),
  const _PortElementSpec(
    id: 'el_selbrume_port_panneau',
    name: 'Panneau du port',
    source: TilesetSourceRect(x: 8, y: 8, width: 2, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1)],
    occlusionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 1, y: 0),
    ],
  ),
];

ProjectPathPatternPreset _task5OpenSeaPattern() => ProjectPathPatternPreset(
      id: 'pp_selbrume_open_sea_loop',
      name: 'Boucle marine ouverte de Selbrume',
      basePathPresetId: 'nouveau-chemin',
      centerPattern: PathCenterPattern(
        size: PathCenterPatternSize(width: 2, height: 2),
        cells: <PathCenterPatternCell>[
          for (var localY = 0; localY < 2; localY += 1)
            for (var localX = 0; localX < 2; localX += 1)
              PathCenterPatternCell(
                localX: localX,
                localY: localY,
                frames: <TilesetVisualFrame>[
                  for (var frameIndex = 0; frameIndex < 32; frameIndex += 1)
                    TilesetVisualFrame(
                      tilesetId: 'ts_selbrume_open_sea_loop',
                      source: TilesetSourceRect(
                        x: 2 * frameIndex + localX,
                        y: localY,
                        width: 1,
                        height: 1,
                      ),
                      durationMs: 100,
                    ),
                ],
              ),
        ],
      ),
    );

Map<String, dynamic> _withoutFullMapReferenceLayer(
  Map<String, dynamic> source, {
  required String mapId,
}) {
  final cleaned = _deepJsonCopy(source);
  final layers = _jsonObjectList(
    cleaned['layers'],
    context: '$mapId layers',
  );
  final objectiveLayers = layers.where(
    (layer) => layer['id'] == 'l_tile_objectif',
  );
  if (objectiveLayers.length != 1) {
    throw StateError(
      '$mapId must contain exactly one l_tile_objectif seed layer; '
      'found ${objectiveLayers.length}.',
    );
  }
  final placedElements = _jsonObjectList(
    cleaned['placedElements'],
    context: '$mapId placedElements',
  );
  final objectivePlacements = placedElements.where(
    (placed) => placed['layerId'] == 'l_tile_objectif',
  );
  if (objectivePlacements.isEmpty) {
    throw StateError(
      '$mapId must contain a placement hosted by l_tile_objectif.',
    );
  }
  cleaned['layers'] = <Map<String, dynamic>>[
    for (final layer in layers)
      if (layer['id'] != 'l_tile_objectif') layer,
  ];
  cleaned['placedElements'] = <Map<String, dynamic>>[
    for (final placed in placedElements)
      if (placed['layerId'] != 'l_tile_objectif') placed,
  ];
  return cleaned;
}

Map<String, dynamic> _withBourgPortCauseway(
  Map<String, dynamic> source,
) {
  const mapId = 'map_bourg_selbrume';
  const width = 55;
  const height = 55;
  final cleaned = _deepJsonCopy(source);
  final map = MapData.fromJson(cleaned);
  if (map.id != mapId ||
      map.size != const GridSize(width: width, height: height)) {
    throw StateError('$mapId must remain 55x55 before painting its Port exit.');
  }
  final layers = _jsonObjectList(cleaned['layers'], context: '$mapId layers');

  List<dynamic> mutableCells(String layerId, String field) {
    final matching = layers.where((layer) => layer['id'] == layerId);
    if (matching.length != 1) {
      throw StateError('$mapId must contain exactly one $layerId layer.');
    }
    final rawCells = matching.single[field];
    if (rawCells is! List || rawCells.length != width * height) {
      throw StateError('$mapId $layerId.$field must contain 3025 cells.');
    }
    if (rawCells.any((cell) => cell is! bool)) {
      throw StateError('$mapId $layerId.$field must contain booleans only.');
    }
    final cells = List<dynamic>.from(rawCells);
    matching.single[field] = cells;
    return cells;
  }

  final portPath = mutableCells('l_path_path', 'cells');
  final ocean = mutableCells('l_path_oc_an', 'cells');
  final collisions = mutableCells('l_collisions', 'collisions');
  for (var y = 46; y < height; y += 1) {
    for (var x = 26; x <= 30; x += 1) {
      final index = y * width + x;
      portPath[index] = true;
      ocean[index] = false;
      collisions[index] = false;
    }
  }
  return cleaned;
}

Map<String, dynamic> _migrateSeedMap(
  Map<String, dynamic> source, {
  required String id,
  required String name,
  required MapMetadata metadata,
  required List<MapConnection> connections,
  required List<MapWarp> warps,
}) {
  final migrated = _deepJsonCopy(source);
  migrated['id'] = id;
  migrated['name'] = name;
  migrated['connections'] = <Map<String, dynamic>>[
    for (final connection in connections) connection.toJson(),
  ];
  migrated['warps'] = <Map<String, dynamic>>[
    for (final warp in warps) warp.toJson(),
  ];
  migrated['mapMetadata'] = metadata.toJson();
  return migrated;
}

void _validateTask7BourgSeed(Map<String, dynamic> source) {
  final semanticProjection = <String, dynamic>{
    'size': source['size'],
    'tilesetId': source['tilesetId'],
    'layers': source['layers'],
    'placedElements': source['placedElements'],
    'entities': source['entities'],
    'triggers': source['triggers'],
    'gameplayZones': source['gameplayZones'],
    'events': source['events'],
  };
  final semanticSha256 = narrativeEventCanonicalSha256(semanticProjection);
  if (semanticSha256 != _task0BourgSemanticCanonicalSha256) {
    throw StateError(
      'Task 7 Bourg seed semantic fingerprint drifted from Task 0 '
      '($_task0BourgSemanticFingerprint); canonical sha256 expected '
      '$_task0BourgSemanticCanonicalSha256, got $semanticSha256.',
    );
  }

  final navigationProjection = <String, dynamic>{
    ...semanticProjection,
    'connections': source['connections'],
    'warps': source['warps'],
  };
  final navigationSha256 = narrativeEventCanonicalSha256(navigationProjection);
  if (navigationSha256 != _task0BourgNavigationCanonicalSha256) {
    throw StateError(
      'Task 7 Bourg seed navigation fingerprint drifted from Task 0 '
      '($_task0BourgNavigationFingerprint); canonical sha256 expected '
      '$_task0BourgNavigationCanonicalSha256, got $navigationSha256.',
    );
  }
}

MapData _buildBourgPilot(Map<String, dynamic> sourceJson) {
  const width = 55;
  const height = 55;
  final source = MapData.fromJson(_deepJsonCopy(sourceJson));
  if (source.id != 'Selbrume' ||
      source.size != const GridSize(width: width, height: height)) {
    throw StateError('Task 7 Bourg seed must be Selbrume.json at 55x55.');
  }

  final terrain = source.layers
      .whereType<TerrainLayer>()
      .singleWhere((layer) => layer.id == 'l_terrain');
  final pavement = source.layers
      .whereType<PathLayer>()
      .singleWhere((layer) => layer.id == 'l_path_path');
  final ocean = source.layers
      .whereType<PathLayer>()
      .singleWhere((layer) => layer.id == 'l_path_oc_an');
  final sourceCollision = source.layers
      .whereType<CollisionLayer>()
      .singleWhere((layer) => layer.id == 'l_collisions');
  final primaryCells = List<bool>.from(pavement.cells);
  final waterCells = List<bool>.from(ocean.cells);
  final collisionCells = List<bool>.from(sourceCollision.collisions);

  void paintWalkable(_CellRect rectangle) {
    if (rectangle.x < 0 ||
        rectangle.y < 0 ||
        rectangle.x + rectangle.width > width ||
        rectangle.y + rectangle.height > height) {
      throw StateError('Task 7 Bourg corridor is out of bounds: $rectangle');
    }
    for (var y = rectangle.y; y < rectangle.y + rectangle.height; y += 1) {
      for (var x = rectangle.x; x < rectangle.x + rectangle.width; x += 1) {
        final index = y * width + x;
        primaryCells[index] = true;
        waterCells[index] = false;
        collisionCells[index] = false;
      }
    }
  }

  paintWalkable(const _CellRect(26, 46, 5, 9));
  paintWalkable(const _CellRect(17, 24, 38, 5));
  paintWalkable(const _CellRect(12, 22, 6, 4));
  paintWalkable(const _CellRect(25, 19, 5, 4));
  for (var index = 0; index < primaryCells.length; index += 1) {
    if (!primaryCells[index]) continue;
    waterCells[index] = false;
    collisionCells[index] = false;
  }
  for (var y = 0; y < height; y += 1) {
    if (y >= 24 && y <= 28) continue;
    final index = y * width + (width - 1);
    primaryCells[index] = false;
    collisionCells[index] = true;
  }
  for (var x = 0; x < width; x += 1) {
    if (x >= 26 && x <= 30) continue;
    final index = (height - 1) * width + x;
    primaryCells[index] = false;
    collisionCells[index] = true;
  }

  const placementLayerBySeedLayer = <String, String>{
    'l_tile_ponton': 'l_tile_ground',
    'l_tile_rock_cliff': 'l_tile_structures',
    'l_tile_trees': 'l_tile_overhead',
    'l_tile_parasol_lampadaire': 'l_tile_structures',
    'l_tile_maison_selbrume': 'l_tile_structures',
    'l_tile_grass_element': 'l_tile_ground',
    'l_tile_plant_elements': 'l_tile_ground',
  };
  final placements = <MapPlacedElement>[];
  for (final placed in source.placedElements) {
    if (placed.layerId == 'l_tile_objectif') continue;
    final targetLayerId = placementLayerBySeedLayer[placed.layerId];
    if (targetLayerId == null) {
      throw StateError(
        'Task 7 cannot map Bourg placement ${placed.id} from '
        '${placed.layerId}.',
      );
    }
    placements.add(
      placed.copyWith(
        id: _canonicalBourgPlacementId(placed),
        layerId: targetLayerId,
      ),
    );
  }

  const count = width * height;
  return source.copyWith(
    id: 'map_bourg_selbrume',
    name: 'Bourg de Selbrume',
    tilesetId: '',
    properties: <String, dynamic>{
      ...source.properties,
      'selbrumeGeneratorBoundary': 'task7',
    },
    layers: <MapLayer>[
      MapLayer.terrain(
        id: 'l_terrain',
        name: 'Terrain',
        terrains: List<TerrainType>.from(terrain.terrains),
      ),
      MapLayer.path(
        id: 'l_path_primary',
        name: 'Chemin principal',
        presetId: 'pavement_path',
        cells: primaryCells,
      ),
      MapLayer.path(
        id: 'l_path_secondary',
        name: 'Cote et ocean',
        presetId: 'nouveau-chemin',
        cells: waterCells,
      ),
      MapLayer.tile(
        id: 'l_tile_ground',
        name: 'Decors au sol',
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.tile(
        id: 'l_tile_structures',
        name: 'Structures',
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.tile(
        id: 'l_tile_overhead',
        name: 'Occlusion',
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.tile(
        id: 'l_tile_fx',
        name: 'Effets',
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.collision(
        id: 'l_collisions',
        name: 'Collisions',
        collisions: collisionCells,
      ),
    ],
    placedElements: placements,
    connections: const <MapConnection>[
      MapConnection(
        direction: MapConnectionDirection.south,
        targetMapId: 'map_port_brisants',
      ),
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'map_bois_chaise_brume',
      ),
    ],
    warps: const <MapWarp>[
      MapWarp(
        id: 'warp_bourg_to_maison',
        pos: GridPos(x: 13, y: 23),
        targetMapId: 'map_maison_joueur',
        targetPos: GridPos(x: 10, y: 13),
        triggerMode: MapWarpTriggerMode.onBump,
        allowedApproachFacings: <EntityFacing>[EntityFacing.south],
        triggerPadding: WarpTriggerPadding(bottom: 8),
      ),
    ],
    mapMetadata: const MapMetadata(
      displayName: 'Bourg de Selbrume',
      mapType: MapType.city,
      isIndoor: false,
      allowEscapeRope: false,
      defaultSpawnId: 'spawn',
      tags: <String>['selbrume', 'beta', 'map-production'],
    ),
  );
}

String _canonicalBourgPlacementId(MapPlacedElement placed) {
  final key = '${placed.elementId}@${placed.pos.x},${placed.pos.y}';
  return switch (key) {
    'selbrum_maison_1@10,18' => 'pe_bourg_maison_joueur_facade',
    'selbrume_centre_pok_mon@29,22' => 'pe_bourg_centre_facade',
    'le_puits@23,27' => 'pe_bourg_puits',
    'kiosque_l_gumes@36,35' => 'pe_bourg_kiosque',
    _ => placed.id,
  };
}

MapData _buildPort() => MapData(
      id: 'map_port_brisants',
      name: 'Port des Brisants',
      size: const GridSize(width: 45, height: 45),
      tilesetId: 'arbre_pixellab',
      layers: _exteriorLayers(
        width: 45,
        height: 45,
        terrain: TerrainType.stone,
        primaryRects: const <_CellRect>[
          _CellRect(26, 0, 5, 27),
          _CellRect(17, 16, 14, 10),
          _CellRect(8, 18, 20, 3),
          _CellRect(28, 7, 9, 4),
        ],
        secondaryRects: const <_CellRect>[
          _CellRect(3, 28, 10, 4),
          _CellRect(5, 4, 5, 5),
        ],
      ),
      connections: const <MapConnection>[
        MapConnection(
          direction: MapConnectionDirection.north,
          targetMapId: 'map_bourg_selbrume',
        ),
      ],
      gameplayZones: <MapGameplayZone>[
        _specialZone('zone_port_entry', 24, 0, 8, 5),
        _specialZone('zone_port_center', 17, 16, 12, 10),
      ],
      triggers: <MapTrigger>[
        _reservedTrigger(
          'zone_port_entry',
          'event_enter_port_alert',
          24,
          0,
          8,
          5,
        ),
        _reservedTrigger(
          'zone_port_center',
          'event_ending_port',
          17,
          16,
          12,
          10,
        ),
        _reservedTrigger(
          'tr_port_rival_scene',
          'event_selbrume_port_rival_scene',
          17,
          17,
          10,
          8,
        ),
        _reservedTrigger(
          'tr_port_nest',
          'event_selbrume_port_nest',
          6,
          5,
          2,
          2,
        ),
      ],
      mapMetadata: const MapMetadata(
        displayName: 'Port des Brisants',
        mapType: MapType.city,
        isIndoor: false,
        allowEscapeRope: false,
        tags: <String>['selbrume', 'beta', 'map-production'],
      ),
    );

MapData _buildPortPilot() => MapData(
      id: 'map_port_brisants',
      name: 'Port des Brisants',
      size: const GridSize(width: 45, height: 45),
      tilesetId: '',
      layers: _portPilotLayers(),
      placedElements: const <MapPlacedElement>[
        MapPlacedElement(
          id: 'pe_port_bateau',
          layerId: 'l_tile_structures',
          elementId: 'el_selbrume_port_bateau',
          pos: GridPos(x: 3, y: 30),
        ),
        MapPlacedElement(
          id: 'pe_port_hangar',
          layerId: 'l_tile_structures',
          elementId: 'el_selbrume_port_hangar',
          pos: GridPos(x: 35, y: 12),
        ),
        MapPlacedElement(
          id: 'pe_port_brise_lames_001',
          layerId: 'l_tile_structures',
          elementId: 'el_selbrume_port_brise_lames',
          pos: GridPos(x: 0, y: 25),
        ),
        MapPlacedElement(
          id: 'pe_port_quai_droit_001',
          layerId: 'l_tile_ground',
          elementId: 'el_selbrume_port_quai_droit',
          pos: GridPos(x: 12, y: 27),
        ),
        MapPlacedElement(
          id: 'pe_port_quai_droit_002',
          layerId: 'l_tile_ground',
          elementId: 'el_selbrume_port_quai_droit',
          pos: GridPos(x: 16, y: 27),
        ),
        MapPlacedElement(
          id: 'pe_port_quai_droit_003',
          layerId: 'l_tile_ground',
          elementId: 'el_selbrume_port_quai_droit',
          pos: GridPos(x: 20, y: 27),
        ),
        MapPlacedElement(
          id: 'pe_port_quai_droit_004',
          layerId: 'l_tile_ground',
          elementId: 'el_selbrume_port_quai_droit',
          pos: GridPos(x: 24, y: 27),
        ),
        MapPlacedElement(
          id: 'pe_port_quai_droit_005',
          layerId: 'l_tile_ground',
          elementId: 'el_selbrume_port_quai_droit',
          pos: GridPos(x: 28, y: 27),
        ),
        MapPlacedElement(
          id: 'pe_port_quai_angle_001',
          layerId: 'l_tile_ground',
          elementId: 'el_selbrume_port_quai_angle',
          pos: GridPos(x: 9, y: 24),
        ),
        MapPlacedElement(
          id: 'pe_port_quai_t_001',
          layerId: 'l_tile_ground',
          elementId: 'el_selbrume_port_quai_t',
          pos: GridPos(x: 4, y: 19),
        ),
        MapPlacedElement(
          id: 'pe_port_quai_fin_001',
          layerId: 'l_tile_ground',
          elementId: 'el_selbrume_port_quai_fin',
          pos: GridPos(x: 7, y: 22),
        ),
        MapPlacedElement(
          id: 'pe_port_escalier_quai_001',
          layerId: 'l_tile_ground',
          elementId: 'el_selbrume_port_escalier_quai',
          pos: GridPos(x: 30, y: 25),
        ),
        MapPlacedElement(
          id: 'pe_port_bollard_001',
          layerId: 'l_tile_structures',
          elementId: 'el_selbrume_port_bollard',
          pos: GridPos(x: 24, y: 28),
        ),
        MapPlacedElement(
          id: 'pe_port_bollard_002',
          layerId: 'l_tile_structures',
          elementId: 'el_selbrume_port_bollard',
          pos: GridPos(x: 28, y: 28),
        ),
        MapPlacedElement(
          id: 'pe_port_corde_001',
          layerId: 'l_tile_ground',
          elementId: 'el_selbrume_port_corde',
          pos: GridPos(x: 18, y: 28),
        ),
        MapPlacedElement(
          id: 'pe_port_filets_001',
          layerId: 'l_tile_structures',
          elementId: 'el_selbrume_port_filets',
          pos: GridPos(x: 11, y: 18),
        ),
        MapPlacedElement(
          id: 'pe_port_caisses_001',
          layerId: 'l_tile_structures',
          elementId: 'el_selbrume_port_caisses',
          pos: GridPos(x: 35, y: 18),
        ),
        MapPlacedElement(
          id: 'pe_port_tonneaux_001',
          layerId: 'l_tile_structures',
          elementId: 'el_selbrume_port_tonneaux',
          pos: GridPos(x: 40, y: 18),
        ),
        MapPlacedElement(
          id: 'pe_port_bouees_001',
          layerId: 'l_tile_ground',
          elementId: 'el_selbrume_port_bouees',
          pos: GridPos(x: 10, y: 31),
          applyCollision: false,
        ),
        MapPlacedElement(
          id: 'pe_port_nid_goelise',
          layerId: 'l_tile_ground',
          elementId: 'el_selbrume_port_nid_vide',
          pos: GridPos(x: 6, y: 5),
          applyCollision: false,
          properties: <String, String>{
            'eventId': 'event_goelise_nest_found',
            'reservedForNarrative': 'true',
          },
        ),
        MapPlacedElement(
          id: 'pe_port_panneau_001',
          layerId: 'l_tile_structures',
          elementId: 'el_selbrume_port_panneau',
          pos: GridPos(x: 30, y: 9),
        ),
      ],
      entities: const <MapEntity>[
        MapEntity(
          id: 'anchor_port_lysa',
          name: 'Ancre structurelle Lysa',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 22, y: 21),
          blocksMovement: false,
          properties: <String, String>{
            'contractRole': 'reserved_character_anchor',
            'inert': 'true',
          },
        ),
        MapEntity(
          id: 'anchor_port_soline',
          name: 'Ancre structurelle Soline',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 34, y: 8),
          blocksMovement: false,
          properties: <String, String>{
            'contractRole': 'reserved_character_anchor',
            'inert': 'true',
          },
        ),
        MapEntity(
          id: 'anchor_port_pecheurs',
          name: 'Ancre structurelle Pecheurs',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 8, y: 18),
          blocksMovement: false,
          properties: <String, String>{
            'contractRole': 'reserved_character_anchor',
            'inert': 'true',
          },
        ),
      ],
      connections: const <MapConnection>[
        MapConnection(
          direction: MapConnectionDirection.north,
          targetMapId: 'map_bourg_selbrume',
        ),
      ],
      gameplayZones: <MapGameplayZone>[
        _specialZone('zone_port_entry', 24, 0, 8, 5),
        _specialZone('zone_port_center', 17, 16, 12, 10),
      ],
      triggers: <MapTrigger>[
        _reservedTrigger(
          'zone_port_entry',
          'event_enter_port_alert',
          24,
          0,
          8,
          5,
        ),
        _reservedTrigger(
          'zone_port_center',
          'event_ending_port',
          17,
          16,
          12,
          10,
        ),
        _reservedTrigger(
          'tr_port_rival_scene',
          'event_selbrume_port_rival_scene',
          17,
          17,
          10,
          8,
        ),
        _reservedTrigger(
          'tr_port_nest',
          'event_selbrume_port_nest',
          6,
          5,
          2,
          2,
        ),
      ],
      mapMetadata: const MapMetadata(
        displayName: 'Port des Brisants',
        mapType: MapType.city,
        isIndoor: false,
        allowEscapeRope: false,
        tags: <String>['selbrume', 'beta', 'map-production'],
      ),
    );

List<MapLayer> _portPilotLayers() {
  const width = 45;
  const height = 45;
  const count = width * height;
  final primary = _paintedCells(
    width,
    height,
    const <_CellRect>[
      _CellRect(26, 0, 5, 17),
      _CellRect(5, 4, 34, 9),
      _CellRect(7, 12, 4, 9),
      _CellRect(7, 17, 10, 5),
      _CellRect(14, 14, 20, 13),
      _CellRect(31, 7, 9, 14),
      _CellRect(12, 25, 22, 4),
      _CellRect(25, 27, 3, 13),
    ],
  );
  final water = _paintedCellsExcept(
    width,
    height,
    painted: const <_CellRect>[
      _CellRect(0, 22, 14, 23),
      _CellRect(34, 21, 11, 24),
      _CellRect(14, 29, 20, 16),
    ],
    cleared: const <_CellRect>[
      _CellRect(25, 29, 3, 11),
    ],
  );
  for (var index = 0; index < water.length; index += 1) {
    if (primary[index]) water[index] = false;
  }
  return <MapLayer>[
    MapLayer.terrain(
      id: 'l_terrain',
      name: 'Terrain portuaire',
      terrains: List<TerrainType>.filled(count, TerrainType.stone),
    ),
    MapLayer.path(
      id: 'l_path_primary',
      name: 'Circulation portuaire',
      presetId: 'pavement_path',
      cells: primary,
    ),
    MapLayer.path(
      id: 'l_path_secondary',
      name: 'Mer ouverte',
      presetId: 'nouveau-chemin',
      cells: water,
    ),
    MapLayer.tile(
      id: 'l_tile_ground',
      name: 'Decors au sol',
      tiles: List<int>.filled(count, 0),
    ),
    MapLayer.tile(
      id: 'l_tile_structures',
      name: 'Structures',
      tiles: List<int>.filled(count, 0),
    ),
    MapLayer.tile(
      id: 'l_tile_overhead',
      name: 'Occlusion',
      tiles: List<int>.filled(count, 0),
    ),
    MapLayer.tile(
      id: 'l_tile_fx',
      name: 'Effets',
      tiles: List<int>.filled(count, 0),
    ),
    MapLayer.collision(
      id: 'l_collisions',
      name: 'Collisions',
      collisions: List<bool>.from(water),
    ),
  ];
}

List<bool> _paintedCellsExcept(
  int width,
  int height, {
  required List<_CellRect> painted,
  required List<_CellRect> cleared,
}) {
  final cells = _paintedCells(width, height, painted);
  final clearMask = _paintedCells(width, height, cleared);
  for (var index = 0; index < cells.length; index += 1) {
    if (clearMask[index]) cells[index] = false;
  }
  return cells;
}

MapData _buildForest() => MapData(
      id: 'map_bois_chaise_brume',
      name: 'Bois de la Chaise-Brume',
      size: const GridSize(width: 45, height: 45),
      tilesetId: 'arbre_pixellab',
      layers: _exteriorLayers(
        width: 45,
        height: 45,
        terrain: TerrainType.grass,
        primaryRects: const <_CellRect>[
          _CellRect(0, 24, 45, 5),
          _CellRect(12, 13, 5, 18),
          _CellRect(29, 13, 5, 20),
          _CellRect(14, 13, 18, 4),
          _CellRect(14, 29, 18, 4),
        ],
        secondaryRects: const <_CellRect>[
          _CellRect(11, 12, 7, 7),
          _CellRect(28, 27, 7, 7),
        ],
      ),
      connections: const <MapConnection>[
        MapConnection(
          direction: MapConnectionDirection.west,
          targetMapId: 'map_bourg_selbrume',
        ),
        MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: 'map_marais_salants',
        ),
      ],
      mapMetadata: const MapMetadata(
        displayName: 'Bois de la Chaise-Brume',
        mapType: MapType.forest,
        weather: MapWeather.fog,
        isIndoor: false,
        allowEscapeRope: false,
        tags: <String>['selbrume', 'beta', 'map-production'],
      ),
    );

MapData _buildForestPilot() {
  const width = 45;
  const height = 45;
  const primaryRects = <_CellRect>[
    _CellRect(0, 24, 45, 5),
    _CellRect(12, 13, 5, 5),
    _CellRect(13, 17, 3, 7),
    _CellRect(13, 15, 13, 3),
    _CellRect(23, 17, 3, 7),
    _CellRect(29, 28, 5, 5),
    _CellRect(30, 24, 3, 4),
  ];
  const grassRects = <_CellRect>[
    _CellRect(9, 8, 8, 6),
    _CellRect(26, 9, 8, 7),
    _CellRect(7, 29, 10, 7),
    _CellRect(27, 30, 8, 6),
  ];
  final primary = _paintedCells(width, height, primaryRects);
  final tallGrass = _paintedCellsExcept(
    width,
    height,
    painted: grassRects,
    cleared: primaryRects,
  );
  const count = width * height;
  const forestTileset = 'ts_selbrume_forest_props';

  return MapData(
    id: 'map_bois_chaise_brume',
    name: 'Bois de la Chaise-Brume',
    size: const GridSize(width: width, height: height),
    tilesetId: '',
    properties: const <String, dynamic>{
      'selbrumeGeneratorBoundary': 'task9',
    },
    layers: <MapLayer>[
      MapLayer.terrain(
        id: 'l_terrain',
        name: 'Terrain',
        terrains: List<TerrainType>.filled(count, TerrainType.grass),
      ),
      MapLayer.path(
        id: 'l_path_primary',
        name: 'Chemin principal',
        presetId: 'dirth_path',
        cells: primary,
      ),
      MapLayer.path(
        id: 'l_path_secondary',
        name: 'Herbes hautes structurelles',
        presetId: 'haute_herbe',
        cells: tallGrass,
      ),
      MapLayer.tile(
        id: 'l_tile_ground',
        name: 'Decors au sol',
        tilesetId: forestTileset,
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.tile(
        id: 'l_tile_structures',
        name: 'Structures',
        tilesetId: forestTileset,
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.tile(
        id: 'l_tile_overhead',
        name: 'Canopies et occlusion',
        tilesetId: forestTileset,
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.tile(
        id: 'l_tile_fx',
        name: 'Brume basse',
        tilesetId: forestTileset,
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.collision(
        id: 'l_collisions',
        name: 'Collisions',
        collisions: List<bool>.filled(count, false),
      ),
    ],
    placedElements: const <MapPlacedElement>[
      MapPlacedElement(
        id: 'pe_bois_pin_grand_001',
        layerId: 'l_tile_overhead',
        elementId: 'el_selbrume_bois_pin_grand',
        pos: GridPos(x: 2, y: 2),
      ),
      MapPlacedElement(
        id: 'pe_bois_pin_moyen_001',
        layerId: 'l_tile_overhead',
        elementId: 'el_selbrume_bois_pin_moyen',
        pos: GridPos(x: 19, y: 2),
      ),
      MapPlacedElement(
        id: 'pe_bois_pin_petit_001',
        layerId: 'l_tile_overhead',
        elementId: 'el_selbrume_bois_pin_petit',
        pos: GridPos(x: 38, y: 3),
      ),
      MapPlacedElement(
        id: 'pe_bois_buisson_1_001',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_bois_buisson_1',
        pos: GridPos(x: 5, y: 15),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_bois_buisson_2_001',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_bois_buisson_2',
        pos: GridPos(x: 35, y: 18),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_bois_fougere_001',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_bois_fougere',
        pos: GridPos(x: 17, y: 19),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_bois_souche_001',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_bois_souche',
        pos: GridPos(x: 37, y: 29),
      ),
      MapPlacedElement(
        id: 'pe_bois_tronc_tombe_001',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_bois_tronc_tombe',
        pos: GridPos(x: 18, y: 36),
      ),
      MapPlacedElement(
        id: 'pe_bois_ronces_001',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_bois_ronces',
        pos: GridPos(x: 19, y: 20),
      ),
      MapPlacedElement(
        id: 'pe_bois_aiguilles_sol_001',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_bois_aiguilles_sol',
        pos: GridPos(x: 10, y: 18),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_bois_banc_001',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_bois_banc',
        pos: GridPos(x: 27, y: 21),
      ),
      MapPlacedElement(
        id: 'pe_bois_panneau_001',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_bois_panneau',
        pos: GridPos(x: 3, y: 21),
      ),
    ],
    connections: const <MapConnection>[
      MapConnection(
        direction: MapConnectionDirection.west,
        targetMapId: 'map_bourg_selbrume',
      ),
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'map_marais_salants',
      ),
    ],
    gameplayZones: const <MapGameplayZone>[
      MapGameplayZone(
        id: 'zone_bois_herbe_1',
        name: 'Herbes hautes nord-ouest',
        kind: GameplayZoneKind.special,
        area: MapRect(
          pos: GridPos(x: 9, y: 8),
          size: GridSize(width: 8, height: 6),
        ),
        special: SpecialZonePayload(
          properties: <String, String>{
            'contractRole': 'tall_grass_surface',
            'inert': 'true',
          },
        ),
      ),
      MapGameplayZone(
        id: 'zone_bois_herbe_2',
        name: 'Herbes hautes nord-est',
        kind: GameplayZoneKind.special,
        area: MapRect(
          pos: GridPos(x: 26, y: 9),
          size: GridSize(width: 8, height: 7),
        ),
        special: SpecialZonePayload(
          properties: <String, String>{
            'contractRole': 'tall_grass_surface',
            'inert': 'true',
          },
        ),
      ),
      MapGameplayZone(
        id: 'zone_bois_herbe_3',
        name: 'Herbes hautes sud-ouest',
        kind: GameplayZoneKind.special,
        area: MapRect(
          pos: GridPos(x: 7, y: 29),
          size: GridSize(width: 10, height: 7),
        ),
        special: SpecialZonePayload(
          properties: <String, String>{
            'contractRole': 'tall_grass_surface',
            'inert': 'true',
          },
        ),
      ),
      MapGameplayZone(
        id: 'zone_bois_herbe_4',
        name: 'Herbes hautes sud-est',
        kind: GameplayZoneKind.special,
        area: MapRect(
          pos: GridPos(x: 27, y: 30),
          size: GridSize(width: 8, height: 6),
        ),
        special: SpecialZonePayload(
          properties: <String, String>{
            'contractRole': 'tall_grass_surface',
            'inert': 'true',
          },
        ),
      ),
    ],
    mapMetadata: const MapMetadata(
      displayName: 'Bois de la Chaise-Brume',
      mapType: MapType.forest,
      weather: MapWeather.fog,
      isIndoor: false,
      allowEscapeRope: false,
      tags: <String>['selbrume', 'beta', 'map-production'],
    ),
  );
}

MapData _buildMarshPilot(Map<String, dynamic> sourceJson) {
  const width = 45;
  const height = 45;
  const count = width * height;
  const marshTileset = 'ts_selbrume_marsh_props';
  const primaryRects = <_CellRect>[
    _CellRect(0, 24, 35, 5),
    _CellRect(30, 24, 5, 21),
    _CellRect(0, 22, 5, 7),
    _CellRect(9, 11, 3, 14),
    _CellRect(9, 11, 7, 3),
    _CellRect(13, 7, 3, 18),
    _CellRect(31, 10, 3, 15),
    _CellRect(31, 21, 8, 3),
    _CellRect(7, 24, 3, 9),
    _CellRect(5, 18, 3, 7),
    _CellRect(23, 20, 4, 5),
    _CellRect(18, 16, 3, 9),
    _CellRect(20, 17, 2, 8),
  ];
  const encounterRects = <_CellRect>[
    _CellRect(1, 27, 2, 8),
    _CellRect(3, 27, 3, 6),
    _CellRect(4, 28, 3, 8),
    _CellRect(7, 31, 5, 3),
    _CellRect(10, 32, 3, 2),
  ];
  final primary = _paintedCells(width, height, primaryRects);
  final secondary = _paintedCellsExcept(
    width,
    height,
    painted: encounterRects,
    cleared: primaryRects,
  );
  final staticCollisions = <bool>[
    for (var index = 0; index < count; index += 1)
      !primary[index] && !secondary[index],
  ];
  final source = MapData.fromJson(_deepJsonCopy(sourceJson));

  return MapData(
    id: 'map_marais_salants',
    name: 'Marais Salants',
    size: const GridSize(width: width, height: height),
    tilesetId: '',
    properties: const <String, dynamic>{
      'selbrumeGeneratorBoundary': 'task10',
    },
    layers: <MapLayer>[
      MapLayer.terrain(
        id: 'l_terrain',
        name: 'Terrain du marais',
        terrains: List<TerrainType>.filled(count, TerrainType.grass),
      ),
      MapLayer.path(
        id: 'l_path_primary',
        name: 'Digues et passerelles',
        presetId: 'pavement_path',
        cells: primary,
      ),
      MapLayer.path(
        id: 'l_path_secondary',
        name: 'Herbes hautes du marais',
        presetId: 'haute_herbe',
        cells: secondary,
      ),
      MapLayer.tile(
        id: 'l_tile_ground',
        name: 'Decors au sol',
        tilesetId: marshTileset,
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.tile(
        id: 'l_tile_structures',
        name: 'Structures',
        tilesetId: marshTileset,
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.tile(
        id: 'l_tile_overhead',
        name: 'Toits et occlusion',
        tilesetId: marshTileset,
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.tile(
        id: 'l_tile_fx',
        name: 'Effets du marais',
        tilesetId: marshTileset,
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.collision(
        id: 'l_collisions',
        name: 'Bassins et obstacles',
        collisions: staticCollisions,
      ),
    ],
    placedElements: const <MapPlacedElement>[
      MapPlacedElement(
        id: 'pe_marais_cabane_paludier',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_marais_cabane_paludier',
        pos: GridPos(x: 4, y: 14),
      ),
      MapPlacedElement(
        id: 'pe_marais_passerelle_h',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_marais_passerelle_h',
        pos: GridPos(x: 17, y: 24),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_marais_passerelle_v',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_marais_passerelle_v',
        pos: GridPos(x: 31, y: 29),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_marais_passerelle_angle',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_marais_passerelle_angle',
        pos: GridPos(x: 18, y: 16),
      ),
      MapPlacedElement(
        id: 'pe_marais_ecluse',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_marais_ecluse_fermee',
        pos: GridPos(x: 27, y: 18),
      ),
      MapPlacedElement(
        id: 'pe_marais_roseaux_1',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_marais_roseaux_1',
        pos: GridPos(x: 2, y: 38),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_marais_roseaux_2',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_marais_roseaux_2',
        pos: GridPos(x: 39, y: 5),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_marais_roseaux_3',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_marais_roseaux_3',
        pos: GridPos(x: 16, y: 3),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_marais_sel_petit',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_marais_sel_petit',
        pos: GridPos(x: 19, y: 8),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_marais_sel_moyen',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_marais_sel_moyen',
        pos: GridPos(x: 22, y: 10),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_marais_sel_grand',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_marais_sel_grand',
        pos: GridPos(x: 18, y: 34),
      ),
      MapPlacedElement(
        id: 'pe_marais_rateau',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_marais_rateau',
        pos: GridPos(x: 27, y: 12),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_marais_indice_verre',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_indice_verre',
        pos: GridPos(x: 8, y: 32),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_marais_indice_traces_electriques',
        layerId: 'l_tile_fx',
        elementId: 'el_selbrume_indice_traces_electriques',
        pos: GridPos(x: 32, y: 10),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_marais_indice_repere_lentille',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_indice_repere_lentille',
        pos: GridPos(x: 34, y: 34),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_marais_cristal_1',
        layerId: 'l_tile_fx',
        elementId: 'el_selbrume_cristal_1',
        pos: GridPos(x: 14, y: 7),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_marais_cristal_2',
        layerId: 'l_tile_fx',
        elementId: 'el_selbrume_cristal_2',
        pos: GridPos(x: 24, y: 28),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_marais_cristal_3',
        layerId: 'l_tile_fx',
        elementId: 'el_selbrume_cristal_3',
        pos: GridPos(x: 38, y: 22),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_marais_passerelle_t',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_marais_passerelle_t',
        pos: GridPos(x: 30, y: 24),
      ),
      MapPlacedElement(
        id: 'pe_marais_roseaux_4',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_marais_roseaux_4',
        pos: GridPos(x: 2, y: 8),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_marais_roseaux_5',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_marais_roseaux_5',
        pos: GridPos(x: 36, y: 31),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_marais_roseaux_6',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_marais_roseaux_6',
        pos: GridPos(x: 40, y: 36),
        applyCollision: false,
      ),
    ],
    entities: <MapEntity>[
      ...source.entities,
      const MapEntity(
        id: 'anchor_marais_mado',
        name: 'Ancre structurelle Mado',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 10, y: 12),
        blocksMovement: false,
        properties: <String, String>{
          'contractRole': 'reserved_character_anchor',
          'inert': 'true',
        },
      ),
    ],
    connections: const <MapConnection>[
      MapConnection(
        direction: MapConnectionDirection.west,
        targetMapId: 'map_bois_chaise_brume',
      ),
      MapConnection(
        direction: MapConnectionDirection.south,
        targetMapId: 'map_passage_dames',
      ),
    ],
    gameplayZones: <MapGameplayZone>[
      ...source.gameplayZones,
      _specialZone('zone_marais_entry', 0, 22, 5, 7),
    ],
    triggers: <MapTrigger>[
      _reservedTrigger(
        'zone_marais_entry',
        'event_marais_entry',
        0,
        22,
        5,
        7,
      ),
      _reservedTrigger(
        'tr_marais_indice_verre',
        'event_selbrume_indice_verre',
        8,
        32,
        1,
        1,
      ),
      _reservedTrigger(
        'tr_marais_indice_traces_electriques',
        'event_selbrume_indice_traces_electriques',
        32,
        10,
        1,
        1,
      ),
      _reservedTrigger(
        'tr_marais_indice_repere_lentille',
        'event_selbrume_indice_repere_lentille',
        34,
        34,
        1,
        1,
      ),
      _reservedTrigger(
        'tr_marais_cristal_1',
        'event_selbrume_cristal_1',
        14,
        7,
        1,
        1,
      ),
      _reservedTrigger(
        'tr_marais_cristal_2',
        'event_selbrume_cristal_2',
        24,
        28,
        1,
        1,
      ),
      _reservedTrigger(
        'tr_marais_cristal_3',
        'event_selbrume_cristal_3',
        38,
        22,
        1,
        1,
      ),
    ],
    mapMetadata: const MapMetadata(
      displayName: 'Marais Salants',
      mapType: MapType.route,
      weather: MapWeather.fog,
      isIndoor: false,
      allowEscapeRope: false,
      tags: <String>['selbrume', 'beta', 'map-production'],
    ),
  );
}

MapData _buildPassage() => MapData(
      id: 'map_passage_dames',
      name: 'Passage des Dames',
      size: const GridSize(width: 60, height: 24),
      tilesetId: 'arbre_pixellab',
      layers: _exteriorLayers(
        width: 60,
        height: 24,
        terrain: TerrainType.rock,
        primaryRects: const <_CellRect>[
          _CellRect(30, 0, 5, 17),
          _CellRect(30, 12, 30, 5),
          _CellRect(48, 8, 5, 9),
        ],
        secondaryRects: const <_CellRect>[
          _CellRect(28, 0, 9, 5),
          _CellRect(48, 8, 5, 5),
        ],
      ),
      connections: const <MapConnection>[
        MapConnection(
          direction: MapConnectionDirection.north,
          targetMapId: 'map_marais_salants',
        ),
        MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: 'map_phare_exterieur',
        ),
      ],
      gameplayZones: <MapGameplayZone>[
        _specialZone('zone_passage_entry', 28, 0, 9, 5),
      ],
      triggers: <MapTrigger>[
        _reservedTrigger(
          'tr_passage_entry',
          'event_enter_passage_dames',
          28,
          0,
          9,
          5,
        ),
      ],
      mapMetadata: const MapMetadata(
        displayName: 'Passage des Dames',
        mapType: MapType.route,
        weather: MapWeather.fog,
        isIndoor: false,
        allowEscapeRope: false,
        tags: <String>['selbrume', 'beta', 'map-production'],
      ),
    );

MapData _buildPassagePilot() {
  const width = 60;
  const height = 24;
  const count = width * height;
  const passageTileset = 'ts_selbrume_passage_props';
  const primaryRects = <_CellRect>[
    _CellRect(28, 0, 9, 7),
    _CellRect(30, 5, 5, 12),
    _CellRect(30, 12, 30, 5),
    _CellRect(48, 8, 5, 9),
  ];
  final primary = _paintedCells(width, height, primaryRects);
  final sea = <bool>[for (final cell in primary) !cell];

  return MapData(
    id: 'map_passage_dames',
    name: 'Passage des Dames',
    size: const GridSize(width: width, height: height),
    tilesetId: '',
    properties: const <String, dynamic>{
      'selbrumeGeneratorBoundary': 'task11',
    },
    layers: <MapLayer>[
      MapLayer.terrain(
        id: 'l_terrain',
        name: 'Fond rocheux du Passage',
        terrains: List<TerrainType>.filled(count, TerrainType.rock),
      ),
      MapLayer.path(
        id: 'l_path_primary',
        name: 'Chaussee du Passage',
        presetId: 'pavement_path',
        cells: primary,
      ),
      MapLayer.path(
        id: 'l_path_secondary',
        name: 'Mer du Passage',
        presetId: 'nouveau-chemin',
        cells: sea,
      ),
      MapLayer.tile(
        id: 'l_tile_ground',
        name: 'Decors de chaussee',
        tilesetId: passageTileset,
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.tile(
        id: 'l_tile_structures',
        name: 'Barrieres et balises',
        tilesetId: passageTileset,
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.tile(
        id: 'l_tile_overhead',
        name: 'Occlusion',
        tilesetId: passageTileset,
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.tile(
        id: 'l_tile_fx',
        name: 'Ecume et brume',
        tilesetId: passageTileset,
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.collision(
        id: 'l_collisions',
        name: 'Mer et bords de chaussee',
        collisions: List<bool>.from(sea),
      ),
    ],
    placedElements: const <MapPlacedElement>[
      MapPlacedElement(
        id: 'pe_passage_barriere',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_passage_barriere_fermee',
        pos: GridPos(x: 32, y: 3),
      ),
      MapPlacedElement(
        id: 'pe_passage_borne',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_passage_borne',
        pos: GridPos(x: 37, y: 7),
      ),
      MapPlacedElement(
        id: 'pe_passage_panneau',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_passage_panneau',
        pos: GridPos(x: 27, y: 7),
      ),
      MapPlacedElement(
        id: 'pe_passage_chaussee_humide',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_passage_chaussee_humide',
        pos: GridPos(x: 30, y: 7),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_passage_ecume_h',
        layerId: 'l_tile_fx',
        elementId: 'el_selbrume_passage_ecume_h',
        pos: GridPos(x: 24, y: 11),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_passage_ecume_v',
        layerId: 'l_tile_fx',
        elementId: 'el_selbrume_passage_ecume_v',
        pos: GridPos(x: 38, y: 8),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_passage_algues',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_passage_algues',
        pos: GridPos(x: 39, y: 12),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_passage_balanes',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_passage_balanes',
        pos: GridPos(x: 45, y: 16),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_passage_bois_flotte',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_passage_bois_flotte',
        pos: GridPos(x: 20, y: 18),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_passage_marches',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_passage_marches',
        pos: GridPos(x: 56, y: 13),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_passage_chaussee_seche',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_passage_chaussee_seche',
        pos: GridPos(x: 42, y: 12),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_passage_flaques',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_passage_flaques',
        pos: GridPos(x: 49, y: 9),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_passage_banc_brume',
        layerId: 'l_tile_fx',
        elementId: 'el_selbrume_passage_banc_brume',
        pos: GridPos(x: 42, y: 10),
        applyCollision: false,
      ),
    ],
    connections: const <MapConnection>[
      MapConnection(
        direction: MapConnectionDirection.north,
        targetMapId: 'map_marais_salants',
      ),
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'map_phare_exterieur',
      ),
    ],
    gameplayZones: <MapGameplayZone>[
      _specialZone('zone_passage_entry', 28, 0, 9, 5),
    ],
    triggers: <MapTrigger>[
      _reservedTrigger(
        'zone_passage_entry',
        'event_enter_passage_dames',
        28,
        0,
        9,
        5,
      ),
    ],
    mapMetadata: const MapMetadata(
      displayName: 'Passage des Dames',
      mapType: MapType.route,
      weather: MapWeather.fog,
      isIndoor: false,
      allowEscapeRope: false,
      tags: <String>['selbrume', 'beta', 'map-production'],
    ),
  );
}

MapData _buildLighthouseExterior() => MapData(
      id: 'map_phare_exterieur',
      name: "Vieux Phare d'Ecume - Exterieur",
      size: const GridSize(width: 45, height: 45),
      tilesetId: 'arbre_pixellab',
      layers: _exteriorLayers(
        width: 45,
        height: 45,
        terrain: TerrainType.rock,
        primaryRects: const <_CellRect>[
          _CellRect(0, 12, 25, 5),
          _CellRect(21, 12, 5, 9),
          _CellRect(8, 18, 17, 4),
          _CellRect(6, 20, 5, 16),
        ],
        secondaryRects: const <_CellRect>[
          _CellRect(0, 10, 8, 8),
          _CellRect(18, 7, 11, 14),
        ],
      ),
      connections: const <MapConnection>[
        MapConnection(
          direction: MapConnectionDirection.west,
          targetMapId: 'map_passage_dames',
        ),
      ],
      warps: const <MapWarp>[
        MapWarp(
          id: 'warp_phare_ext_to_interieur',
          pos: GridPos(x: 23, y: 18),
          targetMapId: 'map_phare_interieur',
          targetPos: GridPos(x: 18, y: 42),
        ),
        MapWarp(
          id: 'warp_phare_ext_to_cabane',
          pos: GridPos(x: 8, y: 33),
          targetMapId: 'map_cabane_gardien',
          targetPos: GridPos(x: 10, y: 13),
        ),
      ],
      gameplayZones: <MapGameplayZone>[
        _specialZone('zone_lighthouse_entry', 0, 10, 8, 8),
      ],
      triggers: <MapTrigger>[
        _reservedTrigger(
          'tr_lighthouse_entry',
          'event_lighthouse_exterior_arrival',
          0,
          10,
          8,
          8,
        ),
      ],
      mapMetadata: const MapMetadata(
        displayName: "Vieux Phare d'Ecume - Exterieur",
        mapType: MapType.building,
        weather: MapWeather.fog,
        isIndoor: false,
        allowEscapeRope: false,
        tags: <String>['selbrume', 'beta', 'map-production'],
      ),
    );

MapData _buildLighthouseExteriorPilot() {
  const width = 45;
  const height = 45;
  const count = width * height;
  const lighthouseTileset = 'ts_selbrume_lighthouse_exterior';
  const primaryRects = <_CellRect>[
    _CellRect(0, 12, 18, 5),
    _CellRect(14, 15, 4, 6),
    _CellRect(14, 18, 15, 5),
    _CellRect(22, 17, 5, 6),
    _CellRect(4, 20, 10, 16),
  ];
  const landRects = <_CellRect>[
    _CellRect(0, 8, 32, 24),
    _CellRect(3, 24, 15, 16),
    _CellRect(14, 5, 19, 20),
  ];
  final primary = _paintedCells(width, height, primaryRects);
  final land = _paintedCells(width, height, landRects);
  final secondary = <bool>[
    for (var index = 0; index < count; index += 1)
      land[index] && !primary[index],
  ];
  final staticCollisions = <bool>[for (final cell in land) !cell];

  return MapData(
    id: 'map_phare_exterieur',
    name: "Vieux Phare d'Ecume - Exterieur",
    size: const GridSize(width: width, height: height),
    tilesetId: '',
    properties: const <String, dynamic>{
      'selbrumeGeneratorBoundary': 'task12',
    },
    layers: <MapLayer>[
      MapLayer.terrain(
        id: 'l_terrain',
        name: 'Ilot rocheux du phare',
        terrains: List<TerrainType>.filled(count, TerrainType.rock),
      ),
      MapLayer.path(
        id: 'l_path_primary',
        name: 'Approches du phare',
        presetId: 'pavement_path',
        cells: primary,
      ),
      MapLayer.path(
        id: 'l_path_secondary',
        name: 'Sols secondaires du phare',
        presetId: 'dirth_path',
        cells: secondary,
      ),
      MapLayer.tile(
        id: 'l_tile_ground',
        name: 'Fondations et marches',
        tilesetId: lighthouseTileset,
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.tile(
        id: 'l_tile_structures',
        name: 'Phare et cabane',
        tilesetId: lighthouseTileset,
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.tile(
        id: 'l_tile_overhead',
        name: 'Occlusion',
        tilesetId: lighthouseTileset,
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.tile(
        id: 'l_tile_fx',
        name: 'Brume et lumiere',
        tilesetId: lighthouseTileset,
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.collision(
        id: 'l_collisions',
        name: 'Mer et falaises',
        collisions: staticCollisions,
      ),
    ],
    placedElements: const <MapPlacedElement>[
      MapPlacedElement(
        id: 'pe_phare_batiment',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_phare_batiment',
        pos: GridPos(x: 19, y: 8),
      ),
      MapPlacedElement(
        id: 'pe_phare_cabane_facade',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_cabane_facade',
        pos: GridPos(x: 6, y: 28),
      ),
      MapPlacedElement(
        id: 'pe_phare_porte_ouverte',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_phare_porte_ouverte',
        pos: GridPos(x: 22, y: 16),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_phare_cabane_porte_ouverte',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_cabane_porte_ouverte',
        pos: GridPos(x: 7, y: 32),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_phare_fenetre_sombre',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_phare_fenetre_sombre',
        pos: GridPos(x: 21, y: 11),
        applyCollision: false,
      ),
      MapPlacedElement(
        id: 'pe_phare_rambarde',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_phare_rambarde',
        pos: GridPos(x: 29, y: 19),
      ),
      MapPlacedElement(
        id: 'pe_phare_fondation',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_phare_fondation',
        pos: GridPos(x: 19, y: 17),
      ),
      MapPlacedElement(
        id: 'pe_phare_panneau',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_phare_panneau',
        pos: GridPos(x: 2, y: 18),
      ),
      MapPlacedElement(
        id: 'pe_phare_debris',
        layerId: 'l_tile_structures',
        elementId: 'el_selbrume_phare_debris',
        pos: GridPos(x: 28, y: 27),
      ),
      MapPlacedElement(
        id: 'pe_phare_marches',
        layerId: 'l_tile_ground',
        elementId: 'el_selbrume_phare_marches',
        pos: GridPos(x: 22, y: 18),
        applyCollision: false,
      ),
    ],
    connections: const <MapConnection>[
      MapConnection(
        direction: MapConnectionDirection.west,
        targetMapId: 'map_passage_dames',
      ),
    ],
    warps: const <MapWarp>[
      MapWarp(
        id: 'warp_phare_ext_to_interieur',
        pos: GridPos(x: 23, y: 18),
        targetMapId: 'map_phare_interieur',
        targetPos: GridPos(x: 18, y: 42),
      ),
      MapWarp(
        id: 'warp_phare_ext_to_cabane',
        pos: GridPos(x: 8, y: 33),
        targetMapId: 'map_cabane_gardien',
        targetPos: GridPos(x: 10, y: 13),
      ),
    ],
    gameplayZones: <MapGameplayZone>[
      _specialZone('zone_lighthouse_entry', 0, 10, 8, 8),
    ],
    triggers: <MapTrigger>[
      _reservedTrigger(
        'zone_lighthouse_entry',
        'event_lighthouse_exterior_arrival',
        0,
        10,
        8,
        8,
      ),
    ],
    mapMetadata: const MapMetadata(
      displayName: "Vieux Phare d'Ecume - Exterieur",
      mapType: MapType.building,
      weather: MapWeather.fog,
      isIndoor: false,
      allowEscapeRope: false,
      tags: <String>['selbrume', 'beta', 'map-production'],
    ),
  );
}

MapData _buildLighthouseInterior() => MapData(
      id: 'map_phare_interieur',
      name: "Vieux Phare d'Ecume - Interieur",
      size: const GridSize(width: 36, height: 45),
      tilesetId: 'selbrume_all_sprite',
      layers: _interiorLayers(width: 36, height: 45),
      warps: const <MapWarp>[
        MapWarp(
          id: 'warp_phare_interieur_to_exterieur',
          pos: GridPos(x: 18, y: 44),
          targetMapId: 'map_phare_exterieur',
          targetPos: GridPos(x: 23, y: 19),
        ),
        MapWarp(
          id: 'warp_phare_interieur_to_sommet',
          pos: GridPos(x: 18, y: 1),
          targetMapId: 'map_sommet_phare',
          targetPos: GridPos(x: 12, y: 22),
        ),
      ],
      gameplayZones: <MapGameplayZone>[
        _specialZone('zone_lighthouse_floor_1', 6, 32, 24, 11),
        _specialZone('zone_lighthouse_top_access', 14, 0, 8, 4),
      ],
      triggers: <MapTrigger>[
        _reservedTrigger(
          'tr_phare_note',
          'event_selbrume_phare_note_ancien_gardien',
          10,
          24,
          2,
          2,
        ),
      ],
      mapMetadata: const MapMetadata(
        displayName: "Vieux Phare d'Ecume - Interieur",
        mapType: MapType.interior,
        isIndoor: true,
        allowEscapeRope: false,
        tags: <String>['selbrume', 'beta', 'map-production'],
      ),
    );

const _lighthouseInteriorHostLayerId = 'l_host_selbrume_lighthouse_interior';
const _lighthouseFxHostLayerId = 'l_host_selbrume_lighthouse_fx';

MapData _buildLighthouseInteriorPilot() {
  const width = 36;
  const height = 45;
  const interiorTileset = 'ts_selbrume_lighthouse_interior';
  const floorYs = <int>[0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 41];

  final placedElements = <MapPlacedElement>[
    for (final y in floorYs)
      for (var x = 0; x < width; x += 4)
        MapPlacedElement(
          id: 'pe_phare_sol_${x}_$y',
          layerId: _lighthouseInteriorHostLayerId,
          elementId: (x == 24 || x == 28) && (y == 20 || y == 24 || y == 28)
              ? 'el_selbrume_phare_sol_bois'
              : 'el_selbrume_phare_sol_pierre',
          pos: GridPos(x: x, y: y),
          applyCollision: false,
        ),
    for (final x in const <int>[2, 6, 10, 20, 24, 28, 32])
      MapPlacedElement(
        id: 'pe_phare_mur_n_$x',
        layerId: _lighthouseInteriorHostLayerId,
        elementId: 'el_selbrume_phare_mur_n',
        pos: GridPos(x: x, y: 0),
      ),
    for (final x in const <int>[0, 4, 8, 12, 20, 24, 28, 32])
      MapPlacedElement(
        id: 'pe_phare_mur_s_$x',
        layerId: _lighthouseInteriorHostLayerId,
        elementId: 'el_selbrume_phare_mur_s',
        pos: GridPos(x: x, y: 43),
      ),
    for (final y in const <int>[2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 40])
      MapPlacedElement(
        id: 'pe_phare_mur_o_$y',
        layerId: _lighthouseInteriorHostLayerId,
        elementId: 'el_selbrume_phare_mur_o',
        pos: GridPos(x: 0, y: y),
      ),
    for (final y in const <int>[2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 40])
      MapPlacedElement(
        id: 'pe_phare_mur_e_$y',
        layerId: _lighthouseInteriorHostLayerId,
        elementId: 'el_selbrume_phare_mur_e',
        pos: GridPos(x: 34, y: y),
      ),
    const MapPlacedElement(
      id: 'pe_phare_coin_no',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_phare_coin_no',
      pos: GridPos(x: 0, y: 0),
    ),
    const MapPlacedElement(
      id: 'pe_phare_coin_ne',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_phare_coin_ne',
      pos: GridPos(x: 34, y: 0),
    ),
    const MapPlacedElement(
      id: 'pe_phare_coin_so',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_phare_coin_so',
      pos: GridPos(x: 0, y: 43),
    ),
    const MapPlacedElement(
      id: 'pe_phare_coin_se',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_phare_coin_se',
      pos: GridPos(x: 34, y: 43),
    ),
    for (final x in const <int>[2, 6, 10, 14, 20, 24, 28, 32])
      MapPlacedElement(
        id: 'pe_phare_rambarde_etage_1_$x',
        layerId: _lighthouseInteriorHostLayerId,
        elementId: 'el_selbrume_phare_rambarde_h',
        pos: GridPos(x: x, y: 31),
      ),
    for (final x in const <int>[2, 6, 14, 18, 22, 30])
      MapPlacedElement(
        id: 'pe_phare_rambarde_etage_2_$x',
        layerId: _lighthouseInteriorHostLayerId,
        elementId: 'el_selbrume_phare_rambarde_h',
        pos: GridPos(x: x, y: 20),
      ),
    for (final y in const <int>[21, 25, 29])
      MapPlacedElement(
        id: 'pe_phare_rambarde_salle_optionnelle_$y',
        layerId: _lighthouseInteriorHostLayerId,
        elementId: 'el_selbrume_phare_rambarde_v',
        pos: GridPos(x: 22, y: y),
      ),
    const MapPlacedElement(
      id: 'pe_phare_escalier_haut',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_phare_escalier_haut',
      pos: GridPos(x: 17, y: 0),
      applyCollision: false,
    ),
    const MapPlacedElement(
      id: 'pe_phare_escalier_bas',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_phare_escalier_bas',
      pos: GridPos(x: 17, y: 42),
      applyCollision: false,
    ),
    const MapPlacedElement(
      id: 'pe_phare_plancher_brise',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_phare_plancher_brise',
      pos: GridPos(x: 27, y: 8),
    ),
    const MapPlacedElement(
      id: 'pe_phare_mecanisme',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_phare_mecanisme',
      pos: GridPos(x: 25, y: 23),
    ),
    const MapPlacedElement(
      id: 'pe_phare_machinerie',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_phare_machinerie',
      pos: GridPos(x: 4, y: 34),
    ),
    const MapPlacedElement(
      id: 'pe_phare_note_ancien_gardien',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_phare_bureau_note',
      pos: GridPos(x: 10, y: 24),
    ),
    const MapPlacedElement(
      id: 'pe_phare_caisses_debris',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_phare_caisses_debris',
      pos: GridPos(x: 28, y: 13),
    ),
    const MapPlacedElement(
      id: 'pe_phare_fenetre_interieure',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_phare_fenetre_interieure',
      pos: GridPos(x: 8, y: 0),
      applyCollision: false,
    ),
    const MapPlacedElement(
      id: 'pe_phare_trappe',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_phare_trappe',
      pos: GridPos(x: 28, y: 29),
      applyCollision: false,
    ),
  ];

  return MapData(
    id: 'map_phare_interieur',
    name: "Vieux Phare d'Ecume - Interieur",
    size: const GridSize(width: width, height: height),
    tilesetId: '',
    properties: const <String, dynamic>{
      'selbrumeGeneratorBoundary': 'task13',
      'tileLayerOrder': 'bottom_to_top',
    },
    layers: _interiorLayers(
      width: width,
      height: height,
      tilesetId: interiorTileset,
      fxTilesetId: 'ts_selbrume_lighthouse_fx',
    ),
    placedElements: _lighthousePlacementsOnRecommendedLayers(placedElements),
    warps: const <MapWarp>[
      MapWarp(
        id: 'warp_phare_interieur_to_exterieur',
        pos: GridPos(x: 18, y: 44),
        targetMapId: 'map_phare_exterieur',
        targetPos: GridPos(x: 23, y: 19),
      ),
      MapWarp(
        id: 'warp_phare_interieur_to_sommet',
        pos: GridPos(x: 18, y: 1),
        targetMapId: 'map_sommet_phare',
        targetPos: GridPos(x: 12, y: 22),
      ),
    ],
    gameplayZones: <MapGameplayZone>[
      _specialZone('zone_lighthouse_floor_1', 6, 32, 24, 11),
      _specialZone('zone_lighthouse_top_access', 14, 0, 8, 4),
    ],
    triggers: <MapTrigger>[
      _reservedTrigger(
        'tr_phare_note',
        'event_selbrume_phare_note_ancien_gardien',
        10,
        24,
        2,
        2,
      ),
    ],
    mapMetadata: const MapMetadata(
      displayName: "Vieux Phare d'Ecume - Interieur",
      mapType: MapType.interior,
      isIndoor: true,
      allowEscapeRope: false,
      tags: <String>['selbrume', 'beta', 'map-production'],
    ),
  );
}

MapData _buildLighthouseTop() => MapData(
      id: 'map_sommet_phare',
      name: 'Sommet du Phare',
      size: const GridSize(width: 24, height: 24),
      tilesetId: 'selbrume_all_sprite',
      layers: _interiorLayers(width: 24, height: 24),
      warps: const <MapWarp>[
        MapWarp(
          id: 'warp_sommet_to_phare_interieur',
          pos: GridPos(x: 12, y: 23),
          targetMapId: 'map_phare_interieur',
          targetPos: GridPos(x: 18, y: 2),
        ),
      ],
      gameplayZones: <MapGameplayZone>[
        _specialZone('zone_lighthouse_top', 7, 5, 10, 10),
      ],
      triggers: <MapTrigger>[
        _reservedTrigger(
          'tr_sommet_confrontation',
          'event_selbrume_sommet_confrontation',
          12,
          10,
          1,
          1,
        ),
        _reservedTrigger(
          'tr_lighthouse_top',
          'event_final_pokemon_scene',
          7,
          5,
          10,
          10,
        ),
      ],
      mapMetadata: const MapMetadata(
        displayName: 'Sommet du Phare',
        mapType: MapType.interior,
        isIndoor: true,
        allowEscapeRope: false,
        tags: <String>['selbrume', 'beta', 'map-production'],
      ),
    );

MapData _buildLighthouseTopPilot() {
  const width = 24;
  const height = 24;
  final placedElements = <MapPlacedElement>[
    const MapPlacedElement(
      id: 'pe_sommet_plateforme',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_sommet_plateforme',
      pos: GridPos(x: 9, y: 7),
      applyCollision: false,
    ),
    for (final y in const <int>[0, 22])
      for (final x in const <int>[0, 4, 16, 20])
        MapPlacedElement(
          id: 'pe_sommet_parapet_${y == 0 ? 'n' : 's'}_$x',
          layerId: _lighthouseInteriorHostLayerId,
          elementId: 'el_selbrume_sommet_parapet_h',
          pos: GridPos(x: x, y: y),
        ),
    for (final x in const <int>[0, 22])
      for (final y in const <int>[2, 6, 10, 14, 18])
        MapPlacedElement(
          id: 'pe_sommet_parapet_${x == 0 ? 'o' : 'e'}_$y',
          layerId: _lighthouseInteriorHostLayerId,
          elementId: 'el_selbrume_sommet_parapet_v',
          pos: GridPos(x: x, y: y),
        ),
    const MapPlacedElement(
      id: 'pe_sommet_lanterne',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_sommet_lanterne',
      pos: GridPos(x: 10, y: 0),
    ),
    const MapPlacedElement(
      id: 'pe_sommet_trappe',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_phare_trappe',
      pos: GridPos(x: 11, y: 22),
      applyCollision: false,
    ),
    const MapPlacedElement(
      id: 'pe_sommet_mecanisme',
      layerId: _lighthouseInteriorHostLayerId,
      elementId: 'el_selbrume_phare_mecanisme',
      pos: GridPos(x: 17, y: 15),
    ),
    const MapPlacedElement(
      id: 'pe_sommet_lumiere_eteinte',
      layerId: _lighthouseFxHostLayerId,
      elementId: 'el_selbrume_fx_lumiere_eteinte',
      pos: GridPos(x: 10, y: 0),
      applyCollision: false,
    ),
  ];

  return MapData(
    id: 'map_sommet_phare',
    name: 'Sommet du Phare',
    size: const GridSize(width: width, height: height),
    tilesetId: '',
    properties: const <String, dynamic>{
      'selbrumeGeneratorBoundary': 'task14',
      'tileLayerOrder': 'bottom_to_top',
    },
    layers: _interiorLayers(
      width: width,
      height: height,
      tilesetId: 'ts_selbrume_lighthouse_interior',
      fxTilesetId: 'ts_selbrume_lighthouse_fx',
    ),
    placedElements: _lighthousePlacementsOnRecommendedLayers(placedElements),
    warps: const <MapWarp>[
      MapWarp(
        id: 'warp_sommet_to_phare_interieur',
        pos: GridPos(x: 12, y: 23),
        targetMapId: 'map_phare_interieur',
        targetPos: GridPos(x: 18, y: 2),
      ),
    ],
    gameplayZones: <MapGameplayZone>[
      _specialZone('zone_lighthouse_top', 7, 5, 10, 10),
    ],
    triggers: <MapTrigger>[
      _reservedTrigger(
        'tr_sommet_confrontation',
        'event_selbrume_sommet_confrontation',
        12,
        10,
        1,
        1,
      ),
      _reservedTrigger(
        'tr_lighthouse_top',
        'event_final_pokemon_scene',
        7,
        5,
        10,
        10,
      ),
    ],
    mapMetadata: const MapMetadata(
      displayName: 'Sommet du Phare',
      mapType: MapType.interior,
      isIndoor: true,
      allowEscapeRope: false,
      tags: <String>['selbrume', 'beta', 'map-production'],
    ),
  );
}

MapData _buildKeeperCabin() => MapData(
      id: 'map_cabane_gardien',
      name: 'Cabane du Gardien',
      size: const GridSize(width: 20, height: 16),
      tilesetId: 'selbrume_all_sprite',
      layers: _interiorLayers(width: 20, height: 16),
      warps: const <MapWarp>[
        MapWarp(
          id: 'warp_cabane_to_phare_exterieur',
          pos: GridPos(x: 10, y: 15),
          targetMapId: 'map_phare_exterieur',
          targetPos: GridPos(x: 8, y: 34),
        ),
        MapWarp(
          id: 'warp_cabane_to_passage',
          pos: GridPos(x: 19, y: 8),
          targetMapId: 'map_passage_dames',
          targetPos: GridPos(x: 50, y: 10),
        ),
      ],
      triggers: <MapTrigger>[
        _reservedTrigger(
          'tr_cabane_journal',
          'event_selbrume_cabane_journal',
          6,
          5,
          2,
          2,
        ),
        _reservedTrigger(
          'tr_cabane_cle',
          'event_selbrume_cabane_cle',
          14,
          9,
          1,
          1,
        ),
      ],
      mapMetadata: const MapMetadata(
        displayName: 'Cabane du Gardien',
        mapType: MapType.interior,
        isIndoor: true,
        allowEscapeRope: false,
        tags: <String>['selbrume', 'beta', 'map-production'],
      ),
    );

const String _cabinInteriorHostLayerId = 'l_host_selbrume_cabin_interior';

MapData _buildKeeperCabinPilot() {
  const width = 20;
  const height = 16;
  final placedElements = <MapPlacedElement>[
    for (final y in const <int>[0, 4, 8, 12])
      for (final x in const <int>[0, 4, 8, 12, 16])
        MapPlacedElement(
          id: 'pe_cabane_sol_${x}_$y',
          layerId: _cabinInteriorHostLayerId,
          elementId: 'el_selbrume_cabane_sol_bois',
          pos: GridPos(x: x, y: y),
          applyCollision: false,
        ),
    for (final x in const <int>[0, 4, 8, 12, 16])
      MapPlacedElement(
        id: 'pe_cabane_mur_n_$x',
        layerId: _cabinInteriorHostLayerId,
        elementId: 'el_selbrume_cabane_mur_n',
        pos: GridPos(x: x, y: 0),
      ),
    for (final y in const <int>[2, 6, 10, 12])
      MapPlacedElement(
        id: 'pe_cabane_mur_o_$y',
        layerId: _cabinInteriorHostLayerId,
        elementId: 'el_selbrume_cabane_mur_cote',
        pos: GridPos(x: 0, y: y),
      ),
    for (final y in const <int>[2, 9, 12])
      MapPlacedElement(
        id: 'pe_cabane_mur_e_$y',
        layerId: _cabinInteriorHostLayerId,
        elementId: 'el_selbrume_cabane_mur_cote',
        pos: GridPos(x: 18, y: y),
      ),
    for (final x in const <int>[2, 5, 11, 14])
      MapPlacedElement(
        id: 'pe_cabane_mur_s_$x',
        layerId: _cabinInteriorHostLayerId,
        elementId: 'el_selbrume_cabane_mur_n',
        pos: GridPos(x: x, y: 14),
      ),
    const MapPlacedElement(
      id: 'pe_cabane_lit',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_lit',
      pos: GridPos(x: 2, y: 3),
    ),
    const MapPlacedElement(
      id: 'pe_cabane_table',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_table_carnet_ferme',
      pos: GridPos(x: 6, y: 5),
    ),
    const MapPlacedElement(
      id: 'pe_cabane_journal',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_table_carnet_ouvert',
      pos: GridPos(x: 6, y: 5),
      applyCollision: false,
      opacity: 0,
    ),
    const MapPlacedElement(
      id: 'pe_cabane_poele',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_poele',
      pos: GridPos(x: 10, y: 2),
    ),
    const MapPlacedElement(
      id: 'pe_cabane_etagere',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_etagere',
      pos: GridPos(x: 16, y: 2),
    ),
    const MapPlacedElement(
      id: 'pe_cabane_coffre',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_coffre',
      pos: GridPos(x: 2, y: 9),
    ),
    const MapPlacedElement(
      id: 'pe_cabane_carte',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_carte',
      pos: GridPos(x: 7, y: 1),
      applyCollision: false,
    ),
    const MapPlacedElement(
      id: 'pe_cabane_cle',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_cle',
      pos: GridPos(x: 14, y: 9),
      applyCollision: false,
    ),
    const MapPlacedElement(
      id: 'pe_cabane_outils',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_outils',
      pos: GridPos(x: 12, y: 2),
      applyCollision: false,
    ),
    const MapPlacedElement(
      id: 'pe_cabane_lanterne',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_lanterne',
      pos: GridPos(x: 10, y: 5),
      applyCollision: false,
    ),
    const MapPlacedElement(
      id: 'pe_cabane_chaise_o',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_chaise',
      pos: GridPos(x: 5, y: 6),
    ),
    const MapPlacedElement(
      id: 'pe_cabane_chaise_e',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_chaise',
      pos: GridPos(x: 8, y: 6),
    ),
    const MapPlacedElement(
      id: 'pe_cabane_porte_principale',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_porte_principale',
      pos: GridPos(x: 9, y: 13),
      applyCollision: false,
    ),
    const MapPlacedElement(
      id: 'pe_cabane_porte_secondaire',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_porte_secondaire_fermee',
      pos: GridPos(x: 18, y: 6),
      applyCollision: false,
    ),
  ];

  return MapData(
    id: 'map_cabane_gardien',
    name: 'Cabane du Gardien',
    size: const GridSize(width: width, height: height),
    tilesetId: '',
    properties: const <String, dynamic>{
      'selbrumeGeneratorBoundary': 'task15',
      'tileLayerOrder': 'bottom_to_top',
    },
    layers: _interiorLayers(
      width: width,
      height: height,
      tilesetId: 'ts_selbrume_cabin_interior',
    ),
    placedElements: _cabinPlacementsOnRecommendedLayers(placedElements),
    warps: const <MapWarp>[
      MapWarp(
        id: 'warp_cabane_to_phare_exterieur',
        pos: GridPos(x: 10, y: 15),
        targetMapId: 'map_phare_exterieur',
        targetPos: GridPos(x: 8, y: 34),
      ),
      MapWarp(
        id: 'warp_cabane_to_passage',
        pos: GridPos(x: 19, y: 8),
        targetMapId: 'map_passage_dames',
        targetPos: GridPos(x: 50, y: 10),
      ),
    ],
    triggers: <MapTrigger>[
      _reservedTrigger(
        'tr_cabane_journal',
        'event_selbrume_cabane_journal',
        6,
        5,
        2,
        2,
      ),
      _reservedTrigger(
        'tr_cabane_cle',
        'event_selbrume_cabane_cle',
        14,
        9,
        1,
        1,
      ),
    ],
    mapMetadata: const MapMetadata(
      displayName: 'Cabane du Gardien',
      mapType: MapType.interior,
      isIndoor: true,
      allowEscapeRope: false,
      tags: <String>['selbrume', 'beta', 'map-production'],
    ),
  );
}

MapData _buildPlayerHouse() => MapData(
      id: 'map_maison_joueur',
      name: 'Maison du Joueur',
      size: const GridSize(width: 20, height: 16),
      tilesetId: 'selbrume_all_sprite',
      layers: _interiorLayers(width: 20, height: 16),
      entities: const <MapEntity>[
        MapEntity(
          id: 'spawn_maison_joueur',
          name: 'Spawn support maison joueur',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 10, y: 11),
          spawn: MapEntitySpawnData(
            spawnKey: 'maison_joueur_support',
            role: EntitySpawnRole.debug,
            facing: EntityFacing.south,
          ),
          blocksMovement: false,
        ),
      ],
      warps: const <MapWarp>[
        MapWarp(
          id: 'warp_maison_to_bourg',
          pos: GridPos(x: 10, y: 15),
          targetMapId: 'map_bourg_selbrume',
          targetPos: GridPos(x: 13, y: 24),
        ),
      ],
      gameplayZones: <MapGameplayZone>[
        _specialZone('zone_player_house_exit', 8, 12, 5, 4),
      ],
      triggers: <MapTrigger>[
        _reservedTrigger(
          'tr_player_house_exit',
          'event_player_house_exit',
          8,
          12,
          5,
          4,
        ),
      ],
      mapMetadata: const MapMetadata(
        displayName: 'Maison du Joueur',
        mapType: MapType.interior,
        isIndoor: true,
        allowEscapeRope: false,
        tags: <String>['selbrume', 'beta', 'map-production'],
      ),
    );

MapData _buildPlayerHousePilot() {
  const width = 20;
  const height = 16;
  final staticCollisions = List<bool>.filled(width * height, false);
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      final topWall = y <= 1;
      final sideWall = x <= 1 || x >= width - 2;
      final bottomWall = y >= height - 2 && x != 9 && x != 10;
      staticCollisions[y * width + x] = topWall || sideWall || bottomWall;
    }
  }

  final layers = _interiorLayers(
    width: width,
    height: height,
    tilesetId: 'ts_selbrume_cabin_interior',
    collisions: staticCollisions,
  );

  final placedElements = <MapPlacedElement>[
    for (var y = 0; y < height; y += 4)
      for (var x = 0; x < width; x += 4)
        MapPlacedElement(
          id: 'pe_maison_sol_${x}_$y',
          layerId: _cabinInteriorHostLayerId,
          elementId: 'el_selbrume_cabane_sol_bois',
          pos: GridPos(x: x, y: y),
          applyCollision: false,
        ),
    for (var x = 0; x < width; x += 4)
      MapPlacedElement(
        id: 'pe_maison_mur_n_$x',
        layerId: _cabinInteriorHostLayerId,
        elementId: 'el_selbrume_cabane_mur_n',
        pos: GridPos(x: x, y: 0),
      ),
    for (final y in const <int>[2, 6, 10])
      MapPlacedElement(
        id: 'pe_maison_mur_g_$y',
        layerId: _cabinInteriorHostLayerId,
        elementId: 'el_selbrume_cabane_mur_cote',
        pos: GridPos(x: 0, y: y),
      ),
    for (final y in const <int>[2, 6, 10])
      MapPlacedElement(
        id: 'pe_maison_mur_d_$y',
        layerId: _cabinInteriorHostLayerId,
        elementId: 'el_selbrume_cabane_mur_cote',
        pos: GridPos(x: 18, y: y),
      ),
    for (final x in const <int>[0, 4, 12, 16])
      MapPlacedElement(
        id: 'pe_maison_mur_s_$x',
        layerId: _cabinInteriorHostLayerId,
        elementId: 'el_selbrume_cabane_mur_n',
        pos: GridPos(x: x, y: 14),
      ),
    const MapPlacedElement(
      id: 'pe_maison_lit',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_maison_lit',
      pos: GridPos(x: 2, y: 3),
    ),
    const MapPlacedElement(
      id: 'pe_maison_bureau',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_maison_bureau',
      pos: GridPos(x: 14, y: 4),
    ),
    const MapPlacedElement(
      id: 'pe_maison_tapis',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_maison_tapis',
      pos: GridPos(x: 8, y: 8),
      applyCollision: false,
    ),
    const MapPlacedElement(
      id: 'pe_maison_etagere',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_etagere',
      pos: GridPos(x: 16, y: 3),
    ),
    const MapPlacedElement(
      id: 'pe_maison_carte',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_carte',
      pos: GridPos(x: 9, y: 1),
      applyCollision: false,
    ),
    const MapPlacedElement(
      id: 'pe_maison_lanterne',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_lanterne',
      pos: GridPos(x: 10, y: 2),
      applyCollision: false,
    ),
    const MapPlacedElement(
      id: 'pe_maison_chaise',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_chaise',
      pos: GridPos(x: 14, y: 6),
    ),
    const MapPlacedElement(
      id: 'pe_maison_porte',
      layerId: _cabinInteriorHostLayerId,
      elementId: 'el_selbrume_cabane_porte_principale',
      pos: GridPos(x: 9, y: 13),
      applyCollision: false,
    ),
  ];

  return MapData(
    id: 'map_maison_joueur',
    name: 'Maison du Joueur',
    size: const GridSize(width: width, height: height),
    tilesetId: '',
    layers: layers,
    placedElements: _cabinPlacementsOnRecommendedLayers(placedElements),
    entities: const <MapEntity>[
      MapEntity(
        id: 'spawn_maison_joueur',
        name: 'Spawn support maison joueur',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 10, y: 11),
        spawn: MapEntitySpawnData(
          spawnKey: 'maison_joueur_support',
          role: EntitySpawnRole.debug,
          facing: EntityFacing.south,
        ),
        blocksMovement: false,
      ),
    ],
    warps: const <MapWarp>[
      MapWarp(
        id: 'warp_maison_to_bourg',
        pos: GridPos(x: 10, y: 15),
        targetMapId: 'map_bourg_selbrume',
        targetPos: GridPos(x: 13, y: 24),
      ),
    ],
    gameplayZones: <MapGameplayZone>[
      _specialZone('zone_player_house_exit', 8, 12, 5, 4),
    ],
    triggers: <MapTrigger>[
      _reservedTrigger(
        'zone_player_house_exit',
        'event_player_house_exit',
        10,
        13,
        1,
        2,
      ),
    ],
    mapMetadata: const MapMetadata(
      displayName: 'Maison du Joueur',
      mapType: MapType.interior,
      isIndoor: true,
      allowEscapeRope: false,
      tags: <String>['selbrume', 'beta', 'map-production'],
    ),
    properties: const <String, dynamic>{
      'selbrumeGeneratorBoundary': 'task8',
      'tileLayerOrder': 'bottom_to_top',
    },
  );
}

List<MapLayer> _exteriorLayers({
  required int width,
  required int height,
  required TerrainType terrain,
  required List<_CellRect> primaryRects,
  required List<_CellRect> secondaryRects,
}) {
  final count = width * height;
  return <MapLayer>[
    MapLayer.terrain(
      id: 'l_terrain',
      name: 'Terrain',
      terrains: List<TerrainType>.filled(count, terrain),
    ),
    MapLayer.path(
      id: 'l_path_primary',
      name: 'Chemin principal',
      presetId: 'pavement_path',
      cells: _paintedCells(width, height, primaryRects),
    ),
    MapLayer.path(
      id: 'l_path_secondary',
      name: 'Chemin secondaire',
      presetId: 'dirth_path',
      cells: _paintedCells(width, height, secondaryRects),
    ),
    MapLayer.tile(
      id: 'l_tile_ground',
      name: 'Decors au sol',
      tiles: List<int>.filled(count, 0),
    ),
    MapLayer.tile(
      id: 'l_tile_structures',
      name: 'Structures',
      tiles: List<int>.filled(count, 0),
    ),
    MapLayer.tile(
      id: 'l_tile_overhead',
      name: 'Occlusion',
      tiles: List<int>.filled(count, 0),
    ),
    MapLayer.tile(
      id: 'l_tile_fx',
      name: 'Effets',
      tiles: List<int>.filled(count, 0),
    ),
    MapLayer.collision(
      id: 'l_collisions',
      name: 'Collisions',
      collisions: List<bool>.filled(count, false),
    ),
  ];
}

List<MapLayer> _interiorLayers({
  required int width,
  required int height,
  String tilesetId = 'selbrume_all_sprite',
  String fxTilesetId = '',
  List<bool>? collisions,
}) {
  final count = width * height;
  final effectiveFxTilesetId = fxTilesetId.isEmpty ? tilesetId : fxTilesetId;
  return <MapLayer>[
    MapLayer.terrain(
      id: 'l_terrain',
      name: 'Terrain interieur',
      terrains: List<TerrainType>.filled(count, TerrainType.indoor),
    ),
    MapLayer.tile(
      id: 'l_tile_floor',
      name: 'Sol',
      tilesetId: tilesetId,
      tiles: List<int>.filled(count, 0),
    ),
    MapLayer.tile(
      id: 'l_tile_walls',
      name: 'Murs',
      tilesetId: tilesetId,
      tiles: List<int>.filled(count, 0),
    ),
    MapLayer.tile(
      id: 'l_tile_furniture',
      name: 'Mobilier',
      tilesetId: tilesetId,
      tiles: List<int>.filled(count, 0),
    ),
    MapLayer.tile(
      id: 'l_tile_overhead',
      name: 'Occlusion',
      tilesetId: tilesetId,
      tiles: List<int>.filled(count, 0),
    ),
    MapLayer.tile(
      id: 'l_tile_fx',
      name: 'Effets',
      tilesetId: effectiveFxTilesetId,
      tiles: List<int>.filled(count, 0),
    ),
    MapLayer.collision(
      id: 'l_collisions',
      name: 'Collisions',
      collisions: collisions ?? List<bool>.filled(count, false),
    ),
  ];
}

List<MapPlacedElement> _placementsOnRecommendedLayers(
  List<MapPlacedElement> placements,
  Map<String, String> layerByElementId, {
  required String context,
}) =>
    <MapPlacedElement>[
      for (final placement in placements)
        placement.copyWith(
          layerId: layerByElementId[placement.elementId] ??
              (throw StateError(
                '$context cannot resolve ${placement.elementId}.',
              )),
        ),
    ];

List<MapPlacedElement> _lighthousePlacementsOnRecommendedLayers(
  List<MapPlacedElement> placements,
) =>
    _placementsOnRecommendedLayers(
      placements,
      <String, String>{
        for (final spec in _lighthouseInteriorElementSpecs)
          spec.id: spec.layerId,
        for (final spec in _lighthouseFxElementSpecs) spec.id: 'l_tile_fx',
      },
      context: 'Lighthouse placement',
    );

List<MapPlacedElement> _cabinPlacementsOnRecommendedLayers(
  List<MapPlacedElement> placements,
) =>
    _placementsOnRecommendedLayers(
      placements,
      <String, String>{
        for (final spec in _cabinElementSpecs) spec.id: spec.layerId,
      },
      context: 'Cabin placement',
    );

List<bool> _paintedCells(
  int width,
  int height,
  List<_CellRect> rectangles,
) {
  final cells = List<bool>.filled(width * height, false);
  for (final rectangle in rectangles) {
    if (rectangle.x < 0 ||
        rectangle.y < 0 ||
        rectangle.width <= 0 ||
        rectangle.height <= 0 ||
        rectangle.x + rectangle.width > width ||
        rectangle.y + rectangle.height > height) {
      throw StateError('Path rectangle exceeds ${width}x$height: $rectangle');
    }
    for (var y = rectangle.y; y < rectangle.y + rectangle.height; y++) {
      for (var x = rectangle.x; x < rectangle.x + rectangle.width; x++) {
        cells[y * width + x] = true;
      }
    }
  }
  return cells;
}

MapGameplayZone _specialZone(
  String id,
  int x,
  int y,
  int width,
  int height,
) =>
    MapGameplayZone(
      id: id,
      name: id,
      kind: GameplayZoneKind.special,
      area: MapRect(
        pos: GridPos(x: x, y: y),
        size: GridSize(width: width, height: height),
      ),
      special: const SpecialZonePayload(
        properties: <String, String>{
          'contractRole': 'navigation_anchor',
          'inert': 'true',
        },
      ),
    );

MapTrigger _reservedTrigger(
  String id,
  String eventId,
  int x,
  int y,
  int width,
  int height,
) =>
    MapTrigger(
      id: id,
      name: id,
      type: TriggerType.custom,
      area: MapRect(
        pos: GridPos(x: x, y: y),
        size: GridSize(width: width, height: height),
      ),
      properties: <String, String>{
        'eventId': eventId,
        'reservedForNarrative': 'true',
      },
    );

List<ProjectMapEntry> _canonicalMapEntries() => const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map_bourg_selbrume',
        name: 'Bourg de Selbrume',
        relativePath: 'maps/map_bourg_selbrume.json',
        groupId: 'group_selbrume_bourg',
        role: MapRole.exterior,
      ),
      ProjectMapEntry(
        id: 'map_port_brisants',
        name: 'Port des Brisants',
        relativePath: 'maps/map_port_brisants.json',
        groupId: 'group_selbrume_port',
        role: MapRole.exterior,
      ),
      ProjectMapEntry(
        id: 'map_bois_chaise_brume',
        name: 'Bois de la Chaise-Brume',
        relativePath: 'maps/map_bois_chaise_brume.json',
        groupId: 'group_selbrume_bois',
        role: MapRole.exterior,
      ),
      ProjectMapEntry(
        id: 'map_marais_salants',
        name: 'Marais Salants',
        relativePath: 'maps/map_marais_salants.json',
        groupId: 'group_selbrume_marais',
        role: MapRole.exterior,
      ),
      ProjectMapEntry(
        id: 'map_passage_dames',
        name: 'Passage des Dames',
        relativePath: 'maps/map_passage_dames.json',
        groupId: 'group_selbrume_marais',
        role: MapRole.connector,
      ),
      ProjectMapEntry(
        id: 'map_phare_exterieur',
        name: "Vieux Phare d'Ecume - Exterieur",
        relativePath: 'maps/map_phare_exterieur.json',
        groupId: 'group_selbrume_phare',
        role: MapRole.exterior,
      ),
      ProjectMapEntry(
        id: 'map_phare_interieur',
        name: "Vieux Phare d'Ecume - Interieur",
        relativePath: 'maps/map_phare_interieur.json',
        groupId: 'group_selbrume_interiors',
        role: MapRole.interior,
      ),
      ProjectMapEntry(
        id: 'map_sommet_phare',
        name: 'Sommet du Phare',
        relativePath: 'maps/map_sommet_phare.json',
        groupId: 'group_selbrume_phare',
        role: MapRole.upper_floor,
      ),
      ProjectMapEntry(
        id: 'map_cabane_gardien',
        name: 'Cabane du Gardien',
        relativePath: 'maps/map_cabane_gardien.json',
        groupId: 'group_selbrume_interiors',
        role: MapRole.interior,
      ),
      ProjectMapEntry(
        id: 'map_maison_joueur',
        name: 'Maison du Joueur',
        relativePath: 'maps/map_maison_joueur.json',
        groupId: 'group_selbrume_interiors',
        role: MapRole.interior,
      ),
    ];

List<ProjectMapGroup> _canonicalGroups({required String through}) {
  final rank = _boundaryRank(through);
  return <ProjectMapGroup>[
    ProjectMapGroup(
      id: 'group_selbrume_bourg',
      name: 'Bourg de Selbrume',
      type: MapGroupType.village,
      tags: const <String>['selbrume', 'beta', 'map-production'],
      properties: rank < 7
          ? const <String, dynamic>{}
          : <String, dynamic>{'selbrumeGeneratorBoundary': through},
    ),
    const ProjectMapGroup(
      id: 'group_selbrume_port',
      name: 'Port des Brisants',
      type: MapGroupType.city,
      tags: <String>['selbrume', 'beta', 'map-production'],
    ),
    const ProjectMapGroup(
      id: 'group_selbrume_bois',
      name: 'Bois de la Chaise-Brume',
      type: MapGroupType.forest,
      tags: <String>['selbrume', 'beta', 'map-production'],
    ),
    const ProjectMapGroup(
      id: 'group_selbrume_marais',
      name: 'Marais et Passage',
      type: MapGroupType.route,
      tags: <String>['selbrume', 'beta', 'map-production'],
    ),
    const ProjectMapGroup(
      id: 'group_selbrume_phare',
      name: "Vieux Phare d'Ecume",
      type: MapGroupType.tower,
      tags: <String>['selbrume', 'beta', 'map-production'],
    ),
    const ProjectMapGroup(
      id: 'group_selbrume_interiors',
      name: 'Interieurs Selbrume',
      type: MapGroupType.facility,
      tags: <String>['selbrume', 'beta', 'map-production'],
    ),
  ];
}

void _validateGeneratedOutput({
  required Map<String, Map<String, dynamic>> maps,
  required ProjectManifest manifest,
  required String through,
}) {
  ProjectValidator.validate(manifest);
  if (maps.keys.toSet().length != canonicalSelbrumeMapIds.length ||
      !maps.keys.toSet().containsAll(canonicalSelbrumeMapIds)) {
    throw StateError('Canonical Selbrume map output set is incomplete.');
  }
  final parsedMaps = <String, MapData>{};
  for (final id in canonicalSelbrumeMapIds) {
    final map = MapData.fromJson(maps[id]!);
    if (map.id != id) {
      throw StateError('Map file key $id serializes MapData.id ${map.id}.');
    }
    MapValidator.validate(map, projectDialogueContext: manifest);
    parsedMaps[id] = map;
  }
  for (final map in parsedMaps.values) {
    for (final connection in map.connections) {
      final target = parsedMaps[connection.targetMapId];
      if (target == null) {
        throw StateError(
          '${map.id} connection targets unknown map '
          '${connection.targetMapId}.',
        );
      }
      final reciprocal = target.connections.where(
        (candidate) =>
            candidate.targetMapId == map.id &&
            candidate.direction == connection.direction.opposite &&
            candidate.offset == -connection.offset,
      );
      if (reciprocal.length != 1) {
        throw StateError(
          '${map.id} ${connection.direction.name} connection must have one '
          'reciprocal connection on ${target.id}.',
        );
      }
    }
    for (final warp in map.warps) {
      final target = parsedMaps[warp.targetMapId];
      if (target == null) {
        throw StateError('${map.id}/${warp.id} targets an unknown map.');
      }
      if (warp.targetMapId == map.id) {
        throw StateError('${map.id}/${warp.id} targets its own map.');
      }
      if (warp.targetPos.x < 0 ||
          warp.targetPos.y < 0 ||
          warp.targetPos.x >= target.size.width ||
          warp.targetPos.y >= target.size.height) {
        throw StateError('${map.id}/${warp.id} target is out of bounds.');
      }
      if (_isStaticallyBlocked(target, warp.targetPos)) {
        throw StateError('${map.id}/${warp.id} target is statically blocked.');
      }
    }
  }
  final rank = _boundaryRank(through);
  if (rank >= 5) {
    _validateTask5Output(maps: maps, manifest: manifest);
  }
  if (rank >= 6) {
    _validateTask6Output(maps: maps, manifest: manifest);
  }
  if (rank >= 7) {
    _validateTask7Output(maps: maps, manifest: manifest);
  }
  if (rank >= 8) {
    _validateTask8Output(maps: maps, manifest: manifest);
  }
  if (rank >= 9) {
    _validateTask9Output(maps: maps, manifest: manifest);
  }
  if (rank >= 10) {
    _validateTask10Output(maps: maps, manifest: manifest);
  }
  if (rank >= 11) {
    _validateTask11Output(maps: maps, manifest: manifest);
  }
  if (rank >= 12) {
    _validateTask12Output(maps: maps, manifest: manifest);
  }
  if (rank >= 13) {
    _validateTask13Output(maps: maps, manifest: manifest);
  }
  if (rank >= 14) {
    _validateTask14Output(maps: maps, manifest: manifest);
  }
  if (rank >= 15) {
    _validateTask15Output(maps: maps, manifest: manifest);
  }
  if (rank >= 16) {
    _validateTask16Output(maps: maps, manifest: manifest);
  }
}

void _validateTask5Output({
  required Map<String, Map<String, dynamic>> maps,
  required ProjectManifest manifest,
}) {
  for (final mapId in const <String>[
    'map_bourg_selbrume',
    'map_marais_salants',
  ]) {
    final raw = maps[mapId]!;
    final layers = _jsonObjectList(raw['layers'], context: '$mapId layers');
    final placedElements = _jsonObjectList(
      raw['placedElements'],
      context: '$mapId placedElements',
    );
    if (layers.any((layer) => layer['id'] == 'l_tile_objectif') ||
        placedElements.any(
          (placed) => placed['layerId'] == 'l_tile_objectif',
        )) {
      throw StateError('$mapId still contains the full-map reference layer.');
    }
  }

  ProjectTilesetEntry requireTileset(String id, String relativePath) {
    final matches = manifest.tilesets.where((entry) => entry.id == id);
    if (matches.length != 1 || matches.single.relativePath != relativePath) {
      throw StateError('$id must be registered exactly once at $relativePath.');
    }
    return matches.single;
  }

  requireTileset(
    'ts_selbrume_boat',
    'assets/tilesets/selbrume_boat.png',
  );
  requireTileset(
    'ts_selbrume_open_sea_loop',
    'assets/tilesets/selbrume_open_sea_loop.png',
  );

  final boats = manifest.elements.where(
    (entry) => entry.id == 'el_selbrume_port_bateau',
  );
  if (boats.length != 1) {
    throw StateError('el_selbrume_port_bateau must be registered once.');
  }
  final boat = boats.single;
  if (boat.tilesetId != 'ts_selbrume_boat' ||
      boat.recommendedLayerId != 'l_tile_structures' ||
      boat.frames.length != 1 ||
      boat.frames.single.source !=
          const TilesetSourceRect(x: 0, y: 0, width: 5, height: 7) ||
      boat.frames.single.durationMs != null) {
    throw StateError('el_selbrume_port_bateau has an invalid frame contract.');
  }
  final profile = boat.collisionProfile;
  if (profile == null ||
      profile.source != ElementCollisionProfileSource.manual ||
      profile.visualMask == null ||
      profile.collisionMask == null ||
      profile.occlusionMask == null ||
      profile.cells.isEmpty ||
      profile.shapeCells.length != profile.cells.length ||
      profile.shapeCells.toSet().difference(profile.cells.toSet()).isNotEmpty) {
    throw StateError('el_selbrume_port_bateau has an invalid mask profile.');
  }

  final patterns = manifest.pathPatternPresets.where(
    (entry) => entry.basePathPresetId == 'nouveau-chemin',
  );
  if (patterns.length != 1 ||
      patterns.single.id != 'pp_selbrume_open_sea_loop') {
    throw StateError(
      'nouveau-chemin must resolve to the unique '
      'pp_selbrume_open_sea_loop pattern.',
    );
  }
  final pattern = patterns.single.centerPattern;
  if (pattern.size.width != 2 ||
      pattern.size.height != 2 ||
      pattern.cells.length != 4) {
    throw StateError(
        'pp_selbrume_open_sea_loop must be a complete 2x2 pattern.');
  }
  var frameCount = 0;
  for (final cell in pattern.cells) {
    if (cell.frames.length != 32) {
      throw StateError('Every open-sea pattern cell must have 32 frames.');
    }
    for (var index = 0; index < cell.frames.length; index += 1) {
      final frame = cell.frames[index];
      frameCount += 1;
      if (frame.tilesetId != 'ts_selbrume_open_sea_loop' ||
          frame.source.x != 2 * index + cell.localX ||
          frame.source.y != cell.localY ||
          frame.source.width != 1 ||
          frame.source.height != 1 ||
          frame.durationMs != 100) {
        throw StateError('Open-sea pattern frame contract is invalid.');
      }
    }
  }
  if (frameCount != 128) {
    throw StateError('Open-sea pattern must contain exactly 128 frames.');
  }
}

void _validateTask6Output({
  required Map<String, Map<String, dynamic>> maps,
  required ProjectManifest manifest,
}) {
  final rootFolders = manifest.tilesetFolders.where(
    (entry) => entry.id == 'tsf_selbrume_beta',
  );
  final portFolders = manifest.tilesetFolders.where(
    (entry) => entry.id == 'tsf_selbrume_beta_port',
  );
  if (rootFolders.length != 1 ||
      portFolders.length != 1 ||
      portFolders.single.parentFolderId != 'tsf_selbrume_beta') {
    throw StateError('Task 6 Selbrume tileset folders are invalid.');
  }
  final categories = manifest.elementCategories.where(
    (entry) => entry.id == 'cat_selbrume_port_props',
  );
  if (categories.length != 1 || categories.single.parentCategoryId != 'props') {
    throw StateError('cat_selbrume_port_props must exist below props.');
  }
  final tilesets = manifest.tilesets.where(
    (entry) => entry.id == 'ts_selbrume_port_props',
  );
  if (tilesets.length != 1 ||
      tilesets.single.relativePath !=
          'assets/tilesets/selbrume_port_props.png' ||
      tilesets.single.folderId != 'tsf_selbrume_beta_port') {
    throw StateError('ts_selbrume_port_props registration is invalid.');
  }

  final elementsById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  for (final spec in _portElementSpecs) {
    final element = elementsById[spec.id];
    if (element == null ||
        element.tilesetId != 'ts_selbrume_port_props' ||
        element.categoryId != 'cat_selbrume_port_props' ||
        element.frames.length != 1 ||
        element.frames.single.source != spec.source ||
        element.frames.single.durationMs != null ||
        element.recommendedLayerId != spec.layerId) {
      throw StateError('${spec.id} has an invalid Task 6 element contract.');
    }
    final stateTag = spec.isStateVariant ? 'state_variant' : 'static';
    if (!element.tags.toSet().containsAll(<String>{
      'environment',
      'map_port_brisants',
      'beta',
      stateTag,
    })) {
      throw StateError('${spec.id} is missing required Task 6 tags.');
    }
    if (spec.collisionCells.isEmpty) {
      if (element.collisionProfile != null) {
        throw StateError('${spec.id} must remain passable.');
      }
      continue;
    }
    final profile = element.collisionProfile;
    if (profile == null ||
        profile.source != ElementCollisionProfileSource.manual ||
        !_sameGridPositions(profile.cells, spec.collisionCells) ||
        !_sameGridPositions(profile.shapeCells, spec.collisionCells) ||
        profile.visualMask == null ||
        profile.collisionMask == null ||
        (spec.occlusionCells.isNotEmpty && profile.occlusionMask == null)) {
      throw StateError('${spec.id} has an invalid collision profile.');
    }
    _validatePortMask(
      spec.id,
      'visual',
      profile.visualMask!,
      spec.source,
      requireSolidPixel: true,
    );
    _validatePortMask(
      spec.id,
      'collision',
      profile.collisionMask!,
      spec.source,
      requireSolidPixel: true,
    );
    final maskDerivedCells = ElementCollisionMaskCodec.cellsFromPixelMask(
      mask: profile.collisionMask!,
      tileWidth: 32,
      tileHeight: 32,
      sourceWidthInTiles: spec.source.width,
      sourceHeightInTiles: spec.source.height,
    );
    if (!_sameGridPositions(maskDerivedCells, profile.cells)) {
      throw StateError('${spec.id} pixel/coarse collision cells diverge.');
    }
    if (profile.occlusionMask != null) {
      _validatePortMask(
        spec.id,
        'occlusion',
        profile.occlusionMask!,
        spec.source,
        requireSolidPixel: spec.occlusionCells.isNotEmpty,
      );
    }
  }

  final port = MapData.fromJson(maps['map_port_brisants']!);
  if (port.size != const GridSize(width: 45, height: 45) ||
      port.mapMetadata.isIndoor ||
      port.tilesetId.isNotEmpty) {
    throw StateError('map_port_brisants base contract is invalid.');
  }
  const expectedLayerIds = <String>[
    'l_terrain',
    'l_path_primary',
    'l_path_secondary',
    'l_tile_ground',
    'l_tile_structures',
    'l_tile_overhead',
    'l_tile_fx',
    'l_collisions',
  ];
  if (port.layers.map((layer) => layer.id).toList(growable: false).join('|') !=
      expectedLayerIds.join('|')) {
    throw StateError('map_port_brisants exterior layer order is invalid.');
  }
  final primary = port.layers
      .whereType<PathLayer>()
      .singleWhere((layer) => layer.id == 'l_path_primary');
  final water = port.layers
      .whereType<PathLayer>()
      .singleWhere((layer) => layer.id == 'l_path_secondary');
  final collision = port.layers.whereType<CollisionLayer>().single;
  if (water.presetId != 'nouveau-chemin') {
    throw StateError('Port water must use nouveau-chemin.');
  }
  for (var index = 0; index < water.cells.length; index += 1) {
    if (water.cells[index] && !collision.collisions[index]) {
      throw StateError('Port water cell $index is walkable.');
    }
  }
  for (var x = 26; x <= 30; x += 1) {
    if (!primary.cells[x] || collision.collisions[x]) {
      throw StateError('Port north corridor is blocked at ($x,0).');
    }
  }
  for (var y = 29; y <= 39; y += 1) {
    for (var x = 25; x <= 27; x += 1) {
      final index = y * port.size.width + x;
      if (!primary.cells[index] ||
          water.cells[index] ||
          collision.collisions[index]) {
        throw StateError('Port main quay is invalid at ($x,$y).');
      }
    }
  }

  _requirePortZone(port, 'zone_port_entry', 24, 0, 8, 5);
  _requirePortZone(port, 'zone_port_center', 17, 16, 12, 10);
  _requirePortTrigger(
    port,
    'zone_port_entry',
    'event_enter_port_alert',
    24,
    0,
    8,
    5,
  );
  _requirePortTrigger(
    port,
    'zone_port_center',
    'event_ending_port',
    17,
    16,
    12,
    10,
  );
  _requirePortTrigger(
    port,
    'tr_port_rival_scene',
    'event_selbrume_port_rival_scene',
    17,
    17,
    10,
    8,
  );
  _requirePortTrigger(
    port,
    'tr_port_nest',
    'event_selbrume_port_nest',
    6,
    5,
    2,
    2,
  );
  if (port.gameplayZones.map((zone) => zone.id).toSet().length != 2 ||
      !port.gameplayZones.map((zone) => zone.id).toSet().containsAll(
        const <String>{'zone_port_entry', 'zone_port_center'},
      )) {
    throw StateError('Port gameplay-zone inventory is not exact.');
  }
  if (port.triggers.map((trigger) => trigger.id).toSet().length != 4 ||
      !port.triggers.map((trigger) => trigger.id).toSet().containsAll(
        const <String>{
          'zone_port_entry',
          'zone_port_center',
          'tr_port_rival_scene',
          'tr_port_nest',
        },
      )) {
    throw StateError('Port reserved-trigger inventory is not exact.');
  }
  final connections = port.connections.where(
    (connection) =>
        connection.direction == MapConnectionDirection.north &&
        connection.targetMapId == 'map_bourg_selbrume' &&
        connection.offset == 0,
  );
  final bourg = MapData.fromJson(maps['map_bourg_selbrume']!);
  final reciprocal = bourg.connections.where(
    (connection) =>
        connection.direction == MapConnectionDirection.south &&
        connection.targetMapId == port.id &&
        connection.offset == 0,
  );
  if (connections.length != 1 || reciprocal.length != 1) {
    throw StateError('Port/Bourg connection must be reciprocal.');
  }
  final bourgHasCanonicalLayers =
      bourg.layers.any((layer) => layer.id == 'l_path_primary');
  final bourgPortPath = bourg.layers.whereType<PathLayer>().singleWhere(
        (layer) =>
            layer.id ==
            (bourgHasCanonicalLayers ? 'l_path_primary' : 'l_path_path'),
      );
  final bourgOcean = bourg.layers.whereType<PathLayer>().singleWhere(
        (layer) =>
            layer.id ==
            (bourgHasCanonicalLayers ? 'l_path_secondary' : 'l_path_oc_an'),
      );
  final bourgCollision = bourg.layers
      .whereType<CollisionLayer>()
      .singleWhere((layer) => layer.id == 'l_collisions');
  for (var y = 46; y <= 54; y += 1) {
    for (var x = 26; x <= 30; x += 1) {
      final index = y * bourg.size.width + x;
      if (!bourgPortPath.cells[index] ||
          bourgOcean.cells[index] ||
          bourgCollision.collisions[index]) {
        throw StateError('Bourg Port causeway is blocked at ($x,$y).');
      }
    }
  }

  final placedById = <String, MapPlacedElement>{
    for (final placed in port.placedElements) placed.id: placed,
  };
  _requirePortPlacement(
    placedById,
    'pe_port_bateau',
    'el_selbrume_port_bateau',
    'l_tile_structures',
    const GridPos(x: 3, y: 30),
  );
  final nest = _requirePortPlacement(
    placedById,
    'pe_port_nid_goelise',
    'el_selbrume_port_nid_vide',
    'l_tile_ground',
    const GridPos(x: 6, y: 5),
  );
  if (nest.behaviors.isNotEmpty ||
      nest.properties['eventId'] != 'event_goelise_nest_found' ||
      nest.properties['reservedForNarrative'] != 'true') {
    throw StateError('pe_port_nid_goelise must remain an inert reservation.');
  }
  final usedPortElementIds = port.placedElements
      .map((placed) => placed.elementId)
      .where((id) => id.startsWith('el_selbrume_port_'))
      .toSet();
  final requiredVisible = _portElementSpecs
      .where((spec) => spec.id != 'el_selbrume_port_nid_brillant')
      .map((spec) => spec.id)
      .toSet();
  if (!usedPortElementIds.containsAll(requiredVisible) ||
      usedPortElementIds.contains('el_selbrume_port_nid_brillant')) {
    throw StateError('Port visible asset coverage/state selection is invalid.');
  }

  for (final anchor in const <(String, GridPos)>[
    ('anchor_port_lysa', GridPos(x: 22, y: 21)),
    ('anchor_port_soline', GridPos(x: 34, y: 8)),
    ('anchor_port_pecheurs', GridPos(x: 8, y: 18)),
  ]) {
    final matches = port.entities.where((entity) => entity.id == anchor.$1);
    if (matches.length != 1 ||
        matches.single.pos != anchor.$2 ||
        matches.single.kind != MapEntityKind.custom ||
        matches.single.blocksMovement ||
        matches.single.npc != null ||
        matches.single.properties['contractRole'] !=
            'reserved_character_anchor' ||
        matches.single.properties['inert'] != 'true') {
      throw StateError('${anchor.$1} is not an inert structural anchor.');
    }
  }
  if (port.events.isNotEmpty) {
    throw StateError('Task 6 must not invent Port narrative events.');
  }

  const stage = MapRect(
    pos: GridPos(x: 17, y: 17),
    size: GridSize(width: 10, height: 8),
  );
  for (var y = stage.pos.y; y < stage.pos.y + stage.size.height; y += 1) {
    for (var x = stage.pos.x; x < stage.pos.x + stage.size.width; x += 1) {
      if (collision.collisions[y * port.size.width + x]) {
        throw StateError('Rival stage has static collision at ($x,$y).');
      }
    }
  }
  for (final placed in port.placedElements) {
    final element = elementsById[placed.elementId];
    if (element == null) continue;
    final source = element.frames.single.source;
    final right = placed.pos.x + source.width;
    final bottom = placed.pos.y + source.height;
    final stageRight = stage.pos.x + stage.size.width;
    final stageBottom = stage.pos.y + stage.size.height;
    if (placed.pos.x < stageRight &&
        right > stage.pos.x &&
        placed.pos.y < stageBottom &&
        bottom > stage.pos.y) {
      throw StateError('${placed.id} intrudes into the rival stage.');
    }
  }
  for (var y = 30; y < 37; y += 1) {
    for (var x = 3; x < 8; x += 1) {
      if (!water.cells[y * port.size.width + x]) {
        throw StateError('Boat footprint is not entirely over water.');
      }
    }
  }
  for (var x = 36; x <= 38; x += 1) {
    if (_portBlockedCells(port, elementsById)[17 * port.size.width + x]) {
      throw StateError('Hangar approach must keep three free cells.');
    }
  }
  _validatePortAnchorConnectivity(port, elementsById);
}

void _validateTask7Output({
  required Map<String, Map<String, dynamic>> maps,
  required ProjectManifest manifest,
}) {
  final bourg = MapData.fromJson(maps['map_bourg_selbrume']!);
  const expectedLayerIds = <String>[
    'l_terrain',
    'l_path_primary',
    'l_path_secondary',
    'l_tile_ground',
    'l_tile_structures',
    'l_tile_overhead',
    'l_tile_fx',
    'l_collisions',
  ];
  if (bourg.size != const GridSize(width: 55, height: 55) ||
      bourg.tilesetId.isNotEmpty ||
      bourg.mapMetadata.isIndoor ||
      bourg.mapMetadata.defaultSpawnId != 'spawn' ||
      bourg.properties['selbrumeGeneratorBoundary'] != 'task7' ||
      bourg.layers.map((layer) => layer.id).join('|') !=
          expectedLayerIds.join('|')) {
    throw StateError('Task 7 Bourg base/layer contract is invalid.');
  }
  if (bourg.placedElements.length != 306 ||
      bourg.placedElements.any(
        (placed) =>
            placed.layerId == 'l_tile_objectif' || placed.elementId == 'test',
      )) {
    throw StateError('Task 7 Bourg seed placement migration is invalid.');
  }
  final entitiesById = <String, MapEntity>{
    for (final entity in bourg.entities) entity.id: entity,
  };
  if (entitiesById.length != 3 ||
      !entitiesById.keys.toSet().containsAll(
        const <String>{'spawn', 'p6_03_intro_sign', 'npc'},
      ) ||
      entitiesById['spawn']?.pos != const GridPos(x: 17, y: 24) ||
      entitiesById['p6_03_intro_sign']?.pos != const GridPos(x: 22, y: 25) ||
      entitiesById['npc']?.pos != const GridPos(x: 34, y: 29) ||
      entitiesById['npc']?.npc?.characterId != 'mael') {
    throw StateError('Task 7 Bourg authored entities drifted.');
  }

  final placedById = <String, MapPlacedElement>{
    for (final placed in bourg.placedElements) placed.id: placed,
  };
  for (final contract in const <(String, String, GridPos)>[
    (
      'pe_bourg_maison_joueur_facade',
      'selbrum_maison_1',
      GridPos(x: 10, y: 18),
    ),
    (
      'pe_bourg_centre_facade',
      'selbrume_centre_pok_mon',
      GridPos(x: 29, y: 22),
    ),
    ('pe_bourg_puits', 'le_puits', GridPos(x: 23, y: 27)),
    ('pe_bourg_kiosque', 'kiosque_l_gumes', GridPos(x: 36, y: 35)),
  ]) {
    final placed = placedById[contract.$1];
    if (placed == null ||
        placed.elementId != contract.$2 ||
        placed.pos != contract.$3 ||
        placed.layerId != 'l_tile_structures') {
      throw StateError('${contract.$1} violates the Bourg landmark contract.');
    }
  }
  if (bourg.placedElements
          .where((placed) => placed.elementId.startsWith('selbrum_maison_'))
          .length <
      2) {
    throw StateError('Task 7 Bourg must preserve at least two houses.');
  }

  final connectionKeys = <String>{
    for (final connection in bourg.connections)
      '${connection.direction.name}:${connection.targetMapId}:'
          '${connection.offset}',
  };
  if (bourg.connections.length != 2 ||
      !connectionKeys.containsAll(const <String>{
        'south:map_port_brisants:0',
        'east:map_bois_chaise_brume:0',
      })) {
    throw StateError('Task 7 Bourg connections are not exact.');
  }
  if (bourg.warps.length != 1) {
    throw StateError('Task 7 Bourg must expose one player-house warp.');
  }
  final warp = bourg.warps.single;
  if (warp.id != 'warp_bourg_to_maison' ||
      warp.pos != const GridPos(x: 13, y: 23) ||
      warp.targetMapId != 'map_maison_joueur' ||
      warp.targetPos != const GridPos(x: 10, y: 13)) {
    throw StateError('Task 7 Bourg player-house warp is invalid.');
  }

  final primary = bourg.layers
      .whereType<PathLayer>()
      .singleWhere((layer) => layer.id == 'l_path_primary');
  final water = bourg.layers
      .whereType<PathLayer>()
      .singleWhere((layer) => layer.id == 'l_path_secondary');
  final collisions = bourg.layers.whereType<CollisionLayer>().single;
  if (primary.presetId != 'pavement_path' ||
      water.presetId != 'nouveau-chemin' ||
      !water.cells.contains(true)) {
    throw StateError('Task 7 Bourg terrain/path composition is invalid.');
  }
  void requireWalkable(int x, int y, String label) {
    final index = y * bourg.size.width + x;
    if (!primary.cells[index] ||
        water.cells[index] ||
        collisions.collisions[index]) {
      throw StateError('Task 7 Bourg $label is blocked at ($x,$y).');
    }
  }

  for (var y = 46; y <= 54; y += 1) {
    for (var x = 26; x <= 30; x += 1) {
      requireWalkable(x, y, 'Port causeway');
    }
  }
  for (var y = 24; y <= 28; y += 1) {
    requireWalkable(54, y, 'Bois corridor');
  }
  for (var y = 0; y < bourg.size.height; y += 1) {
    if (y >= 24 && y <= 28) continue;
    final index = y * bourg.size.width + (bourg.size.width - 1);
    if (primary.cells[index] || !collisions.collisions[index]) {
      throw StateError('Task 7 Bourg east boundary leaks at (54,$y).');
    }
  }
  for (var x = 0; x < bourg.size.width; x += 1) {
    if (x >= 26 && x <= 30) continue;
    final index = (bourg.size.height - 1) * bourg.size.width + x;
    if (primary.cells[index] || !collisions.collisions[index]) {
      throw StateError('Task 7 Bourg south boundary leaks at ($x,54).');
    }
  }
  for (final pos in const <GridPos>[
    GridPos(x: 17, y: 24),
    GridPos(x: 13, y: 23),
    GridPos(x: 13, y: 24),
    GridPos(x: 27, y: 20),
  ]) {
    requireWalkable(pos.x, pos.y, 'reserved approach');
  }
  final groups = manifest.groups.where(
    (group) => group.id == 'group_selbrume_bourg',
  );
  final marker = groups.length == 1
      ? groups.single.properties['selbrumeGeneratorBoundary']
      : null;
  if (marker != 'task7' &&
      marker != 'task8' &&
      marker != 'task9' &&
      marker != 'task10' &&
      marker != 'task11' &&
      marker != 'task12' &&
      marker != 'task13' &&
      marker != 'task14' &&
      marker != 'task15' &&
      marker != 'task16') {
    throw StateError('Task 7 boundary marker is missing from the manifest.');
  }
}

const List<String> _canonicalInteriorLayerIds = <String>[
  'l_terrain',
  'l_tile_floor',
  'l_tile_walls',
  'l_tile_furniture',
  'l_tile_overhead',
  'l_tile_fx',
  'l_collisions',
];

void _validateCanonicalInteriorLayerContract(
  MapData map,
  ProjectManifest manifest, {
  required String tilesetId,
  required String fxTilesetId,
}) {
  final expectedCellCount = map.size.width * map.size.height;
  if (!_sameStrings(
        map.layers.map((layer) => layer.id).toList(growable: false),
        _canonicalInteriorLayerIds,
      ) ||
      map.layers.first is! TerrainLayer ||
      map.layers.last is! CollisionLayer ||
      map.layers.sublist(1, 6).any((layer) => layer is! TileLayer) ||
      map.properties['tileLayerOrder'] != 'bottom_to_top') {
    throw StateError('${map.id} canonical interior layer order is invalid.');
  }

  for (final layer in map.layers) {
    final cellCount = switch (layer) {
      TerrainLayer(:final terrains) => terrains.length,
      TileLayer(:final tiles) => tiles.length,
      CollisionLayer(:final collisions) => collisions.length,
      _ => -1,
    };
    if (cellCount != expectedCellCount) {
      throw StateError('${map.id}/${layer.id} has $cellCount cells.');
    }
  }

  final tileLayersById = <String, TileLayer>{
    for (final layer in map.layers.whereType<TileLayer>()) layer.id: layer,
  };
  for (final layer in tileLayersById.values) {
    final expectedTilesetId = layer.id == 'l_tile_fx' ? fxTilesetId : tilesetId;
    if (layer.tilesetId != expectedTilesetId ||
        layer.tiles.any((tile) => tile != 0)) {
      throw StateError('${map.id}/${layer.id} atlas host is invalid.');
    }
  }

  final elementsById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  for (final placed in map.placedElements) {
    final layer = tileLayersById[placed.layerId];
    final element = elementsById[placed.elementId];
    if (layer == null ||
        element == null ||
        placed.layerId != element.recommendedLayerId ||
        layer.tilesetId != element.tilesetId) {
      throw StateError(
        '${map.id}/${placed.id} violates its recommended layer or atlas.',
      );
    }
  }
}

void _validateTask8Output({
  required Map<String, Map<String, dynamic>> maps,
  required ProjectManifest manifest,
}) {
  final folders = manifest.tilesetFolders.where(
    (entry) => entry.id == 'tsf_selbrume_beta_interiors',
  );
  if (folders.length != 1 ||
      folders.single.parentFolderId != 'tsf_selbrume_beta') {
    throw StateError('Task 8 Selbrume interior tileset folder is invalid.');
  }
  final categories = manifest.elementCategories.where(
    (entry) => entry.id == 'cat_selbrume_interiors',
  );
  if (categories.length != 1 || categories.single.parentCategoryId != 'props') {
    throw StateError('cat_selbrume_interiors must exist below props.');
  }
  final tilesets = manifest.tilesets.where(
    (entry) => entry.id == 'ts_selbrume_cabin_interior',
  );
  if (tilesets.length != 1 ||
      tilesets.single.relativePath !=
          'assets/tilesets/selbrume_cabin_interior.png' ||
      tilesets.single.folderId != 'tsf_selbrume_beta_interiors') {
    throw StateError('ts_selbrume_cabin_interior registration is invalid.');
  }

  final elementsById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  for (final spec in _cabinElementSpecs) {
    final element = elementsById[spec.id];
    if (element == null ||
        element.tilesetId != 'ts_selbrume_cabin_interior' ||
        element.categoryId != 'cat_selbrume_interiors' ||
        element.frames.length != 1 ||
        element.frames.single.source != spec.source ||
        element.frames.single.durationMs != null ||
        element.recommendedLayerId != spec.layerId) {
      throw StateError('${spec.id} has an invalid Task 8 element contract.');
    }
    final stateTag = spec.isStateVariant ? 'state_variant' : 'static';
    if (!element.tags.toSet().containsAll(<String>{
      'selbrume',
      'environment',
      'interior',
      'map_cabane_gardien',
      'map_maison_joueur',
      'beta',
      stateTag,
    })) {
      throw StateError('${spec.id} is missing required Task 8 tags.');
    }
    if (spec.collisionCells.isEmpty) {
      if (element.collisionProfile != null) {
        throw StateError('${spec.id} must remain passable.');
      }
      continue;
    }
    final profile = element.collisionProfile;
    if (profile == null ||
        profile.source != ElementCollisionProfileSource.manual ||
        !_sameGridPositions(profile.cells, spec.collisionCells) ||
        !_sameGridPositions(profile.shapeCells, spec.collisionCells) ||
        profile.visualMask == null ||
        profile.collisionMask == null ||
        profile.occlusionMask != null) {
      throw StateError('${spec.id} has an invalid Task 8 collision profile.');
    }
    _validatePortMask(
      spec.id,
      'visual',
      profile.visualMask!,
      spec.source,
      requireSolidPixel: true,
    );
    _validatePortMask(
      spec.id,
      'collision',
      profile.collisionMask!,
      spec.source,
      requireSolidPixel: true,
    );
    final derivedCells = ElementCollisionMaskCodec.cellsFromPixelMask(
      mask: profile.collisionMask!,
      tileWidth: 32,
      tileHeight: 32,
      sourceWidthInTiles: spec.source.width,
      sourceHeightInTiles: spec.source.height,
    );
    if (!_sameGridPositions(derivedCells, spec.collisionCells)) {
      throw StateError('${spec.id} pixel/coarse collision cells diverge.');
    }
  }
  final registeredCabinIds = manifest.elements
      .where((element) => element.tilesetId == 'ts_selbrume_cabin_interior')
      .map((element) => element.id)
      .toSet();
  if (registeredCabinIds.length != _task8CabinElementIds.length ||
      !registeredCabinIds.containsAll(_task8CabinElementIds)) {
    throw StateError('Task 8 cabin atlas must expose exactly 20 elements.');
  }

  final house = MapData.fromJson(maps['map_maison_joueur']!);
  if (house.size != const GridSize(width: 20, height: 16) ||
      house.tilesetId.isNotEmpty ||
      !house.mapMetadata.isIndoor ||
      house.properties['selbrumeGeneratorBoundary'] != 'task8') {
    throw StateError('Task 8 player-house base contract is invalid.');
  }
  _validateCanonicalInteriorLayerContract(
    house,
    manifest,
    tilesetId: 'ts_selbrume_cabin_interior',
    fxTilesetId: 'ts_selbrume_cabin_interior',
  );

  final placedById = <String, MapPlacedElement>{
    for (final placed in house.placedElements) placed.id: placed,
  };
  for (final contract in const <(String, String, String, GridPos)>[
    (
      'pe_maison_lit',
      'el_selbrume_maison_lit',
      'l_tile_furniture',
      GridPos(x: 2, y: 3),
    ),
    (
      'pe_maison_bureau',
      'el_selbrume_maison_bureau',
      'l_tile_furniture',
      GridPos(x: 14, y: 4),
    ),
    (
      'pe_maison_tapis',
      'el_selbrume_maison_tapis',
      'l_tile_floor',
      GridPos(x: 8, y: 8),
    ),
    (
      'pe_maison_etagere',
      'el_selbrume_cabane_etagere',
      'l_tile_furniture',
      GridPos(x: 16, y: 3),
    ),
    (
      'pe_maison_porte',
      'el_selbrume_cabane_porte_principale',
      'l_tile_walls',
      GridPos(x: 9, y: 13),
    ),
  ]) {
    final placed = placedById[contract.$1];
    if (placed == null ||
        placed.elementId != contract.$2 ||
        placed.layerId != contract.$3 ||
        placed.pos != contract.$4) {
      throw StateError('${contract.$1} violates the player-house contract.');
    }
  }
  if (placedById['pe_maison_tapis']!.applyCollision ||
      placedById['pe_maison_porte']!.applyCollision) {
    throw StateError('Player-house rug and doorway must remain passable.');
  }
  if (house.entities.length != 1) {
    throw StateError('Player house must contain one support spawn.');
  }
  final spawn = house.entities.single;
  if (spawn.id != 'spawn_maison_joueur' ||
      spawn.kind != MapEntityKind.spawn ||
      spawn.pos != const GridPos(x: 10, y: 11) ||
      spawn.blocksMovement) {
    throw StateError('Player-house support spawn is invalid.');
  }
  _requirePortZone(house, 'zone_player_house_exit', 8, 12, 5, 4);
  _requirePortTrigger(
    house,
    'zone_player_house_exit',
    'event_player_house_exit',
    10,
    13,
    1,
    2,
  );
  if (house.gameplayZones.length != 1 ||
      house.triggers.length != 1 ||
      house.events.isNotEmpty) {
    throw StateError('Player-house inert reservation inventory is not exact.');
  }
  if (house.warps.length != 1) {
    throw StateError('Player house must expose one return warp.');
  }
  final warp = house.warps.single;
  if (warp.id != 'warp_maison_to_bourg' ||
      warp.pos != const GridPos(x: 10, y: 15) ||
      warp.targetMapId != 'map_bourg_selbrume' ||
      warp.targetPos != const GridPos(x: 13, y: 24)) {
    throw StateError('Player-house return warp is invalid.');
  }

  final blocked = _portBlockedCells(house, elementsById);
  for (final pos in const <GridPos>[
    GridPos(x: 10, y: 11),
    GridPos(x: 10, y: 12),
    GridPos(x: 10, y: 13),
    GridPos(x: 10, y: 14),
    GridPos(x: 10, y: 15),
  ]) {
    if (blocked[pos.y * house.size.width + pos.x]) {
      throw StateError('Player-house critical approach is blocked at $pos.');
    }
  }
  final marker = manifest.groups
      .singleWhere((group) => group.id == 'group_selbrume_bourg')
      .properties['selbrumeGeneratorBoundary'];
  if (marker != 'task8' &&
      marker != 'task9' &&
      marker != 'task10' &&
      marker != 'task11' &&
      marker != 'task12' &&
      marker != 'task13' &&
      marker != 'task14' &&
      marker != 'task15' &&
      marker != 'task16') {
    throw StateError('Task 8 boundary marker is missing from the manifest.');
  }
}

void _validateTask9Output({
  required Map<String, Map<String, dynamic>> maps,
  required ProjectManifest manifest,
}) {
  final folders = manifest.tilesetFolders.where(
    (entry) => entry.id == 'tsf_selbrume_beta_forest',
  );
  if (folders.length != 1 ||
      folders.single.parentFolderId != 'tsf_selbrume_beta') {
    throw StateError('Task 9 Selbrume forest tileset folder is invalid.');
  }
  final categories = manifest.elementCategories.where(
    (entry) => entry.id == 'cat_selbrume_forest',
  );
  if (categories.length != 1 ||
      categories.single.parentCategoryId != 'environnement') {
    throw StateError('cat_selbrume_forest must exist below environnement.');
  }
  final tilesets = manifest.tilesets.where(
    (entry) => entry.id == 'ts_selbrume_forest_props',
  );
  if (tilesets.length != 1 ||
      tilesets.single.relativePath !=
          'assets/tilesets/selbrume_forest_props.png' ||
      tilesets.single.folderId != 'tsf_selbrume_beta_forest') {
    throw StateError('ts_selbrume_forest_props registration is invalid.');
  }

  final elementsById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  for (final spec in _forestElementSpecs) {
    final element = elementsById[spec.id];
    if (element == null ||
        element.tilesetId != 'ts_selbrume_forest_props' ||
        element.categoryId != 'cat_selbrume_forest' ||
        element.frames.length != 1 ||
        element.frames.single.source != spec.source ||
        element.frames.single.durationMs != null ||
        element.recommendedLayerId != spec.layerId ||
        !element.tags.toSet().containsAll(const <String>{
          'selbrume',
          'environment',
          'forest',
          'map_bois_chaise_brume',
          'beta',
          'static',
        })) {
      throw StateError('${spec.id} has an invalid Task 9 element contract.');
    }
    if (spec.collisionCells.isEmpty) {
      if (element.collisionProfile != null) {
        throw StateError('${spec.id} must remain passable.');
      }
      continue;
    }
    final profile = element.collisionProfile;
    if (profile == null ||
        profile.source != ElementCollisionProfileSource.manual ||
        !_sameGridPositions(profile.cells, spec.collisionCells) ||
        !_sameGridPositions(profile.shapeCells, spec.collisionCells) ||
        profile.visualMask == null ||
        profile.collisionMask == null ||
        (profile.occlusionMask != null) != spec.hasCanopy) {
      throw StateError('${spec.id} has an invalid Task 9 collision profile.');
    }
    _validatePortMask(
      spec.id,
      'visual',
      profile.visualMask!,
      spec.source,
      requireSolidPixel: true,
    );
    _validatePortMask(
      spec.id,
      'collision',
      profile.collisionMask!,
      spec.source,
      requireSolidPixel: true,
    );
    if (spec.hasCanopy) {
      _validatePortMask(
        spec.id,
        'occlusion',
        profile.occlusionMask!,
        spec.source,
        requireSolidPixel: true,
      );
    }
    final derivedCells = ElementCollisionMaskCodec.cellsFromPixelMask(
      mask: profile.collisionMask!,
      tileWidth: 32,
      tileHeight: 32,
      sourceWidthInTiles: spec.source.width,
      sourceHeightInTiles: spec.source.height,
    );
    if (!_sameGridPositions(derivedCells, spec.collisionCells)) {
      throw StateError('${spec.id} pixel/coarse collision cells diverge.');
    }
  }
  final registeredForestIds = manifest.elements
      .where((element) => element.tilesetId == 'ts_selbrume_forest_props')
      .map((element) => element.id)
      .toSet();
  if (registeredForestIds.length != _task9ForestElementIds.length ||
      !registeredForestIds.containsAll(_task9ForestElementIds)) {
    throw StateError('Task 9 forest atlas must expose exactly 12 elements.');
  }

  final forest = MapData.fromJson(maps['map_bois_chaise_brume']!);
  const expectedLayerIds = <String>[
    'l_terrain',
    'l_path_primary',
    'l_path_secondary',
    'l_tile_ground',
    'l_tile_structures',
    'l_tile_overhead',
    'l_tile_fx',
    'l_collisions',
  ];
  if (forest.size != const GridSize(width: 45, height: 45) ||
      forest.tilesetId.isNotEmpty ||
      forest.mapMetadata.isIndoor ||
      forest.mapMetadata.mapType != MapType.forest ||
      forest.mapMetadata.weather != MapWeather.fog ||
      forest.properties['selbrumeGeneratorBoundary'] != 'task9' ||
      forest.layers.map((layer) => layer.id).join('|') !=
          expectedLayerIds.join('|') ||
      forest.layers.whereType<TileLayer>().any(
            (layer) => layer.tilesetId != 'ts_selbrume_forest_props',
          )) {
    throw StateError('Task 9 forest base/layer contract is invalid.');
  }
  if (forest.warps.isNotEmpty ||
      forest.events.isNotEmpty ||
      forest.triggers.isNotEmpty ||
      forest.entities.isNotEmpty) {
    throw StateError('Task 9 forest must not invent narrative content.');
  }
  final connectionKeys = <String>{
    for (final connection in forest.connections)
      '${connection.direction.name}:${connection.targetMapId}:'
          '${connection.offset}',
  };
  if (forest.connections.length != 2 ||
      !connectionKeys.containsAll(const <String>{
        'west:map_bourg_selbrume:0',
        'east:map_marais_salants:0',
      })) {
    throw StateError('Task 9 forest connections are not exact.');
  }

  const grassAreas = <String, MapRect>{
    'zone_bois_herbe_1': MapRect(
      pos: GridPos(x: 9, y: 8),
      size: GridSize(width: 8, height: 6),
    ),
    'zone_bois_herbe_2': MapRect(
      pos: GridPos(x: 26, y: 9),
      size: GridSize(width: 8, height: 7),
    ),
    'zone_bois_herbe_3': MapRect(
      pos: GridPos(x: 7, y: 29),
      size: GridSize(width: 10, height: 7),
    ),
    'zone_bois_herbe_4': MapRect(
      pos: GridPos(x: 27, y: 30),
      size: GridSize(width: 8, height: 6),
    ),
  };
  if (forest.gameplayZones.length != grassAreas.length ||
      !forest.gameplayZones
          .map((zone) => zone.id)
          .toSet()
          .containsAll(grassAreas.keys)) {
    throw StateError('Task 9 forest grass-zone inventory is not exact.');
  }
  for (final zone in forest.gameplayZones) {
    if (zone.area != grassAreas[zone.id] ||
        zone.kind != GameplayZoneKind.special ||
        zone.encounter != null ||
        zone.special?.scriptKey != null ||
        zone.special?.properties['contractRole'] != 'tall_grass_surface' ||
        zone.special?.properties['inert'] != 'true') {
      throw StateError('${zone.id} violates the structural grass contract.');
    }
  }

  final placedById = <String, MapPlacedElement>{
    for (final placed in forest.placedElements) placed.id: placed,
  };
  final forestSpecById = <String, _ForestElementSpec>{
    for (final spec in _forestElementSpecs) spec.id: spec,
  };
  for (final contract in const <(String, String, String, GridPos)>[
    (
      'pe_bois_pin_grand_001',
      'el_selbrume_bois_pin_grand',
      'l_tile_overhead',
      GridPos(x: 2, y: 2),
    ),
    (
      'pe_bois_pin_moyen_001',
      'el_selbrume_bois_pin_moyen',
      'l_tile_overhead',
      GridPos(x: 19, y: 2),
    ),
    (
      'pe_bois_pin_petit_001',
      'el_selbrume_bois_pin_petit',
      'l_tile_overhead',
      GridPos(x: 38, y: 3),
    ),
    (
      'pe_bois_buisson_1_001',
      'el_selbrume_bois_buisson_1',
      'l_tile_ground',
      GridPos(x: 5, y: 15),
    ),
    (
      'pe_bois_buisson_2_001',
      'el_selbrume_bois_buisson_2',
      'l_tile_ground',
      GridPos(x: 35, y: 18),
    ),
    (
      'pe_bois_fougere_001',
      'el_selbrume_bois_fougere',
      'l_tile_ground',
      GridPos(x: 17, y: 19),
    ),
    (
      'pe_bois_souche_001',
      'el_selbrume_bois_souche',
      'l_tile_structures',
      GridPos(x: 37, y: 29),
    ),
    (
      'pe_bois_tronc_tombe_001',
      'el_selbrume_bois_tronc_tombe',
      'l_tile_structures',
      GridPos(x: 18, y: 36),
    ),
    (
      'pe_bois_ronces_001',
      'el_selbrume_bois_ronces',
      'l_tile_structures',
      GridPos(x: 19, y: 20),
    ),
    (
      'pe_bois_aiguilles_sol_001',
      'el_selbrume_bois_aiguilles_sol',
      'l_tile_ground',
      GridPos(x: 10, y: 18),
    ),
    (
      'pe_bois_banc_001',
      'el_selbrume_bois_banc',
      'l_tile_structures',
      GridPos(x: 27, y: 21),
    ),
    (
      'pe_bois_panneau_001',
      'el_selbrume_bois_panneau',
      'l_tile_structures',
      GridPos(x: 3, y: 21),
    ),
  ]) {
    final placed = placedById[contract.$1];
    if (placed == null ||
        placed.elementId != contract.$2 ||
        placed.layerId != contract.$3 ||
        placed.pos != contract.$4) {
      throw StateError(
          '${contract.$1} violates the forest placement contract.');
    }
    final shouldApplyCollision =
        forestSpecById[placed.elementId]!.collisionCells.isNotEmpty;
    if (placed.applyCollision != shouldApplyCollision) {
      throw StateError(
        '${contract.$1} applyCollision does not match its forest profile.',
      );
    }
  }
  final usedElementIds =
      forest.placedElements.map((placed) => placed.elementId).toSet();
  if (forest.placedElements.length != _task9ForestElementIds.length ||
      !usedElementIds.containsAll(_task9ForestElementIds)) {
    throw StateError('Task 9 forest must place all twelve atlas elements.');
  }

  final primary = forest.layers
      .whereType<PathLayer>()
      .singleWhere((layer) => layer.id == 'l_path_primary');
  final tallGrass = forest.layers
      .whereType<PathLayer>()
      .singleWhere((layer) => layer.id == 'l_path_secondary');
  final blocked = _portBlockedCells(forest, elementsById);
  if (primary.presetId != 'dirth_path' || tallGrass.presetId != 'haute_herbe') {
    throw StateError('Task 9 forest path presets are invalid.');
  }
  for (var index = 0; index < primary.cells.length; index += 1) {
    if (primary.cells[index] && tallGrass.cells[index]) {
      throw StateError('Task 9 forest path overlaps tall grass at $index.');
    }
    if (primary.cells[index] && blocked[index]) {
      throw StateError('Task 9 forest path is dynamically blocked at $index.');
    }
  }
  for (final placed in forest.placedElements) {
    final spec = forestSpecById[placed.elementId]!;
    final collisionCells = spec.collisionCells.toSet();
    for (final cell in spec.collisionCells) {
      final x = placed.pos.x + cell.x;
      final y = placed.pos.y + cell.y;
      if (!blocked[y * forest.size.width + x]) {
        throw StateError('${placed.id} solid base is passable at ($x,$y).');
      }
    }
    if (!spec.hasCanopy) continue;
    for (var localY = 0; localY < spec.source.height; localY += 1) {
      for (var localX = 0; localX < spec.source.width; localX += 1) {
        final local = GridPos(x: localX, y: localY);
        if (collisionCells.contains(local)) continue;
        final x = placed.pos.x + localX;
        final y = placed.pos.y + localY;
        if (blocked[y * forest.size.width + x]) {
          throw StateError('${placed.id} canopy blocks at ($x,$y).');
        }
      }
    }
  }
  for (var y = 24; y <= 28; y += 1) {
    for (var x = 0; x < forest.size.width; x += 1) {
      final index = y * forest.size.width + x;
      if (!primary.cells[index] || blocked[index]) {
        throw StateError('Task 9 west/east corridor is blocked at ($x,$y).');
      }
    }
  }
  for (final crossing in const <List<GridPos>>[
    <GridPos>[
      GridPos(x: 13, y: 20),
      GridPos(x: 14, y: 20),
      GridPos(x: 15, y: 20),
    ],
    <GridPos>[
      GridPos(x: 23, y: 20),
      GridPos(x: 24, y: 20),
      GridPos(x: 25, y: 20),
    ],
    <GridPos>[
      GridPos(x: 30, y: 26),
      GridPos(x: 31, y: 26),
      GridPos(x: 32, y: 26),
    ],
  ]) {
    if (crossing.where((pos) {
          final index = pos.y * forest.size.width + pos.x;
          return primary.cells[index] && !blocked[index];
        }).length <
        3) {
      throw StateError('Task 9 forest critical crossing is too narrow.');
    }
  }
  for (final center in const <GridPos>[
    GridPos(x: 14, y: 15),
    GridPos(x: 31, y: 30),
  ]) {
    for (var y = center.y - 1; y <= center.y + 1; y += 1) {
      for (var x = center.x - 1; x <= center.x + 1; x += 1) {
        final index = y * forest.size.width + x;
        if (!primary.cells[index] || tallGrass.cells[index] || blocked[index]) {
          throw StateError(
            'Task 9 forest clearing around $center is obstructed at ($x,$y).',
          );
        }
      }
    }
  }

  Set<int> reachablePrimary(
    GridPos start, {
    Set<int> excluded = const <int>{},
  }) {
    final startIndex = start.y * forest.size.width + start.x;
    if (!primary.cells[startIndex] ||
        blocked[startIndex] ||
        excluded.contains(startIndex)) {
      return <int>{};
    }
    final reached = <int>{startIndex};
    final queue = <GridPos>[start];
    var cursor = 0;
    while (cursor < queue.length) {
      final current = queue[cursor++];
      for (final next in <GridPos>[
        GridPos(x: current.x, y: current.y - 1),
        GridPos(x: current.x + 1, y: current.y),
        GridPos(x: current.x, y: current.y + 1),
        GridPos(x: current.x - 1, y: current.y),
      ]) {
        if (next.x < 0 ||
            next.y < 0 ||
            next.x >= forest.size.width ||
            next.y >= forest.size.height) {
          continue;
        }
        final index = next.y * forest.size.width + next.x;
        if (!primary.cells[index] ||
            blocked[index] ||
            excluded.contains(index) ||
            !reached.add(index)) {
          continue;
        }
        queue.add(next);
      }
    }
    return reached;
  }

  final reached = reachablePrimary(const GridPos(x: 0, y: 26));
  for (final pos in const <GridPos>[
    GridPos(x: 44, y: 26),
    GridPos(x: 14, y: 15),
    GridPos(x: 24, y: 16),
    GridPos(x: 24, y: 23),
    GridPos(x: 31, y: 30),
  ]) {
    final index = pos.y * forest.size.width + pos.x;
    if (!primary.cells[index] || !reached.contains(index)) {
      throw StateError('Task 9 forest anchor is unreachable at $pos.');
    }
  }
  final directMainSegment = <int>{
    for (var x = 15; x <= 23; x += 1) 24 * forest.size.width + x,
  };
  final loopReached = reachablePrimary(
    const GridPos(x: 14, y: 24),
    excluded: directMainSegment,
  );
  const loopReturn = GridPos(x: 24, y: 24);
  if (!loopReached.contains(
    loopReturn.y * forest.size.width + loopReturn.x,
  )) {
    throw StateError('Task 9 forest optional loop lacks two main-path joins.');
  }
  final marker = manifest.groups
      .singleWhere((group) => group.id == 'group_selbrume_bourg')
      .properties['selbrumeGeneratorBoundary'];
  if (marker != 'task9' &&
      marker != 'task10' &&
      marker != 'task11' &&
      marker != 'task12' &&
      marker != 'task13' &&
      marker != 'task14' &&
      marker != 'task15' &&
      marker != 'task16') {
    throw StateError('Task 9 boundary marker is missing from the manifest.');
  }
}

void _validateTask10Output({
  required Map<String, Map<String, dynamic>> maps,
  required ProjectManifest manifest,
}) {
  final folders = manifest.tilesetFolders.where(
    (entry) => entry.id == 'tsf_selbrume_beta_marsh',
  );
  if (folders.length != 1 ||
      folders.single.parentFolderId != 'tsf_selbrume_beta') {
    throw StateError('Task 10 Selbrume marsh tileset folder is invalid.');
  }
  final categories = manifest.elementCategories.where(
    (entry) => entry.id == 'cat_selbrume_marsh',
  );
  if (categories.length != 1 ||
      categories.single.parentCategoryId != 'environnement') {
    throw StateError('cat_selbrume_marsh must exist below environnement.');
  }
  final tilesets = manifest.tilesets.where(
    (entry) => entry.id == 'ts_selbrume_marsh_props',
  );
  if (tilesets.length != 1 ||
      tilesets.single.relativePath !=
          'assets/tilesets/selbrume_marsh_props.png' ||
      tilesets.single.folderId != 'tsf_selbrume_beta_marsh') {
    throw StateError('ts_selbrume_marsh_props registration is invalid.');
  }

  final elementsById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  for (final spec in _marshElementSpecs) {
    final element = elementsById[spec.id];
    final expectedStateTag = spec.isStateVariant ? 'state_variant' : 'static';
    if (element == null ||
        element.tilesetId != 'ts_selbrume_marsh_props' ||
        element.categoryId != 'cat_selbrume_marsh' ||
        element.frames.length != 1 ||
        element.frames.single.source != spec.source ||
        element.frames.single.durationMs != null ||
        element.recommendedLayerId != spec.layerId ||
        !element.tags.toSet().containsAll(<String>{
          'selbrume',
          'environment',
          'marsh',
          'map_marais_salants',
          'beta',
          expectedStateTag,
        })) {
      throw StateError('${spec.id} has an invalid Task 10 element contract.');
    }
    if (spec.collisionCells.isEmpty) {
      if (element.collisionProfile != null) {
        throw StateError('${spec.id} must remain passable.');
      }
      continue;
    }
    final profile = element.collisionProfile;
    if (profile == null ||
        profile.source != ElementCollisionProfileSource.manual ||
        !_sameGridPositions(profile.cells, spec.collisionCells) ||
        !_sameGridPositions(profile.shapeCells, spec.collisionCells) ||
        profile.visualMask == null ||
        profile.collisionMask == null ||
        (profile.occlusionMask != null) != spec.occlusionCells.isNotEmpty) {
      throw StateError('${spec.id} has an invalid Task 10 collision profile.');
    }
    _validatePortMask(
      spec.id,
      'visual',
      profile.visualMask!,
      spec.source,
      requireSolidPixel: true,
    );
    _validatePortMask(
      spec.id,
      'collision',
      profile.collisionMask!,
      spec.source,
      requireSolidPixel: true,
    );
    if (profile.occlusionMask != null) {
      _validatePortMask(
        spec.id,
        'occlusion',
        profile.occlusionMask!,
        spec.source,
        requireSolidPixel: true,
      );
    }
    final derivedCells = ElementCollisionMaskCodec.cellsFromPixelMask(
      mask: profile.collisionMask!,
      tileWidth: 32,
      tileHeight: 32,
      sourceWidthInTiles: spec.source.width,
      sourceHeightInTiles: spec.source.height,
    );
    if (!_sameGridPositions(derivedCells, spec.collisionCells)) {
      throw StateError('${spec.id} pixel/coarse collision cells diverge.');
    }
  }
  final registeredMarshIds = manifest.elements
      .where((element) => element.tilesetId == 'ts_selbrume_marsh_props')
      .map((element) => element.id)
      .toSet();
  if (registeredMarshIds.length != _task10MarshElementIds.length ||
      !registeredMarshIds.containsAll(_task10MarshElementIds)) {
    throw StateError('Task 10 marsh atlas must expose exactly 23 elements.');
  }

  final marsh = MapData.fromJson(maps['map_marais_salants']!);
  const expectedLayerIds = <String>[
    'l_terrain',
    'l_path_primary',
    'l_path_secondary',
    'l_tile_ground',
    'l_tile_structures',
    'l_tile_overhead',
    'l_tile_fx',
    'l_collisions',
  ];
  if (marsh.size != const GridSize(width: 45, height: 45) ||
      marsh.tilesetId.isNotEmpty ||
      marsh.mapMetadata.isIndoor ||
      marsh.mapMetadata.mapType != MapType.route ||
      marsh.properties['selbrumeGeneratorBoundary'] != 'task10' ||
      marsh.layers.map((layer) => layer.id).join('|') !=
          expectedLayerIds.join('|') ||
      marsh.layers.whereType<TileLayer>().any(
            (layer) => layer.tilesetId != 'ts_selbrume_marsh_props',
          )) {
    throw StateError('Task 10 marsh base/layer contract is invalid.');
  }
  if (marsh.warps.isNotEmpty || marsh.events.isNotEmpty) {
    throw StateError('Task 10 marsh must not invent narrative actions.');
  }
  final connectionKeys = <String>{
    for (final connection in marsh.connections)
      '${connection.direction.name}:${connection.targetMapId}:'
          '${connection.offset}',
  };
  if (marsh.connections.length != 2 ||
      !connectionKeys.containsAll(const <String>{
        'west:map_bois_chaise_brume:0',
        'south:map_passage_dames:0',
      })) {
    throw StateError('Task 10 marsh connections are not exact.');
  }

  final entitiesById = <String, MapEntity>{
    for (final entity in marsh.entities) entity.id: entity,
  };
  final grant = entitiesById['grant'];
  final mado = entitiesById['anchor_marais_mado'];
  if (entitiesById.length != 2 ||
      grant == null ||
      grant.kind != MapEntityKind.npc ||
      grant.pos != const GridPos(x: 24, y: 20) ||
      grant.size != const GridSize(width: 2, height: 2) ||
      grant.npc?.trainerId != 'grant' ||
      mado == null ||
      mado.kind != MapEntityKind.custom ||
      mado.pos != const GridPos(x: 10, y: 12) ||
      mado.blocksMovement ||
      mado.properties['contractRole'] != 'reserved_character_anchor' ||
      mado.properties['inert'] != 'true') {
    throw StateError('Task 10 marsh entity preservation is invalid.');
  }

  const encounterAreas = <String, MapRect>{
    'zone': MapRect(
      pos: GridPos(x: 1, y: 27),
      size: GridSize(width: 2, height: 8),
    ),
    'zone_1': MapRect(
      pos: GridPos(x: 3, y: 27),
      size: GridSize(width: 3, height: 6),
    ),
    'zone_2': MapRect(
      pos: GridPos(x: 4, y: 28),
      size: GridSize(width: 3, height: 8),
    ),
    'zone_3': MapRect(
      pos: GridPos(x: 7, y: 31),
      size: GridSize(width: 5, height: 3),
    ),
    'zone_4': MapRect(
      pos: GridPos(x: 10, y: 32),
      size: GridSize(width: 3, height: 2),
    ),
  };
  if (marsh.gameplayZones.length != encounterAreas.length + 1) {
    throw StateError('Task 10 marsh gameplay-zone inventory is not exact.');
  }
  for (final contract in encounterAreas.entries) {
    final matches =
        marsh.gameplayZones.where((zone) => zone.id == contract.key);
    if (matches.length != 1 ||
        matches.single.name != contract.key ||
        matches.single.kind != GameplayZoneKind.encounter ||
        matches.single.area != contract.value ||
        matches.single.encounter?.encounterTableId != 'grass_path_route_1') {
      throw StateError('${contract.key} encounter-zone preservation failed.');
    }
  }
  _requirePortZone(marsh, 'zone_marais_entry', 0, 22, 5, 7);

  for (final contract in const <(String, String, int, int, int, int)>[
    ('zone_marais_entry', 'event_marais_entry', 0, 22, 5, 7),
    (
      'tr_marais_indice_verre',
      'event_selbrume_indice_verre',
      8,
      32,
      1,
      1,
    ),
    (
      'tr_marais_indice_traces_electriques',
      'event_selbrume_indice_traces_electriques',
      32,
      10,
      1,
      1,
    ),
    (
      'tr_marais_indice_repere_lentille',
      'event_selbrume_indice_repere_lentille',
      34,
      34,
      1,
      1,
    ),
    ('tr_marais_cristal_1', 'event_selbrume_cristal_1', 14, 7, 1, 1),
    ('tr_marais_cristal_2', 'event_selbrume_cristal_2', 24, 28, 1, 1),
    ('tr_marais_cristal_3', 'event_selbrume_cristal_3', 38, 22, 1, 1),
  ]) {
    _requirePortTrigger(
      marsh,
      contract.$1,
      contract.$2,
      contract.$3,
      contract.$4,
      contract.$5,
      contract.$6,
    );
  }
  if (marsh.triggers.length != 7) {
    throw StateError('Task 10 marsh reserved-trigger inventory is not exact.');
  }

  final placedById = <String, MapPlacedElement>{
    for (final placed in marsh.placedElements) placed.id: placed,
  };
  for (final contract in const <(String, String, String, GridPos)>[
    (
      'pe_marais_cabane_paludier',
      'el_selbrume_marais_cabane_paludier',
      'l_tile_structures',
      GridPos(x: 4, y: 14),
    ),
    (
      'pe_marais_ecluse',
      'el_selbrume_marais_ecluse_fermee',
      'l_tile_structures',
      GridPos(x: 27, y: 18),
    ),
    (
      'pe_marais_indice_verre',
      'el_selbrume_indice_verre',
      'l_tile_ground',
      GridPos(x: 8, y: 32),
    ),
    (
      'pe_marais_indice_traces_electriques',
      'el_selbrume_indice_traces_electriques',
      'l_tile_fx',
      GridPos(x: 32, y: 10),
    ),
    (
      'pe_marais_indice_repere_lentille',
      'el_selbrume_indice_repere_lentille',
      'l_tile_ground',
      GridPos(x: 34, y: 34),
    ),
    (
      'pe_marais_cristal_1',
      'el_selbrume_cristal_1',
      'l_tile_fx',
      GridPos(x: 14, y: 7),
    ),
    (
      'pe_marais_cristal_2',
      'el_selbrume_cristal_2',
      'l_tile_fx',
      GridPos(x: 24, y: 28),
    ),
    (
      'pe_marais_cristal_3',
      'el_selbrume_cristal_3',
      'l_tile_fx',
      GridPos(x: 38, y: 22),
    ),
  ]) {
    _requirePortPlacement(
      placedById,
      contract.$1,
      contract.$2,
      contract.$3,
      contract.$4,
    );
  }
  final marshSpecById = <String, _MarshElementSpec>{
    for (final spec in _marshElementSpecs) spec.id: spec,
  };
  final usedElementIds =
      marsh.placedElements.map((placed) => placed.elementId).toSet();
  final expectedUsedElementIds = _task10MarshElementIds
      .where((id) => id != 'el_selbrume_marais_ecluse_ouverte')
      .toSet();
  if (marsh.placedElements.length != expectedUsedElementIds.length ||
      usedElementIds.length != expectedUsedElementIds.length ||
      !usedElementIds.containsAll(expectedUsedElementIds)) {
    throw StateError('Task 10 marsh placement inventory is not exact.');
  }
  for (final placed in marsh.placedElements) {
    final spec = marshSpecById[placed.elementId];
    if (spec == null ||
        placed.applyCollision != spec.collisionCells.isNotEmpty) {
      throw StateError('${placed.id} applyCollision violates its marsh spec.');
    }
  }

  final primary = marsh.layers
      .whereType<PathLayer>()
      .singleWhere((layer) => layer.id == 'l_path_primary');
  final secondary = marsh.layers
      .whereType<PathLayer>()
      .singleWhere((layer) => layer.id == 'l_path_secondary');
  final blocked = _portBlockedCells(marsh, elementsById);
  if (primary.presetId != 'pavement_path' ||
      secondary.presetId != 'haute_herbe') {
    throw StateError('Task 10 marsh path presets are invalid.');
  }
  final allowed = <bool>[
    for (var index = 0; index < primary.cells.length; index += 1)
      primary.cells[index] || secondary.cells[index],
  ];
  const start = GridPos(x: 0, y: 26);
  final startIndex = start.y * marsh.size.width + start.x;
  final reached = <int>{startIndex};
  final queue = <GridPos>[start];
  var cursor = 0;
  while (cursor < queue.length) {
    final current = queue[cursor++];
    for (final next in <GridPos>[
      GridPos(x: current.x, y: current.y - 1),
      GridPos(x: current.x + 1, y: current.y),
      GridPos(x: current.x, y: current.y + 1),
      GridPos(x: current.x - 1, y: current.y),
    ]) {
      if (next.x < 0 ||
          next.y < 0 ||
          next.x >= marsh.size.width ||
          next.y >= marsh.size.height) {
        continue;
      }
      final index = next.y * marsh.size.width + next.x;
      if (allowed[index] && !blocked[index] && reached.add(index)) {
        queue.add(next);
      }
    }
  }
  for (final pos in const <GridPos>[
    GridPos(x: 10, y: 12),
    GridPos(x: 8, y: 32),
    GridPos(x: 32, y: 10),
    GridPos(x: 34, y: 34),
    GridPos(x: 14, y: 7),
    GridPos(x: 24, y: 28),
    GridPos(x: 38, y: 22),
    GridPos(x: 6, y: 18),
    GridPos(x: 18, y: 24),
    GridPos(x: 31, y: 30),
    GridPos(x: 19, y: 17),
    GridPos(x: 31, y: 25),
  ]) {
    final index = pos.y * marsh.size.width + pos.x;
    if (!primary.cells[index] || blocked[index] || !reached.contains(index)) {
      throw StateError('Task 10 marsh anchor is unreachable at $pos.');
    }
  }
  for (var y = 24; y <= 28; y += 1) {
    final index = y * marsh.size.width;
    if (!primary.cells[index] || blocked[index] || !reached.contains(index)) {
      throw StateError('Task 10 west corridor is blocked at (0,$y).');
    }
  }
  for (var x = 30; x <= 34; x += 1) {
    final index = 44 * marsh.size.width + x;
    if (!primary.cells[index] || blocked[index] || !reached.contains(index)) {
      throw StateError('Task 10 south corridor is blocked at ($x,44).');
    }
  }
  for (final basin in const <GridPos>[
    GridPos(x: 20, y: 5),
    GridPos(x: 40, y: 40),
    GridPos(x: 24, y: 15),
  ]) {
    if (!blocked[basin.y * marsh.size.width + basin.x]) {
      throw StateError('Task 10 basin is passable at $basin.');
    }
  }
  final marker = manifest.groups
      .singleWhere((group) => group.id == 'group_selbrume_bourg')
      .properties['selbrumeGeneratorBoundary'];
  if (marker != 'task10' &&
      marker != 'task11' &&
      marker != 'task12' &&
      marker != 'task13' &&
      marker != 'task14' &&
      marker != 'task15' &&
      marker != 'task16') {
    throw StateError('Task 10 boundary marker is missing from the manifest.');
  }
}

void _validateTask11Output({
  required Map<String, Map<String, dynamic>> maps,
  required ProjectManifest manifest,
}) {
  final folders = manifest.tilesetFolders.where(
    (entry) => entry.id == 'tsf_selbrume_beta_passage',
  );
  if (folders.length != 1 ||
      folders.single.parentFolderId != 'tsf_selbrume_beta') {
    throw StateError('Task 11 Selbrume passage tileset folder is invalid.');
  }
  final categories = manifest.elementCategories.where(
    (entry) => entry.id == 'cat_selbrume_passage',
  );
  if (categories.length != 1 ||
      categories.single.parentCategoryId != 'environnement') {
    throw StateError('cat_selbrume_passage must exist below environnement.');
  }
  final tilesets = manifest.tilesets.where(
    (entry) => entry.id == 'ts_selbrume_passage_props',
  );
  if (tilesets.length != 1 ||
      tilesets.single.relativePath !=
          'assets/tilesets/selbrume_passage_props.png' ||
      tilesets.single.folderId != 'tsf_selbrume_beta_passage') {
    throw StateError('ts_selbrume_passage_props registration is invalid.');
  }

  final elementsById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  for (final spec in _passageElementSpecs) {
    final element = elementsById[spec.id];
    final stateTag = spec.isStateVariant ? 'state_variant' : 'static';
    if (element == null ||
        element.tilesetId != 'ts_selbrume_passage_props' ||
        element.categoryId != 'cat_selbrume_passage' ||
        element.frames.length != 1 ||
        element.frames.single.source != spec.source ||
        element.frames.single.durationMs != null ||
        element.recommendedLayerId != spec.layerId ||
        !element.tags.toSet().containsAll(<String>{
          'selbrume',
          'environment',
          'passage',
          'map_passage_dames',
          'beta',
          stateTag,
        })) {
      throw StateError('${spec.id} has an invalid Task 11 element contract.');
    }
    if (spec.collisionCells.isEmpty) {
      if (element.collisionProfile != null) {
        throw StateError('${spec.id} must remain passable.');
      }
      continue;
    }
    final profile = element.collisionProfile;
    if (profile == null ||
        profile.source != ElementCollisionProfileSource.manual ||
        !_sameGridPositions(profile.cells, spec.collisionCells) ||
        !_sameGridPositions(profile.shapeCells, spec.collisionCells) ||
        profile.visualMask == null ||
        profile.collisionMask == null ||
        profile.occlusionMask != null) {
      throw StateError('${spec.id} has an invalid Task 11 collision profile.');
    }
    _validatePortMask(
      spec.id,
      'visual',
      profile.visualMask!,
      spec.source,
      requireSolidPixel: true,
    );
    _validatePortMask(
      spec.id,
      'collision',
      profile.collisionMask!,
      spec.source,
      requireSolidPixel: true,
    );
    final derivedCells = ElementCollisionMaskCodec.cellsFromPixelMask(
      mask: profile.collisionMask!,
      tileWidth: 32,
      tileHeight: 32,
      sourceWidthInTiles: spec.source.width,
      sourceHeightInTiles: spec.source.height,
    );
    if (!_sameGridPositions(derivedCells, spec.collisionCells)) {
      throw StateError('${spec.id} pixel/coarse collision cells diverge.');
    }
  }
  final registeredIds = manifest.elements
      .where((element) => element.tilesetId == 'ts_selbrume_passage_props')
      .map((element) => element.id)
      .toSet();
  if (registeredIds.length != _task11PassageElementIds.length ||
      !registeredIds.containsAll(_task11PassageElementIds)) {
    throw StateError('Task 11 passage atlas must expose exactly 14 elements.');
  }

  final passage = MapData.fromJson(maps['map_passage_dames']!);
  const expectedLayerIds = <String>[
    'l_terrain',
    'l_path_primary',
    'l_path_secondary',
    'l_tile_ground',
    'l_tile_structures',
    'l_tile_overhead',
    'l_tile_fx',
    'l_collisions',
  ];
  if (passage.size != const GridSize(width: 60, height: 24) ||
      passage.tilesetId.isNotEmpty ||
      passage.mapMetadata.isIndoor ||
      passage.mapMetadata.mapType != MapType.route ||
      passage.mapMetadata.weather != MapWeather.fog ||
      passage.properties['selbrumeGeneratorBoundary'] != 'task11' ||
      passage.layers.map((layer) => layer.id).join('|') !=
          expectedLayerIds.join('|') ||
      passage.layers.whereType<TileLayer>().any(
            (layer) => layer.tilesetId != 'ts_selbrume_passage_props',
          )) {
    throw StateError('Task 11 passage base/layer contract is invalid.');
  }
  if (passage.warps.isNotEmpty ||
      passage.events.isNotEmpty ||
      passage.entities.isNotEmpty) {
    throw StateError('Task 11 passage must not invent narrative content.');
  }
  final connectionKeys = <String>{
    for (final connection in passage.connections)
      '${connection.direction.name}:${connection.targetMapId}:'
          '${connection.offset}',
  };
  if (passage.connections.length != 2 ||
      !connectionKeys.containsAll(const <String>{
        'north:map_marais_salants:0',
        'east:map_phare_exterieur:0',
      })) {
    throw StateError('Task 11 passage connections are not exact.');
  }
  _requirePortZone(passage, 'zone_passage_entry', 28, 0, 9, 5);
  _requirePortTrigger(
    passage,
    'zone_passage_entry',
    'event_enter_passage_dames',
    28,
    0,
    9,
    5,
  );
  if (passage.gameplayZones.length != 1 || passage.triggers.length != 1) {
    throw StateError('Task 11 passage reservation inventory is not exact.');
  }

  final placedById = <String, MapPlacedElement>{
    for (final placed in passage.placedElements) placed.id: placed,
  };
  _requirePortPlacement(
    placedById,
    'pe_passage_barriere',
    'el_selbrume_passage_barriere_fermee',
    'l_tile_structures',
    const GridPos(x: 32, y: 3),
  );
  _requirePortPlacement(
    placedById,
    'pe_passage_marches',
    'el_selbrume_passage_marches',
    'l_tile_ground',
    const GridPos(x: 56, y: 13),
  );
  _requirePortPlacement(
    placedById,
    'pe_passage_flaques',
    'el_selbrume_passage_flaques',
    'l_tile_ground',
    const GridPos(x: 49, y: 9),
  );
  _requirePortPlacement(
    placedById,
    'pe_passage_banc_brume',
    'el_selbrume_passage_banc_brume',
    'l_tile_fx',
    const GridPos(x: 42, y: 10),
  );
  final passageSpecById = <String, _PassageElementSpec>{
    for (final spec in _passageElementSpecs) spec.id: spec,
  };
  final expectedUsedIds = _task11PassageElementIds
      .where((id) => id != 'el_selbrume_passage_barriere_ouverte')
      .toSet();
  final usedIds =
      passage.placedElements.map((placed) => placed.elementId).toSet();
  if (passage.placedElements.length != expectedUsedIds.length ||
      usedIds.length != expectedUsedIds.length ||
      !usedIds.containsAll(expectedUsedIds)) {
    throw StateError('Task 11 passage placement inventory is not exact.');
  }
  for (final placed in passage.placedElements) {
    final spec = passageSpecById[placed.elementId];
    if (spec == null ||
        placed.applyCollision != spec.collisionCells.isNotEmpty) {
      throw StateError(
        '${placed.id} applyCollision violates its passage spec.',
      );
    }
  }

  final primary = passage.layers
      .whereType<PathLayer>()
      .singleWhere((layer) => layer.id == 'l_path_primary');
  final sea = passage.layers
      .whereType<PathLayer>()
      .singleWhere((layer) => layer.id == 'l_path_secondary');
  final blocked = _portBlockedCells(passage, elementsById);
  if (primary.presetId != 'pavement_path' || sea.presetId != 'nouveau-chemin') {
    throw StateError('Task 11 passage path presets are invalid.');
  }
  for (var index = 0; index < primary.cells.length; index += 1) {
    if (primary.cells[index] == sea.cells[index]) {
      throw StateError('Task 11 path/sea partition is invalid at $index.');
    }
  }
  const start = GridPos(x: 32, y: 0);
  final startIndex = start.y * passage.size.width + start.x;
  final reached = <int>{startIndex};
  final queue = <GridPos>[start];
  var cursor = 0;
  while (cursor < queue.length) {
    final current = queue[cursor++];
    for (final next in <GridPos>[
      GridPos(x: current.x, y: current.y - 1),
      GridPos(x: current.x + 1, y: current.y),
      GridPos(x: current.x, y: current.y + 1),
      GridPos(x: current.x - 1, y: current.y),
    ]) {
      if (next.x < 0 ||
          next.y < 0 ||
          next.x >= passage.size.width ||
          next.y >= passage.size.height) {
        continue;
      }
      final index = next.y * passage.size.width + next.x;
      if (primary.cells[index] && !blocked[index] && reached.add(index)) {
        queue.add(next);
      }
    }
  }
  final critical = <GridPos>[
    for (var x = 30; x <= 34; x += 1) GridPos(x: x, y: 0),
    for (var y = 12; y <= 16; y += 1) GridPos(x: 59, y: y),
    for (var y = 9; y <= 11; y += 1)
      for (var x = 49; x <= 51; x += 1) GridPos(x: x, y: y),
    for (final x in const <int>[28, 29, 30, 31]) GridPos(x: x, y: 4),
    const GridPos(x: 44, y: 12),
    const GridPos(x: 50, y: 10),
    const GridPos(x: 57, y: 13),
  ];
  for (final pos in critical) {
    final index = pos.y * passage.size.width + pos.x;
    if (!primary.cells[index] || blocked[index] || !reached.contains(index)) {
      throw StateError('Task 11 passage anchor is unreachable at $pos.');
    }
  }
  for (var x = 32; x <= 35; x += 1) {
    if (!blocked[4 * passage.size.width + x]) {
      throw StateError('Task 11 closed barrier is passable at ($x,4).');
    }
  }
  for (final seaCell in const <GridPos>[
    GridPos(x: 29, y: 8),
    GridPos(x: 35, y: 8),
    GridPos(x: 40, y: 11),
    GridPos(x: 40, y: 17),
  ]) {
    final index = seaCell.y * passage.size.width + seaCell.x;
    if (!sea.cells[index] || !blocked[index]) {
      throw StateError('Task 11 sea is passable at $seaCell.');
    }
  }
  final marker = manifest.groups
      .singleWhere((group) => group.id == 'group_selbrume_bourg')
      .properties['selbrumeGeneratorBoundary'];
  if (marker != 'task11' &&
      marker != 'task12' &&
      marker != 'task13' &&
      marker != 'task14' &&
      marker != 'task15' &&
      marker != 'task16') {
    throw StateError('Task 11 boundary marker is missing from the manifest.');
  }
}

void _validateTask12Output({
  required Map<String, Map<String, dynamic>> maps,
  required ProjectManifest manifest,
}) {
  final folders = manifest.tilesetFolders.where(
    (entry) => entry.id == 'tsf_selbrume_beta_lighthouse',
  );
  if (folders.length != 1 ||
      folders.single.parentFolderId != 'tsf_selbrume_beta') {
    throw StateError('Task 12 lighthouse tileset folder is invalid.');
  }
  final categories = manifest.elementCategories.where(
    (entry) => entry.id == 'cat_selbrume_lighthouse',
  );
  if (categories.length != 1 ||
      categories.single.parentCategoryId != 'batiments') {
    throw StateError('cat_selbrume_lighthouse must exist below batiments.');
  }
  final tilesets = manifest.tilesets.where(
    (entry) => entry.id == 'ts_selbrume_lighthouse_exterior',
  );
  if (tilesets.length != 1 ||
      tilesets.single.relativePath !=
          'assets/tilesets/selbrume_lighthouse_exterior.png' ||
      tilesets.single.folderId != 'tsf_selbrume_beta_lighthouse') {
    throw StateError('Task 12 lighthouse tileset registration is invalid.');
  }

  final elementsById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  for (final spec in _lighthouseExteriorElementSpecs) {
    final element = elementsById[spec.id];
    final stateTag = spec.isStateVariant ? 'state_variant' : 'static';
    if (element == null ||
        element.tilesetId != 'ts_selbrume_lighthouse_exterior' ||
        element.categoryId != 'cat_selbrume_lighthouse' ||
        element.frames.length != 1 ||
        element.frames.single.source != spec.source ||
        element.frames.single.durationMs != null ||
        element.recommendedLayerId != spec.layerId ||
        !element.tags.toSet().containsAll(<String>{
          'selbrume',
          'lighthouse',
          'map_phare_exterieur',
          'beta',
          stateTag,
        })) {
      throw StateError('${spec.id} has an invalid Task 12 element contract.');
    }
    if (spec.collisionCells.isEmpty && spec.occlusionCells.isEmpty) {
      if (element.collisionProfile != null) {
        throw StateError('${spec.id} must remain passable.');
      }
      continue;
    }
    final profile = element.collisionProfile;
    if (profile == null ||
        profile.source != ElementCollisionProfileSource.manual ||
        !_sameGridPositions(profile.cells, spec.collisionCells) ||
        !_sameGridPositions(profile.shapeCells, spec.collisionCells) ||
        profile.visualMask == null ||
        (profile.collisionMask != null) != spec.collisionCells.isNotEmpty ||
        (profile.occlusionMask != null) != spec.occlusionCells.isNotEmpty) {
      throw StateError('${spec.id} has an invalid Task 12 collision profile.');
    }
    _validatePortMask(
      spec.id,
      'visual',
      profile.visualMask!,
      spec.source,
      requireSolidPixel: true,
    );
    if (profile.collisionMask != null) {
      _validatePortMask(
        spec.id,
        'collision',
        profile.collisionMask!,
        spec.source,
        requireSolidPixel: true,
      );
      final derivedCollisionCells =
          ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: profile.collisionMask!,
        tileWidth: 32,
        tileHeight: 32,
        sourceWidthInTiles: spec.source.width,
        sourceHeightInTiles: spec.source.height,
      );
      if (!_sameGridPositions(derivedCollisionCells, spec.collisionCells)) {
        throw StateError('${spec.id} pixel/coarse collision cells diverge.');
      }
    }
    if (profile.occlusionMask != null) {
      _validatePortMask(
        spec.id,
        'occlusion',
        profile.occlusionMask!,
        spec.source,
        requireSolidPixel: true,
      );
      final derivedOcclusionCells =
          ElementCollisionMaskCodec.cellsFromPixelMask(
        mask: profile.occlusionMask!,
        tileWidth: 32,
        tileHeight: 32,
        sourceWidthInTiles: spec.source.width,
        sourceHeightInTiles: spec.source.height,
      );
      if (!_sameGridPositions(derivedOcclusionCells, spec.occlusionCells)) {
        throw StateError('${spec.id} pixel/coarse occlusion cells diverge.');
      }
    }
  }
  final registeredIds = manifest.elements
      .where(
        (element) => element.tilesetId == 'ts_selbrume_lighthouse_exterior',
      )
      .map((element) => element.id)
      .toSet();
  if (registeredIds.length != _task12LighthouseExteriorElementIds.length ||
      !registeredIds.containsAll(_task12LighthouseExteriorElementIds)) {
    throw StateError('Task 12 lighthouse atlas must expose 13 elements.');
  }

  final exterior = MapData.fromJson(maps['map_phare_exterieur']!);
  const expectedLayerIds = <String>[
    'l_terrain',
    'l_path_primary',
    'l_path_secondary',
    'l_tile_ground',
    'l_tile_structures',
    'l_tile_overhead',
    'l_tile_fx',
    'l_collisions',
  ];
  if (exterior.size != const GridSize(width: 45, height: 45) ||
      exterior.tilesetId.isNotEmpty ||
      exterior.mapMetadata.isIndoor ||
      exterior.mapMetadata.mapType != MapType.building ||
      exterior.mapMetadata.weather != MapWeather.fog ||
      exterior.properties['selbrumeGeneratorBoundary'] != 'task12' ||
      exterior.layers.map((layer) => layer.id).join('|') !=
          expectedLayerIds.join('|') ||
      exterior.layers.whereType<TileLayer>().any(
            (layer) => layer.tilesetId != 'ts_selbrume_lighthouse_exterior',
          )) {
    throw StateError('Task 12 lighthouse base/layer contract is invalid.');
  }
  if (exterior.events.isNotEmpty || exterior.entities.isNotEmpty) {
    throw StateError('Task 12 lighthouse must not invent narrative content.');
  }
  final connectionKeys = <String>{
    for (final connection in exterior.connections)
      '${connection.direction.name}:${connection.targetMapId}:'
          '${connection.offset}',
  };
  if (exterior.connections.length != 1 ||
      !connectionKeys.contains('west:map_passage_dames:0')) {
    throw StateError('Task 12 lighthouse connection is not exact.');
  }
  _requirePortZone(exterior, 'zone_lighthouse_entry', 0, 10, 8, 8);
  _requirePortTrigger(
    exterior,
    'zone_lighthouse_entry',
    'event_lighthouse_exterior_arrival',
    0,
    10,
    8,
    8,
  );
  if (exterior.gameplayZones.length != 1 || exterior.triggers.length != 1) {
    throw StateError('Task 12 lighthouse reservation inventory is not exact.');
  }

  const expectedWarps = <MapWarp>[
    MapWarp(
      id: 'warp_phare_ext_to_interieur',
      pos: GridPos(x: 23, y: 18),
      targetMapId: 'map_phare_interieur',
      targetPos: GridPos(x: 18, y: 42),
    ),
    MapWarp(
      id: 'warp_phare_ext_to_cabane',
      pos: GridPos(x: 8, y: 33),
      targetMapId: 'map_cabane_gardien',
      targetPos: GridPos(x: 10, y: 13),
    ),
  ];
  if (exterior.warps.length != expectedWarps.length ||
      !exterior.warps.toSet().containsAll(expectedWarps)) {
    throw StateError('Task 12 lighthouse warps are not exact.');
  }
  final interior = MapData.fromJson(maps['map_phare_interieur']!);
  final cabin = MapData.fromJson(maps['map_cabane_gardien']!);
  if (interior.warps
          .where(
            (warp) =>
                warp.id == 'warp_phare_interieur_to_exterieur' &&
                warp.pos == const GridPos(x: 18, y: 44) &&
                warp.targetMapId == exterior.id &&
                warp.targetPos == const GridPos(x: 23, y: 19),
          )
          .length !=
      1) {
    throw StateError('Task 12 lighthouse interior reciprocity is invalid.');
  }
  if (cabin.warps
          .where(
            (warp) =>
                warp.id == 'warp_cabane_to_phare_exterieur' &&
                warp.pos == const GridPos(x: 10, y: 15) &&
                warp.targetMapId == exterior.id &&
                warp.targetPos == const GridPos(x: 8, y: 34),
          )
          .length !=
      1) {
    throw StateError('Task 12 keeper-cabin reciprocity is invalid.');
  }

  final placedById = <String, MapPlacedElement>{
    for (final placed in exterior.placedElements) placed.id: placed,
  };
  for (final contract in const <(String, String, String, GridPos)>[
    (
      'pe_phare_batiment',
      'el_selbrume_phare_batiment',
      'l_tile_structures',
      GridPos(x: 19, y: 8),
    ),
    (
      'pe_phare_cabane_facade',
      'el_selbrume_cabane_facade',
      'l_tile_structures',
      GridPos(x: 6, y: 28),
    ),
    (
      'pe_phare_porte_ouverte',
      'el_selbrume_phare_porte_ouverte',
      'l_tile_structures',
      GridPos(x: 22, y: 16),
    ),
    (
      'pe_phare_cabane_porte_ouverte',
      'el_selbrume_cabane_porte_ouverte',
      'l_tile_structures',
      GridPos(x: 7, y: 32),
    ),
    (
      'pe_phare_fenetre_sombre',
      'el_selbrume_phare_fenetre_sombre',
      'l_tile_structures',
      GridPos(x: 21, y: 11),
    ),
    (
      'pe_phare_rambarde',
      'el_selbrume_phare_rambarde',
      'l_tile_structures',
      GridPos(x: 29, y: 19),
    ),
    (
      'pe_phare_fondation',
      'el_selbrume_phare_fondation',
      'l_tile_ground',
      GridPos(x: 19, y: 17),
    ),
    (
      'pe_phare_panneau',
      'el_selbrume_phare_panneau',
      'l_tile_structures',
      GridPos(x: 2, y: 18),
    ),
    (
      'pe_phare_debris',
      'el_selbrume_phare_debris',
      'l_tile_structures',
      GridPos(x: 28, y: 27),
    ),
    (
      'pe_phare_marches',
      'el_selbrume_phare_marches',
      'l_tile_ground',
      GridPos(x: 22, y: 18),
    ),
  ]) {
    _requirePortPlacement(
      placedById,
      contract.$1,
      contract.$2,
      contract.$3,
      contract.$4,
    );
  }
  final expectedUsedIds = _task12LighthouseExteriorElementIds
      .where(
        (id) =>
            id != 'el_selbrume_phare_porte_fermee' &&
            id != 'el_selbrume_cabane_porte_fermee' &&
            id != 'el_selbrume_phare_fenetre_lumineuse',
      )
      .toSet();
  final usedIds =
      exterior.placedElements.map((placed) => placed.elementId).toSet();
  if (exterior.placedElements.length != expectedUsedIds.length ||
      usedIds.length != expectedUsedIds.length ||
      !usedIds.containsAll(expectedUsedIds)) {
    throw StateError('Task 12 lighthouse placement inventory is not exact.');
  }
  final specById = <String, _LighthouseExteriorElementSpec>{
    for (final spec in _lighthouseExteriorElementSpecs) spec.id: spec,
  };
  for (final placed in exterior.placedElements) {
    final spec = specById[placed.elementId];
    if (spec == null ||
        placed.applyCollision != spec.collisionCells.isNotEmpty) {
      throw StateError(
        '${placed.id} applyCollision violates its lighthouse spec.',
      );
    }
  }

  final primary = exterior.layers
      .whereType<PathLayer>()
      .singleWhere((layer) => layer.id == 'l_path_primary');
  final secondary = exterior.layers
      .whereType<PathLayer>()
      .singleWhere((layer) => layer.id == 'l_path_secondary');
  if (primary.presetId != 'pavement_path' ||
      secondary.presetId != 'dirth_path') {
    throw StateError('Task 12 lighthouse path presets are invalid.');
  }
  final allowed = <bool>[
    for (var index = 0; index < primary.cells.length; index += 1)
      primary.cells[index] || secondary.cells[index],
  ];
  final staticCollisions =
      exterior.layers.whereType<CollisionLayer>().single.collisions;
  for (var index = 0; index < allowed.length; index += 1) {
    if (primary.cells[index] && secondary.cells[index]) {
      throw StateError('Task 12 lighthouse paths overlap at $index.');
    }
    if (staticCollisions[index] == allowed[index]) {
      throw StateError(
        'Task 12 lighthouse land/collision partition is invalid at $index.',
      );
    }
  }
  final blocked = _portBlockedCells(exterior, elementsById);
  const start = GridPos(x: 0, y: 14);
  final startIndex = start.y * exterior.size.width + start.x;
  final reached = <int>{startIndex};
  final queue = <GridPos>[start];
  var cursor = 0;
  while (cursor < queue.length) {
    final current = queue[cursor++];
    for (final next in <GridPos>[
      GridPos(x: current.x, y: current.y - 1),
      GridPos(x: current.x + 1, y: current.y),
      GridPos(x: current.x, y: current.y + 1),
      GridPos(x: current.x - 1, y: current.y),
    ]) {
      if (next.x < 0 ||
          next.y < 0 ||
          next.x >= exterior.size.width ||
          next.y >= exterior.size.height) {
        continue;
      }
      final index = next.y * exterior.size.width + next.x;
      if (allowed[index] && !blocked[index] && reached.add(index)) {
        queue.add(next);
      }
    }
  }
  for (var y = 12; y <= 16; y += 1) {
    final index = y * exterior.size.width;
    if (!primary.cells[index] || blocked[index] || !reached.contains(index)) {
      throw StateError('Task 12 west approach is blocked at (0,$y).');
    }
  }
  for (final target in const <GridPos>[
    GridPos(x: 23, y: 18),
    GridPos(x: 23, y: 19),
    GridPos(x: 8, y: 33),
    GridPos(x: 8, y: 34),
  ]) {
    final index = target.y * exterior.size.width + target.x;
    if (blocked[index] || !reached.contains(index)) {
      throw StateError('Task 12 lighthouse anchor is unreachable at $target.');
    }
  }
  for (final bypass in const <GridPos>[
    GridPos(x: 22, y: 17),
    GridPos(x: 7, y: 32),
  ]) {
    if (!blocked[bypass.y * exterior.size.width + bypass.x]) {
      throw StateError('Task 12 doorway bypass is passable at $bypass.');
    }
  }
  for (final cliff in const <GridPos>[
    GridPos(x: 40, y: 5),
    GridPos(x: 42, y: 40),
    GridPos(x: 2, y: 42),
  ]) {
    if (!blocked[cliff.y * exterior.size.width + cliff.x]) {
      throw StateError('Task 12 cliff is passable at $cliff.');
    }
  }
  final marker = manifest.groups
      .singleWhere((group) => group.id == 'group_selbrume_bourg')
      .properties['selbrumeGeneratorBoundary'];
  if (marker != 'task12' &&
      marker != 'task13' &&
      marker != 'task14' &&
      marker != 'task15' &&
      marker != 'task16') {
    throw StateError('Task 12 boundary marker is missing from the manifest.');
  }
}

void _validateTask13Output({
  required Map<String, Map<String, dynamic>> maps,
  required ProjectManifest manifest,
}) {
  final folders = manifest.tilesetFolders.where(
    (entry) => entry.id == 'tsf_selbrume_beta_lighthouse',
  );
  final categories = manifest.elementCategories.where(
    (entry) => entry.id == 'cat_selbrume_lighthouse',
  );
  if (folders.length != 1 ||
      folders.single.parentFolderId != 'tsf_selbrume_beta' ||
      categories.length != 1 ||
      categories.single.parentCategoryId != 'batiments') {
    throw StateError('Task 13 lighthouse catalog hierarchy is invalid.');
  }
  final tilesets = manifest.tilesets.where(
    (entry) => entry.id == 'ts_selbrume_lighthouse_interior',
  );
  if (tilesets.length != 1 ||
      tilesets.single.relativePath !=
          'assets/tilesets/selbrume_lighthouse_interior.png' ||
      tilesets.single.folderId != 'tsf_selbrume_beta_lighthouse') {
    throw StateError('Task 13 lighthouse interior tileset is invalid.');
  }

  final elementsById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  for (final spec in _lighthouseInteriorElementSpecs) {
    final element = elementsById[spec.id];
    if (element == null ||
        element.tilesetId != 'ts_selbrume_lighthouse_interior' ||
        element.categoryId != 'cat_selbrume_lighthouse' ||
        element.frames.length != 1 ||
        element.frames.single.source != spec.source ||
        element.frames.single.durationMs != null ||
        element.recommendedLayerId != spec.layerId ||
        !element.tags.toSet().containsAll(<String>{
          'selbrume',
          'lighthouse',
          'interior',
          spec.mapTag,
          'beta',
          'static',
        })) {
      throw StateError('${spec.id} has an invalid Task 13 element contract.');
    }
    if (spec.collisionCells.isEmpty) {
      if (element.collisionProfile != null) {
        throw StateError('${spec.id} must remain passable.');
      }
      continue;
    }
    final profile = element.collisionProfile;
    if (profile == null ||
        profile.source != ElementCollisionProfileSource.manual ||
        !_sameGridPositions(profile.cells, spec.collisionCells) ||
        !_sameGridPositions(profile.shapeCells, spec.collisionCells) ||
        profile.visualMask == null ||
        profile.collisionMask == null ||
        profile.occlusionMask != null) {
      throw StateError('${spec.id} has an invalid Task 13 collision profile.');
    }
    _validatePortMask(
      spec.id,
      'visual',
      profile.visualMask!,
      spec.source,
      requireSolidPixel: true,
    );
    _validatePortMask(
      spec.id,
      'collision',
      profile.collisionMask!,
      spec.source,
      requireSolidPixel: true,
    );
    final derivedCells = ElementCollisionMaskCodec.cellsFromPixelMask(
      mask: profile.collisionMask!,
      tileWidth: 32,
      tileHeight: 32,
      sourceWidthInTiles: spec.source.width,
      sourceHeightInTiles: spec.source.height,
    );
    if (!_sameGridPositions(derivedCells, spec.collisionCells)) {
      throw StateError('${spec.id} pixel/coarse collision cells diverge.');
    }
  }
  final registeredIds = manifest.elements
      .where(
        (element) => element.tilesetId == 'ts_selbrume_lighthouse_interior',
      )
      .map((element) => element.id)
      .toSet();
  if (registeredIds.length != _task13LighthouseInteriorElementIds.length ||
      !registeredIds.containsAll(_task13LighthouseInteriorElementIds)) {
    throw StateError('Task 13 lighthouse atlas must expose 25 elements.');
  }

  final interior = MapData.fromJson(maps['map_phare_interieur']!);
  if (interior.size != const GridSize(width: 36, height: 45) ||
      interior.tilesetId.isNotEmpty ||
      !interior.mapMetadata.isIndoor ||
      interior.mapMetadata.mapType != MapType.interior ||
      interior.properties['selbrumeGeneratorBoundary'] != 'task13') {
    throw StateError('Task 13 lighthouse map contract is invalid.');
  }
  _validateCanonicalInteriorLayerContract(
    interior,
    manifest,
    tilesetId: 'ts_selbrume_lighthouse_interior',
    fxTilesetId: 'ts_selbrume_lighthouse_fx',
  );
  if (interior.connections.isNotEmpty ||
      interior.events.isNotEmpty ||
      interior.entities.isNotEmpty) {
    throw StateError('Task 13 lighthouse must not invent narrative content.');
  }
  if (interior.layers
      .whereType<CollisionLayer>()
      .single
      .collisions
      .contains(true)) {
    throw StateError('Task 13 must not add invisible static collisions.');
  }
  const expectedWarps = <MapWarp>[
    MapWarp(
      id: 'warp_phare_interieur_to_exterieur',
      pos: GridPos(x: 18, y: 44),
      targetMapId: 'map_phare_exterieur',
      targetPos: GridPos(x: 23, y: 19),
    ),
    MapWarp(
      id: 'warp_phare_interieur_to_sommet',
      pos: GridPos(x: 18, y: 1),
      targetMapId: 'map_sommet_phare',
      targetPos: GridPos(x: 12, y: 22),
    ),
  ];
  if (interior.warps.length != expectedWarps.length ||
      !interior.warps.toSet().containsAll(expectedWarps)) {
    throw StateError('Task 13 lighthouse warps are not exact.');
  }
  final exterior = MapData.fromJson(maps['map_phare_exterieur']!);
  final top = MapData.fromJson(maps['map_sommet_phare']!);
  if (exterior.warps
          .where(
            (warp) =>
                warp.id == 'warp_phare_ext_to_interieur' &&
                warp.targetMapId == interior.id &&
                warp.targetPos == const GridPos(x: 18, y: 42),
          )
          .length !=
      1) {
    throw StateError('Task 13 exterior reciprocity is invalid.');
  }
  if (top.warps
          .where(
            (warp) =>
                warp.id == 'warp_sommet_to_phare_interieur' &&
                warp.targetMapId == interior.id &&
                warp.targetPos == const GridPos(x: 18, y: 2),
          )
          .length !=
      1) {
    throw StateError('Task 13 summit reciprocity is invalid.');
  }
  _requirePortZone(interior, 'zone_lighthouse_floor_1', 6, 32, 24, 11);
  _requirePortZone(interior, 'zone_lighthouse_top_access', 14, 0, 8, 4);
  _requirePortTrigger(
    interior,
    'tr_phare_note',
    'event_selbrume_phare_note_ancien_gardien',
    10,
    24,
    2,
    2,
  );
  if (interior.gameplayZones.length != 2 || interior.triggers.length != 1) {
    throw StateError('Task 13 lighthouse reservation inventory is invalid.');
  }

  final placedById = <String, MapPlacedElement>{
    for (final placed in interior.placedElements) placed.id: placed,
  };
  for (final contract in const <(String, String, String, GridPos)>[
    (
      'pe_phare_escalier_haut',
      'el_selbrume_phare_escalier_haut',
      'l_tile_floor',
      GridPos(x: 17, y: 0),
    ),
    (
      'pe_phare_escalier_bas',
      'el_selbrume_phare_escalier_bas',
      'l_tile_floor',
      GridPos(x: 17, y: 42),
    ),
    (
      'pe_phare_note_ancien_gardien',
      'el_selbrume_phare_bureau_note',
      'l_tile_furniture',
      GridPos(x: 10, y: 24),
    ),
    (
      'pe_phare_mecanisme',
      'el_selbrume_phare_mecanisme',
      'l_tile_furniture',
      GridPos(x: 25, y: 23),
    ),
    (
      'pe_phare_trappe',
      'el_selbrume_phare_trappe',
      'l_tile_floor',
      GridPos(x: 28, y: 29),
    ),
  ]) {
    _requirePortPlacement(
      placedById,
      contract.$1,
      contract.$2,
      contract.$3,
      contract.$4,
    );
  }
  final specById = <String, _LighthouseInteriorElementSpec>{
    for (final spec in _lighthouseInteriorElementSpecs) spec.id: spec,
  };
  final expectedUsedIds = _lighthouseInteriorElementSpecs
      .where((spec) => spec.mapTag == 'map_phare_interieur')
      .map((spec) => spec.id)
      .toSet();
  final usedIds =
      interior.placedElements.map((placed) => placed.elementId).toSet();
  if (usedIds.length != expectedUsedIds.length ||
      !usedIds.containsAll(expectedUsedIds)) {
    throw StateError('Task 13 lighthouse placement coverage is invalid.');
  }
  for (final placed in interior.placedElements) {
    final spec = specById[placed.elementId];
    if (spec == null ||
        spec.mapTag != 'map_phare_interieur' ||
        placed.layerId != spec.layerId ||
        placed.applyCollision != spec.collisionCells.isNotEmpty) {
      throw StateError(
        '${placed.id} applyCollision or scope violates its Task 13 spec.',
      );
    }
  }

  final blocked = _portBlockedCells(interior, elementsById);
  const start = GridPos(x: 18, y: 42);
  final startIndex = start.y * interior.size.width + start.x;
  final reached = <int>{startIndex};
  final queue = <GridPos>[start];
  var cursor = 0;
  while (cursor < queue.length) {
    final current = queue[cursor++];
    for (final next in <GridPos>[
      GridPos(x: current.x, y: current.y - 1),
      GridPos(x: current.x + 1, y: current.y),
      GridPos(x: current.x, y: current.y + 1),
      GridPos(x: current.x - 1, y: current.y),
    ]) {
      if (next.x < 0 ||
          next.y < 0 ||
          next.x >= interior.size.width ||
          next.y >= interior.size.height) {
        continue;
      }
      final index = next.y * interior.size.width + next.x;
      if (!blocked[index] && reached.add(index)) queue.add(next);
    }
  }
  final critical = <GridPos>[
    const GridPos(x: 18, y: 44),
    const GridPos(x: 18, y: 42),
    const GridPos(x: 10, y: 24),
    const GridPos(x: 10, y: 26),
    const GridPos(x: 18, y: 2),
    const GridPos(x: 18, y: 1),
    for (var x = 26; x <= 28; x++) GridPos(x: x, y: 28),
    for (var y = 29; y <= 30; y++)
      for (var x = 28; x <= 29; x++) GridPos(x: x, y: y),
    for (final x in const <int>[18, 19]) GridPos(x: x, y: 31),
    for (final x in const <int>[10, 11, 26, 27]) GridPos(x: x, y: 20),
  ];
  for (final pos in critical) {
    final index = pos.y * interior.size.width + pos.x;
    if (blocked[index] || !reached.contains(index)) {
      throw StateError('Task 13 lighthouse route is blocked at $pos.');
    }
  }
  for (final pos in <GridPos>[
    for (var y = 0; y < 3; y++)
      for (var x = 17; x < 20; x++) GridPos(x: x, y: y),
    for (var y = 42; y < 45; y++)
      for (var x = 17; x < 20; x++) GridPos(x: x, y: y),
    for (var y = 29; y < 31; y++)
      for (var x = 28; x < 30; x++) GridPos(x: x, y: y),
  ]) {
    if (blocked[pos.y * interior.size.width + pos.x]) {
      throw StateError('Task 13 stairs/trapdoor are blocked at $pos.');
    }
  }
  for (final wall in const <GridPos>[
    GridPos(x: 0, y: 10),
    GridPos(x: 35, y: 10),
    GridPos(x: 2, y: 31),
    GridPos(x: 14, y: 20),
    GridPos(x: 22, y: 25),
    GridPos(x: 25, y: 23),
    GridPos(x: 27, y: 8),
  ]) {
    if (!blocked[wall.y * interior.size.width + wall.x]) {
      throw StateError('Task 13 wall/obstacle is passable at $wall.');
    }
  }
  final marker = manifest.groups
      .singleWhere((group) => group.id == 'group_selbrume_bourg')
      .properties['selbrumeGeneratorBoundary'];
  if (marker != 'task13' &&
      marker != 'task14' &&
      marker != 'task15' &&
      marker != 'task16') {
    throw StateError('Task 13 boundary marker is missing from the manifest.');
  }
}

void _validateTask14Output({
  required Map<String, Map<String, dynamic>> maps,
  required ProjectManifest manifest,
}) {
  final folders = manifest.tilesetFolders.where(
    (entry) => entry.id == 'tsf_selbrume_beta_fx',
  );
  final categories = manifest.elementCategories.where(
    (entry) => entry.id == 'cat_selbrume_fx',
  );
  if (folders.length != 1 ||
      folders.single.parentFolderId != 'tsf_selbrume_beta' ||
      categories.length != 1 ||
      categories.single.parentCategoryId != 'environnement') {
    throw StateError('Task 14 FX catalog hierarchy is invalid.');
  }
  final tilesets = manifest.tilesets.where(
    (entry) => entry.id == 'ts_selbrume_lighthouse_fx',
  );
  if (tilesets.length != 1 ||
      tilesets.single.relativePath !=
          'assets/tilesets/selbrume_lighthouse_fx.png' ||
      tilesets.single.folderId != 'tsf_selbrume_beta_fx') {
    throw StateError('Task 14 lighthouse FX tileset is invalid.');
  }

  final elementsById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  for (final spec in _lighthouseFxElementSpecs) {
    final element = elementsById[spec.id];
    if (element == null ||
        element.tilesetId != 'ts_selbrume_lighthouse_fx' ||
        element.categoryId != 'cat_selbrume_fx' ||
        element.frames.length != spec.frames.length ||
        element.recommendedLayerId != 'l_tile_fx' ||
        element.collisionProfile != null ||
        !element.tags.toSet().containsAll(<String>{
          'selbrume',
          'environment',
          'lighthouse',
          'fx',
          'map_passage_dames',
          'map_phare_exterieur',
          'map_phare_interieur',
          'map_sommet_phare',
          'beta',
        })) {
      throw StateError('${spec.id} has an invalid Task 14 element contract.');
    }
    for (var frameIndex = 0; frameIndex < spec.frames.length; frameIndex++) {
      if (element.frames[frameIndex] != spec.frames[frameIndex]) {
        throw StateError(
          '${spec.id} frame ${frameIndex + 1} has an invalid Task 14 '
          'source or duration.',
        );
      }
      final source = element.frames[frameIndex].source;
      final firstSource = element.frames.first.source;
      if (source.width != firstSource.width ||
          source.height != firstSource.height) {
        throw StateError('${spec.id} animation footprint is not stable.');
      }
    }
    if (spec.stateVariant != element.tags.contains('state_variant') ||
        spec.animated != element.tags.contains('animated') ||
        (!spec.stateVariant && !spec.animated) !=
            element.tags.contains('static')) {
      throw StateError('${spec.id} Task 14 tags are invalid.');
    }
  }
  final registeredIds = manifest.elements
      .where((element) => element.tilesetId == 'ts_selbrume_lighthouse_fx')
      .map((element) => element.id)
      .toSet();
  if (registeredIds.length != _task14LighthouseFxElementIds.length ||
      !registeredIds.containsAll(_task14LighthouseFxElementIds)) {
    throw StateError('Task 14 FX atlas must expose nine logical elements.');
  }

  final top = MapData.fromJson(maps['map_sommet_phare']!);
  if (top.size != const GridSize(width: 24, height: 24) ||
      top.tilesetId.isNotEmpty ||
      !top.mapMetadata.isIndoor ||
      top.mapMetadata.mapType != MapType.interior ||
      top.properties['selbrumeGeneratorBoundary'] != 'task14') {
    throw StateError('Task 14 summit map contract is invalid.');
  }
  _validateCanonicalInteriorLayerContract(
    top,
    manifest,
    tilesetId: 'ts_selbrume_lighthouse_interior',
    fxTilesetId: 'ts_selbrume_lighthouse_fx',
  );
  if (top.connections.isNotEmpty ||
      top.events.isNotEmpty ||
      top.entities.isNotEmpty) {
    throw StateError('Task 14 summit must not invent narrative content.');
  }
  if (top.layers.whereType<CollisionLayer>().single.collisions.contains(true)) {
    throw StateError('Task 14 must not add invisible static collisions.');
  }
  const expectedWarp = MapWarp(
    id: 'warp_sommet_to_phare_interieur',
    pos: GridPos(x: 12, y: 23),
    targetMapId: 'map_phare_interieur',
    targetPos: GridPos(x: 18, y: 2),
  );
  if (top.warps.length != 1 || top.warps.single != expectedWarp) {
    throw StateError('Task 14 summit warp is not exact.');
  }
  final interior = MapData.fromJson(maps['map_phare_interieur']!);
  if (interior.warps
          .where(
            (warp) =>
                warp.id == 'warp_phare_interieur_to_sommet' &&
                warp.targetMapId == top.id &&
                warp.targetPos == const GridPos(x: 12, y: 22),
          )
          .length !=
      1) {
    throw StateError('Task 14 summit reciprocity is invalid.');
  }
  _requirePortZone(top, 'zone_lighthouse_top', 7, 5, 10, 10);
  _requirePortTrigger(
    top,
    'tr_sommet_confrontation',
    'event_selbrume_sommet_confrontation',
    12,
    10,
    1,
    1,
  );
  _requirePortTrigger(
    top,
    'tr_lighthouse_top',
    'event_final_pokemon_scene',
    7,
    5,
    10,
    10,
  );
  if (top.gameplayZones.length != 1 || top.triggers.length != 2) {
    throw StateError('Task 14 summit reservation inventory is invalid.');
  }

  final placedById = <String, MapPlacedElement>{
    for (final placed in top.placedElements) placed.id: placed,
  };
  void requirePlacement(
    String id,
    String elementId,
    String layerId,
    GridPos pos,
    bool applyCollision,
  ) {
    _requirePortPlacement(placedById, id, elementId, layerId, pos);
    if (placedById[id]!.applyCollision != applyCollision) {
      throw StateError('$id has invalid Task 14 collision application.');
    }
  }

  requirePlacement(
    'pe_sommet_plateforme',
    'el_selbrume_sommet_plateforme',
    'l_tile_floor',
    const GridPos(x: 9, y: 7),
    false,
  );
  requirePlacement(
    'pe_sommet_lanterne',
    'el_selbrume_sommet_lanterne',
    'l_tile_furniture',
    const GridPos(x: 10, y: 0),
    true,
  );
  requirePlacement(
    'pe_sommet_trappe',
    'el_selbrume_phare_trappe',
    'l_tile_floor',
    const GridPos(x: 11, y: 22),
    false,
  );
  requirePlacement(
    'pe_sommet_mecanisme',
    'el_selbrume_phare_mecanisme',
    'l_tile_furniture',
    const GridPos(x: 17, y: 15),
    true,
  );
  requirePlacement(
    'pe_sommet_lumiere_eteinte',
    'el_selbrume_fx_lumiere_eteinte',
    'l_tile_fx',
    const GridPos(x: 10, y: 0),
    false,
  );

  final horizontalParapets = top.placedElements.where(
    (placed) => placed.elementId == 'el_selbrume_sommet_parapet_h',
  );
  final verticalParapets = top.placedElements.where(
    (placed) => placed.elementId == 'el_selbrume_sommet_parapet_v',
  );
  final expectedHorizontalPositions = <GridPos>{
    for (final y in const <int>[0, 22])
      for (final x in const <int>[0, 4, 16, 20]) GridPos(x: x, y: y),
  };
  final expectedVerticalPositions = <GridPos>{
    for (final x in const <int>[0, 22])
      for (final y in const <int>[2, 6, 10, 14, 18]) GridPos(x: x, y: y),
  };
  if (horizontalParapets.length != expectedHorizontalPositions.length ||
      horizontalParapets.any(
        (placed) =>
            placed.layerId != 'l_tile_walls' ||
            !placed.applyCollision ||
            !expectedHorizontalPositions.contains(placed.pos),
      ) ||
      verticalParapets.length != expectedVerticalPositions.length ||
      verticalParapets.any(
        (placed) =>
            placed.layerId != 'l_tile_walls' ||
            !placed.applyCollision ||
            !expectedVerticalPositions.contains(placed.pos),
      )) {
    throw StateError('Task 14 summit parapet layout is invalid.');
  }
  if (top.placedElements.length != 23) {
    throw StateError('Task 14 summit placement inventory is invalid.');
  }
  final placedFx = top.placedElements.where(
    (placed) => placed.elementId.startsWith('el_selbrume_fx_'),
  );
  if (placedFx.length != 1 ||
      placedFx.single.elementId != 'el_selbrume_fx_lumiere_eteinte' ||
      placedFx.single.layerId != 'l_tile_fx' ||
      placedFx.single.applyCollision) {
    throw StateError('Task 14 initial FX state must be off and passable.');
  }
  for (final placed in top.placedElements) {
    final element = elementsById[placed.elementId];
    if (element == null) {
      throw StateError('${placed.id} references an unknown Task 14 element.');
    }
    final source = element.frames.first.source;
    if (placed.pos.x < 0 ||
        placed.pos.y < 0 ||
        placed.pos.x + source.width > top.size.width ||
        placed.pos.y + source.height > top.size.height) {
      throw StateError('${placed.id} exceeds the Task 14 summit bounds.');
    }
  }

  final blocked = _portBlockedCells(top, elementsById);
  for (var y = 5; y < 15; y++) {
    for (var x = 7; x < 17; x++) {
      if (blocked[y * top.size.width + x]) {
        throw StateError('Task 14 confrontation area is blocked at ($x,$y).');
      }
    }
  }
  const start = GridPos(x: 12, y: 22);
  final reached = <int>{start.y * top.size.width + start.x};
  final queue = <GridPos>[start];
  var cursor = 0;
  while (cursor < queue.length) {
    final current = queue[cursor++];
    for (final next in <GridPos>[
      GridPos(x: current.x, y: current.y - 1),
      GridPos(x: current.x + 1, y: current.y),
      GridPos(x: current.x, y: current.y + 1),
      GridPos(x: current.x - 1, y: current.y),
    ]) {
      if (next.x < 0 ||
          next.y < 0 ||
          next.x >= top.size.width ||
          next.y >= top.size.height) {
        continue;
      }
      final index = next.y * top.size.width + next.x;
      if (!blocked[index] && reached.add(index)) queue.add(next);
    }
  }
  for (final pos in const <GridPos>[
    GridPos(x: 12, y: 22),
    GridPos(x: 12, y: 23),
    GridPos(x: 12, y: 10),
  ]) {
    final index = pos.y * top.size.width + pos.x;
    if (blocked[index] || !reached.contains(index)) {
      throw StateError('Task 14 summit route is blocked at $pos.');
    }
  }
  for (final placed in <MapPlacedElement>[
    ...horizontalParapets,
    ...verticalParapets,
  ]) {
    final cells = elementsById[placed.elementId]!.collisionProfile!.cells;
    for (final cell in cells) {
      final x = placed.pos.x + cell.x;
      final y = placed.pos.y + cell.y;
      if (!blocked[y * top.size.width + x]) {
        throw StateError('${placed.id} parapet is passable at ($x,$y).');
      }
    }
  }
  final marker = manifest.groups
      .singleWhere((group) => group.id == 'group_selbrume_bourg')
      .properties['selbrumeGeneratorBoundary'];
  if (marker != 'task14' && marker != 'task15' && marker != 'task16') {
    throw StateError('Task 14 boundary marker is missing from the manifest.');
  }
}

void _validateTask15Output({
  required Map<String, Map<String, dynamic>> maps,
  required ProjectManifest manifest,
}) {
  final cabin = MapData.fromJson(maps['map_cabane_gardien']!);
  if (cabin.size != const GridSize(width: 20, height: 16) ||
      cabin.tilesetId.isNotEmpty ||
      !cabin.mapMetadata.isIndoor ||
      cabin.mapMetadata.mapType != MapType.interior ||
      cabin.properties['selbrumeGeneratorBoundary'] != 'task15') {
    throw StateError('Task 15 keeper-cabin map contract is invalid.');
  }
  _validateCanonicalInteriorLayerContract(
    cabin,
    manifest,
    tilesetId: 'ts_selbrume_cabin_interior',
    fxTilesetId: 'ts_selbrume_cabin_interior',
  );
  final staticCollisions =
      cabin.layers.whereType<CollisionLayer>().single.collisions;
  if (staticCollisions.length != 20 * 16 || staticCollisions.contains(true)) {
    throw StateError('Task 15 must not add invisible static collisions.');
  }
  if (cabin.connections.isNotEmpty ||
      cabin.entities.isNotEmpty ||
      cabin.events.isNotEmpty ||
      cabin.gameplayZones.isNotEmpty) {
    throw StateError('Task 15 keeper cabin must not invent narrative content.');
  }

  const expectedWarps = <MapWarp>[
    MapWarp(
      id: 'warp_cabane_to_phare_exterieur',
      pos: GridPos(x: 10, y: 15),
      targetMapId: 'map_phare_exterieur',
      targetPos: GridPos(x: 8, y: 34),
    ),
    MapWarp(
      id: 'warp_cabane_to_passage',
      pos: GridPos(x: 19, y: 8),
      targetMapId: 'map_passage_dames',
      targetPos: GridPos(x: 50, y: 10),
    ),
  ];
  if (cabin.warps.length != expectedWarps.length) {
    throw StateError('Task 15 keeper-cabin warp inventory is invalid.');
  }
  for (var index = 0; index < expectedWarps.length; index++) {
    if (cabin.warps[index] != expectedWarps[index]) {
      throw StateError('Task 15 keeper-cabin warps are not exact.');
    }
  }
  _requirePortTrigger(
    cabin,
    'tr_cabane_journal',
    'event_selbrume_cabane_journal',
    6,
    5,
    2,
    2,
  );
  _requirePortTrigger(
    cabin,
    'tr_cabane_cle',
    'event_selbrume_cabane_cle',
    14,
    9,
    1,
    1,
  );
  if (cabin.triggers.length != 2) {
    throw StateError('Task 15 keeper-cabin reservation inventory is invalid.');
  }

  final elementsById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  final placedById = <String, MapPlacedElement>{
    for (final placed in cabin.placedElements) placed.id: placed,
  };
  if (cabin.placedElements.length != 50 ||
      placedById.length != cabin.placedElements.length) {
    throw StateError('Task 15 keeper-cabin placement inventory is invalid.');
  }

  void requirePlacement(
    String id,
    String elementId,
    GridPos pos, {
    required bool applyCollision,
    double opacity = 1,
  }) {
    final placed = placedById[id];
    if (placed == null ||
        placed.elementId != elementId ||
        placed.layerId != elementsById[elementId]?.recommendedLayerId ||
        placed.pos != pos ||
        placed.applyCollision != applyCollision ||
        placed.opacity != opacity ||
        placed.behaviors.isNotEmpty ||
        placed.properties.isNotEmpty) {
      throw StateError('$id violates the Task 15 cabin placement contract.');
    }
  }

  for (final y in const <int>[0, 4, 8, 12]) {
    for (final x in const <int>[0, 4, 8, 12, 16]) {
      requirePlacement(
        'pe_cabane_sol_${x}_$y',
        'el_selbrume_cabane_sol_bois',
        GridPos(x: x, y: y),
        applyCollision: false,
      );
    }
  }
  for (final x in const <int>[0, 4, 8, 12, 16]) {
    requirePlacement(
      'pe_cabane_mur_n_$x',
      'el_selbrume_cabane_mur_n',
      GridPos(x: x, y: 0),
      applyCollision: true,
    );
  }
  for (final y in const <int>[2, 6, 10, 12]) {
    requirePlacement(
      'pe_cabane_mur_o_$y',
      'el_selbrume_cabane_mur_cote',
      GridPos(x: 0, y: y),
      applyCollision: true,
    );
  }
  for (final y in const <int>[2, 9, 12]) {
    requirePlacement(
      'pe_cabane_mur_e_$y',
      'el_selbrume_cabane_mur_cote',
      GridPos(x: 18, y: y),
      applyCollision: true,
    );
  }
  for (final x in const <int>[2, 5, 11, 14]) {
    requirePlacement(
      'pe_cabane_mur_s_$x',
      'el_selbrume_cabane_mur_n',
      GridPos(x: x, y: 14),
      applyCollision: true,
    );
  }
  for (final contract in const <(
    String,
    String,
    GridPos,
    bool,
    double,
  )>[
    (
      'pe_cabane_lit',
      'el_selbrume_cabane_lit',
      GridPos(x: 2, y: 3),
      true,
      1,
    ),
    (
      'pe_cabane_table',
      'el_selbrume_cabane_table_carnet_ferme',
      GridPos(x: 6, y: 5),
      true,
      1,
    ),
    (
      'pe_cabane_journal',
      'el_selbrume_cabane_table_carnet_ouvert',
      GridPos(x: 6, y: 5),
      false,
      0,
    ),
    (
      'pe_cabane_poele',
      'el_selbrume_cabane_poele',
      GridPos(x: 10, y: 2),
      true,
      1,
    ),
    (
      'pe_cabane_etagere',
      'el_selbrume_cabane_etagere',
      GridPos(x: 16, y: 2),
      true,
      1,
    ),
    (
      'pe_cabane_coffre',
      'el_selbrume_cabane_coffre',
      GridPos(x: 2, y: 9),
      true,
      1,
    ),
    (
      'pe_cabane_carte',
      'el_selbrume_cabane_carte',
      GridPos(x: 7, y: 1),
      false,
      1,
    ),
    (
      'pe_cabane_cle',
      'el_selbrume_cabane_cle',
      GridPos(x: 14, y: 9),
      false,
      1,
    ),
    (
      'pe_cabane_outils',
      'el_selbrume_cabane_outils',
      GridPos(x: 12, y: 2),
      false,
      1,
    ),
    (
      'pe_cabane_lanterne',
      'el_selbrume_cabane_lanterne',
      GridPos(x: 10, y: 5),
      false,
      1,
    ),
    (
      'pe_cabane_chaise_o',
      'el_selbrume_cabane_chaise',
      GridPos(x: 5, y: 6),
      true,
      1,
    ),
    (
      'pe_cabane_chaise_e',
      'el_selbrume_cabane_chaise',
      GridPos(x: 8, y: 6),
      true,
      1,
    ),
    (
      'pe_cabane_porte_principale',
      'el_selbrume_cabane_porte_principale',
      GridPos(x: 9, y: 13),
      false,
      1,
    ),
    (
      'pe_cabane_porte_secondaire',
      'el_selbrume_cabane_porte_secondaire_fermee',
      GridPos(x: 18, y: 6),
      false,
      1,
    ),
  ]) {
    requirePlacement(
      contract.$1,
      contract.$2,
      contract.$3,
      applyCollision: contract.$4,
      opacity: contract.$5,
    );
  }
  if (cabin.placedElements.any(
    (placed) =>
        placed.elementId == 'el_selbrume_cabane_porte_secondaire_ouverte' ||
        placed.elementId.startsWith('el_selbrume_maison_'),
  )) {
    throw StateError('Task 15 renders an alternative or house-only state.');
  }
  for (final placed in cabin.placedElements) {
    final element = elementsById[placed.elementId];
    if (element == null || element.tilesetId != 'ts_selbrume_cabin_interior') {
      throw StateError('${placed.id} references a non-cabin Task 15 element.');
    }
    final source = element.frames.first.source;
    if (placed.pos.x < 0 ||
        placed.pos.y < 0 ||
        placed.pos.x + source.width > cabin.size.width ||
        placed.pos.y + source.height > cabin.size.height) {
      throw StateError('${placed.id} exceeds the Task 15 cabin bounds.');
    }
  }

  final blocked = _portBlockedCells(cabin, elementsById);
  const start = GridPos(x: 10, y: 13);
  final reached = <int>{start.y * cabin.size.width + start.x};
  final queue = <GridPos>[start];
  var cursor = 0;
  while (cursor < queue.length) {
    final current = queue[cursor++];
    for (final next in <GridPos>[
      GridPos(x: current.x, y: current.y - 1),
      GridPos(x: current.x + 1, y: current.y),
      GridPos(x: current.x, y: current.y + 1),
      GridPos(x: current.x - 1, y: current.y),
    ]) {
      if (next.x < 0 ||
          next.y < 0 ||
          next.x >= cabin.size.width ||
          next.y >= cabin.size.height) {
        continue;
      }
      final index = next.y * cabin.size.width + next.x;
      if (!blocked[index] && reached.add(index)) queue.add(next);
    }
  }
  for (final pos in const <GridPos>[
    GridPos(x: 10, y: 13),
    GridPos(x: 10, y: 15),
    GridPos(x: 19, y: 8),
    GridPos(x: 6, y: 5),
    GridPos(x: 7, y: 5),
    GridPos(x: 14, y: 9),
  ]) {
    final index = pos.y * cabin.size.width + pos.x;
    if (blocked[index] || !reached.contains(index)) {
      throw StateError('Task 15 keeper-cabin route is blocked at $pos.');
    }
  }
  for (final pos in const <GridPos>[
    GridPos(x: 0, y: 0),
    GridPos(x: 19, y: 5),
    GridPos(x: 2, y: 3),
    GridPos(x: 6, y: 6),
    GridPos(x: 10, y: 4),
    GridPos(x: 16, y: 2),
    GridPos(x: 2, y: 10),
    GridPos(x: 5, y: 7),
    GridPos(x: 8, y: 7),
  ]) {
    if (!blocked[pos.y * cabin.size.width + pos.x]) {
      throw StateError('Task 15 solid furniture is passable at $pos.');
    }
  }

  final exterior = MapData.fromJson(maps['map_phare_exterieur']!);
  final passage = MapData.fromJson(maps['map_passage_dames']!);
  final exteriorBlocked = _portBlockedCells(exterior, elementsById);
  final passageBlocked = _portBlockedCells(passage, elementsById);
  if (exteriorBlocked[34 * exterior.size.width + 8] ||
      passageBlocked[10 * passage.size.width + 50]) {
    throw StateError('Task 15 keeper-cabin warp target is blocked.');
  }
  final exteriorReturn = exterior.warps.where(
    (warp) =>
        warp.id == 'warp_phare_ext_to_cabane' &&
        warp.targetMapId == cabin.id &&
        warp.targetPos == const GridPos(x: 10, y: 13),
  );
  if (exteriorReturn.length != 1) {
    throw StateError('Task 15 exterior/cabin reciprocity is invalid.');
  }

  final marker = manifest.groups
      .singleWhere((group) => group.id == 'group_selbrume_bourg')
      .properties['selbrumeGeneratorBoundary'];
  if (marker != 'task15' && marker != 'task16') {
    throw StateError('Task 15 boundary marker is missing from the manifest.');
  }
}

void _validateTask16Output({
  required Map<String, Map<String, dynamic>> maps,
  required ProjectManifest manifest,
}) {
  final mapIds = manifest.maps.map((entry) => entry.id).toList(growable: false);
  if (!_sameStrings(mapIds, canonicalSelbrumeMapIds)) {
    throw StateError(
      'Task 16 active map catalog must contain exactly the ten canonical maps.',
    );
  }
  final groupIds =
      manifest.groups.map((group) => group.id).toList(growable: false);
  if (!_sameStrings(groupIds, canonicalSelbrumeGroupIds)) {
    throw StateError(
      'Task 16 active group catalog must contain exactly the six canonical groups.',
    );
  }
  final knownMapIds = mapIds.toSet();
  for (final scenario in manifest.scenarios) {
    for (final node in scenario.nodes) {
      final mapId = node.binding.mapId;
      if (mapId != null && mapId.isNotEmpty && !knownMapIds.contains(mapId)) {
        throw StateError(
          'Task 16 scenario ${scenario.id}/${node.id} references retired map $mapId.',
        );
      }
    }
  }
  for (final cinematic in manifest.cinematics) {
    final mapId = cinematic.mapId;
    if (mapId != null && mapId.isNotEmpty && !knownMapIds.contains(mapId)) {
      throw StateError(
        'Task 16 cinematic ${cinematic.id} references retired map $mapId.',
      );
    }
  }
  for (final mapId in canonicalSelbrumeMapIds) {
    final map = MapData.fromJson(maps[mapId]!);
    for (final targetMapId in <String>[
      ...map.connections.map((connection) => connection.targetMapId),
      ...map.warps.map((warp) => warp.targetMapId),
    ]) {
      if (!knownMapIds.contains(targetMapId)) {
        throw StateError(
          'Task 16 canonical map $mapId references retired map $targetMapId.',
        );
      }
    }
  }
  final marker = manifest.groups
      .singleWhere((group) => group.id == 'group_selbrume_bourg')
      .properties['selbrumeGeneratorBoundary'];
  if (marker != 'task16') {
    throw StateError('Task 16 boundary marker is missing from the manifest.');
  }
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _sameGridPositions(List<GridPos> left, List<GridPos> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

void _validatePortMask(
  String elementId,
  String label,
  ElementCollisionPixelMask mask,
  TilesetSourceRect source, {
  required bool requireSolidPixel,
}) {
  final widthPx = source.width * 32;
  final heightPx = source.height * 32;
  if (mask.widthPx != widthPx || mask.heightPx != heightPx) {
    throw StateError('$elementId $label mask has invalid dimensions.');
  }
  final bits = ElementCollisionMaskCodec.decodePackedBits(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: mask.dataBase64,
  );
  if (requireSolidPixel && !bits.contains(true)) {
    throw StateError('$elementId $label mask is empty.');
  }
}

void _requirePortZone(
  MapData map,
  String id,
  int x,
  int y,
  int width,
  int height,
) {
  final matches = map.gameplayZones.where((zone) => zone.id == id);
  final expectedArea = MapRect(
    pos: GridPos(x: x, y: y),
    size: GridSize(width: width, height: height),
  );
  if (matches.length != 1 ||
      matches.single.kind != GameplayZoneKind.special ||
      matches.single.area != expectedArea ||
      matches.single.special?.scriptKey != null ||
      matches.single.special?.properties['contractRole'] !=
          'navigation_anchor' ||
      matches.single.special?.properties['inert'] != 'true') {
    throw StateError('$id special-zone contract is invalid.');
  }
}

void _requirePortTrigger(
  MapData map,
  String id,
  String eventId,
  int x,
  int y,
  int width,
  int height,
) {
  final matches = map.triggers.where((trigger) => trigger.id == id);
  final expectedArea = MapRect(
    pos: GridPos(x: x, y: y),
    size: GridSize(width: width, height: height),
  );
  if (matches.length != 1 ||
      matches.single.type != TriggerType.custom ||
      matches.single.area != expectedArea ||
      matches.single.properties['eventId'] != eventId ||
      matches.single.properties['reservedForNarrative'] != 'true') {
    throw StateError('$id reserved-trigger contract is invalid.');
  }
}

MapPlacedElement _requirePortPlacement(
  Map<String, MapPlacedElement> placedById,
  String id,
  String elementId,
  String layerId,
  GridPos pos,
) {
  final placed = placedById[id];
  if (placed == null ||
      placed.elementId != elementId ||
      placed.layerId != layerId ||
      placed.pos != pos) {
    throw StateError('$id placement contract is invalid.');
  }
  return placed;
}

List<bool> _portBlockedCells(
  MapData port,
  Map<String, ProjectElementEntry> elementsById,
) {
  final blocked = List<bool>.from(
    port.layers.whereType<CollisionLayer>().single.collisions,
  );
  for (final placed in port.placedElements) {
    if (!placed.applyCollision) continue;
    final cells = elementsById[placed.elementId]?.collisionProfile?.cells;
    if (cells == null) continue;
    for (final cell in cells) {
      final x = placed.pos.x + cell.x;
      final y = placed.pos.y + cell.y;
      if (x >= 0 && y >= 0 && x < port.size.width && y < port.size.height) {
        blocked[y * port.size.width + x] = true;
      }
    }
  }
  for (final entity in port.entities) {
    if (!entity.blocksMovement) continue;
    for (var y = entity.pos.y; y < entity.pos.y + entity.size.height; y += 1) {
      for (var x = entity.pos.x; x < entity.pos.x + entity.size.width; x += 1) {
        blocked[y * port.size.width + x] = true;
      }
    }
  }
  return blocked;
}

void _validatePortAnchorConnectivity(
  MapData port,
  Map<String, ProjectElementEntry> elementsById,
) {
  final blocked = _portBlockedCells(port, elementsById);
  const start = GridPos(x: 28, y: 0);
  if (blocked[start.y * 45 + start.x]) {
    throw StateError('Port connection start is blocked.');
  }
  final seen = <int>{start.y * port.size.width + start.x};
  final queue = <GridPos>[start];
  var cursor = 0;
  while (cursor < queue.length) {
    final current = queue[cursor++];
    for (final next in <GridPos>[
      GridPos(x: current.x, y: current.y - 1),
      GridPos(x: current.x + 1, y: current.y),
      GridPos(x: current.x, y: current.y + 1),
      GridPos(x: current.x - 1, y: current.y),
    ]) {
      if (next.x < 0 ||
          next.y < 0 ||
          next.x >= port.size.width ||
          next.y >= port.size.height) {
        continue;
      }
      final index = next.y * port.size.width + next.x;
      if (!blocked[index] && seen.add(index)) queue.add(next);
    }
  }
  for (final target in const <GridPos>[
    GridPos(x: 22, y: 21),
    GridPos(x: 34, y: 8),
    GridPos(x: 8, y: 18),
    GridPos(x: 6, y: 5),
    GridPos(x: 26, y: 39),
    GridPos(x: 37, y: 17),
  ]) {
    if (!seen.contains(target.y * port.size.width + target.x)) {
      throw StateError('Port anchor $target is disconnected from Bourg.');
    }
  }
}

bool _isStaticallyBlocked(MapData map, GridPos position) {
  final index = position.y * map.size.width + position.x;
  return map.layers
      .whereType<CollisionLayer>()
      .any((layer) => layer.collisions[index]);
}

const Map<String, String> _task16LegacyMapIdMigrations = <String, String>{
  'Selbrume': 'map_bourg_selbrume',
  'route 1': 'map_marais_salants',
};

const Map<String, String> _task16LegacyGroupIdMigrations = <String, String>{
  'group_1777757343053': 'group_selbrume_bourg',
  'group_1778244410364': 'group_selbrume_marais',
  'group_1779716203042': 'group_selbrume_interiors',
};

List<Map<String, dynamic>> _migrateTask16MapBindings(
  List<Map<String, dynamic>> entries, {
  required String context,
}) =>
    <Map<String, dynamic>>[
      for (var index = 0; index < entries.length; index += 1)
        (_migrateTask16MapBindingValue(
          entries[index],
          context: '$context[$index]',
        ) as Map)
            .cast<String, dynamic>(),
    ];

List<Map<String, dynamic>> _migrateTask16GroupBindings(
  List<Map<String, dynamic>> entries, {
  required String context,
}) =>
    <Map<String, dynamic>>[
      for (var index = 0; index < entries.length; index += 1)
        <String, dynamic>{
          for (final entry in entries[index].entries)
            entry.key: entry.key == 'groupId' && entry.value is String
                ? _task16LegacyGroupIdMigrations[entry.value] ?? entry.value
                : entry.value,
        },
    ];

Object? _migrateTask16MapBindingValue(
  Object? value, {
  required String context,
}) {
  if (value is List) {
    return <Object?>[
      for (var index = 0; index < value.length; index += 1)
        _migrateTask16MapBindingValue(
          value[index],
          context: '$context[$index]',
        ),
    ];
  }
  if (value is! Map) return value;
  final result = <String, dynamic>{};
  for (final rawEntry in value.entries) {
    final key = rawEntry.key;
    if (key is! String) {
      throw FormatException('$context contains a non-string object key.');
    }
    final childContext = '$context.$key';
    final child = rawEntry.value;
    if (key == 'mapId' && child is String) {
      final migrated = _task16LegacyMapIdMigrations[child];
      if (migrated != null) {
        result[key] = migrated;
        continue;
      }
    }
    result[key] = _migrateTask16MapBindingValue(
      child,
      context: childContext,
    );
  }
  return result;
}

List<Map<String, dynamic>> _upsertObjectsById(
  List<Map<String, dynamic>> existing,
  List<Map<String, dynamic>> desired, {
  required String context,
}) {
  final desiredById = <String, Map<String, dynamic>>{
    for (final item in desired) _requiredId(item, context): item,
  };
  if (desiredById.length != desired.length) {
    throw StateError('Duplicate desired IDs in $context.');
  }
  final seenExisting = <String>{};
  final result = <Map<String, dynamic>>[];
  for (final item in existing) {
    final id = _requiredId(item, context);
    if (!seenExisting.add(id)) {
      throw StateError('Duplicate existing ID "$id" in $context.');
    }
    result.add(desiredById[id] ?? item);
  }
  for (final item in desired) {
    final id = _requiredId(item, context);
    if (!seenExisting.contains(id)) result.add(item);
  }
  return result;
}

List<Map<String, dynamic>> _replaceNouveauCheminPatterns(
  List<Map<String, dynamic>> existing,
  Map<String, dynamic> desired,
) {
  const desiredId = 'pp_selbrume_open_sea_loop';
  final result = <Map<String, dynamic>>[];
  final retainedIds = <String>{};
  var inserted = false;
  for (final item in existing) {
    final id = _requiredId(item, 'project pathPatternPresets');
    final affected =
        id == desiredId || item['basePathPresetId'] == 'nouveau-chemin';
    if (affected) {
      if (!inserted) {
        result.add(desired);
        inserted = true;
      }
      continue;
    }
    if (!retainedIds.add(id)) {
      throw StateError(
        'Duplicate existing ID "$id" in project pathPatternPresets.',
      );
    }
    result.add(item);
  }
  if (!inserted) result.add(desired);
  return result;
}

String _requiredId(Map<String, dynamic> value, String context) {
  final id = value['id'];
  if (id is! String || id.trim().isEmpty) {
    throw StateError('$context contains an object without a non-empty id.');
  }
  return id;
}

List<Map<String, dynamic>> _jsonObjectList(
  Object? value, {
  required String context,
}) {
  if (value is! List) throw FormatException('$context must be an array.');
  return <Map<String, dynamic>>[
    for (final item in value)
      if (item is Map)
        item.cast<String, dynamic>()
      else
        throw FormatException('$context contains a non-object value.'),
  ];
}

void _rejectBoundaryDowngrade(
  Map<String, dynamic> projectJson, {
  required Directory mapsDirectory,
  required String requested,
}) {
  final tilesetIds = _optionalObjectIds(projectJson['tilesets']);
  final elementIds = _optionalObjectIds(projectJson['elements']);
  final folderIds = _optionalObjectIds(projectJson['tilesetFolders']);
  final categoryIds = _optionalObjectIds(projectJson['elementCategories']);
  final patternIds = _optionalObjectIds(projectJson['pathPatternPresets']);
  var materialized = 'task4';
  if (tilesetIds.contains('ts_selbrume_boat') ||
      tilesetIds.contains('ts_selbrume_open_sea_loop') ||
      elementIds.contains('el_selbrume_port_bateau') ||
      patternIds.contains('pp_selbrume_open_sea_loop')) {
    materialized = _laterBoundary(materialized, 'task5');
  }
  if (tilesetIds.contains('ts_selbrume_port_props') ||
      elementIds.any(
        (id) =>
            id.startsWith('el_selbrume_port_') &&
            id != 'el_selbrume_port_bateau',
      ) ||
      folderIds.contains('tsf_selbrume_beta_port') ||
      categoryIds.contains('cat_selbrume_port_props')) {
    materialized = _laterBoundary(materialized, 'task6');
  }
  final groups = _jsonObjectList(projectJson['groups'], context: 'groups');
  final bourgGroups = groups.where(
    (group) => group['id'] == 'group_selbrume_bourg',
  );
  if (bourgGroups.length > 1) {
    throw StateError('Duplicate group_selbrume_bourg boundary markers.');
  }
  if (bourgGroups.length == 1) {
    final properties = bourgGroups.single['properties'];
    if (properties is Map) {
      final marker = properties['selbrumeGeneratorBoundary'];
      if (marker is String && marker.isNotEmpty) {
        if (marker != 'task7' &&
            marker != 'task8' &&
            marker != 'task9' &&
            marker != 'task10' &&
            marker != 'task11' &&
            marker != 'task12' &&
            marker != 'task13' &&
            marker != 'task14' &&
            marker != 'task15' &&
            marker != 'task16') {
          throw StateError('Invalid Selbrume generator boundary: $marker.');
        }
        materialized = _laterBoundary(materialized, marker);
      }
    }
  }
  if (tilesetIds.contains('ts_selbrume_cabin_interior') ||
      elementIds.any((id) => _task8CabinElementIds.contains(id)) ||
      folderIds.contains('tsf_selbrume_beta_interiors') ||
      categoryIds.contains('cat_selbrume_interiors')) {
    materialized = _laterBoundary(materialized, 'task8');
  }
  if (tilesetIds.contains('ts_selbrume_forest_props') ||
      elementIds.any((id) => _task9ForestElementIds.contains(id)) ||
      folderIds.contains('tsf_selbrume_beta_forest') ||
      categoryIds.contains('cat_selbrume_forest')) {
    materialized = _laterBoundary(materialized, 'task9');
  }
  if (tilesetIds.contains('ts_selbrume_marsh_props') ||
      elementIds.any((id) => _task10MarshElementIds.contains(id)) ||
      folderIds.contains('tsf_selbrume_beta_marsh') ||
      categoryIds.contains('cat_selbrume_marsh')) {
    materialized = _laterBoundary(materialized, 'task10');
  }
  if (tilesetIds.contains('ts_selbrume_passage_props') ||
      elementIds.any((id) => _task11PassageElementIds.contains(id)) ||
      folderIds.contains('tsf_selbrume_beta_passage') ||
      categoryIds.contains('cat_selbrume_passage')) {
    materialized = _laterBoundary(materialized, 'task11');
  }
  if (tilesetIds.contains('ts_selbrume_lighthouse_exterior') ||
      elementIds.any(
        (id) => _task12LighthouseExteriorElementIds.contains(id),
      ) ||
      folderIds.contains('tsf_selbrume_beta_lighthouse') ||
      categoryIds.contains('cat_selbrume_lighthouse')) {
    materialized = _laterBoundary(materialized, 'task12');
  }
  if (tilesetIds.contains('ts_selbrume_lighthouse_interior') ||
      elementIds.any(
        (id) => _task13LighthouseInteriorElementIds.contains(id),
      )) {
    materialized = _laterBoundary(materialized, 'task13');
  }
  if (tilesetIds.contains('ts_selbrume_lighthouse_fx') ||
      elementIds.any((id) => _task14LighthouseFxElementIds.contains(id)) ||
      folderIds.contains('tsf_selbrume_beta_fx') ||
      categoryIds.contains('cat_selbrume_fx')) {
    materialized = _laterBoundary(materialized, 'task14');
  }
  materialized = _laterBoundary(
    materialized,
    _materializedMapBoundary(mapsDirectory),
  );
  if (_boundaryRank(requested) < _boundaryRank(materialized)) {
    throw StateError(
      'Refusing Selbrume boundary downgrade from $materialized to $requested; '
      'lower-boundary output would overwrite or retain later map/manifest '
      'artifacts.',
    );
  }
}

String _materializedMapBoundary(Directory mapsDirectory) {
  var boundary = 'task4';

  Map<String, dynamic>? readMap(String id) {
    final file = File(p.join(mapsDirectory.path, '$id.json'));
    if (!file.existsSync()) return null;
    return _decodeJsonObject(file.readAsStringSync(), file.path);
  }

  String? markerOf(Map<String, dynamic> map, String mapId) {
    final properties = map['properties'];
    if (properties is! Map) return null;
    final marker = properties['selbrumeGeneratorBoundary'];
    if (marker == null || marker == '') return null;
    if (marker != 'task7' &&
        marker != 'task8' &&
        marker != 'task9' &&
        marker != 'task10' &&
        marker != 'task11' &&
        marker != 'task12' &&
        marker != 'task13' &&
        marker != 'task14' &&
        marker != 'task15' &&
        marker != 'task16') {
      throw StateError('Invalid $mapId generator boundary: $marker.');
    }
    return marker as String;
  }

  final bourg = readMap('map_bourg_selbrume');
  if (bourg != null) {
    final marker = markerOf(bourg, 'map_bourg_selbrume');
    if (marker != null) {
      boundary = _laterBoundary(boundary, marker);
    } else {
      final layerIds = _jsonObjectList(
        bourg['layers'],
        context: 'map_bourg_selbrume layers',
      ).map((layer) => layer['id']).toList(growable: false);
      final placedIds = _optionalObjectIds(bourg['placedElements']);
      if (bourg['tilesetId'] == '' &&
          layerIds.join('|') ==
              'l_terrain|l_path_primary|l_path_secondary|l_tile_ground|'
                  'l_tile_structures|l_tile_overhead|l_tile_fx|l_collisions' &&
          placedIds.contains('pe_bourg_maison_joueur_facade')) {
        boundary = _laterBoundary(boundary, 'task7');
      }
    }
  }

  final house = readMap('map_maison_joueur');
  if (house != null) {
    final marker = markerOf(house, 'map_maison_joueur');
    if (marker != null) {
      boundary = _laterBoundary(boundary, marker);
    } else {
      final placedIds = _optionalObjectIds(house['placedElements']);
      if (house['tilesetId'] == '' &&
          placedIds.containsAll(const <String>{
            'pe_maison_lit',
            'pe_maison_bureau',
            'pe_maison_tapis',
            'pe_maison_etagere',
            'pe_maison_porte',
          })) {
        boundary = _laterBoundary(boundary, 'task8');
      }
    }
  }
  final forest = readMap('map_bois_chaise_brume');
  if (forest != null) {
    final marker = markerOf(forest, 'map_bois_chaise_brume');
    if (marker != null) {
      boundary = _laterBoundary(boundary, marker);
    } else {
      final layerIds = _jsonObjectList(
        forest['layers'],
        context: 'map_bois_chaise_brume layers',
      ).map((layer) => layer['id']).toList(growable: false);
      final placedIds = _optionalObjectIds(forest['placedElements']);
      if (forest['tilesetId'] == '' &&
          layerIds.join('|') ==
              'l_terrain|l_path_primary|l_path_secondary|l_tile_ground|'
                  'l_tile_structures|l_tile_overhead|l_tile_fx|l_collisions' &&
          placedIds.containsAll(const <String>{
            'pe_bois_pin_grand_001',
            'pe_bois_tronc_tombe_001',
            'pe_bois_panneau_001',
          })) {
        boundary = _laterBoundary(boundary, 'task9');
      }
    }
  }
  final marsh = readMap('map_marais_salants');
  if (marsh != null) {
    final marker = markerOf(marsh, 'map_marais_salants');
    if (marker != null) {
      boundary = _laterBoundary(boundary, marker);
    } else {
      final layerIds = _jsonObjectList(
        marsh['layers'],
        context: 'map_marais_salants layers',
      ).map((layer) => layer['id']).toList(growable: false);
      final placedIds = _optionalObjectIds(marsh['placedElements']);
      if (marsh['tilesetId'] == '' &&
          layerIds.join('|') ==
              'l_terrain|l_path_primary|l_path_secondary|l_tile_ground|'
                  'l_tile_structures|l_tile_overhead|l_tile_fx|l_collisions' &&
          placedIds.containsAll(const <String>{
            'pe_marais_cabane_paludier',
            'pe_marais_ecluse',
            'pe_marais_indice_verre',
            'pe_marais_cristal_3',
          })) {
        boundary = _laterBoundary(boundary, 'task10');
      }
    }
  }
  final passage = readMap('map_passage_dames');
  if (passage != null) {
    final marker = markerOf(passage, 'map_passage_dames');
    if (marker != null) {
      boundary = _laterBoundary(boundary, marker);
    } else {
      final layerIds = _jsonObjectList(
        passage['layers'],
        context: 'map_passage_dames layers',
      ).map((layer) => layer['id']).toList(growable: false);
      final placedIds = _optionalObjectIds(passage['placedElements']);
      if (passage['tilesetId'] == '' &&
          layerIds.join('|') ==
              'l_terrain|l_path_primary|l_path_secondary|l_tile_ground|'
                  'l_tile_structures|l_tile_overhead|l_tile_fx|l_collisions' &&
          placedIds.containsAll(const <String>{
            'pe_passage_barriere',
            'pe_passage_marches',
            'pe_passage_flaques',
            'pe_passage_banc_brume',
          })) {
        boundary = _laterBoundary(boundary, 'task11');
      }
    }
  }
  final lighthouseExterior = readMap('map_phare_exterieur');
  if (lighthouseExterior != null) {
    final marker = markerOf(lighthouseExterior, 'map_phare_exterieur');
    if (marker != null) {
      boundary = _laterBoundary(boundary, marker);
    } else {
      final layerIds = _jsonObjectList(
        lighthouseExterior['layers'],
        context: 'map_phare_exterieur layers',
      ).map((layer) => layer['id']).toList(growable: false);
      final placedIds = _optionalObjectIds(
        lighthouseExterior['placedElements'],
      );
      if (lighthouseExterior['tilesetId'] == '' &&
          layerIds.join('|') ==
              'l_terrain|l_path_primary|l_path_secondary|l_tile_ground|'
                  'l_tile_structures|l_tile_overhead|l_tile_fx|l_collisions' &&
          placedIds.containsAll(const <String>{
            'pe_phare_batiment',
            'pe_phare_cabane_facade',
            'pe_phare_porte_ouverte',
            'pe_phare_cabane_porte_ouverte',
          })) {
        boundary = _laterBoundary(boundary, 'task12');
      }
    }
  }
  final lighthouseInterior = readMap('map_phare_interieur');
  if (lighthouseInterior != null) {
    final marker = markerOf(lighthouseInterior, 'map_phare_interieur');
    if (marker != null) {
      boundary = _laterBoundary(boundary, marker);
    } else {
      final layerIds = _jsonObjectList(
        lighthouseInterior['layers'],
        context: 'map_phare_interieur layers',
      ).map((layer) => layer['id']).toList(growable: false);
      final placedIds = _optionalObjectIds(
        lighthouseInterior['placedElements'],
      );
      if (lighthouseInterior['tilesetId'] == '' &&
          layerIds.join('|') ==
              'l_terrain|l_host_selbrume_lighthouse_interior|l_collisions' &&
          placedIds.containsAll(const <String>{
            'pe_phare_escalier_haut',
            'pe_phare_escalier_bas',
            'pe_phare_note_ancien_gardien',
            'pe_phare_mecanisme',
          })) {
        boundary = _laterBoundary(boundary, 'task13');
      }
    }
  }
  final lighthouseTop = readMap('map_sommet_phare');
  if (lighthouseTop != null) {
    final marker = markerOf(lighthouseTop, 'map_sommet_phare');
    if (marker != null) {
      boundary = _laterBoundary(boundary, marker);
    } else {
      final layerIds = _jsonObjectList(
        lighthouseTop['layers'],
        context: 'map_sommet_phare layers',
      ).map((layer) => layer['id']).toList(growable: false);
      final placedIds = _optionalObjectIds(lighthouseTop['placedElements']);
      if (lighthouseTop['tilesetId'] == '' &&
          layerIds.join('|') ==
              'l_terrain|l_host_selbrume_lighthouse_interior|'
                  'l_host_selbrume_lighthouse_fx|l_collisions' &&
          placedIds.containsAll(const <String>{
            'pe_sommet_plateforme',
            'pe_sommet_lanterne',
            'pe_sommet_lumiere_eteinte',
          })) {
        boundary = _laterBoundary(boundary, 'task14');
      }
    }
  }
  final keeperCabin = readMap('map_cabane_gardien');
  if (keeperCabin != null) {
    final marker = markerOf(keeperCabin, 'map_cabane_gardien');
    if (marker != null) {
      boundary = _laterBoundary(boundary, marker);
    } else {
      final layerIds = _jsonObjectList(
        keeperCabin['layers'],
        context: 'map_cabane_gardien layers',
      ).map((layer) => layer['id']).toList(growable: false);
      final placedIds = _optionalObjectIds(keeperCabin['placedElements']);
      if (keeperCabin['tilesetId'] == '' &&
          layerIds.join('|') ==
              'l_terrain|l_tile_floor|l_tile_walls|l_tile_furniture|'
                  'l_tile_overhead|l_tile_fx|l_collisions' &&
          placedIds.containsAll(const <String>{
            'pe_cabane_table',
            'pe_cabane_journal',
            'pe_cabane_cle',
            'pe_cabane_porte_secondaire',
          })) {
        boundary = _laterBoundary(boundary, 'task15');
      }
    }
  }
  return boundary;
}

String _laterBoundary(String left, String right) =>
    _boundaryRank(left) >= _boundaryRank(right) ? left : right;

Set<String> _optionalObjectIds(Object? value) {
  if (value is! List) return const <String>{};
  return <String>{
    for (final item in value)
      if (item is Map && item['id'] is String) item['id'] as String,
  };
}

int _boundaryRank(String boundary) => switch (boundary) {
      'task4' => 4,
      'task5' => 5,
      'task6' => 6,
      'task7' => 7,
      'task8' => 8,
      'task9' => 9,
      'task10' => 10,
      'task11' => 11,
      'task12' => 12,
      'task13' => 13,
      'task14' => 14,
      'task15' => 15,
      'task16' => 16,
      _ => throw ArgumentError.value(boundary, 'boundary'),
    };

String _replaceTopLevelArray(
  String source, {
  required String key,
  required List<Map<String, dynamic>> value,
}) {
  final span = _findTopLevelArraySpan(source, key);
  final encoded = _prettyJson.convert(value).replaceAll('\n', '\n  ');
  return source.replaceRange(span.start, span.end, encoded);
}

_SourceSpan _findTopLevelArraySpan(String source, String targetKey) {
  var objectDepth = 0;
  var arrayDepth = 0;
  var inString = false;
  var escaped = false;
  var stringStart = -1;
  String? topLevelKey;

  for (var index = 0; index < source.length; index++) {
    final code = source.codeUnitAt(index);
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (code == 0x5c) {
        escaped = true;
      } else if (code == 0x22) {
        inString = false;
        if (objectDepth == 1 && arrayDepth == 0) {
          topLevelKey = jsonDecode(source.substring(stringStart, index + 1));
        }
      }
      continue;
    }

    switch (code) {
      case 0x22:
        inString = true;
        stringStart = index;
        break;
      case 0x7b:
        objectDepth++;
        break;
      case 0x7d:
        objectDepth--;
        topLevelKey = null;
        break;
      case 0x5b:
        if (objectDepth == 1 && arrayDepth == 0 && topLevelKey == targetKey) {
          final end = _matchingArrayEnd(source, index);
          return _SourceSpan(index, end);
        }
        arrayDepth++;
        topLevelKey = null;
        break;
      case 0x5d:
        arrayDepth--;
        break;
      case 0x2c:
        if (objectDepth == 1 && arrayDepth == 0) topLevelKey = null;
        break;
    }
  }
  throw FormatException('Missing top-level array "$targetKey".');
}

int _matchingArrayEnd(String source, int start) {
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var index = start; index < source.length; index++) {
    final code = source.codeUnitAt(index);
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (code == 0x5c) {
        escaped = true;
      } else if (code == 0x22) {
        inString = false;
      }
      continue;
    }
    if (code == 0x22) {
      inString = true;
    } else if (code == 0x5b) {
      depth++;
    } else if (code == 0x5d) {
      depth--;
      if (depth == 0) return index + 1;
    }
  }
  throw const FormatException('Unterminated JSON array.');
}

Future<Directory> _validatedProjectRoot(Directory requested) async {
  if (!await requested.exists()) {
    throw FileSystemException('Project root does not exist.', requested.path);
  }
  final resolved = Directory(await requested.resolveSymbolicLinks());
  final projectFile = File(p.join(resolved.path, 'project.json'));
  if (!await projectFile.exists()) {
    throw FileSystemException('Missing project.json.', projectFile.path);
  }
  final resolvedProjectFile = await projectFile.resolveSymbolicLinks();
  if (!p.isWithin(resolved.path, resolvedProjectFile)) {
    throw FileSystemException(
      'project.json escapes the project root.',
      projectFile.path,
    );
  }
  final mapsDirectory = await _validatedMapsDirectory(resolved);
  for (final name in <String>['Selbrume.json', 'route 1.json']) {
    final seed = File(p.join(mapsDirectory.path, name));
    if (!await seed.exists()) {
      throw FileSystemException('Missing required seed map.', seed.path);
    }
    final resolvedSeed = await seed.resolveSymbolicLinks();
    if (!p.isWithin(resolved.path, resolvedSeed)) {
      throw FileSystemException(
          'Seed map escapes the project root.', seed.path);
    }
  }
  return resolved;
}

Future<Directory> _validatedMapsDirectory(Directory projectRoot) async {
  final requested = Directory(p.join(projectRoot.path, 'maps'));
  if (!await requested.exists()) {
    throw FileSystemException('Missing maps directory.', requested.path);
  }
  final resolvedPath = await requested.resolveSymbolicLinks();
  if (!p.isWithin(projectRoot.path, resolvedPath)) {
    throw FileSystemException(
      'maps directory escapes the project root.',
      requested.path,
    );
  }
  return Directory(resolvedPath);
}

Future<void> _writeAtomicallyWithManifestLast({
  required Map<File, String> desiredFiles,
  required File manifestFile,
}) async {
  final tempFiles = <File, File>{};
  var counter = 0;
  try {
    for (final entry in desiredFiles.entries) {
      final target = entry.key;
      final temp = File(
        '${target.path}.selbrume-tmp-$pid-'
        '${DateTime.now().microsecondsSinceEpoch}-${counter++}',
      );
      await temp.create(exclusive: true);
      RandomAccessFile? handle;
      try {
        handle = await temp.open(mode: FileMode.writeOnly);
        await handle.writeString(entry.value);
        await handle.flush();
      } finally {
        await handle?.close();
      }
      tempFiles[target] = temp;
    }

    final targets = tempFiles.keys
        .where((file) => file.path != manifestFile.path)
        .toList(growable: false);
    for (final target in targets) {
      await tempFiles[target]!.rename(target.path);
      tempFiles.remove(target);
    }
    final manifestTemp = tempFiles[manifestFile];
    if (manifestTemp != null) {
      await manifestTemp.rename(manifestFile.path);
      tempFiles.remove(manifestFile);
    }
  } finally {
    for (final temp in tempFiles.values) {
      if (await temp.exists()) await temp.delete();
    }
  }
}

Map<String, dynamic> _decodeJsonObject(String source, String path) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) throw FormatException('$path must contain an object.');
  return decoded.cast<String, dynamic>();
}

Map<String, dynamic> _deepJsonCopy(Map<String, dynamic> source) =>
    _decodeJsonObject(jsonEncode(source), '<memory>');

final class _CellRect {
  const _CellRect(this.x, this.y, this.width, this.height);

  final int x;
  final int y;
  final int width;
  final int height;

  @override
  String toString() => '($x,$y ${width}x$height)';
}

final class _SourceSpan {
  const _SourceSpan(this.start, this.end);

  final int start;
  final int end;
}

final class _Task5Assets {
  const _Task5Assets({required this.boat});

  final img.Image boat;
}

final class _PortElementSpec {
  const _PortElementSpec({
    required this.id,
    required this.name,
    required this.source,
    required this.layerId,
    this.collisionCells = const <GridPos>[],
    this.occlusionCells = const <GridPos>[],
    this.isStateVariant = false,
  });

  final String id;
  final String name;
  final TilesetSourceRect source;
  final String layerId;
  final List<GridPos> collisionCells;
  final List<GridPos> occlusionCells;
  final bool isStateVariant;
}

final class _CabinElementSpec {
  const _CabinElementSpec({
    required this.id,
    required this.name,
    required this.source,
    required this.layerId,
    this.collisionCells = const <GridPos>[],
    this.isStateVariant = false,
  });

  final String id;
  final String name;
  final TilesetSourceRect source;
  final String layerId;
  final List<GridPos> collisionCells;
  final bool isStateVariant;
}

final class _ForestElementSpec {
  const _ForestElementSpec({
    required this.id,
    required this.name,
    required this.source,
    required this.layerId,
    this.collisionCells = const <GridPos>[],
    this.hasCanopy = false,
  });

  final String id;
  final String name;
  final TilesetSourceRect source;
  final String layerId;
  final List<GridPos> collisionCells;
  final bool hasCanopy;
}

final class _MarshElementSpec {
  const _MarshElementSpec({
    required this.id,
    required this.name,
    required this.source,
    required this.layerId,
    this.collisionCells = const <GridPos>[],
    this.occlusionCells = const <GridPos>[],
    this.isStateVariant = false,
  });

  final String id;
  final String name;
  final TilesetSourceRect source;
  final String layerId;
  final List<GridPos> collisionCells;
  final List<GridPos> occlusionCells;
  final bool isStateVariant;
}

final class _PassageElementSpec {
  const _PassageElementSpec({
    required this.id,
    required this.name,
    required this.source,
    required this.layerId,
    this.collisionCells = const <GridPos>[],
    this.isStateVariant = false,
  });

  final String id;
  final String name;
  final TilesetSourceRect source;
  final String layerId;
  final List<GridPos> collisionCells;
  final bool isStateVariant;
}

final class _LighthouseExteriorElementSpec {
  const _LighthouseExteriorElementSpec({
    required this.id,
    required this.name,
    required this.source,
    required this.layerId,
    this.collisionCells = const <GridPos>[],
    this.occlusionCells = const <GridPos>[],
    this.isStateVariant = false,
  });

  final String id;
  final String name;
  final TilesetSourceRect source;
  final String layerId;
  final List<GridPos> collisionCells;
  final List<GridPos> occlusionCells;
  final bool isStateVariant;
}

final List<_LighthouseExteriorElementSpec> _lighthouseExteriorElementSpecs =
    <_LighthouseExteriorElementSpec>[
  const _LighthouseExteriorElementSpec(
    id: 'el_selbrume_phare_batiment',
    name: "Vieux Phare d'Ecume",
    source: TilesetSourceRect(x: 0, y: 0, width: 8, height: 10),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 3, y: 0),
      GridPos(x: 4, y: 0),
      GridPos(x: 5, y: 0),
      GridPos(x: 3, y: 1),
      GridPos(x: 5, y: 1),
      GridPos(x: 2, y: 2),
      GridPos(x: 5, y: 2),
      GridPos(x: 2, y: 3),
      GridPos(x: 5, y: 3),
      GridPos(x: 2, y: 4),
      GridPos(x: 5, y: 4),
      GridPos(x: 1, y: 5),
      GridPos(x: 5, y: 5),
      GridPos(x: 1, y: 6),
      GridPos(x: 5, y: 6),
      GridPos(x: 1, y: 7),
      GridPos(x: 6, y: 7),
      GridPos(x: 1, y: 8),
      GridPos(x: 6, y: 8),
      GridPos(x: 1, y: 9),
      GridPos(x: 2, y: 9),
      GridPos(x: 3, y: 9),
      GridPos(x: 5, y: 9),
      GridPos(x: 6, y: 9),
    ],
    occlusionCells: <GridPos>[
      GridPos(x: 3, y: 0),
      GridPos(x: 4, y: 0),
      GridPos(x: 5, y: 0),
      GridPos(x: 3, y: 1),
      GridPos(x: 4, y: 1),
      GridPos(x: 5, y: 1),
      GridPos(x: 2, y: 2),
      GridPos(x: 3, y: 2),
      GridPos(x: 4, y: 2),
      GridPos(x: 5, y: 2),
      GridPos(x: 2, y: 3),
      GridPos(x: 3, y: 3),
      GridPos(x: 4, y: 3),
      GridPos(x: 5, y: 3),
      GridPos(x: 2, y: 4),
      GridPos(x: 3, y: 4),
      GridPos(x: 4, y: 4),
      GridPos(x: 5, y: 4),
      GridPos(x: 1, y: 5),
      GridPos(x: 2, y: 5),
      GridPos(x: 3, y: 5),
      GridPos(x: 4, y: 5),
      GridPos(x: 5, y: 5),
      GridPos(x: 1, y: 6),
      GridPos(x: 2, y: 6),
      GridPos(x: 3, y: 6),
      GridPos(x: 4, y: 6),
      GridPos(x: 5, y: 6),
      GridPos(x: 1, y: 7),
      GridPos(x: 2, y: 7),
      GridPos(x: 3, y: 7),
      GridPos(x: 4, y: 7),
      GridPos(x: 5, y: 7),
      GridPos(x: 6, y: 7),
    ],
  ),
  _LighthouseExteriorElementSpec(
    id: 'el_selbrume_cabane_facade',
    name: 'Facade de la cabane du gardien',
    source: const TilesetSourceRect(x: 8, y: 0, width: 5, height: 5),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[
      for (var y = 0; y < 5; y++)
        for (var x = 0; x < 5; x++)
          if (y == 0 || x == 0 || x == 4 || (y == 4 && x != 2))
            GridPos(x: x, y: y),
    ],
    occlusionCells: _fullGridCells(5, 4),
  ),
  _LighthouseExteriorElementSpec(
    id: 'el_selbrume_phare_porte_fermee',
    name: 'Porte fermee du phare',
    source: const TilesetSourceRect(x: 8, y: 5, width: 2, height: 3),
    layerId: 'l_tile_structures',
    collisionCells: _fullGridCells(2, 3),
    isStateVariant: true,
  ),
  const _LighthouseExteriorElementSpec(
    id: 'el_selbrume_phare_porte_ouverte',
    name: 'Porte ouverte du phare',
    source: TilesetSourceRect(x: 10, y: 5, width: 2, height: 3),
    layerId: 'l_tile_structures',
    isStateVariant: true,
  ),
  _LighthouseExteriorElementSpec(
    id: 'el_selbrume_cabane_porte_fermee',
    name: 'Porte fermee de la cabane du gardien',
    source: const TilesetSourceRect(x: 12, y: 5, width: 2, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: _fullGridCells(2, 2),
    isStateVariant: true,
  ),
  const _LighthouseExteriorElementSpec(
    id: 'el_selbrume_cabane_porte_ouverte',
    name: 'Porte ouverte de la cabane du gardien',
    source: TilesetSourceRect(x: 14, y: 5, width: 2, height: 2),
    layerId: 'l_tile_structures',
    isStateVariant: true,
  ),
  const _LighthouseExteriorElementSpec(
    id: 'el_selbrume_phare_fenetre_sombre',
    name: 'Fenetre sombre du phare',
    source: TilesetSourceRect(x: 8, y: 8, width: 2, height: 2),
    layerId: 'l_tile_structures',
    isStateVariant: true,
  ),
  const _LighthouseExteriorElementSpec(
    id: 'el_selbrume_phare_fenetre_lumineuse',
    name: 'Fenetre lumineuse du phare',
    source: TilesetSourceRect(x: 10, y: 8, width: 2, height: 2),
    layerId: 'l_tile_fx',
    isStateVariant: true,
  ),
  _LighthouseExteriorElementSpec(
    id: 'el_selbrume_phare_rambarde',
    name: 'Rambarde du phare',
    source: const TilesetSourceRect(x: 12, y: 8, width: 4, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: _fullGridCells(4, 2),
  ),
  const _LighthouseExteriorElementSpec(
    id: 'el_selbrume_phare_fondation',
    name: 'Fondation rocheuse du phare',
    source: TilesetSourceRect(x: 0, y: 10, width: 8, height: 2),
    layerId: 'l_tile_ground',
    collisionCells: <GridPos>[
      GridPos(x: 1, y: 0),
      GridPos(x: 6, y: 0),
      GridPos(x: 1, y: 1),
      GridPos(x: 6, y: 1),
    ],
  ),
  const _LighthouseExteriorElementSpec(
    id: 'el_selbrume_phare_panneau',
    name: 'Panneau du phare',
    source: TilesetSourceRect(x: 8, y: 10, width: 2, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1)],
  ),
  const _LighthouseExteriorElementSpec(
    id: 'el_selbrume_phare_debris',
    name: 'Debris du phare',
    source: TilesetSourceRect(x: 10, y: 10, width: 3, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ],
  ),
  const _LighthouseExteriorElementSpec(
    id: 'el_selbrume_phare_marches',
    name: 'Marches du phare',
    source: TilesetSourceRect(x: 13, y: 10, width: 3, height: 2),
    layerId: 'l_tile_ground',
  ),
];

final Set<String> _task12LighthouseExteriorElementIds = <String>{
  for (final spec in _lighthouseExteriorElementSpecs) spec.id,
};

final class _LighthouseInteriorElementSpec {
  const _LighthouseInteriorElementSpec({
    required this.id,
    required this.name,
    required this.source,
    required this.layerId,
    required this.mapTag,
    this.collisionCells = const <GridPos>[],
  });

  final String id;
  final String name;
  final TilesetSourceRect source;
  final String layerId;
  final String mapTag;
  final List<GridPos> collisionCells;
}

final List<_LighthouseInteriorElementSpec> _lighthouseInteriorElementSpecs =
    <_LighthouseInteriorElementSpec>[
  const _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_sol_pierre',
    name: 'Sol de pierre du phare',
    source: TilesetSourceRect(x: 0, y: 0, width: 4, height: 4),
    layerId: 'l_tile_floor',
    mapTag: 'map_phare_interieur',
  ),
  const _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_sol_bois',
    name: 'Plancher de bois du phare',
    source: TilesetSourceRect(x: 4, y: 0, width: 4, height: 4),
    layerId: 'l_tile_floor',
    mapTag: 'map_phare_interieur',
  ),
  _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_mur_n',
    name: 'Mur nord du phare',
    source: const TilesetSourceRect(x: 8, y: 0, width: 4, height: 2),
    layerId: 'l_tile_walls',
    mapTag: 'map_phare_interieur',
    collisionCells: _fullGridCells(4, 2),
  ),
  _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_mur_s',
    name: 'Mur sud du phare',
    source: const TilesetSourceRect(x: 12, y: 0, width: 4, height: 2),
    layerId: 'l_tile_walls',
    mapTag: 'map_phare_interieur',
    collisionCells: _fullGridCells(4, 2),
  ),
  _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_mur_e',
    name: 'Mur est du phare',
    source: const TilesetSourceRect(x: 16, y: 0, width: 2, height: 4),
    layerId: 'l_tile_walls',
    mapTag: 'map_phare_interieur',
    collisionCells: _fullGridCells(2, 4),
  ),
  _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_mur_o',
    name: 'Mur ouest du phare',
    source: const TilesetSourceRect(x: 18, y: 0, width: 2, height: 4),
    layerId: 'l_tile_walls',
    mapTag: 'map_phare_interieur',
    collisionCells: _fullGridCells(2, 4),
  ),
  for (final contract in const <(String, String, int)>[
    ('el_selbrume_phare_coin_no', 'Coin nord-ouest du phare', 20),
    ('el_selbrume_phare_coin_ne', 'Coin nord-est du phare', 22),
    ('el_selbrume_phare_coin_so', 'Coin sud-ouest du phare', 24),
    ('el_selbrume_phare_coin_se', 'Coin sud-est du phare', 26),
  ])
    _LighthouseInteriorElementSpec(
      id: contract.$1,
      name: contract.$2,
      source: TilesetSourceRect(x: contract.$3, y: 0, width: 2, height: 2),
      layerId: 'l_tile_walls',
      mapTag: 'map_phare_interieur',
      collisionCells: _fullGridCells(2, 2),
    ),
  const _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_escalier_haut',
    name: 'Escalier montant du phare',
    source: TilesetSourceRect(x: 8, y: 4, width: 3, height: 3),
    layerId: 'l_tile_floor',
    mapTag: 'map_phare_interieur',
  ),
  const _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_escalier_bas',
    name: 'Escalier descendant du phare',
    source: TilesetSourceRect(x: 11, y: 4, width: 3, height: 3),
    layerId: 'l_tile_floor',
    mapTag: 'map_phare_interieur',
  ),
  _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_rambarde_h',
    name: 'Rambarde horizontale du phare',
    source: const TilesetSourceRect(x: 14, y: 4, width: 4, height: 1),
    layerId: 'l_tile_walls',
    mapTag: 'map_phare_interieur',
    collisionCells: _fullGridCells(4, 1),
  ),
  _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_rambarde_v',
    name: 'Rambarde verticale du phare',
    source: const TilesetSourceRect(x: 18, y: 4, width: 1, height: 4),
    layerId: 'l_tile_walls',
    mapTag: 'map_phare_interieur',
    collisionCells: _fullGridCells(1, 4),
  ),
  _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_plancher_brise',
    name: 'Plancher brise du phare',
    source: const TilesetSourceRect(x: 19, y: 4, width: 3, height: 3),
    layerId: 'l_tile_furniture',
    mapTag: 'map_phare_interieur',
    collisionCells: _fullGridCells(3, 3),
  ),
  _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_mecanisme',
    name: 'Mecanisme principal du phare',
    source: const TilesetSourceRect(x: 22, y: 4, width: 5, height: 5),
    layerId: 'l_tile_furniture',
    mapTag: 'map_phare_interieur',
    collisionCells: _fullGridCells(5, 5),
  ),
  _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_machinerie',
    name: 'Machinerie du phare',
    source: const TilesetSourceRect(x: 0, y: 8, width: 3, height: 3),
    layerId: 'l_tile_furniture',
    mapTag: 'map_phare_interieur',
    collisionCells: _fullGridCells(3, 3),
  ),
  const _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_bureau_note',
    name: "Bureau et note de l'ancien gardien",
    source: TilesetSourceRect(x: 3, y: 8, width: 2, height: 2),
    layerId: 'l_tile_furniture',
    mapTag: 'map_phare_interieur',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ],
  ),
  const _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_caisses_debris',
    name: 'Caisses et debris du phare',
    source: TilesetSourceRect(x: 5, y: 8, width: 3, height: 2),
    layerId: 'l_tile_furniture',
    mapTag: 'map_phare_interieur',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
    ],
  ),
  const _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_fenetre_interieure',
    name: 'Fenetre interieure du phare',
    source: TilesetSourceRect(x: 8, y: 8, width: 2, height: 2),
    layerId: 'l_tile_walls',
    mapTag: 'map_phare_interieur',
  ),
  const _LighthouseInteriorElementSpec(
    id: 'el_selbrume_phare_trappe',
    name: 'Trappe du phare',
    source: TilesetSourceRect(x: 10, y: 8, width: 2, height: 2),
    layerId: 'l_tile_floor',
    mapTag: 'map_phare_interieur',
  ),
  const _LighthouseInteriorElementSpec(
    id: 'el_selbrume_sommet_plateforme',
    name: 'Plateforme du sommet du phare',
    source: TilesetSourceRect(x: 0, y: 12, width: 6, height: 6),
    layerId: 'l_tile_floor',
    mapTag: 'map_sommet_phare',
  ),
  const _LighthouseInteriorElementSpec(
    id: 'el_selbrume_sommet_parapet_h',
    name: 'Parapet horizontal du sommet',
    source: TilesetSourceRect(x: 6, y: 12, width: 4, height: 2),
    layerId: 'l_tile_walls',
    mapTag: 'map_sommet_phare',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
      GridPos(x: 3, y: 1),
    ],
  ),
  _LighthouseInteriorElementSpec(
    id: 'el_selbrume_sommet_parapet_v',
    name: 'Parapet vertical du sommet',
    source: const TilesetSourceRect(x: 10, y: 12, width: 2, height: 4),
    layerId: 'l_tile_walls',
    mapTag: 'map_sommet_phare',
    collisionCells: _fullGridCells(2, 4),
  ),
  _LighthouseInteriorElementSpec(
    id: 'el_selbrume_sommet_lanterne',
    name: 'Lanterne du sommet du phare',
    source: const TilesetSourceRect(x: 12, y: 12, width: 5, height: 5),
    layerId: 'l_tile_furniture',
    mapTag: 'map_sommet_phare',
    collisionCells: <GridPos>[
      for (var y = 0; y < 5; y++)
        for (var x = 0; x < 5; x++)
          if (y != 0 || (x != 0 && x != 4)) GridPos(x: x, y: y),
    ],
  ),
];

final Set<String> _task13LighthouseInteriorElementIds = <String>{
  for (final spec in _lighthouseInteriorElementSpecs) spec.id,
};

final class _LighthouseFxElementSpec {
  const _LighthouseFxElementSpec({
    required this.id,
    required this.name,
    required this.frames,
    this.stateVariant = false,
    this.animated = false,
  });

  final String id;
  final String name;
  final List<TilesetVisualFrame> frames;
  final bool stateVariant;
  final bool animated;
}

final List<_LighthouseFxElementSpec> _lighthouseFxElementSpecs =
    <_LighthouseFxElementSpec>[
  const _LighthouseFxElementSpec(
    id: 'el_selbrume_fx_brume_basse',
    name: 'Brume basse du phare',
    frames: <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: 8, height: 4),
      ),
    ],
  ),
  const _LighthouseFxElementSpec(
    id: 'el_selbrume_fx_banc_brume',
    name: 'Banc de brume du phare',
    frames: <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 8, y: 0, width: 8, height: 4),
      ),
    ],
  ),
  const _LighthouseFxElementSpec(
    id: 'el_selbrume_fx_faisceau',
    name: 'Faisceau du phare',
    frames: <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 4, width: 8, height: 2),
      ),
    ],
  ),
  const _LighthouseFxElementSpec(
    id: 'el_selbrume_fx_fenetre_lumineuse',
    name: 'Fenetre lumineuse du phare',
    frames: <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 8, y: 4, width: 2, height: 2),
      ),
    ],
  ),
  const _LighthouseFxElementSpec(
    id: 'el_selbrume_fx_halo',
    name: 'Halo du phare',
    frames: <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 10, y: 4, width: 4, height: 4),
      ),
    ],
  ),
  const _LighthouseFxElementSpec(
    id: 'el_selbrume_fx_lumiere_eteinte',
    name: 'Lumiere du phare eteinte',
    frames: <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 6, width: 4, height: 4),
      ),
    ],
    stateVariant: true,
  ),
  const _LighthouseFxElementSpec(
    id: 'el_selbrume_fx_lumiere_stabilisee',
    name: 'Lumiere du phare stabilisee',
    frames: <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 4, y: 6, width: 4, height: 4),
      ),
    ],
    stateVariant: true,
  ),
  const _LighthouseFxElementSpec(
    id: 'el_selbrume_fx_lumiere_instable',
    name: 'Lumiere instable du phare',
    frames: <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 10, width: 4, height: 4),
        durationMs: 160,
      ),
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 4, y: 10, width: 4, height: 4),
        durationMs: 160,
      ),
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 8, y: 10, width: 4, height: 4),
        durationMs: 160,
      ),
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 12, y: 10, width: 4, height: 4),
        durationMs: 160,
      ),
    ],
    stateVariant: true,
    animated: true,
  ),
  const _LighthouseFxElementSpec(
    id: 'el_selbrume_fx_etincelles',
    name: 'Etincelles du phare',
    frames: <TilesetVisualFrame>[
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 14, width: 2, height: 2),
        durationMs: 120,
      ),
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 2, y: 14, width: 2, height: 2),
        durationMs: 120,
      ),
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 4, y: 14, width: 2, height: 2),
        durationMs: 120,
      ),
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 6, y: 14, width: 2, height: 2),
        durationMs: 120,
      ),
    ],
    stateVariant: true,
    animated: true,
  ),
];

final Set<String> _task14LighthouseFxElementIds = <String>{
  for (final spec in _lighthouseFxElementSpecs) spec.id,
};

final List<_PassageElementSpec> _passageElementSpecs = <_PassageElementSpec>[
  _PassageElementSpec(
    id: 'el_selbrume_passage_barriere_fermee',
    name: 'Barriere fermee du Passage des Dames',
    source: const TilesetSourceRect(x: 0, y: 0, width: 4, height: 3),
    layerId: 'l_tile_structures',
    collisionCells: _fullGridCells(4, 3),
    isStateVariant: true,
  ),
  const _PassageElementSpec(
    id: 'el_selbrume_passage_barriere_ouverte',
    name: 'Barriere ouverte du Passage des Dames',
    source: TilesetSourceRect(x: 4, y: 0, width: 4, height: 3),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 2),
      GridPos(x: 3, y: 2),
    ],
    isStateVariant: true,
  ),
  const _PassageElementSpec(
    id: 'el_selbrume_passage_borne',
    name: 'Borne du Passage des Dames',
    source: TilesetSourceRect(x: 8, y: 0, width: 1, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1)],
  ),
  const _PassageElementSpec(
    id: 'el_selbrume_passage_panneau',
    name: 'Panneau du Passage des Dames',
    source: TilesetSourceRect(x: 9, y: 0, width: 2, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1)],
  ),
  const _PassageElementSpec(
    id: 'el_selbrume_passage_chaussee_humide',
    name: 'Chaussee humide du Passage',
    source: TilesetSourceRect(x: 11, y: 0, width: 4, height: 2),
    layerId: 'l_tile_ground',
  ),
  const _PassageElementSpec(
    id: 'el_selbrume_passage_ecume_h',
    name: 'Ecume horizontale du Passage',
    source: TilesetSourceRect(x: 0, y: 3, width: 4, height: 1),
    layerId: 'l_tile_fx',
  ),
  const _PassageElementSpec(
    id: 'el_selbrume_passage_ecume_v',
    name: 'Ecume verticale du Passage',
    source: TilesetSourceRect(x: 4, y: 3, width: 1, height: 4),
    layerId: 'l_tile_fx',
  ),
  const _PassageElementSpec(
    id: 'el_selbrume_passage_algues',
    name: 'Algues du Passage des Dames',
    source: TilesetSourceRect(x: 5, y: 3, width: 3, height: 1),
    layerId: 'l_tile_ground',
  ),
  const _PassageElementSpec(
    id: 'el_selbrume_passage_balanes',
    name: 'Balanes du Passage des Dames',
    source: TilesetSourceRect(x: 8, y: 3, width: 2, height: 1),
    layerId: 'l_tile_ground',
  ),
  const _PassageElementSpec(
    id: 'el_selbrume_passage_bois_flotte',
    name: 'Bois flotte du Passage des Dames',
    source: TilesetSourceRect(x: 10, y: 3, width: 3, height: 2),
    layerId: 'l_tile_ground',
  ),
  const _PassageElementSpec(
    id: 'el_selbrume_passage_marches',
    name: 'Marches du Passage des Dames',
    source: TilesetSourceRect(x: 13, y: 3, width: 3, height: 2),
    layerId: 'l_tile_ground',
  ),
  const _PassageElementSpec(
    id: 'el_selbrume_passage_chaussee_seche',
    name: 'Chaussee seche du Passage',
    source: TilesetSourceRect(x: 5, y: 5, width: 6, height: 3),
    layerId: 'l_tile_ground',
  ),
  const _PassageElementSpec(
    id: 'el_selbrume_passage_flaques',
    name: 'Flaques du Passage des Dames',
    source: TilesetSourceRect(x: 11, y: 5, width: 3, height: 2),
    layerId: 'l_tile_ground',
  ),
  const _PassageElementSpec(
    id: 'el_selbrume_passage_banc_brume',
    name: 'Banc de brume du Passage des Dames',
    source: TilesetSourceRect(x: 0, y: 8, width: 8, height: 4),
    layerId: 'l_tile_fx',
  ),
];

final Set<String> _task11PassageElementIds = <String>{
  for (final spec in _passageElementSpecs) spec.id,
};

final List<_MarshElementSpec> _marshElementSpecs = <_MarshElementSpec>[
  const _MarshElementSpec(
    id: 'el_selbrume_marais_cabane_paludier',
    name: 'Cabane du paludier',
    source: TilesetSourceRect(x: 0, y: 0, width: 5, height: 5),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 1, y: 0),
      GridPos(x: 2, y: 0),
      GridPos(x: 3, y: 0),
      GridPos(x: 4, y: 0),
      GridPos(x: 0, y: 1),
      GridPos(x: 4, y: 1),
      GridPos(x: 0, y: 2),
      GridPos(x: 4, y: 2),
      GridPos(x: 0, y: 3),
      GridPos(x: 4, y: 3),
      GridPos(x: 0, y: 4),
      GridPos(x: 1, y: 4),
      GridPos(x: 3, y: 4),
      GridPos(x: 4, y: 4),
    ],
    occlusionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 1, y: 0),
      GridPos(x: 2, y: 0),
      GridPos(x: 3, y: 0),
      GridPos(x: 4, y: 0),
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
      GridPos(x: 3, y: 1),
      GridPos(x: 4, y: 1),
      GridPos(x: 0, y: 2),
      GridPos(x: 1, y: 2),
      GridPos(x: 2, y: 2),
      GridPos(x: 3, y: 2),
      GridPos(x: 4, y: 2),
      GridPos(x: 0, y: 3),
      GridPos(x: 1, y: 3),
      GridPos(x: 2, y: 3),
      GridPos(x: 3, y: 3),
      GridPos(x: 4, y: 3),
    ],
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_marais_passerelle_h',
    name: 'Passerelle horizontale du marais',
    source: TilesetSourceRect(x: 5, y: 0, width: 4, height: 2),
    layerId: 'l_tile_ground',
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_marais_passerelle_v',
    name: 'Passerelle verticale du marais',
    source: TilesetSourceRect(x: 9, y: 0, width: 2, height: 4),
    layerId: 'l_tile_ground',
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_marais_passerelle_angle',
    name: 'Passerelle en angle du marais',
    source: TilesetSourceRect(x: 11, y: 0, width: 3, height: 3),
    layerId: 'l_tile_ground',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 2),
      GridPos(x: 2, y: 2),
    ],
  ),
  _MarshElementSpec(
    id: 'el_selbrume_marais_ecluse_fermee',
    name: 'Ecluse fermee du marais',
    source: const TilesetSourceRect(x: 5, y: 3, width: 3, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: _fullGridCells(3, 2),
    isStateVariant: true,
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_marais_ecluse_ouverte',
    name: 'Ecluse ouverte du marais',
    source: TilesetSourceRect(x: 8, y: 4, width: 3, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 2, y: 0),
      GridPos(x: 0, y: 1),
      GridPos(x: 2, y: 1),
    ],
    isStateVariant: true,
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_marais_roseaux_1',
    name: 'Roseaux du marais 1',
    source: TilesetSourceRect(x: 11, y: 3, width: 2, height: 2),
    layerId: 'l_tile_ground',
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_marais_roseaux_2',
    name: 'Roseaux du marais 2',
    source: TilesetSourceRect(x: 13, y: 3, width: 3, height: 3),
    layerId: 'l_tile_ground',
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_marais_roseaux_3',
    name: 'Roseaux du marais 3',
    source: TilesetSourceRect(x: 0, y: 5, width: 2, height: 3),
    layerId: 'l_tile_ground',
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_marais_sel_petit',
    name: 'Petit tas de sel',
    source: TilesetSourceRect(x: 2, y: 5, width: 1, height: 1),
    layerId: 'l_tile_ground',
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_marais_sel_moyen',
    name: 'Tas de sel moyen',
    source: TilesetSourceRect(x: 3, y: 5, width: 2, height: 1),
    layerId: 'l_tile_ground',
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_marais_sel_grand',
    name: 'Grand tas de sel',
    source: TilesetSourceRect(x: 5, y: 6, width: 3, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ],
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_marais_rateau',
    name: 'Rateau de paludier',
    source: TilesetSourceRect(x: 8, y: 6, width: 2, height: 2),
    layerId: 'l_tile_ground',
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_indice_verre',
    name: 'Indice de verre',
    source: TilesetSourceRect(x: 10, y: 6, width: 1, height: 1),
    layerId: 'l_tile_ground',
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_indice_traces_electriques',
    name: 'Traces electriques',
    source: TilesetSourceRect(x: 11, y: 6, width: 2, height: 1),
    layerId: 'l_tile_fx',
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_indice_repere_lentille',
    name: 'Repere de lentille',
    source: TilesetSourceRect(x: 13, y: 6, width: 1, height: 1),
    layerId: 'l_tile_ground',
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_cristal_1',
    name: 'Cristal du marais 1',
    source: TilesetSourceRect(x: 10, y: 7, width: 1, height: 1),
    layerId: 'l_tile_fx',
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_cristal_2',
    name: 'Cristal du marais 2',
    source: TilesetSourceRect(x: 11, y: 7, width: 1, height: 1),
    layerId: 'l_tile_fx',
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_cristal_3',
    name: 'Cristal du marais 3',
    source: TilesetSourceRect(x: 12, y: 7, width: 1, height: 1),
    layerId: 'l_tile_fx',
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_marais_passerelle_t',
    name: 'Passerelle en T du marais',
    source: TilesetSourceRect(x: 0, y: 8, width: 4, height: 3),
    layerId: 'l_tile_ground',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 3, y: 0),
      GridPos(x: 0, y: 1),
      GridPos(x: 3, y: 1),
    ],
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_marais_roseaux_4',
    name: 'Roseaux du marais 4',
    source: TilesetSourceRect(x: 4, y: 8, width: 2, height: 2),
    layerId: 'l_tile_ground',
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_marais_roseaux_5',
    name: 'Roseaux du marais 5',
    source: TilesetSourceRect(x: 6, y: 8, width: 3, height: 2),
    layerId: 'l_tile_ground',
  ),
  const _MarshElementSpec(
    id: 'el_selbrume_marais_roseaux_6',
    name: 'Roseaux du marais 6',
    source: TilesetSourceRect(x: 9, y: 8, width: 2, height: 3),
    layerId: 'l_tile_ground',
  ),
];

final Set<String> _task10MarshElementIds = <String>{
  for (final spec in _marshElementSpecs) spec.id,
};

final List<_ForestElementSpec> _forestElementSpecs = <_ForestElementSpec>[
  const _ForestElementSpec(
    id: 'el_selbrume_bois_pin_grand',
    name: 'Grand pin de la Chaise-Brume',
    source: TilesetSourceRect(x: 0, y: 0, width: 6, height: 8),
    layerId: 'l_tile_overhead',
    collisionCells: <GridPos>[
      GridPos(x: 2, y: 6),
      GridPos(x: 3, y: 6),
      GridPos(x: 2, y: 7),
      GridPos(x: 3, y: 7),
    ],
    hasCanopy: true,
  ),
  const _ForestElementSpec(
    id: 'el_selbrume_bois_pin_moyen',
    name: 'Pin moyen de la Chaise-Brume',
    source: TilesetSourceRect(x: 6, y: 0, width: 5, height: 7),
    layerId: 'l_tile_overhead',
    collisionCells: <GridPos>[
      GridPos(x: 2, y: 5),
      GridPos(x: 2, y: 6),
    ],
    hasCanopy: true,
  ),
  const _ForestElementSpec(
    id: 'el_selbrume_bois_pin_petit',
    name: 'Petit pin de la Chaise-Brume',
    source: TilesetSourceRect(x: 11, y: 0, width: 4, height: 6),
    layerId: 'l_tile_overhead',
    collisionCells: <GridPos>[GridPos(x: 1, y: 5)],
    hasCanopy: true,
  ),
  const _ForestElementSpec(
    id: 'el_selbrume_bois_buisson_1',
    name: 'Buisson forestier 1',
    source: TilesetSourceRect(x: 0, y: 8, width: 3, height: 2),
    layerId: 'l_tile_ground',
  ),
  const _ForestElementSpec(
    id: 'el_selbrume_bois_buisson_2',
    name: 'Buisson forestier 2',
    source: TilesetSourceRect(x: 3, y: 8, width: 3, height: 2),
    layerId: 'l_tile_ground',
  ),
  const _ForestElementSpec(
    id: 'el_selbrume_bois_fougere',
    name: 'Fougere forestiere',
    source: TilesetSourceRect(x: 6, y: 8, width: 2, height: 1),
    layerId: 'l_tile_ground',
  ),
  const _ForestElementSpec(
    id: 'el_selbrume_bois_souche',
    name: 'Souche forestiere',
    source: TilesetSourceRect(x: 8, y: 8, width: 2, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ],
  ),
  const _ForestElementSpec(
    id: 'el_selbrume_bois_tronc_tombe',
    name: 'Tronc tombe forestier',
    source: TilesetSourceRect(x: 10, y: 8, width: 4, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
      GridPos(x: 3, y: 1),
    ],
  ),
  const _ForestElementSpec(
    id: 'el_selbrume_bois_ronces',
    name: 'Ronces forestieres',
    source: TilesetSourceRect(x: 0, y: 10, width: 3, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
    ],
  ),
  const _ForestElementSpec(
    id: 'el_selbrume_bois_aiguilles_sol',
    name: 'Aiguilles de pin au sol',
    source: TilesetSourceRect(x: 3, y: 10, width: 2, height: 1),
    layerId: 'l_tile_ground',
  ),
  const _ForestElementSpec(
    id: 'el_selbrume_bois_banc',
    name: 'Banc forestier',
    source: TilesetSourceRect(x: 5, y: 10, width: 3, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
      GridPos(x: 2, y: 1),
    ],
  ),
  const _ForestElementSpec(
    id: 'el_selbrume_bois_panneau',
    name: 'Panneau forestier',
    source: TilesetSourceRect(x: 8, y: 10, width: 2, height: 2),
    layerId: 'l_tile_structures',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1)],
  ),
];

final Set<String> _task9ForestElementIds = <String>{
  for (final spec in _forestElementSpecs) spec.id,
};

final List<_CabinElementSpec> _cabinElementSpecs = <_CabinElementSpec>[
  const _CabinElementSpec(
    id: 'el_selbrume_cabane_sol_bois',
    name: 'Plancher bois Selbrume',
    source: TilesetSourceRect(x: 0, y: 0, width: 4, height: 4),
    layerId: 'l_tile_floor',
  ),
  _CabinElementSpec(
    id: 'el_selbrume_cabane_mur_n',
    name: 'Mur nord de cabane',
    source: const TilesetSourceRect(x: 4, y: 0, width: 4, height: 2),
    layerId: 'l_tile_walls',
    collisionCells: _fullGridCells(4, 2),
  ),
  _CabinElementSpec(
    id: 'el_selbrume_cabane_mur_cote',
    name: 'Mur lateral de cabane',
    source: const TilesetSourceRect(x: 8, y: 0, width: 2, height: 4),
    layerId: 'l_tile_walls',
    collisionCells: _fullGridCells(2, 4),
  ),
  _CabinElementSpec(
    id: 'el_selbrume_cabane_lit',
    name: 'Lit de la cabane',
    source: const TilesetSourceRect(x: 10, y: 0, width: 2, height: 3),
    layerId: 'l_tile_furniture',
    collisionCells: _fullGridCells(2, 3),
  ),
  const _CabinElementSpec(
    id: 'el_selbrume_cabane_table_carnet_ferme',
    name: 'Table et carnet ferme',
    source: TilesetSourceRect(x: 0, y: 4, width: 2, height: 2),
    layerId: 'l_tile_furniture',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1), GridPos(x: 1, y: 1)],
    isStateVariant: true,
  ),
  const _CabinElementSpec(
    id: 'el_selbrume_cabane_table_carnet_ouvert',
    name: 'Table et carnet ouvert',
    source: TilesetSourceRect(x: 2, y: 4, width: 2, height: 2),
    layerId: 'l_tile_furniture',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1), GridPos(x: 1, y: 1)],
    isStateVariant: true,
  ),
  const _CabinElementSpec(
    id: 'el_selbrume_cabane_poele',
    name: 'Poele de la cabane',
    source: TilesetSourceRect(x: 4, y: 4, width: 2, height: 3),
    layerId: 'l_tile_furniture',
    collisionCells: <GridPos>[GridPos(x: 0, y: 2), GridPos(x: 1, y: 2)],
  ),
  _CabinElementSpec(
    id: 'el_selbrume_cabane_etagere',
    name: 'Etagere interieure',
    source: const TilesetSourceRect(x: 6, y: 4, width: 2, height: 3),
    layerId: 'l_tile_furniture',
    collisionCells: _fullGridCells(2, 3),
  ),
  const _CabinElementSpec(
    id: 'el_selbrume_cabane_coffre',
    name: 'Coffre de la cabane',
    source: TilesetSourceRect(x: 8, y: 4, width: 2, height: 2),
    layerId: 'l_tile_furniture',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1), GridPos(x: 1, y: 1)],
  ),
  const _CabinElementSpec(
    id: 'el_selbrume_cabane_carte',
    name: 'Carte murale',
    source: TilesetSourceRect(x: 10, y: 4, width: 2, height: 2),
    layerId: 'l_tile_walls',
  ),
  const _CabinElementSpec(
    id: 'el_selbrume_cabane_cle',
    name: 'Cle de la cabane',
    source: TilesetSourceRect(x: 12, y: 4),
    layerId: 'l_tile_floor',
  ),
  const _CabinElementSpec(
    id: 'el_selbrume_cabane_outils',
    name: 'Outils de gardien',
    source: TilesetSourceRect(x: 13, y: 4, width: 2, height: 2),
    layerId: 'l_tile_furniture',
  ),
  const _CabinElementSpec(
    id: 'el_selbrume_cabane_lanterne',
    name: 'Lanterne de cabane',
    source: TilesetSourceRect(x: 0, y: 7, width: 1, height: 2),
    layerId: 'l_tile_overhead',
  ),
  _CabinElementSpec(
    id: 'el_selbrume_cabane_porte_secondaire_fermee',
    name: 'Porte secondaire fermee',
    source: const TilesetSourceRect(x: 1, y: 7, width: 2, height: 3),
    layerId: 'l_tile_walls',
    collisionCells: _fullGridCells(2, 3),
    isStateVariant: true,
  ),
  const _CabinElementSpec(
    id: 'el_selbrume_cabane_porte_secondaire_ouverte',
    name: 'Porte secondaire ouverte',
    source: TilesetSourceRect(x: 3, y: 7, width: 2, height: 3),
    layerId: 'l_tile_walls',
    isStateVariant: true,
  ),
  _CabinElementSpec(
    id: 'el_selbrume_maison_lit',
    name: 'Lit de la maison du joueur',
    source: const TilesetSourceRect(x: 5, y: 7, width: 2, height: 3),
    layerId: 'l_tile_furniture',
    collisionCells: _fullGridCells(2, 3),
  ),
  const _CabinElementSpec(
    id: 'el_selbrume_maison_bureau',
    name: 'Bureau de la maison du joueur',
    source: TilesetSourceRect(x: 7, y: 7, width: 2, height: 2),
    layerId: 'l_tile_furniture',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1), GridPos(x: 1, y: 1)],
  ),
  const _CabinElementSpec(
    id: 'el_selbrume_maison_tapis',
    name: 'Tapis de la maison du joueur',
    source: TilesetSourceRect(x: 9, y: 7, width: 3, height: 2),
    layerId: 'l_tile_floor',
  ),
  const _CabinElementSpec(
    id: 'el_selbrume_cabane_porte_principale',
    name: 'Porte principale interieure',
    source: TilesetSourceRect(x: 12, y: 7, width: 2, height: 3),
    layerId: 'l_tile_walls',
  ),
  const _CabinElementSpec(
    id: 'el_selbrume_cabane_chaise',
    name: 'Chaise de cabane',
    source: TilesetSourceRect(x: 14, y: 7, width: 1, height: 2),
    layerId: 'l_tile_furniture',
    collisionCells: <GridPos>[GridPos(x: 0, y: 1)],
  ),
];

final Set<String> _task8CabinElementIds = <String>{
  for (final spec in _cabinElementSpecs) spec.id,
};

List<GridPos> _fullGridCells(int width, int height) => <GridPos>[
      for (var y = 0; y < height; y += 1)
        for (var x = 0; x < width; x += 1) GridPos(x: x, y: y),
    ];

const String _usage = 'Usage: dart run '
    'tool/generate_selbrume_canonical_maps.dart '
    '--project-root <selbrume-directory> '
    '[--validate-authored | '
    '--through task4|task5|task6|task7|task8|task9|task10|task11|task12|task13|task14|task15|task16 '
    '[--check|--write-historical]]';
