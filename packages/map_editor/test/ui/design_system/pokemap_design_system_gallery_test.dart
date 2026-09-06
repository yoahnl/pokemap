import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/gallery/pokemap_design_system_gallery.dart';
import 'package:map_player_ui/personalization_preview.dart';

void main() {
  testWidgets('opens Player primitives in the existing gallery only',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: PokeMapTheme.dark(),
      home: const PokeMapDesignSystemGallery(),
    ));
    expect(find.byType(PlayerMenuPrimitivesGallery), findsNothing);
    await tester.tap(find.text('Player menus'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PlayerMenuPrimitivesGallery), findsOneWidget);
    await tester.tap(find.text('Opaque'));
    await tester.tap(find.text('Contraste'));
    await tester.tap(find.text('Mouvements réduits'));
    await tester.tap(find.text('Texte ×1.0'));
    await tester.pump();
    await tester.tap(find.text('Texte ×1.5'));
    await tester.tap(find.text('Fond : sombre'));
    await tester.pump(const Duration(milliseconds: 300));
    final scene = tester.widget<PlayerMenuPrimitivesGallery>(
        find.byType(PlayerMenuPrimitivesGallery));
    expect(scene.opaque, isTrue);
    expect(scene.highContrast, isTrue);
    expect(scene.reducedMotion, isTrue);
    expect(scene.textScale, 2);
    expect(scene.backdrop, PlayerMenuGalleryBackdrop.light);
    expect(find.text('Retour').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Dark'));
    await tester.pump();
    expect(find.byType(PlayerMenuPrimitivesGallery), findsNothing);
    expect(find.text('Buttons (PokeMapButton)'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  group('PokeMapDesignSystemGallery Widget Tests', () {
    Widget buildTestWidget({
      required ThemeData theme,
      required Widget child,
    }) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('Gallery pumps successfully under light theme', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapDesignSystemGallery(),
        ),
      );

      // Verify header title
      expect(find.text('PokeMap Design System Gallery'), findsOneWidget);
      expect(find.text('Buttons (PokeMapButton)'), findsWidgets);
      expect(find.text('Icon Buttons (PokeMapIconButton)'), findsWidgets);
    });

    testWidgets('Gallery pumps successfully under dark theme', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.dark(),
          child: const PokeMapDesignSystemGallery(),
        ),
      );

      expect(find.text('PokeMap Design System Gallery'), findsOneWidget);
      expect(find.text('Status Badges (PokeMapBadge)'), findsWidgets);
    });

    testWidgets('Gallery displays all main component category sections',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapDesignSystemGallery(),
        ),
      );

      // Verify the presence of all section headers
      expect(find.text('Buttons (PokeMapButton)'), findsWidgets);
      expect(find.text('Icon Buttons (PokeMapIconButton)'), findsWidgets);
      expect(find.text('Status Badges (PokeMapBadge)'), findsWidgets);
      expect(find.text('Cards & Panels (PokeMapCard / PokeMapPanel)'),
          findsWidgets);
      expect(
          find.text('Toolbar Surfaces (PokeMapToolbarSurface)'), findsWidgets);
      expect(find.text('Empty States (PokeMapEmptyState)'), findsWidgets);
      expect(find.text('Sidebar Items (PokeMapSidebarItem)'), findsWidgets);
    });

    testWidgets(
        'Gallery renders widget variants and states correctly without layout exceptions',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapDesignSystemGallery(),
        ),
      );

      // Verify specific variant/state texts are visible
      expect(find.text('Primary Small'), findsWidgets);
      expect(find.text('Ghost Action'), findsWidgets);
      expect(find.text('Success'), findsWidgets);
      expect(find.text('Secondary'), findsWidgets);
      expect(find.text('Narrative Segment'), findsWidgets);
      expect(find.text('Combat Rule'), findsWidgets);
      expect(find.text('Grid Map Accent'), findsWidgets);
      expect(find.text('No Assets Imported Yet'), findsWidgets);
      expect(find.text('Map Editor Grid (Active)'), findsWidgets);
    });
  });
}
