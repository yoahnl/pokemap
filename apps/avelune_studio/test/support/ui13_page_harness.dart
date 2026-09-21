import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/verification/verification_view_state.dart';
import 'package:avelune_studio/presentation/features/verification/verification_workspace_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_application_frame.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'capture_m3_widget.dart';
import 'load_desktop_capture_fonts.dart';
import 'ui13_verification_harness.dart';
import 'ui13_widget_verification_port.dart';

/// The UI13 page inside the Avelune frame, on a real project with real faults.
class Ui13PageHarness {
  Ui13PageHarness(this.project, this.port);

  final Ui13VerificationHarness project;
  final Ui13WidgetVerificationPort port;
  final view = VerificationViewState();
  final search = TextEditingController();
  final captureKey = GlobalKey();
  final changes = ValueNotifier(0);
  final opened = <NarrativeProjectDiagnostic>[];
  bool returned = false;

  VerificationWorkspaceController get controller => project.verification;

  static Future<Ui13PageHarness> create(WidgetTester tester) async {
    await loadDesktopCaptureFonts();
    late Ui13WidgetVerificationPort port;
    final project = await Ui13VerificationHarness.create(
      wrap: (delegate) => port = Ui13WidgetVerificationPort(delegate, tester),
    );
    final harness = Ui13PageHarness(project, port);
    project.onChanged = () => harness.changes.value++;
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
            projectName: 'Projet de démonstration UI13',
            child: VerificationWorkspacePage(
              controller: controller,
              view: view,
              onBack: () => returned = true,
              openLabel: (item) =>
                  item.destination ==
                      NarrativeProjectDiagnosticDestination.overview
                  ? null
                  : 'Éditeur ${item.destination.name}',
              onOpen: (item) async => opened.add(item),
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
    await project.dispose();
  }
}
