import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import 'item_studio_gateway.dart';

final class ItemReadinessPanel extends StatelessWidget {
  const ItemReadinessPanel({
    super.key,
    required this.definition,
    required this.readiness,
    required this.usages,
    required this.onSimulate,
    this.simulation,
    this.isSimulating = false,
  });

  final ProjectItemDefinition definition;
  final ItemStudioReadiness? readiness;
  final List<ItemStudioUsage> usages;
  final ValueChanged<ProjectItemUseContext> onSimulate;
  final Map<String, Object?>? simulation;
  final bool isSimulating;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final isReady = readiness?.ready ?? true;
    return PokeMapPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapSectionHeader(
            title: 'Usages et disponibilité',
            description: 'Ce qui utilise cet objet et ce qui bloque son jeu.',
            trailing: PokeMapBadge(
              label: isReady ? 'Objet prêt' : 'Objet à corriger',
              variant: isReady
                  ? PokeMapBadgeVariant.success
                  : PokeMapBadgeVariant.warning,
            ),
          ),
          if (readiness?.diagnostics case final diagnostics?
              when diagnostics.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final diagnostic in diagnostics) ...[
              PokeMapDiagnosticCallout(
                severity: _severity(diagnostic.severity),
                title: diagnostic.code,
                message: '${diagnostic.message}\n${diagnostic.path}',
              ),
              const SizedBox(height: 6),
            ],
          ] else ...[
            const SizedBox(height: 8),
            const PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.info,
              message: 'Aucun diagnostic bloquant pour cet objet.',
            ),
          ],
          const SizedBox(height: 12),
          Text(
            usages.isEmpty
                ? 'Cet objet n’est encore utilisé nulle part.'
                : '${usages.length} utilisation(s) dans le projet',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          if (usages.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final usage in usages)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: PokeMapCard(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${usage.sourceKind} · ${usage.sourceId}',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              usage.editablePath,
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (usage.blocksDeletion)
                        const PokeMapBadge(
                          label: 'Bloque la suppression',
                          variant: PokeMapBadgeVariant.warning,
                        ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          const PokeMapSectionHeader(
            title: 'Aperçu de l’effet',
            description: 'Simulation pure, sans modifier le sac du joueur.',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              PokeMapButton(
                key: const Key('item-studio-simulate-overworld-button'),
                onPressed: isSimulating
                    ? null
                    : () => onSimulate(ProjectItemUseContext.overworld),
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                child: const Text('Simuler dans le monde'),
              ),
              PokeMapButton(
                key: const Key('item-studio-simulate-battle-button'),
                onPressed: isSimulating
                    ? null
                    : () => onSimulate(ProjectItemUseContext.battle),
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                child: const Text('Simuler en combat'),
              ),
            ],
          ),
          if (simulation case final value?) ...[
            const SizedBox(height: 8),
            PokeMapCard(
              child: Text(
                _simulationLabel(value),
                key: const Key('item-studio-simulation-result'),
                style: TextStyle(color: colors.textPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

PokeMapDiagnosticSeverity _severity(String severity) => switch (severity) {
  'error' => PokeMapDiagnosticSeverity.error,
  'warning' => PokeMapDiagnosticSeverity.warning,
  _ => PokeMapDiagnosticSeverity.info,
};

String _simulationLabel(Map<String, Object?> simulation) {
  final status = simulation['status'] == 'configured'
      ? 'Effet configuré'
      : 'Objet passif dans ce contexte';
  final context = switch (simulation['context']) {
    'battle' => 'combat',
    _ => 'monde',
  };
  final target = switch (simulation['target']) {
    'partyMember' || 'party_member' => 'un équipier',
    'partyMove' || 'party_move' => 'une capacité',
    'world' => 'le monde',
    _ => 'aucune cible',
  };
  return '$status dans le $context · cible : $target';
}
