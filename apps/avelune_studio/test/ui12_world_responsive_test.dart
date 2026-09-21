import 'dart:async';

import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/world/world_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/m2_ui_fixture.dart';
import 'support/ui12_page_harness.dart';

void seed(Ui12PageHarness h) {
  final factId = h.controller.createFact();
  h.controller.editFact(
    NarrativeFactDefinition(
      id: factId,
      label: 'Train parti',
      initialValue: const NarrativeValue.boolean(false),
    ),
  );
  final map = h.controller.maps.firstWhere((map) => map.entities.isNotEmpty);
  final entity = map.entities.first;
  final ruleId = h.controller.createRule(factId: factId);
  h.controller.editRule(ruleId, (draft) {
    draft.label = 'Masquer le conducteur';
    draft.target = WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEntity,
      mapId: map.id,
      entityId: entity.id,
      label: entity.id,
    );
    draft.effect = const WorldRuleEffect(
      kind: WorldRuleEffectKind.entityHidden,
    );
  });
  h.controller.simulate();
}

void main() {
  for (final size in [
    const Size(1536, 1024),
    const Size(1440, 900),
    const Size(1280, 800),
    const Size(1024, 640),
  ]) {
    final width = size.width.toInt();
    testWidgets('UI12 stays usable at $width', (tester) async {
      final compact = width == 1024;
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = (await tester.runAsync(() => Ui12PageHarness.create(tester)))!;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(h.dispose);
      });
      await tester.pumpWidget(h.app(textScale: compact ? 1.5 : 1));
      unawaited(h.controller.initialize());
      await pumpIo(tester);
      seed(h);
      h.view.view = WorldView.rules;
      await pumpIo(tester);

      // Saving must stay within reach whatever the window does.
      expect(find.text('Enregistrer').hitTestable(), findsOneWidget);
      expect(find.text('Masquer le conducteur'), findsWidgets);

      if (compact) {
        // The panels fold into sheets instead of shrinking the whole page.
        expect(find.text('Contexte').hitTestable(), findsOneWidget);
        await tester.tap(find.text('Contexte'));
        await pumpIo(tester, frames: 12);
        expect(find.text('Tester la règle').hitTestable(), findsOneWidget);
        await tester.tapAt(const Offset(4, 4));
        await pumpIo(tester, frames: 12);
      } else {
        expect(find.text('Tester la règle').hitTestable(), findsOneWidget);
        expect(find.text('Condition'), findsOneWidget);
        expect(find.text('Cible'), findsOneWidget);
        expect(find.text('Effet'), findsOneWidget);
      }
      await h.capture(tester, 'ui12-04-taille-$width');
      expect(tester.takeException(), isNull);
    });
  }
}
