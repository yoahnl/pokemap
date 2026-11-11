import 'dart:io';

import 'package:avelune_studio/features/decors/application/decor_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog_view.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';
import 'resource_fixture.dart';

Future<Map<String, List<int>>> _files(Directory root) async => {
  for (final entity in root.listSync(recursive: true))
    if (entity is File) entity.path: await entity.readAsBytes(),
};

Future<_Host> _open(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final host = (await tester.runAsync(() async {
    final owned = await Directory.systemTemp.createTemp('decor-retirement-');
    final fixture = await ResourceFixture.create(parent: owned);
    final imported = await fixture.import();
    await fixture.resources.saveElement(
      fixture.element(imported.createdTilesetId!),
    );
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
        .singleWhere((item) => item.element != null);
    return _Host(owned, fixture, workspace, visuals, navigation, item, used);
  }))!;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    host.navigation.dispose();
    host.workspace.dispose();
    host.visuals.dispose();
    await tester.runAsync(() async {
      await host.fixture.dispose();
      await host.owned.delete(recursive: true);
    });
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

Future<void> _openDetail(
  WidgetTester tester,
  _Host host, {
  ResourceItem? item,
}) async {
  final selected = item ?? host.item;
  final card = find.byKey(ValueKey('resource-card-${selected.identity}'));
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

void main() {
  for (final size in [const Size(1536, 1024), const Size(760, 620)]) {
    testWidgets(
      'retired decor workshop keeps its owner and published use at $size',
      (tester) async {
        final host = await _open(tester, size);
        final beforeFiles = await tester.runAsync(() => _files(host.owned));
        final beforeProject = host.workspace.project!.toJson();
        final beforeMap = host.workspace.active!.current;
        await _openDetail(tester, host);
        expect(
          find.byKey(const ValueKey('resource-decor-workshop-unavailable')),
          findsOneWidget,
        );
        expect(find.text('Modifier le décor'), findsNothing);
        expect(
          tester
              .widget<StudioButton>(find.byKey(const ValueKey('resource-use')))
              .onPressed,
          isNotNull,
        );
        await tester.tap(find.byKey(const ValueKey('resource-use')));
        await tester.pumpAndSettle();
        expect(host.used.map((item) => item.identity), [host.item.identity]);

        host.navigation.edit(host.item);
        final draft = host.navigation.decor!..name = 'Préparation conservée';
        draft.beginCollisionPointer(5, 10, fine: true, solid: true);
        draft.endCollisionPointer();
        final prepared = draft.build();
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            const ValueKey('resource-decor-workshop-unavailable-state'),
          ),
          findsOneWidget,
        );
        expect(find.text('Enregistrer le décor'), findsNothing);
        expect(host.navigation.dirty, isTrue);
        expect(draft.canUndoCollision, isTrue);
        await tester.tap(
          find.byKey(const ValueKey('resource-decor-return-to-catalog')),
        );
        await tester.pumpAndSettle();
        expect(host.navigation.page, ResourcePage.library);
        expect(host.navigation.decor, same(draft));
        expect(host.navigation.decorDraftFor(host.item.id), same(draft));
        expect(draft.build(), prepared);
        expect(draft.canUndoCollision, isTrue);
        expect(
          find.byKey(const ValueKey('resource-decor-draft-preserved')),
          findsOneWidget,
        );
        expect(find.text('Reprendre le décor'), findsNothing);
        await _openDetail(tester, host);
        await tester.tap(find.byKey(const ValueKey('resource-use')));
        await tester.pumpAndSettle();
        expect(host.used.map((item) => item.identity), [
          host.item.identity,
          host.item.identity,
        ]);
        expect(host.workspace.project!.toJson(), beforeProject);
        expect(host.workspace.active!.current, beforeMap);
        expect(await tester.runAsync(() => _files(host.owned)), beforeFiles);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'retired environment route keeps its recipe without opening a decor owner',
    (tester) async {
      final host = await _open(tester, const Size(1536, 1024));
      final beforeFiles = await tester.runAsync(() => _files(host.owned));
      final beforeProject = host.workspace.project!.toJson();
      host.navigation.openEnvironment();
      final draft = host.navigation.environment!
        ..name = 'Palette conservée'
        ..add(host.item.id);
      final prepared = draft.build();
      await tester.pumpAndSettle();
      expect(find.text('Définir ses collisions'), findsNothing);
      expect(
        find.byKey(
          const ValueKey('resource-environment-workshop-unavailable-state'),
        ),
        findsOneWidget,
      );
      expect(host.navigation.decor, isNull);
      await tester.tap(
        find.byKey(const ValueKey('resource-environment-return-to-catalog')),
      );
      await tester.pumpAndSettle();
      expect(host.navigation.page, ResourcePage.library);
      expect(host.navigation.environment, same(draft));
      expect(draft.build(), prepared);
      expect(host.workspace.project!.toJson(), beforeProject);
      expect(await tester.runAsync(() => _files(host.owned)), beforeFiles);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'imported source remains available when its retired decor route is requested',
    (tester) async {
      final host = await _open(tester, const Size(1536, 1024));
      final beforeMap = host.workspace.active!.current;
      final sourceBytes = await tester.runAsync(
        host.fixture.source.readAsBytes,
      );
      await tester.runAsync(
        () => host.navigation.import(
          ResourceImageImport(
            sourcePath: host.fixture.source.path,
            name: 'Source à conserver',
            tileWidth: host.workspace.project!.settings.tileWidth,
            tileHeight: host.workspace.project!.settings.tileHeight,
          ),
          intent: ResourceImportIntent.source,
        ),
      );
      await tester.pumpAndSettle();
      expect(host.navigation.error, isNull);
      expect(host.navigation.decor, isNull);
      final source = host.navigation.importedSource!;
      final beforeFiles = await tester.runAsync(() => _files(host.owned));
      final beforeProject = host.workspace.project!.toJson();
      expect(
        find.byKey(const ValueKey('resource-import-decor-unavailable')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('resource-import-create-decor')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('resource-import-create-terrain')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('resource-import-dismiss')));
      await tester.pumpAndSettle();
      expect(host.navigation.importedSource, isNull);
      expect(host.navigation.page, ResourcePage.library);
      host.navigation.showLibrary(source);
      await tester.pumpAndSettle();
      await _openDetail(tester, host, item: source);
      expect(
        find.byKey(const ValueKey('resource-decor-creation-unavailable')),
        findsOneWidget,
      );
      expect(find.text('Créer un décor'), findsNothing);

      host.navigation.edit(source);
      expect(host.navigation.error, isNull);
      expect(host.navigation.decor, isNotNull);
      final draft = host.navigation.decor!;
      expect(draft.tileset.id, source.id);
      expect(draft.original, isNull);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('resource-decor-workshop-unavailable-state')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('resource-decor-return-to-catalog')),
      );
      await tester.pumpAndSettle();
      expect(host.navigation.decor, same(draft));
      expect(host.navigation.decors.values, contains(same(draft)));
      expect(host.navigation.page, ResourcePage.library);
      expect(host.workspace.project!.toJson(), beforeProject);
      expect(host.workspace.active!.current, beforeMap);
      expect(await tester.runAsync(() => _files(host.owned)), beforeFiles);
      expect(
        await tester.runAsync(host.fixture.source.readAsBytes),
        sourceBytes,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

final class _Host {
  _Host(
    this.owned,
    this.fixture,
    this.workspace,
    this.visuals,
    this.navigation,
    this.item,
    this.used,
  );

  final Directory owned;
  final ResourceFixture fixture;
  final MapWorkspaceController workspace;
  final WorkspaceTestVisuals visuals;
  final ResourceNavigation navigation;
  final ResourceItem item;
  final List<ResourceItem> used;
}
