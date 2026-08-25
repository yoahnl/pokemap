/// La fabrique de packages Avelune de stress — BETA-AVL-005.
///
/// Point d'entrée SÉPARÉ de `map_distribution.dart`, volontairement : un
/// consommateur du format de package ne doit pas voir apparaître une fabrique
/// de fixtures dans son autocomplétion. Les trois consommateurs prévus au
/// ticket — les tests de `map_distribution`, ceux du Hub et les outils de
/// `tools/performance` — l'importent explicitement.
library;

export 'src/stress/avelune_stress_assets.dart';
export 'src/stress/avelune_stress_entropy.dart';
export 'src/stress/avelune_stress_profile.dart';
