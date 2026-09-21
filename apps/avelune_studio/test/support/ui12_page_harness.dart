import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/world/world_view_state.dart';
import 'package:avelune_studio/presentation/features/world/world_workspace_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_application_frame.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'capture_m3_widget.dart';
import 'load_desktop_capture_fonts.dart';
import 'ui12_widget_world_port.dart';
import 'ui12_world_harness.dart';

/// The UI12 page inside the Avelune frame, on a real project.
class Ui12PageHarness {
  Ui12PageHarness(this.world, this.visuals);

  final Ui12WorldHarness world;
  final MapWorkspaceVisuals visuals;
  final view = WorldViewState();
  final search = TextEditingController();
  final captureKey = GlobalKey();
  final changes = ValueNotifier(0);
  bool returned = false;

  WorldWorkspaceController get controller => world.world;

  static Future<Ui12PageHarness> create(WidgetTester tester) async {
    await loadDesktopCaptureFonts();
    final world = await Ui12WorldHarness.create(
      wrap: (port) => Ui12WidgetWorldPort(port, tester),
      initialize: false,
    );
    final visuals = await StudioMapResources.load(
      world.session,
      world.maps.project!,
    );
    final harness = Ui12PageHarness(world, visuals);
    world.onChanged = () => harness.changes.value++;
    return harness;
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
          valueListenable: changes,
          builder: (context, value, _) => StudioApplicationFrame(
            search: search,
            onSearch: (_) {},
            onDestination: (_) {},
            active: 'story',
            projectName: 'Projet de démonstration UI12',
            child: WorldWorkspacePage(
              controller: controller,
              view: view,
              onBack: () => returned = true,
              visuals: visuals,
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> capture(WidgetTester tester, String name) =>
      captureM3Widget(tester, captureKey, name);

  Future<void> dispose() async {
    view.dispose();
    search.dispose();
    changes.dispose();
    await world.dispose();
  }
}
