import 'package:map_core/map_core.dart';

import '../application/working_catalog_controller.dart';
import '../domain/resource_port.dart';
import '../domain/working_catalog_port.dart';

enum WorkingCatalogExitDecision { save, discard, stay }

class WorkingCatalogWorkflow {
  WorkingCatalogWorkflow({
    required this.catalog,
    required this.isActive,
    required this.confirmExit,
    required this.changed,
    this.onSaved,
    this.onRecovered,
    this.onReplaceModelSource,
    this.onModelLightSaved,
    this.readOnly = false,
  });

  final WorkingCatalogController catalog;
  final bool Function() isActive;
  final Future<WorkingCatalogExitDecision> Function() confirmExit;
  final void Function() changed;
  final Future<void> Function()? onSaved, onRecovered;
  final Future<bool> Function(String)? onReplaceModelSource;
  final Future<void> Function(ProjectModel3dEntry, String, String)?
  onModelLightSaved;
  final bool readOnly;
  bool synchronizing = false, synchronizationPending = false;
  bool sourceReplacementActive = false;
  bool sourceReconciliationPending = false, sourceReloadPending = false;
  bool _deciding = false, _closed = false;
  String? saved, navigationNotice;
  int sourcePreviewRevision = 0;
  WorkingCatalogEntry? _sourceOwner;

  bool get active => !_closed && isActive();
  bool get editable =>
      active && !readOnly && !catalog.saving && !sourceReplacementPending;
  bool get sourceReplacementPending =>
      sourceReplacementActive ||
      sourceReconciliationPending ||
      sourceReloadPending;

  void _changed() {
    if (active) changed();
  }

  Future<bool> allowExit({bool closing = false}) async {
    if (!active ||
        _deciding ||
        catalog.saving ||
        catalog.recovering ||
        synchronizing ||
        sourceReplacementActive ||
        (!closing && (sourceReconciliationPending || sourceReloadPending))) {
      return false;
    }
    _deciding = true;
    try {
      if (synchronizationPending && !await synchronize()) return false;
      if (!active) return false;
      if (!catalog.dirty) return true;
      final selected = catalog.selected?.identity;
      final draft = catalog.draft;
      final decision = await confirmExit();
      if (!active ||
          catalog.selected?.identity != selected ||
          !identical(catalog.draft, draft)) {
        return false;
      }
      if (decision == WorkingCatalogExitDecision.save) return await save();
      if (decision == WorkingCatalogExitDecision.discard) {
        catalog.discard();
        return !catalog.dirty;
      }
      return false;
    } finally {
      _deciding = false;
    }
  }

  Future<void> showLibrary([String destination = 'resources']) async {
    if (!await allowExit() || !active) return;
    navigationNotice =
        const {'resources', 'resourceLibrary', 'library'}.contains(destination)
        ? null
        : 'Cet atelier est accessible depuis la navigation de Studio.';
    _changed();
    final selected = catalog.selected;
    await catalog.search(catalog.query);
    if (active &&
        selected != null &&
        catalog.selected?.identity == selected.identity &&
        !catalog.dirty) {
      await catalog.select(selected);
    }
  }

  Future<void> recover() async {
    if (!active) return;
    await catalog.recover(refresh: onRecovered == null);
    if (!active ||
        catalog.error != null ||
        catalog.recoveryOperationIds.isNotEmpty) {
      return;
    }
    try {
      await onRecovered?.call();
    } on Object catch (failure) {
      if (active) {
        navigationNotice = 'Rouvrez le projet après la reprise : $failure';
      }
    }
    _changed();
  }

  Future<bool> synchronize() async {
    if (!active || synchronizing) return false;
    synchronizing = true;
    _changed();
    try {
      await onSaved?.call();
      synchronizationPending = false;
      return active;
    } on Object catch (failure) {
      if (active) {
        navigationNotice =
            'La ressource est enregistrée, mais la carte ne peut pas être actualisée : $failure';
      }
      return false;
    } finally {
      synchronizing = false;
      _changed();
    }
  }

  Future<bool> save() async {
    if (!editable || synchronizing) return false;
    saved = null;
    if (!await catalog.save()) return false;
    synchronizationPending = true;
    if (!active || !await synchronize() || !active) return false;
    saved = catalog.dirty ? null : 'Ressource enregistrée.';
    _changed();
    return !catalog.dirty;
  }

  Future<void> replaceModelSource() async {
    final selected = catalog.selected;
    final replace = onReplaceModelSource;
    if (!active ||
        readOnly ||
        selected == null ||
        selected.kind != 'model3d' ||
        replace == null ||
        catalog.dirty ||
        catalog.saving ||
        catalog.opening ||
        synchronizing ||
        synchronizationPending ||
        sourceReplacementActive) {
      return;
    }
    if (_sourceOwner != null && _sourceOwner!.identity != selected.identity) {
      navigationNotice =
          'Actualisez le modèle précédent avant de changer de ressource.';
      _changed();
      return;
    }
    _sourceOwner = selected;
    sourceReplacementActive = true;
    saved = null;
    navigationNotice = null;
    _changed();
    try {
      if (!sourceReloadPending && !await replace(selected.id)) {
        _sourceOwner = null;
        return;
      }
      sourceReconciliationPending = false;
      sourceReloadPending = true;
      if (!active ||
          catalog.selected?.identity != selected.identity ||
          catalog.dirty) {
        return;
      }
      sourcePreviewRevision++;
      _changed();
      await catalog.select(selected);
      if (!active ||
          catalog.selected?.identity != selected.identity ||
          catalog.opening ||
          catalog.dirty) {
        return;
      }
      if (catalog.error != null) {
        navigationNotice = 'Le modèle est enregistré. Actualisez son aperçu avant de continuer.';
        return;
      }
      if (catalog.detail?.entry.identity != selected.identity) return;
      sourceReloadPending = false;
      _sourceOwner = null;
      saved = 'Modèle remplacé.';
    } on ResourceFailure catch (failure) {
      sourceReconciliationPending = failure.partialReceipt != null;
      if (!sourceReconciliationPending) _sourceOwner = null;
      navigationNotice = failure.message;
    } on Object catch (failure) {
      if (!sourceReloadPending && !sourceReconciliationPending) {
        _sourceOwner = null;
      }
      navigationNotice = 'Le modèle ne peut pas être remplacé : $failure';
    } finally {
      sourceReplacementActive = false;
      _changed();
    }
  }

  void edit({String? name, String? description, String? placementContext}) {
    if (!editable) return;
    catalog.edit(
      name: name,
      description: description,
      placementContext: placementContext,
    );
  }

  void editTags(String value) {
    if (!editable) return;
    catalog.edit(
      tags: value
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toSet(),
    );
  }

  Future<void> configureLight(Model3dPointLight? light) async {
    if (!editable) return;
    final selected = catalog.detail;
    if (selected == null || selected.entry.kind != 'model3d') return;
    await catalog.configureLight(light);
    final updated = catalog.detail;
    if (!active ||
        updated == null ||
        updated.entry.identity != selected.entry.identity) {
      return;
    }
    final model = updated.definitions.models3d.singleWhere(
      (model) => model.id == selected.entry.id,
    );
    await onModelLightSaved?.call(
      model,
      updated.previousDocumentRevision ?? selected.revision,
      updated.documentRevision ?? updated.revision,
    );
  }

  void dispose() => _closed = true;
}
