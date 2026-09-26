import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/home/data/memory_recent_projects_adapter.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/features/project_session/project_session_screen.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import '../support/m2_ui_fixture.dart';
import '../support/capture_m3_widget.dart';

void main() {
  testWidgets('UI02 real map, overlap, shared home and responsive viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(() => M2UiFixture.create(tester)))!;
    final imported = (await tester.runAsync(
      () => fixture.resources.importImage(
        ResourceImageImport(
          sourcePath: '${fixture.directory.path}/assets/atelier.png',
          name: 'Atlas de l’atelier',
          tileWidth: 16,
          tileHeight: 16,
        ),
      ),
    ))!;
    fixture.controller.acceptResources(imported.before, imported.manifest);
    final session = ProjectSessionController(_Session(fixture.session));
    final capture = GlobalKey();
    var scale = 1.0;
    Widget app() => MaterialApp(
      theme: studioTheme(),
      home: MediaQuery(
        data: MediaQueryData(
          size: tester.view.physicalSize,
          textScaler: TextScaler.linear(scale),
        ),
        child: RepaintBoundary(
          key: capture,
          child: ProjectSessionScreen(
            session: session,
            recentProjects: MemoryRecentProjectsAdapter(),
            chooseDirectory: () async => fixture.directory.path,
            workspaceBuilder: (_, close) => Builder(
              builder: (context) => MapWorkspaceScreen(
                controller: fixture.controller,
                home: StudioHomeScope.of(context),
                resourcePort: WidgetResourcePort(fixture.resources, tester),
                loadVisuals: (session, manifest) =>
                    StudioMapResources.load(session, manifest),
                runtimeBuilder: (entry, revision, close) => StudioPlaytestView(
                  session: fixture.session,
                  entry: entry,
                  expectedRevision: revision,
                  port: fixture.port,
                  onClose: close,
                ),
                onClose: close,
                registerExitGuard: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-project-picker')));
    await pumpIo(tester, frames: 45);
    final controller = fixture.controller;
    final document = controller.active!;
    final commands = MapEditingCommands(document, controller.project!);
    const position = GridPos(x: 8, y: 6);
    final compatibleDecor = controller.project!.elements.firstWhere(
      (entry) => entry.id == 'arbre',
    );
    for (var i = 0; i < 3; i++) {
      commands.place(compatibleDecor, position);
    }
    document.selectedId = null;
    controller.notify();
    await pumpIo(tester);
    await captureM3Widget(tester, capture, '01-carte-generale');
    final stack = commands.stack(position);
    expect(stack.length, greaterThanOrEqualTo(3));
    document.stackPosition = position;
    document.selectedId = stack[1].id;
    controller.notify();
    await pumpIo(tester);
    final before = document.current;
    expect(commands.canReorder(forward: true), isTrue);
    await tester.tap(find.byKey(const ValueKey('Passer devant')));
    await pumpIo(tester);
    expect(commands.stack(position).first.id, document.selectedId);
    expect(commands.canReorder(forward: true), isFalse);
    expect(commands.canReorder(forward: false), isTrue);
    expect(document.current.entities, before.entities);
    expect(document.current.layers, before.layers);
    expect(
      document.current.placedElements.map((e) => e.pos),
      before.placedElements.map((e) => e.pos),
    );
    for (final instance in document.current.placedElements) {
      final original = before.placedElements.firstWhere(
        (e) => e.id == instance.id,
      );
      expect(instance.copyWith(visualOrder: original.visualOrder), original);
    }
    await captureM3Widget(tester, capture, '02-decor-empilement');
    await tester.tap(find.byKey(const ValueKey('Annuler')));
    await pumpIo(tester);
    expect(document.current.placedElements, before.placedElements);
    await tester.tap(find.byTooltip('Changer la palette'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tuiles').last);
    await pumpIo(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atlas de l’atelier').last);
    await pumpIo(tester);
    expect(find.byKey(const ValueKey('atlas-selection')), findsOneWidget);
    await captureM3Widget(tester, capture, '03-palette-tuiles');
    await tester.tap(find.byTooltip('Retour à la carte'));
    await tester.pumpAndSettle();
    final layout = tester.widget<MapWorkspaceLayout>(
      find.byType(MapWorkspaceLayout),
    );
    final view = layout.view!;
    final matrix = view.transform.value.clone();
    final mountedState = tester.state(find.byType(MapWorkspaceScreen));
    await tester.tap(find.byTooltip('Accueil'));
    await tester.pumpAndSettle();
    await captureM3Widget(tester, capture, '05-accueil-conserve');
    await tester.tap(find.text('Reprendre mon projet'));
    await pumpIo(tester);
    expect(tester.state(find.byType(MapWorkspaceScreen)), same(mountedState));
    expect(controller.active, same(document));
    expect(document.dirty, isTrue);
    expect(view.transform.value, matrix);
    await tester.tap(find.byTooltip('Accueil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Jardin');
    await pumpIo(tester);
    expect(find.text('Reprendre mon projet'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byType(TextField).first)
          .focusNode!
          .hasFocus,
      isTrue,
    );
    await tester.enterText(find.byType(TextField).first, 'Jardin des essais');
    await tester.pump();
    await tester.tap(find.byTooltip('Effacer la recherche').first);
    await tester.tap(find.text('Reprendre mon projet'));
    await pumpIo(tester);
    expect(controller.active, same(document));
    for (final size in [
      const Size(1440, 900),
      const Size(1280, 800),
      const Size(1024, 640),
    ]) {
      tester.view.physicalSize = size;
      scale = size.width == 1024 ? 1.5 : 1;
      await tester.pumpWidget(app());
      await pumpIo(tester);
      expect(view.transform.value, matrix);
      expect(tester.takeException(), isNull);
      if (size.width == 1024) {
        await captureM3Widget(tester, capture, '04-compact-150');
        await tester.tap(find.byKey(const ValueKey('Palette')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Décors'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('decor-arbre')));
        await tester.pumpAndSettle();
        final canvas = tester.renderObject<RenderBox>(
          find.byKey(const ValueKey('map-canvas')),
        );
        final settings = controller.project!.settings;
        await tester.tapAt(
          canvas.localToGlobal(
            Offset(
              4.4 * settings.tileWidth * settings.displayScale,
              4.4 * settings.tileHeight * settings.displayScale,
            ),
          ),
        );
        await tester.pump();
        expect(document.selected!.pos, const GridPos(x: 4, y: 4));
        await tester.tap(find.byKey(const ValueKey('Zoom avant')));
        await tester.pump();
        expect(view.transform.value.getMaxScaleOnAxis(), closeTo(1.25, .001));
        await tester.tap(find.byKey(const ValueKey('Palette')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('Déplacer la vue')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('Retour à la carte')));
        await tester.pumpAndSettle();
        final beforePan = view.transform.value.clone();
        await tester.drag(
          find.byKey(const ValueKey('map-viewport')),
          const Offset(-80, -80),
        );
        await tester.pumpAndSettle();
        expect(view.transform.value, isNot(beforePan));
        await tester.tap(find.byKey(const ValueKey('Palette')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('decor-arbre')));
        await tester.pumpAndSettle();
        await tester.tapAt(
          canvas.localToGlobal(
            Offset(
              6.4 * settings.tileWidth * settings.displayScale,
              5.4 * settings.tileHeight * settings.displayScale,
            ),
          ),
        );
        await tester.pump();
        expect(document.selected!.pos, const GridPos(x: 6, y: 5));
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await session.dispose();
      await fixture.dispose();
    });
  });
}

class _Session implements ProjectSessionPort {
  _Session(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession> open(String directoryPath) async => session;
  @override
  Future<void> close(ProjectSession session) async {}
}
