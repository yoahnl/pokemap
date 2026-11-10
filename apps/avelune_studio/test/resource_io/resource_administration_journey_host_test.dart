import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_containers.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';

import '../../tool/example_project_assets.dart';

import 'package:avelune_studio/presentation/features/resources/resource_usage_results.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

import '../support/m2_ui_fixture.dart';
import '../support/resource_replacement_fixture.dart';
import '../support/run_resource_replacement.dart';
import '../support/resource_administration_host.dart';

Future<T> _runResourceCommand<T>(
  WidgetTester tester,
  Future<T> Function() action,
) async {
  var completed = false;
  T? value;
  Object? failure;
  StackTrace? trace;
  action().then(
    (result) {
      value = result;
      completed = true;
    },
    onError: (Object error, StackTrace stack) {
      failure = error;
      trace = stack;
      completed = true;
    },
  );
  await pumpIoUntil(tester, () => completed);
  expect(completed, isTrue);
  if (failure case final error?) {
    Error.throwWithStackTrace(error, trace!);
  }
  return value as T;
}

void main() {
  test(
    'successful replacement clears the previous incompatible candidate error',
    () async {
      final host = await ResourceReplacementFixture.create();
      final fixture = host.fixture;
      final navigation = host.navigation;
      final imported = host.item.tileset!;
      final item = host.item;
      final originalFile = File(
        '${fixture.root.path}/${imported.relativePath}',
      );
      final before = await originalFile.readAsBytes();
      final pixels = image.decodeImage(before)!;
      final maps = await fixture.mapFile.readAsBytes();
      Future<PickedResourceImage> candidate(
        int width,
        int height,
        String name,
      ) async {
        final pixels = image.Image(
          width: width,
          height: height,
          numChannels: 4,
        );
        image.fill(pixels, color: image.ColorRgba8(255, 0, 255, 255));
        final bytes = Uint8List.fromList(image.encodePng(pixels));
        final file = File('${fixture.root.path}/$name.png');
        await file.writeAsBytes(bytes);
        return PickedResourceImage(file.path, name, bytes, width, height);
      }

      final incompatible = await candidate(1, 1, 'incompatible');
      await runReplacementForTest(
        navigation: navigation,
        item: item,
        picker: () async => incompatible,
        isActive: () => true,
        shouldPresent: false,
        present: (_) async =>
            fail('An incompatible candidate cannot be confirmed'),
      );
      expect(navigation.error, contains('tileset.candidate_geometry'));
      expect(await originalFile.readAsBytes(), before);
      expect(navigation.pendingReceipt, isNull);
      expect(navigation.managementDialogActive, isFalse);
      final replacement = await candidate(
        pixels.width,
        pixels.height,
        'compatible',
      );
      await runReplacementForTest(
        navigation: navigation,
        item: item,
        picker: () async => replacement,
        isActive: () => true,
        present: (session) async {
          session.confirm(true);
          expect(await session.apply(), isNull);
        },
      );
      final updated = host.workspace.project!.tilesets.singleWhere(
        (item) => item.id == imported.id,
      );
      final publishedFile = File(
        '${fixture.root.path}/${updated.relativePath}',
      );
      expect(await publishedFile.readAsBytes(), replacement.bytes);
      expect(updated.id, imported.id);
      expect(updated.source, imported.source);
      expect(navigation.pendingReceipt, isNull);
      expect(navigation.error, isNull);
      expect(navigation.managementDialogActive, isFalse);
      expect(
        (await host.reopen()).tilesets.singleWhere(
          (item) => item.id == imported.id,
        ),
        updated,
      );
      expect(await fixture.mapFile.readAsBytes(), maps);
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
      final source = File('${original.directory.path}/journey-source.png');
      await WidgetResourcePort.serial(
        tester,
        () => source.writeAsBytes(exampleAtlasPng()),
      );
      final importing = host.navigation.import(
        ResourceImageImport(
          sourcePath: source.path,
          name: 'Planche M2',
          tileWidth: original.controller.project!.settings.tileWidth,
          tileHeight: original.controller.project!.settings.tileHeight,
        ),
        intent: ResourceImportIntent.source,
      );
      await pumpIo(tester);
      await importing;
      expect(host.navigation.error, isNull);
      final imported = original.controller.project!.tilesets.singleWhere(
        (item) => item.name == 'Planche M2',
      );
      final png = File('${original.directory.path}/${imported.relativePath}');
      final pixels = await tester.runAsync(png.readAsBytes);
      expect(host.navigation.decor, isNull);
      host.navigation.edit(
        resourceCatalog(original.controller.project!)
            .singleWhere((item) => item.tileset?.id == imported.id),
      );
      await pumpIo(tester);
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
      expect(host.navigation.library.selectedIdentity, 'element:${element.id}');
      await tester.tap(
        find.byKey(ValueKey('resource-card-element:${element.id}')),
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
        'tileset:${imported.id}',
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
      expect(
        await _runResourceCommand(
          tester,
          () async => publishResourceManagementChange(
            host.navigation,
            await host.navigation.captureResourceRevision(),
            'tileset.metadata.update',
            {
              'tilesetId': imported.id,
              'name': 'Planche du jardin',
              'folderId': imported.folderId,
            },
          ),
        ),
        isNull,
      );
      await pumpIo(tester, frames: 6);
      Future<String?> storeFolder(ResourceContainer folder) =>
          _runResourceCommand<String?>(
            tester,
            () async => publishResourceManagementChange(
              host.navigation,
              await host.navigation.captureResourceRevision(),
              containerAction(ResourceKind.images, 'upsert'),
              containerParameters(ResourceKind.images, folder),
            ),
          );
      const createdFolder = ResourceContainer(
        'journey-plants',
        'Images végétales',
        null,
        0,
      );
      expect(await storeFolder(createdFolder), isNull);
      const renamedFolder = ResourceContainer(
        'journey-plants',
        'Végétation',
        null,
        0,
      );
      expect(await storeFolder(renamedFolder), isNull);
      final folder = host.fixture.controller.project!.tilesetFolders.single;
      final (moveAction, moveParameters) = resourceMoveParameters(
        resourceCatalog(host.fixture.controller.project!)
            .singleWhere((item) => item.tileset?.id == imported.id),
        folder.id,
      );
      expect(
        await _runResourceCommand(
          tester,
          () async => publishResourceManagementChange(
            host.navigation,
            await host.navigation.captureResourceRevision(),
            moveAction,
            moveParameters,
          ),
        ),
        isNull,
      );
      expect(
        await _runResourceCommand(
          tester,
          () => deleteResourceContainer(
            host.navigation,
            ResourceKind.images,
            renamedFolder,
          ),
        ),
        isNotNull,
      );
      const empty = ResourceContainer(
        'journey-empty',
        'Dossier temporaire',
        null,
        0,
      );
      expect(await storeFolder(empty), isNull);
      expect(
        await _runResourceCommand(
          tester,
          () => deleteResourceContainer(
            host.navigation,
            ResourceKind.images,
            empty,
          ),
        ),
        isNull,
      );
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
