import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_ambiance_harness.dart';

void main() {
  testWidgets('a map keeps the project clock or fixes its own hour', (
    tester,
  ) async {
    await open(tester, spatial: true);

    expect(
      find.byKey(const ValueKey('map-space-rubric-dayNight')),
      findsOneWidget,
    );
    expect(
      find.text('Le projet suit l’heure réelle de l’appareil.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<StudioChoice>(
            find.byKey(const ValueKey('map-ambiance-time-inherit')),
          )
          .selected,
      isTrue,
    );
    expect(find.byKey(const ValueKey('map-ambiance-time-hour')), findsNothing);
    expect(maps.dirty, isFalse);

    await tester.tap(find.byKey(const ValueKey('map-ambiance-time-fixed')));
    await tester.pump();
    expect(patch().choice(SpatialVisualParameter.timeMode), 'fixed');
    expect(find.text('Heure · 12:00'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('map-ambiance-time-preset-1380')),
    );
    await tester.pump();
    expect(patch().number(SpatialVisualParameter.minuteOfDay), 1380);
    expect(find.text('Heure · 23:00'), findsOneWidget);
    expect(
      maps.active!.visualProfile.number(SpatialVisualParameter.minuteOfDay),
      1380,
    );
    expect(maps.dirty, isTrue);

    bar(tester).onUndo!();
    await tester.pump();
    expect(patch().number(SpatialVisualParameter.minuteOfDay), 720);
    expect(patch().choice(SpatialVisualParameter.timeMode), 'fixed');
    bar(tester).onRedo!();
    await tester.pump();
    expect(patch().number(SpatialVisualParameter.minuteOfDay), 1380);

    expect(await maps.saveAll(), isTrue);
    expect(port.mapPatches['a']!.toJson(), {
      'timeMode': 'fixed',
      'minuteOfDay': 1380.0,
    });
    expect(port.saved['a'], spatialMap('a'));
    expect(maps.dirty, isFalse);

    await tester.tap(find.byKey(const ValueKey('map-ambiance-time-inherit')));
    await tester.pump();
    expect(patch().toJson(), isEmpty);
    expect(find.byKey(const ValueKey('map-ambiance-time-hour')), findsNothing);
  });

  testWidgets('a map keeps the project weather or fixes its own sky', (
    tester,
  ) async {
    await open(tester, spatial: true);
    await tester.tap(find.byKey(const ValueKey('map-space-rubric-weather')));
    await tester.pump();

    expect(find.text('Le projet suit la météo réelle.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('map-ambiance-weather-kind-rain')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('map-ambiance-weather-fixed')));
    await tester.pump();
    expect(patch().choice(SpatialVisualParameter.weatherMode), 'fixed');
    expect(patch().choice(SpatialVisualParameter.weatherKind), 'rain');
    expect(
      find.byKey(const ValueKey('map-ambiance-weather-kind-rain')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('map-ambiance-weather-fixed')));
    await tester.pump();
    expect(patch().choice(SpatialVisualParameter.weatherKind), 'rain');

    await tester.tap(
      find.byKey(const ValueKey('map-ambiance-weather-kind-storm')),
    );
    await tester.pump();
    expect(patch().choice(SpatialVisualParameter.weatherKind), 'storm');
    expect(
      find.byKey(const ValueKey('map-ambiance-weather-lightning')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('map-ambiance-weather-sound')));
    await tester.pump();
    expect(patch().enabled(SpatialVisualParameter.weatherSoundEnabled), isTrue);

    await tester.tap(
      find.byKey(const ValueKey('map-ambiance-weather-kind-clear')),
    );
    await tester.pump();
    expect(patch().choice(SpatialVisualParameter.weatherKind), 'clear');
    expect(patch().enabled(SpatialVisualParameter.weatherEnabled), isFalse);
    expect(
      find.byKey(const ValueKey('map-ambiance-weather-intensity')),
      findsNothing,
    );

    bar(tester).onUndo!();
    await tester.pump();
    expect(patch().choice(SpatialVisualParameter.weatherKind), 'storm');
    expect(patch().enabled(SpatialVisualParameter.weatherSoundEnabled), isTrue);

    expect(await maps.saveAll(), isTrue);
    expect(
      port.mapPatches['a']!.choice(SpatialVisualParameter.weatherKind),
      'storm',
    );

    await tester.tap(
      find.byKey(const ValueKey('map-ambiance-weather-inherit')),
    );
    await tester.pump();
    expect(patch().toJson(), isEmpty);
  });

  testWidgets('each effect follows the project or takes its own setting', (
    tester,
  ) async {
    await open(tester, spatial: true);
    await tester.tap(find.byKey(const ValueKey('map-space-rubric-effects')));
    await tester.pump();

    expect(find.text('Activé · comme le projet'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('map-ambiance-effect-detail-halos')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('map-ambiance-effect-toggle')),
      findsNothing,
    );

    await tester.tap(find.text('Cette carte'));
    await tester.pump();
    expect(patch().enabled(SpatialVisualParameter.halosEnabled), isTrue);
    expect(patch().number(SpatialVisualParameter.haloStrength), 1.06);
    expect(
      find.byKey(const ValueKey('map-ambiance-effect-level-haloStrength')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('map-ambiance-effect-toggle')));
    await tester.pump();
    expect(patch().enabled(SpatialVisualParameter.halosEnabled), isFalse);
    expect(find.text('Désactivé · propre à la carte'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('map-ambiance-effect-level-haloStrength')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('map-ambiance-effect-fireflies')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('map-ambiance-effect-detail-halos')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('map-ambiance-effect-detail-fireflies')),
      findsOneWidget,
    );

    bar(tester).onUndo!();
    await tester.pump();
    expect(patch().enabled(SpatialVisualParameter.halosEnabled), isTrue);
    bar(tester).onRedo!();
    await tester.pump();

    expect(await maps.saveAll(), isTrue);
    final saved = port.mapPatches['a']!;
    expect(saved.enabled(SpatialVisualParameter.halosEnabled), isFalse);
    expect(saved.number(SpatialVisualParameter.haloStrength), 1.06);
    expect(saved.number(SpatialVisualParameter.haloSpread), isNotNull);
    expect(saved.values.keys, hasLength(3));

    await tester.tap(find.byKey(const ValueKey('map-ambiance-effect-halos')));
    await tester.pump();
    await tester.tap(find.text('Projet'));
    await tester.pump();
    expect(patch().toJson(), isEmpty);
  });
}
