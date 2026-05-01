part of 'path_studio_panel.dart';

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.48)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MacosIcon(icon, size: 12, color: PathStudioTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: PathStudioTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SidebarCounter extends StatelessWidget {
  const _SidebarCounter({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: PathStudioTheme.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: PathStudioTheme.accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$value',
        style: const TextStyle(
          color: PathStudioTheme.accentHover,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SidebarNotice extends StatelessWidget {
  const _SidebarNotice({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: PathStudioTheme.subtleDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MacosIcon(
              CupertinoIcons.tray,
              color: PathStudioTheme.textMuted,
              size: 26,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _presetCardHasCenterOnlyBadge(PathPatternPresetCardModel card) {
  return card.issues.contains(PathPatternDiagnosticCode.centerOnly);
}

bool _presetCardHasPartialVariantsBadge(PathPatternPresetCardModel card) {
  return card.issues.contains(PathPatternDiagnosticCode.partialVariantCoverage);
}

class _PresetListCard extends StatefulWidget {
  const _PresetListCard({
    super.key,
    required this.card,
    required this.selected,
    required this.onTap,
  });

  final PathPatternPresetCardModel card;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PresetListCard> createState() => _PresetListCardState();
}

class _PresetListCardState extends State<_PresetListCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final status = _statusPresentation(widget.card.status);
    final borderColor = widget.selected
        ? PathStudioTheme.accentHover
        : widget.card.status == PathPatternPresetReadinessStatus.blocked
            ? PathStudioTheme.error.withValues(alpha: 0.45)
            : PathStudioTheme.border;
    final fill = widget.selected
        ? Color.lerp(
            PathStudioTheme.surfaceStrong, PathStudioTheme.accent, 0.2)!
        : _hovered
            ? Color.lerp(
                PathStudioTheme.surfaceRaised,
                PathStudioTheme.accent,
                0.08,
              )!
            : PathStudioTheme.surfaceRaised;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: borderColor, width: widget.selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PathStudioTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusChip(label: status.label, color: status.color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.card.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PathStudioTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Base : ${widget.card.basePathPresetName ?? widget.card.basePathPresetId} · ${widget.card.centerPatternLabel}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PathStudioTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _StatusChip(
                    label: widget.card.animatedCellCount > 0
                        ? 'Animé'
                        : 'Statique',
                    color: widget.card.animatedCellCount > 0
                        ? PathStudioTheme.accentCyan
                        : PathStudioTheme.textMuted,
                  ),
                  if (_presetCardHasCenterOnlyBadge(widget.card))
                    const _StatusChip(
                      label: 'Centre uniquement',
                      color: PathStudioTheme.accent,
                    ),
                  if (_presetCardHasPartialVariantsBadge(widget.card))
                    const _StatusChip(
                      label: 'Variants partiels',
                      color: PathStudioTheme.warning,
                    ),
                ],
              ),
              if (widget.card.hasBlockingDiagnostics ||
                  widget.card.warningCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  widget.card.hasBlockingDiagnostics
                      ? pluralizeFr(
                          widget.card.diagnostics
                              .where(
                                (d) =>
                                    d.severity ==
                                    PathPatternDiagnosticSeverity.blocking,
                              )
                              .length,
                          'blocage',
                          'blocages',
                        )
                      : pluralizeFr(
                          widget.card.warningCount,
                          'warning',
                          'warnings',
                        ),
                  style: TextStyle(
                    color: widget.card.hasBlockingDiagnostics
                        ? PathStudioTheme.error
                        : PathStudioTheme.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NewPathDraftListCard extends StatelessWidget {
  const _NewPathDraftListCard({
    required this.draft,
    required this.selected,
    required this.onTap,
  });

  final PathStudioNewPathDraft draft;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const Key('path-studio-new-path-draft-card'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? Color.lerp(
                  PathStudioTheme.surfaceStrong,
                  PathStudioTheme.accentCyan,
                  0.22,
                )
              : PathStudioTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? PathStudioTheme.accentCyan
                : PathStudioTheme.accentCyan.withValues(alpha: 0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PathStudioTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusChip(
                  label: draft.isEditMode ? 'Modification' : 'Nouveau chemin',
                  color: PathStudioTheme.accentCyan,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              draft.isEditMode
                  ? 'Modification • Mémoire uniquement'
                  : 'Nouveau • Mémoire uniquement',
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MiniMetric(
                  icon: CupertinoIcons.square_grid_2x2,
                  label: draft.centerPatternLabel,
                ),
                const SizedBox(width: 8),
                const _MiniMetric(
                  icon: CupertinoIcons.wand_stars,
                  label: 'à configurer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftListCard extends StatelessWidget {
  const _DraftListCard({
    required this.draft,
    required this.selected,
    required this.onTap,
  });

  final PathPatternDraft draft;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const Key('path-studio-draft-card'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? Color.lerp(
                  PathStudioTheme.surfaceStrong,
                  PathStudioTheme.accentCyan,
                  0.22,
                )
              : PathStudioTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? PathStudioTheme.accentCyan
                : PathStudioTheme.accentCyan.withValues(alpha: 0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PathStudioTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const _StatusChip(
                  label: 'Depuis path existant',
                  color: PathStudioTheme.accentCyan,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Structure héritée • Mémoire uniquement',
              style: TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MiniMetric(
                  icon: CupertinoIcons.square_grid_2x2,
                  label: draft.centerPatternLabel,
                ),
                const SizedBox(width: 8),
                _MiniMetric(
                  icon: draft.animatedCellCount > 0
                      ? CupertinoIcons.play_circle
                      : CupertinoIcons.circle,
                  label: draft.animatedCellCount > 0 ? 'Animé' : 'Statique',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
