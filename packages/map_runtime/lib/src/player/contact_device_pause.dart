import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'runtime_player_pause_data.dart';
import '../application/dialogue_portrait_resolver.dart';

RuntimePlayerPauseDetailSnapshot? buildContactDevicePauseDetail({
  required ProjectManifest project,
  required GameState state,
  DialoguePortraitLookup? portraitLookup,
}) {
  final access = ContactDeviceAccess.resolve(project: project, state: state);
  if (!access.isAcquired) return null;
  return RuntimePlayerPauseDetailSnapshot(
    section: RuntimePlayerPauseSection.contacts,
    title: access.configuration!.label,
    emptyMessage: access.configuration!.emptyMessage,
    entries: [
      for (final contact in access.contacts)
        RuntimePlayerDetailEntrySnapshot(
          id: contact.id,
          title: contact.label,
          portraitFilePath: _portrait(project, contact, portraitLookup),
        ),
    ],
  );
}

String? _portrait(
  ProjectManifest project,
  ProjectContactEntryConfig contact,
  DialoguePortraitLookup? lookup,
) {
  final character = project.characters
      .where((c) => c.id == contact.characterId)
      .firstOrNull;
  if (character == null || character.portraits.isEmpty) return null;
  return lookup
      ?.call(
        characterId: character.id,
        portraitStateId: character.portraits.first.portraitStateId,
      )
      ?.absoluteFilePath;
}
