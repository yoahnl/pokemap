import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/resources/application/resource_removal_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_definition_lifecycle.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/resource_owner_seed.dart';
import '../support/resource_owner_host.dart';

Future<ResourceOwnerHost> _open() => ResourceOwnerHost.create(
  configure: (fixture) => seedFreeDecor(fixture),
);

Future<void> _remove(
  ResourceOwnerHost host,
  Future<void> Function(ResourceRemovalController) present, {
  bool decor = false,
}) => runResourceDefinitionRemoval(
  navigation: host.navigation,
  item: decor ? decorItem(host.workspace.project!) : host.item,
  isActive: () => true,
  confirmOwnerSave: () async => true,
  present: present,
);

Future<void> _removeDecor(ResourceOwnerHost host) =>
    _remove(host, (controller) async {
      await controller.prepare();
      controller.confirm(true);
      expect(await controller.apply(), isNull);
    }, decor: true);

class _Disk {
  _Disk(this.host, this.sourcePath);
  final ResourceOwnerHost host;
  final String sourcePath;
  File get source => File('${host.fixture.root.path}/$sourcePath');
  File get catalog =>
      File('${host.fixture.root.path}/assets/.pokemap-assets.json');
  File get project => host.fixture.manifestFile;
  bool get addressed => sourcePath.startsWith('assets/.pokemap-store/');
}

Future<_Disk> _disk(ResourceOwnerHost host) async =>
    _Disk(host, (await host.reopen()).tilesets.single.relativePath);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cancelling the prepared source withdrawal writes nothing', () async {
    final host = await _open();
    await _removeDecor(host);
    final before = await host.reopen();
    final disk = await _disk(host);
    final projectBytes = await disk.project.readAsBytes();
    final catalogBytes = await disk.catalog.readAsBytes();
    final sourceBytes = await disk.source.readAsBytes();
    await _remove(host, (controller) async {
      await controller.prepare();
      await controller.selectRemoveSource(true);
      expect(controller.removeSource, isTrue);
      expect(controller.preparation!.parameters['removeSource'], isTrue);
      expect(controller.canApply, isFalse);
    });
    expect(host.navigation.managementDialogActive, isFalse);
    expect((await host.reopen()).tilesets, before.tilesets);
    expect(await disk.project.readAsBytes(), projectBytes);
    expect(await disk.catalog.readAsBytes(), catalogBytes);
    expect(await disk.source.readAsBytes(), sourceBytes);
  });

  test('source removal can return to definition-only after analysis', () async {
    final host = await _open();
    await _removeDecor(host);
    final disk = await _disk(host);
    final sourceBytes = await disk.source.readAsBytes();
    final catalogBytes = await disk.catalog.readAsBytes();
    await _remove(host, (controller) async {
      await controller.prepare();
      expect(controller.removeSource, isFalse);
      expect(controller.sourceRemovalSupported, isTrue);
      await controller.selectRemoveSource(true);
      expect(controller.removeSource, isTrue);
      expect(controller.sourceRemovalSupported, isTrue);
      await controller.selectRemoveSource(false);
      expect(controller.removeSource, isFalse);
      expect(controller.confirmed, isFalse);
      expect(controller.preparation!.parameters['removeSource'], isFalse);
      controller.confirm(true);
      expect(await controller.apply(), isNull);
    });
    expect((await host.reopen()).tilesets, isEmpty);
    expect(await disk.source.readAsBytes(), sourceBytes);
    expect(await disk.catalog.readAsBytes(), catalogBytes);
  });

  test('confirmed source removal applies the announced logical effects', () async {
    final host = await _open();
    await _removeDecor(host);
    final disk = await _disk(host);
    final before =
        jsonDecode(await disk.catalog.readAsString()) as Map<String, dynamic>;
    expect(before['records'], hasLength(1));
    await _remove(host, (controller) async {
      await controller.prepare();
      await controller.selectRemoveSource(true);
      expect(controller.preparation!.impact['sourceRemoved'], isTrue);
      expect(
        controller.preparation!.impact['logicalFileRemoved'],
        !disk.addressed,
      );
      controller.confirm(true);
      expect(await controller.apply(), isNull);
    });
    expect((await host.reopen()).tilesets, isEmpty);
    final after =
        jsonDecode(await disk.catalog.readAsString()) as Map<String, dynamic>;
    expect(after['records'], isEmpty);
    expect(await disk.source.exists(), disk.addressed);
  });

  for (final apply in [false, true]) {
    test('source OFF ON OFF ON remains explicit, apply=$apply', () async {
      final host = await _open();
      await _removeDecor(host);
      final sheet = (await host.reopen()).tilesets.single;
      final disk = await _disk(host);
      final pixels = await disk.source.readAsBytes();
      final catalogBefore = await disk.catalog.readAsBytes();
      await _remove(host, (controller) async {
        await controller.prepare();
        expect(controller.removeSource, isFalse);
        for (final enabled in [true, false, true]) {
          controller.confirm(true);
          expect(controller.canApply, isTrue);
          await controller.selectRemoveSource(enabled);
          expect(controller.removeSource, enabled);
          expect(controller.sourceRemovalSupported, isTrue);
          expect(controller.confirmed, isFalse);
          expect(controller.canApply, isFalse);
          expect(await disk.catalog.readAsBytes(), catalogBefore);
          expect(await disk.source.readAsBytes(), pixels);
        }
        expect(controller.preparation!.parameters['removeSource'], isTrue);
        if (apply) {
          controller.confirm(true);
          expect(await controller.apply(), isNull);
        }
      });
      if (apply) {
        expect((await host.reopen()).tilesets, isEmpty);
        final after =
            jsonDecode(await disk.catalog.readAsString())
                as Map<String, dynamic>;
        expect(after['records'], isEmpty);
        expect(await disk.source.exists(), disk.addressed);
        if (disk.addressed) expect(await disk.source.readAsBytes(), pixels);
      } else {
        expect((await host.reopen()).tilesets.single, sheet);
        expect(await disk.catalog.readAsBytes(), catalogBefore);
        expect(await disk.source.readAsBytes(), pixels);
      }
    });
  }

  test('free definition then planche removal preserve source and map', () async {
    final host = await _open();
    final before = await host.reopen();
    final map = host.workspace.active!.current;
    final mapBytes = await host.fixture.mapFile.readAsBytes();
    await _removeDecor(host);
    expect((await host.reopen()).elements, isEmpty);
    expect((await host.reopen()).tilesets, before.tilesets);
    expect(host.workspace.active!.current, map);
    await _remove(host, (controller) async {
      await controller.prepare();
      expect(controller.removeSource, isFalse);
      controller.confirm(true);
      expect(await controller.apply(), isNull);
    });
    final reopened = await host.reopen();
    expect(reopened.tilesets, isEmpty);
    expect(reopened.elements, isEmpty);
    expect(host.workspace.active!.current, map);
    expect(await host.fixture.mapFile.readAsBytes(), mapBytes);
  });
}
