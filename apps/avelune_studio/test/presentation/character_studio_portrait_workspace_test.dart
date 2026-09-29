import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';

import '../support/m2_ui_fixture.dart';
import '../support/map_tool_menu.dart';

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
      await tester.tap(find.text('Importer une image'));
      await pumpIo(tester);
      await tester.tap(find.text('Importer').last);
      await pumpIo(tester);
      await tester.tap(find.text('Retour aux ressources'));
      await pumpIo(tester);
      await tester.tap(find.text('Personnages'));
      await pumpIo(tester);
      await tester.tap(find.text('Nouveau personnage'));
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextField, 'Nom'), 'Élia');
      await tester.tap(find.text('Créer'));
      await pumpIo(tester);
      final navigation = tester
          .widget<ResourceWorkspacePane>(find.byType(ResourceWorkspacePane))
          .navigation;
      await tester.tap(find.text('Portraits'));
      await tester.pump();
      await tester.tap(find.text('Ajouter un état'));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom de l’état'),
        'Souriante',
      );
      await tester.tap(find.text('Créer l’état'));
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
