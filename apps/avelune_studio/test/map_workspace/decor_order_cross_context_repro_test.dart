import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_host_fixture.dart';

void main() {
  testWidgets('overlapping decors can exchange their visible order', (
    tester,
  ) async {
    final fixture = await MapHostFixture.open(tester);

    await tester.tap(find.byKey(const ValueKey('decor-arbre')));
    await fixture.tapCell(8, 7);
    final tree = fixture.document.selected!;

    await tester.tap(find.byKey(const ValueKey('decor-rocher')));
    await fixture.tapCell(8, 7);
    final rock = fixture.document.selected!;

    expect(rock.layerId, tree.layerId);
    expect(rock.visualOrder, greaterThan(tree.visualOrder));

    final sendBackward = tester.widget<StudioButton>(
      find.byKey(const ValueKey('Passer derrière')),
    );
    expect(
      sendBackward.onPressed,
      isNotNull,
      reason:
          'Deux décors réordonnables visibles à la même position '
          'doivent pouvoir échanger leur ordre depuis l’inspecteur.',
    );

    await tester.tap(find.byKey(const ValueKey('Passer derrière')));
    await tester.pump();

    final placed = fixture.document.current.placedElements;
    final treeAfter = placed.firstWhere((element) => element.id == tree.id);
    final rockAfter = placed.firstWhere((element) => element.id == rock.id);
    expect(rockAfter.visualOrder, lessThan(treeAfter.visualOrder));
  });
}
