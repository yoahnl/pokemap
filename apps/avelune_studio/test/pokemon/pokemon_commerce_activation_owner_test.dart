import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_shop_editing.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_commerce_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

const _goldenItems =
    '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/items.json';

const _diagnostic = ShopStateDiagnostic(
  code: 'shop.state_invalid',
  severity: ShopStateDiagnosticSeverity.warning,
  message: 'État invalide',
  shopId: 'gare',
  path: 'states[0]',
);

const _otherDiagnostic = ShopStateDiagnostic(
  code: 'shop.state_invalid',
  severity: ShopStateDiagnosticSeverity.warning,
  message: 'Autre',
  shopId: 'port',
  path: 'states[0]',
);

final class _Port implements PokemonCommercePort {
  _Port(this.catalog);

  final ProjectItemCatalog catalog;

  @override
  Future<PokemonCommerceSnapshot> load() async => PokemonCommerceSnapshot(
    project: const ProjectManifest(name: 'Commerce', maps: [], tilesets: []),
    catalog: catalog,
    shops: const [
      ShopDefinition(id: 'gare', label: 'Boutique de la gare'),
      ShopDefinition(id: 'port', label: 'Boutique du port'),
    ],
    references: ProjectItemReferenceIndex(const []),
    narrativeReferences: NarrativeDependencyIndex(),
    shopDiagnostics: const [_diagnostic, _otherDiagnostic],
    catalogPath: 'items.json',
    problem: null,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ReferencePort extends _Port
    implements PokemonCommerceReferencePort {
  _ReferencePort(super.catalog);

  @override
  Future<PokemonCommerceSnapshot> analyzeReferences() => load();
}

Future<ProjectItemCatalog> _catalog() async => ProjectItemCatalog.fromJson(
  jsonDecode(await File(_goldenItems).readAsString()) as Map<String, dynamic>,
);

Future<PokemonCommerceController> _loaded(PokemonCommercePort port) async {
  final commerce = PokemonCommerceController(port, changed: () {});
  addTearDown(commerce.dispose);
  await commerce.load();
  return commerce;
}

void main() {
  group('analysis activation', () {
    test('needs a reference-capable port', () async {
      final catalog = await _catalog();
      expect((await _loaded(_Port(catalog))).canAnalyzeReferences, isFalse);
      expect(
        (await _loaded(_ReferencePort(catalog))).canAnalyzeReferences,
        isTrue,
      );
    });

    test('is off while the owner is busy or dirty', () async {
      final commerce = await _loaded(_ReferencePort(await _catalog()));
      for (final busy in <void Function(bool)>[
        (value) => commerce.loading = value,
        (value) => commerce.saving = value,
        (value) => commerce.importing = value,
      ]) {
        busy(true);
        expect(commerce.canAnalyzeReferences, isFalse);
        busy(false);
        expect(commerce.canAnalyzeReferences, isTrue);
      }
      commerce.selectItem(commerce.snapshot!.catalog!.entries.first);
      commerce.editItem((item) => item.copyWith(displayName: 'Brouillon'));
      expect(commerce.dirty, isTrue);
      expect(commerce.canAnalyzeReferences, isFalse);
    });
  });

  group('item filters', () {
    test('search matches the id or the display name, ignoring case', () async {
      final catalog = await _catalog();
      final potion = catalog.entries.firstWhere((item) => item.id == 'potion');
      expect(pokemonItemMatchesSearch(potion, ''), isTrue);
      expect(pokemonItemMatchesSearch(potion, '  '), isTrue);
      expect(pokemonItemMatchesSearch(potion, ' POT '), isTrue);
      expect(
        pokemonItemMatchesSearch(
          potion.copyWith(id: 'x', displayName: 'Super Soin'),
          'soin',
        ),
        isTrue,
      );
      expect(pokemonItemMatchesSearch(potion, 'zzz'), isFalse);
    });

    test('the open item is flagged once the filters hide it', () async {
      final commerce = await _loaded(_Port(await _catalog()));
      expect(commerce.selectedItemHiddenByFilters, isFalse);
      final item = commerce.snapshot!.catalog!.entries.first;
      commerce.selectItem(item);
      expect(commerce.selectedItemHiddenByFilters, isFalse);
      commerce.itemSearch = 'introuvable-xyz';
      expect(commerce.visibleItems, isEmpty);
      expect(commerce.selectedItemHiddenByFilters, isTrue);
      commerce.itemSearch = item.id;
      expect(commerce.selectedItemHiddenByFilters, isFalse);
    });

    test('the pocket filter narrows the visible items', () async {
      final commerce = await _loaded(_Port(await _catalog()));
      final all = commerce.visibleItems.length;
      final pocket = commerce.snapshot!.catalog!.entries.first.pocketId;
      commerce.pocketFilter = pocket;
      expect(
        commerce.visibleItems.every((item) => item.pocketId == pocket),
        isTrue,
      );
      expect(commerce.visibleItems, isNotEmpty);
      expect(commerce.visibleItems.length, lessThanOrEqualTo(all));
    });
  });

  test('a shop only sees its own state diagnostics', () async {
    final commerce = await _loaded(_Port(await _catalog()));
    expect(commerce.selectedShopDiagnostics, isEmpty);
    commerce.selectShop(commerce.snapshot!.shops.first);
    expect(commerce.selectedShopDiagnostics, [_diagnostic]);
    commerce.selectShop(commerce.snapshot!.shops.last);
    expect(commerce.selectedShopDiagnostics, [_otherDiagnostic]);
  });
}
