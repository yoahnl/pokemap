import 'dart:io';
import 'dart:typed_data';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_image_import.dart';
import 'package:avelune_studio/presentation/features/resources/resource_usage_results.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import '../support/m2_ui_fixture.dart';
import '../support/resource_administration_host.dart';

void main() {
  testWidgets(
    'successful replacement clears the previous incompatible candidate banner',
    (tester) async {
      final sources = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('avelune_replacement_retry_'),
      ))!;
      addTearDown(() => sources.delete(recursive: true));
      Uint8List png(int size, image.Color color) {
        final pixels = image.Image(width: size, height: size, numChannels: 4);
        image.fill(pixels, color: color);
        return Uint8List.fromList(image.encodePng(pixels));
      }

      final before = png(32, image.ColorRgba8(20, 160, 80, 255));
      final incompatible = png(16, image.ColorRgba8(20, 80, 160, 255));
      final replacement = png(32, image.ColorRgba8(255, 0, 255, 255));
      final candidates = [before, incompatible, replacement];
      var picked = 0;
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final seed = (await tester.runAsync(() => M2UiFixture.create(tester)))!;
      addTearDown(seed.dispose);
      await prepareResourceAdministrationAtlas(tester, seed);
      seed.controller.dispose();
      await tester.runAsync(seed.resources.dispose);
      final host = await reopenResourceAdministrationHost(
        tester,
        seed,
        imagePicker: () async {
          final index = picked++;
          final bytes = candidates[index];
          final file = File('${sources.path}/candidate-$index.png');
          await WidgetResourcePort.serial(
            tester,
            () => file.writeAsBytes(bytes),
          );
          final size = index == 1 ? 16 : 32;
          return PickedResourceImage(
            file.path,
            'Planche reprise',
            bytes,
            size,
            size,
          );
        },
      );
      await host.family(ResourceKind.images);
      await tapResourceAdministrationText(tester, 'Importer une image');
      await tapResourceAdministrationText(tester, 'Importer');
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom du décor'),
        'Décor reprise',
      );
      final beforeSave = host.fixture.controller.active!.current;
      await tapResourceAdministrationText(tester, 'Enregistrer le décor');
      expect(host.fixture.controller.active!.current, beforeSave);
      await tester.tap(find.byTooltip('Ressources').first);
      await pumpIo(tester);
      await host.family(ResourceKind.images);
      final imported = host.fixture.controller.project!.tilesets.singleWhere(
        (item) => item.name == 'Planche reprise',
      );
      final originalFile = File(
        '${host.fixture.directory.path}/${imported.relativePath}',
      );
      expect(
        await WidgetResourcePort.serial(tester, originalFile.readAsBytes),
        before,
      );
      await host.action('images:${imported.id}', 'Remplacer l’image source…');
      expect(host.navigation.error, contains('tileset.candidate_geometry'));
      expect(find.textContaining('tileset.candidate_geometry'), findsWidgets);
      expect(
        await WidgetResourcePort.serial(tester, originalFile.readAsBytes),
        before,
      );
      expect(host.navigation.pendingReceipt, isNull);
      await host.action('images:${imported.id}', 'Remplacer l’image source…');
      expect(
        find.byKey(const ValueKey('resource-replacement-confirm')),
        findsOneWidget,
        reason: 'Picked $picked; ${host.navigation.error}',
      );
      await host.tap('resource-replacement-confirm');
      await host.tap('resource-management-save');
      final updated = host.fixture.controller.project!.tilesets.singleWhere(
        (item) => item.id == imported.id,
      );
      final publishedFile = File(
        '${host.fixture.directory.path}/${updated.relativePath}',
      );
      expect(
        await WidgetResourcePort.serial(tester, publishedFile.readAsBytes),
        replacement,
      );
      expect(updated.id, imported.id);
      expect(updated.source, imported.source);
      expect(host.navigation.pendingReceipt, isNull);
      expect(host.navigation.error, isNull);
      expect(find.textContaining('tileset.candidate_geometry'), findsNothing);
      final reopened = await host.reopen();
      expect(
        reopened.tilesets.singleWhere((item) => item.id == imported.id),
        updated,
      );
      expect(
        await WidgetResourcePort.serial(tester, publishedFile.readAsBytes),
        replacement,
      );
      expect(picked, 3);
      await tester.pumpWidget(const SizedBox());
      await pumpIo(tester, frames: 4);
    },
  );

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
      var host = await reopenResourceAdministrationHost(tester, seed);
      final original = host.fixture;
      await tester.tap(find.byTooltip('Carte').first);
      await pumpIo(tester);
      await host.tap('map-library-clairiere');
      expect(original.controller.active!.current.id, 'clairiere');
      await tester.tap(find.byTooltip('Ressources').first);
      await pumpIo(tester);
      await host.family(ResourceKind.images);
      await tapResourceAdministrationText(tester, 'Importer une image');
      await tapResourceAdministrationText(tester, 'Importer');
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
      final beforeSave = original.controller.active!.current;
      await tapResourceAdministrationText(tester, 'Enregistrer le décor');
      final element = original.controller.project!.elements.singleWhere(
        (item) => item.name == 'Décor pilote',
      );
      expect(element.tilesetId, imported.id);
      expect(original.controller.active!.current, beforeSave);
      expect(host.navigation.library.selectedIdentity, 'decors:${element.id}');
      await tester.tap(
        find.byKey(ValueKey('resource-card-decors:${element.id}')),
      );
      await pumpIo(tester);
      await host.tap('resource-use');
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
      host = await reopenResourceAdministrationHost(tester, original);
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
      await tapResourceAdministrationText(tester, 'Retour aux ressources');
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
      await tapResourceAdministrationText(tester, 'Retour aux ressources');
      await host.action('images:${imported.id}', 'Déplacer vers…');
      await host.choose('resource-move-destination', 'Végétation');
      await host.tap('resource-management-save');
      await host.tap('resource-manage-containers');
      await host.tap('resource-container-delete-${folder.id}');
      expect(find.textContaining('1 ressource(s)'), findsWidgets);
      expect(find.text('Supprimer le dossier vide'), findsNothing);
      await tapResourceAdministrationText(tester, 'Annuler');
      await host.tap('resource-container-create');
      await host.enter('resource-container-name', 'Dossier temporaire');
      await host.tap('resource-management-save');
      final empty = host.fixture.controller.project!.tilesetFolders.singleWhere(
        (item) => item.name == 'Dossier temporaire',
      );
      await host.tap('resource-container-delete-${empty.id}');
      await tapResourceAdministrationText(tester, 'Supprimer le dossier vide');
      await tapResourceAdministrationText(tester, 'Retour aux ressources');
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
      final independentMap = await tester.runAsync(
        () => readResourceAdministrationMap(host.fixture, 'clairiere'),
      );
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
