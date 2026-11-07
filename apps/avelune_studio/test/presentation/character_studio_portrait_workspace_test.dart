import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/characters/character_studio_controller.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_tabs.dart';

import '../support/m2_ui_fixture.dart';
import '../support/map_tool_menu.dart';
import '../support/resource_family_gestures.dart';

void main() {
  testWidgets(
    'portrait import binds a real image and survives independent reopen',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(
        () => M2UiFixture.create(tester),
      ))!;
      addTearDown(fixture.dispose);
      await tester.pumpWidget(fixture.app(tester));
      await pumpIo(tester);
      await chooseMapExtraTool(tester, 'Gérer les ressources');
      await pumpIo(tester);
      await selectResourceFamily(tester, ResourceLibraryFamily.images);
      await tester.tap(find.text('Importer une image'));
      await pumpIo(tester);
      await tester.tap(find.text('Importer').last);
      await pumpIo(tester);
      await tester.tap(find.byKey(const ValueKey('resource-import-dismiss')));
      await pumpIo(tester);
      await openResourceCharacters(tester);
      await tester.tap(find.text('Nouveau personnage'));
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextField, 'Nom'), 'Élia');
      await tester.tap(find.text('Créer'));
      await pumpIo(tester);
      final navigation = tester
          .widget<ResourceWorkspacePane>(find.byType(ResourceWorkspacePane))
          .navigation;
      final tabs = find.byWidgetPredicate(
        (widget) => widget is StudioTabs<CharacterStudioSection>,
      );
      expect(
        find.descendant(of: tabs, matching: find.text('Bibliothèque')),
        findsNothing,
      );
      expect(
        find.descendant(of: tabs, matching: find.text('Identité')),
        findsOneWidget,
      );
      await tester.tap(find.text('Portraits'));
      await tester.pump();
      expect(
        find.textContaining('communes à tous les personnages'),
        findsOneWidget,
      );
      expect(find.textContaining('état'), findsNothing);
      await tester.tap(find.text('Créer une expression'));
      await tester.pump();
      expect(find.text('Nouvelle expression'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom de l’expression'),
        'Souriante',
      );
      await tester.tap(find.text('Créer l’expression'));
      await pumpIo(tester);
      await tester.tap(find.text('Importer un portrait'));
      await pumpIo(tester);
      await tester.tap(find.text('Importer').last);
      await pumpIo(tester);
      expect(navigation.characters.error, isNull);
      final saved = navigation.workspace.project!;
      final character = saved.characters.firstWhere(
        (entry) => entry.name == 'Élia',
      );
      final state = saved.characterStudioCatalog.portraitStates.single;
      expect(state.displayName, 'Souriante');
      expect(character.portraits.single.portraitStateId, state.id);
      expect(character.portraits.single.assetId, isNotEmpty);
      await fixture.capture(tester, 'character-studio-portraits');
      final reopened = await tester.runAsync(
        () => LocalMapWorkspaceAdapter().loadProject(fixture.session),
      );
      expect(
        reopened!.characters
            .firstWhere((entry) => entry.id == character.id)
            .portraits,
        character.portraits,
      );
      final portraitBytes = await tester.runAsync(
        () => LocalDialogueAdapter(
          session: fixture.session,
          mapAdapter: fixture.port,
        ).readPortrait(character.id, state.id),
      );
      expect(portraitBytes, isNotNull);
      expect(portraitBytes, isNotEmpty);
      await tester.pumpWidget(const SizedBox());
      await pumpIo(tester);
    },
  );
}
