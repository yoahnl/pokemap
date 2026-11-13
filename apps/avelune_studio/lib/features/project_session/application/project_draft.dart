abstract interface class ProjectDraftPart {
  bool get unsaved;
  bool get saving;
  Future<bool> save();
}

final class ProjectDraft implements ProjectDraftPart {
  ProjectDraft(Iterable<ProjectDraftPart> parts)
    : _parts = List.unmodifiable(parts);

  final List<ProjectDraftPart> _parts;
  Future<bool>? _saving;

  @override
  bool get unsaved => _parts.any((part) => part.unsaved);

  @override
  bool get saving => _saving != null || _parts.any((part) => part.saving);

  @override
  Future<bool> save() =>
      _saving ??= _saveInOrder().whenComplete(() => _saving = null);

  Future<bool> _saveInOrder() async {
    for (final part in _parts) {
      if (part.unsaved && !await part.save()) return false;
    }
    return true;
  }
}
