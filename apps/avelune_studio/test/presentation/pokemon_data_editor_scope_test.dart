import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_commerce_port.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_item_overview.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
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

  Future<PokemonCommerceController> pump(
    WidgetTester tester,
    ProjectItemDefinition selected,
  ) async {
    VoidCallback redraw = () {};
    final commerce = PokemonCommerceController(
      _Port([potion, pokeBall, relic]),
      changed: () => redraw(),
    );
    await commerce.load();
    commerce.selectItem(selected);
    addTearDown(commerce.dispose);
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              redraw = () => setState(() {});
              return SingleChildScrollView(
                child: PokemonItemOverview(commerce: commerce),
              );
            },
          ),
        ),
      ),
    );
    return commerce;
  }

  StudioSelect pocket(WidgetTester tester, String id) =>
      tester.widget<StudioSelect>(find.byKey(ValueKey('item-pocket-$id')));

  testWidgets('the pocket is chosen among localized available pockets', (
    tester,
  ) async {
    final commerce = await pump(tester, potion);
    final select = pocket(tester, 'potion');
    expect(select.value, 'medicine');
    expect(select.options['medicine'], 'Soins');
    expect(select.options['balls'], 'Balls');
    expect(select.options['ancient-relics'], 'ancient-relics');
    expect(select.options, contains(pokemonNewPocketChoice));
    select.onChanged!('balls');
    await tester.pump();
    expect(commerce.item!.pocketId, 'balls');
    expect(find.textContaining('Identifiant de poche : balls'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new pocket is created explicitly and validated', (
    tester,
  ) async {
    final commerce = await pump(tester, potion);
    pocket(tester, 'potion').onChanged!(pokemonNewPocketChoice);
    await tester.pump();
    expect(commerce.item!.pocketId, 'medicine');
    final field = find.byKey(const ValueKey('item-new-pocket-potion'));
    expect(field, findsOneWidget);
    await tester.enterText(
      find.descendant(of: field, matching: find.byType(TextField)),
      '  ',
    );
    await tester.pump();
    expect(commerce.item!.pocketId, 'medicine');
    await tester.enterText(
      find.descendant(of: field, matching: find.byType(TextField)),
      'fossils',
    );
    await tester.pump();
    expect(commerce.item!.pocketId, 'fossils');
    expect(tester.takeException(), isNull);
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
