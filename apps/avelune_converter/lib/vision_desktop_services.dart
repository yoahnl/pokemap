import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

final class ConverterVisionClient {
  const ConverterVisionClient({required this.port, required this.usage});
  final VisionPort port;
  final Future<VisionUsageSnapshot> Function() usage;
}

typedef ConverterVisionClientFactory = Future<ConverterVisionClient> Function({
  required VisionSecretVault vault,
  required Future<VisionLiveContext> Function() liveContext,
  required Future<SourceFilePort> Function() sourceFiles,
  required Future<List<String>> Function() excludedRoots,
});

Future<ConverterVisionClient> openConverterVisionClient({
  required VisionSecretVault vault,
  required Future<VisionLiveContext> Function() liveContext,
  required Future<SourceFilePort> Function() sourceFiles,
  required Future<List<String>> Function() excludedRoots,
}) async {
  final support = await getApplicationSupportDirectory();
  final service = VisionAssistanceService(
    vault: vault,
    store: LocalVisionStore(
      rootPath: path.join(support.path, 'vision-assistance'),
      excludedRoots: excludedRoots,
    ),
    liveContext: liveContext,
    sourceFiles: sourceFiles,
  );
  return ConverterVisionClient(port: service, usage: service.usage);
}

final class ConverterVisionSourceFiles implements SourceFilePort {
  ConverterVisionSourceFiles(
    this.selection,
    this.snapshot,
    List<ConverterSharedSourceFile> sharedSourceFiles,
  ) : sharedSourceFiles = List.unmodifiable(sharedSourceFiles);
  final ConverterSourceSelection selection;
  final SourceSnapshot snapshot;
  final List<ConverterSharedSourceFile> sharedSourceFiles;

  @override
  Future<List<int>> read(ConverterId fileId) async {
    final source = await SupplementedSourceTree.open(
      selection.rootPath,
      supplementalRootPaths: selection.supplementalRootPaths,
    );
    try {
      final files = await SnapshotSourceFiles.bind(
        source: source,
        snapshot: snapshot,
        policy: selection.policy,
      );
      _verifyProvenance(source, snapshot, sharedSourceFiles);
      final bytes = await files.read(fileId);
      await files.verifyUnchanged();
      _verifyProvenance(source, snapshot, sharedSourceFiles);
      return bytes;
    } finally {
      await source.close();
    }
  }
}

Future<bool> verifyConverterVisionSource(
  ConverterSourceSelection selection,
  SourceSnapshot snapshot,
  List<ConverterSharedSourceFile> sharedSourceFiles,
) async {
  final source = await SupplementedSourceTree.open(
    selection.rootPath,
    supplementalRootPaths: selection.supplementalRootPaths,
  );
  try {
    final fresh = await SourceScanner().scan(
      source: source,
      logicalProjectNamespace: selection.logicalProjectNamespace,
      policy: selection.policy,
    );
    _verifyProvenance(source, fresh, sharedSourceFiles);
    return fresh.state == SourceScanState.complete &&
        fresh.canonicalHash == snapshot.canonicalHash &&
        fresh.policyHash == snapshot.policyHash;
  } finally {
    await source.close();
  }
}

void _verifyProvenance(
  SupplementedSourceTree source,
  SourceSnapshot snapshot,
  List<ConverterSharedSourceFile> expected,
) {
  if (canonicalHashOf(
        source
            .sharedSourceFilesFor(snapshot)
            .map((file) => file.toJson())
            .toList(),
      ) !=
      canonicalHashOf(expected.map((file) => file.toJson()).toList())) {
    throw const ConverterWorkflowFailure(
      'workflow.source_provenance_changed',
      'Source file origins changed; scan and prepare a new exact draft.',
    );
  }
}

final class ConverterKeychainFailure implements Exception {
  const ConverterKeychainFailure();

  @override
  String toString() => 'ConverterKeychainFailure: secret unavailable';
}

final class ConverterKeychainVault implements VisionSecretVault {
  ConverterKeychainVault({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('com.avelune.converter/vision_secret');

  final MethodChannel _channel;

  @override
  Future<String?> read() async {
    try {
      final value = await _channel.invokeMethod<String>('read');
      if (value != null && !_validSecret(value)) {
        throw const ConverterKeychainFailure();
      }
      return value;
    } catch (_) {
      throw const ConverterKeychainFailure();
    }
  }

  @override
  Future<void> write(String secret) async {
    if (!_validSecret(secret)) {
      throw ArgumentError('La clé doit être un texte non vide, sans espaces.');
    }
    try {
      await _channel.invokeMethod<void>('write', {'secret': secret});
    } catch (_) {
      throw const ConverterKeychainFailure();
    }
  }

  @override
  Future<void> delete() async {
    try {
      await _channel.invokeMethod<void>('delete');
    } catch (_) {
      throw const ConverterKeychainFailure();
    }
  }

  bool _validSecret(String value) =>
      value.isNotEmpty &&
      value.length <= 4096 &&
      !value.codeUnits.any((unit) => unit <= 32 || unit >= 127);
}
