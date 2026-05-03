/// Écriture mémoire d’un preset d’environnement sur le [ProjectManifest] de session.
///
/// Utilisé par le callback [EnvironmentStudioPanel.onEnvironmentPresetSaved] pour
/// distinguer création et mise à jour (messages shell / feedback local).
enum EnvironmentPresetMemoryWriteKind {
  create,
  update,
}
