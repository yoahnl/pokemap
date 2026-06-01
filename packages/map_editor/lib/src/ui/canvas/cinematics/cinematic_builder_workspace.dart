import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class CinematicBuilderWorkspace extends StatelessWidget {
  const CinematicBuilderWorkspace({
    super.key,
    required this.entry,
    required this.onBackToLibrary,
  });

  final CinematicsLibraryEntry entry;
  final VoidCallback onBackToLibrary;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: PokeMapPageSurface(
        key: const ValueKey('cinematic-builder-workspace'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BuilderHeader(entry: entry, onBackToLibrary: onBackToLibrary),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 250,
                    child: _BlockPalette(entry: entry),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _PreviewSandbox(entry: entry)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: _TimelinePlaceholder(entry: entry),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 300,
                    child: _InspectorPlaceholder(entry: entry),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuilderHeader extends StatelessWidget {
  const _BuilderHeader({
    required this.entry,
    required this.onBackToLibrary,
  });

  final CinematicsLibraryEntry entry;
  final VoidCallback onBackToLibrary;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderAction(
          label: 'Retour Library',
          button: PokeMapButton(
            key: const ValueKey('cinematic-builder-back-button'),
            onPressed: onBackToLibrary,
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.chevron_left),
            child: const SizedBox.shrink(),
          ),
        ),
        const SizedBox(width: 10),
        const PokeMapIconTile(
          icon: CupertinoIcons.film,
          tone: PokeMapTone.cinematic,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cinematic Builder V0',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                '${entry.title} • ${entry.id}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  const PokeMapBadge(
                    label: 'Shell read-only',
                    variant: PokeMapBadgeVariant.info,
                  ),
                  PokeMapBadge(
                    label: entry.diagnostics.isEmpty
                        ? 'Aucun diagnostic'
                        : '${entry.diagnostics.length} diagnostic(s)',
                    variant: entry.diagnostics.isEmpty
                        ? PokeMapBadgeVariant.success
                        : PokeMapBadgeVariant.warning,
                  ),
                  PokeMapBadge(
                    label: '${entry.timeline.stepCount} step(s)',
                    variant: PokeMapBadgeVariant.neutral,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            _HeaderAction(
              label: 'Valider',
              button: PokeMapButton(
                key: ValueKey('cinematic-builder-validate-button'),
                onPressed: null,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: Icon(CupertinoIcons.check_mark_circled),
                child: SizedBox.shrink(),
              ),
            ),
            _HeaderAction(
              label: 'Aperçu',
              button: PokeMapButton(
                key: ValueKey('cinematic-builder-preview-button'),
                onPressed: null,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: Icon(CupertinoIcons.play),
                child: SizedBox.shrink(),
              ),
            ),
            _HeaderAction(
              label: 'Sauvegarder',
              button: PokeMapButton(
                key: ValueKey('cinematic-builder-save-button'),
                onPressed: null,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: Icon(CupertinoIcons.tray_arrow_down),
                child: SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.label,
    required this.button,
  });

  final String label;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(width: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DefaultTextStyle.of(context).style.copyWith(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _BlockPalette extends StatelessWidget {
  const _BlockPalette({required this.entry});

  final CinematicsLibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            title: 'Palette de blocs',
            subtitle: 'Visible seulement',
          ),
          const SizedBox(height: 10),
          const PokeMapBadge(
            label: 'Authoring à venir',
            variant: PokeMapBadgeVariant.neutral,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final block in _paletteBlocks) ...[
                    _PaletteBlockTile(block: block),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _MutedText(
            '${entry.timeline.stepCount} bloc(s) lu(s) depuis la timeline.',
          ),
        ],
      ),
    );
  }
}

class _PaletteBlockTile extends StatelessWidget {
  const _PaletteBlockTile({required this.block});

  final _PaletteBlock block;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      child: Row(
        children: [
          PokeMapIconTile(
            icon: block.icon,
            tone: PokeMapTone.neutral,
            size: 30,
            iconSize: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StrongText(block.label),
                const SizedBox(height: 2),
                const _MutedText('Non authorable dans ce lot.'),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            CupertinoIcons.lock_fill,
            color: colors.textMuted,
            size: 13,
          ),
        ],
      ),
    );
  }
}

class _PreviewSandbox extends StatelessWidget {
  const _PreviewSandbox({required this.entry});

  final CinematicsLibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      key: const ValueKey('cinematic-builder-preview-placeholder'),
      expandChild: true,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.rectangle_on_rectangle,
                color: colors.textMuted,
                size: 34,
              ),
              const SizedBox(height: 10),
              Text(
                'Aperçu sandbox',
                textAlign: TextAlign.center,
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'La preview in-engine n’est pas disponible dans ce lot. '
                'Cette zone reste une sandbox visuelle sans runtime.',
                textAlign: TextAlign.center,
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  PokeMapBadge(
                    label: '${entry.timeline.stepCount} step(s)',
                    variant: PokeMapBadgeVariant.neutral,
                  ),
                  PokeMapBadge(
                    label: _durationLabel(entry.timeline),
                    variant: PokeMapBadgeVariant.info,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelinePlaceholder extends StatelessWidget {
  const _TimelinePlaceholder({required this.entry});

  final CinematicsLibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final timeline = entry.timeline;
    return PokeMapPanel(
      key: const ValueKey('cinematic-builder-timeline-placeholder'),
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: timeline.isEmpty
          ? const _EmptyTimelineState()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionTitle(
                    title: 'Déroulé read-only',
                    subtitle: 'Résumé issu du CinematicAsset',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      PokeMapBadge(
                        label: '${timeline.stepCount} step(s)',
                        variant: PokeMapBadgeVariant.info,
                      ),
                      PokeMapBadge(
                        label: _durationLabel(timeline),
                        variant: PokeMapBadgeVariant.neutral,
                      ),
                      if (timeline.actorIds.isEmpty)
                        const PokeMapBadge(
                          label: 'Aucun acteur',
                          variant: PokeMapBadgeVariant.neutral,
                        )
                      else
                        for (final actorId in timeline.actorIds)
                          PokeMapBadge(
                            label: actorId,
                            variant: PokeMapBadgeVariant.narrative,
                          ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (timeline.stepKindLabels.isNotEmpty)
                    _KeyValue(
                      label: 'Types',
                      value: timeline.stepKindLabels.join(', '),
                    ),
                  if (timeline.previewLabels.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    const _MutedText('Aperçu textuel des blocs'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final label in timeline.previewLabels)
                          PokeMapBadge(
                            label: label,
                            variant: PokeMapBadgeVariant.info,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _EmptyTimelineState extends StatelessWidget {
  const _EmptyTimelineState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SectionTitle(
          title: 'Timeline vide',
          subtitle: 'Déroulé read-only',
        ),
        SizedBox(height: 10),
        _BodyText('Cette cinématique ne contient encore aucun bloc.'),
        SizedBox(height: 4),
        _MutedText('La construction de timeline arrive dans un lot futur.'),
      ],
    );
  }
}

class _InspectorPlaceholder extends StatelessWidget {
  const _InspectorPlaceholder({required this.entry});

  final CinematicsLibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      key: const ValueKey('cinematic-builder-inspector-placeholder'),
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle(
              title: 'Inspecteur',
              subtitle: 'Bloc sélectionné',
            ),
            const SizedBox(height: 10),
            const _EmptySelectionCard(),
            const SizedBox(height: 12),
            const _SectionTitle(
              title: 'Métadonnées',
              subtitle: 'Lecture seule',
            ),
            const SizedBox(height: 8),
            _KeyValue(label: 'Titre', value: entry.title),
            _KeyValue(label: 'Id', value: entry.id),
            _KeyValue(
              label: 'Description',
              value: entry.description?.isEmpty ?? true
                  ? 'Aucune description'
                  : entry.description!,
            ),
            _KeyValue(label: 'Map', value: entry.mapId ?? 'Aucune map'),
            _KeyValue(
              label: 'Acteurs',
              value: entry.requiredActors.isEmpty
                  ? 'Aucun acteur requis'
                  : entry.requiredActors
                      .map((actor) => actor.displayLabel)
                      .join(', '),
            ),
            _KeyValue(
              label: 'Timeline',
              value: '${entry.timeline.stepCount} step(s)',
            ),
            _KeyValue(label: 'Durée', value: _durationLabel(entry.timeline)),
            _KeyValue(
              label: 'Usages',
              value: entry.usages.isEmpty
                  ? 'Aucun usage'
                  : entry.usages.map((usage) => usage.sceneTitle).join(', '),
            ),
            const SizedBox(height: 8),
            _DiagnosticsSummary(entry: entry),
          ],
        ),
      ),
    );
  }
}

class _EmptySelectionCard extends StatelessWidget {
  const _EmptySelectionCard();

  @override
  Widget build(BuildContext context) {
    return const PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StrongText('Aucun bloc sélectionné'),
          SizedBox(height: 4),
          _MutedText('Sélection de bloc à venir'),
        ],
      ),
    );
  }
}

class _DiagnosticsSummary extends StatelessWidget {
  const _DiagnosticsSummary({required this.entry});

  final CinematicsLibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    if (entry.diagnostics.isEmpty) {
      return const PokeMapBadge(
        label: 'Aucun diagnostic',
        variant: PokeMapBadgeVariant.success,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final diagnostic in entry.diagnostics) ...[
          PokeMapBadge(
            label: diagnostic.code,
            variant: switch (diagnostic.severity) {
              CinematicsLibraryDiagnosticSeverity.error =>
                PokeMapBadgeVariant.error,
              CinematicsLibraryDiagnosticSeverity.warning =>
                PokeMapBadgeVariant.warning,
              CinematicsLibraryDiagnosticSeverity.info =>
                PokeMapBadgeVariant.info,
            },
          ),
          const SizedBox(height: 6),
          _MutedText(diagnostic.message),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DefaultTextStyle.of(context).style.copyWith(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: DefaultTextStyle.of(context).style.copyWith(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _StrongText extends StatelessWidget {
  const _StrongText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: DefaultTextStyle.of(context).style.copyWith(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      value,
      style: DefaultTextStyle.of(context).style.copyWith(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      value,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: DefaultTextStyle.of(context).style.copyWith(
            color: colors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _PaletteBlock {
  const _PaletteBlock({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

const _paletteBlocks = [
  _PaletteBlock(label: 'Caméra', icon: CupertinoIcons.video_camera),
  _PaletteBlock(
      label: 'Déplacement acteur', icon: CupertinoIcons.person_crop_square),
  _PaletteBlock(label: 'Dialogue', icon: CupertinoIcons.text_bubble),
  _PaletteBlock(label: 'FX', icon: CupertinoIcons.sparkles),
  _PaletteBlock(label: 'Son', icon: CupertinoIcons.speaker_2),
  _PaletteBlock(label: 'Fondu', icon: CupertinoIcons.layers_alt),
  _PaletteBlock(label: 'Attente', icon: CupertinoIcons.timer),
];

String _durationLabel(CinematicTimelineSummary timeline) {
  final duration = timeline.estimatedDurationMs;
  return duration == null ? 'Durée non calculable' : '$duration ms estimé(s)';
}
