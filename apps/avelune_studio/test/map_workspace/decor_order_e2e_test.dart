import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/map_host_fixture.dart';

void main() {
  testWidgets('mixed render contexts can be reordered from the inspector', (
    tester,
  ) async {
    final fixture = await MapHostFixture.open(tester);
    for (final id in ['arbre', 'rocher']) {
      await tester.tap(find.byKey(ValueKey('decor-$id')));
      await fixture.tapCell(8, 7);
    }
    final pair = fixture.document.current.placedElements;
    final tree = pair[pair.length - 2];
    final rock = pair.last;
    await tester.tap(find.byKey(const ValueKey('Passer derrière')));
    await tester.pump();
    final reordered = fixture.document.current.placedElements;
    expect(
      reordered.firstWhere((item) => item.id == rock.id).visualOrder,
      lessThan(reordered.firstWhere((item) => item.id == tree.id).visualOrder),
    );
    await tester.tap(find.byKey(const ValueKey('Annuler')));
    await tester.pump();
    final undone = fixture.document.current.placedElements;
    expect(
      undone.firstWhere((item) => item.id == rock.id).visualOrder,
      greaterThan(undone.firstWhere((item) => item.id == tree.id).visualOrder),
    );
    await tester.tap(find.byKey(const ValueKey('Rétablir')));
    await tester.pump();
    final redone = fixture.document.current.placedElements;
    expect(
      redone.firstWhere((item) => item.id == rock.id).visualOrder,
      lessThan(redone.firstWhere((item) => item.id == tree.id).visualOrder),
    );
    await tester.tap(find.byKey(const ValueKey('Passer devant')));
    await tester.pump();
    final broughtForward = fixture.document.current.placedElements;
    expect(
      broughtForward.firstWhere((item) => item.id == rock.id).visualOrder,
      greaterThan(
        broughtForward.firstWhere((item) => item.id == tree.id).visualOrder,
      ),
    );
  });

  testWidgets('a mixed decor stack moves one neighboring rank and saves it', (
    tester,
  ) async {
    final fixture = await MapHostFixture.open(tester);
    for (final id in ['arbre', 'rocher', 'arbre']) {
      await tester.tap(find.byKey(ValueKey('decor-$id')));
      await fixture.tapCell(8, 7);
    }
    final placed = fixture.document.current.placedElements;
    final firstTree = placed[placed.length - 3];
    final rock = placed[placed.length - 2];
    final lastTree = placed.last;
    expect(firstTree.layerId, 'decor');
    expect(rock.layerId, 'decor');
    expect(lastTree.layerId, 'decor');
    expect(find.textContaining(' / 3 · 1 = devant'), findsOneWidget);
    final before = fixture.document.undoCount;

    await tester.tap(find.byKey(const ValueKey('Passer derrière')));
    await tester.pump();

    final updated = fixture.document.current.placedElements;
    expect(
      updated.firstWhere((item) => item.id == lastTree.id).visualOrder,
      lessThan(updated.firstWhere((item) => item.id == rock.id).visualOrder),
    );
    expect(
      updated.firstWhere((item) => item.id == lastTree.id).visualOrder,
      inExclusiveRange(
        updated.firstWhere((item) => item.id == firstTree.id).visualOrder,
        updated.firstWhere((item) => item.id == rock.id).visualOrder,
      ),
    );
    expect(fixture.document.undoCount, before + 1);

    await tester.tap(find.byKey(const ValueKey('Enregistrer')));
    for (var index = 0; index < 50 && fixture.document.dirty; index++) {
      await pumpIo(tester, frames: 3);
    }
    expect(fixture.document.dirty, isFalse, reason: fixture.document.error);
    final reopened = (await tester.runAsync(() async {
      final adapter = LocalMapWorkspaceAdapter();
      final project = await adapter.loadProject(fixture.source.session);
      return adapter.loadMap(
        fixture.source.session,
        project.maps.firstWhere(
          (entry) => entry.id == fixture.document.current.id,
        ),
      );
    }))!;
    final saved = reopened.map.placedElements;
    expect(
      saved.firstWhere((item) => item.id == lastTree.id).visualOrder,
      lessThan(saved.firstWhere((item) => item.id == rock.id).visualOrder),
    );
    expect(
      saved.firstWhere((item) => item.id == lastTree.id).visualOrder,
      inExclusiveRange(
        saved.firstWhere((item) => item.id == firstTree.id).visualOrder,
        saved.firstWhere((item) => item.id == rock.id).visualOrder,
      ),
    );
  });
}
