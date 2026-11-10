import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core_domain.dart';

import 'project_surf_controller.dart';

class ProjectSurfConditionController extends ChangeNotifier {
  ProjectSurfConditionController({required this.owner, this.loadItems}) {
    _condition = owner.preview.value.condition;
    _source = owner.conditionSourceDraft;
    owner.addListener(_ownerChanged);
  }

  final ProjectSurfController owner;
  final Future<Map<String, String>> Function()? loadItems;
  String kind = 'fact';
  Map<String, String> items = const {};
  NarrativeFactDefinition? fact;
  String? error;
  bool loading = false;
  ScriptCondition? _condition;
  String? _source;
  int _generation = 0;
  bool _disposed = false;

  bool get editable =>
      !_disposed &&
      !loading &&
      !owner.loading &&
      !owner.saving &&
      !owner.loadingReferences &&
      owner.saved != null;

  Future<void> start() async {
    await owner.loadReferences();
    if (!_disposed) await _synchronize();
  }

  Future<void> _synchronize() async {
    if (_disposed) return;
    final condition = owner.preview.value.condition;
    _condition = condition;
    _source = owner.conditionSourceDraft;
    kind =
        _source ??
        switch (condition?.type) {
          ScriptConditionType.badgeOwned => 'badge',
          ScriptConditionType.itemQuantityAtLeast => 'item',
          ScriptConditionType.factEquals || null => 'fact',
          _ => 'advanced',
        };
    if (kind == 'item') await loadItemReferences();
    if (kind == 'fact' && condition != null && _source == null) {
      final id = condition.params[ScriptConditionParams.factId];
      if (id != null && fact?.id != id) await selectFact(id, apply: false);
    }
  }

  void _ownerChanged() {
    if (_disposed) return;
    if (_condition != owner.preview.value.condition ||
        _source != owner.conditionSourceDraft) {
      unawaited(_synchronize());
    }
    if (owner.inputError == null) error = null;
    notifyListeners();
  }

  Future<void> selectSource(String value) async {
    if (_disposed || owner.loading || owner.saving) return;
    _generation++;
    kind = value;
    fact = null;
    error = null;
    loading = false;
    owner.selectConditionSource(value);
    if (value == 'item') await loadItemReferences();
    if (!_disposed) notifyListeners();
  }

  Future<void> loadItemReferences() async {
    if (_disposed || items.isNotEmpty || loading) return;
    final generation = ++_generation;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final loader = loadItems;
      if (loader == null) {
        throw StateError('Le catalogue des objets est indisponible.');
      }
      final result = await loader();
      if (!_disposed && generation == _generation) {
        items = Map.unmodifiable(result);
      }
    } on Object catch (failure) {
      if (!_disposed && generation == _generation) error = '$failure';
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectReference(String id) async {
    if (!editable) return;
    if (kind == 'fact') {
      await selectFact(id);
    } else if (kind == 'badge') {
      owner.change(condition: ScriptConditionFactory.badgeOwned(id));
    } else if (kind == 'item') {
      owner.change(
        condition: ScriptConditionFactory.itemQuantityAtLeast(id, 1),
      );
    }
  }

  Future<void> selectFact(String id, {bool apply = true}) async {
    if (_disposed || owner.loading || owner.saving) return;
    if (apply) owner.selectConditionSource('fact');
    final revision = owner.draftRevision;
    final generation = ++_generation;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await owner.port.loadSurfFact(owner.session, id);
      if (_disposed ||
          generation != _generation ||
          owner.preview.value.accessMode != ProjectSurfAccessMode.condition ||
          owner.draftRevision != revision) {
        return;
      }
      if (result.id != id) {
        throw StateError(
          'La référence chargée ne correspond pas à la demande.',
        );
      }
      fact = result;
      if (apply) {
        owner.change(
          condition: ScriptConditionFactory.factEquals(id, result.initialValue),
        );
      }
    } on Object catch (failure) {
      if (!_disposed && generation == _generation) error = '$failure';
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void editValue(String raw) {
    if (!editable) return;
    final condition = owner.preview.value.condition;
    final id = condition?.params[ScriptConditionParams.factId];
    final selected = fact;
    if (kind != 'fact' || id == null || selected?.id != id) return;
    final integer = int.tryParse(raw);
    if (selected!.valueKind == NarrativeValueKind.integer &&
        (integer == null ||
            integer < -9007199254740991 ||
            integer > 9007199254740991)) {
      error = 'Saisissez un entier compris entre −9007199254740991 et 9007199254740991.';
      owner.rejectInput(error!, value: raw);
      return;
    }
    error = null;
    owner.acceptInput();
    owner.change(
      condition: ScriptConditionFactory.factEquals(
        id,
        switch (selected.valueKind) {
          NarrativeValueKind.integer => NarrativeValue.integer(integer!),
          NarrativeValueKind.boolean => NarrativeValue.boolean(raw == 'true'),
          _ => NarrativeValue.string(raw),
        },
      ),
    );
  }

  void editQuantity(String raw) {
    if (!editable || kind != 'item') return;
    final id =
        owner.preview.value.condition?.params[ScriptConditionParams.itemId];
    if (id == null) return;
    final quantity = int.tryParse(raw);
    if (quantity == null || quantity < 1 || quantity > 9007199254740991) {
      error = 'Saisissez une quantité supérieure à zéro.';
      owner.rejectInput(error!, value: raw);
      return;
    }
    error = null;
    owner.acceptInput();
    owner.change(
      condition: ScriptConditionFactory.itemQuantityAtLeast(id, quantity),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    owner.removeListener(_ownerChanged);
    super.dispose();
  }
}
