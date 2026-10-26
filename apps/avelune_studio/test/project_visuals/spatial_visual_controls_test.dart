import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/features/project_settings/spatial_visual_controls.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_slider.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';

void main() {
  testWidgets('time modes and automatic weather edit only their local settings', (tester) async {
    var patch = SpatialVisualPatch();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: StatefulBuilder(builder: (context, setState) => SpatialVisualControls(
      camera: false, patch: patch,
      inherited: SpatialVisualPatch.fromScene(camera: SpatialCameraProfile(), atmosphere: SpatialAtmosphereSettings()),
      onChanged: (value) => setState(() => patch = value),
    ))))));
    Future<void> choose(String key, String label) async {
      final select = find.byKey(ValueKey(key));
      await tester.ensureVisible(select);
      await tester.tap(select);
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }
    await choose('visual-timeMode', 'Heure réelle de l’appareil');
    expect(patch.choice(SpatialVisualParameter.timeMode), 'real');
    expect(find.byKey(const ValueKey('visual-minuteOfDay')), findsNothing);
    await choose('visual-timeMode', 'Cycle du jeu');
    expect(find.byKey(const ValueKey('visual-dayDurationSeconds')), findsOneWidget);
    await choose('visual-timeMode', 'Heure fixe');
    expect(find.byKey(const ValueKey('visual-minuteOfDay')), findsOneWidget);
    await choose('visual-weatherMode', 'Météo réelle du joueur');
    expect(patch.choice(SpatialVisualParameter.weatherMode), 'real');
    await choose('visual-weatherMode', 'Météo automatique');
    expect(patch.enabled(SpatialVisualParameter.weatherEnabled), isTrue);
    final snow = find.byKey(const ValueKey('weather-preset-snow'));
    await tester.ensureVisible(snow);
    await tester.tap(snow);
    await tester.pump();
    expect(patch.value(SpatialVisualParameter.weatherSequence), ['clear', 'cloudy', 'rain', 'snow']);
    expect(patch.choice(SpatialVisualParameter.weatherKind), isNull);
    expect(find.byType(StudioSelect), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'FOV retains framing, fog bounds stay valid and inheritance removes only one field',
    (tester) async {
      var patch = SpatialVisualPatch.fromJson({
        'pitchDegrees': 34,
        'haloStrength': 1.2,
        'fogStart': 40,
        'fogEnd': 60,
      });
      final base = SpatialVisualPatch.fromScene(
        camera: SpatialCameraProfile(),
        atmosphere: SpatialAtmosphereSettings(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpatialVisualControls(
                patch: patch,
                inherited: base,
                onChanged: (next) => patch = next,
              ),
            ),
          ),
        ),
      );
      final controls = tester.widget<SpatialVisualControls>(
        find.byType(SpatialVisualControls),
      );
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
    },
  );
  testWidgets('weather presets, sliders and inheritance use one local patch', (
    tester,
  ) async {
    var patch = SpatialVisualPatch.fromJson({'haloStrength': 1.2});
    final base = SpatialVisualPatch.fromScene(
      camera: SpatialCameraProfile(),
      atmosphere: SpatialAtmosphereSettings(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => SpatialVisualControls(
                camera: false,
                clock: false,
                patch: patch,
                inherited: base,
                onChanged: (next) => setState(() => patch = next),
              ),
            ),
          ),
        ),
      ),
    );
    final snow = find.byKey(const ValueKey('weather-preset-snow'));
    await tester.ensureVisible(snow);
    await tester.tap(snow);
    await tester.pump();
    expect(patch.choice(SpatialVisualParameter.weatherKind), 'snow');
    expect(patch.enabled(SpatialVisualParameter.weatherEnabled), isTrue);
    final control = find.descendant(
      of: find.byKey(const ValueKey('visual-weatherIntensity')),
      matching: find.byType(Slider),
    );
    await tester.ensureVisible(control);
    await tester.drag(control, const Offset(45, 0));
    await tester.pump();
    expect(patch.number(SpatialVisualParameter.weatherIntensity), isNotNull);
    final audio = find.byKey(const ValueKey('visual-weatherSoundEnabled'));
    await tester.ensureVisible(audio);
    await tester.tap(find.descendant(of: audio, matching: find.byType(Switch)));
    await tester.pump();
    expect(patch.enabled(SpatialVisualParameter.weatherSoundEnabled), isTrue);
    final rainVolume = find.descendant(of: find.byKey(const ValueKey('visual-weatherRainVolume')), matching: find.byType(Slider));
    await tester.ensureVisible(rainVolume);
    await tester.drag(rainVolume, const Offset(45, 0));
    await tester.pump();
    expect(patch.number(SpatialVisualParameter.weatherRainVolume), isNotNull);
    final inheritAudio = find.byKey(const ValueKey('inherit-weatherSoundEnabled'));
    await tester.ensureVisible(inheritAudio);
    await tester.tap(inheritAudio);
    await tester.pump();
    expect(patch.enabled(SpatialVisualParameter.weatherSoundEnabled), isNull);
    final inherit = find.byKey(const ValueKey('inherit-weatherKind'));
    await tester.ensureVisible(inherit);
    await tester.tap(inherit);
    await tester.pump();
    expect(patch.choice(SpatialVisualParameter.weatherKind), isNull);
    expect(patch.number(SpatialVisualParameter.haloStrength), 1.2);
    expect(patch.enabled(SpatialVisualParameter.weatherLightning), isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('a physical slider gesture invokes one undo boundary', (
    tester,
  ) async {
    var starts = 0, ends = 0, updates = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpatialVisualControls(
              patch: SpatialVisualPatch(),
              inherited: SpatialVisualPatch.fromScene(
                camera: SpatialCameraProfile(),
                atmosphere: SpatialAtmosphereSettings(),
              ),
              onEditStart: () => starts++,
              onEditEnd: () => ends++,
              onChanged: (_) => updates++,
            ),
          ),
        ),
      ),
    );
    final control = find.descendant(
      of: find.byKey(const ValueKey('visual-pitchDegrees')),
      matching: find.byType(Slider),
    );
    await tester.drag(control, const Offset(50, 0));
    await tester.pump();
    expect(starts, 1);
    expect(ends, 1);
    expect(updates, greaterThan(0));
    expect(find.byType(StudioSlider), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
