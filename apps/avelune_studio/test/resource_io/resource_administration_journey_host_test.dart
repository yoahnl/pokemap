import 'dart:io';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_usage_results.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu_resource_host.dart';
import '../support/widget_resource_management_port.dart';
import '../support/widget_resource_journey_map_port.dart';

void main() {
  testWidgets(
    'actual import decor placement closed map usages metadata organization and reopen',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final seed = (await tester.runAsync(() => M2UiFixture.create(tester)))!;
      addTearDown(seed.dispose);
      seed.controller.dispose();
      await tester.runAsync(seed.resources.dispose);
      var host = await _reopenHost(tester, seed);
      final original = host.fixture;
      await tester.tap(find.byTooltip('Carte').first);
      await pumpIo(tester);
      await host.tap('map-library-clairiere');
      expect(original.controller.active!.current.id, 'clairiere');
      await tester.tap(find.byTooltip('Ressources').first);
      await pumpIo(tester);
      await host.family(ResourceKind.images);
      await _tapText(tester, 'Importer une image');
      await _tapText(tester, 'Importer');
      final imported = original.controller.project!.tilesets.singleWhere(
        (item) => item.name == 'Planche M2',
      );
      final png = File('${original.directory.path}/${imported.relativePath}');
      final pixels = await tester.runAsync(png.readAsBytes);
      expect(host.navigation.decor!.tileset.id, imported.id);
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom du décor'),
        'Décor pilote',
      );
      await _tapText(tester, 'Enregistrer et utiliser');
      final element = original.controller.project!.elements.singleWhere(
        (item) => item.name == 'Décor pilote',
      );
      expect(element.tilesetId, imported.id);
      final document = original.controller.active!;
      final canvas = find.byKey(const ValueKey('map-canvas'));
      final scale = tester
          .widget<InteractiveViewer>(find.byKey(const ValueKey('map-viewport')))
          .transformationController!
          .value
          .getMaxScaleOnAxis();
      final settings = original.controller.project!.settings;
      await tester.tapAt(
        tester.getTopLeft(canvas) +
            Offset(
              4.4 * settings.tileWidth * settings.displayScale * scale,
              4.4 * settings.tileHeight * settings.displayScale * scale,
            ),
      );
      await pumpIo(tester, frames: 6);
      final placed = document.current.placedElements.singleWhere(
        (item) => item.elementId == element.id,
      );
      expect(document.dirty, isTrue);
      await host.tap('Enregistrer');
      expect(document.dirty, isFalse);
      final savedMap = document.current;
      await original.capture(tester, 'uwu3-journey-placed');

      await tester.pumpWidget(const SizedBox());
      await pumpIo(tester, frames: 4);
      original.controller.dispose();
      await tester.runAsync(original.resources.dispose);
      host = await _reopenHost(tester, original);
      expect(host.fixture.controller.active!.current.id, 'jardin');
      expect(
        host.fixture.controller.documents.containsKey('clairiere'),
        isFalse,
      );
      await host.family(ResourceKind.images);
      await host.action(
        'images:${imported.id}',
        'Voir les usages dans le projet',
      );
      await host.tap('resource-usage-analyze');
      final report = tester
          .widget<ResourceUsageResults>(find.byType(ResourceUsageResults))
          .report!;
      expect(report.complete, isTrue);
      expect(
        report.entries.any(
          (entry) => entry.mapId == 'clairiere' && entry.entityId == placed.id,
        ),
        isTrue,
      );
      expect(
        host.fixture.controller.documents.containsKey('clairiere'),
        isFalse,
      );
      await host.fixture.capture(tester, 'uwu3-journey-closed-map-usages');
      await _tapText(tester, 'Retour aux ressources');
      await host.action('images:${imported.id}', 'Modifier les informations');
      await host.enter('resource-information-name', 'Planche du jardin');
      await host.tap('resource-management-save');
      await host.tap('resource-manage-containers');
      await host.tap('resource-container-create');
      await host.enter('resource-container-name', 'Images végétales');
      await host.tap('resource-management-save');
      final folder = host.fixture.controller.project!.tilesetFolders.single;
      await host.tap('resource-container-edit-${folder.id}');
      await host.enter('resource-container-name', 'Végétation');
      await host.tap('resource-management-save');
      await _tapText(tester, 'Retour aux ressources');
      await host.action('images:${imported.id}', 'Déplacer vers…');
      await host.choose('resource-move-destination', 'Végétation');
      await host.tap('resource-management-save');
      await host.tap('resource-manage-containers');
      await host.tap('resource-container-delete-${folder.id}');
      expect(find.textContaining('1 ressource(s)'), findsWidgets);
      expect(find.text('Supprimer le dossier vide'), findsNothing);
      await _tapText(tester, 'Annuler');
      await host.tap('resource-container-create');
      await host.enter('resource-container-name', 'Dossier temporaire');
      await host.tap('resource-management-save');
      final empty = host.fixture.controller.project!.tilesetFolders.singleWhere(
        (item) => item.name == 'Dossier temporaire',
      );
      await host.tap('resource-container-delete-${empty.id}');
      await _tapText(tester, 'Supprimer le dossier vide');
      await _tapText(tester, 'Retour aux ressources');
      final reopened = await host.reopen();
      final after = reopened.tilesets.singleWhere(
        (item) => item.id == imported.id,
      );
      expect(after.name, 'Planche du jardin');
      expect(after.folderId, folder.id);
      expect(
        after.copyWith(name: imported.name, folderId: imported.folderId),
        imported,
      );
      expect(reopened.tilesetFolders.single.name, 'Végétation');
      expect(
        reopened.elements.singleWhere((item) => item.id == element.id),
        element,
      );
      expect(await tester.runAsync(png.readAsBytes), pixels);
      final independentMap = await tester.runAsync(() async {
        final sessions = LocalProjectSessionAdapter();
        final session = await sessions.open(host.fixture.directory.path);
        try {
          final reader = LocalMapWorkspaceAdapter();
          final manifest = await reader.loadProject(session);
          return await reader.loadMap(
            session,
            manifest.maps.singleWhere((item) => item.id == 'clairiere'),
          );
        } finally {
          await sessions.close(session);
        }
      });
      expect(independentMap!.map, savedMap);
      await tester.tap(find.byTooltip('Carte').first);
      await pumpIo(tester);
      await host.tap('map-library-clairiere');
      expect(host.fixture.controller.active!.current, savedMap);
      await host.fixture.capture(tester, 'uwu3-journey-reopened-render');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await pumpIo(tester, frames: 4);
    },
  );
}

Future<void> _tapText(WidgetTester tester, String label) async {
  final target = find.text(label).last;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await pumpIo(tester);
}

Future<UwUResourceHost> _reopenHost(
  WidgetTester tester,
  M2UiFixture original,
) async {
  final sessions = LocalProjectSessionAdapter();
  final fixture = (await tester.runAsync(() async {
    final session = await sessions.open(original.directory.path);
    final maps = LocalMapWorkspaceAdapter();
    final mapPort = WidgetResourceJourneyMapPort(maps, tester);
    final controller = WidgetMapController(session, mapPort, tester);
    await controller.initialize();
    mapPort.active = true;
    return M2UiFixture(
      original.directory,
      session,
      maps,
      controller,
      LocalResourceAdapter(session: session, mapAdapter: maps),
    );
  }))!;
  addTearDown(() async {
    fixture.controller.dispose();
    await fixture.resources.dispose();
    await sessions.close(fixture.session);
  });
  await tester.pumpWidget(
    fixture.app(
      tester,
      resourcePort: WidgetResourceManagementPort(fixture.resources, tester),
    ),
  );
  await pumpIo(tester);
  await tester.tap(find.byTooltip('Ressources').first);
  await pumpIo(tester);
  return UwUResourceHost(tester, fixture);
}
