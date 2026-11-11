import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog_view.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';
import 'ledge_border_metadata_test.dart' show NativeLedgeResourceFixture;

Future<Map<String, List<int>>> _files(Directory root) async => {
  for (final entity in root.listSync(recursive: true))
    if (entity is File) entity.path: await entity.readAsBytes(),
};

Future<_Host> _open(
  WidgetTester tester, {
  Size size = const Size(1536, 1024),
  bool unpublished = false,
  bool deprecated = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final host = (await tester.runAsync(() async {
    final fixture = await NativeLedgeResourceFixture.create(
      isDeprecated: deprecated,
    );
    var borderId = fixture.record.id;
    if (unpublished) {
      final receipt = await fixture.resources.createBorder(
        const BorderCreationRequest(
          name: 'Bordure non publiée',
          publish: false,
        ),
      );
      borderId = receipt.manifest.borderCatalog.records
          .singleWhere((record) => record.id != fixture.record.id)
          .id;
    }
    final workspace = MapWorkspaceController(fixture.session, fixture.maps);
    await workspace.initialize();
    await workspace.materializeProject();
    final visuals = WorkspaceTestVisuals();
    final used = <ResourceItem>[];
    final navigation = ResourceNavigation(
      workspace: workspace,
      port: fixture.resources,
      visuals: visuals,
      onUse: used.add,
    );
    final item = resourceCatalog(workspace.project!)
        .singleWhere((item) => item.border?.id == borderId);
    return _Host(
      fixture,
      workspace,
      visuals,
      navigation,
      item,
      used,
      await _files(fixture.root),
      workspace.project!.toJson(),
    );
  }))!;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    host.navigation.dispose();
    host.workspace.dispose();
    host.visuals.dispose();
    await tester.runAsync(host.fixture.dispose);
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: AnimatedBuilder(
          animation: host.navigation,
          builder: (context, _) => ResourceWorkspacePane(
            navigation: host.navigation,
            picker: () async => null,
            onBack: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return host;
}

Future<void> _openDetail(WidgetTester tester, _Host host) async {
  final card = find.byKey(ValueKey('resource-card-${host.item.identity}'));
  await tester.scrollUntilVisible(
    card,
    240,
    scrollable: find
        .descendant(
          of: find.byType(ResourceCatalogView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.tap(card);
  await tester.pumpAndSettle();
}

Future<void> _expectUnchanged(WidgetTester tester, _Host host) async {
  await tester.runAsync(() async {
    expect(await _files(host.fixture.root), host.beforeFiles);
  });
  expect(host.workspace.project!.toJson(), host.beforeProject);
}

void main() {
  for (final size in [const Size(1536, 1024), const Size(760, 620)]) {
    testWidgets(
      'published Borders remain usable when a retired workshop is requested at $size',
      (tester) async {
        final host = await _open(tester, size: size);
        await _openDetail(tester, host);
        expect(
          find.byKey(const ValueKey('resource-border-workshop-unavailable')),
          findsOneWidget,
        );
        expect(find.text('Ouvrir l’atelier'), findsNothing);
        expect(
          tester
              .widget<StudioButton>(find.byKey(const ValueKey('resource-use')))
              .onPressed,
          isNotNull,
        );
        await tester.tap(find.byKey(const ValueKey('resource-use')));
        await tester.pumpAndSettle();
        expect(host.used.map((item) => item.identity), [host.item.identity]);
        await _expectUnchanged(tester, host);

        if (size.width < 1000) {
          expect(find.text('Retour aux ressources'), findsNothing);
          expect(find.text('Détail de la ressource'), findsNothing);
          expect(
            find.byKey(const ValueKey('resource-border-workshop-unavailable')),
            findsNothing,
          );
        }
        expect(find.byType(ResourceCatalogView), findsOneWidget);
        expect(
          find
              .byKey(ValueKey('resource-card-${host.item.identity}'))
              .hitTestable(),
          findsOneWidget,
        );
        host.navigation.edit(host.item);
        await tester.pumpAndSettle();
        expect(host.navigation.library.atelierVisible, isTrue);
        expect(host.navigation.library.family, ResourceLibraryFamily.borders);
        expect(
          find.byKey(
            const ValueKey('resource-border-workshop-unavailable-state'),
          ),
          findsOneWidget,
        );
        expect(find.text('Atelier des bordures indisponible'), findsOneWidget);
        await _expectUnchanged(tester, host);

        await tester.tap(
          find.byKey(const ValueKey('resource-border-return-to-catalog')),
        );
        await tester.pumpAndSettle();
        expect(host.navigation.library.atelierVisible, isFalse);
        expect(find.byType(ResourceCatalogView), findsOneWidget);
        await _openDetail(tester, host);
        expect(find.text('Ouvrir l’atelier'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('resource-use')));
        await tester.pumpAndSettle();
        expect(host.used.map((item) => item.identity), [
          host.item.identity,
          host.item.identity,
        ]);
        await _expectUnchanged(tester, host);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final state in ['unpublished', 'deprecated']) {
    testWidgets(
      '$state Borders keep their placement refusal after workshop retirement',
      (tester) async {
        final host = await _open(
          tester,
          unpublished: state == 'unpublished',
          deprecated: state == 'deprecated',
        );
        await _openDetail(tester, host);
        expect(
          find.byKey(const ValueKey('resource-border-workshop-unavailable')),
          findsOneWidget,
        );
        expect(find.text('Ouvrir l’atelier'), findsNothing);
        expect(
          tester
              .widget<StudioButton>(find.byKey(const ValueKey('resource-use')))
              .onPressed,
          isNull,
        );
        expect(host.used, isEmpty);
        await _expectUnchanged(tester, host);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

final class _Host {
  _Host(
    this.fixture,
    this.workspace,
    this.visuals,
    this.navigation,
    this.item,
    this.used,
    this.beforeFiles,
    this.beforeProject,
  );

  final NativeLedgeResourceFixture fixture;
  final MapWorkspaceController workspace;
  final WorkspaceTestVisuals visuals;
  final ResourceNavigation navigation;
  final ResourceItem item;
  final List<ResourceItem> used;
  final Map<String, List<int>> beforeFiles;
  final Map<String, dynamic> beforeProject;
}
