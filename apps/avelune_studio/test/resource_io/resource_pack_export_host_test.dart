import 'dart:io';

import 'package:avelune_studio/features/resources/application/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_pack_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_connections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/domains/assets/resource_pack_import_fixture.dart';
import 'resource_pack_import_host_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('a real mixed native export stages UTF8 licences and reimports independently of the active 3D map', () async {
    final camera = SpatialCameraProfile();
    final map = MapData(
      id: 'spatial',
      name: 'Spatial room',
      version: ProjectVersion.v9,
      size: const GridSize(width: 8, height: 6),
      layers: const [],
      spatialScene: MapSpatialScene(width: 8, depth: 6, camera: camera),
    );
    final target = ProjectManifest(
      name: 'Spatial source',
      version: ProjectVersion.v9,
      tilesets: [],
      maps: [
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: 'spatial.json',
        ),
      ],
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: camera,
        tileWidth: 2,
        tileHeight: 2,
      ),
    );
    ProjectValidator.validate(target, maps: [map]);
    MapValidator.validate(map, projectDialogueContext: target);
    final source = await ResourcePackImportFixture.create(target: target);
    final folder = await Directory.systemTemp.createTemp('p11-export-host-');
    addTearDown(() => folder.delete(recursive: true));
    final destination = File('${folder.path}/published.aveluneassets');
    await destination.writeAsString('prior destination');
    List<String>? picked;
    final host = await ResourcePackTestHost.create(
      sourceFixture: source,
      initialMap: map,
      exportSink: FileExportTestSink(destination),
      pickLicenses: () async => picked,
    );
    addTearDown(host.dispose);
    await host.prepare();
    await host.transfer.apply();
    expect(host.transfer.error, isNull);
    await host.transfer.requestClose();
    final before = await host.resourceState();
    final mapBefore = await File('${host.root.path}/spatial.json')
        .readAsBytes();
    final first = File('${folder.path}/LICENSE');
    await first.writeAsString('First licence é😀');
    final second = File('${folder.path}/LICENCE');
    await second.writeAsString('Second original licence');
    final invalid = File('${folder.path}/invalid');
    await invalid.writeAsBytes([0xc3, 0x28]);
    final manifest = host.workspace.project!;
    final preset = manifest.smartTileCatalog.presets.single;
    final draft = TerrainDraftController(
      manifest: manifest,
      atlas: terrainAtlas(manifest.tilesets.first, 'memory-atlas'),
      id: 'memory-editor-id',
    ).draft.copyWith(targetPresetId: preset.id, sourcePresetId: preset.id);
    final editor = TerrainDraftController.resume(
      manifest: manifest,
      draft: draft,
    );
    editor.rename('Memory-only terrain');
    host.navigation.terrains['unrelated-owner-key'] = editor;
    host.navigation.packBorderDraftOwners['unreached-border'] = () =>
        const ResourcePackBorderDraft(
          request: BorderCreationRequest(
            name: 'Unrelated border',
            blueprintId: 'unreached-border',
          ),
          dirty: true,
          saving: false,
        );
    final c = host.transfer;
    await configureExport(c);
    await c.selectFiltered();
    expect(
      c.entries.map((row) => row['kind']).toSet(),
      containsAll([
        'element',
        'model3d',
        'smartTilePreset',
        'tileset',
        'borderBlueprint',
        'environmentPreset',
        'character',
      ]),
    );
    picked = [invalid.path];
    await c.addLicenseDocuments();
    expect(c.error, isNotNull);
    expect(c.licenseDocuments, isEmpty);
    picked = [first.path, second.path];
    await c.addLicenseDocuments();
    expect(c.error, isNull);
    expect(c.licenseDocuments, hasLength(2));
    await c.prepare();
    expect(c.error, isNull);
    expect(c.preparedSummary['resourceCount'], 8);
    expect(c.localNotices.map((notice) => notice.id), [preset.id]);
    expect(editor.dirty, isTrue);
    final prepared = c.preparedSummary;
    picked = null;
    await c.addLicenseDocuments();
    expect(c.preparedSummary, same(prepared));
    expect(c.licenseDocuments, hasLength(2));
    if (c.requiresOrganizationAcknowledgement) {
      c.setOrganizationAcknowledgement(true);
    }
    await c.export();
    expect(c.error, isNull);
    expect(c.phase, ResourcePackTransferPhase.complete);
    expect(c.outputPath, destination.path);
    expect(await destination.length(), greaterThan(100));
    expect((await host.resourceState()).fingerprints, before.fingerprints);
    expect(
      await File('${host.root.path}/spatial.json').readAsBytes(),
      mapBefore,
    );
    final imported = await ResourcePackTestHost.create();
    addTearDown(imported.dispose);
    final archive = imported.archiveFile.openWrite();
    await archive.addStream(destination.openRead());
    await archive.close();
    await imported.prepare();
    expect(imported.transfer.error, isNull);
    await imported.transfer.showAttributions('sources');
    expect(
      imported.transfer.attributions.any(
        (row) => row['label'] == 'Studio Publisher',
      ),
      isTrue,
    );
    await imported.transfer.apply();
    expect(imported.transfer.error, isNull);
    await imported.transfer.requestClose();
    final reopened = await imported.reopen();
    expect(
      reopened.elements,
      hasLength(host.workspace.project!.elements.length),
    );
    expect(reopened.models3d, hasLength(1));
    expect(reopened.smartTileCatalog.presets, hasLength(1));
    expect(reopened.tilesets, isNotEmpty);
    expect(reopened.borderCatalog.records, hasLength(1));
    expect(reopened.environmentPresets, hasLength(1));
    expect(reopened.characters, isNotEmpty);
    final installed = reopened.resourcePackInstallations.entries.single;
    expect(
      installed.origins.map((origin) => origin.author),
      contains('Studio Publisher'),
    );
    expect(installed.licenses.length, greaterThanOrEqualTo(3));
    expect(await c.requestClose(), isTrue);
  });
  test('sink cancellation and failure preserve the destination; postpublication warning remains published', () async {
    final host = await ResourcePackTestHost.create();
    addTearDown(host.dispose);
    await host.prepare();
    await host.transfer.apply();
    await host.transfer.requestClose();
    final folder = await Directory.systemTemp.createTemp('p11-sink-host-');
    addTearDown(() => folder.delete(recursive: true));
    final destination = File('${folder.path}/sentinel.aveluneassets');
    final sink = FileExportTestSink(destination);
    final c = ResourcePackTransferController(
      port: host.pack,
      picker: () async => null,
      exportSink: sink,
      accept: (_) async {
        fail('export cannot apply');
      },
    );
    addTearDown(c.dispose);
    for (final mode in ['cancel', 'error', 'warning']) {
      await destination.writeAsString('sentinel');
      sink.mode = mode;
      await configureExport(c);
      await c.selectFiltered();
      await c.prepare();
      expect(c.error, isNull);
      if (c.requiresOrganizationAcknowledgement) {
        c.setOrganizationAcknowledgement(true);
      }
      await c.export();
      if (mode == 'warning') {
        expect(c.phase, ResourcePackTransferPhase.complete);
        expect(c.outputPath, destination.path);
        expect(c.notice, contains('cleanup warning'));
        expect(await destination.length(), greaterThan(100));
      } else {
        expect(await destination.readAsString(), 'sentinel');
        expect(c.outputPath, isNull);
        expect(c.phase, isNot(ResourcePackTransferPhase.complete));
        if (mode == 'error') expect(c.error, contains('sink failure'));
      }
      expect(await File('${destination.path}.part').exists(), isFalse);
    }
    expect(await c.requestClose(), isTrue);
  });
}

Future<void> configureExport(ResourcePackTransferController c) async {
  await c.beginExport(projectName: 'Studio pack');
  for (final e in {
    'version': '1.0.0',
    'author': 'Studio Publisher',
    'universeId': 'original',
    'provenance': 'Original Studio edition',
  }.entries) {
    await c.setExportField(e.key, e.value);
  }
  expect(c.error, isNull);
}

class FileExportTestSink implements ResourcePackExportSink {
  @override
  Future<ResourcePackPublication> reconcilePublication(String token) async =>
      throw StateError('No pending publication');
  FileExportTestSink(this.destination);
  final File destination;
  String mode = 'publish';
  @override
  Future<ResourcePackPublication> publish({
    required String suggestedName,
    required int byteLength,
    required String rawSha256,
    required Future<List<int>> Function(int, int) readChunk,
    required bool Function() isCancelled,
    required void Function() enterFinalization,
  }) async {
    final temporary = File('${destination.path}.part');
    final stream = temporary.openWrite();
    var written = 0;
    var renamed = false;
    try {
      while (written < byteLength) {
        final count = (byteLength - written).clamp(1, 128 * 1024);
        final bytes = await readChunk(written, count);
        if (bytes.isEmpty || bytes.length > count) {
          throw StateError('invalid payload chunk');
        }
        stream.add(bytes);
        written += bytes.length;
        if (mode == 'error') throw StateError('sink failure');
      }
      await stream.flush();
      await stream.close();
      if (mode == 'cancel' || isCancelled()) {
        return const ResourcePackPublication.cancelled();
      }
      enterFinalization();
      await temporary.rename(destination.path);
      renamed = true;
      return ResourcePackPublication.published(
        destination.path,
        warning: mode == 'warning' ? 'cleanup warning' : null,
      );
    } finally {
      await stream.close();
      if (!renamed && await temporary.exists()) await temporary.delete();
    }
  }
}
