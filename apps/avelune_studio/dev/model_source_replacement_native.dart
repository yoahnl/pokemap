import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/presentation/features/resources/model_resource_library.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_render_3d/map_render_3d.dart';

import 'save_disk_trace.dart';
import '../test/support/native_resource_phase_bootstrap.dart';
import 'marionette_main.dart' show applyStudioCaptureLifecycle;

import 'package:avelune_studio/presentation/features/resources/working_catalog_workspace.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:map_core/map_core.dart';

const _qaRoot = String.fromEnvironment('BG3D_NATIVE_ROOT');
const _projectRoot = '$_qaRoot/project';
final _traceEnabled = Platform.environment['BG3D_NATIVE_TRACE'] != 'false';
final _boundary = GlobalKey();
final _errors = <String>[];
final _workerRows = <Object?>[];
late SaveDiskTrace _disk;
late ProjectSessionController _session;
Map<String, Object?> _opening = {};
Stopwatch? _operationWatch;
final _phaseStamps = <String, List<int>>{};

void _markMutationPhase(String phase) {
  final watch = _operationWatch;
  if (watch != null) {
    _phaseStamps.putIfAbsent(phase, () => []).add(watch.elapsedMicroseconds);
  }
}

Future<void> _markPhase(String phase) async => _markMutationPhase(phase);

Widget _instrumentedStudio(BuildContext context) =>
    buildNativeResourcePhaseBootstrap(
      context,
      bootstrapWidget: StudioBootstrap(debugSession: _session),
      beforeTransactionPrecondition: () => _markPhase('precondition'),
      beforeReconciliation: () => _markPhase('durablePublication'),
      mutationPhaseObserver: (phase) => _markMutationPhase('mutation.$phase'),
    );

void _visit(void Function(Element) action) {
  void visit(Element element) {
    action(element);
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
}

T? _widget<T extends Widget>() {
  T? result;
  _visit((element) {
    if (element.widget is T) result = element.widget as T;
  });
  return result;
}

Element _labelElement(String label, {bool tooltip = false}) {
  final matches = <Element>[];
  _visit((element) {
    final matchesLabel = tooltip
        ? element.widget is Tooltip &&
              (element.widget as Tooltip).message == label
        : element.widget is Text && (element.widget as Text).data == label;
    if (matchesLabel) {
      if (tooltip) {
        final box = element.findRenderObject();
        if (box is! RenderBox || !box.hasSize) return;
        final hit = HitTestResult();
        WidgetsBinding.instance.hitTestInView(
          hit,
          box.localToGlobal(box.size.center(Offset.zero)),
          View.of(element).viewId,
        );
        if (!hit.path.any((entry) => identical(entry.target, box))) return;
      }
      matches.add(element);
    }
  });
  if (matches.length != 1) {
    throw StateError('Expected one label "$label", found ${matches.length}.');
  }
  return matches.single;
}

Future<Offset> _target(String label, {bool tooltip = false}) async {
  final element = _labelElement(label, tooltip: tooltip);
  await Scrollable.ensureVisible(element, alignment: .5);
  WidgetsBinding.instance.scheduleFrame();
  await WidgetsBinding.instance.endOfFrame;
  final box = element.findRenderObject() as RenderBox;
  return box.localToGlobal(box.size.center(Offset.zero));
}

void _tap(Offset position) {
  GestureBinding.instance.handlePointerEvent(
    PointerDownEvent(
      pointer: 71,
      position: position,
      kind: ui.PointerDeviceKind.mouse,
    ),
  );
  GestureBinding.instance.handlePointerEvent(
    PointerUpEvent(
      pointer: 71,
      position: position,
      kind: ui.PointerDeviceKind.mouse,
    ),
  );
}

Map<String, Object?> _state() {
  final texts = <String>[];
  _visit((element) {
    if (element.widget case Text(:final data?) when data.trim().isNotEmpty) {
      if (!texts.contains(data)) texts.add(data);
    }
  });
  final navigation = _widget<ResourceWorkspacePane>()?.navigation;
  final preview = _widget<ModelPreview>()?.controller;
  return {
    'pid': pid,
    'buildMode': kReleaseMode
        ? 'release'
        : (kProfileMode ? 'profile' : 'debug'),
    'activeProject': _session.state.project?.directoryPath,
    'matchesExpectedProject':
        _session.state.project?.directoryPath == _projectRoot,
    'ioTraceEnabled': _traceEnabled,
    'resourcePane': navigation != null,
    'modelLibrary': _widget<ModelResourceLibrary>() != null,
    'busy': navigation?.busy,
    'error': navigation?.error,
    'pendingReceipt': navigation?.pendingReceipt != null,
    'previewGeneration': preview?.previewGeneration,
    'texts': texts,
    'errors': _errors,
    'opening': _opening,
  };
}

StudioButton? _replaceButton() {
  StudioButton? result;
  _visit((element) {
    if (element.widget case final StudioButton button
        when button.key == const ValueKey('working-model-source-replace')) {
      result = button;
    }
  });
  return result;
}

Future<Map<String, Object?>> _replace(Map<String, dynamic> command) async {
  final catalog = _widget<WorkingCatalogWorkspace>()?.controller;
  if (catalog == null ||
      catalog.dirty ||
      catalog.saving ||
      catalog.selected?.id != 'door' ||
      _replaceButton()?.onPressed == null) {
    throw StateError(
      'The real catalogue must show the clean owned door model.',
    );
  }
  final candidate = command['candidate'] as String;
  if (!RegExp(r'^candidate-[12]\.glb$').hasMatch(candidate)) {
    throw StateError('An owned candidate is required.');
  }
  final picker = _OwnedPicker('$_qaRoot/$candidate');
  FilePickerPlatform.instance = picker;
  final position = await _target('Remplacer le modèle GLB');
  final before = _widget<ModelPreview>()?.controller;
  final workerStart = _workerRows.length;
  final watch = Stopwatch();
  _phaseStamps.clear();
  _operationWatch = watch;
  if (_traceEnabled) _disk.arm();
  watch.start();
  try {
    _tap(position);
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
    final feedbackUs = watch.elapsedMicroseconds;
    final feedbackLabel = _replaceButton()?.label;
    while ((_replaceButton()?.label != 'Remplacer le modèle GLB' ||
            picker.calls == 0 ||
            catalog.opening) &&
        watch.elapsed < const Duration(seconds: 30)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame;
    }
    final durableUs = watch.elapsedMicroseconds;
    final durableDisk = _disk.snapshot();
    final texts = _state()['texts'] as List<String>;
    if (picker.calls != 1 ||
        catalog.error != null ||
        _phaseStamps['durablePublication']?.length != 1 ||
        !texts.contains('Modèle remplacé.')) {
      throw StateError(
        'Replacement did not complete successfully: ${_state()}',
      );
    }
    while (watch.elapsed < const Duration(seconds: 10)) {
      final after = _widget<ModelPreview>()?.controller;
      if (after != null &&
          !identical(before, after) &&
          after.projectPoint(Model3dVector3.zero) != null) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame;
    }
    final after = _widget<ModelPreview>()?.controller;
    return {
      'label': command['label'],
      'candidate': candidate,
      'pickerCalls': picker.calls,
      'ioTraceEnabled': _traceEnabled,
      'path': 'real catalogue StudioButton pointer → picker boundary → replaceStudioModelSource → LocalResourceAdapter → canonical authoring → ResourceNavigation.accept → selected detail reread',
      'pointerToFirstFeedbackFrameUs': feedbackUs,
      'phaseStampsUs': Map<String, List<int>>.of(_phaseStamps),
      'pointerToDurablePublicationUs':
          _phaseStamps['durablePublication']?.single,
      'publicationMeaning': 'Existing LocalResourceAdapter.beforeReconciliation callback immediately after successful canonical applyMutation returns. No I/O or prewarming in hook.',
      'feedbackLabel': feedbackLabel,
      'pointerToDurableAndAcceptedUs': durableUs,
      'pointerToReadyPreviewFrameUs': watch.elapsedMicroseconds,
      'previewControllerReplaced':
          before != null && after != null && !identical(before, after),
      'previewProjectionReady':
          after?.projectPoint(Model3dVector3.zero) != null,
      'durableDisk': durableDisk,
      'settledDisk': _disk.snapshot(),
      'workerDiagnostics': _workerRows.skip(workerStart).toList(),
      'errors': List<String>.of(_errors),
      'activeProject': _session.state.project?.directoryPath,
      'durableMeaning': 'Upper bound: successful canonical publication, receipt acceptance, selected detail reread and completed UI frame. Fresh disk reopen is verified separately.',
      'previewMeaning': 'New preview controller exposes a valid projection after a completed frame. GPU content is checked separately by capture.',
      'lifecycle': 'Resumed through existing QA capture lifecycle helper before measurement.',
    };
  } finally {
    _disk.armed = false;
    _operationWatch = null;
  }
}

Future<Map<String, Object?>> _execute(Map<String, dynamic> command) async {
  applyStudioCaptureLifecycle(AppLifecycleState.resumed);
  if (_session.state.project?.directoryPath != _projectRoot) {
    throw StateError('The active project is not the owned QA fixture.');
  }
  switch (command['action']) {
    case 'state':
      return _state();
    case 'tap':
      _tap(
        await _target(
          command['label'] as String,
          tooltip: command['tooltip'] == true,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return _state();
    case 'replace':
      return _replace(command);
    case 'capture':
      final boundary =
          _boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await File('$_qaRoot/capture.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      return {'capture': '$_qaRoot/capture.png', ..._state()};
    case 'quit':
      Timer(const Duration(milliseconds: 300), () => exit(0));
      return {'quitting': true};
    default:
      throw StateError('Unknown native QA command.');
  }
}

Future<void> main() async {
  if (!kReleaseMode ||
      !Platform.isMacOS ||
      _qaRoot !=
          '/Users/karim/Library/Caches/AveluneQA/bg3d-02-replacement/native') {
    throw StateError(
      'This harness requires the owned BG3D-02 macOS Release fixture.',
    );
  }
  AveluneWidgetsFlutterBinding.ensureInitialized();
  if (await Directory(_projectRoot).resolveSymbolicLinks() != _projectRoot) {
    throw StateError('A canonical fixture root is required.');
  }
  final worker = ReceivePort()..listen(_workerRows.add);
  MapAuthoringWorkerDiagnostics.port = worker.sendPort;
  final previousError = FlutterError.onError;
  FlutterError.onError = (details) {
    _errors.add(details.exceptionAsString());
    previousError?.call(details);
  };
  _disk = SaveDiskTrace(_projectRoot);
  _session = ProjectSessionController(LocalProjectSessionAdapter());
  final opening = Stopwatch()..start();
  if (_traceEnabled) {
    _disk.arm();
    await _disk.run(() => _session.open(_projectRoot));
  } else {
    if (IOOverrides.current != null) {
      throw StateError('Untraced measurements require the native filesystem.');
    }
    await _session.open(_projectRoot);
  }
  _opening = {
    'sessionOpenUs': opening.elapsedMicroseconds,
    'ioTraceEnabled': _traceEnabled,
    'disk': _disk.snapshot(),
  };
  _disk.armed = false;
  if (_session.state.project?.directoryPath != _projectRoot) {
    throw StateError('Could not open owned fixture: ${_session.state.problem}');
  }
  runApp(
    RepaintBoundary(
      key: _boundary,
      child: Builder(builder: _instrumentedStudio),
    ),
  );
  var busy = false;
  String? handled;
  Timer.periodic(const Duration(milliseconds: 100), (_) async {
    if (busy) return;
    busy = true;
    String? id;
    try {
      final file = File('$_qaRoot/control.json');
      if (!await file.exists()) return;
      final command =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      id = command['id'] as String;
      if (id == handled) return;
      handled = id;
      final result = await _execute(command);
      await File('$_qaRoot/result.json')
          .writeAsString(jsonEncode({'id': id, 'ok': true, ...result}));
    } catch (error, stack) {
      await File('$_qaRoot/result.json').writeAsString(
        jsonEncode({
          'id': id,
          'ok': false,
          'error': '$error',
          'stack': '$stack',
          'state': _state(),
        }),
      );
    } finally {
      busy = false;
    }
  });
}

final class _OwnedPicker extends FilePickerPlatform {
  _OwnedPicker(this.path);
  final String path;
  int calls = 0;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
  }) async {
    if (type != FileType.custom ||
        allowedExtensions?.single != 'glb' ||
        allowMultiple) {
      throw StateError('Unexpected picker request.');
    }
    calls++;
    return FilePickerResult([
      PlatformFile(
        name: path.split('/').last,
        path: path,
        size: await File(path).length(),
      ),
    ]);
  }
}
