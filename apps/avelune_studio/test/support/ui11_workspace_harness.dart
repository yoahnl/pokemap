import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:avelune_studio/features/presentations/data/local_presentation_adapter.dart';
import 'package:avelune_studio/platform/rendering/presentation_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/presentations/presentation_view_state.dart';
import 'package:avelune_studio/presentation/features/presentations/presentation_workspace_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_application_frame.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'capture_m3_widget.dart';
import 'load_desktop_capture_fonts.dart';
import 'm2_ui_fixture.dart';
import 'ui11_presentation_fixture.dart';
import 'ui11_widget_port.dart';

class Ui11WorkspaceHarness {
  Ui11WorkspaceHarness(
    this.fixture,
    this.maps,
    this.narrative,
    this.controller,
    this.port,
    this.visuals,
    this.changed,
  );
  final Ui11PresentationFixture fixture;
  final MapWorkspaceController maps;
  final NarrativeWorkspaceController narrative;
  final PresentationWorkspaceController controller;
  final Ui11WidgetPort port;
  final StudioPresentationVisuals visuals;
  final ValueNotifier<int> changed;
  final views = PresentationViewStore();
  final search = TextEditingController();
  final captureKey = GlobalKey();
  bool returned = false;
  static Future<Ui11WorkspaceHarness> create(WidgetTester tester) async {
    await loadDesktopCaptureFonts();
    final fixture = await Ui11PresentationFixture.create();
    final source = fixture.source;
    final maps = MapWorkspaceController(source.session, source.maps);
    await maps.initialize();
    final changed = ValueNotifier(0);
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: source.session, mapAdapter: source.maps),
      () => changed.value++,
      (_, _) async {},
    );
    final port = Ui11WidgetPort(
      LocalPresentationAdapter(
        session: source.session,
        mapAdapter: source.maps,
      ),
      tester,
    );
    final controller = PresentationWorkspaceController(
      narrative,
      port,
      changed: () => changed.value++,
    );
    if (!await controller.open(fixture.asset.id)) {
      throw StateError(controller.error!);
    }
    final visuals = StudioPresentationVisuals(
      projectRoot: source.directory.path,
      revision: controller.active!.base!.revision,
      catalog: controller.active!.mediaCatalog,
    );
    await visuals.prepare(controller.active!.asset, portrait: false);
    port.interactive = true;
    port.reads = port.writes = 0;
    return Ui11WorkspaceHarness(
      fixture,
      maps,
      narrative,
      controller,
      port,
      visuals,
      changed,
    );
  }

  Widget app({double textScale = 1}) => RepaintBoundary(
    key: captureKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: studioTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: ValueListenableBuilder(
          valueListenable: changed,
          builder: (context, value, _) => StudioApplicationFrame(
            search: search,
            onSearch: (_) {},
            onDestination: (_) {},
            active: 'story',
            projectName: 'Projet de démonstration UI11',
            child: PresentationWorkspacePage(
              controller: controller,
              views: views,
              visuals: visuals,
              onBack: () {
                returned = true;
              },
            ),
          ),
        ),
      ),
    ),
  );
  Future<void> settle(WidgetTester tester) async {
    await WidgetResourcePort.pending;
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.runAsync(() => visuals.settled);
    await tester.pump();
  }

  Future<void> capture(WidgetTester tester, String name) =>
      captureM3Widget(tester, captureKey, name);
  Future<void> shutdown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    var done = false;
    final closing = dispose().whenComplete(() => done = true);
    for (var i = 0; i < 200 && !done; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(
      done,
      isTrue,
      reason: 'Owned presentation visuals and fixture must close',
    );
    await closing;
  }

  Future<void> dispose() async {
    await visuals.close();
    visuals.dispose();
    controller.dispose();
    narrative.dispose();
    maps.dispose();
    views.dispose();
    search.dispose();
    changed.dispose();
    await fixture.dispose();
  }
}
