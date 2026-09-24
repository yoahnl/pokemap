import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets('border preview notice belongs to Map while diagnostics remain', (
    tester,
  ) async {
    final host = await MapHostFixture.open(tester);
    host.document.commit(
      addBorderLayer(host.document.current, id: 'borders', name: 'Bordures'),
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    await host.go('Carte');
    await pumpIo(tester);
    expect(find.textContaining('Bordures non prévisualisées'), findsOneWidget);
    await host.go('Pokémon');
    await pumpIo(tester);
    expect(find.textContaining('Bordures non prévisualisées'), findsNothing);
    expect(
      find.textContaining('Aucun incident sur les ressources'),
      findsOneWidget,
    );
    await tester.tap(find.text('Attaques').first);
    await pumpIo(tester);
    expect(find.textContaining('Bordures non prévisualisées'), findsNothing);
    await host.go('Carte');
    await pumpIo(tester);
    expect(find.textContaining('Bordures non prévisualisées'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
