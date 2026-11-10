import 'package:map_core/map_core_domain.dart';

import '../application/border_creation_draft.dart';
import '../domain/resource_pack_port.dart';
import '../domain/resource_port.dart';
import 'resource_navigation.dart';

class BorderCreationWorkflow {
  BorderCreationWorkflow({
    required this.navigation,
    required this.draft,
    required this.isActive,
    required this.confirmDiscard,
    required this.confirmRepublication,
  }) {
    _dirtyOwner = () => draft.hasChanges || working;
    _exportOwner = () => ResourcePackBorderDraft(
      request: draft.buildRequest(),
      dirty: draft.hasChanges,
      saving: working,
    );
    _register();
  }

  final ResourceNavigation navigation;
  final BorderCreationDraft draft;
  final bool Function() isActive;
  final Future<bool> Function() confirmDiscard;
  final Future<bool> Function(Map<String, int>) confirmRepublication;
  late final bool Function() _dirtyOwner;
  late final ResourcePackBorderDraft Function() _exportOwner;
  bool _closed = false, _confirmingClose = false, _saving = false;
  bool _completed = false;
  bool _ownershipLost = false;
  ResourceMutationReceipt? _committed;

  bool get working => _confirmingClose || _saving;
  bool get _current =>
      !_closed &&
      !_ownershipLost &&
      isActive() &&
      !navigation.isDisposed &&
      (draft.pendingId == null ||
          (identical(
                navigation.borderEditorOwners[draft.pendingId],
                _dirtyOwner,
              ) &&
              identical(
                navigation.packBorderDraftOwners[draft.pendingId],
                _exportOwner,
              )));

  bool _available(String? id) =>
      id == null ||
      ((navigation.borderEditorOwners[id] == null ||
              identical(navigation.borderEditorOwners[id], _dirtyOwner)) &&
          (navigation.packBorderDraftOwners[id] == null ||
              identical(navigation.packBorderDraftOwners[id], _exportOwner)));

  void _register() {
    final id = draft.pendingId;
    if (_closed || id == null) return;
    navigation.borderEditorOwners[id] = _dirtyOwner;
    navigation.packBorderDraftOwners[id] = _exportOwner;
  }

  Future<bool> requestClose() async {
    if (!_current || working) return false;
    if (!draft.hasChanges || _completed) return true;
    _confirmingClose = true;
    try {
      return await confirmDiscard() && _current;
    } finally {
      _confirmingClose = false;
    }
  }

  Map<String, int> get tracedContours {
    final id = draft.pendingId;
    if (id == null ||
        navigation.workspace.project?.borderCatalog
                .recordById(id)
                ?.latestPublished ==
            null) {
      return const {};
    }
    return {
      for (final document in navigation.workspace.documents.values)
        if (document.current.layers
                .whereType<BorderLayer>()
                .expand((layer) => layer.content.features)
                .where((feature) => feature.blueprintId == id)
                .length
            case final count when count > 0)
          document.current.name: count,
    };
  }

  Future<bool> save({required bool publish}) async {
    if (!_current || working || _completed || navigation.busy) return false;
    if (_committed == null &&
        (draft.name.trim().isEmpty ||
            draft.settingsProblem != null ||
            (publish && !draft.complete) ||
            navigation.pendingReceipt != null)) {
      return false;
    }
    _saving = true;
    draft.saving = true;
    draft.error = null;
    try {
      if (_committed != null) {
        await navigation.accept(_committed!);
        _completed = true;
        return _current;
      }
      final traced = publish ? tracedContours : const <String, int>{};
      if (traced.isNotEmpty && !await confirmRepublication(traced)) {
        return false;
      }
      if (!_current) return false;
      final receipt = await navigation.port.createBorder(
        draft.buildRequest(publish: publish),
      );
      _committed = receipt;
      await navigation.accept(receipt);
      _completed = true;
      return _current;
    } on ResourceFailure catch (failure) {
      final partial = failure.partialReceipt;
      final id = failure.borderId ?? draft.pendingId;
      if (partial != null) {
        final record = partial.manifest.borderCatalog.recordById(id ?? '');
        final before = partial.before.borderCatalog.recordById(id ?? '');
        if (publish &&
            record?.latestPublished != null &&
            record?.latestPublished != before?.latestPublished) {
          _committed = partial;
        }
        if (_current && _available(id)) {
          draft.expectedRecord = record ?? draft.expectedRecord;
          draft.pendingId = id;
          _register();
        } else if (!_available(id)) {
          _ownershipLost = true;
        }
        try {
          await navigation.accept(partial);
        } on Object catch (error) {
          if (_current) draft.error = '${failure.message}\n$error';
          return false;
        }
      }
      if (_current) {
        draft.pendingId = id;
        draft.error = failure.message;
        draft.warningCodes = failure.warningCodes;
        _register();
      }
      return false;
    } on Object catch (failure) {
      if (_current) draft.error = '$failure';
      return false;
    } finally {
      _saving = false;
      draft.saving = false;
    }
  }

  void dispose() {
    _closed = true;
    final id = draft.pendingId;
    if (identical(navigation.borderEditorOwners[id], _dirtyOwner)) {
      navigation.borderEditorOwners.remove(id);
    }
    if (identical(navigation.packBorderDraftOwners[id], _exportOwner)) {
      navigation.packBorderDraftOwners.remove(id);
    }
  }
}
