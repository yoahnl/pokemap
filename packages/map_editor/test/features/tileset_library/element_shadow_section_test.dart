import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart';

void main() {
  group('ElementShadowSection', () {
    test('is inserted before the collision summary in Edit Element', () {
      final source = File(
        'lib/src/ui/panels/tileset_palette_panel.dart',
      ).readAsStringSync();
      final editDialogIndex = source.indexOf("'Edit Element'");

      final shadowIndex = source.indexOf(
        'ElementShadowSection(',
        editDialogIndex,
      );
      final collisionIndex =
          source.indexOf('_ElementCollisionProfileSummaryCard(', shadowIndex);

      expect(editDialogIndex, isNonNegative);
      expect(shadowIndex, isNonNegative);
      expect(collisionIndex, isNonNegative);
      expect(shadowIndex, lessThan(collisionIndex));
    });

    testWidgets('shows not configured state for a null shadow config',
        (tester) async {
      final harness = _ShadowSectionHarness();

      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(_catalog([_profile('tree_large')])),
      );

      expect(find.text('Ombre de l’élément'), findsOneWidget);
      expect(find.text('Non configurée'), findsOneWidget);
      expect(harness.shadow, isNull);
    });

    testWidgets('shows seed action when the catalog has no compatible profiles',
        (tester) async {
      final harness = _ShadowSectionHarness();
      var seedCount = 0;

      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(ProjectShadowCatalog()),
        onEnsureDefaultShadowProfiles: () => seedCount += 1,
      );

      expect(find.text('Aucun profil Shadow disponible.'), findsOneWidget);
      expect(
        find.text('Ajouter les profils Shadow par défaut'),
        findsOneWidget,
      );
      final toggle = tester.widget<CupertinoSwitch>(
        find.byKey(const ValueKey('element-shadow-casts-switch')),
      );
      expect(toggle.onChanged, isNull);

      await tester.tap(
        find.byKey(const ValueKey('element-shadow-default-profiles-button')),
      );
      await tester.pump();

      expect(seedCount, 1);
    });

    testWidgets('actorContact-only catalog is treated as no compatible profile',
        (tester) async {
      final harness = _ShadowSectionHarness();

      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(
          _catalog([
            _profile(
              'actor_contact',
              mode: ShadowCasterMode.contactBlob,
              renderPass: ShadowRenderPass.actorContact,
            ),
          ]),
        ),
        onEnsureDefaultShadowProfiles: () {},
      );

      expect(find.text('Aucun profil Shadow disponible.'), findsOneWidget);
      expect(
        find.text('Ajouter les profils Shadow par défaut'),
        findsOneWidget,
      );
      final popup = tester.widget<MacosPopupButton<String>>(
        find.byKey(const ValueKey('element-shadow-profile-popup')),
      );
      expect(popup.items, isEmpty);
    });

    testWidgets('none-only catalog is treated as no compatible profile',
        (tester) async {
      final harness = _ShadowSectionHarness();

      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(
          _catalog([
            _profile('none_profile', mode: ShadowCasterMode.none),
          ]),
        ),
        onEnsureDefaultShadowProfiles: () {},
      );

      expect(find.text('Aucun profil Shadow disponible.'), findsOneWidget);
      expect(
        find.text('Ajouter les profils Shadow par défaut'),
        findsOneWidget,
      );
    });

    testWidgets('after seed the default profiles appear in the dropdown',
        (tester) async {
      final harness = _ShadowSectionHarness();
      var manifest = _project(ProjectShadowCatalog());

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
                    child: ElementShadowSection(
                      manifest: manifest,
                      element: _element().copyWith(shadow: harness.shadow),
                      shadow: harness.shadow,
                      onChanged: (next) {
                        harness.changes.add(next);
                        setState(() => harness.shadow = next);
                      },
                      onEnsureDefaultShadowProfiles: () {
                        setState(() {
                          manifest =
                              ensureDefaultGroundStaticShadowProfilesForProject(
                            manifest,
                          );
                        });
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

      expect(find.text('Aucun profil Shadow disponible.'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('element-shadow-default-profiles-button')),
      );
      await tester.pump();

      expect(find.text('Aucun profil Shadow disponible.'), findsNothing);
      final popup = tester.widget<MacosPopupButton<String>>(
        find.byKey(const ValueKey('element-shadow-profile-popup')),
      );
      expect(
        popup.items!.map((item) => item.value),
        [
          'default-ground-soft-ellipse',
          'default-ground-wide-ellipse',
          'default-ground-contact-blob',
        ],
      );
    });

    testWidgets(
        'activating from null creates an active config with first profile',
        (tester) async {
      final harness = _ShadowSectionHarness();

      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(
          _catalog([_profile('tree_large'), _profile('rock_small')]),
        ),
      );

      final toggle = tester.widget<CupertinoSwitch>(
        find.byKey(const ValueKey('element-shadow-casts-switch')),
      );
      toggle.onChanged!(true);
      await tester.pump();

      expect(harness.shadow, isNotNull);
      expect(harness.shadow!.castsShadow, isTrue);
      expect(harness.shadow!.shadowProfileId, 'tree_large');
    });

    testWidgets('disabling preserves the selected profile and overrides',
        (tester) async {
      final harness = _ShadowSectionHarness(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
          offsetX: 4,
          opacity: 0.35,
        ),
      );

      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(_catalog([_profile('tree_large')])),
      );

      final toggle = tester.widget<CupertinoSwitch>(
        find.byKey(const ValueKey('element-shadow-casts-switch')),
      );
      toggle.onChanged!(false);
      await tester.pump();

      expect(harness.shadow, isNotNull);
      expect(harness.shadow!.castsShadow, isFalse);
      expect(harness.shadow!.shadowProfileId, 'tree_large');
      expect(harness.shadow!.offsetX, 4);
      expect(harness.shadow!.opacity, 0.35);
    });

    testWidgets('reset clears the shadow config instead of disabling it',
        (tester) async {
      final harness = _ShadowSectionHarness(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
      );

      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(_catalog([_profile('tree_large')])),
      );

      await tester.tap(
        find.byKey(const ValueKey('element-shadow-reset-button')),
      );
      await tester.pump();

      expect(harness.shadow, isNull);
      expect(harness.changes.last, isNull);
    });

    testWidgets('changing profile updates shadowProfileId', (tester) async {
      final harness = _ShadowSectionHarness(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
      );

      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(
          _catalog([_profile('tree_large'), _profile('rock_small')]),
        ),
      );

      final popup = tester.widget<MacosPopupButton<String>>(
        find.byKey(const ValueKey('element-shadow-profile-popup')),
      );
      popup.onChanged!('rock_small');
      await tester.pump();

      expect(harness.shadow!.shadowProfileId, 'rock_small');
    });

    testWidgets('numeric fields update and clear nullable overrides',
        (tester) async {
      final harness = _ShadowSectionHarness(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
          offsetX: 4,
        ),
      );

      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(_catalog([_profile('tree_large')])),
      );

      await tester.enterText(
        find.byKey(const ValueKey('element-shadow-offsetX-field')),
        '3.5',
      );
      await tester.pump();
      expect(harness.shadow!.offsetX, 3.5);

      await tester.enterText(
        find.byKey(const ValueKey('element-shadow-offsetX-field')),
        '',
      );
      await tester.pump();
      expect(harness.shadow!.offsetX, isNull);
    });

    testWidgets('invalid scale and opacity values are rejected',
        (tester) async {
      final harness = _ShadowSectionHarness(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
          scaleX: 1,
          opacity: 0.5,
        ),
      );

      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(_catalog([_profile('tree_large')])),
      );

      await tester.enterText(
        find.byKey(const ValueKey('element-shadow-scaleX-field')),
        '0',
      );
      await tester.pump();
      expect(find.text('Scale X doit être > 0.'), findsOneWidget);
      expect(harness.shadow!.scaleX, 1);

      await tester.enterText(
        find.byKey(const ValueKey('element-shadow-opacity-field')),
        '2',
      );
      await tester.pump();
      expect(find.text('Opacité doit être entre 0 et 1.'), findsOneWidget);
      expect(harness.shadow!.opacity, 0.5);
    });

    testWidgets('footprint block is visible only for active shadows',
        (tester) async {
      final activeHarness = _ShadowSectionHarness(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
      );
      await _pumpSection(
        tester,
        harness: activeHarness,
        manifest: _project(_catalog([_profile('tree_large')])),
      );

      expect(find.text('Empreinte au sol'), findsOneWidget);

      final nullHarness = _ShadowSectionHarness();
      await _pumpSection(
        tester,
        harness: nullHarness,
        manifest: _project(_catalog([_profile('tree_large')])),
      );

      expect(find.text('Empreinte au sol'), findsNothing);

      final disabledHarness = _ShadowSectionHarness(
        ProjectElementShadowConfig(
          castsShadow: false,
          shadowProfileId: 'tree_large',
        ),
      );
      await _pumpSection(
        tester,
        harness: disabledHarness,
        manifest: _project(_catalog([_profile('tree_large')])),
      );

      expect(find.text('Empreinte au sol'), findsNothing);
    });

    testWidgets('footprint null and partial values sync text fields',
        (tester) async {
      final emptyHarness = _ShadowSectionHarness(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
      );
      await _pumpSection(
        tester,
        harness: emptyHarness,
        manifest: _project(_catalog([_profile('tree_large')])),
      );

      expect(_fieldText(tester, 'element-shadow-footprint-anchorX-field'), '');
      expect(_fieldText(tester, 'element-shadow-footprint-anchorY-field'), '');
      expect(_fieldText(tester, 'element-shadow-footprint-width-field'), '');
      expect(_fieldText(tester, 'element-shadow-footprint-height-field'), '');

      final partialHarness = _ShadowSectionHarness(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
          footprint: StaticShadowFootprintConfig(
            anchorXRatio: 0.25,
            footprintWidthRatio: 0.5,
          ),
        ),
      );
      await _pumpSection(
        tester,
        harness: partialHarness,
        manifest: _project(_catalog([_profile('tree_large')])),
      );

      expect(
        _fieldText(tester, 'element-shadow-footprint-anchorX-field'),
        '0.25',
      );
      expect(_fieldText(tester, 'element-shadow-footprint-anchorY-field'), '');
      expect(
        _fieldText(tester, 'element-shadow-footprint-width-field'),
        '0.5',
      );
      expect(_fieldText(tester, 'element-shadow-footprint-height-field'), '');
    });

    testWidgets('footprint fields update ratios and preserve shadow fields',
        (tester) async {
      final harness = _ShadowSectionHarness(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
          offsetX: 1,
          offsetY: 2,
          scaleX: 1.2,
          scaleY: 0.8,
          opacity: 0.4,
        ),
      );
      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(_catalog([_profile('tree_large')])),
      );

      await tester.enterText(
        find.byKey(const ValueKey('element-shadow-footprint-anchorX-field')),
        '0.25',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('element-shadow-footprint-anchorY-field')),
        '0.75',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('element-shadow-footprint-width-field')),
        '0.5',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('element-shadow-footprint-height-field')),
        '0.125',
      );
      await tester.pump();

      final shadow = harness.shadow!;
      expect(shadow.castsShadow, isTrue);
      expect(shadow.shadowProfileId, 'tree_large');
      expect(shadow.offsetX, 1);
      expect(shadow.offsetY, 2);
      expect(shadow.scaleX, 1.2);
      expect(shadow.scaleY, 0.8);
      expect(shadow.opacity, 0.4);
      expect(shadow.footprint!.anchorXRatio, 0.25);
      expect(shadow.footprint!.anchorYRatio, 0.75);
      expect(shadow.footprint!.footprintWidthRatio, 0.5);
      expect(shadow.footprint!.footprintHeightRatio, 0.125);
    });

    testWidgets('invalid footprint values show errors and do not emit changes',
        (tester) async {
      final initial = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          footprintWidthRatio: 0.75,
        ),
      );
      final harness = _ShadowSectionHarness(initial);
      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(_catalog([_profile('tree_large')])),
      );
      harness.changes.clear();

      await tester.enterText(
        find.byKey(const ValueKey('element-shadow-footprint-anchorX-field')),
        '2',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('element-shadow-footprint-width-field')),
        '0',
      );
      await tester.pump();

      expect(find.text('Doit être entre 0 et 1'), findsOneWidget);
      expect(find.text('Doit être > 0'), findsOneWidget);
      expect(harness.shadow, initial);
      expect(harness.changes, isEmpty);
    });

    testWidgets('reset and clearing the last footprint field write null',
        (tester) async {
      final harness = _ShadowSectionHarness(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
          footprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
        ),
      );
      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(_catalog([_profile('tree_large')])),
      );

      await tester.enterText(
        find.byKey(const ValueKey('element-shadow-footprint-anchorX-field')),
        '',
      );
      await tester.pump();

      expect(harness.shadow!.footprint, isNull);

      harness.shadow = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
      );
      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(_catalog([_profile('tree_large')])),
      );

      await tester.tap(
        find.byKey(const ValueKey('element-shadow-footprint-reset-button')),
      );
      await tester.pump();

      expect(harness.shadow!.footprint, isNull);
      expect(harness.changes.last!.footprint, isNull);
    });

    testWidgets('existing profile toggle and number changes preserve footprint',
        (tester) async {
      final footprint = StaticShadowFootprintConfig(
        anchorXRatio: 0.25,
        anchorYRatio: 0.75,
        footprintWidthRatio: 0.5,
        footprintHeightRatio: 0.125,
      );
      final harness = _ShadowSectionHarness(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
          offsetX: 4,
          footprint: footprint,
        ),
      );
      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(
          _catalog([_profile('tree_large'), _profile('rock_small')]),
        ),
      );

      final popup = tester.widget<MacosPopupButton<String>>(
        find.byKey(const ValueKey('element-shadow-profile-popup')),
      );
      popup.onChanged!('rock_small');
      await tester.pump();
      expect(harness.shadow!.shadowProfileId, 'rock_small');
      expect(harness.shadow!.footprint, footprint);

      await tester.enterText(
        find.byKey(const ValueKey('element-shadow-offsetX-field')),
        '3.5',
      );
      await tester.pump();
      expect(harness.shadow!.offsetX, 3.5);
      expect(harness.shadow!.footprint, footprint);

      final toggle = tester.widget<CupertinoSwitch>(
        find.byKey(const ValueKey('element-shadow-casts-switch')),
      );
      toggle.onChanged!(false);
      await tester.pump();
      expect(harness.shadow!.castsShadow, isFalse);
      expect(harness.shadow!.footprint, footprint);
    });

    testWidgets('missing profile is shown as a diagnostic', (tester) async {
      final harness = _ShadowSectionHarness(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_missing',
        ),
      );

      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(ProjectShadowCatalog()),
      );

      expect(find.text('Profil manquant'), findsOneWidget);
      expect(
        find.text('Profil Shadow introuvable : tree_missing'),
        findsOneWidget,
      );
    });

    testWidgets('profile none is informational and not an error',
        (tester) async {
      final harness = _ShadowSectionHarness(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'none_profile',
        ),
      );

      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(
          _catalog([
            _profile('none_profile', mode: ShadowCasterMode.none),
          ]),
        ),
      );

      expect(find.text('Profil sans ombre'), findsOneWidget);
      expect(find.textContaining('introuvable'), findsNothing);
    });

    testWidgets('forbidden V0 fields are not rendered', (tester) async {
      final harness = _ShadowSectionHarness(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
      );

      await _pumpSection(
        tester,
        harness: harness,
        manifest: _project(_catalog([_profile('tree_large')])),
      );

      expect(find.textContaining('blur'), findsNothing);
      expect(find.textContaining('zOrder'), findsNothing);
      expect(find.textContaining('renderPass'), findsNothing);
      expect(find.textContaining('softness'), findsNothing);
      expect(find.textContaining('color'), findsNothing);
    });
  });
}

String _fieldText(WidgetTester tester, String keyName) {
  return tester
      .widget<MacosTextField>(find.byKey(ValueKey(keyName)))
      .controller!
      .text;
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required _ShadowSectionHarness harness,
  required ProjectManifest manifest,
  VoidCallback? onEnsureDefaultShadowProfiles,
}) async {
  await tester.binding.setSurfaceSize(const Size(520, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final element = _element();

  await tester.pumpWidget(
    MacosTheme(
      data: MacosThemeData.light(),
      child: MaterialApp(
        home: CupertinoPageScaffold(
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: SizedBox(
                  width: 460,
                  child: ElementShadowSection(
                    manifest: manifest,
                    element: element.copyWith(shadow: harness.shadow),
                    shadow: harness.shadow,
                    onChanged: (next) {
                      harness.changes.add(next);
                      setState(() => harness.shadow = next);
                    },
                    onEnsureDefaultShadowProfiles:
                        onEnsureDefaultShadowProfiles,
                  ),
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

final class _ShadowSectionHarness {
  _ShadowSectionHarness([this.shadow]);

  ProjectElementShadowConfig? shadow;
  final List<ProjectElementShadowConfig?> changes =
      <ProjectElementShadowConfig?>[];
}

ProjectManifest _project(ProjectShadowCatalog catalog) {
  return ProjectManifest(
    name: 'Shadow UI test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    elementCategories: const <ProjectElementCategory>[],
    elements: const <ProjectElementEntry>[],
    surfaceCatalog: ProjectSurfaceCatalog(),
    shadowCatalog: catalog,
  );
}

ProjectElementEntry _element({
  ElementCollisionProfile? collisionProfile,
}) {
  return ProjectElementEntry(
    id: 'tree_element',
    name: 'Tree element',
    tilesetId: 'tileset_main',
    categoryId: 'decor',
    frames: const <TilesetVisualFrame>[
      TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
    ],
    collisionProfile: collisionProfile,
  );
}

ProjectShadowCatalog _catalog(List<ProjectShadowProfile> profiles) {
  return ProjectShadowCatalog(profiles: profiles);
}

ProjectShadowProfile _profile(
  String id, {
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
}) {
  return ProjectShadowProfile(
    id: id,
    name: '$id shadow',
    mode: mode,
    renderPass: renderPass,
  );
}
