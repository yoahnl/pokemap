import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_binding.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

String mapBuilderTrackName(String path) {
  final name = p.basenameWithoutExtension(path);
  final folder = p.basename(p.dirname(path));
  return folder.isEmpty || folder == '.' || folder == 'audio'
      ? name
      : '$folder · $name';
}

class MapBuilderMusicForm extends StatefulWidget {
  const MapBuilderMusicForm({
    super.key,
    required this.binding,
    required this.enabled,
  });

  final MapBuilderAmbianceBinding binding;
  final bool enabled;

  @override
  State<MapBuilderMusicForm> createState() => _MapBuilderMusicFormState();
}

class _MapBuilderMusicFormState extends State<MapBuilderMusicForm> {
  late final _search = TextEditingController(text: widget.binding.audioQuery);
  double? _dragVolume;
  Timer? _searchDelay;

  @override
  void dispose() {
    _searchDelay?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _searchLater(String query) {
    _searchDelay?.cancel();
    _searchDelay = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(widget.binding.searchAudio(query)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final binding = widget.binding;
    final enabled = widget.enabled;
    final metadata = binding.metadata;
    if (metadata == null) return const SizedBox.shrink();
    final music = metadata.musicPath;
    final battle = metadata.battleMusicPath;
    final volume =
        _dragVolume ?? metadata.musicVolume ?? mapBuilderDefaultMusicVolume;
    final current = binding.musicSlot == MapMusicSlot.battle ? battle : music;
    return Column(
      key: const ValueKey('map-ambiance-music'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Eyebrow(l10n.musicExploration),
        const SizedBox(height: StudioSpacing.xs),
        _Slot(
          key: const ValueKey('map-ambiance-music-slot-exploration'),
          icon: Icons.music_note_outlined,
          label: music == null ? l10n.musicNone : mapBuilderTrackName(music),
          selected: binding.musicSlot == MapMusicSlot.exploration,
          onTap: () => binding.selectMusicSlot(MapMusicSlot.exploration),
        ),
        if (music != null)
          StudioSlider(
            key: const ValueKey('map-ambiance-music-volume'),
            label: l10n.musicVolume,
            value: volume,
            divisions: 20,
            valueLabel: '${(volume * 100).round()} %',
            onChangeStart: enabled
                ? (value) => setState(() => _dragVolume = value)
                : null,
            onChanged: enabled
                ? (value) => setState(() => _dragVolume = value)
                : null,
            onChangeEnd: enabled
                ? (value) {
                    setState(() => _dragVolume = null);
                    binding.setMusicVolume(value);
                  }
                : null,
          ),
        const SizedBox(height: StudioSpacing.m),
        _Eyebrow(l10n.musicBattle),
        const SizedBox(height: StudioSpacing.xs),
        _Slot(
          key: const ValueKey('map-ambiance-music-slot-battle'),
          icon: Icons.sports_martial_arts_outlined,
          label: battle == null
              ? l10n.musicBattleProject
              : mapBuilderTrackName(battle),
          selected: binding.musicSlot == MapMusicSlot.battle,
          onTap: () => binding.selectMusicSlot(MapMusicSlot.battle),
        ),
        const SizedBox(height: StudioSpacing.xl),
        _Eyebrow(
          binding.musicSlot == MapMusicSlot.battle
              ? l10n.musicChooseBattle
              : l10n.musicChooseExploration,
        ),
        const SizedBox(height: StudioSpacing.s),
        StudioSearchField(
          key: const ValueKey('map-ambiance-music-search'),
          controller: _search,
          label: l10n.musicSearch,
          onChanged: _searchLater,
        ),
        const SizedBox(height: StudioSpacing.s),
        StudioChoice(
          key: const ValueKey('map-ambiance-music-track-none'),
          dense: true,
          label: binding.musicSlot == MapMusicSlot.battle
              ? l10n.musicBattleProject
              : l10n.musicNone,
          selected: current == null,
          onTap: enabled ? () => binding.chooseMusic(null) : null,
        ),
        for (final entry in binding.audio)
          StudioChoice(
            key: ValueKey('map-ambiance-music-track-${entry.id}'),
            dense: true,
            label: mapBuilderTrackName(entry.path!),
            selected: entry.path == current,
            onTap: enabled ? () => binding.chooseMusic(entry.path) : null,
          ),
        ..._status(context, l10n),
      ],
    );
  }

  List<Widget> _status(BuildContext context, AppLocalizations l10n) {
    final binding = widget.binding;
    if (binding.audioError case final error?) {
      return [
        const SizedBox(height: StudioSpacing.s),
        StudioNotice(error, isError: true),
      ];
    }
    if (binding.audioLoading) {
      return [
        const SizedBox(height: StudioSpacing.s),
        _Caption(l10n.musicLoading),
      ];
    }
    if (binding.audioLoaded && binding.audio.isEmpty) {
      return [
        const SizedBox(height: StudioSpacing.s),
        _Caption(
          binding.audioQuery.trim().isEmpty
              ? l10n.musicLibraryEmpty
              : l10n.musicNoMatch,
        ),
      ];
    }
    if (binding.audioMore) {
      return [
        const SizedBox(height: StudioSpacing.s),
        StudioButton(
          key: const ValueKey('map-ambiance-music-more'),
          variant: StudioButtonVariant.quiet,
          label: l10n.musicMore,
          onPressed: () => binding.loadAudio(more: true),
        ),
      ];
    }
    return const [];
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => StudioChoice(
    dense: true,
    leading: Icon(icon, size: 16),
    label: label,
    selected: selected,
    onTap: onTap,
  );
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1,
      ),
    );
  }
}
