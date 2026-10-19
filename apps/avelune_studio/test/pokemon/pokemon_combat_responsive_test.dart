import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_combat_trainer_detail.dart';

import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/map_host_fixture.dart';
import '../support/combat_project_fixture.dart';

void main() {
  testWidgets('combat actions stay reachable at 1280x800 with large text', (
    tester,
  ) async {
    final host = await MapHostFixture.open(
      tester,
      prepareSource: seedCombatProject,
      size: const Size(1280, 1000),
      textScale: 1.5,
    );
    await host.go('Pokémon');
    await tester.tap(find.text('Combats').first);
    await pumpIo(tester);
    tester.view.physicalSize = const Size(1280, 800);
    await pumpIo(tester);
    await tester.tap(find.text('Créer une table').last);
    await pumpIo(tester);
    await tester.enterText(find.byType(TextField).last, 'petit_ecran');
    await tester.tap(find.text('Créer').last);
    await pumpIo(tester);

    expect(find.text('Enregistrer'), findsWidgets);
    expect(find.text('Annuler les modifications'), findsWidgets);
    await tester.tap(find.text('Annuler les modifications').last);
    await pumpIo(tester);
    await tester.tap(find.text('Dresseurs').last);
    await pumpIo(tester);
    await tester.tap(find.text('Créer un dresseur').last);
    await pumpIo(tester);
    await tester.enterText(find.byType(TextField).last, 'compact_stats');
    await tester.tap(find.text('Créer').last);
    await pumpIo(tester);
    await tester.scrollUntilVisible(
      find.text('Ajouter un Pokémon'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(PokemonCombatTrainerDetail),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await pumpIo(tester);
    await tester.tap(find.text('Ajouter un Pokémon').last);
    await pumpIo(tester);
    await tester.tap(find.text('Bulbizarre').last);
    await pumpIo(tester);
    final mode = find.byKey(const ValueKey('compact_stats:0:stats-mode'));
    await tester.ensureVisible(mode);
    await pumpIo(tester);
    expect(mode.hitTestable(), findsOneWidget);
    tester.widget<StudioSelect>(mode).onChanged!('advanced');
    await pumpIo(tester);
    for (final group in ['ivs', 'evs']) {
      for (final stat in trainerPokemonStatKeys) {
        final field = find.descendant(
          of: find.byKey(ValueKey('compact_stats:0:$group:$stat')),
          matching: find.byType(TextField),
        );
        await tester.ensureVisible(field);
        await pumpIo(tester);
        expect(field.hitTestable(), findsOneWidget);
        await tester.enterText(field, group == 'ivs' ? '15' : '0');
        await pumpIo(tester);
      }
    }
    final moves = find.byWidgetPredicate(
      (widget) =>
          widget is StudioSelect && widget.label == 'Ajouter une attaque',
    );
    await tester.ensureVisible(moves);
    await pumpIo(tester);
    expect(moves.hitTestable(), findsOneWidget);
    tester.widget<StudioSelect>(moves).onChanged!('tackle');
    await pumpIo(tester);
    await tester.tap(find.text('Enregistrer').last);
    await pumpIo(tester);
    expect(
      find.text('Annuler les modifications').last.hitTestable(),
      findsOneWidget,
    );
    expect(find.text('Supprimer').last.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
