import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  test('both item effect actions discover atomic full restore semantics', () {
    for (final id in ['item.set_overworld_effect', 'item.set_battle_effect']) {
      final descriptor =
          ItemCatalogActions.descriptors.singleWhere((d) => d.id == id);
      expect(descriptor.extensions['effectKinds'], contains('full_restore'));
      final contract = descriptor.extensions['fullRestore'] as Map;
      expect(contract['faintedTarget'], 'refused_without_consumption');
      expect(contract['consumption'], 'one_on_applied');
      expect(contract['restoresPp'], isFalse);
    }
  });
}
