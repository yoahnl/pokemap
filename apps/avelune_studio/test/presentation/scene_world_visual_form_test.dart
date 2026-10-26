import 'package:avelune_studio/presentation/features/scenes/scene_world_visual_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  testWidgets('scene atmosphere form preserves explicit time and weather modes', (tester) async {
    final settings = SpatialVisualPatch.fromJson({'timeMode': 'fixed', 'minuteOfDay': 1320, 'weatherMode': 'fixed', 'weatherKind': 'storm'});
    final command = SceneInteractiveCommand.worldPresentation(operation: SceneWorldPresentationOperation.atmosphere, visualSettings: settings, scope: SceneVisualScope.scene);
    SceneNodePayload? applied;
    await tester.pumpWidget(MaterialApp(theme: studioTheme(), home: Scaffold(body: SingleChildScrollView(child: SceneWorldVisualActionForm(
      current: SceneActionPayload.interactive(command), onApply: (value) => applied = value,
    )))));
    expect(tester.widget<StudioSelect>(find.byKey(const ValueKey('visual-timeMode'))).value, 'fixed');
    expect(tester.widget<StudioSelect>(find.byKey(const ValueKey('visual-weatherMode'))).value, 'fixed');
    final apply = find.byWidgetPredicate((widget) => widget is StudioButton && widget.label == 'Appliquer l’action');
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pump();
    expect((applied as SceneActionPayload).interactiveCommand!.toJson(), command.toJson());
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'guided visual form preserves an existing picture and explicit scope',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final command = SceneInteractiveCommand.worldPresentation(
        operation: SceneWorldPresentationOperation.erasePicture,
        slotId: 7,
        scope: SceneVisualScope.scene,
      );
      SceneNodePayload? applied;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SceneWorldVisualActionForm(
                current: SceneActionPayload.interactive(command),
                onApply: (value) => applied = value,
              ),
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<StudioSelect>(
              find.byWidgetPredicate(
                (widget) => widget is StudioSelect && widget.label == 'Effet',
              ),
            )
            .value,
        'erasePicture',
      );
      expect(find.text('Scène'), findsWidgets);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is StudioButton && widget.label == 'Appliquer l’action',
        ),
      );
      await tester.pump();
      expect(
        (applied as SceneActionPayload).interactiveCommand!.toJson(),
        command.toJson(),
      );
    },
  );
}
