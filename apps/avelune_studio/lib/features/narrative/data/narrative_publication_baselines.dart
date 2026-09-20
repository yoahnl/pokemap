import 'package:map_core/map_core_domain.dart';

import '../domain/narrative_port.dart';

void validateNarrativePublicationBases(
  NarrativePublication publication,
  ProjectManifest project,
) {
  _validate(publication.expectedEvents, {
    for (final value
        in project.eventRegistry?.records ?? <NarrativeEventRecord>[])
      value.id: value,
  }, 'L’événement');
  _validate(publication.expectedScenes, {
    for (final value in project.scenes) value.id: value,
  }, 'La scène liée');
  _validate(publication.expectedCinematics, {
    for (final value in project.cinematics) value.id: value,
  }, 'La cinématique liée');
  _validate(publication.expectedDialogues, {
    for (final value in project.dialogues) value.id: value,
  }, 'Le dialogue lié');
  _validate(publication.expectedFacts, {
    for (final value in project.facts) value.id: value,
  }, 'Le fait');
  _validate(publication.expectedStorylines, {
    for (final value in project.storylines) value.id: value,
  }, 'L’histoire');
}

void _validate<T>(
  Map<String, T?> expected,
  Map<String, T> actual,
  String label,
) {
  for (final entry in expected.entries) {
    if (actual[entry.key] != entry.value) {
      throw NarrativeFailure(
        '$label a changé sur le disque. Votre brouillon est conservé ; rechargez la version actuelle avant de poursuivre.',
      );
    }
  }
}
