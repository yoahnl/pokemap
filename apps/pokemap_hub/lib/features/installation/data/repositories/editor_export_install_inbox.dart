import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

import 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';
import 'package:pokemap_hub/features/installation/domain/repositories/game_installation_repository_interface.dart';

typedef EditorExportPackageInstaller = Future<void> Function(
  File package, {
  required GamePackageInstallSource source,
  required GameInstallCancellationToken cancellationToken,
  GameInstallProgressListener? onProgress,
});

enum EditorExportInstallStatus { installed, failed }

final class EditorExportInstallResult {
  const EditorExportInstallResult({
    required this.requestId,
    required this.status,
    required this.code,
  });

  final String requestId;
  final EditorExportInstallStatus status;
  final String code;
}

/// Consumes the editor-to-Hub inbox without trusting either filename or bytes.
final class EditorExportInstallInbox {
  const EditorExportInstallInbox({
    required this.inbox,
    required this.installer,
    this.maxRequests = 100,
    this.maxRequestBytes = 64 * 1024,
  });

  factory EditorExportInstallInbox.fromInstaller({
    required Directory inbox,
    required GameInstallationRepositoryInterface installer,
    int maxRequests = 100,
    int maxRequestBytes = 64 * 1024,
  }) =>
      EditorExportInstallInbox(
        inbox: inbox,
        maxRequests: maxRequests,
        maxRequestBytes: maxRequestBytes,
        installer: (
          package, {
          required source,
          required cancellationToken,
          onProgress,
        }) async {
          await installer.install(
            package,
            source: source,
            cancellationToken: cancellationToken,
            onProgress: onProgress,
          );
        },
      );

  final Directory inbox;
  final EditorExportPackageInstaller installer;
  final int maxRequests;
  final int maxRequestBytes;

  Future<List<EditorExportInstallResult>> consumePending({
    GameInstallCancellationToken? cancellationToken,
    GameInstallProgressListener? onProgress,
  }) async {
    final cancellation = cancellationToken ?? GameInstallCancellationToken();
    final inboxType = await FileSystemEntity.type(
      inbox.path,
      followLinks: false,
    );
    if (inboxType == FileSystemEntityType.notFound) {
      return const <EditorExportInstallResult>[];
    }
    if (inboxType != FileSystemEntityType.directory) {
      return const <EditorExportInstallResult>[
        EditorExportInstallResult(
          requestId: 'inbox',
          status: EditorExportInstallStatus.failed,
          code: 'unsafeInbox',
        ),
      ];
    }

    final requests = <File>[];
    await for (final entity in inbox.list(followLinks: false)) {
      if (entity is File && entity.path.endsWith('.request.json')) {
        requests.add(entity);
      }
    }
    requests.sort((left, right) => left.path.compareTo(right.path));
    if (requests.length > maxRequests) {
      return const <EditorExportInstallResult>[
        EditorExportInstallResult(
          requestId: 'inbox',
          status: EditorExportInstallStatus.failed,
          code: 'requestQuotaExceeded',
        ),
      ];
    }

    final results = <EditorExportInstallResult>[];
    for (final requestFile in requests) {
      final fallbackId = p
          .basename(requestFile.path)
          .replaceFirst(RegExp(r'\.request\.json$'), '');
      if (cancellation.isCancelled) {
        results.add(
          EditorExportInstallResult(
            requestId: fallbackId,
            status: EditorExportInstallStatus.failed,
            code: 'cancelled',
          ),
        );
        break;
      }
      results.add(
        await _consume(
          requestFile,
          fallbackId: fallbackId,
          cancellationToken: cancellation,
          onProgress: onProgress,
        ),
      );
    }
    return List<EditorExportInstallResult>.unmodifiable(results);
  }

  Future<EditorExportInstallResult> _consume(
    File requestFile, {
    required String fallbackId,
    required GameInstallCancellationToken cancellationToken,
    required GameInstallProgressListener? onProgress,
  }) async {
    GamePackageInstallRequest? request;
    File? packageFile;
    try {
      if (await FileSystemEntity.type(
            requestFile.path,
            followLinks: false,
          ) !=
          FileSystemEntityType.file) {
        return _failed(fallbackId, 'unsafeRequest');
      }
      if (await requestFile.length() > maxRequestBytes) {
        return _failed(fallbackId, 'requestTooLarge');
      }
      request = const GamePackageInstallRequestCodec().decodeUtf8(
        await requestFile.readAsBytes(),
      );
      if (p.basename(requestFile.path) != '${request.requestId}.request.json') {
        return _failed(request.requestId, 'requestNameMismatch');
      }
      packageFile = File(p.join(inbox.path, request.packageFileName));
      if (await FileSystemEntity.type(
            packageFile.path,
            followLinks: false,
          ) !=
          FileSystemEntityType.file) {
        return _failed(request.requestId, 'packageMissingOrUnsafe');
      }
      final digest = await sha256.bind(packageFile.openRead()).first;
      if (digest.toString() != request.packageSha256) {
        return _failed(request.requestId, 'digestMismatch');
      }
      await installer(
        packageFile,
        source: GamePackageInstallSource.localExport,
        cancellationToken: cancellationToken,
        onProgress: onProgress,
      );
    } on GamePackageFormatException {
      return _failed(request?.requestId ?? fallbackId, 'invalidRequest');
    } on GameInstallationException catch (error) {
      return _failed(
        request?.requestId ?? fallbackId,
        'install.${error.diagnostic.code.name}',
      );
    } on Object {
      return _failed(
        request?.requestId ?? fallbackId,
        'installationFailed',
      );
    }

    var code = 'installed';
    try {
      // Remove the discovery marker first. A leftover package is inert,
      // whereas a leftover request would schedule a redundant installation.
      await requestFile.delete();
      await packageFile.delete();
    } on Object {
      code = 'installedCleanupPending';
    }
    return EditorExportInstallResult(
      requestId: request.requestId,
      status: EditorExportInstallStatus.installed,
      code: code,
    );
  }

  EditorExportInstallResult _failed(String requestId, String code) =>
      EditorExportInstallResult(
        requestId: requestId,
        status: EditorExportInstallStatus.failed,
        code: code,
      );
}
