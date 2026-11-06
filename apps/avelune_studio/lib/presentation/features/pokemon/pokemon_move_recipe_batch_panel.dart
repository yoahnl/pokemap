import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class PokemonMoveRecipeBatchPanel extends StatelessWidget {
  const PokemonMoveRecipeBatchPanel({super.key, required this.controller});

  final PokemonWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final results = controller.recipeBatchResults;
    final total = controller.recipeBatchTotal;
    final active = controller.recipeBatchActive;
    final stopped = controller.recipeBatchStopped;
    final imported = results
        .where((entry) => entry.status == BattleMoveRecipeBatchStatus.imported)
        .length;
    final already = results
        .where(
          (entry) => entry.status == BattleMoveRecipeBatchStatus.alreadyPresent,
        )
        .length;
    final preserved = results
        .where(
          (entry) =>
              entry.status == BattleMoveRecipeBatchStatus.custom ||
              entry.status == BattleMoveRecipeBatchStatus.preserved,
        )
        .length;
    final missing = results
        .where((entry) => entry.status == BattleMoveRecipeBatchStatus.missing)
        .length;
    final uncertain = results
        .where(
          (entry) =>
              entry.status == BattleMoveRecipeBatchStatus.ambiguous ||
              entry.status == BattleMoveRecipeBatchStatus.uncertain,
        )
        .length;
    final pilots = results.where((entry) => entry.isPilotFallback).length;
    final failed = results
        .where((entry) => entry.status == BattleMoveRecipeBatchStatus.failed)
        .length;
    final details = results
        .where((entry) => entry.status != BattleMoveRecipeBatchStatus.imported)
        .toList();
    String moveName(String? id) =>
        controller.index?.moves.entries
            .where((move) => move.id == id)
            .firstOrNull
            ?.name ??
        id ??
        'Attaque inconnue';
    return StudioPanel(
      compact: true,
      children: [
        if (active)
          Text(
            controller.recipeBatchPreparing
                ? 'Préparation du projet…'
                : controller.recipeBatchStopRequested
                ? 'Arrêt en cours… Les animations déjà ajoutées sont conservées.'
                : total == null
                ? 'Analyse des attaques…'
                : '${controller.recipeBatchProcessed} sur $total attaques traitées',
          )
        else
          Text(_stoppedLabel(stopped)),
        if (active && !controller.recipeBatchPreparing) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: total == null || total == 0
                ? null
                : controller.recipeBatchProcessed / total,
          ),
          const SizedBox(height: 8),
          StudioButton(
            label: 'Arrêter l’import',
            secondary: true,
            onPressed: controller.recipeBatchStopRequested
                ? null
                : controller.stopMoveRecipeBatch,
          ),
        ],
        if (total != null && !active) ...[
          const SizedBox(height: 8),
          Text(
            '$imported animation${imported == 1 ? '' : 's'} ajoutée${imported == 1 ? '' : 's'} · $already déjà présente${already == 1 ? '' : 's'} · $preserved conservée${preserved == 1 ? '' : 's'} · $missing sans animation · $uncertain à vérifier · $failed en échec',
          ),
          if (pilots > 0) Text('$pilots version(s) pilote utilisées.'),
          if (total > controller.recipeBatchProcessed)
            Text(
              '${total - controller.recipeBatchProcessed} attaque(s) non traitée(s).',
            ),
          if (details.isNotEmpty)
            ExpansionTile(
              title: const Text('Voir les attaques non ajoutées'),
              children: [
                for (final entry in details)
                  ListTile(
                    dense: true,
                    title: Text(moveName(entry.projectMoveId)),
                    subtitle: Text(_entryLabel(entry)),
                  ),
              ],
            ),
        ],
        if (!active && stopped == 'preparationRequired') ...[
          const SizedBox(height: 8),
          StudioButton(
            label: 'Préparer le projet',
            onPressed: controller.prepareMoveRecipeBatchProject,
          ),
        ],
      ],
    );
  }
}

String _stoppedLabel(String? stopped) => switch (stopped) {
  null => 'Import terminé.',
  'cancelled' => 'Import arrêté. Les animations déjà ajoutées sont conservées.',
  'preparationRequired' => 'Ce projet doit être préparé avant l’import. Cette opération peut prendre un moment.',
  'prepared' => 'Projet préparé. Vous pouvez relancer l’import.',
  'preparationFailed' =>
    'La préparation a échoué. Rouvrez le projet avant de réessayer.',
  'recoveryRequired' => 'Rouvrez le projet et utilisez « Reprendre » dans Ressources pour récupérer l’opération avant de relancer l’import.',
  'network' =>
    'Connexion interrompue. Vérifiez le réseau, puis relancez l’import.',
  'projectChanged' =>
    'Le catalogue a changé pendant l’import. Relancez l’analyse.',
  'refreshRequired' =>
    'L’import est arrêté. Rouvrez le projet avant de continuer.',
  _ => 'L’import a été interrompu. Vérifiez le projet et votre connexion, puis réessayez.',
};

String _entryLabel(BattleMoveRecipeBatchEntry entry) => switch (entry.status) {
  BattleMoveRecipeBatchStatus.imported => 'Ajoutée',
  BattleMoveRecipeBatchStatus.alreadyPresent => 'Animation déjà présente',
  BattleMoveRecipeBatchStatus.preserved => 'Animation existante conservée',
  BattleMoveRecipeBatchStatus.custom => 'Attaque personnalisée conservée',
  BattleMoveRecipeBatchStatus.missing => 'Aucune animation disponible',
  BattleMoveRecipeBatchStatus.ambiguous => 'Plusieurs animations possibles',
  BattleMoveRecipeBatchStatus.uncertain => 'Correspondance à vérifier',
  BattleMoveRecipeBatchStatus.failed =>
    entry.reason == 'network' ? 'Connexion interrompue' : 'Import impossible',
};
