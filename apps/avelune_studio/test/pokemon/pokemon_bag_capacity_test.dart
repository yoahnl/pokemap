import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_commerce_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_bag_capacity_dialog.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';

void main() {
  testWidgets('Studio preserves invalid raw across pockets and saves bounds', (
    tester,
  ) async {
    final port = _Port();
    final commerce = PokemonCommerceController(port, changed: () {});
    addTearDown(commerce.dispose);
    await commerce.load();
    await _pump(tester, commerce);
    await tester.tap(find.byKey(const Key('bag-capacity-quantity-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limité').last);
    await tester.pumpAndSettle();
    await tester.enterText(_field('medicine', 'quantity'), '2.5');
    await _mode(tester, 'quantity', 'limited');
    _pocket(tester, 'tools');
    await tester.pump();
    expect(
      tester
          .widget<StudioReviewDialog>(find.byType(StudioReviewDialog))
          .onConfirmed,
      isNull,
    );
    _pocket(tester, 'medicine');
    await tester.pump();
    expect(
      tester.widget<TextField>(_field('medicine', 'quantity')).controller!.text,
      '2.5',
    );
    await tester.enterText(_field('medicine', 'quantity'), '99');
    await _mode(tester, 'distinct', 'limited');
    await tester.enterText(_field('medicine', 'distinct'), '2');
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(port.saved.single.pockets, {
      'medicine': const BagPocketCapacity(
        maxDistinctItems: 2,
        maxQuantityPerItem: 99,
      ),
    });
    expect(commerce.snapshot!.project.bagCapacity, port.saved.single);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(_field('medicine', 'distinct')).controller!.text,
      '2',
    );
    await tester.tap(find.text('Tout rendre illimité'));
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(port.saved.last.isUnlimited, true);
  });

  testWidgets(
    'Studio orphan pockets remain accessible and cancel never writes',
    (tester) async {
      final port = _Port(
        capacity: const ProjectBagCapacity(
          pockets: {'orphan': BagPocketCapacity(maxDistinctItems: 1)},
        ),
      );
      final commerce = PokemonCommerceController(port, changed: () {});
      addTearDown(commerce.dispose);
      await commerce.load();
      await _pump(tester, commerce);
      expect(
        tester
            .widget<StudioSelect>(find.byKey(const Key('bag-capacity-pocket')))
            .options
            .keys,
        contains('orphan'),
      );
      await tester.tap(find.text('Tout rendre illimité'));
      await tester.pump();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(port.saved, isEmpty);
      expect(
        commerce.snapshot!.project.bagCapacity.pockets,
        contains('orphan'),
      );
    },
  );

  testWidgets('Studio save refusal preserves raw and does not commit draft', (
    tester,
  ) async {
    final port = _Port()..reject = true;
    final commerce = PokemonCommerceController(port, changed: () {});
    addTearDown(commerce.dispose);
    await commerce.load();
    await _pump(tester, commerce);
    await _mode(tester, 'distinct', 'limited');
    await tester.enterText(_field('medicine', 'distinct'), '3');
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Changed externally'), findsOneWidget);
    expect(
      tester.widget<TextField>(_field('medicine', 'distinct')).controller!.text,
      '3',
    );
    expect(port.saved, isEmpty);
  });

  test(
    'Studio controller refuses capacity writes while an item is dirty',
    () async {
      final port = _Port();
      final commerce = PokemonCommerceController(port, changed: () {});
      addTearDown(commerce.dispose);
      await commerce.load();
      commerce.selectItem(_catalog.entries.first);
      commerce.editItem((entry) => entry.copyWith(displayName: 'Draft'));
      expect(
        await commerce.saveBagCapacity(
          const ProjectBagCapacity.unlimited(),
          const ProjectBagCapacity(
            pockets: {'medicine': BagPocketCapacity(maxDistinctItems: 2)},
          ),
        ),
        false,
      );
      expect(port.saved, isEmpty);
      expect(commerce.item!.displayName, 'Draft');
    },
  );

  test(
    'Studio accepts the saved capacity without reloading the workshop',
    () async {
      final port = _Port()..failReload = true;
      final commerce = PokemonCommerceController(port, changed: () {});
      addTearDown(commerce.dispose);
      await commerce.load();
      const capacity = ProjectBagCapacity(
        pockets: {'medicine': BagPocketCapacity(maxDistinctItems: 2)},
      );
      expect(
        await commerce.saveBagCapacity(
          const ProjectBagCapacity.unlimited(),
          capacity,
        ),
        true,
      );
      expect(port.saved, [capacity]);
      expect(commerce.snapshot!.project.bagCapacity, capacity);
      expect(commerce.error, isNull);
      expect(port.loads, 1);
      expect(commerce.snapshot!.referencesComplete, isFalse);
    },
  );

  for (final refreshFailure in [false, true]) {
    test(
      'Studio adapter persists capacity with canonical stale checks and independent reopen, refreshFailure=$refreshFailure',
      () async {
        final temporary = await Directory.systemTemp.createTemp(
          'studio-bag-capacity-',
        );
        final root = Directory(await temporary.resolveSymbolicLinks());
        addTearDown(() => root.delete(recursive: true));
        final project = _project(const ProjectBagCapacity.unlimited());
        final manifest = File('${root.path}/project.json');
        await manifest.writeAsString(jsonEncode(project.toJson()));
        final items = File('${root.path}/data/pokemon/catalogs/items.json');
        await items.parent.create(recursive: true);
        await items.writeAsString(jsonEncode(_catalog.toJson()));
        final session = ProjectSession(
          sessionId: root.path,
          name: 'Bag',
          directoryPath: root.path,
        );
        final reader = _PostCommitFailureReader();
        final maps = LocalMapWorkspaceAdapter(reader: reader);
        await maps.loadProject(session);
        final adapter = LocalPokemonCommerceAdapter(
          session: session,
          mapAdapter: maps,
        );
        final initial = await adapter.load();
        reader.failCommitted = refreshFailure;
        const capacity = ProjectBagCapacity(
          pockets: {
            'medicine': BagPocketCapacity(
              maxDistinctItems: 2,
              maxQuantityPerItem: 99,
            ),
          },
        );
        final commerce = PokemonCommerceController(adapter, changed: () {});
        addTearDown(commerce.dispose);
        await commerce.load();
        expect(
          await commerce.saveBagCapacity(initial.project.bagCapacity, capacity),
          true,
        );
        expect(commerce.snapshot!.project.bagCapacity, capacity);
        if (refreshFailure) {
          expect(commerce.error, contains('Capacité enregistrée'));
        }
        reader.failCommitted = false;
        final independent = ProjectManifest.fromJson(
          jsonDecode(await manifest.readAsString()) as Map<String, dynamic>,
        );
        expect(independent.bagCapacity, capacity);
        expect((await adapter.load()).project.bagCapacity, capacity);
        final bytes = await manifest.readAsBytes();
        await expectLater(
          adapter.saveBagCapacity(
            const ProjectBagCapacity.unlimited(),
            const ProjectBagCapacity(
              pockets: {'tools': BagPocketCapacity(maxDistinctItems: 1)},
            ),
          ),
          throwsStateError,
        );
        expect(await manifest.readAsBytes(), bytes);
        await adapter.saveBagCapacity(
          capacity,
          const ProjectBagCapacity.unlimited(),
        );
        expect((await adapter.load()).project.bagCapacity.isUnlimited, true);
      },
    );
  }
}

Finder _field(String pocket, String field) => find.descendant(
  of: find.byKey(ValueKey('bag-capacity-$pocket-$field-value')),
  matching: find.byType(TextField),
);

Future<void> _mode(WidgetTester tester, String field, String value) async {
  tester
      .widget<StudioSelect>(find.byKey(ValueKey('bag-capacity-$field-mode')))
      .onChanged!(value);
  await tester.pump();
}

void _pocket(WidgetTester tester, String id) => tester
    .widget<StudioSelect>(find.byKey(const Key('bag-capacity-pocket')))
    .onChanged!(id);

Future<void> _pump(
  WidgetTester tester,
  PokemonCommerceController commerce,
) async {
  await tester.binding.setSurfaceSize(const Size(1100, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showPokemonBagCapacityDialog(context, commerce),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

const _catalog = ProjectItemCatalog(
  schemaVersion: 1,
  entries: [
    ProjectItemDefinition(
      id: 'medicine_a',
      displayName: 'Medicine A',
      pocketId: 'medicine',
    ),
    ProjectItemDefinition(
      id: 'tool_a',
      displayName: 'Tool A',
      pocketId: 'tools',
    ),
  ],
);

ProjectManifest _project(ProjectBagCapacity capacity) => ProjectManifest(
  name: 'Bag',
  maps: const [],
  tilesets: const [],
  bagCapacity: capacity,
  pokemon: const ProjectPokemonConfig(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
  ),
);

final class _Port implements PokemonCommercePort {
  _Port({this.capacity = const ProjectBagCapacity.unlimited()});
  ProjectBagCapacity capacity;
  final saved = <ProjectBagCapacity>[];
  bool reject = false;
  bool failReload = false;
  int loads = 0;
  @override
  Future<PokemonCommerceSnapshot> load() async {
    loads++;
    if (failReload && saved.isNotEmpty) {
      failReload = false;
      throw StateError('Refresh unavailable');
    }
    return PokemonCommerceSnapshot(
      project: _project(capacity),
      catalog: _catalog,
      shops: const [],
      references: ProjectItemReferenceIndex(const []),
      narrativeReferences: NarrativeDependencyIndex(),
      shopDiagnostics: const [],
      catalogPath: 'data/pokemon/catalogs/items.json',
      problem: null,
    );
  }

  @override
  Future<({String? refreshWarning})> saveBagCapacity(
    ProjectBagCapacity before,
    ProjectBagCapacity after,
  ) async {
    if (reject || before != capacity) throw StateError('Changed externally');
    capacity = after;
    saved.add(after);
    return (refreshWarning: null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _PostCommitFailureReader implements ProjectFileReader {
  bool failCommitted = false;
  final delegate = const LocalProjectFileReader();

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    final bytes = await delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    if (failCommitted &&
        relativePath == 'project.json' &&
        (jsonDecode(utf8.decode(bytes)) as Map).containsKey('bagCapacity')) {
      throw StateError('Post-commit atelier refresh unavailable');
    }
    return bytes;
  }
}
