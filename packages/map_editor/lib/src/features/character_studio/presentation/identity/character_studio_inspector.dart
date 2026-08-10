import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../character_studio_character_metrics.dart';

class CharacterStudioInspector extends StatelessWidget {
  const CharacterStudioInspector({
    super.key,
    required this.project,
    required this.character,
  });

  final ProjectManifest project;
  final ProjectCharacterEntry? character;

  @override
  Widget build(BuildContext context) {
    final selected = character;
    if (selected == null) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: PokeMapEmptyState(
          title: 'Aucun personnage sélectionné',
          description:
              'Sélectionnez un personnage pour afficher son état et ses références.',
          icon: Icon(CupertinoIcons.slider_horizontal_3),
          compact: true,
        ),
      );
    }
    final report = analyzeCharacterStudioReadiness(
      manifest: project,
      requiredCharacterIds: <String>{selected.id},
    );
    final diagnostics = report.forCharacter(selected.id);
    final tileset = project.tilesets
        .where((entry) => entry.id == selected.tilesetId)
        .firstOrNull;
    final isDefault = project.settings.defaultPlayerCharacterId == selected.id;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(
            title: 'Inspecteur',
            description: 'État de ${selected.name}',
          ),
          const SizedBox(height: 8),
          _InspectorSummary(
            icon: isDefault
                ? CupertinoIcons.game_controller_solid
                : CupertinoIcons.person_crop_circle,
            title: isDefault ? 'Personnage jouable' : 'Personnage non jouable',
            description: tileset?.name ?? 'Planche de sprites introuvable',
            tone: isDefault ? PokeMapTone.success : PokeMapTone.cinematic,
          ),
          const SizedBox(height: 10),
          PokeMapPanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InspectorMetric(
                  label: 'Portraits',
                  value: '${selected.portraits.length}',
                ),
                const SizedBox(height: 8),
                _InspectorMetric(
                  label: 'Animations de base',
                  value: '${characterStudioSystemAnimationCount(selected)}',
                ),
                const SizedBox(height: 8),
                _InspectorMetric(
                  label: 'Animations custom',
                  value: '${characterStudioCustomAnimationCount(selected)}',
                ),
                const SizedBox(height: 8),
                _InspectorMetric(
                  label: 'Frame',
                  value: '${selected.frameWidth} × ${selected.frameHeight}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PokeMapSectionHeader(
            title: 'Validation',
            description: diagnostics.isEmpty
                ? 'Toutes les exigences actives sont satisfaites.'
                : '${diagnostics.length} points demandent votre attention.',
          ),
          const SizedBox(height: 6),
          if (diagnostics.isEmpty)
            const PokeMapBadge(
              label: 'Prêt pour le runtime',
              variant: PokeMapBadgeVariant.success,
              icon: Icon(CupertinoIcons.checkmark_circle_fill),
            )
          else
            for (final diagnostic in diagnostics) ...[
              _InspectorDiagnostic(diagnostic: diagnostic),
              const SizedBox(height: 7),
            ],
          if (selected.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            const PokeMapSectionHeader(title: 'Tags'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in selected.tags) PokeMapBadge(label: tag),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InspectorSummary extends StatelessWidget {
  const _InspectorSummary({
    required this.icon,
    required this.title,
    required this.description,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String description;
  final PokeMapTone tone;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          PokeMapIconTile(icon: icon, tone: tone, size: 40, iconSize: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.pokeMapColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.pokeMapColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorMetric extends StatelessWidget {
  const _InspectorMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: context.pokeMapColors.textMuted,
              fontSize: 10,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: context.pokeMapColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InspectorDiagnostic extends StatelessWidget {
  const _InspectorDiagnostic({required this.diagnostic});

  final CharacterStudioReadinessDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    final isError =
        diagnostic.severity == CharacterStudioReadinessSeverity.error;
    return PokeMapCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError
                ? CupertinoIcons.xmark_octagon_fill
                : CupertinoIcons.exclamationmark_triangle_fill,
            size: 15,
            color: isError
                ? context.pokeMapColors.error
                : context.pokeMapColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _diagnosticLabel(diagnostic),
              style: TextStyle(
                color: context.pokeMapColors.textSecondary,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _diagnosticLabel(CharacterStudioReadinessDiagnostic diagnostic) {
  return switch (diagnostic.code) {
    CharacterStudioReadinessCode.requiredCharacterUnknown =>
      'Le personnage requis est introuvable.',
    CharacterStudioReadinessCode.baseDirectionMissing =>
      'Animation de base ${_directionLabel(diagnostic.direction)} manquante.',
    CharacterStudioReadinessCode.optionalAnimationDirectionMissing =>
      '${_animationLabel(diagnostic.animationState)} est incomplète vers ${_directionLabel(diagnostic.direction)}.',
    CharacterStudioReadinessCode.portraitMissing =>
      'Un état de portrait global n’est pas défini.',
    CharacterStudioReadinessCode.customAnimationMissing =>
      'Une animation custom globale n’est pas définie.',
    CharacterStudioReadinessCode.customAnimationDirectionMissing =>
      'Une direction d’animation custom est manquante.',
  };
}

String _directionLabel(EntityFacing? direction) => switch (direction) {
  EntityFacing.north => 'nord',
  EntityFacing.south => 'sud',
  EntityFacing.east => 'est',
  EntityFacing.west => 'ouest',
  null => 'inconnue',
};

String _animationLabel(CharacterAnimationState? state) => switch (state) {
  CharacterAnimationState.walk => 'La marche',
  CharacterAnimationState.run => 'La course',
  CharacterAnimationState.idle => 'L’animation de base',
  null => 'L’animation',
};
