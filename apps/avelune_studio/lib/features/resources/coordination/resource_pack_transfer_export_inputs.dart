part of 'resource_pack_transfer_controller.dart';

extension _ResourcePackExportInputs on ResourcePackTransferController {
  String? get _exportValidation {
    try {
      _exportMetadata();
      final url = exportFields['sourceUrl']?.trim() ?? '';
      if (url.isNotEmpty) {
        final uri = Uri.tryParse(url);
        if (uri == null ||
            !const ['http', 'https'].contains(uri.scheme) ||
            uri.host.isEmpty ||
            uri.userInfo.isNotEmpty) {
          return 'Utilisez une URL HTTP ou HTTPS sans identifiants.';
        }
      }
      return null;
    } on Object {
      return 'Renseignez le nom, une version comme 1.0.0, l’auteur (128 caractères maximum), l’univers et la provenance.';
    }
  }

  Map<String, Object?> _exportMetadata() => ResourcePackMetadata(
    id: _exportId,
    version: exportFields['version'] ?? '',
    name: exportFields['name'] ?? '',
    description: exportFields['description'] ?? '',
    universeId: exportFields['universeId'] ?? '',
    authors: [exportFields['author'] ?? ''],
    provenance: exportFields['provenance'] ?? '',
  ).toJson();
  Future<void> _beginExport({
    String projectName = '',
    List<({String kind, String id})> selection = const [],
  }) => _run((epoch) async {
    if (!exportAvailable) return;
    await _release();
    direction = ResourcePackTransferDirection.exporting;
    context = 'all';
    kind = null;
    familyId = null;
    selectedFamilyLabel = null;
    search = '';
    selectedCount = 0;
    addedCount = 0;
    firstImported = null;
    entries = const [];
    preview = const [];
    families = const [];
    attributions = const [];
    inspection = const {};
    preparedSummary = const {};
    notice = null;
    outputPath = null;
    _receipt = null;
    _exportId = 'studio-pack-${DateTime.now().microsecondsSinceEpoch}';
    exportFields = Map.unmodifiable({
      'name': projectName,
      'version': '1.0.0',
      'author': '',
      'description': '',
      'universeId': '',
      'provenance': '',
      'sourceUrl': '',
    });
    final summary = await port.transfer('selection.create', {'mode': 'native'});
    final handle = summary['selectionHandle']! as String;
    _handles.add(handle);
    if (!_current(epoch) || _closing) return;
    _selection = handle;
    _expectedRevision = summary['sourceRevision']! as String;
    _summary(summary);
    if (selection.isNotEmpty) {
      final chosen = await port.transfer('selection.patch', {
        'selectionHandle': handle,
        'revision': _selectionRevision,
        'add': [
          for (final ref in selection.take(200))
            {'kind': ref.kind, 'id': ref.id},
        ],
      });
      if (!_current(epoch) || _closing) return;
      _summary(chosen);
    }
    phase = ResourcePackTransferPhase.selecting;
    await _loadFamilies();
    await _loadAttributions();
    await _loadPage();
  });
  Future<void> _setExportField(String field, String value) async {
    if (!exporting ||
        _disposed ||
        operationActive ||
        requiresPublicationReconciliation ||
        _closing ||
        !const [
          'name',
          'version',
          'author',
          'description',
          'universeId',
          'provenance',
          'sourceUrl',
        ].contains(field)) {
      return;
    }
    exportFields = Map.unmodifiable({...exportFields, field: value});
    _inputRevision++;
    organizationAcknowledged = false;
    if (phase == ResourcePackTransferPhase.complete) outputPath = null;
    phase = ResourcePackTransferPhase.selecting;
    final epoch = _epoch;
    _releasingInputs++;
    final cleanup = _releasePreparation();
    _inputCleanup = Future.wait([_inputCleanup, cleanup]).then<void>(
      (_) {},
      onError: (Object failure, StackTrace stack) {
        if (_current(epoch) && !_closing) {
          error = '$failure';
          _changed();
        }
      },
    );
    _changed();
    try {
      await cleanup;
    } on Object catch (failure) {
      if (_current(epoch) && !_closing) error = '$failure';
    } finally {
      _releasingInputs--;
      if (_current(epoch)) _changed();
    }
  }

  Future<void> _addLicenseDocuments() => _run((epoch) async {
    if (!exporting || pickLicenses == null) return;
    final paths = await pickLicenses!();
    if (!_current(epoch) || _closing || paths == null || paths.isEmpty) return;
    if (paths.length + licenseDocuments.length > 200) {
      throw const ResourceFailure(
        'Choisissez au maximum 200 documents de licence.',
      );
    }
    await _releasePreparation();
    phase = ResourcePackTransferPhase.selecting;
    for (final path in paths) {
      await port.authorizeSource(path);
      if (!_current(epoch) || _closing) return;
      final staged = await _monitor(
        await port.transfer('stage_license', {'sourcePath': path}),
      );
      final handle = staged['licenseHandle']! as String;
      if (licenseDocuments.any((d) => d.rawSha256 == staged['rawSha256'])) {
        await port.transfer('release', {'handle': handle});
        _handles.remove(handle);
        continue;
      }
      licenseDocuments = List.unmodifiable([
        ...licenseDocuments,
        ResourcePackLicenseDocument(
          handle: handle,
          label: path.split(RegExp(r'[/\\]')).last,
          rawSha256: staged['rawSha256']! as String,
          byteLength: staged['byteLength']! as int,
        ),
      ]);
    }
    _inputRevision++;
    organizationAcknowledged = false;
  });
  Future<void> _removeLicenseDocument(String handle) => _run((_) async {
    if (!exporting) return;
    await _releasePreparation();
    await port.transfer('release', {'handle': handle});
    _handles.remove(handle);
    licenseDocuments = List.unmodifiable(
      licenseDocuments.where((d) => d.handle != handle),
    );
    _inputRevision++;
    phase = ResourcePackTransferPhase.selecting;
  });
}
