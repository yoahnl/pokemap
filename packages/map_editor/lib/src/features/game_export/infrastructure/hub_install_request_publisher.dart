import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

import '../application/game_package_export_profile.dart';

typedef HubInstallRequestIdGenerator = String Function();

final class HubInstallRequestPublisher {
  HubInstallRequestPublisher({
    required this.inbox,
    HubInstallRequestIdGenerator? requestIdGenerator,
    DateTime Function()? now,
  }) : requestIdGenerator = requestIdGenerator ?? _secureRequestId,
       now = now ?? DateTime.now;

  final Directory inbox;
  final HubInstallRequestIdGenerator requestIdGenerator;
  final DateTime Function() now;

  Future<GamePackageInstallRequest> publish(List<int> packageBytes) async {
    if (packageBytes.isEmpty) {
      throw const GamePackageExportException(
        code: 'emptyPackage',
        message: 'Cannot publish an empty game package.',
      );
    }
    final requestId = requestIdGenerator();
    final packageFileName = '$requestId.avelunegame';
    final request = GamePackageInstallRequest(
      requestId: requestId,
      packageFileName: packageFileName,
      packageSha256: sha256.convert(packageBytes).toString(),
      createdAt: now().toUtc(),
    );
    // Validate caller-provided IDs before touching the inbox.
    const GamePackageInstallRequestCodec().encodeCanonicalUtf8(request);
    await inbox.create(recursive: true);
    final packageFile = File(p.join(inbox.path, packageFileName));
    final requestFile = File(p.join(inbox.path, '$requestId.request.json'));
    if (await packageFile.exists() || await requestFile.exists()) {
      throw GamePackageExportException(
        code: 'installRequestCollision',
        path: requestId,
        message: 'A Hub install request with this ID already exists.',
      );
    }
    final token = '${DateTime.now().microsecondsSinceEpoch}-$pid';
    final packageTemporary = File('${packageFile.path}.$token.tmp');
    final requestTemporary = File('${requestFile.path}.$token.tmp');
    try {
      await packageTemporary.writeAsBytes(packageBytes, flush: true);
      final reread = await packageTemporary.readAsBytes();
      if (sha256.convert(reread).toString() != request.packageSha256) {
        throw const GamePackageExportException(
          code: 'installRequestDigestMismatch',
          message: 'Inbox package digest changed during publication.',
        );
      }
      await packageTemporary.rename(packageFile.path);
      await requestTemporary.writeAsBytes(
        const GamePackageInstallRequestCodec().encodeCanonicalUtf8(request),
        flush: true,
      );
      const GamePackageInstallRequestCodec().decodeUtf8(
        await requestTemporary.readAsBytes(),
      );
      // The request is promoted last so the Hub never observes partial bytes.
      await requestTemporary.rename(requestFile.path);
      return request;
    } on Object catch (error) {
      if (await packageTemporary.exists()) await packageTemporary.delete();
      if (await requestTemporary.exists()) await requestTemporary.delete();
      if (await packageFile.exists() && !await requestFile.exists()) {
        await packageFile.delete();
      }
      if (error is GamePackageExportException) rethrow;
      throw GamePackageExportException(
        code: 'installRequestPublishFailed',
        path: inbox.path,
        message: 'The package could not be queued for PokeMap Hub.',
        cause: error,
      );
    }
  }

  static String _secureRequestId() {
    final random = Random.secure();
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final suffix = List<int>.generate(
      8,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return 'export-$timestamp-$suffix';
  }
}
