import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/gameplay/items/item_studio_gateway.dart';
import 'package:map_editor/src/features/gameplay/items/item_studio_workspace.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  testWidgets('loads canonical items and their readiness', (tester) async {
    final gateway = _FakeItemStudioGateway();

    await _pumpWorkspace(tester, gateway);

    expect(find.text('Potion'), findsWidgets);
    expect(find.text('Prêt'), findsOneWidget);
    expect(find.textContaining('newGame.initialBag'), findsOneWidget);
    expect(gateway.loadCount, 1);
  });

  testWidgets('creates an item then reloads the canonical snapshot', (
    tester,
  ) async {
    final gateway = _FakeItemStudioGateway();

    await _pumpWorkspace(tester, gateway);
    await tester.tap(find.byKey(const Key('item-studio-create-button')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('item-definition-name-field')),
      'Antidote',
    );
    await _tapVisible(
      tester,
      find.byKey(const Key('item-definition-save-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(gateway.savedOriginalItemId, isNull);
    expect(gateway.savedDefinition!.id, 'antidote');
    expect(gateway.loadCount, 2);
    expect(find.text('Antidote'), findsWidgets);
  });

  testWidgets('edits the selected item through the canonical gateway', (
    tester,
  ) async {
    final gateway = _FakeItemStudioGateway();

    await _pumpWorkspace(tester, gateway);
    await tester.enterText(
      find.byKey(const Key('item-definition-name-field')),
      'Potion Plus',
    );
    await _tapVisible(
      tester,
      find.byKey(const Key('item-definition-save-button')),
    );
    await tester.pump(const Duration(milliseconds: 20));

    expect(gateway.savedOriginalItemId, 'potion');
    expect(gateway.savedDefinition!.id, 'potion');
    expect(gateway.savedDefinition!.displayName, 'Potion Plus');
    expect(gateway.loadCount, 2);
  });

  testWidgets('reloads the canonical snapshot on demand', (tester) async {
    final gateway = _FakeItemStudioGateway();

    await _pumpWorkspace(tester, gateway);
    await tester.tap(find.byKey(const Key('item-studio-reload-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(gateway.loadCount, 2);
  });

  testWidgets('undoes the last item mutation then reloads', (tester) async {
    final gateway = _FakeItemStudioGateway();

    await _pumpWorkspace(tester, gateway);
    await tester.tap(find.byKey(const Key('item-studio-create-button')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('item-definition-name-field')),
      'Antidote',
    );
    await _tapVisible(
      tester,
      find.byKey(const Key('item-definition-save-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.tap(find.byKey(const Key('item-studio-undo-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(gateway.undoneReceiptId, 'receipt-1');
    expect(gateway.loadCount, 3);
  });

  testWidgets('shows a canonical mutation failure inline', (tester) async {
    final gateway = _FakeItemStudioGateway()..saveError = StateError('boom');

    await _pumpWorkspace(tester, gateway);
    await tester.tap(find.byKey(const Key('item-studio-create-button')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('item-definition-name-field')),
      'Antidote',
    );
    await _tapVisible(
      tester,
      find.byKey(const Key('item-definition-save-button')),
    );
    await tester.pump();

    expect(find.textContaining('boom'), findsOneWidget);
    expect(gateway.loadCount, 1);
  });
}

Future<void> _pumpWorkspace(
  WidgetTester tester,
  ItemStudioGateway gateway,
) async {
  await tester.binding.setSurfaceSize(const Size(1200, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.light(),
      home: Scaffold(
        body: ItemStudioWorkspace(
          projectRootPath: '/tmp/item-studio-test',
          gateway: gateway,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

final class _FakeItemStudioGateway implements ItemStudioGateway {
  final List<ProjectItemDefinition> definitions = <ProjectItemDefinition>[
    const ProjectItemDefinition(
      id: 'potion',
      displayName: 'Potion',
      pocketId: 'medicine',
      buyPrice: 300,
    ),
  ];

  int loadCount = 0;
  ProjectItemDefinition? savedDefinition;
  String? savedOriginalItemId;
  String? undoneReceiptId;
  Object? saveError;

  @override
  Future<ItemStudioCatalogSnapshot> load(String projectRootPath) async {
    loadCount++;
    return ItemStudioCatalogSnapshot(
      definitions: List<ProjectItemDefinition>.unmodifiable(definitions),
      readinessByItemId: const <String, ItemStudioReadiness>{
        'potion': ItemStudioReadiness(
          ready: true,
          diagnostics: <ItemStudioDiagnostic>[],
        ),
      },
      usagesByItemId: const <String, List<ItemStudioUsage>>{
        'potion': <ItemStudioUsage>[
          ItemStudioUsage(
            kind: 'initialBag',
            sourceKind: 'project',
            sourceId: 'project',
            editablePath: 'newGame.initialBag[0].itemId',
            blocksDeletion: true,
          ),
        ],
      },
      snapshotRevision: 'revision-$loadCount',
    );
  }

  @override
  Future<ItemStudioMutationReceipt> save(
    String projectRootPath, {
    required ProjectItemDefinition definition,
    required String snapshotRevision,
    String? originalItemId,
  }) async {
    final error = saveError;
    if (error != null) throw error;
    savedDefinition = definition;
    savedOriginalItemId = originalItemId;
    definitions.removeWhere((item) => item.id == originalItemId);
    definitions.add(definition);
    return const ItemStudioMutationReceipt(receiptId: 'receipt-1');
  }

  @override
  Future<Map<String, Object?>> simulate(
    String projectRootPath, {
    required String itemId,
    required ProjectItemUseContext context,
  }) async {
    return <String, Object?>{'status': 'configured', 'context': context.name};
  }

  @override
  Future<void> undo(String projectRootPath, {required String receiptId}) async {
    undoneReceiptId = receiptId;
    definitions.removeWhere((item) => item.id == 'antidote');
  }
}
