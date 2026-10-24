import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_options.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final section in <RuntimePlayerPauseSection>[
    RuntimePlayerPauseSection.party,
    RuntimePlayerPauseSection.bag,
    RuntimePlayerPauseSection.quests,
  ]) {
    testWidgets('${section.name} renders runtime-provided detail data', (
      tester,
    ) async {
      final snapshot = _detailSnapshot(
        section,
        detail: RuntimePlayerPauseDetailSnapshot(
          section: section,
          title: 'Titre ${section.name}',
          entries: <RuntimePlayerDetailEntrySnapshot>[
            RuntimePlayerDetailEntrySnapshot(
              id: '${section.name}-entry',
              title: 'Contenu ${section.name}',
              subtitle: 'Donnée runtime',
              trailingLabel: '1 / 1',
              progress: 1,
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        _app(RuntimePlayerDetailRouter(snapshot: snapshot)),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey<String>('runtime-player-detail-${section.name}')),
        findsOneWidget,
      );
      expect(
        find.text('Contenu ${section.name}'),
        section == RuntimePlayerPauseSection.bag
            ? findsNWidgets(2)
            : findsOneWidget,
      );
      expect(find.text('Donnée runtime'), findsOneWidget);
    });
  }

  testWidgets('profile renders its typed projection without generic rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        RuntimePlayerDetailRouter(
          snapshot: _detailSnapshot(
            RuntimePlayerPauseSection.profile,
            detail: RuntimePlayerPauseDetailSnapshot(
              section: RuntimePlayerPauseSection.profile,
              title: 'Profil',
              profile: RuntimePlayerProfileSnapshot(
                playerName: 'Camille',
                currentMapId: 'map.internal.port',
                locationName: 'Port des Brumes',
                money: 4321,
                playtimeSeconds: 25 * 3600 + 7 * 60,
              ),
              entries: [
                RuntimePlayerDetailEntrySnapshot(
                  id: 'profile.internal.row',
                  title: 'Ancienne carte générique',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Camille'), findsOneWidget);
    expect(find.text('Port des Brumes'), findsOneWidget);
    expect(find.text('Ancienne carte générique'), findsNothing);
    expect(find.text('map.internal.port'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('BETA-SYS-001 pokedex search filters the projected entries', () {
    RuntimePlayerSnapshot dexSnapshot() => _detailSnapshot(
      RuntimePlayerPauseSection.pokedex,
      detail: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.pokedex,
        title: 'Pokédex',
        entries: <RuntimePlayerDetailEntrySnapshot>[
          RuntimePlayerDetailEntrySnapshot(
            id: 'bulbasaur',
            title: 'Bulbizarre',
            subtitle: '#001 · Capturé · Grass / Poison',
            trailingLabel: '●',
            pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
              knowledge: RuntimePlayerPokedexKnowledge.caught,
              nationalDex: 1,
              typeIds: ['grass', 'poison'],
            ),
          ),
          RuntimePlayerDetailEntrySnapshot(
            id: 'ivysaur',
            title: 'Herbizarre',
            subtitle: '#002 · Vu · Grass / Poison',
            trailingLabel: '○',
            pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
              knowledge: RuntimePlayerPokedexKnowledge.seen,
              nationalDex: 2,
              typeIds: ['grass', 'poison'],
            ),
          ),
          RuntimePlayerDetailEntrySnapshot(
            id: 'charmander',
            title: '???',
            subtitle: '#004 · Inconnu',
            pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
              knowledge: RuntimePlayerPokedexKnowledge.unknown,
              nationalDex: 4,
            ),
          ),
        ],
      ),
    );

    testWidgets('typing a name keeps only the matching species', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(RuntimePlayerDetailRouter(snapshot: dexSnapshot())),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('pokedex-entry-bulbasaur')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('pokedex-entry-ivysaur')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('pokedex-search')),
        'herbi',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('pokedex-entry-ivysaur')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('pokedex-entry-bulbasaur')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('pokedex-entry-charmander')),
        findsNothing,
      );
    });

    testWidgets('an unknown species stays findable by number, not by name', (
      tester,
    ) async {
      // On ne peut pas chercher le nom de ce qu'on n'a pas vu — mais le
      // numéro du Pokédex reste une donnée affichée, donc cherchable.
      await tester.pumpWidget(
        _app(RuntimePlayerDetailRouter(snapshot: dexSnapshot())),
      );
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey<String>('pokedex-search'));

      await tester.enterText(search, '#004');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('pokedex-entry-charmander')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('pokedex-entry-bulbasaur')),
        findsNothing,
      );

      await tester.enterText(search, 'charmander');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('pokedex-entry-charmander')),
        findsNothing,
      );
    });

    testWidgets('the caught state is searchable and case-insensitive', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(RuntimePlayerDetailRouter(snapshot: dexSnapshot())),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('pokedex-search')),
        'CAPTURÉ',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('pokedex-entry-bulbasaur')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('pokedex-entry-ivysaur')), findsNothing);
    });

    testWidgets('no match shows a dedicated empty state, then recovers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(RuntimePlayerDetailRouter(snapshot: dexSnapshot())),
      );
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey<String>('pokedex-search'));

      await tester.enterText(search, 'zzz-aucune-espece');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('pokedex-no-results')),
        findsOneWidget,
      );

      await tester.enterText(search, '');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('pokedex-entry-bulbasaur')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('pokedex-entry-ivysaur')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('pokedex-entry-charmander')),
        findsOneWidget,
      );
    });
  });

  testWidgets('options expose a persisted touch-control opacity slider', (
    tester,
  ) async {
    PlayerPreferencesSnapshot? changed;
    final snapshot = RuntimePlayerSnapshot(
      revision: 3,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.options,
      defaultPreferences: const PlayerPreferencesSnapshot(
        locale: 'en',
        accessibility: GameSessionAccessibilityOptions(),
        audioMix: RuntimeAudioMix(musicVolume: 0.8, effectsVolume: 0.8),
      ),
      preferences: const PlayerPreferencesSnapshot(
        locale: 'fr',
        accessibility: GameSessionAccessibilityOptions(),
        touchControlsOpacity: 0.82,
      ),
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.openOptions,
        ),
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.updatePreferences,
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        RuntimePlayerDetailRouter(
          snapshot: snapshot,
          onPreferencesChanged: (preferences) => changed = preferences,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<RuntimePlayerOptions>(find.byType(RuntimePlayerOptions))
          .defaultPreferences,
      same(snapshot.defaultPreferences),
    );
    final controls = find.byKey(const ValueKey('options-category-controls'));
    if (controls.evaluate().isEmpty) {
      await tester.tap(find.byKey(const ValueKey('options-category-picker')));
      await tester.pumpAndSettle();
    }
    await _tapBagControl(tester, 'options-category-controls');

    final slider = find.byKey(
      const ValueKey<String>('touch-controls-opacity-slider'),
    );
    await _revealControl(tester, slider);
    expect(slider, findsOneWidget);
    await tester.drag(slider, const Offset(-120, 0));
    await tester.pump();

    expect(changed, isNotNull);
    expect(changed!.touchControlsOpacity, lessThan(0.82));
  });

  testWidgets(
    'bag automatically uses its sole target and keeps key items unavailable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      RuntimePlayerPauseCommand? command;
      final detail = RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.bag,
        title: 'Sac',
        entries: <RuntimePlayerDetailEntrySnapshot>[
          RuntimePlayerDetailEntrySnapshot(
            id: 'bag.medicine.potion',
            title: 'Potion',
            trailingLabel: '×2',
            bagAction: RuntimePlayerBagItemActionSnapshot(
              itemTargetId: 'potion',
              targetKind: RuntimePlayerBagUseTargetKind.partyMember,
              usability: ItemUsabilityState.usable,
              isEnabled: true,
            ),
          ),
          RuntimePlayerDetailEntrySnapshot(
            id: 'bag.key-items.harbor-pass',
            title: 'Passe du port',
            trailingLabel: '×1',
            bagAction: RuntimePlayerBagItemActionSnapshot(
              itemTargetId: 'harbor-pass',
              targetKind: RuntimePlayerBagUseTargetKind.partyMember,
              usability: ItemUsabilityState.passive,
              isEnabled: false,
              unavailableReason: 'Cet objet clé s’utilise automatiquement et n’est pas consommé.',
            ),
          ),
        ],
        bagTargets: <RuntimePlayerBagPartyTargetSnapshot>[
          RuntimePlayerBagPartyTargetSnapshot(
            targetId: 'party.0',
            label: 'Salamèche',
            subtitle: 'PV 12/39',
          ),
        ],
      );

      await tester.pumpWidget(
        _app(
          RuntimePlayerDetailRouter(
            snapshot: _detailSnapshot(
              RuntimePlayerPauseSection.bag,
              detail: detail,
            ),
            onPauseCommand: (value) => command = value,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('runtime-player-bag-use-potion')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('runtime-player-bag-use-potion')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(command?.itemTargetId, 'potion');
      expect(command?.partyTargetId, 'party.0');
      await _tapBagControl(tester, 'bag-item-bag.key-items.harbor-pass');
      expect(
        find.byKey(
          const ValueKey<String>('runtime-player-bag-use-harbor-pass'),
        ),
        findsNothing,
      );
      final reason = find.text(
        'Cet objet clé s’utilise automatiquement et n’est pas consommé.',
      );
      await tester.ensureVisible(reason);
      expect(reason, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('TM replacement requires a compatible target and confirmation', (
    tester,
  ) async {
    RuntimePlayerPauseCommand? command;
    final detail = RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.bag,
      title: 'Sac',
      entries: <RuntimePlayerDetailEntrySnapshot>[
        RuntimePlayerDetailEntrySnapshot(
          id: 'bag.machines.tm-protect',
          title: 'TM Protect',
          bagAction: RuntimePlayerBagItemActionSnapshot(
            itemTargetId: 'tm-protect',
            targetKind: RuntimePlayerBagUseTargetKind.partyMoveReplacement,
            requiresConfirmation: true,
            usability: ItemUsabilityState.usable,
            isEnabled: true,
            eligiblePartyTargetIds: const <String>{'party.0'},
            learnedMoveLabel: 'Abri',
            unavailablePartyTargetReasons: const {
              'party.1': 'Cette espèce ne peut pas apprendre Abri.',
            },
          ),
        ),
      ],
      bagTargets: <RuntimePlayerBagPartyTargetSnapshot>[
        RuntimePlayerBagPartyTargetSnapshot(
          targetId: 'party.0',
          label: 'Bulbizarre',
          moves: const <RuntimePlayerBagMoveTargetSnapshot>[
            RuntimePlayerBagMoveTargetSnapshot(
              targetId: 'tackle',
              label: 'Charge',
            ),
            RuntimePlayerBagMoveTargetSnapshot(
              targetId: 'growl',
              label: 'Rugissement',
            ),
            RuntimePlayerBagMoveTargetSnapshot(
              targetId: 'vine-whip',
              label: 'Fouet Lianes',
            ),
            RuntimePlayerBagMoveTargetSnapshot(
              targetId: 'sleep-powder',
              label: 'Poudre Dodo',
            ),
          ],
          requiresMoveReplacement: true,
        ),
        RuntimePlayerBagPartyTargetSnapshot(
          targetId: 'party.1',
          label: 'Carapuce',
          moves: const <RuntimePlayerBagMoveTargetSnapshot>[
            RuntimePlayerBagMoveTargetSnapshot(
              targetId: 'tackle',
              label: 'Charge',
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        RuntimePlayerDetailRouter(
          snapshot: _detailSnapshot(
            RuntimePlayerPauseSection.bag,
            detail: detail,
          ),
          onPauseCommand: (value) => command = value,
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('runtime-player-bag-use-tm-protect')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('runtime-player-bag-target-party.1')),
      findsNothing,
    );
    await _tapBagControl(tester, 'runtime-player-bag-target-party.0-growl');
    expect(find.text('Apprendre Abri — oublier Rugissement'), findsOneWidget);
    expect(command, isNull);
    await _tapBagControl(tester, 'bag-use-confirm');

    expect(command?.itemTargetId, 'tm-protect');
    expect(command?.partyTargetId, 'party.0');
    expect(command?.moveTargetId, 'growl');
  });

  testWidgets('HM target picker emits a compatible replacement command', (
    tester,
  ) async {
    RuntimePlayerPauseCommand? command;
    final detail = RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.bag,
      title: 'Sac',
      entries: <RuntimePlayerDetailEntrySnapshot>[
        RuntimePlayerDetailEntrySnapshot(
          id: 'bag.machines.hm-surf',
          title: 'HM Surf',
          bagAction: RuntimePlayerBagItemActionSnapshot(
            itemTargetId: 'hm-surf',
            targetKind: RuntimePlayerBagUseTargetKind.partyMoveReplacement,
            requiresConfirmation: true,
            usability: ItemUsabilityState.usable,
            isEnabled: true,
            eligiblePartyTargetIds: const <String>{'party.0'},
          ),
        ),
      ],
      bagTargets: <RuntimePlayerBagPartyTargetSnapshot>[
        RuntimePlayerBagPartyTargetSnapshot(
          targetId: 'party.0',
          label: 'Bulbizarre',
          moves: const <RuntimePlayerBagMoveTargetSnapshot>[
            RuntimePlayerBagMoveTargetSnapshot(
              targetId: 'tackle',
              label: 'Charge',
            ),
            RuntimePlayerBagMoveTargetSnapshot(
              targetId: 'growl',
              label: 'Rugissement',
            ),
            RuntimePlayerBagMoveTargetSnapshot(
              targetId: 'vine-whip',
              label: 'Fouet Lianes',
            ),
            RuntimePlayerBagMoveTargetSnapshot(
              targetId: 'sleep-powder',
              label: 'Poudre Dodo',
            ),
          ],
          requiresMoveReplacement: true,
        ),
        RuntimePlayerBagPartyTargetSnapshot(
          targetId: 'party.1',
          label: 'Salamèche',
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        RuntimePlayerDetailRouter(
          snapshot: _detailSnapshot(
            RuntimePlayerPauseSection.bag,
            detail: detail,
          ),
          onPauseCommand: (value) => command = value,
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('runtime-player-bag-use-hm-surf')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('runtime-player-bag-target-party.1')),
      findsNothing,
    );
    await _tapBagControl(tester, 'runtime-player-bag-target-party.0-growl');
    expect(command, isNull);
    await _tapBagControl(tester, 'bag-use-confirm');

    expect(command?.itemTargetId, 'hm-surf');
    expect(command?.partyTargetId, 'party.0');
    expect(command?.moveTargetId, 'growl');
  });

  for (final targetKind in [
    RuntimePlayerBagUseTargetKind.partyMove,
    RuntimePlayerBagUseTargetKind.partyMoveReplacement,
  ]) {
    testWidgets(
      '${targetKind.name} cancels without effect then resolves its decision',
      (tester) async {
        final commands = <RuntimePlayerPauseCommand>[];
        final restoresPp =
            targetKind == RuntimePlayerBagUseTargetKind.partyMove;
        final itemId = restoresPp ? 'ether' : 'tm-protect';
        final detail = RuntimePlayerPauseDetailSnapshot(
          section: RuntimePlayerPauseSection.bag,
          title: 'Sac',
          entries: [
            RuntimePlayerDetailEntrySnapshot(
              id: 'bag.$itemId',
              title: restoresPp ? 'Éther' : 'CT Abri',
              bagAction: RuntimePlayerBagItemActionSnapshot(
                itemTargetId: itemId,
                targetKind: targetKind,
                requiresConfirmation: !restoresPp,
                usability: ItemUsabilityState.usable,
                isEnabled: true,
                learnedMoveLabel: restoresPp ? null : 'Abri',
              ),
            ),
          ],
          bagTargets: [
            RuntimePlayerBagPartyTargetSnapshot(
              targetId: 'party.0',
              label: 'Bulbizarre',
              moves: const [
                RuntimePlayerBagMoveTargetSnapshot(
                  targetId: 'growl',
                  label: 'Rugissement',
                  subtitle: 'PP actuels : 0',
                ),
              ],
            ),
          ],
        );
        await tester.pumpWidget(
          _app(
            RuntimePlayerDetailRouter(
              snapshot: _detailSnapshot(
                RuntimePlayerPauseSection.bag,
                detail: detail,
              ),
              onPauseCommand: commands.add,
            ),
          ),
        );
        await _tapBagControl(tester, 'runtime-player-bag-use-$itemId');
        await _tapBagControl(tester, 'runtime-player-bag-target-close');
        await _tapBagControl(tester, 'runtime-player-bag-target-close');
        expect(find.byType(Dialog), findsNothing);
        expect(commands, isEmpty);

        await _tapBagControl(tester, 'runtime-player-bag-use-$itemId');
        if (restoresPp) {
          expect(find.text('PP actuels : 0'), findsOneWidget);
          await _tapBagControl(
            tester,
            'runtime-player-bag-target-party.0-growl',
          );
        } else {
          expect(find.text('Apprendre Abri'), findsOneWidget);
          expect(commands, isEmpty);
          await _tapBagControl(tester, 'bag-use-confirm');
        }
        expect(commands, hasLength(1));
        expect(commands.single.itemTargetId, itemId);
        expect(commands.single.partyTargetId, 'party.0');
        expect(commands.single.moveTargetId, restoresPp ? 'growl' : null);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('party gives, swaps and takes held items with guided labels', (
    tester,
  ) async {
    final commands = <RuntimePlayerPauseCommand>[];
    final detail = RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.party,
      title: 'Équipe',
      entries: <RuntimePlayerDetailEntrySnapshot>[
        RuntimePlayerDetailEntrySnapshot(
          id: 'party.0',
          title: 'Bulbizarre',
          pokemonSummary: RuntimePokemonSummarySnapshot(
            targetId: 'party.0',
            individualId: 'first',
            natureLabel: 'Modeste',
            abilityLabel: 'Engrais',
            friendship: 70,
            speciesLabel: 'Bulbizarre',
            nickname: '',
            level: 12,
            currentHp: 20,
            maxHp: 48,
          ),
          heldItemAction: RuntimePlayerHeldItemActionSnapshot(
            partyTargetId: 'party.0',
            currentItemLabel: 'Baie Oran',
            options: const <RuntimePlayerHeldItemOptionSnapshot>[
              RuntimePlayerHeldItemOptionSnapshot(
                itemTargetId: 'leftovers-charm',
                label: 'Restes',
              ),
            ],
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        RuntimePlayerDetailRouter(
          snapshot: _detailSnapshot(
            RuntimePlayerPauseSection.party,
            detail: detail,
          ),
          onPauseCommand: commands.add,
        ),
      ),
    );

    if (find.byType(PlayerPokemonSummarySheet).evaluate().isEmpty) {
      await _tapBagControl(tester, 'party-member-first');
      await _tapBagControl(tester, 'pokemon-summary-tab-actions');
    }
    await _tapBagControl(tester, 'runtime-player-held-manage-party.0');

    expect(find.text('Objet tenu : Baie Oran'), findsOneWidget);
    expect(find.text('Remplacer par Restes'), findsOneWidget);
    expect(find.text('leftovers-charm'), findsNothing);

    await tester.tap(find.text('Remplacer par Restes'));
    await tester.pumpAndSettle();

    expect(commands.single.kind, RuntimePlayerPauseCommandKind.equipHeldItem);
    expect(commands.single.itemTargetId, 'leftovers-charm');
    expect(commands.single.partyTargetId, 'party.0');

    if (find.byType(PlayerPokemonSummarySheet).evaluate().isEmpty) {
      await _tapBagControl(tester, 'party-member-first');
      await _tapBagControl(tester, 'pokemon-summary-tab-actions');
    }
    await _tapBagControl(tester, 'runtime-player-held-manage-party.0');
    await tester.tap(find.text('Retirer Baie Oran'));
    await tester.pumpAndSettle();

    expect(commands.last.kind, RuntimePlayerPauseCommandKind.unequipHeldItem);
    expect(commands.last.partyTargetId, 'party.0');
  });

  testWidgets('closing held item picker emits no command', (tester) async {
    final commands = <RuntimePlayerPauseCommand>[];
    final detail = RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.party,
      title: 'Équipe',
      entries: <RuntimePlayerDetailEntrySnapshot>[
        RuntimePlayerDetailEntrySnapshot(
          id: 'party.0',
          title: 'Bulbizarre',
          pokemonSummary: RuntimePokemonSummarySnapshot(
            targetId: 'party.0',
            individualId: 'first',
            natureLabel: 'Modeste',
            abilityLabel: 'Engrais',
            friendship: 70,
            speciesLabel: 'Bulbizarre',
            nickname: '',
            level: 12,
            currentHp: 20,
            maxHp: 48,
          ),
          heldItemAction: RuntimePlayerHeldItemActionSnapshot(
            partyTargetId: 'party.0',
            options: const <RuntimePlayerHeldItemOptionSnapshot>[
              RuntimePlayerHeldItemOptionSnapshot(
                itemTargetId: 'leftovers-charm',
                label: 'Restes',
              ),
            ],
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        RuntimePlayerDetailRouter(
          snapshot: _detailSnapshot(
            RuntimePlayerPauseSection.party,
            detail: detail,
          ),
          onPauseCommand: commands.add,
        ),
      ),
    );

    if (find.byType(PlayerPokemonSummarySheet).evaluate().isEmpty) {
      await _tapBagControl(tester, 'party-member-first');
      await _tapBagControl(tester, 'pokemon-summary-tab-actions');
    }
    await _tapBagControl(tester, 'runtime-player-held-manage-party.0');
    await tester.tap(
      find.byKey(const ValueKey<String>('runtime-player-held-close')),
    );
    await tester.pumpAndSettle();

    expect(commands, isEmpty);
  });

  testWidgets(
    'map renders current and unknown locations from its typed projection',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final detail = RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.map,
        title: 'Carte',
        regionalMap: RuntimePlayerRegionMapSnapshot(
          regions: [
            RuntimePlayerRegionSnapshot(
              id: 'region',
              label: 'Région des Brumes',
              points: const [
                RuntimePlayerMapPointSnapshot(
                  id: 'route',
                  label: 'Route des Brumes',
                  status: RuntimePlayerMapPointStatus.current,
                ),
                RuntimePlayerMapPointSnapshot(
                  id: 'cave',
                  label: 'Nom secret',
                  status: RuntimePlayerMapPointStatus.unknown,
                ),
              ],
            ),
          ],
        ),
      );
      await tester.pumpWidget(
        _app(
          RuntimePlayerDetailRouter(
            snapshot: _detailSnapshot(
              RuntimePlayerPauseSection.map,
              detail: detail,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scrollable), findsNothing);
      final row = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('region-row-route')),
      );
      expect(row.label, 'Route des Brumes');
      expect(row.semanticValue, 'Vous êtes ici');
      await _tapBagControl(tester, 'region-row-cave');
      expect(find.text('Nom secret'), findsNothing);
      expect(find.text('???'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing or empty detail gives a guided empty state', (
    tester,
  ) async {
    final snapshot = _detailSnapshot(
      RuntimePlayerPauseSection.party,
      detail: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.party,
        title: 'Équipe',
        emptyMessage: 'Aucun Pokémon dans votre équipe.',
      ),
    );

    await tester.pumpWidget(
      _app(RuntimePlayerDetailRouter(snapshot: snapshot)),
    );

    expect(
      find.byKey(const ValueKey<String>('runtime-player-detail-empty')),
      findsOneWidget,
    );
    expect(find.text('Aucun Pokémon dans votre équipe.'), findsOneWidget);
  });

  testWidgets('disabled detail shows the runtime-provided reason', (
    tester,
  ) async {
    final snapshot = RuntimePlayerSnapshot(
      revision: 4,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.pokedex,
      actions: <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.disabled(
          RuntimePlayerAction.openPokedex,
          reason: 'Obtenez le Pokédex auprès du professeur.',
        ),
      ],
    );

    await tester.pumpWidget(
      _app(RuntimePlayerDetailRouter(snapshot: snapshot)),
    );

    expect(
      find.byKey(const ValueKey<String>('runtime-player-detail-unavailable')),
      findsOneWidget,
    );
    expect(
      find.text('Obtenez le Pokédex auprès du professeur.'),
      findsOneWidget,
    );
  });

  testWidgets('Save dispatches only the runtime save command', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final actions = <RuntimePlayerAction>[];
    final snapshot = RuntimePlayerSnapshot(
      revision: 12,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.root,
      activeSaveAddress: const RuntimePlayerSaveAddress(
        gameId: 'com.example.aube',
        profileId: 'karim',
        slotId: 'slot-2',
      ),
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.resume),
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.save),
      ],
    );

    await tester.pumpWidget(
      _app(
        RuntimePlayerSurfaceRouter(
          snapshot: snapshot,
          titlePresentation: const RuntimePlayerTitlePresentation(
            author: 'Studio Test',
          ),
          gameSceneBuilder: (_) => const SizedBox.expand(),
          onAction: (action) async {
            actions.add(action);
            return const RuntimePlayerCommandResult(
              status: RuntimePlayerCommandStatus.accepted,
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _revealControl(tester, find.text('Sauvegarder'));
    await tester.tap(find.text('Sauvegarder'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.byKey(const ValueKey('runtime-save-confirm')), findsNothing);
    expect(actions, <RuntimePlayerAction>[RuntimePlayerAction.save]);
  });

  testWidgets(
    'manual Save receipt names the freshly persisted profile and slot',
    (tester) async {
      const address = RuntimePlayerSaveAddress(
        gameId: 'com.example.aube',
        profileId: 'karim',
        slotId: 'slot-2',
      );
      final snapshot = ValueNotifier(
        RuntimePlayerSnapshot(
          revision: 13,
          phase: RuntimePlayerPhase.paused,
          gameTitle: 'Aube',
          pauseSection: RuntimePlayerPauseSection.root,
          activeSaveAddress: address,
          actions: const [
            RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.resume),
            RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.save),
          ],
        ),
      );
      addTearDown(snapshot.dispose);
      await tester.pumpWidget(
        _app(
          ValueListenableBuilder<RuntimePlayerSnapshot>(
            valueListenable: snapshot,
            builder: (context, value, _) => RuntimePlayerSurfaceRouter(
              snapshot: value,
              titlePresentation: const RuntimePlayerTitlePresentation(
                author: 'Studio Test',
              ),
              gameSceneBuilder: (_) => const SizedBox.expand(),
              onAction: (action) async {
                expect(action, RuntimePlayerAction.save);
                final receipt = RuntimePlayerSaveReceipt(
                  address: address,
                  trigger: GameSessionCheckpointTrigger.manual,
                );
                snapshot.value = snapshot.value.next(saveReceipt: receipt);
                return RuntimePlayerCommandResult(
                  status: RuntimePlayerCommandStatus.accepted,
                  saveReceipt: receipt,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('runtime-save-receipt')), findsNothing);
      await _revealControl(tester, find.text('Sauvegarder'));
      await tester.tap(find.text('Sauvegarder'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(
        find.byKey(const ValueKey('runtime-save-receipt')),
        findsOneWidget,
      );
      expect(
        find.text('Partie sauvegardée — profil « karim », slot « slot-2 ».'),
        findsOneWidget,
      );
    },
  );
}

RuntimePlayerSnapshot _detailSnapshot(
  RuntimePlayerPauseSection section, {
  required RuntimePlayerPauseDetailSnapshot detail,
}) {
  return RuntimePlayerSnapshot(
    revision: 2,
    phase: RuntimePlayerPhase.paused,
    gameTitle: 'Aube',
    pauseSection: section,
    pauseDetails: <RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>{
      section: detail,
    },
    actions: <RuntimePlayerActionAvailability>[
      RuntimePlayerActionAvailability.enabled(_actionFor(section)),
      const RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.returnToPauseRoot,
      ),
    ],
  );
}

RuntimePlayerAction _actionFor(RuntimePlayerPauseSection section) =>
    switch (section) {
      RuntimePlayerPauseSection.party => RuntimePlayerAction.openParty,
      RuntimePlayerPauseSection.bag => RuntimePlayerAction.openBag,
      RuntimePlayerPauseSection.pokedex => RuntimePlayerAction.openPokedex,
      RuntimePlayerPauseSection.map => RuntimePlayerAction.openMap,
      RuntimePlayerPauseSection.quests => RuntimePlayerAction.openQuests,
      RuntimePlayerPauseSection.contacts => RuntimePlayerAction.openContacts,
      RuntimePlayerPauseSection.profile => RuntimePlayerAction.openProfile,
      RuntimePlayerPauseSection.options => RuntimePlayerAction.openOptions,
      RuntimePlayerPauseSection.root => throw ArgumentError('root'),
    };

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
  localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
  theme: PokeMapPlayerTheme.dark(),
  home: Material(child: child),
);

Future<void> _tapBagControl(WidgetTester tester, String key) async {
  final control = find.byKey(ValueKey<String>(key));
  await _revealControl(tester, control);
  await tester.tap(control);
  await tester.pumpAndSettle();
}

Future<void> _revealControl(WidgetTester tester, Finder control) async {
  await tester.pumpAndSettle();
  for (
    var page = 0;
    control.hitTestable().evaluate().isEmpty && page < 24;
    page++
  ) {
    final next = find
        .byKey(const ValueKey('player-page-next'))
        .hitTestable()
        .evaluate()
        .where((element) => (element.widget as IconButton).onPressed != null)
        .firstOrNull;
    if (next == null) break;
    await tester.tap(
      find.byElementPredicate((element) => identical(element, next)),
    );
    await tester.pumpAndSettle();
  }
}
