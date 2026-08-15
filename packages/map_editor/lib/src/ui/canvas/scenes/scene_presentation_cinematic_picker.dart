import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class ScenePresentationCinematicPicker extends StatefulWidget {
  const ScenePresentationCinematicPicker({super.key, required this.cinematics});

  final List<PresentationCinematicAsset> cinematics;

  @override
  State<ScenePresentationCinematicPicker> createState() =>
      _ScenePresentationCinematicPickerState();
}

class _ScenePresentationCinematicPickerState
    extends State<ScenePresentationCinematicPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final visible =
        widget.cinematics
            .where((cinematic) => _matches(cinematic, query))
            .toList(growable: false)
          ..sort((left, right) => left.title.compareTo(right.title));
    final colors = context.pokeMapColors;

    return SizedBox.expand(
      key: const ValueKey('scene-presentation-picker-sheet'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.cinematics.length} cinématique${widget.cinematics.length > 1 ? 's' : ''} compatible${widget.cinematics.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PokeMapButton(
                  key: const ValueKey(
                    'scene-presentation-picker-create-and-link-disabled',
                  ),
                  onPressed: null,
                  disabledReason: 'Disponible dans le lot CIN-039',
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(Icons.add_rounded),
                  child: const Text('Créer et lier'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            PokeMapSearchField(
              key: const ValueKey('scene-presentation-picker-search'),
              hintText: 'Rechercher une cinématique de présentation…',
              semanticLabel: 'Rechercher une cinématique compatible',
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 10),
            const PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.info,
              title: 'Utiliser une cinématique existante',
              message:
                  'La sélection ajoute un nœud typé au graph. Les repères '
                  'd’interaction obligatoires devront ensuite être reliés.',
            ),
            const SizedBox(height: 10),
            Expanded(
              child: visible.isEmpty
                  ? PokeMapEmptyState(
                      key: const ValueKey('scene-presentation-picker-empty'),
                      icon: const Icon(Icons.search_off_rounded),
                      title: query.isEmpty
                          ? 'Aucune cinématique compatible'
                          : 'Aucun résultat',
                      description: query.isEmpty
                          ? 'Créez une cinématique de présentation dans la bibliothèque.'
                          : 'Modifiez la recherche pour afficher une autre cinématique.',
                    )
                  : ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _PresentationCinematicOption(
                            cinematic: visible[index],
                          ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matches(PresentationCinematicAsset cinematic, String query) {
    if (query.isEmpty) return true;
    final searchable = <String>[
      cinematic.title,
      if (cinematic.description != null) cinematic.description!,
      for (final marker in _interactionMarkers(cinematic)) marker.label,
    ].join(' ').toLowerCase();
    return searchable.contains(query);
  }
}

class _PresentationCinematicOption extends StatelessWidget {
  const _PresentationCinematicOption({required this.cinematic});

  final PresentationCinematicAsset cinematic;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final visualClips = _visualClips(cinematic);
    final markers = _interactionMarkers(cinematic);
    final requiredMarkers = markers.where((marker) => marker.required).toList();
    final hasLandscapeAlternative = visualClips.any(
      (clip) => clip.landscapeResourceId != null,
    );
    final hasPortraitAlternative = visualClips.any(
      (clip) => clip.portraitResourceId != null,
    );

    return PokeMapCard(
      key: ValueKey(
        'scene-presentation-picker-option-${_pickerKeyPart(cinematic.id)}',
      ),
      onTap: () => Navigator.of(context).pop(cinematic),
      keyboardInteractive: true,
      semanticLabel: 'Utiliser ${cinematic.title}',
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cinematic.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PokeMapBadge(
                label: _formatDuration(cinematic.durationUs),
                variant: PokeMapBadgeVariant.info,
              ),
            ],
          ),
          if (cinematic.description case final description?) ...[
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              PokeMapBadge(
                label: hasLandscapeAlternative
                    ? 'Paysage · média dédié'
                    : 'Paysage · fallback',
                variant: PokeMapBadgeVariant.success,
              ),
              PokeMapBadge(
                label: hasPortraitAlternative
                    ? 'Portrait · média dédié'
                    : 'Portrait · fallback',
                variant: PokeMapBadgeVariant.success,
              ),
              PokeMapBadge(
                label: markers.isEmpty
                    ? 'Aucune interaction'
                    : '${markers.length} interaction${markers.length > 1 ? 's' : ''}',
                variant: markers.isEmpty
                    ? PokeMapBadgeVariant.neutral
                    : PokeMapBadgeVariant.info,
              ),
            ],
          ),
          if (markers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              markers.map((marker) => marker.label).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (requiredMarkers.isNotEmpty) ...[
            const SizedBox(height: 8),
            PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.warning,
              message:
                  '${requiredMarkers.length} interaction${requiredMarkers.length > 1 ? 's' : ''} obligatoire${requiredMarkers.length > 1 ? 's' : ''} à relier dans cette scène.',
            ),
          ],
        ],
      ),
    );
  }
}

List<PresentationVisualClip> _visualClips(
  PresentationCinematicAsset cinematic,
) {
  return [
    for (final track in cinematic.tracks)
      for (final clip in track.clips)
        if (clip is PresentationVisualClip) clip,
  ];
}

List<PresentationMarkerClip> _interactionMarkers(
  PresentationCinematicAsset cinematic,
) {
  return [
    for (final track in cinematic.tracks)
      for (final clip in track.clips)
        if (clip is PresentationMarkerClip &&
            clip.markerKind == PresentationMarkerKind.interactionCue)
          clip,
  ];
}

String _formatDuration(int durationUs) {
  final totalSeconds = (durationUs / PresentationCinematicAsset.ticksPerSecond)
      .ceil();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String _pickerKeyPart(String value) {
  return value
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
