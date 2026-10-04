import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import '../support/uwu5_character_host.dart';
import '../support/m2_ui_fixture.dart';

void main() {
  testWidgets(
    'published character removal retries UI without replaying delete',
    (tester) async {
      final host = await openUwU5CharacterHost(tester);
      final navigation = host.navigation;
      var reconciliations = 0;
      navigation.characterSourcesChanged = (_) {
        reconciliations++;
        throw StateError('Réconciliation injectée');
      };
      await host.tap('character-studio-remove');
      await host.tap('character-removal-confirm');
      await host.tap('resource-management-save');
      expect((await host.reopen()).characters.map((c) => c.id), ['remplacant']);
      final receipt = navigation.pendingReceipt!;
      expect(receipt.actionId, 'characterStudio.character.delete');
      expect(reconciliations, 1);
      expect(find.textContaining('publication a réussi'), findsWidgets);
      navigation.characterSourcesChanged = (_) => reconciliations++;
      final retry = navigation.retryReconciliation();
      await pumpIo(tester);
      final retried = await retry;
      expect(retried, true, reason: navigation.error);
      expect(navigation.pendingReceipt, isNull);
      expect(reconciliations, 2);
      expect((await host.reopen()).characters.map((c) => c.id), ['remplacant']);
      expect(navigation.characters.selectedId, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
