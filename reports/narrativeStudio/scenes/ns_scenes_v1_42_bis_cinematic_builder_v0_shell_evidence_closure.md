# NS-SCENES-V1-42-bis — Cinematic Builder V0 Shell Evidence Closure

## 1. Résumé exécutif

Ce bis ne modifie pas la feature.

Ce bis ne modifie pas le code.

Ce bis complète uniquement l’Evidence Pack de V1-42.

## 2. Pourquoi ce bis existe

Le rapport V1-42 résumait les fichiers et les diffs. Il ne prouvait pas assez précisément le contenu complet des nouveaux fichiers ni les hunks complets des fichiers modifiés. Ce bis ferme ce trou documentaire en produisant un ticket de caisse complet, sans correction de feature.

## 3. Gate 0

Commande : `pwd`

Exit code : `0`

~~~~text
/Users/karim/Project/pokemonProject
~~~~
Commande : `git branch --show-current`

Exit code : `0`

~~~~text
main
~~~~
Commande : `git status --short --untracked-files=all`

Exit code : `0`

~~~~text
<vide>
~~~~
Commande : `git diff --stat`

Exit code : `0`

~~~~text
<vide>
~~~~
Commande : `git diff --name-only`

Exit code : `0`

~~~~text
<vide>
~~~~
Commande : `git log --oneline -n 10`

Exit code : `0`

~~~~text
c9d44fc8 feat(narrative): add cinematic builder v0 shell (NS-SCENES-V1-42)
38f09efa feat(narrative): add cinematic builder v0 scope and runtime playback contract (NS-SCENES-V1-41)
9e1d45d9 feat(narrative): add cinematic runtime adapter v0 bis evidence closure (NS-SCENES-V1-40)
b39d596f feat(narrative): add cinematic runtime adapter v0 (NS-SCENES-V1-40)
eadb0052 chore(reports): add missing screenshot for V1-15 wire anchor color code
0fe8fa1f feat(narrative): add cinematic scene builder picker v0 (NS-SCENES-V1-39)
6644def0 feat(narrative): add cinematics library v0 (NS-SCENES-V1-38)
05d631f8 feat(narrative): add cinematic asset core model v0 (NS-SCENES-V1-37)
ba7a91f3 update package_config.json
7c4667a4 feat(runtime): finalize cinematic v1 bridge decision and battle auto-switch
~~~~

## 4. Fichiers V1-42 préexistants avant le bis

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_42_cinematic_builder_v0_shell.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Preuve `git ls-files` :

~~~~text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_42_cinematic_builder_v0_shell.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png
~~~~
Le Gate 0 montre un worktree propre avant création du rapport bis. Les fichiers V1-42 listés ci-dessus sont donc préexistants au bis.

## 5. Fichier créé par le bis

- `reports/narrativeStudio/scenes/ns_scenes_v1_42_bis_cinematic_builder_v0_shell_evidence_closure.md`

## 6. Contenu complet — cinematic_builder_workspace.dart

~~~~dart
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
~~~~

## 7. Contenu complet — cinematic_builder_workspace_test.dart

~~~~dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_builder_workspace.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('shows populated read-only cinematic builder shell',
      (tester) async {
    _setLargeSurface(tester);
    final project = _project();
    final before = project.toJson();
    await _pumpBuilder(tester, _entry(project, 'cinematic_intro'));

    expect(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      findsOneWidget,
    );
    expect(find.text('Cinematic Builder V0'), findsOneWidget);
    expect(find.text('Intro cinematic'), findsWidgets);
    expect(find.text('cinematic_intro'), findsWidgets);

    for (final label in <String>[
      'Caméra',
      'Déplacement acteur',
      'Dialogue',
      'FX',
      'Son',
      'Fondu',
      'Attente',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    expect(find.text('Aperçu sandbox'), findsOneWidget);
    expect(find.text('Déroulé read-only'), findsOneWidget);
    expect(find.text('2 step(s)'), findsWidgets);
    expect(find.text('750 ms estimé(s)'), findsWidgets);
    expect(find.text('Camera reveal'), findsWidgets);
    expect(find.text('Professor reacts'), findsWidgets);
    expect(find.text('Aucun bloc sélectionné'), findsOneWidget);
    expect(find.text('Sélection de bloc à venir'), findsOneWidget);
    expect(find.text('actor_professor'), findsWidgets);
    expect(find.text('Canonical scene'), findsWidgets);

    for (final key in <String>[
      'cinematic-builder-validate-button',
      'cinematic-builder-preview-button',
      'cinematic-builder-save-button',
    ]) {
      final button = tester.widget<PokeMapButton>(
        find.byKey(ValueKey<String>(key)),
      );
      expect(button.onPressed, isNull);
    }

    expect(find.text('Ajouter un bloc'), findsNothing);
    expect(project.toJson(), before);
  });

  testWidgets('shows empty timeline state without authoring controls',
      (tester) async {
    _setLargeSurface(tester);
    final project = _project(
      cinematics: [
        CinematicAsset(
          id: 'cinematic_empty',
          title: 'Empty cinematic',
          timeline: CinematicTimeline(),
        ),
      ],
      includeBridge: false,
    );
    await _pumpBuilder(tester, _entry(project, 'cinematic_empty'));

    expect(find.text('Empty cinematic'), findsWidgets);
    expect(find.text('Timeline vide'), findsWidgets);
    expect(
      find.text('Cette cinématique ne contient encore aucun bloc.'),
      findsOneWidget,
    );
    expect(find.text('Aperçu sandbox'), findsOneWidget);
    expect(find.text('Aucun bloc sélectionné'), findsOneWidget);
    expect(find.text('Ajouter un bloc'), findsNothing);
  });

  testWidgets('calls back to library from builder header', (tester) async {
    _setLargeSurface(tester);
    var returned = false;
    await _pumpBuilder(
      tester,
      _entry(_project(), 'cinematic_intro'),
      onBackToLibrary: () => returned = true,
    );

    await tester.tap(
      find.byKey(const ValueKey('cinematic-builder-back-button')),
    );
    await tester.pumpAndSettle();

    expect(returned, isTrue);
  });

  testWidgets('captures V1-42 builder shell screenshot when requested',
      (tester) async {
    if (!const bool.fromEnvironment(
      'NS_SCENES_V1_42_CAPTURE_CINEMATIC_BUILDER',
    )) {
      return;
    }

    _setLargeSurface(tester);
    await _loadScreenshotFonts();
    await _pumpBuilder(tester, _entry(_project(), 'cinematic_intro'));

    final screenshotFile = File(
      '../../reports/narrativeStudio/scenes/screenshots/'
      'ns_scenes_v1_42_cinematic_builder_v0_shell.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('cinematic-builder-workspace')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  });
}

Future<void> _pumpBuilder(
  WidgetTester tester,
  CinematicsLibraryEntry entry, {
  VoidCallback? onBackToLibrary,
}) async {
  await tester.pumpWidget(
    MacosTheme(
      data: MacosThemeData.dark(),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1280,
            height: 860,
            child: CinematicBuilderWorkspace(
              entry: entry,
              onBackToLibrary: onBackToLibrary ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

CinematicsLibraryEntry _entry(ProjectManifest project, String id) {
  final entry = buildCinematicsLibraryReadModel(project).entryById(id);
  if (entry == null) {
    throw StateError('Missing cinematic entry $id');
  }
  return entry;
}

Future<void> _loadScreenshotFonts() async {
  final fontBytes =
      File('/System/Library/Fonts/Supplemental/Arial.ttf').readAsBytesSync();
  for (final family in <String>[
    'Roboto',
    'Arial',
    '.SF Pro Text',
    'SF Pro Text',
  ]) {
    final loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.sublistView(fontBytes)));
    await loader.load();
  }
}

ProjectManifest _project({
  List<CinematicAsset>? cinematics,
  bool includeBridge = true,
}) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'cinematic_project',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(id: 'map_lab', name: 'Lab map', relativePath: 'lab.json'),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    scenes: [
      if (cinematics == null)
        _sceneReferencing(
          id: 'scene_canonical',
          name: 'Canonical scene',
          nodeId: 'node_cinematic',
          nodeTitle: 'Play intro',
          cinematicId: 'cinematic_intro',
        ),
      if (includeBridge)
        _sceneReferencing(
          id: 'scene_bridge',
          name: 'Bridge scene',
          nodeId: 'node_bridge',
          nodeTitle: 'Play bridge',
          cinematicId: 'scenario_cutscene',
        ),
    ],
    scenarios: includeBridge
        ? const <ScenarioAsset>[
            ScenarioAsset(
              id: 'scenario_cutscene',
              name: 'Legacy cutscene',
              scope: ScenarioScope.localEventFlow,
              entryNodeId: 'start',
              metadata: <String, String>{
                'authoring.cutsceneSchema': 'cutscene-studio-v0',
              },
            ),
          ]
        : const <ScenarioAsset>[],
    cinematics: [
      ...?cinematics,
      if (cinematics == null)
        CinematicAsset(
          id: 'cinematic_intro',
          title: 'Intro cinematic',
          description: 'Camera reveal.',
          mapId: 'map_lab',
          requiredActors: [
            CinematicActorRef(
              actorId: 'actor_professor',
              label: 'Professor',
            ),
          ],
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step_camera',
                kind: CinematicTimelineStepKind.camera,
                label: 'Camera reveal',
                durationMs: 500,
              ),
              CinematicTimelineStep(
                id: 'step_emote',
                kind: CinematicTimelineStepKind.actorEmote,
                label: 'Professor reacts',
                durationMs: 250,
                actorId: 'actor_professor',
              ),
            ],
          ),
        ),
    ],
  );
}

SceneAsset _sceneReferencing({
  required String id,
  required String name,
  required String nodeId,
  required String nodeTitle,
  required String cinematicId,
}) {
  return SceneAsset(
    id: id,
    name: name,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: nodeId,
          kind: SceneNodeKind.cinematic,
          title: nodeTitle,
          payload: SceneCinematicPayload(cinematicId: cinematicId),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
    ),
  );
}

void _setLargeSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 860);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
~~~~

## 8. Contenu complet — rapport V1-42

~~~~md
# NS-SCENES-V1-42 — Cinematic Builder V0 Shell

## 1. Statut

`NS-SCENES-V1-42 — Cinematic Builder V0 Shell` est propose DONE.

## 2. Resume

Le Cinematic Builder V0 dispose maintenant d'une coque editor read-only ouverte depuis la Cinematics Library pour les `CinematicAsset` canoniques. Le shell affiche un header, une palette verrouillee, un apercu sandbox, un deroule en lecture seule et un inspecteur placeholder.

## 3. Scope realise

- Navigation Library -> Builder -> Library.
- Ouverture uniquement depuis une entree canonique.
- Bridge legacy visible dans la Library mais exclu du Builder canonique.
- Palette visible et non authorable : Camera, Deplacement acteur, Dialogue, FX, Son, Fondu, Attente.
- Apercu sandbox placeholder, sans player visuel.
- Timeline vide/existante affichee en lecture seule.
- Inspecteur placeholder avec metadonnees, acteurs, usages et diagnostics.
- Boutons Valider, Apercu et Sauvegarder visibles mais inactifs.

## 4. Hors scope confirme

- Aucun modele core modifie.
- Aucune mutation `ProjectManifest` depuis le Builder.
- Aucune edition de timeline.
- Aucune creation, suppression ou reorganisation de step.
- Aucun player visuel.
- Aucune migration legacy.
- Aucun package runtime/gameplay/battle/examples modifie.

## 5. Design Gate

1. Le branchement est local a la Cinematics Library : pas de nouveau `EditorWorkspaceMode`.
2. Le `CinematicAsset` selectionne est relu depuis `buildCinematicsLibraryReadModel` via son id et transmis au `CinematicBuilderWorkspace`.
3. Les bridges legacy restent `scenarioBridge` et ne definissent jamais `_builderEntryId`.
4. Le shell contient header, palette, apercu sandbox, deroule et inspecteur.
5. Toutes les zones sont read-only.
6. Valider/Apercu/Sauvegarder sont inactifs car V1-42 ne valide, ne joue et ne sauvegarde rien depuis le Builder.
7. Retour Library vide seulement l'id local du Builder.
8. L'UI utilise le design system et `context.pokeMapColors`.
9. Il n'y a aucun controle d'authoring timeline.
10. Les tests couvrent navigation, bridge legacy, layout, boutons inactifs, timeline vide et non-mutation.
11. Visual Gate : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png`.

## 6. Architecture

Le Builder consomme un `CinematicsLibraryEntry`, pas un `ProjectManifest`. Cette frontiere rend impossible une mutation de donnees depuis le shell V0 et garde la Library responsable de la resolution canonique/legacy.

## 7. UI

Le shell est compose de :

- `CinematicBuilderWorkspace`
- `_BuilderHeader`
- `_BlockPalette`
- `_PreviewSandbox`
- `_TimelinePlaceholder`
- `_InspectorPlaceholder`

Les elements interactifs du header restent explicites, mais les actions de Builder sont inactives.

## 8. Navigation

La Library ajoute un bouton `Ouvrir le Builder` sur les entrees canoniques. Le bouton retour du Builder appelle `onBackToLibrary`, ce qui remet `_builderEntryId` a `null`.

## 9. Legacy

Les entrees bridge affichent `Builder canonique indisponible` avec un bouton inactif. Elles ne peuvent pas ouvrir le shell canonique.

## 10. Read-only

Le shell n'a aucun callback de sauvegarde, aucun callback d'edition, aucun champ texte et aucun controle de modification de timeline. Les tests verifient aussi que le `ProjectManifest` fixture reste identique apres rendu.

## 11. Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 12. Fichiers ajoutes

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_42_cinematic_builder_v0_shell.md`

## 13. Extraits de diff essentiels

- `CinematicsLibraryWorkspace` ajoute `_builderEntryId`, branche `CinematicBuilderWorkspace` si l'entree est canonique, et ajoute l'action `cinematics-library-open-builder-button`.
- `_BridgeDetailsPanel` ajoute `cinematics-library-legacy-builder-disabled-button`.
- `CinematicBuilderWorkspace` introduit les cinq zones UI read-only et les boutons header inactifs.
- Les tests Library ajoutent le parcours canonique et le verrou legacy.
- Le test Builder direct ajoute layout, etat vide, retour et screenshot gate.

## 14. Gate 0

Commandes lues avant edition :

```text
pwd -> /Users/karim/Project/pokemonProject
git branch --show-current -> main
git status --short --untracked-files=all -> sortie vide
git diff --stat -> sortie vide
git diff --name-only -> sortie vide
```

Dernier commit lu :

```text
38f09efa feat(narrative): add cinematic builder v0 scope and runtime playback contract (NS-SCENES-V1-41)
```

## 15. Tests rouges

`cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart`

Resultat attendu rouge :

```text
Expected: exactly one matching candidate
Actual: Found 0 widgets with key [<'cinematics-library-open-builder-button'>]
Test: opens builder shell for canonical cinematic and returns
Some tests failed.
```

Un lancement parallele d'un second `flutter test` a provoque un verrou Flutter local :

```text
PathExistsException: Cannot create link ... macos_window_utils-1.9.1
```

Il s'agissait d'une collision de tooling, pas d'un comportement produit. Les relances finales ont ete faites sequentiellement.

## 16. Correction intermediaire

Le premier passage du test direct a revele que le bloc `Attente` etait dans un `ListView` non construit sans scroll. La palette a ete basculee vers une colonne scrollable afin que tous les labels requis soient presents dans l'arbre widget.

## 17. Tests verts

`cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart`

```text
00:01 +4: All tests passed!
```

`cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart`

```text
00:02 +7: All tests passed!
```

## 18. Visual Gate

`cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_42_CAPTURE_CINEMATIC_BUILDER=true --reporter=compact test/cinematic_builder_workspace_test.dart`

```text
00:02 +4: All tests passed!
```

Fichier produit :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png
taille : 148681 bytes
```

## 19. Analyze

`cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematics_library_workspace_test.dart test/cinematic_builder_workspace_test.dart`

```text
Analyzing 4 items...
No issues found! (ran in 1.7s)
```

## 20. Gardes anti-scope

`git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples`

```text
sortie vide
```

`rg -n "Color\\(|Colors\\.|0xFF|0xff" packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true`

```text
sortie vide
```

`rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true`

```text
sortie vide
```

`rg -n "add.*Step|remove.*Step|reorder|drag|drop|TimelineEditor|scrubber|keyframe|save.*timeline|copyWith\\(.*timeline" packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematics_library_workspace_test.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true`

```text
sortie vide
```

Garde produit hors lot :

```text
git diff -U0 -- <modified tracked files> --no-ext-diff | rg -n "sel""brume|ma(?:el|ël)|ly""sa|port_""brisants|bourg_""sel""brume|pha""re|bru""me|ma""rais" || true
rg -n "sel""brume|ma(?:el|ël)|ly""sa|port_""brisants|bourg_""sel""brume|pha""re|bru""me|ma""rais" <new V1-42 files> || true
```

```text
sortie vide
```

## 21. Diff hygiene

`git diff --check`

```text
sortie vide
```

## 22. Roadmaps

`road_map_scenes.md` et `road_map_scene_builder_authoring.md` marquent V1-42 DONE et recommandent :

```text
NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0
```

## 23. Non-regressions fonctionnelles

- La creation metadata-only existante reste verte.
- L'edition/suppression metadata Library reste verte.
- Les usages et diagnostics Library restent visibles.
- Les bridges legacy restent visibles et non canoniques.

## 24. Risques residuels

- Les icones Cupertino peuvent apparaitre comme placeholders dans le golden si la police d'icones n'est pas chargee par le runner de test, mais les libelles texte sont lisibles.
- La prochaine etape devra choisir comment representer une selection locale de step sans ouvrir d'authoring.

## 25. Decisions

- Pas de nouveau mode global pour eviter du churn d'etat/generation.
- Pas de dependance runtime.
- Pas de mutation de projet dans le Builder.
- Palette presente mais verrouillee.

## 26. Statut propose

`NS-SCENES-V1-42 — Cinematic Builder V0 Shell` peut etre considere DONE.

## 27. Prochain lot

`NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0`

Objectif recommande : rendre le deroule existant inspectable en lecture seule, avec selection locale de bloc et details contextualises, sans operation de modification.
~~~~

## 9. Preuve de la Visual Gate

La capture n’a pas été régénérée dans ce bis. Elle est prouvée par existence, type PNG et empreinte SHA-256.

Commande : `ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png`

Exit code : `0`

~~~~text
-rw-r--r--  1 karim  staff   145K Jun  1 17:59 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png
~~~~
Commande : `file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png`

Exit code : `0`

~~~~text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png: PNG image data, 1280 x 860, 8-bit/color RGBA, non-interlaced
~~~~
Commande : `shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png`

Exit code : `0`

~~~~text
f5af0a1f7bf91feb3bd9b541f76beacd833f7fe2bdd28820df210710904801fe  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png
~~~~

## 10. Hunks complets — cinematics_library_workspace.dart

~~~~diff
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
index 7731793a..c89efd0a 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
@@ -4,6 +4,7 @@ import 'package:map_core/map_core.dart';
 
 import '../../design_system/design_system.dart';
 import '../../../theme/theme.dart';
+import 'cinematic_builder_workspace.dart';
 
 typedef CreateCinematicShellCallback = Future<String?> Function({
   required String title,
@@ -56,6 +57,7 @@ class _CinematicsLibraryWorkspaceState
 
   _CinematicsLibraryFilter _filter = _CinematicsLibraryFilter.all;
   String? _selectedEntryId;
+  String? _builderEntryId;
   String? _loadedEditorId;
   String? _pendingDeleteId;
   String? _feedback;
@@ -77,6 +79,20 @@ class _CinematicsLibraryWorkspaceState
         ? null
         : readModel.entryById(_selectedEntryId!);
     _syncMetadataEditor(selectedEntry);
+    final builderEntry =
+        _builderEntryId == null ? null : readModel.entryById(_builderEntryId!);
+    if (builderEntry != null &&
+        builderEntry.kind == CinematicsLibraryEntryKind.canonical) {
+      return CinematicBuilderWorkspace(
+        entry: builderEntry,
+        onBackToLibrary: () {
+          setState(() => _builderEntryId = null);
+        },
+      );
+    }
+    if (_builderEntryId != null) {
+      _builderEntryId = null;
+    }
 
     return Material(
       type: MaterialType.transparency,
@@ -335,6 +351,22 @@ class _CinematicsLibraryWorkspaceState
               spacing: 8,
               runSpacing: 8,
               children: [
+                PokeMapButton(
+                  key: const ValueKey(
+                    'cinematics-library-open-builder-button',
+                  ),
+                  onPressed: () {
+                    setState(() {
+                      _builderEntryId = entry.id;
+                      _pendingDeleteId = null;
+                      _feedback = null;
+                    });
+                  },
+                  variant: PokeMapButtonVariant.secondary,
+                  size: PokeMapButtonSize.small,
+                  leading: const Icon(CupertinoIcons.slider_horizontal_3),
+                  child: const Text('Ouvrir le Builder'),
+                ),
                 PokeMapButton(
                   key: const ValueKey('cinematics-library-save-button'),
                   onPressed: () => _saveMetadata(entry),
@@ -740,6 +772,16 @@ class _BridgeDetailsPanel extends StatelessWidget {
               label: 'Migration future',
               variant: PokeMapBadgeVariant.neutral,
             ),
+            const SizedBox(height: 10),
+            const PokeMapButton(
+              key:
+                  ValueKey('cinematics-library-legacy-builder-disabled-button'),
+              onPressed: null,
+              variant: PokeMapButtonVariant.secondary,
+              size: PokeMapButtonSize.small,
+              leading: Icon(CupertinoIcons.lock_fill),
+              child: Text('Builder canonique indisponible'),
+            ),
           ],
         ),
       ),
~~~~

## 11. Hunks complets — cinematics_library_workspace_test.dart

~~~~diff
diff --git a/packages/map_editor/test/cinematics_library_workspace_test.dart b/packages/map_editor/test/cinematics_library_workspace_test.dart
index ba4fe3a1..bca96bff 100644
--- a/packages/map_editor/test/cinematics_library_workspace_test.dart
+++ b/packages/map_editor/test/cinematics_library_workspace_test.dart
@@ -95,6 +95,72 @@ void main() {
     );
   });
 
+  testWidgets('opens builder shell for canonical cinematic and returns',
+      (tester) async {
+    _setLargeSurface(tester);
+    await tester.pumpWidget(_Harness(project: _project()));
+    await tester.pumpAndSettle();
+
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(
+      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
+      findsOneWidget,
+    );
+    await tester.tap(
+      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(
+      find.byKey(const ValueKey('cinematic-builder-workspace')),
+      findsOneWidget,
+    );
+    expect(find.text('Cinematic Builder V0'), findsOneWidget);
+    expect(find.text('Intro cinematic'), findsWidgets);
+    expect(find.text('cinematic_intro'), findsWidgets);
+    expect(find.text('Aperçu sandbox'), findsOneWidget);
+
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-back-button')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(
+      find.byKey(const ValueKey('cinematics-library-workspace')),
+      findsOneWidget,
+    );
+    expect(find.text('Bibliothèque'), findsWidgets);
+  });
+
+  testWidgets('keeps legacy bridge out of canonical builder shell',
+      (tester) async {
+    _setLargeSurface(tester);
+    await tester.pumpWidget(_Harness(project: _project()));
+    await tester.pumpAndSettle();
+
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-entry-scenario_cutscene')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(
+      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
+      findsNothing,
+    );
+    expect(
+      find.text('Bridge legacy — pas un CinematicAsset canonique'),
+      findsOneWidget,
+    );
+    expect(
+      find.byKey(const ValueKey('cinematic-builder-workspace')),
+      findsNothing,
+    );
+  });
+
   testWidgets('edits metadata and deletes only unused canonicals',
       (tester) async {
     _setLargeSurface(tester);
~~~~

## 12. Hunks complets — road_map_scenes.md

~~~~diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 6f807aa1..25bfb995 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -96,12 +96,15 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-39 — Cinematic Scene Builder Picker V0 | DONE | Scene Builder peut ajouter/editer un `CinematicNode` via picker `CinematicAsset` canonique, exposer/connecter `cinematic.completed`, afficher details/diagnostics et signaler les bridges legacy sans les promouvoir. |
 | NS-SCENES-V1-40 — Cinematic Runtime Adapter V0 | DONE | Runtime Scene V1 : `playCinematic(cinematicId)` resout un `CinematicAsset` canonique, passe par un adapter awaitable/player V0, attend la completion reelle, retourne `completed`, preserve les bridges legacy explicites et bloque les refs inconnues sans commit partiel. |
 | NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract | DONE | Lot documentaire : contrat strict du futur Builder V0 comme assembleur no-code de sequences moteur simples, lineaires et sandboxees, plus contrat Runtime Playback V0/V1 borne, sans Builder code, sans timeline editor, sans playback visuel et sans effet gameplay depuis Cinematic. |
+| NS-SCENES-V1-42 — Cinematic Builder V0 Shell | DONE | Shell editor read-only ouvert depuis la Cinematics Library pour les `CinematicAsset` canoniques : header, palette verrouillee, apercu sandbox, deroule et inspecteur placeholders, bridges legacy exclus du Builder canonique, visual gate et tests widget. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-42 — Cinematic Builder V0 Shell`
+`NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0`
 
-Raison : V1-41 a borne le Builder et le playback avant code. Le prochain verrou est de creer seulement le shell du Builder depuis la Library, avec navigation, structure d'ecran et etats vides/diagnostics, sans edition de steps, sans timeline authoring et sans playback visuel.
+Raison : V1-42 a pose la coque navigable du Builder sans mutation. Le prochain verrou est de rendre le deroule plus utile en lecture seule : selection locale de bloc, inspecteur detaille du step existant, diagnostics contextualises et aucune operation de creation/suppression/reordonnancement.
+
+Ordre apres V1-42 : `NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0`.
 
 Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Selbrume Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell.
 
@@ -253,6 +256,18 @@ Limites : aucun code produit, aucun modele Dart, aucun widget Flutter, aucun Bui
 
 Prochain lot exact : `NS-SCENES-V1-42 — Cinematic Builder V0 Shell`.
 
+## Mise a jour V1-42
+
+Statut : `NS-SCENES-V1-42 — Cinematic Builder V0 Shell` est DONE.
+
+Decision : le Cinematic Builder V0 existe comme shell editor local de la Cinematics Library, uniquement pour les `CinematicAsset` canoniques. Il expose une structure claire et read-only : header avec retour Library, palette de blocs verrouillee, apercu sandbox, deroule simplifie et inspecteur placeholder. Les bridges legacy restent visibles dans la Library, mais n'ouvrent pas le Builder canonique.
+
+Scope realise : widget `CinematicBuilderWorkspace`, navigation Library -> Builder -> Library, action Builder sur entree canonique, action indisponible pour bridge legacy, etats timeline vide/existante en lecture seule, boutons Valider/Apercu/Sauvegarder inactifs, screenshot `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png`, tests widget cibles.
+
+Limites : aucune edition de timeline, aucune creation/suppression/reorganisation de step, aucun player visuel, aucune mutation de `ProjectManifest`, aucun modele core, aucun package runtime/gameplay/battle/examples modifie et aucune migration legacy.
+
+Prochain lot exact : `NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0`.
+
 ## Mise a jour V1-30-bis
 
 Statut : `NS-SCENES-V1-30-bis — Scene Node Deletion UX V0` est DONE.
~~~~

## 13. Hunks complets — road_map_scene_builder_authoring.md

~~~~diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 7faec7f8..9e2fcc5b 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-42 — Cinematic Builder V0 Shell
+NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0
 ```
 
 ## Principes
@@ -75,6 +75,7 @@ NS-SCENES-V1-42 — Cinematic Builder V0 Shell
 | NS-SCENES-V1-39 | Cinematic Scene Builder Picker V0 | core / editor | Ajouter/editer un `CinematicNode` depuis un picker `CinematicAsset` canonique et rendre `cinematic.completed` authorable. | Pas de Builder V2, pas de timeline editor, pas de runtime cinematic, pas de migration legacy, pas de bridge selectionnable en workflow normal. | operations Scene cinematic, picker/inspector Scene Builder, diagnostics, tests core/editor, visual gate. | DONE : canonical-only, bridge legacy warning, completed port, tests/analyze, screenshot. | Promouvoir les bridges Scenario comme choix normal ; laisser entrer des cinematicId libres. | DONE : CinematicNode honnete, editable et connectable sans fake ref. | V1-38. |
 | NS-SCENES-V1-40 | Cinematic Runtime Adapter V0 | runtime / integration | Remplacer l'ack cinematic bridge par un adapter awaitable qui resout un `CinematicAsset` canonique, attend une completion reelle et retourne `completed`. | Pas de Builder V2, pas de timeline editor UI, pas de migration ScenarioAsset, pas de playback visuel complet, pas d'effets gameplay depuis cinematic. | adapter cinematic runtime, result/request/player V0, wiring PlayableMapGame, tests hook no partial writes, rapport. | DONE : canonical awaitable, bridge legacy explicite, unknown failed, consequences post-cinematic commit apres completion, tests/analyze. | Continuer a ack immediatement ; traiter scenarioBridge comme canonical ; laisser une cinematic ecrire le monde. | DONE : pont runtime propre Scene -> CinematicAsset -> completed. | V1-39. |
 | NS-SCENES-V1-41 | Cinematic Builder V0 Scope / Runtime Playback Contract | doc / architecture-review | Cadrer le futur Builder V0 et le futur contrat Runtime Playback avant de coder l'UI, la timeline, les blocs authorables ou le player visuel. | Pas de code Dart, pas de widget, pas de timeline editor, pas de playback visuel, pas de migration ScenarioAsset, pas d'effet gameplay cinematic. | rapport V1-41, roadmaps. | DONE : rapport contractuel, capability matrix, taxonomie blocs, frontieres anti-scope, `git diff --check`. | Coder le Builder trop tot ; refaire ScenarioAsset ; ouvrir branches/failures authorables ; laisser Cinematic ecrire le monde. | DONE : Builder V0 = assembleur lineaire sandboxe ; Runtime Playback V0/V1 = lecture bornee sans gameplay effect ; prochain lot shell seulement. | V1-40. |
+| NS-SCENES-V1-42 | Cinematic Builder V0 Shell | editor / ui-shell | Ouvrir un shell Builder depuis la Cinematics Library pour un `CinematicAsset` canonique, avec zones read-only et navigation retour. | Pas de timeline editor, pas de mutation `ProjectManifest`, pas de preview runtime, pas de migration bridge, pas de modele core. | `cinematic_builder_workspace.dart`, `cinematics_library_workspace.dart`, tests widget, rapport, screenshot. | DONE : Library -> Builder -> retour, bridge legacy exclu, palette/preview/deroule/inspecteur visibles, boutons inactifs, visual gate, analyze cible. | Confondre shell et authoring ; promouvoir bridge legacy ; laisser croire que la preview est jouable. | DONE : shell V0 lisible, strictement read-only et canonique-only. | V1-41. |
 
 ## Options comparees
 
@@ -669,6 +670,18 @@ Limites : aucun Builder code, aucune timeline editor, aucun widget, aucun modele
 
 Prochain lot exact : `NS-SCENES-V1-42 — Cinematic Builder V0 Shell`.
 
+## Mise a jour V1-42
+
+Statut : `NS-SCENES-V1-42 — Cinematic Builder V0 Shell` est DONE.
+
+Decision : le Builder V0 est branche comme surface read-only depuis la Cinematics Library, sans nouveau mode global et sans toucher aux contrats core/runtime. Il consomme le read model de Library, ouvre seulement les entrees `CinematicAsset` canoniques et laisse les bridges legacy dans un etat explicite non ouvrable.
+
+Scope realise : header, retour Library, titre/id selectionnes, resume diagnostics, palette de blocs verrouillee, apercu sandbox, deroule read-only, inspecteur placeholder, etats timeline vide/existante, boutons Valider/Apercu/Sauvegarder inactifs, screenshot V1-42 et tests widget dedies.
+
+Limites : pas de creation de blocs, pas de suppression de blocs, pas de reorganisation de timeline, pas de player visuel, pas de mutation `ProjectManifest`, pas de nouveau modele et pas de package runtime/gameplay/battle/examples modifie.
+
+Prochain lot exact : `NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0`.
+
 ## Selbrume golden slice
 
 Avant le golden slice, il faut au minimum :
~~~~

## 14. Tests relancés

Commande : `cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart`

Exit code : `0`

~~~~text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart                                                                                   
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart                                                                                   
00:01 +0: shows populated read-only cinematic builder shell                                                                                                                                            
00:01 +1: shows populated read-only cinematic builder shell                                                                                                                                            
00:01 +1: shows empty timeline state without authoring controls                                                                                                                                        
00:01 +2: shows empty timeline state without authoring controls                                                                                                                                        
00:01 +2: calls back to library from builder header                                                                                                                                                    
00:01 +3: calls back to library from builder header                                                                                                                                                    
00:01 +3: captures V1-42 builder shell screenshot when requested                                                                                                                                       
00:01 +4: captures V1-42 builder shell screenshot when requested                                                                                                                                       
00:01 +4: All tests passed!                                                                                                                                                                            
~~~~
Commande : `cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart`

Exit code : `0`

~~~~text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart                                                                                  
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart                                                                                  
00:01 +0: shows empty state and creates a cinematic shell                                                                                                                                              
00:01 +1: shows empty state and creates a cinematic shell                                                                                                                                              
00:01 +1: lists canonical and bridge entries with read-only details                                                                                                                                    
00:01 +2: lists canonical and bridge entries with read-only details                                                                                                                                    
00:01 +2: shows timeline summary and scene usages for canonical entry                                                                                                                                  
00:02 +2: shows timeline summary and scene usages for canonical entry                                                                                                                                  
00:02 +3: shows timeline summary and scene usages for canonical entry                                                                                                                                  
00:02 +3: opens builder shell for canonical cinematic and returns                                                                                                                                      
00:02 +4: opens builder shell for canonical cinematic and returns                                                                                                                                      
00:02 +4: keeps legacy bridge out of canonical builder shell                                                                                                                                           
00:02 +5: keeps legacy bridge out of canonical builder shell                                                                                                                                           
00:02 +5: edits metadata and deletes only unused canonicals                                                                                                                                            
00:02 +6: edits metadata and deletes only unused canonicals                                                                                                                                            
00:02 +6: captures V1-38 Cinematics Library screenshot when requested                                                                                                                                  
00:02 +7: captures V1-38 Cinematics Library screenshot when requested                                                                                                                                  
00:02 +7: All tests passed!                                                                                                                                                                            
~~~~

## 15. Analyze relancé

Commande : `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematics_library_workspace_test.dart test/cinematic_builder_workspace_test.dart`

Exit code : `0`

~~~~text
Analyzing 4 items...                                            
No issues found! (ran in 1.0s)
~~~~

## 16. Checks anti-scope

### Packages hors scope

Commande : `git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples`

Exit code : `0`

~~~~text
<vide>
~~~~
### Anti-runtime UI

Commande : `rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true`

Exit code : `0`

~~~~text
<vide>
~~~~
### Anti-authoring timeline

Commande : `rg -n "add.*Step|remove.*Step|reorder|drag|drop|TimelineEditor|scrubber|keyframe|save.*timeline|copyWith\(.*timeline" packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematics_library_workspace_test.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true`

Exit code : `0`

~~~~text
<vide>
~~~~
### Anti-couleurs hardcodees

Commande : `rg -n "Color\(|Colors\.|0xFF|0xff" packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true`

Exit code : `0`

~~~~text
<vide>
~~~~
### Anti-donnees produit nommees

Commande : `rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematics_library_workspace_test.dart packages/map_editor/test/cinematic_builder_workspace_test.dart reports/narrativeStudio/scenes/ns_scenes_v1_42_cinematic_builder_v0_shell.md || true`

Exit code : `0`

~~~~text
reports/narrativeStudio/scenes/ns_scenes_v1_42_cinematic_builder_v0_shell.md:207:git diff -U0 -- <modified tracked files> --no-ext-diff | rg -n "sel""brume|ma(?:el|ël)|ly""sa|port_""brisants|bourg_""sel""brume|pha""re|bru""me|ma""rais" || true
reports/narrativeStudio/scenes/ns_scenes_v1_42_cinematic_builder_v0_shell.md:208:rg -n "sel""brume|ma(?:el|ël)|ly""sa|port_""brisants|bourg_""sel""brume|pha""re|bru""me|ma""rais" <new V1-42 files> || true
~~~~
Note critique : le check anti-données produit nommées renvoie deux lignes du rapport V1-42, où celui-ci cite ses propres commandes de garde anti-scope avec des fragments de regex. Les fichiers de code et de test V1-42 ne ressortent pas. Le bis ne modifie pas le rapport V1-42 car le plan l’interdit.

## 17. Git diff --check final

Commande : `git diff --check`

Exit code : `0`

~~~~text
<vide>
~~~~

## 18. Git diff --stat final

Commande : `git diff --stat`

Exit code : `0`

~~~~text
<vide>
~~~~

## 19. Git diff --name-only final

Commande : `git diff --name-only`

Exit code : `0`

~~~~text
<vide>
~~~~

## 20. Git status final

Commande : `git status --short --untracked-files=all`

Exit code : `0`

~~~~text
?? reports/narrativeStudio/scenes/ns_scenes_v1_42_bis_cinematic_builder_v0_shell_evidence_closure.md
~~~~

## 21. Auto-review critique

- 1. Est-ce que le bis a modifié du code produit ? Non. Le statut final ne contient que le rapport bis non tracké.
- 2. Est-ce que les nouveaux fichiers V1-42 sont reproduits intégralement ? Oui. Les trois fichiers texte nouveaux de V1-42 sont reproduits en sections 6, 7 et 8.
- 3. Est-ce que les hunks des fichiers modifiés sont suffisamment complets ? Oui. Les hunks V1-42 sont reproduits depuis `git diff HEAD~1 HEAD` pour les quatre fichiers modifiés.
- 4. Est-ce que la Visual Gate est prouvée ? Oui. `ls -lh`, `file` et `shasum -a 256` sont reproduits.
- 5. Est-ce que les tests V1-42 passent encore ? Oui. Les deux commandes `flutter test --reporter=compact` ont un exit code 0.
- 6. Est-ce que l’analyze ciblé passe encore ? Oui. `flutter analyze --no-fatal-infos` a un exit code 0 et affiche `No issues found!`.
- 7. Est-ce qu’aucun package hors map_editor n’est modifié ? Oui. Le check `git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples` est vide.
- 8. Est-ce qu’aucun runtime n’est couplé au shell ? Oui. Le check anti-runtime UI est vide.
- 9. Est-ce qu’aucune édition de timeline n’a été ajoutée ? Oui. Le check anti-authoring timeline est vide.
- 10. Est-ce qu’aucune couleur hardcodée n’a été ajoutée ? Oui. Le check anti-couleurs hardcodées est vide.
- 11. Est-ce qu’aucune donnée Selbrume n’apparaît ? Oui pour le code, les tests et les données produit. Le rapport V1-42 contient deux lignes de commande anti-scope qui citent des fragments de regex ; ce bis les documente et ne les modifie pas.
- 12. Est-ce que V1-42 peut être commité ? Oui : V1-42 est déjà le commit `c9d44fc8` en HEAD au Gate 0. Le bis ajoute seulement un rapport non tracké.

## 22. Verdict de clôture V1-42

V1-42 est clôturable fonctionnellement et techniquement : tests ciblés verts, analyze ciblé vert, Visual Gate prouvée, code produit non modifié par le bis. Le seul point critique est documentaire : le check anti-données produit nommées appliqué au rapport V1-42 ressort sur deux lignes qui citent une commande de garde anti-scope. Ce n’est pas une donnée produit ni un couplage code, et le bis n’a pas le droit de modifier ce rapport.
