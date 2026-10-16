import 'package:avelune_studio/presentation/features/map_workspace/map_escape_rope_settings.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  testWidgets('guided dungeon picker and restriction save typed map metadata', (
    tester,
  ) async {
    Map<String, Object?>? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showEscapeRopeMapSettings(
                context,
                map: const MapData(
                  id: 'map',
                  name: 'Grotte',
                  size: GridSize(width: 8, height: 6),
                ),
                project: const ProjectManifest(
                  name: 'Rope',
                  maps: [],
                  tilesets: [],
                  groups: [
                    ProjectMapGroup(
                      id: 'dungeon',
                      name: 'Montagne',
                      type: MapGroupType.dungeon,
                    ),
                  ],
                ),
                save: (values) async {
                  saved = values;
                  return null;
                },
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aucun donjon'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Montagne').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(StudioToggleRow).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(StudioToggleRow).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(saved, {
      'mapId': 'map',
      'escapeRopeDungeonId': 'dungeon',
      'allowEscapeRope': false,
      'allowBicycle': false,
    });
  });
}
