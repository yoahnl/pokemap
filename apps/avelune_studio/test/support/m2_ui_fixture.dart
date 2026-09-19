import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'load_desktop_capture_fonts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/resources/resource_image_import.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import '../../tool/create_example_project.dart';
import '../../tool/example_project_assets.dart';

class M2UiFixture {
  M2UiFixture(
    this.directory,
    this.session,
    this.port,
    this.controller,
    this.resources,
  );
  final Directory directory;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter port;
  final MapWorkspaceController controller;
  final LocalResourceAdapter resources;
  final captureKey = GlobalKey();
  StudioMapResources? visuals;
  static Future<M2UiFixture> create(
    WidgetTester tester, {
    bool stress = false,
  }) async {
    await loadDesktopCaptureFonts();
    final directory = await Directory.systemTemp.createTemp('avelune_m2_ui_');
    await writeExampleProject(directory, stress: stress);
    final session = ProjectSession(
      sessionId: directory.path,
      name: 'Atelier M2',
      directoryPath: await directory.resolveSymbolicLinks(),
    );
    final port = LocalMapWorkspaceAdapter();
    final controller = WidgetMapController(session, port, tester);
    await controller.initialize();
    return M2UiFixture(
      directory,
      session,
      port,
      controller,
      LocalResourceAdapter(session: session, mapAdapter: port),
    );
  }

  Widget app(WidgetTester tester, {double textScale = 1}) => MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    theme: studioTheme(),
    home: RepaintBoundary(
      key: captureKey,
      child: MapWorkspaceScreen(
        controller: controller,
        loadVisuals: (session, manifest) async =>
            visuals = await StudioMapResources.load(session, manifest),
        resourcePort: WidgetResourcePort(resources, tester),
        imagePicker: () async {
          final bytes = exampleAtlasPng();
          final file = File(
            '${directory.parent.path}/${directory.uri.pathSegments.where((s) => s.isNotEmpty).last}-source.png',
          );
          await file.writeAsBytes(bytes);
          return PickedResourceImage(
            file.path,
            'Planche M2',
            Uint8List.fromList(bytes),
            160,
            64,
          );
        },
        runtimeBuilder: (entry, revision, close) => StudioPlaytestView(
          session: session,
          entry: entry,
          expectedRevision: revision,
          port: port,
          onClose: close,
        ),
        onClose: () async {},
        registerExitGuard: (_) {},
      ),
    ),
  );
  Future<void> dispose() async {
    controller.dispose();
    await resources.dispose();
    final source = File(
      '${directory.parent.path}/${directory.uri.pathSegments.where((s) => s.isNotEmpty).last}-source.png',
    );
    if (await source.exists()) await source.delete();
    await directory.delete(recursive: true);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final path = Platform.environment['AVELUNE_CAPTURE_DIR'];
    if (path == null) return;
    await tester.pump();
    final boundary =
        captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(path).create(recursive: true);
      await File('$path/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }
}

class WidgetResourcePort implements ResourcePort {
  WidgetResourcePort(this.port, this.tester);
  final ResourcePort port;
  final WidgetTester tester;
  static Future<Object?>? pending;
  Future<ResourceMutationReceipt> run(
    Future<ResourceMutationReceipt> Function() action,
  ) async {
    final operation = tester.runAsync(action);
    pending = operation;
    try {
      return (await operation)!;
    } finally {
      if (identical(pending, operation)) pending = null;
    }
  }

  @override
  Future<ResourceMutationReceipt> importImage(
    ResourceImageImport request,
  ) async => run(() => port.importImage(request));
  @override
  Future<ResourceMutationReceipt> mutate(
    String action,
    Map<String, Object?> parameters,
  ) async => run(() => port.mutate(action, parameters));
  @override
  Future<ResourceMutationReceipt> saveElement(
    ProjectElementEntry element,
  ) async => run(() => port.saveElement(element));
  @override
  Future<void> dispose() => port.dispose();
}

class WidgetMapController extends MapWorkspaceController {
  WidgetMapController(super.session, super.port, this.tester);
  final WidgetTester tester;
  @override
  Future<bool> save(EditableMapDocument document) async {
    final operation = tester.runAsync(() => super.save(document));
    WidgetResourcePort.pending = operation;
    try {
      return (await operation)!;
    } finally {
      if (identical(WidgetResourcePort.pending, operation)) {
        WidgetResourcePort.pending = null;
      }
    }
  }
}

Future<void> pumpIo(WidgetTester tester, {int frames = 30}) async {
  for (var i = 0; i < frames; i++) {
    await WidgetResourcePort.pending;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(tester.takeException(), isNull);
}
