// ignore_for_file: invalid_use_of_protected_member

part of 'package:map_editor/src/ui/panels/entity_properties_panel.dart';

extension _EntityPropertiesNpcRuntime on _EntityPropertiesPanelState {
  /// Garde la logique waypoint hors du shell principal, sans changer
  /// l’orchestration existante du panneau.
  void _addNpcWaypointRow({GridPos? seed}) {
    final fallbackX = int.tryParse(_xController.text.trim()) ?? 0;
    final fallbackY = int.tryParse(_yController.text.trim()) ?? 0;
    setState(() {
      _npcWaypointRows.add(
        _NpcWaypointDraft(
          xController: TextEditingController(
            text: (seed?.x ?? fallbackX).toString(),
          ),
          yController: TextEditingController(
            text: (seed?.y ?? fallbackY).toString(),
          ),
        ),
      );
    });
  }

  /// Bloc UI dédié au mouvement PNJ.
  ///
  /// L’objectif du lot est purement structurel : on garde le même comportement
  /// mais on évite que le fichier principal noie la logique d’édition au milieu
  /// du reste du panneau.
  List<Widget> _npcMovementFields(
    BuildContext context,
    EditorState state,
    EditorNotifier notifier,
  ) {
    final modeIds = MapEntityNpcMovementMode.values
        .map((mode) => mode.name)
        .toList(growable: false);

    final modePicker = widget.embedded
        ? InspectorEmbeddedDropdown(
            accent: EditorChrome.inspectorJoyMint,
            fieldLabel: _l('Déplacement PNJ', 'NPC movement'),
            valueLabel: _npcMovementModeLabel(_npcMovementMode),
            orderedIds: modeIds,
            selectedMenuValue: _npcMovementMode.name,
            selectedIdForCheck: _npcMovementMode.name,
            idToLabel: (id) => _npcMovementModeLabel(
              MapEntityNpcMovementMode.values.firstWhere((e) => e.name == id),
            ),
            onSelected: (id) {
              final mode = MapEntityNpcMovementMode.values.firstWhere(
                (e) => e.name == id,
              );
              setState(() => _npcMovementMode = mode);
            },
            tooltip: _l(
              'Comportement par défaut en overworld. Scripted only = aucun auto-move.',
              'Default overworld behavior. Scripted only = no automatic movement.',
            ),
          )
        : CupertinoButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () async {
              final picked =
                  await showCupertinoListPicker<MapEntityNpcMovementMode>(
                context: context,
                title: _l('Déplacement PNJ', 'NPC movement'),
                items: MapEntityNpcMovementMode.values,
                labelOf: _npcMovementModeLabel,
              );
              if (picked != null) {
                setState(() => _npcMovementMode = picked);
              }
            },
            child: Text(
              '${_l('Déplacement PNJ', 'NPC movement')}: ${_npcMovementModeLabel(_npcMovementMode)}',
            ),
          );

    final widgets = <Widget>[modePicker];

    final selectedEntityId = state.selectedEntityId?.trim();
    final placementEntityId = state.npcWaypointPlacementEntityId?.trim();
    final placementActiveForSelection = selectedEntityId != null &&
        selectedEntityId.isNotEmpty &&
        placementEntityId == selectedEntityId;
    if (_npcMovementMode == MapEntityNpcMovementMode.patrol ||
        placementActiveForSelection) {
      widgets.addAll([
        const SizedBox(height: 8),
        if (placementActiveForSelection)
          InspectorEmbeddedFootnote(
            text: _l(
              'Mode placement actif : cliquez sur la map pour ajouter un waypoint.',
              'Placement mode is active: click the map to add a waypoint.',
            ),
            accent: EditorChrome.inspectorJoyMint,
          ),
        const SizedBox(height: 6),
        CupertinoButton(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          onPressed: () {
            if (placementActiveForSelection) {
              notifier.cancelNpcWaypointPlacement();
              return;
            }
            notifier.startNpcWaypointPlacementForSelectedEntity();
          },
          child: Text(
            placementActiveForSelection
                ? _l('Quitter mode placement', 'Exit placement mode')
                : _l('Placer waypoint sur la map', 'Place waypoint on map'),
          ),
        ),
      ]);
    }

    if (_npcMovementMode != MapEntityNpcMovementMode.patrol) {
      return widgets;
    }

    widgets.addAll([
      const SizedBox(height: 8),
      _toggleField(
        context,
        label: _l('Patrouille en boucle', 'Patrol loop'),
        value: _npcMovementLoop,
        onChanged: (value) => setState(() => _npcMovementLoop = value),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _labeledField(
              context,
              label: _l('Pause waypoint (ms)', 'Waypoint pause (ms)'),
              controller: _npcMovementPauseMs,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _labeledField(
              context,
              label: _l('Durée d’un pas (ms)', 'Step duration (ms)'),
              controller: _npcMovementStepMs,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        _l(
          'Waypoints (minimum 2 pour bouger)',
          'Waypoints (minimum 2 to move)',
        ),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
      const SizedBox(height: 6),
      if (_npcWaypointRows.isEmpty)
        Text(
          _l(
            'Aucun waypoint. Le PNJ restera immobile.',
            'No waypoints. NPC will stay still.',
          ),
          style: TextStyle(
            fontSize: 11,
            color: CupertinoColors.placeholderText.resolveFrom(context),
          ),
        ),
    ]);

    for (var index = 0; index < _npcWaypointRows.length; index++) {
      final row = _npcWaypointRows[index];
      widgets.addAll([
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _labeledField(
                context,
                label: 'X',
                controller: row.xController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _labeledField(
                context,
                label: 'Y',
                controller: row.yController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: const EdgeInsets.all(0),
              minimumSize: const Size(28, 28),
              onPressed: () {
                setState(() {
                  final removed = _npcWaypointRows.removeAt(index);
                  removed.dispose();
                });
              },
              child: const Icon(
                CupertinoIcons.minus_circle,
                size: 18,
              ),
            ),
          ],
        ),
      ]);
    }

    widgets.addAll([
      const SizedBox(height: 8),
      CupertinoButton(
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        onPressed: _addNpcWaypointRow,
        child: Text(_l('+ Ajouter waypoint', '+ Add waypoint')),
      ),
    ]);
    return widgets;
  }
}
