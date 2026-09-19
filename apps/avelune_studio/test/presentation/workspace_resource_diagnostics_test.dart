import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_resource_diagnostic.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_resource_diagnostics.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  for (final count in [0, 1, 200]) {
    testWidgets('$count diagnostics preserve canvas with large text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final visuals = _Visuals(_diagnostics(count));
      await tester.pumpWidget(_app(visuals, textScale: 1.75));
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const ValueKey('canvas'))).height,
        greaterThan(500),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('resource-summary'))).height,
        lessThan(80),
      );
      if (count == 0) {
        expect(find.byKey(const ValueKey('resource-details')), findsNothing);
      } else {
        await tester.tap(find.byKey(const ValueKey('resource-details')));
        await tester.pumpAndSettle();
        final panel = find.byKey(const ValueKey('resource-diagnostics-panel'));
        expect(tester.getSize(panel).height, lessThanOrEqualTo(640 * .70));
        expect(tester.getSize(panel).width, lessThanOrEqualTo(600));
        expect(tester.takeException(), isNull);
        if (count == 200) {
          expect(
            find.textContaining('Ressource très longue').evaluate().length,
            lessThan(20),
          );
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('resource-row-resource-199')),
            800,
            scrollable: find.descendant(
              of: find.byKey(const ValueKey('resource-diagnostics-list')),
              matching: find.byType(Scrollable),
            ),
            maxScrolls: 80,
          );
          expect(tester.takeException(), isNull);
        }
        await tester.tap(find.byKey(const ValueKey('Fermer les diagnostics')));
        await tester.pumpAndSettle();
        expect(panel, findsNothing);
        expect(find.byKey(const ValueKey('canvas')), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      await visuals.dispose();
    });
  }

  testWidgets('active filter retries failed resources only and updates live', (
    tester,
  ) async {
    final visuals = _Visuals(_diagnostics(200, retryingFirst: true));
    await tester.pumpWidget(_app(visuals));
    await tester.tap(find.byKey(const ValueKey('resource-details')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carte active'));
    await tester.pumpAndSettle();
    expect(find.text('2 ressources concernées'), findsOneWidget);
    expect(find.textContaining('Réessai en cours'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('resource-retry-filter')));
    await tester.pumpAndSettle();
    expect(visuals.retried, [
      <String>['resource-1'],
    ]);
    expect(find.text('1 ressources concernées'), findsOneWidget);
    await tester.tap(find.text('Toutes demandées'));
    await tester.pumpAndSettle();
    expect(find.text('199 ressources concernées'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await visuals.dispose();
  });

  testWidgets('deduplicates identities and groups memory with full details', (
    tester,
  ) async {
    final items = _diagnostics(
      200,
      cause: WorkspaceResourceCause.memoryPressure,
    );
    final visuals = _Visuals([...items, items.first]);
    await tester.pumpWidget(_app(visuals));
    expect(
      find.text('200 ressources en incident · ressources demandées'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('resource-details')));
    await tester.pumpAndSettle();
    expect(find.text('200 ressources · pression mémoire'), findsOneWidget);
    expect(find.byKey(const ValueKey('resource-row-memory')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('Voir le diagnostic complet')));
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsWidgets);
    expect(find.textContaining('Détail technique ressource 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await visuals.dispose();
  });
}

List<WorkspaceResourceDiagnostic> _diagnostics(
  int count, {
  WorkspaceResourceCause cause = WorkspaceResourceCause.missing,
  bool retryingFirst = false,
}) => [
  for (var index = 0; index < count; index++)
    WorkspaceResourceDiagnostic(
      resourceId: 'resource-$index',
      name:
          'Ressource très longue $index ${List.filled(20, 'atlas').join(' ')}',
      cause: cause,
      detail: 'Détail technique ressource $index',
      status: index == 0 && retryingFirst
          ? WorkspaceResourceStatus.retrying
          : WorkspaceResourceStatus.failed,
    ),
];

Widget _app(_Visuals visuals, {double textScale = 1}) => MaterialApp(
  theme: studioTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          const Expanded(child: SizedBox.expand(key: ValueKey('canvas'))),
          WorkspaceResourceDiagnostics(visuals: visuals),
        ],
      ),
    ),
  ),
);

class _Visuals implements MapWorkspaceVisuals {
  _Visuals(this.diagnostics);
  final _changes = ChangeNotifier();
  final retried = <List<String>>[];
  @override
  List<WorkspaceResourceDiagnostic> diagnostics;
  @override
  Set<String> get activeResourceIds => {'resource-0', 'resource-1'};
  @override
  List<String> get warnings => [];
  @override
  void addListener(VoidCallback listener) => _changes.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      _changes.removeListener(listener);
  @override
  Widget canvas(MapData map) => const SizedBox.expand();
  @override
  void setActiveMap(MapData map) {}
  @override
  void setBrush(ProjectElementEntry? element, TileLayerPaletteEntry? tile) {}
  @override
  Widget thumbnail(ProjectElementEntry element, {double size = 48}) =>
      SizedBox(width: size, height: size);
  @override
  Widget tileThumbnail(TileLayerPaletteEntry tile, {double size = 48}) =>
      SizedBox(width: size, height: size);
  @override
  Future<void> retryResources(Iterable<String> resourceIds) async {
    final ids = resourceIds.toList();
    retried.add(ids);
    diagnostics = diagnostics
        .where((item) => !ids.contains(item.resourceId))
        .toList();
    _changes.notifyListeners();
  }

  @override
  Future<void> dispose() async => _changes.dispose();
}
