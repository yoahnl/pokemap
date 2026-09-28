import 'package:flame/components.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_combat_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_workspace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/map_host_fixture.dart';
import '../support/combat_project_fixture.dart';
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';

void main() {
  testWidgets(
    'Studio creates a wild table and trainer with independent reopen',
    (tester) async {
      await tester.runAsync(loadDesktopCaptureFonts);
      final captureKey = GlobalKey();
      final host = await MapHostFixture.open(
        tester,
        prepareSource: seedCombatProject,
        captureKey: captureKey,
      );
      await host.go('Pokémon');
      await tester.tap(find.text('Combats').first);
      await pumpIo(tester);
      await tester.tap(find.text('Créer une table').last);
      await pumpIo(tester);
      await tester.enterText(find.byType(TextField).last, 'jardin_wild');
      await tester.tap(find.text('Créer').last);
      await pumpIo(tester);
      await tester.tap(find.text('Ajouter une espèce').last);
      await pumpIo(tester);
      await tester.tap(find.text('Bulbizarre').last);
      await pumpIo(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('jardin_wild:chance')),
          matching: find.byType(TextField),
        ),
        '100',
      );
      await tester.tap(find.text('Enregistrer').last);
      await pumpIo(tester);
      final workspace = tester
          .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
          .controller!;
      expect(workspace.combat!.dirty, isFalse);
      expect(
        host.maps.project!.encounterTables.any(
          (table) => table.id == 'jardin_wild',
        ),
        isTrue,
      );
      await captureM3Widget(
        tester,
        captureKey,
        'combat-01-rencontres-sauvages',
      );

      await tester.tap(find.text('Dresseurs').last);
      await pumpIo(tester);
      await tester.tap(find.text('Créer un dresseur').last);
      await pumpIo(tester);
      await tester.enterText(find.byType(TextField).last, 'Chef gare');
      await tester.tap(find.text('Créer').last);
      await pumpIo(tester);
      await tester.tap(find.text('Ajouter un Pokémon').last);
      await pumpIo(tester);
      await tester.tap(find.text('Bulbizarre').last);
      await pumpIo(tester);
      await tester.tap(find.text('Enregistrer').last);
      await pumpIo(tester);
      expect(workspace.combat!.dirty, isTrue);
      expect(workspace.combat!.error, contains('au moins une attaque'));
      final movePicker = find.widgetWithText(
        DropdownButtonFormField<String>,
        'Ajouter une attaque',
      );
      await tester.ensureVisible(movePicker);
      await tester.tap(movePicker);
      await pumpIo(tester);
      await tester.tap(find.text('Charge').last);
      await pumpIo(tester);
      await tester.tap(find.text('Enregistrer').last);
      await pumpIo(tester);
      expect(workspace.combat!.dirty, isFalse);
      expect(
        host.maps.project!.trainers.any((trainer) => trainer.id == 'chef_gare'),
        isTrue,
      );
      await captureM3Widget(tester, captureKey, 'combat-02-dresseurs');

      await tester.tap(find.text('Rencontres uniques').last);
      await pumpIo(tester);
      await tester.tap(find.text('Créer une rencontre unique').last);
      await pumpIo(tester);
      await tester.enterText(find.byType(TextField).last, 'rencontre_gare');
      await tester.tap(find.text('Créer').last);
      await pumpIo(tester);
      await tester.tap(find.text('Ajouter une espèce').last);
      await pumpIo(tester);
      await tester.tap(find.text('Bulbizarre').last);
      await pumpIo(tester);
      await tester.tap(find.text('Enregistrer').last);
      await pumpIo(tester);
      expect(workspace.combat!.dirty, isFalse);
      await captureM3Widget(tester, captureKey, 'combat-03-rencontres-uniques');

      await host.go('Carte');
      await tester.ensureVisible(find.text('Zones').first);
      await pumpIo(tester);
      await tester.tap(find.text('Zones').first);
      await pumpIo(tester);
      final paintTool = find.text('Case par case');
      await tester.ensureVisible(paintTool);
      await tester.tap(paintTool);
      await pumpIo(tester);
      final stroke = await tester.startGesture(host.cellAt(9, 9));
      await stroke.moveTo(host.cellAt(11, 9));
      await stroke.moveTo(host.cellAt(11, 11));
      await stroke.up();
      await pumpIo(tester);
      final painted = host.document.current.gameplayZones.single;
      expect(painted.cellMask, hasLength(5));
      await tester.tap(find.byKey(ValueKey('zone-table-${painted.id}')));
      await pumpIo(tester);
      await tester.tap(find.text('jardin_wild').last);
      await pumpIo(tester);
      expect(
        host.document.current.gameplayZones.single.encounter?.encounterTableId,
        'jardin_wild',
      );
      await captureM3Widget(tester, captureKey, 'combat-04-cases-peintes');
      final selectTool = find.byKey(const ValueKey('Sélectionner')).first;
      await tester.ensureVisible(selectTool);
      await tester.tap(selectTool);
      await pumpIo(tester);
      await host.tapCell(7, 9);
      final trainerPicker = find.byKey(
        const ValueKey('trainer-combat-guide-null'),
      );
      await tester.ensureVisible(trainerPicker);
      await tester.tap(trainerPicker);
      await pumpIo(tester);
      await tester.tap(find.text('Chef gare').last);
      await pumpIo(tester);
      expect(
        host.document.current.entities
            .singleWhere((value) => value.id == 'combat-guide')
            .npc
            ?.trainerId,
        'chef_gare',
      );
      expect(
        await tester.runAsync(() => host.maps.save(host.document)),
        isTrue,
      );

      final reopened = (await tester.runAsync(() async {
        final session = ProjectSession(
          sessionId: 'independent-combat-reader',
          name: host.source.session.name,
          directoryPath: host.source.directory.path,
        );
        final maps = LocalMapWorkspaceAdapter();
        await maps.loadProject(session);
        final combat = await LocalPokemonCombatAdapter(
          session: session,
          mapAdapter: maps,
        ).load();
        final map = await maps.loadMap(session, combat.project.maps.first);
        return (combat, map.map);
      }))!;
      final combat = reopened.$1;
      final map = reopened.$2;
      final table = combat.project.encounterTables.singleWhere(
        (value) => value.id == 'jardin_wild',
      );
      final trainer = combat.project.trainers.singleWhere(
        (value) => value.id == 'chef_gare',
      );
      expect(table.entries.single.speciesId, 'bulbasaur');
      expect(trainer.team.single.speciesId, 'bulbasaur');
      expect(
        map.entities
            .singleWhere((value) => value.id == 'combat-guide')
            .npc
            ?.trainerId,
        trainer.id,
      );
      final unique = combat.project.encounterTables.singleWhere(
        (value) => value.id == 'rencontre_gare',
      );
      expect(unique.tags, contains('studio:unique'));
      expect(unique.entries.single.minLevel, unique.entries.single.maxLevel);
      final restoredZone = map.gameplayZones.singleWhere(
        (zone) => zone.id == painted.id,
      );
      expect(restoredZone.cellMask, hasLength(5));
      expect(
        gameplayZoneContainsPosition(restoredZone, const GridPos(x: 10, y: 9)),
        isTrue,
      );
      expect(
        gameplayZoneContainsPosition(restoredZone, const GridPos(x: 10, y: 10)),
        isFalse,
      );
      expect(restoredZone.encounter?.encounterTableId, table.id);
      final playerBundle = await tester.runAsync(
        () => loadRuntimeMapBundle(
          projectFilePath: '${host.source.directory.path}/project.json',
          mapId: map.id,
        ),
      );
      expect(playerBundle?.map.gameplayZones.single.cellMask, hasLength(5));
      expect(
        playerBundle?.manifest.encounterTables.any(
          (value) => value.id == table.id,
        ),
        isTrue,
      );
      final enteredBattle = await tester.runAsync(() async {
        final game = _CombatGame(
          bundle: playerBundle!,
          projectFilePath: '${host.source.directory.path}/project.json',
        );
        try {
          game.onGameResize(Vector2(640, 480));
          await game.onLoad();
          await _until(
            game,
            () =>
                !game.debugIsMapActivationDispatchInFlight &&
                !game.inputAuthoritySnapshot.isGameplayLocked,
          );
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.right),
          );
          game.update(.016);
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.right),
          );
          await _until(game, () => game.debugEncounterCheckCount > 0);
          await _until(game, () => game.debugFlowPhaseName == 'battle');
          final wildPosition = game.debugPlayerGridPosition;
          game.debugResetBattleForTest();
          game.debugSetPlayerStateForTest(
            position: const GridPos(x: 8, y: 9),
            facing: Direction.west,
          );
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          );
          game.update(.016);
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.primary),
          );
          await _until(game, () => game.debugFlowPhaseName == 'battle');
          expect(
            game.debugActiveBattleRequest,
            isA<TrainerBattleStartRequest>(),
          );
          return wildPosition;
        } finally {
          game.onRemove();
        }
      });
      expect(enteredBattle, const GridPos(x: 9, y: 9));
      expect(tester.takeException(), isNull);
    },
  );
}

class _CombatGame extends PlayableMapGame {
  _CombatGame({required super.bundle, required super.projectFilePath});

  @override
  bool get isLoaded => true;
}

Future<void> _until(PlayableMapGame game, bool Function() done) async {
  for (var i = 0; i < 300; i++) {
    if (done()) return;
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError(
    'Le combat créé dans Studio ne démarre pas dans le Player : '
    'position=${game.debugPlayerGridPosition} '
    'phase=${game.debugFlowPhaseName} '
    'pas=${game.debugEncounterCheckCount} '
    'verrou=${game.inputAuthoritySnapshot.isGameplayLocked}.',
  );
}
