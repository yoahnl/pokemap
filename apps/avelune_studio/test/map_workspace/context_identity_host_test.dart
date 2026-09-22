import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/map_host_fixture.dart';

const twin = 'jardin-rocher';

void main() {
  String header(WidgetTester tester) => tester
      .widget<Text>(find.byKey(const ValueKey('map-context-target')))
      .data!;

  void addTwinZone(MapHostFixture f) => f.document.commit(
    f.document.current.copyWith(
      gameplayZones: [
        const MapGameplayZone(
          id: twin,
          name: 'Herbes',
          kind: GameplayZoneKind.encounter,
          area: MapRect(
            pos: GridPos(x: 10, y: 4),
            size: GridSize(width: 3, height: 3),
          ),
          encounter: EncounterZonePayload(),
        ),
      ],
    ),
  );

  Future<void> shiftF10(MapHostFixture f) =>
      f.key(LogicalKeyboardKey.f10, shift: true);

  testWidgets(
    'twin ids in two families stay distinct rows of the real menu',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      addTwinZone(f);
      await pumpIo(tester, frames: 4);

      await f.rightClick(11, 5);
      expect(tester.takeException(), isNull, reason: 'no duplicate keys');
      await tester.tap(f.inMenu('Herbes · Zone de jeu'));
      await pumpIo(tester, frames: 4);

      expect(header(tester), 'Herbes');
      final picks = tester
          .widgetList<TextButton>(
            find.descendant(of: f.menu, matching: find.byType(TextButton)),
          )
          .where(
            (button) => button.style?.backgroundColor?.resolve({}) != null,
          );
      expect(picks, hasLength(1), reason: 'a single row is selected');

      await f.choose('Supprimer la zone');
      expect(f.document.current.gameplayZones, isEmpty);
      expect(
        f.document.current.placedElements.where((item) => item.id == twin),
        hasLength(1),
        reason: 'the homonym decor is untouched',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'Shift+F10 reopens the menu on the target chosen in the stack',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      await f.rightClick(12, 6);
      expect(header(tester), 'Caisse corail');
      await tester.tap(f.inMenu('Rocher bleu · Décor'));
      await pumpIo(tester, frames: 4);
      await f.key(LogicalKeyboardKey.escape);
      expect(f.menu, findsNothing);

      await shiftF10(f);
      expect(header(tester), 'Rocher bleu');
      await f.choose('Déplacer');
      await f.drag(12, 6, 12, 9);
      expect(
        f.document.current.placedElements
            .firstWhere((item) => item.id == twin)
            .pos,
        const GridPos(x: 11, y: 8),
      );

      await f.zoomAt(11, 8, -80);
      await shiftF10(f);
      expect(header(tester), 'Rocher bleu');
      final anchor = f.cellAt(12, 9);
      final menu = tester.getTopLeft(f.menu);
      expect(
        (menu - anchor).distance,
        lessThan(80),
        reason: 'the menu opens next to the target, in the current viewport',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'a deleted target is never replaced by its homonym on Shift+F10',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      addTwinZone(f);
      await pumpIo(tester, frames: 4);
      await f.rightClick(11, 5);
      await tester.tap(f.inMenu('Rocher bleu · Décor'));
      await pumpIo(tester, frames: 4);
      await f.choose('Supprimer le décor');
      final steps = f.document.undoCount;

      await shiftF10(f);
      expect(f.menu, findsNothing, reason: 'no silent retargeting');
      expect(find.textContaining('Sélectionnez un élément'), findsOneWidget);
      expect(f.document.undoCount, steps);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'a map change really closes the menu, it does not only hide it',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      final garden = f.maps.project!.maps.firstWhere(
        (entry) => entry.id == f.document.current.id,
      );
      final other = f.maps.project!.maps.firstWhere(
        (entry) => entry.id != garden.id,
      );
      await f.rightClick(5, 4);
      expect(f.menu, findsOneWidget);

      unawaited(f.maps.activate(other));
      await pumpIo(tester, frames: 12);
      unawaited(f.maps.activate(garden));
      await pumpIo(tester, frames: 12);

      expect(f.document.current.id, garden.id);
      expect(f.menu, findsNothing);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
