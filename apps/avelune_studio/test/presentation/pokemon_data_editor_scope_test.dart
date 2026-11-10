import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_commerce_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  final potion = ProjectItemDefinition(
    id: 'potion',
    displayName: 'Potion',
    pocketId: 'medicine',
  );
  final pokeBall = ProjectItemDefinition(
    id: 'poke-ball',
    displayName: 'Poké Ball',
    pocketId: 'balls',
  );
  final relic = ProjectItemDefinition(
    id: 'relic',
    displayName: 'Relique',
    pocketId: 'ancient-relics',
  );

  Future<PokemonCommerceController> open(ProjectItemDefinition selected) async {
    final commerce = PokemonCommerceController(
      _Port([potion, pokeBall, relic]),
      changed: () {},
    );
    addTearDown(commerce.dispose);
    await commerce.load();
    commerce.selectItem(selected);
    return commerce;
  }

  test('the pocket is chosen among localized available pockets', () async {
    final commerce = await open(potion);
    expect(commerce.item!.pocketId, 'medicine');
    expect(commerce.itemPocketOptions['medicine'], 'Soins');
    expect(commerce.itemPocketOptions['balls'], 'Balls');
    expect(commerce.itemPocketOptions['ancient-relics'], 'ancient-relics');
    expect(commerce.setItemPocket('balls'), isTrue);
    expect(commerce.item!.pocketId, 'balls');
  });

  test('a new pocket is created explicitly and validated', () async {
    final commerce = await open(potion);
    expect(commerce.setItemPocket('  '), isFalse);
    expect(commerce.item!.pocketId, 'medicine');
    expect(commerce.setItemPocket(' fossils '), isTrue);
    expect(commerce.item!.pocketId, 'fossils');
    expect(commerce.itemPocketOptions['fossils'], 'fossils');
    commerce.saving = true;
    expect(commerce.setItemPocket('balls'), isFalse);
    expect(commerce.item!.pocketId, 'fossils');
    commerce.saving = false;
    commerce.discardSelected();
    expect(commerce.item!.pocketId, 'medicine');
  });
}

final class _Port implements PokemonCommercePort {
  _Port(this.items);
  final List<ProjectItemDefinition> items;

  @override
  Future<PokemonCommerceSnapshot> load() async => PokemonCommerceSnapshot(
    project: const ProjectManifest(name: 'Objets', maps: [], tilesets: []),
    catalog: ProjectItemCatalog(schemaVersion: 1, entries: items),
    shops: const [],
    references: ProjectItemReferenceIndex(const []),
    narrativeReferences: NarrativeDependencyIndex(),
    shopDiagnostics: const [],
    catalogPath: 'data/pokemon/catalogs/items.json',
    problem: null,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
