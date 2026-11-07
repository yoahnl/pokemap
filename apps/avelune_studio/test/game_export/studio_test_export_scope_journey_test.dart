import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/verification/application/test_launch_preflight.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_actions.dart';
import 'package:avelune_studio/presentation/features/verification/test_launch_dialog.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('the preflight separates saved drafts, blockers and the test scope', () {
    final map = TestLaunchPreflight(
      scope: TestLaunchScope.map,
      mapName: 'Bourg Geon',
      saves: const ['Carte « Bourg Geon »', 'Ambiance de la carte'],
      blockers: const [],
    );
    expect(map.canLaunch, isTrue);
    expect(map.title, 'Tester cette carte');
    expect(map.scopeNote, contains('en mémoire'));
    final game = TestLaunchPreflight(
      scope: TestLaunchScope.game,
      mapName: 'Bourg Geon',
      saves: const [],
      blockers: const [TestLaunchBlocker('Dialogues', 'Histoire › Dialogues')],
    );
    expect(game.canLaunch, isFalse);
    expect(game.title, 'Tester le jeu');
    expect(game.scopeNote, contains('joueurs ne sont pas touchées'));
  });

  testWidgets(
    'a blocking draft disables the launch and names where to resolve it',
    (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async => result = await showTestLaunchDialog(
                    context,
                    TestLaunchPreflight(
                      scope: TestLaunchScope.game,
                      mapName: 'Bourg Geon',
                      saves: const ['Scènes'],
                      blockers: const [
                        TestLaunchBlocker('Dialogues', 'Histoire › Dialogues'),
                      ],
                    ),
                  ),
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text('Tester le jeu'), findsOneWidget);
      expect(find.textContaining('Histoire › Dialogues'), findsOneWidget);
      expect(find.textContaining('Scènes'), findsOneWidget);
      final confirm = tester.widget<ButtonStyleButton>(
        find.descendant(
          of: find.byKey(const ValueKey('confirm-reviewed-plan')),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      expect(confirm.onPressed, isNull);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    },
  );

  testWidgets(
    'the map test saves its drafts only after confirmation and returns without reloading',
    (tester) async {
      final port = WorkspaceMemoryPort();
      final controller = MapWorkspaceController(workspaceSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final document = controller.active!;
      document.commit(document.current.copyWith(name: 'Clairière modifiée'));
      TestLaunchPreflight? reviewed;
      var confirm = false;
      var launches = 0;
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Builder(
            builder: (value) {
              context = value;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );
      final actions = WorkspaceActions(
        controller: controller,
        context: () => context,
        mounted: () => true,
        changed: () {},
        resources: () => null,
        narrative: () => null,
        confirmLaunch: (preflight) async {
          reviewed = preflight;
          return confirm;
        },
        runtimeBuilder: (entry, revision, close) {
          launches++;
          WidgetsBinding.instance.addPostFrameCallback((_) => close());
          return const SizedBox();
        },
      );
      await actions.test();
      expect(reviewed!.scope, TestLaunchScope.map);
      expect(reviewed!.saves, contains('Carte « Clairière »'));
      expect(port.writes, 0);
      expect(launches, 0);
      expect(document.dirty, isTrue);
      final catalogs = port.catalogs;
      confirm = true;
      final running = actions.test();
      await tester.pumpAndSettle();
      await running;
      expect(port.writes, 1);
      expect(launches, 1);
      expect(identical(controller.active, document), isTrue);
      expect(port.catalogs, catalogs);
      expect(actions.testing, isFalse);
    },
  );
}
