import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:path/path.dart' as p;

import '../tool/seed_selbrume_canonical_narrative_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seeds the canonical Selbrume narrative inventory idempotently',
      () async {
    final fixture = _copySelbrumeFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));

    final first = await seedSelbrumeCanonicalNarrativeContent(fixture);
    expect(first.changedRelativePaths, isNotEmpty);
    expect(first.authoringContract, 'canonicalSeedAutomation');
    expect(
      first.humanWorkflowProof,
      'test/selbrume_narrative_reconstruction_test.dart',
    );

    final firstBytes = _authoredBytes(fixture);
    final second = await seedSelbrumeCanonicalNarrativeContent(fixture);
    final secondBytes = _authoredBytes(fixture);

    expect(second.changedRelativePaths, isEmpty);
    expect(second.authoringContract, first.authoringContract);
    expect(second.humanWorkflowProof, first.humanWorkflowProof);
    expect(secondBytes, firstBytes);

    final manifest = ProjectManifest.fromJson(
      _readJson(File(p.join(fixture.path, 'project.json'))),
    );
    expect(() => ProjectValidator.validate(manifest), returnsNormally);
    final mapsById = <String, MapData>{
      for (final entry in manifest.maps)
        entry.id: MapData.fromJson(
          _readJson(File(p.join(fixture.path, entry.relativePath))),
        ),
    };

    expect(
      manifest.characters.map((entry) => entry.id),
      containsAll(<String>[
        'mael',
        'character_lysa',
        'character_mado',
        'character_soline',
        'character_yvon',
      ]),
    );
    expect(
      manifest.trainers.map((entry) => entry.id),
      containsAll(<String>[
        'trainer_lysa_port',
        'trainer_phare_gardien_1',
        'trainer_phare_gardien_2',
        'trainer_boss_phare_pokemon',
      ]),
    );
    final marshEncounters = manifest.encounterTables.singleWhere(
      (entry) => entry.id == 'grass_path_route_1',
    );
    expect(marshEncounters.name, 'Herbes des marais salants');
    expect(marshEncounters.entries, hasLength(1));
    expect(marshEncounters.entries.single.speciesId, 'pidgeotto');
    expect(marshEncounters.entries.single.minLevel, 11);
    expect(marshEncounters.entries.single.maxLevel, 11);
    expect(
      manifest.dialogues.map((entry) => entry.id),
      containsAll(canonicalSelbrumeDialogueIds),
    );
    expect(
      manifest.cinematics.map((entry) => entry.id),
      containsAll(canonicalSelbrumeCinematicIds),
    );
    expect(
      manifest.scenes.map((entry) => entry.id),
      containsAll(canonicalSelbrumeSceneIds),
    );
    expect(
      manifest.facts.map((entry) => entry.id),
      containsAll(canonicalSelbrumeFactIds),
    );

    final existingPokemon = manifest.facts.singleWhere(
      (entry) => entry.id == 'fact_player_started_with_existing_pokemon',
    );
    expect(existingPokemon.defaultValue, isFalse);
    expect(manifest.newGame.enabled, isTrue);
    expect(manifest.newGame.startMapId, 'map_bourg_selbrume');
    expect(manifest.newGame.startSpawnId, 'spawn');
    expect(manifest.newGame.initialParty, isEmpty);
    expect(
      manifest.newGame.existingPartyFactId,
      'fact_player_started_with_existing_pokemon',
    );
    expect(
      manifest.newGame.starterOptions.map((option) => option.id),
      const <String>[
        'starter_bulbasaur',
        'starter_charmander',
        'starter_squirtle',
      ],
    );
    final startersById = <String, PlayerPokemon>{
      for (final option in manifest.newGame.starterOptions)
        option.id: option.pokemon,
    };
    expect(
      startersById.map(
        (id, pokemon) => MapEntry(id, pokemon.level),
      ),
      <String, int>{
        'starter_bulbasaur': 16,
        'starter_charmander': 16,
        'starter_squirtle': 15,
      },
    );
    expect(startersById['starter_bulbasaur']!.currentHp, 40);
    expect(startersById['starter_charmander']!.currentHp, 38);
    expect(startersById['starter_squirtle']!.currentHp, 40);
    expect(startersById['starter_squirtle']!.experience, 2534);
    expect(
      startersById['starter_bulbasaur']!.knownMoveIds,
      contains('vine_whip'),
    );
    expect(
      startersById['starter_charmander']!.knownMoveIds,
      contains('ember'),
    );
    expect(
      startersById['starter_squirtle']!.knownMoveIds,
      contains('water_gun'),
    );
    expect(
      manifest.globalProperties['selbrume.activeStarterConfiguration'],
      'projectDriven',
    );
    expect(
      manifest.globalProperties['selbrume.starterChoiceStatus'],
      'runtime_scene_consequence_bound',
    );
    expect(
      manifest.globalProperties['selbrume.dialogueChoicePersistenceStatus'],
      'runtime_yarn_outcomes_bound',
    );
    expect(
      manifest.globalProperties['selbrume.sideQuestRewardStatus'],
      'runtime_scene_consequences_bound',
    );
    expect(
      manifest.globalProperties['selbrume.cinematicStatus'],
      'visual_runtime_v1',
    );
    expect(
      manifest.globalProperties['selbrume.worldStateStatus'],
      'runtime_world_rules_v1',
    );
    expect(
      manifest.globalProperties['selbrume.routeLocksStatus'],
      'physical_entities_runtime_projected',
    );
    expect(
      manifest.globalProperties['selbrume.bossBattleStatus'],
      'static_encounter_runtime_bound',
    );

    final storylinesById = {
      for (final storyline in manifest.storylines) storyline.id: storyline,
    };
    expect(
      storylinesById.keys,
      containsAll(<String>[
        'story_main_brume_phare',
        'story_side_salt_crystals',
        'story_side_goelise_port',
        'story_side_lighthouse_cabin',
      ]),
    );
    expect(
      storylinesById['story_main_brume_phare']!
          .chapters
          .expand((chapter) => chapter.steps)
          .map((step) => step.id),
      containsAll(<String>[
        'step_intro_selbrume',
        'step_receive_mission',
        'step_go_to_port',
        'step_rival_battle',
        'step_enter_marais',
        'step_find_three_clues',
        'step_report_to_soline',
        'step_reach_lighthouse',
        'step_climb_lighthouse',
        'step_final_confrontation',
        'step_return_to_port',
        'step_main_story_completed',
      ]),
    );

    _expectDialogueFilesAndNodes(fixture, manifest);
    _expectDialogueOutcomeContract(
      fixture,
      manifest,
      'dialogue_mael_intro',
      const <String>[
        'starter_bulbasaur',
        'starter_charmander',
        'starter_squirtle',
      ],
    );
    _expectDialogueOutcomeContract(
      fixture,
      manifest,
      'dialogue_port_alert',
      const ['panic', 'reassure'],
    );
    _expectDialogueOutcomeContract(
      fixture,
      manifest,
      'dialogue_lysa_port',
      const ['confident', 'hesitant', 'aggressive'],
    );
    _expectDialogueOutcomeContract(
      fixture,
      manifest,
      'dialogue_mado',
      const ['accept_help', 'refuse_for_now'],
    );
    _expectDialogueOutcomeContract(
      fixture,
      manifest,
      'dialogue_goelise_port',
      const ['return_item', 'keep_item'],
    );
    _expectDialogueOutcomeContract(
      fixture,
      manifest,
      'dialogue_yvon_cabin',
      const ['accept_search_key', 'ignore_for_now'],
    );
    _expectEventSourcesClose(fixture, manifest);
    final session = await NarrativeEventAuthoringSession.prepare(
      p.join(fixture.path, 'project.json'),
    );
    final validationReport = buildNarrativeEventValidationReport(
      registry: session.manifest.eventRegistry!,
      catalog: session.context.catalog,
    );
    expect(
      validationReport.diagnostics.where(
        (diagnostic) =>
            diagnostic.severity == NarrativeEventValidationSeverity.error,
      ),
      isEmpty,
    );
    _expectMapNpc(fixture, 'map_bourg_selbrume', 'npc_mael', 'mael');
    _expectMapNpc(
      fixture,
      'map_marais_salants',
      'npc_mado',
      'character_mado',
    );
    _expectMapNpc(
      fixture,
      'map_port_brisants',
      'npc_soline',
      'character_soline',
    );
    _expectMapNpc(
      fixture,
      'map_phare_exterieur',
      'npc_yvon',
      'character_yvon',
    );
    _expectWorldStateContract(manifest, mapsById);
    _expectPlayerServicesContract(manifest, mapsById);
    _expectCanonicalEventProgression(manifest);
    _expectSelbrumeSpecificationMatrix(manifest);
    _expectCanonicalOutcomePolicies(manifest);

    final lysaScene = manifest.scenes.singleWhere(
      (entry) => entry.id == 'scene_lysa_port',
    );
    expect(
      lysaScene.graph.nodes.where((node) => node.kind == SceneNodeKind.battle),
      hasLength(1),
    );
    expect(
      lysaScene.declaredOutcomes.map((outcome) => outcome.id),
      containsAll(<String>['lysa.victory', 'lysa.defeat']),
    );
    _expectStarterBranches(manifest);
    _expectCanonicalRewards(manifest);
    final finalBattle = manifest.scenes
        .singleWhere((scene) => scene.id == 'scene_final_pokemon')
        .graph
        .nodes
        .map((node) => node.payload)
        .whereType<SceneBattlePayload>()
        .single;
    expect(finalBattle.battleKind, 'static');
    expect(finalBattle.battleTemplateId, 'battle_lighthouse_pokemon');
    expect(finalBattle.trainerId, 'trainer_boss_phare_pokemon');
    final finalBattleContract =
        buildBattlePublicContracts(manifest).singleWhere(
      (contract) => contract.trainerId == 'trainer_boss_phare_pokemon',
    );
    expect(
      finalBattleContract.battleKind,
      BattlePublicContractKind.staticEncounter,
    );
    expect(
        finalBattleContract.battleRefId, 'static:trainer_boss_phare_pokemon');
    expect(
      finalBattleContract.battleTemplateId,
      'battle_lighthouse_pokemon',
    );
    expect(
      finalBattleContract.status,
      LinkedAssetContractStatus.available,
    );
    expect(
      _scenesCompletingStep(manifest, 'step_climb_lighthouse'),
      <String>{'scene_lighthouse_guardian_2'},
    );
    for (final cinematic in manifest.cinematics.where(
      (entry) => canonicalSelbrumeCinematicIds.contains(entry.id),
    )) {
      expect(cinematic.timeline.steps.length, greaterThanOrEqualTo(3),
          reason: cinematic.id);
      expect(
        cinematic.timeline.steps.map((step) => step.kind).toSet(),
        isNot(equals(<CinematicTimelineStepKind>{
          CinematicTimelineStepKind.wait,
        })),
        reason: '${cinematic.id} must not remain a wait-only placeholder',
      );
    }
    _expectOutcomePathFacts(
      manifest.scenes.singleWhere((scene) => scene.id == 'scene_port_entry'),
      const <String, Set<String>>{
        'panic': {'fact_port_crowd_panicked'},
        'reassure': {'fact_port_crowd_reassured'},
      },
    );
    _expectOutcomePathFacts(
      lysaScene,
      const <String, Set<String>>{
        'confident': {'fact_lysa_tone_confident'},
        'hesitant': {'fact_lysa_tone_hesitant'},
        'aggressive': {'fact_lysa_tone_aggressive'},
      },
    );
    _expectOutcomePathFacts(
      manifest.scenes
          .singleWhere((scene) => scene.id == 'scene_goelise_nest_choice'),
      const <String, Set<String>>{
        'return_item': {'fact_goelise_object_returned'},
        'keep_item': {'fact_goelise_object_kept'},
      },
    );
    _expectYvonChoiceContract(manifest);
    _expectMistDispersalContract(manifest);
    _expectFisherEpilogueContract(manifest);
    for (final scene in manifest.scenes.where(
      (entry) => canonicalSelbrumeSceneIds.contains(entry.id),
    )) {
      final report = diagnoseSceneAgainstProject(
        scene,
        manifest,
        mapsById: mapsById,
      );
      expect(
        report.diagnostics.where(
          (diagnostic) => diagnostic.severity == SceneDiagnosticSeverity.error,
        ),
        isEmpty,
        reason: scene.id,
      );
    }
  });
}

void _expectPlayerServicesContract(
  ProjectManifest manifest,
  Map<String, MapData> mapsById,
) {
  final shop = manifest.shops.singleWhere(
    (entry) => entry.id == 'shop_port_supplies',
  );
  expect(shop.label, 'Comptoir des Brisants');
  expect(
    shop.entries.map((entry) => entry.itemId),
    const <String>['potion', 'antidote', 'poke-ball'],
  );

  final badge = manifest.badges.singleWhere(
    (entry) => entry.id == 'badge_brisants',
  );
  expect(badge.label, 'Badge des Brisants');
  expect(badge.fieldAbilityUnlock, FieldAbility.surf);

  final serviceCommands = <String, SceneInteractiveCommand>{
    for (final sceneId in const <String>[
      'scene_port_shop',
      'scene_port_pc',
      'scene_port_return_bourg',
    ])
      sceneId: manifest.scenes
          .singleWhere((scene) => scene.id == sceneId)
          .graph
          .nodes
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((payload) => payload.interactiveCommand)
          .whereType<SceneInteractiveCommand>()
          .single,
  };
  expect(
    serviceCommands['scene_port_shop'],
    SceneInteractiveCommand.openShop(shopId: 'shop_port_supplies'),
  );
  expect(
    serviceCommands['scene_port_pc'],
    SceneInteractiveCommand.openPc(storageId: 'selbrume_pc'),
  );
  expect(
    serviceCommands['scene_port_return_bourg'],
    SceneInteractiveCommand.warp(
      destinationMapId: 'map_bourg_selbrume',
      warpId: 'warp_bourg_port_arrival',
    ),
  );

  final healingConsequences = manifest.scenes
      .singleWhere((scene) => scene.id == 'scene_port_healing')
      .graph
      .nodes
      .map((node) => node.payload)
      .whereType<SceneActionPayload>()
      .map((payload) => payload.consequence)
      .whereType<SceneHealPartyConsequence>();
  expect(healingConsequences, hasLength(1));

  final victoryConsequences = manifest.scenes
      .singleWhere((scene) => scene.id == 'scene_rival_after_win')
      .graph
      .nodes
      .map((node) => node.payload)
      .whereType<SceneActionPayload>()
      .map((payload) => payload.consequence)
      .whereType<SceneConsequence>()
      .toList();
  expect(
    victoryConsequences.whereType<SceneAwardBadgeConsequence>().single.badgeId,
    'badge_brisants',
  );
  expect(
    victoryConsequences
        .whereType<SceneUnlockFieldAbilityConsequence>()
        .single
        .ability,
    FieldAbility.surf,
  );

  final port = mapsById['map_port_brisants']!;
  expect(
    port.entities.map((entity) => entity.id),
    containsAll(const <String>[
      'service_port_shop',
      'service_port_pc',
      'service_port_healing',
      'service_port_ferry',
    ]),
  );
  expect(
    port.entities.singleWhere((entity) => entity.id == 'service_port_pc').pos,
    const GridPos(x: 35, y: 19),
  );
  final portSources = manifest.eventRegistry!.records
      .map((record) => record.definitionOrNull)
      .whereType<NarrativeEventDefinition>()
      .map(
        (event) => event.source.when<String?>(
          entityInteract: (mapId, entityId) =>
              mapId == 'map_port_brisants' ? entityId : null,
          triggerEnter: (_, _) => null,
          mapEnter: (_) => null,
          outcomeReceived: (_) => null,
        ),
      )
      .whereType<String>()
      .toSet();
  expect(
    portSources,
    containsAll(const <String>{
      'service_port_shop',
      'service_port_pc',
      'service_port_healing',
      'service_port_ferry',
    }),
  );
  final portSurfGate = port.gameplayZones.singleWhere(
    (zone) => zone.id == 'zone_port_surf_training',
  );
  expect(portSurfGate.kind, GameplayZoneKind.movement);
  expect(portSurfGate.movement!.requiredMode, MovementMode.surf);
  expect(
    port.entities.map((entity) => entity.id),
    contains('surf_training_marker'),
  );

  final passage = mapsById['map_passage_dames']!;
  final surfGate = passage.gameplayZones.singleWhere(
    (zone) => zone.id == 'zone_passage_surf_gate',
  );
  expect(surfGate.kind, GameplayZoneKind.movement);
  expect(surfGate.movement!.requiredMode, MovementMode.surf);
  expect(
    passage.entities.map((entity) => entity.id),
    contains('surf_gate_marker'),
  );

  final bourg = mapsById['map_bourg_selbrume']!;
  final arrival = bourg.warps.singleWhere(
    (warp) => warp.id == 'warp_bourg_port_arrival',
  );
  expect(arrival.triggerMode, MapWarpTriggerMode.onBump);
  expect(arrival.targetMapId, 'map_port_brisants');
}

void _expectSelbrumeSpecificationMatrix(ProjectManifest manifest) {
  // This is the executable translation of MVP Selbrume/selbrume.md. The
  // overview's separate "unlock passage" wording is intentionally normalized
  // into the detailed twelve-step contract's report-to-Soline beat.
  const beats = <_SelbrumeSpecificationBeat>[
    _SelbrumeSpecificationBeat(
      id: 'main-introduction',
      storylineId: 'story_main_brume_phare',
      stepIds: <String>['step_intro_selbrume', 'step_receive_mission'],
      sceneIds: <String>['scene_mael_intro'],
      factIds: <String>[
        'fact_main_story_started',
        'fact_mael_intro_done',
        'fact_mael_mission_given',
      ],
    ),
    _SelbrumeSpecificationBeat(
      id: 'main-port-alert',
      storylineId: 'story_main_brume_phare',
      stepIds: <String>['step_go_to_port'],
      sceneIds: <String>['scene_port_entry'],
      factIds: <String>[
        'fact_port_alert_seen',
        'fact_port_crowd_panicked',
        'fact_port_crowd_reassured',
      ],
    ),
    _SelbrumeSpecificationBeat(
      id: 'main-rival',
      storylineId: 'story_main_brume_phare',
      stepIds: <String>['step_rival_battle'],
      sceneIds: <String>[
        'scene_lysa_port',
        'scene_rival_after_win',
        'scene_rival_after_loss',
      ],
      factIds: <String>[
        'fact_rival_port_defeated',
        'fact_rival_port_lost_once',
        'fact_lysa_respects_player',
        'fact_lysa_goes_ahead',
      ],
    ),
    _SelbrumeSpecificationBeat(
      id: 'main-marsh-entry',
      storylineId: 'story_main_brume_phare',
      stepIds: <String>['step_enter_marais'],
      sceneIds: <String>['scene_marais_entry', 'scene_mado_intro'],
      factIds: <String>['fact_marais_unlocked', 'fact_mado_met'],
    ),
    _SelbrumeSpecificationBeat(
      id: 'main-clues',
      storylineId: 'story_main_brume_phare',
      stepIds: <String>['step_find_three_clues'],
      sceneIds: <String>[
        'scene_clue_glass',
        'scene_clue_electric_tracks',
        'scene_clue_lighthouse_mark',
      ],
      factIds: <String>[
        'fact_clue_glass_found',
        'fact_clue_electric_tracks_found',
        'fact_clue_lighthouse_mark_found',
      ],
    ),
    _SelbrumeSpecificationBeat(
      id: 'main-soline-passage',
      storylineId: 'story_main_brume_phare',
      stepIds: <String>['step_report_to_soline'],
      sceneIds: <String>['scene_soline_unlock_passage'],
      factIds: <String>[
        'fact_all_clues_found',
        'fact_passage_dames_unlocked',
      ],
    ),
    _SelbrumeSpecificationBeat(
      id: 'main-lighthouse-arrival',
      storylineId: 'story_main_brume_phare',
      stepIds: <String>['step_reach_lighthouse'],
      sceneIds: <String>['scene_lighthouse_arrival'],
      factIds: <String>['fact_lighthouse_reached'],
    ),
    _SelbrumeSpecificationBeat(
      id: 'main-lighthouse-climb',
      storylineId: 'story_main_brume_phare',
      stepIds: <String>['step_climb_lighthouse'],
      sceneIds: <String>[
        'scene_lighthouse_old_note',
        'scene_lighthouse_guardian_1',
        'scene_lighthouse_guardian_2',
      ],
      factIds: <String>[
        'fact_lighthouse_old_note_read',
        'fact_lighthouse_guardian_1_defeated',
        'fact_lighthouse_guardian_2_defeated',
        'fact_lighthouse_top_unlocked',
      ],
    ),
    _SelbrumeSpecificationBeat(
      id: 'main-final',
      storylineId: 'story_main_brume_phare',
      stepIds: <String>['step_final_confrontation'],
      sceneIds: <String>['scene_final_pokemon', 'scene_mist_disperses'],
      factIds: <String>[
        'fact_lighthouse_pokemon_appeased',
        'fact_mist_source_resolved',
      ],
    ),
    _SelbrumeSpecificationBeat(
      id: 'main-epilogue',
      storylineId: 'story_main_brume_phare',
      stepIds: <String>['step_return_to_port', 'step_main_story_completed'],
      sceneIds: <String>['scene_ending_port'],
      factIds: <String>['fact_ending_seen', 'fact_main_story_completed'],
    ),
    _SelbrumeSpecificationBeat(
      id: 'side-salt-crystals',
      storylineId: 'story_side_salt_crystals',
      stepIds: <String>[
        'step_crystals_talk_to_mado',
        'step_crystals_collect_three',
        'step_crystals_return_to_mado',
        'step_crystals_completed',
      ],
      sceneIds: <String>[
        'scene_mado_intro',
        'scene_crystal_1',
        'scene_crystal_2',
        'scene_crystal_3',
        'scene_mado_crystals_return',
      ],
      factIds: <String>[
        'fact_crystals_quest_started',
        'fact_crystal_1_found',
        'fact_crystal_2_found',
        'fact_crystal_3_found',
        'fact_all_crystals_found',
        'fact_crystals_quest_completed',
      ],
    ),
    _SelbrumeSpecificationBeat(
      id: 'side-goelise',
      storylineId: 'story_side_goelise_port',
      stepIds: <String>[
        'step_goelise_talk_to_fisher',
        'step_goelise_find_nest',
        'step_goelise_choice',
        'step_goelise_return',
        'step_goelise_completed',
      ],
      sceneIds: <String>[
        'scene_goelise_fisher_intro',
        'scene_goelise_nest_choice',
        'scene_goelise_return',
        'scene_goelise_keep_reward',
      ],
      factIds: <String>[
        'fact_goelise_quest_started',
        'fact_goelise_nest_found',
        'fact_goelise_object_returned',
        'fact_goelise_object_kept',
        'fact_goelise_quest_completed',
      ],
    ),
    _SelbrumeSpecificationBeat(
      id: 'side-lighthouse-cabin',
      storylineId: 'story_side_lighthouse_cabin',
      stepIds: <String>[
        'step_cabin_talk_to_yvon',
        'step_cabin_find_key',
        'step_cabin_open_door',
        'step_cabin_read_journal',
        'step_cabin_completed',
      ],
      sceneIds: <String>[
        'scene_yvon_intro',
        'scene_cabin_key',
        'scene_cabin_journal',
      ],
      factIds: <String>[
        'fact_cabin_quest_started',
        'fact_cabin_key_found',
        'fact_cabin_opened',
        'fact_cabin_journal_read',
        'fact_cabin_quest_completed',
      ],
    ),
  ];

  final storylinesById = <String, StorylineAsset>{
    for (final storyline in manifest.storylines) storyline.id: storyline,
  };
  final scenesById = <String, SceneAsset>{
    for (final scene in manifest.scenes) scene.id: scene,
  };
  final facts = manifest.facts.map((fact) => fact.id).toSet();
  final activeEventSceneIds = <String>{
    for (final record in manifest.eventRegistry!.records)
      if (record.enabledOrNull == true && record.definitionOrNull != null)
        record.definitionOrNull!.sceneId,
  };

  for (final beat in beats) {
    final storyline = storylinesById[beat.storylineId];
    expect(storyline, isNotNull, reason: beat.id);
    final stepsById = <String, StorylineStep>{
      for (final chapter in storyline!.chapters)
        for (final step in chapter.steps) step.id: step,
    };
    expect(stepsById.keys, containsAll(beat.stepIds), reason: beat.id);
    final linkedSceneIds = <String>{
      for (final stepId in beat.stepIds) ...stepsById[stepId]!.sceneLinkIds,
    };
    expect(linkedSceneIds, containsAll(beat.sceneIds), reason: beat.id);
    expect(scenesById.keys, containsAll(beat.sceneIds), reason: beat.id);
    expect(activeEventSceneIds, containsAll(beat.sceneIds), reason: beat.id);
    expect(facts, containsAll(beat.factIds), reason: beat.id);
  }

  for (final sideQuest in manifest.storylines.where(
    (storyline) => storyline.type == StorylineType.sideQuest,
  )) {
    expect(sideQuest.relationships, isNotEmpty, reason: sideQuest.id);
    expect(
      sideQuest.relationships.map((relationship) => relationship.kind),
      everyElement(StorylineRelationshipKind.sideQuestAvailableDuring),
      reason: '${sideQuest.id} must stay optional for the main campaign.',
    );
  }
  expect(
    storylinesById['story_main_brume_phare']!.relationships,
    isEmpty,
    reason: 'The main campaign must not require a side quest.',
  );
}

void _expectCanonicalOutcomePolicies(ProjectManifest manifest) {
  // The Validator must read explicit product intent here; labels such as
  // "Défaite" are presentation text and must never drive retry semantics.
  const expected = <String, Map<String, SceneOutcomePolicy>>{
    'scene_lysa_port': <String, SceneOutcomePolicy>{
      'lysa.victory': SceneOutcomePolicy.progression,
      'lysa.defeat': SceneOutcomePolicy.terminalFailureAccepted,
    },
    'scene_lighthouse_guardian_1': <String, SceneOutcomePolicy>{
      'lighthouse.guardian_1.victory': SceneOutcomePolicy.progression,
      'lighthouse.guardian_1.defeat': SceneOutcomePolicy.retryable,
    },
    'scene_lighthouse_guardian_2': <String, SceneOutcomePolicy>{
      'lighthouse.guardian_2.victory': SceneOutcomePolicy.progression,
      'lighthouse.guardian_2.defeat': SceneOutcomePolicy.retryable,
    },
    'scene_final_pokemon': <String, SceneOutcomePolicy>{
      'lighthouse.pokemon.appeased': SceneOutcomePolicy.progression,
      'lighthouse.pokemon.defeat': SceneOutcomePolicy.retryable,
    },
    'scene_mist_disperses': <String, SceneOutcomePolicy>{
      'mist_resolved': SceneOutcomePolicy.progression,
    },
  };
  for (final entry in expected.entries) {
    final scene = manifest.scenes.singleWhere((scene) => scene.id == entry.key);
    final policiesByOutcome = <String, SceneOutcomePolicy?>{
      for (final end in scene.graph.nodes
          .map((node) => node.payload)
          .whereType<SceneEndPayload>())
        ?end.sceneOutcomeId: end.outcomePolicy,
    };
    expect(policiesByOutcome, entry.value, reason: entry.key);
  }
}

final class _SelbrumeSpecificationBeat {
  const _SelbrumeSpecificationBeat({
    required this.id,
    required this.storylineId,
    required this.stepIds,
    required this.sceneIds,
    required this.factIds,
  });

  final String id;
  final String storylineId;
  final List<String> stepIds;
  final List<String> sceneIds;
  final List<String> factIds;
}

void _expectWorldStateContract(
  ProjectManifest manifest,
  Map<String, MapData> mapsById,
) {
  const blockingEntities = <String, List<String>>{
    'map_bourg_selbrume': <String>[
      'gate_bourg_to_port',
      'gate_bourg_to_bois',
    ],
    'map_bois_chaise_brume': <String>['gate_bois_to_marais'],
    'map_marais_salants': <String>['gate_marais_to_passage'],
    'map_passage_dames': <String>['gate_passage_to_phare'],
    'map_phare_exterieur': <String>['gate_cabin_door'],
    'map_phare_interieur': <String>['gate_lighthouse_top'],
    'map_cabane_gardien': <String>['gate_cabin_shortcut'],
  };
  for (final entry in blockingEntities.entries) {
    final entities = {
      for (final entity in mapsById[entry.key]!.entities) entity.id: entity,
    };
    for (final entityId in entry.value) {
      final entity = entities[entityId];
      expect(entity, isNotNull, reason: '${entry.key}:$entityId');
      expect(entity!.blocksMovement, isTrue, reason: entityId);
      expect(entity.sign?.plainText.trim(), isNotEmpty, reason: entityId);
    }
  }

  const visualEntities = <String, Map<String, String>>{
    'map_port_brisants': <String, String>{
      'goelise_nest_proxy': 'el_port_ref_nest',
    },
    'map_marais_salants': <String, String>{
      'clue_glass_object': 'el_selbrume_indice_verre',
      'clue_electric_object': 'el_selbrume_indice_traces_electriques',
      'clue_lens_object': 'el_selbrume_indice_repere_lentille',
      'crystal_1_object': 'el_selbrume_cristal_1',
      'crystal_2_object': 'el_selbrume_cristal_2',
      'crystal_3_object': 'el_selbrume_cristal_3',
      'fog_marais': 'el_selbrume_fx_brume_basse',
    },
    'map_phare_exterieur': <String, String>{
      'cabin_key_object': 'el_selbrume_cabane_cle',
      'fog_phare': 'el_selbrume_fx_brume_basse',
    },
    'map_sommet_phare': <String, String>{
      'boss_phare_pokemon': 'el_selbrume_fx_lumiere_instable',
      'fog_sommet': 'el_selbrume_fx_brume_basse',
    },
  };
  for (final mapEntry in visualEntities.entries) {
    final entities = {
      for (final entity in mapsById[mapEntry.key]!.entities) entity.id: entity,
    };
    for (final visualEntry in mapEntry.value.entries) {
      expect(
        entities[visualEntry.key]?.editorVisual?.elementId,
        visualEntry.value,
        reason: '${mapEntry.key}:${visualEntry.key}',
      );
    }
  }

  final rulesByTarget = <String, WorldRuleDefinition>{
    for (final rule in manifest.worldRules)
      if (rule.tags.contains('canonical-narrative'))
        '${rule.target.mapId}:${rule.target.entityId}': rule,
  };
  for (final entry in blockingEntities.entries) {
    for (final entityId in entry.value) {
      final rule = rulesByTarget['${entry.key}:$entityId'];
      expect(rule, isNotNull, reason: '${entry.key}:$entityId');
      expect(rule!.effect.kind, WorldRuleEffectKind.entityHidden);
    }
  }
  for (final target in const <String>[
    'map_port_brisants:goelise_nest_proxy',
    'map_port_brisants:fog_port',
    'map_marais_salants:fog_marais',
    'map_passage_dames:fog_passage',
    'map_phare_exterieur:fog_phare',
    'map_sommet_phare:fog_sommet',
    'map_sommet_phare:boss_phare_pokemon',
  ]) {
    expect(rulesByTarget, contains(target), reason: target);
  }
  final goeliseRule = rulesByTarget['map_port_brisants:goelise_nest_proxy']!;
  expect(goeliseRule.source.kind, WorldRuleSourceKind.fact);
  expect(goeliseRule.source.sourceId, 'fact_goelise_quest_completed');
  expect(goeliseRule.effect.kind, WorldRuleEffectKind.entityHidden);

  expect(
    mapsById['map_port_brisants']!.placedElements.map((entry) => entry.id),
    isNot(contains('pe_port_nid_goelise')),
    reason:
        'The static nest placement would remain visible after the proxy is hidden.',
  );

  final diagnostics = diagnoseWorldRules(
    manifest,
    maps: mapsById.values.toList(growable: false),
  ).diagnostics.where(
        (diagnostic) => manifest.worldRules
            .singleWhere((rule) => rule.id == diagnostic.ruleId)
            .tags
            .contains('canonical-narrative'),
      );
  expect(
    diagnostics.where(
      (diagnostic) => diagnostic.severity == WorldRuleDiagnosticSeverity.error,
    ),
    isEmpty,
    reason: diagnostics
        .map((diagnostic) =>
            '${diagnostic.ruleId}:${diagnostic.code.name}:${diagnostic.message}')
        .join('\n'),
  );
}

void _expectCanonicalEventProgression(ProjectManifest manifest) {
  final definitions = <String, NarrativeEventDefinition>{
    for (final record in manifest.eventRegistry!.records)
      ?record.definitionOrNull?.id: ?record.definitionOrNull,
  };
  Set<String> requiredTrueFacts(String eventId) => definitions[eventId]!
      .conditions
      .map((condition) => condition.when(
            fact: (factId, value) => value ? factId : null,
            narrativeEventConsumed: (_, _) => null,
          ))
      .whereType<String>()
      .toSet();

  expect(
    requiredTrueFacts('evt_019abcde-4000-7000-8000-000000000001'),
    contains('fact_port_alert_seen'),
  );
  final yvon = definitions['evt_019abcde-5000-7000-8000-000000000024']!;
  expect(yvon.reusePolicy, NarrativeEventReusePolicy.reusable);
  expect(
    yvon.conditions.map((condition) => condition.when(
          fact: (factId, value) => (factId: factId, value: value),
          narrativeEventConsumed: (_, _) => null,
        )),
    contains((factId: 'fact_cabin_quest_started', value: false)),
  );

  // The lighthouse defeat branches complete normally. Their Events therefore
  // stay reusable until a persisted victory Fact makes the source ineligible;
  // otherwise a single loss would consume the only route to the epilogue.
  const lighthouseRetryFacts = <String, String>{
    'evt_019abcde-5000-7000-8000-000000000026':
        'fact_lighthouse_guardian_1_defeated',
    'evt_019abcde-5000-7000-8000-000000000027':
        'fact_lighthouse_guardian_2_defeated',
    'evt_019abcde-5000-7000-8000-000000000028': 'fact_mist_source_resolved',
  };
  for (final entry in lighthouseRetryFacts.entries) {
    final encounter = definitions[entry.key]!;
    expect(encounter.reusePolicy, NarrativeEventReusePolicy.reusable);
    expect(
      encounter.conditions.map((condition) => condition.when(
            fact: (factId, value) => (factId: factId, value: value),
            narrativeEventConsumed: (_, _) => null,
          )),
      contains((factId: entry.value, value: false)),
      reason: '${entry.key} must close permanently after victory.',
    );
  }

  final mistDispersal =
      definitions['evt_019abcde-5000-7000-8000-000000000036']!;
  expect(mistDispersal.sceneId, 'scene_mist_disperses');
  mistDispersal.source.when(
    entityInteract: (_, _) => fail('La dissipation vient du boss.'),
    triggerEnter: (_, _) => fail('La dissipation vient du boss.'),
    mapEnter: (_) => fail('La dissipation vient du boss.'),
    outcomeReceived: (outcome) {
      expect(outcome.producerKind, NarrativeOutcomeProducerKind.scene);
      expect(outcome.producerId, 'scene_final_pokemon');
      expect(outcome.outcomeId, 'lighthouse.pokemon.appeased');
    },
  );
  expect(
    requiredTrueFacts('evt_019abcde-4000-7000-8000-000000000002'),
    contains('fact_mael_mission_given'),
  );
  expect(
    requiredTrueFacts('evt_019abcde-4000-7000-8000-000000000003'),
    contains('fact_mado_met'),
  );
  expect(
    requiredTrueFacts('evt_019abcde-5000-7000-8000-000000000020'),
    contains('fact_lysa_goes_ahead'),
  );
  expect(
    requiredTrueFacts('evt_019abcde-5000-7000-8000-000000000027'),
    containsAll(<String>[
      'fact_lighthouse_old_note_read',
      'fact_lighthouse_guardian_1_defeated',
    ]),
  );
  final cabinKey = definitions['evt_019abcde-5000-7000-8000-000000000029']!;
  cabinKey.source.when(
    entityInteract: (_, _) => fail('La clé doit être trouvée dans une zone.'),
    triggerEnter: (mapId, triggerId) {
      expect(mapId, 'map_phare_exterieur');
      expect(triggerId, 'tr_cabin_key_outside');
    },
    mapEnter: (_) => fail('La clé doit avoir une source spatiale précise.'),
    outcomeReceived: (_) => fail('La clé ne provient pas d’un outcome.'),
  );
}

void _expectYvonChoiceContract(ProjectManifest manifest) {
  final scene = manifest.scenes.singleWhere(
    (entry) => entry.id == 'scene_yvon_intro',
  );
  final dialogue = scene.graph.nodes.singleWhere(
    (node) => node.kind == SceneNodeKind.yarnDialogue,
  );
  final payload = dialogue.payload as SceneYarnDialoguePayload;
  expect(
    payload.expectedOutcomes,
    const <String>['accept_search_key', 'ignore_for_now'],
  );

  final acceptConsequences = _reachableConsequences(
    scene,
    dialogue.id,
    'accept_search_key',
  );
  expect(
    acceptConsequences.whereType<SceneSetFactConsequence>().map(
          (consequence) => consequence.factId,
        ),
    contains('fact_cabin_quest_started'),
  );
  expect(
    acceptConsequences.whereType<SceneCompleteStoryStepConsequence>().map(
          (consequence) => consequence.stepId,
        ),
    contains('step_cabin_talk_to_yvon'),
  );

  expect(
    _reachableConsequences(scene, dialogue.id, 'ignore_for_now'),
    isEmpty,
    reason: 'Refuser pour le moment ne doit rien persister.',
  );
}

void _expectMistDispersalContract(ProjectManifest manifest) {
  final finalScene = manifest.scenes.singleWhere(
    (entry) => entry.id == 'scene_final_pokemon',
  );
  expect(
    finalScene.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneCinematicPayload>()
        .map((payload) => payload.cinematicId),
    isNot(contains('cinematic_mist_disperses')),
    reason: 'La réaction post-boss appartient à scene_mist_disperses.',
  );

  final scene = manifest.scenes.singleWhere(
    (entry) => entry.id == 'scene_mist_disperses',
  );
  expect(
    scene.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneCinematicPayload>()
        .map((payload) => payload.cinematicId),
    contains('cinematic_mist_disperses'),
  );
  final dialogue = scene.graph.nodes
      .map((node) => node.payload)
      .whereType<SceneYarnDialoguePayload>()
      .single;
  expect(dialogue.dialogueId, 'dialogue_lighthouse');
  expect(dialogue.yarnNodeName, 'MistDisperses');
  expect(
    scene.declaredOutcomes.map((outcome) => outcome.id),
    contains('mist_resolved'),
  );
  final end = scene.graph.nodes
      .map((node) => node.payload)
      .whereType<SceneEndPayload>()
      .single;
  expect(end.sceneOutcomeId, 'mist_resolved');
}

void _expectFisherEpilogueContract(ProjectManifest manifest) {
  final dialogue = manifest.dialogues.singleWhere(
    (entry) => entry.id == 'dialogue_fisher_epilogue',
  );
  expect(dialogue.defaultStartNode, 'FisherEpilogue');

  final rule = manifest.worldRules.singleWhere(
    (entry) => entry.id == 'world_rule_fisher_epilogue',
  );
  expect(rule.source.kind, WorldRuleSourceKind.fact);
  expect(rule.source.sourceId, 'fact_main_story_completed');
  expect(rule.target.mapId, 'map_port_brisants');
  expect(rule.target.entityId, 'npc_pecheur');
  expect(rule.effect.dialogueId, 'dialogue_fisher_epilogue');
  expect(rule.priority, 100);
}

Set<String> _scenesCompletingStep(
  ProjectManifest manifest,
  String stepId,
) =>
    <String>{
      for (final scene in manifest.scenes)
        if (scene.graph.nodes.any(
          (node) =>
              node.payload is SceneActionPayload &&
              (node.payload as SceneActionPayload).consequence
                  is SceneCompleteStoryStepConsequence &&
              ((node.payload as SceneActionPayload).consequence
                          as SceneCompleteStoryStepConsequence)
                      .stepId ==
                  stepId,
        ))
          scene.id,
    };

void _expectStarterBranches(ProjectManifest manifest) {
  final scene = manifest.scenes.singleWhere(
    (entry) => entry.id == 'scene_mael_intro',
  );
  expect(
    manifest.newGame.starterOptions
        .singleWhere((option) => option.id == 'starter_squirtle')
        .pokemon
        .knownMoveIds,
    contains(FieldAbility.surf.moveId),
    reason: 'Le starter eau doit rendre le field gate Surf jouable après le '
        'déblocage narratif.',
  );
  final starterDialogue = scene.graph.nodes.singleWhere((node) {
    final payload = node.payload;
    return payload is SceneYarnDialoguePayload &&
        payload.yarnNodeName == 'MaelStarterChoice';
  });
  final payload = starterDialogue.payload as SceneYarnDialoguePayload;
  expect(
    payload.expectedOutcomes,
    const <String>[
      'starter_bulbasaur',
      'starter_charmander',
      'starter_squirtle',
    ],
  );
  for (final outcome in payload.expectedOutcomes) {
    final consequences = _reachableConsequences(
      scene,
      starterDialogue.id,
      outcome,
    );
    final starterGrants =
        consequences.whereType<SceneGiveConfiguredStarterConsequence>();
    expect(starterGrants, hasLength(1), reason: outcome);
    expect(starterGrants.single.starterOptionId, outcome, reason: outcome);
    expect(
      consequences
          .whereType<SceneSetFactConsequence>()
          .map((entry) => entry.factId),
      containsAll(<String>[
        'fact_starter_received',
        'fact_mael_mission_given',
      ]),
      reason: outcome,
    );
    final ballGrants = consequences
        .whereType<SceneGiveItemConsequence>()
        .where((entry) => entry.itemId == 'poke-ball');
    expect(ballGrants, hasLength(1), reason: outcome);
    expect(ballGrants.single.quantity, 5, reason: outcome);
  }

  final existingPokemonDialogue = scene.graph.nodes.singleWhere((node) {
    final nodePayload = node.payload;
    return nodePayload is SceneYarnDialoguePayload &&
        nodePayload.yarnNodeName == 'MaelExistingPokemon';
  });
  final existingPartyBallGrants = _reachableConsequences(
    scene,
    existingPokemonDialogue.id,
    'completed',
  )
      .whereType<SceneGiveItemConsequence>()
      .where((entry) => entry.itemId == 'poke-ball');
  expect(existingPartyBallGrants, hasLength(1));
  expect(existingPartyBallGrants.single.quantity, 5);
}

void _expectCanonicalRewards(ProjectManifest manifest) {
  final expectedKindsByScene = <String, Set<SceneConsequenceKind>>{
    'scene_mado_crystals_return': <SceneConsequenceKind>{
      SceneConsequenceKind.giveItem,
    },
    'scene_goelise_return': <SceneConsequenceKind>{
      SceneConsequenceKind.giveMoney,
    },
    'scene_goelise_keep_reward': <SceneConsequenceKind>{
      SceneConsequenceKind.giveItem,
    },
    'scene_cabin_journal': <SceneConsequenceKind>{
      SceneConsequenceKind.giveItem,
    },
  };
  for (final entry in expectedKindsByScene.entries) {
    final scene = manifest.scenes.singleWhere((scene) => scene.id == entry.key);
    final kinds = scene.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((payload) => payload.consequence?.kind)
        .whereType<SceneConsequenceKind>()
        .toSet();
    expect(kinds, containsAll(entry.value), reason: entry.key);
  }
}

List<SceneConsequence> _reachableConsequences(
  SceneAsset scene,
  String fromNodeId,
  String fromPortId,
) {
  final nodesById = <String, SceneNode>{
    for (final node in scene.graph.nodes) node.id: node,
  };
  final pending = scene.graph.edges
      .where(
        (edge) =>
            edge.fromNodeId == fromNodeId && edge.fromPortId == fromPortId,
      )
      .map((edge) => edge.toNodeId)
      .toList();
  final visited = <String>{};
  final consequences = <SceneConsequence>[];
  while (pending.isNotEmpty) {
    final nodeId = pending.removeLast();
    if (!visited.add(nodeId)) continue;
    final node = nodesById[nodeId];
    if (node?.payload case SceneActionPayload(:final consequence?)) {
      consequences.add(consequence);
    }
    pending.addAll(
      scene.graph.edges
          .where((edge) => edge.fromNodeId == nodeId)
          .map((edge) => edge.toNodeId),
    );
  }
  return consequences;
}

void _expectDialogueOutcomeContract(
  Directory fixture,
  ProjectManifest manifest,
  String dialogueId,
  List<String> expectedOutcomeIds,
) {
  final dialogue =
      manifest.dialogues.singleWhere((entry) => entry.id == dialogueId);
  expect(
    dialogue.declaredOutcomes.map((outcome) => outcome.id),
    expectedOutcomeIds,
    reason: dialogueId,
  );
  final yarn =
      File(p.join(fixture.path, dialogue.relativePath)).readAsStringSync();
  for (final outcomeId in expectedOutcomeIds) {
    expect(yarn, contains('<<outcome $outcomeId>>'), reason: dialogueId);
  }
}

void _expectOutcomePathFacts(
  SceneAsset scene,
  Map<String, Set<String>> expectedByOutcome,
) {
  final dialogueNode = scene.graph.nodes
      .singleWhere((node) => node.kind == SceneNodeKind.yarnDialogue);
  final payload = dialogueNode.payload as SceneYarnDialoguePayload;
  expect(payload.expectedOutcomes, expectedByOutcome.keys);
  final outgoingPorts = scene.graph.edges
      .where((edge) => edge.fromNodeId == dialogueNode.id)
      .map((edge) => edge.fromPortId)
      .toSet();
  expect(
      outgoingPorts,
      containsAll(<String>{
        'completed',
        ...expectedByOutcome.keys,
      }));

  for (final entry in expectedByOutcome.entries) {
    final factIds = _reachableFactIds(scene, dialogueNode.id, entry.key);
    expect(factIds, containsAll(entry.value),
        reason: '${scene.id}:${entry.key}');
    final otherFacts = expectedByOutcome.entries
        .where((candidate) => candidate.key != entry.key)
        .expand((candidate) => candidate.value);
    expect(
      factIds.intersection(otherFacts.toSet()),
      isEmpty,
      reason: '${scene.id}:${entry.key} must not apply another choice fact',
    );
  }
}

Set<String> _reachableFactIds(
  SceneAsset scene,
  String fromNodeId,
  String fromPortId,
) {
  final nodesById = <String, SceneNode>{
    for (final node in scene.graph.nodes) node.id: node,
  };
  final pending = scene.graph.edges
      .where(
        (edge) =>
            edge.fromNodeId == fromNodeId && edge.fromPortId == fromPortId,
      )
      .map((edge) => edge.toNodeId)
      .toList();
  final visited = <String>{};
  final facts = <String>{};
  while (pending.isNotEmpty) {
    final nodeId = pending.removeLast();
    if (!visited.add(nodeId)) continue;
    final node = nodesById[nodeId];
    if (node?.payload case SceneActionPayload(:final consequence)) {
      if (consequence case SceneSetFactConsequence(:final factId)) {
        facts.add(factId);
      }
    }
    pending.addAll(
      scene.graph.edges
          .where((edge) => edge.fromNodeId == nodeId)
          .map((edge) => edge.toNodeId),
    );
  }
  return facts;
}

Map<String, List<int>> _authoredBytes(Directory fixture) {
  final files = <File>[
    File(p.join(fixture.path, 'project.json')),
    ...Directory(p.join(fixture.path, 'maps'))
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json')),
    ...Directory(p.join(fixture.path, 'dialogues'))
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.yarn')),
  ]..sort((left, right) => left.path.compareTo(right.path));
  return <String, List<int>>{
    for (final file in files)
      p.relative(file.path, from: fixture.path): file.readAsBytesSync(),
  };
}

void _expectDialogueFilesAndNodes(
  Directory fixture,
  ProjectManifest manifest,
) {
  for (final dialogue in manifest.dialogues.where(
    (entry) => canonicalSelbrumeDialogueIds.contains(entry.id),
  )) {
    final file = File(p.join(fixture.path, dialogue.relativePath));
    expect(file.existsSync(), isTrue, reason: dialogue.id);
    final content = file.readAsStringSync();
    expect(content, contains('title: ${dialogue.defaultStartNode}'));
    expect(content, contains('==='));
  }
}

void _expectEventSourcesClose(
  Directory fixture,
  ProjectManifest manifest,
) {
  final registry = manifest.eventRegistry!;
  expect(registry.records.length, greaterThanOrEqualTo(20));
  final sceneIds = manifest.scenes.map((scene) => scene.id).toSet();
  final facts = manifest.facts.map((fact) => fact.id).toSet();
  final mapCache = <String, Map<String, dynamic>>{};

  for (final record in registry.records) {
    final definition = record.definitionOrNull;
    if (definition == null) continue;
    expect(sceneIds, contains(definition.sceneId), reason: definition.id);
    for (final condition in definition.conditions) {
      condition.when(
        fact: (factId, _) =>
            expect(facts, contains(factId), reason: definition.id),
        narrativeEventConsumed: (_, _) {},
      );
    }
    definition.source.when(
      entityInteract: (mapId, entityId) {
        final map = _mapJson(fixture, manifest, mapCache, mapId);
        final ids = (map['entities'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((entry) => entry['id']);
        expect(ids, contains(entityId), reason: definition.id);
      },
      triggerEnter: (mapId, triggerId) {
        final map = _mapJson(fixture, manifest, mapCache, mapId);
        final ids = (map['triggers'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((entry) => entry['id']);
        expect(ids, contains(triggerId), reason: definition.id);
      },
      mapEnter: (mapId) {
        _mapJson(fixture, manifest, mapCache, mapId);
      },
      outcomeReceived: (_) {},
    );
  }
}

Map<String, dynamic> _mapJson(
  Directory fixture,
  ProjectManifest manifest,
  Map<String, Map<String, dynamic>> cache,
  String mapId,
) {
  return cache.putIfAbsent(mapId, () {
    final entry =
        manifest.maps.singleWhere((candidate) => candidate.id == mapId);
    return _readJson(File(p.join(fixture.path, entry.relativePath)));
  });
}

void _expectMapNpc(
  Directory fixture,
  String mapId,
  String entityId,
  String characterId,
) {
  final map = _readJson(File(p.join(fixture.path, 'maps', '$mapId.json')));
  final entity = (map['entities'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .singleWhere((entry) => entry['id'] == entityId);
  expect(entity['kind'], 'npc');
  expect((entity['npc'] as Map<String, dynamic>)['characterId'], characterId);
}

Directory _copySelbrumeFixture() {
  final repositoryRoot = _findRepositoryRoot();
  final source = Directory(p.join(repositoryRoot.path, 'selbrume'));
  final parent = Directory.systemTemp.createTempSync('pokemap_selbrume_seed_');
  final target = Directory(p.join(parent.path, 'selbrume'))..createSync();

  File(p.join(source.path, 'project.json'))
      .copySync(p.join(target.path, 'project.json'));
  for (final directoryName in const <String>['maps', 'dialogues']) {
    final sourceDirectory = Directory(p.join(source.path, directoryName));
    final targetDirectory = Directory(p.join(target.path, directoryName))
      ..createSync(recursive: true);
    for (final file in sourceDirectory.listSync().whereType<File>()) {
      file.copySync(p.join(targetDirectory.path, p.basename(file.path)));
    }
  }
  // Force one deterministic divergence even when the checked-in project has
  // already been seeded, so the first pass still proves repair behavior.
  final ending = File(p.join(target.path, 'dialogues', 'ending_port.yarn'));
  if (ending.existsSync()) ending.deleteSync();
  return target;
}

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

Map<String, dynamic> _readJson(File file) {
  return (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();
}
