import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_commit_field.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart' show writeExampleProject;
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/map_workspace_fixture.dart' show WorkspaceTestVisuals;

const departure = 'jardin';

Finder menu() => find.byKey(const ValueKey('map-context-menu'));
Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is StudioCommitField && widget.label == label,
);
Finder inMenu(String label) =>
    find.descendant(of: menu(), matching: find.text(label));

void main() {
  late Directory directory;
  late ProjectSession session;
  late MapWorkspaceController controller;

  setUp(() async {
    final temporary = await Directory.systemTemp.createTemp('avelune_ctxh_');
    directory = Directory(await temporary.resolveSymbolicLinks());
    await writeExampleProject(directory);
    session = ProjectSession(
      sessionId: directory.path,
      name: 'Menu sur le vrai hôte',
      directoryPath: directory.path,
    );
  });
  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  /// The real screen, with its own owners and ports, on a temporary project.
  Future<MapEntity> openHost(
    WidgetTester tester, {
    Size size = const Size(1500, 1000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    controller = MapWorkspaceController(session, LocalMapWorkspaceAdapter());
    late MapEntity sign;
    await tester.runAsync(() async {
      await controller.initialize();
      await controller.activate(
        controller.project!.maps.firstWhere((entry) => entry.id == departure),
      );
      sign = MapEntityEditingCommands(
        controller.active!,
        controller.project!,
      ).place(MapEntityKind.sign, const GridPos(x: 5, y: 5));
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: MapWorkspaceScreen(
          controller: controller,
          loadVisuals: (_, _) async => WorkspaceTestVisuals(),
          runtimeBuilder: (entry, revision, close) => const SizedBox(),
          onClose: () async {},
          registerExitGuard: (_) {},
        ),
      ),
    );
    await pumpIo(tester, frames: 10);
    return sign;
  }

  /// The screen point of a cell. The canvas is fitted to the space it gets,
  /// so a narrow window shrinks the tiles: the size is read from the rendered
  /// rectangle, never assumed from the project settings.
  Offset cellAt(WidgetTester tester, int x, int y) {
    final rect = tester.getRect(find.byKey(const ValueKey('map-canvas')));
    final size = controller.active!.current.size;
    return rect.topLeft +
        Offset(
          (x + .4) * rect.width / size.width,
          (y + .4) * rect.height / size.height,
        );
  }

  Future<void> rightClickCell(WidgetTester tester, int x, int y) async {
    final gesture = await tester.startGesture(
      cellAt(tester, x, y),
      buttons: kSecondaryButton,
    );
    await gesture.up();
    await pumpIo(tester, frames: 4);
  }

  Future<void> settleSave(WidgetTester tester) async {
    for (var i = 0; i < 240 && controller.active!.dirty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(controller.active!.dirty, isFalse, reason: controller.error);
  }

  testWidgets(
    'the real screen opens the menu and deletes through it',
    (tester) async {
      final sign = await openHost(tester);

      await rightClickCell(tester, 5, 5);
      expect(menu(), findsOneWidget);
      expect(inMenu('Panneau'), findsWidgets);

      await tester.tap(inMenu('Supprimer'));
      await pumpIo(tester, frames: 4);

      expect(menu(), findsNothing);
      expect(
        controller.active!.current.entities.where((e) => e.id == sign.id),
        isEmpty,
        reason: 'the deletion went through the screen, not a harness copy',
      );

      await tester.tap(find.byKey(const ValueKey('Enregistrer')));
      await pumpIo(tester, frames: 4);
      await settleSave(tester);

      await tester.runAsync(() async {
        final reopened = MapWorkspaceController(
          session,
          LocalMapWorkspaceAdapter(),
        );
        await reopened.initialize();
        await reopened.activate(
          reopened.project!.maps.firstWhere((entry) => entry.id == departure),
        );
        expect(
          reopened.active!.current.entities.where((e) => e.id == sign.id),
          isEmpty,
          reason: 'what the menu removed survives the round trip to disk',
        );
        reopened.dispose();
      });
      controller.dispose();
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'opening and closing the menu writes nothing',
    (tester) async {
      await openHost(tester);
      final before = controller.active!.current;
      final steps = controller.active!.undoCount;

      await rightClickCell(tester, 5, 5);
      expect(menu(), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await pumpIo(tester, frames: 4);

      expect(menu(), findsNothing);
      expect(controller.active!.current, before);
      expect(controller.active!.undoCount, steps);
      controller.dispose();
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'Propriétés reaches the inspector even when it is compact',
    (tester) async {
      await openHost(tester, size: const Size(900, 900));
      expect(
        find.byType(Dialog),
        findsNothing,
        reason: 'the compact inspector is not open on its own',
      );

      await rightClickCell(tester, 5, 5);
      await tester.tap(inMenu('Propriétés'));
      await pumpIo(tester, frames: 6);

      expect(
        find.descendant(of: find.byType(Dialog), matching: field('Titre')),
        findsOneWidget,
        reason: 'the sign inspector is reachable on a narrow window',
      );
      controller.dispose();
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'a story zone without interaction says so instead of opening',
    (tester) async {
      await openHost(tester);
      await tester.runAsync(() async {
        final document = controller.active!;
        document.commit(
          document.current.copyWith(
            triggers: [
              ...document.current.triggers,
              const MapTrigger(
                id: 'quai',
                name: 'Quai',
                type: TriggerType.event,
                area: MapRect(
                  pos: GridPos(x: 8, y: 3),
                  size: GridSize(width: 3, height: 3),
                ),
              ),
            ],
          ),
        );
      });
      await pumpIo(tester, frames: 4);

      await rightClickCell(tester, 9, 4);
      expect(inMenu('Ouvrir son interaction'), findsOneWidget);
      await tester.tap(inMenu('Ouvrir son interaction'));
      await pumpIo(tester, frames: 6);

      // Not 'Aucune interaction': the trigger inspector already says that.
      expect(
        find.textContaining('Tracez-la depuis'),
        findsOneWidget,
        reason: 'opening says the zone has none, it never invents one',
      );
      expect(
        controller.active!.current.triggers.where((t) => t.id == 'quai'),
        isNotEmpty,
      );
      controller.dispose();
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
