import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/presentation/flame/battle_transition_manifest.dart';
import 'package:map_runtime/src/presentation/flame/battle_transition_spec.dart';

ProjectManifest _manifest({ProjectBattleTransitionConfig? battleTransitions}) {
  return ProjectManifest(
    name: 'battle_transition_spec_test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    battleTransitions: battleTransitions,
  );
}

WildBattleStartRequest _wildRequest({String requestId = 'wild-request'}) {
  return WildBattleStartRequest(
    requestId: requestId,
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 2, y: 2),
      playerFacing: Direction.north,
    ),
    mapId: 'field_map',
    encounterSourceId: 'grass_zone',
    encounterSourceKind: EncounterSourceKind.gameplayZone,
    tableId: 'grass_table',
    encounterKind: EncounterKind.walk,
    speciesId: 'sparkitten',
    level: 5,
    minLevel: 5,
    maxLevel: 5,
    weight: 1,
    playerPos: GridPos(x: 2, y: 2),
  );
}

TrainerBattleStartRequest _trainerRequest() {
  return const TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 2, y: 2),
      playerFacing: Direction.north,
    ),
    trainerId: 'rookie',
    npcEntityId: 'npc_rookie',
    mapId: 'field_map',
    playerPos: GridPos(x: 2, y: 2),
  );
}

MapData _mapWithZoneTransitions(List<String> battleTransitionIds) {
  return MapData(
    id: 'field_map',
    name: 'Field Map',
    size: const GridSize(width: 8, height: 8),
    layers: const <MapLayer>[],
    gameplayZones: <MapGameplayZone>[
      MapGameplayZone(
        id: 'grass_zone',
        kind: GameplayZoneKind.encounter,
        area: const MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 8, height: 8),
        ),
        encounter: EncounterZonePayload(
          encounterTableId: 'grass_table',
          battleTransitionIds: battleTransitionIds,
        ),
      ),
    ],
  );
}

void main() {
  group('resolveBattleTransitionSpec — choisie par la donnée', () {
    test('sans config : défaut distinct par type de combat', () {
      expect(
        resolveBattleTransitionSpec(
          request: _wildRequest(),
          manifest: _manifest(),
        ).id,
        'rby_wild',
      );
      expect(
        resolveBattleTransitionSpec(
          request: _trainerRequest(),
          manifest: _manifest(),
        ).id,
        'dpp_trainer',
      );
    });

    test('un id connu est honoré, croisé entre les types', () {
      final manifest = _manifest(
        battleTransitions: const ProjectBattleTransitionConfig(
          wildTransitionId: 'dpp_trainer',
          trainerTransitionId: 'rby_wild',
        ),
      );
      expect(
        resolveBattleTransitionSpec(
          request: _wildRequest(),
          manifest: manifest,
        ).id,
        'dpp_trainer',
      );
      expect(
        resolveBattleTransitionSpec(
          request: _trainerRequest(),
          manifest: manifest,
        ).id,
        'rby_wild',
      );
    });

    test('un id inconnu ou blanc retombe sur le défaut du type', () {
      final manifest = _manifest(
        battleTransitions: const ProjectBattleTransitionConfig(
          wildTransitionId: 'xy_ultra_deluxe',
          trainerTransitionId: '   ',
        ),
      );
      expect(
        resolveBattleTransitionSpec(
          request: _wildRequest(),
          manifest: manifest,
        ).id,
        'rby_wild',
        reason: 'critère 2 : une transition inconnue ne casse rien',
      );
      expect(
        resolveBattleTransitionSpec(
          request: _trainerRequest(),
          manifest: manifest,
        ).id,
        'dpp_trainer',
      );
    });
  });

  group('specs — parité recontrôlée sur la source de référence', () {
    test('rby_wild : flash 1,5 s ×6, planche 10×3 en 0,5 s, noir 0,25 s', () {
      final phases = battleTransitionRbyWild.phases;
      expect(phases, hasLength(3));
      expect(
        phases[0],
        isA<TransitionFlashPhase>()
            .having((p) => p.durationSeconds, 'durée', 1.5)
            .having((p) => p.factor, 'facteur', 6),
      );
      expect(
        phases[1],
        isA<TransitionSheetCellsPhase>()
            .having((p) => p.sheetName, 'planche', 'rby_wild')
            .having((p) => p.columns, 'colonnes', 10)
            .having((p) => p.rows, 'lignes', 3)
            .having((p) => p.durationSeconds, 'durée', 0.5),
      );
      expect(
        phases[2],
        isA<TransitionHoldBlackPhase>()
            .having((p) => p.durationSeconds, 'durée', 0.25),
      );
      expect(battleTransitionRbyWild.totalSeconds, closeTo(2.25, 1e-9));
    });

    test('dpp_trainer : flash 0,7 s ×2, ball zoom+rotation, deux planches', () {
      final phases = battleTransitionDppTrainer.phases;
      expect(phases, hasLength(6));
      expect(
        phases[0],
        isA<TransitionFlashPhase>()
            .having((p) => p.durationSeconds, 'durée', 0.7)
            .having((p) => p.factor, 'facteur', 2),
      );
      expect(
        phases[1],
        isA<TransitionSpriteZoomPhase>()
            .having((p) => p.durationSeconds, 'durée', 0.4)
            .having((p) => p.zoomFrom, 'zoom départ', 0.2),
      );
      expect(
        phases[2],
        isA<TransitionSpriteAnglePhase>()
            .having((p) => p.angleFromDegrees, 'de', 90)
            .having((p) => p.angleToDegrees, 'à', -360),
      );
      expect(
        phases[3],
        isA<TransitionSheetCellsPhase>()
            .having((p) => p.sheetName, 'planche', 'diamant_perle_trainer_01')
            .having((p) => p.durationSeconds, 'durée', 0.2),
      );
      expect(
        phases[4],
        isA<TransitionSheetCellsPhase>()
            .having((p) => p.sheetName, 'planche', 'diamant_perle_trainer_02'),
      );
      expect(phases[5], isA<TransitionHoldBlackPhase>());
    });
  });

  group('BETA-BAT-019 — la chaîne dresseur > zone > projet > moteur', () {
    test(
        'la zone qui a déclenché la rencontre gagne sur le défaut projet, '
        'et le tirage est déterministe par requête', () {
      final manifest = _manifest(
        battleTransitions: const ProjectBattleTransitionConfig(
          wildTransitionId: 'rby_wild',
        ),
      );
      final map = _mapWithZoneTransitions(<String>['hgss_wild', 'rs_wild']);

      final first = resolveBattleTransitionSpec(
        request: _wildRequest(requestId: 'wild:a'),
        manifest: manifest,
        map: map,
      );
      expect(
        <String>['hgss_wild', 'rs_wild'],
        contains(first.id),
        reason: 'la zone impose son panel, pas le défaut projet',
      );
      for (var i = 0; i < 5; i++) {
        expect(
          resolveBattleTransitionSpec(
            request: _wildRequest(requestId: 'wild:a'),
            manifest: manifest,
            map: map,
          ).id,
          first.id,
          reason: 'le même requestId rejoue LA même transition — tirage '
              'déterministe, rejouable en test comme en partie chargée',
        );
      }

      final drawn = <String>{first.id};
      for (var i = 0; i < 40 && drawn.length < 2; i++) {
        drawn.add(
          resolveBattleTransitionSpec(
            request: _wildRequest(requestId: 'wild:$i'),
            manifest: manifest,
            map: map,
          ).id,
        );
      }
      expect(
        drawn,
        hasLength(2),
        reason: 'des requêtes différentes finissent par tirer les deux '
            'transitions de la zone',
      );
    });

    test(
        'les ids inconnus de la zone sont ignorés ; une liste morte rend '
        'la main au défaut projet', () {
      final manifest = _manifest(
        battleTransitions: const ProjectBattleTransitionConfig(
          wildTransitionId: 'crystal_wild',
        ),
      );
      final withOneAlive = resolveBattleTransitionSpec(
        request: _wildRequest(),
        manifest: manifest,
        map: _mapWithZoneTransitions(
            <String>['pas_une_transition', 'gold_wild']),
      );
      expect(withOneAlive.id, 'gold_wild',
          reason: 'l’id inconnu est écarté sans casser l’entrée en combat');

      final allDead = resolveBattleTransitionSpec(
        request: _wildRequest(),
        manifest: manifest,
        map: _mapWithZoneTransitions(<String>['toujours_pas']),
      );
      expect(allDead.id, 'crystal_wild',
          reason: 'liste morte : la chaîne continue vers le défaut projet');
    });

    test(
        'la transition authorée du dresseur gagne sur tout, un id inconnu '
        'rend la main à la chaîne', () {
      final manifest = ProjectManifest(
        name: 'battle_transition_spec_test',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        battleTransitions: const ProjectBattleTransitionConfig(
          trainerTransitionId: 'dpp_trainer',
        ),
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'rookie',
            name: 'Rookie',
            trainerClass: 'Rookie',
            battleTransitionId: 'hgss_trainer',
          ),
          ProjectTrainerEntry(
            id: 'lost',
            name: 'Lost',
            trainerClass: 'Rookie',
            battleTransitionId: 'transition_fantome',
          ),
        ],
      );

      expect(
        resolveBattleTransitionSpec(
          request: _trainerRequest(),
          manifest: manifest,
        ).id,
        'hgss_trainer',
        reason: 'le dresseur d’abord, comme TRAINER_TRANSITIONS',
      );
    });
  });

  group('BETA-BAT-019 — le panel porté de la référence', () {
    test(
        'le registre porte les neuf transitions sans shader, réparties par '
        'type pour le panel d’authoring', () {
      expect(
        battleTransitionRegistry.keys,
        containsAll(<String>[
          'rby_wild',
          'gold_wild',
          'crystal_wild',
          'hgss_wild',
          'hgss_cave',
          'rs_wild',
          'dpp_wild',
          'dpp_trainer',
          'hgss_trainer',
        ]),
      );
      for (final id in battleWildTransitionIds) {
        expect(battleTransitionRegistry, contains(id),
            reason: 'chaque id du panel sauvage se résout');
      }
      for (final id in battleTrainerTransitionIds) {
        expect(battleTransitionRegistry, contains(id),
            reason: 'chaque id du panel dresseur se résout');
      }
      for (final entry in battleTransitionRegistry.entries) {
        expect(entry.value.id, entry.key,
            reason: 'l’id de la spec et la clé du registre disent pareil');
      }
    });

    test(
        'les sauvages à planche héritent du flash RBY et ne varient que par '
        'la planche et son tempo (oracle 110/150/151)', () {
      const expectations = <String, (String, double)>{
        'gold_wild': ('gold_wild', 1.0),
        'crystal_wild': ('crystal_wild', 0.5),
        'hgss_wild': ('heartgold_soulsilver_wild', 1.5),
        'hgss_cave': ('heartgold_soulsilver_cave_wild', 1.5),
      };
      for (final entry in expectations.entries) {
        final phases = battleTransitionRegistry[entry.key]!.phases;
        expect(
          phases.first,
          isA<TransitionFlashPhase>()
              .having((p) => p.durationSeconds, 'durée', 1.5)
              .having((p) => p.factor, 'facteur', 6),
          reason: '${entry.key} : create_pre_transition_animation de RBYWild '
              'porte le flash pour tous ses héritiers',
        );
        expect(
          phases[1],
          isA<TransitionSheetCellsPhase>()
              .having((p) => p.sheetName, 'planche', entry.value.$1)
              .having((p) => p.columns, 'colonnes', 10)
              .having((p) => p.rows, 'lignes', 3)
              .having((p) => p.durationSeconds, 'tempo', entry.value.$2),
          reason: '${entry.key} : pre_transition_cells_duration de l’oracle',
        );
        expect(phases[2], isA<TransitionHoldBlackPhase>());
      }
    });

    test('rs_wild et dpp_wild glissent leurs bandes en 0,7 s (oracle 120)', () {
      for (final id in <String>['rs_wild', 'dpp_wild']) {
        final phases = battleTransitionRegistry[id]!.phases;
        expect(phases.first, isA<TransitionFlashPhase>());
        expect(
          phases[1],
          isA<TransitionInterleavedBandsPhase>()
              .having((p) => p.durationSeconds, 'durée', 0.7),
          reason: '$id : ya.move(0.7, …) de RSWild',
        );
        expect(phases[2], isA<TransitionHoldBlackPhase>());
      }
    });

    test(
        'hgss_trainer rejoue toute la séquence DPP avec ses planches '
        '(oracle 154)', () {
      final phases = battleTransitionRegistry['hgss_trainer']!.phases;
      expect(phases, hasLength(6));
      expect(
        phases[3],
        isA<TransitionSheetCellsPhase>().having(
            (p) => p.sheetName, 'planche', 'heartgold_soulsilver_trainer_01'),
      );
      expect(
        phases[4],
        isA<TransitionSheetCellsPhase>().having(
            (p) => p.sheetName, 'planche', 'heartgold_soulsilver_trainer_02'),
      );
    });

    test('chaque planche du registre est réellement embarquée', () {
      for (final spec in battleTransitionRegistry.values) {
        for (final phase
            in spec.phases.whereType<TransitionSheetCellsPhase>()) {
          expect(
            battleTransitionSheetManifest,
            contains(phase.sheetName),
            reason: '${spec.id} référence ${phase.sheetName} : la planche '
                'doit être dans le manifeste embarqué',
          );
        }
      }
    });
  });
}
