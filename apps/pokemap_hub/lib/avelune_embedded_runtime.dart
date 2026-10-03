import 'package:flutter/widgets.dart';

import 'embedding/avelune_runtime_app.dart';
import 'embedding/avelune_surface_probe_app.dart';
import 'embedding/avelune_gameplay_companion_app.dart';

export 'embedding/avelune_library_bridge.dart';
export 'embedding/avelune_runtime_app.dart';

void runAveluneEmbeddedRuntime() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AveluneRuntimeApp());
}

void runAveluneCompanionProbe() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AveluneCompanionProbeApp());
}

void runAveluneGameplayCompanion() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AveluneGameplayCompanionApp());
}
