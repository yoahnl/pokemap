import 'package:flutter/painting.dart';
import 'package:pokemap_hub/avelune_embedded_runtime.dart';

void main() => runAveluneEmbeddedRuntime(
  app: const AveluneRuntimeApp(
    splashLogo: AssetImage('assets/branding/avelune-lagune.png'),
    splashWordmark: AssetImage('assets/branding/avelune-wordmark.png'),
    splashMovieAsset: 'assets/branding/avelune-lagune-splash.mp4',
    splashMoviePackage: null,
  ),
);
