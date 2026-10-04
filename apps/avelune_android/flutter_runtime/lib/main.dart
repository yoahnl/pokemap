import 'package:pokemap_hub/avelune_embedded_runtime.dart';

void main() => runAveluneEmbeddedRuntime();

@pragma('vm:entry-point')
void aveluneCompanionMain() => runAveluneCompanionProbe();

@pragma('vm:entry-point')
void aveluneGameplayCompanionMain() => runAveluneGameplayCompanion();
