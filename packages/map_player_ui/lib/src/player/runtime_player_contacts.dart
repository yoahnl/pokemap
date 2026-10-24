import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_image.dart';
import '../foundation/player_paged_layout.dart';

class RuntimePlayerContacts extends StatelessWidget {
  const RuntimePlayerContacts({
    super.key,
    required this.snapshot,
    this.onPauseCommand,
  });

  final RuntimePlayerSnapshot snapshot;
  final FutureOr<void> Function(RuntimePlayerPauseCommand)? onPauseCommand;

  @override
  Widget build(BuildContext context) {
    final detail = snapshot.pauseDetailFor(RuntimePlayerPauseSection.contacts);
    return PlayerPagedList(
      key: const ValueKey('runtime-player-detail-contacts'),
      children: [
        for (final contact
            in detail?.entries ?? <RuntimePlayerDetailEntrySnapshot>[])
          PlayerActionButton(
            key: ValueKey('contact.${contact.id}'),
            label: contact.title,
            icon: Icons.contact_phone_outlined,
            trailing: contact.portraitFilePath == null
                ? null
                : PlayerImageBuilder(
                    path: contact.portraitFilePath!,
                    builder: (context, image) => RawImage(
                      image: image,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                  ),
            onPressed:
                onPauseCommand != null &&
                    snapshot.isActionEnabled(RuntimePlayerAction.callContact)
                ? () => onPauseCommand!(
                    RuntimePlayerPauseCommand.callContact(
                      contactId: contact.id,
                    ),
                  )
                : null,
          ),
      ],
    );
  }
}
