import 'package:avelune_studio/presentation/features/home/studio_home_screen.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_panel.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';

void main() {
  testWidgets('all maps page shows nested folders and opens any map', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(loadDesktopCaptureFonts);
    const entries = [
      ProjectMapEntry(
        id: 'a',
        name: 'Gare',
        relativePath: 'a.json',
        groupId: 'outside',
      ),
      ProjectMapEntry(
        id: 'b',
        name: 'Route',
        relativePath: 'b.json',
        groupId: 'outside',
      ),
      ProjectMapEntry(
        id: 'c',
        name: 'Boutique',
        relativePath: 'c.json',
        groupId: 'inside',
      ),
      ProjectMapEntry(
        id: 'd',
        name: 'Café',
        relativePath: 'd.json',
        groupId: 'inside',
      ),
      ProjectMapEntry(
        id: 'e',
        name: 'Maison',
        relativePath: 'e.json',
        groupId: 'inside',
      ),
      ProjectMapEntry(id: 'f', name: 'Divers', relativePath: 'f.json'),
      ProjectMapEntry(
        id: 'g',
        name: 'Place',
        relativePath: 'g.json',
        groupId: 'region',
      ),
    ];
    const groups = [
      ProjectMapGroup(
        id: 'region',
        name: 'Hanazuki',
        type: MapGroupType.village,
      ),
      ProjectMapGroup(
        id: 'outside',
        name: 'Extérieurs',
        type: MapGroupType.route,
        parentGroupId: 'region',
      ),
      ProjectMapGroup(
        id: 'inside',
        name: 'Intérieurs',
        type: MapGroupType.facility,
        parentGroupId: 'region',
      ),
    ];
    final opened = <String>[];
    final captureKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: RepaintBoundary(
          key: captureKey,
          child: StudioHomeScreen(
            projectName: 'Le Train',
            onOpen: () {},
            onDestination: (_) {},
            onRecent: (_) {},
            onRemoveRecent: (_) {},
            maps: [
              for (final entry in entries) (id: entry.id, name: entry.name),
            ],
            mapLibrary: const ProjectManifest(
              name: 'Le Train',
              maps: entries,
              groups: groups,
              tilesets: [],
            ),
            onMap: opened.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Voir toutes les cartes (7)'));
    await tester.tap(find.text('Voir toutes les cartes (7)'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-all-maps-page')), findsOneWidget);
    expect(find.text('Toutes les cartes (7)'), findsOneWidget);
    expect(find.text('Hanazuki'), findsOneWidget);
    expect(find.text('Extérieurs'), findsOneWidget);
    expect(find.text('Intérieurs'), findsOneWidget);
    await captureM3Widget(tester, captureKey, 'home-all-maps');
    final parentPanel = find.ancestor(
      of: find.byKey(const ValueKey('home-map-card-g')),
      matching: find.byType(StudioPanel),
    );
    expect(tester.widget<StudioPanel>(parentPanel).title, 'Hanazuki');
    final allMaps = find.byKey(const ValueKey('home-all-maps-page'));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home-map-card-f')),
      300,
      scrollable: find.descendant(
        of: allMaps,
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Sans dossier'), findsOneWidget);
    final openLast = find.descendant(
      of: find.byKey(const ValueKey('home-map-card-f')),
      matching: find.text('Ouvrir'),
    );
    await tester.ensureVisible(openLast);
    await tester.pumpAndSettle();
    await tester.tap(openLast);
    expect(opened, ['f']);
    tester
        .state<ScrollableState>(
          find.descendant(of: allMaps, matching: find.byType(Scrollable)),
        )
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retour à l’accueil'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-all-maps-page')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
