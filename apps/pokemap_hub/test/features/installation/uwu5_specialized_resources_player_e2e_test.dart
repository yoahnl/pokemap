import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../../avelune_studio/test/support/m2_ui_owner_fixture.dart'
    show pumpIo;
import '../../../../avelune_studio/test/support/map_host_owner_fixture.dart';
import 'uwu5_specialized_resources_fixture.dart';
import 'uwu5_specialized_resources_player_support.dart';

void main() {
  testWidgets(
    'specialized resources survive actual export and installed Player isolation',
    (tester) async {
      final temporary =
          (await tester.runAsync(
            () => Directory.systemTemp.createTemp('uwu5-specialized-player-'),
          ))!;
      addTearDown(() => temporary.delete(recursive: true));
      final package = File(p.join(temporary.path, 'uwu5.avelunegame'));
      final host = await MapHostOwnerFixture.open(
        tester,
        prepareSource: (source) async {
          await prepareUwu5ExportFixture(source);
          await resolveUwu5Character(source);
        },
      );
      final port = LocalResourceAdapter(
        session: host.source.session,
        mapAdapter: host.source.maps,
      );
      addTearDown(() => tester.runAsync(port.dispose));
      final blueprint = MapBorderEditingCommands.publishedLines(
        host.maps.project!,
      ).singleWhere(
        (entry) => entry.latestPublished!.definition.name == 'Muret conservé',
      );
      final stroke = MapBorderDrawingDraft.start(
        mapId: host.document.current.id,
        mapSize: host.document.current.size,
        blueprintId: blueprint.id,
        alignment: borderTemplateStrokeAlignment(
          blueprint.latestPublished!.definition.template,
        ),
        origin: const GridPos(x: 10, y: 8),
      ).addAngle(const GridPos(x: 13, y: 8));
      expect(stroke.canFinish, isTrue);
      MapBorderEditingCommands(
        host.document,
        host.maps.project!,
      ).finish(stroke);
      host.maps.notify();
      await pumpIo(tester, frames: 4);
      expect(
        host.document.current.layers.whereType<BorderLayer>(),
        hasLength(1),
        reason: host.document.error,
      );
      final painted =
          host.document.current.layers.whereType<BorderLayer>().single;
      final materialized = painted.content.features.single.materialization;
      expect(materialized, isNotNull);
      expect(await host.save(), true, reason: host.document.error);
      expect(host.document.dirty, false, reason: host.document.error);
      final receipt =
          (await tester.runAsync(() async {
            final planning = Stopwatch()..start();
            final plan = await port.prepareOperation(
              'border.blueprint.set_deprecated',
              {'blueprintId': 'uwu5-border', 'isDeprecated': true},
            );
            planning.stop();
            final applying = Stopwatch()..start();
            final applied = await port.applyPrepared(
              plan,
              confirmDestructive: true,
            );
            applying.stop();
            print(
              'UWU5_BORDER_PLAN_US=${planning.elapsedMicroseconds} APPLY_US=${applying.elapsedMicroseconds}',
            );
            return applied;
          }))!;
      host.maps.acceptResources(receipt.before, receipt.manifest);
      await pumpIo(tester, frames: 4);
      final authored = host.maps.project!;
      expect(authored.borderCatalog.records.single.isDeprecated, true);
      expect(
        host.document.current.layers
            .whereType<BorderLayer>()
            .single
            .content
            .features
            .single
            .materialization,
        materialized,
      );
      expect(
        authored.smartTileCatalog.presets.single.name,
        'Sentier des étoiles',
      );
      expect(authored.settings.defaultPlayerCharacterId, 'uwu5-replacement');
      final authoredMap = host.document.current;
      final filesBeforeExport = await host.disk();
      expect(
        await host.exportGame(package, author: 'Recette UwU V'),
        true,
        reason: host.gameExport.error,
      );
      expect(
        host.gameExport.outputPath,
        package.path,
        reason: host.gameExport.error,
      );
      expect(await host.disk(), filesBeforeExport);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(port.dispose);
      host.maps.dispose();
      host.gameExport.dispose();
      expect(host.maps.isDisposed, true);
      final source = host.source.directory;
      final hidden = Directory('${source.path}.offline');
      await tester.runAsync(() => source.rename(hidden.path));
      addTearDown(() async {
        if (await hidden.exists()) await hidden.delete(recursive: true);
      });
      expect(await tester.runAsync(source.exists), false);
      print('UWU5_AUTHOR_SESSION_DISPOSED=${host.maps.isDisposed}');
      print(
        'UWU5_AUTHOR_ORIGINAL_INACCESSIBLE=${await tester.runAsync(source.exists) == false}',
      );
      await playUwu5InstalledPackage(
        tester,
        package,
        temporary,
        authored: authored,
        authoredMap: authoredMap,
      );
      expect(await tester.runAsync(source.exists), false);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
