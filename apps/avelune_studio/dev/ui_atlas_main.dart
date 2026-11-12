import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/files/scoped_project_session_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import 'spatial_frame_recorder.dart';

final class AtlasProjectSessionPort implements ProjectSessionPort {
  AtlasProjectSessionPort(this.delegate, this.errorFile);

  final ProjectSessionPort delegate;
  final File errorFile;

  @override
  Future<ProjectSession> open(
    String directoryPath, {
    void Function(ProjectOpeningPhase phase)? onPhase,
  }) async {
    try {
      return await delegate.open(directoryPath, onPhase: onPhase);
    } catch (error, stack) {
      await errorFile.writeAsString('$error\n$stack', flush: true);
      rethrow;
    }
  }

  @override
  Future<void> close(ProjectSession session) => delegate.close(session);
}

Future<String> requireAtlasProject(
  String projectPath,
  Directory captureRoot,
) async {
  if (!p.isAbsolute(projectPath) ||
      p.normalize(projectPath) != projectPath ||
      p.dirname(projectPath) != captureRoot.parent.path ||
      p.basename(projectPath) != 'project' ||
      await FileSystemEntity.type(projectPath, followLinks: false) !=
          FileSystemEntityType.directory ||
      await Directory(projectPath).resolveSymbolicLinks() != projectPath) {
    throw StateError('The atlas project must be the owned project copy.');
  }
  return projectPath;
}

Future<void> main() async {
  if (!kReleaseMode || !Platform.isMacOS) {
    throw StateError('The Studio UI atlas requires macOS Release mode.');
  }
  WidgetsFlutterBinding.ensureInitialized();
  const capturePath = String.fromEnvironment('MARIONETTE_CAPTURE_ROOT');
  const projectPath = String.fromEnvironment('AVELUNE_ATLAS_PROJECT_PATH');
  final captureRoot = await requireStudioCaptureRoot(capturePath);
  await requireAtlasProject(projectPath, captureRoot);
  final errorFile = File(p.join(captureRoot.path, 'startup-error.txt'));
  if (await errorFile.exists()) await errorFile.delete();
  final session = ProjectSessionController(
    AtlasProjectSessionPort(
      ScopedProjectSessionAdapter(LocalProjectSessionAdapter()),
      errorFile,
    ),
  );
  try {
    await session.open(projectPath);
    if (session.state.project?.directoryPath != projectPath ||
        session.state.problem != null) {
      throw StateError(
        'The requested atlas project could not be opened: ${session.state.problem}',
      );
    }
  } catch (error, stack) {
    if (!await errorFile.exists()) {
      await errorFile.writeAsString('$error\n$stack', flush: true);
    }
    rethrow;
  }
  final boundaryKey = GlobalKey();
  var capturing = false;
  var sequence = 0;
  Future<void> capture() async {
    if (capturing || session.state.project?.directoryPath != projectPath) {
      return;
    }
    capturing = true;
    ui.Image? image;
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = boundaryKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary || !boundary.hasSize) {
        throw StateError('The Studio capture surface is unavailable.');
      }
      final pixelRatio = View.of(boundaryKey.currentContext!).devicePixelRatio;
      image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('The capture could not be encoded.');
      final name =
          'studio_${DateTime.now().toUtc().microsecondsSinceEpoch}_${sequence++}.png';
      final file = File(p.join(captureRoot.path, name));
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      stdout.writeln('AVELUNE_ATLAS_CAPTURE ${file.path}');
    } catch (error, stack) {
      stderr.writeln('AVELUNE_ATLAS_CAPTURE_ERROR $error\n$stack');
    } finally {
      image?.dispose();
      capturing = false;
    }
  }

  HardwareKeyboard.instance.addHandler((event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f12) {
      unawaited(capture());
      return true;
    }
    return false;
  });
  RendererBinding.instance.ensureSemantics();
  stdout.writeln('AVELUNE_ATLAS_PROJECT $projectPath');
  runApp(
    RepaintBoundary(
      key: boundaryKey,
      child: StudioBootstrap(debugSession: session),
    ),
  );
}
