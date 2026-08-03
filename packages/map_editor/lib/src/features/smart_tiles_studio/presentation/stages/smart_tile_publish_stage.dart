import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/smart_tile_publication_service.dart';

class SmartTilePublishStage extends StatelessWidget {
  const SmartTilePublishStage({
    super.key,
    required this.name,
    required this.usage,
    required this.atlasSummary,
    required this.gridSummary,
    required this.guideSummary,
    required this.mappingSummary,
    required this.targetKind,
    required this.mapId,
    required this.mapAvailable,
    required this.layerIdController,
    required this.layerNameController,
    required this.blockingDiagnostics,
    required this.warningDiagnostics,
    required this.wangDrawingDeferred,
    required this.busy,
    required this.plan,
    required this.errorCode,
    required this.errorMessage,
    required this.published,
    required this.onTargetChanged,
    required this.onLayerIdentityChanged,
    required this.onPlan,
    required this.onApply,
  });

  final String name;
  final SmartTileUsage usage;
  final String atlasSummary;
  final String gridSummary;
  final String guideSummary;
  final String mappingSummary;
  final SmartTilePublicationTargetKind targetKind;
  final String? mapId;
  final bool mapAvailable;
  final TextEditingController layerIdController;
  final TextEditingController layerNameController;
  final List<SmartTileDiagnostic> blockingDiagnostics;
  final List<SmartTileDiagnostic> warningDiagnostics;
  final bool wangDrawingDeferred;
  final bool busy;
  final SmartTilePublicationPlan? plan;
  final String? errorCode;
  final String? errorMessage;
  final bool published;
  final ValueChanged<SmartTilePublicationTargetKind> onTargetChanged;
  final VoidCallback onLayerIdentityChanged;
  final VoidCallback onPlan;
  final VoidCallback onApply;

  bool get _canPlan =>
      !busy &&
      !published &&
      blockingDiagnostics.isEmpty &&
      (targetKind == SmartTilePublicationTargetKind.library || mapAvailable) &&
      (targetKind == SmartTilePublicationTargetKind.library ||
          layerIdController.text.trim().isNotEmpty &&
              layerNameController.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapSectionHeader(
          title: 'Publier le Smart Tile',
          description:
              'Choisissez la destination, inspectez le plan exact, puis appliquez-le.',
          trailing: PokeMapBadge(
            key: const Key('smart-tiles-publish-status'),
            label: published
                ? 'Publié'
                : blockingDiagnostics.isNotEmpty
                    ? '${blockingDiagnostics.length} erreur(s) bloquante(s)'
                    : plan == null
                        ? 'Prêt à planifier'
                        : 'Plan prêt',
            variant: published
                ? PokeMapBadgeVariant.success
                : blockingDiagnostics.isNotEmpty
                    ? PokeMapBadgeVariant.error
                    : plan == null
                        ? PokeMapBadgeVariant.info
                        : PokeMapBadgeVariant.warning,
          ),
        ),
        const SizedBox(height: 14),
        _PublicationIdentityPanel(
          name: name,
          usage: usage,
          atlasSummary: atlasSummary,
          gridSummary: gridSummary,
          guideSummary: guideSummary,
          mappingSummary: mappingSummary,
        ),
        const SizedBox(height: 14),
        const PokeMapSectionHeader(
          title: 'Destination',
          description:
              'La bibliothèque publie le preset seul. La map publie et crée sa couche dans la même transaction.',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            PokeMapButton(
              key: const Key('smart-tiles-publish-target-library'),
              onPressed: busy
                  ? null
                  : () => onTargetChanged(
                        SmartTilePublicationTargetKind.library,
                      ),
              variant: PokeMapButtonVariant.ghost,
              isSelected: targetKind == SmartTilePublicationTargetKind.library,
              leading: const Icon(CupertinoIcons.square_grid_2x2, size: 15),
              child: const Text('Bibliothèque seulement'),
            ),
            PokeMapButton(
              key: const Key('smart-tiles-publish-target-map'),
              onPressed: busy || !mapAvailable
                  ? null
                  : () => onTargetChanged(SmartTilePublicationTargetKind.map),
              disabledReason: mapAvailable
                  ? null
                  : 'La map capturée à l’ouverture n’est plus active.',
              variant: PokeMapButtonVariant.ghost,
              isSelected: targetKind == SmartTilePublicationTargetKind.map,
              leading: const Icon(CupertinoIcons.map, size: 15),
              child: Text(mapId == null ? 'Map capturée' : 'Map $mapId'),
            ),
          ],
        ),
        if (targetKind == SmartTilePublicationTargetKind.map) ...[
          const SizedBox(height: 12),
          PokeMapPanel(
            key: const Key('smart-tiles-publish-map-identity'),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: PokeMapTextField(
                    label: 'Identifiant de couche',
                    fieldKey: const Key('smart-tiles-publish-layer-id'),
                    controller: layerIdController,
                    enabled: !busy && plan == null,
                    onChanged: (_) => onLayerIdentityChanged(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PokeMapTextField(
                    label: 'Nom de couche',
                    fieldKey: const Key('smart-tiles-publish-layer-name'),
                    controller: layerNameController,
                    enabled: !busy && plan == null,
                    onChanged: (_) => onLayerIdentityChanged(),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (wangDrawingDeferred) ...[
          const SizedBox(height: 10),
          const PokeMapBadge(
            key: Key('smart-tiles-publish-wang-stn05'),
            label: 'Dessin sur carte disponible avec STN-05',
            variant: PokeMapBadgeVariant.warning,
          ),
        ],
        if (blockingDiagnostics.isNotEmpty ||
            warningDiagnostics.isNotEmpty) ...[
          const SizedBox(height: 14),
          _PublicationDiagnostics(
            blocking: blockingDiagnostics,
            warnings: warningDiagnostics,
          ),
        ],
        if (errorCode != null || errorMessage != null) ...[
          const SizedBox(height: 12),
          PokeMapPanel(
            key: const Key('smart-tiles-publish-error'),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (errorCode != null)
                  PokeMapBadge(
                    label: errorCode!,
                    variant: PokeMapBadgeVariant.error,
                  ),
                if (errorCode != null && errorMessage != null)
                  const SizedBox(height: 6),
                if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: TextStyle(color: context.pokeMapColors.textPrimary),
                  ),
              ],
            ),
          ),
        ],
        if (plan != null) ...[
          const SizedBox(height: 14),
          _PublicationPlanPanel(plan: plan!),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: plan == null
              ? PokeMapButton(
                  key: const Key('smart-tiles-publish-plan'),
                  onPressed: _canPlan ? onPlan : null,
                  disabledReason: blockingDiagnostics.isNotEmpty
                      ? 'Corrigez les erreurs avant de préparer le plan.'
                      : null,
                  isLoading: busy,
                  leading: const Icon(CupertinoIcons.doc_text_search, size: 15),
                  child: const Text('Préparer le plan'),
                )
              : PokeMapButton(
                  key: const Key('smart-tiles-publish-apply'),
                  onPressed: busy || published ? null : onApply,
                  isLoading: busy,
                  variant: PokeMapButtonVariant.primary,
                  leading:
                      const Icon(CupertinoIcons.check_mark_circled, size: 15),
                  child: Text(
                    targetKind == SmartTilePublicationTargetKind.map
                        ? 'Publier et ouvrir la couche'
                        : 'Publier dans la bibliothèque',
                  ),
                ),
        ),
      ],
    );
  }
}

class _PublicationIdentityPanel extends StatelessWidget {
  const _PublicationIdentityPanel({
    required this.name,
    required this.usage,
    required this.atlasSummary,
    required this.gridSummary,
    required this.guideSummary,
    required this.mappingSummary,
  });

  final String name;
  final SmartTileUsage usage;
  final String atlasSummary;
  final String gridSummary;
  final String guideSummary;
  final String mappingSummary;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        children: <Widget>[
          _PlanValue(label: 'Nom', value: name),
          _PlanValue(label: 'Usage', value: _usageLabel(usage)),
          _PlanValue(label: 'Atlas', value: atlasSummary),
          _PlanValue(label: 'Grille', value: gridSummary),
          _PlanValue(label: 'Guide', value: guideSummary),
          _PlanValue(label: 'Associations', value: mappingSummary),
        ],
      ),
    );
  }
}

class _PublicationDiagnostics extends StatelessWidget {
  const _PublicationDiagnostics({
    required this.blocking,
    required this.warnings,
  });

  final List<SmartTileDiagnostic> blocking;
  final List<SmartTileDiagnostic> warnings;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PokeMapSectionHeader(
            title: 'Diagnostics',
            description:
                '${blocking.length} erreur(s), ${warnings.length} avertissement(s).',
          ),
          const SizedBox(height: 8),
          for (final diagnostic in <SmartTileDiagnostic>[
            ...blocking,
            ...warnings,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  PokeMapBadge(
                    label: diagnostic.code,
                    variant: diagnostic.isError
                        ? PokeMapBadgeVariant.error
                        : PokeMapBadgeVariant.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(diagnostic.message)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PublicationPlanPanel extends StatelessWidget {
  const _PublicationPlanPanel({required this.plan});

  final SmartTilePublicationPlan plan;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      key: const Key('smart-tiles-publish-plan-summary'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PokeMapSectionHeader(
            title: 'Plan canonique prêt',
            description:
                'Aucune écriture n’a encore été appliquée. Vérifiez cette cible.',
            trailing: PokeMapBadge(
              label: 'Tout ou rien',
              variant: PokeMapBadgeVariant.info,
            ),
          ),
          const SizedBox(height: 10),
          _PlanValue(label: 'Preset', value: plan.presetId),
          if (plan.layerId case final layerId?)
            _PlanValue(label: 'Couche', value: layerId),
          _PlanValue(label: 'Plan', value: plan.planId),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final resource in plan.affectedResources)
                PokeMapBadge(
                  label: '${_resourceLabel(resource.kind)} · ${resource.id}',
                  variant: PokeMapBadgeVariant.neutral,
                ),
            ],
          ),
          if (plan.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            PokeMapBadge(
              label: '${plan.warnings.length} avertissement(s) conservé(s)',
              variant: PokeMapBadgeVariant.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanValue extends StatelessWidget {
  const _PlanValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: context.pokeMapColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

String _usageLabel(SmartTileUsage usage) => switch (usage) {
      SmartTileUsage.terrain => 'Terrain',
      SmartTileUsage.path => 'Chemin',
      SmartTileUsage.forestSurface => 'Surface organique',
    };

String _resourceLabel(String kind) => switch (kind) {
      'project' => 'Manifeste',
      'map' => 'Map',
      _ => kind,
    };
