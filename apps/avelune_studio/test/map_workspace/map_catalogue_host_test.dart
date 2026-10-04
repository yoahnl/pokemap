import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_catalogue_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/clairbois_player_recipe.dart';
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';

void main() {
  testWidgets(
    'Clairbois creates edits saves and renames without changing existing identities',
    (tester) async {
      await tester.runAsync(loadDesktopCaptureFonts);
      final key = GlobalKey();
      final f = await MapCatalogueHostFixture.open(tester, captureKey: key);
      final initial = await f.reopen();
      final original = f.host.maps.active!;
      final originalViewport = tester
          .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
          .view;
      final originalTransform = originalViewport.transform.value.clone();
      final created = await f.createMap('Île des saules');
      expect(created.id, isNot('Île des saules'));
      final draft = f.host.maps.active!;
      expect(f.host.maps.project!.settings.tileWidth, 32);
      expect(f.host.maps.project!.settings.tileHeight, 32);
      expect(
        draft.current.size,
        GridSize(
          width: initial.project.settings.defaultMapWidth,
          height: initial.project.settings.defaultMapHeight,
        ),
      );
      await f.paintCollision();
      expect(draft.dirty, isTrue);
      expect(draft.undoCount, 1);
      await f.tapKey('Enregistrer');
      expect(
        draft.dirty,
        isFalse,
        reason: '${draft.error}; saving=${draft.saving}',
      );
      final saved = await f.reopen();
      expect(saved.maps[created.id], draft.current);
      for (final entry in initial.project.maps) {
        expect(saved.maps[entry.id], initial.maps[entry.id]);
        expect(saved.project.maps.firstWhere((e) => e.id == entry.id), entry);
      }
      expect(saved.project.newGame, initial.project.newGame);
      expect(saved.project.settings, initial.project.settings);
      await f.renameMap(created.id, 'Île aux lucioles');
      expect(f.host.maps.active, same(draft));
      expect(draft.current.name, 'Île aux lucioles');
      final renamed = await f.reopen();
      expect(
        renamed.project.maps.firstWhere((e) => e.id == created.id).relativePath,
        created.relativePath,
      );
      expect(renamed.maps[created.id]!.name, 'Île aux lucioles');
      f.host.maps.restore(redo: false);
      expect(draft.current.name, 'Île aux lucioles');
      expect(draft.undoCount, 0);
      f.host.maps.restore(redo: true);
      expect(draft.current.name, 'Île aux lucioles');
      expect(draft.current, renamed.maps[created.id]);
      await f.renameMap('first-map', 'Clairbois — village');
      final finalRead = await f.reopen();
      expect(finalRead.project.newGame, initial.project.newGame);
      expect(
        finalRead.maps['first-map']!.warps,
        initial.maps['first-map']!.warps,
      );
      expect(finalRead.maps['maison'], initial.maps['maison']);
      expect(original.current.name, 'Clairbois — village');
      expect(originalViewport.transform.value, originalTransform);
      await f.createFolder('Clairbois');
      await f.mapAction('first-map', 'Déplacer…');
      await f.choose('Dossier de destination', 'Clairbois');
      await tester.tap(find.text('Déplacer').last);
      await pumpIo(tester, frames: 20);
      expect(
        (await f.reopen()).maps['first-map']!.warps,
        initial.maps['first-map']!.warps,
      );
      await captureM3Widget(tester, key, 'uwu-created-and-renamed');
      await f.preserveNativeFixture();
      await playCreatedClairbois(tester, f.host.session.state.project!);
    },
  );

  testWidgets(
    'empty project creates its first editable map using the project grid',
    (tester) async {
      final f = await MapCatalogueHostFixture.open(tester, empty: true);
      expect(f.host.maps.active, isNull);
      expect(f.host.maps.project!.tilesets, isEmpty);
      final entry = await f.createMap('Première carte');
      final document = f.host.maps.active!;
      expect(f.host.maps.project!.settings.tileWidth, 16);
      expect(f.host.maps.project!.settings.tileHeight, 16);
      await f.paintCollision();
      expect(document.dirty, isTrue);
      await f.tapKey('Enregistrer');
      expect(
        document.dirty,
        isFalse,
        reason: '${document.error}; saving=${document.saving}',
      );
      expect((await f.reopen()).maps[entry.id], document.current);
    },
  );

  testWidgets(
    'invalid dimensions and cancellation leave the project untouched',
    (tester) async {
      final f = await MapCatalogueHostFixture.open(tester);
      final initial = await f.reopen();
      await f.tapKey('new-map');
      await f.field('new-map-name', 'Brouillon conservé');
      await f.field('new-map-width', '1.5');
      await tester.tap(find.text('Créer la carte'));
      await pumpIo(tester, frames: 3);
      expect(find.text('Brouillon conservé'), findsOneWidget);
      expect(find.text('Entier positif requis'), findsOneWidget);
      expect(f.host.maps.project, initial.project);
      await tester.tap(find.text('Annuler').last);
      await pumpIo(tester, frames: 4);
      final after = await f.reopen();
      expect(after.project, initial.project);
      expect(after.maps, initial.maps);
    },
  );
}
