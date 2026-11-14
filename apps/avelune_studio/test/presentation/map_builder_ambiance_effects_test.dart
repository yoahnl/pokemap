import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'map_builder_ambiance_harness.dart';

void main() {
  testWidgets('effect sources come from the canvas and share the tab history', (
    tester,
  ) async {
    await open(tester, spatial: true);
    await tester.tap(find.byKey(const ValueKey('map-space-rubric-effects')));
    await tester.pump();
    SpatialAtmosphereSettings sources() => maps.active!.atmosphere!.current;
    Finder key(String value) => find.byKey(ValueKey(value));

    expect(find.text('Aucun halo placé sur cette carte.'), findsOneWidget);
    expect(key('map-ambiance-source-hint'), findsOneWidget);
    expect(key('map-ambiance-source-add-halo'), findsNothing);

    view.select(maps.active!, MapSelectionFamily.decor, 'lamp-1');
    ambiance.changed();
    await tester.pump();
    expect(find.text('Lanterne'), findsOneWidget);

    await tester.tap(find.text('Cette carte'));
    await tester.pump();
    await tester.tap(key('map-ambiance-source-add-halo'));
    await tester.pump();
    expect(sources().halos.single.instanceId, 'lamp-1');
    expect(find.text('1 halo placé sur cette carte.'), findsOneWidget);
    expect(key('map-ambiance-source-0'), findsOneWidget);

    bar(tester).onUndo!();
    await tester.pump();
    expect(sources().halos, isEmpty);
    expect(patch().toJson(), isNotEmpty);
    bar(tester).onUndo!();
    await tester.pump();
    expect(patch().toJson(), isEmpty);
    expect(bar(tester).onUndo, isNull);
    bar(tester).onRedo!();
    await tester.pump();
    expect(patch().toJson(), isNotEmpty);
    expect(sources().halos, isEmpty);
    bar(tester).onRedo!();
    await tester.pump();
    expect(sources().halos, hasLength(1));

    bar(tester).onUndo!();
    await tester.pump();
    expect(bar(tester).onRedo, isNotNull);
    await tester.tap(key('map-ambiance-effect-toggle'));
    await tester.pump();
    expect(bar(tester).onRedo, isNull);
    expect(sources().halos, isEmpty);

    await tester.tap(key('map-ambiance-source-add-halo'));
    await tester.pump();
    await tester.tap(key('map-ambiance-source-remove-0'));
    await tester.pump();
    expect(sources().halos, isEmpty);
    await tester.tap(key('map-ambiance-source-add-halo'));
    await tester.pump();

    await tester.tap(key('map-ambiance-effect-water'));
    await tester.pump();
    await tester.tap(key('map-ambiance-material-lamp-1-verre'));
    await tester.pump();
    expect(sources().waterTargets.single.materialName, 'verre');
    expect(find.text('verre · Lanterne'), findsOneWidget);
    await tester.tap(key('map-ambiance-material-lamp-1-verre'));
    await tester.pump();
    expect(sources().waterTargets, isEmpty);

    await tester.tap(key('map-ambiance-effect-windows'));
    await tester.pump();
    await tester.tap(key('map-ambiance-material-lamp-1-fer'));
    await tester.pump();
    expect(sources().windows.single.target.materialName, 'fer');

    await tester.tap(key('map-ambiance-effect-fireflies'));
    await tester.pump();
    expect(key('map-ambiance-source-hint'), findsNothing);
    await tester.tap(key('map-ambiance-source-cover-map'));
    await tester.pump();
    expect(sources().fireflyZones, hasLength(1));
    expect(find.text('Toute la carte'), findsOneWidget);
    expect(key('map-ambiance-source-cover-map'), findsNothing);

    expect(await maps.saveAll(), isTrue);
    final saved = port.atmospheres['a']!;
    expect(saved.halos.single.instanceId, 'lamp-1');
    expect(saved.windows, hasLength(1));
    expect(saved.waterTargets, isEmpty);
    expect(saved.fireflyZones, hasLength(1));
    expect(port.saved['a'], spatialMap('a'));

    view.clearSelection(maps.active!);
    ambiance.changed();
    await tester.pump();
    await tester.tap(key('map-ambiance-source-remove-0'));
    await tester.pump();
    expect(sources().fireflyZones, isEmpty);
    expect(key('map-ambiance-source-cover-map'), findsOneWidget);
  });

  testWidgets('a map picks its music from the imported sounds', (tester) async {
    await open(tester, spatial: true);
    await tester.tap(find.byKey(const ValueKey('map-space-rubric-music')));
    for (var frame = 0; frame < 3; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    MapMetadata metadata() => maps.active!.current.mapMetadata;
    Finder key(String value) => find.byKey(ValueKey(value));

    expect(find.text('Aucune musique'), findsNWidgets(2));
    expect(find.text('arene · combat'), findsOneWidget);
    expect(key('map-ambiance-music-track-title'), findsNothing);
    expect(key('map-ambiance-music-volume'), findsNothing);

    await tester.tap(key('map-ambiance-music-track-town'));
    await tester.pump();
    expect(metadata().musicPath, 'assets/audio/johto/bourg/theme.wav');
    expect(find.text('bourg · theme'), findsNWidgets(2));
    tester.widget<StudioSlider>(key('map-ambiance-music-volume')).onChangeEnd!(
      .5,
    );
    await tester.pump();
    expect(metadata().musicVolume, .5);

    await tester.tap(key('map-ambiance-music-slot-battle'));
    await tester.pump();
    expect(find.text('Comme le projet'), findsNWidgets(2));
    await tester.enterText(key('map-ambiance-music-search'), 'aren');
    await tester.enterText(key('map-ambiance-music-search'), 'arene');
    await tester.pump(const Duration(milliseconds: 200));
    expect(key('map-ambiance-music-track-town'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(key('map-ambiance-music-track-town'), findsNothing);
    await tester.tap(key('map-ambiance-music-track-battle'));
    await tester.pump();
    expect(metadata().battleMusicPath, 'assets/audio/johto/arene/combat.wav');
    expect(metadata().musicPath, 'assets/audio/johto/bourg/theme.wav');

    await tester.tap(key('map-space-rubric-dayNight'));
    await tester.pump();
    await tester.tap(key('map-ambiance-time-fixed'));
    await tester.pump();
    expect(patch().choice(SpatialVisualParameter.timeMode), 'fixed');

    bar(tester).onUndo!();
    await tester.pump();
    expect(patch().toJson(), isEmpty);
    bar(tester).onUndo!();
    await tester.pump();
    expect(metadata().battleMusicPath, isNull);
    bar(tester).onUndo!();
    await tester.pump();
    expect(metadata().musicVolume, isNull);
    bar(tester).onUndo!();
    await tester.pump();
    expect(metadata().musicPath, isNull);
    expect(bar(tester).onUndo, isNull);
    bar(tester).onRedo!();
    await tester.pump();
    expect(metadata().musicPath, 'assets/audio/johto/bourg/theme.wav');

    await tester.tap(key('map-space-rubric-music'));
    await tester.pump();
    await tester.tap(key('map-ambiance-music-slot-exploration'));
    await tester.pump();
    await tester.tap(key('map-ambiance-music-track-none'));
    await tester.pump();
    expect(metadata().musicPath, isNull);
    await tester.tap(key('map-ambiance-music-track-battle'));
    await tester.pump();

    expect(await maps.saveAll(), isTrue);
    expect(
      port.saved['a']!.mapMetadata.musicPath,
      'assets/audio/johto/arene/combat.wav',
    );
    expect(port.saved['a']!.mapMetadata.battleMusicPath, isNull);
  });

  testWidgets('a custom clock override is announced and can be replaced', (
    tester,
  ) async {
    await open(tester, spatial: true);
    port.mapPatches['a'] = SpatialVisualPatch.fromJson({
      'timeMode': 'cycle',
      'dayDurationSeconds': 300,
    });
    await ambiance.visuals!.open(map: workspaceEntries.first);
    await tester.pump();

    expect(
      find.text(
        'Cette carte a un réglage d’horloge personnalisé. Choisissez une option pour le remplacer.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('map-ambiance-time-fixed')));
    await tester.pump();
    expect(patch().toJson(), {'timeMode': 'fixed', 'minuteOfDay': 720.0});
  });

  testWidgets('a 2D map says ambience needs a 3D map', (tester) async {
    await open(tester, spatial: false);

    expect(find.text('L’ambiance se règle sur les cartes 3D.'), findsOneWidget);
    expect(ambiance.visuals, isNull);
    await tester.tap(find.byKey(const ValueKey('map-space-rubric-music')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('map-ambiance-music')), findsOneWidget);
    expect(find.text('L’ambiance se règle sur les cartes 3D.'), findsNothing);
    expect(bar(tester).onUndo, isNull);
  });
}
