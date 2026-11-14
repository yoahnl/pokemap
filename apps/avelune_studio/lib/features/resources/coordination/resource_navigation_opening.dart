part of 'resource_navigation.dart';

extension _ResourceNavigationOpening on ResourceNavigation {
  Future<bool> _loadFamily(ResourceLibraryFamily family) async {
    if (_disposed || workspace.isDisposed) return false;
    final request = ++_libraryLoadRequest;
    try {
      await workspace.ensureResourceKind(family.canonicalKind);
      if (_disposed || workspace.isDisposed || request != _libraryLoadRequest) {
        return false;
      }
      error = null;
      changed();
      return true;
    } catch (failure) {
      if (!_disposed && request == _libraryLoadRequest) {
        error = 'Cette famille ne peut pas être chargée : $failure';
        changed();
      }
      return false;
    }
  }

  Future<void> _openCharacters([String? characterId]) async {
    if (_disposed || workspace.isDisposed) return;
    final request = ++_libraryLoadRequest;
    try {
      await workspace.ensureResourceKind('character');
      if (_disposed || workspace.isDisposed || request != _libraryLoadRequest) {
        return;
      }
      if (characterId != null) characters.select(characterId);
      page = ResourcePage.characters;
      error = null;
      changed();
    } catch (failure) {
      if (!_disposed && request == _libraryLoadRequest) {
        error = 'Les personnages ne peuvent pas être chargés : $failure';
        changed();
      }
    }
  }

  void _openElement(ProjectElementEntry? element, {bool edit = false}) {
    final item = element == null
        ? null
        : ResourceItem(
            id: element.id,
            name: element.name,
            kind: ResourceKind.decors,
            element: element,
            category: element.categoryId,
            tags: element.tags,
          );
    if (edit && item != null) {
      this.edit(item);
    } else {
      showLibrary(item);
    }
  }

  Future<void> _import(
    ResourceImageImport request, {
    ResourceImportIntent intent = ResourceImportIntent.decor,
  }) async {
    busy = true;
    error = null;
    importedSource = null;
    _notifyListeners();
    try {
      final receipt = await port.importImage(request);
      final manifest = await accept(receipt);
      final tileset = manifest.tilesets.firstWhere(
        (t) => t.id == receipt.createdTilesetId,
      );
      final item = ResourceItem(
        id: tileset.id,
        name: tileset.name,
        kind: ResourceKind.images,
        tileset: tileset,
        category: tileset.folderId ?? '',
      );
      switch (intent) {
        case ResourceImportIntent.decor:
          edit(item);
        case ResourceImportIntent.terrain:
          prepareTerrain(item);
        case ResourceImportIntent.source:
          importedSource = item;
          showLibrary(item);
      }
    } catch (e) {
      if (e is ResourceFailure && e.partialReceipt != null) {
        pendingReceipt = e.partialReceipt;
      }
      error = e.toString();
    } finally {
      busy = false;
      changed();
    }
  }

  void _edit(ResourceItem item) {
    importedSource = null;
    if (item.model3d != null) {
      library.selectFamily(ResourceLibraryFamily.models3d);
      showLibrary(item);
      return;
    }
    if (item.environment case final preset?) {
      openEnvironment(preset);
      return;
    }
    if (item.character != null) {
      openCharacters(item.id);
      return;
    }
    if (item.border != null) {
      openBorders();
      return;
    }
    final project = workspace.project!;
    final tileset =
        item.tileset ??
        project.tilesets.firstWhere((t) => t.id == item.element!.tilesetId);
    if (item.element == null && !canCreateDecor(tileset, project)) {
      error = decorConversionProblem(tileset, project);
      showLibrary(item);
      return;
    }
    decor = decors.putIfAbsent(
      item.identity,
      () => DecorDraft(tileset: tileset, original: item.element),
    );
    page = ResourcePage.decor;
    _notifyListeners();
  }

  void _completeTerrainPublication(ProjectSmartTilePreset preset) {
    final item = ResourceItem(
      id: preset.id,
      name: preset.name,
      kind: ResourceKind.terrains,
      terrain: preset,
      category: preset.categoryId,
      tags: preset.tags,
    );
    if (workspace.project!.maps.isEmpty) {
      showLibrary(item);
    } else {
      onUse(item);
    }
  }
}
