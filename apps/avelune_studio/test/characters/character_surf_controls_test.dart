import 'package:avelune_studio/presentation/features/characters/character_studio_controller.dart';
import 'package:avelune_studio/presentation/features/characters/character_studio_dedicated_only_panel.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets(
    'dedicated animation picker exposes climbing and all Surf poses',
    (tester) async {
      const project = ProjectManifest(
        name: 'Test',
        maps: [],
        tilesets: [],
        characters: [
          ProjectCharacterEntry(
            id: 'hero',
            name: 'Héroïne',
            tilesetId: 'sheet',
            frameWidth: 1,
            frameHeight: 1,
          ),
        ],
      );
      final controller = CharacterStudioController(
        project: () => project,
        mutate: (_, _) async => project,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: AnimatedBuilder(
              animation: controller,
              builder: (context, _) => CharacterStudioDedicatedOnlyPanel(
                hasAtlas: false,
                draft: controller.selectedDraft!,
                controller: controller,
                visuals: WorkspaceTestVisuals(),
                onImport: (_, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Marche'));
      await tester.pumpAndSettle();
      expect(find.text('Échelle'), findsOneWidget);
      expect(find.text('Surf au repos'), findsOneWidget);
      expect(find.text('Surf en déplacement'), findsOneWidget);
      expect(find.text('Entrée dans l’eau'), findsOneWidget);
      expect(find.text('Sortie de l’eau'), findsOneWidget);
      await tester.tap(find.text('Surf en déplacement'));
      await tester.pumpAndSettle();
      expect(controller.animationState.name, 'surf');
      expect(controller.selectedDraft!.dirty, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
