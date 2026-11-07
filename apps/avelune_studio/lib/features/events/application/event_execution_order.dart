import 'package:map_core/map_core_domain.dart';

import '../domain/event_record_view.dart';

String eventExecutionOrder(
  NarrativeEventRecord record,
  NarrativeEventRegistry registry,
) {
  final definition = record.definitionOrNull;
  if (definition == null) {
    return 'Brouillon : le jeu ne l’examine qu’une fois l’événement configuré.';
  }
  if (definition.parallelPolicy case final parallel?) {
    return 'En parallèle : repris toutes les ${_seconds(parallel.cadenceMs)}, '
        'sans attendre les autres événements de ce déclencheur.';
  }
  final candidates = [
    for (final candidate in narrativeEventDispatchCandidates(
      registry.records,
      definition.source,
      registry.mode,
    ))
      if (candidate.parallelPolicy == null) candidate,
  ];
  final position = candidates.indexWhere(
    (candidate) => candidate.id == record.id,
  );
  if (position < 0) {
    return 'Le projet est en mode historique et cet événement n’y est pas '
        'actif : le jeu ne l’examine pas.';
  }
  final disabled = record.enabledOrNull == false
      ? ' Désactivé : il garde sa place mais le jeu le saute.'
      : '';
  if (candidates.length == 1) {
    return 'Seul événement de ce déclencheur : joué dès que ses conditions '
        'sont remplies.$disabled';
  }
  final before = [
    for (final candidate in candidates.take(position)) '« ${candidate.name} »',
  ];
  final ahead = switch (before.length) {
    0 => '',
    <= 3 => ' Passent avant lui : ${before.join(', ')}.',
    _ =>
      ' Passent avant lui : ${before.take(3).join(', ')} et '
          '${before.length - 3} autres.',
  };
  return 'Examiné en ${_ordinal(position + 1)} sur ${candidates.length} pour '
      'ce déclencheur : un seul événement est joué à chaque déclenchement, le '
      'premier dont les conditions sont remplies.$ahead$disabled';
}

String _ordinal(int value) => value == 1 ? '1er' : '${value}e';

String _seconds(int milliseconds) {
  final seconds = milliseconds / 1000;
  final text = seconds == seconds.roundToDouble()
      ? seconds.toStringAsFixed(0)
      : seconds.toStringAsFixed(1).replaceAll('.', ',');
  return seconds <= 1 ? '$text seconde' : '$text secondes';
}
