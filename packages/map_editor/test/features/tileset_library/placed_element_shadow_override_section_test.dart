import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart';

void main() {
  group('PlacedElementShadowOverrideSection', () {
    testWidgets('shows the section title and inherit mode for null override',
        (tester) async {
      final harness = _Harness();

      await _pumpSection(tester, harness: harness);

      expect(find.text('Ombre de cette instance'), findsOneWidget);
      expect(find.text('Hériter'), findsWidgets);
      expect(harness.value, isNull);
    });

    testWidgets('disabled mode emits a disabled override', (tester) async {
      final harness = _Harness();
      await _pumpSection(tester, harness: harness);

      await tester.tap(find.text('Désactiver'));
      await tester.pump();

      expect(harness.value, isNotNull);
      expect(harness.value!.mode, ShadowOverrideMode.disabled);
    });

    testWidgets('custom mode emits custom override and reset emits null',
        (tester) async {
      final harness = _Harness();
      await _pumpSection(tester, harness: harness);

      await tester.tap(find.text('Personnaliser'));
      await tester.pump();

      expect(harness.value!.mode, ShadowOverrideMode.custom);

      await tester
          .tap(find.byKey(const ValueKey('placed-shadow-reset-button')));
      await tester.pump();

      expect(harness.value, isNull);
    });

    testWidgets('number fields update custom offset scale and opacity',
        (tester) async {
      final harness = _Harness(
        value: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
        ),
      );
      await _pumpSection(tester, harness: harness);

      await tester.enterText(
        find.byKey(const ValueKey('placed-shadow-offsetX-field')),
        '4',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('placed-shadow-scaleX-field')),
        '1.5',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('placed-shadow-opacity-field')),
        '0.25',
      );
      await tester.pump();

      expect(harness.value!.offsetX, 4);
      expect(harness.value!.scaleX, 1.5);
      expect(harness.value!.opacity, 0.25);
    });

    testWidgets('invalid scale and opacity values do not emit changes',
        (tester) async {
      final initial = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        scaleX: 1,
        opacity: 0.5,
      );
      final harness = _Harness(value: initial);
      await _pumpSection(tester, harness: harness);

      await tester.enterText(
        find.byKey(const ValueKey('placed-shadow-scaleX-field')),
        '0',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('placed-shadow-opacity-field')),
        '2',
      );
      await tester.pump();

      expect(harness.value, initial);
      expect(find.text('Doit être > 0'), findsOneWidget);
      expect(find.text('Doit être entre 0 et 1'), findsOneWidget);
    });

    testWidgets('profile dropdown filters actorContact and none profiles',
        (tester) async {
      final harness = _Harness(
        value: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
        ),
        manifest: _project(
          catalog: ProjectShadowCatalog(
            profiles: [
              _profile('ground_shadow', name: 'Ground shadow'),
              _profile(
                'actor_shadow',
                mode: ShadowCasterMode.contactBlob,
                renderPass: ShadowRenderPass.actorContact,
              ),
              _profile('none_shadow', mode: ShadowCasterMode.none),
            ],
          ),
        ),
      );
      await _pumpSection(tester, harness: harness);

      final popup = tester.widget<MacosPopupButton<String>>(
        find.byKey(const ValueKey('placed-shadow-profile-popup')),
      );

      expect(popup.items!.map((item) => item.value), [
        '__inherit__',
        'ground_shadow',
      ]);
    });

    testWidgets('empty catalog shows seed action', (tester) async {
      final harness = _Harness(
        value: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
        ),
        manifest: _project(catalog: const ProjectShadowCatalog.empty()),
      );
      await _pumpSection(tester, harness: harness);

      expect(find.text('Aucun profil Shadow disponible.'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('placed-shadow-default-profiles-button')),
      );
      await tester.pump();

      expect(harness.seedCount, 1);
    });

    testWidgets('quick tuning presets appear only in custom mode',
        (tester) async {
      final inheritHarness = _Harness();
      await _pumpSection(tester, harness: inheritHarness);

      expect(find.text('Réglages rapides'), findsNothing);

      final customHarness = _Harness(
        value: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
        ),
      );
      await _pumpSection(tester, harness: customHarness);

      expect(find.text('Réglages rapides'), findsOneWidget);
      expect(find.text('Petite ombre'), findsOneWidget);
      expect(find.text('Portée bas-droite'), findsOneWidget);
      expect(find.text('Portée bas-gauche'), findsOneWidget);
    });

    testWidgets('compact preset emits expected custom override values',
        (tester) async {
      final harness = _Harness(
        value: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
        ),
      );
      await _pumpSection(tester, harness: harness);

      await tester.tap(find.text('Petite ombre'));
      await tester.pump();

      expect(harness.value!.mode, ShadowOverrideMode.custom);
      expect(harness.value!.shadowProfileId, isNull);
      expect(harness.value!.offsetX, 0);
      expect(harness.value!.offsetY, 2);
      expect(harness.value!.scaleX, 0.65);
      expect(harness.value!.scaleY, 0.45);
      expect(harness.value!.opacity, 0.24);
      expect(
        tester
            .widget<MacosTextField>(
              find.byKey(const ValueKey('placed-shadow-offsetY-field')),
            )
            .controller!
            .text,
        '2.0',
      );
      expect(
        tester
            .widget<MacosTextField>(
              find.byKey(const ValueKey('placed-shadow-scaleX-field')),
            )
            .controller!
            .text,
        '0.65',
      );
    });

    testWidgets('cast presets apply the expected offset directions',
        (tester) async {
      final harness = _Harness(
        value: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
        ),
      );
      await _pumpSection(tester, harness: harness);

      await tester.tap(find.text('Portée bas-droite'));
      await tester.pump();

      expect(harness.value!.offsetX, greaterThan(0));
      expect(harness.value!.offsetY, greaterThan(0));

      await tester.tap(find.text('Portée bas-gauche'));
      await tester.pump();

      expect(harness.value!.offsetX, lessThan(0));
      expect(harness.value!.offsetY, greaterThan(0));
    });

    testWidgets('preset preserves a selected custom profile id',
        (tester) async {
      final harness = _Harness(
        value: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          shadowProfileId: 'wide_shadow',
        ),
      );
      await _pumpSection(tester, harness: harness);

      await tester.tap(find.text('Petite ombre'));
      await tester.pump();

      expect(harness.value!.mode, ShadowOverrideMode.custom);
      expect(harness.value!.shadowProfileId, 'wide_shadow');
    });
  });
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required _Harness harness,
}) async {
  await tester.binding.setSurfaceSize(const Size(520, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MacosTheme(
      data: MacosThemeData.light(),
      child: MaterialApp(
        home: CupertinoPageScaffold(
          child: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 460,
                child: PlacedElementShadowOverrideSection(
                  manifest: harness.manifest,
                  element: harness.element,
                  instance: harness.instance,
                  shadowOverride: harness.value,
                  onChanged: (next) {
                    harness.changes.add(next);
                    setState(() => harness.value = next);
                  },
                  onEnsureDefaultShadowProfiles: () {
                    harness.seedCount += 1;
                  },
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

final class _Harness {
  _Harness({
    this.value,
    ProjectManifest? manifest,
  }) : manifest = manifest ?? _project();

  MapPlacedElementShadowOverride? value;
  final ProjectManifest manifest;
  final ProjectElementEntry element = _element();
  final MapPlacedElement instance = _instance();
  final List<MapPlacedElementShadowOverride?> changes = [];
  int seedCount = 0;
}

ProjectManifest _project({ProjectShadowCatalog? catalog}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    shadowCatalog: catalog ??
        ProjectShadowCatalog(
          profiles: [
            _profile('base_shadow', name: 'Base shadow'),
            _profile('wide_shadow', name: 'Wide shadow'),
          ],
        ),
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectElementEntry _element() {
  return ProjectElementEntry(
    id: 'lamp',
    name: 'Lamp',
    tilesetId: 'ts',
    categoryId: 'cat',
    frames: const [
      TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
    ],
    shadow: ProjectElementShadowConfig(
      castsShadow: true,
      shadowProfileId: 'base_shadow',
    ),
  );
}

MapPlacedElement _instance() {
  return const MapPlacedElement(
    id: 'layer::1::1',
    layerId: 'layer',
    elementId: 'lamp',
    pos: GridPos(x: 1, y: 1),
  );
}

ProjectShadowProfile _profile(
  String id, {
  String? name,
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
}) {
  return ProjectShadowProfile(
    id: id,
    name: name ?? '$id profile',
    mode: mode,
    renderPass: renderPass,
  );
}
