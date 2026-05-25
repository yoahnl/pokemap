import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

void _runtimeHostSaveLog(String message) {
  debugPrint('[runtime_host_save] $message');
}

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
  _runtimeHostSaveLog('launch save lookup path=${launchSaveFile.path}');
  if (!await launchSaveFile.exists()) {
    _runtimeHostSaveLog('launch save missing path=${launchSaveFile.path}');
    return null;
  }

  _runtimeHostSaveLog('launch save read start path=${launchSaveFile.path}');
  final decoded = jsonDecode(await launchSaveFile.readAsString());
  if (decoded is! Map<String, dynamic>) {
    _runtimeHostSaveLog('launch save invalid rootType=${decoded.runtimeType}');
    throw StateError(
      'Le fichier $kRuntimeHostLaunchSaveFileName doit contenir un objet JSON.',
    );
  }

  try {
    final saveData = SaveData.fromJson(decoded).normalized();
    _runtimeHostSaveLog(
      'launch save parsed mapId=${saveData.currentMapId} party=${saveData.party.members.length}',
    );
    return saveData;
  } catch (error) {
    _runtimeHostSaveLog('launch save parse failed error=$error');
    throw StateError(
      'Le fichier $kRuntimeHostLaunchSaveFileName est invalide: $error',
    );
  }
}
