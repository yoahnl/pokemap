// ignore_for_file: invalid_use_of_protected_member

part of 'package:map_editor/src/ui/panels/entity_properties_panel.dart';

/// Binding UI local pour les dialogues projet / Yarn au sein de l'inspecteur.
///
/// On garde ici toutes les petites traductions entre menus, contrôleurs texte
/// et références manifest pour éviter que le shell principal ne soit noyé dans
/// du code de support éditorial.
extension _EntityPropertiesDialogueBindings on _EntityPropertiesPanelState {
  Future<({DialogueRef? ref, bool invalid})> _dialogueRefFromManifestBinding(
    BuildContext context,
    TextEditingController idC,
    TextEditingController nodeC,
  ) async {
    final id = idC.text.trim();
    if (id.isEmpty) {
      return (ref: null, invalid: false);
    }
    final node = nodeC.text.trim();
    if (!isValidDialogueStartNode(node.isEmpty ? null : node)) {
      await showCupertinoEditorAlert(
        context,
        message: _l(
          'Nœud Yarn invalide (lettres, chiffres, espaces, - ou . ; max 256).',
          'Invalid Yarn node (letters, digits, spaces, - or .; max 256 chars).',
        ),
      );
      return (ref: null, invalid: true);
    }
    return (
      ref: DialogueRef(
        dialogueId: id,
        scriptPathRelative: '',
        startNode: node.isEmpty ? null : node,
      ),
      invalid: false,
    );
  }

  List<ProjectDialogueEntry> _sortedDialogueEntries(
    List<ProjectDialogueEntry> entries,
  ) {
    final sorted = List<ProjectDialogueEntry>.of(entries);
    sorted.sort((a, b) {
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (byName != 0) {
        return byName;
      }
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  List<String> _dialogueDropdownIds(
    List<ProjectDialogueEntry> sorted,
    String currentId,
  ) {
    final ids = <String>[
      _kDialogueNoneMenuId,
      ...sorted.map((e) => e.id),
    ];
    final c = currentId.trim();
    if (c.isNotEmpty && !ids.contains(c)) {
      ids.add(c);
    }
    return ids;
  }

  String _dialogueDropdownValueLabel(
    List<ProjectDialogueEntry> sorted,
    String menuId,
  ) {
    if (menuId == _kDialogueNoneMenuId) {
      return _l('Aucun dialogue', 'No dialogue');
    }
    for (final e in sorted) {
      if (e.id == menuId) {
        return e.name;
      }
    }
    return '$menuId (${_l('absent du projet', 'missing from project')})';
  }

  String _npcDialogueSelectedMenuId() {
    if (_npcDialogueSource == _DialogueRefSource.none) {
      return _kDialogueNoneMenuId;
    }
    if (_npcDialogueSource == _DialogueRefSource.legacy) {
      return _kDialogueNoneMenuId;
    }
    final id = _npcDialogueId.text.trim();
    return id.isEmpty ? _kDialogueNoneMenuId : id;
  }

  String _signDialogueSelectedMenuId() {
    if (_signDialogueSource == _DialogueRefSource.none) {
      return _kDialogueNoneMenuId;
    }
    if (_signDialogueSource == _DialogueRefSource.legacy) {
      return _kDialogueNoneMenuId;
    }
    final id = _signDialogueId.text.trim();
    return id.isEmpty ? _kDialogueNoneMenuId : id;
  }

  String _npcDefeatDialogueSelectedMenuId() {
    if (_npcDefeatDialogueSource == _DialogueRefSource.none) {
      return _kDialogueNoneMenuId;
    }
    if (_npcDefeatDialogueSource == _DialogueRefSource.legacy) {
      return _kDialogueNoneMenuId;
    }
    final id = _npcDefeatDialogueId.text.trim();
    return id.isEmpty ? _kDialogueNoneMenuId : id;
  }

  void _onDefeatDialogueMenuSelected(String menuId) {
    setState(() {
      if (menuId == _kDialogueNoneMenuId) {
        _npcDefeatDialogueSource = _DialogueRefSource.none;
        _npcDefeatDialogueId.text = '';
        _npcDefeatDialogueNodes = [];
      } else {
        _npcDefeatDialogueSource = _DialogueRefSource.manifest;
        _npcDefeatDialogueId.text = menuId;
        _npcDefeatDialogueNodes = [];
      }
      _npcDefeatStartNode.text = '';
    });
    Future.microtask(_reloadYarnNodes);
  }

  String? _resolveDialogueFilePath(
    String dialogueId,
    ProjectManifest manifest,
    String projectRoot,
  ) {
    if (dialogueId.isEmpty) return null;
    final matches = manifest.dialogues.where((e) => e.id == dialogueId);
    if (matches.isEmpty) return null;
    final rel = matches.first.relativePath.trim().replaceAll(r'\', '/');
    if (rel.isEmpty) return null;
    return '$projectRoot/$rel';
  }

  Future<void> _reloadYarnNodes() async {
    final state = ref.read(editorNotifierProvider);
    final root = state.projectRootPath;
    final manifest = state.project;
    if (root == null || manifest == null) {
      if (mounted) {
        setState(() {
          _npcDialogueNodes = [];
          _signDialogueNodes = [];
          _npcDefeatDialogueNodes = [];
        });
      }
      return;
    }

    final npcPath = _resolveDialogueFilePath(
      _npcDialogueId.text.trim(),
      manifest,
      root,
    );
    final signPath = _resolveDialogueFilePath(
      _signDialogueId.text.trim(),
      manifest,
      root,
    );
    final defeatPath = _resolveDialogueFilePath(
      _npcDefeatDialogueId.text.trim(),
      manifest,
      root,
    );

    final results = await Future.wait([
      npcPath != null
          ? _extractYarnNodeTitles(npcPath)
          : Future.value(<String>[]),
      signPath != null
          ? _extractYarnNodeTitles(signPath)
          : Future.value(<String>[]),
      defeatPath != null
          ? _extractYarnNodeTitles(defeatPath)
          : Future.value(<String>[]),
    ]);

    if (!mounted) return;
    setState(() {
      _npcDialogueNodes = results[0];
      _signDialogueNodes = results[1];
      _npcDefeatDialogueNodes = results[2];
    });
  }

  void _onDialogueMenuSelected({
    required bool forNpc,
    required String menuId,
  }) {
    setState(() {
      if (forNpc) {
        if (menuId == _kDialogueNoneMenuId) {
          _npcDialogueSource = _DialogueRefSource.none;
          _npcDialogueId.text = '';
          _npcScriptPath.text = '';
          _npcDialogueNodes = [];
        } else {
          _npcDialogueSource = _DialogueRefSource.manifest;
          _npcDialogueId.text = menuId;
          _npcScriptPath.text = '';
          _npcDialogueNodes = [];
        }
        _npcStartNode.text = '';
      } else {
        if (menuId == _kDialogueNoneMenuId) {
          _signDialogueSource = _DialogueRefSource.none;
          _signDialogueId.text = '';
          _signScriptPath.text = '';
          _signDialogueNodes = [];
        } else {
          _signDialogueSource = _DialogueRefSource.manifest;
          _signDialogueId.text = menuId;
          _signScriptPath.text = '';
          _signDialogueNodes = [];
        }
        _signStartNode.text = '';
      }
    });
    Future.microtask(_reloadYarnNodes);
  }

  Widget _yarnNodeField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required List<String> nodes,
    required Color accent,
  }) {
    if (nodes.isEmpty) {
      return _labeledField(context, label: label, controller: controller);
    }
    final currentVal = controller.text.trim();
    final selected = nodes.contains(currentVal) ? currentVal : _kNodeNoneMenuId;
    final menuIds = [_kNodeNoneMenuId, ...nodes];
    return InspectorEmbeddedDropdown(
      accent: accent,
      fieldLabel: label,
      valueLabel: selected == _kNodeNoneMenuId
          ? _l('Nœud par défaut', 'Default node')
          : selected,
      orderedIds: menuIds,
      selectedMenuValue: selected,
      selectedIdForCheck: selected,
      idToLabel: (id) =>
          id == _kNodeNoneMenuId ? _l('Nœud par défaut', 'Default node') : id,
      onSelected: (id) {
        setState(() {
          controller.text = id == _kNodeNoneMenuId ? '' : id;
        });
      },
      tooltip: _l(
        'Nœuds Yarn disponibles dans ce script',
        'Yarn nodes available in this script',
      ),
    );
  }

  List<Widget> _npcCharacterFields(
    BuildContext context,
    ProjectManifest? project,
  ) {
    const charAccent = EditorChrome.inspectorJoyCyan;
    final characters = project?.characters ?? const <ProjectCharacterEntry>[];
    final menuIds = [_kCharacterNoneMenuId, ...characters.map((c) => c.id)];
    String labelOf(String id) {
      if (id == _kCharacterNoneMenuId) return _l('Aucun', 'None');
      for (final c in characters) {
        if (c.id == id) return c.name;
      }
      return id;
    }

    final selected = menuIds.contains(_npcCharacterMenuId)
        ? _npcCharacterMenuId
        : _kCharacterNoneMenuId;

    return [
      InspectorEmbeddedSectionLabel(
          _l('PERSONNAGE OVERWORLD', 'OVERWORLD CHARACTER')),
      const SizedBox(height: 6),
      if (widget.embedded)
        InspectorEmbeddedDropdown(
          accent: charAccent,
          fieldLabel: _l('Personnage', 'Character'),
          valueLabel: labelOf(selected),
          orderedIds: menuIds,
          selectedMenuValue: selected,
          selectedIdForCheck: selected,
          idToLabel: labelOf,
          onSelected: (id) => setState(() => _npcCharacterMenuId = id),
          tooltip: _l(
            'Sprite de personnage utilisé pour ce PNJ sur l\'overworld',
            'Character sprite used for this NPC on the overworld',
          ),
        )
      else ...[
        CupertinoButton(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          onPressed: () async {
            final picked = await showCupertinoListPicker<String>(
              context: context,
              title: _l('Personnage', 'Character'),
              items: menuIds,
              labelOf: labelOf,
            );
            if (picked != null && context.mounted) {
              setState(() => _npcCharacterMenuId = picked);
            }
          },
          child: Text(
            '${_l('Personnage', 'Character')}: ${labelOf(selected)}',
          ),
        ),
      ],
    ];
  }

  bool _npcUsesTrainerAppearance() {
    final trainerId = _npcTrainerMenuId.trim();
    return trainerId.isNotEmpty && trainerId != _kTrainerNoneMenuId;
  }

  void _setNpcTrainerSelection(String id) {
    setState(() {
      _npcTrainerMenuId = id;
      if (_npcUsesTrainerAppearance()) {
        _npcCharacterMenuId = _kCharacterNoneMenuId;
        _editorVisualMenuId = _kElementNoneMenuId;
      }
    });
  }

  List<Widget> _npcDialogueFields(
    BuildContext context,
    ProjectManifest? project,
  ) {
    const scriptAccent = EditorChrome.inspectorJoyLilac;
    final dialogueEntries =
        project?.dialogues ?? const <ProjectDialogueEntry>[];
    final sorted = _sortedDialogueEntries(dialogueEntries);

    if (dialogueEntries.isEmpty) {
      return [
        InspectorEmbeddedFootnote(
          text: _l(
            'Créez ou importez des dialogues dans Dialogue Studio, puis sélectionnez-les ici — plus besoin de chemin relatif.',
            'Create or import dialogues in Dialogue Studio, then pick them here — no relative paths.',
          ),
          accent: scriptAccent,
        ),
        if (_npcDialogueSource == _DialogueRefSource.legacy &&
            _npcScriptPath.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          InspectorEmbeddedFootnote(
            text: _l(
              'Référence fichier héritée : ${_npcScriptPath.text.trim()}. Importez ce fichier dans Dialogue Studio pour le lier proprement.',
              'Legacy file reference: ${_npcScriptPath.text.trim()}. Import it in Dialogue Studio to bind it cleanly.',
            ),
            accent: scriptAccent,
          ),
        ],
        const SizedBox(height: 8),
        _labeledField(
          context,
          label: _l('Nœud Yarn (optionnel)', 'Yarn node (optional)'),
          controller: _npcStartNode,
        ),
      ];
    }

    final menuIds = _dialogueDropdownIds(sorted, _npcDialogueId.text);
    final selectedMenu = _npcDialogueSelectedMenuId();

    return [
      if (widget.embedded)
        InspectorEmbeddedSectionLabel(
          _l('Dialogue (projet)', 'Project dialogue'),
        )
      else
        Text(
          _l('Dialogue (projet)', 'Project dialogue'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      const SizedBox(height: 6),
      if (_npcDialogueSource == _DialogueRefSource.legacy &&
          _npcScriptPath.text.trim().isNotEmpty) ...[
        InspectorEmbeddedFootnote(
          text: _l(
            'Ancienne référence par chemin : ${_npcScriptPath.text.trim()}\nChoisissez un dialogue dans la liste pour enregistrer la liaison au projet.',
            'Legacy path reference: ${_npcScriptPath.text.trim()}\nPick a dialogue from the list to save the project binding.',
          ),
          accent: scriptAccent,
        ),
        const SizedBox(height: 8),
      ],
      InspectorEmbeddedDropdown(
        accent: scriptAccent,
        fieldLabel: _l('Dialogue Yarn', 'Yarn dialogue'),
        valueLabel: _dialogueDropdownValueLabel(sorted, selectedMenu),
        orderedIds: menuIds,
        selectedMenuValue: selectedMenu,
        selectedIdForCheck: selectedMenu,
        idToLabel: (id) => _dialogueDropdownValueLabel(sorted, id),
        onSelected: (id) => _onDialogueMenuSelected(forNpc: true, menuId: id),
        tooltip: _l(
          'Scripts enregistrés dans le manifeste projet',
          'Scripts registered in the project manifest',
        ),
      ),
      const SizedBox(height: 8),
      _yarnNodeField(
        context,
        label: _l('Nœud Yarn (optionnel)', 'Yarn node (optional)'),
        controller: _npcStartNode,
        nodes: _npcDialogueNodes,
        accent: scriptAccent,
      ),
    ];
  }

  List<Widget> _npcTrainerBattleFields(
    BuildContext context,
    ProjectManifest? project,
  ) {
    const battleAccent = EditorChrome.accentCoral;
    final dialogueEntries =
        project?.dialogues ?? const <ProjectDialogueEntry>[];
    final sorted = _sortedDialogueEntries(dialogueEntries);
    final trainers = project?.trainers ?? const <ProjectTrainerEntry>[];

    // Trainer IDs: none sentinel + actual IDs
    final trainerMenuIds = [
      _kTrainerNoneMenuId,
      ...trainers.map((t) => t.id),
    ];
    String trainerMenuLabel(String id) {
      if (id == _kTrainerNoneMenuId) return _l('Aucun', 'None');
      final match = trainers.where((t) => t.id == id);
      if (match.isEmpty) return id;
      final t = match.first;
      return '${t.name} (${t.trainerClass})';
    }

    final selectedTrainer = trainerMenuIds.contains(_npcTrainerMenuId)
        ? _npcTrainerMenuId
        : _kTrainerNoneMenuId;

    return [
      InspectorEmbeddedSectionLabel(
        _l('COMBAT DE DRESSEUR', 'TRAINER BATTLE'),
      ),
      const SizedBox(height: 6),
      if (widget.embedded)
        InspectorEmbeddedDropdown(
          accent: battleAccent,
          fieldLabel: _l('Dresseur', 'Trainer'),
          valueLabel: trainerMenuLabel(selectedTrainer),
          orderedIds: trainerMenuIds,
          selectedMenuValue: selectedTrainer,
          selectedIdForCheck: selectedTrainer,
          idToLabel: trainerMenuLabel,
          onSelected: _setNpcTrainerSelection,
          tooltip: _l(
            'Lier à une fiche dresseur du projet. Vide = PNJ non combattant.',
            'Link to a project trainer entry. Empty = non-combat NPC.',
          ),
        )
      else ...[
        Text(
          _l('Dresseur', 'Trainer'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          onPressed: () async {
            final picked = await showCupertinoListPicker<String>(
              context: context,
              title: _l('Dresseur', 'Trainer'),
              items: trainerMenuIds,
              labelOf: trainerMenuLabel,
            );
            if (picked != null && context.mounted) {
              _setNpcTrainerSelection(picked);
            }
          },
          child: Text(trainerMenuLabel(selectedTrainer)),
        ),
      ],
      const SizedBox(height: 6),
      _labeledField(
        context,
        label: _l('Portée détection (cases)', 'Line of sight (tiles)'),
        controller: _npcLineOfSight,
        keyboardType: TextInputType.number,
      ),
      if (selectedTrainer != _kTrainerNoneMenuId) ...[
        const SizedBox(height: 8),
        InspectorEmbeddedSectionLabel(
          _l('DIALOGUE APRÈS DÉFAITE', 'DEFEAT DIALOGUE'),
        ),
        const SizedBox(height: 4),
        if (dialogueEntries.isEmpty)
          InspectorEmbeddedFootnote(
            text: _l(
              'Ajoutez des dialogues dans Dialogue Studio pour en sélectionner un ici.',
              'Add dialogues in Dialogue Studio to pick one here.',
            ),
            accent: battleAccent,
          )
        else ...[
          InspectorEmbeddedDropdown(
            accent: battleAccent,
            fieldLabel: _l('Dialogue Yarn', 'Yarn dialogue'),
            valueLabel: _dialogueDropdownValueLabel(
              sorted,
              _npcDefeatDialogueSelectedMenuId(),
            ),
            orderedIds: _dialogueDropdownIds(
              sorted,
              _npcDefeatDialogueId.text,
            ),
            selectedMenuValue: _npcDefeatDialogueSelectedMenuId(),
            selectedIdForCheck: _npcDefeatDialogueSelectedMenuId(),
            idToLabel: (id) => _dialogueDropdownValueLabel(sorted, id),
            onSelected: _onDefeatDialogueMenuSelected,
            tooltip: _l(
              'Scripts enregistrés dans le manifeste projet',
              'Scripts registered in the project manifest',
            ),
          ),
          const SizedBox(height: 4),
          _yarnNodeField(
            context,
            label: _l('Nœud Yarn (optionnel)', 'Yarn node (optional)'),
            controller: _npcDefeatStartNode,
            nodes: _npcDefeatDialogueNodes,
            accent: battleAccent,
          ),
        ],
      ],
    ];
  }

  List<Widget> _signDialogueFields(
    BuildContext context,
    ProjectManifest? project,
  ) {
    const scriptAccent = EditorChrome.inspectorJoyLilac;
    final dialogueEntries =
        project?.dialogues ?? const <ProjectDialogueEntry>[];
    final sorted = _sortedDialogueEntries(dialogueEntries);

    if (dialogueEntries.isEmpty) {
      return [
        InspectorEmbeddedFootnote(
          text: _l(
            'Créez ou importez des dialogues dans Dialogue Studio, puis sélectionnez-les ici.',
            'Create or import dialogues in Dialogue Studio, then pick them here.',
          ),
          accent: scriptAccent,
        ),
        if (_signDialogueSource == _DialogueRefSource.legacy &&
            _signScriptPath.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          InspectorEmbeddedFootnote(
            text: _l(
              'Référence fichier héritée : ${_signScriptPath.text.trim()}. Importez ce fichier dans Dialogue Studio.',
              'Legacy file reference: ${_signScriptPath.text.trim()}. Import it in Dialogue Studio.',
            ),
            accent: scriptAccent,
          ),
        ],
        const SizedBox(height: 8),
        _yarnNodeField(
          context,
          label: _l('Nœud Yarn (optionnel)', 'Yarn node (optional)'),
          controller: _signStartNode,
          nodes: _signDialogueNodes,
          accent: scriptAccent,
        ),
      ];
    }

    final menuIds = _dialogueDropdownIds(sorted, _signDialogueId.text);
    final selectedMenu = _signDialogueSelectedMenuId();

    return [
      if (widget.embedded)
        InspectorEmbeddedSectionLabel(
          _l('Dialogue (projet)', 'Project dialogue'),
        )
      else
        Text(
          _l('Dialogue (projet)', 'Project dialogue'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      const SizedBox(height: 6),
      if (_signDialogueSource == _DialogueRefSource.legacy &&
          _signScriptPath.text.trim().isNotEmpty) ...[
        InspectorEmbeddedFootnote(
          text: _l(
            'Ancienne référence par chemin : ${_signScriptPath.text.trim()}\nChoisissez un script dans la liste pour migrer.',
            'Legacy path reference: ${_signScriptPath.text.trim()}\nPick a script from the list to migrate.',
          ),
          accent: scriptAccent,
        ),
        const SizedBox(height: 8),
      ],
      InspectorEmbeddedDropdown(
        accent: scriptAccent,
        fieldLabel: _l('Dialogue Yarn', 'Yarn dialogue'),
        valueLabel: _dialogueDropdownValueLabel(sorted, selectedMenu),
        orderedIds: menuIds,
        selectedMenuValue: selectedMenu,
        selectedIdForCheck: selectedMenu,
        idToLabel: (id) => _dialogueDropdownValueLabel(sorted, id),
        onSelected: (id) => _onDialogueMenuSelected(forNpc: false, menuId: id),
        tooltip: _l(
          'Scripts enregistrés dans le manifeste projet',
          'Scripts registered in the project manifest',
        ),
      ),
      const SizedBox(height: 8),
      _yarnNodeField(
        context,
        label: _l('Nœud Yarn (optionnel)', 'Yarn node (optional)'),
        controller: _signStartNode,
        nodes: _signDialogueNodes,
        accent: scriptAccent,
      ),
    ];
  }

}
