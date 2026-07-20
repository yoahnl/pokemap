import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../design_system/design_system.dart';

/// Shared summary for the command picker and the Scene inspector.
///
/// It mirrors the canonical descriptor instead of maintaining UI-specific
/// support flags, so an unavailable FG mechanic cannot look publishable.
class SceneActionInspector extends StatelessWidget {
  const SceneActionInspector({
    super.key,
    required this.command,
    required this.missingParameterLabels,
  });

  final NarrativeCommandDescriptor command;
  final List<String> missingParameterLabels;

  @override
  Widget build(BuildContext context) {
    final backendLabel = switch (command.backend) {
      NarrativeCommandBackend.sceneConsequence => 'Persistant',
      NarrativeCommandBackend.interactiveRuntimeCommand => 'Interactif',
      NarrativeCommandBackend.dedicatedSceneNode => 'Nœud Scene',
    };
    final expectedResult = switch (command.backend) {
      NarrativeCommandBackend.sceneConsequence => 'Sortie completed',
      NarrativeCommandBackend.interactiveRuntimeCommand =>
        'Résultat runtime explicite',
      NarrativeCommandBackend.dedicatedSceneNode => 'Outcome de Scene',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            PokeMapBadge(
              label: command.isPublishable ? 'Disponible' : 'Non disponible',
              variant: command.isPublishable
                  ? PokeMapBadgeVariant.success
                  : PokeMapBadgeVariant.warning,
            ),
            PokeMapBadge(label: command.fgLotId),
            PokeMapBadge(
              label: backendLabel,
              variant: PokeMapBadgeVariant.narrative,
            ),
            PokeMapBadge(label: expectedResult),
          ],
        ),
        const SizedBox(height: 8),
        if (!command.isPublishable)
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.warning,
            title: 'Mécanique non publiée',
            message: command.capabilities.reason ?? command.description,
          )
        else if (missingParameterLabels.isNotEmpty)
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.warning,
            title: 'Configuration incomplète',
            message:
                'Paramètres manquants : ${missingParameterLabels.join(', ')}.',
          )
        else
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.info,
            title: 'Wire canonique',
            message: command.wireId,
          ),
      ],
    );
  }
}
