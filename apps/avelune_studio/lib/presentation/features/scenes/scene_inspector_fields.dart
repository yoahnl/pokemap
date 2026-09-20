part of 'scene_inspector.dart';

extension _SceneInspectorFields on SceneInspector {
  List<Widget> _fields(BuildContext context, SceneNode node) {
    final value = node.payload;
    if (value is SceneYarnDialoguePayload) {
      final entry = project.dialogues
          .where((d) => d.id == value.dialogueId)
          .firstOrNull;
      return [
        StudioSelect(
          label: 'Document de dialogue',
          value: value.dialogueId,
          options: {for (final d in project.dialogues) d.id: d.name},
          onChanged: (id) {
            final selected = project.dialogues.firstWhere((d) => d.id == id);
            payload(
              node,
              SceneYarnDialoguePayload(
                dialogueId: id,
                yarnNodeName: selected.defaultStartNode,
                expectedOutcomes: selected.declaredOutcomes
                    .map((outcome) => outcome.id)
                    .toList(),
                speakerHints: value.speakerHints,
              ),
            );
          },
        ),

        const SizedBox(height: 12),
        Text(
          'Départ : ${value.yarnNodeName ?? entry?.defaultStartNode ?? 'début du document'}',
        ),
        Text(
          'Résultats : ${value.expectedOutcomes.isEmpty ? 'Continuer' : value.expectedOutcomes.join(', ')}',
        ),
        if (session.current.graph.edges.any(
          (edge) =>
              edge.fromNodeId == node.id &&
              !authorableSceneOutputPortsForNodeInGraph(
                node,
                session.current.graph,
              ).any((port) => port.id == edge.fromPortId),
        ))
          const StudioNotice(
            'Des connexions utilisent des résultats absents du document choisi. Elles restent conservées : sélectionnez ces fils pour les corriger ou annulez le changement.',
            isError: true,
          ),
        if (documents != null && entry != null) ...[
          const SizedBox(height: 12),
          documents!.dialoguePreview(
            value,
            project,
            narrative,
            onStartChanged: (start) => payload(
              node,
              SceneYarnDialoguePayload(
                dialogueId: value.dialogueId,
                yarnNodeName: start,
                expectedOutcomes: value.expectedOutcomes,
                speakerHints: value.speakerHints,
              ),
            ),
          ),
        ],
        if (entry == null)
          const StudioNotice(
            'Document introuvable. Sa référence est conservée.',
            isError: true,
          ),
        const SizedBox(height: 12),
        StudioButton(
          label: 'Ouvrir le dialogue',
          icon: Icons.open_in_new,
          secondary: true,
          onPressed: () => onDocument(node),
        ),
      ];
    }
    if (value is SceneConditionPayload) {
      return [
        SceneConditionForm(
          project: project,
          current: value,
          onApply: (source) => edit(
            (scene) => updateSceneConditionSource(
              scene,
              nodeId: node.id,
              source: source,
            ).updatedScene,
          ),
        ),
      ];
    }
    if (value is SceneActionPayload) {
      return [
        SceneActionForm(
          project: project,
          current: value,
          onApply: (v) => payload(node, v),
        ),
      ];
    }
    if (value is SceneCinematicPayload) {
      return [
        StudioSelect(
          label: 'Cinématique sur carte',
          value: value.cinematicId,
          options: {for (final c in project.cinematics) c.id: c.title},
          onChanged: (id) => edit(
            (scene) => updateSceneCinematicPayload(
              scene,
              nodeId: node.id,
              cinematicId: id,
            ).updatedScene,
          ),
        ),
        const SizedBox(height: 12),
        StudioButton(
          label: 'Ouvrir la cinématique',
          secondary: true,
          onPressed: () => onDocument(node),
        ),
      ];
    }
    if (value is ScenePresentationCinematicPayload) {
      return [
        StudioSelect(
          label: 'Cinématique de présentation',
          value: value.presentationCinematicId,
          options: {
            for (final c in project.presentationCinematics) c.id: c.title,
          },
          onChanged: (id) => payload(
            node,
            ScenePresentationCinematicPayload(
              presentationCinematicId: id,
              interactionCueBindings: value.interactionCueBindings,
            ),
          ),
        ),
        const SizedBox(height: 12),
        StudioButton(
          label: 'Ouvrir la présentation',
          secondary: true,
          onPressed: () => onDocument(node),
        ),
      ];
    }
    if (value is SceneEndPayload) {
      return [
        StudioSelect(
          label: 'Résultat public',
          value: value.sceneOutcomeId ?? '',
          options: {
            '': 'Aucun résultat',
            for (final o in session.current.declaredOutcomes) o.id: o.label,
          },
          onChanged: (id) => edit(
            (scene) => updateSceneEndPayload(
              scene,
              nodeId: node.id,
              sceneOutcomeId: id.isEmpty ? null : id,
              outcomePolicy: value.outcomePolicy,
            ).updatedScene,
          ),
        ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Politique de fin',
          value: value.outcomePolicy?.name ?? '',
          options: {
            '': 'Non précisée',
            for (final p in SceneOutcomePolicy.values) p.name: p.name,
          },
          onChanged: (id) => edit(
            (scene) => updateSceneEndPayload(
              scene,
              nodeId: node.id,
              sceneOutcomeId: value.sceneOutcomeId,
              outcomePolicy: SceneOutcomePolicy.values
                  .where((p) => p.name == id)
                  .firstOrNull,
            ).updatedScene,
          ),
        ),
      ];
    }
    if (value is SceneBattlePayload) {
      return [
        StudioSelect(
          label: 'Dresseur',
          value: value.trainerId,
          options: {for (final t in project.trainers) t.id: t.name},
          onChanged: (id) => edit(
            (scene) => updateSceneBattlePayload(
              scene,
              nodeId: node.id,
              trainerId: id,
              battleKind: value.battleKind,
              battleTemplateId: value.battleTemplateId,
            ).updatedScene,
          ),
        ),
        Text(
          'Résultats : ${authorableSceneOutputPortsForNodeInGraph(node, session.current.graph).map((p) => p.id).join(', ')}',
        ),
      ];
    }
    if (value is SceneBranchByOutcomePayload) {
      return [
        StudioSelect(
          label: 'Résultats du bloc',
          value: value.sourceNodeId,
          options: {
            for (final n in session.current.graph.nodes.where(
              (n) =>
                  n.id != node.id &&
                  {
                    SceneNodeKind.yarnDialogue,
                    SceneNodeKind.condition,
                    SceneNodeKind.battle,
                    SceneNodeKind.action,
                  }.contains(n.kind),
            ))
              n.id: n.title ?? sceneBlockLabel(n.kind),
          },
          onChanged: (id) => payload(
            node,
            SceneBranchByOutcomePayload(
              sourceNodeId: id,
              sourceOutcomeSetRef: value.sourceOutcomeSetRef,
              fallbackPolicy: value.fallbackPolicy,
            ),
          ),
        ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Sans résultat correspondant',
          value: value.fallbackPolicy.name,
          options: const {
            'exact': 'Correspondance exacte',
            'defaultRoute': 'Sortie par défaut',
            'errorRoute': 'Sortie d’erreur',
          },
          onChanged: (id) => payload(
            node,
            SceneBranchByOutcomePayload(
              sourceNodeId: value.sourceNodeId,
              sourceOutcomeSetRef: value.sourceOutcomeSetRef,
              fallbackPolicy: SceneBranchOutcomeFallbackPolicy.values.byName(
                id,
              ),
            ),
          ),
        ),
        const StudioNotice(
          'Les anciens fils sont conservés. Vérifiez leurs sorties après un changement de source.',
        ),
      ];
    }
    return [
      Text(
        node.kind == SceneNodeKind.start
            ? 'Point d’entrée unique de la scène.'
            : 'Réunit les chemins vers une continuation commune.',
      ),
    ];
  }
}
