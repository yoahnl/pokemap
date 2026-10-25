import 'dart:typed_data';

import 'package:avelune_studio/features/pokemon/application/pokemon_combat_controller.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_combat_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_commerce_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/regional_map/application/regional_map_controller.dart';
import 'package:avelune_studio/features/regional_map/domain/regional_map_port.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_combat_page.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_commerce_references.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

const _project = ProjectManifest(
  name: 'References',
  maps: [],
  tilesets: [],
  encounterTables: [
    ProjectEncounterTable(id: 'table', name: 'Table', encounterKind: EncounterKind.walk, entries: []),
  ],
);

void main() {
  test(
    'combat deletion requires an explicit complete reference analysis',
    () async {
      final port = _CombatPort();
      final owner = PokemonCombatController(port, changed: () {});
      await owner.load();
      owner.selectTable(_project.encounterTables.single);
      expect(await owner.deleteSelected(), isFalse);
      expect(port.deleted, 0);
      expect(port.analyzed, 0);
      expect(owner.error, contains('Analysez'));
      await owner.analyzeReferences();
      expect(port.analyzed, 1);
      expect(owner.snapshot!.referencesComplete, isTrue);
      expect(await owner.deleteSelected(), isTrue);
      expect(port.deleted, 1);
    },
  );

  testWidgets(
    'combat exposes analysis and disables delete while its references are incomplete',
    (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final port = _CombatPort();
      VoidCallback rebuild = () {};
      final owner = PokemonCombatController(port, changed: () => rebuild());
      await owner.load();
      owner.selectTable(_project.encounterTables.single);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = () => setState(() {});
                return PokemonCombatPage(
                  combat: owner,
                  index: const PokemonWorkspaceIndex(
                    enabled: true,
                    entries: [],
                    moves: PokemonMovesCatalogView(
                      entries: [],
                      relativePath: '',
                    ),
                    types: [],
                    items: {},
                  ),
                );
              },
            ),
          ),
        ),
      );
      expect(port.analyzed, 0);
      final delete = tester
          .widgetList<StudioButton>(find.byType(StudioButton))
          .singleWhere((button) => button.label == 'Supprimer');
      expect(delete.onPressed, isNull);
      expect(
        find.text('Aucune carte ou scène ne référence cette fiche.'),
        findsNothing,
      );
      await tester.tap(find.text('Analyser les usages du projet'));
      await tester.pumpAndSettle();
      expect(port.analyzed, 1);
      expect(find.text('Analyser les usages du projet'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('commerce reference panel waits for explicit global analysis', (
    tester,
  ) async {
    final port = _CommercePort();
    VoidCallback rebuild = () {};
    final owner = PokemonCommerceController(port, changed: () => rebuild());
    await owner.load();
    owner.selectItem(owner.snapshot!.catalog!.entries.single);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = () => setState(() {});
              return PokemonCommerceReferences(
                commerce: owner,
                items: true,
                onOpenShop: (_) {},
              );
            },
          ),
        ),
      ),
    );
    expect(port.analyzed, 0);
    expect(
      find.text('Aucune référence trouvée dans les données enregistrées.'),
      findsNothing,
    );
    await tester.tap(find.text('Analyser les usages du projet'));
    await tester.pumpAndSettle();
    expect(port.analyzed, 1);
    expect(owner.snapshot!.referencesComplete, isTrue);
    expect(
      find.text('Aucune référence trouvée dans les données enregistrées.'),
      findsOneWidget,
    );
  });

  test(
    'regional controller loads only the selected destination and reuses it',
    () async {
      final port = _RegionalPort();
      final owner = RegionalMapController(port, changed: () {});
      await owner.load();
      expect(port.reads, 0);
      owner.createRegion('Kanto');
      owner.createPoint('Town', 'town');
      expect(owner.point, isNotNull);
      expect(port.reads, 0);
      owner.editPoint(
        destination: ProjectRegionDestination(
          mapId: 'town',
          spawnId: 'arrival',
        ),
      );
      expect(await owner.loadMap('town'), isTrue);
      expect(port.reads, 1);
      expect(await owner.loadMap('town'), isTrue);
      expect(port.reads, 1);
    },
  );
}

final class _CombatPort
    implements PokemonCombatPort, PokemonCombatReferencePort {
  int analyzed = 0, deleted = 0;
  @override
  Future<PokemonCombatSnapshot> load() async => const PokemonCombatSnapshot(
    project: _project,
    maps: [],
    referencesComplete: false,
  );
  @override
  Future<PokemonCombatSnapshot> analyzeReferences() async {
    analyzed++;
    return const PokemonCombatSnapshot(project: _project, maps: []);
  }

  @override
  Future<void> deleteTable(ProjectEncounterTable before) async {
    deleted++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final class _CommercePort
    implements PokemonCommercePort, PokemonCommerceReferencePort {
  int analyzed = 0;
  PokemonCommerceSnapshot source(bool complete) {
    const catalog = ProjectItemCatalog(
      schemaVersion: 1,
      entries: [
        ProjectItemDefinition(
          id: 'potion',
          displayName: 'Potion',
          pocketId: 'items',
        ),
      ],
    );
    return PokemonCommerceSnapshot(
      project: _project,
      catalog: catalog,
      shops: [],
      references: buildProjectItemReferenceIndex(project: _project, maps: []),
      narrativeReferences: buildNarrativeDependencyIndex(
        project: _project,
        maps: [],
      ),
      shopDiagnostics: [],
      catalogPath: 'items.json',
      problem: null,
      referencesComplete: complete,
    );
  }

  @override
  Future<PokemonCommerceSnapshot> load() async => source(false);
  @override
  Future<PokemonCommerceSnapshot> analyzeReferences() async {
    analyzed++;
    return source(true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final class _RegionalPort implements RegionalMapPort, RegionalMapDetailsPort {
  int reads = 0;
  @override
  Future<RegionalMapSource> load() async => RegionalMapSource(
    project: _project.copyWith(
      maps: [
        const ProjectMapEntry(
          id: 'town',
          name: 'Town',
          relativePath: 'maps/town.json',
        ),
      ],
    ),
    revision: 'revision',
    maps: {},
    images: {},
  );
  @override
  Future<MapData> readMap({
    required RegionalMapSource source,
    required String mapId,
  }) async {
    reads++;
    return const MapData(
      id: 'town',
      name: 'Town',
      size: GridSize(width: 4, height: 4),
    );
  }

  @override
  Future<Uint8List?> readImage(String path) async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
