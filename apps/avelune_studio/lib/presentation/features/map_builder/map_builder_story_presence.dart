import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_memory/application/game_memory_names.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_resource.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_labels.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_states.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

const _presenceOwners = {
  NarrativeOwnerKind.worldRule,
  NarrativeOwnerKind.scene,
};

class MapBuilderStoryPresence extends StatefulWidget {
  const MapBuilderStoryPresence({
    super.key,
    required this.port,
    required this.mapId,
    required this.characterId,
    required this.saved,
  });

  final NarrativeIndexPort? port;
  final String mapId;
  final String characterId;
  final bool saved;

  @override
  State<MapBuilderStoryPresence> createState() =>
      _MapBuilderStoryPresenceState();
}

class _MapBuilderStoryPresenceState extends State<MapBuilderStoryPresence> {
  late final _port = widget.port;
  late final _names = switch (_port) {
    final port? => GameMemoryNames(port, _changed),
    null => null,
  };
  final _owners = GameMemoryResource<NarrativeUsages>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MapBuilderStoryPresence old) {
    super.didUpdateWidget(old);
    if (old.mapId != widget.mapId ||
        old.characterId != widget.characterId ||
        old.saved != widget.saved) {
      _load(force: true);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _load({bool force = false}) {
    final port = _port;
    if (port == null || !widget.saved) return;
    unawaited(
      _owners.load(
        () async {
          final owners = await port.elementOwners(
            widget.mapId,
            widget.characterId,
          );
          for (final kind in _presenceOwners) {
            unawaited(_names!.ensure(kind.titles));
          }
          return owners;
        },
        _changed,
        force: force,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final owners = _owners.value;
    return StudioSection(
      key: const ValueKey('map-story-presence'),
      title: l10n.memoryPresence,
      children: [
        Text(l10n.memoryPresenceHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: StudioSpacing.m),
        if (_port == null)
          StudioNotice(l10n.memoryUnavailable)
        else if (!widget.saved)
          StudioNotice(l10n.memoryPresenceSaveFirst)
        else if (gameMemoryResourceState(
              context,
              _owners,
              loading: l10n.memoryUsagesLoading,
              onRetry: () => _load(force: true),
            )
            case final state?)
          SizedBox(height: 180, child: state)
        else if (owners != null) ...[
          if (!owners.owners.any(
            (owner) => _presenceOwners.contains(owner.kind),
          ))
            Text(l10n.memoryPresenceEmpty, style: theme.textTheme.bodySmall),
          for (final owner in owners.owners)
            if (_presenceOwners.contains(owner.kind))
              StudioChoice(
                key: ValueKey(
                  'map-story-presence-${owner.kind.name}-${owner.id}',
                ),
                dense: true,
                label: l10n.memoryOwner(
                  owner,
                  _names?.name(owner.kind.titles, owner.id),
                ),
                subtitle: l10n.memoryOwnerKind(owner.kind.name),
                onTap: null,
              ),
          if (owners.notCovered.isNotEmpty) ...[
            const SizedBox(height: StudioSpacing.s),
            StudioNotice(l10n.memoryCoverage(owners.notCovered)),
          ],
        ],
      ],
    );
  }
}
