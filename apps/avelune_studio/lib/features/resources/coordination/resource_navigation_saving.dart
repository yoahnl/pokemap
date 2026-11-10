part of 'resource_navigation.dart';

extension ResourceNavigationSaving on ResourceNavigation {
  void _retainDecorPublication(
    DecorDraft? draft,
    String id,
    ResourceFailure failure,
  ) {
    final receipt = failure.partialReceipt;
    if (receipt == null) return;
    pendingReceipt = receipt;
    final published = receipt.manifest.elements
        .where((element) => element.id == id)
        .firstOrNull;
    if (draft != null && published != null) draft.rebase(published);
  }

  Future<bool> saveDrafts() async {
    if (busy) return false;
    busy = true;
    changed();
    try {
      for (final draft in decors.values.toList()) {
        _validateDecorOwner(draft);
        final snapshot = draft.build();
        try {
          await accept(await port.saveElement(snapshot));
        } on ResourceFailure catch (failure) {
          _retainDecorPublication(draft, snapshot.id, failure);
          rethrow;
        }
        draft.rebase(snapshot);
        if (draft.build() == snapshot) {
          decors.removeWhere((key, value) => identical(value, draft));
          if (identical(decor, draft)) decor = null;
        }
      }
      for (final draft in terrains.values.where((t) => t.dirty)) {
        if (!await draft.save(mutate, publish: false)) return false;
      }
      for (final draft
          in environments.values.where((draft) => draft.dirty).toList()) {
        await _saveEnvironment(draft);
      }
      if (!await characters.saveAll()) {
        error = characters.error;
        return false;
      }
      return !dirty;
    } catch (e) {
      if (e is ResourceFailure && e.partialReceipt != null) {
        pendingReceipt = e.partialReceipt;
      }
      error = e.toString();
      changed();
      return false;
    } finally {
      busy = false;
      changed();
    }
  }

  Future<void> saveDecor(ProjectElementEntry element) async {
    if (busy || _disposed || workspace.isDisposed) return;
    final draft = decor;
    _validateDecorOwner(draft);
    busy = true;
    error = null;
    changed();
    try {
      final receipt = await port.saveElement(element);
      await accept(receipt);
      final saved = receipt.manifest.elements.firstWhere(
        (e) => e.id == element.id,
      );
      if (draft != null && draft.build() != element) {
        draft.rebase(saved);
      } else {
        decors.removeWhere((k, v) => identical(v, draft));
        if (identical(decor, draft)) {
          decor = null;
          showLibrary(
            ResourceItem(
              id: saved.id,
              name: saved.name,
              kind: ResourceKind.decors,
              element: saved,
              category: saved.categoryId,
              tags: saved.tags,
            ),
          );
        }
      }
    } on Object catch (failure) {
      if (failure is ResourceFailure && failure.partialReceipt != null) {
        _retainDecorPublication(draft, element.id, failure);
      }
      if (!_disposed) error = '$failure';
      rethrow;
    } finally {
      busy = false;
      changed();
    }
  }
}
