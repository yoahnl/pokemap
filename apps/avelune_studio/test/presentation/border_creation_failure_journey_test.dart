import 'dart:io';

import 'package:avelune_studio/features/resources/application/border_creation_draft.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/border_creation_workflow.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core_domain.dart';

import '../support/resource_replacement_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'invalid border keeps its native pattern and explains the failed join',
    () async {
      final host = await ResourceReplacementFixture.create();
      final pixels = image.Image(width: 48, height: 24, numChannels: 4);
      for (var piece = 0; piece < 3; piece++) {
        image.fillRect(
          pixels,
          x1: piece * 16 + 6,
          y1: 6,
          x2: piece * 16 + 9,
          y2: 9,
          color: image.ColorRgba8(80, 150, 200, 255),
        );
      }
      final source = File('${host.fixture.root.path}/disconnected-border.png');
      await source.writeAsBytes(image.encodePng(pixels));
      final sourceBytes = await source.readAsBytes();
      final imported = await host.fixture.resources.importImage(
        ResourceImageImport(
          sourcePath: source.path,
          name: 'Pièces séparées',
          tileWidth: 16,
          tileHeight: 24,
        ),
      );
      await host.navigation.accept(imported);
      for (final (id, x) in [('cap', 0), ('straight', 1), ('corner', 2)]) {
        await host.navigation.accept(
          await host.fixture.resources.saveElement(
            host.fixture
                .element(imported.createdTilesetId!, id: id)
                .copyWith(
                  frames: [
                    TilesetVisualFrame(source: TilesetSourceRect(x: x, y: 0)),
                  ],
                ),
          ),
        );
      }
      final draft = BorderCreationDraft(
        project: host.workspace.project!,
        unavailableResourceIds: () => const {},
      )..name = 'Clôture sans raccords';
      for (final (role, id) in [
        ('lineCap', 'cap'),
        ('lineStraight', 'straight'),
        ('lineCorner', 'corner'),
      ]) {
        draft.assignRole(
          role,
          resourceCatalog(host.workspace.project!)
              .firstWhere((item) => item.element?.id == id),
        );
      }
      final workflow = BorderCreationWorkflow(
        navigation: host.navigation,
        draft: draft,
        isActive: () => true,
        confirmDiscard: () async => false,
        confirmRepublication: (_) async => true,
      );
      addTearDown(workflow.dispose);
      final mapBefore = await host.fixture.mapFile.readAsBytes();
      expect(draft.complete, isTrue);
      expect(await workflow.save(publish: true), isFalse);
      expect(draft.error, contains('Courbe en S'));
      expect(draft.error, contains('Réassociez'));
      expect(draft.error, isNot(contains('MapAuthoringException')));
      expect(draft.complete, isTrue);
      expect(
        draft.chosen.keys,
        containsAll(['lineCap', 'lineStraight', 'lineCorner']),
      );
      final record = (await host.reopen()).borderCatalog.records.single;
      expect(record.latestPublished, isNull);
      expect(draft.pendingId, record.id);
      expect(draft.expectedRecord, record);
      expect(await workflow.save(publish: true), isFalse);
      final records = (await host.reopen()).borderCatalog.records;
      expect(records, hasLength(1));
      expect(records.single.id, record.id);
      expect(records.single.latestPublished, isNull);
      expect(await host.fixture.mapFile.readAsBytes(), mapBefore);
      expect(await source.readAsBytes(), sourceBytes);
    },
  );
}
