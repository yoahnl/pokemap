import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/map_catalogue_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';

void main() {
  testWidgets(
    'home refreshes an already mounted preview after a closed map title changes',
    (tester) async {
      final f = await MapCatalogueHostFixture.open(tester);
      expect(f.host.maps.documents.containsKey('maison'), isFalse);
      await tester.tap(find.text('Accueil'));
      await pumpIo(tester, frames: 30);
      await tester.tap(find.text('Carte').first);
      await pumpIo(tester, frames: 20);
      await f.renameMap('maison', 'Maison des saules');
      await tester.tap(find.text('Accueil'));
      await pumpIo(tester, frames: 30);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Aperçu de Maison des saules',
        ),
        findsOneWidget,
      );
      expect(f.host.maps.documents.containsKey('maison'), isFalse);
    },
  );
  testWidgets(
    'real workspace organizes nested folders and preserves referenced maps',
    (tester) async {
      await tester.runAsync(loadDesktopCaptureFonts);
      final key = GlobalKey();
      final f = await MapCatalogueHostFixture.open(tester, captureKey: key);
      final before = await f.reopen();
      final active = f.host.maps.active!;
      final root = await f.createFolder('Région');
      final town = await f.createFolder('Village', parent: 'Région');
      final houses = await f.createFolder(
        'Intérieurs',
        parent: 'Région / Village',
      );
      expect(houses.parentGroupId, town.id);
      await f.mapAction('maison', 'Déplacer…');
      await f.choose('Dossier de destination', 'Région / Village / Intérieurs');
      await tester.tap(find.text('Déplacer').last);
      await pumpIo(tester, frames: 20);
      expect(f.host.maps.active, same(active));
      expect(
        f.host.maps.project!.maps.singleWhere((e) => e.id == 'maison').groupId,
        houses.id,
      );
      await f.groupAction(houses.id, 'Renommer…');
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom du dossier'),
        'Maisons',
      );
      await tester.tap(find.text('Enregistrer').last);
      await pumpIo(tester, frames: 20);
      expect(
        f.host.maps.project!.groups.singleWhere((g) => g.id == houses.id).name,
        'Maisons',
      );
      await f.groupAction(root.id, 'Supprimer le dossier');
      expect(find.textContaining('Déplacez-les d’abord'), findsOneWidget);
      await tester.tap(find.text('Annuler').last);
      await pumpIo(tester, frames: 4);
      await f.groupAction(houses.id, 'Déplacer…');
      await f.choose('Dossier parent', 'Sans dossier');
      await tester.tap(find.text('Enregistrer').last);
      await pumpIo(tester, frames: 20);
      final empty = await f.createFolder('Dossier provisoire');
      await f.groupAction(empty.id, 'Supprimer le dossier');
      await tester.tap(find.text('Supprimer').last);
      await pumpIo(tester, frames: 20);
      expect(f.host.maps.project!.groups.any((g) => g.id == empty.id), isFalse);
      final after = await f.reopen();
      expect(
        after.project.groups
            .singleWhere((g) => g.id == houses.id)
            .parentGroupId,
        isNull,
      );
      expect(after.maps, before.maps);
      expect(after.project.newGame, before.project.newGame);
      expect(after.project.elements, before.project.elements);
      await captureM3Widget(tester, key, 'uwu-folders-organized');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dirty rename saves only its target and cancellation preserves work',
    (tester) async {
      final f = await MapCatalogueHostFixture.open(tester);
      final before = await f.reopen();
      final active = f.host.maps.active!;
      await f.paintCollision();
      final draft = active.current;
      await f.mapAction(active.base.mapId, 'Renommer…');
      expect(
        find.text('Enregistrer cette carte avant de la renommer ?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Annuler').last);
      await pumpIo(tester, frames: 3);
      expect(active.current, draft);
      expect(active.dirty, isTrue);
      expect((await f.reopen()).maps, before.maps);
      await f.mapAction(active.base.mapId, 'Renommer…');
      await tester.tap(find.text('Enregistrer cette carte puis renommer'));
      await pumpIo(tester, frames: 20);
      await f.field('rename-map-name', 'Clairbois — verger');
      await tester.tap(find.text('Enregistrer').last);
      await pumpIo(tester, frames: 20);
      expect(active.dirty, isFalse);
      final after = await f.reopen();
      expect(
        after.maps[active.base.mapId],
        draft.copyWith(name: 'Clairbois — verger'),
      );
      expect(after.maps['maison'], before.maps['maison']);
      expect(after.project.newGame, before.project.newGame);
    },
  );
}
