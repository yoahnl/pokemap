import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/features/project_settings/spatial_visual_controls.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_slider.dart';

void main() {
  testWidgets('FOV retains framing, fog bounds stay valid and inheritance removes only one field', (tester) async {
    var patch = SpatialVisualPatch.fromJson({'pitchDegrees':34,'haloStrength':1.2,'fogStart':40,'fogEnd':60});
    final base = SpatialVisualPatch.fromScene(camera: SpatialCameraProfile(), atmosphere: SpatialAtmosphereSettings());
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SpatialVisualControls(
      patch: patch, inherited: base, onChanged: (next) => patch = next)))));
    final controls = tester.widget<SpatialVisualControls>(find.byType(SpatialVisualControls));
    controls.change(SpatialVisualParameter.fieldOfViewDegrees, 24.0);
    expect(patch.number(SpatialVisualParameter.cameraDistance), lessThan(42));
    controls.change(SpatialVisualParameter.fogStart, 80.0);
    expect(patch.number(SpatialVisualParameter.fogEnd), 81);
    final button = find.byKey(const ValueKey('inherit-haloStrength'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    expect(patch.value(SpatialVisualParameter.haloStrength), isNull);
    expect(patch.number(SpatialVisualParameter.pitchDegrees), 34);
    expect(tester.takeException(), isNull);
  });
  testWidgets('a physical slider gesture invokes one undo boundary', (tester) async {
    var starts = 0, ends = 0, updates = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SpatialVisualControls(
      patch: SpatialVisualPatch(), inherited: SpatialVisualPatch.fromScene(camera: SpatialCameraProfile(), atmosphere: SpatialAtmosphereSettings()),
      onEditStart: () => starts++, onEditEnd: () => ends++, onChanged: (_) => updates++)))));
    final control = find.descendant(of: find.byKey(const ValueKey('visual-pitchDegrees')), matching: find.byType(Slider));
    await tester.drag(control, const Offset(50,0));
    await tester.pump();
    expect(starts, 1);expect(ends, 1);expect(updates, greaterThan(0));
    expect(find.byType(StudioSlider), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
