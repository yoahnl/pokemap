import 'package:flutter/painting.dart';
import 'package:avelune_player_host/avelune_embedded_runtime.dart';

void main() => runAveluneEmbeddedRuntime(
  app: const AveluneRuntimeApp(
    splashLogo: AssetImage('assets/branding/avelune-lagune.png'),
  ),
);
