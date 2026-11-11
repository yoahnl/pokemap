import 'package:avelune_studio/features/map_workspace/application/map_selection_context.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_disk_owner_fixture.dart';

const twin = 'jardin-rocher';

void main() {
  void addTwinZone(MapDiskOwnerFixture f) => f.document.commit(
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

  String? header(MapDiskOwnerFixture f) => f.host.input.target?.label;

  Future<void> pick(MapDiskOwnerFixture f, String row) async {
    f.host.input.select(
      f.host.input.targets.singleWhere(
        (target) => '${target.label} · ${target.kindLabel}' == row,
      ),
    );
    await f.pump();
  }

  Future<void> choose(MapDiskOwnerFixture f, String label) async {
    final action = f.host.input.actions.singleWhere(
      (action) => action.label == label,
    );
    expect(action.unavailable, isNull);
    f.host.input.run(action.command);
    await f.pump();
  }

  Future<bool> shiftF10(MapDiskOwnerFixture f) async {
    final selected = keyboardContextTarget(f.document, f.maps.project!, f.view);
    if (selected != null) {
      f.host.input.open(selected.at, selected: selected.target);
    }
    await f.pump();
    return selected != null;
  }

  testWidgets('twin ids in two families stay distinct rows of the real menu', (
    tester,
  ) async {
    final f = await MapDiskOwnerFixture.open(tester);
    addTwinZone(f);
    await f.pump();

    await f.rightClick(11, 5);
    final keys = f.host.input.targets.map((target) => target.key).toList();
    expect(keys.toSet(), hasLength(keys.length), reason: 'no duplicate keys');
    expect(
      f.host.input.targets.where((target) => target.id == twin),
      hasLength(2),
    );
    await pick(f, 'Herbes · Zone de jeu');

    expect(header(f), 'Herbes');
    expect(
      f.host.input.targets.where(
        (target) => target.sameAs(f.host.input.target),
      ),
      hasLength(1),
      reason: 'a single row is selected',
    );

    await choose(f, 'Supprimer la zone');
    expect(f.document.current.gameplayZones, isEmpty);
    expect(
      f.document.current.placedElements.where((item) => item.id == twin),
      hasLength(1),
      reason: 'the homonym decor is untouched',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('Shift+F10 reopens the menu on the target chosen in the stack', (
    tester,
  ) async {
    final f = await MapDiskOwnerFixture.open(tester);
    await f.rightClick(12, 6);
    expect(header(f), 'Caisse corail');
    await pick(f, 'Rocher bleu · Décor');
    await f.key(LogicalKeyboardKey.escape);
    expect(f.host.input.contextOpen, isFalse);

    expect(await shiftF10(f), isTrue);
    expect(f.host.input.contextOpen, isTrue);
    expect(header(f), 'Rocher bleu');
    await choose(f, 'Déplacer');
    await f.host.drag(12, 6, 12, 9);
    expect(
      f.document.current.placedElements
          .firstWhere((item) => item.id == twin)
          .pos,
      const GridPos(x: 11, y: 8),
    );

    expect(await shiftF10(f), isTrue);
    expect(header(f), 'Rocher bleu');
    expect(f.host.input.cell, const GridPos(x: 11, y: 8));
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets(
    'a deleted target is never replaced by its homonym on Shift+F10',
    (tester) async {
      final f = await MapDiskOwnerFixture.open(tester);
      addTwinZone(f);
      await f.pump();
      await f.rightClick(11, 5);
      await pick(f, 'Rocher bleu · Décor');
      await choose(f, 'Supprimer le décor');
      final steps = f.document.undoCount;

      expect(await shiftF10(f), isFalse);
      expect(
        f.host.input.contextOpen,
        isFalse,
        reason: 'no silent retargeting',
      );
      expect(f.document.error, mapContextNoVisibleSelection);
      expect(
        f.document.error,
        contains('Aucun élément visible n’est sélectionné'),
      );
      expect(f.document.undoCount, steps);
      expect(f.document.current.gameplayZones.single.id, twin);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets('a map change really closes the menu, it does not only hide it', (
    tester,
  ) async {
    final f = await MapDiskOwnerFixture.open(tester);
    final garden = f.document.current.id;
    final other = f.maps.project!.maps
        .firstWhere((entry) => entry.id != garden)
        .id;
    await f.rightClick(5, 4);
    expect(f.host.input.contextOpen, isTrue);

    await f.activate(other);
    f.host.input.reconcile();
    await f.activate(garden);
    f.host.input.reconcile();
    await f.pump();

    expect(f.document.current.id, garden);
    expect(f.host.input.contextOpen, isFalse);
    expect(f.host.input.targets, isEmpty);
    expect(f.host.input.actions, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
