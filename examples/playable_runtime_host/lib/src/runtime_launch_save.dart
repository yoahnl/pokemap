import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

/// Nom fixe du fichier de save versionné qu'un projet peut exposer pour le
/// host runtime.
///
/// Phase A veut une vérité produit réellement lançable :
/// - un simple `project.json` sélectionnable dans le host ;
/// - éventuellement une vraie save de lancement adjacente ;
/// - et aucune dépendance à une fixture temporaire ou à un seed "magique".
///
/// Si ce fichier est présent à côté du `project.json`, le host le traite comme
/// la meilleure source de vérité pour l'état joueur initial.
const kRuntimeHostLaunchSaveFileName = 'runtime_host_launch_save.json';

/// Charge la save versionnée de lancement d'un projet runtime, si elle existe.
///
/// Politique volontairement stricte :
/// - absence du fichier => `null`, le host peut alors retomber sur son seed
///   de démo historique ;
/// - fichier présent mais invalide => erreur explicite ;
/// - aucune fallback silencieuse vers une autre save si ce seam produit est
///   cassé, parce qu'on veut que le golden slice reste honnête.
Future<SaveData?> loadRuntimeHostLaunchSaveData({
  required String projectFilePath,
}) async {
  final projectFile = File(projectFilePath);
  final launchSaveFile = File.fromUri(
    projectFile.parent.uri.resolve(kRuntimeHostLaunchSaveFileName),
  );
  if (!await launchSaveFile.exists()) {
    return null;
  }

  final decoded = jsonDecode(await launchSaveFile.readAsString());
  if (decoded is! Map<String, dynamic>) {
    throw StateError(
      'Le fichier $kRuntimeHostLaunchSaveFileName doit contenir un objet JSON.',
    );
  }

  try {
    return SaveData.fromJson(decoded).normalized();
  } catch (error) {
    throw StateError(
      'Le fichier $kRuntimeHostLaunchSaveFileName est invalide: $error',
    );
  }
}
