part of 'map_builder_story_binding.dart';

extension MapStoryAdditions on MapBuilderStoryBinding {
  List<ProjectCharacterEntry> get characters =>
      [...?maps.project?.characters]..sort((a, b) => a.name.compareTo(b.name));

  void toggleChoices() {
    choosing = !choosing;
    if (!choosing) cancelAdding();
    changed();
  }

  Future<void> startAdding(MapStoryAddition kind) async {
    final session = view();
    if (session == null || maps.active == null) return;
    adding = kind;
    error = null;
    switch (kind) {
      case MapStoryAddition.sign:
        _arm(session, StudioMapTool.sign);
      case MapStoryAddition.zone:
        _arm(session, StudioMapTool.zone);
      case MapStoryAddition.character:
        session.tool = StudioMapTool.select;
        await loadCharacters();
    }
    changed();
  }

  Future<void> loadCharacters() async {
    if (charactersLoading) return;
    charactersLoading = true;
    charactersError = null;
    changed();
    try {
      await maps.ensureResourceKind('character');
    } on Object catch (failure) {
      charactersError = failure is StateError ? failure.message : '$failure';
    } finally {
      charactersLoading = false;
      changed();
    }
  }

  void chooseCharacter(ProjectCharacterEntry character) {
    final session = view();
    if (session == null || adding != MapStoryAddition.character) return;
    session.character = character;
    _arm(session, StudioMapTool.character);
    changed();
  }

  void cancelAdding() {
    final session = view();
    if (adding != null &&
        session != null &&
        const {
          StudioMapTool.character,
          StudioMapTool.sign,
          StudioMapTool.zone,
        }.contains(session.tool)) {
      session.tool = StudioMapTool.select;
    }
    adding = null;
  }

  bool get armed {
    final tool = view()?.tool;
    return switch (adding) {
      MapStoryAddition.character => tool == StudioMapTool.character,
      MapStoryAddition.sign => tool == StudioMapTool.sign,
      MapStoryAddition.zone => tool == StudioMapTool.zone,
      null => false,
    };
  }

  void reconcile() {
    final map = this.map;
    if (adding == null || map == null || !armed) return;
    if (adding != MapStoryAddition.zone &&
        map.entities.length > _armedEntities) {
      _record(_StorySide.map, maps.active?.undoToken);
      _finish();
    }
  }

  bool addZone(MapRect area) {
    if (adding != MapStoryAddition.zone) return false;
    final applied = _edit((document, project) {
      final ids = document.current.triggers.map((item) => item.id).toSet();
      var index = document.current.triggers.length + 1;
      while (ids.contains('story-zone-$index')) {
        index++;
      }
      final trigger = TriggerEditingCommands(document, project).add(
        MapTrigger(
          id: 'story-zone-$index',
          name: _zoneName(),
          type: TriggerType.event,
          area: area,
        ),
      );
      view()?.select(document, MapSelectionFamily.trigger, trigger.id);
      return true;
    });
    if (applied) _finish();
    return applied;
  }

  void _arm(MapEditingViewportSession session, StudioMapTool tool) {
    _armedEntities = map?.entities.length ?? 0;
    session
      ..brush = null
      ..model3d = null
      ..tile = null
      ..terrain = null
      ..tool = tool;
  }

  void _finish() {
    cancelAdding();
    choosing = false;
    tab = MapStoryTab.properties;
    changed();
  }
}
