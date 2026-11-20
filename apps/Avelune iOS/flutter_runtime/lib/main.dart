import 'package:flutter/painting.dart';
import 'package:pokemap_hub/avelune_embedded_runtime.dart';

void main() => runAveluneEmbeddedRuntime(
  app: const AveluneRuntimeApp(
    splashLogo: AssetImage('assets/branding/avelune-lagune.png'),
  ),
);
