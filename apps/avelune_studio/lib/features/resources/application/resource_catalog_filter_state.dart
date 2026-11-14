import 'resource_catalog.dart';

class ResourceCatalogFilterState {
  ResourceCatalogFilterState({
    this.familyId = '',
    this.scope = ResourceCatalogScope.all,
    this.usage = ResourceCatalogUsage.all,
    this.context = ResourceCatalogContext.all,
    this.query = '',
    this.showComponents = false,
    this.typeKind = '',
    this.usableOnly = false,
  });
  String familyId;
  ResourceCatalogScope scope;
  ResourceCatalogUsage usage;
  ResourceCatalogContext context;
  String query;
  bool showComponents;
  String typeKind;
  bool usableOnly;

  ResourceCatalogFilterState copy() => ResourceCatalogFilterState(
    familyId: familyId,
    scope: scope,
    usage: usage,
    context: context,
    query: query,
    showComponents: showComponents,
    typeKind: typeKind,
    usableOnly: usableOnly,
  );

  void copyFrom(ResourceCatalogFilterState value) {
    familyId = value.familyId;
    scope = value.scope;
    usage = value.usage;
    context = value.context;
    query = value.query;
    showComponents = value.showComponents;
    typeKind = value.typeKind;
    usableOnly = value.usableOnly;
  }

  int activeFilterCount({
    bool forMapPicker = false,
    bool showType = false,
    bool categorySelected = false,
  }) =>
      (scope == ResourceCatalogScope.all ? 0 : 1) +
      (!forMapPicker && usage != ResourceCatalogUsage.all ? 1 : 0) +
      (showComponents ? 1 : 0) +
      (context == ResourceCatalogContext.all ? 0 : 1) +
      (showType && typeKind.isNotEmpty ? 1 : 0) +
      (categorySelected ? 1 : 0);

  void resetDraftFields() {
    context = ResourceCatalogContext.all;
    scope = ResourceCatalogScope.all;
    usage = ResourceCatalogUsage.all;
    showComponents = false;
    typeKind = '';
  }

  void applyDraft(ResourceCatalogFilterState draft, {bool showType = false}) {
    context = draft.context;
    scope = draft.scope;
    usage = draft.usage;
    showComponents = draft.showComponents;
    if (showType) typeKind = draft.typeKind;
  }

  void reset() {
    familyId = '';
    scope = ResourceCatalogScope.all;
    usage = ResourceCatalogUsage.all;
    context = ResourceCatalogContext.all;
    query = '';
    showComponents = false;
    typeKind = '';
    usableOnly = false;
  }
}

const resourceTypeFilterLabels = {
  '': 'Tous les types',
  'element': 'Décors 2D',
  'model3d': 'Modèles 3D',
  'smartTilePreset': 'Terrains automatiques',
  'tileset': 'Images et tuiles',
  'borderBlueprint': 'Bordures',
  'environmentPreset': 'Environnements',
  'character': 'Personnages',
};
