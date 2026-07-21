import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

const canonicalSelbrumeDialogueIds = <String>{
  'dialogue_mael_intro',
  'dialogue_port_alert',
  'dialogue_lysa_port',
  'dialogue_mado',
  'dialogue_soline',
  'dialogue_marais_clues',
  'dialogue_lighthouse',
  'dialogue_ending_port',
  'dialogue_goelise_port',
  'dialogue_yvon_cabin',
  'dialogue_mael_after_mission',
  'dialogue_mael_epilogue',
  'dialogue_lysa_after_loss',
  'dialogue_mado_after_crystals',
  'dialogue_soline_after_passage',
  'dialogue_soline_epilogue',
  'dialogue_fisher_after_return',
  'dialogue_fisher_after_keep',
  'dialogue_fisher_epilogue',
  'dialogue_yvon_after_cabin',
};

const canonicalSelbrumeCinematicIds = <String>{
  'cinematic_port_panic',
  'cinematic_port_reassure',
  'cinematic_rival_smiles',
  'cinematic_rival_teases',
  'cinematic_rival_depart_win',
  'cinematic_rival_depart_loss',
  'cinematic_marais_first_fog',
  'cinematic_crystal_glow',
  'cinematic_passage_revealed',
  'cinematic_lighthouse_arrival',
  'cinematic_lighthouse_light_unstable',
  'cinematic_mist_disperses',
  'cinematic_port_celebration',
  'cinematic_lighthouse_final_beam',
};

const canonicalSelbrumeSceneIds = <String>{
  'scene_mael_intro',
  'scene_port_entry',
  'scene_port_alert',
  'scene_lysa_port',
  'scene_rival_after_win',
  'scene_rival_after_loss',
  'scene_marais_entry',
  'scene_mado_intro',
  'scene_mado_crystals_return',
  'scene_soline_unlock_passage',
  'scene_clue_electric_tracks',
  'scene_clue_lighthouse_mark',
  'scene_crystal_1',
  'scene_crystal_2',
  'scene_crystal_3',
  'scene_goelise_fisher_intro',
  'scene_goelise_nest_choice',
  'scene_goelise_return',
  'scene_goelise_keep_reward',
  'scene_yvon_intro',
  'scene_cabin_key',
  'scene_cabin_journal',
  'scene_lighthouse_arrival',
  'scene_lighthouse_old_note',
  'scene_lighthouse_guardian_1',
  'scene_lighthouse_guardian_2',
  'scene_final_pokemon',
  'scene_mist_disperses',
  'scene_ending_port',
};

const canonicalSelbrumeFactIds = <String>{
  'fact_main_story_started',
  'fact_mael_intro_done',
  'fact_starter_received',
  'fact_player_started_with_existing_pokemon',
  'fact_mael_mission_given',
  'fact_port_alert_seen',
  'fact_port_crowd_panicked',
  'fact_port_crowd_reassured',
  'fact_rival_port_defeated',
  'fact_rival_port_lost_once',
  'fact_lysa_respects_player',
  'fact_lysa_goes_ahead',
  'fact_lysa_tone_confident',
  'fact_lysa_tone_hesitant',
  'fact_lysa_tone_aggressive',
  'fact_marais_unlocked',
  'fact_mado_met',
  'fact_clue_glass_found',
  'fact_clue_electric_tracks_found',
  'fact_clue_lighthouse_mark_found',
  'fact_all_clues_found',
  'fact_passage_dames_unlocked',
  'fact_lighthouse_reached',
  'fact_lighthouse_old_note_read',
  'fact_lighthouse_top_unlocked',
  'fact_lighthouse_pokemon_appeased',
  'fact_mist_source_resolved',
  'fact_ending_seen',
  'fact_main_story_completed',
  'fact_crystals_quest_started',
  'fact_crystal_1_found',
  'fact_crystal_2_found',
  'fact_crystal_3_found',
  'fact_all_crystals_found',
  'fact_crystals_quest_completed',
  'fact_goelise_quest_started',
  'fact_goelise_nest_found',
  'fact_goelise_object_returned',
  'fact_goelise_object_kept',
  'fact_goelise_quest_completed',
  'fact_cabin_quest_started',
  'fact_cabin_key_found',
  'fact_cabin_opened',
  'fact_cabin_journal_read',
  'fact_cabin_quest_completed',
  'fact_lighthouse_guardian_1_defeated',
  'fact_lighthouse_guardian_2_defeated',
};

const _eventMael = 'evt_019abcde-5000-7000-8000-000000000011';
const _eventMaraisEntry = 'evt_019abcde-5000-7000-8000-000000000012';
const _eventMadoIntro = 'evt_019abcde-5000-7000-8000-000000000013';
const _eventClueElectric = 'evt_019abcde-5000-7000-8000-000000000014';
const _eventClueLens = 'evt_019abcde-5000-7000-8000-000000000015';
const _eventSoline = 'evt_019abcde-5000-7000-8000-000000000016';
const _eventCrystal1 = 'evt_019abcde-5000-7000-8000-000000000017';
const _eventCrystal2 = 'evt_019abcde-5000-7000-8000-000000000018';
const _eventCrystal3 = 'evt_019abcde-5000-7000-8000-000000000019';
const _eventFisherIntro = 'evt_019abcde-5000-7000-8000-000000000020';
const _eventFisherReturn = 'evt_019abcde-5000-7000-8000-000000000021';
const _eventNest = 'evt_019abcde-5000-7000-8000-000000000022';
const _eventLighthouseEntry = 'evt_019abcde-5000-7000-8000-000000000023';
const _eventYvon = 'evt_019abcde-5000-7000-8000-000000000024';
const _eventLighthouseNote = 'evt_019abcde-5000-7000-8000-000000000025';
const _eventGuardian1 = 'evt_019abcde-5000-7000-8000-000000000026';
const _eventGuardian2 = 'evt_019abcde-5000-7000-8000-000000000027';
const _eventBoss = 'evt_019abcde-5000-7000-8000-000000000028';
const _eventCabinKey = 'evt_019abcde-5000-7000-8000-000000000029';
const _eventCabinJournal = 'evt_019abcde-5000-7000-8000-000000000030';
const _eventEnding = 'evt_019abcde-5000-7000-8000-000000000031';
const _eventMadoReturn = 'evt_019abcde-5000-7000-8000-000000000032';
const _eventRivalAfterWin = 'evt_019abcde-5000-7000-8000-000000000033';
const _eventRivalAfterLoss = 'evt_019abcde-5000-7000-8000-000000000034';
const _eventFisherKeepReward = 'evt_019abcde-5000-7000-8000-000000000035';
const _eventMistDisperses = 'evt_019abcde-5000-7000-8000-000000000036';

const _prettyJson = JsonEncoder.withIndent('  ');
const selbrumeNarrativeSeedAuthoringContract = 'canonicalSeedAutomation';
const selbrumeNarrativeHumanWorkflowProof =
    'test/selbrume_narrative_reconstruction_test.dart';

final class SelbrumeNarrativeSeedResult {
  const SelbrumeNarrativeSeedResult({
    required this.changedRelativePaths,
    this.authoringContract = selbrumeNarrativeSeedAuthoringContract,
    this.humanWorkflowProof = selbrumeNarrativeHumanWorkflowProof,
  });

  final List<String> changedRelativePaths;
  final String authoringContract;
  final String humanWorkflowProof;
}

Future<void> main(List<String> arguments) async {
  var check = false;
  Directory? projectRoot;
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument == '--check') {
      check = true;
    } else if (argument == '--project-root' && index + 1 < arguments.length) {
      projectRoot = Directory(arguments[++index]);
    } else {
      stderr.writeln(
        'Usage: dart run tool/seed_selbrume_canonical_narrative_content.dart '
        '[--project-root PATH] [--check]',
      );
      exitCode = 64;
      return;
    }
  }
  final root =
      projectRoot ?? Directory(p.join(_findRepositoryRoot().path, 'selbrume'));
  final result = await seedSelbrumeCanonicalNarrativeContent(
    root,
    write: !check,
  );
  if (result.changedRelativePaths.isEmpty) {
    stdout.writeln('Selbrume canonical narrative content is up to date.');
    return;
  }
  stdout.writeln(
    '${result.changedRelativePaths.length} fichier(s) à mettre à jour :',
  );
  for (final path in result.changedRelativePaths) {
    stdout.writeln('- $path');
  }
  if (check) exitCode = 1;
}

Future<SelbrumeNarrativeSeedResult> seedSelbrumeCanonicalNarrativeContent(
  Directory projectRoot, {
  bool write = true,
}) async {
  final projectFile = File(p.join(projectRoot.path, 'project.json'));
  if (!projectFile.existsSync()) {
    throw StateError('Missing Selbrume manifest: ${projectFile.path}');
  }
  final project = _readJson(projectFile);

  _seedCharacters(project);
  _upsertProjectEntries(
    project,
    'trainers',
    _canonicalTrainers().map((entry) => entry.toJson()).toList(),
  );
  _upsertProjectEntries(
    project,
    'dialogues',
    _canonicalDialogues().map((entry) => entry.toJson()).toList(),
  );
  _upsertProjectEntries(
    project,
    'cinematics',
    _canonicalCinematics().map((entry) => entry.toJson()).toList(),
  );
  _upsertProjectEntries(
    project,
    'facts',
    _canonicalFacts().map((entry) => entry.toJson()).toList(),
  );
  _upsertProjectEntries(
    project,
    'scenes',
    _canonicalScenes().map((entry) => entry.toJson()).toList(),
  );
  _upsertProjectEntries(
    project,
    'worldRules',
    _canonicalWorldRules().map((entry) => entry.toJson()).toList(),
  );
  _repairSupersededLegacyContent(project);
  _seedNewGameConfig(project);
  _seedEventRegistry(project);
  _seedStorylineLinks(project);
  _seedCapabilityMarkers(project);

  final authoredFiles = <String, String>{
    'project.json': '${_prettyJson.convert(project)}\n',
  };
  for (final entry in _canonicalYarnFiles.entries) {
    authoredFiles[p.join('dialogues', entry.key)] = entry.value;
  }

  final manifest = ProjectManifest.fromJson(project);
  ProjectValidator.validate(manifest);
  for (final mapId in const <String>[
    'map_bourg_selbrume',
    'map_port_brisants',
    'map_marais_salants',
    'map_phare_exterieur',
    'map_phare_interieur',
    'map_bois_chaise_brume',
    'map_passage_dames',
    'map_sommet_phare',
    'map_cabane_gardien',
  ]) {
    final relativePath =
        manifest.maps.singleWhere((entry) => entry.id == mapId).relativePath;
    final mapJson = _readJson(File(p.join(projectRoot.path, relativePath)));
    _seedMap(mapId, mapJson);
    final map = MapData.fromJson(mapJson);
    MapValidator.validate(map, projectDialogueContext: manifest);
    authoredFiles[relativePath] = '${_prettyJson.convert(mapJson)}\n';
  }

  final changed = <String>[];
  for (final entry in authoredFiles.entries) {
    final file = File(p.join(projectRoot.path, entry.key));
    final before = file.existsSync() ? file.readAsStringSync() : null;
    if (before == entry.value) continue;
    changed.add(p.posix.normalize(entry.key.replaceAll('\\', '/')));
    if (write) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value, flush: true);
    }
  }
  changed.sort();
  return SelbrumeNarrativeSeedResult(
    changedRelativePaths: List<String>.unmodifiable(changed),
  );
}

void _repairSupersededLegacyContent(Map<String, dynamic> project) {
  for (final rule in _jsonObjects(project['worldRules'])) {
    if (rule['id'] != 'world_rule_lysa_port_resolved') continue;
    final source = _jsonObjectOrEmpty(rule['source']);
    source['sourceId'] = 'fact_rival_port_defeated';
    rule['source'] = source;
    rule['description'] =
        'Compatibilité migrée vers le Fact canonique de victoire contre Lysa.';
  }

  for (final cinematic in _jsonObjects(project['cinematics'])) {
    if (cinematic['id'] != 'cinematic_uwu') continue;
    final timeline = _jsonObjectOrEmpty(cinematic['timeline']);
    for (final step in _jsonObjects(timeline['steps'])) {
      if (step['id'] != 'step_actor_move_2') continue;
      final metadata = _jsonObjectOrEmpty(step['metadata']);
      if (metadata['actor.pathMode'] == 'manual') {
        metadata['actor.pathMode'] = 'direct';
      }
      step['metadata'] = metadata;
    }
    cinematic['timeline'] = timeline;
  }
}

void _seedCharacters(Map<String, dynamic> project) {
  final characters = _jsonObjects(project['characters']);
  Map<String, dynamic> cloneCharacter(
    String sourceId,
    String id,
    String name,
  ) {
    final source = characters.singleWhere((entry) => entry['id'] == sourceId);
    final copy = _deepCopy(source);
    copy['id'] = id;
    copy['name'] = name;
    copy['tags'] = <String>['selbrume', 'canonical-narrative'];
    return copy;
  }

  final mael = cloneCharacter('mael', 'mael', 'Maël');
  final lysa = cloneCharacter('character_lysa', 'character_lysa', 'Lysa');
  _upsertProjectEntries(project, 'characters', <Map<String, dynamic>>[
    mael,
    lysa,
    cloneCharacter('mael', 'character_mado', 'Mado'),
    cloneCharacter('rival', 'character_soline', 'Soline'),
    cloneCharacter('grant', 'character_yvon', 'Yvon'),
    cloneCharacter('rival', 'character_pecheur', 'Pêcheur de Selbrume'),
  ]);
}

List<ProjectTrainerEntry> _canonicalTrainers() => <ProjectTrainerEntry>[
      const ProjectTrainerEntry(
        id: 'trainer_lysa_port',
        name: 'Lysa du port',
        trainerClass: 'Rivale',
        battleDifficulty: 5,
        characterId: 'character_lysa',
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(
            speciesId: 'bulbasaur',
            level: 7,
            moves: <String>['tackle', 'growl'],
          ),
        ],
        tags: <String>['selbrume', 'chapter-1', 'canonical-narrative'],
      ),
      const ProjectTrainerEntry(
        id: 'trainer_phare_gardien_1',
        name: 'Écho électrique du phare',
        trainerClass: 'Écho de la brume',
        battleDifficulty: 4,
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(
            speciesId: 'magnemite',
            level: 10,
            moves: <String>['tackle', 'supersonic', 'thunder_shock'],
          ),
        ],
        tags: <String>['selbrume', 'chapter-3', 'canonical-narrative'],
      ),
      const ProjectTrainerEntry(
        id: 'trainer_phare_gardien_2',
        name: 'Écho spectral du phare',
        trainerClass: 'Écho de la brume',
        battleDifficulty: 5,
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(
            speciesId: 'gastly',
            level: 11,
            moves: <String>['lick', 'hypnosis', 'night_shade'],
          ),
        ],
        tags: <String>['selbrume', 'chapter-3', 'canonical-narrative'],
      ),
      const ProjectTrainerEntry(
        id: 'trainer_boss_phare_pokemon',
        name: 'Lanturn affolé du phare',
        trainerClass: 'Pokémon du phare',
        battleDifficulty: 7,
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(
            speciesId: 'lanturn',
            level: 14,
            moves: <String>[
              'bubble',
              'supersonic',
              'thunder_wave',
              'water_gun',
            ],
          ),
        ],
        tags: <String>[
          'selbrume',
          'chapter-3',
          'boss',
          'static-encounter',
          'canonical-narrative',
        ],
      ),
    ];

List<ProjectDialogueEntry> _canonicalDialogues() =>
    const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'dialogue_mael_intro',
        name: 'Maël — introduction et mission',
        relativePath: 'dialogues/mael_intro.yarn',
        defaultStartNode: 'MaelIntro',
        description:
            'Introduction de Selbrume et choix guidé du compagnon initial.',
        declaredOutcomes: <DialogueDeclaredOutcome>[
          DialogueDeclaredOutcome(
            id: 'starter_bulbasaur',
            label: 'Choisir Bulbizarre',
          ),
          DialogueDeclaredOutcome(
            id: 'starter_charmander',
            label: 'Choisir Salamèche',
          ),
          DialogueDeclaredOutcome(
            id: 'starter_squirtle',
            label: 'Choisir Carapuce',
          ),
        ],
        tags: <String>['selbrume', 'chapter-1', 'canonical-narrative'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_port_alert',
        name: 'Alerte au Port des Brisants',
        relativePath: 'dialogues/port_alert.yarn',
        defaultStartNode: 'PortAlert',
        description: 'La foule découvre la montée anormale de la brume.',
        declaredOutcomes: <DialogueDeclaredOutcome>[
          DialogueDeclaredOutcome(id: 'panic', label: 'Paniquer'),
          DialogueDeclaredOutcome(id: 'reassure', label: 'Rassurer'),
        ],
        tags: <String>['selbrume', 'chapter-1', 'canonical-narrative'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_lysa_port',
        name: 'Lysa au port',
        relativePath: 'dialogues/lysa_port.yarn',
        defaultStartNode: 'LysaPort',
        description: 'Rencontre, provocation et suites du combat contre Lysa.',
        declaredOutcomes: <DialogueDeclaredOutcome>[
          DialogueDeclaredOutcome(id: 'confident', label: 'Assuré'),
          DialogueDeclaredOutcome(id: 'hesitant', label: 'Prudent'),
          DialogueDeclaredOutcome(id: 'aggressive', label: 'Agressif'),
        ],
        tags: <String>['selbrume', 'chapter-1', 'golden-slice'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_mado',
        name: 'Mado des marais',
        relativePath: 'dialogues/mado.yarn',
        defaultStartNode: 'MadoIntro',
        description: 'Enquête et quête des cristaux de sel.',
        declaredOutcomes: <DialogueDeclaredOutcome>[
          DialogueDeclaredOutcome(id: 'accept_help', label: 'Accepter'),
          DialogueDeclaredOutcome(
            id: 'refuse_for_now',
            label: 'Refuser pour le moment',
          ),
        ],
        tags: <String>['selbrume', 'chapter-2', 'side-quest'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_soline',
        name: 'Soline et le Passage des Dames',
        relativePath: 'dialogues/soline.yarn',
        defaultStartNode: 'SolineClues',
        description: 'Validation des indices et ouverture du passage.',
        tags: <String>['selbrume', 'chapter-2', 'canonical-narrative'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_marais_clues',
        name: 'Indices des Marais Salants',
        relativePath: 'dialogues/marais_clues.yarn',
        defaultStartNode: 'ClueGlass',
        description: 'Textes des trois indices de la brume.',
        tags: <String>['selbrume', 'chapter-2', 'exploration'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_lighthouse',
        name: 'Le Vieux Phare d’Écume',
        relativePath: 'dialogues/lighthouse.yarn',
        defaultStartNode: 'LighthouseArrival',
        description: 'Notes du gardien et confrontation finale.',
        tags: <String>['selbrume', 'chapter-3', 'canonical-narrative'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_ending_port',
        name: 'Épilogue au port',
        relativePath: 'dialogues/ending_port.yarn',
        defaultStartNode: 'EndingPort',
        description: 'Conclusion de La brume du phare.',
        tags: <String>['selbrume', 'chapter-4', 'canonical-narrative'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_goelise_port',
        name: 'Le Goélise du port',
        relativePath: 'dialogues/goelise_port.yarn',
        defaultStartNode: 'FisherIntro',
        description: 'Quête du nid et choix moral léger.',
        declaredOutcomes: <DialogueDeclaredOutcome>[
          DialogueDeclaredOutcome(id: 'return_item', label: 'Rendre l’objet'),
          DialogueDeclaredOutcome(id: 'keep_item', label: 'Garder l’objet'),
        ],
        tags: <String>['selbrume', 'side-quest', 'choice-persistence'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_yvon_cabin',
        name: 'Yvon et la cabane du gardien',
        relativePath: 'dialogues/yvon_cabin.yarn',
        defaultStartNode: 'YvonCabin',
        description: 'Clé, cabane et carnet de l’ancien gardien.',
        declaredOutcomes: <DialogueDeclaredOutcome>[
          DialogueDeclaredOutcome(
            id: 'accept_search_key',
            label: 'Chercher la clé',
          ),
          DialogueDeclaredOutcome(
            id: 'ignore_for_now',
            label: 'Revenir plus tard',
          ),
        ],
        tags: <String>['selbrume', 'side-quest', 'lore'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_mael_after_mission',
        name: 'Maël — rappel de mission',
        relativePath: 'dialogues/mael_after_mission.yarn',
        defaultStartNode: 'MaelAfterMission',
        description: 'Rappel guidé après le départ vers le port.',
        tags: <String>['selbrume', 'world-state', 'post-progression'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_mael_epilogue',
        name: 'Maël — épilogue',
        relativePath: 'dialogues/mael_epilogue.yarn',
        defaultStartNode: 'MaelEpilogue',
        description: 'Réaction finale après la dissipation de la brume.',
        tags: <String>['selbrume', 'world-state', 'epilogue'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_lysa_after_loss',
        name: 'Lysa — après la défaite du joueur',
        relativePath: 'dialogues/lysa_after_loss.yarn',
        defaultStartNode: 'RivalAfterLoss',
        description: 'Moquerie douce persistante après la branche défaite.',
        tags: <String>['selbrume', 'world-state', 'post-progression'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_mado_after_crystals',
        name: 'Mado — cristaux retrouvés',
        relativePath: 'dialogues/mado_after_crystals.yarn',
        defaultStartNode: 'MadoCompleted',
        description: 'Réaction persistante après la quête des cristaux.',
        tags: <String>['selbrume', 'world-state', 'side-quest'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_soline_after_passage',
        name: 'Soline — passage ouvert',
        relativePath: 'dialogues/soline_after_passage.yarn',
        defaultStartNode: 'SolineAfterPassage',
        description: 'Rappel du chemin vers le phare.',
        tags: <String>['selbrume', 'world-state', 'post-progression'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_soline_epilogue',
        name: 'Soline — port apaisé',
        relativePath: 'dialogues/soline_epilogue.yarn',
        defaultStartNode: 'SolineEpilogue',
        description: 'Dialogue final après le retour des bateaux.',
        tags: <String>['selbrume', 'world-state', 'epilogue'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_fisher_after_return',
        name: 'Pêcheur — objet rendu',
        relativePath: 'dialogues/fisher_after_return.yarn',
        defaultStartNode: 'FisherAfterReturn',
        description: 'Confiance persistante après avoir rendu l’objet.',
        tags: <String>['selbrume', 'world-state', 'side-quest'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_fisher_after_keep',
        name: 'Pêcheur — objet gardé',
        relativePath: 'dialogues/fisher_after_keep.yarn',
        defaultStartNode: 'FisherAfterKeep',
        description: 'Méfiance persistante après avoir gardé l’objet.',
        tags: <String>['selbrume', 'world-state', 'side-quest'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_fisher_epilogue',
        name: 'Pêcheur — épilogue',
        relativePath: 'dialogues/fisher_epilogue.yarn',
        defaultStartNode: 'FisherEpilogue',
        description: 'Le pêcheur reprend la mer après la fin de la brume.',
        tags: <String>['selbrume', 'world-state', 'epilogue'],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_yvon_after_cabin',
        name: 'Yvon — carnet retrouvé',
        relativePath: 'dialogues/yvon_after_cabin.yarn',
        defaultStartNode: 'YvonAfterCabin',
        description: 'Réaction persistante après la lecture du carnet.',
        tags: <String>['selbrume', 'world-state', 'side-quest'],
      ),
    ];

List<CinematicAsset> _canonicalCinematics() {
  const definitions = <(String, String, String, String)>[
    (
      'cinematic_port_panic',
      'Panique sur les quais',
      'map_port_brisants',
      'chapter_1_port'
    ),
    (
      'cinematic_port_reassure',
      'Le port reprend son souffle',
      'map_port_brisants',
      'chapter_1_port'
    ),
    (
      'cinematic_rival_smiles',
      'Lysa sourit',
      'map_port_brisants',
      'chapter_1_port'
    ),
    (
      'cinematic_rival_teases',
      'Lysa provoque le joueur',
      'map_port_brisants',
      'chapter_1_port'
    ),
    (
      'cinematic_rival_depart_win',
      'Lysa part après la victoire',
      'map_port_brisants',
      'chapter_1_port'
    ),
    (
      'cinematic_rival_depart_loss',
      'Lysa ouvre la voie malgré la défaite',
      'map_port_brisants',
      'chapter_1_port'
    ),
    (
      'cinematic_marais_first_fog',
      'Première nappe de brume',
      'map_marais_salants',
      'chapter_2_marais'
    ),
    (
      'cinematic_crystal_glow',
      'Un cristal réagit à la brume',
      'map_marais_salants',
      'chapter_2_marais'
    ),
    (
      'cinematic_passage_revealed',
      'Le Passage des Dames apparaît',
      'map_port_brisants',
      'chapter_2_marais'
    ),
    (
      'cinematic_lighthouse_arrival',
      'Arrivée au Vieux Phare d’Écume',
      'map_phare_exterieur',
      'chapter_3_phare'
    ),
    (
      'cinematic_lighthouse_light_unstable',
      'La lentille vacille',
      'map_phare_interieur',
      'chapter_3_phare'
    ),
    (
      'cinematic_mist_disperses',
      'La brume se disperse',
      'map_sommet_phare',
      'chapter_3_phare'
    ),
    (
      'cinematic_port_celebration',
      'Selbrume célèbre le retour de la lumière',
      'map_port_brisants',
      'chapter_4_epilogue'
    ),
    (
      'cinematic_lighthouse_final_beam',
      'Le phare retrouve son faisceau',
      'map_port_brisants',
      'chapter_4_epilogue'
    ),
  ];
  return <CinematicAsset>[
    for (final definition in definitions)
      CinematicAsset(
        id: definition.$1,
        title: definition.$2,
        description: 'Beat cinématique canonique défini dans selbrume.md.',
        storylineId: 'story_main_brume_phare',
        chapterId: definition.$4,
        mapId: definition.$3,
        tags: const <String>['selbrume', 'canonical-narrative'],
        timeline: _canonicalCinematicTimeline(definition.$1, definition.$2),
        metadata: const <String, String>{
          'contentStatus': 'visual_runtime_v1',
          'source': 'selbrume.md',
        },
      ),
  ];
}

CinematicTimeline _canonicalCinematicTimeline(String id, String label) {
  final dramatic = id.contains('panic') ||
      id.contains('teases') ||
      id.contains('unstable') ||
      id.contains('fog');
  final reveal = id.contains('revealed') ||
      id.contains('disperses') ||
      id.contains('celebration') ||
      id.contains('beam');
  return CinematicTimeline(
    steps: <CinematicTimelineStep>[
      CinematicTimelineStep(
        id: '${id}_fade_out',
        kind: CinematicTimelineStepKind.fade,
        label: 'Transition — $label',
        durationMs: reveal ? 320 : 180,
        metadata: const <String, String>{
          cinematicTimelineFadeModeMetadataKey: 'fadeOut',
          'contentStatus': 'visual_runtime_v1',
        },
      ),
      CinematicTimelineStep(
        id: '${id}_establish',
        kind: dramatic
            ? CinematicTimelineStepKind.shake
            : CinematicTimelineStepKind.camera,
        label: label,
        durationMs: dramatic ? 420 : 360,
        metadata: dramatic
            ? const <String, String>{
                'contentStatus': 'visual_runtime_v1',
              }
            : const <String, String>{
                cinematicTimelineCameraModeMetadataKey: 'hold',
                'contentStatus': 'visual_runtime_v1',
              },
      ),
      CinematicTimelineStep(
        id: '${id}_breath',
        kind: CinematicTimelineStepKind.wait,
        label: 'Respiration visuelle',
        durationMs: reveal ? 420 : 180,
        metadata: const <String, String>{
          'contentStatus': 'visual_runtime_v1',
        },
      ),
      CinematicTimelineStep(
        id: '${id}_fade_in',
        kind: CinematicTimelineStepKind.fade,
        label: 'Retour au jeu — $label',
        durationMs: reveal ? 420 : 240,
        metadata: const <String, String>{
          cinematicTimelineFadeModeMetadataKey: 'fadeIn',
          'contentStatus': 'visual_runtime_v1',
        },
      ),
    ],
  );
}

List<NarrativeFactDefinition> _canonicalFacts() {
  const labels = <String, String>{
    'fact_main_story_started': 'L’histoire principale a commencé',
    'fact_mael_intro_done': 'Maël a présenté Selbrume',
    'fact_starter_received': 'Le starter a été reçu',
    'fact_player_started_with_existing_pokemon':
        'Le joueur arrive avec un Pokémon',
    'fact_mael_mission_given': 'Maël a confié la mission',
    'fact_port_alert_seen': 'L’alerte du port a été vue',
    'fact_port_crowd_panicked': 'La foule du port a paniqué',
    'fact_port_crowd_reassured': 'La foule du port a été rassurée',
    'fact_rival_port_defeated': 'Lysa a été vaincue au port',
    'fact_rival_port_lost_once': 'Le joueur a perdu une fois contre Lysa',
    'fact_lysa_respects_player': 'Lysa respecte le joueur',
    'fact_lysa_goes_ahead': 'Lysa est partie en éclaireuse',
    'fact_lysa_tone_confident': 'Le joueur a répondu à Lysa avec assurance',
    'fact_lysa_tone_hesitant': 'Le joueur est resté prudent face à Lysa',
    'fact_lysa_tone_aggressive': 'Le joueur a provoqué Lysa',
    'fact_marais_unlocked': 'Les Marais Salants sont accessibles',
    'fact_mado_met': 'Mado a été rencontrée',
    'fact_clue_glass_found': 'Le verre poli a été trouvé',
    'fact_clue_electric_tracks_found':
        'Les traces électriques ont été trouvées',
    'fact_clue_lighthouse_mark_found': 'Le repère de lentille a été trouvé',
    'fact_all_clues_found': 'Les trois indices ont été réunis',
    'fact_passage_dames_unlocked': 'Le Passage des Dames est ouvert',
    'fact_lighthouse_reached': 'Le Vieux Phare d’Écume a été atteint',
    'fact_lighthouse_old_note_read': 'L’ancienne note du phare a été lue',
    'fact_lighthouse_top_unlocked': 'Le sommet du phare est accessible',
    'fact_lighthouse_pokemon_appeased': 'Le Pokémon du phare a été apaisé',
    'fact_mist_source_resolved': 'La source de la brume est résolue',
    'fact_ending_seen': 'L’épilogue a été vu',
    'fact_main_story_completed': 'La brume du phare est terminée',
    'fact_crystals_quest_started': 'La quête des cristaux a commencé',
    'fact_crystal_1_found': 'Premier cristal de sel trouvé',
    'fact_crystal_2_found': 'Deuxième cristal de sel trouvé',
    'fact_crystal_3_found': 'Troisième cristal de sel trouvé',
    'fact_all_crystals_found': 'Les trois cristaux de sel sont réunis',
    'fact_crystals_quest_completed': 'La quête des cristaux est terminée',
    'fact_goelise_quest_started': 'La quête du Goélise a commencé',
    'fact_goelise_nest_found': 'Le nid du Goélise a été trouvé',
    'fact_goelise_object_returned': 'L’objet brillant a été rendu',
    'fact_goelise_object_kept': 'L’objet brillant a été gardé',
    'fact_goelise_quest_completed': 'La quête du Goélise est terminée',
    'fact_cabin_quest_started': 'La quête de la cabane a commencé',
    'fact_cabin_key_found': 'La clé de la cabane a été trouvée',
    'fact_cabin_opened': 'La cabane du gardien a été ouverte',
    'fact_cabin_journal_read': 'Le carnet du gardien a été lu',
    'fact_cabin_quest_completed': 'La quête de la cabane est terminée',
    'fact_lighthouse_guardian_1_defeated':
        'Le premier écho du phare est dissipé',
    'fact_lighthouse_guardian_2_defeated':
        'Le second écho du phare est dissipé',
  };
  return <NarrativeFactDefinition>[
    for (final entry in labels.entries)
      NarrativeFactDefinition(
        id: entry.key,
        label: entry.value,
        description: _factDescription(entry.key),
        category: _factCategory(entry.key),
        defaultValue: false,
        tags: const <String>['selbrume', 'canonical-narrative'],
      ),
  ];
}

String _factCategory(String id) {
  if (id.contains('crystal')) return 'Quête — Cristaux de sel';
  if (id.contains('goelise')) return 'Quête — Goélise du port';
  if (id.contains('cabin')) return 'Quête — Cabane du phare';
  if (id.contains('clue')) return 'Histoire — Enquête';
  if (id.contains('lighthouse') || id.contains('mist')) {
    return 'Histoire — Phare';
  }
  return 'Histoire principale';
}

String _factDescription(String id) {
  if (id == 'fact_starter_received') {
    return 'Le compagnon choisi a été remis par une conséquence Scene typée.';
  }
  if (id == 'fact_player_started_with_existing_pokemon') {
    return 'Dérivé automatiquement de la party initiale par le contrat New Game.';
  }
  if (id == 'fact_goelise_object_returned' ||
      id == 'fact_goelise_object_kept') {
    return 'Choix persistant produit par un outcome Yarn typé.';
  }
  return 'État narratif canonique issu de MVP Selbrume/selbrume.md.';
}

List<SceneAsset> _canonicalScenes() => <SceneAsset>[
      _maelNewGameScene(),
      _choiceScene(
        id: 'scene_port_entry',
        name: 'Première entrée au Port des Brisants',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_1_port',
        description:
            'Implémentation exécutable du déclencheur de port existant.',
        dialogue: _dialogueBeat(
          'dialogue_port_alert',
          'PortAlert',
          <String>['character_soline', 'character_pecheur'],
          expectedOutcomes: const <String>['panic', 'reassure'],
        ),
        fallbackOutcomeId: 'panic',
        branches: <String, List<_SceneBeat>>{
          'panic': <_SceneBeat>[
            _cinematicBeat('cinematic_port_panic'),
            _factBeat(
              'fact_port_crowd_panicked',
              'Mémoriser la panique du port',
            ),
          ],
          'reassure': <_SceneBeat>[
            _cinematicBeat('cinematic_port_reassure'),
            _factBeat('fact_port_crowd_reassured', 'Rassurer la foule du port'),
          ],
        },
        commonTail: <_SceneBeat>[
          _factBeat('fact_port_alert_seen', 'Mémoriser l’alerte du port'),
          _stepBeat('step_go_to_port', 'Terminer le trajet vers le port'),
        ],
      ),
      _choiceScene(
        id: 'scene_port_alert',
        name: 'Alerte au port',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_1_port',
        description:
            'Scene canonique consultable ; le déclencheur historique reste lié à scene_port_entry.',
        dialogue: _dialogueBeat(
          'dialogue_port_alert',
          'PortAlert',
          <String>['character_soline', 'character_pecheur'],
          expectedOutcomes: const <String>['panic', 'reassure'],
        ),
        fallbackOutcomeId: 'panic',
        branches: <String, List<_SceneBeat>>{
          'panic': <_SceneBeat>[
            _cinematicBeat('cinematic_port_panic'),
            _factBeat(
              'fact_port_crowd_panicked',
              'Mémoriser la panique du port',
            ),
          ],
          'reassure': <_SceneBeat>[
            _cinematicBeat('cinematic_port_reassure'),
            _factBeat('fact_port_crowd_reassured', 'Rassurer la foule du port'),
          ],
        },
      ),
      _lysaToneBattleScene(),
      _linearScene(
        id: 'scene_rival_after_win',
        name: 'Lysa après la victoire du joueur',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_1_port',
        beats: <_SceneBeat>[
          _cinematicBeat('cinematic_rival_smiles'),
          _dialogueBeat(
            'dialogue_lysa_port',
            'RivalAfterWin',
            <String>['character_lysa'],
          ),
          _factBeat(
              'fact_rival_port_defeated', 'Mémoriser la victoire contre Lysa'),
          _factBeat('fact_lysa_respects_player', 'Gagner le respect de Lysa'),
          _factBeat('fact_lysa_goes_ahead', 'Envoyer Lysa en éclaireuse'),
          _cinematicBeat('cinematic_rival_depart_win'),
          _stepBeat('step_rival_battle', 'Faire converger la branche victoire'),
        ],
      ),
      _linearScene(
        id: 'scene_rival_after_loss',
        name: 'Lysa après la défaite du joueur',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_1_port',
        beats: <_SceneBeat>[
          _cinematicBeat('cinematic_rival_teases'),
          _dialogueBeat(
            'dialogue_lysa_port',
            'RivalAfterLoss',
            <String>['character_lysa'],
          ),
          _factBeat(
              'fact_rival_port_lost_once', 'Mémoriser la défaite contre Lysa'),
          _factBeat('fact_lysa_goes_ahead', 'Envoyer Lysa en éclaireuse'),
          _cinematicBeat('cinematic_rival_depart_loss'),
          _stepBeat('step_rival_battle', 'Faire converger la branche défaite'),
        ],
      ),
      _linearScene(
        id: 'scene_marais_entry',
        name: 'Entrée dans les Marais Salants',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_2_marais',
        beats: <_SceneBeat>[
          _cinematicBeat('cinematic_marais_first_fog'),
          _factBeat('fact_marais_unlocked', 'Déverrouiller les marais'),
          _stepBeat('step_enter_marais', 'Terminer l’entrée dans les marais'),
        ],
      ),
      _choiceScene(
        id: 'scene_mado_intro',
        name: 'Rencontre avec Mado',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_2_marais',
        dialogue: _dialogueBeat(
          'dialogue_mado',
          'MadoIntro',
          <String>['character_mado'],
          expectedOutcomes: const <String>['accept_help', 'refuse_for_now'],
        ),
        fallbackOutcomeId: 'accept_help',
        branches: <String, List<_SceneBeat>>{
          'accept_help': <_SceneBeat>[
            _factBeat('fact_mado_met', 'Mémoriser la rencontre avec Mado'),
            _factBeat(
              'fact_crystals_quest_started',
              'Démarrer la quête des cristaux',
            ),
            _stepBeat(
              'step_crystals_talk_to_mado',
              'Terminer la discussion avec Mado',
            ),
          ],
          'refuse_for_now': <_SceneBeat>[
            _factBeat('fact_mado_met', 'Mémoriser la rencontre avec Mado'),
          ],
        },
      ),
      _linearScene(
        id: 'scene_mado_crystals_return',
        name: 'Rapporter les cristaux à Mado',
        storylineId: 'story_side_salt_crystals',
        chapterId: 'chapter_salt_crystals',
        description: 'Mado remet une Super Potion de manière persistante.',
        beats: <_SceneBeat>[
          _dialogueBeat(
              'dialogue_mado', 'MadoReturn', <String>['character_mado']),
          _giveItemBeat(
            'super-potion',
            1,
            'Recevoir une Super Potion de Mado',
          ),
          _factBeat('fact_all_crystals_found', 'Réunir les trois cristaux'),
          _factBeat('fact_crystals_quest_completed',
              'Terminer la quête des cristaux'),
          _stepBeat('step_crystals_collect_three', 'Terminer la collecte'),
          _stepBeat('step_crystals_return_to_mado', 'Rapporter les cristaux'),
          _stepBeat('step_crystals_completed', 'Clore la quête des cristaux'),
        ],
        metadata: const <String, String>{
          'rewardStatus': 'runtime_scene_consequence_bound',
        },
      ),
      _linearScene(
        id: 'scene_clue_glass',
        name: 'Indice du verre poli',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_2_marais',
        beats: <_SceneBeat>[
          _dialogueBeat('dialogue_marais_clues', 'ClueGlass', const <String>[]),
          _factBeat('fact_clue_glass_found', 'Trouver le verre poli'),
        ],
      ),
      _linearScene(
        id: 'scene_clue_electric_tracks',
        name: 'Indice des traces électriques',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_2_marais',
        beats: <_SceneBeat>[
          _dialogueBeat(
              'dialogue_marais_clues', 'ClueElectric', const <String>[]),
          _factBeat('fact_clue_electric_tracks_found',
              'Trouver les traces électriques'),
        ],
      ),
      _linearScene(
        id: 'scene_clue_lighthouse_mark',
        name: 'Indice du repère de lentille',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_2_marais',
        beats: <_SceneBeat>[
          _dialogueBeat('dialogue_marais_clues', 'ClueLens', const <String>[]),
          _factBeat('fact_clue_lighthouse_mark_found',
              'Trouver le repère de lentille'),
        ],
      ),
      _linearScene(
        id: 'scene_soline_unlock_passage',
        name: 'Soline ouvre le Passage des Dames',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_2_marais',
        beats: <_SceneBeat>[
          _dialogueBeat(
              'dialogue_soline', 'SolineClues', <String>['character_soline']),
          _factBeat('fact_all_clues_found', 'Réunir les trois indices'),
          _factBeat(
              'fact_passage_dames_unlocked', 'Ouvrir le Passage des Dames'),
          _cinematicBeat('cinematic_passage_revealed'),
          _stepBeat(
              'step_find_three_clues', 'Terminer la recherche des indices'),
          _stepBeat('step_report_to_soline', 'Terminer le rapport à Soline'),
        ],
      ),
      _crystalScene(1),
      _crystalScene(2),
      _crystalScene(3),
      _linearScene(
        id: 'scene_goelise_fisher_intro',
        name: 'Le pêcheur demande de l’aide',
        storylineId: 'story_side_goelise_port',
        chapterId: 'chapter_goelise_port',
        beats: <_SceneBeat>[
          _dialogueBeat('dialogue_goelise_port', 'FisherIntro',
              <String>['character_pecheur']),
          _factBeat(
              'fact_goelise_quest_started', 'Démarrer la quête du Goélise'),
          _stepBeat('step_goelise_talk_to_fisher',
              'Terminer la discussion avec le pêcheur'),
        ],
      ),
      _choiceScene(
        id: 'scene_goelise_nest_choice',
        name: 'Le nid du Goélise',
        storylineId: 'story_side_goelise_port',
        chapterId: 'chapter_goelise_port',
        description: 'Le choix Yarn persiste une décision morale distincte.',
        dialogue: _dialogueBeat(
          'dialogue_goelise_port',
          'GoeliseChoice',
          const <String>[],
          expectedOutcomes: const <String>['return_item', 'keep_item'],
        ),
        fallbackOutcomeId: 'return_item',
        branches: <String, List<_SceneBeat>>{
          'return_item': <_SceneBeat>[
            _factBeat(
              'fact_goelise_object_returned',
              'Rendre l’objet brillant',
            ),
          ],
          'keep_item': <_SceneBeat>[
            _factBeat(
              'fact_goelise_object_kept',
              'Garder l’objet brillant',
            ),
          ],
        },
        commonTail: <_SceneBeat>[
          _factBeat('fact_goelise_nest_found', 'Trouver le nid du Goélise'),
          _stepBeat('step_goelise_find_nest', 'Terminer la recherche du nid'),
          _stepBeat('step_goelise_choice', 'Valider le choix du Goélise'),
        ],
      ),
      _linearScene(
        id: 'scene_goelise_return',
        name: 'Rendre l’objet au pêcheur',
        storylineId: 'story_side_goelise_port',
        chapterId: 'chapter_goelise_port',
        beats: <_SceneBeat>[
          _dialogueBeat('dialogue_goelise_port', 'FisherReturn',
              <String>['character_pecheur']),
          _giveMoneyBeat(300, 'Recevoir 300 ₽ des pêcheurs'),
          _factBeat(
              'fact_goelise_quest_completed', 'Terminer la quête du Goélise'),
          _stepBeat('step_goelise_choice', 'Valider le choix du Goélise'),
          _stepBeat('step_goelise_return', 'Retourner voir le pêcheur'),
          _stepBeat('step_goelise_completed', 'Clore la quête du Goélise'),
        ],
      ),
      _linearScene(
        id: 'scene_goelise_keep_reward',
        name: 'Assumer le choix auprès du pêcheur',
        storylineId: 'story_side_goelise_port',
        chapterId: 'chapter_goelise_port',
        beats: <_SceneBeat>[
          _dialogueBeat('dialogue_goelise_port', 'FisherSuspicious',
              <String>['character_pecheur']),
          _giveItemBeat(
            'pearl',
            1,
            'Conserver la perle trouvée dans le nid',
          ),
          _factBeat(
              'fact_goelise_quest_completed', 'Terminer la quête du Goélise'),
          _stepBeat('step_goelise_choice', 'Valider le choix du Goélise'),
          _stepBeat('step_goelise_return', 'Retourner voir le pêcheur'),
          _stepBeat('step_goelise_completed', 'Clore la quête du Goélise'),
        ],
      ),
      _choiceScene(
        id: 'scene_yvon_intro',
        name: 'Yvon parle de la cabane du gardien',
        storylineId: 'story_side_lighthouse_cabin',
        chapterId: 'chapter_lighthouse_cabin',
        description:
            'Yvon laisse le joueur accepter la recherche ou revenir plus tard.',
        dialogue: _dialogueBeat(
          'dialogue_yvon_cabin',
          'YvonCabin',
          <String>['character_yvon'],
          expectedOutcomes: const <String>[
            'accept_search_key',
            'ignore_for_now',
          ],
        ),
        fallbackOutcomeId: 'ignore_for_now',
        branches: <String, List<_SceneBeat>>{
          'accept_search_key': <_SceneBeat>[
            _factBeat(
              'fact_cabin_quest_started',
              'Démarrer la quête de la cabane',
            ),
            _stepBeat(
              'step_cabin_talk_to_yvon',
              'Terminer la discussion avec Yvon',
            ),
          ],
          'ignore_for_now': const <_SceneBeat>[],
        },
      ),
      _linearScene(
        id: 'scene_cabin_key',
        name: 'Trouver la clé de la cabane',
        storylineId: 'story_side_lighthouse_cabin',
        chapterId: 'chapter_lighthouse_cabin',
        beats: <_SceneBeat>[
          _dialogueBeat('dialogue_yvon_cabin', 'CabinKey', const <String>[]),
          _giveItemBeat(
            'basement-key',
            1,
            'Ramasser la clé de la cabane',
          ),
          _factBeat('fact_cabin_key_found', 'Trouver la clé de la cabane'),
          _stepBeat('step_cabin_find_key', 'Terminer la recherche de la clé'),
        ],
      ),
      _linearScene(
        id: 'scene_cabin_journal',
        name: 'Lire le carnet du gardien',
        storylineId: 'story_side_lighthouse_cabin',
        chapterId: 'chapter_lighthouse_cabin',
        beats: <_SceneBeat>[
          _factBeat('fact_cabin_opened', 'Ouvrir la cabane du gardien'),
          _dialogueBeat(
              'dialogue_yvon_cabin', 'CabinJournal', const <String>[]),
          _giveItemBeat(
            'rare-candy',
            1,
            'Trouver le Super Bonbon d’Yvon',
          ),
          _factBeat('fact_cabin_journal_read', 'Lire le carnet du gardien'),
          _factBeat(
              'fact_cabin_quest_completed', 'Terminer la quête de la cabane'),
          _stepBeat('step_cabin_open_door', 'Ouvrir la porte'),
          _stepBeat('step_cabin_read_journal', 'Lire le carnet'),
          _stepBeat('step_cabin_completed', 'Clore la quête de la cabane'),
        ],
      ),
      _linearScene(
        id: 'scene_lighthouse_arrival',
        name: 'Arrivée au Vieux Phare d’Écume',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_3_phare',
        beats: <_SceneBeat>[
          _cinematicBeat('cinematic_lighthouse_arrival'),
          _dialogueBeat(
              'dialogue_lighthouse', 'LighthouseArrival', const <String>[]),
          _factBeat('fact_lighthouse_reached', 'Atteindre le phare'),
          _stepBeat(
              'step_reach_lighthouse', 'Terminer le trajet vers le phare'),
        ],
      ),
      _linearScene(
        id: 'scene_lighthouse_old_note',
        name: 'L’ancienne note du gardien',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_3_phare',
        beats: <_SceneBeat>[
          _dialogueBeat(
              'dialogue_lighthouse', 'LighthouseOldNote', const <String>[]),
          _cinematicBeat('cinematic_lighthouse_light_unstable'),
          _factBeat('fact_lighthouse_old_note_read', 'Lire la note du phare'),
        ],
      ),
      _battleScene(
        id: 'scene_lighthouse_guardian_1',
        name: 'Premier écho du phare',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_3_phare',
        trainerId: 'trainer_phare_gardien_1',
        victoryOutcomeId: 'lighthouse.guardian_1.victory',
        defeatOutcomeId: 'lighthouse.guardian_1.defeat',
        victoryBeats: <_SceneBeat>[
          _factBeat('fact_lighthouse_guardian_1_defeated',
              'Dissiper le premier écho'),
        ],
      ),
      _battleScene(
        id: 'scene_lighthouse_guardian_2',
        name: 'Second écho du phare',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_3_phare',
        trainerId: 'trainer_phare_gardien_2',
        victoryOutcomeId: 'lighthouse.guardian_2.victory',
        defeatOutcomeId: 'lighthouse.guardian_2.defeat',
        victoryBeats: <_SceneBeat>[
          _factBeat(
              'fact_lighthouse_guardian_2_defeated', 'Dissiper le second écho'),
          _factBeat('fact_lighthouse_top_unlocked',
              'Déverrouiller le sommet du phare'),
          _stepBeat('step_climb_lighthouse', 'Terminer l’exploration du phare'),
        ],
      ),
      _battleScene(
        id: 'scene_final_pokemon',
        name: 'Apaiser le Pokémon du phare',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_3_phare',
        trainerId: 'trainer_boss_phare_pokemon',
        battleKind: 'static',
        battleTemplateId: 'battle_lighthouse_pokemon',
        npcEntityId: 'boss_phare_pokemon',
        victoryOutcomeId: 'lighthouse.pokemon.appeased',
        defeatOutcomeId: 'lighthouse.pokemon.defeat',
        openingBeats: <_SceneBeat>[
          _dialogueBeat(
              'dialogue_lighthouse', 'FinalPokemon', const <String>[]),
        ],
        victoryBeats: <_SceneBeat>[
          _factBeat('fact_lighthouse_pokemon_appeased',
              'Apaiser le Pokémon du phare'),
          _factBeat(
              'fact_mist_source_resolved', 'Résoudre la source de la brume'),
          _stepBeat(
              'step_final_confrontation', 'Terminer la confrontation finale'),
        ],
      ),
      _linearScene(
        id: 'scene_mist_disperses',
        name: 'La brume se disperse',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_3_phare',
        beats: <_SceneBeat>[
          _cinematicBeat('cinematic_mist_disperses'),
          _dialogueBeat(
            'dialogue_lighthouse',
            'MistDisperses',
            const <String>['mael'],
          ),
        ],
        endOutcome: SceneOutcome(
          id: 'mist_resolved',
          label: 'La brume est dissipée',
        ),
      ),
      _linearScene(
        id: 'scene_ending_port',
        name: 'Épilogue au Port des Brisants',
        storylineId: 'story_main_brume_phare',
        chapterId: 'chapter_4_epilogue',
        beats: <_SceneBeat>[
          _cinematicBeat('cinematic_port_celebration'),
          _dialogueBeat('dialogue_ending_port', 'EndingPort', <String>[
            'mael',
            'character_lysa',
            'character_soline',
          ]),
          _cinematicBeat('cinematic_lighthouse_final_beam'),
          _factBeat('fact_ending_seen', 'Voir l’épilogue'),
          _factBeat('fact_main_story_completed', 'Terminer La brume du phare'),
          _stepBeat('step_return_to_port', 'Terminer le retour au port'),
          _stepBeat('step_main_story_completed', 'Clore l’histoire principale'),
        ],
      ),
    ];

SceneAsset _crystalScene(int index) => _linearScene(
      id: 'scene_crystal_$index',
      name: 'Cristal de sel $index',
      storylineId: 'story_side_salt_crystals',
      chapterId: 'chapter_salt_crystals',
      beats: <_SceneBeat>[
        _cinematicBeat('cinematic_crystal_glow'),
        _factBeat('fact_crystal_${index}_found', 'Trouver le cristal $index'),
      ],
    );

final class _SceneBeat {
  const _SceneBeat(this.title, this.payload);

  final String title;
  final SceneNodePayload payload;
}

_SceneBeat _dialogueBeat(
  String dialogueId,
  String node,
  List<String> speakers, {
  List<String> expectedOutcomes = const <String>[],
}) =>
    _SceneBeat(
      'Dialogue — $node',
      SceneYarnDialoguePayload(
        dialogueId: dialogueId,
        yarnNodeName: node,
        speakerHints: speakers,
        expectedOutcomes: expectedOutcomes,
      ),
    );

_SceneBeat _cinematicBeat(String cinematicId) => _SceneBeat(
      'Cinématique — $cinematicId',
      SceneCinematicPayload(cinematicId: cinematicId),
    );

_SceneBeat _factBeat(String factId, String label) => _SceneBeat(
      label,
      SceneActionPayload.consequence(
        SceneConsequence.setFact(factId: factId, value: true, label: label),
      ),
    );

_SceneBeat _stepBeat(String stepId, String label) => _SceneBeat(
      label,
      SceneActionPayload.consequence(
        SceneConsequence.completeStoryStep(stepId: stepId, label: label),
      ),
    );

_SceneBeat _giveConfiguredStarterBeat({
  required String starterOptionId,
  required String label,
}) =>
    _SceneBeat(
      label,
      SceneActionPayload.consequence(
        SceneConsequence.giveConfiguredStarter(
          starterOptionId: starterOptionId,
          label: label,
        ),
      ),
    );

_SceneBeat _giveItemBeat(String itemId, int quantity, String label) =>
    _SceneBeat(
      label,
      SceneActionPayload.consequence(
        SceneConsequence.giveItem(
          itemId: itemId,
          quantity: quantity,
          label: label,
        ),
      ),
    );

_SceneBeat _giveMoneyBeat(int amount, String label) => _SceneBeat(
      label,
      SceneActionPayload.consequence(
        SceneConsequence.giveMoney(amount: amount, label: label),
      ),
    );

SceneAsset _maelNewGameScene() {
  final nodes = <SceneNode>[
    SceneNode(id: 'node_start', kind: SceneNodeKind.start, title: 'Début'),
    SceneNode(
      id: 'node_party_condition',
      kind: SceneNodeKind.condition,
      title: 'Le joueur possède déjà un Pokémon ?',
      payload: SceneConditionPayload(
        conditionLabel: 'Équipe présente au démarrage',
        conditionSource: SceneConditionSource(
          sourceKind: SceneConditionSourceKind.fact,
          sourceId: 'fact_player_started_with_existing_pokemon',
          operator: SceneConditionOperator.isTrue,
          label: 'Le joueur arrive avec un Pokémon',
        ),
      ),
    ),
    SceneNode(
      id: 'node_existing_dialogue',
      kind: SceneNodeKind.yarnDialogue,
      title: 'Maël vérifie le compagnon existant',
      payload: SceneYarnDialoguePayload(
        dialogueId: 'dialogue_mael_intro',
        yarnNodeName: 'MaelExistingPokemon',
        speakerHints: const <String>['mael'],
      ),
    ),
    SceneNode(
      id: 'node_starter_dialogue',
      kind: SceneNodeKind.yarnDialogue,
      title: 'Maël propose trois compagnons',
      payload: SceneYarnDialoguePayload(
        dialogueId: 'dialogue_mael_intro',
        yarnNodeName: 'MaelStarterChoice',
        expectedOutcomes: const <String>[
          'starter_bulbasaur',
          'starter_charmander',
          'starter_squirtle',
        ],
        speakerHints: const <String>['mael'],
      ),
    ),
    SceneNode(
      id: 'node_give_bulbasaur',
      kind: SceneNodeKind.action,
      title: 'Recevoir Bulbizarre',
      payload: _giveConfiguredStarterBeat(
        starterOptionId: 'starter_bulbasaur',
        label: 'Maël confie Bulbizarre',
      ).payload,
    ),
    SceneNode(
      id: 'node_give_charmander',
      kind: SceneNodeKind.action,
      title: 'Recevoir Salamèche',
      payload: _giveConfiguredStarterBeat(
        starterOptionId: 'starter_charmander',
        label: 'Maël confie Salamèche',
      ).payload,
    ),
    SceneNode(
      id: 'node_give_squirtle',
      kind: SceneNodeKind.action,
      title: 'Recevoir Carapuce',
      payload: _giveConfiguredStarterBeat(
        starterOptionId: 'starter_squirtle',
        label: 'Maël confie Carapuce',
      ).payload,
    ),
    SceneNode(
      id: 'node_starter_received',
      kind: SceneNodeKind.action,
      title: 'Mémoriser le starter',
      payload: _factBeat(
        'fact_starter_received',
        'Mémoriser le compagnon reçu',
      ).payload,
    ),
    SceneNode(
      id: 'node_main_started',
      kind: SceneNodeKind.action,
      title: 'Démarrer l’histoire principale',
      payload: _factBeat(
        'fact_main_story_started',
        'Démarrer l’histoire principale',
      ).payload,
    ),
    SceneNode(
      id: 'node_intro_done',
      kind: SceneNodeKind.action,
      title: 'Mémoriser la rencontre',
      payload: _factBeat(
        'fact_mael_intro_done',
        'Mémoriser la rencontre avec Maël',
      ).payload,
    ),
    SceneNode(
      id: 'node_mission_given',
      kind: SceneNodeKind.action,
      title: 'Confier la mission',
      payload: _factBeat(
        'fact_mael_mission_given',
        'Confier la mission du phare',
      ).payload,
    ),
    SceneNode(
      id: 'node_intro_step',
      kind: SceneNodeKind.action,
      title: 'Terminer l’introduction',
      payload: _stepBeat(
        'step_intro_selbrume',
        'Terminer l’introduction',
      ).payload,
    ),
    SceneNode(
      id: 'node_mission_step',
      kind: SceneNodeKind.action,
      title: 'Terminer la mission de Maël',
      payload: _stepBeat(
        'step_receive_mission',
        'Terminer la mission de Maël',
      ).payload,
    ),
    SceneNode(id: 'node_end', kind: SceneNodeKind.end, title: 'Fin'),
  ];
  final edges = <SceneEdge>[
    SceneEdge(
      id: 'edge_start_condition',
      fromNodeId: 'node_start',
      fromPortId: 'completed',
      toNodeId: 'node_party_condition',
      kind: SceneEdgeKind.defaultFlow,
    ),
    SceneEdge(
      id: 'edge_condition_existing',
      fromNodeId: 'node_party_condition',
      fromPortId: 'true',
      toNodeId: 'node_existing_dialogue',
      kind: SceneEdgeKind.conditionTrue,
    ),
    SceneEdge(
      id: 'edge_condition_starter',
      fromNodeId: 'node_party_condition',
      fromPortId: 'false',
      toNodeId: 'node_starter_dialogue',
      kind: SceneEdgeKind.conditionFalse,
    ),
    SceneEdge(
      id: 'edge_existing_common',
      fromNodeId: 'node_existing_dialogue',
      fromPortId: 'completed',
      toNodeId: 'node_main_started',
      kind: SceneEdgeKind.defaultFlow,
    ),
    for (final branch in const <(String, String)>[
      ('starter_bulbasaur', 'node_give_bulbasaur'),
      ('starter_charmander', 'node_give_charmander'),
      ('starter_squirtle', 'node_give_squirtle'),
      ('completed', 'node_give_bulbasaur'),
    ])
      SceneEdge(
        id: 'edge_starter_${branch.$1}',
        fromNodeId: 'node_starter_dialogue',
        fromPortId: branch.$1,
        toNodeId: branch.$2,
        kind: branch.$1 == 'completed'
            ? SceneEdgeKind.defaultFlow
            : SceneEdgeKind.dialogueOutcome,
      ),
    for (final nodeId in const <String>[
      'node_give_bulbasaur',
      'node_give_charmander',
      'node_give_squirtle',
    ])
      SceneEdge(
        id: 'edge_${nodeId}_received',
        fromNodeId: nodeId,
        fromPortId: 'completed',
        toNodeId: 'node_starter_received',
        kind: SceneEdgeKind.actionCompleted,
      ),
    SceneEdge(
      id: 'edge_received_common',
      fromNodeId: 'node_starter_received',
      fromPortId: 'completed',
      toNodeId: 'node_main_started',
      kind: SceneEdgeKind.actionCompleted,
    ),
  ];
  _appendLinearEdges(
    edges,
    nodes
        .where((node) => const <String>{
              'node_main_started',
              'node_intro_done',
              'node_mission_given',
              'node_intro_step',
              'node_mission_step',
              'node_end',
            }.contains(node.id))
        .toList(growable: false),
  );
  return SceneAsset(
    id: 'scene_mael_intro',
    name: 'Maël prépare le départ vers le port',
    description:
        'Les configurations party vide et party existante convergent ici.',
    storylineId: 'story_main_brume_phare',
    chapterId: 'chapter_1_port',
    tags: const <String>['selbrume', 'canonical-narrative', 'new-game'],
    graph: SceneGraph(startNodeId: 'node_start', nodes: nodes, edges: edges),
    layout: SceneGraphLayout(
      nodeLayouts: <SceneNodeLayout>[
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 220),
        SceneNodeLayout(nodeId: 'node_party_condition', x: 304, y: 220),
        SceneNodeLayout(nodeId: 'node_existing_dialogue', x: 584, y: 40),
        SceneNodeLayout(nodeId: 'node_starter_dialogue', x: 584, y: 300),
        SceneNodeLayout(nodeId: 'node_give_bulbasaur', x: 864, y: 220),
        SceneNodeLayout(nodeId: 'node_give_charmander', x: 864, y: 360),
        SceneNodeLayout(nodeId: 'node_give_squirtle', x: 864, y: 500),
        SceneNodeLayout(nodeId: 'node_starter_received', x: 1144, y: 360),
        for (final indexed in const <String>[
          'node_main_started',
          'node_intro_done',
          'node_mission_given',
          'node_intro_step',
          'node_mission_step',
          'node_end',
        ].indexed)
          SceneNodeLayout(
            nodeId: indexed.$2,
            x: (1424 + indexed.$1 * 280).toDouble(),
            y: 220,
          ),
      ],
    ),
    metadata: const <String, String>{
      'source': 'MVP Selbrume/selbrume.md',
      'contentStatus': 'runtime_authored',
      'newGameContract': 'party_empty_or_existing_converges',
    },
  );
}

SceneAsset _linearScene({
  required String id,
  required String name,
  required String storylineId,
  required String chapterId,
  required List<_SceneBeat> beats,
  String? description,
  SceneOutcome? endOutcome,
  Map<String, String> metadata = const <String, String>{},
}) {
  final nodes = <SceneNode>[
    SceneNode(id: 'node_start', kind: SceneNodeKind.start, title: 'Début'),
    for (var index = 0; index < beats.length; index++)
      SceneNode(
        id: 'node_${index + 1}',
        kind: beats[index].payload.kind,
        title: beats[index].title,
        payload: beats[index].payload,
      ),
    SceneNode(
      id: 'node_end',
      kind: SceneNodeKind.end,
      title: 'Fin',
      payload: endOutcome == null
          ? null
          : SceneEndPayload(
              sceneOutcomeId: endOutcome.id,
              outcomePolicy: SceneOutcomePolicy.progression,
            ),
    ),
  ];
  final edges = <SceneEdge>[];
  for (var index = 0; index < nodes.length - 1; index++) {
    final from = nodes[index];
    final to = nodes[index + 1];
    final port = _completedPort(from.kind);
    edges.add(
      SceneEdge(
        id: 'edge_${from.id}_${to.id}',
        fromNodeId: from.id,
        fromPortId: port,
        toNodeId: to.id,
        kind: _completedEdgeKind(from.kind),
        label: port,
      ),
    );
  }
  return SceneAsset(
    id: id,
    name: name,
    description: description ?? 'Contenu canonique issu de selbrume.md.',
    storylineId: storylineId,
    chapterId: chapterId,
    tags: const <String>['selbrume', 'canonical-narrative'],
    graph: SceneGraph(startNodeId: 'node_start', nodes: nodes, edges: edges),
    layout: _layout(nodes),
    declaredOutcomes: endOutcome == null
        ? const <SceneOutcome>[]
        : <SceneOutcome>[endOutcome],
    metadata: <String, String>{
      'source': 'MVP Selbrume/selbrume.md',
      'contentStatus': 'runtime_authored',
      ...metadata,
    },
  );
}

SceneAsset _choiceScene({
  required String id,
  required String name,
  required String storylineId,
  required String chapterId,
  required _SceneBeat dialogue,
  required Map<String, List<_SceneBeat>> branches,
  required String fallbackOutcomeId,
  List<_SceneBeat> commonTail = const <_SceneBeat>[],
  String? description,
}) {
  if (!branches.containsKey(fallbackOutcomeId)) {
    throw ArgumentError.value(
      fallbackOutcomeId,
      'fallbackOutcomeId',
      'must identify one of the authored branches',
    );
  }
  final dialoguePayload = dialogue.payload;
  if (dialoguePayload is! SceneYarnDialoguePayload) {
    throw ArgumentError.value(
      dialogue,
      'dialogue',
      'must contain a Yarn dialogue payload',
    );
  }

  final startNode = SceneNode(
    id: 'node_start',
    kind: SceneNodeKind.start,
    title: 'Début',
  );
  final dialogueNode = SceneNode(
    id: 'node_dialogue',
    kind: SceneNodeKind.yarnDialogue,
    title: dialogue.title,
    payload: dialoguePayload,
  );
  final branchNodes = <String, List<SceneNode>>{
    for (final entry in branches.entries)
      entry.key: <SceneNode>[
        for (var index = 0; index < entry.value.length; index++)
          SceneNode(
            id: 'node_${entry.key}_${index + 1}',
            kind: entry.value[index].payload.kind,
            title: entry.value[index].title,
            payload: entry.value[index].payload,
          ),
      ],
  };
  final commonNodes = <SceneNode>[
    for (var index = 0; index < commonTail.length; index++)
      SceneNode(
        id: 'node_common_${index + 1}',
        kind: commonTail[index].payload.kind,
        title: commonTail[index].title,
        payload: commonTail[index].payload,
      ),
  ];
  final endNode = SceneNode(
    id: 'node_end',
    kind: SceneNodeKind.end,
    title: 'Fin',
  );
  final nodes = <SceneNode>[
    startNode,
    dialogueNode,
    ...branchNodes.values.expand((nodes) => nodes),
    ...commonNodes,
    endNode,
  ];
  final commonTarget = commonNodes.isEmpty ? endNode : commonNodes.first;
  final edges = <SceneEdge>[
    SceneEdge(
      id: 'edge_start_dialogue',
      fromNodeId: 'node_start',
      fromPortId: 'completed',
      toNodeId: 'node_dialogue',
      kind: SceneEdgeKind.defaultFlow,
      label: 'completed',
    ),
  ];
  for (final entry in branchNodes.entries) {
    final target = entry.value.isEmpty ? commonTarget : entry.value.first;
    edges.add(
      SceneEdge(
        id: 'edge_dialogue_${entry.key}',
        fromNodeId: dialogueNode.id,
        fromPortId: entry.key,
        toNodeId: target.id,
        kind: SceneEdgeKind.dialogueOutcome,
        label: entry.key,
      ),
    );
    _appendLinearEdges(edges, entry.value);
    if (entry.value.isNotEmpty) {
      final last = entry.value.last;
      edges.add(
        SceneEdge(
          id: 'edge_${last.id}_${commonTarget.id}',
          fromNodeId: last.id,
          fromPortId: _completedPort(last.kind),
          toNodeId: commonTarget.id,
          kind: _completedEdgeKind(last.kind),
          label: _completedPort(last.kind),
        ),
      );
    }
  }
  final fallbackNodes = branchNodes[fallbackOutcomeId]!;
  final fallbackTarget =
      fallbackNodes.isEmpty ? commonTarget : fallbackNodes.first;
  edges.add(
    SceneEdge(
      id: 'edge_dialogue_completed_fallback',
      fromNodeId: dialogueNode.id,
      fromPortId: 'completed',
      toNodeId: fallbackTarget.id,
      kind: SceneEdgeKind.defaultFlow,
      label: 'completed',
    ),
  );
  if (commonNodes.isNotEmpty) {
    _appendLinearEdges(edges, <SceneNode>[...commonNodes, endNode]);
  }

  return SceneAsset(
    id: id,
    name: name,
    description: description ?? 'Choix canonique issu de selbrume.md.',
    storylineId: storylineId,
    chapterId: chapterId,
    tags: const <String>['selbrume', 'canonical-narrative', 'choice'],
    graph: SceneGraph(startNodeId: startNode.id, nodes: nodes, edges: edges),
    layout: _choiceLayout(
      startNode: startNode,
      dialogueNode: dialogueNode,
      branchNodes: branchNodes,
      commonNodes: commonNodes,
      endNode: endNode,
    ),
    metadata: const <String, String>{
      'source': 'MVP Selbrume/selbrume.md',
      'contentStatus': 'runtime_authored',
      'choicePersistenceStatus': 'runtime_yarn_outcomes_bound',
    },
  );
}

SceneAsset _lysaToneBattleScene() {
  final dialoguePayload = SceneYarnDialoguePayload(
    dialogueId: 'dialogue_lysa_port',
    yarnNodeName: 'LysaPort',
    speakerHints: const <String>['character_lysa'],
    expectedOutcomes: const <String>[
      'confident',
      'hesitant',
      'aggressive',
    ],
  );
  final nodes = <SceneNode>[
    SceneNode(
      id: 'node_start',
      kind: SceneNodeKind.start,
      title: 'Début',
    ),
    SceneNode(
      id: 'node_dialogue',
      kind: SceneNodeKind.yarnDialogue,
      title: 'Dialogue avec Lysa',
      payload: dialoguePayload,
    ),
    SceneNode(
      id: 'node_confident_fact',
      kind: SceneNodeKind.action,
      title: 'Réponse assurée',
      payload: _factBeat(
        'fact_lysa_tone_confident',
        'Mémoriser la réponse assurée',
      ).payload,
    ),
    SceneNode(
      id: 'node_confident_cinematic',
      kind: SceneNodeKind.cinematic,
      title: 'Lysa sourit',
      payload: SceneCinematicPayload(cinematicId: 'cinematic_rival_smiles'),
    ),
    SceneNode(
      id: 'node_hesitant_fact',
      kind: SceneNodeKind.action,
      title: 'Réponse prudente',
      payload: _factBeat(
        'fact_lysa_tone_hesitant',
        'Mémoriser la réponse prudente',
      ).payload,
    ),
    SceneNode(
      id: 'node_aggressive_fact',
      kind: SceneNodeKind.action,
      title: 'Provocation',
      payload: _factBeat(
        'fact_lysa_tone_aggressive',
        'Mémoriser la provocation',
      ).payload,
    ),
    SceneNode(
      id: 'node_teases_cinematic',
      kind: SceneNodeKind.cinematic,
      title: 'Lysa réplique',
      payload: SceneCinematicPayload(cinematicId: 'cinematic_rival_teases'),
    ),
    SceneNode(
      id: 'node_battle',
      kind: SceneNodeKind.battle,
      title: 'Combat contre Lysa',
      payload: SceneBattlePayload(
        battleKind: 'trainer',
        trainerId: 'trainer_lysa_port',
        npcEntityId: 'npc_lysa',
        declaredOutcomes: const <String>['victory', 'defeat'],
      ),
    ),
    SceneNode(
      id: 'node_victory_end',
      kind: SceneNodeKind.end,
      title: 'Victoire contre Lysa',
      payload: SceneEndPayload(
        sceneOutcomeId: 'lysa.victory',
        outcomePolicy: SceneOutcomePolicy.progression,
      ),
    ),
    SceneNode(
      id: 'node_defeat_end',
      kind: SceneNodeKind.end,
      title: 'Défaite contre Lysa',
      payload: SceneEndPayload(
        sceneOutcomeId: 'lysa.defeat',
        outcomePolicy: SceneOutcomePolicy.terminalFailureAccepted,
      ),
    ),
  ];
  final edges = <SceneEdge>[
    SceneEdge(
      id: 'edge_start_dialogue',
      fromNodeId: 'node_start',
      fromPortId: 'completed',
      toNodeId: 'node_dialogue',
      kind: SceneEdgeKind.defaultFlow,
      label: 'completed',
    ),
    for (final entry in const <(String, String)>[
      ('confident', 'node_confident_fact'),
      ('hesitant', 'node_hesitant_fact'),
      ('aggressive', 'node_aggressive_fact'),
    ])
      SceneEdge(
        id: 'edge_dialogue_${entry.$1}',
        fromNodeId: 'node_dialogue',
        fromPortId: entry.$1,
        toNodeId: entry.$2,
        kind: SceneEdgeKind.dialogueOutcome,
        label: entry.$1,
      ),
    SceneEdge(
      id: 'edge_dialogue_completed_fallback',
      fromNodeId: 'node_dialogue',
      fromPortId: 'completed',
      toNodeId: 'node_hesitant_fact',
      kind: SceneEdgeKind.defaultFlow,
      label: 'completed',
    ),
    SceneEdge(
      id: 'edge_confident_fact_cinematic',
      fromNodeId: 'node_confident_fact',
      fromPortId: 'completed',
      toNodeId: 'node_confident_cinematic',
      kind: SceneEdgeKind.actionCompleted,
      label: 'completed',
    ),
    SceneEdge(
      id: 'edge_confident_cinematic_battle',
      fromNodeId: 'node_confident_cinematic',
      fromPortId: 'completed',
      toNodeId: 'node_battle',
      kind: SceneEdgeKind.cinematicCompleted,
      label: 'completed',
    ),
    for (final nodeId in const <String>[
      'node_hesitant_fact',
      'node_aggressive_fact',
    ])
      SceneEdge(
        id: 'edge_${nodeId}_teases',
        fromNodeId: nodeId,
        fromPortId: 'completed',
        toNodeId: 'node_teases_cinematic',
        kind: SceneEdgeKind.actionCompleted,
        label: 'completed',
      ),
    SceneEdge(
      id: 'edge_teases_cinematic_battle',
      fromNodeId: 'node_teases_cinematic',
      fromPortId: 'completed',
      toNodeId: 'node_battle',
      kind: SceneEdgeKind.cinematicCompleted,
      label: 'completed',
    ),
    SceneEdge(
      id: 'edge_battle_victory',
      fromNodeId: 'node_battle',
      fromPortId: 'victory',
      toNodeId: 'node_victory_end',
      kind: SceneEdgeKind.battleVictory,
      label: 'victory',
    ),
    SceneEdge(
      id: 'edge_battle_defeat',
      fromNodeId: 'node_battle',
      fromPortId: 'defeat',
      toNodeId: 'node_defeat_end',
      kind: SceneEdgeKind.battleDefeat,
      label: 'defeat',
    ),
  ];
  return SceneAsset(
    id: 'scene_lysa_port',
    name: 'Rencontre et combat contre Lysa au port',
    description: 'Golden Slice Yarn → Scene → cinématique → combat.',
    storylineId: 'story_main_brume_phare',
    chapterId: 'chapter_1_port',
    tags: const <String>['selbrume', 'golden-slice', 'choice'],
    graph: SceneGraph(startNodeId: 'node_start', nodes: nodes, edges: edges),
    layout: SceneGraphLayout(
      nodeLayouts: <SceneNodeLayout>[
        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 220),
        SceneNodeLayout(nodeId: 'node_dialogue', x: 324, y: 220),
        SceneNodeLayout(nodeId: 'node_confident_fact', x: 624, y: 40),
        SceneNodeLayout(nodeId: 'node_confident_cinematic', x: 924, y: 40),
        SceneNodeLayout(nodeId: 'node_hesitant_fact', x: 624, y: 220),
        SceneNodeLayout(nodeId: 'node_aggressive_fact', x: 624, y: 400),
        SceneNodeLayout(nodeId: 'node_teases_cinematic', x: 924, y: 310),
        SceneNodeLayout(nodeId: 'node_battle', x: 1224, y: 220),
        SceneNodeLayout(nodeId: 'node_victory_end', x: 1524, y: 130),
        SceneNodeLayout(nodeId: 'node_defeat_end', x: 1524, y: 310),
      ],
    ),
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: 'lysa.victory', label: 'Victoire contre Lysa'),
      SceneOutcome(id: 'lysa.defeat', label: 'Défaite contre Lysa'),
    ],
    metadata: const <String, String>{
      'source': 'MVP Selbrume/selbrume.md',
      'contentStatus': 'runtime_authored',
      'choicePersistenceStatus': 'runtime_yarn_outcomes_bound',
    },
  );
}

SceneGraphLayout _choiceLayout({
  required SceneNode startNode,
  required SceneNode dialogueNode,
  required Map<String, List<SceneNode>> branchNodes,
  required List<SceneNode> commonNodes,
  required SceneNode endNode,
}) {
  final maxBranchLength = branchNodes.values.fold<int>(
    0,
    (current, nodes) => nodes.length > current ? nodes.length : current,
  );
  final commonStartX = 624 + maxBranchLength * 280;
  return SceneGraphLayout(
    nodeLayouts: <SceneNodeLayout>[
      SceneNodeLayout(nodeId: startNode.id, x: 24, y: 220),
      SceneNodeLayout(nodeId: dialogueNode.id, x: 324, y: 220),
      for (final indexed in branchNodes.entries.indexed)
        for (final node in indexed.$2.value.indexed)
          SceneNodeLayout(
            nodeId: node.$2.id,
            x: (624 + node.$1 * 280).toDouble(),
            y: (40 + indexed.$1 * 180).toDouble(),
          ),
      for (final node in commonNodes.indexed)
        SceneNodeLayout(
          nodeId: node.$2.id,
          x: (commonStartX + node.$1 * 280).toDouble(),
          y: 220,
        ),
      SceneNodeLayout(
        nodeId: endNode.id,
        x: (commonStartX + commonNodes.length * 280).toDouble(),
        y: 220,
      ),
    ],
  );
}

SceneAsset _battleScene({
  required String id,
  required String name,
  required String storylineId,
  required String chapterId,
  required String trainerId,
  required String victoryOutcomeId,
  required String defeatOutcomeId,
  String battleKind = 'trainer',
  String? battleTemplateId,
  String? npcEntityId,
  List<_SceneBeat> openingBeats = const <_SceneBeat>[],
  List<_SceneBeat> victoryBeats = const <_SceneBeat>[],
}) {
  final nodes = <SceneNode>[
    SceneNode(id: 'node_start', kind: SceneNodeKind.start, title: 'Début'),
  ];
  for (var index = 0; index < openingBeats.length; index++) {
    final beat = openingBeats[index];
    nodes.add(
      SceneNode(
        id: 'node_open_${index + 1}',
        kind: beat.payload.kind,
        title: beat.title,
        payload: beat.payload,
      ),
    );
  }
  nodes.add(
    SceneNode(
      id: 'node_battle',
      kind: SceneNodeKind.battle,
      title: name,
      payload: SceneBattlePayload(
        battleKind: battleKind,
        trainerId: trainerId,
        battleTemplateId: battleTemplateId,
        npcEntityId: npcEntityId,
        declaredOutcomes: const <String>['victory', 'defeat'],
      ),
    ),
  );
  for (var index = 0; index < victoryBeats.length; index++) {
    final beat = victoryBeats[index];
    nodes.add(
      SceneNode(
        id: 'node_victory_${index + 1}',
        kind: beat.payload.kind,
        title: beat.title,
        payload: beat.payload,
      ),
    );
  }
  nodes.addAll(<SceneNode>[
    SceneNode(
      id: 'node_victory_end',
      kind: SceneNodeKind.end,
      title: 'Victoire',
      payload: SceneEndPayload(
        sceneOutcomeId: victoryOutcomeId,
        outcomePolicy: SceneOutcomePolicy.progression,
      ),
    ),
    SceneNode(
      id: 'node_defeat_end',
      kind: SceneNodeKind.end,
      title: 'Défaite',
      payload: SceneEndPayload(
        sceneOutcomeId: defeatOutcomeId,
        outcomePolicy: SceneOutcomePolicy.retryable,
      ),
    ),
  ]);

  final edges = <SceneEdge>[];
  final openingPath = <SceneNode>[
    nodes.first,
    ...nodes.where((node) => node.id.startsWith('node_open_')),
    nodes.singleWhere((node) => node.id == 'node_battle'),
  ];
  _appendLinearEdges(edges, openingPath);
  final victoryPath =
      nodes.where((node) => node.id.startsWith('node_victory_')).toList();
  final firstVictory = victoryPath.first;
  edges.add(
    SceneEdge(
      id: 'edge_battle_victory_${firstVictory.id}',
      fromNodeId: 'node_battle',
      fromPortId: 'victory',
      toNodeId: firstVictory.id,
      kind: SceneEdgeKind.battleVictory,
      label: 'victory',
    ),
  );
  _appendLinearEdges(edges, victoryPath);
  edges.add(
    SceneEdge(
      id: 'edge_battle_defeat',
      fromNodeId: 'node_battle',
      fromPortId: 'defeat',
      toNodeId: 'node_defeat_end',
      kind: SceneEdgeKind.battleDefeat,
      label: 'defeat',
    ),
  );
  return SceneAsset(
    id: id,
    name: name,
    description: 'Combat canonique issu de selbrume.md.',
    storylineId: storylineId,
    chapterId: chapterId,
    tags: const <String>['selbrume', 'canonical-narrative', 'battle'],
    graph: SceneGraph(startNodeId: 'node_start', nodes: nodes, edges: edges),
    layout: _layout(nodes),
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: victoryOutcomeId, label: 'Victoire'),
      SceneOutcome(id: defeatOutcomeId, label: 'Défaite'),
    ],
    metadata: const <String, String>{
      'source': 'MVP Selbrume/selbrume.md',
      'contentStatus': 'runtime_authored',
    },
  );
}

void _appendLinearEdges(List<SceneEdge> edges, List<SceneNode> nodes) {
  for (var index = 0; index < nodes.length - 1; index++) {
    final from = nodes[index];
    final to = nodes[index + 1];
    final port = _completedPort(from.kind);
    edges.add(
      SceneEdge(
        id: 'edge_${from.id}_${to.id}',
        fromNodeId: from.id,
        fromPortId: port,
        toNodeId: to.id,
        kind: _completedEdgeKind(from.kind),
        label: port,
      ),
    );
  }
}

String _completedPort(SceneNodeKind kind) => switch (kind) {
      SceneNodeKind.cinematic => 'completed',
      SceneNodeKind.action => 'completed',
      _ => 'completed',
    };

SceneEdgeKind _completedEdgeKind(SceneNodeKind kind) => switch (kind) {
      SceneNodeKind.cinematic => SceneEdgeKind.cinematicCompleted,
      SceneNodeKind.action => SceneEdgeKind.actionCompleted,
      _ => SceneEdgeKind.defaultFlow,
    };

SceneGraphLayout _layout(List<SceneNode> nodes) => SceneGraphLayout(
      nodeLayouts: <SceneNodeLayout>[
        for (var index = 0; index < nodes.length; index++)
          SceneNodeLayout(
            nodeId: nodes[index].id,
            x: (24 + index * 300).toDouble(),
            y: nodes[index].id == 'node_defeat_end' ? 260 : 80,
          ),
      ],
    );

List<WorldRuleDefinition> _canonicalWorldRules() => <WorldRuleDefinition>[
      _dialogueRule(
        id: 'world_rule_mael_after_mission',
        label: 'Maël suit la progression de l’enquête',
        factId: 'fact_mael_mission_given',
        mapId: 'map_bourg_selbrume',
        entityId: 'npc_mael',
        dialogueId: 'dialogue_mael_after_mission',
        priority: 10,
      ),
      _dialogueRule(
        id: 'world_rule_mael_epilogue',
        label: 'Maël félicite le joueur après l’épilogue',
        factId: 'fact_main_story_completed',
        mapId: 'map_bourg_selbrume',
        entityId: 'npc_mael',
        dialogueId: 'dialogue_mael_epilogue',
        priority: 100,
      ),
      _dialogueRule(
        id: 'world_rule_mado_after_crystals',
        label: 'Mado remercie le joueur après les cristaux',
        factId: 'fact_crystals_quest_completed',
        mapId: 'map_marais_salants',
        entityId: 'npc_mado',
        dialogueId: 'dialogue_mado_after_crystals',
        priority: 10,
      ),
      _dialogueRule(
        id: 'world_rule_soline_after_passage',
        label: 'Soline commente l’ouverture du passage',
        factId: 'fact_passage_dames_unlocked',
        mapId: 'map_port_brisants',
        entityId: 'npc_soline',
        dialogueId: 'dialogue_soline_after_passage',
        priority: 10,
      ),
      _dialogueRule(
        id: 'world_rule_soline_epilogue',
        label: 'Soline commente le retour des bateaux',
        factId: 'fact_main_story_completed',
        mapId: 'map_port_brisants',
        entityId: 'npc_soline',
        dialogueId: 'dialogue_soline_epilogue',
        priority: 100,
      ),
      _dialogueRule(
        id: 'world_rule_fisher_after_return',
        label: 'Le pêcheur fait confiance au joueur',
        factId: 'fact_goelise_object_returned',
        mapId: 'map_port_brisants',
        entityId: 'npc_pecheur',
        dialogueId: 'dialogue_fisher_after_return',
        priority: 20,
      ),
      _dialogueRule(
        id: 'world_rule_fisher_after_keep',
        label: 'Le pêcheur reste méfiant',
        factId: 'fact_goelise_object_kept',
        mapId: 'map_port_brisants',
        entityId: 'npc_pecheur',
        dialogueId: 'dialogue_fisher_after_keep',
        priority: 21,
      ),
      _dialogueRule(
        id: 'world_rule_fisher_epilogue',
        label: 'Le pêcheur reprend la mer après l’épilogue',
        factId: 'fact_main_story_completed',
        mapId: 'map_port_brisants',
        entityId: 'npc_pecheur',
        dialogueId: 'dialogue_fisher_epilogue',
        priority: 100,
      ),
      _dialogueRule(
        id: 'world_rule_yvon_after_cabin',
        label: 'Yvon réagit à la lecture du carnet',
        factId: 'fact_cabin_quest_completed',
        mapId: 'map_phare_exterieur',
        entityId: 'npc_yvon',
        dialogueId: 'dialogue_yvon_after_cabin',
        priority: 10,
      ),
      _dialogueRule(
        id: 'world_rule_lysa_after_loss',
        label: 'Lysa se moque doucement après sa victoire',
        factId: 'fact_rival_port_lost_once',
        mapId: 'map_port_brisants',
        entityId: 'npc_lysa',
        dialogueId: 'dialogue_lysa_after_loss',
        priority: 20,
      ),
      _entityHideFactRule(
        id: 'world_rule_open_bourg_to_port',
        label: 'Ouvrir la route du port après la mission de Maël',
        factId: 'fact_mael_mission_given',
        mapId: 'map_bourg_selbrume',
        entityId: 'gate_bourg_to_port',
      ),
      _entityHideStepRule(
        id: 'world_rule_open_bourg_to_bois',
        label: 'Ouvrir le chemin du bois après Lysa',
        stepId: 'step_rival_battle',
        mapId: 'map_bourg_selbrume',
        entityId: 'gate_bourg_to_bois',
      ),
      _entityHideStepRule(
        id: 'world_rule_open_bois_to_marais',
        label: 'Ouvrir le chemin des marais après Lysa',
        stepId: 'step_rival_battle',
        mapId: 'map_bois_chaise_brume',
        entityId: 'gate_bois_to_marais',
      ),
      _entityHideFactRule(
        id: 'world_rule_open_marais_to_passage',
        label: 'Ouvrir le Passage des Dames',
        factId: 'fact_passage_dames_unlocked',
        mapId: 'map_marais_salants',
        entityId: 'gate_marais_to_passage',
      ),
      _entityHideFactRule(
        id: 'world_rule_open_passage_to_phare',
        label: 'Rendre le phare accessible depuis le passage',
        factId: 'fact_passage_dames_unlocked',
        mapId: 'map_passage_dames',
        entityId: 'gate_passage_to_phare',
      ),
      _entityHideStepRule(
        id: 'world_rule_open_lighthouse_top',
        label: 'Déverrouiller le sommet du phare',
        stepId: 'step_climb_lighthouse',
        mapId: 'map_phare_interieur',
        entityId: 'gate_lighthouse_top',
      ),
      _entityHideFactRule(
        id: 'world_rule_open_cabin_door',
        label: 'Ouvrir la cabane avec la clé',
        factId: 'fact_cabin_key_found',
        mapId: 'map_phare_exterieur',
        entityId: 'gate_cabin_door',
      ),
      _entityHideFactRule(
        id: 'world_rule_open_cabin_shortcut',
        label: 'Ouvrir le raccourci de la cabane',
        factId: 'fact_cabin_journal_read',
        mapId: 'map_cabane_gardien',
        entityId: 'gate_cabin_shortcut',
      ),
      for (final entry in const <(String, String, String, String)>[
        (
          'goelise_nest_proxy',
          'fact_goelise_quest_completed',
          'map_port_brisants',
          'world_rule_hide_goelise_nest'
        ),
        (
          'clue_glass_object',
          'fact_clue_glass_found',
          'map_marais_salants',
          'world_rule_hide_clue_glass'
        ),
        (
          'clue_electric_object',
          'fact_clue_electric_tracks_found',
          'map_marais_salants',
          'world_rule_hide_clue_electric'
        ),
        (
          'clue_lens_object',
          'fact_clue_lighthouse_mark_found',
          'map_marais_salants',
          'world_rule_hide_clue_lens'
        ),
        (
          'crystal_1_object',
          'fact_crystal_1_found',
          'map_marais_salants',
          'world_rule_hide_crystal_1'
        ),
        (
          'crystal_2_object',
          'fact_crystal_2_found',
          'map_marais_salants',
          'world_rule_hide_crystal_2'
        ),
        (
          'crystal_3_object',
          'fact_crystal_3_found',
          'map_marais_salants',
          'world_rule_hide_crystal_3'
        ),
        (
          'cabin_key_object',
          'fact_cabin_key_found',
          'map_phare_exterieur',
          'world_rule_hide_cabin_key'
        ),
        (
          'boss_phare_pokemon',
          'fact_lighthouse_pokemon_appeased',
          'map_sommet_phare',
          'world_rule_hide_lighthouse_boss'
        ),
      ])
        _entityHideFactRule(
          id: entry.$4,
          label: 'Retirer ${entry.$1} après interaction',
          factId: entry.$2,
          mapId: entry.$3,
          entityId: entry.$1,
        ),
      for (final entry in const <(String, String)>[
        ('map_port_brisants', 'fog_port'),
        ('map_marais_salants', 'fog_marais'),
        ('map_passage_dames', 'fog_passage'),
        ('map_phare_exterieur', 'fog_phare'),
        ('map_sommet_phare', 'fog_sommet'),
      ])
        _entityHideFactRule(
          id: 'world_rule_clear_${entry.$2}',
          label: 'Dissiper la brume de ${entry.$1}',
          factId: 'fact_mist_source_resolved',
          mapId: entry.$1,
          entityId: entry.$2,
        ),
    ];

WorldRuleDefinition _dialogueRule({
  required String id,
  required String label,
  required String factId,
  required String mapId,
  required String entityId,
  required String dialogueId,
  int priority = 0,
}) =>
    WorldRuleDefinition(
      id: id,
      label: label,
      description: 'Règle du monde canonique de Selbrume.',
      source: WorldRuleSource(
        kind: WorldRuleSourceKind.fact,
        sourceId: factId,
        predicate: WorldRuleSourcePredicate.isTrue,
      ),
      target: WorldRuleTarget(
        kind: WorldRuleTargetKind.npcDialogue,
        mapId: mapId,
        entityId: entityId,
      ),
      effect: WorldRuleEffect(
        kind: WorldRuleEffectKind.npcDialogueOverride,
        dialogueId: dialogueId,
      ),
      priority: priority,
      tags: const <String>['selbrume', 'canonical-narrative'],
    );

WorldRuleDefinition _entityHideFactRule({
  required String id,
  required String label,
  required String factId,
  required String mapId,
  required String entityId,
}) =>
    WorldRuleDefinition(
      id: id,
      label: label,
      description: 'La progression retire cet élément du monde.',
      source: WorldRuleSource(
        kind: WorldRuleSourceKind.fact,
        sourceId: factId,
        predicate: WorldRuleSourcePredicate.isTrue,
      ),
      target: WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: mapId,
        entityId: entityId,
      ),
      effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
      tags: const <String>['selbrume', 'canonical-narrative', 'world-state'],
    );

WorldRuleDefinition _entityHideStepRule({
  required String id,
  required String label,
  required String stepId,
  required String mapId,
  required String entityId,
}) =>
    WorldRuleDefinition(
      id: id,
      label: label,
      description: 'La complétion de l’étape ouvre ce passage.',
      source: WorldRuleSource(
        kind: WorldRuleSourceKind.storyStepCompletion,
        sourceId: stepId,
        predicate: WorldRuleSourcePredicate.completed,
      ),
      target: WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: mapId,
        entityId: entityId,
      ),
      effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
      tags: const <String>['selbrume', 'canonical-narrative', 'route-lock'],
    );

void _seedEventRegistry(Map<String, dynamic> project) {
  final existing = NarrativeEventRegistry.fromJson(project['eventRegistry']);
  final additions = <NarrativeEventRecord>[
    _event(
      'evt_019abcde-4000-7000-8000-000000000001',
      'Rencontre avec Lysa au port',
      NarrativeEventSourceRef.entityInteract(
        'map_port_brisants',
        'npc_lysa',
      ),
      'scene_lysa_port',
      order: 0,
      conditions: _factsTrue(<String>['fact_port_alert_seen']),
    ),
    _event(
      'evt_019abcde-4000-7000-8000-000000000002',
      'Entrée dans le Port des Brisants',
      NarrativeEventSourceRef.triggerEnter(
        'map_port_brisants',
        'zone_port_entry',
      ),
      'scene_port_entry',
      order: 1,
      conditions: _factsTrue(<String>['fact_mael_mission_given']),
    ),
    _event(
      'evt_019abcde-4000-7000-8000-000000000003',
      'Indice du verre poli',
      NarrativeEventSourceRef.entityInteract(
        'map_marais_salants',
        'clue_glass_object',
      ),
      'scene_clue_glass',
      order: 2,
      conditions: _factsTrue(<String>['fact_mado_met']),
    ),
    _event(
      _eventRivalAfterWin,
      'Suite de la victoire contre Lysa',
      NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_lysa_port',
          outcomeId: 'lysa.victory',
        ),
      ),
      'scene_rival_after_win',
      order: 3,
    ),
    _event(
      _eventRivalAfterLoss,
      'Suite de la défaite contre Lysa',
      NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_lysa_port',
          outcomeId: 'lysa.defeat',
        ),
      ),
      'scene_rival_after_loss',
      order: 4,
    ),
    _event(
      _eventMael,
      'Parler à Maël au bourg',
      NarrativeEventSourceRef.entityInteract('map_bourg_selbrume', 'npc_mael'),
      'scene_mael_intro',
      order: 10,
      conditions: <NarrativeEventCondition>[
        NarrativeEventCondition.fact('fact_mael_intro_done', false),
      ],
    ),
    _event(
      _eventMaraisEntry,
      'Première entrée dans les Marais Salants',
      NarrativeEventSourceRef.triggerEnter(
          'map_marais_salants', 'zone_marais_entry'),
      'scene_marais_entry',
      order: 11,
    ),
    _event(
      _eventMadoIntro,
      'Rencontrer Mado',
      NarrativeEventSourceRef.entityInteract('map_marais_salants', 'npc_mado'),
      'scene_mado_intro',
      order: 12,
      conditions: <NarrativeEventCondition>[
        NarrativeEventCondition.fact('fact_crystals_quest_started', false),
      ],
      reusePolicy: NarrativeEventReusePolicy.reusable,
    ),
    _event(
      _eventMadoReturn,
      'Rapporter les cristaux à Mado',
      NarrativeEventSourceRef.entityInteract('map_marais_salants', 'npc_mado'),
      'scene_mado_crystals_return',
      order: 13,
      conditions: _factsTrue(<String>[
        'fact_crystal_1_found',
        'fact_crystal_2_found',
        'fact_crystal_3_found',
      ]),
    ),
    _event(
      _eventClueElectric,
      'Découvrir les traces électriques',
      NarrativeEventSourceRef.triggerEnter(
        'map_marais_salants',
        'tr_marais_indice_traces_electriques',
      ),
      'scene_clue_electric_tracks',
      order: 14,
      conditions: _factsTrue(<String>['fact_mado_met']),
    ),
    _event(
      _eventClueLens,
      'Découvrir le repère de lentille',
      NarrativeEventSourceRef.triggerEnter(
        'map_marais_salants',
        'tr_marais_indice_repere_lentille',
      ),
      'scene_clue_lighthouse_mark',
      order: 15,
      conditions: _factsTrue(<String>['fact_mado_met']),
    ),
    _event(
      _eventSoline,
      'Présenter les indices à Soline',
      NarrativeEventSourceRef.entityInteract('map_port_brisants', 'npc_soline'),
      'scene_soline_unlock_passage',
      order: 16,
      conditions: _factsTrue(<String>[
        'fact_clue_glass_found',
        'fact_clue_electric_tracks_found',
        'fact_clue_lighthouse_mark_found',
      ]),
    ),
    _event(
      _eventCrystal1,
      'Ramasser le premier cristal de sel',
      NarrativeEventSourceRef.triggerEnter(
          'map_marais_salants', 'tr_marais_cristal_1'),
      'scene_crystal_1',
      order: 17,
      conditions: _factsTrue(<String>['fact_crystals_quest_started']),
    ),
    _event(
      _eventCrystal2,
      'Ramasser le deuxième cristal de sel',
      NarrativeEventSourceRef.triggerEnter(
          'map_marais_salants', 'tr_marais_cristal_2'),
      'scene_crystal_2',
      order: 18,
      conditions: _factsTrue(<String>['fact_crystals_quest_started']),
    ),
    _event(
      _eventCrystal3,
      'Ramasser le troisième cristal de sel',
      NarrativeEventSourceRef.triggerEnter(
          'map_marais_salants', 'tr_marais_cristal_3'),
      'scene_crystal_3',
      order: 19,
      conditions: _factsTrue(<String>['fact_crystals_quest_started']),
    ),
    _event(
      _eventFisherIntro,
      'Le pêcheur signale le Goélise',
      NarrativeEventSourceRef.entityInteract(
          'map_port_brisants', 'npc_pecheur'),
      'scene_goelise_fisher_intro',
      order: 20,
      conditions: <NarrativeEventCondition>[
        NarrativeEventCondition.fact('fact_lysa_goes_ahead', true),
        NarrativeEventCondition.fact('fact_goelise_quest_started', false),
      ],
    ),
    _event(
      _eventNest,
      'Trouver le nid du Goélise',
      NarrativeEventSourceRef.triggerEnter('map_port_brisants', 'tr_port_nest'),
      'scene_goelise_nest_choice',
      order: 21,
      conditions: _factsTrue(<String>['fact_goelise_quest_started']),
    ),
    _event(
      _eventFisherReturn,
      'Rendre l’objet au pêcheur',
      NarrativeEventSourceRef.entityInteract(
          'map_port_brisants', 'npc_pecheur'),
      'scene_goelise_return',
      order: 22,
      conditions: _factsTrue(<String>['fact_goelise_object_returned']),
    ),
    _event(
      _eventFisherKeepReward,
      'Assumer le choix de garder l’objet',
      NarrativeEventSourceRef.entityInteract(
          'map_port_brisants', 'npc_pecheur'),
      'scene_goelise_keep_reward',
      order: 22,
      conditions: _factsTrue(<String>['fact_goelise_object_kept']),
    ),
    _event(
      _eventLighthouseEntry,
      'Atteindre le Vieux Phare d’Écume',
      NarrativeEventSourceRef.triggerEnter(
        'map_phare_exterieur',
        'zone_lighthouse_entry',
      ),
      'scene_lighthouse_arrival',
      order: 23,
      conditions: _factsTrue(<String>['fact_passage_dames_unlocked']),
    ),
    _event(
      _eventYvon,
      'Parler à Yvon près du phare',
      NarrativeEventSourceRef.entityInteract('map_phare_exterieur', 'npc_yvon'),
      'scene_yvon_intro',
      order: 24,
      conditions: <NarrativeEventCondition>[
        NarrativeEventCondition.fact('fact_cabin_quest_started', false),
      ],
      reusePolicy: NarrativeEventReusePolicy.reusable,
    ),
    _event(
      _eventLighthouseNote,
      'Lire la note du vieux phare',
      NarrativeEventSourceRef.triggerEnter(
          'map_phare_interieur', 'tr_phare_note'),
      'scene_lighthouse_old_note',
      order: 25,
      conditions: _factsTrue(<String>['fact_lighthouse_reached']),
    ),
    // A defeat is a completed Scene outcome, so these battles must stay
    // reusable until their terminal victory Fact closes the trigger. This
    // keeps the retry policy in authored data instead of teaching the generic
    // Event coordinator which battle outcomes should count as success.
    _event(
      _eventGuardian1,
      'Affronter le premier écho du phare',
      NarrativeEventSourceRef.triggerEnter(
        'map_phare_interieur',
        'tr_phare_guardian_1',
      ),
      'scene_lighthouse_guardian_1',
      order: 26,
      conditions: <NarrativeEventCondition>[
        ..._factsTrue(<String>['fact_lighthouse_old_note_read']),
        NarrativeEventCondition.fact(
          'fact_lighthouse_guardian_1_defeated',
          false,
        ),
      ],
      reusePolicy: NarrativeEventReusePolicy.reusable,
    ),
    _event(
      _eventGuardian2,
      'Affronter le second écho du phare',
      NarrativeEventSourceRef.triggerEnter(
        'map_phare_interieur',
        'tr_phare_guardian_2',
      ),
      'scene_lighthouse_guardian_2',
      order: 27,
      conditions: <NarrativeEventCondition>[
        ..._factsTrue(<String>[
          'fact_lighthouse_old_note_read',
          'fact_lighthouse_guardian_1_defeated',
        ]),
        NarrativeEventCondition.fact(
          'fact_lighthouse_guardian_2_defeated',
          false,
        ),
      ],
      reusePolicy: NarrativeEventReusePolicy.reusable,
    ),
    _event(
      _eventBoss,
      'Confrontation au sommet du phare',
      NarrativeEventSourceRef.triggerEnter(
          'map_sommet_phare', 'tr_sommet_confrontation'),
      'scene_final_pokemon',
      order: 28,
      conditions: <NarrativeEventCondition>[
        ..._factsTrue(<String>[
          'fact_lighthouse_top_unlocked',
          'fact_lighthouse_guardian_2_defeated',
        ]),
        NarrativeEventCondition.fact('fact_mist_source_resolved', false),
      ],
      reusePolicy: NarrativeEventReusePolicy.reusable,
    ),
    _event(
      _eventMistDisperses,
      'La brume se disperse après l’apaisement du phare',
      NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_final_pokemon',
          outcomeId: 'lighthouse.pokemon.appeased',
        ),
      ),
      'scene_mist_disperses',
      order: 29,
    ),
    _event(
      _eventCabinKey,
      'Trouver la clé de la cabane',
      NarrativeEventSourceRef.triggerEnter(
          'map_phare_exterieur', 'tr_cabin_key_outside'),
      'scene_cabin_key',
      order: 29,
      conditions: _factsTrue(<String>['fact_cabin_quest_started']),
    ),
    _event(
      _eventCabinJournal,
      'Lire le carnet du gardien',
      NarrativeEventSourceRef.triggerEnter(
          'map_cabane_gardien', 'tr_cabane_journal'),
      'scene_cabin_journal',
      order: 30,
      conditions: _factsTrue(<String>['fact_cabin_key_found']),
    ),
    _event(
      _eventEnding,
      'Célébration finale au port',
      NarrativeEventSourceRef.triggerEnter(
          'map_port_brisants', 'zone_port_center'),
      'scene_ending_port',
      order: 31,
      conditions: _factsTrue(<String>['fact_mist_source_resolved']),
    ),
  ];
  final byId = <String, NarrativeEventRecord>{
    for (final record in existing.records) record.id: record,
    for (final record in additions) record.id: record,
  };
  final records = byId.values.toList()
    ..sort((left, right) {
      final leftOrder =
          left.definitionOrNull?.order ?? left.draftOrNull?.order ?? 0;
      final rightOrder =
          right.definitionOrNull?.order ?? right.draftOrNull?.order ?? 0;
      final byOrder = leftOrder.compareTo(rightOrder);
      return byOrder != 0 ? byOrder : left.id.compareTo(right.id);
    });
  project['eventRegistry'] = NarrativeEventRegistry(
    schemaVersion: existing.schemaVersion,
    mode: existing.mode,
    records: records,
    legacyClaims: existing.legacyClaims,
  ).toJson();
}

NarrativeEventRecord _event(
  String id,
  String name,
  NarrativeEventSourceRef source,
  String sceneId, {
  required int order,
  List<NarrativeEventCondition> conditions = const <NarrativeEventCondition>[],
  NarrativeEventReusePolicy reusePolicy = NarrativeEventReusePolicy.oneShot,
}) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: id,
        name: name,
        source: source,
        conditions: conditions,
        sceneId: sceneId,
        reusePolicy: reusePolicy,
        priority: 0,
        order: order,
      ),
      enabled: true,
    );

List<NarrativeEventCondition> _factsTrue(List<String> factIds) =>
    <NarrativeEventCondition>[
      for (final factId in factIds) NarrativeEventCondition.fact(factId, true),
    ];

void _seedStorylineLinks(Map<String, dynamic> project) {
  const links = <String, List<String>>{
    'step_intro_selbrume': <String>['scene_mael_intro'],
    'step_receive_mission': <String>['scene_mael_intro'],
    'step_go_to_port': <String>['scene_port_entry', 'scene_port_alert'],
    'step_rival_battle': <String>[
      'scene_lysa_port',
      'scene_rival_after_win',
      'scene_rival_after_loss',
    ],
    'step_enter_marais': <String>['scene_marais_entry', 'scene_mado_intro'],
    'step_find_three_clues': <String>[
      'scene_clue_glass',
      'scene_clue_electric_tracks',
      'scene_clue_lighthouse_mark',
    ],
    'step_report_to_soline': <String>['scene_soline_unlock_passage'],
    'step_reach_lighthouse': <String>['scene_lighthouse_arrival'],
    'step_climb_lighthouse': <String>[
      'scene_lighthouse_old_note',
      'scene_lighthouse_guardian_1',
      'scene_lighthouse_guardian_2',
    ],
    'step_final_confrontation': <String>[
      'scene_final_pokemon',
      'scene_mist_disperses',
    ],
    'step_return_to_port': <String>['scene_ending_port'],
    'step_main_story_completed': <String>['scene_ending_port'],
    'step_crystals_talk_to_mado': <String>['scene_mado_intro'],
    'step_crystals_collect_three': <String>[
      'scene_crystal_1',
      'scene_crystal_2',
      'scene_crystal_3',
    ],
    'step_crystals_return_to_mado': <String>['scene_mado_crystals_return'],
    'step_crystals_completed': <String>['scene_mado_crystals_return'],
    'step_goelise_talk_to_fisher': <String>['scene_goelise_fisher_intro'],
    'step_goelise_find_nest': <String>['scene_goelise_nest_choice'],
    'step_goelise_choice': <String>['scene_goelise_nest_choice'],
    'step_goelise_return': <String>[
      'scene_goelise_return',
      'scene_goelise_keep_reward',
    ],
    'step_goelise_completed': <String>[
      'scene_goelise_return',
      'scene_goelise_keep_reward',
    ],
    'step_cabin_talk_to_yvon': <String>['scene_yvon_intro'],
    'step_cabin_find_key': <String>['scene_cabin_key'],
    'step_cabin_open_door': <String>['scene_cabin_journal'],
    'step_cabin_read_journal': <String>['scene_cabin_journal'],
    'step_cabin_completed': <String>['scene_cabin_journal'],
  };
  final storylines = _jsonObjects(project['storylines']);
  for (final storyline in storylines) {
    storyline['authorNotes'] =
        'Contenu narratif canonique appliqué depuis MVP Selbrume/selbrume.md. '
        'Les limites moteur restantes sont documentées dans globalProperties.';
    final metadata = _jsonObjectOrEmpty(storyline['metadata']);
    metadata['source'] = 'selbrume.md';
    metadata['seedScope'] = 'canonical_narrative_content_v1';
    metadata['seed'] = 'selbrume_canonical_narrative_v1';
    storyline['metadata'] = metadata;
    for (final chapter in _jsonObjects(storyline['chapters'])) {
      for (final step in _jsonObjects(chapter['steps'])) {
        final stepLinks = links[step['id']];
        if (stepLinks == null) continue;
        step['sceneLinkIds'] = <String>{
          ..._stringList(step['sceneLinkIds']),
          ...stepLinks,
        }.toList();
      }
    }
  }
  project['storylines'] = storylines;
}

void _seedCapabilityMarkers(Map<String, dynamic> project) {
  final properties = _jsonObjectOrEmpty(project['globalProperties']);
  properties.addAll(<String, dynamic>{
    'selbrume.canonicalContentVersion': 1,
    'selbrume.canonicalSource': 'MVP Selbrume/selbrume.md',
    'selbrume.activeStarterConfiguration': 'projectDriven',
    'selbrume.starterChoiceStatus': 'runtime_scene_consequence_bound',
    'selbrume.dialogueChoicePersistenceStatus': 'runtime_yarn_outcomes_bound',
    'selbrume.sideQuestRewardStatus': 'runtime_scene_consequences_bound',
    'selbrume.cinematicStatus': 'visual_runtime_v1',
    'selbrume.worldStateStatus': 'runtime_world_rules_v1',
    'selbrume.routeLocksStatus': 'physical_entities_runtime_projected',
    'selbrume.bossBattleStatus': 'static_encounter_runtime_bound',
  });
  project['globalProperties'] = properties;
}

void _seedNewGameConfig(Map<String, dynamic> project) {
  project['newGame'] = const ProjectNewGameConfig(
    enabled: true,
    startMapId: 'map_bourg_selbrume',
    startSpawnId: 'spawn',
    playerName: 'Joueur',
    startingMoney: 500,
    initialBag: <BagEntry>[
      BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
    ],
    initialParty: <PlayerPokemon>[],
    initialFacts: <String, bool>{},
    existingPartyFactId: 'fact_player_started_with_existing_pokemon',
    starterSelectionSceneId: 'scene_mael_intro',
    starterOptions: <ProjectStarterOption>[
      ProjectStarterOption(
        id: 'starter_bulbasaur',
        label: 'Bulbizarre',
        pokemon: PlayerPokemon(
          speciesId: 'bulbasaur',
          natureId: 'hardy',
          abilityId: 'overgrow',
          level: 16,
          currentHp: 40,
          knownMoveIds: <String>['tackle', 'growl', 'vine_whip'],
        ),
      ),
      ProjectStarterOption(
        id: 'starter_charmander',
        label: 'Salamèche',
        pokemon: PlayerPokemon(
          speciesId: 'charmander',
          natureId: 'hardy',
          abilityId: 'blaze',
          level: 16,
          currentHp: 38,
          knownMoveIds: <String>['scratch', 'growl', 'ember', 'mud_slap'],
        ),
      ),
      ProjectStarterOption(
        id: 'starter_squirtle',
        label: 'Carapuce',
        pokemon: PlayerPokemon(
          speciesId: 'squirtle',
          natureId: 'hardy',
          abilityId: 'torrent',
          level: 16,
          currentHp: 40,
          knownMoveIds: <String>[
            'tackle',
            'tail_whip',
            'water_gun',
            'mud_slap',
          ],
        ),
      ),
    ],
  ).toJson();
}

void _seedMap(String mapId, Map<String, dynamic> map) {
  switch (mapId) {
    case 'map_bourg_selbrume':
      final entities = _jsonObjects(map['entities']);
      map['entities'] = _upsertById(entities, <Map<String, dynamic>>[
        _structuralAnchor(
          id: 'npc',
          name: 'Ancre historique du PNJ du bourg',
          x: 34,
          y: 29,
        ),
        _npcEntity(
          id: 'npc_mael',
          name: 'Maël',
          x: 27,
          y: 20,
          characterId: 'mael',
          dialogueId: 'dialogue_mael_intro',
          startNode: 'MaelIntro',
        ),
        _gateEntity(
          id: 'gate_bourg_to_port',
          name: 'Route du Port des Brisants fermée',
          x: 0,
          y: 54,
          width: 55,
          height: 1,
          message: 'Avant de partir au port, va parler à Maël sur la place.',
          visualElementId: 'el_selbrume_passage_barriere_fermee',
        ),
        _gateEntity(
          id: 'gate_bourg_to_bois',
          name: 'Route du Bois de la Chaise fermée',
          x: 54,
          y: 0,
          width: 1,
          height: 55,
          message: 'La brume est trop dense. Lysa doit d’abord ouvrir la voie.',
          visualElementId: 'el_selbrume_bois_ronces',
        ),
      ]);
      break;
    case 'map_port_brisants':
      map['placedElements'] = _jsonObjects(map['placedElements'])
        ..removeWhere((entry) => entry['id'] == 'pe_port_nid_goelise');
      map['entities'] = _upsertById(
        _jsonObjects(map['entities']),
        <Map<String, dynamic>>[
          _npcEntity(
            id: 'npc_soline',
            name: 'Soline',
            x: 39,
            y: 10,
            characterId: 'character_soline',
            dialogueId: 'dialogue_soline',
            startNode: 'SolineClues',
          ),
          _npcEntity(
            id: 'npc_pecheur',
            name: 'Pêcheur inquiet',
            x: 13,
            y: 17,
            characterId: 'character_pecheur',
            dialogueId: 'dialogue_goelise_port',
            startNode: 'FisherIntro',
          ),
          _visualEntity(
            id: 'goelise_nest_proxy',
            name: 'Nid du Goélise déplacé par la brume',
            x: 7,
            y: 9,
            elementId: 'el_port_ref_nest',
          ),
          _visualEntity(
            id: 'fog_port',
            name: 'Banc de brume du port',
            x: 22,
            y: 11,
            elementId: 'el_selbrume_fx_brume_basse',
          ),
        ],
      );
      break;
    case 'map_bois_chaise_brume':
      map['entities'] = _upsertById(
        _jsonObjects(map['entities']),
        <Map<String, dynamic>>[
          _gateEntity(
            id: 'gate_bois_to_marais',
            name: 'Accès aux Marais Salants fermé',
            x: 44,
            y: 0,
            width: 1,
            height: 45,
            message:
                'Les ronces et la brume barrent encore la route des marais.',
            visualElementId: 'el_selbrume_bois_ronces',
          ),
        ],
      );
      break;
    case 'map_marais_salants':
      map['entities'] = _upsertById(
        _jsonObjects(map['entities']),
        <Map<String, dynamic>>[
          _npcEntity(
            id: 'npc_mado',
            name: 'Mado',
            x: 10,
            y: 12,
            characterId: 'character_mado',
            dialogueId: 'dialogue_mado',
            startNode: 'MadoIntro',
          ),
          _gateEntity(
            id: 'gate_marais_to_passage',
            name: 'Passage des Dames fermé',
            x: 0,
            y: 44,
            width: 45,
            height: 1,
            message:
                'Le Passage des Dames reste fermé. Rapporte les trois indices à Soline.',
            visualElementId: 'el_selbrume_passage_barriere_fermee',
          ),
          _visualEntity(
            id: 'clue_glass_object',
            name: 'Indice en verre poli',
            x: 8,
            y: 32,
            elementId: 'el_selbrume_indice_verre',
          ),
          _visualEntity(
            id: 'clue_electric_object',
            name: 'Traces électriques',
            x: 32,
            y: 10,
            elementId: 'el_selbrume_indice_traces_electriques',
          ),
          _visualEntity(
            id: 'clue_lens_object',
            name: 'Repère de l’ancienne lentille',
            x: 34,
            y: 34,
            elementId: 'el_selbrume_indice_repere_lentille',
          ),
          _visualEntity(
            id: 'crystal_1_object',
            name: 'Premier cristal de sel',
            x: 14,
            y: 7,
            elementId: 'el_selbrume_cristal_1',
          ),
          _visualEntity(
            id: 'crystal_2_object',
            name: 'Deuxième cristal de sel',
            x: 24,
            y: 28,
            elementId: 'el_selbrume_cristal_2',
          ),
          _visualEntity(
            id: 'crystal_3_object',
            name: 'Troisième cristal de sel',
            x: 38,
            y: 22,
            elementId: 'el_selbrume_cristal_3',
          ),
          _visualEntity(
            id: 'fog_marais',
            name: 'Brume des Marais Salants',
            x: 20,
            y: 20,
            elementId: 'el_selbrume_fx_brume_basse',
          ),
        ],
      );
      break;
    case 'map_passage_dames':
      map['entities'] = _upsertById(
        _jsonObjects(map['entities']),
        <Map<String, dynamic>>[
          _gateEntity(
            id: 'gate_passage_to_phare',
            name: 'Route du Vieux Phare fermée',
            x: 59,
            y: 0,
            width: 1,
            height: 24,
            message: 'La barrière ne s’ouvrira qu’après l’accord de Soline.',
            visualElementId: 'el_selbrume_passage_barriere_fermee',
          ),
          _visualEntity(
            id: 'fog_passage',
            name: 'Brume du Passage des Dames',
            x: 28,
            y: 8,
            elementId: 'el_selbrume_fx_brume_basse',
          ),
        ],
      );
      break;
    case 'map_phare_exterieur':
      map['entities'] = _upsertById(
        _jsonObjects(map['entities']),
        <Map<String, dynamic>>[
          _npcEntity(
            id: 'npc_yvon',
            name: 'Yvon',
            x: 10,
            y: 12,
            characterId: 'character_yvon',
            dialogueId: 'dialogue_yvon_cabin',
            startNode: 'YvonCabin',
          ),
          _gateEntity(
            id: 'gate_cabin_door',
            name: 'Cabane du gardien verrouillée',
            x: 8,
            y: 33,
            width: 1,
            height: 1,
            message: 'La porte est verrouillée. Yvon a parlé d’une clé.',
          ),
          _visualEntity(
            id: 'cabin_key_object',
            name: 'Clé de la cabane',
            x: 14,
            y: 28,
            elementId: 'el_selbrume_cabane_cle',
          ),
          _visualEntity(
            id: 'fog_phare',
            name: 'Brume autour du vieux phare',
            x: 22,
            y: 22,
            elementId: 'el_selbrume_fx_brume_basse',
          ),
        ],
      );
      map['triggers'] = _upsertById(
        _jsonObjects(map['triggers']),
        <Map<String, dynamic>>[
          _trigger(
            id: 'tr_cabin_key_outside',
            x: 14,
            y: 28,
            eventId: 'event_selbrume_cabin_key_outside',
            width: 1,
            height: 1,
          ),
        ],
      );
      break;
    case 'map_phare_interieur':
      map['entities'] = _upsertById(
        _jsonObjects(map['entities']),
        <Map<String, dynamic>>[
          _gateEntity(
            id: 'gate_lighthouse_top',
            name: 'Escalier du sommet instable',
            x: 18,
            y: 1,
            width: 1,
            height: 1,
            message:
                'Les deux échos du phare doivent être dissipés avant de monter.',
            visualElementId: 'el_selbrume_fx_lumiere_instable',
          ),
        ],
      );
      map['triggers'] = _upsertById(
        _jsonObjects(map['triggers']),
        <Map<String, dynamic>>[
          _trigger(
            id: 'tr_phare_guardian_1',
            x: 7,
            y: 32,
            eventId: 'event_selbrume_phare_guardian_1',
          ),
          _trigger(
            id: 'tr_phare_guardian_2',
            x: 24,
            y: 14,
            eventId: 'event_selbrume_phare_guardian_2',
          ),
        ],
      );
      break;
    case 'map_sommet_phare':
      map['entities'] = _upsertById(
        _jsonObjects(map['entities']),
        <Map<String, dynamic>>[
          _visualEntity(
            id: 'boss_phare_pokemon',
            name: 'Lanturn affolé du phare',
            x: 12,
            y: 10,
            elementId: 'el_selbrume_fx_lumiere_instable',
            blocksMovement: true,
          ),
          _visualEntity(
            id: 'fog_sommet',
            name: 'Brume concentrée au sommet',
            x: 12,
            y: 12,
            elementId: 'el_selbrume_fx_brume_basse',
          ),
        ],
      );
      break;
    case 'map_cabane_gardien':
      map['entities'] = _upsertById(
        _jsonObjects(map['entities']),
        <Map<String, dynamic>>[
          _gateEntity(
            id: 'gate_cabin_shortcut',
            name: 'Raccourci du gardien fermé',
            x: 19,
            y: 8,
            width: 1,
            height: 1,
            message:
                'Le mécanisme est bloqué. Le carnet du gardien doit contenir la solution.',
          ),
        ],
      );
      map['triggers'] = _jsonObjects(map['triggers'])
        ..removeWhere((entry) => entry['id'] == 'tr_cabane_cle');
      break;
  }
}

Map<String, dynamic> _npcEntity({
  required String id,
  required String name,
  required int x,
  required int y,
  required String characterId,
  required String dialogueId,
  required String startNode,
}) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'kind': 'npc',
      'pos': <String, dynamic>{'x': x, 'y': y},
      'size': <String, dynamic>{'width': 1, 'height': 1},
      'npc': <String, dynamic>{
        'displayName': name,
        'dialogue': <String, dynamic>{
          'dialogueId': dialogueId,
          'scriptPathRelative': '',
          'startNode': startNode,
        },
        'facing': 'south',
        'visualElementId': '',
        'trainerId': null,
        'lineOfSightRange': 0,
        'defeatDialogueRef': null,
        'characterId': characterId,
        'movement': <String, dynamic>{
          'mode': 'idle',
          'waypoints': <dynamic>[],
          'loop': true,
          'pauseDurationMs': 0,
          'stepDurationMs': 200,
        },
        'visibilityRule': null,
        'conditionalDialogues': <dynamic>[],
      },
      'sign': null,
      'item': null,
      'spawn': null,
      'editorVisual': null,
      'blocksMovement': true,
      'properties': <String, String>{
        'contractRole': 'selbrume_canonical_narrative_source',
      },
    };

Map<String, dynamic> _structuralAnchor({
  required String id,
  required String name,
  required int x,
  required int y,
}) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'kind': 'custom',
      'pos': <String, dynamic>{'x': x, 'y': y},
      'size': <String, dynamic>{'width': 1, 'height': 1},
      'npc': null,
      'sign': null,
      'item': null,
      'spawn': null,
      'editorVisual': null,
      'blocksMovement': false,
      'properties': <String, String>{
        'contractRole': 'canonical_map_generator_compatibility_anchor',
        'inert': 'true',
      },
    };

Map<String, dynamic> _gateEntity({
  required String id,
  required String name,
  required int x,
  required int y,
  required int width,
  required int height,
  required String message,
  String? visualElementId,
}) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'kind': 'sign',
      'pos': <String, dynamic>{'x': x, 'y': y},
      'size': <String, dynamic>{'width': width, 'height': height},
      'npc': null,
      'sign': <String, dynamic>{
        'title': name,
        'dialogue': null,
        'plainText': message,
      },
      'item': null,
      'spawn': null,
      'editorVisual': visualElementId == null
          ? null
          : <String, dynamic>{
              'elementId': visualElementId,
              'renderInForeground': false,
            },
      'blocksMovement': true,
      'properties': <String, String>{
        'contractRole': 'selbrume_route_lock',
        'unlockProjection': 'world_rule_entity_hidden',
      },
    };

Map<String, dynamic> _visualEntity({
  required String id,
  required String name,
  required int x,
  required int y,
  required String elementId,
  bool blocksMovement = false,
}) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'kind': 'custom',
      'pos': <String, dynamic>{'x': x, 'y': y},
      'size': <String, dynamic>{'width': 1, 'height': 1},
      'npc': null,
      'sign': null,
      'item': null,
      'spawn': null,
      'editorVisual': <String, dynamic>{
        'elementId': elementId,
        'renderInForeground': false,
      },
      'blocksMovement': blocksMovement,
      'properties': <String, String>{
        'contractRole': 'selbrume_world_state_visual',
      },
    };

Map<String, dynamic> _trigger({
  required String id,
  required int x,
  required int y,
  required String eventId,
  int width = 2,
  int height = 2,
}) =>
    <String, dynamic>{
      'id': id,
      'name': id,
      'type': 'custom',
      'area': <String, dynamic>{
        'pos': <String, dynamic>{'x': x, 'y': y},
        'size': <String, dynamic>{'width': width, 'height': height},
      },
      'properties': <String, String>{
        'eventId': eventId,
        'reservedForNarrative': 'true',
      },
    };

const _canonicalYarnFiles = <String, String>{
  'mael_intro.yarn': '''title: MaelIntro
tags: selbrume chapter-1
---
Maël: Bienvenue à Selbrume. La brume n'a jamais été aussi épaisse.
Maël: Viens me voir avec ton compagnon, ou choisis-en un si tu pars de zéro.
===
title: MaelExistingPokemon
tags: selbrume chapter-1
---
Maël: Ton Pokémon semble déjà te faire confiance. Nous n'avons pas de temps à perdre.
Maël: Rejoins le Port des Brisants et découvre pourquoi le vieux phare s'est tu.
===
title: MaelStarterChoice
tags: selbrume chapter-1 starter
---
Maël: La route sera dangereuse. Lequel de ces trois compagnons veux-tu protéger ?
-> Bulbizarre, calme et tenace
    <<outcome starter_bulbasaur>>
    Maël: Bulbizarre saura sentir les changements dans les marais.
-> Salamèche, vif et courageux
    <<outcome starter_charmander>>
    Maël: Salamèche gardera une lumière près de toi dans la brume.
-> Carapuce, à l'aise avec les embruns
    <<outcome starter_squirtle>>
    Maël: Carapuce connaît déjà le rythme des marées.
Maël: Rejoins maintenant le Port des Brisants. Le vieux phare nous inquiète.
===
''',
  'port_alert.yarn': '''title: PortAlert
tags: selbrume chapter-1
---
Pêcheur: Les barques reviennent toutes seules ! On ne voit plus les balises !
Soline: Le phare envoie des éclats irréguliers. Gardez votre calme et restez sur les quais.
-> Céder à la panique
    <<outcome panic>>
    Joueur: Oh mon Dieu, on va tous mourir !
    <<jump PortPanicked>>
-> Rassurer la foule
    <<outcome reassure>>
    Joueur: Calmez-vous, on va comprendre ce qui se passe.
    <<jump PortReassured>>
===
title: PortPanicked
tags: selbrume chapter-1
---
Soline: Respire. Va voir Lysa avant que la peur ne gagne tous les quais.
===
title: PortReassured
tags: selbrume chapter-1
---
Soline: Va voir Lysa. Elle prétend connaître un passage vers les marais.
===
''',
  'lysa_port.yarn': '''title: LysaPort
tags: selbrume chapter-1 golden-slice
---
Lysa: La brume se lève sur le Port des Brisants.
Lysa: Elle avale les balises et les pêcheurs n’osent plus sortir. Si tu veux continuer, montre-moi ce que vaut ton équipe.
-> Répondre avec assurance
    <<outcome confident>>
    Joueur: Je dégagerai le passage et je trouverai ce qui affole le phare.
-> Rester prudent
    <<outcome hesitant>>
    Joueur: Je préfère comprendre la brume avant de foncer, mais je ne reculerai pas.
-> La provoquer
    <<outcome aggressive>>
    Joueur: Tu parles beaucoup pour quelqu'un qui bloque le seul passage vers les marais.
===
title: RivalAfterWin
tags: selbrume chapter-1
---
Lysa: D'accord, tu as gagné mon respect. Tu peux tenir le rythme ; je pars devant reconnaître les marais.
===
title: RivalAfterLoss
tags: selbrume chapter-1
---
Lysa: Tu manques encore d'expérience, mais la brume n'attendra pas. Le chemin des marais reste ouvert : entraîne-toi et suis-moi quand tu seras prêt.
===
''',
  'mado.yarn': '''title: MadoIntro
tags: selbrume chapter-2 side-quest
---
Mado: La brume fait chanter le sel. Écoute bien : trois notes manquent dans les marais.
Mado: Ce sont mes cristaux. Retrouve-les et ils nous diront d'où vient cette énergie.
-> Accepter d'aider
    <<outcome accept_help>>
    Joueur: Je chercherai les trois cristaux.
-> Refuser pour le moment
    <<outcome refuse_for_now>>
    Joueur: Je dois d’abord me préparer. Je reviendrai.
===
title: MadoReturn
tags: selbrume chapter-2 side-quest
---
Mado: Les trois cristaux vibrent ensemble. Ils pointent vers la lentille du vieux phare.
Mado: Prends cette Super Potion. Elle t'aidera quand la brume se resserrera.
===
''',
  'soline.yarn': '''title: SolineClues
tags: selbrume chapter-2
---
Soline: Du verre poli, des traces électriques et la marque de l'ancienne lentille...
Soline: Tu as raison. Le Passage des Dames doit être ouvert, même si la marée se lève.
===
title: SolineAfterPassage
tags: selbrume chapter-2
---
Soline: Le passage est libre. Reviens vivant du phare.
===
''',
  'marais_clues.yarn': '''title: ClueGlass
tags: selbrume chapter-2 clue
---
Narration: Un éclat de verre parfaitement poli est pris dans le sel. Il provient d'une lentille ancienne.
===
title: ClueElectric
tags: selbrume chapter-2 clue
---
Narration: De fines brûlures bleutées serpentent dans la vase. L'énergie file vers le nord.
===
title: ClueLens
tags: selbrume chapter-2 clue
---
Narration: Une marque gravée représente le mécanisme de la lentille du phare.
===
''',
  'lighthouse.yarn': '''title: LighthouseArrival
tags: selbrume chapter-3
---
Narration: Le Vieux Phare d'Écume tremble sous chaque pulsation de lumière.
===
title: LighthouseOldNote
tags: selbrume chapter-3 lore
---
Ancien carnet: La lentille amplifie les émotions des Pokémon sensibles aux courants marins.
Ancien carnet: Si la lumière s'emballe, le Pokémon n'est pas malveillant : il est effrayé, pris au piège dans sa propre énergie. Ne détruisez pas la source. Apaisez-la.
===
title: FinalPokemon
tags: selbrume chapter-3 boss
---
Narration: Un Lanturn affolé est prisonnier du mécanisme. La lentille amplifie chacune de ses décharges et sa lumière pulse au rythme de la brume.
Joueur: Je ne suis pas venu te chasser. Mais je dois arrêter cette tempête.
===
title: MistDisperses
tags: selbrume chapter-3 resolution
---
Narration: Le faisceau du phare se stabilise et découpe un chemin clair dans la brume.
Maël: Même depuis le bourg, je vois la lumière. Tu as réussi ; Selbrume respire de nouveau.
===
''',
  'ending_port.yarn': '''title: EndingPort
tags: selbrume chapter-4
---
Maël: Regarde le large. Pour la première fois depuis des jours, on distingue l'horizon.
Soline: Les bateaux peuvent repartir et le Passage des Dames restera sûr tant que le phare gardera ce rythme.
Lysa: Ne prends pas cet air satisfait. La prochaine fois, je gagne.
Narration: Les pêcheurs détachent leurs barques, les étals rouvrent et, au loin, le phare envoie un faisceau stable au-dessus de Selbrume.
===
''',
  'goelise_port.yarn': '''title: FisherIntro
tags: selbrume side-quest
---
Pêcheur: Un Goélise vole nos repas depuis que la brume a déplacé son nid.
Pêcheur: Trouve-le avant que quelqu'un ne décide de le chasser.
===
title: GoeliseChoice
tags: selbrume side-quest choice
---
Narration: Dans le nid repose un petit objet brillant appartenant aux pêcheurs.
-> Rendre l'objet au pêcheur
    <<outcome return_item>>
    Joueur: Le Goélise a surtout besoin qu'on remette son nid en place.
    <<jump GoeliseReturned>>
-> Garder l'objet
    <<outcome keep_item>>
    Joueur: Cet objet pourrait servir plus tard.
    <<jump GoeliseKept>>
===
title: GoeliseReturned
tags: selbrume side-quest choice
---
Narration: Le joueur décide de rendre l'objet aux pêcheurs.
===
title: GoeliseKept
tags: selbrume side-quest choice
---
Narration: Le joueur garde l'objet et devra assumer la méfiance des pêcheurs.
===
title: FisherReturn
tags: selbrume side-quest
---
Pêcheur: Le Goélise est calmé et son nid tient bon. Merci.
===
title: FisherSuspicious
tags: selbrume side-quest choice
---
Pêcheur: Le nid tient bon, mais l'objet des pêcheurs n'est jamais revenu.
Pêcheur: Garde donc cette perle. La confiance, elle, se regagne autrement.
===
''',
  'yvon_cabin.yarn': '''title: YvonCabin
tags: selbrume side-quest lore
---
Yvon: J'ai gardé ce phare autrefois. Ma vieille cabane contient un carnet sur la lentille.
Yvon: La clé a dû glisser près du mur extérieur. Si tu la retrouves, lis tout.
-> Chercher la clé
    <<outcome accept_search_key>>
    Joueur: Je retrouverai la clé et je lirai le carnet.
-> Revenir plus tard
    <<outcome ignore_for_now>>
    Joueur: Je reviendrai quand je pourrai fouiller les abords du phare.
===
title: CabinKey
tags: selbrume side-quest
---
Narration: Une clé piquée de sel porte l'emblème du vieux phare.
===
title: CabinJournal
tags: selbrume side-quest lore
---
Carnet d'Yvon: La lumière ne commande pas la mer ; elle lui répond.
Carnet d'Yvon: Un Pokémon effrayé peut transformer la lentille en amplificateur de brume.
===
''',
  'mael_after_mission.yarn': '''title: MaelAfterMission
tags: selbrume world-state chapter-1
---
Maël: Le Port des Brisants t’attend. Écoute Soline et ne sous-estime pas Lysa.
===
''',
  'mael_epilogue.yarn': '''title: MaelEpilogue
tags: selbrume world-state epilogue
---
Maël: Tu as rendu son horizon à Selbrume. Ce village se souviendra de ta lumière.
===
''',
  'lysa_after_loss.yarn': '''title: RivalAfterLoss
tags: selbrume world-state chapter-1
---
Lysa: La brume n’attend pas les retardataires. Entraîne-toi et essaie de me suivre.
Lysa: Le chemin vers les marais est toujours ouvert. Je t’attends là-bas — essaie simplement de ne pas te perdre avant d’arriver.
===
''',
  'mado_after_crystals.yarn': '''title: MadoCompleted
tags: selbrume world-state side-quest
---
Mado: Les cristaux chantent de nouveau. Le phare ne pourra plus nous cacher sa vérité.
===
''',
  'soline_after_passage.yarn': '''title: SolineAfterPassage
tags: selbrume world-state chapter-2
---
Soline: Le Passage des Dames est ouvert. Le vieux phare est droit devant toi.
===
''',
  'soline_epilogue.yarn': '''title: SolineEpilogue
tags: selbrume world-state epilogue
---
Soline: Les bateaux repartent et la marée est lisible. Selbrume respire enfin.
===
''',
  'fisher_after_return.yarn': '''title: FisherAfterReturn
tags: selbrume world-state side-quest
---
Pêcheur: Tu as protégé le Goélise et rendu notre bien. Tu seras toujours bienvenu sur ce quai.
===
''',
  'fisher_after_keep.yarn': '''title: FisherAfterKeep
tags: selbrume world-state side-quest
---
Pêcheur: Le nid est sauf, mais la confiance ne se ramasse pas comme une perle.
===
''',
  'fisher_epilogue.yarn': '''title: FisherEpilogue
tags: selbrume world-state epilogue
---
Pêcheur: La brume est levée. Les filets sont prêts et les barques reprennent enfin la mer.
===
''',
  'yvon_after_cabin.yarn': '''title: YvonAfterCabin
tags: selbrume world-state side-quest lore
---
Yvon: Tu as lu mon carnet. Alors tu sais que la lumière doit répondre à la mer, jamais la dominer.
===
''',
};

void _upsertProjectEntries(
  Map<String, dynamic> project,
  String key,
  List<Map<String, dynamic>> additions,
) {
  project[key] = _upsertById(_jsonObjects(project[key]), additions);
}

List<Map<String, dynamic>> _upsertById(
  List<Map<String, dynamic>> base,
  List<Map<String, dynamic>> additions,
) {
  final additionsById = <String, Map<String, dynamic>>{
    for (final entry in additions) entry['id']! as String: entry,
  };
  final result = <Map<String, dynamic>>[
    for (final entry in base) additionsById.remove(entry['id']) ?? entry,
  ];
  result.addAll(additionsById.values);
  return result;
}

List<Map<String, dynamic>> _jsonObjects(Object? value) =>
    (value as List<dynamic>? ?? const <dynamic>[])
        .map((entry) => (entry as Map).cast<String, dynamic>())
        .toList();

Map<String, dynamic> _jsonObjectOrEmpty(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

List<String> _stringList(Object? value) =>
    (value as List<dynamic>? ?? const <dynamic>[]).whereType<String>().toList();

Map<String, dynamic> _deepCopy(Map<String, dynamic> value) =>
    (jsonDecode(jsonEncode(value)) as Map).cast<String, dynamic>();

Map<String, dynamic> _readJson(File file) =>
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'MVP Selbrume', 'selbrume.md'))
            .existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}
