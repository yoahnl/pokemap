part of 'resource_pack_projection.dart';

final class NativeResourcePackAttribution {
  NativeResourcePackAttribution(
      {required Iterable<ResourcePackProvenance> provenance,
      required Iterable<ResourcePackFileBinding> files,
      required Iterable<ResourcePackBuildSource> licenses})
      : provenance = List.unmodifiable(provenance),
        files = List.unmodifiable(files),
        licenses = List.unmodifiable(licenses);

  final List<ResourcePackProvenance> provenance;
  final List<ResourcePackFileBinding> files;
  final List<ResourcePackBuildSource> licenses;
}

final class _NativeAttributions {
  _NativeAttributions(
      this.projection, NativeResourcePackAttribution? declared) {
    final selectedFiles = <String>{};
    final selectedResources = <String>{};
    final selectedNodes = projection.completed.keys.toSet();
    for (final key in projection.completed.keys) {
      final node = projection.nodes[key]!;
      if (node.kind == 'file') {
        selectedFiles.add(node.id);
      }
      if (ResourcePackKind.values.any((kind) => kind.name == node.kind)) {
        selectedResources.add(key);
      }
    }
    for (final installation
        in projection.manifest.resourcePackInstallations.entries) {
      final mappedResources = {
        for (final mapping in installation.resources)
          mapping.source.identity:
              _key(mapping.source.kind.name, mapping.targetId)
      };
      final selectedMappings = installation.assets
          .where((mapping) => selectedFiles.contains(mapping.assetId))
          .toList();
      final touched = selectedMappings.isNotEmpty ||
          mappedResources.values.any(selectedResources.contains) ||
          installation.supports.any((mapping) => selectedNodes.contains(_key(
              mapping.kind.name, mapping.targetId, mapping.targetOwnerId)));
      if (!touched) continue;
      final mediaOrigins =
          installation.assets.map((mapping) => mapping.provenanceId).toSet();
      final globals = {
        for (final origin in installation.origins)
          if (origin.resources.isEmpty && !mediaOrigins.contains(origin.id))
            origin.id
      };
      final selectedOrigins =
          selectedMappings.map((mapping) => mapping.provenanceId).toSet();
      final selectedOriginResources = <String, List<String>>{};
      for (final origin in installation.origins) {
        final keys = origin.resources
            .map((ref) => mappedResources[ref.identity]!)
            .where(selectedResources.contains)
            .toList();
        if (keys.isNotEmpty ||
            selectedOrigins.contains(origin.id) ||
            globals.contains(origin.id)) {
          selectedOriginResources[origin.id] = keys;
        }
      }
      if (selectedOriginResources.isEmpty) {
        continue;
      }
      final licenses = {
        for (final mapping in installation.licenses) mapping.sourcePath: mapping
      };
      for (final origin in installation.origins
          .where((origin) => selectedOriginResources.containsKey(origin.id))) {
        final id = _scopedOrigin(installation.installationId, origin.id);
        _addOrigin(id, origin, selectedOriginResources[origin.id]!);
        if (globals.contains(origin.id)) _reachedGlobalOrigins.add(id);
        _nativeLicenses[id] = licenses;
      }
      for (final mapping in selectedMappings) {
        final native = projection.files[mapping.assetId]!;
        if (native.logicalPath != mapping.targetPath ||
            native.rawSha256 != mapping.rawSha256 ||
            native.byteLength != mapping.byteLength ||
            native.mediaType != mapping.mediaType) {
          _fail('attribution_source_changed', mapping.assetId);
        }
        _addFile(
            mapping.assetId,
            _scopedOrigin(installation.installationId, mapping.provenanceId),
            mapping.licenseIds);
      }
    }
    if (declared != null) {
      final origins = <String, ResourcePackProvenance>{};
      for (final origin in declared.provenance) {
        if (origins.containsKey(origin.id)) {
          _fail('attribution_duplicate_origin', origin.id);
        }
        origins[origin.id] = origin;
      }
      final documents = <String, ResourcePackBuildSource>{};
      for (final document in declared.licenses) {
        _validateDocument(document);
        if (documents.containsKey(document.path)) {
          _fail('attribution_duplicate_license', document.path);
        }
        documents[document.path] = document;
      }
      final selectedBindings = <String, ResourcePackFileBinding>{};
      for (final binding in declared.files) {
        if (!origins.containsKey(binding.provenanceId) ||
            binding.licenseIds.any((id) => !documents.containsKey(id))) {
          _fail('attribution_association_invalid', binding.id);
        }
        final native = projection.files[binding.id];
        if (native == null ||
            native.logicalPath != binding.logicalPath ||
            native.rawSha256 != binding.rawSha256 ||
            native.byteLength != binding.byteLength ||
            native.mediaType != binding.mediaType) {
          _fail('attribution_source_changed', binding.id);
        }
        if (selectedFiles.contains(binding.id)) {
          if (selectedBindings.containsKey(binding.id)) {
            _fail('attribution_ambiguous', binding.id);
          }
          selectedBindings[binding.id] = binding;
        }
      }
      final boundOrigins = selectedBindings.values
          .map((binding) => binding.provenanceId)
          .toSet();
      for (final origin in declared.provenance) {
        if (origin.licenseIds.any((id) => !documents.containsKey(id))) {
          _fail('license_document_missing', origin.id);
        }
        for (final ref in origin.resources) {
          if (!projection.nodes.containsKey(_key(ref.kind.name, ref.id))) {
            _fail('attribution_association_invalid', ref.identity);
          }
        }
        final keys = origin.resources
            .map((ref) => _key(ref.kind.name, ref.id))
            .where(selectedResources.contains)
            .toList();
        if (keys.isNotEmpty || boundOrigins.contains(origin.id)) {
          final id = _scopedOrigin('native', origin.id, local: true);
          _addOrigin(id, origin, keys);
          _declaredLicenses[id] = documents;
        }
      }
      for (final binding in selectedBindings.values) {
        _addFile(
            binding.id,
            _scopedOrigin('native', binding.provenanceId, local: true),
            binding.licenseIds);
      }
    }
    _resolveDocuments();
  }

  final _Projection projection;
  final Map<String, ResourcePackProvenance> _origins = {};
  final Map<String, Set<String>> resourceOrigins = {};
  final Map<String, (String, List<String>)> fileOrigins = {};
  final Map<String, List<ResourcePackBuildSource>> _documents = {};
  final Map<String, Map<String, ResourcePackLicenseMapping>> _nativeLicenses =
      {};
  final Map<String, Map<String, ResourcePackBuildSource>> _declaredLicenses =
      {};
  final Set<String> _reachedOrigins = {};
  final Set<String> _reachedGlobalOrigins = {};
  final Set<String> documentFileIds = {};

  void _addOrigin(
      String id, ResourcePackProvenance origin, List<String> resources) {
    _origins[id] = ResourcePackProvenance(
        id: id,
        author: origin.author,
        sourceUrl: origin.sourceUrl,
        licenseIds: origin.licenseIds,
        resources: [
          for (final key in resources)
            ResourcePackRef(
                kind:
                    ResourcePackKind.values.byName(projection.nodes[key]!.kind),
                id: projection.allocate(key))
        ]);
    for (final key in resources) {
      resourceOrigins.putIfAbsent(key, () => {}).add(id);
    }
  }

  void _addFile(String id, String origin, List<String> licenses) {
    final existing = fileOrigins[id];
    if (existing != null) {
      final previous = _origins[existing.$1]!;
      final candidate = _origins[origin]!;
      if (previous.author != candidate.author ||
          previous.sourceUrl != candidate.sourceUrl ||
          jsonEncode(previous.licenseIds) != jsonEncode(candidate.licenseIds) ||
          jsonEncode(existing.$2) != jsonEncode(licenses)) {
        _fail('attribution_ambiguous', id);
      }
      final previousOwnsResource = previous.resources.isNotEmpty;
      final candidateOwnsResource = candidate.resources.isNotEmpty;
      if (previousOwnsResource && !candidateOwnsResource ||
          previousOwnsResource == candidateOwnsResource &&
              existing.$1.compareTo(origin) <= 0) {
        return;
      }
    }
    fileOrigins[id] = (origin, licenses);
  }

  void _resolveDocuments() {
    final required = <String, Set<String>>{
      for (final origin in _origins.values)
        if (origin.resources.isNotEmpty ||
            _reachedGlobalOrigins.contains(origin.id))
          origin.id: {...origin.licenseIds},
    };
    for (final binding in fileOrigins.values) {
      required
          .putIfAbsent(binding.$1, () => {..._origins[binding.$1]!.licenseIds})
          .addAll(binding.$2);
    }
    _reachedOrigins.addAll(required.keys);
    final declaredSources = Set<ResourcePackBuildSource>.identity();
    for (final entry in required.entries) {
      for (final path in entry.value) {
        final nativeDescriptor = _nativeLicenses[entry.key]?[path];
        if (nativeDescriptor != null) {
          final native = projection
              .files[projection.filesByPath[nativeDescriptor.targetPath]];
          if (native == null) {
            _fail('license_document_missing', path);
          }
          if (native.rawSha256 != nativeDescriptor.rawSha256 ||
              native.byteLength != nativeDescriptor.byteLength ||
              native.mediaType != 'text/plain') {
            _fail('license_document_changed', path);
          }
          if (documentFileIds.add(native.id)) {
            _addDocument(ResourcePackBuildSource(
                path: path,
                byteLength: nativeDescriptor.byteLength,
                rawSha256: nativeDescriptor.rawSha256,
                mediaType: 'text/plain',
                openRead: native.openRead));
          }
        } else {
          final declared = _declaredLicenses[entry.key]?[path];
          if (declared == null) {
            _fail('license_document_missing', path);
          }
          if (declaredSources.add(declared)) {
            _addDocument(declared);
          }
        }
      }
    }
  }

  void _addDocument(ResourcePackBuildSource source) {
    _validateDocument(source);
    final aliases = _documents.putIfAbsent(source.path, () => []);
    if (aliases.isNotEmpty &&
        (aliases.first.byteLength != source.byteLength ||
            aliases.first.rawSha256 != source.rawSha256)) {
      _fail('license_document_changed', source.path);
    }
    aliases.add(source);
  }

  void _validateDocument(ResourcePackBuildSource document) {
    document.inventory;
    if (document.mediaType != 'text/plain' ||
        document.path != 'licenses/${document.rawSha256}.txt' ||
        document.byteLength > projection.policy.maxFileBytes) {
      _fail('license_document_invalid', document.path);
    }
  }

  Map<String, ResourcePackBuildSource> documentSources() => {
        for (final entry in _documents.entries)
          entry.key: ResourcePackBuildSource(
              path: entry.key,
              byteLength: entry.value.first.byteLength,
              rawSha256: entry.value.first.rawSha256,
              mediaType: 'text/plain',
              openRead: () async* {
                for (final alias in entry.value.skip(1)) {
                  await _verifiedDocumentChunks(alias, projection.policy)
                      .drain<void>();
                }
                yield* _verifiedDocumentChunks(
                    entry.value.first, projection.policy);
              })
      };

  List<ResourcePackProvenance> portableOrigins() => _origins.values
      .where((origin) => _reachedOrigins.contains(origin.id))
      .toList()
    ..sort((a, b) => a.id.compareTo(b.id));
}

String _scopedOrigin(String installationId, String originId,
        {bool local = false}) =>
    'origin_${sha256.convert(utf8.encode(jsonEncode([
              local ? 'local' : 'installation',
              installationId,
              originId
            ]))).toString().substring(0, 48)}';

Stream<List<int>> _verifiedDocumentChunks(ResourcePackBuildSource document,
    ResourcePackSecurityPolicy policy) async* {
  var length = 0;
  final digest = _RawDigestReceiver();
  final hasher = sha256.startChunkedConversion(digest);
  final decoder = utf8.decoder.startChunkedConversion(const _DiscardText());
  await for (final chunk in document.openRead()) {
    if (chunk.length > policy.maxChunkBytes ||
        chunk.any((value) => value < 0 || value > 255)) {
      _fail('source_chunk_invalid', document.path);
    }
    length += chunk.length;
    if (length > document.byteLength) {
      _fail('license_document_changed', document.path);
    }
    hasher.add(chunk);
    decoder.add(chunk);
    yield Uint8List.fromList(chunk);
  }
  decoder.close();
  hasher.close();
  if (length != document.byteLength || digest.value != document.rawSha256) {
    _fail('license_document_changed', document.path);
  }
}

final class _RawDigestReceiver implements Sink<Digest> {
  String? value;
  @override
  void add(Digest digest) {
    value = digest.toString();
  }

  @override
  void close() {}
}

final class _DiscardText implements Sink<String> {
  const _DiscardText();
  @override
  void add(String value) {}
  @override
  void close() {}
}
