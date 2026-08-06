// TEMPORARY generator. Emits the JSON fragments spliced into project.json.
// Delete after use.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

const _out =
    '/private/tmp/claude-501/-Users-karim-Project-pokemonProject/b87054f1-b2df-44c4-beb6-5e75d36238ea/scratchpad/scenario_seed.json';

const _startMapId = 'map_hanazuki_guesthouse_room';
const _startSpawnId = 'spawn';
const _sceneId = 'scene_ligne_des_cedres';

void main() {
  test('emit scenario seed', () {
    final facts = <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: 'fact_aki_letter_received',
        label: 'Lettre d’Aki reçue',
        description: 'Le joueur détient la lettre scellée destinée à '
            'Shūhei Sagara, gare de Kisaragi.',
        category: 'prologue',
      ),
      NarrativeFactDefinition(
        id: 'fact_starter_received',
        label: 'Partenaire reçu',
        description: 'Shizune Mori a confié son premier partenaire au joueur. '
            'Condition de sortie de la chambre de la pension.',
        category: 'prologue',
      ),
      NarrativeFactDefinition(
        id: 'fact_journey_started',
        label: 'Voyage commencé',
        description: 'Le joueur a quitté la pension pour rejoindre la Ligne '
            'des Cèdres.',
        category: 'prologue',
      ),
      NarrativeFactDefinition(
        id: 'fact_aki_letter_delivered',
        label: 'Lettre d’Aki remise',
        description: 'La lettre a été remise en main propre à Shūhei Sagara. '
            'Condition de complétion du jeu.',
        category: 'epilogue',
      ),
    ];

    final scene = SceneAsset(
      id: _sceneId,
      name: 'Ligne des Cèdres — colonne narrative',
      description: 'Squelette de la colonne narrative. Le prologue M00 est '
          'authoré ; les chapitres 1 à 7 restent à écrire entre '
          '« prologue_depart » et « epilogue_service_1742 ».',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(
            id: 'start',
            kind: SceneNodeKind.start,
            title: 'Réveil à la pension d’Hanazuki',
          ),
          SceneNode(
            id: 'prologue_lettre',
            kind: SceneNodeKind.action,
            title: 'Enveloppe d’Aki',
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(
                factId: 'fact_aki_letter_received',
                value: true,
                label: 'Le joueur prend la lettre scellée d’Aki',
              ),
            ),
          ),
          SceneNode(
            id: 'prologue_partenaire',
            kind: SceneNodeKind.action,
            title: 'Boîte de voyage — Shizune confie un partenaire',
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(
                factId: 'fact_starter_received',
                value: true,
                label: 'Feuille, flamme ou vague : le partenaire est choisi',
              ),
            ),
          ),
          SceneNode(
            id: 'prologue_depart',
            kind: SceneNodeKind.action,
            title: 'Sortie vers le village d’Hanazuki',
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(
                factId: 'fact_journey_started',
                value: true,
                label: 'Aller voir Kenzō à la gare pour les Jetons de Ligne',
              ),
            ),
          ),
          SceneNode(
            id: 'chapitres_a_ecrire',
            kind: SceneNodeKind.merge,
            title: 'Chapitres 1 à 7 — à authorer',
            payload: SceneMergePayload(),
          ),
          SceneNode(
            id: 'remise_lettre_kisaragi',
            kind: SceneNodeKind.action,
            title: 'Kisaragi — la lettre est remise à Shūhei',
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(
                factId: 'fact_aki_letter_delivered',
                value: true,
                label: 'Remise en main propre à l’observatoire du signal',
              ),
            ),
          ),
          SceneNode(
            id: 'epilogue_service_1742',
            kind: SceneNodeKind.action,
            title: 'Épilogue — service officiel de 17 h 42',
            payload: SceneActionPayload.consequence(
              SceneConsequence.finishGame(
                endingId: 'ending_service_officiel_1742',
                outcome: SceneGameCompletionOutcome.completed,
                result: SceneFinishGameResult(
                  title: SceneLocalizedText(
                    fallback: 'Service officiel de 17 h 42',
                  ),
                  summary: SceneLocalizedText(
                    fallback: 'À 17 h 42, le signal passa au vert. '
                        'Et, pour la première fois, personne n’en eut peur.',
                  ),
                ),
                postGamePolicy: ScenePostGamePolicy.returnToTitle,
              ),
            ),
          ),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            title: 'Fin',
            payload: SceneEndPayload(
              outcomePolicy: SceneOutcomePolicy.progression,
            ),
          ),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'e_start_lettre',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'prologue_lettre',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'e_lettre_partenaire',
            fromNodeId: 'prologue_lettre',
            fromPortId: 'completed',
            toNodeId: 'prologue_partenaire',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'e_partenaire_depart',
            fromNodeId: 'prologue_partenaire',
            fromPortId: 'completed',
            toNodeId: 'prologue_depart',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'e_depart_chapitres',
            fromNodeId: 'prologue_depart',
            fromPortId: 'completed',
            toNodeId: 'chapitres_a_ecrire',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'e_chapitres_remise',
            fromNodeId: 'chapitres_a_ecrire',
            fromPortId: 'completed',
            toNodeId: 'remise_lettre_kisaragi',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'e_remise_epilogue',
            fromNodeId: 'remise_lettre_kisaragi',
            fromPortId: 'completed',
            toNodeId: 'epilogue_service_1742',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'e_epilogue_end',
            fromNodeId: 'epilogue_service_1742',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );

    final registry = NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: 'evt_01984200-1742-7000-8a00-000000000001',
            name: 'Prologue — réveil à la pension d’Hanazuki',
            source: NarrativeEventSourceRef.mapEnter(_startMapId),
            conditions: const [],
            sceneId: _sceneId,
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const [],
    );

    const newGame = ProjectNewGameConfig(
      enabled: true,
      startMapId: _startMapId,
      startSpawnId: _startSpawnId,
      playerName: 'Player',
      playerAvatarCharacterIds: <String>['char_player_a'],
      startingMoney: 3000,
      initialBag: <BagEntry>[
        BagEntry(
          itemId: 'poke-ball',
          categoryId: 'standard-balls',
          quantity: 5,
        ),
        BagEntry(itemId: 'potion', categoryId: 'healing', quantity: 3),
      ],
      initialParty: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'bulbasaur',
          natureId: 'hardy',
          abilityId: 'overgrow',
          level: 5,
          currentHp: 20,
        ),
      ],
    );

    final payload = <String, Object?>{
      'facts': [for (final fact in facts) fact.toJson()],
      'scenes': [scene.toJson()],
      'eventRegistry': registry.toJson(),
      'newGame': newGame.toJson(),
    };
    File(_out).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    // ignore: avoid_print
    print('wrote $_out');
  });
}
