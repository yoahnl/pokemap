// Surface Studio — shell UI lecture seule (Lot 52).
//
// Consomme un [SurfaceStudioReadModel] déjà construit côté [map_core] : pas de
// re-diagnostic, pas de mutation manifest, pas d’I/O. Les actions futures sont
// désactivées ; les sections listées sont des placeholders pour les Lots 53+.

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

/// Panneau présentationnel **lecture seule** pour Surface Studio.
class SurfaceStudioPanel extends StatelessWidget {
  const SurfaceStudioPanel({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  static const String titleText = 'Surface Studio';
  static const String readOnlyBadgeText = 'Lecture seule';
  static const String productDescriptionText =
      'Préparez et contrôlez les surfaces animées du projet : eau, lave, glace, hautes herbes.';
  static const String emptyStateTitle =
      'Aucun catalogue Surface pour le moment';
  static const String emptyStateHint =
      'Les prochains lots permettront de créer des atlas, animations et presets.';
  static const String catalogDetectedText = 'Catalogue Surface détecté';
  static const String diagnosticsCleanText = 'Aucun diagnostic Surface';
  static const String diagnosticsErrorsText = 'Erreurs Surface détectées';
  static const String diagnosticsWarningsText =
      'Avertissements Surface détectés';
  static const String placeholderCatalogTitle = 'Catalogue';
  static const String placeholderDiagnosticsTitle = 'Diagnostics';
  static const String placeholderActionsTitle = 'Actions auteur';
  static const String placeholderSoonText = 'Bientôt';
  static const String actionCreateAtlasLabel = 'Créer un atlas';
  static const String actionImportVerticalAtlasLabel =
      'Importer un atlas vertical';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = readModel.summary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                titleText,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              const _ReadOnlyBadge(label: readOnlyBadgeText),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            productDescriptionText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dans ce lot, il s’agit d’une vue de lecture et de préparation '
            'uniquement : aucune création, édition, suppression ou sauvegarde.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 20),
          _CounterRow(
            atlas: s.atlasCount,
            animations: s.animationCount,
            presets: s.presetCount,
          ),
          const SizedBox(height: 16),
          if (readModel.isEmpty) ...[
            const _EmptyStateCard(
              title: emptyStateTitle,
              subtitle: emptyStateHint,
            ),
          ] else ...[
            Text(
              catalogDetectedText,
              style: theme.textTheme.titleMedium,
            ),
          ],
          const SizedBox(height: 16),
          _DiagnosticsSummary(
            readModel: readModel,
            theme: theme,
          ),
          const SizedBox(height: 20),
          const _FutureActions(
            onCreateAtlas: null,
            onImportVertical: null,
          ),
          const SizedBox(height: 24),
          _SectionPlaceholder(
            title: placeholderCatalogTitle,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _SectionPlaceholder(
            title: placeholderDiagnosticsTitle,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _SectionPlaceholder(
            title: placeholderActionsTitle,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyBadge extends StatelessWidget {
  const _ReadOnlyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.atlas,
    required this.animations,
    required this.presets,
  });

  final int atlas;
  final int animations;
  final int presets;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _CounterChip(label: 'Atlas', value: atlas),
        _CounterChip(label: 'Animations', value: animations),
        _CounterChip(label: 'Presets', value: presets),
      ],
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: t.textTheme.labelMedium?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: t.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: t.textTheme.bodySmall?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticsSummary extends StatelessWidget {
  const _DiagnosticsSummary({
    required this.readModel,
    required this.theme,
  });

  final SurfaceStudioReadModel readModel;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final d = readModel.diagnostics;
    final err = d.summary.errorCount;
    final warn = d.summary.warningCount;

    final children = <Widget>[];

    if (d.isClean) {
      children.add(
        Text(
          SurfaceStudioPanel.diagnosticsCleanText,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    } else {
      if (readModel.hasErrors) {
        children.add(
          Text(
            '$err — ${SurfaceStudioPanel.diagnosticsErrorsText}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        );
      }
      if (readModel.hasWarnings) {
        children.add(
          Padding(
            padding: EdgeInsets.only(top: readModel.hasErrors ? 6 : 0),
            child: Text(
              '$warn — ${SurfaceStudioPanel.diagnosticsWarningsText}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.tertiary,
              ),
            ),
          ),
        );
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _FutureActions extends StatelessWidget {
  const _FutureActions({
    required this.onCreateAtlas,
    required this.onImportVertical,
  });

  final VoidCallback? onCreateAtlas;
  final VoidCallback? onImportVertical;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Actions (non disponibles dans ce lot)',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: onCreateAtlas,
              child: const Text(SurfaceStudioPanel.actionCreateAtlasLabel),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onImportVertical,
              child: const Text(
                SurfaceStudioPanel.actionImportVerticalAtlasLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({
    required this.title,
    required this.theme,
  });

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: const Text(SurfaceStudioPanel.placeholderSoonText),
        trailing: const Icon(Icons.layers_outlined),
      ),
    );
  }
}

/// Adaptateur : construit le read model **sans** I/O à partir d’un [ProjectManifest].
class SurfaceStudioPanelFromManifest extends StatelessWidget {
  const SurfaceStudioPanelFromManifest({
    super.key,
    required this.manifest,
  });

  final ProjectManifest manifest;

  @override
  Widget build(BuildContext context) {
    return SurfaceStudioPanel(
      readModel: buildSurfaceStudioReadModel(manifest),
    );
  }
}
