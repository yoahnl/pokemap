import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_disk_owner_fixture.dart';

void main() {
  Future<void> armDecor(MapDiskOwnerFixture fixture, String id) async {
    final maps = fixture.maps;
    final item = resourceCatalog(maps.project!)
        .singleWhere((item) => item.element?.id == id);
    final source = fixture.document.current;
    final history = fixture.document.undoCount;
    final armed = await fixture.tester.runAsync(
      () => useMapResource(
        workspace: maps,
        item: item,
        view: () => fixture.view,
        isActive: () => !maps.isDisposed,
        chooseMap: (_) async => null,
        chooseTile: (_) async => null,
      ),
    );
    expect(armed, isTrue);
    expect(fixture.view.brush?.id, id);
    expect(fixture.document.current, same(source));
    expect(fixture.document.undoCount, history);
    maps.notify();
    await fixture.pump();
  }

  MapEditingCommands commands(MapDiskOwnerFixture fixture) =>
      MapEditingCommands(fixture.document, fixture.maps.project!);

  int order(List<MapPlacedElement> placed, String id) =>
      placed.firstWhere((item) => item.id == id).visualOrder;

  testWidgets('mixed render contexts can be reordered from the inspector', (
    tester,
  ) async {
    final fixture = await MapDiskOwnerFixture.open(tester);
    for (final id in ['arbre', 'rocher']) {
      await armDecor(fixture, id);
      await fixture.tapCell(8, 7);
    }
    final pair = fixture.document.current.placedElements;
    final tree = pair[pair.length - 2];
    final rock = pair.last;
    expect(fixture.document.selectedId, rock.id);
    expect(commands(fixture).decorOrderContext()!.backwardProblem, isNull);
    commands(fixture).reorder(forward: false);
    final reordered = fixture.document.current.placedElements;
    expect(order(reordered, rock.id), lessThan(order(reordered, tree.id)));
    fixture.maps.restore(redo: false);
    final undone = fixture.document.current.placedElements;
    expect(order(undone, rock.id), greaterThan(order(undone, tree.id)));
    fixture.maps.restore(redo: true);
    final redone = fixture.document.current.placedElements;
    expect(order(redone, rock.id), lessThan(order(redone, tree.id)));
    expect(commands(fixture).decorOrderContext()!.forwardProblem, isNull);
    commands(fixture).reorder(forward: true);
    final broughtForward = fixture.document.current.placedElements;
    expect(
      order(broughtForward, rock.id),
      greaterThan(order(broughtForward, tree.id)),
    );
  });

  testWidgets('a mixed decor stack moves one neighboring rank and saves it', (
    tester,
  ) async {
    final fixture = await MapDiskOwnerFixture.open(tester);
    for (final id in ['arbre', 'rocher', 'arbre']) {
      await armDecor(fixture, id);
      await fixture.tapCell(8, 7);
    }
    final placed = fixture.document.current.placedElements;
    final firstTree = placed[placed.length - 3];
    final rock = placed[placed.length - 2];
    final lastTree = placed.last;
    expect(firstTree.layerId, 'decor');
    expect(rock.layerId, 'decor');
    expect(lastTree.layerId, 'decor');
    final context = commands(fixture).decorOrderContext()!;
    expect(context.reorderable, hasLength(3));
    expect(context.rank, 0);
    final before = fixture.document.undoCount;

    commands(fixture).reorder(forward: false);

    final updated = fixture.document.current.placedElements;
    expect(order(updated, lastTree.id), lessThan(order(updated, rock.id)));
    expect(
      order(updated, lastTree.id),
      inExclusiveRange(order(updated, firstTree.id), order(updated, rock.id)),
    );
    expect(fixture.document.undoCount, before + 1);

    await fixture.save();
    final saved = (await fixture.reopen(fixture.document.current.id))
        .placedElements;
    expect(order(saved, lastTree.id), lessThan(order(saved, rock.id)));
    expect(
      order(saved, lastTree.id),
      inExclusiveRange(order(saved, firstTree.id), order(saved, rock.id)),
    );
  });

  testWidgets('overlapping decors can exchange their visible order', (
    tester,
  ) async {
    final fixture = await MapDiskOwnerFixture.open(tester);

    await armDecor(fixture, 'arbre');
    await fixture.tapCell(8, 7);
    final tree = fixture.document.selected!;

    await armDecor(fixture, 'rocher');
    await fixture.tapCell(8, 7);
    final rock = fixture.document.selected!;

    expect(rock.layerId, tree.layerId);
    expect(rock.visualOrder, greaterThan(tree.visualOrder));

    expect(
      commands(fixture).decorOrderContext()!.backwardProblem,
      isNull,
      reason:
          'Deux décors réordonnables visibles à la même position '
          'doivent pouvoir échanger leur ordre depuis l’inspecteur.',
    );

    commands(fixture).reorder(forward: false);

    final placed = fixture.document.current.placedElements;
    expect(order(placed, rock.id), lessThan(order(placed, tree.id)));
  });
}
