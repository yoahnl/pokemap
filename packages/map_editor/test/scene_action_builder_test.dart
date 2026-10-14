import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
    'warp loads an inactive destination through the supplied map loader',
    (tester) async {
      final requested = <String>[];
      SceneNodePayload? submitted;
      await _pumpBuilder(
        tester,
        initialCommandId: NarrativeCommandIds.warp,
        initialParameters: const {'destinationMapId': 'forest'},
        options: {
          ..._warpOptions,
          NarrativeCommandParameterKind.warp: const [
            SceneActionPickerOption(
              id: 'port_arrival',
              label: 'Port · Arrivée',
              parentId: 'port',
            ),
          ],
        },
        loadWarpMap: (id) async {
          requested.add(id);
          return _warpMap(id);
        },
        onSubmit: (payload) => submitted = payload,
      );
      expect(requested, ['forest']);
      final arrival = _picker(tester, 'Point d’arrivée');
      expect(arrival.items.map((item) => item.value), ['forest_arrival']);
      final submit = find.byKey(const ValueKey('scene-action-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      expect(
        (submitted! as SceneActionPayload).interactiveCommand,
        SceneInteractiveCommand.warp(
          destinationMapId: 'forest',
          warpId: 'forest_arrival',
        ),
      );
    },
  );

  testWidgets('warp ignores a late response from the previous destination', (
    tester,
  ) async {
    final port = Completer<MapData?>(), forest = Completer<MapData?>();
    final requested = <String>[];
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.warp,
      options: _warpOptions,
      loadWarpMap: (id) {
        requested.add(id);
        return id == 'port' ? port.future : forest.future;
      },
      onSubmit: (payload) => submitted = payload,
    );
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey('scene-action-submit')),
          )
          .onPressed,
      isNull,
    );
    _picker(tester, 'Carte de destination').onChanged('forest');
    await tester.pump();
    forest.complete(_warpMap('forest'));
    await tester.pump();
    port.complete(_warpMap('port'));
    await tester.pump();
    expect(requested, ['port', 'forest']);
    final arrival = _picker(tester, 'Point d’arrivée');
    expect(arrival.items.map((item) => item.value), ['', 'forest_arrival']);
    expect(arrival.value, isEmpty);
    arrival.onChanged('forest_arrival');
    await tester.pump();
    final submit = find.byKey(const ValueKey('scene-action-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    expect(
      (submitted! as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.warp(
        destinationMapId: 'forest',
        warpId: 'forest_arrival',
      ),
    );
  });

  for (final failure in ['missing', 'wrongIdentity', 'throws']) {
    testWidgets(
      'warp map loader refuses $failure without using stale options',
      (tester) async {
        await _pumpBuilder(
          tester,
          initialCommandId: NarrativeCommandIds.warp,
          options: _warpOptions,
          loadWarpMap: (id) async => switch (failure) {
            'missing' => null,
            'wrongIdentity' => _warpMap('other'),
            _ => throw StateError('Unavailable destination'),
          },
        );
        expect(
          tester
              .widget<PokeMapButton>(
                find.byKey(const ValueKey('scene-action-submit')),
              )
              .onPressed,
          isNull,
        );
        expect(find.text('Points d’arrivée indisponibles'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('warp map response after disposal has no effect', (tester) async {
    final pending = Completer<MapData?>();
    final requested = <String>[];
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.warp,
      options: _warpOptions,
      loadWarpMap: (id) {
        requested.add(id);
        return pending.future;
      },
    );
    expect(requested, ['port']);
    await tester.pumpWidget(const SizedBox());
    pending.complete(_warpMap('port'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('warp defaults preserve facing and use the map transition', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.warp,
      options: _warpOptions,
      onSubmit: (payload) => submitted = payload,
    );
    expect(find.text('Conserver la direction'), findsOneWidget);
    expect(find.text('Transition de la carte'), findsOneWidget);
    expect(_picker(tester, 'Point d’arrivée').items.map((item) => item.label), [
      'Port · Arrivée',
    ]);
    final submit = find.byKey(const ValueKey('scene-action-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    expect(
      (submitted! as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.warp(
        destinationMapId: 'port',
        warpId: 'port_arrival',
      ),
    );
  });

  testWidgets('warp map change clears the arrival and filters its owner', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.warp,
      options: _warpOptions,
      onSubmit: (payload) => submitted = payload,
    );
    _picker(tester, 'Carte de destination').onChanged('forest');
    await tester.pump();
    final arrival = _picker(tester, 'Point d’arrivée');
    expect(arrival.items.map((item) => item.label), [
      'Choisir un point d’arrivée',
      'Forêt · Arrivée',
    ]);
    expect(arrival.value, isEmpty);
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey('scene-action-submit')),
          )
          .onPressed,
      isNull,
    );
    arrival.onChanged('forest_arrival');
    await tester.pump();
    final submit = find.byKey(const ValueKey('scene-action-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    expect(
      (submitted! as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.warp(
        destinationMapId: 'forest',
        warpId: 'forest_arrival',
      ),
    );
  });

  testWidgets('warp editing preserves explicit facing and no transition', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.warp,
      options: _warpOptions,
      initialParameters: const {
        'destinationMapId': 'forest',
        'warpId': 'forest_arrival',
        'arrivalFacing': 'north',
        'transition': 'none',
      },
      onSubmit: (payload) => submitted = payload,
    );
    final submit = find.byKey(const ValueKey('scene-action-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    expect(
      (submitted! as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.warp(
        destinationMapId: 'forest',
        warpId: 'forest_arrival',
        arrivalFacing: EntityFacing.north,
        transition: SceneWarpTransition.none,
      ),
    );
  });

  for (final invalid in const [
    {'arrivalFacing': 'diagonal'},
    {'transition': 'fade'},
    {'arrivalFacing': ' north '},
    {'transition': ' none '},
    {'arrivalFacing': ' '},
    {'transition': ' '},
  ]) {
    testWidgets('warp refuses unknown option $invalid before submit', (
      tester,
    ) async {
      await _pumpBuilder(
        tester,
        initialCommandId: NarrativeCommandIds.warp,
        options: _warpOptions,
        initialParameters: invalid,
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('scene-action-submit')),
            )
            .onPressed,
        isNull,
      );
    });
  }

  testWidgets('warp scopes identical arrival IDs to one destination map', (
    tester,
  ) async {
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.warp,
      options: {
        ..._warpOptions,
        NarrativeCommandParameterKind.warp: const [
          SceneActionPickerOption(
            id: 'arrival',
            label: 'Forêt · Arrivée',
            parentId: 'forest',
          ),
          SceneActionPickerOption(
            id: 'arrival',
            label: 'Port · Arrivée',
            parentId: 'port',
          ),
        ],
      },
    );
    expect(_picker(tester, 'Point d’arrivée').items.map((item) => item.label), [
      'Port · Arrivée',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('moveNpc retains its independent arrival picker', (tester) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.moveNpc,
      options: {
        ..._warpOptions,
        NarrativeCommandParameterKind.npc: const [
          SceneActionPickerOption(id: 'port::sailor', label: 'Marin'),
        ],
      },
      onSubmit: (payload) => submitted = payload,
      loadWarpMap: (_) async => fail('moveNpc must not load a Warp destination'),
    );
    expect(_picker(tester, 'Destination').items.map((item) => item.label), [
      'Forêt · Arrivée',
      'Port · Arrivée',
    ]);
    final submit = find.byKey(const ValueKey('scene-action-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    expect(
      (submitted! as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.moveNpc(
        mapId: 'port',
        entityId: 'sailor',
        warpId: 'forest_arrival',
      ),
    );
  });

  testWidgets('platform action uses guided platform and motion pickers', (tester) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(tester, initialCommandId: NarrativeCommandIds.movePlatform,
        options: const {NarrativeCommandParameterKind.movingPlatform: [
          SceneActionPickerOption(id: 'gym::bridge', label: 'Arène · Plateforme centrale'),
        ]}, onSubmit: (payload) => submitted = payload);
    expect(find.text('Arène · Plateforme centrale'), findsOneWidget);
    expect(find.text('Avancer'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();
    expect((submitted! as SceneActionPayload).interactiveCommand,
        SceneInteractiveCommand.movePlatform(mapId: 'gym', platformId: 'bridge', motion: MovingPlatformMotion.forward));
  });
  testWidgets('guided gift action exposes received and bagFull without raw IDs', (tester) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(tester, initialCommandId: NarrativeCommandIds.giveItemGift,
      options: const {NarrativeCommandParameterKind.item: [SceneActionPickerOption(id: 'tm23', label: 'CT23') ]},
      onSubmit: (payload) => submitted = payload);
    expect(find.text('Interactif'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();
    final payload = submitted! as SceneActionPayload;
    expect(payload.consequence, isNull);
    expect(payload.interactiveCommand, SceneInteractiveCommand.giveItem(itemId: 'tm23', quantity: 1));
    expect(payload.interactiveCommand!.outputPortIds, ['received', 'bagFull']);
  });
  testWidgets('builds a persistent action from guided picker values', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    SceneActionBuildResult? submittedResult;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.giveItem,
      options: {
        NarrativeCommandParameterKind.item: const [
          SceneActionPickerOption(id: 'potion', label: 'Potion'),
        ],
      },
      onSubmit: (payload) => submitted = payload,
      onSubmitResult: (result) => submittedResult = result,
    );

    expect(find.text('Persistant'), findsOneWidget);
    expect(find.text('FG-083'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('scene-action-parameter-quantity')),
      '2',
    );
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    final action = submitted! as SceneActionPayload;
    expect(
      action.consequence,
      SceneConsequence.giveItem(itemId: 'potion', quantity: 2),
    );
    expect(submittedResult!.command.id, NarrativeCommandIds.giveItem);
    expect(submittedResult!.parameters, {'itemId': 'potion', 'quantity': '2'});
  });

  testWidgets(
    'empty guided picker blocks publication without asking for an ID',
    (tester) async {
      await _pumpBuilder(
        tester,
        initialCommandId: NarrativeCommandIds.giveItem,
      );

      expect(find.textContaining('Aucun Objet disponible'), findsOneWidget);
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('scene-action-submit')),
            )
            .onPressed,
        isNull,
      );
      expect(find.byType(PokeMapTextField), findsOneWidget);
    },
  );

  testWidgets('static encounter uses the dedicated guided contract picker', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.staticEncounter,
      options: const {
        NarrativeCommandParameterKind.staticEncounter: [
          SceneActionPickerOption(
            id: 'static:trainer_lighthouse_guardian',
            label: 'Gardien du phare',
            parameters: {
              'trainerId': 'trainer_lighthouse_guardian',
              'battleTemplateId': 'battle_lighthouse_pokemon',
            },
          ),
        ],
      },
      onSubmit: (payload) => submitted = payload,
    );

    expect(find.text('Gardien du phare'), findsOneWidget);
    expect(find.byType(PokeMapTextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    expect(
      submitted,
      SceneBattlePayload(
        battleKind: 'static',
        trainerId: 'trainer_lighthouse_guardian',
        battleTemplateId: 'battle_lighthouse_pokemon',
        declaredOutcomes: const ['victory', 'defeat'],
      ),
    );
  });

  testWidgets('canonical heal command is authorable without raw parameters', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.healParty,
      onSubmit: (payload) => submitted = payload,
    );

    expect(find.text('Persistant'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    expect(
      (submitted! as SceneActionPayload).consequence,
      SceneConsequence.healParty(),
    );
  });

  testWidgets('Pokemon form picker follows the selected species', (
    tester,
  ) async {
    SceneActionBuildResult? result;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.givePokemon,
      initialParameters: const {'speciesId': 'sproutle', 'formId': 'sunny'},
      options: const {
        NarrativeCommandParameterKind.species: [
          SceneActionPickerOption(id: 'sproutle', label: 'Sproutle'),
          SceneActionPickerOption(id: 'shellby', label: 'Shellby'),
        ],
        NarrativeCommandParameterKind.speciesForm: [
          SceneActionPickerOption(
            id: 'base',
            label: 'Forme de base',
            parentId: 'sproutle',
          ),
          SceneActionPickerOption(
            id: 'sunny',
            label: 'Sunny',
            parentId: 'sproutle',
          ),
          SceneActionPickerOption(
            id: 'shell',
            label: 'Shell',
            parentId: 'shellby',
          ),
        ],
      },
      onSubmitResult: (value) => result = value,
    );

    expect(find.text('Sunny'), findsOneWidget);
    expect(find.text('Shell'), findsNothing);

    final speciesPicker = tester
        .widgetList<PokeMapDropdownField<String>>(
          find.byType(PokeMapDropdownField<String>),
        )
        .singleWhere((field) => field.label == 'Espèce');
    speciesPicker.onChanged('shellby');
    await tester.pump();

    expect(find.text('Sunny'), findsNothing);
    expect(find.text('Shell'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    expect(result!.parameters['speciesId'], 'shellby');
    expect(result!.parameters['formId'], 'shell');
    expect(
      (result!.payload as SceneActionPayload).consequence,
      SceneConsequence.givePokemon(
        speciesId: 'shellby',
        formId: 'shell',
        level: 1,
        currentHp: 1,
      ),
    );
  });

  testWidgets('custom animation uses actor definition and direction pickers', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.playCharacterAnimation,
      options: const {
        NarrativeCommandParameterKind.actor: [
          SceneActionPickerOption(id: 'player', label: 'Joueur'),
        ],
        NarrativeCommandParameterKind.customAnimationDefinition: [
          SceneActionPickerOption(
            id: 'wave',
            label: 'Saluer',
            parameters: {'animationMode': 'directional'},
          ),
        ],
      },
      onSubmit: (payload) => submitted = payload,
    );

    expect(find.text('Joueur'), findsOneWidget);
    expect(find.text('Saluer'), findsOneWidget);
    expect(find.text('Direction'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scene-action-parameter-actorId')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    final command =
        (submitted! as SceneActionPayload).interactiveCommand!
            as SceneCharacterCustomAnimationInteractiveCommand;
    expect(command.runtimeCommand.actorId, 'player');
    expect(command.runtimeCommand.definitionId, 'wave');
    expect(command.runtimeCommand.direction, EntityFacing.south);
    expect(
      command.runtimeCommand.playback,
      CharacterCustomAnimationPlayback.once(),
    );
  });

  testWidgets('RailJourney uses guided journey and transition pickers', (
    tester,
  ) async {
    SceneActionBuildResult? result;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.railJourney,
      runtimeCommandIds: const <String>{NarrativeCommandIds.railJourney},
      options:
          const <NarrativeCommandParameterKind, List<SceneActionPickerOption>>{
            NarrativeCommandParameterKind.railJourney:
                <SceneActionPickerOption>[
                  SceneActionPickerOption(id: 'T1', label: 'Hanazuki → Aohara'),
                ],
          },
      initialParameters: const <String, String>{
        'commandId': 'scene.rail.begin',
        'operation': 'begin',
      },
      onSubmitResult: (value) => result = value,
    );

    expect(find.text('Hanazuki → Aohara'), findsOneWidget);
    expect(find.text('Départ'), findsOneWidget);
    expect(find.text('Aller'), findsOneWidget);
    expect(find.text('Porte ouest'), findsOneWidget);
    expect(find.text('Étape'), findsNothing);
    expect(
      find.byKey(const ValueKey('scene-action-parameter-journeyId')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    expect(
      (result!.payload as SceneActionPayload).interactiveCommand,
      SceneInteractiveCommand.railJourney(
        commandId: 'scene.rail.begin',
        journeyId: 'T1',
        operation: SceneRailJourneyOperation.begin,
        direction: RailJourneyDirection.outbound,
        doorSide: RailJourneyDoorSide.west,
      ),
    );
  });

  testWidgets('badge and field ability use project-owned guided pickers', (
    tester,
  ) async {
    SceneNodePayload? badgePayload;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.awardBadge,
      options: const {
        NarrativeCommandParameterKind.badge: [
          SceneActionPickerOption(id: 'badge_tide', label: 'Badge Marée'),
        ],
      },
      onSubmit: (payload) => badgePayload = payload,
    );

    expect(find.text('Badge Marée'), findsOneWidget);
    expect(find.byType(PokeMapTextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();
    expect(
      (badgePayload! as SceneActionPayload).consequence,
      SceneConsequence.awardBadge(badgeId: 'badge_tide'),
    );

    SceneNodePayload? fieldPayload;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.unlockFieldAbility,
      options: const {
        NarrativeCommandParameterKind.fieldAbility: [
          SceneActionPickerOption(id: 'surf', label: 'Surf'),
        ],
      },
      onSubmit: (payload) => fieldPayload = payload,
    );
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();
    expect(
      (fieldPayload! as SceneActionPayload).consequence,
      SceneConsequence.unlockFieldAbility(ability: FieldAbility.surf),
    );
  });

  testWidgets(
    'NPC state uses a guided project picker without raw identifiers',
    (tester) async {
      SceneActionBuildResult? result;
      await _pumpBuilder(
        tester,
        initialCommandId: NarrativeCommandIds.setNpcPresence,
        runtimeCommandIds: const {NarrativeCommandIds.setNpcPresence},
        options: const {
          NarrativeCommandParameterKind.npc: [
            SceneActionPickerOption(
              id: 'map_port::npc_sailor',
              label: 'Port · Marin',
            ),
          ],
        },
        initialParameters: const {'present': 'false'},
        onSubmitResult: (value) => result = value,
      );

      expect(find.text('Port · Marin'), findsOneWidget);
      expect(find.text('PNJ'), findsOneWidget);
      expect(find.byType(PokeMapDropdownField<String>), findsNWidgets(3));
      expect(find.byType(PokeMapTextField), findsNothing);

      await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
      await tester.pump();

      expect(
        (result!.payload as SceneActionPayload).consequence,
        SceneConsequence.setNpcPresence(
          mapId: 'map_port',
          entityId: 'npc_sailor',
          present: false,
        ),
      );
    },
  );

  testWidgets('pause menu visibility uses a guided picker without Resume', (
    tester,
  ) async {
    SceneActionBuildResult? result;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.setPauseMenuEntryVisibility,
      runtimeCommandIds: const {
        NarrativeCommandIds.setPauseMenuEntryVisibility,
      },
      initialParameters: const {'visible': 'false'},
      onSubmitResult: (value) => result = value,
    );

    final actionField = tester
        .widgetList<PokeMapDropdownField<String>>(
          find.byType(PokeMapDropdownField<String>),
        )
        .singleWhere((field) => field.label == 'Entrée du menu');
    expect(actionField.items.map((item) => item.label), contains('Pokédex'));
    expect(
      actionField.items.map((item) => item.label),
      isNot(contains('Reprendre')),
    );
    final visibilityField = tester
        .widgetList<PokeMapDropdownField<String>>(
          find.byType(PokeMapDropdownField<String>),
        )
        .singleWhere((field) => field.label == 'Visibilité');
    expect(visibilityField.items.map((item) => item.label), <String>[
      'Afficher',
      'Masquer',
    ]);

    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    expect(
      (result!.payload as SceneActionPayload).consequence,
      SceneConsequence.setPauseMenuEntryVisibility(
        actionId: ProjectPauseActionId.party,
        visible: false,
      ),
    );
  });

  testWidgets('deleted picker target is kept visible and blocks editing', (
    tester,
  ) async {
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.awardBadge,
      initialParameters: const {'badgeId': 'badge_deleted'},
      options: const {
        NarrativeCommandParameterKind.badge: [
          SceneActionPickerOption(id: 'badge_tide', label: 'Badge Marée'),
        ],
      },
    );

    expect(find.textContaining('badge_deleted'), findsOneWidget);
    expect(find.textContaining('n’existe plus'), findsOneWidget);
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey('scene-action-submit')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('editing preserves an existing non-default picker target', (
    tester,
  ) async {
    SceneActionBuildResult? result;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.awardBadge,
      initialParameters: const {'badgeId': 'badge_tide'},
      options: const {
        NarrativeCommandParameterKind.badge: [
          SceneActionPickerOption(id: 'badge_leaf', label: 'Badge Feuille'),
          SceneActionPickerOption(id: 'badge_tide', label: 'Badge Marée'),
        ],
      },
      onSubmitResult: (value) => result = value,
    );

    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    expect(result!.parameters['badgeId'], 'badge_tide');
    expect(
      (result!.payload as SceneActionPayload).consequence,
      SceneConsequence.awardBadge(badgeId: 'badge_tide'),
    );
  });

  testWidgets('commands absent from the current runtime stay hidden', (
    tester,
  ) async {
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.healParty,
      runtimeCommandIds: const {NarrativeCommandIds.healParty},
    );

    expect(find.text('Soigner l’équipe'), findsOneWidget);
    expect(find.text('Donner un badge'), findsNothing);
    expect(find.text('Modifier la présence d’un PNJ'), findsNothing);
  });

  testWidgets('Finish Game uses friendly fields and guided policy pickers', (
    tester,
  ) async {
    SceneNodePayload? submitted;
    await _pumpBuilder(
      tester,
      initialCommandId: NarrativeCommandIds.finishGame,
      runtimeCommandIds: const {NarrativeCommandIds.finishGame},
      initialParameters: const {
        'endingName': 'Selbrume sauvée',
        'resultTitle': 'Selbrume est sauvée',
        'resultSummary': 'La brume se retire.',
        'includeCredits': 'false',
      },
      onSubmit: (payload) => submitted = payload,
    );

    expect(find.text('Issue de la partie'), findsOneWidget);
    expect(find.text('Après la fin'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scene-action-parameter-endingId')),
      findsNothing,
    );

    final finishSubmit = find.byKey(const ValueKey('scene-action-submit'));
    await tester.ensureVisible(finishSubmit);
    final finishButton = tester.widget<PokeMapButton>(finishSubmit);
    expect(finishButton.onPressed, isNotNull);
    finishButton.onPressed!();
    await tester.pump();

    final consequence =
        (submitted! as SceneActionPayload).consequence!
            as SceneFinishGameConsequence;
    expect(consequence.endingId, 'ending.selbrume-sauvee');
    expect(consequence.credits, isNull);
    expect(consequence.postGamePolicy, ScenePostGamePolicy.continueGame);
  });
}

const _warpOptions = {
  NarrativeCommandParameterKind.map: [
    SceneActionPickerOption(id: 'port', label: 'Port'),
    SceneActionPickerOption(id: 'forest', label: 'Forêt'),
  ],
  NarrativeCommandParameterKind.warp: [
    SceneActionPickerOption(
      id: 'forest_arrival',
      label: 'Forêt · Arrivée',
      parentId: 'forest',
    ),
    SceneActionPickerOption(
      id: 'port_arrival',
      label: 'Port · Arrivée',
      parentId: 'port',
    ),
  ],
};

MapData _warpMap(String id) => MapData(
  id: id,
  name: id,
  size: const GridSize(width: 4, height: 4),
  warps: [
    MapWarp(
      id: '${id}_arrival',
      pos: const GridPos(x: 1, y: 1),
      targetMapId: id,
      targetPos: const GridPos(x: 1, y: 1),
    ),
  ],
);

PokeMapDropdownField<String> _picker(WidgetTester tester, String label) =>
    tester
        .widgetList<PokeMapDropdownField<String>>(
          find.byType(PokeMapDropdownField<String>),
        )
        .singleWhere((field) => field.label == label);

Future<void> _pumpBuilder(
  WidgetTester tester, {
  required String initialCommandId,
  Map<NarrativeCommandParameterKind, List<SceneActionPickerOption>> options =
      const {},
  ValueChanged<SceneNodePayload>? onSubmit,
  ValueChanged<SceneActionBuildResult>? onSubmitResult,
  Map<String, String> initialParameters = const {},
  Set<String>? runtimeCommandIds,
  Future<MapData?> Function(String)? loadWarpMap,
}) async {
  tester.view.physicalSize = const Size(900, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.light(),
      darkTheme: PokeMapTheme.dark(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SceneActionBuilder(
            key: ValueKey('builder-$initialCommandId'),
            initialCommandId: initialCommandId,
            pickerOptions: options,
            initialParameters: initialParameters,
            runtimeCommandIds: runtimeCommandIds,
            loadWarpMap: loadWarpMap,
            onSubmit: onSubmit ?? (_) {},
            onSubmitResult: onSubmitResult,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
