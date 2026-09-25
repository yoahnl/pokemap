import 'dart:async';

import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_commerce_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test(
    'refresh cannot replace an item edited during its awaited read',
    () async {
      final port = _HeldCommercePort();
      final commerce = PokemonCommerceController(port, changed: () {});
      await commerce.load();
      commerce.selectItem(commerce.snapshot!.catalog!.entries.single);
      final refresh = commerce.load(refresh: true);
      await port.refreshStarted.future;
      commerce.editItem((item) => item.copyWith(displayName: 'Brouillon'));
      port.refreshGate.complete();
      await refresh;
      expect(commerce.item!.displayName, 'Brouillon');
      expect(commerce.snapshot!.catalog!.entries.single.displayName, 'Potion');
      expect(commerce.error, contains('brouillon est conservé'));
      expect(port.loads, 2);
      await commerce.load(refresh: true);
      expect(port.loads, 2);
      commerce.dispose();
    },
  );
}

final class _HeldCommercePort implements PokemonCommercePort {
  final refreshStarted = Completer<void>();
  final refreshGate = Completer<void>();
  int loads = 0;

  @override
  Future<PokemonCommerceSnapshot> load() async {
    loads++;
    if (loads == 2) {
      refreshStarted.complete();
      await refreshGate.future;
    }
    return PokemonCommerceSnapshot(
      project: const ProjectManifest(name: 'Test', maps: [], tilesets: []),
      catalog: ProjectItemCatalog(
        schemaVersion: 1,
        entries: [
          ProjectItemDefinition(
            id: 'potion',
            displayName: loads == 1 ? 'Potion' : 'Potion externe',
            pocketId: 'items',
          ),
        ],
      ),
      shops: const [],
      references: ProjectItemReferenceIndex(const []),
      narrativeReferences: NarrativeDependencyIndex(),
      shopDiagnostics: const [],
      catalogPath: 'items.json',
      problem: null,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
