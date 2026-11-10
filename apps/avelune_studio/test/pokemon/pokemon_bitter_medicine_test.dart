import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_item_effects.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'pokemon_fishing_effect_test.dart' show FishingCommercePort;

void main() {
  testWidgets('guided medicine settings persist friendship and confusion without JSON editing', (tester) async {
    final port = FishingCommercePort();
    VoidCallback redraw = () {};
    final commerce = PokemonCommerceController(port, changed: () => redraw());
    await commerce.load();
    commerce.selectItem(port.item);
    addTearDown(commerce.dispose);
    await tester.pumpWidget(MaterialApp(theme: studioTheme(), home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
      redraw = () => setState(() {});
      return SingleChildScrollView(child: PokemonItemEffects(commerce: commerce));
    }))));
    await tester.tap(find.text('Ajouter un effet').first);
    await tester.pumpAndSettle();
    final loss = find.byWidgetPredicate((widget) => widget is StudioToggleRow && widget.label == 'Réduire l’amitié après utilisation');
    tester.widget<StudioToggleRow>(loss).onChanged!(true);
    await tester.pump();
    expect(commerce.item!.uses.single.friendshipLoss, const ProjectItemFriendshipLoss(low: 5, medium: 5, high: 10));
    final high = find.widgetWithText(TextField, 'Amitié retirée (200–255)');
    await tester.ensureVisible(high);
    await tester.enterText(high, '12');
    await tester.pump();
    final type = tester.widgetList<StudioSelect>(find.byType(StudioSelect)).singleWhere((widget) => widget.label == 'Type d’effet');
    type.onChanged!('cure');
    await tester.pump();
    final confusion = find.byWidgetPredicate((widget) => widget is StudioToggleRow && widget.label == 'Soigner aussi la confusion en combat');
    tester.widget<StudioToggleRow>(confusion).onChanged!(true);
    await tester.pump();
    expect(commerce.item!.uses.single.friendshipLoss!.high, 12);
    expect((commerce.item!.uses.single.effect as ProjectItemCureStatusEffectDefinition).curesConfusion, isTrue);
    expect(await commerce.save(), isTrue);
    expect(port.item.uses.single.friendshipLoss!.high, 12);
    expect((port.item.uses.single.effect as ProjectItemCureStatusEffectDefinition).curesConfusion, isTrue);
    expect(tester.takeException(), isNull);
  });
}
