import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_route_presentation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
      'composes real slots and forwards navigation and action callbacks',
      (tester) async {
    final opened = <NarrativeStudioDestination>[];
    var mapsOpenCount = 0;
    var actionCount = 0;
    var documentActionCount = 0;

    await _pumpShell(
      tester,
      selectedDestination: NarrativeStudioDestination.events,
      onSelectDestination: opened.add,
      onOpenMaps: () => mapsOpenCount += 1,
      project: const PokeMapCard(child: Text('Selbrume Demo')),
      status: const Text('Tous les changements enregistrés'),
      documentActions: PokeMapIconButton(
        key: const ValueKey('narrative-document-save-action'),
        onPressed: () => documentActionCount += 1,
        tooltip: 'Enregistrer le document',
        icon: const Icon(Icons.save_outlined),
      ),
      workspace: NarrativeStudioWorkspacePage(
        presentation: const NarrativeStudioRoutePresentation(
          destination: NarrativeStudioDestination.events,
          label: 'Event Builder',
          breadcrumbLabels: ['Événements'],
        ),
        actions: [
          PokeMapButton(
            key: const ValueKey('narrative-studio-contract-action'),
            onPressed: () => actionCount += 1,
            size: PokeMapButtonSize.compact,
            child: const Text('Nouvel événement'),
          ),
        ],
        body: const Text('Event workspace'),
      ),
    );

    for (final key in <ValueKey<String>>[
      narrativeStudioProductShellKey,
      narrativeStudioProductShellHeaderKey,
      narrativeStudioProductShellProjectKey,
      narrativeStudioProductShellNavigationKey,
      narrativeStudioProductShellWorkspaceKey,
      narrativeStudioWorkspaceContextKey,
    ]) {
      expect(find.byKey(key), findsOneWidget);
    }
    expect(find.text('Narrative Studio  /  Événements'), findsOneWidget);
    expect(find.text('Event workspace'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('narrative-studio-product-nav-validator'),
      ),
      findsOneWidget,
    );
    final defaultMark = tester.widget<Image>(
      find.descendant(
        of: find.byKey(narrativeStudioProductShellHeaderKey),
        matching: find.byType(Image),
      ),
    );
    expect(
      (defaultMark.image as AssetImage).assetName,
      'assets/branding/pokemap_event_builder_mark.png',
    );
    final storylinesTop = tester.getTopLeft(
      find.byKey(
        const ValueKey('narrative-studio-product-nav-storylines'),
      ),
    );
    final mapsTop = tester.getTopLeft(
      find.byKey(narrativeStudioProductNavigationMapsKey),
    );
    final scenesTop = tester.getTopLeft(
      find.byKey(const ValueKey('narrative-studio-product-nav-scenes')),
    );
    expect(storylinesTop.dy, lessThan(mapsTop.dy));
    expect(mapsTop.dy, lessThan(scenesTop.dy));

    await tester.tap(
      find.byKey(const ValueKey('narrative-studio-product-nav-overview')),
    );
    await tester.tap(
      find.byKey(const ValueKey('narrative-studio-product-nav-validator')),
    );
    await tester.tap(
      find.byKey(narrativeStudioProductNavigationMapsKey),
    );
    await tester.tap(
      find.byKey(const ValueKey('narrative-studio-contract-action')),
    );
    await tester.tap(
      find.byKey(const ValueKey('narrative-document-save-action')),
    );
    await tester.pump();

    expect(opened, const [
      NarrativeStudioDestination.overview,
      NarrativeStudioDestination.validator,
    ]);
    expect(mapsOpenCount, 1);
    expect(actionCount, 1);
    expect(documentActionCount, 1);
  });

  testWidgets('omits optional project and status slots without reserved space',
      (tester) async {
    await _pumpShell(
      tester,
      selectedDestination: NarrativeStudioDestination.overview,
    );

    final navigationWithoutProject = tester.getTopLeft(
      find.byKey(narrativeStudioProductShellNavigationKey),
    );
    expect(find.byKey(narrativeStudioProductShellProjectKey), findsNothing);
    expect(find.byKey(narrativeStudioProductNavigationStatusKey), findsNothing);

    await _pumpShell(
      tester,
      selectedDestination: NarrativeStudioDestination.overview,
      project: const PokeMapCard(child: Text('Projet')),
    );

    final navigationWithProject = tester.getTopLeft(
      find.byKey(narrativeStudioProductShellNavigationKey),
    );
    expect(find.byKey(narrativeStudioProductShellProjectKey), findsOneWidget);
    expect(
      navigationWithProject.dy - navigationWithoutProject.dy,
      moreOrLessEquals(52),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes Map Events as a typed child of Events', (tester) async {
    final opened = <NarrativeStudioRouteLocation>[];
    final selected = NarrativeStudioRouteLocation.events(
      childRoute: NarrativeStudioChildRoute.mapEvents,
    );

    await _pumpShell(
      tester,
      selectedDestination: NarrativeStudioDestination.events,
      selectedLocation: selected,
      onSelectLocation: opened.add,
    );

    expect(
      find.byKey(const ValueKey('narrative-studio-product-nav-events')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('narrative-studio-product-nav-event-builder')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('narrative-studio-product-nav-map-events')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('narrative-studio-product-nav-event-builder')),
    );
    await tester.tap(
      find.byKey(const ValueKey('narrative-studio-product-nav-map-events')),
    );
    await tester.pump();

    expect(opened, <NarrativeStudioRouteLocation>[
      NarrativeStudioRouteLocation.events(),
      NarrativeStudioRouteLocation.events(
        childRoute: NarrativeStudioChildRoute.mapEvents,
      ),
    ]);
  });
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required NarrativeStudioDestination selectedDestination,
  NarrativeStudioRouteLocation? selectedLocation,
  ValueChanged<NarrativeStudioRouteLocation>? onSelectLocation,
  ValueChanged<NarrativeStudioDestination>? onSelectDestination,
  VoidCallback? onOpenMaps,
  Widget? project,
  Widget? status,
  Widget? documentActions,
  Widget? workspace,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 941);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: NarrativeStudioProductShell(
          selectedDestination: selectedDestination,
          selectedLocation: selectedLocation,
          onSelectLocation: onSelectLocation,
          onSelectDestination: onSelectDestination ?? (_) {},
          onOpenMaps: onOpenMaps ?? () {},
          project: project,
          status: status,
          documentActions: documentActions,
          workspace: workspace ??
              const NarrativeStudioWorkspacePage(
                presentation: NarrativeStudioRoutePresentation(
                  destination: NarrativeStudioDestination.overview,
                  label: 'Aperçu',
                  breadcrumbLabels: ['Aperçu'],
                ),
                body: Text('Overview workspace'),
              ),
        ),
      ),
    ),
  );
  await tester.pump();
}
