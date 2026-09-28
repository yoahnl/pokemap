import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
      size: const Size(1280, 800),
      textScale: 1.5,
    );
    await host.go('Pokémon');
    await tester.tap(find.text('Combats').first);
    await pumpIo(tester);
    await tester.tap(find.text('Créer une table').last);
    await pumpIo(tester);
    await tester.enterText(find.byType(TextField).last, 'petit_ecran');
    await tester.tap(find.text('Créer').last);
    await pumpIo(tester);

    expect(find.text('Enregistrer'), findsWidgets);
    expect(find.text('Annuler les modifications'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
