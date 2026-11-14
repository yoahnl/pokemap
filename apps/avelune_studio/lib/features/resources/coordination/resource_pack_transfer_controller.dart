import 'dart:async';
import 'dart:convert';

import 'package:map_core/map_core_domain.dart';

import 'package:flutter/foundation.dart';
import 'package:map_authoring/map_authoring_api.dart';

import '../domain/resource_pack_port.dart';
import '../domain/resource_port.dart';
import 'resource_pack_transfer_phase.dart';

export 'resource_pack_transfer_phase.dart';

part 'resource_pack_transfer_export_inputs.dart';
part 'resource_pack_transfer_export_publication.dart';
part 'resource_pack_transfer_job.dart';
part 'resource_pack_transfer_preparation.dart';
part 'resource_pack_transfer_release.dart';
part 'resource_pack_transfer_selection.dart';

final class ResourcePackTransferController extends ChangeNotifier {
  ResourcePackTransferController({
    required this.port,
    required this.picker,
    required this.accept,
    this.pickLicenses,
    this.exportSink,
    this.localDrafts,
    this.pollInterval = const Duration(milliseconds: 80),
  });
  final PickResourcePackLicenses? pickLicenses;
  final ResourcePackExportSink? exportSink;
  final List<ResourcePackLocalDraft> Function()? localDrafts;
  ResourcePackTransferDirection direction =
      ResourcePackTransferDirection.importing;
  bool get exporting => direction == ResourcePackTransferDirection.exporting;
  bool get exportAvailable => exportSink != null;
  Map<String, String> exportFields = const {};
  List<ResourcePackLicenseDocument> licenseDocuments = const [];
  List<ResourcePackLocalDraft> localNotices = const [];
  bool requiresOrganizationAcknowledgement = false,
      organizationAcknowledged = false;
  String? outputPath;
  String _exportId = "";
  int _inputRevision = 0, _releasingInputs = 0;
  Future<void> _inputCleanup = Future.value();
  String? _artifactHandle;
  String? _pendingPublicationToken;
  final _nativePreviewOwners = <String, String>{};
  Future<void> _nativeOwnerCleanup = Future.value();
  final ResourcePackPort port;
  final PickResourcePack picker;
  final Future<void> Function(ResourceMutationReceipt receipt) accept;
  final Duration pollInterval;
  ResourcePackTransferPhase phase = ResourcePackTransferPhase.idle;
  String? error, notice, jobPhase;
  String context = 'all', search = '';
  String? kind;
  String? familyId, selectedFamilyLabel;
  List<Map<String, Object?>> families = const [], attributions = const [];
  String? familyCursor, attributionCursor;
  String attributionSection = 'authors';
  int familyCount = 0, attributionCount = 0;
  Map<String, Object?> inspection = const {}, preparedSummary = const {};
  List<Map<String, Object?>> budgetReports = const [];
  Map<String, int> jobCounters = const {};
  List<Map<String, Object?>> entries = const [], preview = const [];
  int selectedCount = 0,
      visibleCount = 0,
      totalCount = 0,
      resourceCount = 0,
      conflictCount = 0;
  String? nextCursor, previewCursor;
  bool operationActive = false, cancelAllowed = true, routeActive = false;
  bool _disposed = false, _closing = false;
  int _epoch = 0, _pageEpoch = 0;
  String? _selection,
      _selectionRevision,
      _prepared,
      _previewHandle,
      _expectedRevision,
      _jobId,
      _operationId;
  final _handles = <String>{};
  ResourceMutationReceipt? _receipt;
  ({String kind, String id})? firstImported;
  int addedCount = 0;
  ResourceMutationReceipt? get pendingReceipt => _receipt;
  Future<void>? _operation;
  Future<bool>? _closeFuture;
  bool get requiresReconciliation =>
      phase == ResourcePackTransferPhase.reconciliationRequired;
  bool get requiresRecovery =>
      phase == ResourcePackTransferPhase.recoveryRequired;
  bool get requiresPublicationReconciliation =>
      _pendingPublicationToken != null;
  bool get blocksClose =>
      requiresPublicationReconciliation ||
      requiresReconciliation ||
      requiresRecovery ||
      (operationActive && !cancelAllowed);
  bool get canPrepare =>
      !operationActive &&
      selectedCount > 0 &&
      phase == ResourcePackTransferPhase.selecting &&
      _releasingInputs == 0 &&
      (!exporting || exportValidation == null);
  bool get canDiagnose => !operationActive && _selection != null &&
      phase == ResourcePackTransferPhase.selecting && !_closing;
  bool get canApply =>
      !operationActive &&
      !exporting &&
      phase == ResourcePackTransferPhase.preview &&
      _prepared != null &&
      conflictCount == 0;
  Map<String, Object?> get filter => {
    'context': context,
    if (kind != null) 'kind': kind,
    if (familyId != null) 'familyId': familyId,
    if (search.trim().isNotEmpty) 'search': search.trim(),
  };

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  bool _current(int epoch) => !_disposed && epoch == _epoch;
  Future<void> _run(
    Future<void> Function(int epoch) work, {
    bool publicationRetry = false,
  }) {
    if (_disposed ||
        operationActive ||
        (blocksClose &&
            !(publicationRetry && requiresPublicationReconciliation)) ||
        _closing) {
      return Future.value();
    }
    final epoch = _epoch;
    operationActive = true;
    error = null;
    cancelAllowed = !publicationRetry;
    jobPhase = null;
    jobCounters = const {};
    _changed();
    final operation = () async {
      try {
        await _inputCleanup;
        if (!_current(epoch)) return;
        await work(epoch);
      } on _PackCancelled {
        if (_current(epoch)) phase = ResourcePackTransferPhase.closed;
      } on _PackRecovery {
        if (_current(epoch)) {
          phase = ResourcePackTransferPhase.recoveryRequired;
          notice = 'La finalisation nécessite une reprise du projet.';
        }
      } on Object catch (failure) {
        if (_current(epoch)) {
          error = '$failure';
          if (requiresPublicationReconciliation) {
            phase = ResourcePackTransferPhase.publicationRequired;
            notice = 'Le résultat de publication doit être relu avant de fermer le projet.';
            return;
          }
          if (failure is ResourceFailure && failure.partialReceipt != null) {
            _receipt = failure.partialReceipt;
          }
          if (failure is ResourcePackCommittedFailure || _receipt != null) {
            phase = ResourcePackTransferPhase.reconciliationRequired;
            notice = 'Import terminé — relire la bibliothèque';
          } else {
            phase = _selection == null
                ? ResourcePackTransferPhase.idle
                : ResourcePackTransferPhase.selecting;
          }
        }
      } finally {
        if (_current(epoch)) {
          operationActive = false;
          _jobId = null;
          _changed();
        }
      }
    }();
    _operation = operation;
    return operation;
  }

  Future<void> beginImport() => _beginImport();

  String? get exportValidation => _exportValidation;

  bool get canExport =>
      exporting &&
      exportAvailable &&
      !operationActive &&
      _releasingInputs == 0 &&
      phase == ResourcePackTransferPhase.preview &&
      _prepared != null &&
      (!requiresOrganizationAcknowledgement || organizationAcknowledged);
  Future<void> beginExport({
    String projectName = '',
    List<({String kind, String id})> selection = const [],
  }) => _beginExport(projectName: projectName, selection: selection);
  Future<void> setExportField(String field, String value) =>
      _setExportField(field, value);

  void setOrganizationAcknowledgement(bool value) {
    if (!exporting ||
        operationActive ||
        phase != ResourcePackTransferPhase.preview) {
      return;
    }
    organizationAcknowledged = value;
    _changed();
  }

  Future<void> addLicenseDocuments() => _addLicenseDocuments();
  Future<void> removeLicenseDocument(String handle) =>
      _removeLicenseDocument(handle);
  Future<void> export() => _export();
  Future<void> retryPublication() => _run((_) async {
    final token = _pendingPublicationToken;
    if (token == null) return;
    _acceptPublication(await exportSink!.reconcilePublication(token));
  }, publicationRetry: true);

  Future<void> setFilter({
    String? context,
    String? kind,
    String? search,
    String? familyId,
  }) => _setFilter(
    context: context,
    kind: kind,
    search: search,
    familyId: familyId,
  );

  Future<void> nextPage() => _run((_) async => _loadPage(cursor: nextCursor));
  Future<void> firstPage() => _run((_) async => _loadPage());
  Future<void> nextFamilyPage() =>
      _run((_) => _loadFamilies(cursor: familyCursor));
  Future<void> firstFamilyPage() => _run((_) => _loadFamilies());

  Future<void> showAttributions(String section) => _run((_) async {
    attributionSection = section;
    await _loadAttributions();
  });
  Future<void> nextAttributionPage() =>
      _run((_) => _loadAttributions(cursor: attributionCursor));
  Future<void> selectFiltered() => _selectFiltered();
  Future<void> toggle(Map<String, Object?> entry) => _toggle(entry);
  Future<void> prepare({bool importCopy = false}) =>
      _prepare(importCopy: importCopy);
  Future<void> diagnose() => _diagnose();

  Future<void> nextPreviewPage() =>
      _run((_) => _loadPreview(cursor: previewCursor));
  Future<void> backToSelection() => _run((_) async {
    await _releasePreparation();
    phase = ResourcePackTransferPhase.selecting;
    _changed();
  });

  Future<void> apply() => _apply();
  Future<bool> retryReconciliation() => _retryReconciliation();
  Future<void> recover() => _recover();

  Future<bool> requestClose() =>
      _closeFuture ??= _requestClose().whenComplete(() {
        _closeFuture = null;
      });

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    unawaited(port.dispose());
    super.dispose();
  }
}
