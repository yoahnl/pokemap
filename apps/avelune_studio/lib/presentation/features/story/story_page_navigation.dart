part of 'story_page.dart';

extension _StoryPageNavigation on _StoryPageState {
  Future<void> _consumeBehaviourRequest() async {
    final request = widget.behaviourRequest;
    if (request == null) return;
    await widget.beforeNavigation?.call();
    if (!mounted || widget.behaviourRequest != request) return;
    _openSection(StorySection.behaviours);
    _workspace = _workspace.select(StorySection.behaviours);
    _behaviours?.filterMap(request.mapId);
    _creation = false;
    if (request.id case final id?) {
      if (widget.behaviourCatalog != null) await _openCatalogBehaviour(id);
    } else {
      widget.behaviourCatalog?.clear();
      _selectItem(StorySection.behaviours, null);
    }
    if (mounted && widget.behaviourRequest == request) _changed();
  }

  Future<bool> _openCatalogBehaviour(String id, {bool simulate = false}) async {
    await widget.beforeNavigation?.call();
    if (!mounted) return false;
    _creation = false;
    _selectItem(StorySection.behaviours, (kind: StoryDraftKind.event, id: id));
    final opened = await widget.behaviourCatalog!.open(id);
    if (!mounted) return false;
    if (opened && simulate) {
      widget.behaviourCatalog!.editor!.toggleSimulation(id);
    }
    _changed();
    return opened;
  }

  Future<void> _createTrigger() async {
    await widget.beforeNavigation?.call();
    if (!mounted) return;
    widget.behaviourCatalog?.clear();
    _creation = true;
    _selectItem(StorySection.behaviours, null);
    _changed();
  }

}
