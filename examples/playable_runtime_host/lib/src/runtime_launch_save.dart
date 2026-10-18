import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

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

/// State and activation semantics selected for one runtime-host launch.
final class RuntimeHostLaunchPlan {
  const RuntimeHostLaunchPlan({
    required this.saveData,
    required this.initialMapActivationReason,
  });

  final SaveData? saveData;
  final MapActivationReason initialMapActivationReason;
}

RuntimeHostLaunchPlan resolveRuntimeHostLaunchPlan({
  required ProjectNewGameConfig newGame,
  required SaveData? versionedLaunchSave,
}) {
  if (versionedLaunchSave != null) {
    return RuntimeHostLaunchPlan(
      saveData: versionedLaunchSave,
      initialMapActivationReason: MapActivationReason.saveRestore,
    );
  }
  if (newGame.enabled) {
    return const RuntimeHostLaunchPlan(
      saveData: null,
      initialMapActivationReason: MapActivationReason.initialBoot,
    );
  }
  throw StateError(
    'Configurez le démarrage du projet ou fournissez une sauvegarde de lancement explicite.',
  );
}

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
