import 'package:avelune_studio/presentation/features/map_workspace/map_library_navigator.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  testWidgets('inactive map exposes actions without activating its document', (
    tester,
  ) async {
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: MapLibraryNavigator(
              project: const ProjectManifest(
                name: 'Bibliothèque',
                tilesets: [],
                maps: [
                  ProjectMapEntry(
                    id: 'inactive',
                    name: 'Carte fermée',
                    relativePath: 'maps/inactive.json',
                  ),
                ],
              ),
              activeMapId: null,
              dirtyMapIds: const {},
              onActivate: (_) => activations++,
              onOrganize: null,
              onRenameMap: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('map-library-actions-inactive')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('map-library-actions-inactive')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Renommer…'), findsOneWidget);
    expect(activations, 0);
  });
}
