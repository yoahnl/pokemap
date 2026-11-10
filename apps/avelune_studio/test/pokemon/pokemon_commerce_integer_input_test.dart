import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_commerce_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

const _item = ProjectItemDefinition(
  id: 'potion',
  displayName: 'Potion',
  pocketId: 'medicine',
  buyPrice: 300,
);

Future<(PokemonCommerceController, _IntegerPort)> _open() async {
  final port = _IntegerPort();
  final commerce = PokemonCommerceController(port, changed: () {});
  addTearDown(commerce.dispose);
  await commerce.load();
  commerce.selectItem(_item);
  return (commerce, port);
}

String? _price(
  PokemonCommerceController commerce,
  String value, {
  int minimum = 0,
  int? maximum,
  bool optional = true,
}) => commerce.setIntegerInput(
  fieldId: 'price',
  value: value,
  minimum: minimum,
  maximum: maximum,
  optional: optional,
  onChanged: (price) =>
      commerce.editItem((item) => item.copyWith(buyPrice: price)),
);

void main() {
  test(
    'invalid focused price remains raw and blocks save until corrected',
    () async {
      final (commerce, port) = await _open();
      expect(_price(commerce, '2.5'), 'Valeur entière ≥ 0 requise');
      expect(commerce.numericInputs['price'], '2.5');
      expect(commerce.item!.buyPrice, 300);
      expect(commerce.dirty, isTrue);
      expect(await commerce.save(), isFalse);
      expect(port.saved, isEmpty);
      expect(_price(commerce, '420'), isNull);
      expect(commerce.fieldErrors, isEmpty);
      expect(await commerce.save(), isTrue);
      expect(port.saved.single.buyPrice, 420);
    },
  );

  test(
    'required bounded integers refuse blanks negative and excessive values',
    () async {
      final (commerce, port) = await _open();
      for (final value in ['', '-1', '101', 'bad']) {
        expect(
          _price(commerce, value, maximum: 100, optional: false),
          'Valeur entière entre 0 et 100 requise',
        );
        expect(commerce.item!.buyPrice, 300);
        expect(commerce.numericInputs['price'], value);
      }
      expect(port.saved, isEmpty);
      expect(_price(commerce, '100', maximum: 100, optional: false), isNull);
      expect(commerce.item!.buyPrice, 100);
    },
  );

  test(
    'an optional empty value clears the canonical price and its error',
    () async {
      final (commerce, port) = await _open();
      _price(commerce, 'not-a-number');
      expect(_price(commerce, ''), isNull);
      expect(commerce.numericInputs['price'], '');
      expect(commerce.fieldErrors, isEmpty);
      expect(commerce.item!.buyPrice, isNull);
      expect(await commerce.save(), isTrue);
      expect(port.saved.single.buyPrice, isNull);
    },
  );

  test('discard removes every raw input and error before another owner is selected', () async {
    final (commerce, _) = await _open();
    _price(commerce, '2.5');
    expect(commerce.selectItem(_item.copyWith(id: 'other')), isFalse);
    expect(commerce.numericInputs['price'], '2.5');
    commerce.discardSelected();
    expect(commerce.numericInputs, isEmpty);
    expect(commerce.fieldErrors, isEmpty);
    expect(commerce.item, _item);
    expect(commerce.selectItem(_item.copyWith(id: 'other')), isTrue);
    expect(commerce.numericInputs, isEmpty);
  });

  test(
    'correcting one field cannot erase another invalid raw integer',
    () async {
      final (commerce, port) = await _open();
      _price(commerce, '2.5');
      commerce.setIntegerInput(
        fieldId: 'stock',
        value: '-1',
        onChanged: (_) {},
        minimum: 0,
      );
      _price(commerce, '450');
      expect(commerce.numericInputs, {'price': '450', 'stock': '-1'});
      expect(commerce.fieldErrors.keys, ['stock']);
      expect(await commerce.save(), isFalse);
      expect(port.saved, isEmpty);
    },
  );
}

class _IntegerPort implements PokemonCommercePort {
  final saved = <ProjectItemDefinition>[];
  @override
  Future<void> saveItem(
    ProjectItemDefinition? before,
    ProjectItemDefinition after,
  ) async {
    saved.add(after);
  }

  @override
  Future<PokemonCommerceSnapshot> load() async => PokemonCommerceSnapshot(
    project: const ProjectManifest(name: 'Commerce', maps: [], tilesets: []),
    catalog: const ProjectItemCatalog(schemaVersion: 1, entries: [_item]),
    shops: const [],
    references: ProjectItemReferenceIndex(const []),
    narrativeReferences: NarrativeDependencyIndex(),
    shopDiagnostics: const [],
    catalogPath: 'items.json',
    problem: null,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
