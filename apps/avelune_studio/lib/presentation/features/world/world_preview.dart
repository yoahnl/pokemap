part of 'world_workspace_page.dart';

extension _WorldPreview on _WorldWorkspacePageState {
  /// The target as the game would draw it, before and after the effects the
  /// current test retains. Panning and zooming never write anything.
  Widget _preview(WorldRuleDraft draft) {
    final visuals = widget.visuals;
    final target = draft.target;
    if (target == null) {
      return const Text('Choisissez une cible pour voir son aperçu.');
    }
    if (target.kind != WorldRuleTargetKind.mapEntity &&
        target.kind != WorldRuleTargetKind.npcDialogue) {
      return _eventOutcome(draft, target);
    }
    final map = controller.maps
        .where((candidate) => candidate.id == target.mapId)
        .firstOrNull;
    if (visuals == null || map == null) {
      return const Text(
        'La carte de cette cible n’est pas chargée sur cet hôte : le résultat '
        'reste lisible dans l’explication ci-dessus.',
      );
    }
    final settings = controller.project.settings;
    final size = Size(
      map.size.width * settings.tileWidth * settings.displayScale.toDouble(),
      map.size.height * settings.tileHeight * settings.displayScale.toDouble(),
    );
    final shown = view.previewAfter ? _applied(map) : map;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioTabs<bool>(
          items: const {false: 'Avant la règle', true: 'Après la règle'},
          selected: view.previewAfter,
          onChanged: (next) {
            view.previewAfter = next;
            refresh();
          },
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 180,
          child: ClipRect(
            child: InteractiveViewer(
              key: const ValueKey('world-preview-viewport'),
              transformationController: view.previewTransform,
              constrained: false,
              alignment: Alignment.topLeft,
              minScale: .15,
              maxScale: 8,
              boundaryMargin: const EdgeInsets.all(300),
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: visuals.canvas(shown),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(_previewCaption(draft, map), style: _label),
      ],
    );
  }

  /// Removes from the drawing what the projection hides, so the picture and
  /// the verdict cannot disagree.
  MapData _applied(MapData map) {
    final report = controller.report;
    if (report == null) return map;
    final hidden = <String>{
      for (final state in report.entityStates)
        if (state.mapId == map.id && !state.visible) state.entityId,
    };
    if (hidden.isEmpty) return map;
    return map.copyWith(
      entities: [
        for (final entity in map.entities)
          if (!hidden.contains(entity.id)) entity,
      ],
    );
  }

  String _previewCaption(WorldRuleDraft draft, MapData map) {
    if (controller.report == null) {
      return 'Lancez le test pour voir l’état après la règle.';
    }
    final entityId = draft.target?.entityId;
    final state = controller.report!.entityStates
        .where((item) => item.mapId == map.id && item.entityId == entityId)
        .firstOrNull;
    if (state == null) {
      return 'Cette cible n’apparaît pas dans le rapport de simulation.';
    }
    final dialogue = state.dialogueId;
    return [
      state.visible ? 'Présent' : 'Absent',
      if (dialogue != null) 'dialogue $dialogue',
      'd’après ${state.contributorRuleIds.length} règle(s)',
    ].join(' · ');
  }

  /// An event has no picture of its own: its state is told, not drawn.
  Widget _eventOutcome(WorldRuleDraft draft, WorldRuleTarget target) {
    final report = controller.report;
    if (report == null) {
      return const Text('Lancez le test pour voir l’état de cet événement.');
    }
    final eventId = target.eventId;
    if (target.kind == WorldRuleTargetKind.mapEvent) {
      final state = report.mapEventStates
          .where((item) => item.eventId == eventId)
          .firstOrNull;
      return Text(
        state == null
            ? 'Cet événement n’apparaît pas dans le rapport.'
            : 'Événement de carte · ${state.active ? 'actif' : 'inactif'}'
                  '${state.hidden ? ' · masqué' : ''}',
      );
    }
    final state = report.narrativeEventStates
        .where((item) => item.eventId == eventId)
        .firstOrNull;
    return Text(
      state == null
          ? 'Cet événement n’apparaît pas dans le rapport.'
          : 'Événement · ${state.configured ? 'configuré' : 'incomplet'} · '
                '${state.active ? 'actif' : 'inactif'}'
                '${state.hidden ? ' · masqué' : ''}',
    );
  }
}
