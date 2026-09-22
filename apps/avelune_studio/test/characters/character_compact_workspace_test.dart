import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/characters/character_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_shortcuts.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import '../support/map_workspace_fixture.dart';
import 'character_editing_test.dart' show guide;

void main() {
  testWidgets(
    'enlarged text keeps palette and character inspector reachable over the map',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      await controller.initialize();
      controller.project = controller.project!.copyWith(characters: [guide]);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: MapWorkspaceScreen(
            controller: controller,
            loadVisuals: (_, _) async => WorkspaceTestVisuals(),
            runtimeBuilder: (_, _, _) => const SizedBox(),
            onClose: () async {},
            registerExitGuard: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Palette'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tap(find.text('Personnages'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('character-guide')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      final canvas = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('map-canvas')),
      );
      await tester.tapAt(
        canvas.localToGlobal(const Offset(6 * 32 + 16, 6 * 32 + 16)),
      );
      await tester.pump();
      expect(
        controller.active!.current.entities.single.npc!.characterId,
        guide.id,
      );
      await tester.tap(find.byTooltip('Inspecteur'));
      await tester.pumpAndSettle();
      expect(find.byType(CharacterInspector), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('character-name')));
      await tester.enterText(
        find.byKey(const ValueKey('character-name')),
        'Chef compact',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(
        controller.active!.current.entities.single.npc!.displayName,
        'Chef compact',
      );
      await tester.ensureVisible(find.text('Écrire son interaction'));
      expect(find.text('Écrire son interaction').hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Retour à la carte'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'keyboard deletion guards pending stories and duplication keeps independent instances',
    () async {
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      await controller.initialize();
      controller.project = controller.project!.copyWith(characters: [guide]);
      addTearDown(controller.dispose);
      final commands = CharacterEditingCommands(
        controller.active!,
        controller.project!,
      );
      final entity = commands.place(guide, const GridPos(x: 3, y: 4));
      final view = MapWorkspaceViewState()
        ..select(controller.active!, MapSelectionFamily.character, entity.id);
      addTearDown(view.dispose);
      controller.historyGuard = (_, _) => 'Interaction non enregistrée';
      var saves = 0;
      final bindings = workspaceShortcuts(
        controller,
        view,
        (action) => action(),
        onSave: () => saves++,
      );
      bindings[const SingleActivator(LogicalKeyboardKey.delete)]!();
      expect(controller.active!.current.entities, hasLength(1));
      expect(controller.active!.error, 'Interaction non enregistrée');
      bindings.entries
          .firstWhere(
            (entry) =>
                entry.key is SingleActivator &&
                (entry.key as SingleActivator).trigger ==
                    LogicalKeyboardKey.keyD &&
                (entry.key as SingleActivator).meta,
          )
          .value();
      expect(controller.active!.current.entities, hasLength(2));
      expect(
        view.selectedFor(
          controller.active!.current.id,
          MapSelectionFamily.character,
        ),
        isNot(entity.id),
      );
      controller.historyGuard = null;
      bindings[const SingleActivator(LogicalKeyboardKey.delete)]!();
      expect(controller.active!.current.entities.single.id, entity.id);
      bindings.entries
          .firstWhere(
            (entry) =>
                entry.key is SingleActivator &&
                (entry.key as SingleActivator).trigger ==
                    LogicalKeyboardKey.keyS &&
                (entry.key as SingleActivator).meta,
          )
          .value();
      expect(saves, 1);
    },
  );
}
