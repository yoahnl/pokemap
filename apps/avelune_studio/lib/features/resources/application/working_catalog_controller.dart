import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/working_catalog_port.dart';

final class WorkingCatalogController extends ChangeNotifier {
  WorkingCatalogController(
    this.port, {
    Iterable<String> recoveryOperationIds = const [],
  }) : recoveryOperationIds = List.of(recoveryOperationIds);

  final WorkingCatalogPort port;
  final List<String> recoveryOperationIds;
  bool recovering = false;
  List<WorkingCatalogEntry> items = const [];
  String kind = 'element';
  String query = '';
  String placementContext = '';
  int total = 0;
  String? nextCursor;
  String? revision;
  String? _currentCursor;
  final List<String?> _previousCursors = [];
  int get pageNumber => _previousCursors.length + 1;
  bool get hasPreviousPage => _previousCursors.isNotEmpty;
  WorkingCatalogEntry? selected;
  WorkingCatalogDetail? detail;
  WorkingCatalogDraft? draft;
  bool loading = false;
  bool opening = false;
  bool saving = false;
  String? error;
  int _queryGeneration = 0;
  int _detailGeneration = 0;
  bool _disposed = false;

  bool get dirty =>
      draft != null &&
      detail != null &&
      !draft!.sameValues(WorkingCatalogDraft.fromEntry(detail!.entry));

  Future<void> search(String text, {String? kind, String? context}) async {
    if (_disposed) return;
    if (recoveryOperationIds.isNotEmpty) return;
    query = text;
    if (kind != null) this.kind = kind;
    if (context != null) placementContext = context;
    final generation = ++_queryGeneration;
    items = const [];
    total = 0;
    nextCursor = null;
    _currentCursor = null;
    _previousCursors.clear();
    loading = true;
    error = null;
    notifyListeners();
    try {
      final page = await port.query(
        kind: this.kind,
        text: query,
        placementContext: placementContext.isEmpty ? null : placementContext,
      );
      if (_disposed || generation != _queryGeneration) return;
      items = page.items;
      total = page.total;
      revision = page.revision;
      nextCursor = page.nextCursor;
    } catch (failure) {
      if (!_disposed && generation == _queryGeneration) error = '$failure';
    } finally {
      if (!_disposed && generation == _queryGeneration) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> recover({bool refresh = true}) async {
    if (_disposed || recovering) return;
    recovering = true;
    error = null;
    notifyListeners();
    try {
      for (final operation in List.of(recoveryOperationIds)) {
        await port.recover(operation);
        if (_disposed) return;
        recoveryOperationIds.remove(operation);
      }
      if (refresh) await search(query);
    } catch (failure) {
      if (!_disposed) error = '$failure';
    } finally {
      if (!_disposed) {
        recovering = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    final cursor = nextCursor;
    if (_disposed || loading || cursor == null) return;
    final generation = _queryGeneration;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final page = await port.query(
        kind: kind,
        text: query,
        cursor: cursor,
        placementContext: placementContext.isEmpty ? null : placementContext,
      );
      if (_disposed || generation != _queryGeneration) return;
      if (page.revision != revision) {
        throw StateError('Le catalogue a changé. Relancez la recherche.');
      }
      _previousCursors.add(_currentCursor);
      _currentCursor = cursor;
      items = page.items;
      total = page.total;
      nextCursor = page.nextCursor;
    } catch (failure) {
      if (!_disposed && generation == _queryGeneration) error = '$failure';
    } finally {
      if (!_disposed && generation == _queryGeneration) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> previousPage() async {
    if (_disposed || loading || _previousCursors.isEmpty) return;
    final cursor = _previousCursors.last;
    final generation = _queryGeneration;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final page = await port.query(
        kind: kind,
        text: query,
        cursor: cursor,
        placementContext: placementContext.isEmpty ? null : placementContext,
      );
      if (_disposed || generation != _queryGeneration) return;
      if (page.revision != revision) {
        throw StateError('Le catalogue a changé. Relancez la recherche.');
      }
      _previousCursors.removeLast();
      _currentCursor = cursor;
      items = page.items;
      total = page.total;
      nextCursor = page.nextCursor;
    } catch (failure) {
      if (!_disposed && generation == _queryGeneration) error = '$failure';
    } finally {
      if (!_disposed && generation == _queryGeneration) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> select(WorkingCatalogEntry entry) async {
    if (_disposed || saving) return;
    if (dirty && selected?.identity != entry.identity) {
      error = 'Enregistrez ou annulez les modifications avant de changer de ressource.';
      notifyListeners();
      return;
    }
    if (dirty && selected?.identity == entry.identity) return;
    final generation = ++_detailGeneration;
    selected = entry;
    detail = null;
    draft = null;
    opening = true;
    error = null;
    notifyListeners();
    try {
      final result = await port.open(entry);
      if (_disposed || generation != _detailGeneration) return;
      detail = result;
      selected = result.entry;
      draft = WorkingCatalogDraft.fromEntry(result.entry);
    } catch (failure) {
      if (!_disposed && generation == _detailGeneration) error = '$failure';
    } finally {
      if (!_disposed && generation == _detailGeneration) {
        opening = false;
        notifyListeners();
      }
    }
  }

  void edit({
    String? name,
    String? description,
    Iterable<String>? tags,
    String? placementContext,
  }) {
    if (_disposed || draft == null) return;
    draft = draft!.copyWith(
      name: name,
      description: description,
      tags: tags,
      placementContext: placementContext,
    );
    notifyListeners();
  }

  void discard() {
    if (_disposed || saving || detail == null) return;
    draft = WorkingCatalogDraft.fromEntry(detail!.entry);
    error = null;
    notifyListeners();
  }

  Future<bool> save() async {
    final entry = selected;
    final current = detail;
    final snapshot = draft;
    if (_disposed ||
        saving ||
        entry == null ||
        current == null ||
        snapshot == null ||
        !snapshot.valid) {
      return false;
    }
    if (!dirty) return true;
    saving = true;
    error = null;
    notifyListeners();
    try {
      final result = await port.save(
        entry,
        snapshot,
        revision: current.revision,
      );
      if (_disposed) return false;
      final unchanged = draft?.sameValues(snapshot) == true;
      detail = result;
      selected = result.entry;
      if (unchanged) draft = WorkingCatalogDraft.fromEntry(result.entry);
      await search(query);
      return true;
    } catch (failure) {
      if (!_disposed) error = '$failure';
      return false;
    } finally {
      if (!_disposed) {
        saving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _queryGeneration++;
    _detailGeneration++;
    unawaited(port.close());
    super.dispose();
  }
}
