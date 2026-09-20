import 'dart:io';
import 'dart:ui' as ui;
import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_view_state.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_workspace_page.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_application_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'load_desktop_capture_fonts.dart';
import 'm2_ui_fixture.dart';
import 'ui09_dialogue_fixture.dart';
import 'ui09_runtime_fixture.dart';

class Ui09DialogueHarness {
  Ui09DialogueHarness(this.fixture, this.maps, this.narrative, this.port) {
    scenes = SceneWorkspaceController(
      maps,
      fixture.scenes,
      narrative: narrative,
      changed: notify,
    );
    dialogues = DialogueWorkspaceController(
      narrative,
      port,
      changed: notify,
      sceneDrafts: () => scenes.scenes,
    );
  }
  final Ui09DialogueFixture fixture;
  final MapWorkspaceController maps;
  final NarrativeWorkspaceController narrative;
  final WidgetDialoguePort port;
  late final SceneWorkspaceController scenes;
  late final DialogueWorkspaceController dialogues;
  final views = DialogueViewStore();
  final notifier = ChangeNotifier();
  final captureKey = GlobalKey();
  final search = TextEditingController();
  int backCount = 0;
  void notify() => notifier.notifyListeners();
  static Future<Ui09DialogueHarness> create(WidgetTester tester) async {
    await loadDesktopCaptureFonts();
    final fixture = await Ui09DialogueFixture.create();
    final maps = MapWorkspaceController(fixture.source.session, fixture.maps);
    await maps.initialize();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(
        session: fixture.source.session,
        mapAdapter: fixture.maps,
      ),
      () {},
      (_, _) async {},
    );
    return Ui09DialogueHarness(
      fixture,
      maps,
      narrative,
      WidgetDialoguePort(fixture.port, tester),
    );
  }

  Future<void> open(WidgetTester tester) async {
    final opening = dialogues.open(ui09DialogueId);
    await pumpIo(tester);
    expect(await opening, isTrue);
  }

  Widget app({double textScale = 1}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: studioTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: RepaintBoundary(
        key: captureKey,
        child: StudioApplicationFrame(
          search: search,
          onSearch: (_) {},
          onDestination: (_) {},
          projectName: 'Rencontre en gare',
          active: 'story',
          child: ListenableBuilder(
            listenable: notifier,
            builder: (context, _) => DialogueWorkspacePage(
              controller: dialogues,
              views: views,
              backLabel: 'la scène',
              onBack: () => backCount++,
            ),
          ),
        ),
      ),
    ),
  );
  Future<void> capture(WidgetTester tester, String name) async {
    final path = Platform.environment['AVELUNE_CAPTURE_DIR'];
    if (path == null) return;
    await tester.pump();
    final boundary =
        captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final rendered = await boundary.toImage(pixelRatio: 1);
      final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
      await Directory(path).create(recursive: true);
      await File('$path/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      rendered.dispose();
    });
  }

  Future<void> dispose() async {
    dialogues.dispose();
    scenes.dispose();
    narrative.dispose();
    maps.dispose();
    views.dispose();
    search.dispose();
    notifier.dispose();
    await fixture.dispose();
  }
}
