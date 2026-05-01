import 'package:map_core/map_core.dart';

/// Helper pour appliquer la sauvegarde d'un ProjectPathPatternPreset dans le manifest.
///
/// Ce helper extrait la logique d'upsert utilisée par le callback de
/// [PathStudioWorkspace] pour la sauvegarde des PathPattern depuis un path existant.
///
/// Il prouve que :
/// 1. On reçoit un [ProjectPathPatternPreset]
/// 2. On appelle [upsertProjectPathPatternPreset] pour mettre à jour le manifest
/// 3. Le manifest est retourné avec la modification
///
/// **Note :** Ce helper ne gère pas la lecture/écriture du state Riverpod.
/// Il se concentre uniquement sur la transformation du manifest.
ProjectManifest applyLegacyPathPatternSaveToManifest({
  required ProjectManifest manifest,
  required ProjectPathPatternPreset preset,
}) {
  return upsertProjectPathPatternPreset(
    manifest: manifest,
    preset: preset,
  );
}
