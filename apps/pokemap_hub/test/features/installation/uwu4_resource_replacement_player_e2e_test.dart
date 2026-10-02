import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_lifecycle_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../../avelune_studio/test/support/map_host_fixture.dart';
import '../../../../avelune_studio/test/support/m2_ui_fixture.dart' show pumpIo;
import 'uwu4_resource_replacement_player_support.dart';

void main() {
  testWidgets(
    'replaced Studio source exports and renders from installed Player alone',
    (tester) async {
      final temporary =
          (await tester.runAsync(
            () => Directory.systemTemp.createTemp('uwu4-replacement-player-'),
          ))!;
      addTearDown(() => temporary.delete(recursive: true));
      final package = File(p.join(temporary.path, 'replaced.avelunegame'));
      final oldPixels = image.encodePng(
        image.Image(width: 32, height: 32)
          ..clear(image.ColorRgba8(230, 44, 31, 255)),
      );
      final newPixels = image.encodePng(
        image.Image(width: 32, height: 32)
          ..clear(image.ColorRgba8(249, 9, 222, 255)),
      );
      final candidate = File(p.join(temporary.path, 'candidate.png'));
      await tester.runAsync(() => candidate.writeAsBytes(oldPixels));
      final host = await MapHostFixture.open(
        tester,
        prepareSource: prepareUwu4ExportFixture,
        gameExportPicker: (_) async => package,
        assetBundle: Uwu4StudioAssets(),
      );
      final port = LocalResourceAdapter(
        session: host.source.session,
        mapAdapter: host.source.maps,
      );
      addTearDown(() => tester.runAsync(port.dispose));
      Future<ResourceMutationReceipt> integrate(
        Future<ResourceMutationReceipt> Function() mutation,
      ) async {
        final receipt = (await tester.runAsync(mutation))!;
        host.maps.acceptResources(receipt.before, receipt.manifest);
        await pumpIo(tester, frames: 4);
        return receipt;
      }

      final imported = await integrate(
        () => port.importImage(
          ResourceImageImport(
            sourcePath: candidate.path,
            name: 'Source remplacée',
            tileWidth: 16,
            tileHeight: 16,
          ),
        ),
      );
      final sheet = imported.manifest.tilesets.singleWhere(
        (entry) => entry.id == imported.createdTilesetId,
      );
      final original = ProjectElementEntry(
        id: 'uwu4-original',
        name: 'Témoin',
        tilesetId: sheet.id,
        categoryId: imported.manifest.elementCategories.first.id,
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      );
      await integrate(() => port.saveElement(original));
      final duplicated =
          (await tester.runAsync(
            () => port.prepareOperation('element.duplicate', {
              'sourceElementId': original.id,
              'newElementId': 'uwu4-copy',
              'name': 'Copie indépendante',
              'categoryId': original.categoryId,
            }),
          ))!;
      await integrate(() => port.applyPrepared(duplicated));
      final copy = host.maps.project!.elements.singleWhere(
        (entry) => entry.id == 'uwu4-copy',
      );
      await integrate(
        () => port.saveElement(
          copy.copyWith(
            frames: const [
              TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
            ],
          ),
        ),
      );
      expect(
        host.maps.project!.elements.singleWhere(
          (entry) => entry.id == original.id,
        ),
        original,
      );
      final placedId = MapEditingCommands(
        host.document,
        host.maps.project!,
      ).place(original, const GridPos(x: 8, y: 7));
      expect(placedId, isNotNull);
      host.maps.notify();
      await tester.pump();
      await tester.runAsync(() => tester.tap(find.text('Enregistrer').first));
      await pumpIo(tester, frames: 20);
      expect(host.document.dirty, isFalse, reason: host.document.error);
      await tester.runAsync(() async {
        final independent = LocalProjectSessionAdapter();
        final session = await independent.open(host.source.directory.path);
        try {
          final reread = await LocalMapWorkspaceAdapter().loadProject(session);
          expect(
            reread.elements
                .singleWhere((entry) => entry.id == copy.id)
                .frames
                .first
                .source
                .x,
            1,
          );
          expect(
            reread.elements.singleWhere((entry) => entry.id == original.id),
            original,
          );
        } finally {
          await independent.close(session);
        }
      });
      final removeCopy =
          (await tester.runAsync(
            () =>
                port.prepareOperation('element.delete', {'elementId': copy.id}),
          ))!;
      await integrate(
        () => port.applyPrepared(removeCopy, confirmDestructive: true),
      );
      final unused = await integrate(
        () => port.importImage(
          ResourceImageImport(
            sourcePath: candidate.path,
            name: 'Planche libre',
            tileWidth: 16,
            tileHeight: 16,
          ),
        ),
      );
      final retire =
          (await tester.runAsync(
            () => port.prepareOperation('tileset.remove', {
              'tilesetId': unused.createdTilesetId!,
              'removeSource': false,
            }),
          ))!;
      await integrate(
        () => port.applyPrepared(retire, confirmDestructive: true),
      );
      final refused = await tester.runAsync(() async {
        try {
          return await port.prepareOperation('element.delete', {
            'elementId': original.id,
          });
        } on ResourceFailure catch (failure) {
          return failure;
        }
      });
      expect(refused, isA<ResourceFailure>());
      final preview =
          (await tester.runAsync(
            () => port.prepareReplacement(
              ResourceReplacementRequest(
                tilesetId: sheet.id,
                sourcePath: candidate.path,
                bytes: Uint8List.fromList(newPixels),
              ),
            ),
          ))!;
      expect(preview.beforeBytes, oldPixels);
      expect(preview.candidateBytes, newPixels);
      expect(
        await tester.runAsync(
          () =>
              File(
                p.join(host.source.directory.path, sheet.relativePath),
              ).readAsBytes(),
        ),
        oldPixels,
      );
      await integrate(
        () => port.applyPrepared(preview.preparation, confirmDestructive: true),
      );
      final authored = host.maps.project!;
      expect(
        authored.tilesets.any((entry) => entry.id == unused.createdTilesetId),
        isFalse,
      );
      expect(authored.elements.any((entry) => entry.id == copy.id), isFalse);
      expect(
        host.document.current.placedElements
            .singleWhere((entry) => entry.id == placedId)
            .elementId,
        original.id,
      );
      await host.openExport();
      await tester.enterText(
        find.widgetWithText(TextField, 'Auteur'),
        'Recette UwU IV',
      );
      await tester.tap(find.text('Test local').first);
      await tester.tap(find.byKey(const ValueKey('start-game-export')));
      for (var i = 0; i < 200 && host.gameExport.outputPath == null; i++) {
        await pumpIo(tester, frames: 2);
        if (host.gameExport.error != null) break;
      }
      expect(
        host.gameExport.outputPath,
        package.path,
        reason: host.gameExport.error,
      );
      expect(await tester.runAsync(package.exists), isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(port.dispose);
      host.maps.dispose();
      host.gameExport.dispose();
      expect(host.maps.isDisposed, isTrue);
      final source = host.source.directory;
      final hidden = Directory('${source.path}.offline');
      await tester.runAsync(() => source.rename(hidden.path));
      addTearDown(() async {
        if (await hidden.exists()) await hidden.delete(recursive: true);
      });
      expect(await tester.runAsync(source.exists), isFalse);
      await playReplacedPackage(
        tester,
        package,
        temporary,
        authored: authored,
        tilesetId: sheet.id,
        elementId: original.id,
        placedId: placedId!,
        expectedPixels: newPixels,
      );
      expect(await tester.runAsync(source.exists), isFalse);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

class Uwu4StudioAssets extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/home/')) {
      return ByteData.sublistView(
        await File(
          p.join(Directory.current.path, '../avelune_studio', key),
        ).readAsBytes(),
      );
    }
    return rootBundle.load(key);
  }
}
