import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_image.dart';
import '../foundation/player_menu_components.dart';
import '../foundation/player_menu_icon.dart';
import '../foundation/player_paged_layout.dart';
import '../theme/pokemap_player_menu_theme.dart';

class RuntimePlayerContacts extends StatefulWidget {
  const RuntimePlayerContacts({
    super.key,
    required this.snapshot,
    this.onPauseCommand,
  });

  final RuntimePlayerSnapshot snapshot;
  final FutureOr<void> Function(RuntimePlayerPauseCommand)? onPauseCommand;

  @override
  State<RuntimePlayerContacts> createState() => _RuntimePlayerContactsState();
}

class _RuntimePlayerContactsState extends State<RuntimePlayerContacts> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final detail = snapshot.pauseDetailFor(RuntimePlayerPauseSection.contacts);
    final entries = detail?.entries ?? <RuntimePlayerDetailEntrySnapshot>[];
    final selectedId = entries.any((entry) => entry.id == _selectedId)
        ? _selectedId
        : entries.firstOrNull?.id;
    final enabled =
        widget.onPauseCommand != null &&
        snapshot.isActionEnabled(RuntimePlayerAction.callContact);
    final theme = context.playerMenuTheme;
    return PlayerPagedList(
      key: const ValueKey('runtime-player-detail-contacts'),
      children: [
        if (detail?.message case final message?)
          Text(message, style: theme.body),
        for (final contact in entries)
          PlayerMenuSelectableRow(
            key: ValueKey('contact.${contact.id}'),
            id: 'contact.${contact.id}',
            label: contact.title,
            subtitle: contact.subtitle,
            semanticValue: contact.trailingLabel,
            selected: enabled && contact.id == selectedId,
            minimumHeight: 56,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            contentGap: 12,
            labelStyle: theme.label.copyWith(fontSize: 16),
            leading: contact.portraitFilePath == null
                ? const PlayerMenuIcon(PlayerMenuGlyph.phone, size: 24)
                : PlayerImageBuilder(
                    key: ValueKey('contact-portrait-source-${contact.id}'),
                    path: contact.portraitFilePath!,
                    fallback: const PlayerMenuIcon(
                      PlayerMenuGlyph.profile,
                      size: 40,
                    ),
                    builder: (context, image) => RawImage(
                      key: ValueKey('contact-portrait-${contact.id}'),
                      image: image,
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
            supportingContent: contact.progress == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: LinearProgressIndicator(
                      value: contact.progress,
                      color: theme.accent,
                      backgroundColor: theme.recessed,
                    ),
                  ),
            trailingWidth: contact.trailingLabel == null ? 20 : 112,
            trailing: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (contact.trailingLabel case final trailing?) ...[
                  Flexible(child: Text(trailing, style: theme.meta)),
                  const SizedBox(width: 8),
                ],
                const PlayerMenuIcon(PlayerMenuGlyph.chevron, size: 16),
              ],
            ),
            showDisabledReason: false,
            disabledReason: snapshot.unavailableReasonFor(
              RuntimePlayerAction.callContact,
            ),
            onFocusChanged: (focused) {
              if (focused && _selectedId != contact.id) {
                setState(() => _selectedId = contact.id);
              }
            },
            onPressed: !enabled
                ? null
                : () {
                    setState(() => _selectedId = contact.id);
                    widget.onPauseCommand!(
                      RuntimePlayerPauseCommand.callContact(
                        contactId: contact.id,
                      ),
                    );
                  },
          ),
      ],
    );
  }
}
