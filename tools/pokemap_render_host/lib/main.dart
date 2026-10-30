import 'dart:io';

import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:flutter/material.dart';
import 'package:pokemap_loader/main.dart' as runtime;
import 'package:pokemap_loader/evaluation.dart';
import 'package:map_authoring/map_authoring_local.dart'
    show initializeCompanionProcessAccess;

import 'src/render_host.dart';

final _boundaryKey = GlobalKey();
final _content = ValueNotifier<Widget>(const SizedBox.shrink());

Future<void> main() async {
  initializeCompanionProcessAccess();
  AveluneWidgetsFlutterBinding.ensureInitialized();
  if (Platform.environment['AVELUNE_RUNTIME_MODE'] == 'interactive') {
    const enabled = bool.fromEnvironment('AVELUNE_RUNTIME_COMPANION');
    if (!enabled) throw StateError('Installed evaluation is unavailable.');
    final environment = Platform.environment;
    runtime.runRuntimeHost(
      evaluationOutputRoot: Directory.current.absolute,
      evaluationProjectIdentity: environment['AVELUNE_EVALUATION_PROJECT_ID'],
      evaluationConfig: InteractiveEvaluationConfig.resolve(
        isReleaseMode: false,
        enabledDefine: environment['POKEMAP_EVAL_INTERACTIVE'] == 'true',
        hostDefine: environment['POKEMAP_EVAL_HOST'] ?? '',
        portDefine: environment['POKEMAP_EVAL_PORT'] ?? '',
        tokenDefine: environment['POKEMAP_EVAL_TOKEN'] ?? '',
        projectDefine: environment['POKEMAP_EVAL_PROJECT'] ?? '',
        playbackRateDefine: environment['POKEMAP_EVAL_PLAYBACK_RATE'] ?? '1',
      ),
    );
    return;
  }
  final errors = <String>[];
  FlutterError.onError = (details) {
    errors.add(details.exceptionAsString());
    stderr.writeln(details);
  };
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: const Color(0xff242b31),
        child: ValueListenableBuilder<Widget>(
          valueListenable: _content,
          builder: (_, value, _) =>
              RepaintBoundary(key: _boundaryKey, child: value),
        ),
      ),
    ),
  );
  final renderer = SpatialMapRenderer(
    boundaryKey: _boundaryKey,
    content: _content,
    errors: errors,
  );
  await RenderHost(renderer.render, scan: renderer.scan).serve(stdin, stdout);
  exit(0);
}
