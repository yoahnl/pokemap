import 'package:flutter/widgets.dart';
import 'package:map_runtime/map_runtime.dart' show AveluneWidgetsFlutterBinding;

import 'embedding/avelune_runtime_app.dart';
import 'embedding/avelune_surface_probe_app.dart';
import 'embedding/avelune_gameplay_companion_app.dart';

export 'embedding/avelune_library_bridge.dart';
export 'embedding/avelune_runtime_app.dart';

void runAveluneEmbeddedRuntime() {
  AveluneWidgetsFlutterBinding.ensureInitialized();
  runApp(const AveluneRuntimeApp());
}

void runAveluneCompanionProbe() {
  AveluneWidgetsFlutterBinding.ensureInitialized();
  runApp(const AveluneCompanionProbeApp());
}

void runAveluneGameplayCompanion() {
  AveluneWidgetsFlutterBinding.ensureInitialized();
  runApp(const AveluneGameplayCompanionApp());
}
