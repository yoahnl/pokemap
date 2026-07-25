enum RuntimeNotificationTone { info, success, warning, error }

/// Message éphémère publié par le runtime, sans dépendance visuelle.
class RuntimeNotificationSnapshot {
  const RuntimeNotificationSnapshot({
    required this.revision,
    required this.text,
    this.tone = RuntimeNotificationTone.info,
  });

  final int revision;
  final String text;
  final RuntimeNotificationTone tone;
}
