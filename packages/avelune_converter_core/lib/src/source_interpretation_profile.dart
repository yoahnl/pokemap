part of '../avelune_converter_core.dart';

final class SourceInterpretationProfile {
  static const maxEncodedBytes = 2097152;
  SourceInterpretationProfile._(
      this.profileId,
      this.scriptsRelativePath,
      this.scriptsArchiveHash,
      this.capabilities,
      this.sections,
      this.declaredPrograms);

  static const jsonLimits = ContractLimits(
      maxDepth: 32,
      maxNodes: 131072,
      maxStringCodeUnits: 512,
      maxTextCodeUnits: 2097152);

  factory SourceInterpretationProfile.fromJson(Object? input) {
    const limits = jsonLimits;
    final encoded = canonicalJsonOf(input, limits: limits);
    if (utf8.encode(encoded).length > maxEncodedBytes) {
      throw ContractError('interpretation_profile.quota', r'$',
          'Source interpretation profile exceeds its byte budget.');
    }
    final json = _interpretationObject(jsonDecode(encoded));
    _interpretationKeys(json, const {
      'kind',
      'schemaVersion',
      'profileId',
      'semanticsId',
      'scriptsArchive',
      'capabilities',
      'sections',
      'declaredPrograms'
    });
    _require(
        json['kind'] == 'sourceInterpretationProfile' &&
            json['schemaVersion'] is int &&
            json['schemaVersion'] == 2 &&
            json['semanticsId'] == 'rmxp-essentials-static-v1',
        'interpretation_profile.schema',
        r'$',
        'Unsupported static source interpretation contract.');
    final archive = _interpretationObject(json['scriptsArchive']);
    _interpretationKeys(archive, const {'relativePath', 'sha256'});
    final path = _interpretationString(archive['relativePath']);
    _require(
        path == 'Data/Scripts.rxdata',
        'interpretation_profile.archive',
        r'$',
        'Static RMXP interpretation requires the compiled Scripts archive.');
    final rawCapabilities = json['capabilities'];
    _require(
        rawCapabilities is List &&
            rawCapabilities.isNotEmpty &&
            rawCapabilities.length <= 4,
        'interpretation_profile.capabilities',
        r'$',
        'Select bounded supported source capabilities.');
    final capabilities =
        (rawCapabilities as List).map(_interpretationString).toSet();
    _require(
        capabilities.length == rawCapabilities.length &&
            capabilities.every(const {
              'walking',
              'events',
              'autotiles',
              'encounters'
            }.contains),
        'interpretation_profile.capabilities',
        r'$',
        'Unknown or duplicate source capability.');
    final rawSections = _interpretationObject(json['sections']);
    _require(
        rawSections.isNotEmpty && rawSections.length <= 128,
        'interpretation_profile.sections',
        r'$',
        'Provide bounded script-section witnesses.');
    final sections = <String, Map<String, Object?>>{};
    for (final entry in rawSections.entries) {
      _require(
          RegExp(r'^[A-Za-z][A-Za-z0-9_.-]{0,95}$').hasMatch(entry.key),
          'interpretation_profile.sections',
          r'$',
          'Invalid script-section role.');
      final section = _interpretationObject(entry.value);
      _interpretationKeys(section, const {'index', 'sha256', 'name', 'lines'});
      final index = section['index'];
      _require(
          index is int && index >= 0 && index <= 65535,
          'interpretation_profile.sections',
          r'$',
          'Invalid script-section index.');
      final hash = Sha256Hash(_interpretationString(section['sha256']));
      final name = section['name'];
      if (name != null) _interpretationString(name);
      final lines = section['lines'];
      if (lines != null) {
        _require(
            lines is List &&
                lines.length == 2 &&
                lines.every(
                    (line) => line is int && line > 0 && line <= 1000000) &&
                (lines[0] as int) <= (lines[1] as int),
            'interpretation_profile.sections',
            r'$',
            'Invalid script-section line range.');
      }
      sections[entry.key] = Map.unmodifiable({
        'index': index,
        'sha256': hash.value,
        if (name != null) 'name': name,
        if (lines != null) 'lines': List.unmodifiable(lines as List)
      });
    }
    for (final capability in capabilities) {
      _require(
          sections.keys.any((role) => role.startsWith('$capability.')) ||
              capability == 'encounters' && capabilities.contains('events'),
          'interpretation_profile.sections',
          r'$',
          'Each capability requires its script witnesses.');
    }
    final rawPrograms = json['declaredPrograms'] ?? const [];
    _require(
        rawPrograms is List && rawPrograms.length <= 256,
        'declared_program.quota',
        r'$',
        'Declared program bindings must be bounded.');
    final programs = (rawPrograms as List)
        .map(SourceDeclaredProgramBinding.fromJson)
        .toList();
    _require(
        programs.map((p) => p.id).toSet().length == programs.length &&
            (programs.isEmpty || capabilities.contains('events')),
        'declared_program.duplicate',
        r'$',
        'Declared programs require unique IDs and the explicit event capability.');
    return SourceInterpretationProfile._(
        ConverterId(_interpretationString(json['profileId'])),
        path,
        Sha256Hash(_interpretationString(archive['sha256'])),
        Set.unmodifiable(capabilities),
        Map.unmodifiable(sections),
        List.unmodifiable(programs));
  }

  final ConverterId profileId;
  final String scriptsRelativePath;
  final Sha256Hash scriptsArchiveHash;
  final Set<String> capabilities;
  final Map<String, Map<String, Object?>> sections;
  final List<SourceDeclaredProgramBinding> declaredPrograms;

  bool supports(String capability) => capabilities.contains(capability);
  bool matchesArchive(Sha256Hash? observed) => observed == scriptsArchiveHash;
  Map<String, Object?> get eventOracleSections => Map.unmodifiable({
        for (final entry in sections.entries)
          if (entry.key.startsWith('events.'))
            entry.key.substring(7): entry.value['sha256'],
      });
  Map<String, Object?> get walkingOracles => Map.unmodifiable({
        for (final entry in sections.entries)
          if (entry.key.startsWith('walking.'))
            entry.key.substring(8): {
              'sectionIndex': entry.value['index'],
              'sha256': entry.value['sha256'],
              if (entry.value.containsKey('lines'))
                'lines': entry.value['lines'],
            },
      });
  Map<String, Object?> toJson() => {
        'kind': 'sourceInterpretationProfile',
        'schemaVersion': 2,
        'profileId': profileId.value,
        'semanticsId': 'rmxp-essentials-static-v1',
        'scriptsArchive': {
          'relativePath': scriptsRelativePath,
          'sha256': scriptsArchiveHash.value
        },
        'capabilities': capabilities.toList()..sort(),
        'sections': sections,
        'declaredPrograms': declaredPrograms.map((p) => p.toJson()).toList(),
      };
  late final Sha256Hash canonicalHash =
      canonicalHashOf(toJson(), limits: jsonLimits);

  Future<void> verifySource(
      {required SourceSnapshot snapshot,
      required SourceFilePort files,
      ScanCancellation? cancellation}) async {
    cancellation?.check();
    final entries = snapshot.entries
        .where((entry) => entry.relativePath == scriptsRelativePath)
        .toList();
    _require(
        entries.length == 1 &&
            entries.single.kind == SourceNodeKind.file &&
            entries.single.sha256 == scriptsArchiveHash &&
            entries.single.byteLength <= 8388608,
        'interpretation_profile.source_mismatch',
        scriptsRelativePath,
        'The selected interpretation profile does not match the admitted script archive.');
    final entry = entries.single;
    final bytes = await files.read(entry.fileId);
    cancellation?.check();
    _require(
        bytes.length == entry.byteLength &&
            Sha256Hash(sha256.convert(bytes).toString()) == scriptsArchiveHash,
        'interpretation_profile.source_changed',
        scriptsRelativePath,
        'The script archive changed after inventory.');
    final document = const MarshalDecoder().decode(bytes,
        sourcePath: scriptsRelativePath,
        limits: const MarshalDecodeLimits(
            maxInputBytes: 8388608,
            maxNodes: 100000,
            maxObjects: 100000,
            maxSymbols: 4096,
            maxContainerEntries: 65536,
            maxTotalEntries: 100000,
            maxStringBytes: 8388608,
            maxTotalStringBytes: 8388608));
    final root = document.node(document.rootId);
    _require(
        root.kind == MarshalKind.array,
        'interpretation_profile.archive_shape',
        scriptsRelativePath,
        'Compiled scripts must be a bounded RMXP array.');
    var expandedBytes = 0;
    for (final pin in sections.values) {
      cancellation?.check();
      final index = pin['index'] as int;
      _require(
          index < root.elements.length,
          'interpretation_profile.section_missing',
          scriptsRelativePath,
          'A selected script-section witness is missing.');
      final row = document.node(root.elements[index]);
      _require(
          row.kind == MarshalKind.array && row.elements.length == 3,
          'interpretation_profile.section_shape',
          scriptsRelativePath,
          'A script-section tuple is malformed.');
      final name = document.node(row.elements[1]);
      final data = document.node(row.elements[2]);
      _require(
          name.kind == MarshalKind.string &&
              (pin['name'] == null || name.text().text == pin['name']) &&
              data.kind == MarshalKind.string &&
              data.bytes != null,
          'interpretation_profile.section_shape',
          scriptsRelativePath,
          'A script-section witness has invalid fields.');
      final expanded = const BoundedZlibDecoder().decode(data.bytes!,
          sourcePath: scriptsRelativePath,
          limits: ZlibDecodeLimits(
              maxInputBytes: 8388608,
              maxOutputBytes: 33554432 - expandedBytes));
      expandedBytes += expanded.length;
      _require(
          sha256.convert(expanded).toString() == pin['sha256'],
          'interpretation_profile.section_mismatch',
          scriptsRelativePath,
          'A selected script section differs from its declared witness.');
    }
  }
}

Map<String, Object?> _interpretationObject(Object? value) {
  _require(
      value is Map && value.keys.every((key) => key is String),
      'interpretation_profile.schema',
      r'$',
      'Expected a source interpretation object.');
  return Map<String, Object?>.from(value as Map);
}

void _interpretationKeys(Map<String, Object?> value, Set<String> allowed) {
  _require(value.keys.every(allowed.contains), 'interpretation_profile.schema',
      r'$', 'Unknown source interpretation fields.');
}

String _interpretationString(Object? value) {
  _require(
      value is String &&
          value.isNotEmpty &&
          value.length <= 256 &&
          value.trim() == value &&
          !value.codeUnits.any((unit) => unit < 32 || unit == 127),
      'interpretation_profile.schema',
      r'$',
      'Expected a bounded source interpretation string.');
  return value as String;
}
