import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_catalogue_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';

void main() {
  for (final settings in [
    (size: const Size(1536, 1024), scale: 1.0),
    (size: const Size(1280, 800), scale: 1.0),
    (size: const Size(1024, 640), scale: 1.5),
  ]) {
    testWidgets(
      'lifecycle actions stay accessible in real workspace ${settings.size} text ${settings.scale}',
      (tester) async {
        await tester.runAsync(loadDesktopCaptureFonts);
        final key = GlobalKey();
        final f = await MapCatalogueHostFixture.open(tester, captureKey: key);
        await f.host.mount(
          size: settings.size,
          textScale: settings.scale,
          captureKey: key,
        );
        if (find
            .byKey(const ValueKey('map-library-actions-first-map'))
            .evaluate()
            .isEmpty) {
          await f.tapKey('Afficher les cartes');
        }
        final before = await f.reopen();
        await f.mapAction('first-map', 'Dupliquer…');
        await f.field('duplicate-map-name', 'Copie sans publication');
        await tester.ensureVisible(find.text('Dupliquer la carte').last);
        await captureM3Widget(
          tester,
          key,
          'uwu2-duplicate-${settings.size.width.toInt()}',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await pumpIo(tester, frames: 6);
        expect((await f.reopen()).project, before.project);
        await f.mapAction('first-map', 'Redimensionner…');
        await f.field('resize-map-width', '2');
        await f.field('resize-map-height', '2');
        await tester.ensureVisible(find.text('Analyser les conséquences'));
        await tester.tap(find.text('Analyser les conséquences'));
        await pumpIo(tester, frames: 20);
        await tester.ensureVisible(find.text('Appliquer le redimensionnement'));
        await captureM3Widget(
          tester,
          key,
          'uwu2-resize-refused-${settings.size.width.toInt()}',
        );
        expect(
          find.text(
            'Analyse terminée : aucun contenu ni référence ne déborde.',
          ),
          findsNothing,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await pumpIo(tester, frames: 6);
        await f.mapAction('first-map', 'Supprimer la carte…');
        await tester.ensureVisible(find.text('Supprimer définitivement'));
        await captureM3Widget(
          tester,
          key,
          'uwu2-delete-blocked-${settings.size.width.toInt()}',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await pumpIo(tester, frames: 5);
        expect(find.text('Supprimer la carte'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await pumpIo(tester, frames: 6);
        final after = await f.reopen();
        expect(after.project, before.project);
        expect(after.maps, before.maps);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'dirty source cancellation keeps its owner and does not duplicate',
    (tester) async {
      final f = await MapCatalogueHostFixture.open(tester);
      final source = await f.createMap('Source non enregistrée');
      await f.paintCollision();
      final owner = f.host.maps.active!;
      final draft = owner.current;
      final before = await f.reopen();
      await f.mapAction(source.id, 'Dupliquer…');
      expect(find.text('Enregistrer et dupliquer'), findsOneWidget);
      await tester.tap(find.text('Annuler').last);
      await pumpIo(tester, frames: 6);
      expect(f.host.maps.active, same(owner));
      expect(owner.current, draft);
      expect(owner.dirty, isTrue);
      final after = await f.reopen();
      expect(after.project, before.project);
      expect(after.maps, before.maps);
    },
  );
}
